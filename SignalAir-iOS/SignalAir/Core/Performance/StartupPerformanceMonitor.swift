import Foundation
import SwiftUI

/// 啟動性能監控器 - 檢測多設備同時啟動的阻塞問題
class StartupPerformanceMonitor: ObservableObject {
    static let shared = StartupPerformanceMonitor()
    
    @Published var metrics: StartupMetrics = StartupMetrics()
    
    private var startTime: Date?
    private var checkpoints: [String: Date] = [:]
    
    private init() {
        print("📊 StartupPerformanceMonitor: 已初始化")
    }
    
    /// 開始監控啟動過程
    func startMonitoring() {
        startTime = Date()
        checkpoints.removeAll()
        
        recordCheckpoint("app_launch")
        print("🚀 啟動性能監控已開始")
    }
    
    /// 記錄檢查點
    func recordCheckpoint(_ name: String) {
        let now = Date()
        checkpoints[name] = now
        
        if let start = startTime {
            let elapsed = now.timeIntervalSince(start) * 1000
            print("⏱️ 檢查點 [\(name)]: \(String(format: "%.0f", elapsed))ms")
            
            // 更新指標
            DispatchQueue.main.async {
                self.updateMetrics(checkpoint: name, elapsed: elapsed)
            }
        }
    }
    
    /// 更新性能指標
    private func updateMetrics(checkpoint: String, elapsed: Double) {
        switch checkpoint {
        case "app_launch":
            metrics.appLaunchTime = elapsed
        case "service_container_init":
            metrics.serviceContainerInitTime = elapsed
        case "network_service_init":
            metrics.networkServiceInitTime = elapsed
        case "content_view_ready":
            metrics.contentViewReadyTime = elapsed
        case "main_ui_visible":
            metrics.mainUIVisibleTime = elapsed
            metrics.totalStartupTime = elapsed
        default:
            break
        }
    }
    
    /// 檢查是否存在阻塞問題
    func checkForBlockingIssues() -> [BlockingIssue] {
        var issues: [BlockingIssue] = []
        
        // 檢查 ServiceContainer 初始化時間
        if metrics.serviceContainerInitTime > 500 {
            issues.append(BlockingIssue(
                type: .serviceContainerBlocking,
                duration: metrics.serviceContainerInitTime,
                description: "ServiceContainer 初始化時間過長"
            ))
        }
        
        // 檢查 NetworkService 初始化時間
        if metrics.networkServiceInitTime > 300 {
            issues.append(BlockingIssue(
                type: .networkServiceBlocking,
                duration: metrics.networkServiceInitTime,
                description: "NetworkService 初始化時間過長"
            ))
        }
        
        // 檢查總啟動時間
        if metrics.totalStartupTime > 2000 {
            issues.append(BlockingIssue(
                type: .slowStartup,
                duration: metrics.totalStartupTime,
                description: "總啟動時間過長，可能影響多設備同時啟動"
            ))
        }
        
        return issues
    }
    
    /// 生成性能報告
    func generateReport() -> String {
        let issues = checkForBlockingIssues()
        
        var report = "📊 啟動性能報告\n"
        report += "==================\n"
        report += "應用啟動: \(String(format: "%.0f", metrics.appLaunchTime))ms\n"
        report += "服務容器初始化: \(String(format: "%.0f", metrics.serviceContainerInitTime))ms\n"
        report += "網路服務初始化: \(String(format: "%.0f", metrics.networkServiceInitTime))ms\n"
        report += "ContentView 就緒: \(String(format: "%.0f", metrics.contentViewReadyTime))ms\n"
        report += "主 UI 顯示: \(String(format: "%.0f", metrics.mainUIVisibleTime))ms\n"
        report += "總啟動時間: \(String(format: "%.0f", metrics.totalStartupTime))ms\n"
        report += "==================\n"
        
        if issues.isEmpty {
            report += "✅ 未發現阻塞問題"
        } else {
            report += "⚠️ 發現 \(issues.count) 個潛在問題:\n"
            for issue in issues {
                report += "- \(issue.description) (\(String(format: "%.0f", issue.duration))ms)\n"
            }
        }
        
        return report
    }
}

// MARK: - 數據結構
struct StartupMetrics {
    var appLaunchTime: Double = 0
    var serviceContainerInitTime: Double = 0
    var networkServiceInitTime: Double = 0
    var contentViewReadyTime: Double = 0
    var mainUIVisibleTime: Double = 0
    var totalStartupTime: Double = 0
}

struct BlockingIssue {
    let type: BlockingIssueType
    let duration: Double
    let description: String
}

enum BlockingIssueType {
    case serviceContainerBlocking
    case networkServiceBlocking
    case slowStartup
}

// MARK: - SwiftUI 集成
struct PerformanceMonitorView: View {
    @StateObject private var monitor = StartupPerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("啟動性能監控")
                .font(.headline)
            
            Text("總啟動時間: \(String(format: "%.0f", monitor.metrics.totalStartupTime))ms")
                .font(.caption)
                .foregroundColor(monitor.metrics.totalStartupTime > 2000 ? .red : .green)
            
            let issues = monitor.checkForBlockingIssues()
            if !issues.isEmpty {
                Text("⚠️ \(issues.count) 個問題")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}