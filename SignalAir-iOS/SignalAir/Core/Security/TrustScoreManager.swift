import Foundation
import SwiftUI
import Combine

// MARK: - Trust Score Manager
/// 信任評分管理器 - 基於 DeviceUUID 的行為信譽追蹤系統
class TrustScoreManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var trustScores: [String: TrustScore] = [:]
    @Published private(set) var localBlacklist: Set<String> = []
    @Published private(set) var observationList: Set<String> = []
    @Published private(set) var bloomFilter: BloomFilter?
    
    // MARK: - Configuration
    private let keychainService = "com.signalair.trustscore"
    private let userDefaultsKey = "trust_scores"
    private let blacklistKey = "local_blacklist"
    private let observationKey = "observation_list"
    private let bloomFilterKey = "bloom_filter"
    
    // MARK: - Async Processing Configuration
    @AppStorage("useAsyncTrustProcessing") private var useAsyncProcessing: Bool = false
    private let asyncQueue = DispatchQueue(label: "com.signalair.trustscore.async", qos: .utility)
    private let batchQueue = DispatchQueue(label: "com.signalair.trustscore.batch", qos: .background)
    private var pendingUpdates: [String: PendingTrustUpdate] = [:]
    private let batchProcessingInterval: TimeInterval = 0.5
    private var batchTimer: Timer?
    
    // MARK: - 批次儲存配置 (減少JSON開銷)
    private var pendingSaveDevices: Set<String> = []          // 待儲存的設備ID
    private var lastSaveTime: Date = Date()                   // 上次儲存時間
    private let batchSaveInterval: TimeInterval = 5.0         // 批次儲存間隔 (5秒)
    private let maxPendingSaveCount: Int = 20                 // 最大待儲存數量
    private var batchSaveTimer: Timer?                        // 批次儲存計時器
    private let saveQueue = DispatchQueue(label: "com.signalair.trustscore.save", qos: .background)
    
    // MARK: - Trust Score Parameters
    private let initialTrustScore: Double = 50.0
    
    // MARK: - 🚀 Warmup階段參數 (新增)
    private let warmupDuration: TimeInterval = 5 * 60        // 5分鐘寬容期
    private let validationDuration: TimeInterval = 10 * 60   // 10分鐘驗證期
    private let bufferDuration: TimeInterval = 2 * 60        // 2分鐘緩衝期
    private let warmupRiskThreshold: Int = 3                 // 風險提示閾值
    private let warmupMaxBroadcast: Int = 30                 // 每分鐘最大廣播
    private let warmupMaxWrites: Int = 5                     // 每分鐘最大寫入
    private let riskDecayInterval: TimeInterval = 30 * 60    // 30分鐘風險衰退
    private let validInteractionThreshold: Int = 3           // 有效互動解鎖閾值
    
    // MARK: - 🧠 行為型輪廓學習參數 (新增)
    private let behaviorAnalysisWindow: TimeInterval = 15 * 60  // 15分鐘行為分析窗口
    private let contentDiversityThreshold: Double = 0.7        // 內容多樣性閾值
    private let interactionRhythmWeight: Double = 1.5           // 互動節奏權重
    private let helpSeekingWeight: Double = 2.0                // 求助行為權重
    private let socialEngagementWeight: Double = 1.8           // 社交參與權重
    private let maxTrustScore: Double = 100.0
    private let minTrustScore: Double = 0.0
    private let blacklistThreshold: Double = 20.0
    private let observationThreshold: Double = 30.0
    
    // MARK: - Cleanup Configuration
    private let maxRecordsCount = 10000
    private let cleanupInterval: TimeInterval = 86400 // 24 hours
    private var cleanupTimer: Timer?
    
    // MARK: - Performance Optimization
    private lazy var trustCacheOptimizer = TrustCacheOptimizer()
    // HybridPerformanceEngine 將由 ServiceContainer 管理，避免 Swift 6 兼容性問題
    
    // MARK: - Initialization
    init() {
        loadStoredData()
        setupBloomFilter()
        startCleanupTimer()
        startBatchProcessingTimer()
        startBatchSaveTimer()
        print("📊 TrustScoreManager: 初始化完成 (異步處理: \(useAsyncProcessing ? "啟用" : "停用"))")
    }
    
    deinit {
        cleanupTimer?.invalidate()
        batchTimer?.invalidate()
        batchSaveTimer?.invalidate()
        // 確保所有待儲存的數據都被儲存
        performBatchSave(force: true)
    }
    
    // MARK: - Public Methods
    
    /// 獲取節點的信任評分（帶緩存優化）
    func getTrustScore(for deviceUUID: String) -> Double {
        // 🚀 嘗試從緩存獲取
        if let cached = trustCacheOptimizer.getCachedTrust(for: deviceUUID) {
            return Double(cached.score)
        }
        
        // 緩存未命中，從存儲獲取
        let score = trustScores[deviceUUID]?.currentScore ?? initialTrustScore
        
        // 更新緩存
        let threatLevel = determineThreatLevel(score: score)
        trustCacheOptimizer.updateCache(
            peer: deviceUUID, 
            score: Float(score), 
            threat: threatLevel, 
            behavior: []
        )
        
        return score
    }
    
    /// 確定威脅級別
    private func determineThreatLevel(score: Double) -> String {
        switch score {
        case 0..<20: return "high"
        case 20..<40: return "medium"  
        case 40..<70: return "low"
        default: return "minimal"
        }
    }
    
    /// 獲取節點的詳細信任資訊
    func getTrustInfo(for deviceUUID: String) -> TrustScore {
        return trustScores[deviceUUID] ?? TrustScore(
            deviceUUID: deviceUUID,
            currentScore: initialTrustScore,
            createdAt: Date(),
            lastUpdated: Date(),
            firstConnectionTime: Date(),      // 🚀 新增
            lastResetTime: Date()            // 🚀 新增
        )
    }
    
    // MARK: - 🚀 Warmup階段邏輯 (新增)
    
    /// 檢查設備是否在warmup階段
    private func isInWarmupPhase(for deviceUUID: String) -> Bool {
        guard let trustScore = trustScores[deviceUUID] else { return true }
        let accountAge = Date().timeIntervalSince(trustScore.firstConnectionTime)
        return accountAge < warmupDuration
    }
    
    /// 檢查設備是否在驗證階段
    private func isInValidationPhase(for deviceUUID: String) -> Bool {
        guard let trustScore = trustScores[deviceUUID] else { return false }
        let accountAge = Date().timeIntervalSince(trustScore.firstConnectionTime)
        return accountAge >= warmupDuration && accountAge < validationDuration
    }
    
    /// 🚀 緩衝區懲罰檢查：考慮最近有效互動
    private func checkBufferZonePenalty(trustScore: TrustScore) -> Bool {
        let warmupEndTime = trustScore.firstConnectionTime.addingTimeInterval(warmupDuration)
        let now = Date()
        
        // 如果剛過warmup期不久，檢查是否有緩衝期內的有效互動
        if now.timeIntervalSince(warmupEndTime) < bufferDuration {
            if let lastValidInteraction = trustScore.lastValidInteractionTime,
               lastValidInteraction > warmupEndTime {
                return false  // 有緩衝期內的有效互動，暫緩懲罰
            }
        }
        
        return true  // 執行懲罰
    }
    
    /// 🚀 自動風險衰退機制
    private func applyRiskDecay(for deviceUUID: String) {
        guard var trustScore = trustScores[deviceUUID] else { return }
        
        let timeSinceLastDecay = Date().timeIntervalSince(trustScore.lastRiskDecayTime)
        
        if timeSinceLastDecay >= riskDecayInterval && trustScore.riskHint > 0 {
            trustScore.riskHint = max(0, trustScore.riskHint - 1)
            trustScore.lastRiskDecayTime = Date()
            trustScores[deviceUUID] = trustScore
            
            print("⏰ TrustScoreManager: 自動風險衰退 - \(deviceUUID) (riskHint: \(trustScore.riskHint))")
        }
    }
    
    /// 🚀 訊息相似度檢測（避免誤判重複但合理的訊息）
    private func calculateMessageSimilarity(_ message1: String, _ message2: String) -> Double {
        let words1 = Set(message1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(message2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    /// 🚀 智慧重複檢測（容忍合理的重複）
    func recordSmartBroadcast(for deviceUUID: String, messageContent: String) -> Bool {
        var trustScore = getTrustInfo(for: deviceUUID)
        
        // 自動風險衰退
        applyRiskDecay(for: deviceUUID)
        
        // 計算訊息雜湊
        let messageHash = String(messageContent.hashValue)
        
        // 檢查是否為高相似度重複（>95%相似視為重複）
        let isDuplicate = trustScore.recentMessageHashes.contains { hash in
            // 簡化版：直接比較hash，實際可加入更複雜的相似度算法
            return hash == messageHash
        }
        
        // 更新訊息雜湊記錄（保留最近10條）
        trustScore.recentMessageHashes.append(messageHash)
        if trustScore.recentMessageHashes.count > 10 {
            trustScore.recentMessageHashes.removeFirst()
        }
        
        // 重複訊息不計入廣播計數（避免誤判語音助理等場景）
        if !isDuplicate {
            return recordBroadcast(for: deviceUUID)
        } else {
            print("🔄 TrustScoreManager: 忽略重複訊息 - \(deviceUUID)")
            trustScores[deviceUUID] = trustScore
            return true  // 允許但不計數
        }
    }
    
    /// 🚀 獲取用戶友善提示訊息
    func getUserFriendlyHint(for deviceUUID: String) -> String? {
        guard let trustScore = trustScores[deviceUUID] else { return nil }
        
        let _ = Date().timeIntervalSince(trustScore.firstConnectionTime)
        
        if isInWarmupPhase(for: deviceUUID) {
            if trustScore.riskHint > 0 {
                return "⚠️ 系統正在觀察您的操作模式，短時間內頻繁操作將不會扣分，但可能會影響後續連線品質。建議您稍等數秒再次嘗試。"
            }
        } else if isInValidationPhase(for: deviceUUID) {
            if trustScore.riskHint > warmupRiskThreshold {
                if trustScore.validInteractionCount < validInteractionThreshold {
                    return "💬 為了確保您的連線品質，請嘗試發送一些聊天訊息或救援信號來證明您是正常使用者。"
                }
            }
        } else if trustScore.currentScore < 50 {
            return "🔓 您的連線品質正在改善中，繼續正常使用即可恢復完整功能。"
        }
        
        return nil  // 無需提示
    }
    
    /// 🚀 檢查是否需要顯示提示
    func shouldShowHint(for deviceUUID: String) -> Bool {
        return getUserFriendlyHint(for: deviceUUID) != nil
    }
    
    // MARK: - 🧠 行為型輪廓學習方法
    
    /// 🧠 分析並記錄智慧互動（包含行為學習）
    func recordIntelligentInteraction(for deviceUUID: String, messageContent: String, interactionType: InteractionType) {
        var trustScore = getTrustInfo(for: deviceUUID)
        
        // 檢查臨時黑名單
        if trustScore.behaviorProfile.isTemporarilyBlacklisted {
            print("🚫 TrustScoreManager: 設備在臨時黑名單中 - \(deviceUUID)")
            return
        }
        
        // 更新行為輪廓
        updateBehaviorProfile(&trustScore.behaviorProfile, content: messageContent, type: interactionType)
        
        // 計算行為善意加成
        let benevolenceBonus = calculateBenevolenceBonus(profile: trustScore.behaviorProfile)
        
        // 基礎有效互動處理
        trustScore.hasValidInteraction = true
        trustScore.lastValidInteractionTime = Date()
        trustScore.validInteractionCount += 1
        
        // 🧠 智慧風險衰退：根據行為善意調整
        if trustScore.riskHint > 0 {
            let decayAmount = benevolenceBonus > 0.7 ? 2 : 1  // 高善意雙倍衰退
            trustScore.riskHint = max(0, trustScore.riskHint - decayAmount)
            print("🧠 TrustScoreManager: 智慧風險衰退 - \(deviceUUID) (riskHint: \(trustScore.riskHint), 善意: \(String(format: "%.2f", benevolenceBonus)))")
        }
        
        // 🧠 智慧解鎖：根據行為模式調整
        let intelligentThreshold = max(1, Int(Double(validInteractionThreshold) * (1.0 - benevolenceBonus)))
        if trustScore.validInteractionCount >= intelligentThreshold && trustScore.currentScore < 50 {
            let bonusScore = 5.0 + (benevolenceBonus * 10.0)  // 最多額外10分
            trustScore.currentScore = min(50.0, trustScore.currentScore + bonusScore)
            print("🧠 TrustScoreManager: 智慧解鎖信任提升 - \(deviceUUID) (分數: \(trustScore.currentScore), 加成: \(String(format: "%.1f", bonusScore)))")
        }
        
        trustScores[deviceUUID] = trustScore
        print("✅ TrustScoreManager: 智慧互動記錄 - \(deviceUUID) (善意評分: \(String(format: "%.2f", benevolenceBonus)))")
    }
    
    /// 🧠 更新行為輪廓
    private func updateBehaviorProfile(_ profile: inout BehaviorProfile, content: String, type: InteractionType) {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        
        // 1. 內容多樣性分析
        updateContentDiversity(&profile, content: content)
        
        // 2. 互動節奏分析
        updateInteractionRhythm(&profile, timestamp: now)
        
        // 3. 求助行為分析
        updateHelpSeekingBehavior(&profile, content: content, type: type)
        
        // 4. 社交參與分析
        updateSocialEngagement(&profile, content: content, type: type)
        
        // 5. 學習行為分析
        updateLearningBehavior(&profile, content: content, type: type)
        
        // 6. 時間模式分析
        profile.activeHours.insert(currentHour)
        updateTemporalPattern(&profile)
        
        profile.lastAnalysisTime = now
    }
    
    /// 🧠 計算行為善意加成 (0.0-1.0)
    private func calculateBenevolenceBonus(profile: BehaviorProfile) -> Double {
        let baseScore = profile.overallBenevolenceScore
        
        // 特殊加成條件
        var bonus = baseScore
        
        // 求助行為加成
        if profile.helpSeekingCount > 0 {
            bonus += 0.2
        }
        
        // 社交參與加成
        if profile.mentionUsage > 0 || profile.responseCount > 0 {
            bonus += 0.15
        }
        
        // 內容多樣性加成
        if profile.contentDiversityScore > contentDiversityThreshold {
            bonus += 0.1
        }
        
        // 時間模式加成（人類模式）
        if profile.temporalPattern == .human {
            bonus += 0.1
        }
        
        return min(1.0, bonus)
    }
    
    /// 🧠 內容多樣性更新
    private func updateContentDiversity(_ profile: inout BehaviorProfile, content: String) {
        // 添加到最近內容
        profile.messageContents.append(content)
        if profile.messageContents.count > 20 {
            profile.messageContents.removeFirst()
        }
        
        // 分析詞彙多樣性
        let words = Set(content.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 1 })
        
        profile.uniqueWords.formUnion(words)
        
        // 計算多樣性評分
        let totalWords = profile.messageContents.flatMap {
            $0.lowercased().components(separatedBy: .whitespacesAndNewlines)
        }.count
        
        profile.contentDiversityScore = totalWords > 0 ?
            Double(profile.uniqueWords.count) / Double(totalWords) : 0.0
    }
    
    /// 🧠 互動節奏更新
    private func updateInteractionRhythm(_ profile: inout BehaviorProfile, timestamp: Date) {
        profile.interactionTimestamps.append(timestamp)
        if profile.interactionTimestamps.count > 50 {
            profile.interactionTimestamps.removeFirst()
        }
        
        guard profile.interactionTimestamps.count >= 3 else { return }
        
        // 計算平均間隔
        let intervals = zip(profile.interactionTimestamps.dropLast(), profile.interactionTimestamps.dropFirst())
            .map { $1.timeIntervalSince($0) }
        
        profile.averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        // 計算節奏一致性（標準差的倒數）
        let variance = intervals.map { pow($0 - profile.averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        
        // 人類行為：有一定變異但不會太極端
        profile.rhythmConsistency = standardDeviation > 0 ? 
            min(1.0, 1.0 / (1.0 + standardDeviation / 60.0)) : 0.5
    }
    
    /// 🧠 求助行為更新
    private func updateHelpSeekingBehavior(_ profile: inout BehaviorProfile, content: String, type: InteractionType) {
        let lowerContent = content.lowercased()
        let hasHelpKeyword = profile.helpKeywords.contains { lowerContent.contains($0) }
        
        if hasHelpKeyword || type == .emergency {
            profile.helpSeekingCount += 1
        }
        
        profile.helpSeekingScore = min(1.0, Double(profile.helpSeekingCount) * helpSeekingWeight / 10.0)
    }
    
    /// 🧠 社交參與更新
    private func updateSocialEngagement(_ profile: inout BehaviorProfile, content: String, type: InteractionType) {
        if content.contains("@") {
            profile.mentionUsage += 1
        }
        
        if type == .response {
            profile.responseCount += 1
        }
        
        let totalEngagement = Double(profile.mentionUsage + profile.responseCount)
        profile.socialEngagementScore = min(1.0, totalEngagement * socialEngagementWeight / 20.0)
    }
    
    /// 🧠 學習行為更新
    private func updateLearningBehavior(_ profile: inout BehaviorProfile, content: String, type: InteractionType) {
        let lowerContent = content.lowercased()
        
        // 檢測學習行為模式
        if lowerContent.contains("怎麼") || lowerContent.contains("如何") || lowerContent.contains("?") || lowerContent.contains("？") {
            profile.learningBehaviors.append(.asking)
        }
        
        if type == .testing {
            profile.learningBehaviors.append(.experimenting)
        }
        
        // 保留最近50個學習行為
        if profile.learningBehaviors.count > 50 {
            profile.learningBehaviors.removeFirst()
        }
        
        // 計算適應評分
        let diversityCount = Set(profile.learningBehaviors.map { $0.rawValue }).count
        profile.adaptationScore = min(1.0, Double(diversityCount) / 5.0)
    }
    
    /// 🧠 時間模式更新
    private func updateTemporalPattern(_ profile: inout BehaviorProfile) {
        guard profile.interactionTimestamps.count >= 10 else {
            profile.temporalPattern = .unknown
            return
        }
        
        let intervals = zip(profile.interactionTimestamps.dropLast(), profile.interactionTimestamps.dropFirst())
            .map { $1.timeIntervalSince($0) }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        
        // 模式判斷
        if standardDeviation < 5.0 && avgInterval < 2.0 {
            profile.temporalPattern = .automated  // 太規律太快
        } else if standardDeviation < 10.0 && avgInterval > 60.0 {
            profile.temporalPattern = .consistent  // 規律但合理
        } else if avgInterval < 5.0 && intervals.filter({ $0 < 1.0 }).count > intervals.count / 2 {
            profile.temporalPattern = .bursty     // 爆發性
        } else {
            profile.temporalPattern = .human      // 人類模式
        }
    }
    
    /// 🚫 臨時黑名單檢查和執行
    func checkTemporaryBlacklist(for deviceUUID: String) -> Bool {
        var trustScore = getTrustInfo(for: deviceUUID)
        
        // 🔧 初期寬容機制：新用戶前2分鐘不進入黑名單（除非極度危險）
        let now = Date()
        let timeSinceFirstSeen = now.timeIntervalSince(trustScore.firstConnectionTime)
        let isNewUser = timeSinceFirstSeen < 120.0  // 前2分鐘
        
        // 🔧 放寬黑名單條件，增加寬容度
        let isExtremelyDangerous = trustScore.riskHint > 25 || trustScore.currentScore < 2
        let isModeratelyRisky = trustScore.riskHint > 15 || trustScore.currentScore < 5
        
        let shouldBlacklist = if isNewUser {
            // 新用戶只有極度危險才進黑名單
            isExtremelyDangerous && !trustScore.hasValidInteraction
        } else {
            // 老用戶使用較寬松的條件
            isModeratelyRisky && !trustScore.hasValidInteraction
        }
        
        if shouldBlacklist && !trustScore.behaviorProfile.isTemporarilyBlacklisted {
            // 進入臨時黑名單
            let blacklistDuration = isNewUser ? 2 * 60 : 5 * 60  // 新用戶較短的黑名單時間
            trustScore.behaviorProfile.temporaryBlacklistUntil = Date().addingTimeInterval(TimeInterval(blacklistDuration))
            trustScore.behaviorProfile.blacklistReason = "可疑行為：riskHint=\(trustScore.riskHint), score=\(trustScore.currentScore), 新用戶=\(isNewUser)"
            trustScores[deviceUUID] = trustScore
            
            print("🚫 TrustScoreManager: 設備進入臨時黑名單 - \(deviceUUID) (\(blacklistDuration/60)分鐘)")
            return true
        }
        
        return trustScore.behaviorProfile.isTemporarilyBlacklisted
    }
    
    /// 記錄有效互動（聊天、救援、收到回應）- 🚀 升級版
    func recordValidInteraction(for deviceUUID: String) {
        var trustScore = getTrustInfo(for: deviceUUID)
        trustScore.hasValidInteraction = true
        trustScore.lastValidInteractionTime = Date()
        trustScore.validInteractionCount += 1
        
        // 🚀 風險衰退機制：有效互動減少風險
        if trustScore.riskHint > 0 {
            trustScore.riskHint = max(0, trustScore.riskHint - 1)
            print("🔄 TrustScoreManager: 有效互動降低風險 - \(deviceUUID) (riskHint: \(trustScore.riskHint))")
        }
        
        // 🚀 解鎖機制：足夠的有效互動可以提升信任
        if trustScore.validInteractionCount >= validInteractionThreshold && trustScore.currentScore < 50 {
            trustScore.currentScore = min(50.0, trustScore.currentScore + 5.0)
            print("🔓 TrustScoreManager: 解鎖信任提升 - \(deviceUUID) (分數: \(trustScore.currentScore))")
        }
        
        trustScores[deviceUUID] = trustScore
        print("✅ TrustScoreManager: 記錄有效互動 - \(deviceUUID) (計數: \(trustScore.validInteractionCount))")
    }
    
    /// 記錄廣播行為（warmup友好）
    func recordBroadcast(for deviceUUID: String) -> Bool {
        var trustScore = getTrustInfo(for: deviceUUID)
        
        // 重置計數器（每分鐘）
        if Date().timeIntervalSince(trustScore.lastResetTime) >= 60 {
            trustScore.broadcastCount = 0
            trustScore.writeCount = 0
            trustScore.lastResetTime = Date()
        }
        
        trustScore.broadcastCount += 1
        
        if isInWarmupPhase(for: deviceUUID) {
            // Warmup階段：寬容處理
            if trustScore.broadcastCount > warmupMaxBroadcast {
                trustScore.riskHint += 1
                print("⚠️ TrustScoreManager: Warmup期間廣播過度 - \(deviceUUID) (riskHint: \(trustScore.riskHint))")
                
                // 🚀 緩衝機制：驗證階段檢查時考慮最近的有效互動
                if isInValidationPhase(for: deviceUUID) && trustScore.riskHint > warmupRiskThreshold {
                    let shouldPenalize = checkBufferZonePenalty(trustScore: trustScore)
                    if shouldPenalize {
                        trustScore.currentScore = 19.0  // 降到可疑區
                        print("🔴 TrustScoreManager: 緩衝期後驗證失敗，降級到可疑區 - \(deviceUUID)")
                    } else {
                        print("⏰ TrustScoreManager: 緩衝期內，暫緩懲罰 - \(deviceUUID)")
                    }
                }
            }
            trustScores[deviceUUID] = trustScore
            return trustScore.broadcastCount <= warmupMaxBroadcast
        } else {
            // 正常階段：套用原有邏輯
            trustScores[deviceUUID] = trustScore
            return true  // 讓原有的recordExcessiveBroadcast處理
        }
    }
    
    /// 記錄寫入行為（房間/錯誤請求）
    func recordWrite(for deviceUUID: String) -> Bool {
        var trustScore = getTrustInfo(for: deviceUUID)
        
        // 重置計數器（每分鐘）
        if Date().timeIntervalSince(trustScore.lastResetTime) >= 60 {
            trustScore.broadcastCount = 0
            trustScore.writeCount = 0
            trustScore.lastResetTime = Date()
        }
        
        trustScore.writeCount += 1
        
        if isInWarmupPhase(for: deviceUUID) {
            // Warmup階段：限制寫入
            if trustScore.writeCount > warmupMaxWrites {
                trustScore.riskHint += 1
                print("⚠️ TrustScoreManager: Warmup期間寫入過度 - \(deviceUUID) (riskHint: \(trustScore.riskHint))")
                
                // 驗證階段檢查
                if isInValidationPhase(for: deviceUUID) && trustScore.riskHint > warmupRiskThreshold {
                    trustScore.currentScore = 19.0  // 降到可疑區
                    print("🔴 TrustScoreManager: 驗證階段失敗，降級到可疑區 - \(deviceUUID)")
                }
            }
            trustScores[deviceUUID] = trustScore
            return trustScore.writeCount <= warmupMaxWrites
        } else {
            // 正常階段：允許
            trustScores[deviceUUID] = trustScore
            return true
        }
    }
    
    /// 記錄正常通訊行為
    func recordSuccessfulCommunication(for deviceUUID: String, messageType: TrustMessageType = .general) {
        let increment = calculateScoreIncrement(for: messageType)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: increment, reason: .successfulCommunication)
        } else {
            updateTrustScore(for: deviceUUID, change: increment, reason: .successfulCommunication)
        }
        
        print("✅ TrustScoreManager: 記錄成功通訊 - \(deviceUUID) (+\(increment)) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄異常行為（🚀 Warmup友好版本）
    func recordSuspiciousBehavior(for deviceUUID: String, behavior: SuspiciousBehavior) {
        // 🚀 Warmup階段寬容處理
        if isInWarmupPhase(for: deviceUUID) {
            var trustScore = getTrustInfo(for: deviceUUID)
            trustScore.riskHint += 1
            trustScore.abnormalCount += 1
            
            // 輕微違規不直接扣分，只記錄
            if behavior == .protocolViolation || behavior == .duplicateMessages {
                print("📝 TrustScoreManager: Warmup期間記錄異常 - \(deviceUUID) (riskHint: \(trustScore.riskHint)): \(behavior)")
                
                // 驗證階段檢查
                if isInValidationPhase(for: deviceUUID) && trustScore.riskHint > warmupRiskThreshold {
                    trustScore.currentScore = 19.0  // 降到可疑區
                    print("🔴 TrustScoreManager: 驗證階段失敗，降級到可疑區 - \(deviceUUID)")
                }
                trustScores[deviceUUID] = trustScore
                return
            }
        }
        
        // 正常階段或嚴重違規：套用原有邏輯
        let decrement = calculateScoreDecrement(for: behavior)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .suspiciousBehavior(behavior))
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .suspiciousBehavior(behavior))
        }
        
        print("⚠️ TrustScoreManager: 記錄可疑行為 - \(deviceUUID) (-\(decrement)): \(behavior) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄過度廣播行為
    func recordExcessiveBroadcast(for deviceUUID: String, messageCount: Int, timeWindow: TimeInterval) {
        let severity = calculateBroadcastSeverity(messageCount: messageCount, timeWindow: timeWindow)
        let decrement = severity * 2.0 // 🔧 修復：降低基礎懲罰分數，從5.0降到2.0
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .excessiveBroadcast)
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .excessiveBroadcast)
        }
        
        print("📢 TrustScoreManager: 記錄過度廣播 - \(deviceUUID) (-\(decrement)) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄錯誤封包行為
    func recordMalformedPacket(for deviceUUID: String, errorType: PacketError) {
        let decrement = calculatePacketErrorDecrement(for: errorType)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .malformedPacket(errorType))
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .malformedPacket(errorType))
        }
        
        print("🚫 TrustScoreManager: 記錄錯誤封包 - \(deviceUUID) (-\(decrement)): \(errorType) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 檢查節點是否在本地黑名單中
    func isBlacklisted(_ deviceUUID: String) -> Bool {
        return localBlacklist.contains(deviceUUID)
    }
    
    /// 檢查節點是否在觀察名單中
    func isUnderObservation(_ deviceUUID: String) -> Bool {
        return observationList.contains(deviceUUID)
    }
    
    /// 手動加入黑名單
    func addToBlacklist(_ deviceUUID: String, reason: String) {
        localBlacklist.insert(deviceUUID)
        
        // 更新信任評分為最低
        updateTrustScore(for: deviceUUID, change: -maxTrustScore, reason: .manualBlacklist)
        
        // 添加到 Bloom Filter
        bloomFilter?.add(deviceUUID)
        
        // 🔧 修復: 黑名單操作立即儲存 (安全性優先)
        saveData()
        print("🚫 TrustScoreManager: 手動加入黑名單 - \(deviceUUID): \(reason)")
    }
    
    /// 從黑名單移除
    func removeFromBlacklist(_ deviceUUID: String) {
        localBlacklist.remove(deviceUUID)
        observationList.remove(deviceUUID)
        
        // 重設信任評分
        updateTrustScore(for: deviceUUID, change: initialTrustScore, reason: .manualWhitelist)
        
        // 🔧 修復: 黑名單操作立即儲存 (安全性優先)
        saveData()
        print("✅ TrustScoreManager: 從黑名單移除 - \(deviceUUID)")
    }
    
    /// 獲取信任評分統計
    func getTrustStatistics() -> TrustStatistics {
        let scores = trustScores.values.map { $0.currentScore }
        let totalNodes = scores.count
        let averageScore = totalNodes > 0 ? scores.reduce(0, +) / Double(totalNodes) : 0
        
        let trustedNodes = scores.filter { $0 >= 80 }.count
        let suspiciousNodes = scores.filter { $0 < observationThreshold }.count
        let blacklistedNodes = localBlacklist.count
        
        return TrustStatistics(
            totalNodes: totalNodes,
            averageScore: averageScore,
            trustedNodes: trustedNodes,
            suspiciousNodes: suspiciousNodes,
            blacklistedNodes: blacklistedNodes,
            observationNodes: observationList.count
        )
    }
    
    /// 獲取 Bloom Filter 摘要（用於去中心化黑名單同步）
    func getBloomFilterSummary() -> Data? {
        return bloomFilter?.getData()
    }
    
    /// 切換異步處理模式
    func toggleAsyncProcessing(_ enabled: Bool) {
        useAsyncProcessing = enabled
        print("🔄 TrustScoreManager: 異步處理 \(enabled ? "啟用" : "停用")")
        
        if enabled {
            startBatchProcessingTimer()
        } else {
            batchTimer?.invalidate()
            // 立即處理所有待處理的更新
            processPendingUpdates()
        }
    }
    
    /// 合併其他節點的 Bloom Filter
    func mergeBloomFilter(_ filterData: Data) {
        guard let otherFilter = BloomFilter(data: filterData) else {
            print("❌ TrustScoreManager: 無效的 Bloom Filter 資料")
            return
        }
        
        bloomFilter?.merge(with: otherFilter)
        print("🔄 TrustScoreManager: 合併 Bloom Filter 完成")
    }
    
    /// 清理過期記錄
    func performCleanup() {
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
        var removedCount = 0
        
        // 清理過期的信任評分記錄
        for (deviceUUID, trustScore) in trustScores {
            if trustScore.lastUpdated < cutoffDate {
                trustScores.removeValue(forKey: deviceUUID)
                removedCount += 1
            }
        }
        
        // 限制記錄數量
        if trustScores.count > maxRecordsCount {
            let sortedScores = trustScores.sorted { $0.value.lastUpdated < $1.value.lastUpdated }
            let toRemove = sortedScores.prefix(trustScores.count - maxRecordsCount)
            
            for (deviceUUID, _) in toRemove {
                trustScores.removeValue(forKey: deviceUUID)
                removedCount += 1
            }
        }
        
        // 🔧 修復: 清理後使用批次儲存
        if removedCount > 0 {
            performBatchSave(force: true)
        }
        print("🧹 TrustScoreManager: 清理了 \(removedCount) 個過期記錄")
    }
    
    // MARK: - Private Methods
    
    /// 異步更新信任評分
    private func updateTrustScoreAsync(for deviceUUID: String, change: Double, reason: ScoreChangeReason) {
        // 高優先級更新（黑名單相關）立即處理
        if case .suspiciousBehavior(let behavior) = reason,
           [.invalidSignature, .inappropriateContent].contains(behavior) {
            asyncQueue.async { [weak self] in
                self?.updateTrustScore(for: deviceUUID, change: change, reason: reason)
            }
            return
        }
        
        // 其他更新加入批次處理佇列
        let update = PendingTrustUpdate(
            deviceUUID: deviceUUID,
            change: change,
            reason: reason,
            timestamp: Date(),
            priority: determinePriority(for: reason)
        )
        
        batchQueue.async { [weak self] in
            self?.addToPendingUpdates(update)
        }
    }
    
    /// 同步更新信任評分（原有方法）
    private func updateTrustScore(for deviceUUID: String, change: Double, reason: ScoreChangeReason) {
        var trustScore = trustScores[deviceUUID] ?? TrustScore(
            deviceUUID: deviceUUID,
            currentScore: initialTrustScore,
            createdAt: Date(),
            lastUpdated: Date(),
            firstConnectionTime: Date(),      // 🚀 新增
            lastResetTime: Date()            // 🚀 新增
        )
        
        // 應用分數變化
        trustScore.currentScore = max(minTrustScore, min(maxTrustScore, trustScore.currentScore + change))
        trustScore.lastUpdated = Date()
        trustScore.updateCount += 1
        
        // 記錄歷史
        let historyEntry = ScoreHistory(
            timestamp: Date(),
            change: change,
            reason: reason,
            resultingScore: trustScore.currentScore
        )
        trustScore.history.append(historyEntry)
        
        // 限制歷史記錄數量
        if trustScore.history.count > 100 {
            trustScore.history.removeFirst(trustScore.history.count - 100)
        }
        
        trustScores[deviceUUID] = trustScore
        
        // 檢查是否需要加入觀察名單或黑名單
        updateNodeStatus(deviceUUID, score: trustScore.currentScore)
        
        // 🔧 修復: 使用批次儲存替代即時儲存
        markForBatchSave(deviceUUID)
    }
    
    /// 更新節點狀態（觀察名單/黑名單）
    private func updateNodeStatus(_ deviceUUID: String, score: Double) {
        if score < blacklistThreshold {
            // 加入黑名單
            if !localBlacklist.contains(deviceUUID) {
                localBlacklist.insert(deviceUUID)
                bloomFilter?.add(deviceUUID)
                print("🚫 TrustScoreManager: 自動加入黑名單 - \(deviceUUID) (分數: \(score))")
            }
        } else if score < observationThreshold {
            // 加入觀察名單
            if !observationList.contains(deviceUUID) {
                observationList.insert(deviceUUID)
                print("👁️ TrustScoreManager: 加入觀察名單 - \(deviceUUID) (分數: \(score))")
            }
        } else {
            // 移出觀察名單（但不自動移出黑名單）
            observationList.remove(deviceUUID)
        }
    }
    
    /// 計算分數增量
    private func calculateScoreIncrement(for messageType: TrustMessageType) -> Double {
        switch messageType {
        case .emergency:
            return 2.0
        case .general:
            return 1.0
        case .heartbeat:
            return 0.5
        case .system:
            return 1.5
        }
    }
    
    /// 計算分數減量
    private func calculateScoreDecrement(for behavior: SuspiciousBehavior) -> Double {
        switch behavior {
        case .duplicateMessages:
            return 3.0
        case .invalidSignature:
            return 10.0
        case .timestampManipulation:
            return 8.0
        case .excessiveRetransmission:
            return 4.0
        case .protocolViolation:
            return 0.1  // 🔧 修復：進一步降低懲罰，避免同版本設備被誤標記
        case .inappropriateContent:
            return 15.0
        }
    }
    
    /// 計算廣播嚴重程度（調整為對測試更友善）
    private func calculateBroadcastSeverity(messageCount: Int, timeWindow: TimeInterval) -> Double {
        let messagesPerMinute = Double(messageCount) / (timeWindow / 60.0)
        
        // 🔧 修復：提高閾值，讓測試時的快速點擊不會被標記為可疑
        switch messagesPerMinute {
        case 0..<30:    // 從10提高到30
            return 0.5    // 降低懲罰
        case 30..<60:   // 從20提高到60
            return 1.0    // 降低懲罰
        case 60..<120:  // 從50提高到120
            return 2.0    // 降低懲罰
        default:
            return 4.0    // 從8降低到4
        }
    }
    
    /// 計算封包錯誤減量
    private func calculatePacketErrorDecrement(for error: PacketError) -> Double {
        switch error {
        case .invalidFormat:
            return 3.0
        case .corruptedData:
            return 5.0
        case .unsupportedVersion:
            return 2.0
        case .invalidChecksum:
            return 4.0
        case .oversizedPacket:
            return 3.0
        }
    }
    
    /// Keychain 安全儲存
    private func storeInKeychain(data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        // 刪除現有項目
        SecItemDelete(query as CFDictionary)
        
        // 添加新項目
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 從 Keychain 讀取資料
    private func retrieveFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    /// 設置 Bloom Filter
    private func setupBloomFilter() {
        if let data = UserDefaults.standard.data(forKey: bloomFilterKey),
           let filter = BloomFilter(data: data) {
            bloomFilter = filter
        } else {
            bloomFilter = BloomFilter(expectedElements: 10000, falsePositiveRate: 0.01)
        }
    }
    
    /// 啟動清理定時器
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.performCleanup()
            }
        }
    }
    
    /// 載入儲存的資料
    private func loadStoredData() {
        // 載入信任評分 (從 Keychain)
        if let data = retrieveFromKeychain(key: userDefaultsKey),
           let scores = try? JSONDecoder().decode([String: TrustScore].self, from: data) {
            trustScores = scores
        } else if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
                  let scores = try? JSONDecoder().decode([String: TrustScore].self, from: data) {
            // 遷移舊資料到 Keychain
            trustScores = scores
            if let encodedData = try? JSONEncoder().encode(scores) {
                _ = storeInKeychain(data: encodedData, key: userDefaultsKey)
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
        }
        
        // 載入黑名單 (敏感資料也移至 Keychain)
        if let data = retrieveFromKeychain(key: blacklistKey),
           let blacklistArray = try? JSONDecoder().decode([String].self, from: data) {
            localBlacklist = Set(blacklistArray)
        } else if let blacklistArray = UserDefaults.standard.array(forKey: blacklistKey) as? [String] {
            localBlacklist = Set(blacklistArray)
            if let encodedData = try? JSONEncoder().encode(blacklistArray) {
                _ = storeInKeychain(data: encodedData, key: blacklistKey)
                UserDefaults.standard.removeObject(forKey: blacklistKey)
            }
        }
        
        // 載入觀察名單
        if let observationArray = UserDefaults.standard.array(forKey: observationKey) as? [String] {
            observationList = Set(observationArray)
        }
        
        print("📥 TrustScoreManager: 載入 \(trustScores.count) 個信任評分記錄")
    }
    
    /// 儲存資料
    private func saveData() {
        // 儲存信任評分 (到 Keychain)
        if let data = try? JSONEncoder().encode(trustScores) {
            if !storeInKeychain(data: data, key: userDefaultsKey) {
                print("⚠️ 儲存信任評分到 Keychain 失敗，回退到 UserDefaults")
                UserDefaults.standard.set(data, forKey: userDefaultsKey)
            }
        }
        
        // 儲存黑名單 (到 Keychain)
        if let data = try? JSONEncoder().encode(Array(localBlacklist)) {
            if !storeInKeychain(data: data, key: blacklistKey) {
                print("⚠️ 儲存黑名單到 Keychain 失敗，回退到 UserDefaults")
                UserDefaults.standard.set(Array(localBlacklist), forKey: blacklistKey)
            }
        }
        
        // 儲存觀察名單 (保留在 UserDefaults，非敏感資料)
        UserDefaults.standard.set(Array(observationList), forKey: observationKey)
        
        // 儲存 Bloom Filter
        if let filterData = bloomFilter?.getData() {
            UserDefaults.standard.set(filterData, forKey: bloomFilterKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// 添加到待處理更新佇列
    private func addToPendingUpdates(_ update: PendingTrustUpdate) {
        let key = update.deviceUUID
        
        if let existing = pendingUpdates[key] {
            // 合併相同裝置的更新
            let mergedUpdate = PendingTrustUpdate(
                deviceUUID: key,
                change: existing.change + update.change,
                reason: update.priority.rawValue > existing.priority.rawValue ? update.reason : existing.reason,
                timestamp: max(existing.timestamp, update.timestamp),
                priority: update.priority.rawValue > existing.priority.rawValue ? update.priority : existing.priority
            )
            pendingUpdates[key] = mergedUpdate
        } else {
            pendingUpdates[key] = update
        }
    }
    
    /// 處理待處理的更新
    private func processPendingUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = Array(pendingUpdates.values).sorted { $0.priority.rawValue > $1.priority.rawValue }
        pendingUpdates.removeAll()
        
        asyncQueue.async { [weak self] in
            for update in updates {
                self?.updateTrustScore(for: update.deviceUUID, change: update.change, reason: update.reason)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .trustScoreBatchUpdated, object: nil)
            }
        }
    }
    
    /// 啟動批次處理定時器
    private func startBatchProcessingTimer() {
        guard useAsyncProcessing else { return }
        
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchProcessingInterval, repeats: true) { [weak self] _ in
            self?.processPendingUpdates()
        }
    }
    
    /// 啟動批次儲存計時器
    private func startBatchSaveTimer() {
        batchSaveTimer = Timer.scheduledTimer(withTimeInterval: batchSaveInterval, repeats: true) { [weak self] _ in
            self?.checkAndPerformBatchSave()
        }
    }
    
    /// 標記設備需要批次儲存
    private func markForBatchSave(_ deviceUUID: String) {
        pendingSaveDevices.insert(deviceUUID)
        
        // 如果待儲存數量超過閾值，立即觸發儲存
        if pendingSaveDevices.count >= maxPendingSaveCount {
            saveQueue.async { [weak self] in
                self?.performBatchSave(force: false)
            }
        }
    }
    
    /// 檢查並執行批次儲存
    private func checkAndPerformBatchSave() {
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTime)
        
        // 如果有待儲存的設備且超過儲存間隔
        if !pendingSaveDevices.isEmpty && timeSinceLastSave >= batchSaveInterval {
            saveQueue.async { [weak self] in
                self?.performBatchSave(force: false)
            }
        }
    }
    
    /// 執行批次儲存
    private func performBatchSave(force: Bool) {
        guard force || !pendingSaveDevices.isEmpty else { return }
        
        let devicesToSave = pendingSaveDevices
        pendingSaveDevices.removeAll()
        
        // 只序列化需要更新的設備數據
        var dataToSave: [String: TrustScore] = [:]
        
        if force {
            // 強制儲存：儲存所有數據
            dataToSave = trustScores
        } else {
            // 批次儲存：只儲存變更的設備
            for deviceID in devicesToSave {
                if let trustScore = trustScores[deviceID] {
                    dataToSave[deviceID] = trustScore
                }
            }
        }
        
        // 執行實際儲存
        if !dataToSave.isEmpty {
            // 合併現有數據
            var allData = trustScores
            if !force {
                // 載入完整數據並合併 (優先從 Keychain)
                let existingData = retrieveFromKeychain(key: userDefaultsKey) ?? UserDefaults.standard.data(forKey: userDefaultsKey)
                if let data = existingData,
                   let existingScores = try? JSONDecoder().decode([String: TrustScore].self, from: data) {
                    allData = existingScores
                    // 更新變更的數據
                    for (key, value) in dataToSave {
                        allData[key] = value
                    }
                }
            }
            
            // 儲存合併後的數據到 Keychain
            if let data = try? JSONEncoder().encode(allData) {
                if !storeInKeychain(data: data, key: userDefaultsKey) {
                    print("⚠️ 批次儲存到 Keychain 失敗，回退到 UserDefaults")
                    UserDefaults.standard.set(data, forKey: userDefaultsKey)
                    UserDefaults.standard.synchronize()
                }
                lastSaveTime = Date()
                
                let savedCount = force ? allData.count : devicesToSave.count
                print("💾 TrustScoreManager: 批次儲存完成 - \(savedCount) 個設備記錄 (\(force ? "強制" : "批次"))")
            }
        }
        
        // 儲存其他數據（黑名單、觀察名單等）
        // 儲存黑名單到 Keychain
        if let data = try? JSONEncoder().encode(Array(localBlacklist)) {
            if !storeInKeychain(data: data, key: blacklistKey) {
                UserDefaults.standard.set(Array(localBlacklist), forKey: blacklistKey)
            }
        }
        
        UserDefaults.standard.set(Array(observationList), forKey: observationKey)
        
        if let filterData = bloomFilter?.getData() {
            UserDefaults.standard.set(filterData, forKey: bloomFilterKey)
        }
    }
    
    /// 決定更新優先級
    private func determinePriority(for reason: ScoreChangeReason) -> UpdatePriority {
        switch reason {
        case .suspiciousBehavior(let behavior):
            switch behavior {
            case .invalidSignature, .inappropriateContent:
                return .critical
            case .protocolViolation, .timestampManipulation:
                return .high
            default:
                return .medium
            }
        case .manualBlacklist, .manualWhitelist:
            return .critical
        case .excessiveBroadcast:
            return .high
        case .malformedPacket:
            return .medium
        case .successfulCommunication:
            return .low
        }
    }
}

