import { MongoClient, Db } from 'mongodb';

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectToDatabase(): Promise<Db> {
  if (db) {
    return db;
  }

  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI is not defined in environment variables');
  }

  try {
    client = new MongoClient(uri, {
      maxPoolSize: 10, // 接続プールサイズ
      minPoolSize: 2,
      maxIdleTimeMS: 30000, // アイドル接続のタイムアウト
    });
    await client.connect();
    
    db = client.db('echolog');
    console.log('✅ Connected to MongoDB Atlas');

    // インデックスを作成
    await createIndexes(db);
    
    return db;
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error);
    throw new Error('Database connection failed');
  }
}

/**
 * パフォーマンス最適化のためのインデックスを作成
 */
async function createIndexes(database: Db): Promise<void> {
  try {
    const memosCollection = database.collection('memos');

    // 既存のインデックスをチェック
    const existingIndexes = await memosCollection.indexes();
    const indexNames = existingIndexes.map((idx) => idx.name);

    // user_id + created_at の複合インデックス（メモ一覧取得用）
    if (!indexNames.includes('user_id_1_created_at_-1')) {
      await memosCollection.createIndex(
        { user_id: 1, created_at: -1 },
        { name: 'user_id_1_created_at_-1' }
      );
      console.log('✅ Created index: user_id_1_created_at_-1');
    }

    // related_memo_ids インデックス（関連メモ検索用）
    if (!indexNames.includes('related_memo_ids_1')) {
      await memosCollection.createIndex(
        { related_memo_ids: 1 },
        { name: 'related_memo_ids_1', sparse: true }
      );
      console.log('✅ Created index: related_memo_ids_1');
    }

    // deleted_at インデックス（削除済みメモのフィルタリング用）
    if (!indexNames.includes('deleted_at_1')) {
      await memosCollection.createIndex(
        { deleted_at: 1 },
        { name: 'deleted_at_1', sparse: true }
      );
      console.log('✅ Created index: deleted_at_1');
    }

    console.log('✅ All indexes created successfully');
  } catch (error) {
    console.error('❌ Index creation failed:', error);
    // インデックス作成失敗はアプリケーション起動を妨げない
  }
}

export async function closeDatabaseConnection(): Promise<void> {
  if (client) {
    await client.close();
    client = null;
    db = null;
    console.log('✅ MongoDB connection closed');
  }
}

export function getDatabase(): Db {
  if (!db) {
    throw new Error('Database not connected. Call connectToDatabase() first.');
  }
  return db;
}
