import SwiftUI

struct HelpView: View {
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(languageService.t("help_guide"))
                    .font(.subheadline.weight(.bold))
                    .lineSpacing(16)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        HelpSection(
                            icon: "antenna.radiowaves.left.and.right",
                            title: languageService.t("emergency_signals"),
                            content: languageService.t("emergency_signals_content")
                        )
                        
                        HelpSection(
                            icon: "message",
                            title: languageService.t("chat_functions"),
                            content: languageService.t("chat_functions_content")
                        )
                        
                        HelpSection(
                            icon: "gamecontroller",
                            title: languageService.t("bingo_game"),
                            content: languageService.t("bingo_game_content")
                        )
                        
                        HelpSection(
                            icon: "gear",
                            title: languageService.t("settings_options"),
                            content: languageService.t("settings_options_content")
                        )
                        
                        HelpSection(
                            icon: "location",
                            title: languageService.t("location_info"),
                            content: languageService.t("location_info_content")
                        )
                        
                        HelpSection(
                            icon: "exclamationmark.triangle",
                            title: languageService.t("important_notes"),
                            content: languageService.t("important_notes_content")
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(languageService.t("help_guide"))
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineSpacing(16)
            }
            
            Text(content)
                .font(.subheadline.weight(.regular))
                .lineSpacing(16)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
