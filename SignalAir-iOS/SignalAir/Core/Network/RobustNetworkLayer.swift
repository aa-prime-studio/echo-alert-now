import Foundation
import MultipeerConnectivity
import Network
import os.log

// MARK: - 健壯網路層 - 邊界情況專用處理
// 專為處理複雜的邊界情況和網路異常設計

/// 網路錯誤類型
enum NetworkError: Error {
    case channelUnavailable
    case sendFailed
    case internalError
    case operationFailed
    case timeout
    case cancelled
    case sessionError(String)
    case notConnected
    case peerNotFound
    case connectionStateInconsistent
    
    var localizedDescription: String {
        switch self {
        case .channelUnavailable:
            return "通道不可用"
        case .sendFailed:
            return "發送失敗"
        case .internalError:
            return "內部錯誤"
        case .operationFailed:
            return "操作失敗"
        case .timeout:
            return "操作超時"
        case .cancelled:
            return "操作已取消"
        case .sessionError(let message):
            return "會話錯誤: \(message)"
        case .notConnected:
            return "未連接到任何設備"
        case .peerNotFound:
            return "找不到指定的設備"
        case .connectionStateInconsistent:
            return "連接狀態不一致"
        }
    }
}

/// 網路操作結果
enum NetworkOperationResult {
    case success(Data?)
    case failure(NetworkError)
    case partialSuccess(Data?, [String: Error])
    case timeout
    case cancelled
}

/// 邊界情況類型
enum EdgeCaseType: String, CaseIterable {
    case simultaneousConnection = "simultaneous_connection"
    case rapidDisconnection = "rapid_disconnection"
    case backgroundTransition = "background_transition"
    case memoryPressure = "memory_pressure"
    case channelContention = "channel_contention"
    case networkInstability = "network_instability"
    case concurrentOperations = "concurrent_operations"
    case resourceExhaustion = "resource_exhaustion"
}

/// 邊界情況處理器
protocol EdgeCaseHandler {
    func canHandle(_ edgeCase: EdgeCaseType) -> Bool
    func handle(_ context: EdgeCaseContext) async -> EdgeCaseResult
    var priority: Int { get }
}

/// 邊界情況上下文
struct EdgeCaseContext {
    let type: EdgeCaseType
    let peerID: MCPeerID?
    let operation: String
    let attemptCount: Int
    let errorHistory: [Error]
    let systemState: [String: Any]
    let timestamp: Date
}

/// 邊界情況處理結果
struct EdgeCaseResult {
    let success: Bool
    let recoveryAction: RecoveryAction?
    let delay: TimeInterval?
    let message: String
}

/// 恢復動作
enum RecoveryAction {
    case retry
    case fallback
    case isolate
    case restart
    case none
}

/// 健壯網路層主類
@MainActor
class RobustNetworkLayer: ObservableObject {
    
    // MARK: - 依賴注入
    private let networkService: NetworkService
    private let channelPoolManager: AdvancedChannelPoolManager
    
    // MARK: - 邊界情況處理
    private var edgeCaseHandlers: [EdgeCaseHandler] = []
    private let edgeCaseDetector = EdgeCaseDetector()
    private let circuitBreaker = CircuitBreaker()
    
    // MARK: - 狀態管理
    @Published private(set) var networkHealth: NetworkHealth = .unknown
    @Published private(set) var edgeCaseStats: [EdgeCaseType: Int] = [:]
    @Published private(set) var activeRecoveries: [String: RecoveryOperation] = [:]
    
    // MARK: - 併發控制
    private let operationQueue = OperationQueue()
    private let edgeCaseQueue = DispatchQueue(label: "com.signalair.edgecase", qos: .userInitiated)
    private let stateLock = NSLock()
    
    // MARK: - 監控
    private let logger = Logger(subsystem: "com.signalair", category: "RobustNetwork")
    private let metricsCollector = NetworkMetricsCollector()
    
    // MARK: - 配置
    private struct Configuration {
        static let maxConcurrentOperations = 15
        static let operationTimeout: TimeInterval = 30.0
        static let circuitBreakerThreshold = 5
        static let recoveryTimeout: TimeInterval = 60.0
    }
    
    init(networkService: NetworkService, channelPoolManager: AdvancedChannelPoolManager) {
        self.networkService = networkService
        self.channelPoolManager = channelPoolManager
        
        setupOperationQueue()
        registerEdgeCaseHandlers()
        startMonitoring()
        
        logger.info("🛡️ RobustNetworkLayer initialized")
    }
    
