import SwiftUI

struct LeaderboardView: View {
    let leaderboard: [BingoScore]
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageService.t("todays_leaderboard"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if leaderboard.isEmpty {
                Text(languageService.t("no_leaderboard_data"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(leaderboard.prefix(5).enumerated()), id: \.element.id) { index, score in
                        HStack {
                            // Rank badge
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(rankTextColor(for: index))
                                .frame(width: 20, height: 20)
                                .background(rankBackgroundColor(for: index))
                                .cornerRadius(10)
                            
                            // Player name
                            Text(score.deviceName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Score
                            Text("\(score.score)\(languageService.t("lines_score"))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func rankBackgroundColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow.opacity(0.2)
        case 1: return Color.gray.opacity(0.2)
        case 2: return Color.orange.opacity(0.2)
        default: return Color.blue.opacity(0.1)
        }
    }
    
    private func rankTextColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow.opacity(0.8)
        case 1: return Color.gray.opacity(0.7)
        case 2: return Color.orange.opacity(0.7)
        default: return Color.blue.opacity(0.6)
        }
    }
}

#Preview {
    LeaderboardView(
        leaderboard: [
            BingoScore(deviceName: "BingoMaster", score: 6, timestamp: Date().timeIntervalSince1970, date: "2024-01-01"),
            BingoScore(deviceName: "LineHunter", score: 5, timestamp: Date().timeIntervalSince1970, date: "2024-01-01"),
            BingoScore(deviceName: "NumberWiz", score: 4, timestamp: Date().timeIntervalSince1970, date: "2024-01-01"),
            BingoScore(deviceName: "LuckyPlayer", score: 3, timestamp: Date().timeIntervalSince1970, date: "2024-01-01")
        ]
    )
    .padding()
} 