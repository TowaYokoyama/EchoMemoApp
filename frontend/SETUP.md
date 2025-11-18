# EchoLog フロントエンド セットアップガイド

## ✅ 完了した設定

### 1. プロジェクト構成
- ✅ XcodeGenでプロジェクト再生成完了
- ✅ AppleSignInService.swiftがプロジェクトに追加
- ✅ entitlementsファイルにSign in with Apple設定追加

### 2. OAuth機能
- ✅ Apple Sign In UI実装
- ✅ Google Sign In UI実装（構造準備済み）
- ✅ バックエンド連携完了

## 🚀 Xcodeでの起動手順

### 1. Xcodeでプロジェクトを開く

```bash
cd frontend
open EchoLogApp.xcodeproj
```

### 2. 開発チームを設定

1. プロジェクトナビゲーターで**EchoLogApp**を選択
2. **Signing & Capabilities**タブを開く
3. **Team**ドロップダウンから自分のApple Developer Teamを選択
4. **Automatically manage signing**にチェック

### 3. Bundle Identifierの確認

- デフォルト: `com.echolog.app`
- 必要に応じて変更可能（Apple Developer Consoleと一致させる）

### 4. Capabilitiesの確認

**Signing & Capabilities**タブで以下が設定されていることを確認：

- ✅ **Sign in with Apple** - 自動的に追加済み

追加されていない場合：
1. **+ Capability**をクリック
2. **Sign in with Apple**を検索して追加

### 5. シミュレーターまたは実機を選択

#### シミュレーター
- iPhone 15 Pro推奨
- iOS 16.0以上

#### 実機
- Apple Sign Inは実機でのテストを推奨
- 開発者証明書が必要

### 6. ビルドと実行

1. **Product > Build** (⌘B) でビルド
2. **Product > Run** (⌘R) で実行

## 🔧 Apple Developer設定

### 必須設定

1. **Apple Developer Console**にアクセス
   - https://developer.apple.com/account

2. **Certificates, Identifiers & Profiles**を開く

3. **Identifiers**を選択

4. アプリのBundle ID（`com.echolog.app`）を選択または作成

5. **Sign in with Apple**にチェック

6. **Save**をクリック

### 注意事項

- Bundle IDはXcodeの設定と一致させる
- 変更後、Xcodeでプロジェクトをクリーンビルド（⇧⌘K）

## 📱 バックエンド接続設定

### 自動切り替え

`APIService.swift`で自動的にURLが切り替わります：

```swift
#if targetEnvironment(simulator)
self.baseURL = "http://localhost:3000/api"  // シミュレーター
#else
self.baseURL = "http://192.168.0.15:3000/api"  // 実機
#endif
```

### バックエンドサーバーの起動

```bash
cd backend
npm run dev
```

サーバーが以下で起動します：
- ローカル: `http://localhost:3000`
- ネットワーク: `http://192.168.0.15:3000`

### 実機テスト時の注意

1. **同じWi-Fiネットワークに接続**
   - MacとiPhoneを同じネットワークに接続

2. **IPアドレスの確認**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   
3. **必要に応じてIPアドレスを更新**
   - `frontend/Core/Services/APIService.swift`の`baseURL`を更新

## 🧪 テスト手順

### 1. 通常のログイン/登録

1. アプリを起動
2. メールアドレスとパスワードを入力
3. **ログイン**または**登録**をタップ
4. ホーム画面に遷移

### 2. Apple Sign In

1. アプリを起動
2. **Appleでログイン**をタップ
3. Face ID/Touch IDで認証
4. 初回: Apple IDの確認画面
5. 自動的にログイン完了

### 3. Google Sign In（準備中）

現在は「Google Sign Inは準備中です」というメッセージが表示されます。

## 🐛 トラブルシューティング

### エラー: "Cannot find 'AppleSignInService' in scope"

**解決方法:**
```bash
cd frontend
xcodegen generate
```

Xcodeでプロジェクトを再度開く。

### エラー: "No such module 'AuthenticationServices'"

**解決方法:**
1. Xcodeでプロジェクトをクリーン（⇧⌘K）
2. ビルドフォルダを削除（⇧⌘K → Option押しながら）
3. 再ビルド（⌘B）

### Apple Sign Inが動作しない

**確認事項:**
1. ✅ Capabilitiesに"Sign in with Apple"が追加されているか
2. ✅ Apple Developer ConsoleでBundle IDが設定されているか
3. ✅ 実機でテストしているか（シミュレーターでは動作しない場合がある）
4. ✅ インターネット接続があるか

### バックエンドに接続できない

**シミュレーターの場合:**
```bash
# バックエンドが起動しているか確認
curl http://localhost:3000/health
# 期待される結果: {"status":"ok"}
```

**実機の場合:**
```bash
# MacのIPアドレスを確認
ifconfig | grep "inet " | grep -v 127.0.0.1

# 実機から接続できるか確認（iPhoneのSafariで）
http://192.168.0.15:3000/health
```

## 📚 関連ドキュメント

- [OAuth統合ガイド](docs/OAUTH_INTEGRATION.md)
- [バックエンド統合ガイド](../backend/docs/XCODE_INTEGRATION.md)
- [OAuth実装状況](../OAUTH_STATUS.md)

## ✅ チェックリスト

起動前に以下を確認：

- [ ] XcodeGenでプロジェクト生成済み
- [ ] Xcodeで開発チームを設定
- [ ] Sign in with Apple Capabilityが追加済み
- [ ] Apple Developer ConsoleでBundle ID設定済み
- [ ] バックエンドサーバーが起動中
- [ ] 同じWi-Fiネットワークに接続（実機の場合）

すべてチェックできたら、Xcodeで実行（⌘R）！

## 🎉 完了

これで、EchoLogアプリがApple Sign In機能付きで起動できます！

ユーザーはワンタップでログインできるようになりました。
