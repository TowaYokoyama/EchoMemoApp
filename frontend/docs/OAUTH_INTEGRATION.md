# OAuth統合ガイド

## 概要
EchoLogアプリにApple Sign InとGoogle Sign In機能を追加しました。

## 実装状況

### ✅ 完了した機能

#### 1. バックエンド（既存）
- `/api/auth/oauth` エンドポイント実装済み
- OAuth プロバイダー（Apple、Google）のサポート
- ユーザーの自動作成または既存ユーザーへのログイン

#### 2. フロントエンド（新規追加）

##### UI
- **LoginView**: Apple/Googleログインボタンを追加
- **RegisterView**: Apple/Googleで登録ボタンを追加
- デザイン: 各プロバイダーのブランドガイドラインに準拠

##### サービス層
- **AppleSignInService**: Apple Sign In実装
  - AuthenticationServicesフレームワークを使用
  - Nonce生成とSHA256ハッシュ化
  - ユーザー情報（ID、メール、名前）の取得

- **AuthService**: OAuth認証メソッド追加
  - `oauthLogin()`: バックエンドのOAuthエンドポイントと連携

##### ViewModel
- **AuthViewModel**: OAuth認証メソッド追加
  - `loginWithApple()`: Apple Sign In処理
  - `loginWithGoogle()`: Google Sign In処理（準備中）

## セットアップ手順

### 1. Xcodeプロジェクト設定

#### Apple Sign Inの有効化

1. **Signing & Capabilities**タブを開く
2. **+ Capability**をクリック
3. **Sign in with Apple**を追加

#### Info.plistの設定（必要に応じて）

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>echolog</string>
        </array>
    </dict>
</array>
```

### 2. Apple Developer設定

1. **Apple Developer Console**にアクセス
2. **Certificates, Identifiers & Profiles**を開く
3. **Identifiers**でアプリのBundle IDを選択
4. **Sign in with Apple**を有効化
5. 保存

### 3. Google Sign In設定（今後の実装）

Google Sign Inを実装する場合：

1. **Google Cloud Console**でプロジェクトを作成
2. **OAuth 2.0 Client ID**を作成
3. **GoogleSignIn SDK**をインストール
   ```bash
   # Swift Package Manager
   https://github.com/google/GoogleSignIn-iOS
   ```

## 使用方法

### ユーザー視点

1. **ログイン画面**を開く
2. **Appleでログイン**または**Googleでログイン**をタップ
3. プロバイダーの認証画面で承認
4. 自動的にアプリにログイン

### 初回ログイン時
- バックエンドに新しいユーザーが自動作成される
- メールアドレスとOAuth IDが保存される
- パスワードは不要

### 2回目以降
- 既存のユーザーとして自動的にログイン
- 同じOAuth IDで識別

## データフロー

```
1. ユーザーがボタンをタップ
   ↓
2. AppleSignInService.signIn()
   - Apple認証画面を表示
   - ユーザーが承認
   - OAuth ID、メール、名前を取得
   ↓
3. AuthService.oauthLogin()
   - バックエンドに送信
   POST /api/auth/oauth
   {
     "email": "user@example.com",
     "oauth_provider": "apple",
     "oauth_id": "001234.abc..."
   }
   ↓
4. バックエンド処理
   - 既存ユーザーを検索
   - いない場合は新規作成
   - アクセストークンとリフレッシュトークンを生成
   ↓
5. トークンを保存
   - Keychainに保存
   - ユーザー情報をキャッシュ
   ↓
6. ログイン完了
   - isAuthenticated = true
   - ホーム画面に遷移
```

## セキュリティ

### Apple Sign In
- **Nonce**: ランダムな文字列を生成してリプレイ攻撃を防止
- **SHA256**: Nonceをハッシュ化してAppleに送信
- **Private Relay**: ユーザーが選択した場合、実際のメールアドレスを隠す

### バックエンド
- **OAuth ID**: プロバイダーごとにユニーク
- **ユニークインデックス**: `oauth_provider` + `oauth_id`の組み合わせ
- **JWT**: アクセストークンとリフレッシュトークンで認証

## トラブルシューティング

### Apple Sign Inが動作しない

1. **Capabilityが有効か確認**
   - Xcode > Signing & Capabilities
   - "Sign in with Apple"が追加されているか

2. **Bundle IDが正しいか確認**
   - Apple Developer Consoleの設定と一致しているか

3. **実機でテスト**
   - シミュレーターでは動作しない場合がある
   - 実機でテストすることを推奨

### エラーメッセージ

#### "Invalid state: A login callback was received..."
- Nonceの生成に失敗
- アプリを再起動して再試行

#### "Email already exists with different provider"
- 同じメールアドレスが別のプロバイダーで登録済み
- 元のプロバイダーでログインするか、別のメールアドレスを使用

## 今後の拡張

### Google Sign In実装

1. **GoogleSignIn SDKをインストール**
   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
   ]
   ```

2. **GoogleSignInService.swift作成**
   ```swift
   import GoogleSignIn
   
   class GoogleSignInService {
       func signIn() async throws -> (String, String, String?) {
           // Google Sign In実装
       }
   }
   ```

3. **AuthViewModel更新**
   ```swift
   func loginWithGoogle() async {
       let (oauthId, email, name) = try await GoogleSignInService.shared.signIn()
       let response = try await AuthService.shared.oauthLogin(
           provider: "google",
           oauthId: oauthId,
           email: email
       )
       // ...
   }
   ```

### その他のプロバイダー
- Facebook Login
- Twitter/X Login
- LINE Login

## まとめ

✅ **バックエンド**: OAuth機能実装済み  
✅ **フロントエンド**: Apple Sign In実装完了  
🔄 **Google Sign In**: 準備中（構造は実装済み）  
✅ **UI**: ログイン・登録画面にボタン追加  
✅ **セキュリティ**: Nonce、SHA256、JWT実装

ユーザーはメールアドレスとパスワードを入力せずに、ワンタップでログインできるようになりました！
