import Foundation
import CryptoKit
import Network

// MARK: - Behavior Analysis System (行為分析系統)
class BehaviorAnalysisSystem {
    private let patternTracker = LongTermPatternTracker()
    private let patternAnalyzer = BehaviorPatternAnalyzer()
    private let responseOrchestrator = ResponseOrchestrator()
    private let intelligenceEngine = BehaviorIntelligenceEngine()
    private let queue = DispatchQueue(label: "com.signalair.behavioranalysis", qos: .utility)
    
    // MARK: - Enhanced Detection Components
    private let enhancedDetection = EnhancedBehaviorDetection()
    private let dataAnomalyDetection = DataExfiltrationDetection.shared
    
    // MARK: - Enhanced Behavior Detection Function
    func detectBehaviorPatterns(_ networkEvents: [NetworkEvent]) -> BehaviorDetectionResult {
        return queue.sync {
            // 傳統模式分析
            let analysisResult = patternAnalyzer.analyzeBehaviorPatterns(networkEvents)
            
            // 增強型通信檢測
            let c2Analysis = enhancedDetection.detectC2Communication(networkEvents)
            
            // 檢測行為分析的五個階段
            let detectedPhases = identifyBehaviorPhases(analysisResult, c2Analysis: c2Analysis)
            
            // 計算異常等級
            let anomalyLevel = determineAnomalyLevel(detectedPhases, c2Analysis: c2Analysis)
            
            // 生成回應策略
            let recommendedResponse = generateBehaviorResponse(detectedPhases, c2Analysis: c2Analysis)
            
            return BehaviorDetectionResult(
                detectedPhases: detectedPhases,
                confidence: calculateConfidence(detectedPhases, c2Analysis: c2Analysis),
                anomalyLevel: anomalyLevel,
                recommendedResponse: recommendedResponse,
                detectionTime: Date(),
                networkEvents: networkEvents,
                c2Analysis: c2Analysis
            )
        }
    }
    
    // MARK: - Enhanced Behavior Phase Identification
    private func identifyBehaviorPhases(_ analysisResult: PatternAnalysisResult, c2Analysis: C2DetectionResult) -> [BehaviorPhase] {
        var detectedPhases: [BehaviorPhase] = []
        
        // 階段1：資訊收集 (Information Gathering)
        if analysisResult.hasReconnaissanceIndicators {
            detectedPhases.append(.informationGathering)
        }
        
        // 階段2：初始存取 (Initial Access)
        if analysisResult.hasInitialCompromiseIndicators {
            detectedPhases.append(.initialAccess)
        }
        
        // 階段3：建立持久性 (Establish Persistence)
        if analysisResult.hasFootholdIndicators {
            detectedPhases.append(.establishPersistence)
        }
        
        // 階段4：橫向移動 (Lateral Movement)
        if analysisResult.hasLateralMovementIndicators {
            detectedPhases.append(.lateralMovement)
        }
        
        // 階段5：資料收集 (Data Collection)
        if analysisResult.hasExfiltrationIndicators {
            detectedPhases.append(.dataCollection)
        }
        
        return detectedPhases
    }
    
    // MARK: - Anomaly Level Determination
    private func determineAnomalyLevel(_ phases: [BehaviorPhase]) -> BehaviorAnomalyLevel {
        switch phases.count {
        case 0:
            return .none
        case 1:
            return .low
        case 2:
            return .medium
        case 3:
            return .high
        case 4...:
            return .critical
        default:
            return .unknown
        }
    }
    
    // MARK: - Response Generation
    private func generateBehaviorResponse(_ phases: [BehaviorPhase]) -> [BehaviorResponse] {
        var responses: [BehaviorResponse] = []
        
        for phase in phases {
            switch phase {
            case .informationGathering:
                responses.append(.enhancedMonitoring)
                responses.append(.networkSegmentation)
            case .initialAccess:
                responses.append(.isolateAffectedNodes)
                responses.append(.forensicAnalysis)
            case .establishPersistence:
                responses.append(.credentialReset)
                responses.append(.systemHardening)
            case .lateralMovement:
                responses.append(.networkIsolation)
                responses.append(.accessRestriction)
            case .dataCollection:
                responses.append(.dataLossDetectionSystem)
                responses.append(.emergencyContainment)
            }
        }
        
        return Array(Set(responses)) // 去重
    }
    
    // MARK: - Confidence Calculation
    private func calculateConfidence(_ phases: [BehaviorPhase]) -> Double {
        guard !phases.isEmpty else { return 0.0 }
        
        let phaseConfidence: [BehaviorPhase: Double] = [
            .informationGathering: 0.6,
            .initialAccess: 0.8,
            .establishPersistence: 0.85,
            .lateralMovement: 0.9,
            .dataCollection: 0.95
        ]
        
        let totalConfidence = phases.compactMap { phaseConfidence[$0] }.reduce(0, +)
        return min(1.0, totalConfidence / Double(phases.count))
    }
    
