import Foundation

//
// SecurityEventTypes.swift
// SignalAir
//
// 安全事件類型定義 - 支援 AutomaticSecurityMonitor
//

/// 安全事件結構體
struct SecurityEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let peerID: String
    let type: SecurityEventType
    let severity: SecuritySeverity
    let details: String
    let sourceComponent: String
    
    init(
        peerID: String,
        type: SecurityEventType,
        severity: SecuritySeverity,
        details: String,
        sourceComponent: String = "Unknown"
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.peerID = peerID
        self.type = type
        self.severity = severity
        self.details = details
        self.sourceComponent = sourceComponent
    }
}

/// 安全事件類型列舉
enum SecurityEventType: String, Codable, CaseIterable {
    case floodProtection = "flood_protection"
    case unauthorizedAccess = "unauthorized_access"
    case dataAccess = "data_access"
    case securityWarning = "security_warning"
    case networkAnomaly = "network_anomaly"
    case encryptionFailure = "encryption_failure"
    case keyExchangeFailure = "key_exchange_failure"
    case deviceFingerprintMismatch = "device_fingerprint_mismatch"
    case botDetection = "bot_detection"
    case suspiciousActivity = "suspicious_activity"
    
    var displayName: String {
        switch self {
        case .floodProtection:
            return "洪水攻擊保護"
        case .unauthorizedAccess:
            return "未授權存取"
        case .dataAccess:
            return "資料存取"
        case .securityWarning:
            return "安全警告"
        case .networkAnomaly:
            return "網路異常"
        case .encryptionFailure:
            return "加密失敗"
        case .keyExchangeFailure:
            return "金鑰交換失敗"
        case .deviceFingerprintMismatch:
            return "設備指紋不符"
        case .botDetection:
            return "機器人檢測"
        case .suspiciousActivity:
            return "可疑活動"
        }
    }
}

/// 安全嚴重性等級
enum SecuritySeverity: String, Codable, CaseIterable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        case .critical:
            return "嚴重"
        }
    }
    
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    static func < (lhs: SecuritySeverity, rhs: SecuritySeverity) -> Bool {
        return lhs.numericValue < rhs.numericValue
    }
}

/// 安全事件回調類型
typealias SecurityEventHandler = (SecurityEvent) -> Void

/// 安全監控設定
struct SecurityMonitorConfig {
    let enableFloodProtection: Bool
    let enableBotDetection: Bool
    let enableAnomalyDetection: Bool
    let maxEventsPerMinute: Int
    let criticalEventThreshold: Int
    
    static let `default` = SecurityMonitorConfig(
        enableFloodProtection: true,
        enableBotDetection: true,
        enableAnomalyDetection: true,
        maxEventsPerMinute: 60,
        criticalEventThreshold: 5
    )
}

/// 擴展：為與現有 SecurityScanResult 相容
extension SecurityEvent {
    /// 從 SecurityScanResult 轉換為 SecurityEvent
    static func from(scanResult: SecurityScanResult, peerID: String) -> SecurityEvent {
        let severity: SecuritySeverity
        switch scanResult.threatLevel {
        case .normal, .low:
            severity = .low
        case .medium:
            severity = .medium
        case .high:
            severity = .high
        case .critical:
            severity = .critical
        }
        
        let eventType: SecurityEventType
        switch scanResult.threats.first?.type {
        case .suspiciousBehavior:
            eventType = .suspiciousActivity
        case .networkAnomaly:
            eventType = .networkAnomaly
        case .unauthorizedAccess:
            eventType = .unauthorizedAccess
        case .floodAttack:
            eventType = .floodProtection
        case .dataCorruption:
            eventType = .dataAccess
        case .none:
            eventType = .securityWarning
        }
        
        return SecurityEvent(
            peerID: peerID,
            type: eventType,
            severity: severity,
            details: scanResult.threats.map { $0.details }.joined(separator: "; "),
            sourceComponent: "SecurityScanner"
        )
    }
}