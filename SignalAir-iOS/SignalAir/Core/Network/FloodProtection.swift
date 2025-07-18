import Foundation

// MARK: - Flood Protection Configuration
struct FloodProtectionConfig {
    let maxMessagesPerSecond: Int
    let maxMessagesPerMinute: Int
    let maxBurstSize: Int
    let banDuration: TimeInterval
    let windowSize: TimeInterval
    
    static let `default` = FloodProtectionConfig(
        maxMessagesPerSecond: 10,
        maxMessagesPerMinute: 100,
        maxBurstSize: 20,
        banDuration: 300, // 5 minutes
        windowSize: 60 // 1 minute
    )
}

// MARK: - Message Rate Tracker
class MessageRateTracker {
    private var messageTimestamps: [Date] = []
    private let lock = NSLock()
    
    func addMessage(at timestamp: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        
        messageTimestamps.append(timestamp)
    }
    
    func getMessageCount(in interval: TimeInterval) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoff = Date().addingTimeInterval(-interval)
        messageTimestamps.removeAll { $0 < cutoff }
        return messageTimestamps.count
    }
    
    func getRecentMessageCount(seconds: TimeInterval) -> Int {
        return getMessageCount(in: seconds)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        messageTimestamps.removeAll()
    }
}

// MARK: - Peer Ban Manager
class PeerBanManager {
    private var bannedPeers: [String: Date] = [:]
    private var banHistory: [String: Int] = [:] // 记录每个节点的封禁次数
    private let lock = NSLock()
    
    // 封禁时长配置
    private let firstBanDuration: TimeInterval = 7200   // 2小时 (第一次封禁)
    private let finalBanDuration: TimeInterval = 432000 // 5天 (第三次封禁)
    private let maxBanCount = 3 // 最大封禁次数
    
    func banPeer(_ peerID: String, duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        let banUntil = Date().addingTimeInterval(duration)
        bannedPeers[peerID] = banUntil
        
        print("🚫 Banned peer \(peerID) until \(banUntil)")
    }
    
    /// 阶梯式封禁节点（基于可疑内容）
    func banPeerForSuspiciousContent(_ peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        // 增加封禁计数
        let currentBanCount = banHistory[peerID, default: 0] + 1
        banHistory[peerID] = currentBanCount
        
        let banDuration: TimeInterval
        let banReason: String
        
        switch currentBanCount {
        case 1:
            banDuration = firstBanDuration // 2小时
            banReason = "第1次可疑内容封禁"
        case 2:
            banDuration = firstBanDuration // 2小时
            banReason = "第2次可疑内容封禁"
        case maxBanCount:
            banDuration = finalBanDuration // 5天
            banReason = "第3次可疑内容封禁（最终封禁）"
        default:
            banDuration = finalBanDuration // 5天 (超过3次继续5天封禁)
            banReason = "多次可疑内容封禁（永久级别）"
        }
        
        let banUntil = Date().addingTimeInterval(banDuration)
        bannedPeers[peerID] = banUntil
        
        let durationText = formatBanDuration(banDuration)
        print("🚨 \(banReason): 封禁节点 \(peerID) \(durationText)，到期时间: \(banUntil)")
        print("📊 节点 \(peerID) 累计封禁次数: \(currentBanCount)/\(maxBanCount)")
    }
    
