import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("服務條款")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最後更新：2024年1月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        TermsSection(
                            title: "服務說明",
                            content: "SignalAir 提供緊急情況下的通訊服務，包括：\n• 緊急訊號發送\n• 附近裝置通訊\n• 聊天室功能\n• 娛樂遊戲功能"
                        )
                        
                        TermsSection(
                            title: "使用限制",
                            content: "使用本服務時，您同意：\n• 不濫用緊急訊號功能\n• 不發送違法或不當內容\n• 尊重其他使用者\n• 遵守當地法律法規"
                        )
                        
                        WarningSection(
                            title: "免責聲明",
                            content: "• SignalAir 無法保證在所有情況下都能正常運作\n• 不應完全依賴本應用程式進行緊急救援\n• 建議同時使用官方緊急救援系統\n• 使用者需自行承擔使用風險"
                        )
                        
                        WarningSection(
                            title: "技術限制",
                            content: "本服務可能受以下因素影響：\n• 裝置電量不足\n• 網路連線品質\n• 系統相容性問題\n• 硬體故障"
                        )
                        
                        TermsSection(
                            title: "購買條款",
                            content: "付費功能說明：\n• 所有購買均為一次性付費\n• 付費後即可使用對應功能\n• 退款政策依照 App Store 規定\n• 功能可能因技術原因暫時無法使用"
                        )
                        
                        TermsSection(
                            title: "服務變更",
                            content: "我們保留權利：\n• 隨時修改或終止服務\n• 更新應用程式功能\n• 修改服務條款\n• 在必要時暫停服務"
                        )
                        
                        TermsSection(
                            title: "聯繫方式",
                            content: "如有服務相關問題，請聯繫：\n• Email: support@signalair.com\n• 應用程式內客服功能"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("服務條款")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WarningSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
