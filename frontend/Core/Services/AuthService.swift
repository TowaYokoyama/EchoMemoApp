//ユーザーの認証（ログイン・新規登録・ログアウト。ログイン状態の確認）をまとめたサービスクラス
import Foundation

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    func login(email: String, password: String) async throws -> LoginResponse {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }
        
        let request = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await APIService.shared.request(
            endpoint: "/auth/login",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        // トークンとユーザー情報を保存
        KeychainManager.shared.saveToken(response.accessToken)
        KeychainManager.shared.saveRefreshToken(response.refreshToken)
        KeychainManager.shared.saveUser(response.user)
        
        return response
    }
    
    func register(email: String, password: String, name: String?) async throws -> RegisterResponse {
        struct RegisterRequest: Encodable {
            let email: String
            let password: String
            let name: String?
        }
        
        let request = RegisterRequest(email: email, password: password, name: name)
        let response: RegisterResponse = try await APIService.shared.request(
            endpoint: "/auth/register",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        // トークンとユーザー情報を保存
        KeychainManager.shared.saveToken(response.accessToken)
        KeychainManager.shared.saveRefreshToken(response.refreshToken)
        KeychainManager.shared.saveUser(response.user)
        
        return response
    }
    
    func logout() {
        KeychainManager.shared.deleteToken()
        KeychainManager.shared.deleteRefreshToken()
        KeychainManager.shared.deleteUser()
    }
    
    func getCurrentUser() async throws -> User {
        // まずローカルから取得を試みる
        if let cachedUser = KeychainManager.shared.getUser() {
            print("👤 [AUTH] Using cached user: \(cachedUser.email)")
            return cachedUser
        }
        
        // ローカルになければサーバーから取得
        print("👤 [AUTH] Fetching user from server...")
        let user: User = try await APIService.shared.request(
            endpoint: "/auth/me",
            method: .get
        )
        
        // 取得したユーザー情報を保存
        KeychainManager.shared.saveUser(user)
        
        return user
    }
    
    func isAuthenticated() -> Bool {
        let hasToken = KeychainManager.shared.getToken() != nil
        let hasUser = KeychainManager.shared.getUser() != nil
        print("🔐 [AUTH] isAuthenticated: hasToken=\(hasToken), hasUser=\(hasUser)")
        return hasToken
    }
    
    func getCachedUser() -> User? {
        return KeychainManager.shared.getUser()
    }
    
    func refreshAccessToken() async throws -> String {
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        struct RefreshRequest: Encodable {
            let refreshToken: String
        }
        
        struct RefreshResponse: Decodable {
            let accessToken: String
        }
        
        let request = RefreshRequest(refreshToken: refreshToken)
        let response: RefreshResponse = try await APIService.shared.request(
            endpoint: "/auth/refresh",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        // 新しいアクセストークンを保存
        KeychainManager.shared.saveToken(response.accessToken)
        print("✅ [AUTH] Access token refreshed successfully")
        
        return response.accessToken
    }
}
