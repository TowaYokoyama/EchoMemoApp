

import SwiftUI

struct EchoAssistantView: View {
    @StateObject private var viewModel = EchoAssistantViewModel()
    @State private var showingKnowledgeGraph = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.theme.accent)
                        
                        Text("Echo アシスタント")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("AIがあなたのメモから洞察を提供します")
                            .font(.caption)
                            .foregroundColor(.theme.secondaryText)
                    }
                    .padding()
                    
                    // 提案一覧
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.suggestions.isEmpty {
                        EmptyStateView()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.suggestions) { suggestion in
                                SuggestionCard(suggestion: suggestion) {
                                    viewModel.markAsActioned(suggestion)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("アシスタント")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingKnowledgeGraph = true
                        } label: {
                            Image(systemName: "network")
                        }
                        
                        Button {
                            Task {
                                await viewModel.refreshSuggestions()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .sheet(isPresented: $showingKnowledgeGraph) {
                KnowledgeGraphView()
            }
            .task {
                await viewModel.loadSuggestions()
            }
            .alert(error: $viewModel.error)
        }
    }
}

struct SuggestionCard: View {
    let suggestion: EchoSuggestion
    let onAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // アイコンとタイプ
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                
                Text(typeLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(iconColor)
                
                Spacer()
                
                // 優先度
                ForEach(0..<suggestion.priority, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            // タイトル
            Text(suggestion.title)
                .font(.headline)
                .foregroundColor(.theme.text)
            
            // 説明
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.theme.secondaryText)
            
            // アクションボタン
            if !suggestion.isActioned {
                Button(action: onAction) {
                    Text("確認")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iconColor.opacity(0.2))
                        .foregroundColor(iconColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .cardStyle()
        .opacity(suggestion.isActioned ? 0.6 : 1.0)
    }
    
    private var iconName: String {
        switch suggestion.type {
        case .reminder: return "bell.fill"
        case .connection: return "link"
        case .insight: return "lightbulb.fill"
        case .taskSuggestion: return "checkmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch suggestion.type {
        case .reminder: return .orange
        case .connection: return .blue
        case .insight: return .yellow
        case .taskSuggestion: return .green
        }
    }
    
    private var typeLabel: String {
        switch suggestion.type {
        case .reminder: return "リマインダー"
        case .connection: return "関連性"
        case .insight: return "洞察"
        case .taskSuggestion: return "タスク提案"
        }
    }
}

#Preview {
    EchoAssistantView()
}