    // MARK: - Continuous Monitoring
    func startContinuousMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performPeriodicBehaviorScan()
        }
    }
    
    private func performPeriodicBehaviorScan() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 獲取最近的網路事件
            let recentEvents = self.patternTracker.getRecentEvents(timeFrame: 3600) // 1小時
            
            // 執行行為檢測
            let result = self.detectBehaviorPatterns(recentEvents)
            
            // 如果檢測到異常，觸發回應
            if result.anomalyLevel != .none {
                self.handleBehaviorDetection(result)
            }
        }
    }
    
    // MARK: - Behavior Response Handling
    private func handleBehaviorDetection(_ result: BehaviorDetectionResult) {
        // 記錄檢測結果
        patternTracker.recordBehaviorDetection(result)
        
        // 發送告警
        sendBehaviorAlert(result)
        
        // 執行自動回應
        executeBehaviorResponses(result.recommendedResponse)
        
        // 更新行為情報
        intelligenceEngine.updateBehaviorIntelligence(result)
    }
    
    private func sendBehaviorAlert(_ result: BehaviorDetectionResult) {
        let alert = BehaviorAlert(
            anomalyLevel: result.anomalyLevel,
            detectedPhases: result.detectedPhases,
            confidence: result.confidence,
            timestamp: result.detectionTime,
            affectedNodes: extractAffectedNodes(result.networkEvents)
        )
        
        NotificationCenter.default.post(
            name: .behaviorAnomalyDetected,
            object: alert
        )
    }
    
    private func executeBehaviorResponses(_ responses: [BehaviorResponse]) {
        for response in responses {
            responseOrchestrator.executeResponse(response)
        }
    }
    
    private func extractAffectedNodes(_ events: [NetworkEvent]) -> [String] {
        return Array(Set(events.compactMap { $0.sourceNodeID }))
    }
    
    // MARK: - Intelligence Integration
    func updateBehaviorIntelligence(_ indicators: [BehaviorIndicator]) {
        intelligenceEngine.updateIndicators(indicators)
    }
    
    func getBehaviorIntelligenceReport() -> BehaviorIntelligenceReport {
        return intelligenceEngine.generateReport()
    }
}

// MARK: - Long Term Pattern Tracker
class LongTermPatternTracker {
    private var eventHistory: [NetworkEvent] = []
    private var behaviorDetections: [BehaviorDetectionResult] = []
    private let queue = DispatchQueue(label: "com.signalair.patterntracker", qos: .utility)
    
    func recordEvent(_ event: NetworkEvent) {
        queue.sync {
            eventHistory.append(event)
            
            // 保持最近24小時的事件
            let cutoffTime = Date().addingTimeInterval(-24 * 3600)
            eventHistory = eventHistory.filter { $0.timestamp >= cutoffTime }
        }
    }
    
    func getRecentEvents(timeFrame: TimeInterval) -> [NetworkEvent] {
        return queue.sync {
            let cutoffTime = Date().addingTimeInterval(-timeFrame)
            return eventHistory.filter { $0.timestamp >= cutoffTime }
        }
    }
    
    func recordBehaviorDetection(_ result: BehaviorDetectionResult) {
        queue.sync {
            behaviorDetections.append(result)
            
            // 保持最近100個檢測結果
            if behaviorDetections.count > 100 {
                behaviorDetections = Array(behaviorDetections.suffix(100))
            }
        }
    }
    
    func getBehaviorDetectionHistory() -> [BehaviorDetectionResult] {
        return queue.sync { behaviorDetections }
    }
}

// MARK: - Behavior Pattern Analyzer
class BehaviorPatternAnalyzer {
    private let machinelearningModel = BehaviorMLModel()
    private let ruleEngine = BehaviorRuleEngine()
    
    func analyzeBehaviorPatterns(_ events: [NetworkEvent]) -> PatternAnalysisResult {
        // 機器學習分析
        let mlResult = machinelearningModel.analyzeEvents(events)
        
        // 規則引擎分析
        let ruleResult = ruleEngine.analyzeEvents(events)
        
        // 合併結果
        return PatternAnalysisResult(
            hasReconnaissanceIndicators: mlResult.reconnaissance || ruleResult.reconnaissance,
            hasInitialCompromiseIndicators: mlResult.initialCompromise || ruleResult.initialCompromise,
            hasFootholdIndicators: mlResult.foothold || ruleResult.foothold,
            hasLateralMovementIndicators: mlResult.lateralMovement || ruleResult.lateralMovement,
            hasExfiltrationIndicators: mlResult.exfiltration || ruleResult.exfiltration,
            confidence: (mlResult.confidence + ruleResult.confidence) / 2,
            indicators: mlResult.indicators + ruleResult.indicators
        )
    }
}

