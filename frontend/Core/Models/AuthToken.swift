
import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct LoginResponse: Codable {
    let token: String // 後方互換性のため
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct RegisterResponse: Codable {
    let token: String // 後方互換性のため
    let accessToken: String
    let refreshToken: String
    let user: User
}
