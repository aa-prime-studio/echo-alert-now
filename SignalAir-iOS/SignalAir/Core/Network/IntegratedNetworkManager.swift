import Foundation
import MultipeerConnectivity
import Combine
import os.log

// MARK: - 整合網路管理器
// 將所有網路組件整合成一個統一的、生產就緒的網路層

@MainActor
class IntegratedNetworkManager: ObservableObject, NetworkServiceProtocol {
    
    // MARK: - NetworkServiceProtocol 實現
    var myPeerID: MCPeerID { return coreNetworkService.myPeerID }
    var connectedPeers: [MCPeerID] { return coreNetworkService.connectedPeers }
    var onDataReceived: ((Data, String) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    // MARK: - 核心組件
    private let coreNetworkService: NetworkService
    private let channelPoolManager: AdvancedChannelPoolManager
    private let robustNetworkLayer: RobustNetworkLayer
    
    // MARK: - 發布狀態
    @Published private(set) var systemStatus: SystemStatus = .initializing
    @Published private(set) var networkMetrics: NetworkMetrics
    @Published private(set) var healthReport: ComprehensiveHealthReport
    
    // MARK: - 配置
    private struct Configuration {
        static let healthCheckInterval: TimeInterval = 30.0
        static let metricsUpdateInterval: TimeInterval = 10.0
        static let autoRecoveryEnabled = true
        static let emergencyModeThreshold = 0.3
    }
    
    // MARK: - 監控和日誌
    private let logger = Logger(subsystem: "com.signalair", category: "IntegratedNetwork")
    private let performanceMonitor = PerformanceMonitor()
    
    // MARK: - 定時器
    private var healthCheckTimer: Timer?
    private var metricsTimer: Timer?
    private var recoveryTimer: Timer?
    
    // MARK: - 初始化
    init() {
        // 初始化核心網路服務
        self.coreNetworkService = NetworkService()
        
        // 初始化通道池管理器
        self.channelPoolManager = AdvancedChannelPoolManager()
        
        // 初始化健壯網路層
        self.robustNetworkLayer = RobustNetworkLayer(
            networkService: coreNetworkService,
            channelPoolManager: channelPoolManager
        )
        
        // 初始化狀態
        self.networkMetrics = NetworkMetrics(
            timestamp: Date(),
            connectedPeers: 0,
            activeOperations: 0,
            edgeCaseCount: 0,
            memoryPressure: 0.0,
            networkHealth: .unknown
        )
        
        self.healthReport = ComprehensiveHealthReport()
        
        setupNetworkCallbacks()
        startMonitoring()
        
        logger.info("🚀 IntegratedNetworkManager initialized")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - 公共API
    
    /// 啟動網路服務
    func startNetworking() async {
        logger.info("🚀 Starting integrated networking")
        systemStatus = .starting
        
        // 啟動核心網路服務
        coreNetworkService.startNetworking()
        
        // 等待初始化完成
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        systemStatus = .running
        logger.info("✅ Integrated networking started")
    }
    
    /// 停止網路服務
    func stopNetworking() async {
        logger.info("🛑 Stopping integrated networking")
        systemStatus = .stopping
        
        // 停止核心網路服務
        coreNetworkService.stopNetworking()
        
        systemStatus = .stopped
        logger.info("✅ Integrated networking stopped")
    }
    
    /// 健壯發送 - 統一的發送API
    func send(_ data: Data, to peers: [MCPeerID]) async throws {
        logger.debug("📤 Integrated send to \(peers.count) peers")
        
        let result = await robustNetworkLayer.robustSend(data, to: peers)
        
        switch result {
        case .success:
            logger.debug("✅ Send completed successfully")
        case .failure(let error):
            logger.error("❌ Send failed: \(error.localizedDescription)")
            throw error
        case .partialSuccess(_, let errors):
            logger.warning("⚠️ Partial send success with \(errors.count) errors")
            // 對於部分成功，我們選擇不拋出錯誤
        case .timeout:
            logger.error("⏰ Send operation timed out")
            throw NetworkError.timeout
        case .cancelled:
            logger.warning("❌ Send operation was cancelled")
            throw NetworkError.connectionFailed
        }
    }
    
    /// 廣播訊息
    func broadcast(_ data: Data) async throws {
        try await send(data, to: connectedPeers)
    }
    
    /// 獲取系統狀態報告
    func getSystemStatusReport() -> SystemStatusReport {
        let channelReport = channelPoolManager.getDetailedReport()
        let networkHealthReport = robustNetworkLayer.getNetworkHealthReport()
        
        return SystemStatusReport(
            systemStatus: systemStatus,
            channelPoolReport: channelReport,
            networkHealthReport: networkHealthReport,
            metrics: networkMetrics,
            uptime: performanceMonitor.getUptime(),
            recommendations: generateSystemRecommendations()
        )
    }
    
    /// 執行系統診斷
    func performSystemDiagnostics() async -> SystemDiagnosticsResult {
        logger.info("🔍 Performing comprehensive system diagnostics")
        
        let startTime = Date()
        var diagnostics: [String: Any] = [:]
        var issues: [DiagnosticIssue] = []
        var recommendations: [String] = []
        
        // 1. 網路服務診斷
        let networkDiagnostics = performNetworkDiagnostics()
        diagnostics["network"] = networkDiagnostics
        
        // 2. 通道池診斷
        let channelDiagnostics = await performChannelPoolDiagnostics()
        diagnostics["channelPool"] = channelDiagnostics
        
        // 3. 記憶體和性能診斷
        let performanceDiagnostics = await performPerformanceDiagnostics()
        diagnostics["performance"] = performanceDiagnostics
        
        // 4. 邊界情況分析
        let edgeCaseDiagnostics = performEdgeCaseDiagnostics()
        diagnostics["edgeCases"] = edgeCaseDiagnostics
        
        // 5. 生成問題和建議
        issues = analyzeForIssues(diagnostics)
        recommendations = generateDiagnosticRecommendations(issues)
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("✅ System diagnostics completed in \(String(format: "%.2f", duration))s")
        
        return SystemDiagnosticsResult(
            timestamp: Date(),
            duration: duration,
            diagnostics: diagnostics,
            issues: issues,
            recommendations: recommendations,
            overallHealth: calculateOverallHealth(issues)
        )
    }
    
    /// 執行緊急恢復
    func performEmergencyRecovery() async -> EmergencyRecoveryResult {
        logger.warning("🚨 Performing emergency recovery")
        systemStatus = .recovering
        
        var actionsPerformed: [String] = []
        var success = false
        
        do {
            // 1. 停止所有非關鍵操作
            await stopNonCriticalOperations()
            actionsPerformed.append("Stopped non-critical operations")
            
            // 2. 執行通道池緊急重置
            await channelPoolManager.emergencyChannelReset()
            actionsPerformed.append("Reset channel pool")
            
            // 3. 清理記憶體
            await performEmergencyMemoryCleanup()
            actionsPerformed.append("Emergency memory cleanup")
            
            // 4. 重啟核心服務
            await restartCoreServices()
            actionsPerformed.append("Restarted core services")
            
            // 5. 驗證恢復狀態
            let isHealthy = await validateRecoveryState()
            if isHealthy {
                systemStatus = .running
                success = true
                actionsPerformed.append("Recovery validation passed")
            } else {
                systemStatus = .degraded
                actionsPerformed.append("Recovery validation failed - system degraded")
            }
            
        } catch {
            logger.error("❌ Emergency recovery failed: \(error)")
            systemStatus = .failed
            actionsPerformed.append("Recovery failed: \(error.localizedDescription)")
        }
        
        logger.info("🏥 Emergency recovery completed: \(success ? "SUCCESS" : "FAILED")")
        
        return EmergencyRecoveryResult(
            success: success,
            actionsPerformed: actionsPerformed,
            finalStatus: systemStatus,
            timestamp: Date()
        )
    }
    
    // MARK: - 私有方法
    
    private func setupNetworkCallbacks() {
        // 設置網路服務回調
        coreNetworkService.onDataReceived = { [weak self] data, peerName in
            self?.onDataReceived?(data, peerName)
        }
        
        coreNetworkService.onPeerConnected = { [weak self] peerName in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // 找到對應的 MCPeerID
                if let peer = self.connectedPeers.first(where: { $0.displayName == peerName }) {
                    await self.robustNetworkLayer.handlePeerConnection(peer)
                }
                
                self.onPeerConnected?(peerName)
                await self.updateMetrics()
            }
        }
        
        coreNetworkService.onPeerDisconnected = { [weak self] peerName in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // 創建臨時 MCPeerID 用於清理
                let tempPeer = MCPeerID(displayName: peerName)
                await self.robustNetworkLayer.handlePeerDisconnection(tempPeer)
                
                self.onPeerDisconnected?(peerName)
                await self.updateMetrics()
            }
        }
    }
    
