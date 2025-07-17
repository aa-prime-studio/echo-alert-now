import Foundation

// MARK: - Node Activity and Behavior Data Types

// MARK: - Node Activity
struct NodeActivity {
    let nodeID: String
    let timestamp: Date
    let connectionPattern: ConnectionPattern
    let dataTransfer: DataTransferPattern
    let timing: TimingPattern
    let topologyBehavior: TopologyBehavior
    let metadata: [String: Any]
    
    var anomalyScore: Double = 0.0
    var isProcessed: Bool = false
}

// MARK: - Connection Pattern
struct ConnectionPattern {
    let connectionsPerMinute: Double
    let averageConnectionDuration: TimeInterval
    let simultaneousConnections: Double
    let successRate: Double
    
    static let `default` = ConnectionPattern(
        connectionsPerMinute: 1.0,
        averageConnectionDuration: 60.0,
        simultaneousConnections: 3.0,
        successRate: 0.9
    )
}

// MARK: - Data Transfer Pattern
struct DataTransferPattern {
    let bytesPerSecond: Double
    let averagePacketSize: Double
    let transferFrequency: Double
    let primaryDataType: String
    let commonDataTypes: [String]
    
    static let `default` = DataTransferPattern(
        bytesPerSecond: 1024.0,
        averagePacketSize: 512.0,
        transferFrequency: 10.0,
        primaryDataType: "text",
        commonDataTypes: ["text", "image", "file"]
    )
}

// MARK: - Timing Pattern
struct TimingPattern {
    let activeHours: [Int]
    let averageResponseTime: TimeInterval
    let activityInterval: TimeInterval
    let activityLevel: Double
    
    static let `default` = TimingPattern(
        activeHours: [9, 10, 11, 14, 15, 16, 19, 20, 21],
        averageResponseTime: 1.0,
        activityInterval: 300.0,
        activityLevel: 0.5
    )
}

// MARK: - Topology Behavior
struct TopologyBehavior {
    let neighborCount: Double
    let routeHopCount: Double
    let networkDistance: Double
    let topologyChangeFrequency: Double
    
    static let `default` = TopologyBehavior(
        neighborCount: 5.0,
        routeHopCount: 3.0,
        networkDistance: 2.0,
        topologyChangeFrequency: 0.1
    )
}

// MARK: - Node Behavior Profile
struct NodeBehaviorProfile {
    let nodeID: String
    var normalConnectionPattern: ConnectionPattern
    var normalDataTransfer: DataTransferPattern
    var normalTiming: TimingPattern
    var normalTopology: TopologyBehavior
    let establishedDate: Date
    var lastUpdated: Date
    
    var isValid: Bool {
        let daysSinceEstablished = Date().timeIntervalSince(establishedDate) / (24 * 3600)
        return daysSinceEstablished < 7 // 7天內的檔案有效
    }
}

// MARK: - Alert System
struct NodeAnomalyAlert {
    let id: UUID = UUID()
    let nodeID: String
    let activity: NodeActivity
    let anomalyScore: Double
    let timestamp: Date
    let severity: AlertSeverity
    var isResolved: Bool = false
    var resolvedTime: Date?
    
    var description: String {
        return "節點 \(nodeID) 檢測到異常行為，異常評分: \(String(format: "%.2f", anomalyScore))"
    }
}

enum AlertSeverity {
    case low
    case medium
    case high
    case critical
    
    var color: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}

// MARK: - Automatic Response System
struct AutomaticResponse {
    let id: UUID = UUID()
    let nodeID: String
    let responseType: ResponseType
    let activity: NodeActivity
    let timestamp: Date
    var isExecuted: Bool = false
    var executedTime: Date?
}

enum ResponseType {
    case logActivity
    case enhancedMonitoring
    case restrictAccess
    case isolateNode
    
    var description: String {
        switch self {
        case .logActivity: return "記錄活動"
        case .enhancedMonitoring: return "增強監控"
        case .restrictAccess: return "限制訪問"
        case .isolateNode: return "隔離節點"
        }
    }
}

// MARK: - Access Restriction
struct AccessRestriction {
    let id: UUID = UUID()
    let nodeID: String
    let restrictionType: RestrictionType
    let duration: TimeInterval
    let reason: String
    let startTime: Date = Date()
    var isActive: Bool = true
    
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
    
    var isExpired: Bool {
        return Date() > endTime
    }
}

enum RestrictionType {
    case limitedAccess
    case readOnly
    case suspended
    case blocked
    
    var description: String {
        switch self {
        case .limitedAccess: return "限制訪問"
        case .readOnly: return "只讀模式"
        case .suspended: return "暫停服務"
        case .blocked: return "完全封鎖"
        }
    }
}

