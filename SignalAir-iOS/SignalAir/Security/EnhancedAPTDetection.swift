import Foundation
import CryptoKit

// MARK: - Enhanced APT C2 Communication Detection
// 增強型 APT C2 通信檢測系統

class EnhancedAPTDetection {
    
    // MARK: - C2 Communication Patterns
    struct C2CommunicationPattern {
        let domainGenerationAlgorithm: Bool
        let beaconingInterval: TimeInterval?
        let jitterPercentage: Double
        let encryptionType: EncryptionType
        let protocolAbuse: ProtocolAbuseType
        let stealthTechnique: StealthTechnique
    }
    
    enum EncryptionType {
        case none
        case customXOR
        case AES
        case customProtocol
        case multiLayer
    }
    
    enum ProtocolAbuseType {
        case none
        case dnsExfiltration
        case httpHeaders
        case icmpTunnel
        case tlsCallback
    }
    
    enum StealthTechnique {
        case none
        case domainFronting
        case fastFlux
        case torNetwork
        case legitimateServiceAbuse
    }
    
    // MARK: - C2 Detection Engine
    func detectC2Communication(_ networkEvents: [NetworkEvent]) -> C2DetectionResult {
        var detectedC2Patterns: [C2Pattern] = []
        
        // 1. 檢測 Beaconing 行為
        if let beaconingPattern = detectBeaconing(networkEvents) {
            detectedC2Patterns.append(beaconingPattern)
        }
        
        // 2. 檢測 DGA (Domain Generation Algorithm)
        if let dgaPattern = detectDGA(networkEvents) {
            detectedC2Patterns.append(dgaPattern)
        }
        
        // 3. 檢測協議濫用
        if let protocolAbusePattern = detectProtocolAbuse(networkEvents) {
            detectedC2Patterns.append(protocolAbusePattern)
        }
        
        // 4. 檢測隱蔽通道
        if let covertChannelPattern = detectCovertChannel(networkEvents) {
            detectedC2Patterns.append(covertChannelPattern)
        }
        
        // 5. 檢測加密異常
        if let encryptionAnomalyPattern = detectEncryptionAnomaly(networkEvents) {
            detectedC2Patterns.append(encryptionAnomalyPattern)
        }
        
        return C2DetectionResult(
            detected: !detectedC2Patterns.isEmpty,
            patterns: detectedC2Patterns,
            confidence: calculateC2Confidence(detectedC2Patterns),
            recommendations: generateC2Recommendations(detectedC2Patterns)
        )
    }
    
