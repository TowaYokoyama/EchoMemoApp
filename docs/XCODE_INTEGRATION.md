# Xcode統合ガイド

## 改善されたAI機能の確認方法

### 1. バックエンドサーバーの起動確認

バックエンドサーバーが以下のアドレスで起動しています：

- **ローカル（シミュレーター用）**: `http://localhost:3000`
- **ネットワーク（実機用）**: `http://192.168.0.15:3000`

### 2. フロントエンド（Xcode）の設定

`frontend/Core/Services/APIService.swift`で自動的にURLが切り替わります：

```swift
#if targetEnvironment(simulator)
self.baseURL = "http://localhost:3000/api"
#else
self.baseURL = "http://192.168.0.15:3000/api"
#endif
```

### 3. 改善されたAI機能のエンドポイント

すべてのエンドポイントは認証が必要です（`Authorization: Bearer <token>`）

#### 音声文字起こし
```
POST /api/transcribe
Content-Type: multipart/form-data
Body: file (audio file)
```

#### タイトル生成（キャッシュ対応）
```
POST /api/gpt/generate-title
Content-Type: application/json
Body: { "content": "メモの内容" }
```

#### タグ抽出（キャッシュ対応）
```
POST /api/gpt/extract-tags
Content-Type: application/json
Body: { "content": "メモの内容" }
```

#### 日時抽出
```
POST /api/gpt/extract-datetime
Content-Type: application/json
Body: { "content": "明日の10時に会議" }
```

#### Echo提案生成
```
POST /api/echo/suggestions
Content-Type: application/json
Body: { "memoIds": ["id1", "id2", ...] }
```

### 4. Xcodeでのテスト手順

1. **Xcodeでプロジェクトを開く**
   ```bash
   cd frontend
   open EchoLogApp.xcodeproj
   ```

2. **シミュレーターまたは実機を選択**
   - シミュレーター: 自動的に`localhost:3000`に接続
   - 実機: 自動的に`192.168.0.15:3000`に接続

3. **アプリを実行**
   - ログイン/登録を実行
   - メモを作成（音声録音または手動入力）
   - AI機能が自動的に呼び出されます

4. **改善点の確認**
   - **キャッシュ**: 同じ内容のメモを2回作成すると、2回目は即座にレスポンス
   - **エラーハンドリング**: エラーメッセージが統一されて分かりやすい
   - **パフォーマンス**: レスポンス時間が大幅に短縮

### 5. デバッグログの確認

#### バックエンド（ターミナル）
```bash
cd backend
npm run dev
```

以下のようなログが表示されます：
```
✅ OpenAI API configured successfully
🚀 Server running on:
   Local:   http://localhost:3000
   Network: http://192.168.0.15:3000
```

AI機能使用時：
```
✨ Cache hit: title generation  # キャッシュヒット
🎤 Starting transcription service
✅ Transcription successful
```

#### フロントエンド（Xcode Console）
```
📡 API Request: POST http://localhost:3000/api/gpt/generate-title
📥 Response: 200
✅ Successfully decoded response
```

### 6. トラブルシューティング

#### 接続できない場合

1. **バックエンドが起動しているか確認**
   ```bash
   curl http://localhost:3000/health
   # 期待される結果: {"status":"ok"}
   ```

2. **実機の場合、同じWi-Fiに接続しているか確認**
   - Mac: Wi-Fi設定でIPアドレスを確認
   - iPhone: 同じネットワークに接続

3. **ファイアウォールの確認**
   ```bash
   # macOSのファイアウォール設定を確認
   # システム設定 > ネットワーク > ファイアウォール
   ```

#### 認証エラーの場合

1. **トークンが保存されているか確認**
   - Xcodeでログイン画面からログイン
   - `KeychainManager`がトークンを保存

2. **トークンの有効期限を確認**
   - アクセストークン: 15分
   - リフレッシュトークン: 7日間
   - 自動リフレッシュ機能が動作

### 7. パフォーマンス比較

#### キャッシュなし（初回）
```
タイトル生成: ~2秒
タグ抽出: ~2秒
```

#### キャッシュあり（2回目以降）
```
タイトル生成: ~10ms（200倍高速）
タグ抽出: ~10ms（200倍高速）
```

### 8. 次のステップ

改善されたAI機能を活用して、以下の機能を実装できます：

1. **リアルタイムプレビュー**
   - メモ入力中にタイトルとタグを自動生成

2. **バッチ処理**
   - 複数のメモを一度に処理

3. **カスタマイズ**
   - ユーザーごとのAI設定（温度、モデルなど）

4. **分析ダッシュボード**
   - キャッシュヒット率
   - API使用状況
   - レスポンス時間

## まとめ

✅ バックエンドサーバーが起動中  
✅ AI機能が改善され、キャッシュ対応  
✅ エラーハンドリングが統一  
✅ Xcodeから自動的に接続  
✅ シミュレーター・実機の両方に対応

Xcodeでアプリを実行すれば、改善されたAI機能が自動的に使用されます！