// MARK: - Enhanced Monitoring Configuration
struct EnhancedMonitoringConfig {
    let nodeID: String
    let monitoringInterval: TimeInterval
    let duration: TimeInterval
    let alertThreshold: Double
    let startTime: Date = Date()
    
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
    
    var isActive: Bool {
        return Date() < endTime
    }
}

// MARK: - Activity Log Entry
struct ActivityLogEntry {
    let id: UUID = UUID()
    let nodeID: String
    let activity: NodeActivity
    let timestamp: Date
    let flagged: Bool
    let reason: String
    var reviewed: Bool = false
    var reviewedBy: String?
    var reviewedTime: Date?
}

// MARK: - Node Anomaly Report
struct NodeAnomalyReport {
    let nodeID: String
    let totalActivities: Int
    let anomalousActivities: Int
    let alerts: [NodeAnomalyAlert]
    let averageAnomalyScore: Double
    let riskLevel: RiskLevel
    let profile: NodeBehaviorProfile
    let recommendations: [String]
    let generatedTime: Date = Date()
    
    var anomalyRate: Double {
        guard totalActivities > 0 else { return 0 }
        return Double(anomalousActivities) / Double(totalActivities)
    }
    
    var alertCount: Int {
        return alerts.count
    }
    
    var criticalAlertCount: Int {
        return alerts.filter { $0.severity == .critical }.count
    }
}

// MARK: - Node Isolation Notification
struct NodeIsolationNotification {
    let nodeID: String
    let reason: String
    let timestamp: Date = Date()
    let isolatedBy: String = "NodeAnomalyTracker"
}

// MARK: - Node Monitor Protocol
protocol NodeMonitorProtocol {
    func isolateNode(_ nodeID: String)
    func restrictAccess(_ nodeID: String)
    func enableEnhancedMonitoring(_ nodeID: String)
    func applyMonitoringConfig(_ config: EnhancedMonitoringConfig)
    func getNodeStatus(_ nodeID: String) -> NodeStatus
}

// MARK: - Node Monitor Implementation
class NodeMonitor: NodeMonitorProtocol {
    private var isolatedNodes: Set<String> = []
    private var restrictedNodes: [String: AccessRestriction] = [:]
    private var enhancedMonitoringNodes: [String: EnhancedMonitoringConfig] = [:]
    private let queue = DispatchQueue(label: "com.signalair.nodemonitor", qos: .utility)
    
    func isolateNode(_ nodeID: String) {
        queue.sync {
            isolatedNodes.insert(nodeID)
            print("🔒 節點 \(nodeID) 已被隔離")
        }
    }
    
    func restrictAccess(_ nodeID: String) {
        queue.sync {
            let restriction = AccessRestriction(
                nodeID: nodeID,
                restrictionType: .limitedAccess,
                duration: 3600,
                reason: "異常行為檢測"
            )
            restrictedNodes[nodeID] = restriction
            print("⚠️ 節點 \(nodeID) 訪問已被限制")
        }
    }
    
    func enableEnhancedMonitoring(_ nodeID: String) {
        queue.sync {
            let config = EnhancedMonitoringConfig(
                nodeID: nodeID,
                monitoringInterval: 1.0,
                duration: 1800,
                alertThreshold: 0.5
            )
            enhancedMonitoringNodes[nodeID] = config
            print("🔍 節點 \(nodeID) 啟用增強監控")
        }
    }
    
    func applyMonitoringConfig(_ config: EnhancedMonitoringConfig) {
        queue.sync {
            enhancedMonitoringNodes[config.nodeID] = config
        }
    }
    
    func getNodeStatus(_ nodeID: String) -> NodeStatus {
        return queue.sync {
            if isolatedNodes.contains(nodeID) {
                return .isolated
            } else if let restriction = restrictedNodes[nodeID], restriction.isActive {
                return .restricted(restriction)
            } else if let config = enhancedMonitoringNodes[nodeID], config.isActive {
                return .enhancedMonitoring(config)
            } else {
                return .normal
            }
        }
    }
}

// MARK: - Node Status
enum NodeStatus {
    case normal
    case enhancedMonitoring(EnhancedMonitoringConfig)
    case restricted(AccessRestriction)
    case isolated
    
    var description: String {
        switch self {
        case .normal: return "正常"
        case .enhancedMonitoring: return "增強監控"
        case .restricted: return "受限制"
        case .isolated: return "已隔離"
        }
    }
}

