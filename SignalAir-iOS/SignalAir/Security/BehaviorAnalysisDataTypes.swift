import Foundation

// MARK: - Behavior Analysis System Data Types

// MARK: - Behavior Phases
enum BehaviorPhase: CaseIterable {
    case informationGathering
    case initialAccess
    case establishPersistence
    case lateralMovement
    case dataCollection
    
    var description: String {
        switch self {
        case .informationGathering: return "資訊收集階段"
        case .initialAccess: return "初始存取"
        case .establishPersistence: return "建立持久性"
        case .lateralMovement: return "橫向移動"
        case .dataCollection: return "資料收集"
        }
    }
    
    var severity: BehaviorSeverity {
        switch self {
        case .informationGathering: return .low
        case .initialAccess: return .medium
        case .establishPersistence: return .high
        case .lateralMovement: return .high
        case .dataCollection: return .critical
        }
    }
}

// MARK: - Behavior Detection Result
struct BehaviorDetectionResult {
    let detectedPhases: [BehaviorPhase]
    let confidence: Double
    let anomalyLevel: BehaviorAnomalyLevel
    let recommendedResponse: [BehaviorResponse]
    let detectionTime: Date
    let networkEvents: [NetworkEvent]
    let c2Analysis: C2DetectionResult
    
    var isActive: Bool {
        return !detectedPhases.isEmpty
    }
    
    var highestSeverity: BehaviorSeverity {
        return detectedPhases.map { $0.severity }.max() ?? .low
    }
}

// MARK: - Behavior Anomaly Level
enum BehaviorAnomalyLevel: CaseIterable {
    case none
    case low
    case medium
    case high
    case critical
    case unknown
    
    var description: String {
        switch self {
        case .none: return "無異常"
        case .low: return "低異常"
        case .medium: return "中等異常"
        case .high: return "高異常"
        case .critical: return "嚴重異常"
        case .unknown: return "未知異常"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "⚪"
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        case .unknown: return "⚫"
        }
    }
}

// MARK: - Behavior Severity
enum BehaviorSeverity: Comparable {
    case low
    case medium
    case high
    case critical
    
