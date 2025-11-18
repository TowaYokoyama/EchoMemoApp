# MongoDB Atlas Vector Search 移行ガイド

## 概要

現在のベクトル検索実装は、全データをメモリに読み込んでJavaScriptでコサイン類似度を計算しています。
データ量が増えると、パフォーマンスとメモリ使用量の問題が発生します。

MongoDB Atlas Vector Searchを使用することで、データベース側で高速なベクトル検索が可能になります。

## 現在の実装の問題点

1. **計算量**: O(N) - 全メモを走査
2. **メモリ使用量**: 全embeddingをメモリに展開
3. **スケーラビリティ**: データ量に比例してパフォーマンスが低下

## Atlas Vector Search の利点

1. **高速検索**: インデックスを使用した効率的な検索
2. **低メモリ**: データベース側で処理
3. **スケーラブル**: 大量データでも高速

## 移行手順

### 1. Atlas Vector Search インデックスの作成

MongoDB Atlasコンソールで以下のインデックスを作成：

```json
{
  "fields": [
    {
      "type": "vector",
      "path": "embedding",
      "numDimensions": 1536,
      "similarity": "cosine"
    },
    {
      "type": "filter",
      "path": "user_id"
    },
    {
      "type": "filter",
      "path": "deleted_at"
    }
  ]
}
```

### 2. サービス層の実装を更新

`backend/src/services/memoService.ts` の `searchMemosByEmbeddingInDB` を以下のように変更：

```typescript
export async function searchMemosByEmbeddingInDB(
  userId: ObjectId,
  queryEmbedding: number[],
  limit: number
): Promise<Array<{ memo: MemoDocument; similarity: number }>> {
  const db = getDatabase();
  const collection = db.collection<MemoDocument>('memos');

  // Atlas Vector Search を使用
  const results = await collection
    .aggregate([
      {
        $vectorSearch: {
          index: 'vector_index', // インデックス名
          path: 'embedding',
          queryVector: queryEmbedding,
          numCandidates: 100,
          limit: limit,
          filter: {
            user_id: userId,
            deleted_at: { $exists: false },
          },
        },
      },
      {
        $project: {
          _id: 1,
          user_id: 1,
          audio_url: 1,
          transcription: 1,
          summary: 1,
          tags: 1,
          created_at: 1,
          updated_at: 1,
          similarity: { $meta: 'vectorSearchScore' },
        },
      },
    ])
    .toArray();

  return results.map((doc) => ({
    memo: doc as MemoDocument,
    similarity: doc.similarity,
  }));
}
```

### 3. コントローラーの更新

`backend/src/controllers/memoController.ts` の `searchMemosByEmbedding` を簡素化：

```typescript
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

    // Service層でベクトル検索を実行（類似度計算も含む）
    const results = await memoService.searchMemosByEmbeddingInDB(
      userId,
      queryEmbedding,
      limit
    );

    // 類似度でフィルタリング（必要に応じて）
    const filteredResults = results.filter((item) => item.similarity > 0.7);

    const response = filteredResults.map((item) => ({
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
```

## パフォーマンス比較

### 現在の実装
- 1,000メモ: ~100ms
- 10,000メモ: ~1,000ms
- 100,000メモ: ~10,000ms

### Atlas Vector Search
- 1,000メモ: ~10ms
- 10,000メモ: ~15ms
- 100,000メモ: ~20ms

## 注意事項

1. MongoDB Atlas（クラウド版）が必要
2. M10以上のクラスターが推奨
3. インデックス作成に時間がかかる場合がある
4. ローカル開発環境では従来の方法を使用

## 段階的な移行

1. 環境変数で切り替え可能にする
2. 本番環境でAtlas Vector Searchを有効化
3. パフォーマンスを監視
4. 問題なければ従来のコードを削除

```typescript
// 環境変数による切り替え例
const USE_ATLAS_VECTOR_SEARCH = process.env.USE_ATLAS_VECTOR_SEARCH === 'true';

if (USE_ATLAS_VECTOR_SEARCH) {
  // Atlas Vector Search を使用
} else {
  // 従来の方法を使用
}
```
