
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $viewModel.searchQuery)
                    .padding()
                
                // 検索結果
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchQuery.isEmpty {
                    EmptySearchView()
                } else if viewModel.searchResults.isEmpty {
                    NoResultsView(query: viewModel.searchQuery)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.searchResults) { memo in
                                NavigationLink(destination: MemoDetailView(memo: memo)) {
                                    MemoCardView(memo: memo)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("検索")
        }
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.theme.secondaryText)
            
            Text("メモを検索")
                .font(.headline)
                .foregroundColor(.theme.text)
            
            Text("キーワードやタグで検索できます")
                .font(.caption)
                .foregroundColor(.theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.theme.secondaryText)
            
            Text("結果が見つかりません")
                .font(.headline)
                .foregroundColor(.theme.text)
            
            Text("「\(query)」に一致するメモがありません")
                .font(.caption)
                .foregroundColor(.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SearchView()
}
