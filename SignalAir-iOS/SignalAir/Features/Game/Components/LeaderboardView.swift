import SwiftUI

struct LeaderboardView: View {
    let leaderboard: [BingoScore]
    @State private var weeklyLeaderboard: WeeklyLeaderboard?
    @State private var selectedBoard: Int = 0 // 0: 勝場榜, 1: DJ榜, 2: 等車榜
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageService.t("this_week_leaderboard"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 排行榜類型選擇器
            Picker("排行榜類型", selection: $selectedBoard) {
                Text(languageService.t("bingo_god")).tag(0)
                Text(languageService.t("are_you_dj")).tag(1)
                Text(languageService.t("turtle_god")).tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 8)
            
            // 如果本週排行榜可用，顯示本週數據，否則顯示日榜數據作為後備
            if let weekly = weeklyLeaderboard {
                VStack(spacing: 12) {
                    // 根據選擇的類型顯示對應的排行榜
                    let (currentBoard, unitText) = getCurrentBoardData(for: selectedBoard, from: weekly)
                    
                    if currentBoard.isEmpty {
                        Text(languageService.t("no_leaderboard_data"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(currentBoard.prefix(3).enumerated()), id: \.element.id) { index, score in
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
                                Text(score.nickname)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Score with appropriate unit
                                Text(formatScoreWithUnit(score.value, unit: unitText))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else if leaderboard.isEmpty {
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
                            Text(NicknameFormatter.cleanNickname(score.deviceName))
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
        .onAppear {
            loadWeeklyLeaderboard()
        }
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
    
    // MARK: - 本週排行榜數據管理
    
    /// 加載本週排行榜數據
    private func loadWeeklyLeaderboard() {
        let weekStartTime = getThisWeekMonday()
        
        // 嘗試從二進制存儲加載
        if let weeklyData = loadWeeklyLeaderboardFromBinaryStorage(weekStartTime: weekStartTime) {
            weeklyLeaderboard = weeklyData
        } else {
            // 如果沒有數據，創建空的本週排行榜
            weeklyLeaderboard = WeeklyLeaderboard(weekStartTime: weekStartTime)
        }
    }
    
    /// 從二進制存儲加載本週排行榜
    private func loadWeeklyLeaderboardFromBinaryStorage(weekStartTime: Date) -> WeeklyLeaderboard? {
        let weekTimestamp = Int(weekStartTime.timeIntervalSince1970)
        
        // 載入三種類型的排行榜
        let winsBoard = loadLeaderboardByType(.wins, weekTimestamp: weekTimestamp)
        let djBoard = loadLeaderboardByType(.interactions, weekTimestamp: weekTimestamp) 
        let reactionBoard = loadLeaderboardByType(.reaction, weekTimestamp: weekTimestamp)
        
        // 如果至少有一個排行榜有數據，就返回WeeklyLeaderboard
        if !winsBoard.isEmpty || !djBoard.isEmpty || !reactionBoard.isEmpty {
            return WeeklyLeaderboard(
                weekStartTime: weekStartTime,
                winsBoard: winsBoard,
                djBoard: djBoard,
                reactionBoard: reactionBoard
            )
        }
        
        return nil
    }
    
    /// 根據類型載入特定排行榜數據 - 安全解包避免崩潰
    private func loadLeaderboardByType(_ type: BinaryGameProtocol.LeaderboardType, weekTimestamp: Int) -> [WeeklyScore] {
        let weekKey = "SignalAir_WeeklyLeaderboard_\(type.rawValue)_\(weekTimestamp)"
        
        guard let data = UserDefaults.standard.data(forKey: weekKey) else {
            print("❌ 無法獲取排行榜數據: \(weekKey)")
            return []
        }
        
        // 安全解包二進制數據，避免崩潰
        guard let decodedResult = BinaryGameProtocol.decodeWeeklyLeaderboard(data) else {
            print("❌ 無法解碼排行榜數據: \(weekKey)")
            return []
        }
        
        let (_, _, entries) = decodedResult
        
        // 將解碼的條目轉換為WeeklyScore
        return entries.map { entry in
            WeeklyScore(
                playerID: entry.playerID,
                nickname: entry.nickname,
                value: entry.value
            )
        }
    }
    
    /// 獲取本週一00:00的時間戳
    private func getThisWeekMonday() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 獲取本週一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 週一
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    /// 格式化分數顯示
    private func formatScoreWithUnit(_ value: Float, unit: String) -> String {
        switch unit {
        case "秒":
            // 將毫秒轉換為秒，並顯示一位小數
            let seconds = value / 1000.0
            return String(format: "%.1f%@", seconds, unit)
        case "次":
            return "\(Int(value))\(unit)"
        default:
            return "\(Int(value))\(unit)"
        }
    }
    
    /// 根據選擇的類型返回對應的排行榜數據和單位
    private func getCurrentBoardData(for selectedBoard: Int, from weekly: WeeklyLeaderboard) -> ([WeeklyScore], String) {
        switch selectedBoard {
        case 0:
            return (weekly.winsBoard, "勝")
        case 1:
            return (weekly.djBoard, "次")
        case 2:
            return (weekly.reactionBoard, "秒")
        default:
            return (weekly.winsBoard, "勝")
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