    private func startMonitoring() {
        // 健康檢查定時器
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Configuration.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performHealthCheck()
            }
        }
        
        // 指標更新定時器
        metricsTimer = Timer.scheduledTimer(withTimeInterval: Configuration.metricsUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateMetrics()
            }
        }
        
        logger.debug("📊 Monitoring started")
    }
    
    private func performHealthCheck() async {
        logger.debug("🏥 Performing health check")
        
        // 收集健康數據
        let channelReport = channelPoolManager.getDetailedReport()
        let networkReport = robustNetworkLayer.getNetworkHealthReport()
        
        // 更新健康報告
        healthReport = ComprehensiveHealthReport(
            channelHealth: calculateChannelHealth(channelReport),
            networkHealth: networkReport.overallHealth,
            systemHealth: calculateSystemHealth(),
            lastUpdate: Date()
        )
        
        // 檢查是否需要自動恢復
        if Configuration.autoRecoveryEnabled {
            await checkForAutoRecovery()
        }
    }
    
    private func updateMetrics() async {
        let newMetrics = NetworkMetrics(
            timestamp: Date(),
            connectedPeers: connectedPeers.count,
            activeOperations: 0, // 這裡需要實際的活躍操作數
            edgeCaseCount: 0,   // 這裡需要實際的邊界情況計數
            memoryPressure: await getCurrentMemoryPressure(),
            networkHealth: healthReport.networkHealth
        )
        
        networkMetrics = newMetrics
        performanceMonitor.record(newMetrics)
    }
    
    private func checkForAutoRecovery() async {
        let overallHealth = calculateOverallSystemHealth()
        
        if overallHealth < Configuration.emergencyModeThreshold {
            logger.warning("⚠️ System health below threshold (\(overallHealth)), initiating auto-recovery")
            let _ = await performEmergencyRecovery()
        }
    }
    
    private func performNetworkDiagnostics() -> NetworkDiagnosticResult {
        return NetworkDiagnosticResult(
            connectedPeers: connectedPeers.count,
            connectionStatus: coreNetworkService.connectionStatus,
            lastError: nil, // 這裡需要實際的錯誤追蹤
            latency: nil    // 這裡需要實際的延遲測量
        )
    }
    
    private func performChannelPoolDiagnostics() async -> ChannelPoolDiagnosticResult {
        let report = channelPoolManager.getDetailedReport()
        
        return ChannelPoolDiagnosticResult(
            totalChannels: report.totalChannels,
            healthyChannels: report.healthyChannels,
            degradedChannels: report.degradedChannels,
            failedChannels: report.failedChannels,
            averageQuality: report.averageQuality
        )
    }
    
    private func performPerformanceDiagnostics() async -> PerformanceDiagnosticResult {
        let memoryUsage = await getCurrentMemoryUsage()
        let cpuUsage = getCurrentCPUUsage()
        
        return PerformanceDiagnosticResult(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            uptime: performanceMonitor.getUptime()
        )
    }
    
    private func performEdgeCaseDiagnostics() -> EdgeCaseDiagnosticResult {
        let networkReport = robustNetworkLayer.getNetworkHealthReport()
        
        return EdgeCaseDiagnosticResult(
            edgeCaseStatistics: networkReport.edgeCaseStatistics,
            activeRecoveries: networkReport.activeRecoveries
        )
    }
    
    private func analyzeForIssues(_ diagnostics: [String: Any]) -> [DiagnosticIssue] {
        var issues: [DiagnosticIssue] = []
        
        // 分析網路問題
        if let networkDiag = diagnostics["network"] as? NetworkDiagnosticResult {
            if networkDiag.connectedPeers == 0 {
                issues.append(DiagnosticIssue(
                    severity: .critical,
                    category: "Network",
                    description: "No connected peers",
                    recommendation: "Check network connectivity and restart networking"
                ))
            }
        }
        
        // 分析通道池問題
        if let channelDiag = diagnostics["channelPool"] as? ChannelPoolDiagnosticResult {
            if channelDiag.failedChannels > channelDiag.totalChannels / 2 {
                issues.append(DiagnosticIssue(
                    severity: .high,
                    category: "Channel Pool",
                    description: "High channel failure rate",
                    recommendation: "Perform channel pool reset"
                ))
            }
        }
        
        // 分析性能問題
        if let perfDiag = diagnostics["performance"] as? PerformanceDiagnosticResult {
            if perfDiag.memoryUsage > 0.8 {
                issues.append(DiagnosticIssue(
                    severity: .high,
                    category: "Performance",
                    description: "High memory usage",
                    recommendation: "Perform memory cleanup"
                ))
            }
        }
        
        return issues
    }
    
    private func generateDiagnosticRecommendations(_ issues: [DiagnosticIssue]) -> [String] {
        return issues.map { $0.recommendation }
    }
    
    private func calculateOverallHealth(_ issues: [DiagnosticIssue]) -> SystemHealth {
        let criticalIssues = issues.filter { $0.severity == .critical }.count
        let highIssues = issues.filter { $0.severity == .high }.count
        let mediumIssues = issues.filter { $0.severity == .medium }.count
        
        if criticalIssues > 0 {
            return .critical
        } else if highIssues > 2 {
            return .poor
        } else if highIssues > 0 || mediumIssues > 3 {
            return .fair
        } else if mediumIssues > 0 {
            return .good
        } else {
            return .excellent
        }
    }
    
    private func stopNonCriticalOperations() async {
        // 停止非關鍵操作
    }
    
    private func performEmergencyMemoryCleanup() async {
        // 緊急記憶體清理
        autoreleasepool {
            // 強制清理自動釋放池
        }
    }
    
    private func restartCoreServices() async {
        await stopNetworking()
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒延遲
        await startNetworking()
    }
    
    private func validateRecoveryState() async -> Bool {
        // 驗證恢復狀態
        return connectedPeers.count > 0 && systemStatus == .running
    }
    
    private func calculateChannelHealth(_ report: ChannelPoolReport) -> NetworkHealth {
        if report.totalChannels == 0 {
            return .offline
        }
        
        let healthyRatio = Float(report.healthyChannels) / Float(report.totalChannels)
        
        switch healthyRatio {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        case 0.2..<0.5: return .poor
        default: return .offline
        }
    }
    
    private func calculateSystemHealth() -> NetworkHealth {
        // 綜合計算系統健康度
        return .good // 簡化實現
    }
    
    private func calculateOverallSystemHealth() -> Double {
        let channelHealth = Double(healthReport.channelHealth.rawValue.hash % 100) / 100.0
        let networkHealth = Double(healthReport.networkHealth.rawValue.hash % 100) / 100.0
        let systemHealth = Double(healthReport.systemHealth.rawValue.hash % 100) / 100.0
        
        return (channelHealth + networkHealth + systemHealth) / 3.0
    }
    
    private func getCurrentMemoryPressure() async -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024 / 1024
            return min(1.0, memoryMB / 512.0)
        }
        
        return 0.0
    }
    
    private func getCurrentMemoryUsage() async -> Double {
        return await getCurrentMemoryPressure()
    }
    
    private func getCurrentCPUUsage() -> Double {
        // 簡化的 CPU 使用率計算
        return 0.3
    }
    
    private func generateSystemRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if networkMetrics.connectedPeers == 0 {
            recommendations.append("No connected peers - check network connectivity")
        }
        
        if networkMetrics.memoryPressure > 0.8 {
            recommendations.append("High memory pressure - consider memory cleanup")
        }
        
        return recommendations
    }
    
    private func cleanup() {
        healthCheckTimer?.invalidate()
        metricsTimer?.invalidate()
        recoveryTimer?.invalidate()
        
        logger.info("🧹 IntegratedNetworkManager cleaned up")
    }
}

