import Foundation

// MARK: - Core Data Types for Trust Behavior Model

// MARK: - Trust Baseline
struct TrustBaseline {
    let userID: String
    let normalTrustRange: ClosedRange<Double>
    let behaviorPatterns: BehaviorPatterns
    let interactionFrequency: InteractionFrequency
    let trustFluctuationPattern: TrustFluctuationPattern
    let establishedDate: Date
    
    var isValid: Bool {
        let daysSinceEstablished = Date().timeIntervalSince(establishedDate) / (24 * 3600)
        return daysSinceEstablished < 30 // 30天內的基線有效
    }
}

// MARK: - Behavior Patterns
struct BehaviorPatterns {
    let connectionFrequency: ConnectionFrequencyAnalysis
    let messageFrequency: MessageFrequencyAnalysis
    let interactionTiming: InteractionTimingAnalysis
    let contentPatterns: ContentPatternAnalysis
}

struct ConnectionFrequencyAnalysis {
    let average: Double
    let peak: Double
    let variance: Double
}

struct MessageFrequencyAnalysis {
    let messagesPerHour: Double
    let averageLength: Double
    let contentVariety: Double
}

struct InteractionTimingAnalysis {
    let averageResponseDelay: TimeInterval
    let typicalActiveHours: [Int]
    let sessionDuration: TimeInterval
}

struct ContentPatternAnalysis {
    let typicalContentTypes: [String]
    let averageContentSize: Double
    let contentVariety: Double
}

// MARK: - Interaction Frequency
struct InteractionFrequency {
    let dailyAverage: Double
    let peakHours: [Int]
    let averageSessionLength: TimeInterval
    let activityDistribution: ActivityDistribution
}

struct ActivityDistribution {
    let messageRatio: Double
    let connectionRatio: Double
    let discoveryRatio: Double
}

// MARK: - Trust Fluctuation Pattern
struct TrustFluctuationPattern {
    let averageFluctuation: Double
    let maxFluctuation: Double
    let fluctuationTrend: FluctuationTrend
    let stabilityScore: Double
}

enum FluctuationTrend {
    case increasing
    case decreasing
    case stable
}

// MARK: - User Activity
struct UserActivity {
    let userID: String
    let timestamp: Date
    let type: ActivityType
    let connectionPattern: ConnectionPattern?
    let messagePattern: MessagePattern?
    let interactionPattern: InteractionPattern?
    let contentType: String?
    let contentSize: Double?
    let isSuccessful: Bool
    let intensity: Double
    let metadata: [String: Any]
}

enum ActivityType {
    case message
    case connection
    case discovery
    case system
}

struct ConnectionPattern {
    let connectionsPerHour: Double
    let connectionDuration: TimeInterval
    let connectionSuccess: Bool
    let peerCount: Int
}

struct MessagePattern {
    let messagesPerHour: Double
    let averageMessageLength: Double
    let contentTypes: [String]
    let recipientCount: Int
}

struct InteractionPattern {
    let responseDelay: TimeInterval
    let activeHour: Int
    let sessionDuration: TimeInterval
    let interactionType: String
}

// MARK: - Anomaly Detection Results
struct TrustAnomalyResult {
    let isAnomalous: Bool
    let trustScore: Double
    let anomalyType: AnomalyType
    let confidenceLevel: Double
    let recommendedAction: RecommendedAction
    let detectionTime: Date
}

enum AnomalyType {
    case noAnomaly
    case trustScoreAnomaly
    case behaviorPatternAnomaly
    case timingAnomaly
    case combinedAnomaly
}

enum RecommendedAction {
    case continueNormalMonitoring
    case increaseObservation
    case enhancedMonitoring
    case immediateInvestigation
}

struct BehaviorAnomalyResult {
    let isAnomalous: Bool
    let anomalyScore: Double
    let anomalyReasons: [String]
}

// MARK: - Statistical Anomaly
struct StatisticalAnomaly {
    let index: Int
    let value: Double
    let zScore: Double
    let severity: AnomalySeverity
}

enum AnomalySeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Security Alert
struct SecurityAlert {
    let id: UUID
    let level: SecurityAlertLevel
    let source: String
    let reason: String
    let timestamp: Date
    let isResolved: Bool
    let metadata: [String: Any]
}

enum SecurityAlertLevel {
    case low
    case medium
    case high
    case critical
}

