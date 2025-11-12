# 環境変数設定ガイド

## 📋 概要

EchoLogアプリケーションは以下の環境変数を使用します。

## Backend環境変数 (.env)

### ✅ 必須の環境変数

#### 1. MongoDB接続

```bash
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/echolog
```

**現在の状態:** ✅ **設定済み**
- MongoDB Atlas クラスター接続済み
- Database: `echolog`
- 接続プール、インデックス作成も完備

**取得方法:**
1. [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) でアカウント作成
2. クラスターを作成
3. Database Access でユーザーを作成
4. Network Access でIPアドレスを許可
5. Connect → Connect your application → 接続文字列をコピー

---

#### 2. JWT認証シークレット

```bash
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
```

**現在の状態:** ✅ **設定済み** (デフォルト値)

⚠️ **本番環境では必ず変更してください！**

**推奨される生成方法:**
```bash
# ランダムな文字列を生成（macOS/Linux）
openssl rand -base64 32

# または
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

#### 3. OpenAI APIキー

```bash
OPENAI_API_KEY=sk-...
```

**現在の状態:** ❌ **未設定** (モック実装で動作)

**取得方法:**
1. [OpenAI Platform](https://platform.openai.com/) でアカウント作成
2. [API Keys](https://platform.openai.com/api-keys) ページへ移動
3. "Create new secret key" をクリック
4. キーをコピーして `.env` に貼り付け

**使用するAPI:**
- GPT-3.5-turbo: タイトル生成、タグ抽出
- Whisper-1: 音声文字起こし（今後実装予定）
- text-embedding-ada-002: メモの関連性分析（今後実装予定）

**料金:**
- GPT-3.5-turbo: $0.0015 / 1K tokens (入力), $0.002 / 1K tokens (出力)
- Whisper: $0.006 / minute
- [詳細な料金](https://openai.com/pricing)

---

### ⚙️ オプションの環境変数

#### サーバー設定

```bash
PORT=3000
NODE_ENV=development
```

**現在の状態:** ✅ 設定済み

---

## Frontend環境変数

Swift/SwiftUIアプリでは環境変数の代わりに定数を使用します。

**設定ファイル:** `/frontend/Core/Utilities/Constants.swift`

```swift
enum API {
    static let baseURL = "http://localhost:3000/api"  // 開発環境
    // static let baseURL = "https://your-production-api.com/api"  // 本番環境
}
```

**iOS Simulatorから接続する場合:**
- `localhost` または `127.0.0.1` が使用可能
- 実機でテストする場合は、MacのローカルIPアドレスを使用
  ```swift
  static let baseURL = "http://192.168.1.xxx:3000/api"
  ```

---

## 🚀 セットアップ手順

### 1. Backend環境変数を設定

```bash
cd /Users/yokoyamatowa/Projects/backend

# .envファイルを編集
nano .env

# 以下を設定（実際の値に置き換えてください）
MONGODB_URI=mongodb+srv://...
JWT_SECRET=ランダムな文字列
OPENAI_API_KEY=sk-...  # 任意（なくても動作します）
PORT=3000
NODE_ENV=development
```

### 2. 依存関係をインストール

```bash
npm install
```

### 3. サーバーを起動

```bash
npm run dev
```

### 4. 動作確認

```bash
# ヘルスチェック
curl http://localhost:3000/health

# 期待される出力: {"status":"ok"}
```

---

## 🔒 セキュリティのベストプラクティス

### ✅ すべきこと

1. **`.env` ファイルを `.gitignore` に追加**
   ```bash
   echo ".env" >> .gitignore
   ```

2. **本番環境では環境変数を使用**
   - Heroku: Config Vars
   - Vercel: Environment Variables
   - AWS: Systems Manager Parameter Store

3. **定期的にシークレットを変更**
   - JWT_SECRET
   - API Keys

4. **最小権限の原則**
   - MongoDBユーザーに必要最小限の権限のみ付与
   - OpenAI APIキーの使用制限を設定

### ❌ してはいけないこと

1. `.env` ファイルをGitにコミット
2. APIキーをコードにハードコード
3. 本番環境でデフォルトのシークレットを使用
4. APIキーを公開リポジトリに含める

---

## 🧪 テスト用の設定

OpenAI APIキーがない場合でも、アプリは動作します：

- **タイトル生成**: 最初の文を使用（簡易実装）
- **タグ抽出**: 頻出単語ベース（簡易実装）
- **文字起こし**: モックレスポンス

実際のAI機能を試すには、OpenAI APIキーが必要です。

---

## 📞 トラブルシューティング

### MongoDB接続エラー

```
❌ MongoDB connection failed
```

**解決方法:**
1. MONGODB_URIが正しいか確認
2. MongoDB Atlasでネットワークアクセスを許可
3. ユーザー名とパスワードが正しいか確認

### OpenAI APIエラー

```
OpenAI API error: Invalid API key
```

**解決方法:**
1. OPENAI_API_KEYが正しいか確認
2. OpenAI Platformで使用量と制限を確認
3. APIキーが有効か確認

### JWT認証エラー

```
Invalid token
```

**解決方法:**
1. JWT_SECRETが設定されているか確認
2. トークンの有効期限を確認（デフォルト: 7日間）
3. フロントエンドとバックエンドでトークンが一致しているか確認

---

## ✅ 現在の設定状態

| 環境変数 | 状態 | 備考 |
|---------|------|------|
| MONGODB_URI | ✅ 設定済み | MongoDB Atlas接続中 |
| JWT_SECRET | ✅ 設定済み | デフォルト値（本番環境では変更必要） |
| OPENAI_API_KEY | ⚠️ 未設定 | モック実装で動作中 |
| PORT | ✅ 設定済み | 3000 |
| NODE_ENV | ✅ 設定済み | development |

**OpenAI APIキーを設定すると、以下の機能が有効になります:**
- ✨ GPTによる高度なタイトル生成
- 🏷️ AIベースのタグ抽出
- 🎯 （今後）Whisper APIによる音声文字起こし
- 🔗 （今後）Embeddingによるメモの関連性分析
