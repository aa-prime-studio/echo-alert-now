import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject var languageService: LanguageService
    
    private var currentLanguage: PrivacyPolicyContent.Language {
        return languageService.currentLanguage == .english ? .english : .chinese
    }
    
    private var content: String {
        return PrivacyPolicyContent.getFullContent(language: currentLanguage)
    }
    
    private var title: String {
        return languageService.currentLanguage == .english ? "Privacy Policy" : "隱私權政策"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PrivacyTextView(
                        title: "SignalAir Rescue 隱私權政策",
                        lastUpdated: PrivacyPolicyContent.getLastUpdated(language: currentLanguage),
                        intro: PrivacyPolicyContent.getPrivacyPolicyIntro(language: currentLanguage),
                        sections: [
                            (PrivacyPolicyContent.getDataCollectionTitle(language: currentLanguage), PrivacyPolicyContent.getDataCollectionContent(language: currentLanguage)),
                            (PrivacyPolicyContent.getDataSharingTitle(language: currentLanguage), PrivacyPolicyContent.getDataSharingContent(language: currentLanguage)),
                            (PrivacyPolicyContent.getUserRightsTitle(language: currentLanguage), PrivacyPolicyContent.getUserRightsContent(language: currentLanguage)),
                            (PrivacyPolicyContent.getDataSecurityTitle(language: currentLanguage), PrivacyPolicyContent.getDataSecurityContent(language: currentLanguage)),
                            (PrivacyPolicyContent.getDataControlTitle(language: currentLanguage), PrivacyPolicyContent.getDataControlContent(language: currentLanguage)),
                            (PrivacyPolicyContent.getContactTitle(language: currentLanguage), PrivacyPolicyContent.getContactContent(language: currentLanguage))
                        ]
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PrivacyTextView: View {
    let title: String
    let lastUpdated: String
    let intro: String
    let sections: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Last Updated
            Text(lastUpdated)
                .font(.subheadline.weight(.thin))
                .foregroundColor(.black)
                .lineSpacing(16)
            
            // Intro
            Text(intro)
                .font(.subheadline.weight(.thin))
                .foregroundColor(.black)
                .lineSpacing(16)
            
            // Sections
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 16) {
                    // Section Title
                    Text(cleanSectionTitle(section.0))
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(.black)
                        .lineSpacing(16)
                    
                    // Section Content
                    Text(section.1)
                        .font(.subheadline.weight(.thin))
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
