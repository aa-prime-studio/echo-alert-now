import Foundation
import CryptoKit
import Network

// MARK: - APT Defense System (APT攻擊防護系統)
class APTDefenseSystem {
    private let threatTracker = LongTermThreatTracker()
    private let patternAnalyzer = APTPatternAnalyzer()
    private let responseOrchestrator = ResponseOrchestrator()
    private let threatIntelligence = ThreatIntelligenceEngine()
    private let queue = DispatchQueue(label: "com.signalair.aptdefense", qos: .utility)
    
    // MARK: - Enhanced Detection Components
    private let enhancedDetection = EnhancedAPTDetection()
    private let dataExfiltrationDefense = DataExfiltrationDefense.shared
    
    // MARK: - Enhanced APT Detection Function
    func detectAPTPhases(_ networkEvents: [NetworkEvent]) -> APTDetectionResult {
        return queue.sync {
            // 傳統模式分析
            let analysisResult = patternAnalyzer.analyzeAPTPatterns(networkEvents)
            
            // 增強型 C2 檢測
            let c2Analysis = enhancedDetection.detectC2Communication(networkEvents)
            
            // 檢測APT攻擊的五個階段
            let detectedPhases = identifyAPTPhases(analysisResult, c2Analysis: c2Analysis)
            
            // 計算威脅等級
            let threatLevel = determineThreatLevel(detectedPhases, c2Analysis: c2Analysis)
            
            // 生成回應策略
            let recommendedResponse = generateAPTResponse(detectedPhases, c2Analysis: c2Analysis)
            
            return APTDetectionResult(
                detectedPhases: detectedPhases,
                confidence: calculateConfidence(detectedPhases, c2Analysis: c2Analysis),
                threatLevel: threatLevel,
                recommendedResponse: recommendedResponse,
                detectionTime: Date(),
                networkEvents: networkEvents,
                c2Analysis: c2Analysis
            )
        }
    }
    
    // MARK: - Enhanced APT Phase Identification
    private func identifyAPTPhases(_ analysisResult: PatternAnalysisResult, c2Analysis: C2DetectionResult) -> [APTPhase] {
        var detectedPhases: [APTPhase] = []
        
        // 階段1：偵察 (Reconnaissance)
        if analysisResult.hasReconnaissanceIndicators {
            detectedPhases.append(.reconnaissance)
        }
        
        // 階段2：滲透 (Initial Compromise)
        if analysisResult.hasInitialCompromiseIndicators {
            detectedPhases.append(.initialCompromise)
        }
        
        // 階段3：建立據點 (Establish Foothold)
        if analysisResult.hasFootholdIndicators {
            detectedPhases.append(.establishFoothold)
        }
        
        // 階段4：橫向移動 (Lateral Movement)
        if analysisResult.hasLateralMovementIndicators {
            detectedPhases.append(.lateralMovement)
        }
        
        // 階段5：資料外洩 (Data Exfiltration)
        if analysisResult.hasExfiltrationIndicators {
            detectedPhases.append(.dataExfiltration)
        }
        
        return detectedPhases
    }
    
