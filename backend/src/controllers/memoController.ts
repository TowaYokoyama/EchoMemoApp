import { Response, NextFunction } from 'express';
import { ObjectId } from 'mongodb';
import { CreateMemoSchema, SearchMemoSchema } from '../models/memo';
import { documentToResponse } from '../types';
import { AppError } from '../utils/errorHandler';
import { cosineSimilarity } from '../utils/similarity';
import { AuthRequest } from '../middleware/auth';
import { calculateMemoLinks, cleanupMemoLinks } from '../services/linkCalculator';
import * as memoService from '../services/memoService';

export async function createMemo(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const validatedData = CreateMemoSchema.parse(req.body);
    const userId = new ObjectId(req.user!.userId);

    // Service層でDB操作を実行
    const insertedMemo = await memoService.createMemoInDB({
      user_id: userId,
      audio_url: validatedData.audio_url,
      transcription: validatedData.transcription,
      summary: validatedData.summary,
      tags: validatedData.tags,
      embedding: validatedData.embedding,
    });

    // レスポンスを即座に返す
    res.status(201).json(documentToResponse(insertedMemo));

    // リンク計算を非同期で実行（awaitしない）
    if (validatedData.embedding && insertedMemo._id) {
      calculateMemoLinks(insertedMemo._id.toString(), validatedData.embedding)
        .catch((error) => console.error('Link calculation failed:', error));
    }
  } catch (error: any) {
    if (error.name === 'ZodError') {
      return next(new AppError(400, 'Invalid request data'));
    }
    next(error);
  }
}

export async function getRecentMemos(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const skip = parseInt(req.query.skip as string) || 0;

    // バリデーション
    if (limit < 1 || limit > 100) {
      throw new AppError(400, 'Limit must be between 1 and 100');
    }
    if (skip < 0) {
      throw new AppError(400, 'Skip must be non-negative');
    }

    const userId = new ObjectId(req.user!.userId);

    // Service層でDB操作を実行
    const { memos, total } = await memoService.getRecentMemosFromDB(userId, {
      skip,
      limit,
    });

    const response = memos.map(documentToResponse);

    res.status(200).json({
      data: response,
      pagination: {
        total,
        skip,
        limit,
        hasMore: skip + memos.length < total,
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function getMemoById(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const { id } = req.params;

    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const userId = new ObjectId(req.user!.userId);
    const memo = await memoService.getMemoByIdFromDB(new ObjectId(id), userId);

    if (!memo) {
      throw new AppError(404, 'Memo not found');
    }

    res.status(200).json(documentToResponse(memo));
  } catch (error) {
    next(error);
  }
}

export async function searchMemosByEmbedding(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const validatedData = SearchMemoSchema.parse(req.body);
    const queryEmbedding = validatedData.embedding;
    const limit = validatedData.limit || 5;
    const userId = new ObjectId(req.user!.userId);

    // Service層でDB操作を実行
    const memos = await memoService.searchMemosByEmbeddingInDB(
      userId,
      queryEmbedding,
      limit
    );

    if (memos.length === 0) {
      return res.status(200).json([]);
    }

    // コサイン類似度を計算
    const memosWithSimilarity = memos.map((memo) => ({
      memo,
      similarity: cosineSimilarity(queryEmbedding, memo.embedding!),
    }));

    // フィルタリングとソート
    const filteredMemos = memosWithSimilarity
      .filter((item) => item.similarity > 0.7)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit);

    const response = filteredMemos.map((item) => ({
      ...documentToResponse(item.memo),
      similarity: item.similarity,
    }));

    res.status(200).json(response);
  } catch (error: unknown) {
    if (error instanceof Error && error.name === 'ZodError') {
      return next(new AppError(400, 'Invalid request data'));
    }
    next(error);
  }
}

export async function deleteMemo(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const { id } = req.params;

    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const userId = new ObjectId(req.user!.userId);

    // 論理削除（Soft Delete）に変更
    const deleted = await memoService.softDeleteMemoInDB(new ObjectId(id), userId);

    if (!deleted) {
      throw new AppError(404, 'Memo not found');
    }

    // リンククリーンアップを非同期で実行
    cleanupMemoLinks(id).catch((error) =>
      console.error('Link cleanup failed:', error)
    );

    res.status(200).json({ message: 'Memo deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getRelatedMemos(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit as string) || 10;

    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const userId = new ObjectId(req.user!.userId);
    const memo = await memoService.getMemoByIdFromDB(new ObjectId(id), userId);

    if (!memo) {
      throw new AppError(404, 'Memo not found');
    }

    if (!memo.related_memo_ids || memo.related_memo_ids.length === 0) {
      return res.status(200).json([]);
    }

    // 制限付きで関連メモを取得
    const relatedMemos = await memoService.getRelatedMemosFromDB(
      userId,
      memo.related_memo_ids,
      limit
    );

    const response = relatedMemos.map(documentToResponse);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
}

export async function updateMemo(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const { id } = req.params;
    console.log('📝 Update memo request:', { id, body: req.body });

    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const userId = new ObjectId(req.user!.userId);

    // 更新データを構築（フロントエンドとの互換性を考慮）
    const updateData = {
      ...(req.body.transcription !== undefined && { transcription: req.body.transcription }),
      ...(req.body.content !== undefined && { transcription: req.body.content }),
      ...(req.body.summary !== undefined && { summary: req.body.summary }),
      ...(req.body.title !== undefined && { summary: req.body.title }),
      ...(req.body.tags !== undefined && { tags: req.body.tags }),
    };

    if (Object.keys(updateData).length === 0) {
      throw new AppError(400, 'No fields to update');
    }

    console.log('🔄 Updating memo with fields:', updateData);

    // Service層でDB操作を実行
    const result = await memoService.updateMemoInDB(
      new ObjectId(id),
      userId,
      updateData
    );

    if (!result) {
      console.log('❌ Memo not found for update');
      throw new AppError(404, 'Memo not found');
    }

    console.log('✅ Memo updated successfully:', result._id?.toString());
    res.status(200).json(documentToResponse(result));
  } catch (error: unknown) {
    console.error('❌ Update memo error:', error);
    if (error instanceof Error && error.name === 'ZodError') {
      return next(new AppError(400, 'Invalid request data'));
    }
    next(error);
  }
}
