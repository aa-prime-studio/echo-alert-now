import Foundation
import SwiftUI
import Combine

// MARK: - Trust Score Manager
/// 信任評分管理器 - 基於 DeviceUUID 的行為信譽追蹤系統
class TrustScoreManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var trustScores: [String: TrustScore] = [:]
    @Published private(set) var localBlacklist: Set<String> = []
    @Published private(set) var observationList: Set<String> = []
    @Published private(set) var bloomFilter: BloomFilter?
    
    // MARK: - Configuration
    private let userDefaultsKey = "trust_scores"
    private let blacklistKey = "local_blacklist"
    private let observationKey = "observation_list"
    private let bloomFilterKey = "bloom_filter"
    
    // MARK: - Async Processing Configuration
    @AppStorage("useAsyncTrustProcessing") private var useAsyncProcessing: Bool = false
    private let asyncQueue = DispatchQueue(label: "com.signalair.trustscore.async", qos: .utility)
    private let batchQueue = DispatchQueue(label: "com.signalair.trustscore.batch", qos: .background)
    private var pendingUpdates: [String: PendingTrustUpdate] = [:]
    private let batchProcessingInterval: TimeInterval = 0.5
    private var batchTimer: Timer?
    
    // MARK: - Trust Score Parameters
    private let initialTrustScore: Double = 50.0
    private let maxTrustScore: Double = 100.0
    private let minTrustScore: Double = 0.0
    private let blacklistThreshold: Double = 20.0
    private let observationThreshold: Double = 30.0
    
    // MARK: - Cleanup Configuration
    private let maxRecordsCount = 10000
    private let cleanupInterval: TimeInterval = 86400 // 24 hours
    private var cleanupTimer: Timer?
    
    // MARK: - Initialization
    init() {
        loadStoredData()
        setupBloomFilter()
        startCleanupTimer()
        startBatchProcessingTimer()
        print("📊 TrustScoreManager: 初始化完成 (異步處理: \(useAsyncProcessing ? "啟用" : "停用"))")
    }
    
    deinit {
        cleanupTimer?.invalidate()
        batchTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// 獲取節點的信任評分
    func getTrustScore(for deviceUUID: String) -> Double {
        return trustScores[deviceUUID]?.currentScore ?? initialTrustScore
    }
    
    /// 獲取節點的詳細信任資訊
    func getTrustInfo(for deviceUUID: String) -> TrustScore {
        return trustScores[deviceUUID] ?? TrustScore(
            deviceUUID: deviceUUID,
            currentScore: initialTrustScore,
            createdAt: Date(),
            lastUpdated: Date()
        )
    }
    
    /// 記錄正常通訊行為
    func recordSuccessfulCommunication(for deviceUUID: String, messageType: TrustMessageType = .general) {
        let increment = calculateScoreIncrement(for: messageType)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: increment, reason: .successfulCommunication)
        } else {
            updateTrustScore(for: deviceUUID, change: increment, reason: .successfulCommunication)
        }
        
        print("✅ TrustScoreManager: 記錄成功通訊 - \(deviceUUID) (+\(increment)) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄異常行為
    func recordSuspiciousBehavior(for deviceUUID: String, behavior: SuspiciousBehavior) {
        let decrement = calculateScoreDecrement(for: behavior)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .suspiciousBehavior(behavior))
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .suspiciousBehavior(behavior))
        }
        
        print("⚠️ TrustScoreManager: 記錄可疑行為 - \(deviceUUID) (-\(decrement)): \(behavior) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄過度廣播行為
    func recordExcessiveBroadcast(for deviceUUID: String, messageCount: Int, timeWindow: TimeInterval) {
        let severity = calculateBroadcastSeverity(messageCount: messageCount, timeWindow: timeWindow)
        let decrement = severity * 5.0 // 基礎懲罰分數
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .excessiveBroadcast)
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .excessiveBroadcast)
        }
        
        print("📢 TrustScoreManager: 記錄過度廣播 - \(deviceUUID) (-\(decrement)) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 記錄錯誤封包行為
    func recordMalformedPacket(for deviceUUID: String, errorType: PacketError) {
        let decrement = calculatePacketErrorDecrement(for: errorType)
        
        if useAsyncProcessing {
            updateTrustScoreAsync(for: deviceUUID, change: -decrement, reason: .malformedPacket(errorType))
        } else {
            updateTrustScore(for: deviceUUID, change: -decrement, reason: .malformedPacket(errorType))
        }
        
        print("🚫 TrustScoreManager: 記錄錯誤封包 - \(deviceUUID) (-\(decrement)): \(errorType) [\(useAsyncProcessing ? "異步" : "同步")]")
    }
    
    /// 檢查節點是否在本地黑名單中
    func isBlacklisted(_ deviceUUID: String) -> Bool {
        return localBlacklist.contains(deviceUUID)
    }
    
    /// 檢查節點是否在觀察名單中
    func isUnderObservation(_ deviceUUID: String) -> Bool {
        return observationList.contains(deviceUUID)
    }
    
    /// 手動加入黑名單
    func addToBlacklist(_ deviceUUID: String, reason: String) {
        localBlacklist.insert(deviceUUID)
        
        // 更新信任評分為最低
        updateTrustScore(for: deviceUUID, change: -maxTrustScore, reason: .manualBlacklist)
        
        // 添加到 Bloom Filter
        bloomFilter?.add(deviceUUID)
        
        saveData()
        print("🚫 TrustScoreManager: 手動加入黑名單 - \(deviceUUID): \(reason)")
    }
    
    /// 從黑名單移除
    func removeFromBlacklist(_ deviceUUID: String) {
        localBlacklist.remove(deviceUUID)
        observationList.remove(deviceUUID)
        
        // 重設信任評分
        updateTrustScore(for: deviceUUID, change: initialTrustScore, reason: .manualWhitelist)
        
        saveData()
        print("✅ TrustScoreManager: 從黑名單移除 - \(deviceUUID)")
    }
    
    /// 獲取信任評分統計
    func getTrustStatistics() -> TrustStatistics {
        let scores = trustScores.values.map { $0.currentScore }
        let totalNodes = scores.count
        let averageScore = totalNodes > 0 ? scores.reduce(0, +) / Double(totalNodes) : 0
        
        let trustedNodes = scores.filter { $0 >= 80 }.count
        let suspiciousNodes = scores.filter { $0 < observationThreshold }.count
        let blacklistedNodes = localBlacklist.count
        
        return TrustStatistics(
            totalNodes: totalNodes,
            averageScore: averageScore,
            trustedNodes: trustedNodes,
            suspiciousNodes: suspiciousNodes,
            blacklistedNodes: blacklistedNodes,
            observationNodes: observationList.count
        )
    }
    
    /// 獲取 Bloom Filter 摘要（用於去中心化黑名單同步）
    func getBloomFilterSummary() -> Data? {
        return bloomFilter?.getData()
    }
    
    /// 切換異步處理模式
    func toggleAsyncProcessing(_ enabled: Bool) {
        useAsyncProcessing = enabled
        print("🔄 TrustScoreManager: 異步處理 \(enabled ? "啟用" : "停用")")
        
        if enabled {
            startBatchProcessingTimer()
        } else {
            batchTimer?.invalidate()
            // 立即處理所有待處理的更新
            processPendingUpdates()
        }
    }
    
    /// 合併其他節點的 Bloom Filter
    func mergeBloomFilter(_ filterData: Data) {
        guard let otherFilter = BloomFilter(data: filterData) else {
            print("❌ TrustScoreManager: 無效的 Bloom Filter 資料")
            return
        }
        
        bloomFilter?.merge(with: otherFilter)
        print("🔄 TrustScoreManager: 合併 Bloom Filter 完成")
    }
    
    /// 清理過期記錄
    func performCleanup() {
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
        var removedCount = 0
        
        // 清理過期的信任評分記錄
        for (deviceUUID, trustScore) in trustScores {
            if trustScore.lastUpdated < cutoffDate {
                trustScores.removeValue(forKey: deviceUUID)
                removedCount += 1
            }
        }
        
        // 限制記錄數量
        if trustScores.count > maxRecordsCount {
            let sortedScores = trustScores.sorted { $0.value.lastUpdated < $1.value.lastUpdated }
            let toRemove = sortedScores.prefix(trustScores.count - maxRecordsCount)
            
            for (deviceUUID, _) in toRemove {
                trustScores.removeValue(forKey: deviceUUID)
                removedCount += 1
            }
        }
        
        saveData()
        print("🧹 TrustScoreManager: 清理了 \(removedCount) 個過期記錄")
    }
    
    // MARK: - Private Methods
    
    /// 異步更新信任評分
    private func updateTrustScoreAsync(for deviceUUID: String, change: Double, reason: ScoreChangeReason) {
        // 高優先級更新（黑名單相關）立即處理
        if case .suspiciousBehavior(let behavior) = reason,
           [.invalidSignature, .maliciousContent].contains(behavior) {
            asyncQueue.async { [weak self] in
                self?.updateTrustScore(for: deviceUUID, change: change, reason: reason)
            }
            return
        }
        
        // 其他更新加入批次處理佇列
        let update = PendingTrustUpdate(
            deviceUUID: deviceUUID,
            change: change,
            reason: reason,
            timestamp: Date(),
            priority: determinePriority(for: reason)
        )
        
        batchQueue.async { [weak self] in
            self?.addToPendingUpdates(update)
        }
    }
    
    /// 同步更新信任評分（原有方法）
    private func updateTrustScore(for deviceUUID: String, change: Double, reason: ScoreChangeReason) {
        var trustScore = trustScores[deviceUUID] ?? TrustScore(
            deviceUUID: deviceUUID,
            currentScore: initialTrustScore,
            createdAt: Date(),
            lastUpdated: Date()
        )
        
        // 應用分數變化
        trustScore.currentScore = max(minTrustScore, min(maxTrustScore, trustScore.currentScore + change))
        trustScore.lastUpdated = Date()
        trustScore.updateCount += 1
        
        // 記錄歷史
        let historyEntry = ScoreHistory(
            timestamp: Date(),
            change: change,
            reason: reason,
            resultingScore: trustScore.currentScore
        )
        trustScore.history.append(historyEntry)
        
        // 限制歷史記錄數量
        if trustScore.history.count > 100 {
            trustScore.history.removeFirst(trustScore.history.count - 100)
        }
        
        trustScores[deviceUUID] = trustScore
        
        // 檢查是否需要加入觀察名單或黑名單
        updateNodeStatus(deviceUUID, score: trustScore.currentScore)
        
        saveData()
    }
    
    /// 更新節點狀態（觀察名單/黑名單）
    private func updateNodeStatus(_ deviceUUID: String, score: Double) {
        if score < blacklistThreshold {
            // 加入黑名單
            if !localBlacklist.contains(deviceUUID) {
                localBlacklist.insert(deviceUUID)
                bloomFilter?.add(deviceUUID)
                print("🚫 TrustScoreManager: 自動加入黑名單 - \(deviceUUID) (分數: \(score))")
            }
        } else if score < observationThreshold {
            // 加入觀察名單
            if !observationList.contains(deviceUUID) {
                observationList.insert(deviceUUID)
                print("👁️ TrustScoreManager: 加入觀察名單 - \(deviceUUID) (分數: \(score))")
            }
        } else {
            // 移出觀察名單（但不自動移出黑名單）
            observationList.remove(deviceUUID)
        }
    }
    
    /// 計算分數增量
    private func calculateScoreIncrement(for messageType: TrustMessageType) -> Double {
        switch messageType {
        case .emergency:
            return 2.0
        case .general:
            return 1.0
        case .heartbeat:
            return 0.5
        case .system:
            return 1.5
        }
    }
    
    /// 計算分數減量
    private func calculateScoreDecrement(for behavior: SuspiciousBehavior) -> Double {
        switch behavior {
        case .duplicateMessages:
            return 3.0
        case .invalidSignature:
            return 10.0
        case .timestampManipulation:
            return 8.0
        case .excessiveRetransmission:
            return 4.0
        case .protocolViolation:
            return 6.0
        case .maliciousContent:
            return 15.0
        }
    }
    
    /// 計算廣播嚴重程度
    private func calculateBroadcastSeverity(messageCount: Int, timeWindow: TimeInterval) -> Double {
        let messagesPerMinute = Double(messageCount) / (timeWindow / 60.0)
        
        switch messagesPerMinute {
        case 0..<10:
            return 1.0
        case 10..<20:
            return 2.0
        case 20..<50:
            return 4.0
        default:
            return 8.0
        }
    }
    
    /// 計算封包錯誤減量
    private func calculatePacketErrorDecrement(for error: PacketError) -> Double {
        switch error {
        case .invalidFormat:
            return 3.0
        case .corruptedData:
            return 5.0
        case .unsupportedVersion:
            return 2.0
        case .invalidChecksum:
            return 4.0
        case .oversizedPacket:
            return 3.0
        }
    }
    
    /// 設置 Bloom Filter
    private func setupBloomFilter() {
        if let data = UserDefaults.standard.data(forKey: bloomFilterKey),
           let filter = BloomFilter(data: data) {
            bloomFilter = filter
        } else {
            bloomFilter = BloomFilter(expectedElements: 10000, falsePositiveRate: 0.01)
        }
    }
    
    /// 啟動清理定時器
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.performCleanup()
            }
        }
    }
    
    /// 載入儲存的資料
    private func loadStoredData() {
        // 載入信任評分
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let scores = try? JSONDecoder().decode([String: TrustScore].self, from: data) {
            trustScores = scores
        }
        
        // 載入黑名單
        if let blacklistArray = UserDefaults.standard.array(forKey: blacklistKey) as? [String] {
            localBlacklist = Set(blacklistArray)
        }
        
        // 載入觀察名單
        if let observationArray = UserDefaults.standard.array(forKey: observationKey) as? [String] {
            observationList = Set(observationArray)
        }
        
        print("📥 TrustScoreManager: 載入 \(trustScores.count) 個信任評分記錄")
    }
    
    /// 儲存資料
    private func saveData() {
        // 儲存信任評分
        if let data = try? JSONEncoder().encode(trustScores) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        
        // 儲存黑名單
        UserDefaults.standard.set(Array(localBlacklist), forKey: blacklistKey)
        
        // 儲存觀察名單
        UserDefaults.standard.set(Array(observationList), forKey: observationKey)
        
        // 儲存 Bloom Filter
        if let filterData = bloomFilter?.getData() {
            UserDefaults.standard.set(filterData, forKey: bloomFilterKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// 添加到待處理更新佇列
    private func addToPendingUpdates(_ update: PendingTrustUpdate) {
        let key = update.deviceUUID
        
        if let existing = pendingUpdates[key] {
            // 合併相同裝置的更新
            let mergedUpdate = PendingTrustUpdate(
                deviceUUID: key,
                change: existing.change + update.change,
                reason: update.priority.rawValue > existing.priority.rawValue ? update.reason : existing.reason,
                timestamp: max(existing.timestamp, update.timestamp),
                priority: update.priority.rawValue > existing.priority.rawValue ? update.priority : existing.priority
            )
            pendingUpdates[key] = mergedUpdate
        } else {
            pendingUpdates[key] = update
        }
    }
    
    /// 處理待處理的更新
    private func processPendingUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = Array(pendingUpdates.values).sorted { $0.priority.rawValue > $1.priority.rawValue }
        pendingUpdates.removeAll()
        
        asyncQueue.async { [weak self] in
            for update in updates {
                self?.updateTrustScore(for: update.deviceUUID, change: update.change, reason: update.reason)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .trustScoreBatchUpdated, object: nil)
            }
        }
    }
    
    /// 啟動批次處理定時器
    private func startBatchProcessingTimer() {
        guard useAsyncProcessing else { return }
        
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchProcessingInterval, repeats: true) { [weak self] _ in
            self?.processPendingUpdates()
        }
    }
    
    /// 決定更新優先級
    private func determinePriority(for reason: ScoreChangeReason) -> UpdatePriority {
        switch reason {
        case .suspiciousBehavior(let behavior):
            switch behavior {
            case .invalidSignature, .maliciousContent:
                return .critical
            case .protocolViolation, .timestampManipulation:
                return .high
            default:
                return .medium
            }
        case .manualBlacklist, .manualWhitelist:
            return .critical
        case .excessiveBroadcast:
            return .high
        case .malformedPacket:
            return .medium
        case .successfulCommunication:
            return .low
        }
    }
}

