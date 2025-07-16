import Foundation
import Network
import CryptoKit

// MARK: - Node Anomaly Tracker (節點異常行為追蹤系統)
class NodeAnomalyTracker {
    private let nodeMonitor = NodeMonitor()
    private let behaviorDatabase = BehaviorDatabase()
    private let alertSystem = AlertSystem()
    private let queue = DispatchQueue(label: "com.signalair.nodeanomaly", qos: .utility)
    
    // 異常檢測閾值
    private struct AnomalyThreshold {
        static let low: Double = 0.3
        static let medium: Double = 0.5
        static let high: Double = 0.7
        static let critical: Double = 0.9
    }
    
    // MARK: - Core Tracking Function
    func trackNodeBehavior(_ nodeID: String, _ activity: NodeActivity) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let behaviorProfile = self.getNodeBehaviorProfile(nodeID)
            let anomalyScore = self.calculateAnomalyScore(activity, behaviorProfile)
            
            // 記錄行為數據
            self.behaviorDatabase.recordActivity(nodeID, activity, anomalyScore)
            
            // 檢查是否需要告警
            if anomalyScore > AnomalyThreshold.high {
                self.triggerNodeAnomalyAlert(nodeID, activity, anomalyScore)
            }
            
            // 更新行為檔案
            self.updateNodeBehaviorProfile(nodeID, activity)
            
