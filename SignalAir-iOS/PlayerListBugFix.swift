import Foundation
import SwiftUI

// MARK: - 🔧 本機玩家未顯示問題修復方案

/// 修復本機玩家在 PlayerListView 中未顯示的問題
/// 
/// 問題根源：NicknameFormatter.cleanNickname() 的清理邏輯可能導致
/// PlayerState.name 和 deviceName 經過清理後不匹配
struct PlayerListBugFix {
    
    /// 修復方案 1: 統一在創建 PlayerState 時就清理名稱
    static func fixPlayerStateCreation() -> String {
        return """
        // 在 BingoGameViewModel 中修復創建 PlayerState 的邏輯
        
        // 修復前 (可能有問題的版本):
        let initialPlayer = PlayerState(id: playerID, name: deviceName)
        
        // 修復後 (確保名稱一致):
        let cleanedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let initialPlayer = PlayerState(id: playerID, name: cleanedDeviceName)
        
        // 同時更新 deviceName 屬性以保持一致性:
        self.deviceName = cleanedDeviceName
        """
    }
    
    /// 修復方案 2: 改進 PlayerListView 的匹配邏輯
    static func fixPlayerListViewMatching() -> String {
        return """
        // 在 PlayerListView 中使用更寬鬆的匹配邏輯
        
        // 修復前 (嚴格匹配):
        if NicknameFormatter.cleanNickname(player.name) == NicknameFormatter.cleanNickname(deviceName) {
            // 顯示本機玩家標識
        }
        
        // 修復後 (多重匹配檢查):
        private func isLocalPlayer(_ player: RoomPlayer, deviceName: String) -> Bool {
            let cleanPlayerName = NicknameFormatter.cleanNickname(player.name)
            let cleanDeviceName = NicknameFormatter.cleanNickname(deviceName)
            
            // 1. 直接清理後比較
            if cleanPlayerName == cleanDeviceName {
                return true
            }
            
            // 2. 原始名稱比較
            if player.name == deviceName {
                return true
            }
            
            // 3. 處理默認名稱情況
            if (cleanPlayerName == "用戶" && (cleanDeviceName == "使用者" || cleanDeviceName.isEmpty)) ||
               (cleanDeviceName == "用戶" && (cleanPlayerName == "使用者" || cleanPlayerName.isEmpty)) {
                return true
            }
            
            return false
        }
        """
    }
    
    /// 修復方案 3: 在 ViewModel 層統一處理名稱
    static func fixViewModelLayer() -> String {
        return """
        // 在 GameViewModel 或 BingoGameViewModel 中統一處理名稱格式
        
        // 添加計算屬性確保名稱一致性:
        var normalizedDeviceName: String {
            return NicknameFormatter.cleanNickname(deviceName)
        }
        
        var normalizedRoomPlayers: [RoomPlayer] {
            return bingoViewModel.roomPlayers.map { playerState in
                RoomPlayer(
                    name: NicknameFormatter.cleanNickname(playerState.name),
                    completedLines: playerState.completedLines,
                    hasWon: playerState.hasWon
                )
            }
        }
        
        // 在 PlayerListView 中使用:
        PlayerListView(
            players: normalizedRoomPlayers,
            deviceName: normalizedDeviceName
        )
        """
    }
}

// MARK: - 🚀 推薦的修復實現

/// 實際的修復代碼實現
extension PlayerListBugFix {
    
    /// 推薦修復：改進 PlayerListView 的本機玩家識別邏輯
    struct ImprovedPlayerListView: View {
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
                            // 改進的本機玩家識別邏輯
                            HStack(spacing: 8) {
                                if isLocalPlayer(player, deviceName: deviceName) {
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894))
                                }
                                
                                Text(NicknameFormatter.cleanNickname(player.name))
                                    .font(.subheadline)
                                    .fontWeight(isLocalPlayer(player, deviceName: deviceName) ? .semibold : .regular)
                                    .foregroundColor(isLocalPlayer(player, deviceName: deviceName) ? Color(red: 0.149, green: 0.243, blue: 0.894) : .primary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text("\\(player.completedLines)\\(languageService.t("lines_score"))")
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
        
        /// 改進的本機玩家識別邏輯
        private func isLocalPlayer(_ player: RoomPlayer, deviceName: String) -> Bool {
            // 1. 標準清理後比較
            let cleanPlayerName = NicknameFormatter.cleanNickname(player.name)
            let cleanDeviceName = NicknameFormatter.cleanNickname(deviceName)
            
            if cleanPlayerName == cleanDeviceName {
                return true
            }
            
            // 2. 原始名稱比較（避免清理邏輯差異）
            if player.name.trimmingCharacters(in: .whitespacesAndNewlines) == 
               deviceName.trimmingCharacters(in: .whitespacesAndNewlines) {
                return true
            }
            
            // 3. 處理默認名稱的特殊情況
            let defaultNames = ["用戶", "使用者", "User", "iPhone", "iPad"]
            if defaultNames.contains(cleanPlayerName) && defaultNames.contains(cleanDeviceName) {
                // 對於默認名稱，可能需要其他識別方式
                // 這裡可以考慮使用 playerID 比較，但需要額外的邏輯
                return true
            }
            
            return false
        }
    }
    
    /// BingoGameViewModel 中的修復
    static func fixBingoGameViewModelCreation() -> String {
        return """
        // 在所有創建 PlayerState 的地方統一使用清理後的名稱
        
        // createGameRoom() 修復:
        func createGameRoom() {
            // ... 其他邏輯 ...
            
            let cleanedDeviceName = NicknameFormatter.cleanNickname(deviceName)
            let initialPlayer = PlayerState(id: playerID, name: cleanedDeviceName)
            roomPlayers = [initialPlayer]
            
            // 同步更新 deviceName 以保持一致性
            self.deviceName = cleanedDeviceName
            
            // ... 其他邏輯 ...
        }
        
        // joinGameRoom() 修復:
        func joinGameRoom(_ roomID: String) {
            // ... 其他邏輯 ...
            
            let cleanedDeviceName = NicknameFormatter.cleanNickname(deviceName)
            let localPlayer = PlayerState(id: playerID, name: cleanedDeviceName)
            roomPlayers = [localPlayer]
            
            self.deviceName = cleanedDeviceName
            
            // ... 其他邏輯 ...
        }
        """
    }
}

// MARK: - 🔍 診斷工具增強版

extension PlayerListBugFix {
    
    /// 增強的診斷工具，專門檢查名稱匹配問題
    static func diagnoseName(playerName: String, deviceName: String) {
        print("🔍 名稱匹配診斷:")
        print("原始玩家名稱: '\\(playerName)'")
        print("原始設備名稱: '\\(deviceName)'")
        
        let cleanPlayer = NicknameFormatter.cleanNickname(playerName)
        let cleanDevice = NicknameFormatter.cleanNickname(deviceName)
        
        print("清理後玩家名稱: '\\(cleanPlayer)'")
        print("清理後設備名稱: '\\(cleanDevice)'")
        print("是否匹配: \\(cleanPlayer == cleanDevice)")
        
        // 檢查可能的問題
        if playerName == "使用者" || deviceName == "使用者" {
            print("⚠️ 發現'使用者'默認名稱，可能被轉換為'用戶'")
        }
        
        if cleanPlayer != cleanDevice {
            print("❌ 名稱不匹配！這可能是本機玩家不顯示的原因")
        } else {
            print("✅ 名稱匹配正常")
        }
    }
}