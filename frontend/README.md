# EchoLog - Swift/SwiftUI Frontend

EchoLogのiOSアプリケーション（Swift/SwiftUI実装）

## 📱 概要

EchoLogは、音声メモを録音・文字起こしし、AIによって自動的に関連付けや洞察を提供するスマートメモアプリです。

## 🏗️ アーキテクチャ

### ディレクトリ構造

```
frontend/
├── EchoLogApp/              # アプリケーションエントリーポイント
│   └── EchoLogApp.swift
├── Core/                    # コアモジュール
│   ├── Models/             # データモデル
│   │   ├── Memo.swift
│   │   ├── User.swift
│   │   ├── AuthToken.swift
│   │   └── EchoSuggestion.swift
│   ├── Services/           # ビジネスロジック
│   │   ├── APIService.swift
│   │   ├── AuthService.swift
│   │   ├── MemoService.swift
│   │   ├── AudioService.swift
│   │   ├── OpenAIService.swift
│   │   ├── SyncManager.swift
│   │   └── LocationService.swift
│   ├── Utilities/          # ユーティリティ
│   │   ├── KeychainManager.swift
│   │   ├── NetworkMonitor.swift
│   │   └── Constants.swift
│   └── Extensions/         # Swift拡張
│       ├── Date+Extensions.swift
│       ├── Color+Extensions.swift
│       └── View+Extensions.swift
├── Features/               # 機能別モジュール
│   ├── Authentication/     # 認証機能
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   └── RegisterView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   ├── Home/              # ホーム画面
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── MemoCardView.swift
│   │   │   └── TagFilterView.swift
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   ├── Recording/         # 録音機能
│   ├── MemoDetail/        # メモ詳細
│   ├── Search/            # 検索機能
│   └── EchoAssistant/     # AIアシスタント
├── Persistence/           # データ永続化
└── Tests/                 # テストコード
```

## 🚀 主な機能

### 実装済み

- ✅ **認証機能**: ログイン・新規登録
- ✅ **メモ管理**: CRUD操作、タグ管理
- ✅ **音声録音**: AVFoundationを使用した録音機能
- ✅ **音声再生**: オーディオプレーヤー
- ✅ **同期管理**: バックエンドとの自動同期
- ✅ **ネットワーク監視**: オンライン/オフライン検知
- ✅ **位置情報**: メモへの位置情報付与
- ✅ **セキュア保存**: Keychainを使用した認証トークン管理

### 今後実装予定

- 🔄 **音声文字起こし**: Whisper API統合
- 🔄 **AIアシスタント**: GPTによる関連メモ提案
- 🔄 **オフライン対応**: CoreDataを使用したローカル保存
- 🔄 **プッシュ通知**: リマインダーと提案通知
- 🔄 **ジオフェンス**: 場所に基づく通知

## 🛠️ 技術スタック

- **言語**: Swift 5.9+
- **フレームワーク**: SwiftUI
- **iOS**: iOS 16.0+
- **アーキテクチャ**: MVVM
- **非同期処理**: async/await, Combine
- **ネットワーク**: URLSession
- **音声**: AVFoundation
- **位置情報**: CoreLocation
- **セキュリティ**: Keychain Services

## 📦 依存関係

現在、外部ライブラリの依存はありません。すべてApple標準フレームワークで実装されています。

将来的に検討中：
- Swift Package Manager for dependency management
- Alamofire (ネットワーキング)
- Realm/CoreData (オフラインストレージ)

## 🔧 セットアップ

### 前提条件

- macOS Ventura 13.0以降
- Xcode 15.0以降
- iOS 16.0以降のデバイスまたはシミュレーター

### インストール手順

1. リポジトリのクローン
```bash
cd /Users/yokoyamatowa/Projects/frontend
```

2. Xcodeでプロジェクトを開く
```bash
open EchoLogApp.xcodeproj
```

3. バックエンドAPIのURLを設定
`Core/Utilities/Constants.swift`を編集：
```swift
enum API {
    static let baseURL = "http://localhost:3000/api"  // 実際のAPIのURLに変更
}
```

4. ビルド＆実行
- シミュレーターまたは実機を選択
- `⌘R`でビルド＆実行

## 🔐 セキュリティ

- 認証トークンはKeychainに安全に保存
- HTTPS通信（本番環境）
- ユーザーデータの暗号化
- App Transport Securityの適切な設定

## 📱 対応デバイス

- iPhone (iOS 16.0+)
- iPad (iPadOS 16.0+)

## 🧪 テスト

```bash
# ユニットテストの実行
⌘U

# UIテストの実行
⌘U (UIテストスキームを選択)
```

## 🤝 バックエンド統合

このフロントエンドは`/backend`フォルダのNode.js/Express APIと連携します。

### API エンドポイント

- `POST /api/auth/login` - ログイン
- `POST /api/auth/register` - 新規登録
- `GET /api/auth/me` - ユーザー情報取得
- `GET /api/memos` - メモ一覧取得
- `POST /api/memos` - メモ作成
- `PATCH /api/memos/:id` - メモ更新
- `DELETE /api/memos/:id` - メモ削除
- `POST /api/transcribe` - 音声文字起こし
- `POST /api/echo/suggestions` - AI提案取得

## 📄 ライセンス

MIT License

## 👥 コントリビューター

開発中のプロジェクトです。

## 📞 お問い合わせ

プロジェクトに関する質問や提案は、GitHubのIssueまでお願いします。