            // 檢查是否需要自動響應
            if anomalyScore > AnomalyThreshold.critical {
                self.triggerAutomaticResponse(nodeID, activity, anomalyScore)
            }
        }
    }
    
    // MARK: - Anomaly Score Calculation
    private func calculateAnomalyScore(
        _ activity: NodeActivity, 
        _ profile: NodeBehaviorProfile
    ) -> Double {
        var anomalyScore = 0.0
        
        // 連接模式異常 (30%)
        if isConnectionPatternAnomalous(activity.connectionPattern, profile.normalConnectionPattern) {
            anomalyScore += 0.3
        }
        
        // 數據傳輸異常 (25%)
        if isDataTransferAnomalous(activity.dataTransfer, profile.normalDataTransfer) {
            anomalyScore += 0.25
        }
        
        // 時間模式異常 (20%)
        if isTimingPatternAnomalous(activity.timing, profile.normalTiming) {
            anomalyScore += 0.2
        }
        
        // 網路拓撲異常 (25%)
        if isTopologyBehaviorAnomalous(activity.topologyBehavior, profile.normalTopology) {
            anomalyScore += 0.25
        }
        
        return min(1.0, anomalyScore)
    }
    
    // MARK: - Anomaly Detection Methods
    private func isConnectionPatternAnomalous(
        _ current: ConnectionPattern,
        _ normal: ConnectionPattern
    ) -> Bool {
        // 連接頻率異常
        if current.connectionsPerMinute > normal.connectionsPerMinute * 2 {
            return true
        }
        
        // 連接持續時間異常
        if current.averageConnectionDuration < normal.averageConnectionDuration * 0.1 {
            return true
        }
        
        // 同時連接數異常
        if current.simultaneousConnections > normal.simultaneousConnections * 3 {
            return true
        }
        
        // 連接成功率異常
        if current.successRate < normal.successRate * 0.5 {
            return true
        }
        
        return false
    }
    
    private func isDataTransferAnomalous(
        _ current: DataTransferPattern,
        _ normal: DataTransferPattern
    ) -> Bool {
        // 數據量異常
        if current.bytesPerSecond > normal.bytesPerSecond * 5 {
            return true
        }
        
        // 數據包大小異常
        if current.averagePacketSize > normal.averagePacketSize * 3 {
            return true
        }
        
        // 傳輸頻率異常
        if current.transferFrequency > normal.transferFrequency * 4 {
            return true
        }
        
        // 數據類型異常
        if !normal.commonDataTypes.contains(current.primaryDataType) {
            return true
        }
        
        return false
    }
    
    private func isTimingPatternAnomalous(
        _ current: TimingPattern,
        _ normal: TimingPattern
    ) -> Bool {
        // 活動時間異常
        let currentHour = Calendar.current.component(.hour, from: Date())
        if !normal.activeHours.contains(currentHour) && current.activityLevel > 0.5 {
            return true
        }
        
        // 響應時間異常
        if current.averageResponseTime > normal.averageResponseTime * 2 {
            return true
        }
        
        // 活動間隔異常
        if current.activityInterval < normal.activityInterval * 0.1 {
            return true
        }
        
        return false
    }
    
    private func isTopologyBehaviorAnomalous(
        _ current: TopologyBehavior,
        _ normal: TopologyBehavior
    ) -> Bool {
        // 鄰居數量異常
        if current.neighborCount > normal.neighborCount * 2 {
            return true
        }
        
        // 路由路徑異常
        if current.routeHopCount > normal.routeHopCount * 1.5 {
            return true
        }
        
        // 網路位置異常
        if current.networkDistance > normal.networkDistance * 2 {
            return true
        }
        
        // 拓撲變化頻率異常
        if current.topologyChangeFrequency > normal.topologyChangeFrequency * 3 {
            return true
        }
        
        return false
    }
    
    // MARK: - Alert and Response System
    private func triggerNodeAnomalyAlert(_ nodeID: String, _ activity: NodeActivity, _ score: Double) {
        let alert = NodeAnomalyAlert(
            nodeID: nodeID,
            activity: activity,
            anomalyScore: score,
            timestamp: Date(),
            severity: determineAlertSeverity(score)
        )
        
        alertSystem.sendAlert(alert)
        
        // 記錄告警
        behaviorDatabase.recordAlert(nodeID, alert)
    }
    
    private func triggerAutomaticResponse(_ nodeID: String, _ activity: NodeActivity, _ score: Double) {
        let response = AutomaticResponse(
            nodeID: nodeID,
            responseType: determineResponseType(score),
            activity: activity,
            timestamp: Date()
        )
        
        executeAutomaticResponse(response)
    }
    
    private func determineAlertSeverity(_ score: Double) -> AlertSeverity {
        switch score {
        case 0.9...1.0:
            return .critical
        case 0.7..<0.9:
            return .high
        case 0.5..<0.7:
            return .medium
        default:
            return .low
        }
    }
    
    private func determineResponseType(_ score: Double) -> ResponseType {
        switch score {
        case 0.9...1.0:
            return .isolateNode
        case 0.8..<0.9:
            return .restrictAccess
        case 0.7..<0.8:
            return .enhancedMonitoring
        default:
            return .logActivity
        }
    }
    
    private func executeAutomaticResponse(_ response: AutomaticResponse) {
        switch response.responseType {
        case .isolateNode:
            isolateNode(response.nodeID)
        case .restrictAccess:
            restrictNodeAccess(response.nodeID)
        case .enhancedMonitoring:
            enableEnhancedMonitoring(response.nodeID)
        case .logActivity:
            logActivityForReview(response.nodeID, response.activity)
        }
    }
    
    // MARK: - Node Management
    private func isolateNode(_ nodeID: String) {
        // 隔離節點，斷開所有連接
        nodeMonitor.isolateNode(nodeID)
        
        // 通知網路管理器
        NotificationCenter.default.post(
            name: .nodeIsolated,
            object: NodeIsolationNotification(nodeID: nodeID, reason: "異常行為檢測")
        )
    }
    
    private func restrictNodeAccess(_ nodeID: String) {
        // 限制節點訪問權限
        nodeMonitor.restrictAccess(nodeID)
        
        // 設置訪問限制
        let restriction = AccessRestriction(
            nodeID: nodeID,
            restrictionType: .limitedAccess,
            duration: 3600, // 1小時
            reason: "異常行為檢測"
        )
        
        behaviorDatabase.recordRestriction(nodeID, restriction)
    }
    
    private func enableEnhancedMonitoring(_ nodeID: String) {
        // 啟用增強監控
        nodeMonitor.enableEnhancedMonitoring(nodeID)
        
        // 增加監控頻率
        let monitoringConfig = EnhancedMonitoringConfig(
            nodeID: nodeID,
            monitoringInterval: 1.0, // 每秒檢查
            duration: 1800, // 30分鐘
            alertThreshold: 0.5
        )
        
        nodeMonitor.applyMonitoringConfig(monitoringConfig)
    }
    
    private func logActivityForReview(_ nodeID: String, _ activity: NodeActivity) {
        // 記錄活動供後續審查
        let logEntry = ActivityLogEntry(
            nodeID: nodeID,
            activity: activity,
            timestamp: Date(),
            flagged: true,
            reason: "異常活動檢測"
        )
        
        behaviorDatabase.recordLogEntry(nodeID, logEntry)
    }
    
    // MARK: - Profile Management
    private func getNodeBehaviorProfile(_ nodeID: String) -> NodeBehaviorProfile {
        if let profile = behaviorDatabase.getProfile(nodeID) {
            return profile
        } else {
            // 建立新的行為檔案
            return createNewBehaviorProfile(nodeID)
        }
    }
    
    private func createNewBehaviorProfile(_ nodeID: String) -> NodeBehaviorProfile {
        let profile = NodeBehaviorProfile(
            nodeID: nodeID,
            normalConnectionPattern: ConnectionPattern.default,
            normalDataTransfer: DataTransferPattern.default,
            normalTiming: TimingPattern.default,
            normalTopology: TopologyBehavior.default,
            establishedDate: Date(),
            lastUpdated: Date()
        )
        
        behaviorDatabase.saveProfile(nodeID, profile)
        return profile
    }
    
    private func updateNodeBehaviorProfile(_ nodeID: String, _ activity: NodeActivity) {
        var profile = getNodeBehaviorProfile(nodeID)
        
        // 更新連接模式
        profile.normalConnectionPattern = updateConnectionPattern(
            profile.normalConnectionPattern,
            activity.connectionPattern
        )
        
        // 更新數據傳輸模式
        profile.normalDataTransfer = updateDataTransferPattern(
            profile.normalDataTransfer,
            activity.dataTransfer
        )
        
        // 更新時間模式
        profile.normalTiming = updateTimingPattern(
            profile.normalTiming,
            activity.timing
        )
        
        // 更新拓撲行為
        profile.normalTopology = updateTopologyBehavior(
            profile.normalTopology,
            activity.topologyBehavior
        )
        
        profile.lastUpdated = Date()
        behaviorDatabase.saveProfile(nodeID, profile)
    }
    
    // MARK: - Pattern Update Methods
    private func updateConnectionPattern(
        _ current: ConnectionPattern,
        _ new: ConnectionPattern
    ) -> ConnectionPattern {
        // 使用指數移動平均更新模式
        let alpha = 0.1 // 學習率
        
        return ConnectionPattern(
            connectionsPerMinute: current.connectionsPerMinute * (1 - alpha) + new.connectionsPerMinute * alpha,
            averageConnectionDuration: current.averageConnectionDuration * (1 - alpha) + new.averageConnectionDuration * alpha,
            simultaneousConnections: current.simultaneousConnections * (1 - alpha) + new.simultaneousConnections * alpha,
            successRate: current.successRate * (1 - alpha) + new.successRate * alpha
        )
    }
    
    private func updateDataTransferPattern(
        _ current: DataTransferPattern,
        _ new: DataTransferPattern
    ) -> DataTransferPattern {
        let alpha = 0.1
        
        return DataTransferPattern(
            bytesPerSecond: current.bytesPerSecond * (1 - alpha) + new.bytesPerSecond * alpha,
            averagePacketSize: current.averagePacketSize * (1 - alpha) + new.averagePacketSize * alpha,
            transferFrequency: current.transferFrequency * (1 - alpha) + new.transferFrequency * alpha,
            primaryDataType: new.primaryDataType, // 保持最新的數據類型
            commonDataTypes: Array(Set(current.commonDataTypes + [new.primaryDataType]))
        )
    }
    
    private func updateTimingPattern(
        _ current: TimingPattern,
        _ new: TimingPattern
    ) -> TimingPattern {
        let alpha = 0.1
        
        return TimingPattern(
            activeHours: Array(Set(current.activeHours + [Calendar.current.component(.hour, from: Date())])),
            averageResponseTime: current.averageResponseTime * (1 - alpha) + new.averageResponseTime * alpha,
            activityInterval: current.activityInterval * (1 - alpha) + new.activityInterval * alpha,
            activityLevel: new.activityLevel
        )
    }
    
    private func updateTopologyBehavior(
        _ current: TopologyBehavior,
        _ new: TopologyBehavior
    ) -> TopologyBehavior {
        let alpha = 0.1
        
        return TopologyBehavior(
            neighborCount: current.neighborCount * (1 - alpha) + new.neighborCount * alpha,
            routeHopCount: current.routeHopCount * (1 - alpha) + new.routeHopCount * alpha,
            networkDistance: current.networkDistance * (1 - alpha) + new.networkDistance * alpha,
            topologyChangeFrequency: current.topologyChangeFrequency * (1 - alpha) + new.topologyChangeFrequency * alpha
        )
    }
    
    // MARK: - Analytics and Reporting
    func generateAnomalyReport(for nodeID: String) -> NodeAnomalyReport {
        let activities = behaviorDatabase.getRecentActivities(nodeID, limit: 100)
        let alerts = behaviorDatabase.getRecentAlerts(nodeID, limit: 50)
        let profile = getNodeBehaviorProfile(nodeID)
        
        return NodeAnomalyReport(
            nodeID: nodeID,
            totalActivities: activities.count,
            anomalousActivities: activities.filter { $0.anomalyScore > AnomalyThreshold.medium }.count,
            alerts: alerts,
            averageAnomalyScore: activities.map { $0.anomalyScore }.reduce(0, +) / Double(activities.count),
            riskLevel: calculateRiskLevel(nodeID),
            profile: profile,
            recommendations: generateRecommendations(nodeID)
        )
    }
    
    private func calculateRiskLevel(_ nodeID: String) -> RiskLevel {
        let recentActivities = behaviorDatabase.getRecentActivities(nodeID, limit: 50)
        let recentAlerts = behaviorDatabase.getRecentAlerts(nodeID, limit: 10)
        
        let averageAnomalyScore = recentActivities.map { $0.anomalyScore }.reduce(0, +) / Double(recentActivities.count)
        let alertCount = recentAlerts.count
        
        switch (averageAnomalyScore, alertCount) {
        case (0.8...1.0, _), (_, 5...):
            return .critical
        case (0.6..<0.8, _), (_, 3..<5):
            return .high
        case (0.4..<0.6, _), (_, 1..<3):
            return .medium
        default:
            return .low
        }
    }
    
    private func generateRecommendations(_ nodeID: String) -> [String] {
        let riskLevel = calculateRiskLevel(nodeID)
        var recommendations: [String] = []
        
        switch riskLevel {
        case .critical:
            recommendations.append("建議立即隔離節點")
            recommendations.append("進行深度安全分析")
            recommendations.append("檢查相關節點")
        case .high:
            recommendations.append("限制節點訪問權限")
            recommendations.append("啟用增強監控")
            recommendations.append("審查最近活動")
        case .medium:
            recommendations.append("增加監控頻率")
            recommendations.append("記錄詳細活動日志")
        case .low:
            recommendations.append("維持正常監控")
        }
        
        return recommendations
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let nodeIsolated = Notification.Name("NodeIsolated")
    static let nodeAnomalyDetected = Notification.Name("NodeAnomalyDetected")
    static let enhancedMonitoringEnabled = Notification.Name("EnhancedMonitoringEnabled")
}