    // MARK: - Threat Level Determination
    private func determineThreatLevel(_ phases: [APTPhase]) -> APTThreatLevel {
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
    private func generateAPTResponse(_ phases: [APTPhase]) -> [APTResponse] {
        var responses: [APTResponse] = []
        
        for phase in phases {
            switch phase {
            case .reconnaissance:
                responses.append(.enhancedMonitoring)
                responses.append(.networkSegmentation)
            case .initialCompromise:
                responses.append(.isolateAffectedNodes)
                responses.append(.forensicAnalysis)
            case .establishFoothold:
                responses.append(.credentialReset)
                responses.append(.systemHardening)
            case .lateralMovement:
                responses.append(.networkIsolation)
                responses.append(.accessRestriction)
            case .dataExfiltration:
                responses.append(.dataLossPreventionSystem)
                responses.append(.emergencyContainment)
            }
        }
        
        return Array(Set(responses)) // 去重
    }
    
    // MARK: - Confidence Calculation
    private func calculateConfidence(_ phases: [APTPhase]) -> Double {
        guard !phases.isEmpty else { return 0.0 }
        
        let phaseConfidence: [APTPhase: Double] = [
            .reconnaissance: 0.6,
            .initialCompromise: 0.8,
            .establishFoothold: 0.85,
            .lateralMovement: 0.9,
            .dataExfiltration: 0.95
        ]
        
        let totalConfidence = phases.compactMap { phaseConfidence[$0] }.reduce(0, +)
        return min(1.0, totalConfidence / Double(phases.count))
    }
    
    // MARK: - Continuous Monitoring
    func startContinuousMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performPeriodicAPTScan()
        }
    }
    
    private func performPeriodicAPTScan() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 獲取最近的網路事件
            let recentEvents = self.threatTracker.getRecentEvents(timeFrame: 3600) // 1小時
            
            // 執行APT檢測
            let result = self.detectAPTPhases(recentEvents)
            
            // 如果檢測到威脅，觸發回應
            if result.threatLevel != .none {
                self.handleAPTDetection(result)
            }
        }
    }
    
    // MARK: - APT Response Handling
    private func handleAPTDetection(_ result: APTDetectionResult) {
        // 記錄檢測結果
        threatTracker.recordAPTDetection(result)
        
        // 發送告警
        sendAPTAlert(result)
        
        // 執行自動回應
        executeAPTResponses(result.recommendedResponse)
        
        // 更新威脅情報
        threatIntelligence.updateThreatIntelligence(result)
    }
    
    private func sendAPTAlert(_ result: APTDetectionResult) {
        let alert = APTAlert(
            threatLevel: result.threatLevel,
            detectedPhases: result.detectedPhases,
            confidence: result.confidence,
            timestamp: result.detectionTime,
            affectedNodes: extractAffectedNodes(result.networkEvents)
        )
        
        NotificationCenter.default.post(
            name: .aptThreatDetected,
            object: alert
        )
    }
    
    private func executeAPTResponses(_ responses: [APTResponse]) {
        for response in responses {
            responseOrchestrator.executeResponse(response)
        }
    }
    
    private func extractAffectedNodes(_ events: [NetworkEvent]) -> [String] {
        return Array(Set(events.compactMap { $0.sourceNodeID }))
    }
    
    // MARK: - Threat Intelligence Integration
    func updateThreatIntelligence(_ indicators: [ThreatIndicator]) {
        threatIntelligence.updateIndicators(indicators)
    }
    
    func getThreatIntelligenceReport() -> ThreatIntelligenceReport {
        return threatIntelligence.generateReport()
    }
}

// MARK: - Long Term Threat Tracker
class LongTermThreatTracker {
    private var eventHistory: [NetworkEvent] = []
    private var aptDetections: [APTDetectionResult] = []
    private let queue = DispatchQueue(label: "com.signalair.threattracker", qos: .utility)
    
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
    
    func recordAPTDetection(_ result: APTDetectionResult) {
        queue.sync {
            aptDetections.append(result)
            
            // 保持最近100個檢測結果
            if aptDetections.count > 100 {
                aptDetections = Array(aptDetections.suffix(100))
            }
        }
    }
    
    func getAPTDetectionHistory() -> [APTDetectionResult] {
        return queue.sync { aptDetections }
    }
}

// MARK: - APT Pattern Analyzer
class APTPatternAnalyzer {
    private let machinelearningModel = APTMLModel()
    private let ruleEngine = APTRuleEngine()
    
