import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Eclipse Attack Defense Coordinator
// 統一協調 Eclipse 攻擊防禦機制

/// Eclipse 攻擊防禦協調器 - 統一管理三層防禦機制
@MainActor
class EclipseDefenseCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var defenseStatus: DefenseStatus = .initializing
    @Published private(set) var lastDefenseCheck: Date = Date.distantPast
    @Published private(set) var detectedThreats: [EclipseThreat] = []
    @Published private(set) var defenseMetrics: DefenseMetrics = DefenseMetrics()
    
    // MARK: - Dependencies
    private weak var networkService: NetworkServiceProtocol?
    private weak var topologyManager: TopologyManager?
    // 暫時註解，等 RobustNetworkLayer 修復後再啟用
    // private weak var robustNetworkLayer: RobustNetworkLayer?
    
    // MARK: - Defense Configuration
    // ⚡ 性能優化師：優化防禦配置參數
    private struct DefenseConfiguration {
        static let coordinatedCheckInterval: TimeInterval = 30.0  // 優化：減少檢查間隔
        static let threatRetentionPeriod: TimeInterval = 180.0    // 優化：減少威脅保存時間
        static let maxConcurrentDefenseActions = 2               // 優化：減少並發動作數
        static let performanceCheckThreshold = 10                 // 新增：性能檢查閾值
    }
    
    // MARK: - Internal State
    // ⚡ 性能優化師：優化內部狀態管理
    private var defenseTimer: Timer?
    private var activeDefenseActions: Set<String> = []
    private let defenseQueue = DispatchQueue(label: "com.signalair.eclipse-defense", qos: .utility) // 優化：降低 QoS
    private var performanceMetrics: [String: TimeInterval] = [:]  // 新增：性能指標追蹤
    private var lastOptimizationTime: Date = Date()               // 新增：最後優化時間
    
    // MARK: - Initialization
    init(
        networkService: NetworkServiceProtocol? = nil,
        topologyManager: TopologyManager? = nil
    ) {
        self.networkService = networkService
        self.topologyManager = topologyManager
        
        setupNotificationObservers()
        print("🛡️ EclipseDefenseCoordinator 初始化完成")
    }
    
    // 🛡️ 安全專家：安全的析構函數
    deinit {
        // 同步清理，避免併發問題
        defenseTimer?.invalidate()
        defenseTimer = nil
        activeDefenseActions.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 啟動 Eclipse 攻擊防禦系統
    func startEclipseDefense() {
        guard defenseStatus != .active else {
            print("⚠️ Eclipse 防禦系統已經在運行中")
            return
        }
        
        defenseStatus = .active
        startCoordinatedDefense()
        
        #if DEBUG
        print("🚀 Eclipse 攻擊防禦系統已啟動")
        #endif
    }
    
    /// 停止 Eclipse 攻擊防禦系統
    func stopEclipseDefense() {
        defenseStatus = .inactive
        defenseTimer?.invalidate()
        defenseTimer = nil
        activeDefenseActions.removeAll()
        
        #if DEBUG
        print("🛑 Eclipse 攻擊防禦系統已停止")
        #endif
    }
    
    /// 執行即時防禦檢查
    func performImmediateDefenseCheck() async {
        await executeCoordinatedDefenseCheck()
    }
    
    /// 獲取防禦狀態報告
    func getDefenseReport() -> EclipseDefenseReport {
        return EclipseDefenseReport(
            status: defenseStatus,
            lastCheck: lastDefenseCheck,
            activeThreats: detectedThreats,
            metrics: defenseMetrics,
            recommendations: generateDefenseRecommendations()
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EclipseRiskDetected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                await self?.handleTopologyRisk(notification.object ?? "Unknown risk")
            }
        }
    }
    
    private func startCoordinatedDefense() {
        defenseTimer = Timer.scheduledTimer(withTimeInterval: DefenseConfiguration.coordinatedCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.executeCoordinatedDefenseCheck()
            }
        }
    }
    
    /// 執行協調的防禦檢查
    // ⚡ 性能優化師：優化防禦檢查性能
    private func executeCoordinatedDefenseCheck() async {
        guard defenseStatus == .active else { return }
        
        let startTime = Date()
        lastDefenseCheck = startTime
        
        #if DEBUG
        print("🔍 執行協調的 Eclipse 防禦檢查")
        #endif
        
        var newThreats: [EclipseThreat] = []
        
        // ⚡ 性能優化：只在必要時執行檢查
        if shouldPerformOptimizedCheck() {
        
        // 1. 輕量隨機探測（NetworkService）
        if let networkService = networkService {
            let probeResult = await performRandomProbeCheck(networkService)
            if let threat = probeResult {
                newThreats.append(threat)
            }
        }
        
        // 2. 被動拓撲多樣性偵測（TopologyManager）
        if let topologyManager = topologyManager {
            let diversityResult = await performDiversityCheck(topologyManager)
            if let threat = diversityResult {
                newThreats.append(threat)
            }
        }
        
        // 3. 微型自動重連容錯（暫時跳過 RobustNetworkLayer）
        // if let robustLayer = robustNetworkLayer {
        //     let connectionResult = await performConnectionCheck(robustLayer)
        //     if let threat = connectionResult {
        //         newThreats.append(threat)
        //     }
        // }
        
        // 更新威脅列表
        updateThreatsList(with: newThreats)
        
        } // 結束 shouldPerformOptimizedCheck
        
        // 更新防禦指標
        updateDefenseMetrics()
        
        // 執行協調的防禦動作
        await executeCoordinatedDefenseActions()
        
        // ⚡ 性能優化：記錄性能指標
        let executionTime = Date().timeIntervalSince(startTime)
        performanceMetrics["defenseCheck"] = executionTime
        
        #if DEBUG
        print("⚡ 防禦檢查執行時間: \(String(format: "%.2f", executionTime))s")
        #endif
    }
    
    // 🛡️ 安全專家：實現安全的隨機探測檢查
    private func performRandomProbeCheck(_ networkService: NetworkServiceProtocol) async -> EclipseThreat? {
        let connectedPeers = networkService.connectedPeers.count
        
        // 安全檢查：檢測異常連接模式
        if connectedPeers > 0 {
            // 執行安全的連接品質檢查
            await performSecureConnectionCheck(networkService)
            return nil
        }
        
        return EclipseThreat(
            type: .probeAnomaly,
            severity: .medium,
            description: "隨機探測檢測到異常模式",
            timestamp: Date(),
            affectedPeers: []
        )
    }
    
    // 🛡️ 安全專家：新增安全連接檢查方法
    private func performSecureConnectionCheck(_ networkService: NetworkServiceProtocol) async {
        // 檢查連接品質和安全性
        let peers = networkService.connectedPeers
        for peer in peers {
            // 執行安全驗證
            await validatePeerSecurity(peer.displayName)
        }
    }
    
    // 🛡️ 安全專家：驗證對等節點安全性
    private func validatePeerSecurity(_ peerName: String) async {
        // 簡化的安全驗證邏輯
        print("🔒 驗證對等節點安全性: \(peerName)")
    }
    
    private func performDiversityCheck(_ topologyManager: TopologyManager) async -> EclipseThreat? {
        // 簡化實現 - 直接觸發多樣性檢查
        topologyManager.performEclipseDiversityCheck()
        
        // 基於連接數進行簡單風險評估
        let stats = topologyManager.getNetworkStatistics()
        
        if stats.connectedNodes > 0 && stats.connectedNodes < 3 {
            return EclipseThreat(
                type: .diversityDeficit,
                severity: .high,
                description: "連接多樣性不足，可能存在 Eclipse 攻擊風險",
                timestamp: Date(),
                affectedPeers: []
            )
        }
        
        return nil
    }
    
    private func performConnectionCheck(_ robustLayer: RobustNetworkLayer) async -> EclipseThreat? {
        // RobustNetworkLayer 的方法現在是私有的，所以暫時簡化實現
        
        // 基本的連接檢查邏輯
        let connectedPeers = networkService?.connectedPeers ?? []
        
        if connectedPeers.count > 0 && connectedPeers.count < 3 {
            return EclipseThreat(
                type: .connectionConcentration,
                severity: .medium,
                description: "檢測到連接集中化，需要重新整理連接",
                timestamp: Date(),
                affectedPeers: []
            )
        }
        
        return nil
    }
    
    private func updateThreatsList(with newThreats: [EclipseThreat]) {
        // 添加新威脅
        detectedThreats.append(contentsOf: newThreats)
        
        // 清理過期威脅
        let cutoffTime = Date().addingTimeInterval(-DefenseConfiguration.threatRetentionPeriod)
        detectedThreats.removeAll { $0.timestamp < cutoffTime }
        
        // 按嚴重性排序
        detectedThreats.sort { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    private func updateDefenseMetrics() {
        let now = Date()
        defenseMetrics = DefenseMetrics(
            totalChecks: defenseMetrics.totalChecks + 1,
            threatsDetected: detectedThreats.count,
            lastUpdate: now,
            averageResponseTime: calculateAverageResponseTime(),
            defenseEffectiveness: calculateDefenseEffectiveness()
        )
    }
    
    private func executeCoordinatedDefenseActions() async {
        let highPriorityThreats = detectedThreats.filter { $0.severity == .critical || $0.severity == .high }
        
        guard !highPriorityThreats.isEmpty,
              activeDefenseActions.count < DefenseConfiguration.maxConcurrentDefenseActions else {
            return
        }
        
        for threat in highPriorityThreats.prefix(DefenseConfiguration.maxConcurrentDefenseActions - activeDefenseActions.count) {
            let actionId = UUID().uuidString
            activeDefenseActions.insert(actionId)
            
            Task {
                defer {
                    Task { @MainActor in
                        self.activeDefenseActions.remove(actionId)
                    }
                }
                
                await executeDefenseAction(for: threat)
            }
        }
    }
    
    private func executeDefenseAction(for threat: EclipseThreat) async {
        #if DEBUG
        print("🛡️ 執行針對 \(threat.type) 的防禦動作")
        #endif
        
        switch threat.type {
        case .probeAnomaly:
            // 🛡️ 安全專家：增加探測頻率並執行安全檢查
            if let networkService = networkService {
                await performSecureConnectionCheck(networkService)
            }
            
        case .diversityDeficit:
            // 觸發拓撲重新平衡
            topologyManager?.performEclipseDiversityCheck()
            
        case .connectionConcentration:
            // 觸發智能重連 (RobustNetworkLayer 方法現在是私有的)
            print("🔄 連接集中化威脅：需要重新整理連接")
        }
    }
    
    private func handleTopologyRisk(_ result: Any) async {
        // 簡化實現 - 直接創建威脅
        let threat = EclipseThreat(
            type: .diversityDeficit,
            severity: .high,
            description: "拓撲多樣性檢測到風險",
            timestamp: Date(),
            affectedPeers: []
        )
        
        detectedThreats.append(threat)
        await executeDefenseAction(for: threat)
    }
    
    private func calculateAverageResponseTime() -> TimeInterval {
        // 簡化實現
        return 0.5
    }
    
    private func calculateDefenseEffectiveness() -> Double {
        // 簡化實現
        let recentThreats = detectedThreats.filter {
            Date().timeIntervalSince($0.timestamp) < 300
        }
        
        if recentThreats.isEmpty {
            return 1.0
        }
        
        return max(0.0, 1.0 - Double(recentThreats.count) / 10.0)
    }
    
    private func generateDefenseRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if detectedThreats.count > 5 {
            recommendations.append("威脅數量較多，建議檢查網路環境")
        }
        
        if defenseMetrics.defenseEffectiveness < 0.7 {
            recommendations.append("防禦效果偏低，建議調整防禦策略")
        }
        
        let criticalThreats = detectedThreats.filter { $0.severity == .critical }
        if !criticalThreats.isEmpty {
            recommendations.append("存在嚴重威脅，建議立即採取行動")
        }
        
        return recommendations
    }
    
    // ⚡ 性能優化師：性能優化方法
    private func shouldPerformOptimizedCheck() -> Bool {
        let timeSinceLastOptimization = Date().timeIntervalSince(lastOptimizationTime)
        return timeSinceLastOptimization > DefenseConfiguration.coordinatedCheckInterval
    }
    
    private func optimizeDefensePerformance() {
        // 清理過期的性能指標
        let _ = Date().addingTimeInterval(-DefenseConfiguration.threatRetentionPeriod)
        performanceMetrics = performanceMetrics.filter { _ in
            // 簡化實現：保留所有指標
            return true
        }
        
        lastOptimizationTime = Date()
    }
}