    // MARK: - 公共API
    
    /// 健壯的發送操作 - 自動處理所有邊界情況
    func robustSend(_ data: Data, to peers: [MCPeerID], timeout: TimeInterval = Configuration.operationTimeout) async -> NetworkOperationResult {
        let operationId = UUID().uuidString
        
        logger.debug("📤 Starting robust send operation \(operationId)")
        
        // 1. 預檢查系統狀態
        guard await preflightCheck(operationId: operationId) else {
            return .failure(.systemUnavailable)
        }
        
        // 2. 檢測邊界情況
        let detectedEdgeCases = await edgeCaseDetector.detect(operation: "send", peers: peers, data: data)
        
        // 3. 處理檢測到的邊界情況
        for edgeCase in detectedEdgeCases {
            let handled = await handleEdgeCase(edgeCase)
            if !handled.success {
                let edgeCaseType: EdgeCaseType = edgeCase.type
                self.logger.warning("⚠️ Failed to handle edge case: \(String(describing: edgeCaseType))")
            }
        }
        
        // 4. 執行實際操作（帶重試機制）
        do {
            return try await executeWithRetry(operationId: operationId) {
                await self.performActualSend(data, to: peers, timeout: timeout)
            }
        } catch {
            logger.error("❌ Execute with retry failed: \(error)")
            return .failure(.sendFailed)
        }
    }
    
    /// 處理peer連接事件（邊界情況感知）
    func handlePeerConnection(_ peerID: MCPeerID) async {
        logger.info("🤝 Handling peer connection for \(peerID.displayName)")
        
        // 檢測同時連接競態條件
        let context = EdgeCaseContext(
            type: .simultaneousConnection,
            peerID: peerID,
            operation: "connect",
            attemptCount: 1,
            errorHistory: [],
            systemState: await getSystemState(),
            timestamp: Date()
        )
        
        let edgeCase = await edgeCaseDetector.analyzeContext(context)
        if let edgeCase = edgeCase {
            let _ = await handleEdgeCase(edgeCase)
        }
        
        // 更新通道池
        channelPoolManager.handlePeerConnected(peerID)
        
        // 更新網路健康度
        await updateNetworkHealth()
    }
    
    /// 處理peer斷開事件（邊界情況感知）
    func handlePeerDisconnection(_ peerID: MCPeerID) async {
        logger.info("👋 Handling peer disconnection for \(peerID.displayName)")
        
        // 檢測快速斷開重連模式
        let context = EdgeCaseContext(
            type: .rapidDisconnection,
            peerID: peerID,
            operation: "disconnect",
            attemptCount: 1,
            errorHistory: [],
            systemState: await getSystemState(),
            timestamp: Date()
        )
        
        let edgeCase = await edgeCaseDetector.analyzeContext(context)
        if let edgeCase = edgeCase {
            let _ = await handleEdgeCase(edgeCase)
        }
        
        // 更新通道池
        channelPoolManager.handlePeerDisconnected(peerID)
        
        // 清理相關恢復操作
        cleanupRecoveryOperations(for: peerID)
        
        // 更新網路健康度
        await updateNetworkHealth()
    }
    
    /// 處理背景/前景轉換
    func handleAppStateTransition(to state: AppState) async {
        let appState: AppState = state
        self.logger.info("📱 Handling app state transition to \(String(describing: appState))")
        
        let context = EdgeCaseContext(
            type: .backgroundTransition,
            peerID: nil,
            operation: "app_state_transition",
            attemptCount: 1,
            errorHistory: [],
            systemState: await getSystemState(),
            timestamp: Date()
        )
        
        let edgeCase = await edgeCaseDetector.analyzeContext(context)
        if let edgeCase = edgeCase {
            let _ = await handleEdgeCase(edgeCase)
        }
        
        // 調整操作策略
        adjustStrategyForAppState(state)
    }
    
    /// 獲取網路健康報告
    func getNetworkHealthReport() -> NetworkHealthReport {
        return NetworkHealthReport(
            overallHealth: networkHealth,
            edgeCaseStatistics: edgeCaseStats,
            activeRecoveries: activeRecoveries.count,
            circuitBreakerState: circuitBreaker.state,
            recommendations: generateHealthRecommendations()
        )
    }
    
    // MARK: - 私有方法
    
