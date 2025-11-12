# EchoLog - Full Stack iOS App

音声メモをAIで賢く管理するiOSアプリケーション

## 📱 プロジェクト構成

```
Projects/
├── frontend/          # Swift/SwiftUI iOS アプリ
├── backend/           # Node.js/Express API サーバー
└── INTEGRATION.md     # Frontend-Backend統合ガイド
```

## 🚀 クイックスタート

### 1. Backendを起動

```bash
cd backend
npm install
echo "MONGODB_URI=your_mongodb_uri" > .env
echo "JWT_SECRET=your_secret" >> .env
npm run dev
```

### 2. Frontendをビルド

```bash
cd frontend
# Xcodeでプロジェクトを開く
open EchoLogApp.xcodeproj
```

## 🎯 主な機能

- 🎤 **音声録音**: 高品質な音声録音
- 📝 **自動文字起こし**: Whisper APIによる文字起こし
- 🤖 **AI提案**: GPTによる関連メモの発見
- 🔗 **スマートリンク**: メモ間の自動関連付け
- 🏷️ **自動タグ付け**: AI によるタグ抽出
- 📍 **位置情報**: メモへの場所の記録
- 🔄 **自動同期**: クラウドとの同期

## 📚 詳細ドキュメント

- [Frontend README](frontend/README.md) - iOS アプリの詳細
- [Backend README](backend/README.md) - API サーバーの詳細  
- [統合ガイド](INTEGRATION.md) - Frontend-Backend統合

## 🛠️ 技術スタック

### Frontend
- Swift 5.9+
- SwiftUI
- AVFoundation
- CoreLocation
- Keychain Services

### Backend
- Node.js / TypeScript
- Express.js
- MongoDB
- JWT認証
- OpenAI API

## 📄 ライセンス

MIT License
# EchoMemoApp
