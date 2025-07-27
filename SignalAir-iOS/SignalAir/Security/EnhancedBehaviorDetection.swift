import Foundation
import CryptoKit

// MARK: - Enhanced Behavior Communication Detection
// 增強型行為通信檢測系統

class EnhancedBehaviorDetection {
    
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
        // REMOVED: case AES (已移除AES支持)
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
    
    private func extractDomains(from events: [NetworkEvent]) -> [String] {
        return events.compactMap { event in
            event.metadata["domain"] as? String
        }
    }
    
    private func detectGenerationPattern(_ domains: [String]) -> (confidence: Double, pattern: String) {
        // 簡化的域名生成模式檢測
        let lengths = domains.map { $0.count }
        let avgLength = lengths.average
        let lengthVariance = lengths.map { pow(Double($0) - avgLength, 2) }.average
        
        // 檢測長度一致性
        let lengthConsistency = 1.0 - min(sqrt(lengthVariance) / avgLength, 1.0)
        
        // 檢測字符分佈
        let charDistribution = analyzeCharacterDistribution(domains)
        
        let confidence = (lengthConsistency + charDistribution.uniformity) / 2
        
        return (confidence: confidence, pattern: charDistribution.pattern)
    }
    
    private func calculateDomainFreshness(_ domains: [String]) -> Double {
        // 簡化的域名新鮮度計算
        // 在實際實現中，這會查詢域名註冊時間
        return 0.5 // 預設值
    }
    
    private func analyzeCharacterDistribution(_ domains: [String]) -> (uniformity: Double, pattern: String) {
        var charCounts: [Character: Int] = [:]
        var totalChars = 0
        
        for domain in domains {
            for char in domain {
                charCounts[char, default: 0] += 1
                totalChars += 1
            }
        }
        
        // 計算字符分佈均勻性
        let expectedFreq = Double(totalChars) / Double(charCounts.count)
        let variance = charCounts.values.map { pow(Double($0) - expectedFreq, 2) }.average
        let uniformity = 1.0 - min(sqrt(variance) / expectedFreq, 1.0)
        
        return (uniformity: uniformity, pattern: "character_distribution")
    }
    
    private func detectHTTPHeaderAbuse(_ events: [NetworkEvent]) -> ProtocolAbuseIndicator? {
        let httpEvents = events.filter { $0.protocol == .http || $0.protocol == .https }
        
        // 檢測異常的 HTTP 頭部
        let suspiciousHeaders = httpEvents.filter { event in
            let headers = event.metadata["headers"] as? [String: String] ?? [:]
            return headers.values.contains { $0.count > 1024 } // 異常大的頭部值
        }
        
        if !suspiciousHeaders.isEmpty {
            return ProtocolAbuseIndicator(
                type: .httpHeaderAbuse,
                severity: .medium,
                details: [
                    "可疑頭部數": suspiciousHeaders.count,
                    "總HTTP事件": httpEvents.count
                ]
            )
        }
        
        return nil
    }
    
    private func detectICMPTunneling(_ events: [NetworkEvent]) -> ProtocolAbuseIndicator? {
        let icmpEvents = events.filter { $0.protocol == .icmp }
        
        // 檢測異常大的 ICMP 包
        let largeICMPPackets = icmpEvents.filter { $0.dataSize > 256 }
        
        // 檢測高頻 ICMP 通信
        let icmpFrequency = Double(icmpEvents.count) / max(1, events.count)
        
        if !largeICMPPackets.isEmpty || icmpFrequency > 0.3 {
            return ProtocolAbuseIndicator(
                type: .icmpTunneling,
                severity: .high,
                details: [
                    "大ICMP包數": largeICMPPackets.count,
                    "ICMP頻率": icmpFrequency
                ]
            )
        }
        
        return nil
    }
    
    private func detectTimingChannel(_ events: [NetworkEvent]) -> (detected: Bool, confidence: Double) {
        // 檢測時間通道模式
        let intervals = calculateConnectionIntervals(events)
        let regularityScore = calculateRegularityScore(intervals)
        
        // 時間通道通常有非常規律的時間間隔
        let detected = regularityScore > 0.9
        
        return (detected: detected, confidence: regularityScore)
    }
    
