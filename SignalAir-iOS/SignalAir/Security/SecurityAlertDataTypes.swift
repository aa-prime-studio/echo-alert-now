import Foundation

// MARK: - Security Alert Data Types

// MARK: - Security Alert
struct SecurityAlert {
    let id: UUID
    let level: SecurityAlertLevel
    let source: String
    let type: SecurityAlertType
    let reason: String
    let timestamp: Date
    var isResolved: Bool
    var resolvedTime: Date?
    let metadata: [String: Any]?
    
    init(id: UUID, level: SecurityAlertLevel, source: String, type: SecurityAlertType, reason: String, timestamp: Date, isResolved: Bool, metadata: [String: Any]? = nil) {
        self.id = id
        self.level = level
        self.source = source
        self.type = type
        self.reason = reason
        self.timestamp = timestamp
        self.isResolved = isResolved
        self.metadata = metadata
    }
    
    var duration: TimeInterval? {
        guard let resolvedTime = resolvedTime else { return nil }
        return resolvedTime.timeIntervalSince(timestamp)
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Security Alert Level
enum SecurityAlertLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var severity: AlertSeverity {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .critical: return .critical
        }
    }
    
    var numericValue: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
    
    var description: String {
        switch self {
        case .low: return "低級"
        case .medium: return "中級"
        case .high: return "高級"
        case .critical: return "嚴重"
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
}

// MARK: - Security Alert Type
enum SecurityAlertType: String, CaseIterable {
    case trustAnomaly = "trust_anomaly"
    case nodeAnomaly = "node_anomaly"
    case behaviorAnomaly = "apt_threat"
    case connectionLimit = "connection_limit"
    case authenticationFailure = "authentication_failure"
    case dataExfiltration = "data_exfiltration"
    case systemCompromise = "system_compromise"
    case malwareDetection = "malware_detection"
    
    var description: String {
        switch self {
        case .trustAnomaly: return "信任異常"
        case .nodeAnomaly: return "節點異常"
        case .behaviorAnomaly: return "行為異常"
        case .connectionLimit: return "連接限制"
        case .authenticationFailure: return "認證失敗"
        case .dataExfiltration: return "數據外洩"
        case .systemCompromise: return "系統入侵"
        case .malwareDetection: return "惡意軟體檢測"
        }
    }
    
    var impactMultiplier: Double {
        switch self {
        case .trustAnomaly: return 0.6
        case .nodeAnomaly: return 0.7
        case .behaviorAnomaly: return 1.0
        case .connectionLimit: return 0.4
        case .authenticationFailure: return 0.5
        case .dataExfiltration: return 0.9
        case .systemCompromise: return 1.0
        case .malwareDetection: return 0.8
        }
    }
    
    var operationalImpactMultiplier: Double {
        switch self {
        case .trustAnomaly: return 0.5
        case .nodeAnomaly: return 0.6
        case .behaviorAnomaly: return 0.9
        case .connectionLimit: return 0.3
        case .authenticationFailure: return 0.4
        case .dataExfiltration: return 0.7
        case .systemCompromise: return 0.8
        case .malwareDetection: return 0.6
        }
    }
    
    var reputationalImpactMultiplier: Double {
        switch self {
        case .trustAnomaly: return 0.3
        case .nodeAnomaly: return 0.4
        case .behaviorAnomaly: return 0.8
        case .connectionLimit: return 0.2
        case .authenticationFailure: return 0.3
        case .dataExfiltration: return 0.9
        case .systemCompromise: return 0.7
        case .malwareDetection: return 0.5
        }
    }
}

// MARK: - Alert Classification
struct AlertClassification {
    let category: AlertCategory
    let priority: AlertPriority
    let severity: AlertSeverity
    let urgency: AlertUrgency
    let source: String
    let tags: [String]
}

// MARK: - Alert Category
enum AlertCategory: String, CaseIterable {
    case trustSecurity = "trust_security"
    case networkSecurity = "network_security"
    case advancedThreat = "advanced_threat"
    case accessSecurity = "access_security"
    case dataSecurity = "data_security"
    case systemSecurity = "system_security"
    case malwareSecurity = "malware_security"
    
    var description: String {
        switch self {
        case .trustSecurity: return "信任安全"
        case .networkSecurity: return "網路安全"
        case .advancedThreat: return "高級威脅"
        case .accessSecurity: return "訪問安全"
        case .dataSecurity: return "數據安全"
        case .systemSecurity: return "系統安全"
        case .malwareSecurity: return "惡意軟體安全"
        }
    }
}

// MARK: - Alert Priority
enum AlertPriority: String, CaseIterable, Comparable {
    case informational = "informational"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .informational: return "資訊"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "嚴重"
        }
    }
    
