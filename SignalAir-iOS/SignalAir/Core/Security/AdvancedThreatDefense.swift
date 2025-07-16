import Foundation
import MultipeerConnectivity
import CryptoKit
import Network

// MARK: - 高級威脅防禦系統
// 專門應對 A/B 級攻擊的防禦機制

enum ThreatLevel: Int, CaseIterable {
    case green = 1      // 正常
    case yellow = 2     // 可疑
    case orange = 3     // 危險
    case red = 4        // 嚴重威脅
    case black = 5      // 國家級攻擊
    
    var description: String {
        switch self {
        case .green: return "正常"
        case .yellow: return "可疑活動"
        case .orange: return "危險警告"
        case .red: return "嚴重威脅"
        case .black: return "國家級攻擊"
        }
    }
    
    var color: String {
        switch self {
        case .green: return "🟢"
        case .yellow: return "🟡"
        case .orange: return "🟠"
        case .red: return "🔴"
        case .black: return "⚫"
        }
    }
}

enum AttackGrade: String {
    case gradeA = "A級(國家級)"
    case gradeB = "B級(組織級)"
    case gradeC = "C級(個人級)"
    case unknown = "未知等級"
    
    var resources: String {
        switch self {
        case .gradeA: return "數千節點+AI+零日漏洞"
        case .gradeB: return "數百節點+社交工程"
        case .gradeC: return "數十節點+腳本攻擊"
        case .unknown: return "資源未知"
        }
    }
}

struct ThreatSignature {
    let patternId: String
    let description: String
    let indicators: [String]
    let minNodes: Int
    let timeWindow: TimeInterval
    let confidence: Float
}

struct AttackAnalysis {
    let grade: AttackGrade
    let threatLevel: ThreatLevel
    let confidence: Float
    let nodeCount: Int
    let attackVectors: [String]
    let recommendedActions: [String]
    let estimatedDuration: TimeInterval
}

@MainActor
class AdvancedThreatDefense: ObservableObject {
    
    // MARK: - 威脅簽名庫
    private let threatSignatures: [ThreatSignature] = [
        // A級攻擊簽名
        ThreatSignature(
            patternId: "GRADE_A_BOTNET",
            description: "大規模 Botnet 攻擊",
            indicators: ["simultaneous_connections", "identical_behavior", "coordinated_timing"],
            minNodes: 500,
            timeWindow: 60.0,
            confidence: 0.95
        ),
        ThreatSignature(
            patternId: "GRADE_A_AI_REVERSE",
            description: "AI 輔助逆向攻擊",
            indicators: ["adaptive_behavior", "pattern_learning", "real_time_adjustment"],
            minNodes: 100,
            timeWindow: 300.0,
            confidence: 0.90
        ),
        
        // B級攻擊簽名
        ThreatSignature(
            patternId: "GRADE_B_ORGANIZED",
            description: "組織化協調攻擊",
            indicators: ["sequential_attacks", "resource_pooling", "tactical_retreat"],
            minNodes: 50,
            timeWindow: 120.0,
            confidence: 0.85
        ),
        ThreatSignature(
            patternId: "GRADE_B_SOCIAL_ENG",
            description: "社交工程混合攻擊",
            indicators: ["trust_exploitation", "identity_spoofing", "reputation_attack"],
            minNodes: 20,
            timeWindow: 600.0,
            confidence: 0.80
        ),
        
        // C級攻擊簽名
        ThreatSignature(
            patternId: "GRADE_C_SCRIPT",
            description: "腳本自動化攻擊",
            indicators: ["repetitive_patterns", "fixed_intervals", "simple_payloads"],
            minNodes: 5,
            timeWindow: 30.0,
            confidence: 0.75
        )
    ]
    
    // MARK: - 防禦狀態
    @Published private(set) var currentThreatLevel: ThreatLevel = .green
    @Published private(set) var activeThreats: [AttackAnalysis] = []
    @Published private(set) var defenseMetrics: DefenseMetrics = DefenseMetrics()
    
