# 🚨 クイックフィックス: OAuth インデックスエラー

## 問題

バックエンドサーバー起動時のエラー：
```
E11000 duplicate key error collection: echolog.users 
index: oauth_provider_1_oauth_id_1 
dup key: { oauth_provider: null, oauth_id: null }
```

## 解決方法（3ステップ）

### 1️⃣ 修正スクリプトを実行

```bash
cd backend
npm run fix-oauth-index
```

### 2️⃣ サーバーを再起動

```bash
npm run dev
```

### 3️⃣ 確認

以下のメッセージが表示されればOK：
```
✅ Connected to MongoDB Atlas
✅ Created unique sparse index: oauth_provider_1_oauth_id_1
✅ All indexes created successfully
🚀 Server running on:
   Local:   http://localhost:3000
```

## 詳細

詳しい説明は以下を参照：
- [backend/docs/FIX_OAUTH_INDEX.md](backend/docs/FIX_OAUTH_INDEX.md)

## 完了後

✅ バックエンドサーバーが正常に起動  
✅ 通常ログイン（メール/パスワード）が動作  
✅ OAuth ログイン（Apple/Google）が動作  
✅ Xcodeからアプリを実行可能

---

**所要時間**: 約1分
