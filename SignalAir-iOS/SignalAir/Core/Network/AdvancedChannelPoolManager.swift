import Foundation
import MultipeerConnectivity
import Combine
import os.log

// MARK: - Channel Pool Manager - 企業級通道管理架構
// 專為災難通信場景設計，確保零崩潰和優雅降級

/// 通道狀態枚舉
enum ChannelState: String, CaseIterable {
    case idle = "idle"
    case active = "active"
    case congested = "congested"
    case failed = "failed"
    case recovering = "recovering"
    case maintenance = "maintenance"
}

/// 通道品質評估
struct ChannelQuality {
    let reliability: Float      // 0.0-1.0 可靠性評分
    let throughput: Float       // bytes/second 吞吐量
    let latency: TimeInterval   // 延遲（毫秒）
    let errorRate: Float        // 0.0-1.0 錯誤率
    let congestionLevel: Float  // 0.0-1.0 擁塞程度
    let lastUpdate: Date
    
    var overallScore: Float {
        let reliabilityWeight = 0.4
        let throughputWeight = 0.25
        let latencyWeight = 0.2
        let errorWeight = 0.15
        
        let latencyScore = max(0, 1.0 - Float(latency / 1000.0)) // 1秒為最差
        let throughputScore = min(1.0, throughput / 10240.0) // 10KB/s為滿分
        
        return Float(
            reliability * reliabilityWeight +
            throughputScore * throughputWeight +
            latencyScore * latencyWeight +
            (1.0 - errorRate) * errorWeight
        )
    }
    
    var isHealthy: Bool {
        return overallScore > 0.6 && reliability > 0.7 && errorRate < 0.3
    }
}

/// 通道實例
class ChannelInstance {
    let id: String
    let peerID: MCPeerID
    var state: ChannelState = .idle
    var quality: ChannelQuality
    var lastActivity: Date = Date()
    var activeOperations: Int = 0
    var totalOperations: Int = 0
    var successfulOperations: Int = 0
    var failureCount: Int = 0
    var recoveryAttempts: Int = 0
    
    private let maxRecoveryAttempts = 3
    private let maintenanceThreshold = 0.4
    
    init(peerID: MCPeerID) {
        self.id = UUID().uuidString
        self.peerID = peerID
        self.quality = ChannelQuality(
            reliability: 1.0,
            throughput: 0.0,
            latency: 0.0,
            errorRate: 0.0,
            congestionLevel: 0.0,
            lastUpdate: Date()
        )
    }
    
    var successRate: Float {
        guard totalOperations > 0 else { return 1.0 }
        return Float(successfulOperations) / Float(totalOperations)
    }
    
    var needsMaintenance: Bool {
        return quality.overallScore < maintenanceThreshold || 
               failureCount > 5 ||
               recoveryAttempts >= maxRecoveryAttempts
    }
    
    func recordOperation(success: Bool, latency: TimeInterval, dataSize: Int) {
        totalOperations += 1
        lastActivity = Date()
        
        if success {
            successfulOperations += 1
            failureCount = max(0, failureCount - 1) // 成功時減少失敗計數
        } else {
            failureCount += 1
        }
        
        // 更新品質指標
        updateQuality(success: success, latency: latency, dataSize: dataSize)
    }
    
    private func updateQuality(success: Bool, latency: TimeInterval, dataSize: Int) {
        let alpha: Float = 0.3 // 平滑因子
        
        let newReliability = success ? 1.0 : 0.0
        let newThroughput = success ? Float(dataSize) / Float(max(latency, 0.001)) : 0.0
        let newErrorRate = success ? 0.0 : 1.0
        
        quality = ChannelQuality(
            reliability: quality.reliability * (1 - alpha) + newReliability * alpha,
            throughput: quality.throughput * (1 - alpha) + newThroughput * alpha,
            latency: quality.latency * (1 - Double(alpha)) + latency * Double(alpha),
            errorRate: quality.errorRate * (1 - alpha) + newErrorRate * alpha,
            congestionLevel: calculateCongestionLevel(),
            lastUpdate: Date()
        )
    }
    
