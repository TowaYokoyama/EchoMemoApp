
import Foundation
import SwiftUI

enum Constants {
    // API
    enum API {
        #if targetEnvironment(simulator)
        static let baseURL = "http://localhost:3000/api"
        #else
        static let baseURL = "http://192.168.0.15:3000/api"
        #endif
        static let timeout: TimeInterval = 30
    }
    
    // Storage
    enum Storage {
        static let userDefaultsSuiteName = "com.echologapp.defaults"
        static let maxLocalMemos = 1000
        static let audioQuality = 0.8
    }
    
    // UI
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let animationDuration: Double = 0.3
    }
    
    // Colors
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let accent = Color.orange
        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    }
    
    // Sync
    enum Sync {
        static let interval: TimeInterval = 300 // 5分
        static let retryAttempts = 3
        static let retryDelay: TimeInterval = 5
    }
    
    // Recording
    enum Recording {
        static let maxDuration: TimeInterval = 3600 // 1時間
        static let sampleRate: Double = 44100
        static let channels = 1
    }
}
