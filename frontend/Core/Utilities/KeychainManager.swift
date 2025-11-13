// アプリがログインに成功するとサーバーからトークンが返ってくる。
//そのトークンをiOS標準の Keychain（暗号化されたセキュアストレージ） に入れる。
import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.echolog.app"
    private let tokenKey = "authToken"
    private let refreshTokenKey = "refreshToken"
    private let userDefaultsTokenKey = "fallbackAuthToken"
    private let userDefaultsRefreshTokenKey = "fallbackRefreshToken"
    private let userDefaultsUserKey = "currentUser"
    
    private init() {}
    
    func saveToken(_ token: String) {
        print("🔑 [AUTH] Saving token: \(token.prefix(20))...")
        
        // 1. UserDefaultsに必ずバックアップ保存（フォールバック用）
        UserDefaults.standard.set(token, forKey: userDefaultsTokenKey)
        UserDefaults.standard.synchronize()
        print("✅ [AUTH] Token saved to UserDefaults")
        
        // 2. Keychainへの保存を試みる（失敗してもOK）
        guard let data = token.data(using: .utf8) else {
            print("⚠️ [AUTH] Failed to convert token to data, but UserDefaults backup exists")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // 既存のアイテムを削除
        SecItemDelete(query as CFDictionary)
        
        // 新しいアイテムを追加
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ [AUTH] Token also saved to Keychain")
        } else {
            print("⚠️ [AUTH] Keychain save failed (\(status)), using UserDefaults backup")
        }
    }
    
    func getToken() -> String? {
        print("🔍 [AUTH] Retrieving token...")
        
        // 1. まずKeychainから取得を試みる
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            print("✅ [AUTH] Token retrieved from Keychain: \(token.prefix(20))...")
            return token
        }
        
        // 2. Keychainから取得できない場合、UserDefaultsからフォールバック
        print("⚠️ [AUTH] Keychain failed (\(status)), trying UserDefaults backup...")
        if let token = UserDefaults.standard.string(forKey: userDefaultsTokenKey) {
            print("✅ [AUTH] Token retrieved from UserDefaults: \(token.prefix(20))...")
            return token
        }
        
        print("❌ [AUTH] No token found - user needs to login")
        return nil
    }
    
    func deleteToken() {
        print("🗑️ [AUTH] Deleting token...")
        
        // UserDefaultsから削除
        UserDefaults.standard.removeObject(forKey: userDefaultsTokenKey)
        UserDefaults.standard.synchronize()
        
        // Keychainから削除
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
        print("✅ [AUTH] Token deleted")
    }
    
    // MARK: - User Management
    
    func saveUser(_ user: User) {
        print("👤 [AUTH] Saving user: \(user.email)")
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsUserKey)
            UserDefaults.standard.synchronize()
            print("✅ [AUTH] User saved")
        } else {
            print("❌ [AUTH] Failed to encode user")
        }
    }
    
    func getUser() -> User? {
        print("👤 [AUTH] Retrieving user...")
        guard let data = UserDefaults.standard.data(forKey: userDefaultsUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            print("❌ [AUTH] No user found")
            return nil
        }
        print("✅ [AUTH] User retrieved: \(user.email)")
        return user
    }
    
    func deleteUser() {
        print("👤 [AUTH] Deleting user...")
        UserDefaults.standard.removeObject(forKey: userDefaultsUserKey)
        UserDefaults.standard.synchronize()
        print("✅ [AUTH] User deleted")
    }
    
    // MARK: - Refresh Token Management
    
    func saveRefreshToken(_ token: String) {
        print("🔄 [AUTH] Saving refresh token: \(token.prefix(20))...")
        
        // UserDefaultsにバックアップ保存
        UserDefaults.standard.set(token, forKey: userDefaultsRefreshTokenKey)
        UserDefaults.standard.synchronize()
        print("✅ [AUTH] Refresh token saved to UserDefaults")
        
        // Keychainへの保存を試みる
        guard let data = token.data(using: .utf8) else {
            print("⚠️ [AUTH] Failed to convert refresh token to data")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ [AUTH] Refresh token also saved to Keychain")
        } else {
            print("⚠️ [AUTH] Keychain save failed (\(status)), using UserDefaults backup")
        }
    }
    
    func getRefreshToken() -> String? {
        print("🔍 [AUTH] Retrieving refresh token...")
        
        // Keychainから取得を試みる
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            print("✅ [AUTH] Refresh token retrieved from Keychain")
            return token
        }
        
        // UserDefaultsからフォールバック
        if let token = UserDefaults.standard.string(forKey: userDefaultsRefreshTokenKey) {
            print("✅ [AUTH] Refresh token retrieved from UserDefaults")
            return token
        }
        
        print("❌ [AUTH] No refresh token found")
        return nil
    }
    
    func deleteRefreshToken() {
        print("🗑️ [AUTH] Deleting refresh token...")
        
        UserDefaults.standard.removeObject(forKey: userDefaultsRefreshTokenKey)
        UserDefaults.standard.synchronize()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
        print("✅ [AUTH] Refresh token deleted")
    }
}