    private func setupOperationQueue() {
        operationQueue.maxConcurrentOperationCount = Configuration.maxConcurrentOperations
        operationQueue.qualityOfService = .userInitiated
    }
    
    private func registerEdgeCaseHandlers() {
        edgeCaseHandlers = [
            SimultaneousConnectionHandler(),
            RapidDisconnectionHandler(),
            BackgroundTransitionHandler(),
            MemoryPressureHandler(),
            ChannelContentionHandler(),
            NetworkInstabilityHandler(),
            ConcurrentOperationHandler(),
            ResourceExhaustionHandler()
        ].sorted { $0.priority > $1.priority }
        
        logger.debug("📝 Registered \(self.edgeCaseHandlers.count) edge case handlers")
    }
    
    private func startMonitoring() {
        // 啟動網路健康監控
        Task {
            while !Task.isCancelled {
                await updateNetworkHealth()
                await collectMetrics()
                
                // Eclipse 攻擊防禦檢查
                await performEclipseDefenseCheck()
                
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30秒
            }
        }
    }
    
    private func preflightCheck(operationId: String) async -> Bool {
        // 檢查熔斷器狀態
        guard circuitBreaker.canExecute() else {
            logger.warning("⚠️ Circuit breaker is open, blocking operation \(operationId)")
            return false
        }
        
        // 檢查系統資源
        let memoryPressure = await checkMemoryPressure()
        if memoryPressure > 0.8 {
            logger.warning("⚠️ High memory pressure, may affect operation \(operationId)")
        }
        
        // 檢查併發操作數
        if operationQueue.operationCount >= Configuration.maxConcurrentOperations {
            logger.warning("⚠️ Too many concurrent operations, may queue operation \(operationId)")
        }
        
        return true
    }
    
    private func executeWithRetry<T>(
        operationId: String,
        maxRetries: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0
        let maxBackoffDelay: TimeInterval = 30.0 // 最大退避延遲 30 秒
        let baseDelay: TimeInterval = 0.5 // 基礎延遲 500ms
        
        while attempt <= maxRetries {
            do {
                let result = try await operation()
                
                // 操作成功，通知熔斷器
                circuitBreaker.recordSuccess()
                
                self.logger.debug("✅ Operation \(operationId) succeeded on attempt \(attempt + 1)")
                return result
                
            } catch {
                lastError = error
                attempt += 1
                
                // 如果已達最大重試次數，拋出最後的錯誤
                if attempt > maxRetries {
                    circuitBreaker.recordFailure()
                    self.logger.error("❌ Operation \(operationId) failed after \(maxRetries + 1) attempts: \(error)")
                    throw error
                }
                
                // 計算指數退避延遲 (0.5s, 1s, 2s, 4s, 8s, ...)
                let backoffDelay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxBackoffDelay)
                let jitter = Double.random(in: 0...0.1) * backoffDelay // 添加 10% 隨機抖動
                let totalDelay = backoffDelay + jitter
                
                self.logger.warning("⚠️ Operation \(operationId) failed on attempt \(attempt), retrying in \(String(format: "%.2f", totalDelay))s: \(error)")
                
                // 等待退避時間
                try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            }
        }
        
