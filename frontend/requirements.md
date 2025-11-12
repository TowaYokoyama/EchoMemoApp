# Requirements Document

## Introduction

EchoLog SwiftUIアプリは、既存のReact Native版EchoLogアプリをSwiftUIで再実装したiOSネイティブアプリケーションです。音声録音、文字起こし、メモ管理、AI支援機能を提供し、既存のバックエンドAPI（http://localhost:3000）と連携します。OpenAI APIを使用して音声認識、要約生成、タグ付け、セマンティック検索を実現します。

## Glossary

- **EchoLog System**: 音声メモ管理アプリケーション全体を指すシステム
- **Backend API**: http://localhost:3000で動作する既存のRESTful APIサーバー
- **OpenAI API**: 音声認識（Whisper）、テキスト処理（GPT）、Embedding生成を提供する外部API
- **Audio Recording Module**: iOSのAVFoundationを使用した音声録音機能
- **Memo**: 音声録音、文字起こし、要約、タグ、Embeddingを含むデータモデル
- **Authentication Module**: JWT認証を使用したユーザー認証機能
- **Sync Manager**: オフライン対応とバックエンド同期を管理するモジュール
- **Echo Assistant**: 過去のメモとの関連性を提案するAI支援機能
- **Reminder System**: 日時抽出と通知スケジューリング機能

## Requirements

### Requirement 1: ユーザー認証

**User Story:** アプリ利用者として、メールアドレスとパスワードでアカウントを作成・ログインし、自分のメモを安全に管理したい

#### Acceptance Criteria

1. WHEN ユーザーがメールアドレスとパスワードを入力して登録ボタンを押す, THE Authentication Module SHALL Backend APIの`/api/auth/register`エンドポイントにPOSTリクエストを送信する
2. WHEN Backend APIが認証成功レスポンス（accessToken, refreshToken）を返す, THE Authentication Module SHALL トークンをiOSのKeychainに安全に保存する
3. WHEN ユーザーがログインボタンを押す, THE Authentication Module SHALL Backend APIの`/api/auth/login`エンドポイントに認証情報を送信する
4. WHEN accessTokenの有効期限が切れる, THE Authentication Module SHALL refreshTokenを使用して`/api/auth/refresh`エンドポイントから新しいaccessTokenを自動取得する
5. THE Authentication Module SHALL すべてのAPI リクエストのAuthorizationヘッダーに`Bearer {accessToken}`を自動付与する

### Requirement 2: 音声録音と再生

**User Story:** アプリ利用者として、ボタンを押して音声を録音し、保存された音声を再生できるようにしたい

#### Acceptance Criteria

1. WHEN ユーザーが録音ボタンを押す, THE Audio Recording Module SHALL iOSのマイク権限をリクエストする
2. WHEN マイク権限が許可される, THE Audio Recording Module SHALL AVAudioRecorderを使用してm4a形式で音声録音を開始する
3. WHILE 録音中, THE Audio Recording Module SHALL 録音時間をリアルタイムで表示する
4. WHEN ユーザーが停止ボタンを押す, THE Audio Recording Module SHALL 録音を停止し、音声ファイルのローカルURLを返す
5. WHEN ユーザーがメモ詳細画面で再生ボタンを押す, THE Audio Recording Module SHALL AVAudioPlayerを使用して音声ファイルを再生する

### Requirement 3: 音声文字起こしとAI処理

**User Story:** アプリ利用者として、録音した音声を自動的に文字起こしし、要約とタグを生成してほしい

#### Acceptance Criteria

1. WHEN 録音が完了する, THE EchoLog System SHALL 音声ファイルをOpenAI Whisper APIに送信して文字起こしを実行する
2. WHEN 文字起こしが完了する, THE EchoLog System SHALL 文字起こしテキストをOpenAI GPT APIに送信して要約とタグを生成する
3. WHEN GPT APIが要約とタグを返す, THE EchoLog System SHALL 要約が1文字以上、タグが1〜10個の範囲であることを検証する
4. WHEN 要約とタグの生成が完了する, THE EchoLog System SHALL 文字起こしテキストからEmbeddingベクトルを生成する
5. THE EchoLog System SHALL すべての処理中にローディングインジケーターを表示する