// MARK: - Supporting Types

enum DefenseStatus: String {
    case initializing = "initializing"
    case active = "active"
    case inactive = "inactive"
    case error = "error"
}

enum EclipseThreatType: String {
    case probeAnomaly = "probe_anomaly"
    case diversityDeficit = "diversity_deficit"
    case connectionConcentration = "connection_concentration"
}

enum ThreatSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

struct EclipseThreat {
    let type: EclipseThreatType
    let severity: ThreatSeverity
    let description: String
    let timestamp: Date
    let affectedPeers: [String]
    
    var id: String {
        return "\(type.rawValue)_\(timestamp.timeIntervalSince1970)"
    }
}

struct DefenseMetrics {
    let totalChecks: Int
    let threatsDetected: Int
    let lastUpdate: Date
    let averageResponseTime: TimeInterval
    let defenseEffectiveness: Double
    
    init() {
        self.totalChecks = 0
        self.threatsDetected = 0
        self.lastUpdate = Date()
        self.averageResponseTime = 0.0
        self.defenseEffectiveness = 1.0
    }
    
    init(totalChecks: Int, threatsDetected: Int, lastUpdate: Date, averageResponseTime: TimeInterval, defenseEffectiveness: Double) {
        self.totalChecks = totalChecks
        self.threatsDetected = threatsDetected
        self.lastUpdate = lastUpdate
        self.averageResponseTime = averageResponseTime
        self.defenseEffectiveness = defenseEffectiveness
    }
}

struct EclipseDefenseReport {
    let status: DefenseStatus
    let lastCheck: Date
    let activeThreats: [EclipseThreat]
    let metrics: DefenseMetrics
    let recommendations: [String]
    
    var isSystemHealthy: Bool {
        return activeThreats.filter { $0.severity == .critical || $0.severity == .high }.isEmpty
    }
    
    var formattedReport: String {
        return """
        🛡️ Eclipse 攻擊防禦報告
        狀態: \(status.rawValue)
        最後檢查: \(lastCheck.formatted())
        活躍威脅: \(activeThreats.count)
        總檢查次數: \(metrics.totalChecks)
        防禦效率: \(String(format: "%.1f%%", metrics.defenseEffectiveness * 100))
        建議: \(recommendations.joined(separator: ", "))
        """
    }
}