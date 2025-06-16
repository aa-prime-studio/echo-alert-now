import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用說明")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        HelpSection(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "緊急訊號",
                            content: "快速發送求救訊號：\n• 藍色「我安全」- 告知他人您的安全狀況\n• 紫色「需要物資」- 請求食物、水或其他物資\n• 紅色「需要醫療」- 緊急醫療協助\n• 黃色「危險警告」- 警告他人周遭危險"
                        )
                        
                        HelpSection(
                            icon: "message",
                            title: "聊天室功能",
                            content: "與附近使用者溝通：\n• 輸入文字訊息並發送\n• 查看其他人的訊息\n• 訊息會在24小時後自動刪除\n• 支援最多50條訊息記錄"
                        )
                        
                        HelpSection(
                            icon: "gamecontroller",
                            title: "賓果遊戲",
                            content: "多人連線娛樂功能：\n• 需要付費解鎖\n• 3個遊戲房間可選擇\n• 與其他玩家即時互動\n• 自動產生隨機賓果卡"
                        )
                        
                        HelpSection(
                            icon: "gear",
                            title: "設定選項",
                            content: "個人化設定：\n• 切換語言（中文/English）\n• 查看訂購狀態\n• 升級到付費版本\n• 恢復之前的購買"
                        )
                        
                        HelpSection(
                            icon: "location",
                            title: "位置資訊",
                            content: "距離與方向顯示：\n• 自動計算與訊號源的距離\n• 顯示相對方向（北、東南等）\n• 僅用於改善使用體驗\n• 可在設定中關閉位置服務"
                        )
                        
                        HelpSection(
                            icon: "exclamationmark.triangle",
                            title: "注意事項",
                            content: "使用時請注意：\n• 確保裝置有足夠電量\n• 在真正緊急情況下，請同時聯繫官方救援單位\n• 不要濫用緊急訊號功能\n• 保持裝置在通訊範圍內"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("使用說明")
        .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
