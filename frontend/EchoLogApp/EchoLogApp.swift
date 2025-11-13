

import SwiftUI
import UserNotifications

@main
struct EchoLogApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        setupAppearance()
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(syncManager)
                .environmentObject(networkMonitor)
                .onAppear {
                    LocationService.shared.requestAuthorization()
                }
        }
    }
    
    private func setupAppearance() {
        // NavigationBarの外観設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
            
            EchoAssistantView()
                .tabItem {
                    Label("アシスタント", systemImage: "sparkles")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(SyncManager.shared)
        .environmentObject(NetworkMonitor.shared)
}
