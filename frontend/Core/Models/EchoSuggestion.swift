

import Foundation

struct EchoSuggestion: Identifiable, Codable {
    let id: String
    let type: SuggestionType
    let title: String
    let description: String
    let relatedMemoIds: [String]
    let priority: Int
    let createdAt: Date
    let isActioned: Bool
    
    enum SuggestionType: String, Codable {
        case reminder = "reminder"
        case connection = "connection"
        case insight = "insight"
        case taskSuggestion = "task_suggestion"
    }
}

extension EchoSuggestion {
    static let preview = EchoSuggestion(
        id: "1",
        type: .connection,
        title: "関連するメモを発見",
        description: "先週の会議メモと今日のアイデアに関連性があります",
        relatedMemoIds: ["memo1", "memo2"],
        priority: 5,
        createdAt: Date(),
        isActioned: false
    )
}
