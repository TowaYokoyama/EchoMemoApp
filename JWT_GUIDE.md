# JWT (JSON Web Token) 運用ガイド

## 🔐 JWTとは？

JWT (JSON Web Token) は、ユーザー認証情報を安全に伝送するためのトークンベースの認証方式です。

### 構造
```
header.payload.signature
```

**例:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxMjM0NSJ9.signature
```

- **Header**: アルゴリズム情報
- **Payload**: ユーザー情報（userId, emailなど）
- **Signature**: 改ざん防止用署名

---

## 📋 EchoLogでの実装状況

### Backend設定

#### 環境変数 (.env)
```env
JWT_SECRET=4xftsxyc3q9IqJ5Lh7k2EnJ4WdAVDTAopjgfsHd0dL/qjh6znu2F4P2NbaI04OvzUZ9nL2goYfOeO/ngXWRlqw==
```
✅ セキュアなランダム文字列を使用

#### トークン生成
```typescript
// Access Token: 7日間有効
export const generateAccessToken = (userId: string, email: string): string => {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );
};

// Refresh Token: 30日間有効
export const generateRefreshToken = (userId: string): string => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET!,
    { expiresIn: '30d' }
  );
};
```

#### トークン検証ミドルウェア
```typescript
export const authenticate = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const token = authHeader.substring(7);
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    (req as any).userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

### Frontend (iOS/Swift)

#### トークン保存
```swift
// Keychainに安全に保存
KeychainManager.shared.saveToken(token)
```

#### API呼び出し時
```swift
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

---

## 🎯 推奨される運用方法

### 1. **二重トークン方式**

現在の実装:
- ✅ Access Token と Refresh Token を両方発行
- ⚠️ Access Token の有効期限が長すぎる (7日)

#### 推奨される設定

```typescript
// ⭐ より安全な設定
const ACCESS_TOKEN_EXPIRES_IN = '15m';   // 15分（短期）
const REFRESH_TOKEN_EXPIRES_IN = '7d';   // 7日（長期）
```

#### フロー図

```
【ログイン】
User → POST /api/auth/login
     ← { token: "xxx", refreshToken: "yyy" }

【API呼び出し】
App → GET /api/memos (Header: Bearer xxx)
    ← 200 OK { memos: [...] }

【トークン期限切れ】
App → GET /api/memos (Header: Bearer xxx)
    ← 401 Unauthorized

【トークン更新】
App → POST /api/auth/refresh { refreshToken: "yyy" }
    ← { token: "new_xxx" }

【Refresh Tokenも期限切れ】
App → POST /api/auth/refresh { refreshToken: "yyy" }
    ← 401 Unauthorized
    → ログイン画面へリダイレクト
```

---

## 🔧 実装すべき改善点

### 1. ⚠️ Access Tokenの有効期限を短縮

**現在:** 7日
**推奨:** 15分〜1時間

**理由:**
- トークンが盗まれた場合の被害を最小化
- Refresh Tokenで簡単に更新可能

**実装:**
```typescript
// backend/src/middleware/auth.ts

export const generateAccessToken = (userId: string, email: string): string => {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET!,
    { expiresIn: '15m' }  // 7d → 15m に変更
  );
};
```

---

### 2. ✅ Refresh Token ローテーション

**セキュリティ向上策:**
- Refresh Tokenを使用したら、新しいRefresh Tokenを発行
- 古いRefresh Tokenは無効化

**実装例:**
```typescript
export const refreshAccessToken = async (req: Request, res: Response): Promise<void> => {
  const { refreshToken } = req.body;
  
  // Refresh Token検証
  const decoded = verifyRefreshToken(refreshToken);
  
  // 新しいAccess Tokenを生成
  const newAccessToken = generateAccessToken(decoded.userId, user.email);
  
  // ⭐ 新しいRefresh Tokenも生成（ローテーション）
  const newRefreshToken = generateRefreshToken(decoded.userId);
  
  res.json({
    accessToken: newAccessToken,
    refreshToken: newRefreshToken  // 新しいRefresh Token
  });
};
```

---

### 3. 🗄️ Refresh Tokenのデータベース管理

**現在:** JWTのみ（stateless）
**推奨:** Refresh TokenをDBに保存

**メリット:**
- トークンの無効化が可能（ログアウト時）
- デバイスごとの管理
- 不正利用の検知

**実装例:**
```typescript
// MongoDB スキーマ
interface RefreshTokenDocument {
  userId: ObjectId;
  token: string;
  deviceId?: string;
  expiresAt: Date;
  createdAt: Date;
  revokedAt?: Date;  // 無効化時にセット
}

// ログアウト時
export const logout = async (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  
  await db.collection('refresh_tokens').updateOne(
    { token: refreshToken },
    { $set: { revokedAt: new Date() } }
  );
  
  res.json({ message: 'Logged out successfully' });
};
```

---

### 4. 📱 Frontend側の自動リフレッシュ

**実装すべき機能:**

```swift
// APIService.swift

