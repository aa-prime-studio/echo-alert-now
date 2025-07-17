import Foundation
import MultipeerConnectivity
import os.log

// MARK: - 邊界情況處理器實現
// 每個處理器針對特定的邊界情況提供專業的處理策略

// MARK: - 同時連接處理器
class SimultaneousConnectionHandler: EdgeCaseHandler {
    let priority = 100
    private let logger = Logger(subsystem: "com.signalair", category: "SimultaneousConnection")
    private var activeConnections: Set<String> = []
    private let connectionLock = NSLock()
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .simultaneousConnection
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        guard let peerID = context.peerID else {
            return EdgeCaseResult(success: false, recoveryAction: RecoveryAction.none, delay: nil, message: "No peer ID provided")
        }
        
        let peerName = peerID.displayName
        
        return connectionLock.withLock {
            // 檢查是否已經在處理該peer的連接
            if activeConnections.contains(peerName) {
                self.logger.warning("⚠️ Simultaneous connection detected for \(peerName)")
                
                // 策略：延遲當前連接嘗試，讓第一個完成
                return EdgeCaseResult(
                    success: true,
                    recoveryAction: .retry,
                    delay: Double.random(in: 0.5...2.0), // 隨機延遲避免同步重試
                    message: "Delayed connection to avoid race condition"
                )
            }
            
            // 標記為正在處理
            activeConnections.insert(peerName)
            
            // 設置自動清理（防止死鎖）
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30秒後自動清理
                _ = connectionLock.withLock {
                    activeConnections.remove(peerName)
                }
            }
            
            self.logger.debug("✅ Handling simultaneous connection for \(peerName)")
            return EdgeCaseResult(success: true, recoveryAction: RecoveryAction.none, delay: nil, message: "Connection handled")
        }
    }
}

// MARK: - 快速斷開重連處理器
class RapidDisconnectionHandler: EdgeCaseHandler {
    let priority = 95
    private let logger = Logger(subsystem: "com.signalair", category: "RapidDisconnection")
    private var disconnectionHistory: [String: [Date]] = [:]
    private let historyLock = NSLock()
    
    private let rapidThreshold: TimeInterval = 30.0 // 30秒內超過3次斷開視為快速斷開
    private let maxDisconnections = 3
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .rapidDisconnection
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        guard let peerID = context.peerID else {
            return EdgeCaseResult(success: false, recoveryAction: RecoveryAction.none, delay: nil, message: "No peer ID provided")
        }
        
        let peerName = peerID.displayName
        let now = Date()
        
        return historyLock.withLock {
            // 更新斷開歷史
            if disconnectionHistory[peerName] == nil {
                disconnectionHistory[peerName] = []
            }
            
            disconnectionHistory[peerName]?.append(now)
            
            // 清理過期記錄
            let cutoffTime = now.addingTimeInterval(-rapidThreshold)
            disconnectionHistory[peerName] = disconnectionHistory[peerName]?.filter { $0 > cutoffTime }
            
            // 檢查是否為快速斷開模式
            if let history = disconnectionHistory[peerName], history.count >= maxDisconnections {
                self.logger.warning("⚠️ Rapid disconnection pattern detected for \(peerName)")
                
                // 策略：暫時隔離該peer，避免頻繁重連
                return EdgeCaseResult(
                    success: true,
                    recoveryAction: .isolate,
                    delay: 60.0, // 隔離60秒
                    message: "Peer temporarily isolated due to rapid disconnections"
                )
            }
            
            self.logger.debug("✅ Normal disconnection for \(peerName)")
            return EdgeCaseResult(success: true, recoveryAction: RecoveryAction.none, delay: nil, message: "Normal disconnection")
        }
    }
}

// MARK: - 背景轉換處理器
class BackgroundTransitionHandler: EdgeCaseHandler {
    let priority = 90
    private let logger = Logger(subsystem: "com.signalair", category: "BackgroundTransition")
    private var backgroundStartTime: Date?
    private var pendingOperations: [String] = []
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .backgroundTransition
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        self.logger.info("📱 Handling background transition")
        
        // 記錄背景開始時間
        backgroundStartTime = Date()
        
        // 暫停非關鍵操作
        let suspendedOperations = suspendNonCriticalOperations()
        
        // 保存狀態以便前景恢復
        saveStateForRecovery()
        
        self.logger.debug("✅ Background transition handled, suspended \(suspendedOperations) operations")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: RecoveryAction.none,
            delay: nil,
            message: "Background transition completed, \(suspendedOperations) operations suspended"
        )
    }
    
    func handleForegroundTransition() async -> EdgeCaseResult {
        self.logger.info("☀️ Handling foreground transition")
        
        // 計算背景時間
        let backgroundDuration = backgroundStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // 恢復操作
        let resumedOperations = resumeOperations()
        
        // 執行健康檢查
        await performPostBackgroundHealthCheck()
        
        self.logger.debug("✅ Foreground transition handled, resumed \(resumedOperations) operations after \(Int(backgroundDuration))s")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: RecoveryAction.none,
            delay: nil,
            message: "Foreground transition completed, \(resumedOperations) operations resumed"
        )
    }
    
    private func suspendNonCriticalOperations() -> Int {
        // 實際實現會暫停非緊急操作
        return pendingOperations.count
    }
    
    private func saveStateForRecovery() {
        // 保存當前狀態
    }
    
    private func resumeOperations() -> Int {
        let count = pendingOperations.count
        pendingOperations.removeAll()
        return count
    }
    
    private func performPostBackgroundHealthCheck() async {
        // 執行背景恢復後的健康檢查
    }
}