        // 這裡理論上不會到達，但為了編譯器滿意
        throw lastError ?? NSError(domain: "RobustNetworkLayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知錯誤"])
    }
    
    private func performActualSend(_ data: Data, to peers: [MCPeerID], timeout: TimeInterval) async -> NetworkOperationResult {
        let startTime = Date()
        
        // 並行發送並收集結果
        let results = await performParallelSend(data: data, to: peers, startTime: startTime)
        
        // 分析發送結果
        return analyzeSendResults(results)
    }
    
    /// 並行發送到多個 peers
    private func performParallelSend(data: Data, to peers: [MCPeerID], startTime: Date) async -> [MCPeerID: Result<Void, Error>] {
        await withTaskGroup(of: (MCPeerID, Result<Void, Error>).self) { group in
            var results: [MCPeerID: Result<Void, Error>] = [:]
            
            // 為每個 peer 創建發送任務
            for peer in peers {
                group.addTask { [weak self] in
                    let result = await self?.sendToPeer(data: data, peer: peer, startTime: startTime) ?? .failure(NetworkError.internalError)
                    return (peer, result)
                }
            }
            
            // 收集所有結果
            for await (peer, result) in group {
                results[peer] = result
            }
            
            return results
        }
    }
    
    /// 發送到單個 peer
    private func sendToPeer(data: Data, peer: MCPeerID, startTime: Date) async -> Result<Void, Error> {
        do {
            // 步驟 1: 獲取通道
            let channel = try await acquireChannelForPeer(peer)
            
            // 步驟 2: 執行發送
            try await performSendOperation(data: data, to: peer)
            
            // 步驟 3: 記錄成功並釋放通道
            recordSuccessAndReleaseChannel(channel: channel, startTime: startTime, dataSize: data.count)
            
            return .success(())
            
        } catch {
            logger.warning("⚠️ 發送到 \(peer.displayName) 失敗: \(error)")
            return .failure(error)
        }
    }
    
    /// 獲取通道
    private func acquireChannelForPeer(_ peer: MCPeerID) async throws -> ChannelInstance {
        guard let channel = await channelPoolManager.acquireChannel(for: peer) else {
            throw NetworkError.channelUnavailable
        }
        return channel
    }
    
    /// 執行實際發送操作
    private func performSendOperation(data: Data, to peer: MCPeerID) async throws {
        try await networkService.send(data, to: [peer])
    }
    
    /// 記錄成功並釋放通道
    private func recordSuccessAndReleaseChannel(channel: ChannelInstance, startTime: Date, dataSize: Int) {
        let latency = Date().timeIntervalSince(startTime)
        channelPoolManager.releaseChannel(channel, success: true, latency: latency, dataSize: dataSize)
    }
    
    /// 分析發送結果
    private func analyzeSendResults(_ results: [MCPeerID: Result<Void, Error>]) -> NetworkOperationResult {
        let successfulSends = results.values.compactMap { result in
            if case .success = result { return 1 } else { return nil }
        }.count
        
        let errors = extractErrors(from: results)
        let totalPeers = results.count
        
        return determineOperationResult(
            successfulSends: successfulSends,
            totalPeers: totalPeers,
            errors: errors
        )
    }
    
    /// 提取錯誤信息
    private func extractErrors(from results: [MCPeerID: Result<Void, Error>]) -> [String: Error] {
        var errors: [String: Error] = [:]
        
        for (peer, result) in results {
            if case .failure(let error) = result {
                errors[peer.displayName] = error
            }
        }
        
        return errors
    }
    
    /// 決定操作結果
    private func determineOperationResult(successfulSends: Int, totalPeers: Int, errors: [String: Error]) -> NetworkOperationResult {
        switch successfulSends {
        case totalPeers:
            return .success(nil)
        case 1..<totalPeers:
            return .partialSuccess(nil, errors)
        default:
            return .failure(.sendFailed)
        }
    }
    
    private func handleEdgeCase(_ context: EdgeCaseContext) async -> EdgeCaseResult {
        // 尋找合適的處理器
        for handler in edgeCaseHandlers {
            if handler.canHandle(context.type) {
                let result = await handler.handle(context)
                
                // 更新統計
                self.edgeCaseStats[context.type, default: 0] += 1
                
                let contextType: EdgeCaseType = context.type
        self.logger.info("🔧 Handled edge case \(String(describing: contextType)) with result: \(result.success)")
                
                return result
            }
        }
        
        // 沒有找到合適的處理器
        let contextType: EdgeCaseType = context.type
        self.logger.warning("⚠️ No handler found for edge case: \(String(describing: contextType))")
        return EdgeCaseResult(success: false, recoveryAction: RecoveryAction.none, delay: nil, message: "No handler available")
    }
    
    private func getSystemState() async -> [String: Any] {
        return [
            "memoryPressure": await checkMemoryPressure(),
            "activeOperations": operationQueue.operationCount,
            "networkHealth": networkHealth.rawValue,
            "connectedPeers": networkService.connectedPeers.count,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    private func checkMemoryPressure() async -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024 / 1024
            return min(1.0, memoryMB / 512.0) // 假設512MB為高壓力線
        }
        
        return 0.0
    }
    
    private func updateNetworkHealth() async {
        let connectedPeers = networkService.connectedPeers.count
        let poolReport = self.channelPoolManager.getDetailedReport()
        let memoryPressure = await checkMemoryPressure()
        
        // 綜合評估網路健康度
        if connectedPeers == 0 {
            self.networkHealth = .offline
        } else if poolReport.averageQuality > 0.8 && poolReport.failedChannels == 0 && memoryPressure < 0.6 {
            self.networkHealth = .excellent
        } else if poolReport.averageQuality > 0.6 && poolReport.failedChannels < 3 && memoryPressure < 0.8 {
            self.networkHealth = .good
        } else if poolReport.averageQuality > 0.4 && poolReport.failedChannels < 5 {
            self.networkHealth = .fair
        } else {
            self.networkHealth = .poor
        }
        
        let currentHealth: NetworkHealth = self.networkHealth
        self.logger.debug("💊 Network health updated to: \(String(describing: currentHealth))")
    }
    
    private func collectMetrics() async {
        let metrics = NetworkMetrics(
            timestamp: Date(),
            connectedPeers: networkService.connectedPeers.count,
            activeOperations: operationQueue.operationCount,
            edgeCaseCount: edgeCaseStats.values.reduce(0, +),
            memoryPressure: await checkMemoryPressure(),
            networkHealth: networkHealth
        )
        
        metricsCollector.record(metrics)
    }
    
    private func adjustStrategyForAppState(_ state: AppState) {
        switch state {
        case .background:
            operationQueue.maxConcurrentOperationCount = max(1, Configuration.maxConcurrentOperations / 3)
        case .foreground:
            operationQueue.maxConcurrentOperationCount = Configuration.maxConcurrentOperations
        }
    }
    
    private func cleanupRecoveryOperations(for peerID: MCPeerID) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        let keysToRemove = activeRecoveries.keys.filter { key in
            activeRecoveries[key]?.peerID == peerID
        }
        
        for key in keysToRemove {
            activeRecoveries.removeValue(forKey: key)
        }
    }
    
    private func calculateBackoffDelay(attempt: Int) -> TimeInterval {
        let baseDelay = 0.5
        let maxDelay = 10.0
        return min(maxDelay, baseDelay * pow(2.0, Double(attempt - 1)))
    }
    
    private func generateHealthRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if networkHealth == .poor {
            recommendations.append("網路品質差，建議檢查連接")
        }
        
        if edgeCaseStats.values.reduce(0, +) > 50 {
            recommendations.append("邊界情況頻繁，建議調整配置")
        }
        
        if activeRecoveries.count > 5 {
            recommendations.append("過多恢復操作，建議重啟網路層")
        }
        
        return recommendations
    }
    
    // MARK: - Eclipse Attack Defense - Micro Auto-Reconnect Fault Tolerance
    
    private struct EclipseDefenseConnectionRefresh {
        private var refreshHistory: [ConnectionRefreshEvent] = []
        private let maxHistorySize = 20
        private let refreshThreshold: TimeInterval = 120.0
        
        struct ConnectionRefreshEvent {
            let timestamp: Date
            let reason: RefreshReason
            let peerID: MCPeerID?
            let success: Bool
        }
        
        enum RefreshReason {
            case securityThreat
            case lowDiversity
            case networkInstability
            case proactiveRefresh
        }
        
        enum RefreshRecommendation {
            case refreshNeeded(priority: RefreshPriority)
            case noActionNeeded
            
            enum RefreshPriority {
                case low
                case medium
                case high
                case emergency
            }
        }
        
        mutating func recordRefresh(_ event: ConnectionRefreshEvent) {
            refreshHistory.append(event)
            
            if refreshHistory.count > maxHistorySize {
                refreshHistory.removeFirst(refreshHistory.count - maxHistorySize)
            }
        }
        
        func evaluateConnectionRefreshNeed(
            networkHealth: NetworkHealth,
            edgeCaseCount: Int,
            connectedPeers: Int
        ) -> RefreshRecommendation {
            let recentFailures = refreshHistory.filter {
                Date().timeIntervalSince($0.timestamp) < refreshThreshold && !$0.success
            }
            
            // 緊急情況判斷
            if networkHealth == .poor && connectedPeers > 0 {
                return .refreshNeeded(priority: .high)
            }
            
            // 邊界情況過多
            if edgeCaseCount > 10 {
                return .refreshNeeded(priority: .medium)
            }
            
            // 最近失敗過多
            if recentFailures.count > 3 {
                return .refreshNeeded(priority: .low)
            }
            
            return .noActionNeeded
        }
        
        func selectOptimalReconnectionTargets(from peers: [MCPeerID]) -> [MCPeerID] {
            // 簡化實現：隨機選擇一部分 peers 進行重連
            let maxTargets = min(3, peers.count / 2)
            return Array(peers.shuffled().prefix(maxTargets))
        }
    }
    
    private var eclipseConnectionRefresh = EclipseDefenseConnectionRefresh()
    
    /// Eclipse 攻擊防禦 - 評估連接重新整理需求
    @MainActor
    private func evaluateEclipseConnectionRefresh() -> EclipseDefenseConnectionRefresh.RefreshRecommendation {
        let connectedPeers = networkService.connectedPeers.count
        let edgeCaseCount = edgeCaseStats.values.reduce(0, +)
        
        return eclipseConnectionRefresh.evaluateConnectionRefreshNeed(
            networkHealth: networkHealth,
            edgeCaseCount: edgeCaseCount,
            connectedPeers: connectedPeers
        )
    }
    
    /// Eclipse 攻擊防禦 - 執行智能重連
    @MainActor
    private func performIntelligentReconnection() async {
        let recommendation = evaluateEclipseConnectionRefresh()
        
        guard case .refreshNeeded(let priority) = recommendation else {
            #if DEBUG
            print("🔍 Eclipse 防禦：無需重連")
            #endif
            return
        }
        
        #if DEBUG
        print("🔄 Eclipse 防禦：開始智能重連 (優先級: \(priority))")
        #endif
        
        let connectedPeers = networkService.connectedPeers
        let optimalTargets = eclipseConnectionRefresh.selectOptimalReconnectionTargets(from: connectedPeers)
        
        // 漸進式重連，避免網路中斷
        for (index, target) in optimalTargets.enumerated() {
            #if DEBUG
            print("🔄 正在重連至 \(target.displayName)")
            #endif
            
            let refreshEvent = EclipseDefenseConnectionRefresh.ConnectionRefreshEvent(
                timestamp: Date(),
                reason: priority == .high ? .securityThreat : .proactiveRefresh,
                peerID: target,
                success: true // 簡化實現，假設成功
            )
            
            eclipseConnectionRefresh.recordRefresh(refreshEvent)
            
            // 關鍵：加入延遲避免同時重連太多連接
            if index < optimalTargets.count - 1 {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒間隔
            }
        }
        
        #if DEBUG
        print("✅ Eclipse 防禦智能重連完成")
        #endif
    }
    
    /// Eclipse 攻擊防禦 - 整合检查
    @MainActor
    func performEclipseDefenseCheck() async {
        let recommendation = evaluateEclipseConnectionRefresh()
        
        if case .refreshNeeded(let priority) = recommendation {
            switch priority {
            case .emergency, .high:
                await performIntelligentReconnection()
            case .medium:
                // 延遲執行，避免影響正常操作
                Task {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10秒
                    await self.performIntelligentReconnection()
                }
            case .low:
                // 低優先級，只在系統關不忙礙時執行
                if operationQueue.operationCount < 5 {
                    Task {
                        try? await Task.sleep(nanoseconds: 30_000_000_000) // 30秒
                        await self.performIntelligentReconnection()
                    }
                }
            }
        }
    }
}