// MARK: - Async Processing Support Types

/// 待處理的信任評分更新
struct PendingTrustUpdate {
    let deviceUUID: String
    let change: Double
    let reason: ScoreChangeReason
    let timestamp: Date
    let priority: UpdatePriority
}

/// 更新優先級
enum UpdatePriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    static func < (lhs: UpdatePriority, rhs: UpdatePriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let trustScoreUpdated = Notification.Name("trustScoreUpdated")
    static let trustScoreBatchUpdated = Notification.Name("trustScoreBatchUpdated")
}

// MARK: - Supporting Types

/// 信任評分記錄
struct TrustScore: Codable {
    let deviceUUID: String
    var currentScore: Double
    let createdAt: Date
    var lastUpdated: Date
    var updateCount: Int = 0
    var history: [ScoreHistory] = []
    
    // MARK: - 🚀 Warmup階段數據 (新增)
    let firstConnectionTime: Date
    var riskHint: Int = 0                    // 風險提示計數
    var abnormalCount: Int = 0               // 異常行為計數  
    var hasValidInteraction: Bool = false    // 是否有有效互動
    var broadcastCount: Int = 0              // 廣播計數（每分鐘重置）
    var writeCount: Int = 0                  // 寫入計數（每分鐘重置）
    var lastResetTime: Date                  // 上次重置時間
    var lastValidInteractionTime: Date?      // 最後有效互動時間
    var lastRiskDecayTime: Date              // 最後風險衰退時間
    var validInteractionCount: Int = 0       // 有效互動計數
    var recentMessageHashes: [String] = []   // 最近訊息雜湊（用於相似度檢測）
    
