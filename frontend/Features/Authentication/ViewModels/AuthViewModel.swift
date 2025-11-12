
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
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
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    func login() async {
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
            // 入力フィールドをクリア
            password = ""
        } catch let apiError as APIError {
            print("❌ Login failed: \(apiError)")
            self.error = apiError
        } catch {
            print("❌ Login error: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    func register() async {
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
            // 入力フィールドをクリア
            password = ""
            name = ""
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func logout() {
        AuthService.shared.logout()
        isAuthenticated = false
        currentUser = nil
        email = ""
        password = ""
        name = ""
    }
    
    private func fetchCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.getCurrentUser()
        } catch {
            // トークンが無効な場合はログアウト
            logout()
        }
    }
}
