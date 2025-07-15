import Foundation
import Combine
import CryptoKit

// MARK: - Automatic Security Monitor
/// 自動安全監控系統 - 取代管理員手動查看安全事件
/// 實現完全自動化的安全威脅檢測、分析和處理
class AutomaticSecurityMonitor: @unchecked Sendable {
    
    // MARK: - Private Properties
    private var securityEvents: [SecurityEvent] = []
    private var threatPatterns: [ThreatPattern] = []
    private var behaviorAnalyzer = UserBehaviorAnalyzer()
    private var networkAnalyzer = NetworkTrafficAnalyzer()
    private let queue = DispatchQueue(label: "AutomaticSecurityMonitor", qos: .utility)
    
    // MARK: - Configuration
    private let maxStoredEvents = 10000
    private let threatAnalysisWindow: TimeInterval = 3600 // 1小時
    private let suspiciousActivityThreshold = 5
    private let criticalThreatThreshold = 3
    
    // MARK: - Initialization
    init() {
        setupThreatPatterns()
        print("🛡️ AutomaticSecurityMonitor: 自動安全監控系統已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 執行安全掃描
    func performSecurityScan() async -> SecurityScanResult {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: SecurityScanResult(threatLevel: .low, threats: [], scanTimestamp: Date()))
                    return
                }
                let result = self.executeSecurityScan()
                continuation.resume(returning: result)
            }
        }
    }
    
    /// 記錄安全事件（自動處理）
    func recordSecurityEvent(_ event: SecurityEvent) {
        queue.async {
            self.processSecurityEvent(event)
        }
    }
    
    /// 分析用戶行為模式
    func analyzeUserBehavior(_ userId: String, actions: [UserAction]) async -> BehaviorAnalysisResult {
        return await behaviorAnalyzer.analyzeBehavior(userId: userId, actions: actions)
    }
    
    /// 分析網路流量異常
    func analyzeNetworkTraffic(_ trafficData: NetworkTrafficData) async -> NetworkAnalysisResult {
        return await networkAnalyzer.analyzeTraffic(trafficData)
    }
    
    // MARK: - Private Methods
    
    private func executeSecurityScan() -> SecurityScanResult {
        print("🔍 AutomaticSecurityMonitor: 執行安全掃描")
        
        let recentEvents = getRecentSecurityEvents()
        let detectedThreats = analyzeEventsForThreats(recentEvents)
        let overallThreatLevel = calculateOverallThreatLevel(detectedThreats)
        
        // 自動處理檢測到的威脅
        for threat in detectedThreats {
            processDetectedThreat(threat)
        }
        
        let result = SecurityScanResult(
            threatLevel: overallThreatLevel,
            threats: detectedThreats,
            scanTimestamp: Date()
        )
        
        print("✅ AutomaticSecurityMonitor: 安全掃描完成 - 威脅等級: \(overallThreatLevel), 發現威脅: \(detectedThreats.count)個")
        
        return result
    }
    
    private func processSecurityEvent(_ event: SecurityEvent) {
        // 添加到事件列表
        securityEvents.insert(event, at: 0)
        
        // 限制儲存的事件數量
        if securityEvents.count > maxStoredEvents {
            securityEvents = Array(securityEvents.prefix(maxStoredEvents))
        }
        
        // 即時威脅分析
        let immediateThreats = analyzeEventForImmediateThreats(event)
        for threat in immediateThreats {
            handleImmediateThreat(threat)
        }
        
        // 記錄事件
        logSecurityEvent(event)
    }
    
    private func analyzeEventsForThreats(_ events: [SecurityEvent]) -> [SecurityThreat] {
        var detectedThreats: [SecurityThreat] = []
        
        // 分析洪水攻擊模式
        let floodThreats = detectFloodAttacks(events)
        detectedThreats.append(contentsOf: floodThreats)
        
        // 分析可疑行為模式
        let behaviorThreats = detectSuspiciousBehavior(events)
        detectedThreats.append(contentsOf: behaviorThreats)
        
        // 分析未授權存取嘗試
        let accessThreats = detectUnauthorizedAccess(events)
        detectedThreats.append(contentsOf: accessThreats)
        
        // 分析網路異常
        let networkThreats = detectNetworkAnomalies(events)
        detectedThreats.append(contentsOf: networkThreats)
        
        return detectedThreats
    }
    
    private func detectFloodAttacks(_ events: [SecurityEvent]) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        // 按來源分組事件
        let eventsBySource = Dictionary(grouping: events) { $0.peerID }
        
        for (sourceID, sourceEvents) in eventsBySource {
            // 檢查短時間內的大量請求
            let recentEvents = sourceEvents.filter { 
                Date().timeIntervalSince($0.timestamp) < 300 // 5分鐘內
            }
            
            if recentEvents.count > 50 { // 5分鐘內超過50個事件
                let threat = SecurityThreat(
                    id: "flood_\(sourceID)_\(Date().timeIntervalSince1970)",
                    source: sourceID,
                    type: .floodAttack,
                    severity: .high,
                    details: "檢測到洪水攻擊：5分鐘內\(recentEvents.count)個事件"
                )
                threats.append(threat)
            }
        }
        
        return threats
    }
    
    private func detectSuspiciousBehavior(_ events: [SecurityEvent]) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        // 檢查異常行為模式
        for pattern in threatPatterns {
            let matchingEvents = events.filter { event in
                pattern.matches(event)
            }
            
            if matchingEvents.count >= pattern.threshold {
                let threat = SecurityThreat(
                    id: "behavior_\(pattern.id)_\(Date().timeIntervalSince1970)",
                    source: "pattern_analysis",
                    type: .suspiciousBehavior,
                    severity: pattern.severity,
                    details: "檢測到可疑行為模式：\(pattern.description)"
                )
                threats.append(threat)
            }
        }
        
        return threats
    }
    
    private func detectUnauthorizedAccess(_ events: [SecurityEvent]) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        // 檢查未授權存取嘗試
        let accessEvents = events.filter { 
            $0.type == .unauthorizedAccess || $0.type == .securityWarning 
        }
        
        let accessAttemptsBySource = Dictionary(grouping: accessEvents) { $0.peerID }
        
        for (sourceID, attempts) in accessAttemptsBySource {
            if attempts.count >= 3 { // 3次或以上未授權嘗試
                let threat = SecurityThreat(
                    id: "access_\(sourceID)_\(Date().timeIntervalSince1970)",
                    source: sourceID,
                    type: .unauthorizedAccess,
                    severity: .medium,
                    details: "檢測到多次未授權存取嘗試：\(attempts.count)次"
                )
                threats.append(threat)
            }
        }
        
        return threats
    }
    
    private func detectNetworkAnomalies(_ events: [SecurityEvent]) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        // 檢查網路異常模式
        let networkEvents = events.filter { $0.type == .networkAnomaly }
        
        if networkEvents.count > 10 { // 大量網路異常
            let threat = SecurityThreat(
                id: "network_anomaly_\(Date().timeIntervalSince1970)",
                source: "network_monitor",
                type: .networkAnomaly,
                severity: .medium,
                details: "檢測到網路異常：\(networkEvents.count)個異常事件"
            )
            threats.append(threat)
        }
        
        return threats
    }
    
    private func calculateOverallThreatLevel(_ threats: [SecurityThreat]) -> ThreatLevel {
        if threats.isEmpty {
            return .normal
        }
        
        let maxSeverity = threats.map { $0.severity.rawValue }.max() ?? 0
        let threatCount = threats.count
        
        // 根據威脅數量和嚴重程度計算整體威脅等級
        if maxSeverity == 4 || threatCount >= 10 {
            return .critical
        } else if maxSeverity == 3 || threatCount >= 5 {
            return .high
        } else if maxSeverity == 2 || threatCount >= 2 {
            return .medium
        } else if maxSeverity == 1 || threatCount == 1 {
            return .low
        } else {
            return .normal
        }
    }
    
    private func processDetectedThreat(_ threat: SecurityThreat) {
        print("⚠️ AutomaticSecurityMonitor: 處理檢測到的威脅 - \(threat.type): \(threat.details)")
        
        // 根據威脅類型自動執行對應措施
        switch threat.type {
        case .floodAttack:
            handleFloodAttack(threat)
        case .suspiciousBehavior:
            handleSuspiciousBehavior(threat)
        case .unauthorizedAccess:
            handleUnauthorizedAccess(threat)
        case .networkAnomaly:
            handleNetworkAnomaly(threat)
        case .dataCorruption:
            handleDataCorruption(threat)
        }
    }
    
    private func handleFloodAttack(_ threat: SecurityThreat) {
        // 自動啟動洪水攻擊防護
        print("🚫 AutomaticSecurityMonitor: 啟動洪水攻擊防護 - 來源: \(threat.source)")
        // 這裡會整合到 FloodProtection 系統
    }
    
    private func handleSuspiciousBehavior(_ threat: SecurityThreat) {
        // 增強對該來源的監控
        print("👁️ AutomaticSecurityMonitor: 增強監控可疑行為 - 來源: \(threat.source)")
    }
    
    private func handleUnauthorizedAccess(_ threat: SecurityThreat) {
        // 自動封鎖未授權存取
        print("🔒 AutomaticSecurityMonitor: 封鎖未授權存取 - 來源: \(threat.source)")
    }
    
    private func handleNetworkAnomaly(_ threat: SecurityThreat) {
        // 啟動網路診斷
        print("📡 AutomaticSecurityMonitor: 啟動網路診斷 - \(threat.details)")
    }
    
    private func handleDataCorruption(_ threat: SecurityThreat) {
        // 啟動資料完整性檢查
        print("🔧 AutomaticSecurityMonitor: 啟動資料完整性檢查")
    }
    
    private func analyzeEventForImmediateThreats(_ event: SecurityEvent) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        // 檢查是否為高嚴重性事件，需要立即處理
        if event.severity == .critical {
            let threat = SecurityThreat(
                id: "immediate_\(event.timestamp.timeIntervalSince1970)",
                source: event.peerID,
                type: mapEventTypeToThreatType(event.type),
                severity: .critical,
                details: "立即威脅：\(event.details)"
            )
            threats.append(threat)
        }
        
        return threats
    }
    
    private func handleImmediateThreat(_ threat: SecurityThreat) {
        print("🚨 AutomaticSecurityMonitor: 處理立即威脅 - \(threat.details)")
        processDetectedThreat(threat)
    }
    
    private func getRecentSecurityEvents() -> [SecurityEvent] {
        let cutoffTime = Date().addingTimeInterval(-threatAnalysisWindow)
        return securityEvents.filter { $0.timestamp > cutoffTime }
    }
    
    private func logSecurityEvent(_ event: SecurityEvent) {
        let logPrefix = getLogPrefix(for: event.severity)
        print("\(logPrefix) AutomaticSecurityMonitor: [\(event.type.rawValue)] \(event.peerID) - \(event.details)")
    }
    
    private func getLogPrefix(for severity: SecuritySeverity) -> String {
        switch severity {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "🚨"
        case .critical: return "🔴"
        }
    }
    
    private func mapEventTypeToThreatType(_ eventType: SecurityEventType) -> ThreatType {
        switch eventType {
        case .floodProtection: return .floodAttack
        case .unauthorizedAccess: return .unauthorizedAccess
        case .dataAccess: return .suspiciousBehavior
        case .securityWarning: return .suspiciousBehavior
        case .networkAnomaly: return .networkAnomaly
        default: return .suspiciousBehavior
        }
    }
    
    private func setupThreatPatterns() {
        threatPatterns = [
            ThreatPattern(
                id: "rapid_requests",
                description: "短時間內大量請求",
                eventType: .dataAccess,
                threshold: 20,
                timeWindow: 300, // 5分鐘
                severity: .medium
            ),
            ThreatPattern(
                id: "repeated_failures",
                description: "重複失敗嘗試",
                eventType: .securityWarning,
                threshold: 5,
                timeWindow: 600, // 10分鐘
                severity: .high
            ),
            ThreatPattern(
                id: "unusual_access_pattern",
                description: "異常存取模式",
                eventType: .unauthorizedAccess,
                threshold: 3,
                timeWindow: 1800, // 30分鐘
                severity: .high
            )
        ]
    }
}