### Requirement 4: メモのCRUD操作

**User Story:** アプリ利用者として、メモの作成、閲覧、編集、削除ができるようにしたい

#### Acceptance Criteria

1. WHEN AI処理が完了する, THE EchoLog System SHALL 音声URL、文字起こし、要約、タグ、EmbeddingをBackend APIの`/api/memos`にPOSTリクエストで保存する
2. WHEN ホーム画面が表示される, THE EchoLog System SHALL Backend APIの`/api/memos?limit=100&skip=0`から最新100件のメモを取得する
3. WHEN ユーザーがメモカードをタップする, THE EchoLog System SHALL メモ詳細画面に遷移し、文字起こし、要約、タグ、作成日時を表示する
4. WHEN ユーザーがメモ編集画面で内容を変更して保存ボタンを押す, THE EchoLog System SHALL Backend APIの`/api/memos/{id}`にPATCHリクエストで更新内容を送信する
5. WHEN ユーザーが削除ボタンを押して確認する, THE EchoLog System SHALL Backend APIの`/api/memos/{id}`にDELETEリクエストを送信してメモを削除する

### Requirement 5: セマンティック検索

**User Story:** アプリ利用者として、キーワードで検索し、意味的に関連するメモを見つけたい

#### Acceptance Criteria

1. WHEN ユーザーが検索画面で検索テキストを入力する, THE EchoLog System SHALL 入力テキストからEmbeddingベクトルを生成する
2. WHEN Embeddingベクトルが生成される, THE EchoLog System SHALL Backend APIの`/api/memos/search`にEmbeddingとlimitパラメータをPOSTリクエストで送信する
3. WHEN Backend APIが類似度スコア付きのメモリストを返す, THE EchoLog System SHALL 類似度の高い順にメモを表示する
4. WHEN 検索結果が0件の場合, THE EchoLog System SHALL 「検索結果がありません」メッセージを表示する
5. THE EchoLog System SHALL 検索処理中にローディングインジケーターを表示する

### Requirement 6: タグフィルタリングとソート

**User Story:** アプリ利用者として、タグでメモをフィルタリングし、日付順に並べ替えたい

#### Acceptance Criteria

1. WHEN ホーム画面が表示される, THE EchoLog System SHALL すべてのメモから重複なしのタグリストを抽出して表示する
2. WHEN ユーザーがタグチップをタップする, THE EchoLog System SHALL 選択されたタグを含むメモのみを表示する
3. WHEN ユーザーが「すべて」チップをタップする, THE EchoLog System SHALL フィルターを解除してすべてのメモを表示する
4. THE EchoLog System SHALL メモを作成日時の降順（新しい順）でソートして表示する
5. THE EchoLog System SHALL フィルター適用後のメモ件数を表示する

### Requirement 7: Echo Assistant（関連メモ提案）

**User Story:** アプリ利用者として、新しいメモを作成したときに関連する過去のメモを自動提案してほしい

#### Acceptance Criteria

1. WHEN 文字起こしが完了する, THE Echo Assistant SHALL 文字起こしテキストからEmbeddingを生成する
2. WHEN Embeddingが生成される, THE Echo Assistant SHALL Backend APIの`/api/memos/search`を使用して類似度0.7以上のメモを検索する
3. WHEN 関連メモが見つかる, THE Echo Assistant SHALL 提案カードを画面上部に表示する
4. WHEN ユーザーが提案カードをタップする, THE Echo Assistant SHALL 関連メモの詳細画面に遷移する
5. WHEN ユーザーが提案カードを閉じる, THE Echo Assistant SHALL 提案カードを非表示にする

### Requirement 8: リマインダー機能

**User Story:** アプリ利用者として、メモに含まれる日時を自動抽出し、その時刻に通知を受け取りたい

