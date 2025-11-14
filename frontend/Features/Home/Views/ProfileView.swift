

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // ユーザー情報
                Section {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.email)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 同期状態
                Section("同期") {
                    HStack {
                        Text("状態")
                        Spacer()
                        switch syncManager.syncStatus {
                        case .idle:
                            Text("同期済み")
                                .foregroundColor(.theme.success)
                        case .syncing:
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("同期中...")
                            }
                        case .error(let message):
                            Text("エラー: \(message)")
                                .foregroundColor(.theme.error)
                        }
                    }
                    
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("最終同期")
                            Spacer()
                            Text(lastSync.timeAgoDisplay())
                                .foregroundColor(.theme.secondaryText)
                        }
                    }
                    
                    Button("今すぐ同期") {
                        Task {
                            await syncManager.forceSync()
                        }
                    }
                }
                
                // ネットワーク状態
                Section("ネットワーク") {
                    HStack {
                        Text("接続状態")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(networkMonitor.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(networkMonitor.isConnected ? "オンライン" : "オフライン")
                                .foregroundColor(.theme.secondaryText)
                        }
                    }
                    
                    if networkMonitor.isConnected {
                        HStack {
                            Text("接続タイプ")
                            Spacer()
                            Text(connectionTypeString)
                                .foregroundColor(.theme.secondaryText)
                        }
                    }
                }
                
                // 設定
                Section {
                    NavigationLink("設定") {
                        Text("設定画面（未実装）")
                    }
                    
                    NavigationLink("ヘルプ") {
                        Text("ヘルプ画面（未実装）")
                    }
                    
                    NavigationLink("プライバシーポリシー") {
                        Text("プライバシーポリシー（未実装）")
                    }
                }
                
                // ログアウト
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                        dismiss()
                    } label: {
                        Text("ログアウト")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var connectionTypeString: String {
        switch networkMonitor.connectionType {
        case .wifi: return "Wi-Fi"
        case .cellular: return "モバイルデータ"
        case .ethernet: return "有線"
        case .unknown: return "不明"
        }
    }
}
