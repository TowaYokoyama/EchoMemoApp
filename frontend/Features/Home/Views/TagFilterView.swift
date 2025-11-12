
import SwiftUI

struct TagFilterView: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    let onToggle: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    FilterTagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: { onToggle(tag) }
                    )
                }
            }
        }
    }
}

struct FilterTagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.theme.primary : Color.theme.secondaryBackground)
                .foregroundColor(isSelected ? .white : .theme.text)
                .cornerRadius(16)
        }
    }
}

#Preview {
    TagFilterView(
        tags: ["仕事", "アイデア", "メモ"],
        selectedTags: .constant(["仕事"]),
        onToggle: { _ in }
    )
    .padding()
}
