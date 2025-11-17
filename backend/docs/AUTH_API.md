# 認証 API ドキュメント

## エンドポイント一覧

### 1. ユーザー登録（通常）
```
POST /api/auth/register
```

**リクエストボディ:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

---

### 2. OAuth ログイン/登録
```
POST /api/auth/oauth
```

**対応プロバイダー:**
- `google` - Google OAuth
- `apple` - Apple Sign In
- `github` - GitHub OAuth
- `twitter` - Twitter OAuth

**リクエストボディ:**
```json
{
  "email": "user@example.com",
  "oauth_provider": "google",
  "oauth_id": "google_user_id_12345"
}
```

**レスポンス:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "oauth_provider": "google",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**動作:**
- 既存ユーザーの場合: ログイン
- 新規ユーザーの場合: 自動登録してログイン

---

### 3. ログイン（通常）
```
POST /api/auth/login
```

**リクエストボディ:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

---

### 4. トークンリフレッシュ
```
POST /api/auth/refresh
```

**リクエストボディ:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**レスポンス:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 5. 現在のユーザー情報取得
```
GET /api/auth/me
```

**ヘッダー:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**レスポンス:**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "email": "user@example.com",
  "oauth_provider": "google",
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

---

## パフォーマンス最適化

### 1. データベースインデックス

以下のインデックスが自動的に作成されます：

```javascript
// メールアドレス（ユニーク）
db.users.createIndex({ email: 1 }, { unique: true })

// OAuth プロバイダー + OAuth ID（ユニーク、スパース）
db.users.createIndex(
  { oauth_provider: 1, oauth_id: 1 }, 
  { unique: true, sparse: true }
)
```

**効果:**
- メールアドレス検索が高速化（O(1)）
- 重複登録を防止
- OAuth ユーザーの検索も高速化

### 2. DB アクセスの最適化

- **Projection**: 必要なフィールドのみ取得
- **パスワード除外**: レスポンスにパスワードを含めない
- **単一クエリ**: 複数回のDB アクセスを削減

### 3. パスワードハッシュ

- bcrypt の saltRounds = 10（セキュリティとパフォーマンスのバランス）
- OAuth 時はハッシュ化をスキップ

---

## エラーハンドリング

### 400 Bad Request
```json
{
  "error": "Email already exists"
}
```

### 401 Unauthorized
```json
{
  "error": "Invalid email or password"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## セキュリティ

- JWT トークンは HS256 アルゴリズムで署名
- アクセストークン有効期限: 24時間
- リフレッシュトークン有効期限: 90日
- パスワードは bcrypt でハッシュ化
- MongoDB のユニークインデックスで重複防止
