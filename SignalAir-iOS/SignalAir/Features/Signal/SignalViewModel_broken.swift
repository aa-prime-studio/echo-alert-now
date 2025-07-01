import Foundation
import SwiftUI
import MultipeerConnectivity
import CoreLocation
import Combine
import CryptoKit // Added for SHA256

// MARK: - 內聯二進制編碼器（已啟用）
struct InlineBinaryEncoder {
    static func encodeSignalData(
        id: String,
        type: SignalType,
        deviceName: String,
        deviceID: String,
        gridCode: String?,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 標誌位
        var flags: UInt8 = 0
        switch type {
        case .safe: flags |= 0x01
        case .medical: flags |= 0x02
        case .supplies: flags |= 0x04
        case .danger: flags |= 0x08
        }
        if gridCode != nil { flags |= 0x10 }
        data.append(flags)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 設備名稱
        if let nameData = deviceName.data(using: .utf8) {
            data.append(UInt8(min(nameData.count, 255)))
            data.append(nameData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 設備ID
        if let idData = deviceID.data(using: .utf8) {
            data.append(UInt8(min(idData.count, 255)))
            data.append(idData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 網格碼（如果有）
        if let gridCode = gridCode, let gridData = gridCode.data(using: .utf8) {
            data.append(UInt8(min(gridData.count, 255)))
            data.append(gridData.prefix(255))
        }
        
        return data
    }
    
    static func encodeEncryptedSignal(
        id: String,
        senderID: String,
        encryptedPayload: Data,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(1)
        
        // 1 byte: 消息類型（信號）
        data.append(3) // Signal = 3 (統一映射)
        
        // 1 byte: 加密標誌
        data.append(1)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 加密載荷長度
        let payloadLength = UInt16(encryptedPayload.count)
        data.append(contentsOf: withUnsafeBytes(of: payloadLength.littleEndian) { Array($0) })
        
        // N bytes: 加密載荷
        data.append(encryptedPayload)
        
        return data
    }
}

// MARK: - 內聯二進制解碼器
struct InlineBinaryDecoder {
    static func decodeSignalData(_ data: Data) -> (
        type: SignalType,
        timestamp: Date,
        id: String,
        deviceName: String,
        deviceID: String,
        gridCode: String?
    )? {
        guard data.count >= 23 else { return nil } // 最小長度檢查
        
        var offset = 0
        
        // 標誌位
        let flags = data[offset]
        offset += 1
        
        // 解析信號類型
        let type: SignalType
        if flags & 0x01 != 0 {
            type = .safe
        } else if flags & 0x02 != 0 {
            type = .medical
        } else if flags & 0x04 != 0 {
            type = .supplies
        } else if flags & 0x08 != 0 {
            type = .danger
        } else {
            return nil
        }
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 設備名稱
        guard offset < data.count else { return nil }
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 設備ID
        guard offset < data.count else { return nil }
        let idLength = Int(data[offset])
        offset += 1
        
        guard offset + idLength <= data.count else { return nil }
        let deviceID = String(data: data.subdata(in: offset..<offset+idLength), encoding: .utf8) ?? ""
        offset += idLength
        
        // 網格碼（可選）
        var gridCode: String?
        if flags & 0x10 != 0 && offset < data.count { // hasGridCode 標誌
            let gridLength = Int(data[offset])
            offset += 1
            
            if offset + gridLength <= data.count {
                gridCode = String(data: data.subdata(in: offset..<offset+gridLength), encoding: .utf8)
            }
        }
        
        return (
            type: type,
            timestamp: timestamp,
            id: uuid.uuidString,
            deviceName: deviceName,
            deviceID: deviceID,
            gridCode: gridCode
        )
    }
}

// MARK: - Security Event Logger
enum SecurityEventType: String, CaseIterable {
    case hmacVerificationFailed = "HMAC_VERIFICATION_FAILED"
    case decryptionFailed = "DECRYPTION_FAILED"
    case messageNumberMismatch = "MESSAGE_NUMBER_MISMATCH"
    case invalidMessageFormat = "INVALID_MESSAGE_FORMAT"
    case sessionKeyMissing = "SESSION_KEY_MISSING"
    case signatureInvalid = "SIGNATURE_INVALID"
    case replayAttackDetected = "REPLAY_ATTACK_DETECTED"
    case encryptionSuccess = "ENCRYPTION_SUCCESS"
    case decryptionSuccess = "DECRYPTION_SUCCESS"
    case dataAccess = "DATA_ACCESS"
    case securityWarning = "SECURITY_WARNING"
}

struct SecurityEvent {
    let type: SecurityEventType
    let peerID: String
    let timestamp: Date
    let details: String
    let severity: SecuritySeverity
    
    enum SecuritySeverity: String {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case critical = "CRITICAL"
    }
}

class SecurityLogger {
    private var events: [SecurityEvent] = []
    private let maxEvents = 1000
    private let queue = DispatchQueue(label: "SecurityLogger", qos: .utility)
    
    func logEvent(_ type: SecurityEventType, peerID: String, details: String = "", severity: SecurityEvent.SecuritySeverity = .medium) {
        queue.async {
            let event = SecurityEvent(
                type: type,
                peerID: peerID,
                timestamp: Date(),
                details: details,
                severity: severity
            )
            
            self.events.insert(event, at: 0)
            
            // 限制事件數量
            if self.events.count > self.maxEvents {
                self.events = Array(self.events.prefix(self.maxEvents))
            }
            
            // 根據嚴重性打印日誌
            let logPrefix = self.getLogPrefix(for: severity)
            print("\(logPrefix) SecurityLogger: [\(type.rawValue)] \(peerID) - \(details)")
        }
    }
    
    private func getLogPrefix(for severity: SecurityEvent.SecuritySeverity) -> String {
        switch severity {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "🚨"
        case .critical: return "🔴"
        }
    }
    
    func getRecentEvents(limit: Int = 50) -> [SecurityEvent] {
        return queue.sync {
            return Array(events.prefix(limit))
        }
    }
    
    func getEventsForPeer(_ peerID: String, limit: Int = 20) -> [SecurityEvent] {
        return queue.sync {
            return Array(events.filter { $0.peerID == peerID }.prefix(limit))
        }
    }
}

// MARK: - Admin System Removed
// 管理員系統已完全移除

// MARK: - Replay Attack Protection

/// 安全的訊息指紋結構 - 用於安全地暴露訊息元資料
struct SafeMessageFingerprint {
    let timestamp: Date
    let messageType: String // 訊息類型而非具體內容
    let processingStatus: String // 處理狀態
    let securityLevel: String // 安全等級
    
    /// 從完整的 MessageFingerprint 創建安全版本
    static func createSafe(from fingerprint: MessageFingerprint, includeFullContent: Bool = false, hasAdminPermission: Bool = false) -> SafeMessageFingerprint {
        // 管理員系統已移除，始終使用一般用戶權限
        let messageType = "Signal_Message"
        let securityLevel = "User_Limited"
        
        return SafeMessageFingerprint(
            timestamp: fingerprint.timestamp,
            messageType: messageType,
            processingStatus: "Processed",
            securityLevel: securityLevel
        )
    }
}

struct MessageFingerprint {
    let messageID: String
    let senderID: String
    let timestamp: Date
    let contentHash: String
    
    /// 生成訊息指紋
    static func create(messageID: String, senderID: String, timestamp: Date, content: Data) -> MessageFingerprint {
        let contentHash = SHA256.hash(data: content).compactMap { String(format: "%02x", $0) }.joined()
        return MessageFingerprint(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            contentHash: contentHash
        )
    }
    
    /// 生成唯一標識符
    var uniqueID: String {
        return "\(senderID):\(messageID):\(contentHash)"
    }
}

class ReplayAttackProtection {
    private var receivedMessages: [String: MessageFingerprint] = [:]
    private let timeWindow: TimeInterval = 300 // 5分鐘時間窗口
    private let maxCacheSize = 10000 // 最大快取數量
    private let cleanupInterval: TimeInterval = 60 // 每分鐘清理一次
    private let queue = DispatchQueue(label: "ReplayProtection", qos: .utility)
    private var cleanupTimer: Timer?
    
    init() {
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    /// 檢查訊息是否為重放攻擊
    func isReplayAttack(messageID: String, senderID: String, timestamp: Date, content: Data) -> Bool {
        return queue.sync {
            let fingerprint = MessageFingerprint.create(
                messageID: messageID,
                senderID: senderID,
                timestamp: timestamp,
                content: content
            )
            
            // 1. 檢查時間窗口（防止過期訊息）
            let now = Date()
            let messageAge = now.timeIntervalSince(timestamp)
            
            if messageAge > timeWindow {
                print("🚨 ReplayProtection: 訊息過期 - 年齡: \(Int(messageAge))秒")
                return true // 過期訊息視為重放攻擊
            }
            
            if messageAge < -30 { // 允許30秒的時鐘偏差
                print("🚨 ReplayProtection: 訊息來自未來 - 偏差: \(Int(-messageAge))秒")
                return true // 來自未來的訊息可能是攻擊
            }
            
            // 2. 檢查是否已經接收過相同訊息
            if receivedMessages[fingerprint.uniqueID] != nil {
                print("🚨 ReplayProtection: 檢測到重複訊息 - \(fingerprint.uniqueID)")
                return true // 重複訊息
            }
            
            // 3. 記錄新訊息
            receivedMessages[fingerprint.uniqueID] = fingerprint
            
            // 4. 檢查快取大小限制
            if receivedMessages.count > maxCacheSize {
                cleanupOldMessages()
            }
            
            print("✅ ReplayProtection: 訊息驗證通過 - \(messageID)")
            return false // 非重放攻擊
        }
    }
    
    /// 清理過期訊息
    private func cleanupOldMessages() {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-timeWindow)
        
        var removedCount = 0
        let keysToRemove = receivedMessages.compactMap { (key, fingerprint) in
            return fingerprint.timestamp < cutoffTime ? key : nil
        }
        
        for key in keysToRemove {
            receivedMessages.removeValue(forKey: key)
            removedCount += 1
        }
        
        print("🧹 ReplayProtection: 清理了 \(removedCount) 個過期訊息記錄")
    }
    
    /// 啟動定期清理計時器
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { _ in
            self.queue.async {
                self.cleanupOldMessages()
            }
        }
    }
    
    /// 獲取快取統計資訊
    func getCacheStats() -> (count: Int, oldestMessage: Date?) {
        return queue.sync {
            let count = receivedMessages.count
            let oldestMessage = receivedMessages.values.min(by: { $0.timestamp < $1.timestamp })?.timestamp
            return (count, oldestMessage)
        }
    }
    
    /// 清除所有快取（用於測試或重置）
    func clearCache() {
        queue.async {
            self.receivedMessages.removeAll()
            print("🧹 ReplayProtection: 清除所有訊息快取")
        }
    }
}

// MARK: - LRU Cache Implementation
class LRUCache<Key: Hashable, Value> {
    
    private class Node {
        var key: Key?
        var value: Value?
        var prev: Node?
        var next: Node?
        
        init(key: Key? = nil, value: Value? = nil) {
            self.key = key
            self.value = value
        }
        
        // 用於 dummy 節點
        init() {
            self.key = nil
            self.value = nil
        }
    }
    
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private let head = Node() // Dummy head
    private let tail = Node() // Dummy tail
    private let queue = DispatchQueue(label: "LRUCache", qos: .utility)
    
    init(capacity: Int) {
        self.capacity = capacity
        head.next = tail
        tail.prev = head
    }
    
    /// 獲取值（線程安全）
    func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let node = cache[key] else { return nil }
            
            // 移動到頭部（最近使用）
            moveToHead(node)
            return node.value
        }
    }
    
    /// 設置值（線程安全）
    func set(_ key: Key, _ value: Value) {
        queue.async {
            if let existingNode = self.cache[key] {
                // 更新現有節點
                existingNode.value = value
                self.moveToHead(existingNode)
            } else {
                // 添加新節點
                let newNode = Node(key: key, value: value)
                
                if self.cache.count >= self.capacity {
                    // 移除最少使用的節點
                    self.removeLeastUsed()
                }
                
                self.cache[key] = newNode
                self.addToHead(newNode)
            }
        }
    }
    
    /// 檢查是否包含鍵（線程安全）
    func contains(_ key: Key) -> Bool {
        return queue.sync {
            return cache[key] != nil
        }
    }
    
    /// 移除指定鍵（線程安全）
    func remove(_ key: Key) {
        queue.async {
            if let node = self.cache[key] {
                self.cache.removeValue(forKey: key)
                self.removeNode(node)
            }
        }
    }
    
    /// 清空快取（線程安全）
    func removeAll() {
        queue.async {
            self.cache.removeAll()
            self.head.next = self.tail
            self.tail.prev = self.head
        }
    }
    
    /// 獲取當前大小
    func count() -> Int {
        return queue.sync {
            return cache.count
        }
    }
    
    /// 獲取所有鍵（按使用順序）
    func getAllKeys() -> [Key] {
        return queue.sync {
            var keys: [Key] = []
            var current = head.next
            while current !== tail, let currentNode = current, let key = currentNode.key {
                keys.append(key)
                current = currentNode.next
            }
            return keys
        }
    }
    
    // MARK: - 私有方法
    
    private func addToHead(_ node: Node) {
        node.prev = head
        node.next = head.next
        head.next?.prev = node
        head.next = node
    }
    
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
    
    private func moveToHead(_ node: Node) {
        removeNode(node)
        addToHead(node)
    }
    
    private func removeLeastUsed() {
        if let lru = tail.prev, lru !== head, let key = lru.key {
            cache.removeValue(forKey: key)
            removeNode(lru)
        }
    }
}

// MARK: - Message Deduplicator
class MessageDeduplicator {
    private let lruCache: LRUCache<String, MessageFingerprint>
    private let maxCacheSize: Int
    private let timeWindow: TimeInterval
    private var cleanupTimer: Timer?
    private let cleanupInterval: TimeInterval = 300 // 5分鐘清理一次
    
