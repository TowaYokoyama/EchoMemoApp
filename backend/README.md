# EchoLog Backend API

Node.js + Express + MongoDB バックエンドAPIサーバー

## 📋 概要

EchoLog React Nativeアプリ用のRESTful APIサーバーです。MongoDB Atlasクラスターへの安全な接続を提供し、音声メモのCRUD操作とEmbedding検索機能を実装しています。

## 🚀 セットアップ

### 前提条件

- Node.js 20.x以上
- MongoDB Atlasアカウント（無料M0クラスター）

### インストール

```bash
# 依存関係をインストール
npm install

# 環境変数を設定
cp .env.example .env
# .envファイルを編集してMONGODB_URIを設定
```

### 環境変数

`.env`ファイルに以下を設定:

```bash
# MongoDB Atlas接続URI
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/echolog?retryWrites=true&w=majority

# サーバーポート（デフォルト: 3000）
PORT=3000

# 環境（development / production）
NODE_ENV=development
```

### MongoDB Atlas設定

1. [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)で無料クラスター作成
2. データベースユーザーを作成
3. ネットワークアクセスで`0.0.0.0/0`を許可（開発環境用）
4. 接続URIをコピーして`.env`に設定

## 🏃 起動方法

### 開発モード（ホットリロード）

```bash
npm run dev
```

サーバーが`http://localhost:3000`で起動します。

### 本番ビルド

```bash
npm run build
npm start
```

## 📡 API エンドポイント

### ヘルスチェック

```
GET /health
```

**レスポンス:**
```json
{
  "status": "ok"
}
```

### メモ作成

```
POST /api/memos
```

**リクエストボディ:**
```json
{
  "audio_url": "https://example.com/audio.m4a",
  "transcription": "音声の文字起こしテキスト",
  "summary": "要約テキスト",
  "tags": ["タグ1", "タグ2"],
  "embedding": [0.1, 0.2, ...] // オプション（1536次元）
}
```

**レスポンス (201 Created):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "audio_url": "https://example.com/audio.m4a",
  "transcription": "音声の文字起こしテキスト",
  "summary": "要約テキスト",
  "tags": ["タグ1", "タグ2"],
  "embedding": [0.1, 0.2, ...],
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### メモ一覧取得

```
GET /api/memos?limit=10
```

**クエリパラメータ:**
- `limit` (オプション): 取得件数（デフォルト: 10、最大: 100）

**レスポンス (200 OK):**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "audio_url": "https://example.com/audio.m4a",
    "transcription": "音声の文字起こしテキスト",
    "summary": "要約テキスト",
    "tags": ["タグ1", "タグ2"],
    "created_at": "2024-01-01T00:00:00.000Z"
  }
]
```

### メモ詳細取得

```
GET /api/memos/:id
```

**レスポンス (200 OK):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "audio_url": "https://example.com/audio.m4a",
  "transcription": "音声の文字起こしテキスト",
  "summary": "要約テキスト",
  "tags": ["タグ1", "タグ2"],
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

**エラーレスポンス (404 Not Found):**
```json
{
  "error": "Memo not found"
}
```

### Embedding検索

```
POST /api/memos/search
```

**リクエストボディ:**
```json
{
  "embedding": [0.1, 0.2, ...], // 1536次元
  "limit": 5 // オプション（デフォルト: 5、最大: 50）
}
```

**レスポンス (200 OK):**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "audio_url": "https://example.com/audio.m4a",
    "transcription": "音声の文字起こしテキスト",
    "summary": "要約テキスト",
    "tags": ["タグ1", "タグ2"],
    "embedding": [0.1, 0.2, ...],
    "created_at": "2024-01-01T00:00:00.000Z",
    "similarity": 0.95
  }
]
```

## 🏗️ プロジェクト構造

```
backend/
├── src/
│   ├── index.ts              # エントリーポイント
│   ├── config/
│   │   └── database.ts       # MongoDB接続
│   ├── routes/
│   │   └── memos.ts          # ルート定義
│   ├── controllers/
│   │   └── memoController.ts # ビジネスロジック
│   ├── models/
│   │   └── memo.ts           # バリデーションスキーマ
│   ├── utils/
│   │   ├── errorHandler.ts  # エラーハンドリング
│   │   └── similarity.ts    # コサイン類似度計算
│   └── types/
│       └── index.ts          # 型定義
├── .env                      # 環境変数
├── .env.example              # 環境変数テンプレート
├── package.json
├── tsconfig.json
└── README.md
```

## 🔒 セキュリティ

- MongoDB接続情報はバックエンドのみで管理
- CORS有効化（開発環境）
- Zodによる入力バリデーション
- エラーメッセージに機密情報を含めない

## 🛠️ 技術スタック

- **Runtime**: Node.js 20.x
- **Framework**: Express 4.x
- **Database**: MongoDB Atlas
- **Language**: TypeScript 5.x
- **Validation**: Zod
- **Dev Tools**: tsx (TypeScript実行)

## 📝 開発

### TypeScriptコンパイル

```bash
npm run build
```

コンパイル結果は`dist/`ディレクトリに出力されます。

### ログ

すべてのリクエストがコンソールにログ出力されます:

```
[2024-01-01T00:00:00.000Z] POST /api/memos
[2024-01-01T00:00:01.000Z] GET /api/memos
```

## 🐛 トラブルシューティング

### MongoDB接続エラー

```
❌ MongoDB connection failed
```

**解決方法:**
1. `.env`の`MONGODB_URI`が正しいか確認
2. MongoDB Atlasでネットワークアクセスが許可されているか確認
3. データベースユーザーの認証情報が正しいか確認

### ポート使用中エラー

```
Error: listen EADDRINUSE: address already in use :::3000
```

**解決方法:**
1. 別のプロセスがポート3000を使用している
2. `.env`で別のポートを指定: `PORT=3001`

## 📄 ライセンス

MIT
# RN_VOICE_APP-backend
