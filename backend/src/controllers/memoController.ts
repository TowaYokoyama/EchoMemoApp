import { Request, Response, NextFunction } from 'express';
import { ObjectId } from 'mongodb';
import { getDatabase } from '../config/database';
import { CreateMemoSchema, SearchMemoSchema } from '../models/memo';
import { MemoDocument, documentToResponse } from '../types';
import { AppError } from '../utils/errorHandler';
import { cosineSimilarity } from '../utils/similarity';
import { AuthRequest } from '../middleware/auth';
import { calculateMemoLinks, cleanupMemoLinks } from '../services/linkCalculator';

export async function createMemo(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    // Validate request body
    const validatedData = CreateMemoSchema.parse(req.body);

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    // 認証されたユーザーIDを取得
    const userId = new ObjectId(req.user!.userId);

    // Create memo document
    const memoDocument: MemoDocument = {
      user_id: userId,
      audio_url: validatedData.audio_url,
      transcription: validatedData.transcription,
      summary: validatedData.summary,
      tags: validatedData.tags,
      embedding: validatedData.embedding,
      created_at: new Date(),
    };

    // Insert into MongoDB
    const result = await collection.insertOne(memoDocument);

    // Fetch the inserted document
    const insertedMemo = await collection.findOne({ _id: result.insertedId });

    if (!insertedMemo) {
      throw new AppError(500, 'Failed to retrieve created memo');
    }

    // Return response immediately
    res.status(201).json(documentToResponse(insertedMemo));

    // Calculate links asynchronously (don't await)
    if (validatedData.embedding) {
      calculateMemoLinks(result.insertedId.toString(), validatedData.embedding)
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

    // Validate limit and skip
    if (limit < 1 || limit > 100) {
      throw new AppError(400, 'Limit must be between 1 and 100');
    }
    if (skip < 0) {
      throw new AppError(400, 'Skip must be non-negative');
    }

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    // 認証されたユーザーIDでフィルタ
    const userId = new ObjectId(req.user!.userId);

    const memos = await collection
      .find({ 
        user_id: userId,
        deleted_at: { $exists: false } 
      })
      .sort({ created_at: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();


    const total = await collection.countDocuments({ 
      user_id: userId,
      deleted_at: { $exists: false } 
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

    // Validate ObjectId format
    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    const userId = new ObjectId(req.user!.userId);

    
    const memo = await collection.findOne({ 
      _id: new ObjectId(id),
      user_id: userId,
      deleted_at: { $exists: false }
    });

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

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    // 認証されたユーザーIDでフィルタ
    const userId = new ObjectId(req.user!.userId);

    const memos = await collection
      .find({ 
        user_id: userId,
        embedding: { $exists: true },
        deleted_at: { $exists: false }
      } as any)
      .toArray();

    if (memos.length === 0) {
      return res.status(200).json([]);
    }

    const memosWithSimilarity = memos.map((memo) => {
      const similarity = cosineSimilarity(queryEmbedding, memo.embedding!);
      return {
        memo,
        similarity,
      };
    });

    const filteredMemos = memosWithSimilarity
      .filter((item) => item.similarity > 0.7)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit);

    const response = filteredMemos.map((item) => ({
      ...documentToResponse(item.memo),
      similarity: item.similarity,
    }));

    res.status(200).json(response);
  } catch (error: any) {
    if (error.name === 'ZodError') {
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

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    const userId = new ObjectId(req.user!.userId);

    
    const result = await collection.deleteOne({ 
      _id: new ObjectId(id),
      user_id: userId
    });

    if (result.deletedCount === 0) {
      throw new AppError(404, 'Memo not found');
    }

  
    cleanupMemoLinks(id).catch((error) =>
      console.error('Link cleanup failed:', error)
    );

    res.status(200).json({ message: 'Memo deleted successfully' });
  } catch (error) {
    next(error);
  }
}

// 関連メモを取得
export async function getRelatedMemos(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const { id } = req.params;


    if (!ObjectId.isValid(id)) {
      throw new AppError(400, 'Invalid memo ID format');
    }

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    // 認証されたユーザーIDでフィルタ
    const userId = new ObjectId(req.user!.userId);

    
    const memo = await collection.findOne({
      _id: new ObjectId(id),
      user_id: userId,
      deleted_at: { $exists: false },
    });

    if (!memo) {
      throw new AppError(404, 'Memo not found');
    }

    if (!memo.related_memo_ids || memo.related_memo_ids.length === 0) {
      return res.status(200).json([]);
    }

    const relatedMemos = await collection
      .find({
        _id: { $in: memo.related_memo_ids.map((id: string) => new ObjectId(id)) },
        user_id: userId,
        deleted_at: { $exists: false },
      })
      .toArray();

    const response = relatedMemos.map(documentToResponse);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
}

// メモ更新
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

    const db = getDatabase();
    const collection = db.collection<MemoDocument>('memos');

    const userId = new ObjectId(req.user!.userId);

    // 更新可能なフィールドのみ抽出
    const updateFields: Partial<MemoDocument> = {};
    
    // transcription または content を受け入れる（フロントエンドとの互換性）
    if (req.body.transcription !== undefined) {
      updateFields.transcription = req.body.transcription;
    } else if (req.body.content !== undefined) {
      updateFields.transcription = req.body.content;
    }
    
    // summary または title を受け入れる（フロントエンドとの互換性）
    if (req.body.summary !== undefined) {
      updateFields.summary = req.body.summary;
    } else if (req.body.title !== undefined) {
      updateFields.summary = req.body.title;
    }
    
    if (req.body.tags !== undefined) {
      updateFields.tags = req.body.tags;
    }

    // 更新するフィールドがない場合はエラー
    if (Object.keys(updateFields).length === 0) {
      throw new AppError(400, 'No fields to update');
    }

    // updated_atを自動設定
    updateFields.updated_at = new Date();

    console.log('🔄 Updating memo with fields:', updateFields);

    const result = await collection.findOneAndUpdate(
      {
        _id: new ObjectId(id),
        user_id: userId,
        deleted_at: { $exists: false },
      },
      { $set: updateFields },
      { returnDocument: 'after' }
    );

    if (!result) {
      console.log('❌ Memo not found for update');
      throw new AppError(404, 'Memo not found');
    }

    console.log('✅ Memo updated successfully:', result._id.toString());
    res.status(200).json(documentToResponse(result));
  } catch (error: any) {
    console.error('❌ Update memo error:', error);
    if (error.name === 'ZodError') {
      return next(new AppError(400, 'Invalid request data'));
    }
    next(error);
  }
}
