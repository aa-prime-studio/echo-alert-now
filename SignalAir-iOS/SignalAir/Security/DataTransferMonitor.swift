import Foundation
import CryptoKit
import Combine

// MARK: - Enhanced Data Transfer Monitoring System
// 增強型數據傳輸監控系統

public class DataTransferMonitor {
    
    // MARK: - Singleton
    public static let shared = DataTransferMonitor()
    
    // MARK: - Properties
    private let detectionQueue = DispatchQueue(label: "com.signalair.transfer-monitor", qos: .userInitiated)
    private var activeMonitors: [TransferMonitor] = []
    private var blockedTransfers: Set<String> = []
    private var suspiciousPatterns: [SuspiciousPattern] = []
    
    // Configuration
    private let fragmentDetectionThreshold = 0.7
    private let tunnelDetectionThreshold = 0.8
    private let maxFragmentSize = 1024 * 10 // 10KB
    private let suspiciousEntropyThreshold = 7.0
    
    private init() {
        setupDefaultPatterns()
        startMonitoring()
    }
    
    // MARK: - Main Detection Interface
    public func analyzeDataTransfer(_ transfer: DataTransferRequest) -> DataTransferAnalysis {
        // 1. 基本檢查
        let basicCheck = performBasicChecks(transfer)
        if basicCheck.shouldBlock {
            return DataTransferAnalysis(
                allowed: false,
                risk: .critical,
                reason: basicCheck.reason,
                recommendations: basicCheck.recommendations
            )
        }
        
        // 2. 分片檢測
        let fragmentAnalysis = analyzeForFragmentation(transfer)
        
        // 3. 隧道檢測
        let tunnelAnalysis = analyzeForTunneling(transfer)
        
        // 4. 內容分析
        let contentAnalysis = analyzeContent(transfer)
        
        // 5. 行為分析
        let behaviorAnalysis = analyzeBehavior(transfer)
        
        // 綜合評估
        return synthesizeAnalysis(
            transfer: transfer,
            fragment: fragmentAnalysis,
            tunnel: tunnelAnalysis,
            content: contentAnalysis,
            behavior: behaviorAnalysis
        )
    }
    
    // MARK: - Fragment Detection Enhancement
    private func analyzeForFragmentation(_ transfer: DataTransferRequest) -> FragmentAnalysis {
        var indicators: [FragmentIndicator] = []
        
        // 1. 檢查數據大小模式
        if let sizePattern = detectSizePattern(transfer) {
            indicators.append(sizePattern)
        }
        
        // 2. 檢查時間模式
        if let timePattern = detectTimePattern(transfer) {
            indicators.append(timePattern)
        }
        
        // 3. 檢查數據頭部
        if let headerPattern = detectHeaderPattern(transfer.data) {
            indicators.append(headerPattern)
        }
        
        // 4. 檢查關聯性
        if let correlation = detectCorrelation(transfer) {
            indicators.append(correlation)
        }
        
        // 5. 機器學習檢測
        if let mlDetection = performMLFragmentDetection(transfer) {
            indicators.append(mlDetection)
        }
        
        let confidence = calculateFragmentConfidence(indicators)
        
        return FragmentAnalysis(
            isFragmented: confidence > fragmentDetectionThreshold,
            confidence: confidence,
            indicators: indicators.map { "\($0.type)" },
            estimatedTotalSize: estimateTotalSize(transfer, indicators),
            fragmentPosition: determineFragmentPosition(transfer, indicators)?.rawValue
        )
    }
    