    // 速率限制器
    private let rateLimiter: RateLimiter
    
    // 系統健康監控
    private var consecutiveErrors = 0
    private let maxConsecutiveErrors = 10
    private var lastHealthCheck = Date()
    
    init(maxCacheSize: Int = 1000, timeWindow: TimeInterval = 1800, rateLimiter: RateLimiter? = nil) {
        self.maxCacheSize = maxCacheSize
        self.timeWindow = timeWindow
        self.lruCache = LRUCache<String, MessageFingerprint>(capacity: maxCacheSize)
        
        // 使用提供的速率限制器或創建預設的
        self.rateLimiter = rateLimiter ?? RateLimiter(
            maxQueriesPerMinute: 1000,  // 每分鐘最多1000次查詢
            maxQueriesPerSecond: 50     // 每秒最多50次查詢
        )
        
        startCleanupTimer()
        print("🔄 MessageDeduplicator: 初始化完成")
        print("   最大快取: \(maxCacheSize)")
        print("   時間窗口: \(Int(timeWindow/60)) 分鐘")
        print("   清理間隔: \(Int(cleanupInterval/60)) 分鐘")
        print("   速率限制: 每分鐘\(self.rateLimiter.getStatistics().maxQueriesPerMinute)次，每秒\(self.rateLimiter.getStatistics().maxQueriesPerSecond)次")
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    /// 檢查訊息是否重複（帶速率限制）
    func isDuplicate(messageID: String, senderID: String, timestamp: Date, content: Data) throws -> Bool {
        // 首先檢查速率限制
        do {
            try rateLimiter.checkRateLimit()
        } catch {
            print("🚨 MessageDeduplicator: 速率限制觸發 - \(error.localizedDescription)")
            throw error
        }
        
        // 檢查系統健康狀態
        try checkSystemHealth()
        
        let fingerprint = MessageFingerprint.create(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: content
        )
        
        let uniqueKey = fingerprint.uniqueID
        
        // 檢查是否已存在
        if lruCache.contains(uniqueKey) {
            consecutiveErrors = 0 // 重置錯誤計數
            print("🔁 MessageDeduplicator: 檢測到重複訊息 - \(uniqueKey)")
            return true
        }
        
        // 檢查時間窗口
        let messageAge = Date().timeIntervalSince(timestamp)
        if messageAge > timeWindow {
            consecutiveErrors = 0 // 重置錯誤計數
            print("⏰ MessageDeduplicator: 訊息過期 - 年齡: \(Int(messageAge))秒，窗口: \(Int(timeWindow))秒")
            return true // 過期訊息也視為重複
        }
        
        // 添加到快取
        lruCache.set(uniqueKey, fingerprint)
        consecutiveErrors = 0 // 重置錯誤計數
        print("✅ MessageDeduplicator: 新訊息已記錄 - \(messageID)")
        return false
    }

    /// 安全版本的重複檢查（不拋出異常）
    func isDuplicateSafe(messageID: String, senderID: String, timestamp: Date, content: Data) -> (isDuplicate: Bool, error: Error?) {
        do {
            let result = try isDuplicate(messageID: messageID, senderID: senderID, timestamp: timestamp, content: content)
            return (result, nil)
        } catch {
            return (true, error) // 發生錯誤時保守地視為重複
        }
    }

    /// 手動添加訊息到快取（帶速率限制）
    func addMessage(messageID: String, senderID: String, timestamp: Date, content: Data) throws {
        try rateLimiter.checkRateLimit()
        
        let fingerprint = MessageFingerprint.create(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: content
        )
        
        lruCache.set(fingerprint.uniqueID, fingerprint)
        print("📝 MessageDeduplicator: 手動添加訊息 - \(messageID)")
    }

    /// 獲取快取統計
    func getCacheStats() -> (count: Int, capacity: Int, utilizationRate: Double) {
        let currentCount = lruCache.count()
        let utilizationRate = Double(currentCount) / Double(maxCacheSize)
        return (currentCount, maxCacheSize, utilizationRate)
    }
    
    /// 獲取速率限制統計
    func getRateLimitStats() -> RateLimitStatistics {
        return rateLimiter.getStatistics()
    }
    
    /// 獲取完整系統統計
    func getSystemStats() -> DeduplicationSystemStats {
        let cacheStats = getCacheStats()
        let rateLimitStats = getRateLimitStats()
        
        return DeduplicationSystemStats(
            cacheCount: cacheStats.count,
            cacheCapacity: cacheStats.capacity,
            cacheUtilization: cacheStats.utilizationRate,
            rateLimitUtilization: rateLimitStats.utilizationRate,
            totalQueries: rateLimitStats.totalQueries,
            rejectedQueries: rateLimitStats.rejectedQueries,
            consecutiveErrors: consecutiveErrors,
            systemHealth: getSystemHealthStatus()
        )
    }

    /// 清空快取
    func clearCache() {
        lruCache.removeAll()
        consecutiveErrors = 0
        print("🧹 MessageDeduplicator: 快取已清空，錯誤計數已重置")
    }

    /// 獲取最近的訊息（調試用）
    func getRecentMessages(limit: Int = 10) -> [MessageFingerprint] {
        let allKeys = lruCache.getAllKeys()
        let recentKeys = Array(allKeys.prefix(limit))
        
        var results: [MessageFingerprint] = []
        for key in recentKeys {
            if let fingerprint = lruCache.get(key) {
                results.append(fingerprint)
            }
        }
        
        return results
    }

    // MARK: - 私有方法
    
    private func checkSystemHealth() throws {
        let now = Date()
        
        // 每30秒檢查一次系統健康狀態
        if now.timeIntervalSince(lastHealthCheck) > 30 {
            lastHealthCheck = now
            
            let cacheStats = getCacheStats()
            let rateLimitStats = getRateLimitStats()
            
            // 檢查快取使用率
            if cacheStats.utilizationRate > 0.95 {
                print("⚠️ MessageDeduplicator: 快取使用率過高 (\(String(format: "%.1f", cacheStats.utilizationRate * 100))%)")
            }
            
            // 檢查速率限制使用率
            if rateLimitStats.utilizationRate > 0.8 {
                print("⚠️ MessageDeduplicator: 速率限制使用率過高 (\(String(format: "%.1f", rateLimitStats.utilizationRate * 100))%)")
            }
            
            // 檢查連續錯誤
            if consecutiveErrors > maxConsecutiveErrors / 2 {
                print("⚠️ MessageDeduplicator: 連續錯誤偏高 (\(consecutiveErrors)/\(maxConsecutiveErrors))")
            }
        }
        
        // 檢查是否需要觸發系統保護
        if consecutiveErrors >= maxConsecutiveErrors {
            throw DeduplicationError.systemOverload
        }
    }
    
    private func getSystemHealthStatus() -> String {
        if consecutiveErrors >= maxConsecutiveErrors {
            return "系統過載"
        } else if consecutiveErrors > maxConsecutiveErrors / 2 {
            return "警告"
        } else {
            return "正常"
        }
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { _ in
            self.performCleanup()
        }
    }

    private func performCleanup() {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-timeWindow)
        var removedCount = 0
        
        // 獲取所有鍵並檢查過期
        let allKeys = lruCache.getAllKeys()
        
        for key in allKeys {
            if let fingerprint = lruCache.get(key) {
                if fingerprint.timestamp < cutoffTime {
                    lruCache.remove(key)
                    removedCount += 1
                }
            }
        }
        
        if removedCount > 0 {
            print("🧹 MessageDeduplicator: 清理了 \(removedCount) 個過期訊息記錄")
        }
        
        let systemStats = getSystemStats()
        print("📊 MessageDeduplicator: 系統狀態")
        print("   快取: \(systemStats.cacheCount)/\(systemStats.cacheCapacity) (\(String(format: "%.1f", systemStats.cacheUtilization * 100))%)")
        print("   速率: \(String(format: "%.1f", systemStats.rateLimitUtilization * 100))% 使用率")
        print("   健康: \(systemStats.systemHealth)")
    }
}

// MARK: - System Statistics

struct DeduplicationSystemStats {
    let cacheCount: Int
    let cacheCapacity: Int
    let cacheUtilization: Double
    let rateLimitUtilization: Double
    let totalQueries: Int
    let rejectedQueries: Int
    let consecutiveErrors: Int
    let systemHealth: String
    