// MARK: - Async Processing Support Types

/// 待處理的信任評分更新
struct PendingTrustUpdate {
    let deviceUUID: String
    let change: Double
    let reason: ScoreChangeReason
    let timestamp: Date
    let priority: UpdatePriority
}

/// 更新優先級
enum UpdatePriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    static func < (lhs: UpdatePriority, rhs: UpdatePriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let trustScoreUpdated = Notification.Name("trustScoreUpdated")
    static let trustScoreBatchUpdated = Notification.Name("trustScoreBatchUpdated")
}

// MARK: - Supporting Types

/// 信任評分記錄
struct TrustScore: Codable {
    let deviceUUID: String
    var currentScore: Double
    let createdAt: Date
    var lastUpdated: Date
    var updateCount: Int = 0
    var history: [ScoreHistory] = []
    
    var trustLevel: TrustLevel {
        switch currentScore {
        case 80...100:
            return .trusted
        case 60..<80:
            return .reliable
        case 40..<60:
            return .neutral
        case 20..<40:
            return .suspicious
        default:
            return .untrusted
        }
    }
}

/// 評分歷史記錄
struct ScoreHistory: Codable {
    let timestamp: Date
    let change: Double
    let reason: ScoreChangeReason
    let resultingScore: Double
}

/// 評分變化原因
enum ScoreChangeReason: Codable {
    case successfulCommunication
    case suspiciousBehavior(SuspiciousBehavior)
    case excessiveBroadcast
    case malformedPacket(PacketError)
    case manualBlacklist
    case manualWhitelist
}

