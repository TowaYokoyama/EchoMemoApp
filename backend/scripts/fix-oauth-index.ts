/**
 * OAuth インデックス修正スクリプト
 * 
 * 問題: oauth_provider と oauth_id のユニークインデックスが sparse でないため、
 *       null 値を持つ複数のユーザーが存在するとエラーになる
 * 
 * 解決: 既存のインデックスを削除して、sparse オプション付きで再作成
 */

import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';

// 環境変数を読み込み
dotenv.config();

async function fixOAuthIndex() {
  const uri = process.env.MONGODB_URI;
  
  if (!uri) {
    console.error('❌ MONGODB_URI is not defined in environment variables');
    process.exit(1);
  }

  const client = new MongoClient(uri);

  try {
    console.log('🔌 Connecting to MongoDB...');
    await client.connect();
    console.log('✅ Connected to MongoDB');

    const db = client.db('echolog');
    const usersCollection = db.collection('users');

    // 既存のインデックスを確認
    console.log('\n📋 Checking existing indexes...');
    const indexes = await usersCollection.indexes();
    console.log('Current indexes:', indexes.map(idx => ({
      name: idx.name,
      key: idx.key,
      unique: idx.unique,
      sparse: idx.sparse
    })));

    // oauth_provider_1_oauth_id_1 インデックスを探す
    const oauthIndex = indexes.find(idx => idx.name === 'oauth_provider_1_oauth_id_1');

    if (oauthIndex) {
      console.log('\n🔍 Found oauth index:', {
        name: oauthIndex.name,
        unique: oauthIndex.unique,
        sparse: oauthIndex.sparse
      });

      if (!oauthIndex.sparse) {
        console.log('\n⚠️  Index is not sparse, dropping it...');
        await usersCollection.dropIndex('oauth_provider_1_oauth_id_1');
        console.log('✅ Dropped index: oauth_provider_1_oauth_id_1');
      } else {
        console.log('✅ Index is already sparse, no action needed');
        await client.close();
        return;
      }
    } else {
      console.log('\n⚠️  oauth_provider_1_oauth_id_1 index not found');
    }

    // sparse オプション付きで再作成
    console.log('\n🔨 Creating new sparse unique index...');
    await usersCollection.createIndex(
      { oauth_provider: 1, oauth_id: 1 },
      { 
        unique: true, 
        sparse: true,
        name: 'oauth_provider_1_oauth_id_1' 
      }
    );
    console.log('✅ Created unique sparse index: oauth_provider_1_oauth_id_1');

    // 確認
    console.log('\n📋 Verifying new indexes...');
    const newIndexes = await usersCollection.indexes();
    const newOauthIndex = newIndexes.find(idx => idx.name === 'oauth_provider_1_oauth_id_1');
    console.log('New oauth index:', {
      name: newOauthIndex?.name,
      unique: newOauthIndex?.unique,
      sparse: newOauthIndex?.sparse
    });

    console.log('\n✅ OAuth index fixed successfully!');
    console.log('\n💡 You can now restart your server with: npm run dev');

  } catch (error) {
    console.error('\n❌ Error:', error);
    process.exit(1);
  } finally {
    await client.close();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// スクリプト実行
fixOAuthIndex();
