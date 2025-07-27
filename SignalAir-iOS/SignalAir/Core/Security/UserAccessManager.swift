import Foundation
import Combine

// MARK: - User Access Manager
/// 用戶存取管理系統 - 基於演算法自動管理用戶行為
/// 實現完全自動化的用戶行為評估和存取管理
class UserAccessManager: @unchecked Sendable {
    
    // MARK: - Private Properties
    private var restrictedUsers: Set<String> = []
    private var userViolationScores: [String: ViolationScore] = [:]
    private var temporaryRestrictions: [String: TemporaryRestriction] = [:]
    private let queue = DispatchQueue(label: "UserAccessManager", qos: .utility)
    
    // MARK: - Configuration
    private let violationThresholds = ViolationThresholds(
        warning: 25,
        temporaryRestriction: 50,
        permanentRestriction: 100
    )
    
    private let restrictionDurations = RestrictionDurations(
        firstOffense: 3600,      // 1小時
        secondOffense: 86400,    // 24小時
        thirdOffense: 604800,    // 7天
        permanentRestriction: 0          // 永久
    )
    
    private let scoreDecayRate: Double = 0.1 // 每小時減少10%
    private let scoreDecayInterval: TimeInterval = 3600 // 1小時
    
    // MARK: - Initialization
    init() {
        setupScoreDecayTimer()
        print("🚫 UserAccessManager: 用戶存取管理系統已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 評估用戶行為並執行存取管理（如果需要）
    func evaluateUserBehavior(_ userId: String) async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.performBehaviorEvaluation(userId)
                continuation.resume()
            }
        }
    }
    
    /// 評估威脅並執行存取控制
    func evaluateAndExecuteAccessControl(_ threat: SecurityThreat) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.processThreatForAccessControl(threat)
                continuation.resume()
            }
        }
    }
    
    /// 檢查用戶是否被限制存取
    func isUserRestricted(_ userId: String) -> Bool {
        return queue.sync {
            // 檢查永久限制
            if restrictedUsers.contains(userId) {
                return true
            }
            
            // 檢查臨時限制
            if let tempRestriction = temporaryRestrictions[userId] {
                if Date() < tempRestriction.expiryDate {
                    return true
                } else {
                    // 臨時限制已過期，清除記錄
                    temporaryRestrictions.removeValue(forKey: userId)
                    return false
                }
            }
            
            return false
        }
    }
    
    /// 獲取用戶違規分數
    func getUserViolationScore(_ userId: String) -> Double {
        return queue.sync {
            return userViolationScores[userId]?.currentScore ?? 0.0
        }
    }
    
    /// 獲取存取管理統計
    func getAccessStatistics() -> UserAccessStatistics {
        return queue.sync {
            let activeTempRestrictions = temporaryRestrictions.values.filter { Date() < $0.expiryDate }
            
            return UserAccessStatistics(
                permanentRestrictions: restrictedUsers.count,
                activeTempRestrictions: activeTempRestrictions.count,
                totalViolations: userViolationScores.values.reduce(0) { $0 + $1.totalViolations },
                averageViolationScore: calculateAverageViolationScore()
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func performBehaviorEvaluation(_ userId: String) {
        // 獲取或創建用戶違規分數記錄
        var violationScore = userViolationScores[userId] ?? ViolationScore(
            userId: userId,
            currentScore: 0.0,
            totalViolations: 0,
            lastViolationDate: nil,
            accessControlHistory: []
        )
        
        // 分析用戶最近的行為
        let behaviorAnalysis = analyzeBehaviorPatterns(userId)
        
        // 根據分析結果調整違規分數
        let scoreIncrease = calculateScoreIncrease(behaviorAnalysis)
        violationScore.currentScore += scoreIncrease
        violationScore.totalViolations += 1
        violationScore.lastViolationDate = Date()
        
        // 更新記錄
        userViolationScores[userId] = violationScore
        
        // 檢查是否需要執行限制
        checkAndExecuteAccessControl(userId, violationScore)
        
        print("📊 UserAccessManager: 用戶 \(userId) 違規分數更新為 \(violationScore.currentScore)")
    }
    
    private func processThreatForAccessControl(_ threat: SecurityThreat) {
        let userId = threat.source
        
        // 根據威脅類型和嚴重程度計算違規分數
        let violationScore = calculateThreatViolationScore(threat)
        
        // 記錄違規
        recordViolation(userId: userId, score: violationScore, reason: threat.details)
        
        print("⚠️ UserAccessManager: 處理威脅 - 用戶: \(userId), 分數: \(violationScore), 原因: \(threat.details)")
    }
    
    private func analyzeBehaviorPatterns(_ userId: String) -> BehaviorAnalysis {
        // 這裡會整合更複雜的行為分析邏輯
        // 暫時返回基本分析結果
        return BehaviorAnalysis(
            suspiciousActivity: false,
            excessiveConnectionsDetected: false,
            spamDetected: false,
            aggressiveBehavior: false,
            riskLevel: .low
        )
    }
    
    private func calculateScoreIncrease(_ analysis: BehaviorAnalysis) -> Double {
        var scoreIncrease: Double = 0.0
        
        if analysis.suspiciousActivity { scoreIncrease += 10.0 }
        if analysis.excessiveConnectionsDetected { scoreIncrease += 25.0 }
        if analysis.spamDetected { scoreIncrease += 15.0 }
        if analysis.aggressiveBehavior { scoreIncrease += 20.0 }
        
        // 根據風險等級調整
        switch analysis.riskLevel {
        case .low: scoreIncrease *= 1.0
        case .medium: scoreIncrease *= 1.5
        case .high: scoreIncrease *= 2.0
        case .critical: scoreIncrease *= 3.0
        }
        
        return scoreIncrease
    }
    
    private func calculateThreatViolationScore(_ threat: SecurityThreat) -> Double {
        let baseScore: Double
        
        switch threat.type {
        case .highConnectionRate:
            baseScore = 40.0
        case .suspiciousBehavior:
            baseScore = 20.0
        case .unauthorizedAccess:
            baseScore = 30.0
        case .networkAnomaly:
            baseScore = 15.0
        case .dataCorruption:
            baseScore = 50.0
        }
        
        // 根據嚴重程度調整
        let severityMultiplier: Double
        switch threat.severity {
        case .normal: severityMultiplier = 1.0
        case .low: severityMultiplier = 1.2
        case .medium: severityMultiplier = 1.5
        case .high: severityMultiplier = 2.0
        case .critical: severityMultiplier = 3.0
        }
        
        return baseScore * severityMultiplier
    }
    
    private func recordViolation(userId: String, score: Double, reason: String) {
        var violationScore = userViolationScores[userId] ?? ViolationScore(
            userId: userId,
            currentScore: 0.0,
            totalViolations: 0,
            lastViolationDate: nil,
            accessControlHistory: []
        )
        
        violationScore.currentScore += score
        violationScore.totalViolations += 1
        violationScore.lastViolationDate = Date()
        
        userViolationScores[userId] = violationScore
        
        // 檢查是否需要執行限制
        checkAndExecuteAccessControl(userId, violationScore)
    }
    
    private func checkAndExecuteAccessControl(_ userId: String, _ violationScore: ViolationScore) {
        let currentScore = violationScore.currentScore
        
        if currentScore >= violationThresholds.permanentRestriction {
            executePermanentRestriction(userId, reason: "違規分數達到永久限制閾值: \(currentScore)")
        } else if currentScore >= violationThresholds.temporaryRestriction {
            executeTemporaryRestriction(userId, violationScore: violationScore)
        } else if currentScore >= violationThresholds.warning {
            issueWarning(userId, currentScore: currentScore)
        }
    }
    
    private func executePermanentRestriction(_ userId: String, reason: String) {
        restrictedUsers.insert(userId)
        
        // 記錄限制歷史
        if var violationScore = userViolationScores[userId] {
            let restrictionRecord = AccessControlRecord(
                date: Date(),
                type: .permanent,
                reason: reason,
                duration: 0
            )
            violationScore.accessControlHistory.append(restrictionRecord)
            userViolationScores[userId] = violationScore
        }
        
        // 清除臨時限制記錄（如果有）
        temporaryRestrictions.removeValue(forKey: userId)
        
        print("🔒 UserAccessManager: 永久限制用戶 \(userId) - 原因: \(reason)")
    }
    
    private func executeTemporaryRestriction(_ userId: String, violationScore: ViolationScore) {
        let restrictionCount = violationScore.accessControlHistory.count
        let duration: TimeInterval
        
        switch restrictionCount {
        case 0: duration = restrictionDurations.firstOffense
        case 1: duration = restrictionDurations.secondOffense
        case 2: duration = restrictionDurations.thirdOffense
        default: duration = restrictionDurations.permanentRestriction
        }
        
        if duration == 0 {
            // 升級為永久限制
            executePermanentRestriction(userId, reason: "多次違規，升級為永久限制")
            return
        }
        
        let expiryDate = Date().addingTimeInterval(duration)
        let tempRestriction = TemporaryRestriction(
            userId: userId,
            startDate: Date(),
            expiryDate: expiryDate,
            reason: "違規分數達到臨時限制閾值: \(violationScore.currentScore)"
        )
        
        temporaryRestrictions[userId] = tempRestriction
        
        // 記錄限制歷史
        if var violationScore = userViolationScores[userId] {
            let restrictionRecord = AccessControlRecord(
                date: Date(),
                type: .temporary,
                reason: tempRestriction.reason,
                duration: duration
            )
            violationScore.accessControlHistory.append(restrictionRecord)
            userViolationScores[userId] = violationScore
        }
        
        let hours = Int(duration / 3600)
        print("⏰ UserAccessManager: 臨時限制用戶 \(userId) \(hours)小時 - 原因: \(tempRestriction.reason)")
    }
    
    private func issueWarning(_ userId: String, currentScore: Double) {
        print("⚠️ UserAccessManager: 警告用戶 \(userId) - 當前違規分數: \(currentScore)")
        // 這裡可以實作警告通知機制
    }
    
    private func setupScoreDecayTimer() {
        Timer.scheduledTimer(withTimeInterval: scoreDecayInterval, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.applyScoreDecay()
            }
        }
    }
    
    private func applyScoreDecay() {
        queue.async {
            for (userId, var violationScore) in self.userViolationScores {
                let newScore = violationScore.currentScore * (1.0 - self.scoreDecayRate)
                violationScore.currentScore = max(0.0, newScore)
                self.userViolationScores[userId] = violationScore
            }
        }
    }
    
    private func calculateAverageViolationScore() -> Double {
        let scores = userViolationScores.values.map { $0.currentScore }
        return scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - Supporting Types

struct ViolationThresholds {
    let warning: Double
    let temporaryRestriction: Double
    let permanentRestriction: Double
}

struct RestrictionDurations {
    let firstOffense: TimeInterval
    let secondOffense: TimeInterval
    let thirdOffense: TimeInterval
    let permanentRestriction: TimeInterval
}

struct ViolationScore {
    let userId: String
    var currentScore: Double
    var totalViolations: Int
    var lastViolationDate: Date?
    var accessControlHistory: [AccessControlRecord]
}

struct TemporaryRestriction {
    let userId: String
    let startDate: Date
    let expiryDate: Date
    let reason: String
}

struct AccessControlRecord {
    let date: Date
    let type: AccessControlType
    let reason: String
    let duration: TimeInterval
}

enum AccessControlType {
    case temporary
    case permanent
}

struct BehaviorAnalysis {
    let suspiciousActivity: Bool
    let excessiveConnectionsDetected: Bool
    let spamDetected: Bool
    let aggressiveBehavior: Bool
    let riskLevel: RiskLevel
}

public enum RiskLevel {
    case low
    case medium
    case high
    case critical
}

// BanStatistics moved to ConnectionRateManager.swift to avoid duplication
struct UserAccessStatistics {
    let permanentRestrictions: Int
    let activeTempRestrictions: Int
    let totalViolations: Int
    let averageViolationScore: Double
} 