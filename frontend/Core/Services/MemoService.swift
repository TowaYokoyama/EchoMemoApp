// メモに関するすべてのAPI通信をまとめて取得するサービスクラス
import Foundation

class MemoService {
    static let shared = MemoService()
    
    private init() {}
    //メモ一覧を取得
    func fetchMemos(skip: Int = 0, limit: Int = 20) async throws -> [Memo] {
        struct MemoListResponse: Codable {
            let data: [Memo]
            let pagination: Pagination
        }
        
        struct Pagination: Codable {
            let total: Int
            let skip: Int
            let limit: Int
            let hasMore: Bool
        }
        
        let response: MemoListResponse = try await APIService.shared.request(
            endpoint: "/memos?skip=\(skip)&limit=\(limit)",
            method: .get
        )
        return response.data
    }
    
    func fetchMemo(id: String) async throws -> Memo {
        return try await APIService.shared.request(
            endpoint: "/memos/\(id)",
            method: .get
        )
    }
    //メモを作成
    func createMemo(title: String, content: String, tags: [String] = [], audioURL: String? = nil) async throws -> Memo {
        struct CreateMemoRequest: Encodable {
            let audioUrl: String
            let transcription: String
            let summary: String
            let tags: [String]
            let embedding: [Double]?
            
            enum CodingKeys: String, CodingKey {
                case audioUrl = "audio_url"
                case transcription
                case summary
                case tags
                case embedding
            }
        }
        
        let request = CreateMemoRequest(
            audioUrl: audioURL ?? "mock://audio.m4a",
            transcription: content,
            summary: title,
            tags: tags.isEmpty ? ["メモ"] : tags,
            embedding: nil
        )
        
        return try await APIService.shared.request(
            endpoint: "/memos",
            method: .post,
            body: request
        )
    }
    //メモを更新
    func updateMemo(id: String, title: String?, content: String?, tags: [String]?) async throws -> Memo {
        struct UpdateMemoRequest: Encodable {
            let title: String?
            let content: String?
            let tags: [String]?
        }
        
        let request = UpdateMemoRequest(title: title, content: content, tags: tags)
        return try await APIService.shared.request(
            endpoint: "/memos/\(id)",
            method: .patch,
            body: request
        )
    }

    //メモを削除
    func deleteMemo(id: String) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/memos/\(id)",
            method: .delete
        )
    }
    //メモを検索
    func searchMemos(query: String) async throws -> [Memo] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await APIService.shared.request(
            endpoint: "/memos/search?q=\(encodedQuery)",
            method: .get
        )
    }
    //関連メモを取得
    func getLinkedMemos(memoId: String) async throws -> [Memo] {
        return try await APIService.shared.request(
            endpoint: "/memos/\(memoId)/linked",
            method: .get
        )
    }
}
