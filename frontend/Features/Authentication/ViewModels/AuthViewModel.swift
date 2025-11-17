
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isAuthenticated = AuthService.shared.isAuthenticated()
        
        if isAuthenticated {
            // まずキャッシュからユーザー情報を取得
            currentUser = AuthService.shared.getCachedUser()
            print("👤 [AUTH] Cached user loaded: \(currentUser?.email ?? "none")")
            
            // バックグラウンドでサーバーから最新情報を取得
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "メールアドレスとパスワードを入力してください"])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("🔐 Login attempt: \(email)")
            let response = try await AuthService.shared.login(email: email, password: password)
            print("✅ Login successful: \(response.user.email)")
            currentUser = response.user
            error = nil // エラーをクリア
            isAuthenticated = true
        } catch let apiError as APIError {
            print("❌ Login failed: \(apiError)")
            self.error = apiError
        } catch {
            print("❌ Login error: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, name: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "メールアドレスとパスワードを入力してください"])
            return
        }
        
        guard password.count >= 8 else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "パスワードは8文字以上で入力してください"])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await AuthService.shared.register(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
            currentUser = response.user
            error = nil // エラーをクリア
            isAuthenticated = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func logout() {
        AuthService.shared.logout()
        isAuthenticated = false
        currentUser = nil
    }
    
    private func fetchCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.getCurrentUser()
            print("👤 [AUTH] User info updated from server")
        } catch {
            print("⚠️ [AUTH] Failed to fetch user from server: \(error)")
            // トークンが無効な場合はログアウト
            if case APIError.unauthorized = error {
                logout()
            }
            // その他のエラーはキャッシュを使い続ける
        }
    }
}
