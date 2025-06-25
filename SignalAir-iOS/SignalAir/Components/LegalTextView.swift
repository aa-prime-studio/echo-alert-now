import SwiftUI
import UIKit

// 專業法律文字顯示元件
struct LegalTextView: UIViewRepresentable {
    let text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 8
    var paragraphSpacing: CGFloat = 16
    var horizontalPadding: CGFloat = 20  // 左右邊距
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        
        // 設定文字內容
        textView.attributedText = createAttributedText()
        
        // 設定內邊距
        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: 0,
            right: horizontalPadding
        )
        
        // 移除額外的內邊距
        textView.textContainer.lineFragmentPadding = 0
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = createAttributedText()
        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: 0,
            right: horizontalPadding
        )
    }
    
    private func createAttributedText() -> NSAttributedString {
        // 段落樣式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified  // 左右對齊
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        paragraphStyle.tailIndent = 0
        
        // 避頭點設定（中文標點符號規則）
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // 基本屬性
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label,
            .kern: 0.3  // 字元間距
        ]
        
        // 處理避頭點
        let processedText = processTextForPunctuation(text)
        
        return NSAttributedString(string: processedText, attributes: attributes)
    }
    
    // 處理避頭點的邏輯
    private func processTextForPunctuation(_ text: String) -> String {
        // 需要避免出現在行首的標點符號（避頭點）
        let prohibitedAtLineStart = ["。", "，", "、", "；", "：", "？", "！", "）", "」", "』", "》", "〉", "】", "〕", "｝", "％", "‰", ".", ",", "?", "!", ":", ";", ")", "]", "}"]
        
        // 需要避免出現在行尾的標點符號（避尾點）
        let prohibitedAtLineEnd = ["（", "「", "『", "《", "〈", "【", "〔", "｛", "(", "[", "{"]
        
        var processedText = text
        
        // 處理避頭點：在標點符號前加入零寬度不換行空格
        for punctuation in prohibitedAtLineStart {
            processedText = processedText.replacingOccurrences(
                of: punctuation,
                with: "\u{FEFF}\(punctuation)"
            )
        }
        
        // 處理避尾點：在標點符號後加入零寬度不換行空格
        for punctuation in prohibitedAtLineEnd {
            processedText = processedText.replacingOccurrences(
                of: punctuation,
                with: "\(punctuation)\u{FEFF}"
            )
        }
        
        return processedText
    }
}

// SwiftUI 包裝器 - 最終使用介面
struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LegalTextView(
                        text: content,
                        fontSize: 16,
                        lineSpacing: 8,
                        paragraphSpacing: 16,
                        horizontalPadding: 20
                    )
                    .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
        .background(Color(UIColor.systemBackground))
    }
}
