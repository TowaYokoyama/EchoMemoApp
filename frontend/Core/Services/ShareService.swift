
import Foundation
import UIKit

/// シェア機能を提供するサービスクラス
class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    /// メモをシェア用にフォーマット
    func shareMemo(_ memo: Memo) -> ShareContent {
        let formattedText = formatMemoText(memo)
        return ShareContent(
            text: formattedText,
            url: nil,
            subject: memo.title
        )
    }
    
    /// ボイスレコーディングをシェア用に準備
    func shareVoice(audioURL: String, title: String) -> ShareContent {
        let url = URL(string: audioURL)
        return ShareContent(
            text: title,
            url: url,
            subject: title
        )
    }
    
    /// LINEアプリがインストールされているかチェック
    func isLINEAvailable() -> Bool {
        guard let lineURL = URL(string: "line://") else { return false }
        return UIApplication.shared.canOpenURL(lineURL)
    }
    
    /// メモをテキストとしてフォーマット
    private func formatMemoText(_ memo: Memo) -> String {
        var text = "タイトル: \(memo.title)\n\n"
        text += "\(memo.content)\n"
        
        if !memo.tags.isEmpty {
            text += "\nタグ: \(memo.tags.joined(separator: ", "))"
        }
        
        return text
    }
}

/// シェアするコンテンツを表す構造体
struct ShareContent {
    let text: String?
    let url: URL?
    let subject: String?
}
