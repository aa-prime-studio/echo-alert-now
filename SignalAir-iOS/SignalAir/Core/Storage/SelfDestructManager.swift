import Foundation
import Observation

@Observable
class SelfDestructManager {
    // 訊息生命週期設定
    private let messageLifetime: TimeInterval = 86400  // 24小時
    private let cleanupInterval: TimeInterval = 3600   // 1小時檢查一次
    
    // 訊息追蹤
    private var messageTimestamps: [String: Date] = [:]
    private var messageMetadata: [String: MessageMetadata] = [:]
    
    // 統計資訊
    @Published private(set) var totalTrackedMessages: Int = 0
    @Published private(set) var expiredMessages: Int = 0
    @Published private(set) var lastCleanupTime: Date = Date()
    
    // Timer 管理
    private var cleanupTimer: Timer?
    private var isActive: Bool = true
    
    // UserDefaults 鍵值
    private let timestampsKey = "SignalAir_MessageTimestamps"
    private let metadataKey = "SignalAir_MessageMetadata"
    private let statsKey = "SignalAir_SelfDestructStats"
    
    init() {
        loadStoredData()
        startCleanupTimer()
        setupBackgroundNotifications()
        performInitialCleanup()
    }
    
    deinit {
        stopCleanupTimer()
        removeBackgroundNotifications()
        saveToStorage()
        print("🧹 SelfDestructManager: deinit 完成，Timer已清理")
    }
    
    // MARK: - 公開方法
    
    /// 追蹤新訊息
    func trackMessage(_ messageID: String, type: MessageType = .chat, priority: MessagePriority = .normal) {
        let now = Date()
        messageTimestamps[messageID] = now
        messageMetadata[messageID] = MessageMetadata(
            id: messageID,
            type: type,
            priority: priority,
            createdAt: now,
            isExpired: false
        )
        
        totalTrackedMessages += 1
        saveToStorage()
        
        print("🗑️ SelfDestructManager: 追蹤訊息 \(messageID) (類型: \(type))")
    }
    
    /// 手動刪除訊息
    func removeMessage(_ messageID: String) {
        messageTimestamps.removeValue(forKey: messageID)
        messageMetadata.removeValue(forKey: messageID)
        saveToStorage()
        
        print("🗑️ SelfDestructManager: 手動移除訊息 \(messageID)")
    }
    
    /// 檢查訊息是否已過期
    func isMessageExpired(_ messageID: String) -> Bool {
        guard let timestamp = messageTimestamps[messageID] else { return true }
        return Date().timeIntervalSince(timestamp) > messageLifetime
    }
    
    /// 取得訊息剩餘時間
    func getTimeRemaining(for messageID: String) -> TimeInterval {
        guard let timestamp = messageTimestamps[messageID] else { return 0 }
        let elapsed = Date().timeIntervalSince(timestamp)
        return max(0, messageLifetime - elapsed)
    }
    
    /// 取得所有追蹤的訊息
    func getTrackedMessages() -> [MessageMetadata] {
        return Array(messageMetadata.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 取得統計資訊
    func getStatistics() -> SelfDestructStats {
        let activeMessages = messageTimestamps.count
        let expiringSoon = messageTimestamps.values.filter { timestamp in
            let remaining = messageLifetime - Date().timeIntervalSince(timestamp)
            return remaining > 0 && remaining < 3600 // 1小時內過期
        }.count
        
        return SelfDestructStats(
            totalTracked: totalTrackedMessages,
            currentActive: activeMessages,
            totalExpired: expiredMessages,
            expiringSoon: expiringSoon,
            lastCleanup: lastCleanupTime
        )
    }
    
    /// 手動執行清理
    func performManualCleanup() {
        print("🗑️ SelfDestructManager: 執行手動清理...")
        cleanupExpiredMessages()
    }
    
    // MARK: - 私有方法
    
    /// 載入儲存的資料
    private func loadStoredData() {
        // 載入訊息時間戳
        if let data = UserDefaults.standard.data(forKey: timestampsKey),
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: data) {
            messageTimestamps = timestamps
        }
        
        // 載入訊息元資料
        if let data = UserDefaults.standard.data(forKey: metadataKey),
           let metadata = try? JSONDecoder().decode([String: MessageMetadata].self, from: data) {
            messageMetadata = metadata
        }
        
        // 載入統計資料
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode(StoredStats.self, from: data) {
            totalTrackedMessages = stats.totalTracked
            expiredMessages = stats.totalExpired
            lastCleanupTime = stats.lastCleanup
        }
        
        print("🗑️ SelfDestructManager: 載入 \(messageTimestamps.count) 個追蹤訊息")
    }
    
    /// 儲存到持久儲存
    private func saveToStorage() {
        // 儲存訊息時間戳
        if let data = try? JSONEncoder().encode(messageTimestamps) {
            UserDefaults.standard.set(data, forKey: timestampsKey)
        }
        
        // 儲存訊息元資料
        if let data = try? JSONEncoder().encode(messageMetadata) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
        
        // 儲存統計資料
        let stats = StoredStats(
            totalTracked: totalTrackedMessages,
            totalExpired: expiredMessages,
            lastCleanup: lastCleanupTime
        )
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// 啟動清理定時器
    private func startCleanupTimer() {
        stopCleanupTimer()
        
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            self?.cleanupExpiredMessages()
        }
        
        print("🗑️ SelfDestructManager: 啟動清理定時器 (每 \(Int(cleanupInterval/3600)) 小時)")
    }
    
    /// 停止清理定時器
    private func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        print("🧹 SelfDestructManager: 清理定時器已停止")
    }
    