    var numericValue: Double {
        switch self {
        case .informational: return 0.1
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .critical: return 1.0
        }
    }
    
    static func < (lhs: AlertPriority, rhs: AlertPriority) -> Bool {
        return lhs.numericValue < rhs.numericValue
    }
}

// MARK: - Alert Severity
enum AlertSeverity: String, CaseIterable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "嚴重"
        }
    }
    
    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        let order: [AlertSeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Alert Urgency
enum AlertUrgency: String, CaseIterable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case immediate = "immediate"
    
    var description: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .immediate: return "立即"
        }
    }
    
    var numericValue: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .immediate: return 1.0
        }
    }
    
    static func < (lhs: AlertUrgency, rhs: AlertUrgency) -> Bool {
        return lhs.numericValue < rhs.numericValue
    }
}

// MARK: - Classified Alert
struct ClassifiedAlert {
    let originalAlert: SecurityAlert
    let classification: AlertClassification
    let correlatedAlerts: [SecurityAlert]
    let recommendedActions: [String]
    let estimatedImpact: ImpactEstimate
    
    var id: UUID {
        return originalAlert.id
    }
    
    var isHighImpact: Bool {
        return estimatedImpact.overall > 0.7
    }
    
    var requiresImmediateAction: Bool {
        return classification.urgency == .immediate || classification.priority == .critical
    }
}

// MARK: - Impact Estimate
struct ImpactEstimate {
    let financial: Double
    let operational: Double
    let reputational: Double
    let overall: Double
    
    var level: ImpactLevel {
        switch overall {
        case 0.8...1.0: return .critical
        case 0.6..<0.8: return .high
        case 0.4..<0.6: return .medium
        case 0.2..<0.4: return .low
        default: return .minimal
        }
    }
}

