import Foundation
import CryptoKit

// MARK: - Trust Behavior Model (內部威脅檢測 - 信任行為模型)
class TrustBehaviorModel {
    private let behaviorAnalyzer = BehaviorAnalyzer()
    private let trustCalculator = TrustCalculator()
    private let anomalyDetector = AnomalyDetector()
    private let queue = DispatchQueue(label: "com.signalair.trustbehavior", qos: .utility)
    
    // MARK: - Trust Baseline Management
    func establishTrustBaseline(for userID: String) -> TrustBaseline {
        return queue.sync {
            let recentActivities = getRecentActivities(userID, days: 30)
            
            return TrustBaseline(
                userID: userID,
                normalTrustRange: calculateNormalTrustRange(recentActivities),
                behaviorPatterns: extractBehaviorPatterns(recentActivities),
                interactionFrequency: calculateInteractionFrequency(recentActivities),
                trustFluctuationPattern: analyzeTrustFluctuations(recentActivities),
                establishedDate: Date()
            )
        }
    }
    
    // MARK: - Anomaly Detection
    func detectTrustBehaviorAnomaly(
        userID: String,
        currentActivity: UserActivity
    ) -> TrustAnomalyResult {
        return queue.sync {
            let baseline = getTrustBaseline(userID) ?? establishTrustBaseline(for: userID)
            let currentTrustScore = trustCalculator.calculateTrustScore(currentActivity)
            
            // 檢查是否超出正常範圍
            let isOutOfRange = !baseline.normalTrustRange.contains(currentTrustScore)
            
            // 檢查行為模式異常
            let behaviorAnomaly = behaviorAnalyzer.detectAnomaly(
                currentActivity, 
                baseline: baseline.behaviorPatterns
            )
            
            // 檢查時間模式異常
            let timingAnomaly = detectTimingAnomaly(currentActivity, baseline: baseline)
            
            let isAnomalous = isOutOfRange || behaviorAnomaly.isAnomalous || timingAnomaly
            
            return TrustAnomalyResult(
                isAnomalous: isAnomalous,
                trustScore: currentTrustScore,
                anomalyType: determineAnomalyType(isOutOfRange, behaviorAnomaly, timingAnomaly),
                confidenceLevel: calculateConfidenceLevel(isOutOfRange, behaviorAnomaly, timingAnomaly),
                recommendedAction: generateRecommendedAction(isOutOfRange, behaviorAnomaly, timingAnomaly),
                detectionTime: Date()
            )
        }
    }
    
