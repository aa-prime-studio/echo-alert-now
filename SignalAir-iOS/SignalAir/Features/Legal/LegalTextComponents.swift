import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// 簡化的法律文字顯示元件
struct SimpleLegalTextView: UIViewRepresentable {
    let text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        
        // 段落樣式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified  // 左右對齊
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 16
        
        // 基本屬性
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
        
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // 更新邏輯
    }
}

// 法律文件視圖包裝器
struct SimpleLegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SimpleLegalTextView(text: content)
                        .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}

// 法律內容
struct SimpleLegalContent {
    static func getPrivacyPolicy(language: String = "zh-TW") -> String {
        if language.contains("en") {
            return "SignalAir Rescue Privacy Policy\n\nThis is a simplified privacy policy for testing purposes."
        } else {
            return "SignalAir Rescue 隱私權政策\n\n這是一個簡化的隱私政策，用於測試目的。"
        }
    }
    
    static func getTermsOfService(language: String = "zh-TW") -> String {
        if language.contains("en") {
            return "SignalAir Rescue Terms of Service\n\nThis is a simplified terms of service for testing purposes."
        } else {
            return "SignalAir Rescue 服務條款\n\n這是一個簡化的服務條款，用於測試目的。"
        }
    }
    
    static func getPrivacyPolicyTitle(language: String = "zh-TW") -> String {
        return language.contains("en") ? "Privacy Policy" : "隱私權政策"
    }
    
    static func getTermsOfServiceTitle(language: String = "zh-TW") -> String {
        return language.contains("en") ? "Terms of Service" : "服務條款"
    }
}
