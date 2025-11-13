

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .unauthorized:
            return "認証に失敗しました"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        // シミュレーターと実機で自動的にURLを切り替え
        #if targetEnvironment(simulator)
        self.baseURL = "http://localhost:3000/api"
        #else
        self.baseURL = "http://192.168.0.15:3000/api"
        #endif
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンの追加
        if requiresAuth {
            if let token = KeychainManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // ボディの設定
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        print("📡 API Request: \(method.rawValue) \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 Response: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                // ISO8601の柔軟な日付デコーディング
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // ISO8601形式（ミリ秒付き）を試行: 2025-11-12T10:57:52.497Z
                    let iso8601Formatter = ISO8601DateFormatter()
                    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                    
                    // ISO8601形式（ミリ秒なし）を試行
                    iso8601Formatter.formatOptions = [.withInternetDateTime]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                    
                    // カスタムフォーマットを試行
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
                }
                
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    print("✅ Successfully decoded response")
                    return decoded
                } catch {
                    print("❌ Decoding error: \(error)")
                    throw APIError.decodingError
                }
            case 401:
                print("⚠️ [API] 401 Unauthorized - attempting token refresh...")
                
                // トークンリフレッシュを試行（リフレッシュエンドポイント以外の場合のみ）
                if !endpoint.contains("/auth/refresh") && !endpoint.contains("/auth/login") && !endpoint.contains("/auth/register") {
                    do {
                        // トークンをリフレッシュ
                        let newToken = try await AuthService.shared.refreshAccessToken()
                        print("✅ [API] Token refreshed, retrying original request...")
                        
                        // 新しいトークンで再度リクエスト
                        var retryRequest = request
                        retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                        
                        let (retryData, retryResponse) = try await session.data(for: retryRequest)
                        
                        guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                              200...299 ~= retryHttpResponse.statusCode else {
                            print("❌ [API] Retry failed after token refresh")
                                throw APIError.unauthorized
                        }
                        
                        // リトライ用のデコーダーを作成
                        let retryDecoder = JSONDecoder()
                        retryDecoder.dateDecodingStrategy = .custom { decoder in
                            let container = try decoder.singleValueContainer()
                            let dateString = try container.decode(String.self)
                            
                            let iso8601Formatter = ISO8601DateFormatter()
                            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            if let date = iso8601Formatter.date(from: dateString) {
                                return date
                            }
                            
                            iso8601Formatter.formatOptions = [.withInternetDateTime]
                            if let date = iso8601Formatter.date(from: dateString) {
                                return date
                            }
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                            if let date = dateFormatter.date(from: dateString) {
                                return date
                            }
                            
                            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
                        }
                        
                        let decoded = try retryDecoder.decode(T.self, from: retryData)
                        print("✅ [API] Retry successful after token refresh")
                        
                        return decoded
                    } catch {
                        print("❌ [API] Token refresh failed: \(error)")
                        throw APIError.unauthorized
                    }
                } else {
                    print("❌ [API] Unauthorized (no refresh attempt for this endpoint)")
                    throw APIError.unauthorized
                }
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Server error: \(errorMessage)")
                throw APIError.serverError(errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    func upload(
        endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String = "file",
        parameters: [String: String] = [:]
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("📤 [API] Uploading file: \(fileName), size: \(fileData.count) bytes")
        
        var body = Data()
        
        // パラメータの追加
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // ファイルの追加
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📡 [API] Sending upload request to: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [API] Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("📥 [API] Upload response: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [API] Upload failed: \(errorMessage)")
            throw APIError.serverError("Upload failed with status \(httpResponse.statusCode)")
        }
        
        print("✅ [API] Upload successful")
        return data
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
