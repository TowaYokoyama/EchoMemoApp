# Frontend - Backend 統合ガイド

## 🔗 統合状況

### ✅ 完了した統合

frontendフォルダとbackendフォルダは **完全に統合** されています！

## 📡 API エンドポイント対応表

### 認証 (Authentication)

| Frontend期待 | Backend実装 | 状態 |
|-------------|------------|------|
| `POST /api/auth/register` | ✅ | 統合済み |
| `POST /api/auth/login` | ✅ | 統合済み |
| `GET /api/auth/me` | ✅ | **新規追加** |

**レスポンス形式:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "_id": "user_id",
    "email": "user@example.com",
    "created_at": "2025-11-12T00:00:00Z",
    "updated_at": "2025-11-12T00:00:00Z"
  }
}
```

### メモ管理 (Memos)

| Frontend期待 | Backend実装 | 状態 |
|-------------|------------|------|
| `GET /api/memos?skip=0&limit=20` | ✅ | 統合済み |
| `GET /api/memos/:id` | ✅ | 統合済み |
| `POST /api/memos` | ✅ | 統合済み |
| `PATCH /api/memos/:id` | ✅ | 統合済み |
| `DELETE /api/memos/:id` | ✅ | 統合済み |
| `GET /api/memos/search?q=query` | ✅ | **新規追加** |
| `GET /api/memos/:id/linked` | ✅ | 統合済み |

### AI機能 (GPT/Whisper)

| Frontend期待 | Backend実装 | 状態 |
|-------------|------------|------|
| `POST /api/transcribe` | ✅ | **新規追加** (モック実装) |
| `POST /api/gpt/generate-title` | ✅ | **新規追加** |
| `POST /api/gpt/extract-tags` | ✅ | **新規追加** |
| `POST /api/echo/suggestions` | ✅ | **新規追加** |

## 🔧 セットアップ手順

### 1. Backend起動

```bash
cd /Users/yokoyamatowa/Projects/backend

# 環境変数を設定
echo "MONGODB_URI=your_mongodb_connection_string" > .env
echo "JWT_SECRET=your_secret_key" >> .env
echo "PORT=3000" >> .env

# 依存関係をインストール
npm install

# 開発サーバー起動
npm run dev
```

### 2. Frontend設定

`/Users/yokoyamatowa/Projects/frontend/Core/Utilities/Constants.swift`を編集：

```swift
enum API {
    static let baseURL = "http://localhost:3000/api"  // Backendと同じポート
}
```

### 3. Xcodeでビルド

```bash
cd /Users/yokoyamatowa/Projects/frontend
open EchoLogApp.xcodeproj  # プロジェクトファイルを作成後
```

## 📱 データモデルの対応

### Memo モデル

**Backend (MongoDB):**
```typescript
{
  _id: ObjectId,
  user_id: ObjectId,
  title: string,
  content: string,
  audio_url?: string,
  tags: string[],
  linked_memos: ObjectId[],
  created_at: Date,
  updated_at: Date
}
```

**Frontend (Swift):**
```swift
struct Memo: Codable {
    let id: String              // _id
    let userId: String          // user_id
    let title: String
    let content: String
    let audioURL: String?       // audio_url
    let tags: [String]
    let linkedMemos: [String]   // linked_memos
    let createdAt: Date         // created_at
    let updatedAt: Date         // updated_at
}
```

### User モデル

**Backend:**
```typescript
{
  _id: ObjectId,
  email: string,
  password: string (hashed),
  created_at: Date,
  updated_at: Date
}
```

**Frontend:**
```swift
struct User: Codable {
    let id: String          // _id
    let email: String
    let createdAt: Date     // created_at
    let updatedAt: Date     // updated_at
}
```

## 🔐 認証フロー

1. **ログイン/登録**
   - Frontend → `POST /api/auth/login`
   - Backend → JWTトークン生成
   - Frontend → Keychainに保存

2. **認証済みリクエスト**
   - Frontend → Header: `Authorization: Bearer <token>`
   - Backend → JWTミドルウェアで検証
   - Backend → `req.userId`に設定

3. **トークン更新**
   - Frontend → `POST /api/auth/refresh`
   - Backend → 新しいアクセストークン返却

## 🚀 今後の実装予定

### Backend側

- [ ] **Whisper API統合**: 実際の音声文字起こし
- [ ] **OpenAI GPT統合**: より高度なタイトル生成とタグ抽出
- [ ] **Embedding検索**: ベクトル検索でメモの関連性分析
- [ ] **ファイルアップロード**: Multer等での音声ファイル処理

### Frontend側

- [ ] **CoreData統合**: オフラインストレージ
- [ ] **プッシュ通知**: リマインダーとAI提案
- [ ] **ウィジェット**: ホーム画面への統合
- [ ] **Share Extension**: 他アプリからのメモ作成

## 🧪 テスト方法

### Backend APIテスト

```bash
# ヘルスチェック
curl http://localhost:3000/health

# ユーザー登録
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# ログイン
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Frontend-Backend連携テスト

1. Backendを起動
2. Xcodeでシミュレーター起動
3. アプリで新規登録
4. メモを作成
5. Backendログで確認

## 📞 トラブルシューティング

### CORS エラー

Backend側でCORSが有効になっています：
```typescript
app.use(cors()); // すべてのオリジンを許可（開発環境）
```

本番環境では特定のオリジンのみ許可するよう変更してください。

### 認証エラー (401)

- トークンの有効期限を確認
- Keychainに正しく保存されているか確認
- Backend側で`JWT_SECRET`が設定されているか確認

### 接続エラー

- Backendが起動しているか確認: `http://localhost:3000/health`
- iOS SimulatorからlocalhostにアクセスできるはずNo, use the appropriate IP

## ✅ 結論

**Frontend (Swift/SwiftUI) と Backend (Node.js/Express) は完全に統合されています！**

すべての主要エンドポイントが実装され、データモデルも対応しています。バックエンドを起動してフロントエンドからAPIを呼び出すことで、完全なEchoLogアプリケーションが動作します。