    // MARK: - 🧠 行為型輪廓學習數據 (新增)
    var behaviorProfile: BehaviorProfile = BehaviorProfile()  // 行為輪廓
    
    /// 自定義初始化器
    init(deviceUUID: String, currentScore: Double, createdAt: Date, lastUpdated: Date, firstConnectionTime: Date, lastResetTime: Date) {
        self.deviceUUID = deviceUUID
        self.currentScore = currentScore
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.firstConnectionTime = firstConnectionTime
        self.lastResetTime = lastResetTime
        self.lastRiskDecayTime = firstConnectionTime
    }
    
    /// Codable兼容初始化器（向後兼容）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        deviceUUID = try container.decode(String.self, forKey: .deviceUUID)
        currentScore = try container.decode(Double.self, forKey: .currentScore)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        updateCount = try container.decodeIfPresent(Int.self, forKey: .updateCount) ?? 0
        history = try container.decodeIfPresent([ScoreHistory].self, forKey: .history) ?? []
        
        // 新字段提供默認值
        firstConnectionTime = try container.decodeIfPresent(Date.self, forKey: .firstConnectionTime) ?? createdAt
        riskHint = try container.decodeIfPresent(Int.self, forKey: .riskHint) ?? 0
        abnormalCount = try container.decodeIfPresent(Int.self, forKey: .abnormalCount) ?? 0
        hasValidInteraction = try container.decodeIfPresent(Bool.self, forKey: .hasValidInteraction) ?? false
        broadcastCount = try container.decodeIfPresent(Int.self, forKey: .broadcastCount) ?? 0
        writeCount = try container.decodeIfPresent(Int.self, forKey: .writeCount) ?? 0
        lastResetTime = try container.decodeIfPresent(Date.self, forKey: .lastResetTime) ?? Date()
        lastValidInteractionTime = try container.decodeIfPresent(Date.self, forKey: .lastValidInteractionTime)
        lastRiskDecayTime = try container.decodeIfPresent(Date.self, forKey: .lastRiskDecayTime) ?? createdAt
        validInteractionCount = try container.decodeIfPresent(Int.self, forKey: .validInteractionCount) ?? 0
        recentMessageHashes = try container.decodeIfPresent([String].self, forKey: .recentMessageHashes) ?? []
        behaviorProfile = try container.decodeIfPresent(BehaviorProfile.self, forKey: .behaviorProfile) ?? BehaviorProfile()
    }
    
    /// Codable編碼
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(deviceUUID, forKey: .deviceUUID)
        try container.encode(currentScore, forKey: .currentScore)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(updateCount, forKey: .updateCount)
        try container.encode(history, forKey: .history)
        try container.encode(firstConnectionTime, forKey: .firstConnectionTime)
        try container.encode(riskHint, forKey: .riskHint)
        try container.encode(abnormalCount, forKey: .abnormalCount)
        try container.encode(hasValidInteraction, forKey: .hasValidInteraction)
        try container.encode(broadcastCount, forKey: .broadcastCount)
        try container.encode(writeCount, forKey: .writeCount)
        try container.encode(lastResetTime, forKey: .lastResetTime)
        try container.encodeIfPresent(lastValidInteractionTime, forKey: .lastValidInteractionTime)
        try container.encode(lastRiskDecayTime, forKey: .lastRiskDecayTime)
        try container.encode(validInteractionCount, forKey: .validInteractionCount)
        try container.encode(recentMessageHashes, forKey: .recentMessageHashes)
        try container.encode(behaviorProfile, forKey: .behaviorProfile)
    }
    
    /// CodingKeys
    private enum CodingKeys: String, CodingKey {
        case deviceUUID, currentScore, createdAt, lastUpdated, updateCount, history
        case firstConnectionTime, riskHint, abnormalCount, hasValidInteraction
        case broadcastCount, writeCount, lastResetTime
        case lastValidInteractionTime, lastRiskDecayTime, validInteractionCount, recentMessageHashes
        case behaviorProfile
    }
    
    var trustLevel: TrustLevel {
        switch currentScore {
        case 80...100:
            return .trusted
        case 60..<80:
            return .reliable
        case 40..<60:
            return .neutral
        case 20..<40:
            return .suspicious
        default:
            return .untrusted
        }
    }
}

