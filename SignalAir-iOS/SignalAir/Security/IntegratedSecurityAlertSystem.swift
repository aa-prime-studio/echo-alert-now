import Foundation
import UserNotifications
import os.log

// MARK: - Integrated Security Alert System (整合告警系統)
class IntegratedSecurityAlertSystem {
    static let shared = IntegratedSecurityAlertSystem()
    
    private let alertProcessingQueue = DispatchQueue(label: "com.signalair.alertprocessing", qos: .userInitiated)
    private let alertStorageQueue = DispatchQueue(label: "com.signalair.alertstorage", qos: .utility)
    private let logger = Logger(subsystem: "com.signalair.security", category: "AlertSystem")
    
    // Alert Storage
    private var activeAlerts: [SecurityAlert] = []
    private var alertHistory: [SecurityAlert] = []
    private var alertSubscribers: [AlertSubscriber] = []
    
    // Alert Configuration
    private var alertConfiguration = AlertConfiguration()
    private var alertFilters: [AlertFilter] = []
    
    // Integration Components
    private let trustBehaviorModel = TrustBehaviorModel()
    private let nodeAnomalyTracker = NodeAnomalyTracker()
    private let aptDefenseSystem = APTDefenseSystem()
    
    private init() {
        setupAlertNotifications()
        setupAlertFilters()
        startAlertProcessing()
    }
    