/// 可疑行為類型
enum SuspiciousBehavior: String, Codable, CaseIterable {
    case duplicateMessages = "DUPLICATE_MESSAGES"
    case invalidSignature = "INVALID_SIGNATURE"
    case timestampManipulation = "TIMESTAMP_MANIPULATION"
    case excessiveRetransmission = "EXCESSIVE_RETRANSMISSION"
    case protocolViolation = "PROTOCOL_VIOLATION"
    case maliciousContent = "MALICIOUS_CONTENT"
}

/// 封包錯誤類型
enum PacketError: String, Codable, CaseIterable {
    case invalidFormat = "INVALID_FORMAT"
    case corruptedData = "CORRUPTED_DATA"
    case unsupportedVersion = "UNSUPPORTED_VERSION"
    case invalidChecksum = "INVALID_CHECKSUM"
    case oversizedPacket = "OVERSIZED_PACKET"
}

/// 信任分數訊息類型
enum TrustMessageType: String, CaseIterable {
    case emergency = "EMERGENCY"
    case general = "GENERAL"
    case heartbeat = "HEARTBEAT"
    case system = "SYSTEM"
}

/// 信任等級
enum TrustLevel: String, CaseIterable {
    case trusted = "TRUSTED"
    case reliable = "RELIABLE"
    case neutral = "NEUTRAL"
    case suspicious = "SUSPICIOUS"
    case untrusted = "UNTRUSTED"
    