    private func calculateCongestionLevel() -> Float {
        // 基於活躍操作數和最近錯誤率計算擁塞程度
        let operationLoad = Float(activeOperations) / 10.0 // 假設10個並發操作為滿載
        let errorContribution = quality.errorRate * 0.5
        return min(1.0, operationLoad + errorContribution)
    }
}

/// 通道池管理器 - 核心架構
@MainActor
class AdvancedChannelPoolManager: ObservableObject {
    
    // MARK: - 配置參數
    private struct Configuration {
        static let maxChannelsPerPeer = 3          // 每個peer最多3個通道
        static let maxTotalChannels = 50           // 總通道數限制
        static let healthCheckInterval: TimeInterval = 30.0
        static let maintenanceInterval: TimeInterval = 120.0
        static let channelTimeout: TimeInterval = 300.0
        static let maxConcurrentOperations = 20
        static let emergencyReservedChannels = 5   // 緊急情況預留通道
    }
    
    // MARK: - 狀態管理
    @Published private(set) var activeChannels: [String: ChannelInstance] = [:]
    @Published private(set) var poolStatistics: PoolStatistics = PoolStatistics()
    @Published private(set) var systemState: SystemState = .normal
    
    // MARK: - 內部組件
    private let qualityMonitor = ChannelQualityMonitor()
    private let flowController = AdaptiveFlowController()
    private let emergencyManager = EmergencyChannelManager()
    private let recoveryEngine = ChannelRecoveryEngine()
    
    // MARK: - 併發控制
    private let channelQueue = DispatchQueue(label: "com.signalair.channel-pool", 
                                           qos: .userInitiated, 
                                           attributes: .concurrent)
    private let operationSemaphore = DispatchSemaphore(value: Configuration.maxConcurrentOperations)
    
    // MARK: - 定時器
    private var healthCheckTimer: Timer?
    private var maintenanceTimer: Timer?
    private var metricsTimer: Timer?
    
    // MARK: - 日誌
    private let logger = Logger(subsystem: "com.signalair", category: "ChannelPool")
    
    // MARK: - 初始化
    init() {
        setupTimers()
        setupSystemMonitoring()
        logger.info("🏊‍♀️ AdvancedChannelPoolManager initialized")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - 公共API
    
    /// 獲取最佳通道進行操作
    func acquireChannel(for peerID: MCPeerID, priority: OperationPriority = .normal) async -> ChannelInstance? {
        return await withCheckedContinuation { continuation in
            channelQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let channel = self.selectOptimalChannel(for: peerID, priority: priority)
                
                if let channel = channel {
                    channel.activeOperations += 1
                    self.logger.debug("📡 Acquired channel \(channel.id) for \(peerID.displayName)")
                }
                
                continuation.resume(returning: channel)
            }
        }
    }
    