    // MARK: - Beaconing Detection
    private func detectBeaconing(_ events: [NetworkEvent]) -> C2Pattern? {
        // 分析連接時間間隔
        let connectionIntervals = calculateConnectionIntervals(events)
        
        // 檢測規律性 beacon
        let regularityScore = calculateRegularityScore(connectionIntervals)
        
        // 檢測 jitter (時間抖動)
        let jitterAnalysis = analyzeJitter(connectionIntervals)
        
        if regularityScore > 0.7 || jitterAnalysis.isArtificial {
            return C2Pattern(
                type: .beaconing,
                severity: .high,
                description: "檢測到規律性 beacon 通信",
                evidence: [
                    "規律性分數": regularityScore,
                    "Jitter 分析": jitterAnalysis,
                    "平均間隔": connectionIntervals.average
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - DGA Detection
    private func detectDGA(_ events: [NetworkEvent]) -> C2Pattern? {
        let domains = extractDomains(from: events)
        
        // 分析域名熵
        let entropyScores = domains.map { calculateDomainEntropy($0) }
        let avgEntropy = entropyScores.average
        
        // 檢測域名生成模式
        let generationPattern = detectGenerationPattern(domains)
        
        // 檢測域名新鮮度
        let freshnessScore = calculateDomainFreshness(domains)
        
        if avgEntropy > 3.5 || generationPattern.confidence > 0.8 || freshnessScore > 0.9 {
            return C2Pattern(
                type: .domainGenerationAlgorithm,
                severity: .critical,
                description: "檢測到 DGA 域名生成活動",
                evidence: [
                    "平均熵值": avgEntropy,
                    "生成模式": generationPattern,
                    "新鮮度分數": freshnessScore,
                    "可疑域名": domains.filter { calculateDomainEntropy($0) > 3.5 }
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Protocol Abuse Detection
    private func detectProtocolAbuse(_ events: [NetworkEvent]) -> C2Pattern? {
        var abuseIndicators: [ProtocolAbuseIndicator] = []
        
        // DNS 隧道檢測
        if let dnsAbuse = detectDNSTunneling(events) {
            abuseIndicators.append(dnsAbuse)
        }
        
        // HTTP Header 濫用檢測
        if let httpAbuse = detectHTTPHeaderAbuse(events) {
            abuseIndicators.append(httpAbuse)
        }
        
        // ICMP 隧道檢測
        if let icmpAbuse = detectICMPTunneling(events) {
            abuseIndicators.append(icmpAbuse)
        }
        
        if !abuseIndicators.isEmpty {
            return C2Pattern(
                type: .protocolAbuse,
                severity: .high,
                description: "檢測到協議濫用行為",
                evidence: [
                    "濫用類型": abuseIndicators.map { $0.type },
                    "詳細信息": abuseIndicators
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Covert Channel Detection
    private func detectCovertChannel(_ events: [NetworkEvent]) -> C2Pattern? {
        // 檢測時間通道
        let timingChannel = detectTimingChannel(events)
        
        // 檢測存儲通道
        let storageChannel = detectStorageChannel(events)
        
        // 檢測混淆技術
        let obfuscation = detectObfuscation(events)
        
        if timingChannel.detected || storageChannel.detected || obfuscation.detected {
            return C2Pattern(
                type: .covertChannel,
                severity: .critical,
                description: "檢測到隱蔽通道通信",
                evidence: [
                    "時間通道": timingChannel,
                    "存儲通道": storageChannel,
                    "混淆技術": obfuscation
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Functions
    private func calculateConnectionIntervals(_ events: [NetworkEvent]) -> [TimeInterval] {
        guard events.count > 1 else { return [] }
        
        var intervals: [TimeInterval] = []
        for i in 1..<events.count {
            intervals.append(events[i].timestamp.timeIntervalSince(events[i-1].timestamp))
        }
        
        return intervals
    }
    
    private func calculateRegularityScore(_ intervals: [TimeInterval]) -> Double {
        guard !intervals.isEmpty else { return 0 }
        
        let mean = intervals.average
        let variance = intervals.map { pow($0 - mean, 2) }.average
        let standardDeviation = sqrt(variance)
        
        // 低標準差表示高規律性
        return 1.0 - min(standardDeviation / mean, 1.0)
    }
    
    private func analyzeJitter(_ intervals: [TimeInterval]) -> (isArtificial: Bool, jitterPercentage: Double) {
        guard intervals.count > 2 else { return (false, 0) }
        
        // 檢測人工 jitter 模式
        var jitterValues: [Double] = []
        for i in 1..<intervals.count {
            let jitter = abs(intervals[i] - intervals[i-1]) / intervals[i-1]
            jitterValues.append(jitter)
        }
        
        let avgJitter = jitterValues.average
        let jitterConsistency = calculateJitterConsistency(jitterValues)
        
        // 人工 jitter 通常有一致的範圍
        let isArtificial = jitterConsistency > 0.8 && avgJitter > 0.05 && avgJitter < 0.3
        
        return (isArtificial, avgJitter)
    }
    
    private func calculateJitterConsistency(_ jitterValues: [Double]) -> Double {
        guard jitterValues.count > 1 else { return 0 }
        
        let mean = jitterValues.average
        let variance = jitterValues.map { pow($0 - mean, 2) }.average
        
        // 低變異表示一致的 jitter
        return 1.0 - min(sqrt(variance) / mean, 1.0)
    }
    
    private func calculateDomainEntropy(_ domain: String) -> Double {
        let characters = Array(domain)
        var frequency: [Character: Double] = [:]
        
        for char in characters {
            frequency[char, default: 0] += 1
        }
        
        var entropy = 0.0
        let length = Double(characters.count)
        
        for count in frequency.values {
            let probability = count / length
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
    
    private func detectDNSTunneling(_ events: [NetworkEvent]) -> ProtocolAbuseIndicator? {
        let dnsEvents = events.filter { $0.protocol == .dns }
        
        // 檢測異常大的 DNS 查詢
        let largeDNSQueries = dnsEvents.filter { $0.dataSize > 512 }
        
        // 檢測高頻 DNS 查詢
        let queryFrequency = Double(dnsEvents.count) / max(1, events.count)
        
        // 檢測 TXT 記錄濫用
        let txtRecordAbuse = dnsEvents.filter { $0.dnsRecordType == "TXT" }.count
        
        if !largeDNSQueries.isEmpty || queryFrequency > 0.7 || txtRecordAbuse > 10 {
            return ProtocolAbuseIndicator(
                type: .dnsTunneling,
                severity: .high,
                details: [
                    "大查詢數": largeDNSQueries.count,
                    "查詢頻率": queryFrequency,
                    "TXT記錄數": txtRecordAbuse
                ]
            )
        }
        
        return nil
    }
}

// MARK: - Data Exfiltration Detection Enhancement
// 增強型數據外洩檢測

extension EnhancedAPTDetection {
    
    // MARK: - Fragment Detection
    func detectFragmentedExfiltration(_ dataTransfers: [DataTransfer]) -> FragmentDetectionResult {
        var fragmentGroups: [FragmentGroup] = []
        
        // 1. 檢測時間相關的分片
        let timeBasedFragments = detectTimeBasedFragments(dataTransfers)
        if !timeBasedFragments.isEmpty {
            fragmentGroups.append(contentsOf: timeBasedFragments)
        }
        
        // 2. 檢測大小模式的分片
        let sizePatternFragments = detectSizePatternFragments(dataTransfers)
        if !sizePatternFragments.isEmpty {
            fragmentGroups.append(contentsOf: sizePatternFragments)
        }
        
        // 3. 檢測序列化標記
        let sequenceMarkers = detectSequenceMarkers(dataTransfers)
        if !sequenceMarkers.isEmpty {
            fragmentGroups.append(contentsOf: sequenceMarkers)
        }
        
        // 4. 重組分析
        let reassemblyAnalysis = analyzeReassemblyPotential(fragmentGroups)
        
        return FragmentDetectionResult(
            detected: !fragmentGroups.isEmpty,
            fragmentGroups: fragmentGroups,
            reassemblyConfidence: reassemblyAnalysis.confidence,
            estimatedOriginalSize: reassemblyAnalysis.estimatedSize,
            exfiltrationMethod: determineExfiltrationMethod(fragmentGroups)
        )
    }
    
    // MARK: - Tunnel Detection
    func detectEncryptedTunnels(_ networkFlows: [NetworkFlow]) -> TunnelDetectionResult {
        var detectedTunnels: [EncryptedTunnel] = []
        
        // 1. 檢測 TLS 隧道
        if let tlsTunnel = detectTLSTunnel(networkFlows) {
            detectedTunnels.append(tlsTunnel)
        }
        
        // 2. 檢測 SSH 隧道
        if let sshTunnel = detectSSHTunnel(networkFlows) {
            detectedTunnels.append(sshTunnel)
        }
        
        // 3. 檢測自定義加密協議
        if let customTunnel = detectCustomEncryption(networkFlows) {
            detectedTunnels.append(customTunnel)
        }
        
        // 4. 檢測嵌套隧道
        let nestedTunnels = detectNestedTunnels(networkFlows)
        detectedTunnels.append(contentsOf: nestedTunnels)
        
        // 5. 流量分析
        let trafficAnalysis = analyzeEncryptedTraffic(detectedTunnels)
        
        return TunnelDetectionResult(
            detected: !detectedTunnels.isEmpty,
            tunnels: detectedTunnels,
            trafficAnalysis: trafficAnalysis,
            riskLevel: calculateTunnelRisk(detectedTunnels),
            blockRecommendation: generateBlockingStrategy(detectedTunnels)
        )
    }
    
    // MARK: - Advanced Fragment Analysis
    private func detectTimeBasedFragments(_ transfers: [DataTransfer]) -> [FragmentGroup] {
        var fragmentGroups: [FragmentGroup] = []
        
        // 按時間窗口分組
        let timeWindows = groupByTimeWindow(transfers, windowSize: 300) // 5分鐘窗口
        
        for window in timeWindows {
            // 檢查是否有分片特徵
            if hasFragmentCharacteristics(window) {
                let group = FragmentGroup(
                    fragments: window,
                    method: .timeBased,
                    confidence: calculateFragmentConfidence(window),
                    metadata: extractFragmentMetadata(window)
                )
                fragmentGroups.append(group)
            }
        }
        
        return fragmentGroups
    }
    
    private func detectSizePatternFragments(_ transfers: [DataTransfer]) -> [FragmentGroup] {
        var fragmentGroups: [FragmentGroup] = []
        
        // 檢測固定大小分片
        let fixedSizeGroups = detectFixedSizeFragments(transfers)
        
        // 檢測遞增/遞減模式
        let patternGroups = detectSizePatterns(transfers)
        
        fragmentGroups.append(contentsOf: fixedSizeGroups)
        fragmentGroups.append(contentsOf: patternGroups)
        
        return fragmentGroups
    }
    
    private func detectSequenceMarkers(_ transfers: [DataTransfer]) -> [FragmentGroup] {
        var fragmentGroups: [FragmentGroup] = []
        
        // 檢測頭部標記
        for transfer in transfers {
            if let markers = extractSequenceMarkers(transfer.data) {
                // 找到相關分片
                let relatedFragments = findRelatedFragments(transfers, markers: markers)
                
                if relatedFragments.count > 1 {
                    let group = FragmentGroup(
                        fragments: relatedFragments,
                        method: .sequenceMarked,
                        confidence: 0.9,
                        metadata: ["markers": markers]
                    )
                    fragmentGroups.append(group)
                }
            }
        }
        
        return fragmentGroups
    }
    
    // MARK: - Tunnel Analysis
    private func detectTLSTunnel(_ flows: [NetworkFlow]) -> EncryptedTunnel? {
        let tlsFlows = flows.filter { $0.protocol == .tls }
        
        // 分析 TLS 流量特徵
        for flow in tlsFlows {
            // 檢測異常的 TLS 使用
            if isSuspiciousTLSUsage(flow) {
                return EncryptedTunnel(
                    type: .tls,
                    startTime: flow.startTime,
                    endTime: flow.endTime,
                    dataVolume: flow.totalBytes,
                    suspicionScore: calculateTLSSuspicionScore(flow),
                    characteristics: extractTLSCharacteristics(flow)
                )
            }
        }
        
        return nil
    }
    
    private func detectCustomEncryption(_ flows: [NetworkFlow]) -> EncryptedTunnel? {
        for flow in flows {
            // 檢測自定義加密特徵
            let entropyScore = calculateDataEntropy(flow.sampleData)
            let patternScore = detectEncryptionPatterns(flow.sampleData)
            
            if entropyScore > 7.5 && patternScore.hasCustomPattern {
                return EncryptedTunnel(
                    type: .custom,
                    startTime: flow.startTime,
                    endTime: flow.endTime,
                    dataVolume: flow.totalBytes,
                    suspicionScore: 0.8,
                    characteristics: [
                        "entropy": entropyScore,
                        "pattern": patternScore
                    ]
                )
            }
        }
        
        return nil
    }
    
    private func calculateDataEntropy(_ data: Data) -> Double {
        var frequency: [UInt8: Int] = [:]
        
        for byte in data {
            frequency[byte, default: 0] += 1
        }
        
        var entropy = 0.0
        let dataSize = Double(data.count)
        
        for count in frequency.values {
            let probability = Double(count) / dataSize
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
}

// MARK: - Data Structures
struct C2DetectionResult {
    let detected: Bool
    let patterns: [C2Pattern]
    let confidence: Double
    let recommendations: [String]
}

struct C2Pattern {
    enum PatternType {
        case beaconing
        case domainGenerationAlgorithm
        case protocolAbuse
        case covertChannel
    }
    
    let type: PatternType
    let severity: SecurityAlertLevel
    let description: String
    let evidence: [String: Any]
}

struct FragmentDetectionResult {
    let detected: Bool
    let fragmentGroups: [FragmentGroup]
    let reassemblyConfidence: Double
    let estimatedOriginalSize: Int
    let exfiltrationMethod: ExfiltrationMethod
}

struct FragmentGroup {
    enum FragmentMethod {
        case timeBased
        case sizeBased
        case sequenceMarked
    }
    
    let fragments: [DataTransfer]
    let method: FragmentMethod
    let confidence: Double
    let metadata: [String: Any]
}

struct TunnelDetectionResult {
    let detected: Bool
    let tunnels: [EncryptedTunnel]
    let trafficAnalysis: TrafficAnalysis
    let riskLevel: RiskLevel
    let blockRecommendation: BlockingStrategy
}

struct EncryptedTunnel {
    enum TunnelType {
        case tls
        case ssh
        case custom
        case nested
    }
    
    let type: TunnelType
    let startTime: Date
    let endTime: Date
    let dataVolume: Int
    let suspicionScore: Double
    let characteristics: [String: Any]
}

// MARK: - Supporting Types
struct NetworkEvent {
    let timestamp: Date
    let protocol: NetworkProtocol
    let dataSize: Int
    let dnsRecordType: String?
    let destinationIP: String
    let sourceIP: String
}

struct DataTransfer {
    let timestamp: Date
    let size: Int
    let data: Data
    let destination: String
    let metadata: [String: Any]
}

struct NetworkFlow {
    let protocol: NetworkProtocol
    let startTime: Date
    let endTime: Date
    let totalBytes: Int
    let sampleData: Data
}

enum NetworkProtocol {
    case tcp
    case udp
    case dns
    case http
    case https
    case tls
    case ssh
    case icmp
    case custom
}

struct ProtocolAbuseIndicator {
    enum AbuseType {
        case dnsTunneling
        case httpHeaderAbuse
        case icmpTunneling
    }
    
    let type: AbuseType
    let severity: SecurityAlertLevel
    let details: [String: Any]
}

enum ExfiltrationMethod {
    case direct
    case fragmented
    case tunneled
    case covert
    case mixed
}

enum RiskLevel {
    case low
    case medium
    case high
    case critical
}

struct BlockingStrategy {
    let shouldBlock: Bool
    let blockingRules: [String]
    let monitoringRecommendations: [String]
}

struct TrafficAnalysis {
    let volumeAnomaly: Bool
    let timingAnomaly: Bool
    let patternAnomaly: Bool
    let overallSuspicionScore: Double
}

// MARK: - Helper Extensions
extension Array where Element == TimeInterval {
    var average: TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / TimeInterval(count)
    }
}

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}