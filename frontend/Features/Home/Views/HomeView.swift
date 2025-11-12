

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingRecording = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $viewModel.searchText)
                    .padding()
                
                // タグフィルタ
                if !viewModel.allTags.isEmpty {
                    TagFilterView(
                        tags: viewModel.allTags,
                        selectedTags: $viewModel.selectedTags,
                        onToggle: viewModel.toggleTag
                    )
                    .padding(.horizontal)
                }
                
                // メモリスト
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredMemos.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(Array(viewModel.groupedMemos().keys.sorted()), id: \.self) { key in
                                Section {
                                    ForEach(viewModel.groupedMemos()[key] ?? []) { memo in
                                        NavigationLink(destination: MemoDetailView(memo: memo)) {
                                            MemoCardView(memo: memo)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                Task {
                                                    await viewModel.deleteMemo(memo)
                                                }
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    Text(key)
                                        .font(.headline)
                                        .foregroundColor(.theme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(Color.theme.background)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshMemos()
                    }
                }
            }
            .navigationTitle("EchoLog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRecording = true
                    } label: {
                        Image(systemName: "mic.circle.fill")
                            .font(.title2)
                            .foregroundColor(.theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingRecording) {
                RecordingView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(authViewModel: authViewModel)
            }
            .task {
                await viewModel.fetchMemos()
            }
            .alert(error: $viewModel.error)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.theme.secondaryText)
            
            Text("メモがありません")
                .font(.headline)
                .foregroundColor(.theme.text)
            
            Text("右上のマイクボタンから録音を開始してください")
                .font(.caption)
                .foregroundColor(.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.theme.secondaryText)
            
            TextField("メモを検索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.theme.secondaryText)
                }
            }
        }
        .padding(10)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

#Preview {
    HomeView()
}