/// 評分歷史記錄
struct ScoreHistory: Codable {
    let timestamp: Date
    let change: Double
    let reason: ScoreChangeReason
    let resultingScore: Double
}

/// 評分變化原因
enum ScoreChangeReason: Codable {
    case successfulCommunication
    case suspiciousBehavior(SuspiciousBehavior)
    case excessiveBroadcast
    case malformedPacket(PacketError)
    case manualBlacklist
    case manualWhitelist
}

/// 可疑行為類型
enum SuspiciousBehavior: String, Codable, CaseIterable {
    case duplicateMessages = "DUPLICATE_MESSAGES"
    case invalidSignature = "INVALID_SIGNATURE"
    case timestampManipulation = "TIMESTAMP_MANIPULATION"
    case excessiveRetransmission = "EXCESSIVE_RETRANSMISSION"
    case protocolViolation = "PROTOCOL_VIOLATION"
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
}

/// 封包錯誤類型
enum PacketError: String, Codable, CaseIterable {
    case invalidFormat = "INVALID_FORMAT"
    case corruptedData = "CORRUPTED_DATA"
    case unsupportedVersion = "UNSUPPORTED_VERSION"
    case invalidChecksum = "INVALID_CHECKSUM"
    case oversizedPacket = "OVERSIZED_PACKET"
}

