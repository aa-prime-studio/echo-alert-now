import Foundation
import Combine

// MARK: - Automatic Ban System
/// 自動封禁系統 - 基於演算法自動管理用戶行為
/// 實現完全自動化的用戶行為評估和封禁管理
class AutomaticBanSystem {
    
    // MARK: - Private Properties
    private var bannedUsers: Set<String> = []
    private var userViolationScores: [String: ViolationScore] = [:]
    private var temporaryBans: [String: TemporaryBan] = [:]
    private let queue = DispatchQueue(label: "AutomaticBanSystem", qos: .utility)
    
    // MARK: - Configuration
    private let violationThresholds = ViolationThresholds(
        warning: 25,
        temporaryBan: 50,
        permanentBan: 100
    )
    
    private let banDurations = BanDurations(
        firstOffense: 3600,      // 1小時
        secondOffense: 86400,    // 24小時
        thirdOffense: 604800,    // 7天
        permanentBan: 0          // 永久
    )
    
    private let scoreDecayRate: Double = 0.1 // 每小時減少10%
    private let scoreDecayInterval: TimeInterval = 3600 // 1小時
    
    // MARK: - Initialization
    init() {
        setupScoreDecayTimer()
        print("🚫 AutomaticBanSystem: 自動封禁系統已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 評估用戶行為並執行封禁（如果需要）
    func evaluateUserBehavior(_ userId: String) async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.performBehaviorEvaluation(userId)
                continuation.resume()
            }
        }
    }
    
    /// 評估威脅並執行封禁
    func evaluateAndExecuteBan(_ threat: SecurityThreat) async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.processThreatForBan(threat)
                continuation.resume()
            }
        }
    }
    
    /// 檢查用戶是否被封禁
    func isUserBanned(_ userId: String) -> Bool {
        return queue.sync {
            // 檢查永久封禁
            if bannedUsers.contains(userId) {
                return true
            }
            
            // 檢查臨時封禁
            if let tempBan = temporaryBans[userId] {
                if Date() < tempBan.expiryDate {
                    return true
                } else {
                    // 臨時封禁已過期，清除記錄
                    temporaryBans.removeValue(forKey: userId)
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
    
    /// 獲取封禁統計
    func getBanStatistics() -> BanStatistics {
        return queue.sync {
            let activeTempBans = temporaryBans.values.filter { Date() < $0.expiryDate }
            
            return BanStatistics(
                permanentBans: bannedUsers.count,
                activeTempBans: activeTempBans.count,
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
            banHistory: []
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
        
        // 檢查是否需要執行封禁
        checkAndExecuteBan(userId, violationScore)
        
        print("📊 AutomaticBanSystem: 用戶 \(userId) 違規分數更新為 \(violationScore.currentScore)")
    }
    
    private func processThreatForBan(_ threat: SecurityThreat) {
        let userId = threat.source
        
        // 根據威脅類型和嚴重程度計算違規分數
        let violationScore = calculateThreatViolationScore(threat)
        
        // 記錄違規
        recordViolation(userId: userId, score: violationScore, reason: threat.details)
        
        print("⚠️ AutomaticBanSystem: 處理威脅 - 用戶: \(userId), 分數: \(violationScore), 原因: \(threat.details)")
    }
    
    private func analyzeBehaviorPatterns(_ userId: String) -> BehaviorAnalysis {
        // 這裡會整合更複雜的行為分析邏輯
        // 暫時返回基本分析結果
        return BehaviorAnalysis(
            suspiciousActivity: false,
            floodingDetected: false,
            spamDetected: false,
            aggressiveBehavior: false,
            riskLevel: .low
        )
    }
    
    private func calculateScoreIncrease(_ analysis: BehaviorAnalysis) -> Double {
        var scoreIncrease: Double = 0.0
        
        if analysis.suspiciousActivity { scoreIncrease += 10.0 }
        if analysis.floodingDetected { scoreIncrease += 25.0 }
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
        case .floodAttack:
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
            banHistory: []
        )
        
        violationScore.currentScore += score
        violationScore.totalViolations += 1
        violationScore.lastViolationDate = Date()
        
        userViolationScores[userId] = violationScore
        
        // 檢查是否需要執行封禁
        checkAndExecuteBan(userId, violationScore)
    }
    
    private func checkAndExecuteBan(_ userId: String, _ violationScore: ViolationScore) {
        let currentScore = violationScore.currentScore
        
        if currentScore >= violationThresholds.permanentBan {
            executePermanentBan(userId, reason: "違規分數達到永久封禁閾值: \(currentScore)")
        } else if currentScore >= violationThresholds.temporaryBan {
            executeTemporaryBan(userId, violationScore: violationScore)
        } else if currentScore >= violationThresholds.warning {
            issueWarning(userId, currentScore: currentScore)
        }
    }
    
    private func executePermanentBan(_ userId: String, reason: String) {
        bannedUsers.insert(userId)
        
        // 記錄封禁歷史
        if var violationScore = userViolationScores[userId] {
            let banRecord = BanRecord(
                date: Date(),
                type: .permanent,
                reason: reason,
                duration: 0
            )
            violationScore.banHistory.append(banRecord)
            userViolationScores[userId] = violationScore
        }
        
        // 清除臨時封禁記錄（如果有）
        temporaryBans.removeValue(forKey: userId)
        
        print("🔒 AutomaticBanSystem: 永久封禁用戶 \(userId) - 原因: \(reason)")
    }
    
    private func executeTemporaryBan(_ userId: String, violationScore: ViolationScore) {
        let banCount = violationScore.banHistory.count
        let duration: TimeInterval
        
        switch banCount {
        case 0: duration = banDurations.firstOffense
        case 1: duration = banDurations.secondOffense
        case 2: duration = banDurations.thirdOffense
        default: duration = banDurations.permanentBan
        }
        
        if duration == 0 {
            // 升級為永久封禁
            executePermanentBan(userId, reason: "多次違規，升級為永久封禁")
            return
        }
        
        let expiryDate = Date().addingTimeInterval(duration)
        let tempBan = TemporaryBan(
            userId: userId,
            startDate: Date(),
            expiryDate: expiryDate,
            reason: "違規分數達到臨時封禁閾值: \(violationScore.currentScore)"
        )
        
        temporaryBans[userId] = tempBan
        
        // 記錄封禁歷史
        if var violationScore = userViolationScores[userId] {
            let banRecord = BanRecord(
                date: Date(),
                type: .temporary,
                reason: tempBan.reason,
                duration: duration
            )
            violationScore.banHistory.append(banRecord)
            userViolationScores[userId] = violationScore
        }
        
        let hours = Int(duration / 3600)
        print("⏰ AutomaticBanSystem: 臨時封禁用戶 \(userId) \(hours)小時 - 原因: \(tempBan.reason)")
    }
    
    private func issueWarning(_ userId: String, currentScore: Double) {
        print("⚠️ AutomaticBanSystem: 警告用戶 \(userId) - 當前違規分數: \(currentScore)")
        // 這裡可以實作警告通知機制
    }
    
    private func setupScoreDecayTimer() {
        Timer.scheduledTimer(withTimeInterval: scoreDecayInterval, repeats: true) { [weak self] _ in
            self?.applyScoreDecay()
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
    let temporaryBan: Double
    let permanentBan: Double
}

struct BanDurations {
    let firstOffense: TimeInterval
    let secondOffense: TimeInterval
    let thirdOffense: TimeInterval
    let permanentBan: TimeInterval
}

struct ViolationScore {
    let userId: String
    var currentScore: Double
    var totalViolations: Int
    var lastViolationDate: Date?
    var banHistory: [BanRecord]
}

struct TemporaryBan {
    let userId: String
    let startDate: Date
    let expiryDate: Date
    let reason: String
}

struct BanRecord {
    let date: Date
    let type: BanType
    let reason: String
    let duration: TimeInterval
}

enum BanType {
    case temporary
    case permanent
}

struct BehaviorAnalysis {
    let suspiciousActivity: Bool
    let floodingDetected: Bool
    let spamDetected: Bool
    let aggressiveBehavior: Bool
    let riskLevel: RiskLevel
}

enum RiskLevel {
    case low
    case medium
    case high
    case critical
}

struct BanStatistics {
    let permanentBans: Int
    let activeTempBans: Int
    let totalViolations: Int
    let averageViolationScore: Double
} 