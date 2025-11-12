

import Foundation

@MainActor
class EchoAssistantViewModel: ObservableObject {
    @Published var suggestions: [EchoSuggestion] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadSuggestions() async {
        isLoading = true
        error = nil
        
        do {
            // まずメモを取得
            let memos = try await MemoService.shared.fetchMemos()
            
            // AIで提案を生成
            suggestions = try await OpenAIService.shared.generateEchoSuggestions(memos: memos)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refreshSuggestions() async {
        await loadSuggestions()
    }
    
    func markAsActioned(_ suggestion: EchoSuggestion) {
        if let index = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            var updated = suggestion
            // Note: EchoSuggestionがstructの場合、isActionedをvarに変更する必要があります
            // ここでは仮の実装
            suggestions.remove(at: index)
        }
    }
}