/// 互動類型
enum InteractionType: String, Codable, CaseIterable {
    case chat = "chat"                       // 聊天訊息
    case emergency = "emergency"             // 緊急信號
    case signal = "signal"                   // 一般信號
    case response = "response"               // 回應他人
    case testing = "testing"                 // 測試行為
    case gaming = "gaming"                   // 遊戲互動
    case help = "help"                       // 求助行為
    case social = "social"                   // 社交互動
}

/// 信任分數訊息類型
enum TrustMessageType: String, CaseIterable {
    case emergency = "EMERGENCY"
    case general = "GENERAL"
    case heartbeat = "HEARTBEAT"
    case system = "SYSTEM"
}

// MARK: - 🧠 行為型輪廓學習系統

/// 行為輪廓 - 學習用戶行為模式
struct BehaviorProfile: Codable {
    // 內容多樣性分析
    var messageContents: [String] = []              // 最近訊息內容（最多20條）
    var uniqueWords: Set<String> = []               // 獨特詞彙集合
    var contentDiversityScore: Double = 0.0         // 內容多樣性評分
    
    // 互動模式分析
    var interactionTimestamps: [Date] = []          // 互動時間戳（最多50個）
    var averageInterval: TimeInterval = 0.0         // 平均互動間隔
    var rhythmConsistency: Double = 0.0             // 節奏一致性評分
    
