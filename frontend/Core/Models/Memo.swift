
import Foundation

struct Memo: Identifiable, Codable {
    let id: String
    let audioURL: String
    let transcription: String
    let summary: String  // バックエンドのsummaryフィールド (titleとして使用)
    let tags: [String]
    let embedding: [Double]?
    let createdAt: Date
    let relatedMemoIds: [String]?
    var isSynced: Bool = true
    
    // UIで使用する計算プロパティ
    var title: String { summary }
    var content: String { transcription }
    
    enum CodingKeys: String, CodingKey {
        case id
        case audioURL = "audio_url"
        case transcription
        case summary
        case tags
        case embedding
        case createdAt = "created_at"
        case relatedMemoIds = "related_memo_ids"
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let placeName: String?
}

extension Memo {
    static let preview = Memo(
        id: "1",
        audioURL: "mock://audio.m4a",
        transcription: "これはサンプルのメモです。",
        summary: "サンプルメモ",
        tags: ["仕事", "アイデア"],
        embedding: nil,
        createdAt: Date(),
        relatedMemoIds: ["2", "3"],
        isSynced: true
    )
}