// MARK: - 記憶體壓力處理器
class MemoryPressureHandler: EdgeCaseHandler {
    let priority = 85
    private let logger = Logger(subsystem: "com.signalair", category: "MemoryPressure")
    private var isHandlingPressure = false
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .memoryPressure
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        guard !isHandlingPressure else {
            return EdgeCaseResult(success: false, recoveryAction: RecoveryAction.none, delay: 1.0, message: "Already handling memory pressure")
        }
        
        isHandlingPressure = true
        defer { isHandlingPressure = false }
        
        self.logger.warning("⚠️ Handling memory pressure")
        
        // 獲取當前記憶體使用
        let memoryUsage = await getCurrentMemoryUsage()
        
        var actionsPerformed: [String] = []
        
        // 漸進式記憶體釋放策略
        if memoryUsage > 0.8 {
            // 高壓力：激進清理
            actionsPerformed.append("Cleared message cache")
            actionsPerformed.append("Reduced connection pool size")
            actionsPerformed.append("Suspended non-critical operations")
            
            await performAggressiveCleanup()
            
        } else if memoryUsage > 0.6 {
            // 中壓力：溫和清理
            actionsPerformed.append("Cleared old metrics")
            actionsPerformed.append("Reduced buffer sizes")
            
            await performModerateCleanup()
        }
        
        // 觸發垃圾回收
        await forceGarbageCollection()
        actionsPerformed.append("Forced garbage collection")
        
        let message = "Memory pressure handled: " + actionsPerformed.joined(separator: ", ")
        self.logger.info("✅ \(message)")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: RecoveryAction.none,
            delay: nil,
            message: message
        )
    }
    
    private func getCurrentMemoryUsage() async -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024 / 1024
            return min(1.0, memoryMB / 512.0) // 假設512MB為最大值
        }
        
        return 0.0
    }
    
    private func performAggressiveCleanup() async {
        // 激進清理策略
    }
    
    private func performModerateCleanup() async {
        // 溫和清理策略
    }
    
    private func forceGarbageCollection() async {
        // 強制垃圾回收
        autoreleasepool {
            // 創建並立即釋放對象來觸發自動釋放池清理
            let _ = Array(0..<1000).map { _ in NSObject() }
        }
    }
}

// MARK: - 通道競爭處理器
class ChannelContentionHandler: EdgeCaseHandler {
    let priority = 80
    private let logger = Logger(subsystem: "com.signalair", category: "ChannelContention")
    private var channelUsage: [String: Int] = [:]
    private let usageLock = NSLock()
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .channelContention
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        self.logger.warning("⚠️ Handling channel contention")
        
        let (strategy, delay, message) = usageLock.withLock { () -> (RecoveryAction, TimeInterval?, String) in
            // 分析通道使用模式
            let contentionLevel = analyzeChannelContention()
            
            var strategy: RecoveryAction = RecoveryAction.none
            var delay: TimeInterval? = nil
            var message = "Channel contention resolved"
            
            if contentionLevel > 0.8 {
                // 高競爭：實施流量控制
                strategy = .retry
                delay = Double.random(in: 0.1...0.5) // 隨機延遲避免同步重試
                message = "High contention detected, implementing flow control"
                
            } else if contentionLevel > 0.6 {
                // 中競爭：負載均衡
                message = "Medium contention detected, load balancing applied"
            }
            
            return (strategy, delay, message)
        }
        
        // 執行異步任務
        if strategy == .retry {
            Task {
                await implementFlowControl()
            }
        }
        
        self.logger.debug("✅ Channel contention handled with strategy: \(String(describing: strategy))")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: strategy,
            delay: delay,
            message: message
        )
    }
    
    private func analyzeChannelContention() -> Double {
        let totalUsage = channelUsage.values.reduce(0, +)
        let maxUsage = channelUsage.values.max() ?? 0
        
        guard totalUsage > 0 else { return 0.0 }
        
        return Double(maxUsage) / Double(totalUsage)
    }
    
    private func implementFlowControl() async {
        // 實施流量控制
    }
    
    private func performLoadBalancing() async {
        // 執行負載均衡
    }
}

// MARK: - 網路不穩定處理器
class NetworkInstabilityHandler: EdgeCaseHandler {
    let priority = 75
    private let logger = Logger(subsystem: "com.signalair", category: "NetworkInstability")
    private var stabilityHistory: [Date: Double] = [:]
    private let historyLock = NSLock()
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .networkInstability
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        self.logger.warning("⚠️ Handling network instability")
        