    var summary: String {
        return """
        去重系統統計:
        快取狀態: \(cacheCount)/\(cacheCapacity) (\(String(format: "%.1f", cacheUtilization * 100))%)
        速率限制: \(String(format: "%.1f", rateLimitUtilization * 100))% 使用率
        總查詢: \(totalQueries)
        被拒絕: \(rejectedQueries)
        連續錯誤: \(consecutiveErrors)
        系統健康: \(systemHealth)
        """
    }
}

// MARK: - Deduplication Errors

enum DeduplicationError: Error, LocalizedError {
    case rateLimitExceeded
    case invalidMessageFormat
    case systemOverload
    case cacheCorrupted
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "查詢速率超過限制，請稍後再試"
        case .invalidMessageFormat:
            return "訊息格式無效"
        case .systemOverload:
            return "系統過載，暫時無法處理請求"
        case .cacheCorrupted:
            return "快取資料損壞，已重新初始化"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded:
            return "等待1分鐘後重試，或降低訊息發送頻率"
        case .invalidMessageFormat:
            return "檢查訊息格式並重新發送"
        case .systemOverload:
            return "等待系統負載降低後重試"
        case .cacheCorrupted:
            return "快取已自動重建，可以繼續使用"
        }
    }
}

// MARK: - Rate Limiter

class RateLimiter {
    private let maxQueriesPerMinute: Int
    private let maxQueriesPerSecond: Int
    private var queryCounter = 0
    private var secondCounter = 0
    private var lastResetTime = Date()
    private var lastSecondResetTime = Date()
    private let queue = DispatchQueue(label: "RateLimiter", qos: .utility)
    
    // 統計資訊
    private var totalQueries = 0
    private var rejectedQueries = 0
    
    init(maxQueriesPerMinute: Int = 1000, maxQueriesPerSecond: Int = 50) {
        self.maxQueriesPerMinute = maxQueriesPerMinute
        self.maxQueriesPerSecond = maxQueriesPerSecond
    }
    
