import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct TermsOfServiceView: View {
    @EnvironmentObject var languageService: LanguageService
    
    private var currentLanguage: TermsOfServiceContent.Language {
        return languageService.currentLanguage == .english ? .english : .chinese
    }
    
    private var content: String {
        return TermsOfServiceContent.getFullContent(language: currentLanguage)
    }
    
    private var title: String {
        return languageService.currentLanguage == .english ? "Terms of Service" : "服務條款"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(content)
                        .font(.body)
                        .lineSpacing(8)
                        .padding(.horizontal, 20)
                        .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationTitle("Terms of Service")
        }
    }
}

// 內部服務條款文字顯示元件
struct TermsTextViewInternal: UIViewRepresentable {
    let text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 8
    var paragraphSpacing: CGFloat = 16
    var horizontalPadding: CGFloat = 20
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        
        textView.attributedText = createAttributedText()
        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: 0,
            right: horizontalPadding
        )
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        paragraphStyle.tailIndent = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label,
            .kern: 0.3
        ]
        
        let processedText = processTextForPunctuation(text)
        return NSAttributedString(string: processedText, attributes: attributes)
    }
    
    private func processTextForPunctuation(_ text: String) -> String {
        let prohibitedAtLineStart = ["。", "，", "、", "；", "：", "？", "！", "）", "」", "』", "》", "〉", "】", "〕", "｝", "％", "‰", ".", ",", "?", "!", ":", ";", ")", "]", "}"]
        let prohibitedAtLineEnd = ["（", "「", "『", "《", "〈", "【", "〔", "｛", "(", "[", "{"]
        
        var processedText = text
        
        for punctuation in prohibitedAtLineStart {
            processedText = processedText.replacingOccurrences(
                of: punctuation,
                with: "\u{FEFF}\(punctuation)"
            )
        }
        
        for punctuation in prohibitedAtLineEnd {
            processedText = processedText.replacingOccurrences(
                of: punctuation,
                with: "\(punctuation)\u{FEFF}"
            )
        }
        
        return processedText
    }
}
