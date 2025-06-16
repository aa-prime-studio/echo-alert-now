import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隱私權政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最後更新：2024年1月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        PolicySection(
                            title: "資料收集",
                            content: "SignalAir 會收集以下資料：\n• 裝置名稱（用於識別訊號來源）\n• 位置資訊（僅限計算距離和方向）\n• 使用統計（改善應用程式體驗）"
                        )
                        
                        PolicySection(
                            title: "資料使用",
                            content: "我們收集的資料僅用於：\n• 提供緊急通訊服務\n• 顯示訊號距離和方向\n• 改善應用程式功能\n• 提供技術支援"
                        )
                        
                        PolicySection(
                            title: "資料儲存",
                            content: "• 所有通訊資料僅在本地裝置儲存\n• 聊天訊息會在24小時後自動刪除\n• 不會將個人資料傳送至外部伺服器\n• 使用端對端加密保護資料安全"
                        )
                        
                        PolicySection(
                            title: "資料分享",
                            content: "SignalAir 承諾：\n• 絕不販售用戶資料\n• 不與第三方分享個人資訊\n• 僅在法律要求時提供必要資料\n• 匿名統計資料可能用於改善服務"
                        )
                        
                        PolicySection(
                            title: "用戶權利",
                            content: "您有權：\n• 隨時刪除應用程式及其資料\n• 要求查看收集的資料\n• 關閉位置服務（但會影響功能）\n• 聯繫我們處理隱私相關問題"
                        )
                        
                        PolicySection(
                            title: "聯繫方式",
                            content: "如有隱私權相關問題，請透過以下方式聯繫：\n• Email: privacy@signalair.com\n• 應用程式內回報功能"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("隱私權政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
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
