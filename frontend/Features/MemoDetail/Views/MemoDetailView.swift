
import SwiftUI

struct MemoDetailView: View {
    let memo: Memo
    @StateObject private var viewModel = MemoDetailViewModel()
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    // 表示用のメモ（編集後に更新される）
    private var displayMemo: Memo {
        viewModel.updatedMemo ?? memo
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // タイトル
                Text(displayMemo.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.theme.text)

                // メタ情報
                HStack {
                    Text(displayMemo.createdAt.formatted())
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                    Spacer()
                }

                Divider()

                // 音声プレーヤー
                if !displayMemo.audioURL.isEmpty, let url = URL(string: displayMemo.audioURL) {
                    AudioPlayerView(audioURL: url)
                        .padding(.vertical)
                }

                // コンテンツ
                Text(displayMemo.content)
                    .font(.body)
                    .foregroundColor(.theme.text)

                // タグ
                if !displayMemo.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タグ")
                            .font(.headline)
                            .foregroundColor(.theme.secondaryText)

                        FlowLayout(spacing: 8) {
                            ForEach(displayMemo.tags, id: \.self) { tag in
                                TagView(tag: tag)
                            }
                        }
                    }
                    .padding(.top)
                }

                // 関連メモ
                if !viewModel.linkedMemos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("関連メモ")
                            .font(.headline)

                        ForEach(viewModel.linkedMemos) { linkedMemo in
                            NavigationLink(destination: MemoDetailView(memo: linkedMemo)) {
                                RelatedMemoCard(memo: linkedMemo)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    ShareLink(item: viewModel.getShareContent(for: displayMemo)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Menu {
                        Button {
                            showingEdit = true
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditMemoView(memo: displayMemo, onSaved: { updatedMemo in
                viewModel.updateMemo(updatedMemo)
            })
        }
        .alert("メモを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteMemo(memo)
                        dismiss()
                    } catch {
                        // エラーは別のアラートで表示
                    }
                }
            }
        } message: {
            Text("このメモを削除してもよろしいですか？この操作は取り消せません。")
        }
        .alert(error: $viewModel.error)
        .overlay {
            if viewModel.isDeleting {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("削除中...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .task {
            await viewModel.loadLinkedMemos(for: memo)
        }
    }
}

struct RelatedMemoCard: View {
    let memo: Memo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memo.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.theme.text)

            Text(memo.content)
                .font(.caption)
                .foregroundColor(.theme.secondaryText)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    NavigationView {
        MemoDetailView(memo: Memo.preview)
    }
}