    /// 釋放通道
    func releaseChannel(_ channel: ChannelInstance, success: Bool, latency: TimeInterval, dataSize: Int) {
        channelQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            channel.activeOperations = max(0, channel.activeOperations - 1)
            channel.recordOperation(success: success, latency: latency, dataSize: dataSize)
            
            self.operationSemaphore.signal()
            
            // 更新狀態
            Task { @MainActor in
                self.updateChannelState(channel)
                self.updatePoolStatistics()
            }
            
            self.logger.debug("🔓 Released channel \(channel.id), success: \(success)")
        }
    }
    
    /// 處理peer連接
    func handlePeerConnected(_ peerID: MCPeerID) {
        channelQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 檢查是否已存在通道
            let existingChannels = self.activeChannels.values.filter { $0.peerID == peerID }
            guard existingChannels.isEmpty else {
                self.logger.warning("⚠️ Channels already exist for \(peerID.displayName)")
                return
            }
            
            // 創建新通道
            let channel = ChannelInstance(peerID: peerID)
            self.activeChannels[channel.id] = channel
            
            Task { @MainActor in
                self.updatePoolStatistics()
            }
            
            self.logger.info("✅ Created channel for \(peerID.displayName)")
        }
    }
    
    /// 處理peer斷開
    func handlePeerDisconnected(_ peerID: MCPeerID) {
        channelQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let channelsToRemove = self.activeChannels.filter { $0.value.peerID == peerID }
            
            for (channelId, _) in channelsToRemove {
                self.activeChannels.removeValue(forKey: channelId)
            }
            
            Task { @MainActor in
                self.updatePoolStatistics()
            }
            
            self.logger.info("❌ Removed channels for \(peerID.displayName)")
        }
    }
    
    /// 執行緊急通道重置
    func emergencyChannelReset() async {
        logger.warning("🚨 Emergency channel reset initiated")
        
        return await withCheckedContinuation { continuation in
            channelQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // 保留緊急通道，重置其他通道
                let emergencyChannels = self.emergencyManager.getEmergencyChannels(from: self.activeChannels)
                
                // 重置非緊急通道
                for (channelId, channel) in self.activeChannels {
                    if !emergencyChannels.contains(channelId) {
                        channel.state = .recovering
                        channel.recoveryAttempts += 1
                    }
                }
                
                Task { @MainActor in
                    self.systemState = .recovery
                    self.updatePoolStatistics()
                }
                
                continuation.resume()
            }
        }
    }
    
    /// 獲取池狀態報告
    func getDetailedReport() -> ChannelPoolReport {
        return channelQueue.sync {
            let healthyChannels = activeChannels.values.filter { $0.quality.isHealthy }.count
            let degradedChannels = activeChannels.values.filter { !$0.quality.isHealthy && $0.state != .failed }.count
            let failedChannels = activeChannels.values.filter { $0.state == .failed }.count
            
            return ChannelPoolReport(
                totalChannels: activeChannels.count,
                healthyChannels: healthyChannels,
                degradedChannels: degradedChannels,
                failedChannels: failedChannels,
                systemState: systemState,
                averageQuality: calculateAverageQuality(),
                recommendations: generateRecommendations()
            )
        }
    }
    
    // MARK: - 私有方法
    
    private func setupTimers() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Configuration.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performHealthCheck()
            }
        }
        
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: Configuration.maintenanceInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMaintenance()
            }
        }
        
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePoolStatistics()
            }
        }
    }
    
    private func setupSystemMonitoring() {
        // 監控系統資源使用情況
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleBackgroundTransition()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleForegroundTransition()
            }
        }
    }
    
    private func selectOptimalChannel(for peerID: MCPeerID, priority: OperationPriority) -> ChannelInstance? {
        // 1. 檢查並發限制
        guard operationSemaphore.wait(timeout: .now() + 0.1) == .success else {
            logger.warning("⚠️ Operation semaphore timeout for \(peerID.displayName)")
            return nil
        }
        
        // 2. 尋找該peer的可用通道
        let peerChannels = activeChannels.values.filter { $0.peerID == peerID }
        
        // 3. 根據優先級和品質選擇最佳通道
        let sortedChannels = peerChannels
            .filter { $0.state != .failed && $0.activeOperations < 5 }
            .sorted { first, second in
                // 緊急操作優先考慮可靠性
                if priority == .emergency {
                    return first.quality.reliability > second.quality.reliability
                } else {
                    return first.quality.overallScore > second.quality.overallScore
                }
            }
        
        return sortedChannels.first
    }
    
    private func updateChannelState(_ channel: ChannelInstance) {
        if channel.needsMaintenance {
            channel.state = .maintenance
        } else if channel.quality.congestionLevel > 0.8 {
            channel.state = .congested
        } else if !channel.quality.isHealthy {
            channel.state = .recovering
        } else if channel.activeOperations > 0 {
            channel.state = .active
        } else {
            channel.state = .idle
        }
    }
    
    private func performHealthCheck() async {
        logger.debug("🏥 Performing health check")
        
        await withTaskGroup(of: Void.self) { group in
            for channel in activeChannels.values {
                group.addTask { [weak self] in
                    await self?.checkChannelHealth(channel)
                }
            }
        }
        
        updatePoolStatistics()
    }
    
    private func checkChannelHealth(_ channel: ChannelInstance) async {
        // 檢查通道是否長時間無活動
        let timeSinceLastActivity = Date().timeIntervalSince(channel.lastActivity)
        
        if timeSinceLastActivity > Configuration.channelTimeout {
            channel.state = .failed
            logger.warning("⚠️ Channel \(channel.id) timed out")
            return
        }
        
        // 檢查品質指標
        if !channel.quality.isHealthy {
            await recoveryEngine.attemptRecovery(channel)
        }
    }
    
    private func performMaintenance() async {
        logger.debug("🔧 Performing maintenance")
        
        let maintenanceChannels = activeChannels.values.filter { $0.needsMaintenance }
        
        for channel in maintenanceChannels {
            await recoveryEngine.performMaintenance(channel)
        }
        
        // 清理失效通道
        cleanupFailedChannels()
        
        updatePoolStatistics()
    }
    
    private func cleanupFailedChannels() {
        let failedChannels = activeChannels.filter { $0.value.state == .failed }
        
        for (channelId, _) in failedChannels {
            activeChannels.removeValue(forKey: channelId)
            logger.info("🗑️ Cleaned up failed channel \(channelId)")
        }
    }
    
    private func handleBackgroundTransition() async {
        logger.info("📱 Handling background transition")
        systemState = .backgroundMode
        
        // 降低健康檢查頻率
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Configuration.healthCheckInterval * 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performHealthCheck()
            }
        }
    }
    
    private func handleForegroundTransition() async {
        logger.info("☀️ Handling foreground transition")
        systemState = .normal
        
        // 恢復正常健康檢查頻率
        setupTimers()
        
        // 立即執行健康檢查
        await performHealthCheck()
    }
    
    private func updatePoolStatistics() {
        let stats = channelQueue.sync {
            let healthy = activeChannels.values.filter { $0.quality.isHealthy }.count
            let active = activeChannels.values.filter { $0.state == .active }.count
            let failed = activeChannels.values.filter { $0.state == .failed }.count
            
            return PoolStatistics(
                totalChannels: activeChannels.count,
                healthyChannels: healthy,
                activeChannels: active,
                failedChannels: failed,
                averageQuality: calculateAverageQuality(),
                totalOperations: activeChannels.values.reduce(0) { $0 + $1.totalOperations },
                successfulOperations: activeChannels.values.reduce(0) { $0 + $1.successfulOperations }
            )
        }
        
        poolStatistics = stats
    }
    
    private func calculateAverageQuality() -> Float {
        let channels = activeChannels.values.filter { $0.state != .failed }
        guard !channels.isEmpty else { return 0.0 }
        
        let totalQuality = channels.reduce(0.0) { $0 + $1.quality.overallScore }
        return totalQuality / Float(channels.count)
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let healthyRatio = Float(poolStatistics.healthyChannels) / Float(max(1, poolStatistics.totalChannels))
        
        if healthyRatio < 0.5 {
            recommendations.append("系統健康度低於50%，建議重啟部分通道")
        }
        
        if poolStatistics.failedChannels > 5 {
            recommendations.append("失效通道過多，建議執行系統維護")
        }
        
        if poolStatistics.averageQuality < 0.6 {
            recommendations.append("平均品質偏低，建議優化網路環境")
        }
        
        return recommendations
    }
    
    private func cleanup() {
        healthCheckTimer?.invalidate()
        maintenanceTimer?.invalidate()
        metricsTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        logger.info("🧹 AdvancedChannelPoolManager cleaned up")
    }
}

