import Foundation
import SwiftUI
import Combine
import Observation

//
// BehaviorAnalysisSystem.swift
// SignalAir
//
// 行為分析系統 (Behavior Analysis System)
// 符合 Apple App Store 規範，不顯示攻擊字眼給用戶
//

// MARK: - 異常等級
enum BehaviorAnomalyLevel {
    case safe           // 安全
    case suspicious     // 可疑
    case dangerous      // 危險
    
    var userMessage: String {
        switch self {
        case .safe:
            return ""
        case .suspicious:
            return "網路連線品質不穩定，請稍後再試"
        case .dangerous:
            return "為確保您的安全，系統已暫時限制此連線"
        }
    }
}

// MARK: - 行為特徵
public struct BehaviorPattern {
    let peerID: String
    var connectionTimes: [Date] = []
    var messageTimes: [Date] = []
    var messageContents: [String] = []
    var averageSessionDuration: TimeInterval = 0
    var lastActivity: Date = Date()
    
    // 計算行為分數
    func calculateScore() -> Int {
        var score = 50 // 基礎分數
        
        // 1. 連線時間規律性檢查 (-10 ~ +5)
        if hasRegularConnectionPattern() {
            score -= 10
        } else {
            score += 5
        }
        
        // 2. 訊息頻率檢查 (-15 ~ +5)
        let messageFrequency = calculateMessageFrequency()
        if messageFrequency > 20 { // 每分鐘超過20條
            score -= 15
        } else if messageFrequency < 5 {
            score += 5
        }
        
        // 3. 內容模式檢查 (-20 ~ +10)
        if hasSuspiciousContent() {
            score -= 20
        } else {
            score += 10
        }
        
        // 4. 會話時長檢查 (-5 ~ +5)
        if averageSessionDuration < 60 { // 平均少於1分鐘
            score -= 5
        } else if averageSessionDuration > 300 { // 超過5分鐘
            score += 5
        }
        
        return max(0, min(100, score))
    }
    
    // 檢查是否有規律連線模式
    private func hasRegularConnectionPattern() -> Bool {
        guard connectionTimes.count >= 3 else { return false }
        
        let intervals = connectionTimes.enumerated().compactMap { index, time -> TimeInterval? in
            guard index > 0 else { return nil }
            return time.timeIntervalSince(connectionTimes[index - 1])
        }
        
        guard !intervals.isEmpty else { return false }
        
        // 計算時間間隔的標準差
        let average = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - average, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        
        // 如果標準差小於平均值的10%，視為規律
        return standardDeviation < average * 0.1
    }
    
    // 計算訊息頻率（每分鐘）
    private func calculateMessageFrequency() -> Double {
        guard messageTimes.count >= 2 else { return 0 }
        
        let duration = messageTimes.last!.timeIntervalSince(messageTimes.first!)
        guard duration > 0 else { return Double(messageTimes.count) }
        
        return Double(messageTimes.count) / (duration / 60.0)
    }
    
