
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
        
        // アクセストークンをKeychainに保存
        KeychainManager.shared.saveToken(response.accessToken)
        
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
        
        // アクセストークンをKeychainに保存
        KeychainManager.shared.saveToken(response.accessToken)
        
        return response
    }
    
    func logout() {
        KeychainManager.shared.deleteToken()
    }
    
    func getCurrentUser() async throws -> User {
        return try await APIService.shared.request(
            endpoint: "/auth/me",
            method: .get
        )
    }
    
    func isAuthenticated() -> Bool {
        return KeychainManager.shared.getToken() != nil
    }
}
