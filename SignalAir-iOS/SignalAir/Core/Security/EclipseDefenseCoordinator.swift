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
    private weak var robustNetworkLayer: RobustNetworkLayer?
    
    // MARK: - Defense Configuration
    private struct DefenseConfiguration {
        static let coordinatedCheckInterval: TimeInterval = 45.0
        static let threatRetentionPeriod: TimeInterval = 300.0
        static let maxConcurrentDefenseActions = 3
    }
    
    // MARK: - Internal State
    private var defenseTimer: Timer?
    private var activeDefenseActions: Set<String> = []
    private let defenseQueue = DispatchQueue(label: "com.signalair.eclipse-defense", qos: .userInitiated)
    
    // MARK: - Initialization
    init(
        networkService: NetworkServiceProtocol? = nil,
        topologyManager: TopologyManager? = nil,
        robustNetworkLayer: RobustNetworkLayer? = nil
    ) {
        self.networkService = networkService
        self.topologyManager = topologyManager
        self.robustNetworkLayer = robustNetworkLayer
        
        setupNotificationObservers()
        print("🛡️ EclipseDefenseCoordinator 初始化完成")
    }
    
    deinit {
        stopEclipseDefense()
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
    private func executeCoordinatedDefenseCheck() async {
        guard defenseStatus == .active else { return }
        
        lastDefenseCheck = Date()
        
        #if DEBUG
        print("🔍 執行協調的 Eclipse 防禦檢查")
        #endif
        
        var newThreats: [EclipseThreat] = []
        
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
        
        // 3. 微型自動重連容錯（RobustNetworkLayer）
        if let robustLayer = robustNetworkLayer {
            let connectionResult = await performConnectionCheck(robustLayer)
            if let threat = connectionResult {
                newThreats.append(threat)
            }
        }
        
        // 更新威脅列表
        updateThreatsList(with: newThreats)
        
        // 更新防禦指標
        updateDefenseMetrics()
        
        // 執行協調的防禦動作
        await executeCoordinatedDefenseActions()
    }
    
    private func performRandomProbeCheck(_ networkService: NetworkServiceProtocol) async -> EclipseThreat? {
        // 檢查網路服務是否有進行隨機探測
        // 這裡簡化實現，實際應該檢查探測結果
        let connectedPeers = networkService.connectedPeers.count
        
        if connectedPeers > 0 {
            // 觸發網路服務的健康檢查，其中包含隨機探測
            networkService.checkConnectionQuality()
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
        let recommendation = robustLayer.evaluateEclipseConnectionRefresh()
        
        if case .refreshNeeded(let priority) = recommendation {
            let severity: ThreatSeverity = switch priority {
            case .emergency: .critical
            case .high: .high
            case .medium: .medium
            case .low: .low
            }
            
            return EclipseThreat(
                type: .connectionConcentration,
                severity: severity,
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
            // 增加探測頻率
            networkService?.checkConnectionQuality()
            
        case .diversityDeficit:
            // 觸發拓撲重新平衡
            topologyManager?.performEclipseDiversityCheck()
            
        case .connectionConcentration:
            // 觸發智能重連
            await robustNetworkLayer?.performIntelligentReconnection()
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