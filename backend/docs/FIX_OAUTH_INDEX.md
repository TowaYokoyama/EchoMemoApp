# OAuth インデックスエラーの修正方法

## 問題

バックエンドサーバー起動時に以下のエラーが発生：

```
❌ Index creation failed: MongoServerError: Index build failed: ...
E11000 duplicate key error collection: echolog.users 
index: oauth_provider_1_oauth_id_1 
dup key: { oauth_provider: null, oauth_id: null }
```

## 原因

`oauth_provider`と`oauth_id`のユニークインデックスが`sparse`オプションなしで作成されているため、両方が`null`のユーザーが複数存在するとエラーになります。

### 詳細

- **通常のユニークインデックス**: `null`値も一意性の対象となる
- **sparseユニークインデックス**: `null`値は無視される（OAuth未使用ユーザーを許可）

## 解決方法

### 方法1: 自動修正スクリプトを実行（推奨）

```bash
cd backend
npm run fix-oauth-index
```

このスクリプトは以下を実行します：
1. 既存のインデックスを確認
2. `sparse`オプションがない場合は削除
3. `sparse: true`オプション付きで再作成

### 方法2: 手動でMongoDBコンソールから修正

```javascript
// MongoDB Atlasのコンソールまたはmongoshで実行

use echolog

// 既存のインデックスを削除
db.users.dropIndex("oauth_provider_1_oauth_id_1")

// sparse オプション付きで再作成
db.users.createIndex(
  { oauth_provider: 1, oauth_id: 1 },
  { unique: true, sparse: true, name: "oauth_provider_1_oauth_id_1" }
)
```

### 方法3: database.tsの自動修正機能を使用

最新の`database.ts`には自動修正機能が含まれています：

1. サーバーを起動
2. 自動的に古いインデックスを検出して削除
3. 新しいsparseインデックスを作成

```bash
cd backend
npm run dev
```

## 確認方法

### スクリプト実行後の出力例

```
✅ Connected to MongoDB
📋 Checking existing indexes...
🔍 Found oauth index: { name: 'oauth_provider_1_oauth_id_1', unique: true, sparse: false }
⚠️  Index is not sparse, dropping it...
✅ Dropped index: oauth_provider_1_oauth_id_1
🔨 Creating new sparse unique index...
✅ Created unique sparse index: oauth_provider_1_oauth_id_1
📋 Verifying new indexes...
New oauth index: { name: 'oauth_provider_1_oauth_id_1', unique: true, sparse: true }
✅ OAuth index fixed successfully!
```

### サーバー起動時の出力例

```
✅ Connected to MongoDB Atlas
⚠️  Dropping old oauth index (not sparse)...
✅ Dropped old index: oauth_provider_1_oauth_id_1
✅ Created unique sparse index: oauth_provider_1_oauth_id_1
✅ All indexes created successfully
🚀 Server running on:
   Local:   http://localhost:3000
   Network: http://192.168.0.15:3000
```

## インデックスの説明

### 修正前（問題あり）

```javascript
{
  oauth_provider: 1,
  oauth_id: 1
}
// unique: true
// sparse: false または未設定
```

**問題点**: 
- 通常のユーザー（メール/パスワード）は`oauth_provider`と`oauth_id`が両方`null`
- 複数の通常ユーザーが存在すると、`null`の重複でエラー

### 修正後（正常）

```javascript
{
  oauth_provider: 1,
  oauth_id: 1
}
// unique: true
// sparse: true ← これが重要！
```

**利点**:
- `null`値を持つドキュメントはインデックスから除外
- 通常ユーザー（OAuth未使用）は何人でも登録可能
- OAuthユーザーは`oauth_provider`と`oauth_id`の組み合わせで一意性を保証

## データ構造の例

### 通常ユーザー（メール/パスワード）

```json
{
  "_id": "...",
  "email": "user1@example.com",
  "password": "hashed_password",
  "oauth_provider": null,
  "oauth_id": null
}
```

### OAuthユーザー（Apple Sign In）

```json
{
  "_id": "...",
  "email": "user2@example.com",
  "oauth_provider": "apple",
  "oauth_id": "001234.abc...",
  "password": undefined
}
```

### OAuthユーザー（Google Sign In）

```json
{
  "_id": "...",
  "email": "user3@example.com",
  "oauth_provider": "google",
  "oauth_id": "123456789",
  "password": undefined
}
```

## トラブルシューティング

### エラー: "Cannot drop index"

インデックスが使用中の可能性があります。

**解決方法**:
1. すべてのバックエンドサーバーを停止
2. スクリプトを再実行

### エラー: "MONGODB_URI is not defined"

環境変数が設定されていません。

**解決方法**:
```bash
# .envファイルを確認
cat backend/.env

# MONGODB_URIが設定されているか確認
# 設定されていない場合は追加
echo "MONGODB_URI=mongodb+srv://..." >> backend/.env
```

### サーバー起動時にまだエラーが出る

**解決方法**:
1. スクリプトを実行: `npm run fix-oauth-index`
2. MongoDB Atlasのコンソールでインデックスを確認
3. 必要に応じて手動で削除・再作成

## まとめ

✅ **推奨**: `npm run fix-oauth-index`を実行  
✅ インデックスが`sparse: true`になっていることを確認  
✅ サーバーを再起動: `npm run dev`  
✅ エラーなく起動することを確認

これで、通常ユーザーとOAuthユーザーの両方が問題なく登録・ログインできるようになります！