// MARK: - 支持類型定義

enum OperationPriority {
    case low
    case normal
    case high
    case emergency
}

enum SystemState: String {
    case normal = "normal"
    case degraded = "degraded"
    case recovery = "recovery"
    case backgroundMode = "background"
    case emergency = "emergency"
}

struct PoolStatistics {
    let totalChannels: Int
    let healthyChannels: Int
    let activeChannels: Int
    let failedChannels: Int
    let averageQuality: Float
    let totalOperations: Int
    let successfulOperations: Int
    
    init() {
        self.totalChannels = 0
        self.healthyChannels = 0
        self.activeChannels = 0
        self.failedChannels = 0
        self.averageQuality = 0.0
        self.totalOperations = 0
        self.successfulOperations = 0
    }
    
    init(totalChannels: Int, healthyChannels: Int, activeChannels: Int, failedChannels: Int, averageQuality: Float, totalOperations: Int, successfulOperations: Int) {
        self.totalChannels = totalChannels
        self.healthyChannels = healthyChannels
        self.activeChannels = activeChannels
        self.failedChannels = failedChannels
        self.averageQuality = averageQuality
        self.totalOperations = totalOperations
        self.successfulOperations = successfulOperations
    }
    
    var successRate: Float {
        guard totalOperations > 0 else { return 1.0 }
        return Float(successfulOperations) / Float(totalOperations)
    }
}