    /// 初始清理（App 啟動時）
    private func performInitialCleanup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.cleanupExpiredMessages()
        }
    }
    
    /// 清理過期訊息
    private func cleanupExpiredMessages() {
        guard isActive else { return }
        
        let now = Date()
        var expiredMessageIDs: [String] = []
        var expiredCount = 0
        
        // 找出過期訊息
        for (messageID, timestamp) in messageTimestamps {
            if now.timeIntervalSince(timestamp) > messageLifetime {
                expiredMessageIDs.append(messageID)
                expiredCount += 1
            }
        }
        
        // 移除過期訊息
        for messageID in expiredMessageIDs {
            messageTimestamps.removeValue(forKey: messageID)
            
            // 標記元資料為過期
            if var metadata = messageMetadata[messageID] {
                metadata.isExpired = true
                messageMetadata[messageID] = metadata
            }
            
            // 發送通知
            NotificationCenter.default.post(
                name: .messageExpired,
                object: nil,
                userInfo: [
                    "messageID": messageID,
                    "expiredAt": now,
                    "type": messageMetadata[messageID]?.type.rawValue ?? "unknown"
                ]
            )
        }
        
        // 更新統計
        if expiredCount > 0 {
            expiredMessages += expiredCount
            lastCleanupTime = now
            saveToStorage()
            
            print("🗑️ SelfDestructManager: 清理了 \(expiredCount) 個過期訊息")
        }
        
        // 清理過期的元資料（保留最近100個用於統計）
        cleanupOldMetadata()
    }
    
    /// 清理舊的元資料
    private func cleanupOldMetadata() {
        let maxMetadataEntries = 100
        
        if messageMetadata.count > maxMetadataEntries {
            let sortedMetadata = messageMetadata.values.sorted { $0.createdAt > $1.createdAt }
            let toKeep = Array(sortedMetadata.prefix(maxMetadataEntries))
            
            messageMetadata.removeAll()
            for metadata in toKeep {
                messageMetadata[metadata.id] = metadata
            }
            
            print("🗑️ SelfDestructManager: 清理舊元資料，保留最新 \(maxMetadataEntries) 筆")
        }
    }
    
    /// 設定背景通知
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    /// 移除背景通知
    private func removeBackgroundNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationWillEnterForeground() {
        isActive = true
        startCleanupTimer()
        
        // App 回到前景時執行清理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.cleanupExpiredMessages()
        }
        
        print("🗑️ SelfDestructManager: App 進入前景，重新啟動清理")
    }
    
    @objc private func applicationDidEnterBackground() {
        isActive = false
        stopCleanupTimer()
        saveToStorage()
        
        print("🗑️ SelfDestructManager: App 進入背景，暫停清理")
    }
}

// MARK: - 支援結構

enum MessageType: String, Codable {
    case chat = "chat"
    case signal = "signal"
    case game = "game"
    case system = "system"
}

enum MessagePriority: Int, Codable {
    case emergency = 3
    case normal = 2
    case game = 1
}

struct MessageMetadata: Codable {
    let id: String
    let type: MessageType
    let priority: MessagePriority
    let createdAt: Date
    var isExpired: Bool
    
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(createdAt)
        return max(0, 86400 - elapsed) // 24小時
    }
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)小時\(minutes)分"
    }
}

struct SelfDestructStats {
    let totalTracked: Int
    let currentActive: Int
    let totalExpired: Int
    let expiringSoon: Int
    let lastCleanup: Date
    
    var formattedLastCleanup: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: lastCleanup)
    }
}

private struct StoredStats: Codable {
    let totalTracked: Int
    let totalExpired: Int
    let lastCleanup: Date
}

// MARK: - 通知擴展

extension Notification.Name {
    static let messageExpired = Notification.Name("SignalAir.messageExpired")
    static let cleanupCompleted = Notification.Name("SignalAir.cleanupCompleted")
}

// MARK: - 延展功能

extension SelfDestructManager {
    /// 批量追蹤多個訊息
    func trackMessages(_ messageIDs: [String], type: MessageType = .chat) {
        for messageID in messageIDs {
            trackMessage(messageID, type: type)
        }
        print("🗑️ SelfDestructManager: 批量追蹤 \(messageIDs.count) 個訊息")
    }
    
    /// 取得即將過期的訊息
    func getExpiringSoonMessages(within hours: Int = 1) -> [MessageMetadata] {
        let threshold: TimeInterval = TimeInterval(hours * 3600)
        
        return messageMetadata.values.filter { metadata in
            let remaining = metadata.timeRemaining
            return remaining > 0 && remaining <= threshold && !metadata.isExpired
        }.sorted { $0.timeRemaining < $1.timeRemaining }
    }
    
    /// 延長訊息生命週期（緊急情況使用）
    func extendMessageLifetime(_ messageID: String, additionalHours: Int) {
        guard let currentTimestamp = messageTimestamps[messageID] else { return }
        let newTimestamp = currentTimestamp.addingTimeInterval(-TimeInterval(additionalHours * 3600))
        messageTimestamps[messageID] = newTimestamp
        saveToStorage()
        
        print("🗑️ SelfDestructManager: 延長訊息 \(messageID) 生命週期 \(additionalHours) 小時")
    }
} 