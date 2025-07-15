import SwiftUI

struct LocalAnalyticsDashboard: View {
    @StateObject private var analytics = LocalAnalyticsManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("網路效能統計") {
                    StatRow(title: "平均延遲", value: "\(analytics.stats.avgLatency)ms")
                    StatRow(title: "連接成功率", value: "\(analytics.stats.successRate * 100, specifier: "%.1f")%")
                    StatRow(title: "平均連接數", value: "\(analytics.stats.avgConnections)")
                    StatRow(title: "總路由查詢", value: "\(analytics.stats.totalRouteQueries)")
                }
                
                Section("訊息統計") {
                    StatRow(title: "發送訊息", value: "\(analytics.stats.messagesSent)")
                    StatRow(title: "接收訊息", value: "\(analytics.stats.messagesReceived)")
                    StatRow(title: "緊急訊息", value: "\(analytics.stats.emergencyMessages)")
                    StatRow(title: "訊息成功率", value: "\(analytics.stats.messageSuccessRate * 100, specifier: "%.1f")%")
                }
                
                Section("使用統計") {
                    StatRow(title: "總使用時間", value: "\(analytics.stats.totalUsageHours, specifier: "%.1f")小時")
                    StatRow(title: "Bingo遊戲次數", value: "\(analytics.stats.bingoGamesPlayed)")
                    StatRow(title: "信任評分更新", value: "\(analytics.stats.trustScoreUpdates)")
                    StatRow(title: "內容檢測次數", value: "\(analytics.stats.contentDetections)")
                }
                
                Section("系統健康") {
                    StatRow(title: "崩潰次數", value: "\(analytics.stats.crashCount)")
                    StatRow(title: "平均電池消耗", value: "\(analytics.stats.avgBatteryDrain, specifier: "%.1f")%/小時")
                    StatRow(title: "記憶體峰值", value: "\(analytics.stats.peakMemoryUsage)MB")
                    StatRow(title: "最後更新", value: analytics.stats.lastUpdated.formatted())
                }
                
                Section("操作") {
                    Button("匯出統計數據") {
                        exportData()
                    }
                    
                    Button("清除所有數據") {
                        analytics.clearAllStats()
                    }
                    .foregroundColor(.red)
                    
                    Toggle("啟用數據收集", isOn: $analytics.isEnabled)
                }
            }
            .navigationTitle("本地統計數據")
            .refreshable {
                analytics.refreshStats()
            }
        }
    }
    
    private func exportData() {
        // 匯出JSON格式的統計數據
        let jsonData = analytics.exportToJSON()
        // 分享或儲存邏輯
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}