    var description: String {
        switch self {
        case .trusted:
            return "可信"
        case .reliable:
            return "可靠"
        case .neutral:
            return "中性"
        case .suspicious:
            return "可疑"
        case .untrusted:
            return "不可信"
        }
    }
    
    var color: UIColor {
        switch self {
        case .trusted:
            return .systemGreen
        case .reliable:
            return .systemBlue
        case .neutral:
            return .systemYellow
        case .suspicious:
            return .systemOrange
        case .untrusted:
            return .systemRed
        }
    }
}

/// 信任統計
struct TrustStatistics {
    let totalNodes: Int
    let averageScore: Double
    let trustedNodes: Int
    let suspiciousNodes: Int
    let blacklistedNodes: Int
    let observationNodes: Int
}

/// 簡化的 Bloom Filter 實作
class BloomFilter {
    private var bitArray: [Bool]
    private let hashFunctionCount: Int
    private let size: Int
    
    init(expectedElements: Int, falsePositiveRate: Double) {
        self.size = Int(-Double(expectedElements) * log(falsePositiveRate) / (log(2) * log(2)))
        self.hashFunctionCount = Int(Double(size) / Double(expectedElements) * log(2))
        self.bitArray = Array(repeating: false, count: size)
    }
    
    init?(data: Data) {
        guard data.count >= 8 else { return nil }
        
        let sizeBytes = data.prefix(4)
        let hashCountBytes = data.dropFirst(4).prefix(4)
        
        self.size = Int(sizeBytes.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian)
        self.hashFunctionCount = Int(hashCountBytes.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian)
        
        let bitData = data.dropFirst(8)
        self.bitArray = bitData.map { $0 != 0 }
    }
    