    /// 格式化封禁时长显示
    private func formatBanDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days)天"
        } else {
            return "\(hours)小时"
        }
    }
    
    func isBanned(_ peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let banUntil = bannedPeers[peerID] else {
            return false
        }
        
        if Date() > banUntil {
            // Ban expired
            bannedPeers.removeValue(forKey: peerID)
            print("✅ 节点 \(peerID) 封禁已到期")
            return false
        }
        
        return true
    }
    
    func unbanPeer(_ peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        bannedPeers.removeValue(forKey: peerID)
        print("✅ 手动解封节点: \(peerID)")
    }
    
    /// 重置节点的封禁历史（管理员功能）
    func resetBanHistory(for peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let oldCount = banHistory[peerID, default: 0]
        banHistory.removeValue(forKey: peerID)
        print("🔄 重置节点 \(peerID) 的封禁历史 (之前: \(oldCount)次)")
    }
    
    /// 获取节点的封禁历史
    func getBanHistory(for peerID: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return banHistory[peerID, default: 0]
    }
    
    /// 获取所有节点的封禁历史
    func getAllBanHistory() -> [String: Int] {
        lock.lock()
        defer { lock.unlock() }
        
        return banHistory
    }
    
    func getBannedPeers() -> [String: Date] {
        lock.lock()
        defer { lock.unlock() }
        
        // Clean expired bans
        let now = Date()
        bannedPeers = bannedPeers.filter { $0.value > now }
        
        return bannedPeers
    }
    
    func clearAllBans() {
        lock.lock()
        defer { lock.unlock() }
        
        bannedPeers.removeAll()
        print("🧹 清除所有节点封禁")
    }
    
    /// 清除所有封禁历史（管理员功能）
    func clearAllBanHistory() {
        lock.lock()
        defer { lock.unlock() }
        
        let clearedCount = banHistory.count
        banHistory.removeAll()
        print("🧹 清除所有封禁历史，共清除 \(clearedCount) 个节点的记录")
    }
    
    /// 获取封禁统计信息
    func getBanStatistics() -> BanStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        let currentlyBanned = bannedPeers.count
        let totalWithHistory = banHistory.count
        let firstTimeBanned = banHistory.values.filter { $0 == 1 }.count
        let secondTimeBanned = banHistory.values.filter { $0 == 2 }.count
        let finallyBanned = banHistory.values.filter { $0 >= 3 }.count
        
        return BanStatistics(
            currentlyBanned: currentlyBanned,
            totalWithHistory: totalWithHistory,
            firstTimeBanned: firstTimeBanned,
            secondTimeBanned: secondTimeBanned,
            finallyBanned: finallyBanned
        )
    }
}

// MARK: - Ban Statistics
struct BanStatistics {
    let currentlyBanned: Int      // 当前被封禁的节点数
    let totalWithHistory: Int     // 有封禁历史的节点总数
    let firstTimeBanned: Int      // 第一次被封禁的节点数
    let secondTimeBanned: Int     // 第二次被封禁的节点数
    let finallyBanned: Int        // 第三次及以上被封禁的节点数
}

// MARK: - Message Type Rate Limiter
class MessageTypeRateLimiter {
    private var rateLimiters: [MeshMessageType: MessageRateTracker] = [:]
    private let lock = NSLock()
    
    private let typeLimits: [MeshMessageType: (perSecond: Int, perMinute: Int)] = [
        .signal: (5, 30),
        .chat: (10, 100),
        .game: (15, 150),
        .heartbeat: (1, 10),
        .routingUpdate: (2, 20),
        .keyExchange: (1, 5),
        .system: (3, 30)
    ]
    
    func canSendMessage(type: MeshMessageType, from peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let key = "\(peerID)_\(type.rawValue)"
        let tracker = rateLimiters[type] ?? MessageRateTracker()
        rateLimiters[type] = tracker
        
        guard let limits = typeLimits[type] else {
            return true // No limits defined
        }
        
        let messagesPerSecond = tracker.getRecentMessageCount(seconds: 1)
        let messagesPerMinute = tracker.getRecentMessageCount(seconds: 60)
        
        if messagesPerSecond >= limits.perSecond {
            print("⚠️ Rate limit exceeded for \(type.rawValue) from \(peerID): \(messagesPerSecond)/s")
            return false
        }
        
        if messagesPerMinute >= limits.perMinute {
            print("⚠️ Rate limit exceeded for \(type.rawValue) from \(peerID): \(messagesPerMinute)/min")
            return false
        }
        
        tracker.addMessage()
        return true
    }
    
    func resetPeerLimits(for peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        for (type, tracker) in rateLimiters {
            tracker.clear()
        }
        
        print("🔄 Reset rate limits for peer \(peerID)")
    }
}