// MARK: - Behavior Machine Learning Model
class BehaviorMLModel {
    func analyzeEvents(_ events: [NetworkEvent]) -> MLAnalysisResult {
        // 簡化的機器學習模型實現
        var indicators: [BehaviorIndicator] = []
        
        // 資訊收集階段檢測
        let informationGatheringScore = detectInformationGatheringPatterns(events)
        let reconnaissance = informationGatheringScore > 0.7
        
        // 初始存取檢測
        let compromiseScore = detectAccessPatterns(events)
        let initialCompromise = compromiseScore > 0.7
        
        // 建立持久性檢測
        let footholdScore = detectPersistencePatterns(events)
        let foothold = footholdScore > 0.7
        
        // 橫向移動檢測
        let lateralScore = detectLateralMovementPatterns(events)
        let lateralMovement = lateralScore > 0.7
        
        // 資料收集檢測
        let exfiltrationScore = detectDataCollectionPatterns(events)
        let exfiltration = exfiltrationScore > 0.7
        
        let overallConfidence = (informationGatheringScore + compromiseScore + footholdScore + lateralScore + exfiltrationScore) / 5
        
        return MLAnalysisResult(
            reconnaissance: reconnaissance,
            initialCompromise: initialCompromise,
            foothold: foothold,
            lateralMovement: lateralMovement,
            exfiltration: exfiltration,
            confidence: overallConfidence,
            indicators: indicators
        )
    }
    
    private func detectInformationGatheringPatterns(_ events: [NetworkEvent]) -> Double {
        let scanningEvents = events.filter { $0.type == .networkScan }
        let probeEvents = events.filter { $0.type == .serviceProbe }
        
        let score = Double(scanningEvents.count + probeEvents.count) / Double(events.count)
        return min(1.0, score * 2) // 放大係數
    }
    
    private func detectAccessPatterns(_ events: [NetworkEvent]) -> Double {
        let exploitEvents = events.filter { $0.type == .exploitAttempt }
        let authFailures = events.filter { $0.type == .authenticationFailure }
        
        let score = Double(exploitEvents.count + authFailures.count) / Double(events.count)
        return min(1.0, score * 3) // 放大係數
    }
    
    private func detectPersistencePatterns(_ events: [NetworkEvent]) -> Double {
        let persistenceEvents = events.filter { $0.type == .persistenceAttempt }
        let privilegeEvents = events.filter { $0.type == .privilegeEscalation }
        
        let score = Double(persistenceEvents.count + privilegeEvents.count) / Double(events.count)
        return min(1.0, score * 4) // 放大係數
    }
    
    private func detectLateralMovementPatterns(_ events: [NetworkEvent]) -> Double {
        let movementEvents = events.filter { $0.type == .lateralMovement }
        let credentialEvents = events.filter { $0.type == .credentialDumping }
        
        let score = Double(movementEvents.count + credentialEvents.count) / Double(events.count)
        return min(1.0, score * 3) // 放大係數
    }
    
    private func detectDataCollectionPatterns(_ events: [NetworkEvent]) -> Double {
        let exfiltrationEvents = events.filter { $0.type == .dataExfiltration }
        let largeTransfers = events.filter { $0.dataSize > 1024 * 1024 } // 1MB以上
        
        let score = Double(exfiltrationEvents.count + largeTransfers.count) / Double(events.count)
        return min(1.0, score * 2) // 放大係數
    }
}

// MARK: - Behavior Rule Engine
class BehaviorRuleEngine {
    private let rules: [BehaviorRule] = [
        BehaviorRule(name: "Port Scanning Detection", condition: { events in
            events.filter { $0.type == .networkScan }.count > 10
        }),
        BehaviorRule(name: "Brute Force Detection", condition: { events in
            events.filter { $0.type == .authenticationFailure }.count > 20
        }),
        BehaviorRule(name: "Privilege Escalation Detection", condition: { events in
            events.filter { $0.type == .privilegeEscalation }.count > 5
        }),
        BehaviorRule(name: "Data Collection Detection", condition: { events in
            events.filter { $0.type == .dataExfiltration }.count > 3
        })
    ]
    
    func analyzeEvents(_ events: [NetworkEvent]) -> RuleAnalysisResult {
        var triggeredRules: [BehaviorRule] = []
        
        for rule in rules {
            if rule.condition(events) {
                triggeredRules.append(rule)
            }
        }
        
        let confidence = Double(triggeredRules.count) / Double(rules.count)
        
        return RuleAnalysisResult(
            reconnaissance: triggeredRules.contains { $0.name.contains("Scanning") },
            initialCompromise: triggeredRules.contains { $0.name.contains("Brute Force") },
            foothold: triggeredRules.contains { $0.name.contains("Privilege") },
            lateralMovement: false, // 簡化實現
            exfiltration: triggeredRules.contains { $0.name.contains("Data Collection") },
            confidence: confidence,
            indicators: triggeredRules.map { BehaviorIndicator(type: .ruleTriggered, description: $0.name) }
        )
    }
}