    // MARK: - Private Helper Methods
    private func getRecentActivities(_ userID: String, days: Int) -> [UserActivity] {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 3600))
        return ActivityDatabase.shared.getActivities(for: userID, since: cutoffDate)
    }
    
    private func calculateNormalTrustRange(_ activities: [UserActivity]) -> ClosedRange<Double> {
        let trustScores = activities.map { trustCalculator.calculateTrustScore($0) }
        let mean = trustScores.reduce(0, +) / Double(trustScores.count)
        let variance = trustScores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(trustScores.count)
        let standardDeviation = sqrt(variance)
        
        let lowerBound = max(0.0, mean - 2 * standardDeviation)
        let upperBound = min(100.0, mean + 2 * standardDeviation)
        
        return lowerBound...upperBound
    }
    
    private func extractBehaviorPatterns(_ activities: [UserActivity]) -> BehaviorPatterns {
        let connectionPatterns = activities.compactMap { $0.connectionPattern }
        let messagePatterns = activities.compactMap { $0.messagePattern }
        let interactionPatterns = activities.compactMap { $0.interactionPattern }
        
        return BehaviorPatterns(
            connectionFrequency: analyzeConnectionFrequency(connectionPatterns),
            messageFrequency: analyzeMessageFrequency(messagePatterns),
            interactionTiming: analyzeInteractionTiming(interactionPatterns),
            contentPatterns: analyzeContentPatterns(activities)
        )
    }
    
    private func calculateInteractionFrequency(_ activities: [UserActivity]) -> InteractionFrequency {
        let totalHours = 24 * 30 // 30天
        let activeHours = Set(activities.map { Calendar.current.component(.hour, from: $0.timestamp) }).count
        
        return InteractionFrequency(
            dailyAverage: Double(activities.count) / 30.0,
            peakHours: identifyPeakHours(activities),
            averageSessionLength: calculateAverageSessionLength(activities),
            activityDistribution: calculateActivityDistribution(activities)
        )
    }
    
    private func analyzeTrustFluctuations(_ activities: [UserActivity]) -> TrustFluctuationPattern {
        let trustScores = activities.map { trustCalculator.calculateTrustScore($0) }
        let fluctuations = zip(trustScores, trustScores.dropFirst()).map { abs($1 - $0) }
        
        return TrustFluctuationPattern(
            averageFluctuation: fluctuations.reduce(0, +) / Double(fluctuations.count),
            maxFluctuation: fluctuations.max() ?? 0,
            fluctuationTrend: calculateFluctuationTrend(fluctuations),
            stabilityScore: calculateStabilityScore(fluctuations)
        )
    }
    
    private func getTrustBaseline(_ userID: String) -> TrustBaseline? {
        return TrustBaselineStore.shared.getBaseline(for: userID)
    }
    
    private func detectTimingAnomaly(_ activity: UserActivity, baseline: TrustBaseline) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: activity.timestamp)
        let isTypicalTime = baseline.interactionFrequency.peakHours.contains(currentHour)
        
        // 如果在非典型時間且活動頻率異常高，則標記為異常
        return !isTypicalTime && activity.intensity > baseline.interactionFrequency.dailyAverage * 2
    }
    
    private func determineAnomalyType(
        _ isOutOfRange: Bool,
        _ behaviorAnomaly: BehaviorAnomalyResult,
        _ timingAnomaly: Bool
    ) -> AnomalyType {
        if isOutOfRange && behaviorAnomaly.isAnomalous {
            return .combinedAnomaly
        } else if isOutOfRange {
            return .trustScoreAnomaly
        } else if behaviorAnomaly.isAnomalous {
            return .behaviorPatternAnomaly
        } else if timingAnomaly {
            return .timingAnomaly
        }
        return .noAnomaly
    }
    
    private func calculateConfidenceLevel(
        _ isOutOfRange: Bool,
        _ behaviorAnomaly: BehaviorAnomalyResult,
        _ timingAnomaly: Bool
    ) -> Double {
        var confidence = 0.0
        
        if isOutOfRange { confidence += 0.4 }
        if behaviorAnomaly.isAnomalous { confidence += 0.4 }
        if timingAnomaly { confidence += 0.2 }
        
        return min(confidence, 1.0)
    }
    
    private func generateRecommendedAction(
        _ isOutOfRange: Bool,
        _ behaviorAnomaly: BehaviorAnomalyResult,
        _ timingAnomaly: Bool
    ) -> RecommendedAction {
        let confidenceLevel = calculateConfidenceLevel(isOutOfRange, behaviorAnomaly, timingAnomaly)
        
        switch confidenceLevel {
        case 0.8...1.0:
            return .immediateInvestigation
        case 0.6..<0.8:
            return .enhancedMonitoring
        case 0.4..<0.6:
            return .increaseObservation
        default:
            return .continueNormalMonitoring
        }
    }
    
    // MARK: - Analysis Helper Methods
    private func analyzeConnectionFrequency(_ patterns: [ConnectionPattern]) -> ConnectionFrequencyAnalysis {
        let averageConnections = patterns.map { $0.connectionsPerHour }.reduce(0, +) / Double(patterns.count)
        let peakConnections = patterns.map { $0.connectionsPerHour }.max() ?? 0
        
        return ConnectionFrequencyAnalysis(
            average: averageConnections,
            peak: peakConnections,
            variance: calculateVariance(patterns.map { $0.connectionsPerHour })
        )
    }
    
    private func analyzeMessageFrequency(_ patterns: [MessagePattern]) -> MessageFrequencyAnalysis {
        let averageMessages = patterns.map { $0.messagesPerHour }.reduce(0, +) / Double(patterns.count)
        let averageLength = patterns.map { $0.averageMessageLength }.reduce(0, +) / Double(patterns.count)
        
        return MessageFrequencyAnalysis(
            messagesPerHour: averageMessages,
            averageLength: averageLength,
            contentVariety: calculateContentVariety(patterns)
        )
    }
    
    private func analyzeInteractionTiming(_ patterns: [InteractionPattern]) -> InteractionTimingAnalysis {
        let averageDelay = patterns.map { $0.responseDelay }.reduce(0, +) / Double(patterns.count)
        let typicalHours = patterns.map { $0.activeHour }.reduce(into: Set<Int>()) { $0.insert($1) }
        
        return InteractionTimingAnalysis(
            averageResponseDelay: averageDelay,
            typicalActiveHours: Array(typicalHours),
            sessionDuration: calculateAverageSessionDuration(patterns)
        )
    }
    
    private func analyzeContentPatterns(_ activities: [UserActivity]) -> ContentPatternAnalysis {
        let contentTypes = activities.compactMap { $0.contentType }
        let contentSizes = activities.compactMap { $0.contentSize }
        
        return ContentPatternAnalysis(
            typicalContentTypes: Array(Set(contentTypes)),
            averageContentSize: contentSizes.reduce(0, +) / Double(contentSizes.count),
            contentVariety: Double(Set(contentTypes).count) / Double(contentTypes.count)
        )
    }
    
    private func identifyPeakHours(_ activities: [UserActivity]) -> [Int] {
        let hourCounts = activities.reduce(into: [Int: Int]()) { counts, activity in
            let hour = Calendar.current.component(.hour, from: activity.timestamp)
            counts[hour, default: 0] += 1
        }
        
        let averageCount = Double(hourCounts.values.reduce(0, +)) / Double(hourCounts.count)
        
        return hourCounts.compactMap { hour, count in
            count > Int(averageCount * 1.5) ? hour : nil
        }.sorted()
    }
    
    private func calculateAverageSessionLength(_ activities: [UserActivity]) -> TimeInterval {
        // 簡化實現：計算相鄰活動的時間間隔
        let intervals = zip(activities, activities.dropFirst()).map { 
            $1.timestamp.timeIntervalSince($0.timestamp) 
        }
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    private func calculateActivityDistribution(_ activities: [UserActivity]) -> ActivityDistribution {
        let totalActivities = activities.count
        let messageCount = activities.filter { $0.type == .message }.count
        let connectionCount = activities.filter { $0.type == .connection }.count
        let discoveryCount = activities.filter { $0.type == .discovery }.count
        
        return ActivityDistribution(
            messageRatio: Double(messageCount) / Double(totalActivities),
            connectionRatio: Double(connectionCount) / Double(totalActivities),
            discoveryRatio: Double(discoveryCount) / Double(totalActivities)
        )
    }
    
    private func calculateFluctuationTrend(_ fluctuations: [Double]) -> FluctuationTrend {
        guard fluctuations.count > 1 else { return .stable }
        
        let recentFluctuations = Array(fluctuations.suffix(10))
        let earlyFluctuations = Array(fluctuations.prefix(10))
        
        let recentAverage = recentFluctuations.reduce(0, +) / Double(recentFluctuations.count)
        let earlyAverage = earlyFluctuations.reduce(0, +) / Double(earlyFluctuations.count)
        
        if recentAverage > earlyAverage * 1.2 {
            return .increasing
        } else if recentAverage < earlyAverage * 0.8 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func calculateStabilityScore(_ fluctuations: [Double]) -> Double {
        let averageFluctuation = fluctuations.reduce(0, +) / Double(fluctuations.count)
        let maxFluctuation = fluctuations.max() ?? 0
        
        // 穩定性評分：越小的波動表示越穩定
        return max(0, 1 - (averageFluctuation / max(maxFluctuation, 1)))
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        return values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    }
    
    private func calculateContentVariety(_ patterns: [MessagePattern]) -> Double {
        // 計算內容多樣性
        let allContentTypes = patterns.flatMap { $0.contentTypes }
        let uniqueTypes = Set(allContentTypes)
        return Double(uniqueTypes.count) / Double(allContentTypes.count)
    }
    
    private func calculateAverageSessionDuration(_ patterns: [InteractionPattern]) -> TimeInterval {
        let durations = patterns.map { $0.sessionDuration }
        return durations.reduce(0, +) / Double(durations.count)
    }
}

// MARK: - Supporting Classes
class BehaviorAnalyzer {
    func detectAnomaly(_ activity: UserActivity, baseline: BehaviorPatterns) -> BehaviorAnomalyResult {
        var anomalyScore = 0.0
        var anomalyReasons: [String] = []
        
        // 連接模式異常檢測
        if let connectionPattern = activity.connectionPattern {
            if connectionPattern.connectionsPerHour > baseline.connectionFrequency.average * 2 {
                anomalyScore += 0.3
                anomalyReasons.append("連接頻率異常")
            }
        }
        
        // 消息模式異常檢測
        if let messagePattern = activity.messagePattern {
            if messagePattern.messagesPerHour > baseline.messageFrequency.messagesPerHour * 2 {
                anomalyScore += 0.3
                anomalyReasons.append("消息頻率異常")
            }
        }
        
        // 內容模式異常檢測
        if let contentSize = activity.contentSize {
            if contentSize > baseline.contentPatterns.averageContentSize * 3 {
                anomalyScore += 0.2
                anomalyReasons.append("內容大小異常")
            }
        }
        
        // 時間模式異常檢測
        let currentHour = Calendar.current.component(.hour, from: activity.timestamp)
        if !baseline.interactionTiming.typicalActiveHours.contains(currentHour) {
            anomalyScore += 0.2
            anomalyReasons.append("活動時間異常")
        }
        
        return BehaviorAnomalyResult(
            isAnomalous: anomalyScore > 0.5,
            anomalyScore: anomalyScore,
            anomalyReasons: anomalyReasons
        )
    }
}

class TrustCalculator {
    func calculateTrustScore(_ activity: UserActivity) -> Double {
        var baseScore = 50.0
        
        // 根據活動類型調整分數
        switch activity.type {
        case .message:
            baseScore += 10.0
        case .connection:
            baseScore += 5.0
        case .discovery:
            baseScore += 3.0
        case .system:
            baseScore += 1.0
        }
        
        // 根據活動品質調整分數
        if activity.isSuccessful {
            baseScore += 10.0
        } else {
            baseScore -= 15.0
        }
        
        // 根據時間因素調整分數
        let timeSinceActivity = Date().timeIntervalSince(activity.timestamp)
        if timeSinceActivity < 3600 { // 1小時內
            baseScore += 5.0
        }
        
        return max(0, min(100, baseScore))
    }
}

class AnomalyDetector {
    func detectStatisticalAnomalies(_ data: [Double]) -> [StatisticalAnomaly] {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let standardDeviation = sqrt(variance)
        
        return data.enumerated().compactMap { index, value in
            let zScore = abs(value - mean) / standardDeviation
            if zScore > 2.0 { // 超過2個標準差
                return StatisticalAnomaly(
                    index: index,
                    value: value,
                    zScore: zScore,
                    severity: zScore > 3.0 ? .high : .medium
                )
            }
            return nil
        }
    }
}

// MARK: - Singleton Stores
class TrustBaselineStore {
    static let shared = TrustBaselineStore()
    private var baselines: [String: TrustBaseline] = [:]
    private let queue = DispatchQueue(label: "com.signalair.trustbaseline", qos: .utility)
    
    func getBaseline(for userID: String) -> TrustBaseline? {
        return queue.sync { baselines[userID] }
    }
    
    func setBaseline(_ baseline: TrustBaseline, for userID: String) {
        queue.sync { baselines[userID] = baseline }
    }
}

class ActivityDatabase {
    static let shared = ActivityDatabase()
    private var activities: [String: [UserActivity]] = [:]
    private let queue = DispatchQueue(label: "com.signalair.activitydb", qos: .utility)
    
    func getActivities(for userID: String, since date: Date) -> [UserActivity] {
        return queue.sync {
            activities[userID]?.filter { $0.timestamp >= date } ?? []
        }
    }
    
    func recordActivity(_ activity: UserActivity, for userID: String) {
        queue.sync {
            activities[userID, default: []].append(activity)
            
            // 保持最近1000條記錄
            if activities[userID]!.count > 1000 {
                activities[userID]! = Array(activities[userID]!.suffix(1000))
            }
        }
    }
}