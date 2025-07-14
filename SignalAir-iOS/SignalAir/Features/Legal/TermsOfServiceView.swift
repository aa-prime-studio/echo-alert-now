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
                    TermsTextView(
                        title: TermsOfServiceContent.getTermsTitle(language: currentLanguage),
                        lastUpdated: TermsOfServiceContent.getLastUpdated(language: currentLanguage),
                        intro: TermsOfServiceContent.getTermsIntro(language: currentLanguage),
                        sections: [
                            (TermsOfServiceContent.getCorePrinciplesTitle(language: currentLanguage), TermsOfServiceContent.getCorePrinciplesContent(language: currentLanguage)),
                            (TermsOfServiceContent.getAcceptanceTitle(language: currentLanguage), TermsOfServiceContent.getAcceptanceContent(language: currentLanguage)),
                            (TermsOfServiceContent.getSystemTitle(language: currentLanguage), TermsOfServiceContent.getSystemContent(language: currentLanguage)),
                            (TermsOfServiceContent.getEnforcementTitle(language: currentLanguage), TermsOfServiceContent.getEnforcementContent(language: currentLanguage)),
                            (TermsOfServiceContent.getEmergencyTitle(language: currentLanguage), TermsOfServiceContent.getEmergencyContent(language: currentLanguage)),
                            (TermsOfServiceContent.getDisputeTitle(language: currentLanguage), TermsOfServiceContent.getDisputeContent(language: currentLanguage)),
                            (TermsOfServiceContent.getDataControlTitle(language: currentLanguage), TermsOfServiceContent.getDataControlContent(language: currentLanguage)),
                            (TermsOfServiceContent.getIntellectualTitle(language: currentLanguage), TermsOfServiceContent.getIntellectualContent(language: currentLanguage)),
                            (TermsOfServiceContent.getAmendmentsTitle(language: currentLanguage), TermsOfServiceContent.getAmendmentsContent(language: currentLanguage)),
                            (TermsOfServiceContent.getInternationalTitle(language: currentLanguage), TermsOfServiceContent.getInternationalContent(language: currentLanguage)),
                            (TermsOfServiceContent.getServiceChangesTitle(language: currentLanguage), TermsOfServiceContent.getServiceChangesContent(language: currentLanguage)),
                            (TermsOfServiceContent.getPurchaseTitle(language: currentLanguage), TermsOfServiceContent.getPurchaseContent(language: currentLanguage)),
                            (TermsOfServiceContent.getExportControlTitle(language: currentLanguage), TermsOfServiceContent.getExportControlContent(language: currentLanguage)),
                            (TermsOfServiceContent.getGeneralTitle(language: currentLanguage), TermsOfServiceContent.getGeneralContent(language: currentLanguage)),
                            (TermsOfServiceContent.getClosingTitle(language: currentLanguage), TermsOfServiceContent.getClosingContent(language: currentLanguage)),
                            (TermsOfServiceContent.getContactTitle(language: currentLanguage), TermsOfServiceContent.getContactContent(language: currentLanguage))
                        ]
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationTitle("Terms of Service")
        }
    }
}

struct TermsTextView: View {
    let title: String
    let lastUpdated: String
    let intro: String
    let sections: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Last Updated
            Text(lastUpdated)
                .font(.subheadline.weight(.regular))
                .foregroundColor(.black)
                .lineSpacing(16)
            
            // Intro
            Text(intro)
                .font(.subheadline.weight(.regular))
                .foregroundColor(.black)
                .lineSpacing(16)
            
            // Sections
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 16) {
                    // Section Title
                    Text(cleanSectionTitle(section.0))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .lineSpacing(16)
                    
                    // Section Content
                    Text(section.1)
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(.black)
                        .lineSpacing(16)
                }
            }
        }
    }
    
    private func cleanSectionTitle(_ title: String) -> String {
        if let range = title.range(of: " / ") {
            return String(title[..<range.lowerBound])
        }
        return title
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