struct ChannelPoolReport {
    let totalChannels: Int
    let healthyChannels: Int
    let degradedChannels: Int
    let failedChannels: Int
    let systemState: SystemState
    let averageQuality: Float
    let recommendations: [String]
}

// MARK: - 品質監控組件

class ChannelQualityMonitor {
    private let metricsHistory: [String: [ChannelQuality]] = [:]
    
    func analyzeQualityTrend(for channelId: String) -> QualityTrend {
        // 分析品質趨勢
        return .stable // 簡化實現
    }
}

enum QualityTrend {
    case improving
    case stable
    case degrading
    case critical
}

// MARK: - 自適應流量控制

class AdaptiveFlowController {
    private var currentLimit: Int = 10
    private let maxLimit = 50
    private let minLimit = 5
    
    func adjustFlowControl(based statistics: PoolStatistics) {
        if statistics.averageQuality > 0.8 && statistics.successRate > 0.9 {
            currentLimit = min(maxLimit, currentLimit + 2)
        } else if statistics.averageQuality < 0.5 || statistics.successRate < 0.7 {
            currentLimit = max(minLimit, currentLimit - 1)
        }
    }
    
    func getCurrentLimit() -> Int {
        return currentLimit
    }
}

// MARK: - 緊急通道管理

class EmergencyChannelManager {
    func getEmergencyChannels(from channels: [String: ChannelInstance]) -> Set<String> {
        // 選擇最佳的幾個通道作為緊急通道
        let sortedChannels = channels.sorted { $0.value.quality.reliability > $1.value.quality.reliability }
        let emergencyCount = min(3, channels.count)
        
        return Set(sortedChannels.prefix(emergencyCount).map { $0.key })
    }
    
    func reserveEmergencyCapacity() {
        // 為緊急情況預留資源
    }
}

// MARK: - 通道恢復引擎

class ChannelRecoveryEngine {
    private let maxRecoveryAttempts = 3
    
    func attemptRecovery(_ channel: ChannelInstance) async {
        guard channel.recoveryAttempts < maxRecoveryAttempts else {
            channel.state = .failed
            return
        }
        
        channel.recoveryAttempts += 1
        channel.state = .recovering
        
        // 模擬恢復過程
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 重置一些指標
        channel.failureCount = max(0, channel.failureCount - 2)
        
        if channel.failureCount < 3 {
            channel.state = .idle
            channel.recoveryAttempts = 0
        }
    }
    
    func performMaintenance(_ channel: ChannelInstance) async {
        channel.state = .maintenance
        
        // 執行維護操作
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 重置統計
        channel.failureCount = 0
        channel.recoveryAttempts = 0
        channel.state = .idle
    }
}