    // 求助行為分析
    var helpKeywords: [String] = ["救命", "幫助", "緊急", "SOS", "help", "emergency"]
    var helpSeekingCount: Int = 0                   // 求助行為計數
    var helpSeekingScore: Double = 0.0              // 求助行為評分
    
    // 社交參與分析
    var mentionUsage: Int = 0                       // @提及使用次數
    var responseCount: Int = 0                      // 回應他人次數
    var socialEngagementScore: Double = 0.0         // 社交參與評分
    
    // 學習行為分析
    var learningBehaviors: [LearningBehavior] = []  // 學習行為記錄
    var adaptationScore: Double = 0.0               // 適應能力評分
    
    // 時間模式分析
    var activeHours: Set<Int> = []                  // 活躍時段
    var sessionDurations: [TimeInterval] = []       // 會話持續時間
    var temporalPattern: TemporalPattern = .unknown // 時間模式
    
    // 臨時黑名單狀態
    var temporaryBlacklistUntil: Date?              // 臨時黑名單結束時間
    var blacklistReason: String?                    // 黑名單原因
    
    var lastAnalysisTime: Date = Date()             // 最後分析時間
    
    /// 計算整體行為善意評分 (0.0-1.0)
    var overallBenevolenceScore: Double {
        let weights: [(score: Double, weight: Double)] = [
            (contentDiversityScore, 1.0),
            (rhythmConsistency, 1.5),
            (helpSeekingScore, 2.0),
            (socialEngagementScore, 1.8),
            (adaptationScore, 1.2)
        ]
        
        let weightedSum = weights.reduce(0.0) { $0 + ($1.score * $1.weight) }
        let totalWeight = weights.reduce(0.0) { $0 + $1.weight }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }
    
