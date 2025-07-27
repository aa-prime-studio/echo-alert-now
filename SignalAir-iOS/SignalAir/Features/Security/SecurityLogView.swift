import SwiftUI

//
// SecurityLogView.swift
// SignalAir
//
// 安全日誌檢視器 - 參考隱私權政策內文設定
//

struct SecurityLogView: View {
    @EnvironmentObject var languageService: LanguageService
    @ObservedObject var securityLogManager: SecurityLogManager
    @State private var selectedSeverity: SecurityLogSeverity? = nil
    @State private var selectedSource: String? = nil
    @State private var showingExportSuccess = false
    @State private var showingClearConfirmation = false
    
    private var filteredLogs: [SecurityLogEntry] {
        var logs = securityLogManager.recentLogs
        
        if let severity = selectedSeverity {
            logs = logs.filter { $0.severity == severity }
        }
        
        if let source = selectedSource {
            logs = logs.filter { $0.source == source }
        }
        
        return logs
    }
    
    private var title: String {
        return languageService.currentLanguage == .english ? "Security Logs" : "安全日誌"
    }
    
    private var availableSources: [String] {
        let sources = Array(Set(securityLogManager.recentLogs.map { $0.source }))
        return sources.sorted()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 頁面說明
                    SecurityLogHeaderView()
                        .padding(.horizontal, 20)
                    
                    // 統計資訊
                    if let statistics = securityLogManager.statistics {
                        SecurityLogStatisticsView(statistics: statistics)
                            .padding(.horizontal, 20)
                    }
                    
                    // 篩選控制
                    SecurityLogFiltersView(
                        selectedSeverity: $selectedSeverity,
                        selectedSource: $selectedSource,
                        availableSources: availableSources
                    )
                    .padding(.horizontal, 20)
                    
                    // 日誌列表
                    if filteredLogs.isEmpty {
                        SecurityLogEmptyView()
                            .padding(.horizontal, 20)
                    } else {
                        SecurityLogEntriesView(logs: filteredLogs)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        exportLogs()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("清理日誌", isPresented: $showingClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("確認清理", role: .destructive) {
                    securityLogManager.manualCleanup()
                }
            } message: {
                Text("此操作將清理舊的日誌文件，無法復原。確定要繼續嗎？")
            }
            .alert("導出成功", isPresented: $showingExportSuccess) {
                Button("確定") { }
            } message: {
                Text("安全日誌已成功導出到檔案中")
            }
        }
        .onAppear {
            // 載入統計資料
            let _ = securityLogManager.generateStatistics()
        }
    }
    
    private func exportLogs() {
        if let exportURL = securityLogManager.exportLogs() {
            // 顯示分享界面
            let activityViewController = UIActivityViewController(
                activityItems: [exportURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityViewController, animated: true)
            }
        }
    }
}

struct SecurityLogHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本系統記錄所有安全相關事件，包括連線失敗、異常資料包、洪水攻擊防護等。日誌僅記錄技術資訊，不包含個人訊息內容，確保隱私保護。")
                .font(.subheadline.weight(.regular))
                .foregroundColor(.black)
                .lineSpacing(16)
        }
    }
}

struct SecurityLogStatisticsView: View {
    let statistics: SecurityLogStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("統計摘要")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
            
            HStack {
                StatisticItemView(
                    title: "總事件數",
                    value: "\(statistics.totalEntries)",
                    color: .blue
                )
                
                Spacer()
                
                StatisticItemView(
                    title: "嚴重事件",
                    value: "\(statistics.entriesBySeverity["CRITICAL"] ?? 0)",
                    color: .blue
                )
                
                Spacer()
                
                StatisticItemView(
                    title: "警告事件",
                    value: "\(statistics.entriesBySeverity["WARNING"] ?? 0)",
                    color: .blue
                )
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatisticItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SecurityLogFiltersView: View {
    @Binding var selectedSeverity: SecurityLogSeverity?
    @Binding var selectedSource: String?
    let availableSources: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 嚴重度篩選
                Menu {
                    Button("全部嚴重度") {
                        selectedSeverity = nil
                    }
                    
                    ForEach(SecurityLogSeverity.allCases, id: \.self) { severity in
                        Button(severity.displayName) {
                            selectedSeverity = severity
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSeverity?.displayName ?? "全部嚴重度")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
    }
}

struct SecurityLogEntriesView: View {
    let logs: [SecurityLogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("日誌記錄")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
            
            LazyVStack(spacing: 12) {
                ForEach(logs) { entry in
                    SecurityLogEntryView(entry: entry)
                }
            }
        }
    }
}

struct SecurityLogEntryView: View {
    let entry: SecurityLogEntry
    
    private var severityColor: Color {
        return .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.severity.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formatDate(entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(entry.eventType)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(mapSourceToDisplayName(entry.source))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(entry.details)
                .font(.subheadline.weight(.regular))
                .foregroundColor(.black)
                .lineSpacing(16)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func mapSourceToDisplayName(_ source: String) -> String {
        switch source {
        case "SecurityLogManager":
            return "安全系統"
        case "ConnectionRateManager":
            return "連線速率管理"
        case "NetworkService":
            return "網路服務"
        case "MeshManager":
            return "網格管理"
        case "LocalBlacklistManager":
            return "黑名單管理"
        default:
            return source
        }
    }
}

struct SecurityLogEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暫無安全日誌")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
            
            Text("當檢測到安全事件時，相關記錄將會顯示在這裡")
                .font(.subheadline.weight(.regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(16)
        }
        .padding(40)
    }
}

struct SecurityLogStatisticsDetailView: View {
    let statistics: SecurityLogStatistics?
    let securityLogManager: SecurityLogManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let stats = statistics {
                        // 事件類型統計
                        VStack(alignment: .leading, spacing: 12) {
                            Text("事件類型統計")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.black)
                            
                            ForEach(stats.topAttackTypes, id: \.type) { item in
                                HStack {
                                    Text(item.type)
                                        .font(.subheadline.weight(.regular))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 風險時段分析
                        VStack(alignment: .leading, spacing: 12) {
                            Text("風險時段分析")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.black)
                            
                            ForEach(stats.riskPeriods, id: \.hour) { period in
                                HStack {
                                    Text(String(format: "%02d:00", period.hour))
                                        .font(.subheadline.weight(.regular))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text("風險值: \(period.riskScore)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(period.riskScore > 10 ? .red : .green)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("詳細統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 關閉視窗
                    }
                }
            }
        }
    }
}

#Preview {
    SecurityLogView(securityLogManager: SecurityLogManager())
        .environmentObject(LanguageService())
}