    // MARK: - Tunnel Detection Enhancement
    private func analyzeForTunneling(_ transfer: DataTransferRequest) -> TunnelAnalysis {
        var tunnelIndicators: [TunnelIndicator] = []
        
        // 1. 熵分析
        let entropy = calculateEntropy(transfer.data)
        if entropy > suspiciousEntropyThreshold {
            tunnelIndicators.append(TunnelIndicator(
                type: .highEntropy,
                confidence: min(entropy / 8.0, 1.0),
                details: ["entropy": entropy]
            ))
        }
        
        // 2. 協議異常檢測
        if let protocolAnomaly = detectProtocolAnomaly(transfer) {
            tunnelIndicators.append(protocolAnomaly)
        }
        
        // 3. 加密模式識別
        if let encryptionPattern = detectEncryptionPattern(transfer.data) {
            tunnelIndicators.append(encryptionPattern)
        }
        
        // 4. 流量模式分析
        if let trafficPattern = analyzeTrafficPattern(transfer) {
            tunnelIndicators.append(trafficPattern)
        }
        
        // 5. 端點分析
        if let endpointAnomaly = analyzeEndpoint(transfer) {
            tunnelIndicators.append(endpointAnomaly)
        }
        
        let confidence = calculateTunnelConfidence(tunnelIndicators)
        
        return TunnelAnalysis(
            isTunneled: confidence > tunnelDetectionThreshold,
            confidence: confidence,
            tunnelType: determineTunnelType(tunnelIndicators)?.rawValue,
            indicators: tunnelIndicators.map { "\($0.type)" },
            decryptionHint: generateDecryptionHint(tunnelIndicators)
        )
    }
    
    // MARK: - Advanced Detection Methods
    private func detectSizePattern(_ transfer: DataTransferRequest) -> FragmentIndicator? {
        // 檢查是否符合常見分片大小
        let commonFragmentSizes = [1024, 2048, 4096, 8192, 16384]
        let dataSize = transfer.data.count
        
        // 檢查固定大小分片
        for size in commonFragmentSizes {
            if dataSize == size || dataSize % size == 0 {
                return FragmentIndicator(
                    type: .fixedSize,
                    confidence: 0.8,
                    details: ["size": dataSize, "pattern": "fixed"]
                )
            }
        }
        
        // 檢查接近最大值的分片
        if dataSize > Int(Double(maxFragmentSize) * 0.9) && dataSize <= maxFragmentSize {
            return FragmentIndicator(
                type: .nearMaxSize,
                confidence: 0.7,
                details: ["size": dataSize, "maxSize": maxFragmentSize]
            )
        }
        
        return nil
    }
    
    private func detectTimePattern(_ transfer: DataTransferRequest) -> FragmentIndicator? {
        // 獲取最近的傳輸記錄
        let recentTransfers = getRecentTransfers(from: transfer.source, within: 300) // 5分鐘內
        
        if recentTransfers.count >= 2 {
            // 計算時間間隔
            let intervals = calculateTimeIntervals(recentTransfers)
            let regularityScore = calculateRegularity(intervals)
            
            if regularityScore > 0.7 {
                return FragmentIndicator(
                    type: .regularTiming,
                    confidence: regularityScore,
                    details: [
                        "intervals": intervals,
                        "regularity": regularityScore
                    ]
                )
            }
        }
        
        return nil
    }
    
    private func detectHeaderPattern(_ data: Data) -> FragmentIndicator? {
        // 檢查常見的分片頭部模式
        let headerPatterns = [
            Data([0xFF, 0xFE]), // 常見分片標記
            Data([0x50, 0x4B]), // ZIP 格式
            Data([0x1F, 0x8B]), // GZIP 格式
        ]
        
        for pattern in headerPatterns {
            if data.starts(with: pattern) {
                return FragmentIndicator(
                    type: .headerMarker,
                    confidence: 0.9,
                    details: ["pattern": pattern.hexString]
                )
            }
        }
        
        // 檢查自定義序列標記
        if let sequenceInfo = extractSequenceInfo(data) {
            return FragmentIndicator(
                type: .sequenceMarker,
                confidence: 0.85,
                details: sequenceInfo
            )
        }
        
        return nil
    }
    