// MARK: - Content Pattern Detector
class ContentPatternDetector {
    private var recentHashes: Set<Int> = []
    private var hashCounts: [Int: Int] = [:]
    private var peerSuspiciousActivity: [String: [Int: Int]] = [:] // 按节点跟踪可疑内容
    private let lock = NSLock()
    private let maxRecentHashes = 1000
    private let suspiciousThreshold = 5 // 同一内容出现5次以上
    
    /// 检查可疑内容并返回是否应该封禁该节点
    func checkSuspiciousContent(_ data: Data, from peerID: String) -> (isSuspicious: Bool, shouldBan: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        let hash = data.hashValue
        
        // 更新全局哈希计数
        hashCounts[hash, default: 0] += 1
        recentHashes.insert(hash)
        
        // 更新该节点的可疑活动记录
        if peerSuspiciousActivity[peerID] == nil {
            peerSuspiciousActivity[peerID] = [:]
        }
        peerSuspiciousActivity[peerID]![hash, default: 0] += 1
        
        // 限制内存使用
        if recentHashes.count > maxRecentHashes {
            let oldHashes = Array(recentHashes.prefix(maxRecentHashes / 2))
            for oldHash in oldHashes {
                recentHashes.remove(oldHash)
                hashCounts.removeValue(forKey: oldHash)
                
                // 同时清理节点的可疑活动记录
                for peerID in peerSuspiciousActivity.keys {
                    peerSuspiciousActivity[peerID]?.removeValue(forKey: oldHash)
                }
            }
        }
        
        // 检查是否达到可疑阈值
        let globalCount = hashCounts[hash] ?? 0
        let peerCount = peerSuspiciousActivity[peerID]?[hash] ?? 0
        
        if globalCount >= suspiciousThreshold {
            print("🚨 可疑重复内容检测: hash \(hash)")
            print("   - 全局出现次数: \(globalCount)")
            print("   - 节点 \(peerID) 发送次数: \(peerCount)")
            
            // 如果该节点发送了这个可疑内容，则应该封禁
            if peerCount > 0 {
                print("🔨 节点 \(peerID) 发送可疑重复内容，触发封禁机制")
                return (isSuspicious: true, shouldBan: true)
            } else {
                // 其他节点发送的可疑内容，当前节点不封禁
                return (isSuspicious: true, shouldBan: false)
            }
        }
        
        return (isSuspicious: false, shouldBan: false)
    }
    
    /// 获取节点的可疑活动统计
    func getSuspiciousActivityStats(for peerID: String) -> SuspiciousActivityStats {
        lock.lock()
        defer { lock.unlock() }
        
        guard let activity = peerSuspiciousActivity[peerID] else {
            return SuspiciousActivityStats(totalSuspiciousMessages: 0, uniqueSuspiciousHashes: 0, mostFrequentCount: 0)
        }
        
        let totalMessages = activity.values.reduce(0, +)
        let uniqueHashes = activity.count
        let mostFrequent = activity.values.max() ?? 0
        
        return SuspiciousActivityStats(
            totalSuspiciousMessages: totalMessages,
            uniqueSuspiciousHashes: uniqueHashes,
            mostFrequentCount: mostFrequent
        )
    }
    
    /// 清理节点的可疑活动记录
    func clearSuspiciousActivity(for peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let clearedCount = peerSuspiciousActivity[peerID]?.count ?? 0
        peerSuspiciousActivity.removeValue(forKey: peerID)
        print("🧹 清理节点 \(peerID) 的可疑活动记录，共 \(clearedCount) 项")
    }
    
    func clearPatterns() {
        lock.lock()
        defer { lock.unlock() }
        
        recentHashes.removeAll()
        hashCounts.removeAll()
        peerSuspiciousActivity.removeAll()
        print("🧹 清除所有内容模式检测数据")
    }
}

// MARK: - Suspicious Activity Statistics
struct SuspiciousActivityStats {
    let totalSuspiciousMessages: Int    // 总可疑消息数
    let uniqueSuspiciousHashes: Int     // 独特可疑内容哈希数
    let mostFrequentCount: Int          // 最频繁内容的出现次数
}

// MARK: - Flood Protection Main Class
@Observable
// MARK: - FloodProtectionProtocol
protocol FloodProtectionProtocol {
    func shouldBlock(_ message: MeshMessage, from peerID: String) -> Bool
}

