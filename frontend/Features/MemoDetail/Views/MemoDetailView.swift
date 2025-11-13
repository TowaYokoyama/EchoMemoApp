
import SwiftUI

struct MemoDetailView: View {
    let memo: Memo
    @StateObject private var viewModel = MemoDetailViewModel()
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // タイトル
                Text(memo.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // メタ情報
                HStack {
                    Text(memo.createdAt.formatted())
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                    
                    // TODO: 位置情報機能は将来実装予定
                }
                
                Divider()
                
                // 音声プレーヤー
                if !memo.audioURL.isEmpty, let url = URL(string: memo.audioURL) {
                    AudioPlayerView(audioURL: url)
                        .padding(.vertical)
                }
                
                // コンテンツ
                Text(memo.content)
                    .font(.body)
                    .foregroundColor(.theme.text)
                
                // タグ
                if !memo.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タグ")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(memo.tags, id: \.self) { tag in
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
        .sheet(isPresented: $showingEdit) {
            EditMemoView(memo: memo)
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
        .background(Color.theme.secondaryBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// FlowLayoutヘルパー
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationView {
        MemoDetailView(memo: Memo.preview)
    }
}