    private func detectEncryptionPattern(_ data: Data) -> TunnelIndicator? {
        // 分析數據模式
        let patternAnalysis = analyzeDataPattern(data)
        
        // 檢測已知加密算法特徵
        if let algorithm = detectKnownEncryption(data) {
            return TunnelIndicator(
                type: .knownEncryption,
                confidence: 0.9,
                details: ["algorithm": algorithm]
            )
        }
        
        // 檢測自定義加密
        if patternAnalysis.isLikelyEncrypted && patternAnalysis.entropy > 7.0 {
            return TunnelIndicator(
                type: .customEncryption,
                confidence: patternAnalysis.confidence,
                details: [
                    "entropy": patternAnalysis.entropy,
                    "blockSize": patternAnalysis.detectedBlockSize
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - ML Detection
    private func performMLFragmentDetection(_ transfer: DataTransferRequest) -> FragmentIndicator? {
        // 提取特徵
        let features = extractMLFeatures(transfer)
        
        // 使用預訓練模型進行預測
        let prediction = fragmentDetectionModel.predict(features)
        
        if prediction.isFragment {
            return FragmentIndicator(
                type: .mlDetected,
                confidence: prediction.confidence,
                details: [
                    "features": features,
                    "modelVersion": "1.0"
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Synthesis and Decision
    private func synthesizeAnalysis(
        transfer: DataTransferRequest,
        fragment: FragmentAnalysis,
        tunnel: TunnelAnalysis,
        content: ContentAnalysis,
        behavior: DataTransferBehaviorAnalysis
    ) -> DataTransferAnalysis {
        // 計算綜合風險分數
        let riskScore = calculateOverallRisk(
            fragment: fragment,
            tunnel: tunnel,
            content: content,
            behavior: behavior
        )
        
        // 確定風險等級
        let riskLevel = determineRiskLevel(riskScore)
        
        // 生成建議
        let recommendations = generateRecommendations(
            riskLevel: riskLevel,
            fragment: fragment,
            tunnel: tunnel
        )
        
        // 決定是否允許
        let shouldAllow = riskLevel != .critical && riskScore < 0.9
        
        // 記錄決策
        logDecision(transfer: transfer, decision: shouldAllow, analysis: [
            "fragment": fragment,
            "tunnel": tunnel,
            "content": content,
            "behavior": behavior,
            "riskScore": riskScore
        ])
        
        return DataTransferAnalysis(
            allowed: shouldAllow,
            risk: riskLevel,
            reason: generateReason(fragment: fragment, tunnel: tunnel),
            recommendations: recommendations,
            detailedAnalysis: DetailedAnalysis(
                fragmentAnalysis: fragment,
                tunnelAnalysis: tunnel,
                contentAnalysis: content,
                behaviorAnalysis: behavior,
                overallConfidence: riskScore
            )
        )
    }
    
    // MARK: - Blocking and Mitigation
    func blockTransfer(_ transferID: String, reason: String) {
        detectionQueue.async { [weak self] in
            self?.blockedTransfers.insert(transferID)
            
            // 發送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("DataTransferBlocked"),
                object: nil,
                userInfo: [
                    "transferID": transferID,
                    "reason": reason,
                    "timestamp": Date()
                ]
            )
            
            print("🚫 DataExfiltrationDetection: 已阻止傳輸 \(transferID) - 原因: \(reason)")
        }
    }
    
    // MARK: - Real-time Monitoring
    private func startMonitoring() {
        // 創建數據傳輸監視器
        let fragmentMonitor = FragmentMonitor { [weak self] fragments in
            self?.handleDetectedFragments(fragments)
        }
        
        let tunnelMonitor = TunnelMonitor { [weak self] tunnel in
            self?.handleDetectedTunnel(tunnel)
        }
        
        activeMonitors = [fragmentMonitor, tunnelMonitor]
        
        // 啟動監視器
        activeMonitors.forEach { $0.start() }
    }
    
    private func handleDetectedFragments(_ fragments: [DataFragment]) {
        // 嘗試重組
        if let reassembled = attemptReassembly(fragments) {
            // 分析重組後的數據
            let analysis = analyzeReassembledData(reassembled)
            
            if analysis.isMalicious {
                // 阻止所有相關傳輸
                blockRelatedTransfers(fragments)
            }
        }
    }
    
    private func handleDetectedTunnel(_ tunnel: DetectedTunnel) {
        // 分析隧道內容
        let tunnelAnalysis = deepAnalyzeTunnel(tunnel)
        
        if tunnelAnalysis.risk > 0.8 {
            // 終止隧道連接
            terminateTunnel(tunnel)
            
            // 記錄事件
            logTunnelDetection(tunnel, analysis: tunnelAnalysis)
        }
    }
}

// MARK: - Supporting Types
// NetworkProtocol is now defined in SecurityService.swift

// DataTransferRequest is now defined in SecurityService.swift

// DataTransferAnalysis is now defined in SecurityService.swift

// FragmentAnalysis is now defined in SecurityService.swift

// TunnelAnalysis is now defined in SecurityService.swift

// ContentAnalysis is now defined in SecurityService.swift

// BehaviorAnalysis is now defined in AutomaticBanSystem.swift

struct DataTransferBehaviorAnalysis {
    let isAnomalous: Bool
    let deviationScore: Double
    let patterns: [String]
}

// DetailedAnalysis is now defined in SecurityService.swift

// MARK: - Indicators
struct FragmentIndicator {
    enum IndicatorType {
        case fixedSize
        case nearMaxSize
        case regularTiming
        case headerMarker
        case sequenceMarker
        case mlDetected
    }
    
    let type: IndicatorType
    let confidence: Double
    let details: [String: Any]
}

struct TunnelIndicator {
    enum IndicatorType {
        case highEntropy
        case knownEncryption
        case customEncryption
        case protocolAnomaly
        case suspiciousEndpoint
    }
    
    let type: IndicatorType
    let confidence: Double
    let details: [String: Any]
}

enum FragmentPosition: String {
    case first
    case middle
    case last
    case unknown
}

enum TunnelType: String {
    case tls
    case ssh
    case vpn
    case custom
    case unknown
}

enum SensitiveDataType {
    case credentials
    case personalInfo
    case financialData
    case healthData
    case proprietaryData
}

// BehaviorPattern is now defined in BehaviorAnalysisSystem.swift to avoid duplication

// MARK: - Monitors
protocol TransferMonitor {
    func start()
    func stop()
}

class FragmentMonitor: TransferMonitor {
    private let detectionHandler: ([DataFragment]) -> Void
    private var timer: Timer?
    
    init(detectionHandler: @escaping ([DataFragment]) -> Void) {
        self.detectionHandler = detectionHandler
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 監控邏輯
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
}

class TunnelMonitor: TransferMonitor {
    private let detectionHandler: (DetectedTunnel) -> Void
    
    init(detectionHandler: @escaping (DetectedTunnel) -> Void) {
        self.detectionHandler = detectionHandler
    }
    
    func start() {
        // 實施隧道監控
    }
    
    func stop() {
        // 停止監控
    }
}

struct DataFragment {
    let id: String
    let sequenceNumber: Int
    let totalFragments: Int
    let data: Data
    let timestamp: Date
}

struct DetectedTunnel {
    let id: String
    let type: TunnelType
    let endpoint: String
    let startTime: Date
    let trafficVolume: Int
}

// MARK: - Helpers
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - Mock ML Model
struct FragmentDetectionModel {
    func predict(_ features: [String: Double]) -> (isFragment: Bool, confidence: Double) {
        // 簡化的ML模型邏輯
        let score = features.values.reduce(0, +) / Double(features.count)
        return (score > 0.5, score)
    }
}

let fragmentDetectionModel = FragmentDetectionModel()

// MARK: - Missing Implementation Methods
extension DataTransferMonitor {
    
    private func performBasicChecks(_ transfer: DataTransferRequest) -> BasicCheckResult {
        // 檢查數據大小
        if transfer.data.count > 100 * 1024 * 1024 { // 100MB 限制
            return BasicCheckResult(
                shouldBlock: true,
                reason: "數據大小超過限制",
                recommendations: ["分割大檔案", "使用壓縮"]
            )
        }
        
        // 檢查空數據
        if transfer.data.isEmpty {
            return BasicCheckResult(
                shouldBlock: true,
                reason: "空數據傳輸",
                recommendations: ["驗證數據完整性"]
            )
        }
        
        return BasicCheckResult(
            shouldBlock: false,
            reason: "基本檢查通過",
            recommendations: []
        )
    }
    
    private func analyzeContent(_ transfer: DataTransferRequest) -> ContentAnalysis {
        return ContentAnalysis(
            containsSensitiveData: false,
            dataTypes: [],
            confidence: 0.5
        )
    }
    
    private func analyzeBehavior(_ transfer: DataTransferRequest) -> DataTransferBehaviorAnalysis {
        return DataTransferBehaviorAnalysis(
            isAnomalous: false,
            deviationScore: 0.0,
            patterns: []
        )
    }
    
    private func calculateOverallRisk(
        fragment: FragmentAnalysis,
        tunnel: TunnelAnalysis,
        content: ContentAnalysis,
        behavior: DataTransferBehaviorAnalysis
    ) -> Double {
        var riskScore = 0.0
        
        if fragment.isFragmented {
            riskScore += fragment.confidence * 0.3
        }
        
        if tunnel.isTunneled {
            riskScore += tunnel.confidence * 0.4
        }
        
        if content.containsSensitiveData {
            riskScore += content.confidence * 0.2
        }
        
        if behavior.isAnomalous {
            riskScore += behavior.deviationScore * 0.1
        }
        
        return min(riskScore, 1.0)
    }
    
    private func determineRiskLevel(_ score: Double) -> RiskLevel {
        switch score {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.6:
            return .medium
        case 0.6..<0.9:
            return .high
        default:
            return .critical
        }
    }
    
    private func generateRecommendations(
        riskLevel: RiskLevel,
        fragment: FragmentAnalysis,
        tunnel: TunnelAnalysis
    ) -> [String] {
        var recommendations: [String] = []
        
        if fragment.isFragmented {
            recommendations.append("檢查數據分片模式")
        }
        
        if tunnel.isTunneled {
            recommendations.append("分析隧道通信")
        }
        
        switch riskLevel {
        case .high, .critical:
            recommendations.append("立即阻止傳輸")
        case .medium:
            recommendations.append("加強監控")
        default:
            recommendations.append("正常處理")
        }
        
        return recommendations
    }
    
    private func generateReason(fragment: FragmentAnalysis, tunnel: TunnelAnalysis) -> String {
        if fragment.isFragmented && tunnel.isTunneled {
            return "偵測到分片和隧道通信"
        } else if fragment.isFragmented {
            return "偵測到數據分片"
        } else if tunnel.isTunneled {
            return "偵測到隧道通信"
        } else {
            return "正常數據傳輸"
        }
    }
    
    private func logDecision(transfer: DataTransferRequest, decision: Bool, analysis: [String: Any]) {
        print("📊 資料傳輸監控決策：\(decision ? "允許" : "阻止") 傳輸 \(transfer.id)")
        
        // 記錄到安全日誌
        Task { @MainActor in
            ServiceContainer.shared.securityLogManager.logEntry(
                eventType: "data_exfiltration_decision",
                source: "DataTransferMonitor",
                severity: decision ? .info : .warning,
                details: "傳輸ID: \(transfer.id), 決策: \(decision ? "允許" : "阻止")"
            )
        }
    }
    
    // 缺少的輔助方法
    private func getRecentTransfers(from source: String, within timeWindow: TimeInterval) -> [DataTransferRequest] {
        return [] // 簡化實現
    }
    
    private func calculateTimeIntervals(_ transfers: [DataTransferRequest]) -> [TimeInterval] {
        return [] // 簡化實現
    }
    
    private func calculateRegularity(_ intervals: [TimeInterval]) -> Double {
        return 0.0 // 簡化實現
    }
    
    private func extractSequenceInfo(_ data: Data) -> [String: Any]? {
        return nil // 簡化實現
    }
    
    private func calculateEntropy(_ data: Data) -> Double {
        var entropy = 0.0
        var frequency = [UInt8: Int]()
        
        for byte in data {
            frequency[byte, default: 0] += 1
        }
        
        let dataLength = Double(data.count)
        for count in frequency.values {
            let probability = Double(count) / dataLength
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
    
    private func detectProtocolAnomaly(_ transfer: DataTransferRequest) -> TunnelIndicator? {
        return nil // 簡化實現
    }
    
    private func analyzeTrafficPattern(_ transfer: DataTransferRequest) -> TunnelIndicator? {
        return nil // 簡化實現
    }
    
    private func analyzeEndpoint(_ transfer: DataTransferRequest) -> TunnelIndicator? {
        return nil // 簡化實現
    }
    
    private func calculateFragmentConfidence(_ indicators: [FragmentIndicator]) -> Double {
        guard !indicators.isEmpty else { return 0.0 }
        return indicators.reduce(0.0) { $0 + $1.confidence } / Double(indicators.count)
    }
    
    private func calculateTunnelConfidence(_ indicators: [TunnelIndicator]) -> Double {
        guard !indicators.isEmpty else { return 0.0 }
        return indicators.reduce(0.0) { $0 + $1.confidence } / Double(indicators.count)
    }
    
    private func estimateTotalSize(_ transfer: DataTransferRequest, _ indicators: [FragmentIndicator]) -> Int? {
        return nil // 簡化實現
    }
    
    private func determineFragmentPosition(_ transfer: DataTransferRequest, _ indicators: [FragmentIndicator]) -> FragmentPosition? {
        return nil // 簡化實現
    }
    
    private func determineTunnelType(_ indicators: [TunnelIndicator]) -> TunnelType? {
        return nil // 簡化實現
    }
    
    private func generateDecryptionHint(_ indicators: [TunnelIndicator]) -> String? {
        return nil // 簡化實現
    }
    
    private func detectCorrelation(_ transfer: DataTransferRequest) -> FragmentIndicator? {
        return nil // 簡化實現
    }
    
    private func analyzeDataPattern(_ data: Data) -> DataPatternAnalysis {
        return DataPatternAnalysis(
            isLikelyEncrypted: false,
            entropy: calculateEntropy(data),
            confidence: 0.5,
            detectedBlockSize: 0
        )
    }
    
    private func detectKnownEncryption(_ data: Data) -> String? {
        return nil // 簡化實現
    }
    
    private func extractMLFeatures(_ transfer: DataTransferRequest) -> [String: Double] {
        return [
            "size": Double(transfer.data.count),
            "entropy": calculateEntropy(transfer.data)
        ]
    }
    
    private func setupDefaultPatterns() {
        // 設置默認的可疑模式
        suspiciousPatterns = [
            SuspiciousPattern(
                name: "large_data_transfer",
                threshold: 50 * 1024 * 1024, // 50MB
                enabled: true
            )
        ]
    }
    
    private func attemptReassembly(_ fragments: [DataFragment]) -> Data? {
        return nil // 簡化實現
    }
    
    private func analyzeReassembledData(_ data: Data) -> ReassemblyAnalysis {
        return ReassemblyAnalysis(isMalicious: false)
    }
    
    private func blockRelatedTransfers(_ fragments: [DataFragment]) {
        // 簡化實現
    }
    
    private func deepAnalyzeTunnel(_ tunnel: DetectedTunnel) -> TunnelAnalysisResult {
        return TunnelAnalysisResult(risk: 0.0)
    }
    
    private func terminateTunnel(_ tunnel: DetectedTunnel) {
        // 簡化實現
    }
    
    private func logTunnelDetection(_ tunnel: DetectedTunnel, analysis: TunnelAnalysisResult) {
        print("🔒 隧道監控：\(tunnel.id) - 風險: \(analysis.risk)")
    }
}

// MARK: - Supporting Structures
struct BasicCheckResult {
    let shouldBlock: Bool
    let reason: String
    let recommendations: [String]
}

struct DataPatternAnalysis {
    let isLikelyEncrypted: Bool
    let entropy: Double
    let confidence: Double
    let detectedBlockSize: Int
}

struct SuspiciousPattern {
    let name: String
    let threshold: Int
    let enabled: Bool
}

struct ReassemblyAnalysis {
    let isMalicious: Bool
}

struct TunnelAnalysisResult {
    let risk: Double
}