    private func detectStorageChannel(_ events: [NetworkEvent]) -> (detected: Bool, confidence: Double) {
        // 檢測存儲通道模式
        let dataSizes = events.map { $0.dataSize }
        let avgSize = dataSizes.average
        let sizeVariance = dataSizes.map { pow(Double($0) - avgSize, 2) }.average
        
        // 存儲通道通常有固定的數據大小
        let sizeConsistency = 1.0 - min(sqrt(sizeVariance) / avgSize, 1.0)
        let detected = sizeConsistency > 0.8
        
        return (detected: detected, confidence: sizeConsistency)
    }
    
    private func detectObfuscation(_ events: [NetworkEvent]) -> (detected: Bool, confidence: Double) {
        // 檢測混淆技術
        var obfuscationScore = 0.0
        
        for event in events {
            // 檢查是否有編碼或加密的跡象
            if let payload = event.metadata["payload"] as? Data {
                let entropy = calculateDataEntropy(payload)
                if entropy > 7.0 { // 高熵值表示可能的加密或編碼
                    obfuscationScore += 0.1
                }
            }
        }
        
        let normalizedScore = min(obfuscationScore, 1.0)
        let detected = normalizedScore > 0.5
        
        return (detected: detected, confidence: normalizedScore)
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
    
    private func calculateC2Confidence(_ patterns: [C2Pattern]) -> Double {
        guard !patterns.isEmpty else { return 0.0 }
        
        let totalConfidence = patterns.map { pattern in
            switch pattern.severity {
            case .low: return 0.3
            case .medium: return 0.6
            case .high: return 0.8
            case .critical: return 1.0
            }
        }.reduce(0, +)
        
        return min(1.0, totalConfidence / Double(patterns.count))
    }
    
    private func generateC2Recommendations(_ patterns: [C2Pattern]) -> [String] {
        var recommendations: [String] = []
        
        for pattern in patterns {
            switch pattern.type {
            case .beaconing:
                recommendations.append("監控定期通信模式")
                recommendations.append("檢查網路時間間隔")
            case .domainGenerationAlgorithm:
                recommendations.append("封鎖可疑域名")
                recommendations.append("監控DNS查詢")
            case .protocolAbuse:
                recommendations.append("檢查協議使用情況")
                recommendations.append("限制異常協議活動")
            case .covertChannel:
                recommendations.append("深度包檢測")
                recommendations.append("監控隱蔽通道")
            }
        }
        
        return Array(Set(recommendations))
    }
    
    private func detectEncryptionAnomaly(_ events: [NetworkEvent]) -> C2Pattern? {
        var anomalyScore = 0.0
        
        for event in events {
            if let payload = event.metadata["payload"] as? Data {
                let entropy = calculateDataEntropy(payload)
                if entropy > 7.5 {
                    anomalyScore += 0.1
                }
            }
        }
        
        if anomalyScore > 0.5 {
            return C2Pattern(
                type: .covertChannel,
                severity: .high,
                description: "檢測到加密異常",
                evidence: [
                    "異常分數": anomalyScore,
                    "高熵事件": events.filter { event in
                        if let payload = event.metadata["payload"] as? Data {
                            return calculateDataEntropy(payload) > 7.5
                        }
                        return false
                    }.count
                ]
            )
        }
        
        return nil
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

// MARK: - Supporting Types
enum SecurityAlertLevel {
    case low
    case medium
    case high
    case critical
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

extension NetworkEvent {
    var protocol: NetworkProtocol {
        return metadata["protocol"] as? NetworkProtocol ?? .tcp
    }
    
    var dnsRecordType: String? {
        return metadata["dnsRecordType"] as? String
    }
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

extension Array where Element == Int {
    var average: Double {
        guard !isEmpty else { return 0 }
        return Double(reduce(0, +)) / Double(count)
    }
}