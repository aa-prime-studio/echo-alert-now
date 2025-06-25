import SwiftUI

struct TermsOfServiceView: View {
    @EnvironmentObject var languageService: LanguageService
    
    private var currentLanguage: String {
        return languageService.currentLanguage == .english ? "en-US" : "zh-TW"
    }
    
    var body: some View {
        LegalDocumentView(
            title: LegalContent.getTermsOfServiceTitle(language: currentLanguage),
            content: LegalContent.getTermsOfService(language: currentLanguage)
        )
    }
} 