class FloodProtection: FloodProtectionProtocol {
    // MARK: - Properties
    private let config: FloodProtectionConfig
    private var peerRateTrackers: [String: MessageRateTracker] = [:]
    private let banManager = PeerBanManager()
    private let typeRateLimiter = MessageTypeRateLimiter()
    private let contentDetector = ContentPatternDetector()
    private let lock = NSLock()
    
    // MARK: - Published State
    @Published var blockedMessagesCount: Int = 0
    @Published var bannedPeersCount: Int = 0
    @Published var isActive: Bool = true
    
    // MARK: - Statistics
    private var stats = FloodProtectionStats()
    
    // MARK: - Initialization
    init(config: FloodProtectionConfig = .default) {
        self.config = config
        startCleanupTimer()
        print("🛡️ FloodProtection initialized with config: \(config)")
    }
    
    // MARK: - Public Methods
    
    /// 檢查是否應該阻止訊息
    func shouldBlock(_ message: MeshMessage, from peerID: String) -> Bool {
        guard isActive else { return false }
        
        // 1. 檢查是否被禁止
        if banManager.isBanned(peerID) {
            incrementBlockedCount()
            stats.blockedByBan += 1
            print("🚫 Blocked message from banned peer: \(peerID)")
            
            // 記錄到安全日誌
            logSecurityEvent(
                eventType: "banned_peer_message_blocked",
                severity: .warning,
                details: "已封禁節點嘗試發送訊息 - PeerID: \(peerID)"
            )
            
            return true
        }
        
        // 2. 檢查訊息類型速率限制
        if !typeRateLimiter.canSendMessage(type: message.type, from: peerID) {
            incrementBlockedCount()
            stats.blockedByTypeLimit += 1
            
            // 記錄到安全日誌
            logSecurityEvent(
                eventType: "message_type_rate_limit_exceeded",
                severity: .warning,
                details: "訊息類型速率限制超出 - PeerID: \(peerID), 類型: \(message.type.rawValue)"
            )
            
            // 多次違反可能導致臨時禁止
            if shouldTemporarilyBan(peerID) {
                banManager.banPeer(peerID, duration: config.banDuration / 2) // 較短的禁止時間
                
                // 記錄臨時封禁
                logSecurityEvent(
                    eventType: "temporary_ban_applied",
                    severity: .error,
                    details: "臨時封禁節點 - PeerID: \(peerID), 原因: 訊息類型速率超限"
                )
            }
            
            return true
        }
        
        // 3. 檢查整體速率限制
        if !checkOverallRateLimit(for: peerID) {
            incrementBlockedCount()
            stats.blockedByRateLimit += 1
            
            // 記錄到安全日誌
            logSecurityEvent(
                eventType: "flood_protection_triggered",
                severity: .error,
                details: "洪水攻擊防護觸發 - PeerID: \(peerID), 訊息速率超限"
            )
            
            // 嚴重超速可能導致禁止
            if shouldBanPeer(peerID) {
                banManager.banPeer(peerID, duration: config.banDuration)
                
                // 記錄封禁事件
                logSecurityEvent(
                    eventType: "peer_banned",
                    severity: .critical,
                    details: "封禁節點 - PeerID: \(peerID), 原因: 嚴重洪水攻擊, 時長: \(config.banDuration)秒"
                )
            }
            
            return true
        }
        
        // 4. 檢查內容模式
        let contentCheck = contentDetector.checkSuspiciousContent(message.data, from: peerID)
        if contentCheck.isSuspicious {
            incrementBlockedCount()
            stats.blockedByPattern += 1
            
            // 記錄到安全日誌
            logSecurityEvent(
                eventType: "suspicious_content_detected",
                severity: .warning,
                details: "可疑重複內容檢測 - PeerID: \(peerID)"
            )
            
            // 如果需要封禁该节点，执行阶梯式封禁
            if contentCheck.shouldBan {
                banManager.banPeerForSuspiciousContent(peerID)
                updateBannedPeersCount()
                print("🚫 封禁可疑内容发送者: \(peerID)")
                
                // 記錄階梯式封禁
                logSecurityEvent(
                    eventType: "tiered_ban_applied",
                    severity: .critical,
                    details: "階梯式封禁節點 - PeerID: \(peerID), 原因: 可疑重複內容"
                )
            }
            
            print("🚫 阻止可疑内容来自: \(peerID)")
            return true
        }
        
        // 5. 檢查訊息大小
        if message.data.count > 1024 * 1024 { // 1MB limit
            incrementBlockedCount()
            stats.blockedBySize += 1
            print("🚫 Blocked oversized message from: \(peerID)")
            
            // 記錄到安全日誌
            logSecurityEvent(
                eventType: "oversized_message_blocked",
                severity: .warning,
                details: "超大訊息被阻止 - PeerID: \(peerID), 大小: \(message.data.count) bytes"
            )
            
            return true
        }
        
        // 記錄合法訊息
        recordMessage(from: peerID)
        stats.allowedMessages += 1
        
        return false
    }
    
