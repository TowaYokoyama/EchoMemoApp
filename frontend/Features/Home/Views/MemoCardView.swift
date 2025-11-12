
import SwiftUI

struct MemoCardView: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            Text(memo.title)
                .font(.headline)
                .foregroundColor(.theme.text)
                .lineLimit(2)
            
            // コンテンツ
            Text(memo.content)
                .font(.subheadline)
                .foregroundColor(.theme.secondaryText)
                .lineLimit(3)
            
            // タグ
            if !memo.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(memo.tags, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
            
            // メタ情報
            HStack {
                if !memo.audioURL.isEmpty {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.theme.accent)
                }
                
                Spacer()
                
                Text(memo.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.theme.secondaryText)
            }
        }
        .padding()
        .cardStyle()
    }
}

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.theme.primary.opacity(0.1))
            .foregroundColor(.theme.primary)
            .cornerRadius(6)
    }
}

#Preview {
    MemoCardView(memo: Memo.preview)
        .padding()
}