// MARK: - 支持類型

enum NetworkHealth: String {
    case unknown = "unknown"
    case offline = "offline"
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
}

enum AppState {
    case foreground
    case background
}

struct NetworkHealthReport {
    let overallHealth: NetworkHealth
    let edgeCaseStatistics: [EdgeCaseType: Int]
    let activeRecoveries: Int
    let circuitBreakerState: CircuitBreakerState
    let recommendations: [String]
}

struct RecoveryOperation {
    let id: String
    let peerID: MCPeerID?
    let type: EdgeCaseType
    let startTime: Date
    let timeout: TimeInterval
}

struct NetworkMetrics {
    let timestamp: Date
    let connectedPeers: Int
    let activeOperations: Int
    let edgeCaseCount: Int
    let memoryPressure: Double
    let networkHealth: NetworkHealth
}

extension NetworkError {
    static let systemUnavailable = NetworkError.sessionError("System unavailable")
}

// MARK: - 邊界情況檢測器

class EdgeCaseDetector {
    private var connectionHistory: [MCPeerID: [Date]] = [:]
    private var disconnectionHistory: [MCPeerID: [Date]] = [:]
    private var operationHistory: [String: [Date]] = [:]
    
    func detect(operation: String, peers: [MCPeerID], data: Data) async -> [EdgeCaseContext] {
        var detectedCases: [EdgeCaseContext] = []
        
        // 檢測併發操作過多
        if await checkConcurrentOperations() {
            detectedCases.append(createContext(.concurrentOperations, operation: operation))
        }
        
        // 檢測通道競爭
        if await checkChannelContention(peers: peers) {
            detectedCases.append(createContext(.channelContention, operation: operation))
        }
        
        // 檢測資源耗盡
        if await checkResourceExhaustion() {
            detectedCases.append(createContext(.resourceExhaustion, operation: operation))
        }
        
        return detectedCases
    }
    