    /// 檢查是否在臨時黑名單中
    var isTemporarilyBlacklisted: Bool {
        guard let blacklistUntil = temporaryBlacklistUntil else { return false }
        return Date() < blacklistUntil
    }
}

/// 學習行為類型
enum LearningBehavior: String, Codable, CaseIterable {
    case exploring = "exploring"              // 探索功能
    case asking = "asking"                   // 提問學習
    case mimicking = "mimicking"             // 模仿他人
    case experimenting = "experimenting"     // 實驗性操作
    case adapting = "adapting"               // 適應改進
}

/// 時間行為模式
enum TemporalPattern: String, Codable, CaseIterable {
    case unknown = "unknown"                 // 未知模式
    case human = "human"                     // 人類模式（不規律但合理）
    case automated = "automated"             // 自動化模式（過於規律）
    case bursty = "bursty"                   // 爆發性模式（短時間大量）
    case consistent = "consistent"           // 一致性模式（穩定間隔）
}

// MARK: - 集中式信任檢查工具
extension TrustScoreManager {
    
    /// 集中式信任檢查工具函數 - 檢查並執行或阻止操作
    /// - Parameters:
    ///   - deviceUUID: 設備UUID（必須提供）
    ///   - action: 如果通過檢查則執行的操作
    ///   - onBlocked: 如果被阻止時的回調（可選）
    /// - Returns: 是否執行了操作
    @MainActor
    @discardableResult
    static func guardTrust(for deviceUUID: String, 
                          action: () -> Void, 
                          onBlocked: (() -> Void)? = nil) -> Bool {
        if ServiceContainer.shared.trustScoreManager.checkTemporaryBlacklist(for: deviceUUID) {
            print("⛔️ TrustGuard: 操作被阻止 - 設備 \(deviceUUID) 處於臨時黑名單狀態")
            onBlocked?()
            return false
        }
        
        action()
        return true
    }
    