    /// 檢查速率限制
    func checkRateLimit() throws {
        try queue.sync {
            let now = Date()
            
            // 重置每秒計數器
            if now.timeIntervalSince(lastSecondResetTime) >= 1.0 {
                secondCounter = 0
                lastSecondResetTime = now
            }
            
            // 重置每分鐘計數器
            if now.timeIntervalSince(lastResetTime) >= 60.0 {
                queryCounter = 0
                lastResetTime = now
                print("🔄 RateLimiter: 速率限制計數器已重置")
            }
            
            // 檢查每秒限制
            if secondCounter >= maxQueriesPerSecond {
                rejectedQueries += 1
                print("🚨 RateLimiter: 每秒查詢限制已達到 (\(secondCounter)/\(maxQueriesPerSecond))")
                throw DeduplicationError.rateLimitExceeded
            }
            
            // 檢查每分鐘限制
            if queryCounter >= maxQueriesPerMinute {
                rejectedQueries += 1
                print("🚨 RateLimiter: 每分鐘查詢限制已達到 (\(queryCounter)/\(maxQueriesPerMinute))")
                throw DeduplicationError.rateLimitExceeded
            }
            
            // 增加計數器
            queryCounter += 1
            secondCounter += 1
            totalQueries += 1
        }
    }
    
    /// 獲取速率限制統計
    func getStatistics() -> RateLimitStatistics {
        return queue.sync {
            let now = Date()
            let timeUntilReset = max(0, 60.0 - now.timeIntervalSince(lastResetTime))
            
            return RateLimitStatistics(
                currentQueriesPerMinute: queryCounter,
                maxQueriesPerMinute: maxQueriesPerMinute,
                currentQueriesPerSecond: secondCounter,
                maxQueriesPerSecond: maxQueriesPerSecond,
                totalQueries: totalQueries,
                rejectedQueries: rejectedQueries,
                timeUntilReset: timeUntilReset,
                utilizationRate: Double(queryCounter) / Double(maxQueriesPerMinute)
            )
        }
    }
    
    /// 重置統計資料
    func resetStatistics() {
        queue.async {
            self.totalQueries = 0
            self.rejectedQueries = 0
            print("📊 RateLimiter: 統計資料已重置")
        }
    }
    
    /// 動態調整速率限制
    func adjustLimits(queriesPerMinute: Int? = nil, queriesPerSecond: Int? = nil) {
        queue.async {
            if let newMinuteLimit = queriesPerMinute {
                print("⚙️ RateLimiter: 每分鐘限制調整 \(self.maxQueriesPerMinute) → \(newMinuteLimit)")
            }
            if let newSecondLimit = queriesPerSecond {
                print("⚙️ RateLimiter: 每秒限制調整 \(self.maxQueriesPerSecond) → \(newSecondLimit)")
            }
        }
    }
}

struct RateLimitStatistics {
    let currentQueriesPerMinute: Int
    let maxQueriesPerMinute: Int
    let currentQueriesPerSecond: Int
    let maxQueriesPerSecond: Int
    let totalQueries: Int
    let rejectedQueries: Int
    let timeUntilReset: TimeInterval
    let utilizationRate: Double
    
    var summary: String {
        return """
        速率限制統計:
        每分鐘: \(currentQueriesPerMinute)/\(maxQueriesPerMinute) (\(String(format: "%.1f", utilizationRate * 100))%)
        每秒: \(currentQueriesPerSecond)/\(maxQueriesPerSecond)
        總查詢: \(totalQueries)
        被拒絕: \(rejectedQueries)
        重置倒數: \(Int(timeUntilReset))秒
        """
    }
}

// MARK: - SignalViewModel
class SignalViewModel: ObservableObject {
    @Published var messages: [SignalMessage] = []
    @Published var deviceName: String = "SignalAir Rescue裝置"
    @Published var connectionStatus: String = "未連線"
    @Published var connectedPeers: [String] = []
    @Published var lastSignalTime: Date?
    
    // Mesh 網路服務
    private let networkService: NetworkService
    private let securityService: SecurityService
    private var meshManager: MeshManagerProtocol
    // 移除對TemporaryIDManager的直接依賴，改用ServiceContainer
    private var deviceID: String {
        return ServiceContainer.shared.temporaryIDManager.deviceID
    }
    private let selfDestructManager: SelfDestructManager
    private let floodProtection: FloodProtection
    
    // 安全事件記錄器
    private let securityLogger = SecurityLogger()
    
    // 防重放攻擊保護
    private let replayProtection = ReplayAttackProtection()
    
    // 訊息去重器（使用更合理的30分鐘時間窗口）
    private let messageDeduplicator = MessageDeduplicator(maxCacheSize: 1000, timeWindow: 1800)
    
    // Settings 參考
    private var settingsViewModel: SettingsViewModel?
    
    // 位置服務 - 使用系統 CLLocationManager
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化方法
    
