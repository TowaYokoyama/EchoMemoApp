import { ObjectId } from 'mongodb';
import { getDatabase } from '../config/database';
import { MemoDocument } from '../types';
import { cosineSimilarity } from '../utils/similarity';

interface LinkResult {
  memoId: string;
  similarity: number;
}

/**
 * メモのリンクを計算して更新
 * @param memoId 対象メモのID
 * @param embedding 対象メモのEmbedding
 * @returns リンクされたメモのIDリスト
 */
export async function calculateMemoLinks(
  memoId: string,
  embedding: number[]
): Promise<string[]> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // 自分以外の全メモを取得（Embeddingがあるもののみ）
  const allMemos = await collection
    .find({
      _id: { $ne: new ObjectId(memoId) },
      embedding: { $exists: true },
      deleted_at: { $exists: false },
    })
    .toArray();

  if (allMemos.length === 0) {
    return [];
  }

  // 類似度を計算
  const similarities: LinkResult[] = allMemos.map((memo) => ({
    memoId: memo._id.toString(),
    similarity: cosineSimilarity(embedding, memo.embedding!),
  }));

  // 閾値0.75以上でフィルタリング、類似度順にソート、TOP 10を取得
  const linkedMemos = similarities
    .filter((s) => s.similarity >= 0.75)
    .sort((a, b) => b.similarity - a.similarity)
    .slice(0, 10)
    .map((s) => s.memoId);

  // 現在のメモのrelated_memo_idsを更新
  await collection.updateOne(
    { _id: new ObjectId(memoId) },
    { $set: { related_memo_ids: linkedMemos } }
  );

  // 双方向リンクを更新（リンクされたメモ側にも追加）
  for (const linkedId of linkedMemos) {
    await collection.updateOne(
      { _id: new ObjectId(linkedId) },
      { $addToSet: { related_memo_ids: memoId } }
    );
  }

  return linkedMemos;
}

/**
 * メモが削除された時にリンクをクリーンアップ
 * @param memoId 削除されたメモのID
 */
export async function cleanupMemoLinks(memoId: string): Promise<void> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // このメモを参照している全メモからリンクを削除
  await collection.updateMany(
    { related_memo_ids: memoId },
    { $pull: { related_memo_ids: memoId } }
  );
}
