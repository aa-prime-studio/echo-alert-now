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
                    Text(content)
                        .font(.body)
                        .lineSpacing(8)
                        .padding(.horizontal, 20)
                        .padding(.vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
