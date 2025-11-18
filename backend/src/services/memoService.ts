import { ObjectId, Filter } from 'mongodb';
import { getDatabase } from '../config/database';
import { MemoDocument } from '../types';
import { AppError } from '../utils/errorHandler';

/**
 * メモサービス層
 * データベース操作とビジネスロジックを担当
 */

interface CreateMemoData {
  user_id: ObjectId;
  audio_url: string;
  transcription: string;
  summary: string;
  tags: string[];
  embedding?: number[];
}

interface UpdateMemoData {
  transcription?: string;
  summary?: string;
  tags?: string[];
}

interface PaginationOptions {
  skip: number;
  limit: number;
}

/**
 * メモを作成
 */
export async function createMemoInDB(data: CreateMemoData): Promise<MemoDocument> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  const memoDocument: MemoDocument = {
    ...data,
    created_at: new Date(),
  };

  const result = await collection.insertOne(memoDocument);
  const insertedMemo = await collection.findOne({ _id: result.insertedId });

  if (!insertedMemo) {
    throw new AppError(500, 'Failed to retrieve created memo');
  }

  return insertedMemo;
}

/**
 * 最近のメモを取得（ページネーション対応）
 */
export async function getRecentMemosFromDB(
  userId: ObjectId,
  options: PaginationOptions
): Promise<{ memos: MemoDocument[]; total: number }> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  const filter: Filter<MemoDocument> = {
    user_id: userId,
    deleted_at: { $exists: false },
  };

  const [memos, total] = await Promise.all([
    collection
      .find(filter)
      .sort({ created_at: -1 })
      .skip(options.skip)
      .limit(options.limit)
      .toArray(),
    collection.countDocuments(filter),
  ]);

  return { memos, total };
}

/**
 * IDでメモを取得
 */
export async function getMemoByIdFromDB(
  memoId: ObjectId,
  userId: ObjectId
): Promise<MemoDocument | null> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  return collection.findOne({
    _id: memoId,
    user_id: userId,
    deleted_at: { $exists: false },
  });
}

/**
 * ベクトル検索（Atlas Vector Search対応予定）
 * TODO: MongoDB Atlas Vector Searchに移行してパフォーマンス改善
 */
export async function searchMemosByEmbeddingInDB(
  userId: ObjectId,
  queryEmbedding: number[],
  limit: number
): Promise<MemoDocument[]> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // 現状: 全データ取得（将来的にAtlas Vector Searchに移行）
  return collection
    .find({
      user_id: userId,
      embedding: { $exists: true },
      deleted_at: { $exists: false },
    })
    .limit(1000) // 安全のため上限を設定
    .toArray();
}

/**
 * メモを論理削除（Soft Delete）
 */
export async function softDeleteMemoInDB(
  memoId: ObjectId,
  userId: ObjectId
): Promise<boolean> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  const result = await collection.updateOne(
    {
      _id: memoId,
      user_id: userId,
      deleted_at: { $exists: false },
    },
    {
      $set: { deleted_at: new Date() },
    }
  );

  return result.matchedCount > 0;
}

/**
 * 関連メモを取得（制限付き）
 */
export async function getRelatedMemosFromDB(
  userId: ObjectId,
  relatedMemoIds: string[],
  limit: number = 10
): Promise<MemoDocument[]> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // 制限を設けて取得
  const limitedIds = relatedMemoIds.slice(0, limit);

  const memos = await collection
    .find({
      _id: { $in: limitedIds.map((id) => new ObjectId(id)) },
      user_id: userId,
      deleted_at: { $exists: false },
    })
    .project({
      // 必要なフィールドのみ取得（embeddingは除外）
      audio_url: 1,
      transcription: 1,
      summary: 1,
      tags: 1,
      created_at: 1,
      updated_at: 1,
    })
    .toArray();

  return memos as MemoDocument[];
}

/**
 * メモを更新
 */
export async function updateMemoInDB(
  memoId: ObjectId,
  userId: ObjectId,
  updateData: UpdateMemoData
): Promise<MemoDocument | null> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // 更新フィールドを構築
  const updateFields: Partial<MemoDocument> = {
    ...updateData,
    updated_at: new Date(),
  };

  const result = await collection.findOneAndUpdate(
    {
      _id: memoId,
      user_id: userId,
      deleted_at: { $exists: false },
    },
    { $set: updateFields },
    { returnDocument: 'after' }
  );

  return result;
}
