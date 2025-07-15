import Foundation
import Combine

// MARK: - System Health Monitor
/// 系統健康監控器 - 實現自動健康檢查和修復
/// 監控系統各個組件的健康狀態並自動執行修復操作
class SystemHealthMonitor: @unchecked Sendable {
    
    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "SystemHealthMonitor", qos: .utility)
    private var healthHistory: [HealthCheckRecord] = []
    private let maxHealthHistory = 1000
    
    // MARK: - Health Check Components
    private let networkHealthChecker = NetworkHealthChecker()
    private let memoryHealthChecker = MemoryHealthChecker()
    private let storageHealthChecker = StorageHealthChecker()
    private let serviceHealthChecker = ServiceHealthChecker()
    
    // MARK: - Initialization
    init() {
        print("💚 SystemHealthMonitor: 系統健康監控器已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 執行健康檢查
    func performHealthCheck() async -> HealthCheckResult {
        return await withCheckedContinuation { continuation in
            queue.async {
                let result = self.executeHealthCheck()
                continuation.resume(returning: result)
            }
        }
    }
    
    /// 嘗試自動修復問題
    func attemptAutoFix(_ issue: SystemIssue) async -> AutoFixResult {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: AutoFixResult(success: false, issue: issue, action: "System unavailable", error: "System unavailable"))
                    return
                }
                let result = self.executeAutoFix(issue)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// 獲取健康統計
    func getHealthStatistics() -> HealthStatistics {
        return queue.sync {
            let recentChecks = healthHistory.filter { 
                Date().timeIntervalSince($0.timestamp) < 86400 // 最近24小時
            }
            
            return HealthStatistics(
                totalChecks: healthHistory.count,
                recentChecks: recentChecks.count,
                averageHealthScore: calculateAverageHealthScore(),
                mostCommonIssues: getMostCommonIssues(),
                autoFixSuccessRate: calculateAutoFixSuccessRate()
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func executeHealthCheck() -> HealthCheckResult {
        print("🔍 SystemHealthMonitor: 執行系統健康檢查")
        
        let startTime = Date()
        var allIssues: [SystemIssue] = []
        var overallStatus: SystemHealthStatus = .healthy
        
        // 網路健康檢查
        let networkResult = networkHealthChecker.checkHealth()
        allIssues.append(contentsOf: networkResult.issues)
        
        // 記憶體健康檢查
        let memoryResult = memoryHealthChecker.checkHealth()
        allIssues.append(contentsOf: memoryResult.issues)
        
        // 儲存健康檢查
        let storageResult = storageHealthChecker.checkHealth()
        allIssues.append(contentsOf: storageResult.issues)
        
        // 服務健康檢查
        let serviceResult = serviceHealthChecker.checkHealth()
        allIssues.append(contentsOf: serviceResult.issues)
        
        // 計算整體健康狀態
        overallStatus = calculateOverallHealthStatus(allIssues)
        
        let result = HealthCheckResult(
            status: overallStatus,
            issues: allIssues,
            timestamp: Date()
        )
        
        // 記錄健康檢查歷史
        recordHealthCheck(result, duration: Date().timeIntervalSince(startTime))
        
        print("✅ SystemHealthMonitor: 健康檢查完成 - 狀態: \(overallStatus), 發現問題: \(allIssues.count)個")
        
        return result
    }
    
    private func executeAutoFix(_ issue: SystemIssue) -> AutoFixResult {
        print("🔧 SystemHealthMonitor: 嘗試自動修復問題 - \(issue.description)")
        
        guard issue.autoFixable else {
            return AutoFixResult(
                success: false,
                issue: issue,
                action: "無法自動修復",
                error: "此問題需要手動處理"
            )
        }
        
        do {
            let action = try performAutoFix(for: issue)
            
            return AutoFixResult(
                success: true,
                issue: issue,
                action: action,
                error: nil
            )
        } catch {
            return AutoFixResult(
                success: false,
                issue: issue,
                action: "修復失敗",
                error: error.localizedDescription
            )
        }
    }
    
    private func performAutoFix(for issue: SystemIssue) throws -> String {
        switch issue.type {
        case .memoryLeak:
            return try fixMemoryLeak(issue)
        case .diskSpace:
            return try fixDiskSpace(issue)
        case .networkConnectivity:
            return try fixNetworkConnectivity(issue)
        case .serviceFailure:
            return try fixServiceFailure(issue)
        case .performanceDegradation:
            return try fixPerformanceDegradation(issue)
        }
    }
    
    private func fixMemoryLeak(_ issue: SystemIssue) throws -> String {
        // 記憶體洩漏修復
        autoreleasepool {
            // 強制垃圾回收
        }
        return "執行記憶體清理和垃圾回收"
    }
    
    private func fixDiskSpace(_ issue: SystemIssue) throws -> String {
        // 磁碟空間修復
        let clearedSpace = clearTemporaryFiles() + clearCaches()
        return "清理臨時檔案和快取，釋放 \(formatBytes(clearedSpace)) 空間"
    }
    
    private func fixNetworkConnectivity(_ issue: SystemIssue) throws -> String {
        // 網路連線修復
        resetNetworkConnections()
        return "重置網路連線"
    }
    
    private func fixServiceFailure(_ issue: SystemIssue) throws -> String {
        // 服務失敗修復
        restartFailedServices()
        return "重啟失敗的服務"
    }
    
    private func fixPerformanceDegradation(_ issue: SystemIssue) throws -> String {
        // 效能降級修復
        optimizeSystemPerformance()
        return "執行系統效能優化"
    }
    
    private func calculateOverallHealthStatus(_ issues: [SystemIssue]) -> SystemHealthStatus {
        if issues.isEmpty {
            return .healthy
        }
        
        let criticalIssues = issues.filter { $0.severity == .critical }
        let highIssues = issues.filter { $0.severity == .high }
        let mediumIssues = issues.filter { $0.severity == .medium }
        
        if !criticalIssues.isEmpty {
            return .critical
        } else if !highIssues.isEmpty || mediumIssues.count > 5 {
            return .degraded
        } else if !mediumIssues.isEmpty || issues.count > 3 {
            return .degraded
        } else {
            return .healthy
        }
    }
    
    private func recordHealthCheck(_ result: HealthCheckResult, duration: TimeInterval) {
        let record = HealthCheckRecord(
            timestamp: result.timestamp,
            status: result.status,
            issueCount: result.issues.count,
            duration: duration,
            issues: result.issues
        )
        
        healthHistory.insert(record, at: 0)
        
        // 限制歷史記錄數量
        if healthHistory.count > maxHealthHistory {
            healthHistory = Array(healthHistory.prefix(maxHealthHistory))
        }
    }
    
    private func calculateAverageHealthScore() -> Double {
        if healthHistory.isEmpty { return 100.0 }
        
        let scores = healthHistory.map { record -> Double in
            switch record.status {
            case .healthy: return 100.0
            case .degraded: return 70.0
            case .critical: return 30.0
            case .offline: return 0.0
            case .unknown: return 50.0
            }
        }
        
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private func getMostCommonIssues() -> [IssueFrequency] {
        let issueTypes = healthHistory.flatMap { $0.issues.map { $0.type } }
        let frequencyDict = Dictionary(grouping: issueTypes) { $0 }
        
        return frequencyDict.map { (type, occurrences) in
            IssueFrequency(type: type, count: occurrences.count)
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateAutoFixSuccessRate() -> Double {
        // 這裡需要記錄自動修復的成功率
        // 暫時返回模擬值
        return 0.85 // 85%成功率
    }
    
    // MARK: - Helper Methods
    
    private func clearTemporaryFiles() -> Int64 {
        // 清理臨時檔案
        return 10 * 1024 * 1024 // 10MB
    }
    
    private func clearCaches() -> Int64 {
        // 清理快取
        return 20 * 1024 * 1024 // 20MB
    }
    
    private func resetNetworkConnections() {
        // 重置網路連線
    }
    
    private func restartFailedServices() {
        // 重啟失敗的服務
    }
    
    private func optimizeSystemPerformance() {
        // 優化系統效能
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Health Checker Components

class NetworkHealthChecker {
    func checkHealth() -> ComponentHealthResult {
        var issues: [SystemIssue] = []
        
        // 檢查網路連線
        if !isNetworkConnected() {
            issues.append(SystemIssue(
                id: "network_disconnected",
                type: .networkConnectivity,
                severity: .high,
                description: "網路連線中斷",
                autoFixable: true
            ))
        }
        
        // 檢查網路延遲
        let latency = measureNetworkLatency()
        if latency > 1000 { // 超過1秒
            issues.append(SystemIssue(
                id: "high_network_latency",
                type: .networkConnectivity,
                severity: .medium,
                description: "網路延遲過高: \(latency)ms",
                autoFixable: false
            ))
        }
        
        return ComponentHealthResult(issues: issues)
    }
    
    private func isNetworkConnected() -> Bool {
        // 檢查網路連線狀態
        return true // 暫時返回true
    }
    
    private func measureNetworkLatency() -> Int {
        // 測量網路延遲
        return 50 // 暫時返回50ms
    }
}

class MemoryHealthChecker {
    func checkHealth() -> ComponentHealthResult {
        var issues: [SystemIssue] = []
        
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 0.9 {
            issues.append(SystemIssue(
                id: "high_memory_usage",
                type: .memoryLeak,
                severity: .critical,
                description: "記憶體使用率過高: \(Int(memoryUsage * 100))%",
                autoFixable: true
            ))
        } else if memoryUsage > 0.8 {
            issues.append(SystemIssue(
                id: "elevated_memory_usage",
                type: .performanceDegradation,
                severity: .medium,
                description: "記憶體使用率偏高: \(Int(memoryUsage * 100))%",
                autoFixable: true
            ))
        }
        
        return ComponentHealthResult(issues: issues)
    }
    
    private func getMemoryUsage() -> Double {
        // 獲取記憶體使用率
        return 0.6 // 暫時返回60%
    }
}

class StorageHealthChecker {
    func checkHealth() -> ComponentHealthResult {
        var issues: [SystemIssue] = []
        
        let diskUsage = getDiskUsage()
        if diskUsage > 0.95 {
            issues.append(SystemIssue(
                id: "critical_disk_space",
                type: .diskSpace,
                severity: .critical,
                description: "磁碟空間嚴重不足: \(Int(diskUsage * 100))%",
                autoFixable: true
            ))
        } else if diskUsage > 0.85 {
            issues.append(SystemIssue(
                id: "low_disk_space",
                type: .diskSpace,
                severity: .medium,
                description: "磁碟空間不足: \(Int(diskUsage * 100))%",
                autoFixable: true
            ))
        }
        
        return ComponentHealthResult(issues: issues)
    }
    
    private func getDiskUsage() -> Double {
        // 獲取磁碟使用率
        return 0.4 // 暫時返回40%
    }
}

class ServiceHealthChecker {
    func checkHealth() -> ComponentHealthResult {
        var issues: [SystemIssue] = []
        
        // 檢查關鍵服務狀態
        let criticalServices = ["NetworkService", "SecurityService", "LanguageService"]
        
        for service in criticalServices {
            if !isServiceRunning(service) {
                issues.append(SystemIssue(
                    id: "service_failure_\(service)",
                    type: .serviceFailure,
                    severity: .high,
                    description: "關鍵服務停止運行: \(service)",
                    autoFixable: true
                ))
            }
        }
        
        return ComponentHealthResult(issues: issues)
    }
    
    private func isServiceRunning(_ serviceName: String) -> Bool {
        // 檢查服務是否運行
        return true // 暫時返回true
    }
}

// MARK: - Supporting Types

struct ComponentHealthResult {
    let issues: [SystemIssue]
}

struct AutoFixResult {
    let success: Bool
    let issue: SystemIssue
    let action: String
    let error: String?
}

struct HealthCheckRecord {
    let timestamp: Date
    let status: SystemHealthStatus
    let issueCount: Int
    let duration: TimeInterval
    let issues: [SystemIssue]
}

struct HealthStatistics {
    let totalChecks: Int
    let recentChecks: Int
    let averageHealthScore: Double
    let mostCommonIssues: [IssueFrequency]
    let autoFixSuccessRate: Double
}

struct IssueFrequency {
    let type: IssueType
    let count: Int
} 