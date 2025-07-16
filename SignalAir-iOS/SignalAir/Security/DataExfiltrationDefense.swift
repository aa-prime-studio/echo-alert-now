import Foundation
import CryptoKit
import Combine

// MARK: - Enhanced Data Exfiltration Defense System
// 增強型數據外洩防禦系統

class DataExfiltrationDefense {
    
    // MARK: - Singleton
    static let shared = DataExfiltrationDefense()
    
    // MARK: - Properties
    private let detectionQueue = DispatchQueue(label: "com.signalair.exfiltration", qos: .userInitiated)
    private var activeMonitors: [ExfiltrationMonitor] = []
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
    func analyzeDataTransfer(_ transfer: DataTransferRequest) -> DataTransferAnalysis {
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
            indicators: indicators,
            estimatedTotalSize: estimateTotalSize(transfer, indicators),
            fragmentPosition: determineFragmentPosition(transfer, indicators)
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
            tunnelType: determineTunnelType(tunnelIndicators),
            indicators: tunnelIndicators,
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
        if dataSize > maxFragmentSize * 0.9 && dataSize <= maxFragmentSize {
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
        behavior: BehaviorAnalysis
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
            
            // 通知告警系統
            let alert = SecurityAlert(
                id: UUID(),
                level: .high,
                source: "DataExfiltrationDefense",
                type: .dataExfiltration,
                reason: reason,
                timestamp: Date(),
                isResolved: false,
                metadata: ["transferID": transferID]
            )
            
            IntegratedSecurityAlertSystem.shared.sendAlert(alert)
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
struct DataTransferRequest {
    let id: String
    let source: String
    let destination: String
    let data: Data
    let timestamp: Date
    let protocol: NetworkProtocol
    let metadata: [String: Any]
}

struct DataTransferAnalysis {
    let allowed: Bool
    let risk: RiskLevel
    let reason: String
    let recommendations: [String]
    let detailedAnalysis: DetailedAnalysis?
}

struct FragmentAnalysis {
    let isFragmented: Bool
    let confidence: Double
    let indicators: [FragmentIndicator]
    let estimatedTotalSize: Int?
    let fragmentPosition: FragmentPosition?
}

struct TunnelAnalysis {
    let isTunneled: Bool
    let confidence: Double
    let tunnelType: TunnelType?
    let indicators: [TunnelIndicator]
    let decryptionHint: String?
}

struct ContentAnalysis {
    let containsSensitiveData: Bool
    let dataTypes: [SensitiveDataType]
    let confidence: Double
}

struct BehaviorAnalysis {
    let isAnomalous: Bool
    let deviationScore: Double
    let patterns: [BehaviorPattern]
}

struct DetailedAnalysis {
    let fragmentAnalysis: FragmentAnalysis
    let tunnelAnalysis: TunnelAnalysis
    let contentAnalysis: ContentAnalysis
    let behaviorAnalysis: BehaviorAnalysis
    let overallConfidence: Double
}

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

enum FragmentPosition {
    case first
    case middle
    case last
    case unknown
}

enum TunnelType {
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

struct BehaviorPattern {
    let type: String
    let frequency: Int
    let lastSeen: Date
}

// MARK: - Monitors
protocol ExfiltrationMonitor {
    func start()
    func stop()
}

class FragmentMonitor: ExfiltrationMonitor {
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

class TunnelMonitor: ExfiltrationMonitor {
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