#### Acceptance Criteria

1. WHEN 文字起こしが完了する, THE Reminder System SHALL OpenAI GPT APIを使用してテキストから日時情報を抽出する
2. WHEN 抽出された日時が現在時刻より未来の場合, THE Reminder System SHALL iOSのUNUserNotificationCenterを使用して通知をスケジュールする
3. WHEN 通知がスケジュールされる, THE Reminder System SHALL ホーム画面のヘッダーにリマインダー件数バッジを表示する
4. WHEN スケジュールされた日時になる, THE Reminder System SHALL メモの要約を含むプッシュ通知を表示する
5. WHEN ユーザーが通知をタップする, THE Reminder System SHALL 該当メモの詳細画面を開く

### Requirement 9: オフライン対応と同期

**User Story:** アプリ利用者として、オフライン時でもメモを作成し、オンライン復帰時に自動同期してほしい

#### Acceptance Criteria

1. WHEN ネットワーク接続が利用できない, THE Sync Manager SHALL メモをローカルストレージ（CoreData）に保存する
2. WHEN ネットワーク接続が復帰する, THE Sync Manager SHALL ローカルに保存された未同期メモをBackend APIに送信する
3. WHILE 同期処理中, THE Sync Manager SHALL 画面上部に同期ステータスインジケーターを表示する
4. WHEN 同期が完了する, THE Sync Manager SHALL ローカルメモに同期済みフラグを設定する
5. THE Sync Manager SHALL 同期失敗時に最大3回まで自動リトライする

### Requirement 10: 位置情報取得（オプション）

**User Story:** アプリ利用者として、メモ作成時の位置情報を記録し、後で確認したい

#### Acceptance Criteria

1. WHEN ユーザーが録音ボタンを押す, THE EchoLog System SHALL iOSの位置情報権限をリクエストする
2. WHEN 位置情報権限が許可される, THE EchoLog System SHALL CoreLocationを使用して現在の緯度経度を取得する
3. WHEN メモを保存する, THE EchoLog System SHALL 位置情報をメモデータに含めてBackend APIに送信する
4. WHEN メモ詳細画面が表示される, THE EchoLog System SHALL 位置情報が存在する場合、地図アイコンと住所を表示する
5. WHERE 位置情報権限が拒否される, THE EchoLog System SHALL 位置情報なしでメモを保存する

### Requirement 11: UI/UXデザイン

**User Story:** アプリ利用者として、直感的で美しいインターフェースでアプリを使いたい

#### Acceptance Criteria

1. THE EchoLog System SHALL ダークテーマ（背景色#0f0f23、アクセントカラー#00D9FF）を使用する
2. WHEN 録音ボタンが表示される, THE EchoLog System SHALL 円形ボタン（直径140pt）をパルスアニメーションで表示する
3. WHEN メモカードが表示される, THE EchoLog System SHALL 要約、タグ、作成日時を含むカードUIを表示する
4. THE EchoLog System SHALL タグを角丸チップ（borderRadius 20pt）で表示する
5. THE EchoLog System SHALL すべてのテキストに適切なフォントウェイト（700〜900）とレタースペーシングを適用する

### Requirement 12: エラーハンドリング

**User Story:** アプリ利用者として、エラーが発生したときに分かりやすいメッセージを受け取りたい

#### Acceptance Criteria

1. WHEN API リクエストがタイムアウトする（10秒以上）, THE EchoLog System SHALL 「通信がタイムアウトしました」エラーメッセージを表示する
2. WHEN Backend APIが4xxまたは5xxエラーを返す, THE EchoLog System SHALL エラーレスポンスのメッセージをアラートで表示する
3. WHEN OpenAI APIがエラーを返す, THE EchoLog System SHALL 「AI処理に失敗しました」エラーメッセージを表示する
4. WHEN マイク権限が拒否される, THE EchoLog System SHALL 「マイク権限が必要です」メッセージと設定画面へのリンクを表示する
5. THE EchoLog System SHALL すべてのエラーをコンソールにログ出力する
