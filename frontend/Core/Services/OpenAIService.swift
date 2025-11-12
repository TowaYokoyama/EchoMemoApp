// OpenAiでメモ関連の処理を行うサービスクラス
import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private init() {}
    //このメモに関連するトピックAIが提案する
    func generateEchoSuggestions(memos: [Memo]) async throws -> [EchoSuggestion] {
        struct SuggestionsRequest: Encodable {
            let memoIds: [String]
        }
        
        let request = SuggestionsRequest(memoIds: memos.map { $0.id })
        return try await APIService.shared.request(
            endpoint: "/echo/suggestions",
            method: .post,
            body: request
        )
    }
    //特定のメモIDを提案して、そのメモとの他の関連メモを分析する
    func analyzeMemoConnections(memoId: String) async throws -> [String: Double] {
        struct ConnectionResponse: Decodable {
            let connections: [String: Double]
        }
        
        let response: ConnectionResponse = try await APIService.shared.request(
            endpoint: "/echo/analyze/\(memoId)",
            method: .get
        )
        
        return response.connections
    }
    //メモ内容からタイトルを生成する
    func generateMemoTitle(content: String) async throws -> String {
        struct TitleRequest: Encodable {
            let content: String
        }
        
        struct TitleResponse: Decodable {
            let title: String
        }
        
        let request = TitleRequest(content: content)
        let response: TitleResponse = try await APIService.shared.request(
            endpoint: "/gpt/generate-title",
            method: .post,
            body: request
        )
        
        return response.title
    }
    //メモ内容からタグを抽出
    func extractTags(content: String) async throws -> [String] {
        struct TagRequest: Encodable {
            let content: String
        }
        
        struct TagResponse: Decodable {
            let tags: [String]
        }
        
        let request = TagRequest(content: content)
        let response: TagResponse = try await APIService.shared.request(
            endpoint: "/gpt/extract-tags",
            method: .post,
            body: request
        )
        
        return response.tags
    }
}