// MARK: - Response Orchestrator
class ResponseOrchestrator {
    private let responseQueue = DispatchQueue(label: "com.signalair.response", qos: .utility)
    
    func executeResponse(_ response: BehaviorResponse) {
        responseQueue.async {
            switch response {
            case .enhancedMonitoring:
                self.enableEnhancedMonitoring()
            case .networkSegmentation:
                self.implementNetworkSegmentation()
            case .isolateAffectedNodes:
                self.isolateAffectedNodes()
            case .forensicAnalysis:
                self.startForensicAnalysis()
            case .credentialReset:
                self.resetCredentials()
            case .systemHardening:
                self.hardenSystems()
            case .networkIsolation:
                self.isolateNetwork()
            case .accessRestriction:
                self.restrictAccess()
            case .dataLossDetectionSystem:
                self.activateDataLossDetectionSystem()
            case .emergencyContainment:
                self.executeEmergencyContainment()
            }
        }
    }
    
    private func enableEnhancedMonitoring() {
        print("🔍 啟用增強監控")
        // 實施增強監控邏輯
    }
    
    private func implementNetworkSegmentation() {
        print("🔒 實施網路分段")
        // 實施網路分段邏輯
    }
    
    private func isolateAffectedNodes() {
        print("🚫 隔離受影響節點")
        // 隔離節點邏輯
    }
    
    private func startForensicAnalysis() {
        print("🔬 開始法醫分析")
        // 啟動法醫分析邏輯
    }
    
    private func resetCredentials() {
        print("🔑 重置憑證")
        // 重置憑證邏輯
    }
    
    private func hardenSystems() {
        print("🛡️ 強化系統")
        // 系統強化邏輯
    }
    
    private func isolateNetwork() {
        print("🌐 隔離網路")
        // 網路隔離邏輯
    }
    
    private func restrictAccess() {
        print("🚪 限制訪問")
        // 訪問限制邏輯
    }
    
    private func activateDataLossDetectionSystem() {
        print("🛡️ 啟動數據異常檢測系統")
        // 數據異常檢測邏輯
    }
    
    private func executeEmergencyContainment() {
        print("🚨 執行緊急遏制")
        // 緊急遏制邏輯
    }
}

// MARK: - Behavior Intelligence Engine
class BehaviorIntelligenceEngine {
    private var indicators: [BehaviorIndicator] = []
    private var reports: [BehaviorIntelligenceReport] = []
    private let queue = DispatchQueue(label: "com.signalair.behaviorintel", qos: .utility)
    
    func updateIndicators(_ newIndicators: [BehaviorIndicator]) {
        queue.sync {
            indicators.append(contentsOf: newIndicators)
            
            // 保持最近1000個指標
            if indicators.count > 1000 {
                indicators = Array(indicators.suffix(1000))
            }
        }
    }
    
    func updateBehaviorIntelligence(_ result: BehaviorDetectionResult) {
        queue.sync {
            let newIndicators = result.detectedPhases.map { phase in
                BehaviorIndicator(
                    type: .behaviorPhase,
                    description: "Behavior Phase: \(phase)",
                    severity: .high,
                    confidence: result.confidence
                )
            }
            
            indicators.append(contentsOf: newIndicators)
        }
    }
    
    func generateReport() -> BehaviorIntelligenceReport {
        return queue.sync {
            let report = BehaviorIntelligenceReport(
                indicators: indicators,
                reportDate: Date(),
                anomalyLevel: calculateOverallAnomalyLevel(),
                recommendations: generateRecommendations()
            )
            
            reports.append(report)
            return report
        }
    }
    
    private func calculateOverallAnomalyLevel() -> AnomalyLevel {
        let highSeverityCount = indicators.filter { $0.severity == .high }.count
        let totalCount = indicators.count
        
        guard totalCount > 0 else { return .low }
        
        let ratio = Double(highSeverityCount) / Double(totalCount)
        
        switch ratio {
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
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let highSeverityCount = indicators.filter { $0.severity == .high }.count
        
        if highSeverityCount > 10 {
            recommendations.append("建議啟用緊急響應模式")
            recommendations.append("增加安全監控頻率")
        }
        
        if highSeverityCount > 5 {
            recommendations.append("檢查系統安全配置")
            recommendations.append("更新異常檢測規則")
        }
        
        recommendations.append("定期更新行為情報")
        
        return recommendations
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let behaviorAnomalyDetected = Notification.Name("BehaviorAnomalyDetected")
    static let behaviorResponseExecuted = Notification.Name("BehaviorResponseExecuted")
}