// MARK: - Alert System
class AlertSystem {
    private var alerts: [NodeAnomalyAlert] = []
    private let queue = DispatchQueue(label: "com.signalair.alertsystem", qos: .utility)
    
    func sendAlert(_ alert: NodeAnomalyAlert) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.alerts.append(alert)
            
            // 發送通知
            NotificationCenter.default.post(
                name: .nodeAnomalyDetected,
                object: alert
            )
            
            // 根據嚴重程度決定處理方式
            switch alert.severity {
            case .critical:
                self.handleCriticalAlert(alert)
            case .high:
                self.handleHighAlert(alert)
            case .medium:
                self.handleMediumAlert(alert)
            case .low:
                self.handleLowAlert(alert)
            }
        }
    }
    
    private func handleCriticalAlert(_ alert: NodeAnomalyAlert) {
        print("🚨 嚴重告警: \(alert.description)")
        // 立即處理邏輯
    }
    
    private func handleHighAlert(_ alert: NodeAnomalyAlert) {
        print("⚠️ 高級告警: \(alert.description)")
        // 高優先級處理邏輯
    }
    
    private func handleMediumAlert(_ alert: NodeAnomalyAlert) {
        print("🟡 中級告警: \(alert.description)")
        // 標準處理邏輯
    }
    
    private func handleLowAlert(_ alert: NodeAnomalyAlert) {
        print("🟢 低級告警: \(alert.description)")
        // 記錄處理邏輯
    }
    
    func getRecentAlerts(limit: Int = 50) -> [NodeAnomalyAlert] {
        return queue.sync {
            Array(alerts.suffix(limit))
        }
    }
}

// MARK: - Behavior Database
class BehaviorDatabase {
    private var profiles: [String: NodeBehaviorProfile] = [:]
    private var activities: [String: [NodeActivity]] = [:]
    private var alerts: [String: [NodeAnomalyAlert]] = [:]
    private var restrictions: [String: [AccessRestriction]] = [:]
    private var logEntries: [String: [ActivityLogEntry]] = [:]
    private let queue = DispatchQueue(label: "com.signalair.behaviordatabase", qos: .utility)
    
    func getProfile(_ nodeID: String) -> NodeBehaviorProfile? {
        return queue.sync { profiles[nodeID] }
    }
    
    func saveProfile(_ nodeID: String, _ profile: NodeBehaviorProfile) {
        queue.sync { profiles[nodeID] = profile }
    }
    
    func recordActivity(_ nodeID: String, _ activity: NodeActivity, _ anomalyScore: Double) {
        queue.sync {
            var activityWithScore = activity
            activityWithScore.anomalyScore = anomalyScore
            activityWithScore.isProcessed = true
            
            activities[nodeID, default: []].append(activityWithScore)
            
            // 保持最近1000條記錄
            if activities[nodeID]!.count > 1000 {
                activities[nodeID]! = Array(activities[nodeID]!.suffix(1000))
            }
        }
    }
    
    func recordAlert(_ nodeID: String, _ alert: NodeAnomalyAlert) {
        queue.sync {
            alerts[nodeID, default: []].append(alert)
            
            // 保持最近100條告警
            if alerts[nodeID]!.count > 100 {
                alerts[nodeID]! = Array(alerts[nodeID]!.suffix(100))
            }
        }
    }
    
    func recordRestriction(_ nodeID: String, _ restriction: AccessRestriction) {
        queue.sync {
            restrictions[nodeID, default: []].append(restriction)
        }
    }
    
    func recordLogEntry(_ nodeID: String, _ entry: ActivityLogEntry) {
        queue.sync {
            logEntries[nodeID, default: []].append(entry)
            
            // 保持最近500條日志
            if logEntries[nodeID]!.count > 500 {
                logEntries[nodeID]! = Array(logEntries[nodeID]!.suffix(500))
            }
        }
    }
    
    func getRecentActivities(_ nodeID: String, limit: Int) -> [NodeActivity] {
        return queue.sync {
            Array((activities[nodeID] ?? []).suffix(limit))
        }
    }
    
    func getRecentAlerts(_ nodeID: String, limit: Int) -> [NodeAnomalyAlert] {
        return queue.sync {
            Array((alerts[nodeID] ?? []).suffix(limit))
        }
    }
    
    func getRecentRestrictions(_ nodeID: String, limit: Int) -> [AccessRestriction] {
        return queue.sync {
            Array((restrictions[nodeID] ?? []).suffix(limit))
        }
    }
    
    func getRecentLogEntries(_ nodeID: String, limit: Int) -> [ActivityLogEntry] {
        return queue.sync {
            Array((logEntries[nodeID] ?? []).suffix(limit))
        }
    }
}