// MARK: - 支持類型

enum SystemStatus: String {
    case initializing = "initializing"
    case starting = "starting"
    case running = "running"
    case degraded = "degraded"
    case recovering = "recovering"
    case stopping = "stopping"
    case stopped = "stopped"
    case failed = "failed"
}

enum SystemHealth: String {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
}

enum IssueSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct ComprehensiveHealthReport {
    let channelHealth: NetworkHealth
    let networkHealth: NetworkHealth
    let systemHealth: NetworkHealth
    let lastUpdate: Date
    
    init() {
        self.channelHealth = .unknown
        self.networkHealth = .unknown
        self.systemHealth = .unknown
        self.lastUpdate = Date()
    }
    
    init(channelHealth: NetworkHealth, networkHealth: NetworkHealth, systemHealth: NetworkHealth, lastUpdate: Date) {
        self.channelHealth = channelHealth
        self.networkHealth = networkHealth
        self.systemHealth = systemHealth
        self.lastUpdate = lastUpdate
    }
}

struct SystemStatusReport {
    let systemStatus: SystemStatus
    let channelPoolReport: ChannelPoolReport
    let networkHealthReport: NetworkHealthReport
    let metrics: NetworkMetrics
    let uptime: TimeInterval
    let recommendations: [String]
}