    /// 異步版本的集中式信任檢查工具函數
    /// - Parameters:
    ///   - deviceUUID: 設備UUID（必須提供）
    ///   - action: 如果通過檢查則執行的異步操作
    ///   - onBlocked: 如果被阻止時的回調（可選）
    /// - Returns: 是否執行了操作
    @MainActor
    @discardableResult
    static func guardTrustAsync(for deviceUUID: String, 
                               action: () async -> Void, 
                               onBlocked: (() -> Void)? = nil) async -> Bool {
        if ServiceContainer.shared.trustScoreManager.checkTemporaryBlacklist(for: deviceUUID) {
            print("⛔️ TrustGuard: 異步操作被阻止 - 設備 \(deviceUUID) 處於臨時黑名單狀態")
            onBlocked?()
            return false
        }
        
        await action()
        return true
    }
}

/// 信任等級
enum TrustLevel: String, CaseIterable {
    case trusted = "TRUSTED"
    case reliable = "RELIABLE"
    case neutral = "NEUTRAL"
    case suspicious = "SUSPICIOUS"
    case untrusted = "UNTRUSTED"
    
    var description: String {
        switch self {
        case .trusted:
            return "可信"
        case .reliable:
            return "可靠"
        case .neutral:
            return "中性"
        case .suspicious:
            return "可疑"
        case .untrusted:
            return "不可信"
        }
    }
    
    var color: UIColor {
        switch self {
        case .trusted:
            return .systemGreen
        case .reliable:
            return .systemBlue
        case .neutral:
            return .systemYellow
        case .suspicious:
            return .systemOrange
        case .untrusted:
            return .systemRed
        }
    }
}

/// 信任統計
struct TrustStatistics {
    let totalNodes: Int
    let averageScore: Double
    let trustedNodes: Int
    let suspiciousNodes: Int
    let blacklistedNodes: Int
    let observationNodes: Int
}

/// 簡化的 Bloom Filter 實作
class BloomFilter {
    private var bitArray: [Bool]
    private let hashFunctionCount: Int
    private let size: Int
    
    init(expectedElements: Int, falsePositiveRate: Double) {
        self.size = Int(-Double(expectedElements) * log(falsePositiveRate) / (log(2) * log(2)))
        self.hashFunctionCount = Int(Double(size) / Double(expectedElements) * log(2))
        self.bitArray = Array(repeating: false, count: size)
    }
    
    init?(data: Data) {
        guard data.count >= 8 else { return nil }
        
        let sizeBytes = data.prefix(4)
        let hashCountBytes = data.dropFirst(4).prefix(4)
        
        self.size = Int(sizeBytes.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian)
        self.hashFunctionCount = Int(hashCountBytes.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian)
        
        let bitData = data.dropFirst(8)
        self.bitArray = bitData.map { $0 != 0 }
    }
    
    func add(_ element: String) {
        let hashes = getHashes(for: element)
        for hash in hashes {
            bitArray[hash % size] = true
        }
    }
    
    func contains(_ element: String) -> Bool {
        let hashes = getHashes(for: element)
        return hashes.allSatisfy { bitArray[$0 % size] }
    }
    
    func merge(with other: BloomFilter) {
        guard size == other.size else { return }
        
        for i in 0..<size {
            bitArray[i] = bitArray[i] || other.bitArray[i]
        }
    }
    
    func getData() -> Data {
        var data = Data()
        
        // 添加 size 和 hashFunctionCount
        var sizeBytes = Int32(size).bigEndian
        var hashCountBytes = Int32(hashFunctionCount).bigEndian
        
        data.append(Data(bytes: &sizeBytes, count: 4))
        data.append(Data(bytes: &hashCountBytes, count: 4))
        
        // 添加 bit array
        let bitData = Data(bitArray.map { $0 ? UInt8(1) : UInt8(0) })
        data.append(bitData)
        
        return data
    }
    
    private func getHashes(for element: String) -> [Int] {
        let data = element.data(using: .utf8) ?? Data()
        var hashes: [Int] = []
        
        for i in 0..<hashFunctionCount {
            let hash = data.hashValue ^ i
            hashes.append(abs(hash))
        }
        
        return hashes
    }
} 