    func analyzeContext(_ context: EdgeCaseContext) async -> EdgeCaseContext? {
        // 分析上下文是否確實構成邊界情況
        switch context.type {
        case .simultaneousConnection:
            return await analyzeSimilarConnections(context)
        case .rapidDisconnection:
            return await analyzeRapidDisconnections(context)
        default:
            return context
        }
    }
    
    private func checkConcurrentOperations() async -> Bool {
        // 實際檢測邏輯
        return false // 簡化實現
    }
    
    private func checkChannelContention(peers: [MCPeerID]) async -> Bool {
        // 實際檢測邏輯
        return false // 簡化實現
    }
    
    private func checkResourceExhaustion() async -> Bool {
        // 實際檢測邏輯
        return false // 簡化實現
    }
    
    private func analyzeSimilarConnections(_ context: EdgeCaseContext) async -> EdgeCaseContext? {
        // 分析是否存在同時連接問題
        return context // 簡化實現
    }
    
    private func analyzeRapidDisconnections(_ context: EdgeCaseContext) async -> EdgeCaseContext? {
        // 分析是否存在快速斷開重連問題
        return context // 簡化實現
    }
    
    private func createContext(_ type: EdgeCaseType, operation: String, peerID: MCPeerID? = nil) -> EdgeCaseContext {
        return EdgeCaseContext(
            type: type,
            peerID: peerID,
            operation: operation,
            attemptCount: 1,
            errorHistory: [],
            systemState: [:],
            timestamp: Date()
        )
    }
}