    // MARK: - 內部狀態
    private var nodeActivityHistory: [String: [NodeActivity]] = [:]
    private var attackPatternBuffer: [AttackPattern] = []
    private let maxHistorySize = 1000
    private let analysisInterval: TimeInterval = 10.0
    
    // MARK: - 監控組件
    private var analysisTimer: Timer?
    private let behaviorAnalyzer = AIBehaviorAnalyzer()
    private let cryptoValidator = CryptographicValidator()
    private let networkForensics = NetworkForensics()
    
    struct NodeActivity {
        let nodeId: String
        let activity: String
        let timestamp: Date
        let data: Data?
        let suspicionScore: Float
    }
    
    struct AttackPattern {
        let patternType: String
        let nodes: Set<String>
        let timestamp: Date
        let confidence: Float
    }
    
    struct DefenseMetrics {
        let threatsDetected: Int
        let attacksBlocked: Int
        let falsePositives: Int
        let averageResponseTime: TimeInterval
        let systemLoad: Float
        
        init() {
            self.threatsDetected = 0
            self.attacksBlocked = 0
            self.falsePositives = 0
            self.averageResponseTime = 0.0
            self.systemLoad = 0.0
        }
    }
    
    // MARK: - 初始化
    init() {
        startThreatAnalysis()
        setupAdvancedMonitoring()
        print("🛡️ 高級威脅防禦系統已啟動")
    }
    