// MARK: - Impact Level
enum ImpactLevel: String, CaseIterable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .minimal: return "最小"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "嚴重"
        }
    }
    
    var color: String {
        switch self {
        case .minimal: return "⚪"
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}

// MARK: - Response Strategy
struct ResponseStrategy {
    let actions: [ResponseAction]
    let timeline: ResponseTimeline
    let escalationPath: EscalationPath
    let requiredApprovals: [String]
    
    var estimatedDuration: TimeInterval {
        return timeline.long
    }
    
    var isAutomated: Bool {
        return requiredApprovals.isEmpty
    }
}

// MARK: - Response Action
enum ResponseAction: String, CaseIterable {
    case immediateIsolation = "immediate_isolation"
    case emergencyNotification = "emergency_notification"
    case forensicInvestigation = "forensic_investigation"
    case enhancedMonitoring = "enhanced_monitoring"
    case accessRestriction = "access_restriction"
    case notifySecurityTeam = "notify_security_team"
    case increaseObservation = "increase_observation"
    case logForReview = "log_for_review"
    case standardResponse = "standard_response"
    
    var description: String {
        switch self {
        case .immediateIsolation: return "立即隔離"
        case .emergencyNotification: return "緊急通知"
        case .forensicInvestigation: return "法醫調查"
        case .enhancedMonitoring: return "增強監控"
        case .accessRestriction: return "訪問限制"
        case .notifySecurityTeam: return "通知安全團隊"
        case .increaseObservation: return "增加觀察"
        case .logForReview: return "記錄審查"
        case .standardResponse: return "標準回應"
        }
    }
    
    var estimatedDuration: TimeInterval {
        switch self {
        case .immediateIsolation: return 60
        case .emergencyNotification: return 120
        case .forensicInvestigation: return 3600
        case .enhancedMonitoring: return 1800
        case .accessRestriction: return 300
        case .notifySecurityTeam: return 600
        case .increaseObservation: return 900
        case .logForReview: return 60
        case .standardResponse: return 300
        }
    }
}

// MARK: - Response Timeline
struct ResponseTimeline {
    let immediate: TimeInterval
    let short: TimeInterval
    let medium: TimeInterval
    let long: TimeInterval
    
    var description: String {
        return "立即: \(immediate)s, 短期: \(short)s, 中期: \(medium)s, 長期: \(long)s"
    }
}

// MARK: - Escalation Path
struct EscalationPath {
    let levels: [String]
    
    var description: String {
        return levels.joined(separator: " → ")
    }
    
    var escalationCount: Int {
        return levels.count
    }
}

// MARK: - Alert Filter
protocol AlertFilter {
    func shouldFilter(_ alert: SecurityAlert) -> Bool
}

// MARK: - Duplicate Alert Filter
struct DuplicateAlertFilter: AlertFilter {
    let timeWindow: TimeInterval
    
    func shouldFilter(_ alert: SecurityAlert) -> Bool {
        // 實際實現會檢查重複告警
        return false
    }
}

// MARK: - Severity Filter
struct SeverityFilter: AlertFilter {
    let minimumLevel: SecurityAlertLevel
    
    func shouldFilter(_ alert: SecurityAlert) -> Bool {
        return alert.level.numericValue < minimumLevel.numericValue
    }
}

// MARK: - Rate Limit Filter
struct RateLimitFilter: AlertFilter {
    let maxAlertsPerMinute: Int
    private var alertCounts: [String: Int] = [:]
    
    func shouldFilter(_ alert: SecurityAlert) -> Bool {
        // 實際實現會檢查速率限制
        return false
    }
}

// MARK: - Alert Subscriber
protocol AlertSubscriber {
    var id: UUID { get }
    func isInterestedIn(_ alert: ClassifiedAlert) -> Bool
    func receiveAlert(_ alert: ClassifiedAlert)
}

// MARK: - Alert Configuration
struct AlertConfiguration {
    let activeAlertExpiration: TimeInterval = 24 * 3600 // 24小時
    let highAlertThreshold: Int = 100
    let emergencyContacts: [String] = ["security@company.com", "admin@company.com"]
    let enableAutoResponse: Bool = true
    let maxAlertHistorySize: Int = 10000
    let alertProcessingInterval: TimeInterval = 60.0
    
    var isValid: Bool {
        return activeAlertExpiration > 0 && highAlertThreshold > 0 && !emergencyContacts.isEmpty
    }
}

// MARK: - Alert Statistics
struct AlertStatistics {
    let activeAlerts: Int
    let resolvedAlerts: Int
    let averageResolutionTime: TimeInterval
    let alertsByType: [SecurityAlertType: Int]
    
    var totalAlerts: Int {
        return activeAlerts + resolvedAlerts
    }
    
    var resolutionRate: Double {
        guard totalAlerts > 0 else { return 0 }
        return Double(resolvedAlerts) / Double(totalAlerts)
    }
    
    var mostCommonAlertType: SecurityAlertType? {
        return alertsByType.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Emergency Notification
struct EmergencyNotification {
    let alert: ClassifiedAlert
    let recipients: [String]
    let priority: AlertPriority
    let timestamp: Date = Date()
    
    var subject: String {
        return "URGENT: \(alert.classification.category.description) - \(alert.originalAlert.reason)"
    }
    
    var body: String {
        return """
        緊急安全告警
        
        告警等級: \(alert.classification.priority.description)
        告警類型: \(alert.originalAlert.type.description)
        告警來源: \(alert.originalAlert.source)
        告警原因: \(alert.originalAlert.reason)
        檢測時間: \(alert.originalAlert.timestamp)
        
        建議行動:
        \(alert.recommendedActions.joined(separator: "\n"))
        
        影響評估:
        - 整體影響: \(alert.estimatedImpact.overall)
        - 營運影響: \(alert.estimatedImpact.operational)
        - 聲譽影響: \(alert.estimatedImpact.reputational)
        
        請立即採取行動！
        """
    }
}

// MARK: - Forensic Investigation
struct ForensicInvestigation {
    let id: UUID = UUID()
    let alertID: UUID
    let investigationType: InvestigationType
    let priority: AlertPriority
    let estimatedDuration: TimeInterval
    let startTime: Date = Date()
    var status: InvestigationStatus = .pending
    
    enum InvestigationType {
        case securityIncident
        case dataBreach
        case malwareInfection
        case systemCompromise
        case networkIntrusion
        
        var description: String {
            switch self {
            case .securityIncident: return "安全事件"
            case .dataBreach: return "數據洩露"
            case .malwareInfection: return "惡意軟體感染"
            case .systemCompromise: return "系統入侵"
            case .networkIntrusion: return "網路入侵"
            }
        }
    }
    
    enum InvestigationStatus {
        case pending
        case inProgress
        case completed
        case cancelled
        
        var description: String {
            switch self {
            case .pending: return "待處理"
            case .inProgress: return "進行中"
            case .completed: return "已完成"
            case .cancelled: return "已取消"
            }
        }
    }
}

// MARK: - Security Team Notification
struct SecurityTeamNotification {
    let alert: ClassifiedAlert
    let priority: AlertPriority
    let requiresResponse: Bool
    let timestamp: Date = Date()
    
    var message: String {
        return """
        安全告警通知
        
        優先級: \(priority.description)
        類型: \(alert.originalAlert.type.description)
        來源: \(alert.originalAlert.source)
        原因: \(alert.originalAlert.reason)
        
        需要回應: \(requiresResponse ? "是" : "否")
        
        建議行動:
        \(alert.recommendedActions.joined(separator: "\n"))
        """
    }
}

// MARK: - Review Item
struct ReviewItem {
    let id: UUID = UUID()
    let alert: ClassifiedAlert
    let priority: AlertPriority
    let assignedTo: String
    let dueDate: Date
    let createdDate: Date = Date()
    var status: ReviewStatus = .pending
    
    enum ReviewStatus {
        case pending
        case inReview
        case completed
        case escalated
        
        var description: String {
            switch self {
            case .pending: return "待審查"
            case .inReview: return "審查中"
            case .completed: return "已完成"
            case .escalated: return "已升級"
            }
        }
    }
    
    var isOverdue: Bool {
        return Date() > dueDate && status != .completed
    }
}

// MARK: - Threshold Exceeded Notification
struct ThresholdExceededNotification {
    let type: ThresholdType
    let currentValue: Int
    let threshold: Int
    let timestamp: Date
    
    enum ThresholdType {
        case highAlertCount
        case criticalAlertCount
        case resolutionTimeExceeded
        case errorRateExceeded
        
        var description: String {
            switch self {
            case .highAlertCount: return "高告警數量"
            case .criticalAlertCount: return "嚴重告警數量"
            case .resolutionTimeExceeded: return "解決時間超標"
            case .errorRateExceeded: return "錯誤率超標"
            }
        }
    }
    
    var message: String {
        return "\(type.description)已超過閾值：當前值 \(currentValue)，閾值 \(threshold)"
    }
}

// MARK: - Log Level
enum LogLevel {
    case critical
    case high
    case medium
    case low
    
    var description: String {
        switch self {
        case .critical: return "嚴重"
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
}