    func add(_ element: String) {
        let hashes = getHashes(for: element)
        for hash in hashes {
            bitArray[hash % size] = true
        }
    }
    
    func contains(_ element: String) -> Bool {
        let hashes = getHashes(for: element)
        return hashes.allSatisfy { bitArray[$0 % size] }
    }
    
    func merge(with other: BloomFilter) {
        guard size == other.size else { return }
        
        for i in 0..<size {
            bitArray[i] = bitArray[i] || other.bitArray[i]
        }
    }
    
    func getData() -> Data {
        var data = Data()
        
        // 添加 size 和 hashFunctionCount
        var sizeBytes = Int32(size).bigEndian
        var hashCountBytes = Int32(hashFunctionCount).bigEndian
        
        data.append(Data(bytes: &sizeBytes, count: 4))
        data.append(Data(bytes: &hashCountBytes, count: 4))
        
        // 添加 bit array
        let bitData = Data(bitArray.map { $0 ? UInt8(1) : UInt8(0) })
        data.append(bitData)
        
        return data
    }
    
    private func getHashes(for element: String) -> [Int] {
        let data = element.data(using: .utf8) ?? Data()
        var hashes: [Int] = []
        
        for i in 0..<hashFunctionCount {
            let hash = data.hashValue ^ i
            hashes.append(abs(hash))
        }
        
        return hashes
    }
} 