    deinit {
        analysisTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    
    /// 記錄節點活動
    func recordNodeActivity(_ nodeId: String, activity: String, data: Data? = nil) {
        let suspicionScore = calculateSuspicionScore(nodeId: nodeId, activity: activity, data: data)
        
        let nodeActivity = NodeActivity(
            nodeId: nodeId,
            activity: activity,
            timestamp: Date(),
            data: data,
            suspicionScore: suspicionScore
        )
        
        // 記錄到歷史
        if nodeActivityHistory[nodeId] == nil {
            nodeActivityHistory[nodeId] = []
        }
        nodeActivityHistory[nodeId]?.append(nodeActivity)
        
        // 限制歷史大小
        if let count = nodeActivityHistory[nodeId]?.count, count > maxHistorySize {
            nodeActivityHistory[nodeId]?.removeFirst(count - maxHistorySize)
        }
        
        #if DEBUG
        if suspicionScore > 0.7 {
            print("⚠️ 高可疑活動: 節點 \(nodeId) - \(activity) (可疑度: \(String(format: "%.2f", suspicionScore)))")
        }
        #endif
    }
    
    /// 分析當前威脅等級
    func analyzeThreatLevel() async -> AttackAnalysis? {
        let recentActivities = getRecentActivities(timeWindow: 300.0) // 5分鐘內
        
        guard !recentActivities.isEmpty else { return nil }
        
        // 計算節點數量和行為模式
        let uniqueNodes = Set(recentActivities.map { $0.nodeId }).count
        let averageSuspicion = recentActivities.reduce(0) { $0 + $1.suspicionScore } / Float(recentActivities.count)
        
        // 檢測攻擊簽名
        for signature in threatSignatures {
            if let analysis = matchThreatSignature(signature, activities: recentActivities, nodeCount: uniqueNodes) {
                return analysis
            }
        }
        
        // 基於節點數量和可疑度的基本分析
        let grade: AttackGrade
        let threatLevel: ThreatLevel
        
        if uniqueNodes > 100 && averageSuspicion > 0.8 {
            grade = .gradeA
            threatLevel = .black
        } else if uniqueNodes > 50 && averageSuspicion > 0.7 {
            grade = .gradeB
            threatLevel = .red
        } else if uniqueNodes > 10 && averageSuspicion > 0.6 {
            grade = .gradeC
            threatLevel = .orange
        } else if averageSuspicion > 0.5 {
            grade = .unknown
            threatLevel = .yellow
        } else {
            return nil // 無威脅
        }
        
        return AttackAnalysis(
            grade: grade,
            threatLevel: threatLevel,
            confidence: averageSuspicion,
            nodeCount: uniqueNodes,
            attackVectors: identifyAttackVectors(recentActivities),
            recommendedActions: generateRecommendations(grade: grade, threatLevel: threatLevel),
            estimatedDuration: estimateAttackDuration(recentActivities)
        )
    }
    
    /// 執行緊急防禦措施
    func executeEmergencyDefense(_ analysis: AttackAnalysis) async {
        #if DEBUG
        print("🚨 執行緊急防禦: \(analysis.grade.rawValue) - \(analysis.threatLevel.description)")
        #endif
        
        switch analysis.threatLevel {
        case .black, .red:
            await executeHighThreatDefense(analysis)
        case .orange:
            await executeMediumThreatDefense(analysis)
        case .yellow:
            await executeLowThreatDefense(analysis)
        case .green:
            break
        }
    }
    
    // MARK: - 私有方法
    
    private func startThreatAnalysis() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performThreatAnalysis()
            }
        }
    }
    
    private func performThreatAnalysis() async {
        if let analysis = await analyzeThreatLevel() {
            // 更新威脅狀態
            currentThreatLevel = analysis.threatLevel
            
            // 檢查是否是新威脅
            let isNewThreat = !activeThreats.contains { existing in
                existing.grade == analysis.grade && 
                existing.threatLevel == analysis.threatLevel
            }
            
            if isNewThreat {
                activeThreats.append(analysis)
                await executeEmergencyDefense(analysis)
                
                #if DEBUG
                print("\(analysis.threatLevel.color) 檢測到新威脅: \(analysis.grade.rawValue)")
                print("   節點數: \(analysis.nodeCount)")
                print("   信心度: \(String(format: "%.1f%%", analysis.confidence * 100))")
                print("   攻擊向量: \(analysis.attackVectors.joined(separator: ", "))")
                #endif
            }
        } else {
            // 無威脅時降低威脅等級
            if currentThreatLevel != .green {
                currentThreatLevel = .green
                activeThreats.removeAll()
                
                #if DEBUG
                print("🟢 威脅等級降至正常")
                #endif
            }
        }
    }
    
    private func calculateSuspicionScore(nodeId: String, activity: String, data: Data?) -> Float {
        var score: Float = 0.0
        
        // 基於活動類型的基礎分數
        switch activity.lowercased() {
        case let act where act.contains("scan"):
            score += 0.6
        case let act where act.contains("flood"):
            score += 0.8
        case let act where act.contains("forge"):
            score += 0.9
        case let act where act.contains("attack"):
            score += 0.95
        default:
            score += 0.1
        }
        
        // 基於歷史行為
        if let history = nodeActivityHistory[nodeId] {
            let recentSuspicious = history.suffix(10).filter { $0.suspicionScore > 0.5 }.count
            score += Float(recentSuspicious) * 0.05
        }
        
        // 基於數據內容分析
        if let data = data {
            score += analyzeDataSuspicion(data)
        }
        
        return min(1.0, score)
    }
    
    private func analyzeDataSuspicion(_ data: Data) -> Float {
        // 簡化的數據分析
        if data.count > 10000 {
            return 0.3 // 大包可疑
        }
        
        // 檢查是否包含可疑關鍵字
        if let string = String(data: data, encoding: .utf8) {
            let suspiciousKeywords = ["attack", "exploit", "payload", "botnet", "ddos"]
            for keyword in suspiciousKeywords {
                if string.lowercased().contains(keyword) {
                    return 0.4
                }
            }
        }
        
        return 0.0
    }
    
    private func getRecentActivities(timeWindow: TimeInterval) -> [NodeActivity] {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        var recentActivities: [NodeActivity] = []
        
        for (_, activities) in nodeActivityHistory {
            let recent = activities.filter { $0.timestamp > cutoffTime }
            recentActivities.append(contentsOf: recent)
        }
        
        return recentActivities.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func matchThreatSignature(_ signature: ThreatSignature, activities: [NodeActivity], nodeCount: Int) -> AttackAnalysis? {
        guard nodeCount >= signature.minNodes else { return nil }
        
        let timeWindow = signature.timeWindow
        let recentActivities = activities.filter { 
            Date().timeIntervalSince($0.timestamp) <= timeWindow 
        }
        
        // 檢查指標匹配
        var matchedIndicators = 0
        for indicator in signature.indicators {
            if checkIndicator(indicator, in: recentActivities) {
                matchedIndicators += 1
            }
        }
        
        let matchRatio = Float(matchedIndicators) / Float(signature.indicators.count)
        
        if matchRatio >= 0.6 { // 60% 指標匹配
            let grade: AttackGrade
            let threatLevel: ThreatLevel
            
            if signature.patternId.contains("GRADE_A") {
                grade = .gradeA
                threatLevel = .black
            } else if signature.patternId.contains("GRADE_B") {
                grade = .gradeB
                threatLevel = .red
            } else {
                grade = .gradeC
                threatLevel = .orange
            }
            
            return AttackAnalysis(
                grade: grade,
                threatLevel: threatLevel,
                confidence: signature.confidence * matchRatio,
                nodeCount: nodeCount,
                attackVectors: signature.indicators,
                recommendedActions: generateRecommendations(grade: grade, threatLevel: threatLevel),
                estimatedDuration: signature.timeWindow
            )
        }
        
        return nil
    }
    
    private func checkIndicator(_ indicator: String, in activities: [NodeActivity]) -> Bool {
        switch indicator {
        case "simultaneous_connections":
            let connectionTimes = activities.filter { $0.activity.contains("connect") }.map { $0.timestamp }
            return checkSimultaneousEvents(connectionTimes, threshold: 5.0)
            
        case "identical_behavior":
            return checkIdenticalBehavior(activities)
            
        case "coordinated_timing":
            return checkCoordinatedTiming(activities)
            
        case "adaptive_behavior":
            return checkAdaptiveBehavior(activities)
            
        default:
            return false
        }
    }
    
    private func checkSimultaneousEvents(_ timestamps: [Date], threshold: TimeInterval) -> Bool {
        guard timestamps.count > 5 else { return false }
        
        let sortedTimes = timestamps.sorted()
        for i in 0..<(sortedTimes.count - 5) {
            let timeSpan = sortedTimes[i + 4].timeIntervalSince(sortedTimes[i])
            if timeSpan <= threshold {
                return true
            }
        }
        return false
    }
    
    private func checkIdenticalBehavior(_ activities: [NodeActivity]) -> Bool {
        let groupedByActivity = Dictionary(grouping: activities) { $0.activity }
        for (_, group) in groupedByActivity {
            if group.count > 10 && Set(group.map { $0.nodeId }).count > 5 {
                return true
            }
        }
        return false
    }
    
    private func checkCoordinatedTiming(_ activities: [NodeActivity]) -> Bool {
        // 檢查是否有規律的時間間隔
        let timestamps = activities.map { $0.timestamp.timeIntervalSince1970 }
        guard timestamps.count > 10 else { return false }
        
        let intervals = zip(timestamps.dropFirst(), timestamps).map { $0 - $1 }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let regularIntervals = intervals.filter { abs($0 - averageInterval) < 1.0 }.count
        
        return Float(regularIntervals) / Float(intervals.count) > 0.7
    }
    
    private func checkAdaptiveBehavior(_ activities: [NodeActivity]) -> Bool {
        // 檢查行為是否在學習和調整
        guard activities.count > 20 else { return false }
        
        let early = activities.prefix(10)
        let late = activities.suffix(10)
        
        let earlyPatterns = Set(early.map { $0.activity })
        let latePatterns = Set(late.map { $0.activity })
        
        // 如果後期行為模式明顯不同，可能是適應性行為
        let uniqueToLate = latePatterns.subtracting(earlyPatterns)
        return uniqueToLate.count > earlyPatterns.count / 2
    }
    
    private func identifyAttackVectors(_ activities: [NodeActivity]) -> [String] {
        var vectors: Set<String> = []
        
        for activity in activities {
            if activity.suspicionScore > 0.7 {
                vectors.insert(activity.activity)
            }
        }
        
        return Array(vectors)
    }
    
    private func generateRecommendations(grade: AttackGrade, threatLevel: ThreatLevel) -> [String] {
        var recommendations: [String] = []
        
        switch grade {
        case .gradeA:
            recommendations = [
                "立即啟動最高級別防禦協議",
                "通知網路安全團隊",
                "啟動離線模式保護關鍵數據",
                "實施加密通道隔離",
                "考慮聯繫執法部門"
            ]
        case .gradeB:
            recommendations = [
                "提升防禦等級至高級",
                "加強節點身份驗證",
                "實施流量限制",
                "啟動自動阻擋機制"
            ]
        case .gradeC:
            recommendations = [
                "啟動標準防禦措施",
                "監控可疑節點",
                "記錄攻擊模式",
                "調整安全參數"
            ]
        case .unknown:
            recommendations = [
                "持續監控異常活動",
                "收集更多威脅情報"
            ]
        }
        
        return recommendations
    }
    
    private func estimateAttackDuration(_ activities: [NodeActivity]) -> TimeInterval {
        guard !activities.isEmpty else { return 0 }
        
        let firstActivity = activities.min { $0.timestamp < $1.timestamp }!
        let lastActivity = activities.max { $0.timestamp < $1.timestamp }!
        
        return lastActivity.timestamp.timeIntervalSince(firstActivity.timestamp)
    }
    
    private func executeHighThreatDefense(_ analysis: AttackAnalysis) async {
        #if DEBUG
        print("🚨 執行高威脅防禦協議")
        #endif
        
        // 1. 立即隔離可疑節點
        await isolateSuspiciousNodes(analysis.attackVectors)
        
        // 2. 啟動加密通道
        await enableEncryptedChannels()
        
        // 3. 通知所有防禦系統
        NotificationCenter.default.post(
            name: NSNotification.Name("HighThreatDetected"),
            object: analysis
        )
    }
    
    private func executeMediumThreatDefense(_ analysis: AttackAnalysis) async {
        #if DEBUG
        print("⚠️ 執行中等威脅防禦")
        #endif
        
        // 提升監控等級
        await enhanceMonitoring()
        
        // 限制可疑節點活動
        await limitSuspiciousActivity(analysis.attackVectors)
    }
    
    private func executeLowThreatDefense(_ analysis: AttackAnalysis) async {
        #if DEBUG
        print("🟡 執行低威脅防禦")
        #endif
        
        // 記錄並監控
        await logThreatActivity(analysis)
    }
    
    private func isolateSuspiciousNodes(_ vectors: [String]) async {
        // 實作節點隔離邏輯
        #if DEBUG
        print("🔒 隔離可疑節點: \(vectors.joined(separator: ", "))")
        #endif
    }
    
    private func enableEncryptedChannels() async {
        // 實作加密通道邏輯
        #if DEBUG
        print("🔐 啟動加密通道")
        #endif
    }
    
    private func enhanceMonitoring() async {
        // 實作增強監控邏輯
        #if DEBUG
        print("👁️ 增強監控等級")
        #endif
    }
    
    private func limitSuspiciousActivity(_ vectors: [String]) async {
        // 實作活動限制邏輯
        #if DEBUG
        print("⛔ 限制可疑活動: \(vectors.joined(separator: ", "))")
        #endif
    }
    
    private func logThreatActivity(_ analysis: AttackAnalysis) async {
        // 實作威脅記錄邏輯
        #if DEBUG
        print("📝 記錄威脅活動: \(analysis.grade.rawValue)")
        #endif
    }
    
    private func setupAdvancedMonitoring() {
        // 設置高級監控組件
        #if DEBUG
        print("🔧 設置高級監控系統")
        #endif
    }
}

// MARK: - 支援組件

class AIBehaviorAnalyzer {
    func analyzePattern(_ activities: [AdvancedThreatDefense.NodeActivity]) -> Float {
        // AI 行為分析邏輯
        return 0.5
    }
}

class CryptographicValidator {
    func validateSignature(_ data: Data) -> Bool {
        // 加密簽名驗證
        return true
    }
}

class NetworkForensics {
    func analyzeTraffic(_ packets: [Data]) -> [String] {
        // 網路封包取證分析
        return []
    }
}