    // MARK: - Alert Management
    func sendAlert(_ alert: SecurityAlert) {
        alertProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 應用過濾器
            if self.shouldFilterAlert(alert) {
                self.logger.debug("Alert filtered: \(alert.id)")
                return
            }
            
            // 檢查重複告警
            if self.isDuplicateAlert(alert) {
                self.logger.debug("Duplicate alert ignored: \(alert.id)")
                return
            }
            
            // 處理告警
            self.processAlert(alert)
        }
    }
    
    private func processAlert(_ alert: SecurityAlert) {
        // 記錄告警
        recordAlert(alert)
        
        // 分類告警
        let classifiedAlert = classifyAlert(alert)
        
        // 確定回應策略
        let responseStrategy = determineResponseStrategy(classifiedAlert)
        
        // 執行回應
        executeResponse(responseStrategy, for: classifiedAlert)
        
        // 通知訂閱者
        notifySubscribers(classifiedAlert)
        
        // 記錄日誌
        logAlert(classifiedAlert)
    }
    
    // MARK: - Alert Classification
    private func classifyAlert(_ alert: SecurityAlert) -> ClassifiedAlert {
        let classification = AlertClassification(
            category: determineAlertCategory(alert),
            priority: determineAlertPriority(alert),
            severity: alert.level.severity,
            urgency: determineAlertUrgency(alert),
            source: alert.source,
            tags: generateAlertTags(alert)
        )
        
        return ClassifiedAlert(
            originalAlert: alert,
            classification: classification,
            correlatedAlerts: findCorrelatedAlerts(alert),
            recommendedActions: generateRecommendedActions(alert),
            estimatedImpact: estimateImpact(alert)
        )
    }
    
    private func determineAlertCategory(_ alert: SecurityAlert) -> AlertCategory {
        switch alert.type {
        case .trustAnomaly:
            return .trustSecurity
        case .nodeAnomaly:
            return .networkSecurity
        case .aptThreat:
            return .advancedThreat
        case .connectionLimit:
            return .networkSecurity
        case .authenticationFailure:
            return .accessSecurity
        case .dataExfiltration:
            return .dataSecurity
        case .systemCompromise:
            return .systemSecurity
        case .malwareDetection:
            return .malwareSecurity
        }
    }
    
    private func determineAlertPriority(_ alert: SecurityAlert) -> AlertPriority {
        let severityScore = alert.level.numericValue
        let urgencyScore = calculateUrgencyScore(alert)
        let impactScore = calculateImpactScore(alert)
        
        let priorityScore = (severityScore * 0.4) + (urgencyScore * 0.3) + (impactScore * 0.3)
        
        switch priorityScore {
        case 0.9...1.0:
            return .critical
        case 0.7..<0.9:
            return .high
        case 0.5..<0.7:
            return .medium
        case 0.3..<0.5:
            return .low
        default:
            return .informational
        }
    }
    
    private func determineAlertUrgency(_ alert: SecurityAlert) -> AlertUrgency {
        let timeSinceAlert = Date().timeIntervalSince(alert.timestamp)
        let alertType = alert.type
        
        switch (alertType, timeSinceAlert) {
        case (.aptThreat, _), (.systemCompromise, _):
            return .immediate
        case (.dataExfiltration, 0..<300):
            return .immediate
        case (.nodeAnomaly, 0..<600):
            return .high
        case (.trustAnomaly, 0..<1800):
            return .medium
        default:
            return .low
        }
    }
    
    // MARK: - Response Strategy
    private func determineResponseStrategy(_ alert: ClassifiedAlert) -> ResponseStrategy {
        let priority = alert.classification.priority
        let category = alert.classification.category
        let severity = alert.classification.severity
        
        var actions: [ResponseAction] = []
        
        switch (priority, category) {
        case (.critical, .advancedThreat), (.critical, .systemSecurity):
            actions.append(.immediateIsolation)
            actions.append(.emergencyNotification)
            actions.append(.forensicInvestigation)
        case (.high, .networkSecurity):
            actions.append(.enhancedMonitoring)
            actions.append(.accessRestriction)
            actions.append(.notifySecurityTeam)
        case (.medium, .trustSecurity):
            actions.append(.increaseObservation)
            actions.append(.logForReview)
        case (.low, _), (.informational, _):
            actions.append(.logForReview)
        default:
            actions.append(.standardResponse)
        }
        
        return ResponseStrategy(
            actions: actions,
            timeline: determineResponseTimeline(priority),
            escalationPath: determineEscalationPath(priority, category),
            requiredApprovals: determineRequiredApprovals(priority)
        )
    }
    
    private func executeResponse(_ strategy: ResponseStrategy, for alert: ClassifiedAlert) {
        for action in strategy.actions {
            executeResponseAction(action, for: alert, strategy: strategy)
        }
    }
    
    private func executeResponseAction(_ action: ResponseAction, for alert: ClassifiedAlert, strategy: ResponseStrategy) {
        switch action {
        case .immediateIsolation:
            performImmediateIsolation(alert)
        case .emergencyNotification:
            sendEmergencyNotification(alert)
        case .forensicInvestigation:
            initiateForensicInvestigation(alert)
        case .enhancedMonitoring:
            enableEnhancedMonitoring(alert)
        case .accessRestriction:
            implementAccessRestriction(alert)
        case .notifySecurityTeam:
            notifySecurityTeam(alert)
        case .increaseObservation:
            increaseObservation(alert)
        case .logForReview:
            logForReview(alert)
        case .standardResponse:
            performStandardResponse(alert)
        }
    }
    
    // MARK: - Alert Correlation
    private func findCorrelatedAlerts(_ alert: SecurityAlert) -> [SecurityAlert] {
        let recentAlerts = getRecentAlerts(timeFrame: 3600) // 1小時內
        
        return recentAlerts.filter { recentAlert in
            isCorrelated(alert, recentAlert)
        }
    }
    
    private func isCorrelated(_ alert1: SecurityAlert, _ alert2: SecurityAlert) -> Bool {
        // 同源頭告警
        if alert1.source == alert2.source && alert1.id != alert2.id {
            return true
        }
        
        // 相似時間窗口
        let timeDifference = abs(alert1.timestamp.timeIntervalSince(alert2.timestamp))
        if timeDifference < 300 { // 5分鐘內
            return true
        }
        
        // 相關告警類型
        if areRelatedTypes(alert1.type, alert2.type) {
            return true
        }
        
        return false
    }
    
    private func areRelatedTypes(_ type1: SecurityAlertType, _ type2: SecurityAlertType) -> Bool {
        let relatedGroups: [[SecurityAlertType]] = [
            [.trustAnomaly, .nodeAnomaly],
            [.aptThreat, .systemCompromise, .dataExfiltration],
            [.connectionLimit, .authenticationFailure],
            [.malwareDetection, .systemCompromise]
        ]
        
        return relatedGroups.contains { group in
            group.contains(type1) && group.contains(type2)
        }
    }
    
    // MARK: - Alert Filtering
    private func shouldFilterAlert(_ alert: SecurityAlert) -> Bool {
        return alertFilters.contains { filter in
            filter.shouldFilter(alert)
        }
    }
    
    private func isDuplicateAlert(_ alert: SecurityAlert) -> Bool {
        let recentAlerts = getRecentAlerts(timeFrame: 300) // 5分鐘內
        
        return recentAlerts.contains { recentAlert in
            recentAlert.source == alert.source &&
            recentAlert.type == alert.type &&
            recentAlert.reason == alert.reason
        }
    }
    
    // MARK: - Alert Storage
    private func recordAlert(_ alert: SecurityAlert) {
        alertStorageQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.activeAlerts.append(alert)
            self.alertHistory.append(alert)
            
            // 清理過期的活動告警
            self.cleanupExpiredAlerts()
            
            // 限制歷史記錄大小
            if self.alertHistory.count > 10000 {
                self.alertHistory = Array(self.alertHistory.suffix(10000))
            }
        }
    }
    
    private func cleanupExpiredAlerts() {
        let expiredThreshold = Date().addingTimeInterval(-alertConfiguration.activeAlertExpiration)
        
        activeAlerts = activeAlerts.filter { alert in
            alert.timestamp > expiredThreshold && !alert.isResolved
        }
    }
    
    // MARK: - Notification Management
    private func setupAlertNotifications() {
        // 註冊通知類型
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrustAnomalyNotification),
            name: .trustAnomalyDetected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNodeAnomalyNotification),
            name: .nodeAnomalyDetected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAPTThreatNotification),
            name: .aptThreatDetected,
            object: nil
        )
    }
    
    @objc private func handleTrustAnomalyNotification(_ notification: Notification) {
        guard let anomalyResult = notification.object as? TrustAnomalyResult else { return }
        
        let alert = SecurityAlert(
            id: UUID(),
            level: mapAnomalyToAlertLevel(anomalyResult),
            source: anomalyResult.userID ?? "Unknown",
            type: .trustAnomaly,
            reason: "Trust behavior anomaly detected",
            timestamp: Date(),
            isResolved: false,
            metadata: [
                "anomalyType": anomalyResult.anomalyType,
                "confidenceLevel": anomalyResult.confidenceLevel,
                "trustScore": anomalyResult.trustScore
            ]
        )
        
        sendAlert(alert)
    }
    
    @objc private func handleNodeAnomalyNotification(_ notification: Notification) {
        guard let nodeAlert = notification.object as? NodeAnomalyAlert else { return }
        
        let alert = SecurityAlert(
            id: UUID(),
            level: mapNodeAlertToSecurityLevel(nodeAlert),
            source: nodeAlert.nodeID,
            type: .nodeAnomaly,
            reason: "Node anomaly detected",
            timestamp: nodeAlert.timestamp,
            isResolved: false,
            metadata: [
                "anomalyScore": nodeAlert.anomalyScore,
                "severity": nodeAlert.severity
            ]
        )
        
        sendAlert(alert)
    }
    
    @objc private func handleAPTThreatNotification(_ notification: Notification) {
        guard let aptAlert = notification.object as? APTAlert else { return }
        
        let alert = SecurityAlert(
            id: UUID(),
            level: mapAPTThreatToSecurityLevel(aptAlert),
            source: aptAlert.affectedNodes.joined(separator: ","),
            type: .aptThreat,
            reason: "APT threat detected",
            timestamp: aptAlert.timestamp,
            isResolved: false,
            metadata: [
                "threatLevel": aptAlert.threatLevel,
                "detectedPhases": aptAlert.detectedPhases,
                "confidence": aptAlert.confidence
            ]
        )
        
        sendAlert(alert)
    }
    
    // MARK: - Response Actions Implementation
    private func performImmediateIsolation(_ alert: ClassifiedAlert) {
        logger.critical("Performing immediate isolation for alert: \(alert.originalAlert.id)")
        
        // 隔離受影響的節點
        let affectedNodes = extractAffectedNodes(alert)
        for nodeID in affectedNodes {
            nodeAnomalyTracker.trackNodeBehavior(nodeID, createIsolationActivity(nodeID))
        }
    }
    
    private func sendEmergencyNotification(_ alert: ClassifiedAlert) {
        logger.critical("Sending emergency notification for alert: \(alert.originalAlert.id)")
        
        // 發送緊急通知
        let emergencyNotification = EmergencyNotification(
            alert: alert,
            recipients: alertConfiguration.emergencyContacts,
            priority: .critical
        )
        
        deliverEmergencyNotification(emergencyNotification)
    }
    
    private func initiateForensicInvestigation(_ alert: ClassifiedAlert) {
        logger.info("Initiating forensic investigation for alert: \(alert.originalAlert.id)")
        
        let investigation = ForensicInvestigation(
            alertID: alert.originalAlert.id,
            investigationType: .securityIncident,
            priority: alert.classification.priority,
            estimatedDuration: TimeInterval(3600) // 1小時
        )
        
        ForensicInvestigationManager.shared.startInvestigation(investigation)
    }
    
    private func enableEnhancedMonitoring(_ alert: ClassifiedAlert) {
        logger.info("Enabling enhanced monitoring for alert: \(alert.originalAlert.id)")
        
        let affectedNodes = extractAffectedNodes(alert)
        for nodeID in affectedNodes {
            let config = EnhancedMonitoringConfig(
                nodeID: nodeID,
                monitoringInterval: 10.0,
                duration: 3600.0,
                alertThreshold: 0.3
            )
            
            NodeMonitor().applyMonitoringConfig(config)
        }
    }
    
    private func implementAccessRestriction(_ alert: ClassifiedAlert) {
        logger.info("Implementing access restriction for alert: \(alert.originalAlert.id)")
        
        let affectedNodes = extractAffectedNodes(alert)
        for nodeID in affectedNodes {
            let restriction = AccessRestriction(
                nodeID: nodeID,
                restrictionType: .limitedAccess,
                duration: 1800, // 30分鐘
                reason: "Security alert response"
            )
            
            AccessControlManager.shared.applyRestriction(restriction)
        }
    }
    
    private func notifySecurityTeam(_ alert: ClassifiedAlert) {
        logger.info("Notifying security team for alert: \(alert.originalAlert.id)")
        
        let notification = SecurityTeamNotification(
            alert: alert,
            priority: alert.classification.priority,
            requiresResponse: true
        )
        
        SecurityTeamManager.shared.sendNotification(notification)
    }
    
    private func increaseObservation(_ alert: ClassifiedAlert) {
        logger.debug("Increasing observation for alert: \(alert.originalAlert.id)")
        
        let affectedNodes = extractAffectedNodes(alert)
        for nodeID in affectedNodes {
            ObservationManager.shared.increaseObservationLevel(nodeID)
        }
    }
    
    private func logForReview(_ alert: ClassifiedAlert) {
        logger.debug("Logging alert for review: \(alert.originalAlert.id)")
        
        let reviewItem = ReviewItem(
            alert: alert,
            priority: alert.classification.priority,
            assignedTo: "SecurityAnalyst",
            dueDate: Date().addingTimeInterval(24 * 3600) // 24小時後
        )
        
        ReviewManager.shared.addReviewItem(reviewItem)
    }
    
    private func performStandardResponse(_ alert: ClassifiedAlert) {
        logger.info("Performing standard response for alert: \(alert.originalAlert.id)")
        
        // 標準回應邏輯
        logForReview(alert)
        
        if alert.classification.priority == .medium {
            increaseObservation(alert)
        }
    }
    
    // MARK: - Utility Methods
    private func extractAffectedNodes(_ alert: ClassifiedAlert) -> [String] {
        return alert.originalAlert.source.components(separatedBy: ",")
    }
    
    private func createIsolationActivity(_ nodeID: String) -> NodeActivity {
        return NodeActivity(
            nodeID: nodeID,
            timestamp: Date(),
            connectionPattern: ConnectionPattern.default,
            dataTransfer: DataTransferPattern.default,
            timing: TimingPattern.default,
            topologyBehavior: TopologyBehavior.default,
            metadata: ["action": "isolation", "reason": "security_alert"]
        )
    }
    
    private func mapAnomalyToAlertLevel(_ anomaly: TrustAnomalyResult) -> SecurityAlertLevel {
        switch anomaly.confidenceLevel {
        case 0.8...1.0:
            return .critical
        case 0.6..<0.8:
            return .high
        case 0.4..<0.6:
            return .medium
        default:
            return .low
        }
    }
    
    private func mapNodeAlertToSecurityLevel(_ nodeAlert: NodeAnomalyAlert) -> SecurityAlertLevel {
        switch nodeAlert.severity {
        case .critical:
            return .critical
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }
    
    private func mapAPTThreatToSecurityLevel(_ aptAlert: APTAlert) -> SecurityAlertLevel {
        switch aptAlert.threatLevel {
        case .critical:
            return .critical
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        case .none:
            return .low
        case .unknown:
            return .medium
        }
    }
    
    // MARK: - Configuration and Setup
    private func setupAlertFilters() {
        alertFilters = [
            DuplicateAlertFilter(timeWindow: 300),
            SeverityFilter(minimumLevel: .low),
            RateLimitFilter(maxAlertsPerMinute: 10)
        ]
    }
    
    private func startAlertProcessing() {
        // 啟動告警處理循環
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performPeriodicMaintenance()
        }
    }
    
    private func performPeriodicMaintenance() {
        alertStorageQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.cleanupExpiredAlerts()
            self.updateAlertStatistics()
            self.checkAlertThresholds()
        }
    }
    
    private func updateAlertStatistics() {
        // 更新告警統計
        let stats = AlertStatistics(
            activeAlerts: activeAlerts.count,
            resolvedAlerts: alertHistory.filter { $0.isResolved }.count,
            averageResolutionTime: calculateAverageResolutionTime(),
            alertsByType: calculateAlertsByType()
        )
        
        AlertStatisticsManager.shared.updateStatistics(stats)
    }
    
    private func checkAlertThresholds() {
        let activeCount = activeAlerts.count
        
        if activeCount > alertConfiguration.highAlertThreshold {
            logger.warning("High alert threshold exceeded: \(activeCount)")
            sendThresholdExceededNotification()
        }
    }
    
    // MARK: - Public Interface
    func getActiveAlerts() -> [SecurityAlert] {
        return alertStorageQueue.sync { activeAlerts }
    }
    
    func getAlertHistory(limit: Int = 100) -> [SecurityAlert] {
        return alertStorageQueue.sync { Array(alertHistory.suffix(limit)) }
    }
    
    func resolveAlert(_ alertID: UUID) {
        alertStorageQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.activeAlerts.firstIndex(where: { $0.id == alertID }) {
                self.activeAlerts[index].isResolved = true
                self.activeAlerts[index].resolvedTime = Date()
            }
            
            if let index = self.alertHistory.firstIndex(where: { $0.id == alertID }) {
                self.alertHistory[index].isResolved = true
                self.alertHistory[index].resolvedTime = Date()
            }
        }
    }
    
    func subscribeToAlerts(_ subscriber: AlertSubscriber) {
        alertSubscribers.append(subscriber)
    }
    
    func unsubscribeFromAlerts(_ subscriberID: UUID) {
        alertSubscribers.removeAll { $0.id == subscriberID }
    }
    
    // MARK: - Helper Methods
    private func calculateUrgencyScore(_ alert: SecurityAlert) -> Double {
        let timeSinceAlert = Date().timeIntervalSince(alert.timestamp)
        let urgencyDecay = min(timeSinceAlert / 3600, 1.0) // 1小時內最高
        
        return 1.0 - urgencyDecay
    }
    
    private func calculateImpactScore(_ alert: SecurityAlert) -> Double {
        switch alert.type {
        case .aptThreat, .systemCompromise:
            return 1.0
        case .dataExfiltration:
            return 0.9
        case .nodeAnomaly:
            return 0.7
        case .trustAnomaly:
            return 0.6
        case .authenticationFailure:
            return 0.5
        case .connectionLimit:
            return 0.4
        case .malwareDetection:
            return 0.8
        }
    }
    
    private func generateAlertTags(_ alert: SecurityAlert) -> [String] {
        var tags: [String] = []
        
        tags.append(alert.type.rawValue)
        tags.append(alert.level.rawValue)
        
        if let metadata = alert.metadata {
            if let anomalyType = metadata["anomalyType"] {
                tags.append("anomaly_\(anomalyType)")
            }
            
            if let severity = metadata["severity"] {
                tags.append("severity_\(severity)")
            }
        }
        
        return tags
    }
    
    private func generateRecommendedActions(_ alert: SecurityAlert) -> [String] {
        switch alert.type {
        case .aptThreat:
            return ["隔離受影響節點", "啟動事件回應", "進行法醫調查"]
        case .trustAnomaly:
            return ["增加監控", "審查用戶行為", "更新信任基線"]
        case .nodeAnomaly:
            return ["檢查節點狀態", "限制節點權限", "監控網路活動"]
        case .systemCompromise:
            return ["立即隔離", "重置憑證", "掃描惡意軟體"]
        case .dataExfiltration:
            return ["阻止數據傳輸", "調查洩露範圍", "通知相關方"]
        case .authenticationFailure:
            return ["檢查認證日誌", "更新認證機制", "監控後續嘗試"]
        case .connectionLimit:
            return ["調整連接限制", "分析連接模式", "實施速率限制"]
        case .malwareDetection:
            return ["隔離感染設備", "清除惡意軟體", "更新防護定義"]
        }
    }
    
    private func estimateImpact(_ alert: SecurityAlert) -> ImpactEstimate {
        let severity = alert.level
        let alertType = alert.type
        
        let financialImpact = estimateFinancialImpact(severity, alertType)
        let operationalImpact = estimateOperationalImpact(severity, alertType)
        let reputationalImpact = estimateReputationalImpact(severity, alertType)
        
        return ImpactEstimate(
            financial: financialImpact,
            operational: operationalImpact,
            reputational: reputationalImpact,
            overall: (financialImpact + operationalImpact + reputationalImpact) / 3
        )
    }
    
    private func estimateFinancialImpact(_ severity: SecurityAlertLevel, _ type: SecurityAlertType) -> Double {
        let baseImpact = severity.numericValue
        let typeMultiplier = type.impactMultiplier
        
        return min(1.0, baseImpact * typeMultiplier)
    }
    
    private func estimateOperationalImpact(_ severity: SecurityAlertLevel, _ type: SecurityAlertType) -> Double {
        return severity.numericValue * type.operationalImpactMultiplier
    }
    
    private func estimateReputationalImpact(_ severity: SecurityAlertLevel, _ type: SecurityAlertType) -> Double {
        return severity.numericValue * type.reputationalImpactMultiplier
    }
    
    private func getRecentAlerts(timeFrame: TimeInterval) -> [SecurityAlert] {
        let cutoffTime = Date().addingTimeInterval(-timeFrame)
        return alertHistory.filter { $0.timestamp >= cutoffTime }
    }
    
    private func calculateAverageResolutionTime() -> TimeInterval {
        let resolvedAlerts = alertHistory.filter { $0.isResolved && $0.resolvedTime != nil }
        
        guard !resolvedAlerts.isEmpty else { return 0 }
        
        let totalTime = resolvedAlerts.compactMap { alert in
            guard let resolvedTime = alert.resolvedTime else { return nil }
            return resolvedTime.timeIntervalSince(alert.timestamp)
        }.reduce(0, +)
        
        return totalTime / Double(resolvedAlerts.count)
    }
    
    private func calculateAlertsByType() -> [SecurityAlertType: Int] {
        return Dictionary(grouping: alertHistory, by: { $0.type })
            .mapValues { $0.count }
    }
    
    private func determineResponseTimeline(_ priority: AlertPriority) -> ResponseTimeline {
        switch priority {
        case .critical:
            return ResponseTimeline(immediate: 0, short: 300, medium: 1800, long: 3600)
        case .high:
            return ResponseTimeline(immediate: 300, short: 1800, medium: 3600, long: 7200)
        case .medium:
            return ResponseTimeline(immediate: 1800, short: 3600, medium: 7200, long: 24 * 3600)
        case .low:
            return ResponseTimeline(immediate: 3600, short: 7200, medium: 24 * 3600, long: 48 * 3600)
        case .informational:
            return ResponseTimeline(immediate: 7200, short: 24 * 3600, medium: 48 * 3600, long: 168 * 3600)
        }
    }
    
    private func determineEscalationPath(_ priority: AlertPriority, _ category: AlertCategory) -> EscalationPath {
        switch (priority, category) {
        case (.critical, .advancedThreat):
            return EscalationPath(levels: ["SecurityAnalyst", "SecurityManager", "CISO", "CEO"])
        case (.high, .systemSecurity):
            return EscalationPath(levels: ["SecurityAnalyst", "SecurityManager", "CTO"])
        case (.medium, _):
            return EscalationPath(levels: ["SecurityAnalyst", "SecurityManager"])
        default:
            return EscalationPath(levels: ["SecurityAnalyst"])
        }
    }
    
    private func determineRequiredApprovals(_ priority: AlertPriority) -> [String] {
        switch priority {
        case .critical:
            return ["SecurityManager", "CISO"]
        case .high:
            return ["SecurityManager"]
        case .medium:
            return ["SecurityAnalyst"]
        default:
            return []
        }
    }
    
    private func notifySubscribers(_ alert: ClassifiedAlert) {
        for subscriber in alertSubscribers {
            if subscriber.isInterestedIn(alert) {
                subscriber.receiveAlert(alert)
            }
        }
    }
    
    private func logAlert(_ alert: ClassifiedAlert) {
        let logLevel = mapAlertLevelToLogLevel(alert.classification.severity)
        
        switch logLevel {
        case .critical:
            logger.critical("Critical alert: \(alert.originalAlert.reason)")
        case .high:
            logger.error("High priority alert: \(alert.originalAlert.reason)")
        case .medium:
            logger.warning("Medium priority alert: \(alert.originalAlert.reason)")
        case .low:
            logger.info("Low priority alert: \(alert.originalAlert.reason)")
        }
    }
    
    private func mapAlertLevelToLogLevel(_ severity: AlertSeverity) -> LogLevel {
        switch severity {
        case .critical:
            return .critical
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }
    
    private func deliverEmergencyNotification(_ notification: EmergencyNotification) {
        // 實施緊急通知邏輯
        logger.critical("Emergency notification sent: \(notification.alert.originalAlert.reason)")
    }
    
    private func sendThresholdExceededNotification() {
        let notification = ThresholdExceededNotification(
            type: .highAlertCount,
            currentValue: activeAlerts.count,
            threshold: alertConfiguration.highAlertThreshold,
            timestamp: Date()
        )
        
        NotificationCenter.default.post(
            name: .alertThresholdExceeded,
            object: notification
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let alertThresholdExceeded = Notification.Name("AlertThresholdExceeded")
    static let securityResponseExecuted = Notification.Name("SecurityResponseExecuted")
}

// MARK: - Singleton Managers (Placeholder implementations)
class ForensicInvestigationManager {
    static let shared = ForensicInvestigationManager()
    
    func startInvestigation(_ investigation: ForensicInvestigation) {
        // 實施法醫調查邏輯
        print("🔬 Starting forensic investigation: \(investigation.alertID)")
    }
}

class AccessControlManager {
    static let shared = AccessControlManager()
    
    func applyRestriction(_ restriction: AccessRestriction) {
        // 實施訪問控制邏輯
        print("🔒 Applying access restriction: \(restriction.nodeID)")
    }
}

class SecurityTeamManager {
    static let shared = SecurityTeamManager()
    
    func sendNotification(_ notification: SecurityTeamNotification) {
        // 實施安全團隊通知邏輯
        print("👥 Notifying security team: \(notification.alert.originalAlert.reason)")
    }
}

class ObservationManager {
    static let shared = ObservationManager()
    
    func increaseObservationLevel(_ nodeID: String) {
        // 實施觀察級別增加邏輯
        print("👁️ Increasing observation level for: \(nodeID)")
    }
}

class ReviewManager {
    static let shared = ReviewManager()
    
    func addReviewItem(_ item: ReviewItem) {
        // 實施審查項目添加邏輯
        print("📝 Adding review item: \(item.alert.originalAlert.reason)")
    }
}

class AlertStatisticsManager {
    static let shared = AlertStatisticsManager()
    
    func updateStatistics(_ stats: AlertStatistics) {
        // 實施統計更新邏輯
        print("📊 Updating alert statistics: \(stats.activeAlerts) active alerts")
    }
}