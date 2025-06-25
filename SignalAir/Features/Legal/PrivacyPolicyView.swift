import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject var languageService: LanguageService
    
    private var currentLanguage: String {
        return languageService.currentLanguage == .english ? "en-US" : "zh-TW"
    }
    
    var body: some View {
        LegalDocumentView(
            title: LegalContent.getPrivacyPolicyTitle(language: currentLanguage),
            content: LegalContent.getPrivacyPolicy(language: currentLanguage)
        )
    }
} 