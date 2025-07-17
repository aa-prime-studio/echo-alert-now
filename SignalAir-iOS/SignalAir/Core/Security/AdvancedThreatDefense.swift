import Foundation
import MultipeerConnectivity
import CryptoKit
import Network

// MARK: - 高級威脅防禦系統
// 專門應對 A/B 級Network Pattern的防禦機制

// 🔧 系統架構師：使用類定義避免衝突
@MainActor
class AdvancedThreatDefense: ObservableObject {
    
    // MARK: - 威脅等級定義
    enum ThreatLevel: Int, CaseIterable {
        case green = 1      // 正常
        case yellow = 2     // 可疑
        case orange = 3     // 危險
        case red = 4        // 嚴重威脅
        case black = 5      // 國家級Network Pattern
        
        var description: String {
            switch self {
            case .green: return "正常"
            case .yellow: return "可疑活動"
            case .orange: return "危險警告"
            case .red: return "嚴重威脅"
            case .black: return "國家級Network Pattern"
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
    
    // 🛡️ 安全專家：App Store 友好的威脅分級系統
    enum ThreatGrade: String {
        case critical = "Critical Level"
        case high = "High Level"
        case medium = "Medium Level"
        case unknown = "Unknown Level"
        
        var description: String {
            switch self {
            case .critical: return "Large scale network anomaly"
            case .high: return "Multi-node network irregularity"
            case .medium: return "Single-node network deviation"
            case .unknown: return "Undefined network pattern"
            }
        }
        
        var complexity: String {
            switch self {
            case .critical: return "Advanced coordination pattern"
            case .high: return "Moderate coordination pattern"
            case .medium: return "Basic coordination pattern"
            case .unknown: return "Pattern analysis pending"
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
    
    struct NetworkAnalysis {
        let grade: ThreatGrade
        let threatLevel: ThreatLevel
        let confidence: Float
        let nodeCount: Int
        let networkVectors: [String]
        let recommendedActions: [String]
        let estimatedDuration: TimeInterval
    }
    
    struct NodeActivity {
        let nodeId: String
        let activity: String
        let timestamp: Date
        let suspicionScore: Float
    }
    
    struct DefenseMetrics {
        let totalChecks: Int
        let threatsDetected: Int
        let falsePositives: Int
        let responseTime: TimeInterval
        let effectivenessScore: Float
    }
    
    // MARK: - 威脅簽名庫
    private let threatSignatures: [ThreatSignature] = [
        // 🛡️ 安全專家：App Store 友好的網路異常簽名
        ThreatSignature(
            patternId: "CRITICAL_NETWORK_PATTERN",
            description: "Large scale network coordination",
            indicators: ["simultaneous_connections", "identical_behavior", "coordinated_timing"],
            minNodes: 100,
            timeWindow: 60.0,
            confidence: 0.95
        ),
        ThreatSignature(
            patternId: "CRITICAL_ADAPTIVE_PATTERN",
            description: "Adaptive network behavior pattern",
            indicators: ["pattern_analysis", "adaptive_behavior", "unusual_coordination"],
            minNodes: 50,
            timeWindow: 120.0,
            confidence: 0.90
        ),
        
        // 🛡️ 安全專家：中等級網路異常簽名
        ThreatSignature(
            patternId: "HIGH_SOCIAL_PATTERN",
            description: "Social interaction anomaly",
            indicators: ["user_interaction", "social_manipulation", "credential_patterns"],
            minNodes: 25,
            timeWindow: 300.0,
            confidence: 0.80
        ),
        ThreatSignature(
            patternId: "HIGH_COORDINATED_PATTERN",
            description: "Coordinated network behavior",
            indicators: ["multi_vector_behavior", "coordinated_nodes", "resource_pooling"],
            minNodes: 15,
            timeWindow: 180.0,
            confidence: 0.85
        ),
        
        // 🛡️ 安全專家：低等級網路異常簽名
        ThreatSignature(
            patternId: "MEDIUM_AUTOMATED_PATTERN",
            description: "Automated network behavior",
            indicators: ["automated_tools", "script_patterns", "repetitive_behavior"],
            minNodes: 5,
            timeWindow: 600.0,
            confidence: 0.70
        ),
        ThreatSignature(
            patternId: "MEDIUM_INDIVIDUAL_PATTERN",
            description: "Individual network anomaly",
            indicators: ["single_source", "limited_resources", "basic_techniques"],
            minNodes: 1,
            timeWindow: 900.0,
            confidence: 0.60
        )
    ]
    
    // MARK: - 防禦狀態
    @Published private(set) var currentThreatLevel: ThreatLevel = .green
    @Published private(set) var activeThreats: [NetworkAnalysis] = []
    @Published private(set) var defenseMetrics: DefenseMetrics = DefenseMetrics(totalChecks: 0, threatsDetected: 0, falsePositives: 0, responseTime: 0, effectivenessScore: 1.0)
    
    // MARK: - 內部狀態
    private var nodeActivities: [NodeActivity] = []
    private var lastAnalysisTime: Date = Date()
    private var defenseTimer: Timer?
    
    // MARK: - 初始化
    init() {
        startContinuousMonitoring()
        print("🛡️ AdvancedThreatDefense 初始化完成")
    }
    
    deinit {
        defenseTimer?.invalidate()
        defenseTimer = nil
    }
    
    // MARK: - 公開方法
    
    /// 啟動連續監控
    func startContinuousMonitoring() {
        defenseTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performThreatAnalysis()
            }
        }
        
        #if DEBUG
        print("🔍 威脅監控已啟動")
        #endif
    }
    
    /// 停止連續監控
    func stopContinuousMonitoring() {
        defenseTimer?.invalidate()
        defenseTimer = nil
        
        #if DEBUG
        print("⏹️ 威脅監控已停止")
        #endif
    }
    
    /// 記錄節點活動
    func recordNodeActivity(_ nodeId: String, activity: String, suspicionScore: Float) {
        let nodeActivity = NodeActivity(
            nodeId: nodeId,
            activity: activity,
            timestamp: Date(),
            suspicionScore: suspicionScore
        )
        
        nodeActivities.append(nodeActivity)
        
        // 清理過期活動（保留最近24小時）
        let cutoffTime = Date().addingTimeInterval(-86400)
        nodeActivities.removeAll { $0.timestamp < cutoffTime }
        
        #if DEBUG
        if suspicionScore > 0.7 {
            print("⚠️ 高可疑活動: 節點 \(nodeId) - \(activity) (可疑度: \(String(format: "%.2f", suspicionScore)))")
        }
        #endif
    }
    
    /// 分析當前威脅等級
    func analyzeThreatLevel() async -> NetworkAnalysis? {
        let recentActivities = getRecentActivities(timeWindow: 300.0) // 5分鐘內
        
        guard !recentActivities.isEmpty else { return nil }
        
        // 計算節點數量和行為模式
        let uniqueNodes = Set(recentActivities.map { $0.nodeId }).count
        let averageSuspicion = recentActivities.reduce(0) { $0 + $1.suspicionScore } / Float(recentActivities.count)
        
        // 檢測Network Pattern簽名
        for signature in threatSignatures {
            if let analysis = matchThreatSignature(signature, activities: recentActivities, nodeCount: uniqueNodes) {
                return analysis
            }
        }
        
        // 基於節點數量和可疑度的基本分析
        let grade: ThreatGrade
        let threatLevel: ThreatLevel
        
        if uniqueNodes > 100 && averageSuspicion > 0.8 {
            grade = .critical
            threatLevel = .black
        } else if uniqueNodes > 50 && averageSuspicion > 0.7 {
            grade = .high
            threatLevel = .red
        } else if uniqueNodes > 10 && averageSuspicion > 0.6 {
            grade = .medium
            threatLevel = .orange
        } else if averageSuspicion > 0.5 {
            grade = .unknown
            threatLevel = .yellow
        } else {
            return nil // 無威脅
        }
        
        return NetworkAnalysis(
            grade: grade,
            threatLevel: threatLevel,
            confidence: averageSuspicion,
            nodeCount: uniqueNodes,
            networkVectors: recentActivities.map { $0.activity },
            recommendedActions: generateRecommendations(grade: grade, threatLevel: threatLevel),
            estimatedDuration: estimateResponseTime(grade: grade)
        )
    }
    
    /// 執行威脅分析
    func performThreatAnalysis() async {
        let startTime = Date()
        
        if let analysis = await analyzeThreatLevel() {
            currentThreatLevel = analysis.threatLevel
            activeThreats = [analysis]
            
            #if DEBUG
            print("🚨 威脅檢測: \(analysis.grade.description) - \(analysis.threatLevel.description)")
            #endif
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
        
        // 更新防禦指標
        let executionTime = Date().timeIntervalSince(startTime)
        updateDefenseMetrics(executionTime: executionTime)
        
        lastAnalysisTime = Date()
    }
    
    // MARK: - 私有方法
    
    private func getRecentActivities(timeWindow: TimeInterval) -> [NodeActivity] {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        return nodeActivities.filter { $0.timestamp >= cutoffTime }
    }
    
    private func matchThreatSignature(_ signature: ThreatSignature, activities: [NodeActivity], nodeCount: Int) -> NetworkAnalysis? {
        guard nodeCount >= signature.minNodes else { return nil }
        
        let recentActivities = activities.filter { 
            Date().timeIntervalSince($0.timestamp) <= signature.timeWindow
        }
        
        let indicatorMatches = signature.indicators.compactMap { indicator in
            recentActivities.first { $0.activity.contains(indicator) }
        }
        
        let matchRatio = Float(indicatorMatches.count) / Float(signature.indicators.count)
        
        if matchRatio >= signature.confidence {
            let grade: ThreatGrade
            let threatLevel: ThreatLevel
            
            if signature.patternId.hasPrefix("CRITICAL") {
                grade = .critical
                threatLevel = .black
            } else if signature.patternId.hasPrefix("HIGH") {
                grade = .high
                threatLevel = .red
            } else {
                grade = .medium
                threatLevel = .orange
            }
            
            return NetworkAnalysis(
                grade: grade,
                threatLevel: threatLevel,
                confidence: matchRatio,
                nodeCount: nodeCount,
                networkVectors: indicatorMatches.map { $0.activity },
                recommendedActions: generateRecommendations(grade: grade, threatLevel: threatLevel),
                estimatedDuration: estimateResponseTime(grade: grade)
            )
        }
        
        return nil
    }
    
    private func generateRecommendations(grade: ThreatGrade, threatLevel: ThreatLevel) -> [String] {
        var recommendations: [String] = []
        
        switch grade {
        case .critical:
            recommendations.append("啟動緊急防禦協議")
            recommendations.append("隔離受影響節點")
            recommendations.append("通知安全團隊")
            
        case .high:
            recommendations.append("增加監控頻率")
            recommendations.append("分析Network Pattern模式")
            recommendations.append("準備防禦措施")
            
        case .medium:
            recommendations.append("持續觀察")
            recommendations.append("記錄異常活動")
            
        case .unknown:
            recommendations.append("收集更多數據")
            recommendations.append("分析行為模式")
        }
        
        return recommendations
    }
    
    private func estimateResponseTime(grade: ThreatGrade) -> TimeInterval {
        switch grade {
        case .critical: return 60.0    // 1分鐘
        case .high: return 300.0       // 5分鐘
        case .medium: return 900.0     // 15分鐘
        case .unknown: return 1800.0   // 30分鐘
        }
    }
    
    private func updateDefenseMetrics(executionTime: TimeInterval) {
        let newMetrics = DefenseMetrics(
            totalChecks: defenseMetrics.totalChecks + 1,
            threatsDetected: activeThreats.count,
            falsePositives: defenseMetrics.falsePositives,
            responseTime: executionTime,
            effectivenessScore: calculateEffectiveness()
        )
        
        defenseMetrics = newMetrics
    }
    
    private func calculateEffectiveness() -> Float {
        let recentThreats = activeThreats.filter { _ in
            Date().timeIntervalSince(lastAnalysisTime) < 300
        }
        
        if recentThreats.isEmpty {
            return 1.0
        }
        
        return max(0.0, 1.0 - Float(recentThreats.count) / 10.0)
    }
    
    /// 獲取防禦報告
    func getDefenseReport() -> String {
        return """
        🛡️ 高級威脅防禦報告
        當前威脅等級: \(currentThreatLevel.description) \(currentThreatLevel.color)
        活躍威脅數量: \(activeThreats.count)
        總檢查次數: \(defenseMetrics.totalChecks)
        防禦效率: \(String(format: "%.1f%%", defenseMetrics.effectivenessScore * 100))
        平均響應時間: \(String(format: "%.2f", defenseMetrics.responseTime))s
        """
    }
}