    static func < (lhs: BehaviorSeverity, rhs: BehaviorSeverity) -> Bool {
        let order: [BehaviorSeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Behavior Response
enum BehaviorResponse: CaseIterable {
    case enhancedMonitoring
    case networkSegmentation
    case isolateAffectedNodes
    case forensicAnalysis
    case credentialReset
    case systemHardening
    case networkIsolation
    case accessRestriction
    case dataLossDetectionSystem
    case emergencyContainment
    
    var description: String {
        switch self {
        case .enhancedMonitoring: return "增強監控"
        case .networkSegmentation: return "網路分段"
        case .isolateAffectedNodes: return "隔離受影響節點"
        case .forensicAnalysis: return "法醫分析"
        case .credentialReset: return "憑證重置"
        case .systemHardening: return "系統強化"
        case .networkIsolation: return "網路隔離"
        case .accessRestriction: return "訪問限制"
        case .dataLossDetectionSystem: return "數據異常檢測"
        case .emergencyContainment: return "緊急遏制"
        }
    }
    
    var priority: Int {
        switch self {
        case .emergencyContainment: return 1
        case .isolateAffectedNodes: return 2
        case .networkIsolation: return 3
        case .accessRestriction: return 4
        case .forensicAnalysis: return 5
        case .credentialReset: return 6
        case .systemHardening: return 7
        case .networkSegmentation: return 8
        case .dataLossDetectionSystem: return 9
        case .enhancedMonitoring: return 10
        }
    }
}

// MARK: - Network Event
struct NetworkEvent {
    let id: UUID = UUID()
    let timestamp: Date
    let type: NetworkEventType
    let sourceNodeID: String?
    let targetNodeID: String?
    let dataSize: Int
    let metadata: [String: Any]
    
    var isSuccessful: Bool {
        return metadata["success"] as? Bool ?? false
    }
    
    var duration: TimeInterval {
        return metadata["duration"] as? TimeInterval ?? 0
    }
}

// MARK: - Network Event Type
enum NetworkEventType: CaseIterable {
    case networkScan
    case serviceProbe
    case exploitAttempt
    case authenticationFailure
    case persistenceAttempt
    case privilegeEscalation
    case lateralMovement
    case credentialDumping
    case dataExfiltration
    case normalCommunication
    case fileTransfer
    case connectionEstablishment
    case connectionTermination
    
    var description: String {
        switch self {
        case .networkScan: return "網路掃描"
        case .serviceProbe: return "服務探測"
        case .exploitAttempt: return "漏洞利用嘗試"
        case .authenticationFailure: return "身份驗證失敗"
        case .persistenceAttempt: return "持久化嘗試"
        case .privilegeEscalation: return "權限提升"
        case .lateralMovement: return "橫向移動"
        case .credentialDumping: return "憑證轉儲"
        case .dataExfiltration: return "數據外洩"
        case .normalCommunication: return "正常通信"
        case .fileTransfer: return "文件傳輸"
        case .connectionEstablishment: return "連接建立"
        case .connectionTermination: return "連接終止"
        }
    }
    
    var suspiciousLevel: Double {
        switch self {
        case .networkScan: return 0.7
        case .serviceProbe: return 0.6
        case .exploitAttempt: return 0.9
        case .authenticationFailure: return 0.5
        case .persistenceAttempt: return 0.8
        case .privilegeEscalation: return 0.9
        case .lateralMovement: return 0.8
        case .credentialDumping: return 0.9
        case .dataExfiltration: return 0.95
        case .normalCommunication: return 0.1
        case .fileTransfer: return 0.3
        case .connectionEstablishment: return 0.2
        case .connectionTermination: return 0.1
        }
    }
}

// MARK: - Pattern Analysis Result
struct PatternAnalysisResult {
    let hasReconnaissanceIndicators: Bool
    let hasInitialCompromiseIndicators: Bool
    let hasFootholdIndicators: Bool
    let hasLateralMovementIndicators: Bool
    let hasExfiltrationIndicators: Bool
    let confidence: Double
    let indicators: [BehaviorIndicator]
}

// MARK: - Machine Learning Analysis Result
struct MLAnalysisResult {
    let reconnaissance: Bool
    let initialCompromise: Bool
    let foothold: Bool
    let lateralMovement: Bool
    let exfiltration: Bool
    let confidence: Double
    let indicators: [BehaviorIndicator]
}

// MARK: - Rule Analysis Result
struct RuleAnalysisResult {
    let reconnaissance: Bool
    let initialCompromise: Bool
    let foothold: Bool
    let lateralMovement: Bool
    let exfiltration: Bool
    let confidence: Double
    let indicators: [BehaviorIndicator]
}

// MARK: - Behavior Rule
struct BehaviorRule {
    let id: UUID = UUID()
    let name: String
    let condition: ([NetworkEvent]) -> Bool
    let severity: BehaviorSeverity
    let description: String
    
    init(name: String, condition: @escaping ([NetworkEvent]) -> Bool, severity: BehaviorSeverity = .medium, description: String = "") {
        self.name = name
        self.condition = condition
        self.severity = severity
        self.description = description.isEmpty ? name : description
    }
}

// MARK: - Behavior Indicator
struct BehaviorIndicator {
    let id: UUID = UUID()
    let type: BehaviorIndicatorType
    let description: String
    let severity: BehaviorSeverity
    let confidence: Double
    let timestamp: Date
    
    init(type: BehaviorIndicatorType, description: String, severity: BehaviorSeverity = .medium, confidence: Double = 0.5) {
        self.type = type
        self.description = description
        self.severity = severity
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - Behavior Indicator Type
enum BehaviorIndicatorType: CaseIterable {
    case behaviorPhase
    case ruleTriggered
    case anomalyDetected
    case networkPattern
    case behaviorPattern
    case dataPattern
    
    var description: String {
        switch self {
        case .behaviorPhase: return "行為階段"
        case .ruleTriggered: return "規則觸發"
        case .anomalyDetected: return "異常檢測"
        case .networkPattern: return "網路模式"
        case .behaviorPattern: return "行為模式"
        case .dataPattern: return "數據模式"
        }
    }
}

// MARK: - Anomaly Severity
enum AnomalySeverity: CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical
    
    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "嚴重"
        }
    }
    
    static func < (lhs: AnomalySeverity, rhs: AnomalySeverity) -> Bool {
        let order: [AnomalySeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Anomaly Level
enum AnomalyLevel: CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical
    
    var description: String {
        switch self {
        case .low: return "低異常"
        case .medium: return "中等異常"
        case .high: return "高異常"
        case .critical: return "嚴重異常"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
    
    static func < (lhs: AnomalyLevel, rhs: AnomalyLevel) -> Bool {
        let order: [AnomalyLevel] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Behavior Alert
struct BehaviorAlert {
    let id: UUID = UUID()
    let anomalyLevel: BehaviorAnomalyLevel
    let detectedPhases: [BehaviorPhase]
    let confidence: Double
    let timestamp: Date
    let affectedNodes: [String]
    var isResolved: Bool = false
    var resolvedTime: Date?
    
    var description: String {
        let phaseDescriptions = detectedPhases.map { $0.description }.joined(separator: ", ")
        return "檢測到行為異常 (等級: \(anomalyLevel.description)) - 階段: \(phaseDescriptions)"
    }
    
    var severity: BehaviorSeverity {
        return detectedPhases.map { $0.severity }.max() ?? .low
    }
}

// MARK: - Behavior Intelligence Report
struct BehaviorIntelligenceReport {
    let id: UUID = UUID()
    let indicators: [BehaviorIndicator]
    let reportDate: Date
    let anomalyLevel: AnomalyLevel
    let recommendations: [String]
    
    var indicatorsByType: [BehaviorIndicatorType: [BehaviorIndicator]] {
        return Dictionary(grouping: indicators, by: { $0.type })
    }
    
    var indicatorsBySeverity: [BehaviorSeverity: [BehaviorIndicator]] {
        return Dictionary(grouping: indicators, by: { $0.severity })
    }
    
    var highSeverityIndicators: [BehaviorIndicator] {
        return indicators.filter { $0.severity == .high || $0.severity == .critical }
    }
    
    var averageConfidence: Double {
        guard !indicators.isEmpty else { return 0 }
        return indicators.map { $0.confidence }.reduce(0, +) / Double(indicators.count)
    }
}

// MARK: - Behavior Detection Statistics
struct BehaviorDetectionStatistics {
    let totalDetections: Int
    let phaseBreakdown: [BehaviorPhase: Int]
    let anomalyLevelBreakdown: [BehaviorAnomalyLevel: Int]
    let averageConfidence: Double
    let detectionTrend: DetectionTrend
    
    var mostCommonPhase: BehaviorPhase? {
        return phaseBreakdown.max(by: { $0.value < $1.value })?.key
    }
    
    var mostCommonAnomalyLevel: BehaviorAnomalyLevel? {
        return anomalyLevelBreakdown.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Detection Trend
enum DetectionTrend {
    case increasing
    case decreasing
    case stable
    case unknown
    
    var description: String {
        switch self {
        case .increasing: return "遞增"
        case .decreasing: return "遞減"
        case .stable: return "穩定"
        case .unknown: return "未知"
        }
    }
    
    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "📊"
        case .unknown: return "❓"
        }
    }
}

// MARK: - Behavior Configuration
struct BehaviorConfiguration {
    // 檢測閾值
    static let detectionThreshold: Double = 0.7
    static let confidenceThreshold: Double = 0.6
    
    // 監控參數
    static let monitoringInterval: TimeInterval = 60.0 // 1分鐘
    static let eventHistoryDuration: TimeInterval = 24 * 3600 // 24小時
    
    // 回應參數
    static let automaticResponseEnabled: Bool = true
    static let emergencyResponseThreshold: Double = 0.9
    
    // 行為情報參數
    static let maxIndicators: Int = 1000
    static let indicatorExpirationTime: TimeInterval = 7 * 24 * 3600 // 7天
    
    // 告警參數
    static let alertCooldownPeriod: TimeInterval = 300 // 5分鐘
    static let maxAlertsPerHour: Int = 10
}

// MARK: - Behavior Metrics
struct BehaviorMetrics {
    let detectionRate: Double
    let falsePositiveRate: Double
    let averageResponseTime: TimeInterval
    let systemPerformanceImpact: Double
    let patternCoverage: Double
    
    var effectivenessScore: Double {
        // 綜合效能評分
        let detectionScore = detectionRate * 0.3
        let falsePositiveScore = (1 - falsePositiveRate) * 0.3
        let responseScore = (1 - min(averageResponseTime / 60, 1)) * 0.2
        let performanceScore = (1 - systemPerformanceImpact) * 0.1
        let coverageScore = patternCoverage * 0.1
        
        return detectionScore + falsePositiveScore + responseScore + performanceScore + coverageScore
    }
}

// MARK: - Behavior Dashboard Data
struct BehaviorDashboardData {
    let currentAnomalyLevel: BehaviorAnomalyLevel
    let activeDetections: [BehaviorDetectionResult]
    let recentAlerts: [BehaviorAlert]
    let statistics: BehaviorDetectionStatistics
    let metrics: BehaviorMetrics
    let intelligenceReport: BehaviorIntelligenceReport
    
    var requiresAttention: Bool {
        return currentAnomalyLevel == .high || currentAnomalyLevel == .critical
    }
    
    var activeAnomalies: Int {
        return activeDetections.filter { $0.isActive }.count
    }
    
    var unresolvedAlerts: Int {
        return recentAlerts.filter { !$0.isResolved }.count
    }
}