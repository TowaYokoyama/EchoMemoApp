

import SwiftUI

struct EditMemoView: View {
    let memo: Memo
    @StateObject private var viewModel = EditMemoViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("タイトル") {
                    TextField("タイトル", text: $viewModel.title)
                }
                
                Section("内容") {
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 200)
                }
                
                Section("タグ") {
                    TextField("タグ（カンマ区切り）", text: $viewModel.tagsString)
                    
                    if !viewModel.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                TagView(tag: tag)
                            }
                        }
                    }
                }
            }
            .navigationTitle("メモを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.save(memo: memo)
                            if viewModel.isSaved {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                viewModel.setup(memo: memo)
            }
            .alert(error: $viewModel.error)
        }
    }
}

class EditMemoViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var tagsString = ""
    @Published var isSaving = false
    @Published var isSaved = false
    @Published var error: Error?
    
    var tags: [String] {
        tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    
    func setup(memo: Memo) {
        title = memo.title
        content = memo.content
        tagsString = memo.tags.joined(separator: ", ")
    }
    
    @MainActor
    func save(memo: Memo) async {
        isSaving = true
        error = nil
        
        do {
            _ = try await MemoService.shared.updateMemo(
                id: memo.id,
                title: title,
                content: content,
                tags: tags
            )
            isSaved = true
        } catch {
            self.error = error
        }
        
        isSaving = false
    }
}
