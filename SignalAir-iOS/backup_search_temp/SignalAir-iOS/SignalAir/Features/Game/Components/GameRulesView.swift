import SwiftUI

struct GameRulesView: View {
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageService.t("game_rules"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 20) {
                RuleItem(
                    icon: "number.circle",
                    title: languageService.t("number_range"),
                    description: languageService.t("number_range_desc")
                )
                
                RuleItem(
                    icon: "target",
                    title: languageService.t("win_condition"),
                    description: languageService.t("win_condition_desc")
                )
                
                RuleItem(
                    icon: "calendar",
                    title: languageService.t("daily_leaderboard"),
                    description: languageService.t("daily_leaderboard_desc")
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct RuleItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                .frame(width: 40, height: 40)
                .background(Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
                .cornerRadius(20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    GameRulesView()
        .padding()
} 