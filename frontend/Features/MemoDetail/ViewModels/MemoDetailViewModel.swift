
import Foundation

@MainActor
class MemoDetailViewModel: ObservableObject {
    @Published var linkedMemos: [Memo] = []
    @Published var isLoading = false
    @Published var error: Error?
    
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
}