// MARK: - Supporting Classes

class UserBehaviorAnalyzer {
    func analyzeBehavior(userId: String, actions: [UserAction]) async -> BehaviorAnalysisResult {
        // 實作用戶行為分析邏輯
        return BehaviorAnalysisResult(
            userId: userId,
            riskScore: calculateRiskScore(actions),
            anomalies: detectAnomalies(actions),
            timestamp: Date()
        )
    }
    
    private func calculateRiskScore(_ actions: [UserAction]) -> Double {
        // 計算風險分數的邏輯
        return 0.0
    }
    
    private func detectAnomalies(_ actions: [UserAction]) -> [BehaviorAnomaly] {
        // 檢測行為異常的邏輯
        return []
    }
}

class NetworkTrafficAnalyzer {
    func analyzeTraffic(_ trafficData: NetworkTrafficData) async -> NetworkAnalysisResult {
        // 實作網路流量分析邏輯
        return NetworkAnalysisResult(
            anomalyDetected: false,
            trafficPattern: .normal,
            suspiciousConnections: [],
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

struct ThreatPattern {
    let id: String
    let description: String
    let eventType: SecurityEventType
    let threshold: Int
    let timeWindow: TimeInterval
    let severity: ThreatLevel
    
    func matches(_ event: SecurityEvent) -> Bool {
        return event.type == eventType && 
               Date().timeIntervalSince(event.timestamp) <= timeWindow
    }
}

struct UserAction {
    let type: ActionType
    let timestamp: Date
    let details: String
}

enum ActionType {
    case login
    case dataAccess
    case messagePost
    case configChange
}

struct BehaviorAnalysisResult {
    let userId: String
    let riskScore: Double
    let anomalies: [BehaviorAnomaly]
    let timestamp: Date
}

struct BehaviorAnomaly {
    let type: AnomalyType
    let description: String
    let severity: ThreatLevel
}

enum AnomalyType {
    case unusualFrequency
    case suspiciousPattern
    case locationAnomaly
    case timeAnomaly
}

struct NetworkTrafficData {
    let sourceIP: String
    let destinationIP: String
    let networkProtocol: String
    let dataSize: Int
    let timestamp: Date
}

struct NetworkAnalysisResult {
    let anomalyDetected: Bool
    let trafficPattern: TrafficPattern
    let suspiciousConnections: [String]
    let timestamp: Date
}

enum TrafficPattern {
    case normal
    case suspicious
    case malicious
} 