func request<T: Decodable>(...) async throws -> T {
    do {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // ⭐ 401エラー時、自動的にトークンをリフレッシュ
        if httpResponse.statusCode == 401 {
            try await refreshToken()
            
            // 元のリクエストをリトライ
            return try await self.request(endpoint: endpoint, method: method, body: body)
        }
        
        // ...通常処理
    }
}

private func refreshToken() async throws {
    guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
        throw APIError.unauthorized
    }
    
    let response: RefreshResponse = try await request(
        endpoint: "/auth/refresh",
        method: .post,
        body: ["refreshToken": refreshToken],
        requiresAuth: false
    )
    
    // 新しいトークンを保存
    KeychainManager.shared.saveToken(response.accessToken)
    if let newRefreshToken = response.refreshToken {
        KeychainManager.shared.saveRefreshToken(newRefreshToken)
    }
}
```

---

## 🔒 セキュリティのベストプラクティス

### ✅ 現在実装済み

1. **HTTPS通信** (本番環境で必須)
2. **Keychainでの安全な保存** (iOS)
3. **環境変数でのシークレット管理**
4. **Authorization Headerでの送信**

### ⚠️ 追加すべき対策

5. **Access Tokenの有効期限短縮** (15分推奨)
6. **Refresh Tokenローテーション**
7. **Refresh TokenのDB管理**
8. **Rate Limiting** (ブルートフォース攻撃対策)
9. **Token Binding** (デバイスIDとの紐付け)

---

## 🚀 実装優先度

### 🔴 高優先度（すぐに実装）

1. **Access Token有効期限の短縮** (7d → 15m)
2. **Frontend自動リフレッシュ機能**
3. **Refresh Token保存機能** (KeychainManager)

### 🟡 中優先度（本番前に実装）

4. **Refresh Tokenローテーション**
5. **Logout機能の改善** (トークン無効化)
6. **Rate Limiting**

### 🟢 低優先度（将来的に実装）

7. **Refresh TokenのDB管理**
8. **デバイス管理機能**
9. **セッション管理画面**

---

## 📝 実装例

### Backend改善版

```typescript
// backend/src/middleware/auth.ts

// 環境変数で設定可能に
const ACCESS_TOKEN_EXPIRES = process.env.ACCESS_TOKEN_EXPIRES || '15m';
const REFRESH_TOKEN_EXPIRES = process.env.REFRESH_TOKEN_EXPIRES || '7d';

export const generateAccessToken = (userId: string, email: string): string => {
  return jwt.sign(
    { 
      userId, 
      email,
      type: 'access'  // トークンタイプを明示
    },
    process.env.JWT_SECRET!,
    { expiresIn: ACCESS_TOKEN_EXPIRES }
  );
};

export const generateRefreshToken = (userId: string): string => {
  return jwt.sign(
    { 
      userId,
      type: 'refresh'  // トークンタイプを明示
    },
    process.env.JWT_SECRET!,
    { expiresIn: REFRESH_TOKEN_EXPIRES }
  );
};

// Refresh Token検証時にタイプをチェック
export const verifyRefreshToken = (token: string): JwtPayload => {
  const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
  
  if (decoded.type !== 'refresh') {
    throw new Error('Invalid token type');
  }
  
  return decoded;
};
```

### Frontend改善版

```swift
// KeychainManager.swift に追加

func saveRefreshToken(_ token: String) {
    save(token, forKey: "refreshToken")
}

func getRefreshToken() -> String? {
    return get(forKey: "refreshToken")
}

func deleteAllTokens() {
    deleteToken()
    delete(forKey: "refreshToken")
}

private func save(_ value: String, forKey key: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}
```

---

## ✅ 現在の設定状態

| 項目 | 現在 | 推奨 | 状態 |
|-----|------|------|------|
| JWT_SECRET | ✅ ランダム文字列 | ✅ | 良好 |
| Access Token期限 | ⚠️ 7日 | 15分 | 要改善 |
| Refresh Token期限 | ✅ 30日 | 7日 | 調整推奨 |
| トークンローテーション | ❌ なし | ✅ 実装 | 要実装 |
| DB管理 | ❌ なし | ✅ 実装 | 将来実装 |
| 自動リフレッシュ | ❌ なし | ✅ 実装 | 要実装 |

---

## 🎓 まとめ

### JWTの基本原則

1. **短期Access Token** - セキュリティのため短く
2. **長期Refresh Token** - UXのため長く  
3. **HTTPSは必須** - トークン漏洩防止
4. **Keychainで保存** - iOS標準のセキュア保存
5. **定期的なローテーション** - セキュリティ向上

### EchoLogでの運用

現在の実装でも基本的には動作しますが、本番環境では:
- ✅ Access Token期限を15分に短縮
- ✅ 自動リフレッシュ機能を実装
- ✅ HTTPS通信を使用

これらを実装することで、セキュアで使いやすい認証システムになります！
