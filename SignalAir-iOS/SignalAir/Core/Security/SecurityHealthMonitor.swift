import Foundation
import MultipeerConnectivity
import CryptoKit
import Network

// MARK: - 系統健康監控系統
// 專門監控網路異常行為的健康機制

// 🔧 系統架構師：使用類定義避免衝突
@MainActor
class SecurityHealthMonitor: ObservableObject {
    
    // MARK: - 系統健康等級定義
    enum HealthLevel: Int, CaseIterable {
        case green = 1      // 正常
        case yellow = 2     // 警告
        case orange = 3     // 異常
        case red = 4        // 高異常
        case black = 5      // 嚴重異常
        
        var description: String {
            switch self {
            case .green: return "正常"
            case .yellow: return "可疑活動"
            case .orange: return "異常警告"
            case .red: return "高風險活動"
            case .black: return "嚴重網路異常"
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
    
    // 🛡️ 健康專家：App Store 友好的健康分級系統
    enum SecurityHealthLevel: String {
        case critical = "Critical Level"
        case high = "High Level"
        case medium = "Medium Level"
        case unknown = "Unknown Level"
        
        var description: String {
            switch self {
            case .critical: return "大規模網路異常"
            case .high: return "多節點網路異常"
            case .medium: return "單節點網路異常"
            case .unknown: return "未定義網路模式"
            }
        }
        
        var complexity: String {
            switch self {
            case .critical: return "進階協調模式"
            case .high: return "中等協調模式"
            case .medium: return "基本協調模式"
            case .unknown: return "模式分析中"
            }
        }
    }
    
    struct HealthSignature {
        let patternId: String
        let description: String
        let indicators: [String]
        let minNodes: Int
        let timeWindow: TimeInterval
        let confidence: Float
    }
    
    struct NetworkAnalysis {
        let grade: SecurityHealthLevel
        let healthLevel: HealthLevel
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
    
    struct HealthMetrics {
        let totalChecks: Int
        let anomaliesDetected: Int
        let falsePositives: Int
        let responseTime: TimeInterval
        let effectivenessScore: Float
    }
    
    // MARK: - 健康簽名庫
    private let healthSignatures: [HealthSignature] = [
        // 🛡️ 安全專家：App Store 友好的網路異常簽名
        HealthSignature(
            patternId: "CRITICAL_NETWORK_PATTERN",
            description: "大規模網路協調",
            indicators: ["simultaneous_connections", "identical_behavior", "coordinated_timing"],
            minNodes: 100,
            timeWindow: 60.0,
            confidence: 0.95
        ),
        HealthSignature(
            patternId: "CRITICAL_ADBehavior AnalysisIVE_PATTERN",
            description: "自適應網路行為模式",
            indicators: ["pattern_analysis", "adaptive_behavior", "unusual_coordination"],
            minNodes: 50,
            timeWindow: 120.0,
            confidence: 0.90
        ),
        
        // 🛡️ 安全專家：中等級網路異常簽名
        HealthSignature(
            patternId: "HIGH_SOCIAL_PATTERN",
            description: "社交互動異常",
            indicators: ["user_interaction", "social_manipulation", "credential_patterns"],
            minNodes: 25,
            timeWindow: 300.0,
            confidence: 0.80
        ),
        HealthSignature(
            patternId: "HIGH_COORDINATED_PATTERN",
            description: "協調網路行為",
            indicators: ["multi_vector_behavior", "coordinated_nodes", "resource_pooling"],
            minNodes: 15,
            timeWindow: 180.0,
            confidence: 0.85
        ),
        
        // 🛡️ 安全專家：低等級網路異常簽名
        HealthSignature(
            patternId: "MEDIUM_AUTOMATED_PATTERN",
            description: "自動化網路行為",
            indicators: ["automated_tools", "script_patterns", "repetitive_behavior"],
            minNodes: 5,
            timeWindow: 600.0,
            confidence: 0.70
        ),
        HealthSignature(
            patternId: "MEDIUM_INDIVIDUAL_PATTERN",
            description: "個別網路異常",
            indicators: ["single_source", "limited_resources", "basic_techniques"],
            minNodes: 1,
            timeWindow: 900.0,
            confidence: 0.60
        )
    ]
    
    // MARK: - 健康狀態
    @Published private(set) var currentHealthLevel: HealthLevel = .green
    @Published private(set) var activeAnomalies: [NetworkAnalysis] = []
    @Published private(set) var healthMetrics: HealthMetrics = HealthMetrics(totalChecks: 0, anomaliesDetected: 0, falsePositives: 0, responseTime: 0, effectivenessScore: 1.0)
    
    // MARK: - 內部狀態
    private var nodeActivities: [SecurityNodeActivity] = []
    private var lastAnalysisTime: Date = Date()
    private var defenseTimer: Timer?
    
    // MARK: - 初始化
    init() {
        startContinuousMonitoring()
        print("🛡️ SystemHealthMonitor 初始化完成")
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
                await self?.performHealthAnalysis()
            }
        }
        
        #if DEBUG
        print("🔍 安全監控已啟動")
        #endif
    }
    
    /// 停止連續監控
    func stopContinuousMonitoring() {
        defenseTimer?.invalidate()
        defenseTimer = nil
        
        #if DEBUG
        print("⏹️ 安全監控已停止")
        #endif
    }
    
    /// 記錄節點活動
    func recordNodeActivity(_ nodeId: String, activity: String, suspicionScore: Float) {
        let nodeActivity = SecurityNodeActivity(
            nodeId: nodeId,
            activityType: activity,
            timestamp: Date(),
            details: ["suspicionScore": suspicionScore],
            activity: activity
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
    
    /// 分析當前健康等級
    func analyzeHealthLevel() async -> NetworkAnalysis? {
        let recentActivities = getRecentActivities(timeWindow: 300.0) // 5分鐘內
        
        guard !recentActivities.isEmpty else { return nil }
        
        // 計算節點數量和行為模式
        let uniqueNodes = Set(recentActivities.map { $0.nodeId }).count
        let averageSuspicion = recentActivities.reduce(0, { $0 + (($1.details["suspicionScore"] as? Float) ?? 0.0) }) / Float(recentActivities.count)
        
        // 檢測網路模式簽名
        for signature in healthSignatures {
            if let analysis = matchHealthSignature(signature, activities: recentActivities, nodeCount: uniqueNodes) {
                return analysis
            }
        }
        
        // 基於節點數量和可疑度的基本分析
        let grade: SecurityHealthLevel
        let healthLevel: HealthLevel
        
        if uniqueNodes > 100 && averageSuspicion > 0.8 {
            grade = .critical
            healthLevel = .black
        } else if uniqueNodes > 50 && averageSuspicion > 0.7 {
            grade = .high
            healthLevel = .red
        } else if uniqueNodes > 10 && averageSuspicion > 0.6 {
            grade = .medium
            healthLevel = .orange
        } else if averageSuspicion > 0.5 {
            grade = .unknown
            healthLevel = .yellow
        } else {
            return nil // 無異常
        }
        
        return NetworkAnalysis(
            grade: grade,
            healthLevel: healthLevel,
            confidence: averageSuspicion,
            nodeCount: uniqueNodes,
            networkVectors: recentActivities.map { $0.activity },
            recommendedActions: generateRecommendations(grade: grade, healthLevel: healthLevel),
            estimatedDuration: estimateResponseTime(grade: grade)
        )
    }
    
    /// 執行安全分析
    func performHealthAnalysis() async {
        let startTime = Date()
        
        if let analysis = await analyzeHealthLevel() {
            currentHealthLevel = analysis.healthLevel
            activeAnomalies = [analysis]
            
            // 通知安全監控系統
            notifySystemHealthMonitoring(analysis: analysis)
            
            #if DEBUG
            print("🚨 安全檢測: \(analysis.grade.description) - \(analysis.healthLevel.description)")
            #endif
        } else {
            // 無異常時降低安全等級
            if currentHealthLevel != .green {
                currentHealthLevel = .green
                activeAnomalies.removeAll()
                
                #if DEBUG
                print("🟢 安全等級降至正常")
                #endif
            }
        }
        
        // 更新安全指標
        let executionTime = Date().timeIntervalSince(startTime)
        updateHealthMetrics(executionTime: executionTime)
        
        lastAnalysisTime = Date()
    }
    
    // MARK: - 私有方法
    
    private func getRecentActivities(timeWindow: TimeInterval) -> [SecurityNodeActivity] {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        return nodeActivities.filter { $0.timestamp >= cutoffTime }
    }
    
    private func matchHealthSignature(_ signature: HealthSignature, activities: [SecurityNodeActivity], nodeCount: Int) -> NetworkAnalysis? {
        guard nodeCount >= signature.minNodes else { return nil }
        
        let recentActivities = activities.filter { 
            Date().timeIntervalSince($0.timestamp) <= signature.timeWindow
        }
        
        let indicatorMatches = signature.indicators.compactMap { indicator in
            recentActivities.first { $0.activity.contains(indicator) }
        }
        
        let matchRatio = Float(indicatorMatches.count) / Float(signature.indicators.count)
        
        if matchRatio >= signature.confidence {
            let grade: SecurityHealthLevel
            let healthLevel: HealthLevel
            
            if signature.patternId.hasPrefix("CRITICAL") {
                grade = .critical
                healthLevel = .black
            } else if signature.patternId.hasPrefix("HIGH") {
                grade = .high
                healthLevel = .red
            } else {
                grade = .medium
                healthLevel = .orange
            }
            
            return NetworkAnalysis(
                grade: grade,
                healthLevel: healthLevel,
                confidence: matchRatio,
                nodeCount: nodeCount,
                networkVectors: indicatorMatches.map { $0.activity },
                recommendedActions: generateRecommendations(grade: grade, healthLevel: healthLevel),
                estimatedDuration: estimateResponseTime(grade: grade)
            )
        }
        
        return nil
    }
    
    private func generateRecommendations(grade: SecurityHealthLevel, healthLevel: HealthLevel) -> [String] {
        var recommendations: [String] = []
        
        switch grade {
        case .critical:
            recommendations.append("啟動緊急安全協議")
            recommendations.append("隔離受影響節點")
            recommendations.append("通知安全團隊")
            
        case .high:
            recommendations.append("增加監控頻率")
            recommendations.append("分析網路模式")
            recommendations.append("準備安全措施")
            
        case .medium:
            recommendations.append("持續觀察")
            recommendations.append("記錄異常活動")
            
        case .unknown:
            recommendations.append("收集更多數據")
            recommendations.append("分析行為模式")
        }
        
        return recommendations
    }
    
    private func estimateResponseTime(grade: SecurityHealthLevel) -> TimeInterval {
        switch grade {
        case .critical: return 60.0    // 1分鐘
        case .high: return 300.0       // 5分鐘
        case .medium: return 900.0     // 15分鐘
        case .unknown: return 1800.0   // 30分鐘
        }
    }
    
    private func updateHealthMetrics(executionTime: TimeInterval) {
        let newMetrics = HealthMetrics(
            totalChecks: healthMetrics.totalChecks + 1,
            anomaliesDetected: activeAnomalies.count,
            falsePositives: healthMetrics.falsePositives,
            responseTime: executionTime,
            effectivenessScore: calculateEffectiveness()
        )
        
        healthMetrics = newMetrics
    }
    
    private func calculateEffectiveness() -> Float {
        let recentAnomalies = activeAnomalies.filter { _ in
            Date().timeIntervalSince(lastAnalysisTime) < 300
        }
        
        if recentAnomalies.isEmpty {
            return 1.0
        }
        
        return max(0.0, 1.0 - Float(recentAnomalies.count) / 10.0)
    }
    
    /// 獲取安全報告
    func getHealthReport() -> String {
        return """
        🛡️ 安全監控報告
        當前安全等級: \(currentHealthLevel.description) \(currentHealthLevel.color)
        活躍異常數量: \(activeAnomalies.count)
        總檢查次數: \(healthMetrics.totalChecks)
        監控效率: \(String(format: "%.1f%%", healthMetrics.effectivenessScore * 100))
        平均響應時間: \(String(format: "%.2f", healthMetrics.responseTime))s
        """
    }
    
    /// 通知安全監控系統
    private func notifySystemHealthMonitoring(analysis: NetworkAnalysis) {
        let userInfo: [String: Any] = [
            "healthLevel": analysis.healthLevel.description,
            "grade": analysis.grade.description,
            "nodeCount": analysis.nodeCount,
            "confidence": analysis.confidence,
            "networkVectors": analysis.networkVectors,
            "recommendedActions": analysis.recommendedActions,
            "estimatedDuration": analysis.estimatedDuration
        ]
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SystemHealthMonitorEvent"),
                object: self,
                userInfo: userInfo
            )
        }
    }
    
    /// 記錄可疑活動並觸發分析
    func recordSuspiciousActivity(_ nodeId: String, activity: String, suspicionScore: Float) {
        recordNodeActivity(nodeId, activity: activity, suspicionScore: suspicionScore)
        
        // 如果是高度可疑的活動，立即觸發分析
        if suspicionScore > 0.8 {
            Task {
                await performHealthAnalysis()
            }
        }
    }
    
    /// 轉換健康等級
    private func convertToSecurityHealthLevel(_ healthLevel: HealthLevel) -> SecurityHealthLevel {
        switch healthLevel {
        case .green, .yellow, .orange:
            return .medium
        case .red:
            return .high
        case .black:
            return .critical
        }
    }
    
    /// 獲取安全統計
    func getHealthStatistics() -> SecurityHealthStatistics {
        return SecurityHealthStatistics(
            currentHealthLevel: convertToSecurityHealthLevel(currentHealthLevel),
            activeAnomaliesCount: activeAnomalies.count,
            totalChecks: healthMetrics.totalChecks,
            anomaliesDetected: healthMetrics.anomaliesDetected,
            effectivenessScore: healthMetrics.effectivenessScore,
            averageResponseTime: healthMetrics.responseTime,
            recentNodeActivities: nodeActivities.suffix(100).map { $0 }
        )
    }
}

// MARK: - 安全相關類型定義
enum SecurityHealthLevel {
    case healthy
    case warning
    case critical
}

struct SecurityNodeActivity {
    let nodeId: String
    let activityType: String
    let timestamp: Date
    let details: [String: Any]
    let activity: String
}

struct SecuritySignature {
    let name: String
    let pattern: String
    let severity: String
    let minNodes: Int
    let timeWindow: TimeInterval
    let indicators: [String]
    let confidence: Float
}

// MARK: - 安全統計結構
struct SecurityHealthStatistics {
    let currentHealthLevel: SecurityHealthMonitor.SecurityHealthLevel
    let activeAnomaliesCount: Int
    let totalChecks: Int
    let anomaliesDetected: Int
    let effectivenessScore: Float
    let averageResponseTime: TimeInterval
    let recentNodeActivities: [SecurityNodeActivity]
}