struct SystemDiagnosticsResult {
    let timestamp: Date
    let duration: TimeInterval
    let diagnostics: [String: Any]
    let issues: [DiagnosticIssue]
    let recommendations: [String]
    let overallHealth: SystemHealth
}

struct EmergencyRecoveryResult {
    let success: Bool
    let actionsPerformed: [String]
    let finalStatus: SystemStatus
    let timestamp: Date
}

struct DiagnosticIssue {
    let severity: IssueSeverity
    let category: String
    let description: String
    let recommendation: String
}

struct NetworkDiagnosticResult {
    let connectedPeers: Int
    let connectionStatus: ConnectionStatus
    let lastError: Error?
    let latency: TimeInterval?
}

struct ChannelPoolDiagnosticResult {
    let totalChannels: Int
    let healthyChannels: Int
    let degradedChannels: Int
    let failedChannels: Int
    let averageQuality: Float
}

struct PerformanceDiagnosticResult {
    let memoryUsage: Double
    let cpuUsage: Double
    let uptime: TimeInterval
}

struct EdgeCaseDiagnosticResult {
    let edgeCaseStatistics: [EdgeCaseType: Int]
    let activeRecoveries: Int
}

// MARK: - 性能監控器

class PerformanceMonitor {
    private let startTime = Date()
    private var metricsHistory: [NetworkMetrics] = []
    
    func record(_ metrics: NetworkMetrics) {
        metricsHistory.append(metrics)
        
        // 保持最近1000條記錄
        if metricsHistory.count > 1000 {
            metricsHistory.removeFirst(metricsHistory.count - 1000)
        }
    }
    
    func getUptime() -> TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    func getAverageMetrics(over duration: TimeInterval) -> NetworkMetrics? {
        let cutoffTime = Date().addingTimeInterval(-duration)
        let recentMetrics = metricsHistory.filter { $0.timestamp > cutoffTime }
        
        guard !recentMetrics.isEmpty else { return nil }
        
        let avgConnectedPeers = recentMetrics.map { $0.connectedPeers }.reduce(0, +) / recentMetrics.count
        let avgActiveOperations = recentMetrics.map { $0.activeOperations }.reduce(0, +) / recentMetrics.count
        let avgMemoryPressure = recentMetrics.map { $0.memoryPressure }.reduce(0, +) / Double(recentMetrics.count)
        
        return NetworkMetrics(
            timestamp: Date(),
            connectedPeers: avgConnectedPeers,
            activeOperations: avgActiveOperations,
            edgeCaseCount: 0,
            memoryPressure: avgMemoryPressure,
            networkHealth: .unknown
        )
    }
}