    func analyzeAPTPatterns(_ events: [NetworkEvent]) -> PatternAnalysisResult {
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

// MARK: - APT Machine Learning Model
class APTMLModel {
    func analyzeEvents(_ events: [NetworkEvent]) -> MLAnalysisResult {
        // 簡化的機器學習模型實現
        var indicators: [ThreatIndicator] = []
        
        // 偵察階段檢測
        let reconnaissanceScore = detectReconnaissancePatterns(events)
        let reconnaissance = reconnaissanceScore > 0.7
        
        // 初始滲透檢測
        let compromiseScore = detectCompromisePatterns(events)
        let initialCompromise = compromiseScore > 0.7
        
        // 建立據點檢測
        let footholdScore = detectFootholdPatterns(events)
        let foothold = footholdScore > 0.7
        
        // 橫向移動檢測
        let lateralScore = detectLateralMovementPatterns(events)
        let lateralMovement = lateralScore > 0.7
        
        // 資料外洩檢測
        let exfiltrationScore = detectExfiltrationPatterns(events)
        let exfiltration = exfiltrationScore > 0.7
        
        let overallConfidence = (reconnaissanceScore + compromiseScore + footholdScore + lateralScore + exfiltrationScore) / 5
        
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
    
    private func detectReconnaissancePatterns(_ events: [NetworkEvent]) -> Double {
        let scanningEvents = events.filter { $0.type == .networkScan }
        let probeEvents = events.filter { $0.type == .serviceProbe }
        
        let score = Double(scanningEvents.count + probeEvents.count) / Double(events.count)
        return min(1.0, score * 2) // 放大係數
    }
    
    private func detectCompromisePatterns(_ events: [NetworkEvent]) -> Double {
        let exploitEvents = events.filter { $0.type == .exploitAttempt }
        let authFailures = events.filter { $0.type == .authenticationFailure }
        
        let score = Double(exploitEvents.count + authFailures.count) / Double(events.count)
        return min(1.0, score * 3) // 放大係數
    }
    
    private func detectFootholdPatterns(_ events: [NetworkEvent]) -> Double {
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
    
    private func detectExfiltrationPatterns(_ events: [NetworkEvent]) -> Double {
        let exfiltrationEvents = events.filter { $0.type == .dataExfiltration }
        let largeTransfers = events.filter { $0.dataSize > 1024 * 1024 } // 1MB以上
        
        let score = Double(exfiltrationEvents.count + largeTransfers.count) / Double(events.count)
        return min(1.0, score * 2) // 放大係數
    }
}

// MARK: - APT Rule Engine
class APTRuleEngine {
    private let rules: [APTRule] = [
        APTRule(name: "Port Scanning Detection", condition: { events in
            events.filter { $0.type == .networkScan }.count > 10
        }),
        APTRule(name: "Brute Force Detection", condition: { events in
            events.filter { $0.type == .authenticationFailure }.count > 20
        }),
        APTRule(name: "Privilege Escalation Detection", condition: { events in
            events.filter { $0.type == .privilegeEscalation }.count > 5
        }),
        APTRule(name: "Data Exfiltration Detection", condition: { events in
            events.filter { $0.type == .dataExfiltration }.count > 3
        })
    ]
    
    func analyzeEvents(_ events: [NetworkEvent]) -> RuleAnalysisResult {
        var triggeredRules: [APTRule] = []
        
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
            exfiltration: triggeredRules.contains { $0.name.contains("Exfiltration") },
            confidence: confidence,
            indicators: triggeredRules.map { ThreatIndicator(type: .ruleTriggered, description: $0.name) }
        )
    }
}

// MARK: - Response Orchestrator
class ResponseOrchestrator {
    private let responseQueue = DispatchQueue(label: "com.signalair.response", qos: .utility)
    
    func executeResponse(_ response: APTResponse) {
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
            case .dataLossPreventionSystem:
                self.activateDataLossPreventionSystem()
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
    
    private func activateDataLossPreventionSystem() {
        print("🛡️ 啟動數據丟失防護系統")
        // 數據丟失防護邏輯
    }
    
    private func executeEmergencyContainment() {
        print("🚨 執行緊急遏制")
        // 緊急遏制邏輯
    }
}

// MARK: - Threat Intelligence Engine
class ThreatIntelligenceEngine {
    private var indicators: [ThreatIndicator] = []
    private var reports: [ThreatIntelligenceReport] = []
    private let queue = DispatchQueue(label: "com.signalair.threatintel", qos: .utility)
    
    func updateIndicators(_ newIndicators: [ThreatIndicator]) {
        queue.sync {
            indicators.append(contentsOf: newIndicators)
            
            // 保持最近1000個指標
            if indicators.count > 1000 {
                indicators = Array(indicators.suffix(1000))
            }
        }
    }
    
    func updateThreatIntelligence(_ result: APTDetectionResult) {
        queue.sync {
            let newIndicators = result.detectedPhases.map { phase in
                ThreatIndicator(
                    type: .aptPhase,
                    description: "APT Phase: \(phase)",
                    severity: .high,
                    confidence: result.confidence
                )
            }
            
            indicators.append(contentsOf: newIndicators)
        }
    }
    
    func generateReport() -> ThreatIntelligenceReport {
        return queue.sync {
            let report = ThreatIntelligenceReport(
                indicators: indicators,
                reportDate: Date(),
                threatLevel: calculateOverallThreatLevel(),
                recommendations: generateRecommendations()
            )
            
            reports.append(report)
            return report
        }
    }
    
    private func calculateOverallThreatLevel() -> ThreatLevel {
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
            recommendations.append("更新威脅檢測規則")
        }
        
        recommendations.append("定期更新威脅情報")
        
        return recommendations
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let aptThreatDetected = Notification.Name("APTThreatDetected")
    static let aptResponseExecuted = Notification.Name("APTResponseExecuted")
}