    /// 依賴注入初始化
    init(networkService: NetworkService? = nil,
         securityService: SecurityService? = nil,
         meshManager: MeshManagerProtocol? = nil,
         selfDestructManager: SelfDestructManager? = nil,
         floodProtection: FloodProtection? = nil) {
        
        // 使用注入的服務或使用 ServiceContainer 中的服務
        self.networkService = networkService ?? ServiceContainer.shared.networkService
        self.securityService = securityService ?? ServiceContainer.shared.securityService
        self.selfDestructManager = selfDestructManager ?? ServiceContainer.shared.selfDestructManager
        self.floodProtection = floodProtection ?? ServiceContainer.shared.floodProtection
        self.meshManager = meshManager ?? ServiceContainer.shared.meshManager!
        
        setupMeshNetworking()
        setupLocationServices()
        setupNotificationObservers()
        
        print("📡 SignalViewModel: 初始化完成，裝置ID: \(self.deviceID)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 公開方法
    
    /// 設定 SettingsViewModel 參考
    func setSettingsViewModel(_ settings: SettingsViewModel) {
        self.settingsViewModel = settings
    }
    
    /// 發送緊急訊號
    func sendSignal(_ type: SignalType) async {
        // 使用 deviceName 如果存在，否則使用設定中的暱稱
        let userNickname = !deviceName.isEmpty ? deviceName : (settingsViewModel?.userNickname ?? "SignalAir Rescue裝置")
        
        // 創建加密的信號數據
        let signalData = createEncryptedSignalData(type: type, userNickname: userNickname)
        
        // 🚀 純二進制協議，零妥協
        guard let binaryData = signalData["binaryData"] as? Data else {
            print("❌ SignalViewModel: 未找到二進制數據，拒絕發送")
            return
        }
        
        let dataToSend = binaryData
        print("📦 使用純二進制協議發送，數據大小: \(binaryData.count) bytes")
        
        if floodProtection.shouldAcceptMessage(
            from: deviceID,
            content: dataToSend,
            size: dataToSend.count,
            priority: MessagePriority.emergency
        ) {
            // 透過 Mesh 網路廣播加密訊息
            meshManager.broadcastMessage(dataToSend, messageType: .signal)
            
            // 追蹤自毀管理
            let messageId = (signalData["id"] as? String) ?? UUID().uuidString
            selfDestructManager.trackMessage(messageId, type: .signal, priority: MessagePriority.emergency)
            
            // 更新本地 UI（顯示真實暱稱）
            let displayMessage = SignalMessage(
                type: type,
                deviceName: userNickname,
                distance: nil,
                direction: nil,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.insert(displayMessage, at: 0)
                lastSignalTime = Date()
            }
            
            print("📡 SignalViewModel: 發送加密緊急訊號成功 - \(type.rawValue) 來自 \(userNickname)")
            
        } else {
            print("🛡️ SignalViewModel: 訊號被洪水保護阻擋")
            
            // 即使被阻擋也顯示在本地列表
            let displayMessage = SignalMessage(
                type: type,
                deviceName: "\(userNickname) (限制中)",
                distance: nil,
                direction: nil,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.insert(displayMessage, at: 0)
            }
        }
    }
    
    /// 更新連線狀態
    func updateConnectionStatus() {
        switch networkService.connectionStatus {
        case .connected:
            connectionStatus = "已連線"
        case .connecting:
            connectionStatus = "連線中"
        case .disconnected:
            connectionStatus = "未連線"
        }
        connectedPeers = networkService.connectedPeers.map { $0.displayName }
    }
    
    /// 手動重新連線
    func reconnect() {
        networkService.startNetworking()
        print("📡 SignalViewModel: 嘗試重新連線")
    }
    
    /// 斷開連線
    func disconnect() async {
        networkService.stopNetworking()
        await MainActor.run {
            connectionStatus = "未連線"
            connectedPeers = []
        }
        print("📡 SignalViewModel: 已斷開連線")
    }
    
    /// 清除訊息
    func clearMessages() {
        messages.removeAll()
        print("📡 SignalViewModel: 清除所有訊號訊息")
    }
    
    // MARK: - 安全監控方法
    
    /// 獲取最近的安全事件
    func getRecentSecurityEvents(limit: Int = 20) -> [SecurityEvent] {
        return securityLogger.getRecentEvents(limit: limit)
    }
    
    /// 獲取特定 peer 的安全事件
    func getSecurityEventsForPeer(_ peerID: String, limit: Int = 10) -> [SecurityEvent] {
        return securityLogger.getEventsForPeer(peerID, limit: limit)
    }
    
    /// 檢查是否有嚴重安全事件
    func hasRecentCriticalSecurityEvents() -> Bool {
        let recentEvents = securityLogger.getRecentEvents(limit: 10)
        return recentEvents.contains { $0.severity == .critical }
    }
    
    // MARK: - 重放攻擊保護監控方法
    
    /// 獲取重放攻擊保護快取統計
    func getReplayProtectionStats() -> (count: Int, oldestMessage: Date?) {
        return replayProtection.getCacheStats()
    }
    
    /// 清除重放攻擊保護快取（用於測試或重置）
    func clearReplayProtectionCache() {
        replayProtection.clearCache()
        print("🧹 SignalViewModel: 已清除重放攻擊保護快取")
    }
    
    /// 檢查特定訊息是否會被視為重放攻擊
    func wouldBeReplayAttack(messageID: String, senderID: String, timestamp: Date, content: Data) -> Bool {
        return replayProtection.isReplayAttack(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: content
        )
    }
    
    // MARK: - 訊息去重監控方法
    
    /// 獲取訊息去重快取統計
    func getDeduplicationStats() -> (count: Int, capacity: Int, utilizationRate: Double) {
        return messageDeduplicator.getCacheStats()
    }
    
    /// 清除訊息去重快取
    func clearDeduplicationCache() {
        messageDeduplicator.clearCache()
        print("🧹 SignalViewModel: 已清除訊息去重快取")
    }
    
    /// 獲取最近處理的訊息（安全版本）
    /// - Parameters:
    ///   - limit: 返回的訊息數量限制
    ///   - includeContent: 是否包含完整內容（管理員系統已移除，此參數無效）
    /// - Returns: 安全的訊息指紋陣列，僅包含基本資訊
    func getRecentProcessedMessages(limit: Int = 10, includeContent: Bool = false) -> [SafeMessageFingerprint] {
        // 管理員系統已移除，始終使用基本權限
        let hasValidAdminSession = false
        
        // 記錄安全事件：訊息查詢請求
        securityLogger.logEvent(
            .dataAccess,
            peerID: deviceID,
            details: "Recent messages query - limit: \(limit), admin_system_removed",
            severity: .low
        )
        
        if includeContent {
            // 記錄警告：嘗試存取完整內容但管理員系統已移除
            securityLogger.logEvent(
                .securityWarning,
                peerID: deviceID,
                details: "Attempt to access full content but admin system removed",
                severity: .medium
            )
            print("⚠️ SignalViewModel: 嘗試存取完整內容，但管理員系統已移除")
        }
        
        print("👤 SignalViewModel: 查詢最近訊息 - 僅基本資訊（管理員系統已移除）")
        
        // 獲取原始訊息指紋
        let rawFingerprints = messageDeduplicator.getRecentMessages(limit: limit)
        
        // 轉換為安全版本（始終使用基本權限）
        let safeFingerprints = rawFingerprints.map { fingerprint in
            SafeMessageFingerprint.createSafe(
                from: fingerprint,
                includeFullContent: false,
                hasAdminPermission: hasValidAdminSession
            )
        }
        
        // 記錄返回的資料量
        print("📊 SignalViewModel: 返回 \(safeFingerprints.count) 個安全訊息指紋")
        
        return safeFingerprints
    }
    
    // 管理員專用方法已完全移除
    
    /// 獲取最近處理的訊息（原始版本 - 已棄用，僅供向後相容）
    @available(*, deprecated, message: "使用 getRecentProcessedMessages(limit:includeContent:hasAdminPermission:) 以獲得更好的安全性")
    func getRecentProcessedMessagesUnsafe(limit: Int = 10) -> [MessageFingerprint] {
        // 記錄安全警告：使用了不安全的API
        securityLogger.logEvent(
            .securityWarning,
            peerID: deviceID,
            details: "Deprecated unsafe message query API used",
            severity: .high
        )
        
        print("⚠️ SignalViewModel: 使用了已棄用的不安全API - getRecentProcessedMessagesUnsafe")
        return messageDeduplicator.getRecentMessages(limit: limit)
    }
    
    /// 手動添加訊息到去重快取
    func addMessageToDeduplicationCache(messageID: String, senderID: String, timestamp: Date, content: Data) {
        do {
            try messageDeduplicator.addMessage(
                messageID: messageID,
                senderID: senderID,
                timestamp: timestamp,
                content: content
            )
            print("✅ SignalViewModel: 訊息已添加到去重快取 - \(messageID)")
        } catch DeduplicationError.rateLimitExceeded {
            print("🚨 SignalViewModel: 添加訊息到快取時速率限制觸發 - \(messageID)")
            // 速率限制觸發時，我們可以選擇忽略或稍後重試
        } catch {
            print("❌ SignalViewModel: 添加訊息到快取失敗 - \(messageID): \(error.localizedDescription)")
        }
    }
    
    // MARK: - 私有方法
    
    /// 設定 Mesh 網路
    private func setupMeshNetworking() {
        // 設定接收處理
        meshManager.onMessageReceived = { [weak self] meshMessage in
            // 只處理信號訊息
            if meshMessage.type == MeshMessageType.signal {
                Task { await self?.handleReceivedSignal(meshMessage.data) }
            }
        }
        
        // 啟動網路服務
        networkService.startNetworking()
        
        print("📡 SignalViewModel: Mesh 網路設定完成")
    }
    
    /// 設定位置服務
    private func setupLocationServices() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        #if targetEnvironment(simulator)
        // 模擬器環境下設定測試位置
        setupSimulatorLocation()
        #endif
    }
    
    /// 設定模擬器位置
    private func setupSimulatorLocation() {
        // 台北市信義區的測試位置
        currentLocation = CLLocation(latitude: 25.0330, longitude: 121.5654)
    }
    
    /// 設定通知觀察者
    private func setupNotificationObservers() {
        // 監聽從 ServiceContainer 路由過來的信號
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SignalReceived"),
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self,
                  let data = notification.object as? Data else { return }
            
            print("📡 SignalViewModel: 收到路由的信號數據")
            
            // 在主線程上處理接收到的信號
            Task {
                await self.handleReceivedSignal(data)
            }
        }
    }
    
    /// 創建信號數據（只傳送網格代碼）
    private func createSignalData(type: SignalType) -> [String: Any] {
        var data: [String: Any] = [
            "id": UUID().uuidString,
            "type": type.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "deviceName": deviceName
        ]
        
        // 只傳送網格代碼，不傳送精確位置
        if let location = currentLocation {
            // 使用本地的網格計算方法
            data["gridCode"] = GridLocationSystem.coordinateToGrid(location.coordinate)
        }
        
        return data
    }
    