    /// 檢查是否應該接受訊息（兼容方法）
    func shouldAcceptMessage(from deviceID: String, content: Data, size: Int, priority: MessagePriority) -> Bool {
        // 緊急訊息傷有更寬鬆的限制
        if priority == .emergency {
            // 只檢查是否被禁止，不檢查速率限制
            if banManager.isBanned(deviceID) {
                print("🚫 Emergency message blocked from banned peer: \(deviceID)")
                return false
            }
            
            // 檢查訊息大小（緊急訊息允許更大）
            if size > 2 * 1024 * 1024 { // 2MB 限制緊急訊息
                print("🚫 Emergency message too large from: \(deviceID)")
                return false
            }
            
            return true
        }
        
        // 非緊急訊息使用標準檢查
        // 創建一個臨時的 MeshMessage 物件來使用現有的 shouldBlock 方法
        let messageType: MeshMessageType = priority == .emergency ? .emergencyDanger : .signal
        let tempMessage = MeshMessage(
            type: messageType,
            sourceID: deviceID,
            targetID: nil,
            data: content
        )
        
        return !shouldBlock(tempMessage, from: deviceID)
    }
    
    /// 手動禁止 peer
    func banPeer(_ peerID: String, duration: TimeInterval? = nil) {
        let banDuration = duration ?? config.banDuration
        banManager.banPeer(peerID, duration: banDuration)
        updateBannedPeersCount()
    }
    
    /// 解除 peer 禁止
    func unbanPeer(_ peerID: String) {
        banManager.unbanPeer(peerID)
        updateBannedPeersCount()
    }
    
    /// 檢查 peer 是否被禁止
    func isPeerBanned(_ peerID: String) -> Bool {
        return banManager.isBanned(peerID)
    }
    
    /// 取得被禁止的 peers
    func getBannedPeers() -> [String: Date] {
        return banManager.getBannedPeers()
    }
    
    /// 清除所有禁止
    func clearAllBans() {
        banManager.clearAllBans()
        updateBannedPeersCount()
    }
    
    /// 重置統計
    func resetStats() {
        stats = FloodProtectionStats()
        DispatchQueue.main.async {
            self.blockedMessagesCount = 0
        }
    }
    
    /// 取得統計信息
    func getStats() -> FloodProtectionStats {
        return stats
    }
    
    /// 啟用/停用保護
    func setActive(_ active: Bool) {
        isActive = active
        print("🛡️ FloodProtection \(active ? "enabled" : "disabled")")
    }
    
    // MARK: - 新增的封禁管理方法
    
    /// 获取节点的封禁历史次数
    func getBanHistory(for peerID: String) -> Int {
        return banManager.getBanHistory(for: peerID)
    }
    
    /// 获取所有节点的封禁历史
    func getAllBanHistory() -> [String: Int] {
        return banManager.getAllBanHistory()
    }
    
    /// 重置节点的封禁历史（管理员功能）
    func resetBanHistory(for peerID: String) {
        banManager.resetBanHistory(for: peerID)
    }
    
    /// 清除所有封禁历史（管理员功能）
    func clearAllBanHistory() {
        banManager.clearAllBanHistory()
    }
    