// MARK: - Connection Statistics
class ConnectionStats {
    var totalConnections: Int = 0
    var successfulConnections: Int = 0
    var failedConnections: Int = 0
    var lastConnectionTime: Date?
    var averageConnectionDuration: TimeInterval = 0
    var suspiciousActivityCount: Int = 0
    
    var successRate: Double {
        guard totalConnections > 0 else { return 0 }
        return Double(successfulConnections) / Double(totalConnections)
    }
    
    var failureRate: Double {
        guard totalConnections > 0 else { return 0 }
        return Double(failedConnections) / Double(totalConnections)
    }
    
    var riskScore: Double {
        var score = 0.0
        
        // 基於失敗率的風險評分
        score += failureRate * 40
        
        // 基於可疑活動的風險評分
        if suspiciousActivityCount > 0 {
            score += Double(suspiciousActivityCount) * 10
        }
        
        // 基於連接頻率的風險評分
        if totalConnections > 100 {
            score += 20
        }
        
        return min(100, score)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let securityAlert = Notification.Name("SecurityAlert")
    static let trustAnomalyDetected = Notification.Name("TrustAnomalyDetected")
    static let behaviorAnomalyDetected = Notification.Name("BehaviorAnomalyDetected")
}

// MARK: - Trust Behavior Configuration
struct TrustBehaviorConfig {
    // 異常檢測閾值
    static let anomalyThreshold: Double = 0.5
    static let criticalAnomalyThreshold: Double = 0.8
    
    // 信任評分範圍
    static let minTrustScore: Double = 0.0
    static let maxTrustScore: Double = 100.0
    static let defaultTrustScore: Double = 50.0
    
    // 行為基線有效期
    static let baselineValidityDays: Int = 30
    
    // 統計異常檢測參數
    static let statisticalAnomalyZScoreThreshold: Double = 2.0
    static let criticalStatisticalAnomalyZScoreThreshold: Double = 3.0
    
    // 監控參數
    static let maxStoredActivities: Int = 1000
    static let baselineActivityMinimum: Int = 10
    
    // 告警參數
    static let alertCooldownPeriod: TimeInterval = 300 // 5分鐘
    static let maxAlertsPerUser: Int = 10
}

// MARK: - Trust Behavior Metrics
struct TrustBehaviorMetrics {
    let userID: String
    let totalActivities: Int
    let anomaliesDetected: Int
    let averageTrustScore: Double
    let trustScoreVariance: Double
    let lastActivityTime: Date
    let riskLevel: RiskLevel
    let behaviorStability: Double
    
    var anomalyRate: Double {
        guard totalActivities > 0 else { return 0 }
        return Double(anomaliesDetected) / Double(totalActivities)
    }
    
    var trustScoreHealth: TrustScoreHealth {
        switch averageTrustScore {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .average
        case 20..<40:
            return .poor
        default:
            return .critical
        }
    }
}

enum RiskLevel {
    case low
    case medium
    case high
    case critical
    
    var numericValue: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
}

enum TrustScoreHealth {
    case excellent
    case good
    case average
    case poor
    case critical
}

// MARK: - Real-time Monitoring
class TrustBehaviorMonitor {
    private var activeMonitoringSessions: [String: MonitoringSession] = [:]
    private let queue = DispatchQueue(label: "com.signalair.trustmonitor", qos: .utility)
    
    func startMonitoring(for userID: String) {
        queue.sync {
            activeMonitoringSessions[userID] = MonitoringSession(
                userID: userID,
                startTime: Date(),
                activityCount: 0,
                anomalyCount: 0
            )
        }
    }
    
    func stopMonitoring(for userID: String) {
        queue.sync {
            activeMonitoringSessions[userID] = nil
        }
    }
    
    func isMonitoring(_ userID: String) -> Bool {
        return queue.sync { activeMonitoringSessions[userID] != nil }
    }
    
    func updateSession(for userID: String, activity: UserActivity, isAnomaly: Bool) {
        queue.sync {
            if var session = activeMonitoringSessions[userID] {
                session.activityCount += 1
                if isAnomaly {
                    session.anomalyCount += 1
                }
                session.lastActivityTime = Date()
                activeMonitoringSessions[userID] = session
            }
        }
    }
}

struct MonitoringSession {
    let userID: String
    let startTime: Date
    var activityCount: Int
    var anomalyCount: Int
    var lastActivityTime: Date?
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var anomalyRate: Double {
        guard activityCount > 0 else { return 0 }
        return Double(anomalyCount) / Double(activityCount)
    }
}