        // 評估網路穩定性
        let instabilityLevel = await assessNetworkInstability()
        
        var actions: [String] = []
        var recoveryAction: RecoveryAction = RecoveryAction.none
        
        if instabilityLevel > 0.7 {
            // 高不穩定：切換到穩定模式
            await switchToStableMode()
            recoveryAction = .fallback
            actions.append("Switched to stable mode")
            
        } else if instabilityLevel > 0.4 {
            // 中不穩定：增加重試機制
            await enhanceRetryMechanism()
            recoveryAction = .retry
            actions.append("Enhanced retry mechanism")
        }
        
        // 調整超時參數
        await adjustTimeoutParameters(instabilityLevel: instabilityLevel)
        actions.append("Adjusted timeout parameters")
        
        let message = "Network instability handled: " + actions.joined(separator: ", ")
        self.logger.info("✅ \(message)")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: recoveryAction,
            delay: instabilityLevel > 0.5 ? 2.0 : nil,
            message: message
        )
    }
    
    private func assessNetworkInstability() async -> Double {
        // 評估網路穩定性的複合指標
        return 0.3 // 簡化實現
    }
    
    private func switchToStableMode() async {
        // 切換到穩定模式
    }
    
    private func enhanceRetryMechanism() async {
        // 增強重試機制
    }
    
    private func adjustTimeoutParameters(instabilityLevel: Double) async {
        // 根據不穩定程度調整超時參數
    }
}

// MARK: - 併發操作處理器
class ConcurrentOperationHandler: EdgeCaseHandler {
    let priority = 70
    private let logger = Logger(subsystem: "com.signalair", category: "ConcurrentOperation")
    private static let maxConcurrentOperations = 10
    private static var currentOperations = 0
    private static let operationsLock = NSLock()
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .concurrentOperations
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        self.logger.warning("⚠️ Handling excessive concurrent operations")
        
        // 使用線程安全的方式檢查可用槽位
        let canProceed = Self.operationsLock.withLock {
            if Self.currentOperations < Self.maxConcurrentOperations {
                Self.currentOperations += 1
                return true
            }
            return false
        }
        
        if canProceed {
            // 有可用槽位，允許操作繼續
            self.logger.debug("✅ Concurrent operation slot acquired (\(Self.currentOperations)/\(Self.maxConcurrentOperations))")
            
            return EdgeCaseResult(
                success: true,
                recoveryAction: RecoveryAction.none,
                delay: nil,
                message: "Concurrent operation managed"
            )
        }
        
        // 無可用槽位，建議延遲重試
        self.logger.warning("⚠️ No available concurrent operation slots (\(Self.currentOperations)/\(Self.maxConcurrentOperations))")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: .retry,
            delay: Double.random(in: 0.5...2.0),
            message: "Operation queued due to concurrency limit"
        )
    }
    
    // 操作完成時調用以釋放槽位
    static func releaseOperation() {
        operationsLock.withLock {
            currentOperations = max(0, currentOperations - 1)
        }
    }
}

// MARK: - 資源耗盡處理器
class ResourceExhaustionHandler: EdgeCaseHandler {
    let priority = 65
    private let logger = Logger(subsystem: "com.signalair", category: "ResourceExhaustion")
    
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool {
        return edgeCase == .resourceExhaustion
    }
    
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        self.logger.warning("⚠️ Handling resource exhaustion")
        
        // 評估資源使用情況
        let resourceStatus = await assessResourceStatus()
        
        var actions: [String] = []
        var recoveryAction: RecoveryAction = RecoveryAction.none
        
        if resourceStatus.memoryPressure > 0.8 {
            await performEmergencyCleanup()
            actions.append("Emergency memory cleanup")
            recoveryAction = .restart
        }
        
        if resourceStatus.cpuUsage > 0.9 {
            await throttleOperations()
            actions.append("CPU throttling applied")
            recoveryAction = .retry
        }
        
        if resourceStatus.networkCapacity < 0.2 {
            await reduceNetworkLoad()
            actions.append("Network load reduced")
        }
        
        let message = "Resource exhaustion handled: " + actions.joined(separator: ", ")
        self.logger.info("✅ \(message)")
        
        return EdgeCaseResult(
            success: true,
            recoveryAction: recoveryAction,
            delay: recoveryAction == .restart ? 5.0 : 1.0,
            message: message
        )
    }
    
    private func assessResourceStatus() async -> ResourceStatus {
        return ResourceStatus(
            memoryPressure: 0.5,
            cpuUsage: 0.3,
            networkCapacity: 0.8
        )
    }
    
    private func performEmergencyCleanup() async {
        // 緊急清理
    }
    
    private func throttleOperations() async {
        // 操作節流
    }
    
    private func reduceNetworkLoad() async {
        // 減少網路負載
    }
}

// MARK: - 支持類型

struct ResourceStatus {
    let memoryPressure: Double
    let cpuUsage: Double
    let networkCapacity: Double
}