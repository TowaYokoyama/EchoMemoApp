
import Foundation

@MainActor
class MemoDetailViewModel: ObservableObject {
    @Published var linkedMemos: [Memo] = []
    @Published var updatedMemo: Memo? = nil
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var error: Error?
    
    func updateMemo(_ memo: Memo) {
        print("📝 [MEMO] Updating displayed memo: \(memo.id)")
        updatedMemo = memo
    }
    
    func loadLinkedMemos(for memo: Memo) async {
        // TODO: 関連メモ機能は将来実装予定
        // 現在のバックエンドはlinkedMemosフィールドをサポートしていません
        return
        
//        isLoading = true
//        error = nil
//        
//        do {
//            linkedMemos = try await MemoService.shared.getLinkedMemos(memoId: memo.id)
//        } catch {
//            self.error = error
//        }
//        
//        isLoading = false
    }
    
    func deleteMemo(_ memo: Memo) async throws {
        isDeleting = true
        error = nil
        
        do {
            print("🗑️ [MEMO] Deleting memo: \(memo.id)")
            try await MemoService.shared.deleteMemo(id: memo.id)
            print("✅ [MEMO] Memo deleted successfully")
        } catch {
            print("❌ [MEMO] Failed to delete memo: \(error)")
            self.error = error
            throw error
        }
        
        isDeleting = false
    }
}
