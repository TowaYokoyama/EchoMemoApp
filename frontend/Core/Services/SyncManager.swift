// ローカルのメモデータをサーバーと自動で同期するための管理クラス
/*オフライン対応がない

CoreDataもSwiftDataも実装されていない
すべてのデータはAPIから直接取得している
ローカルキャッシュがないので同期する対象がない
リアルタイム性が不要

ユーザーが画面を開くたびに最新データを取得している
5分ごとのバックグラウンド同期は過剰
複雑性が増すだけ

デバッグが難しくなる
バグの温床になる
動作検証が複雑化*/

import Foundation
import Combine

enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
}

class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5分ごと
    
    private init() {
        setupAutoSync()
    }
    
    private func setupAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.sync()
            }
        }
    }
    
    func sync() async {
        guard syncStatus != .syncing else { return }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // ローカルの未同期メモを取得
            let unsyncedMemos = try await fetchUnsyncedMemos()
            
            // サーバーにアップロード
            for memo in unsyncedMemos {
                try await uploadMemo(memo)
            }
            
            // サーバーから最新のメモを取得
            let serverMemos = try await MemoService.shared.fetchMemos()
            
            // ローカルデータベースを更新
            try await updateLocalDatabase(with: serverMemos)
            
            await MainActor.run {
                syncStatus = .idle
                lastSyncDate = Date()
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    func forceSync() async {
        await sync()
    }
    
    private func fetchUnsyncedMemos() async throws -> [Memo] {
        // TODO: CoreDataから未同期のメモを取得
        return []
    }
    
    private func uploadMemo(_ memo: Memo) async throws {
        // TODO: メモをサーバーにアップロード
        _ = try await MemoService.shared.createMemo(
            title: memo.title,
            content: memo.content,
            tags: memo.tags,
            audioURL: memo.audioURL
        )
    }
    
    private func updateLocalDatabase(with memos: [Memo]) async throws {
        // TODO: CoreDataを更新
    }
}
