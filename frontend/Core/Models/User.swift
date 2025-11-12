
import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let oauthProvider: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"  // バックエンドは "id" を返す
        case email
        case oauthProvider = "oauth_provider"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension User {
    static let preview = User(
        id: "user123",
        email: "test@example.com",
        oauthProvider: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
