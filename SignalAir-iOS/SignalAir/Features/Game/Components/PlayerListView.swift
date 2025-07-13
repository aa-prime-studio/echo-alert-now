import SwiftUI

struct PlayerListView: View {
    let players: [RoomPlayer]
    let deviceName: String
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageService.t("room_players"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(players) { player in
                    HStack {
                        // Player name with indicator for self
                        HStack(spacing: 8) {
                            if isLocalPlayer(player, deviceName: deviceName) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                            }
                            
                            Text(NicknameFormatter.cleanNickname(player.name))
                                .font(.subheadline)
                                .fontWeight(isLocalPlayer(player, deviceName: deviceName) ? .semibold : .regular)
                                .foregroundColor(isLocalPlayer(player, deviceName: deviceName) ? Color(red: 0.149, green: 0.243, blue: 0.894) : .primary)
                        }
                        
                        Spacer()
                        
                        // Progress and status
                        HStack(spacing: 8) {
                            Text("\(player.completedLines)\(languageService.t("lines_score"))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            if player.hasWon {
                                Text("🎉")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        isLocalPlayer(player, deviceName: deviceName) ? 
                        Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.1) : 
                        Color.clear
                    )
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    /// 改進的本機玩家識別邏輯，解決名稱清理差異問題
    private func isLocalPlayer(_ player: RoomPlayer, deviceName: String) -> Bool {
        // 1. 標準清理後比較
        let cleanPlayerName = NicknameFormatter.cleanNickname(player.name)
        let cleanDeviceName = NicknameFormatter.cleanNickname(deviceName)
        
        if cleanPlayerName == cleanDeviceName {
            return true
        }
        
        // 2. 原始名稱比較（避免清理邏輯差異）
        let trimmedPlayerName = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDeviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedPlayerName == trimmedDeviceName {
            return true
        }
        
        // 3. 處理默認名稱的特殊情況（'使用者' vs '用戶'）
        let isPlayerDefault = ["用戶", "使用者", "User"].contains(cleanPlayerName)
        let isDeviceDefault = ["用戶", "使用者", "User"].contains(cleanDeviceName)
        
        if isPlayerDefault && isDeviceDefault {
            return true
        }
        
        // 4. 處理空名稱情況
        if (cleanPlayerName.isEmpty || cleanPlayerName == "用戶") && 
           (cleanDeviceName.isEmpty || cleanDeviceName == "用戶" || cleanDeviceName == "使用者") {
            return true
        }
        
        return false
    }
}

#Preview {
    PlayerListView(
        players: [
            RoomPlayer(name: "BingoKing", completedLines: 3, hasWon: false),
            RoomPlayer(name: "iPhone", completedLines: 2, hasWon: false),
            RoomPlayer(name: "LuckyStrike", completedLines: 6, hasWon: true),
            RoomPlayer(name: "NumberHunter", completedLines: 1, hasWon: false)
        ],
        deviceName: "iPhone"
    )
} 