    /// 获取封禁统计信息
    func getBanStatistics() -> BanStatistics {
        return banManager.getBanStatistics()
    }
    
    /// 获取节点的可疑活动统计
    func getSuspiciousActivityStats(for peerID: String) -> SuspiciousActivityStats {
        return contentDetector.getSuspiciousActivityStats(for: peerID)
    }
    
    /// 清理节点的可疑活动记录
    func clearSuspiciousActivity(for peerID: String) {
        contentDetector.clearSuspiciousActivity(for: peerID)
    }
    
    // MARK: - Private Methods
    
    /// 記錄安全事件到日誌
    private func logSecurityEvent(eventType: String, severity: SecurityLogSeverity, details: String) {
        // 使用通知機制記錄安全事件，避免循環依賴
        NotificationCenter.default.post(
            name: NSNotification.Name("SecurityEvent"),
            object: nil,
            userInfo: [
                "event": eventType,
                "source": "FloodProtection",
                "severity": severity.rawValue,
                "details": details
            ]
        )
    }
    
    private func recordMessage(from peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let tracker = peerRateTrackers[peerID] ?? MessageRateTracker()
        tracker.addMessage()
        peerRateTrackers[peerID] = tracker
    }
    
    private func checkOverallRateLimit(for peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let tracker = peerRateTrackers[peerID] else {
            return true // No history, allow
        }
        
        let messagesPerSecond = tracker.getRecentMessageCount(seconds: 1)
        let messagesPerMinute = tracker.getRecentMessageCount(seconds: 60)
        
        if messagesPerSecond > config.maxMessagesPerSecond {
            print("⚠️ Overall rate limit exceeded for \(peerID): \(messagesPerSecond)/s > \(config.maxMessagesPerSecond)")
            return false
        }
        
        if messagesPerMinute > config.maxMessagesPerMinute {
            print("⚠️ Overall rate limit exceeded for \(peerID): \(messagesPerMinute)/min > \(config.maxMessagesPerMinute)")
            return false
        }
        
        return true
    }
    
    private func shouldBanPeer(_ peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let tracker = peerRateTrackers[peerID] else {
            return false
        }
        
        let recentMessages = tracker.getRecentMessageCount(seconds: 10)
        return recentMessages > config.maxBurstSize * 2 // 嚴重超速閾值
    }
    
    private func shouldTemporarilyBan(_ peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let tracker = peerRateTrackers[peerID] else {
            return false
        }
        
        let recentMessages = tracker.getRecentMessageCount(seconds: 5)
        return recentMessages > config.maxBurstSize // 中等超速閾值
    }
    
    private func incrementBlockedCount() {
        DispatchQueue.main.async {
            self.blockedMessagesCount += 1
        }
    }
    
    private func updateBannedPeersCount() {
        DispatchQueue.main.async {
            self.bannedPeersCount = self.banManager.getBannedPeers().count
        }
    }
    
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.performCleanup()
        }
    }
    
    private func performCleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        // 清理過期的速率追蹤器
        for (peerID, tracker) in peerRateTrackers {
            if tracker.getRecentMessageCount(seconds: config.windowSize) == 0 {
                peerRateTrackers.removeValue(forKey: peerID)
            }
        }
        
        // 更新統計
        updateBannedPeersCount()
        
        print("🧹 FloodProtection cleanup completed")
    }
}

// MARK: - Flood Protection Statistics
struct FloodProtectionStats {
    var allowedMessages: Int = 0
    var blockedByBan: Int = 0
    var blockedByRateLimit: Int = 0
    var blockedByTypeLimit: Int = 0
    var blockedByPattern: Int = 0
    var blockedBySize: Int = 0
    
    var totalBlocked: Int {
        return blockedByBan + blockedByRateLimit + blockedByTypeLimit + blockedByPattern + blockedBySize
    }
    
    var totalProcessed: Int {
        return allowedMessages + totalBlocked
    }
    
    var blockingRate: Double {
        guard totalProcessed > 0 else { return 0 }
        return Double(totalBlocked) / Double(totalProcessed)
    }
} 