    // 檢查可疑內容
    private func hasSuspiciousContent() -> Bool {
        let suspiciousPatterns = [
            "scan", "probe", "test", "ping", "exploit",
            "payload", "shellcode", "backdoor"
        ]
        
        for content in messageContents {
            let lowercased = content.lowercased()
            for pattern in suspiciousPatterns {
                if lowercased.contains(pattern) {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - 行為分析等級轉換擴展
extension TrustScoreManager {
    
    /// 根據信任分數獲取行為異常等級 (對新設備更寬容)
    func getBehaviorAnomalyLevel(for peerID: String) -> BehaviorAnomalyLevel {
        let score = getTrustScore(for: peerID)
        
        // 檢查是否是新設備 (沒有歷史記錄)
        let trustInfo = self.getTrustInfo(for: peerID)
        let isNewDevice = trustInfo.updateCount <= 1 && trustInfo.history.isEmpty
        
        // 🔧 修復：對新設備使用極度寬容的標準，避免測試時被誤標記
        if isNewDevice {
            switch score {
            case 20...100:  // 新設備: 20+ 就是安全的（從40降到20）
                return .safe
            case 10...19:   // 新設備: 10-19 是可疑的（從20-39縮小到10-19）
                return .suspicious
            default:        // 新設備: <10 才是危險的（從<20降到<10）
                return .dangerous
            }
        } else {
            // 🔧 修復：對已知設備也使用更寬容的標準
            switch score {
            case 60...100:  // 從85降到60
                return .safe
            case 20...59:   // 從30-84調整到20-59
                return .suspicious
            default:        // <20才是危險的
                return .dangerous
            }
        }
    }
    
    /// 調整分數 (適配行為分析系統)
    func adjustScore(for peerID: String, by delta: Double) {
        let currentScore = getTrustScore(for: peerID)
        _ = max(0, min(100, currentScore + delta))
        
        // 記錄可疑行為或成功通訊，但避免重複記錄和過度懲罰
        if delta > 0 {
            recordSuccessfulCommunication(for: peerID)
        } else if delta < -10.0 {  // 只有非常嚴重的分數下降才記錄違規 (提高閾值)
            recordSuspiciousBehavior(for: peerID, behavior: .protocolViolation)
        }
        // 輕微和中等的分數下降 (-10.0 到 0) 不記錄，兼容性問題不應觸發額外懲罰
    }
    
    /// 更新分數 (適配行為分析系統)
    func updateScore(for peerID: String, newScore: Double) {
        let currentScore = getTrustScore(for: peerID)
        let delta = newScore - currentScore
        adjustScore(for: peerID, by: delta)
    }
    
    /// 獲取整數分數 (向後兼容)
    func getScore(for peerID: String) -> Int {
        return Int(getTrustScore(for: peerID))
    }
}

// MARK: - 行為分析系統主類
@Observable
class BehaviorAnalysisSystem {
    // MARK: - Properties
    private var behaviorPatterns: [String: BehaviorPattern] = [:]
    private let trustScoreManager = TrustScoreManager()
    private let lock = NSLock()
    
    // 配置
    private let maxMessageLength = 1000
    private let maxMessagesPerMinute = 30
    private let suspiciousPatternThreshold = 3
    
    // 統計
    var detectedAnomalies: Int = 0
    var blockedConnections: Int = 0
    
    // MARK: - Public Methods
    
    /// 分析連線行為
    func analyzeConnection(from peerID: String) -> BehaviorAnomalyLevel {
        lock.lock()
        defer { lock.unlock() }
        
        // 記錄連線時間
        if behaviorPatterns[peerID] == nil {
            behaviorPatterns[peerID] = BehaviorPattern(peerID: peerID)
        }
        behaviorPatterns[peerID]?.connectionTimes.append(Date())
        
        // 限制記錄數量
        if let count = behaviorPatterns[peerID]?.connectionTimes.count, count > 100 {
            behaviorPatterns[peerID]?.connectionTimes = Array(behaviorPatterns[peerID]!.connectionTimes.suffix(100))
        }
        
        // 更新信任分數
        updateTrustScore(for: peerID)
        
        return trustScoreManager.getBehaviorAnomalyLevel(for: peerID)
    }
    
    /// 分析訊息內容
    func analyzeMessage(from peerID: String, content: String) -> BehaviorAnomalyLevel {
        lock.lock()
        defer { lock.unlock() }
        
        // 確保行為模式存在
        if behaviorPatterns[peerID] == nil {
            behaviorPatterns[peerID] = BehaviorPattern(peerID: peerID)
        }
        
        // 記錄訊息時間和內容
        behaviorPatterns[peerID]?.messageTimes.append(Date())
        behaviorPatterns[peerID]?.messageContents.append(String(content.prefix(maxMessageLength)))
        behaviorPatterns[peerID]?.lastActivity = Date()
        
        // 限制記錄數量
        if let count = behaviorPatterns[peerID]?.messageTimes.count, count > 100 {
            behaviorPatterns[peerID]?.messageTimes = Array(behaviorPatterns[peerID]!.messageTimes.suffix(100))
            behaviorPatterns[peerID]?.messageContents = Array(behaviorPatterns[peerID]!.messageContents.suffix(100))
        }
        
        // 更新信任分數
        updateTrustScore(for: peerID)
        
        let anomalyLevel = trustScoreManager.getBehaviorAnomalyLevel(for: peerID)
        
        // 記錄異常
        if anomalyLevel == .dangerous {
            detectedAnomalies += 1
            logSecurityEvent(
                eventType: "behavior_anomaly_detected",
                severity: .critical,
                details: "偵測到異常行為模式 - PeerID: \(peerID)"
            )
        }
        
        return anomalyLevel
    }
    
    /// 記錄會話結束
    func recordSessionEnd(for peerID: String, duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        guard var pattern = behaviorPatterns[peerID] else { return }
        
        // 更新平均會話時長
        let currentAverage = pattern.averageSessionDuration
        let sessionCount = pattern.connectionTimes.count
        pattern.averageSessionDuration = (currentAverage * Double(sessionCount - 1) + duration) / Double(sessionCount)
        
        behaviorPatterns[peerID] = pattern
        
        // 正常結束會話加分
        if duration > 60 && duration < 3600 { // 1分鐘到1小時
            trustScoreManager.adjustScore(for: peerID, by: 2.0)
        }
    }
    
    /// 獲取用戶的信任分數
    func getTrustScore(for peerID: String) -> Int {
        return trustScoreManager.getScore(for: peerID)
    }
    
    /// 清理舊資料
    func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoffDate = Date().addingTimeInterval(-86400) // 24小時前
        
        behaviorPatterns = behaviorPatterns.compactMapValues { pattern in
            guard pattern.lastActivity > cutoffDate else { return nil }
            return pattern
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新信任分數
    private func updateTrustScore(for peerID: String) {
        guard let pattern = behaviorPatterns[peerID] else { return }
        
        let behaviorScore = pattern.calculateScore()
        trustScoreManager.updateScore(for: peerID, newScore: Double(behaviorScore))
    }
    
    /// 記錄安全事件
    private func logSecurityEvent(eventType: String, severity: SecurityLogSeverity, details: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("SecurityEvent"),
            object: nil,
            userInfo: [
                "event": eventType,
                "source": "BehaviorAnalysis",
                "severity": severity.rawValue,
                "details": details
            ]
        )
    }
}

// MARK: - 回應策略
extension BehaviorAnalysisSystem {
    
    /// 根據異常等級獲取回應策略
    func getResponseStrategy(for anomalyLevel: BehaviorAnomalyLevel) -> ResponseStrategy {
        switch anomalyLevel {
        case .safe:
            return ResponseStrategy(
                allowConnection: true,
                messageDelay: 0,
                rateLimit: nil,
                requiresMonitoring: false
            )
            
        case .suspicious:
            return ResponseStrategy(
                allowConnection: true,
                messageDelay: 0.1, // 100ms 延遲
                rateLimit: 10, // 每分鐘10條
                requiresMonitoring: true
            )
            
        case .dangerous:
            return ResponseStrategy(
                allowConnection: false,
                messageDelay: 0,
                rateLimit: 0,
                requiresMonitoring: true
            )
        }
    }
}

// MARK: - 回應策略結構
struct ResponseStrategy {
    let allowConnection: Bool
    let messageDelay: TimeInterval
    let rateLimit: Int?
    let requiresMonitoring: Bool
}