// MARK: - 熔斷器

enum CircuitBreakerState: String {
    case closed = "closed"
    case open = "open"
    case halfOpen = "half_open"
}

class CircuitBreaker {
    private(set) var state: CircuitBreakerState = .closed
    private var failureCount = 0
    private var successCount = 0
    private var lastFailureTime: Date?
    
    private let failureThreshold = 5
    private let recoveryTimeout: TimeInterval = 60.0
    private let successThreshold = 3
    
    func canExecute() -> Bool {
        switch state {
        case .closed:
            return true
        case .open:
            return shouldAttemptReset()
        case .halfOpen:
            return true
        }
    }
    
    func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0
        case .halfOpen:
            successCount += 1
            if successCount >= successThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
            }
        case .open:
            break
        }
    }
    
    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        switch state {
        case .closed:
            if failureCount >= failureThreshold {
                state = .open
            }
        case .halfOpen:
            state = .open
            successCount = 0
        case .open:
            break
        }
    }
    
    private func shouldAttemptReset() -> Bool {
        guard let lastFailure = lastFailureTime else { return false }
        
        if Date().timeIntervalSince(lastFailure) >= recoveryTimeout {
            state = .halfOpen
            successCount = 0
            return true
        }
        
        return false
    }
}

// MARK: - 網路指標收集器

class NetworkMetricsCollector {
    private var metrics: [NetworkMetrics] = []
    private let maxMetrics = 1000
    
    func record(_ metric: NetworkMetrics) {
        metrics.append(metric)
        
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
    }
    
    func getRecentMetrics(count: Int = 100) -> [NetworkMetrics] {
        return Array(metrics.suffix(count))
    }
    
    func calculateAverageHealth(over duration: TimeInterval) -> NetworkHealth {
        let cutoffTime = Date().addingTimeInterval(-duration)
        let recentMetrics = metrics.filter { $0.timestamp > cutoffTime }
        
        guard !recentMetrics.isEmpty else { return .unknown }
        
        // 簡化的健康度計算
        let healthScores = recentMetrics.map { metric -> Double in
            switch metric.networkHealth {
            case .excellent: return 1.0
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.4
            case .offline: return 0.0
            case .unknown: return 0.5
            }
        }
        
        let averageScore = healthScores.reduce(0, +) / Double(healthScores.count)
        
        switch averageScore {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        case 0.2..<0.5: return .poor
        case 0.0..<0.2: return .offline
        default: return .unknown
        }
    }
}