    /// 創建加密的信號數據（簡化版本以避免崩潰）
    private func createEncryptedSignalData(type: SignalType, userNickname: String) -> [String: Any] {
        let signalID = UUID().uuidString
        
        // 創建基礎信號數據結構（較小的數據包）
        let basicSignalData: [String: Any] = [
            "id": signalID,
            "type": type.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "senderID": deviceID
        ]
        
        // 檢查連接狀態
        let connectedPeers = networkService.connectedPeers
        guard !connectedPeers.isEmpty else {
            print("⚠️ SignalViewModel: 無連接的 peers，無法加密")
            return basicSignalData
        }
        
        // 簡化：只對第一個連接的peer加密，避免批量加密導致的記憶體問題
        guard let firstPeer = connectedPeers.first else {
            return basicSignalData
        }
        
        let peerID = firstPeer.displayName
        
        // 🚀 純二進制協議，要求必須有會話密鑰
        guard securityService.hasSessionKey(for: peerID) else {
            print("❌ SignalViewModel: \(peerID) 沒有會話密鑰，拒絕發送（純二進制協議要求）")
            
            // 返回基礎數據，但不添加二進制數據
            var errorData = basicSignalData
            errorData["error"] = "No session key available"
            return errorData
        }
        
        do {
            let startTime = Date()
            
            // 🚀 使用二進制協議編碼信號數據
            let gridCode = currentLocation != nil ? coordinateToGrid(currentLocation!.coordinate) : nil
            
            let plainTextData = InlineBinaryEncoder.encodeSignalData(
                id: signalID,
                type: type,
                deviceName: userNickname,
                deviceID: deviceID,
                gridCode: gridCode,
                timestamp: Date()
            )
            
            let encryptedData = try securityService.encrypt(plainTextData, for: peerID)
            
            // 記錄成功
            securityLogger.logEvent(
                .encryptionSuccess,
                peerID: peerID,
                details: "Signal message encrypted successfully",
                severity: .low
            )
            
            print("🔒 SignalViewModel: 為 \(peerID) 加密信號訊息")
            
            // 🚀 使用二進制協議編碼外層加密結構（優化版本）
            let binaryData = InlineBinaryEncoder.encodeEncryptedSignal(
                id: signalID,
                senderID: deviceID,
                encryptedPayload: encryptedData,
                timestamp: Date()
            )
            
            // 簡單的數據完整性檢查
            if binaryData.count > 26 && binaryData[0] == 1 {
                let encodingTime = Date().timeIntervalSince(startTime)
                print("✅ 二進制編碼成功，大小: \(binaryData.count) bytes, 編碼時間: \(String(format: "%.3f", encodingTime * 1000))ms")
            } else {
                print("⚠️ 二進制編碼可能有問題")
            }
            
            return [
                "binaryData": binaryData,
                "isBinary": true,
                "id": signalID  // 保留ID用於追蹤
            ] as [String : Any]
            
        } catch {
            print("❌ SignalViewModel: 加密失敗 - \(error)")
            
            // 記錄錯誤
            securityLogger.logEvent(
                .decryptionFailed,
                peerID: peerID,
                details: "Signal encryption failed: \(error.localizedDescription)",
                severity: .high
            )
            
            // 返回基礎數據
            return basicSignalData
        }
    }
    
    /// 更新訊息的相對位置
    private func updateMessagesWithRelativePositions() {
        guard let currentLoc = currentLocation else { return }
        
        let currentGrid = GridLocationSystem.coordinateToGrid(currentLoc.coordinate)
        
        for i in 0..<messages.count {
            if let peerGridCode = messages[i].gridCode {
                let (distance, direction) = calculateRelativePosition(
                    from: currentGrid,
                    to: peerGridCode
                )
                
                // 更新訊息的距離和方向
                let updatedMessage = messages[i]
                // 注意：SignalMessage 是 struct，需要重新賦值
                messages[i] = SignalMessage(
                    type: updatedMessage.type,
                    deviceName: updatedMessage.deviceName,
                    distance: distance,
                    direction: direction,
                    timestamp: updatedMessage.timestamp,
                    gridCode: updatedMessage.gridCode
                )
            }
        }
    }
    
    /// 處理接收到的訊號
    private func handleReceivedSignal(_ messageData: Data) async {
        do {
            // 🚀 優先嘗試二進制解碼
            var signalDict: [String: Any]?
            
            if messageData.count >= 21 { // 最小二進制信號長度檢查
                if let decodedSignal = InlineBinaryDecoder.decodeSignalData(messageData) {
                    // 轉換二進制解碼結果為字典格式
                    signalDict = [
                        "id": decodedSignal.id,
                        "type": decodedSignal.type.rawValue,
                        "timestamp": decodedSignal.timestamp.timeIntervalSince1970,
                        "deviceName": decodedSignal.deviceName,
                        "senderID": decodedSignal.deviceID,
                        "gridCode": decodedSignal.gridCode as Any
                    ]
                    print("📦 SignalViewModel: 成功解碼二進制信號數據")
                }
            }
            
            // 不再支援 JSON 解碼回退
            if signalDict == nil {
                print("⚠️ SignalViewModel: 數據格式不支援，僅支援二進制協議")
                return
            }
            
            guard let signalData = signalDict else {
                print("❌ SignalViewModel: 無效的信號數據格式")
                return
            }
            
            // 1. 提取基本訊息資訊進行重放攻擊檢查
            let messageID = signalData["id"] as? String ?? UUID().uuidString
            let senderID = signalData["senderID"] as? String ?? "unknown"
            let timestampInterval = signalData["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
            let messageTimestamp = Date(timeIntervalSince1970: timestampInterval)
            
            // 2. 執行重放攻擊檢查
            if replayProtection.isReplayAttack(
                messageID: messageID,
                senderID: senderID,
                timestamp: messageTimestamp,
                content: messageData
            ) {
                // 記錄安全事件：檢測到重放攻擊
                securityLogger.logEvent(
                    .replayAttackDetected,
                    peerID: senderID,
                    details: "Replay attack detected - messageID: \(messageID), age: \(Int(Date().timeIntervalSince(messageTimestamp)))s",
                    severity: .critical
                )
                
                print("🚨 SignalViewModel: 拒絕重放攻擊訊息 - \(messageID) 來自 \(senderID)")
                return // 拒絕處理重放攻擊訊息
            }
            
            // 3. 執行訊息去重檢查（使用LRU快取）
            do {
                if try messageDeduplicator.isDuplicate(
                    messageID: messageID,
                    senderID: senderID,
                    timestamp: messageTimestamp,
                    content: messageData
                ) {
                    print("🔁 SignalViewModel: 拒絕重複訊息 - \(messageID) 來自 \(senderID)")
                    return // 拒絕處理重複訊息
                }
            } catch DeduplicationError.rateLimitExceeded {
                print("🚨 SignalViewModel: 去重檢查速率限制觸發 - \(messageID) 來自 \(senderID)")
                // 速率限制觸發時，使用安全模式檢查
                let safeResult = messageDeduplicator.isDuplicateSafe(
                    messageID: messageID,
                    senderID: senderID,
                    timestamp: messageTimestamp,
                    content: messageData
                )
                
                if safeResult.isDuplicate {
                    print("🔁 SignalViewModel: 安全模式檢測到重複訊息 - \(messageID)")
                    return
                }
                
                if let error = safeResult.error {
                    print("⚠️ SignalViewModel: 安全模式檢查出現問題 - \(error.localizedDescription)")
                }
                
                // 繼續處理訊息（保守但確保服務可用性）
            } catch DeduplicationError.systemOverload {
                print("🚨 SignalViewModel: 去重系統過載 - \(messageID) 來自 \(senderID)")
                // 系統過載時，暫時跳過去重檢查，確保緊急訊息能夠傳遞
                print("⚠️ SignalViewModel: 緊急模式：跳過去重檢查以確保訊息傳遞")
            } catch {
                print("❌ SignalViewModel: 去重檢查失敗 - \(messageID): \(error.localizedDescription)")
                // 其他錯誤時，使用安全模式
                let safeResult = messageDeduplicator.isDuplicateSafe(
                    messageID: messageID,
                    senderID: senderID,
                    timestamp: messageTimestamp,
                    content: messageData
                )
                
                if safeResult.isDuplicate {
                    print("🔁 SignalViewModel: 安全模式檢測到重複訊息 - \(messageID)")
                    return
                }
            }
            
            // 4. 所有檢查通過，繼續處理訊息
            if let messageType = signalData["messageType"] as? String, messageType == "encrypted_signal" {
                // 處理加密的 Signal 訊息
                await handleEncryptedSignal(signalData)
            } else {
                // 處理舊格式或未加密的訊息
                await handlePlainTextSignal(signalData)
            }
    }
    
    /// 處理加密的 Signal 訊息
    func handleEncryptedSignal(_ signalDict: [String: Any]) async {
        guard let senderID = signalDict["senderID"] as? String,
              let encryptedForPeersBase64 = signalDict["encryptedForPeers"] as? [String: String],
              let timestamp = signalDict["timestamp"] as? TimeInterval else {
            
            // 記錄安全事件：無效訊息格式
            securityLogger.logEvent(
                .invalidMessageFormat,
                peerID: signalDict["senderID"] as? String ?? "unknown",
                details: "Missing required fields in encrypted signal: senderID=\(signalDict["senderID"] != nil), encryptedForPeers=\(signalDict["encryptedForPeers"] != nil), timestamp=\(signalDict["timestamp"] != nil)",
                severity: .high
            )
            print("❌ SignalViewModel: 加密訊息格式無效 - 缺少必要欄位")
            print("   可用欄位: \(signalDict.keys.sorted())")
            return
        }
        
        // 嘗試用自己的 ID 解密
        let myPeerID = networkService.myPeerID.displayName
        
        do {
            if let encryptedBase64 = encryptedForPeersBase64[myPeerID],
               let encryptedData = Data(base64Encoded: encryptedBase64) {
                // 找到針對我的加密數據
                let _ = try securityService.decrypt(encryptedData, from: senderID)
                // 暫時禁用JSON解碼，僅支援二進制協議
                print("⚠️ SignalViewModel: 信號解密後僅支援二進制協議")
                return
                
            } else {
                // 記錄安全事件：沒有會話密鑰
                securityLogger.logEvent(
                    .sessionKeyMissing,
                    peerID: senderID,
                    details: "No encrypted data found for my peer ID",
                    severity: .medium
                )
                
                print("⚠️ SignalViewModel: 沒有針對我的加密數據，顯示匿名版本")
                await showAnonymousSignal(senderID: senderID, timestamp: timestamp)
            }
            
        } catch {
            // 根據錯誤類型記錄不同的安全事件
            let eventType: SecurityEventType
            let severity: SecurityEvent.SecuritySeverity
            
            if let cryptoError = error as? CryptoError {
                switch cryptoError {
                case .invalidSignature:
                    eventType = .hmacVerificationFailed
                    severity = .critical
                case .messageNumberMismatch:
                    eventType = .replayAttackDetected
                    severity = .critical
                case .noSessionKey:
                    eventType = .sessionKeyMissing
                    severity = .high
                default:
                    eventType = .decryptionFailed
                    severity = .high
                }
            } else {
                eventType = .decryptionFailed
                severity = .high
            }
            
            securityLogger.logEvent(
                eventType,
                peerID: senderID,
                details: "Decryption failed: \(error.localizedDescription)",
                severity: severity
            )
            
            print("❌ SignalViewModel: 解密失敗 - \(error)")
            // 顯示匿名版本
            await showAnonymousSignal(senderID: senderID, timestamp: timestamp)
        }
    }
    
    /// 處理明文 Signal 訊息（向後兼容）
    func handlePlainTextSignal(_ signalDict: [String: Any]) async {
        guard let typeString = signalDict["type"] as? String,
              let type = SignalType(rawValue: typeString),
              let deviceName = signalDict["deviceName"] as? String,
              let timestamp = signalDict["timestamp"] as? TimeInterval else {
            print("❌ SignalViewModel: 無效的明文信號數據格式")
            return
        }
        
        // 計算距離和方向（基於網格）
        let (distance, direction) = calculateDistanceAndDirection(gridCode: signalDict["gridCode"] as? String)
        
        let displayMessage = SignalMessage(
            type: type,
            deviceName: deviceName,
            distance: distance,
            direction: direction,
            timestamp: Date(timeIntervalSince1970: timestamp),
            gridCode: signalDict["gridCode"] as? String
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            
            // 限制訊息數量
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("📡 SignalViewModel: 接收到明文緊急訊號 - \(type.rawValue) 來自 \(deviceName)")
    }
    
    /// 處理解密成功的 Signal 訊息
    private func processDecryptedSignal(_ originalSignal: [String: Any]?, senderID: String, timestamp: TimeInterval) async {
        guard let signal = originalSignal,
              let typeString = signal["type"] as? String,
              let type = SignalType(rawValue: typeString),
              let realDeviceName = signal["deviceName"] as? String else {
            print("❌ SignalViewModel: 解密後的訊息格式無效")
            return
        }
        
        // 計算距離和方向
        let (distance, direction) = calculateDistanceAndDirection(gridCode: signal["gridCode"] as? String)
        
        let displayMessage = SignalMessage(
            type: type,
            deviceName: realDeviceName, // 顯示真實暱稱
            distance: distance,
            direction: direction,
            timestamp: Date(timeIntervalSince1970: timestamp),
            gridCode: signal["gridCode"] as? String
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            
            // 限制訊息數量
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("🔓 SignalViewModel: 成功解密緊急訊號 - \(type.rawValue) 來自 \(realDeviceName)")
    }
    
    /// 顯示匿名版本的 Signal 訊息
    func showAnonymousSignal(senderID: String, timestamp: TimeInterval) async {
        // 當無法解密時，顯示通用的緊急訊號
        let displayMessage = SignalMessage(
            type: .safe, // 默認顯示為安全訊號
            deviceName: "\(senderID) (加密)", // 顯示匿名ID並標註加密
            distance: nil,
            direction: nil,
            timestamp: Date(timeIntervalSince1970: timestamp),
            gridCode: nil
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            
            // 限制訊息數量
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("🔒 SignalViewModel: 顯示匿名緊急訊號來自 \(senderID)")
    }
    
    /// 計算距離和方向（使用網格系統）
    private func calculateDistanceAndDirection(gridCode: String?) -> (Double?, CompassDirection?) {
        guard let peerGridCode = gridCode,
              let currentLoc = currentLocation else {
            return (nil, nil)
        }
        
        let currentGrid = coordinateToGrid(currentLoc.coordinate)
        let (distance, direction) = calculateRelativePosition(
            from: currentGrid,
            to: peerGridCode
        )
        
        return (distance, direction)
    }
    
    /// 統一的距離格式化（本地實現）
    func formatDistance(_ meters: Double) -> String {
        switch meters {
        case 0..<50:
            return "< 50m"
        case 50..<100:
            return "約 \(Int(meters/10)*10)m"
        case 100..<500:
            return "約 \(Int(meters/50)*50)m"
        case 500..<1000:
            return "約 \(Int(meters/100)*100)m"
        case 1000..<5000:
            let km = meters / 1000
            return "約 \(String(format: "%.1f", km)) 公里"
        default:
            let km = Int(meters / 1000)
            return "約 \(km) 公里"
        }
    }
    
    /// 生成訊號訊息
    func generateSignalMessage(for type: SignalType) -> String {
        switch type {
        case .safe:
            return "我在這裡，狀況安全"
        case .supplies:
            return "需要物資支援！"
        case .medical:
            return "需要醫療支援！"
        case .danger:
            return "危險警告！請遠離此區域"
        }
    }
    
    // MARK: - 本地網格系統實現（避免循環依賴）
    
    
    func calculateRelativePosition(from myGrid: String, to peerGrid: String) -> (distance: Double, direction: CompassDirection?) {
        guard let myLetter = myGrid.first,
              let myNumber = Int(myGrid.dropFirst()),
              let peerLetter = peerGrid.first,
              let peerNumber = Int(peerGrid.dropFirst()) else {
            return (0, nil)
        }
        
        let xDiff = Int(peerLetter.asciiValue!) - Int(myLetter.asciiValue!)
        let yDiff = peerNumber - myNumber
        
        let gridDistance = sqrt(Double(xDiff * xDiff + yDiff * yDiff))
        let estimatedDistance = gridDistance * 500 // 米
        
        let angle = atan2(Double(xDiff), Double(yDiff)) * 180 / .pi
        let normalizedAngle = angle < 0 ? angle + 360 : angle
        let direction = bearingToCompassDirection(normalizedAngle)
        
        return (estimatedDistance, direction)
    }
    
    private func bearingToCompassDirection(_ bearing: Double) -> CompassDirection {
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360)
        
        switch normalizedBearing {
        case 337.5...360, 0..<22.5: return .north
        case 22.5..<67.5: return .northeast
        case 67.5..<112.5: return .east
        case 112.5..<157.5: return .southeast
        case 157.5..<202.5: return .south
        case 202.5..<247.5: return .southwest
        case 247.5..<292.5: return .west
        case 292.5..<337.5: return .northwest
        default: return .north
        }
    }
    
    // MARK: - 測試和開發方法 (DEBUG only)
    
    #if DEBUG
    /// 添加測試數據（僅開發模式）
    func addTestData() {
        let testMessages = [
            SignalMessage(
                type: .safe,
                deviceName: "測試設備 A",
                distance: 150.0,
                direction: .northeast, // 45度 -> 東北
                timestamp: Date().addingTimeInterval(-300), // 5分鐘前
                gridCode: "GRID_001"
            ),
            SignalMessage(
                type: .medical,
                deviceName: "救護站",
                distance: 320.0,
                direction: .south, // 180度 -> 南
                timestamp: Date().addingTimeInterval(-600), // 10分鐘前
                gridCode: "GRID_002"
            ),
            SignalMessage(
                type: .danger,
                deviceName: "警報設備",
                distance: 80.0,
                direction: .west, // 270度 -> 西
                timestamp: Date().addingTimeInterval(-120), // 2分鐘前
                gridCode: "GRID_003"
            ),
            SignalMessage(
                type: .supplies,
                deviceName: "補給站 B",
                distance: 500.0,
                direction: .east, // 90度 -> 東
                timestamp: Date().addingTimeInterval(-900), // 15分鐘前
                gridCode: "GRID_004"
            )
        ]
        
        DispatchQueue.main.async {
            self.messages = testMessages
            self.connectionStatus = "已連線"
            self.connectedPeers = ["測試設備 A", "救護站", "警報設備", "補給站 B"]
        }
        
        print("🧪 SignalViewModel: 已添加測試數據 (\(testMessages.count) 個訊息)")
    }
    
    /// 獲取系統狀態摘要（調試用）
    func getSystemStatusSummary() -> SystemStatusSummary {
        let securityEvents = getRecentSecurityEvents(limit: 10)
        let replayStats = getReplayProtectionStats()
        let deduplicationStats = getDeduplicationStats()
        
        return SystemStatusSummary(
            connectionStatus: connectionStatus,
            connectedPeersCount: connectedPeers.count,
            totalMessages: messages.count,
            recentSecurityEvents: securityEvents.count,
            criticalSecurityEvents: securityEvents.filter { $0.severity == .critical }.count,
            replayProtectionCacheCount: replayStats.count,
            deduplicationCacheCount: deduplicationStats.count,
            deduplicationUtilization: deduplicationStats.utilizationRate
        )
    }
    
    /// 模擬安全事件（測試用）
    func simulateSecurityEvent(type: SecurityEventType, severity: SecurityEvent.SecuritySeverity) {
        securityLogger.logEvent(
            type,
            peerID: "TEST_DEVICE",
            details: "模擬的安全事件用於測試",
            severity: severity
        )
        print("🧪 模擬安全事件: \(type) (\(severity))")
    }
    
    /// 測試訊息去重功能
    func testMessageDeduplication() {
        let testMessage = "TEST_MESSAGE_\(Date().timeIntervalSince1970)".data(using: .utf8)!
        let messageID = UUID().uuidString
        let senderID = "TEST_SENDER"
        let timestamp = Date()
        
        do {
            // 第一次檢查（應該不重複）
            let isDuplicate1 = try messageDeduplicator.isDuplicate(
                messageID: messageID,
                senderID: senderID,
                timestamp: timestamp,
                content: testMessage
            )
            
            // 第二次檢查（應該重複）
            let isDuplicate2 = try messageDeduplicator.isDuplicate(
                messageID: messageID,
                senderID: senderID,
                timestamp: timestamp,
                content: testMessage
            )
            
            print("🧪 訊息去重測試:")
            print("   第一次檢查: \(isDuplicate1 ? "重複" : "新訊息")")
            print("   第二次檢查: \(isDuplicate2 ? "重複" : "新訊息")")
            print("   結果: \(isDuplicate1 == false && isDuplicate2 == true ? "✅ 通過" : "❌ 失敗")")
            
            // 測試速率限制統計
            let rateLimitStats = messageDeduplicator.getRateLimitStats()
            print("   速率限制統計: \(rateLimitStats.summary)")
            
        } catch {
            print("❌ 訊息去重測試失敗: \(error.localizedDescription)")
            
            // 使用安全版本重試
            let safeResult1 = messageDeduplicator.isDuplicateSafe(
                messageID: messageID,
                senderID: senderID,
                timestamp: timestamp,
                content: testMessage
            )
            
            if let error = safeResult1.error {
                print("   安全模式錯誤: \(error.localizedDescription)")
            } else {
                print("   安全模式結果: \(safeResult1.isDuplicate ? "重複" : "新訊息")")
            }
        }
    }
    #endif
}

// MARK: - 預覽支援
extension SignalViewModel {
    static func preview() -> SignalViewModel {
        let viewModel = SignalViewModel()
        
        // 添加一些有距離和方位的範例訊息
        viewModel.messages = [
            SignalMessage(
                type: .safe,
                deviceName: "救援隊-Alpha",
                distance: 150.0,
                direction: .north,
                timestamp: Date().addingTimeInterval(-300),
                gridCode: "A6"
            ),
            SignalMessage(
                type: .medical,
                deviceName: "醫療站-1",
                distance: 450.0,
                direction: .northeast,
                timestamp: Date().addingTimeInterval(-600),
                gridCode: "B7"
            ),
            SignalMessage(
                type: .supplies,
                deviceName: "補給點-Central",
                distance: 750.0,
                direction: .east,
                timestamp: Date().addingTimeInterval(-900),
                gridCode: "C5"
            ),
            SignalMessage(
                type: .danger,
                deviceName: "警戒區域",
                distance: 1200.0,
                direction: .south,
                timestamp: Date().addingTimeInterval(-1200),
                gridCode: "A3"
            ),
            SignalMessage(
                type: .safe,
                deviceName: "避難所-Beta",
                distance: 2500.0,
                direction: .southwest,
                timestamp: Date().addingTimeInterval(-1500),
                gridCode: "Z2"
            )
        ]
        
        viewModel.connectionStatus = "已連線"
        viewModel.connectedPeers = ["裝置1", "裝置2", "裝置3"]
        
        return viewModel
    }
}

// MARK: - 測試數據結構

#if DEBUG
struct SystemStatusSummary {
    let connectionStatus: String
    let connectedPeersCount: Int
    let totalMessages: Int
    let recentSecurityEvents: Int
    let criticalSecurityEvents: Int
    let replayProtectionCacheCount: Int
    let deduplicationCacheCount: Int
    let deduplicationUtilization: Double
    
    var formattedSummary: String {
        return """
        📊 系統狀態摘要
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🔗 連線狀態: \(connectionStatus)
        👥 連接設備: \(connectedPeersCount) 個
        📨 訊息總數: \(totalMessages) 個
        🛡️ 安全事件: \(recentSecurityEvents) 個 (嚴重: \(criticalSecurityEvents))
        🔄 重放保護: \(replayProtectionCacheCount) 個記錄
        🔁 去重快取: \(deduplicationCacheCount) 個記錄 (\(String(format: "%.1f", deduplicationUtilization * 100))%)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """
    }
}
#endif
