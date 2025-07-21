import Foundation

// MARK: - ⚠️ DEPRECATED ⚠️
// 此檔案已被 UnifiedTimerManager 取代
// 請使用 UnifiedTimerManager.shared 替代此實作
// 計劃移除日期: 下個主要版本

/// 🎯 集中式計時器管理器 - 解決記憶體洩漏和生命週期問題
@available(*, deprecated, message: "使用 UnifiedTimerManager.shared 替代")
@MainActor
class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    private var timers: [String: Timer] = [:]
    private let cleanupQueue = DispatchQueue(label: "com.signalair.timer.cleanup")
    
    private init() {
        print("⏰ TimerManager: 初始化完成")
    }
    
    /// 創建安全的計時器
    func createTimer(
        id: String,
        interval: TimeInterval,
        repeats: Bool,
        handler: @escaping () -> Void
    ) {
        // 先清除現有的同名計時器
        invalidateTimer(id: id)
        
        // 創建新計時器，使用 weak 引用
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { [weak self] timer in
            // 檢查 TimerManager 是否還存在
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // 檢查計時器是否仍在管理中
            guard self.timers[id] != nil else {
                timer.invalidate()
                return
            }
            
            // 執行回調
            handler()
        }
        
        // 儲存計時器引用
        timers[id] = timer
        print("⏰ TimerManager: 創建計時器 '\(id)', 間隔: \(interval)s, 重複: \(repeats)")
    }
    
    /// 安全地無效化計時器
    func invalidateTimer(id: String) {
        if let timer = timers[id] {
            timer.invalidate()
            timers.removeValue(forKey: id)
            print("⏰ TimerManager: 無效化計時器 '\(id)'")
        }
    }
    
    /// 無效化所有計時器
    func invalidateAll() {
        let timerCount = timers.count
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        print("⏰ TimerManager: 無效化所有計時器 (\(timerCount) 個)")
    }
    
    /// 檢查計時器是否存在
    func hasTimer(id: String) -> Bool {
        return timers[id] != nil
    }
    
    /// 獲取活躍計時器數量
    var activeTimerCount: Int {
        return timers.count
    }
    
    /// 獲取所有計時器 ID
    var activeTimerIDs: [String] {
        return Array(timers.keys)
    }
    
    deinit {
        // 同步清理所有計時器
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        print("⏰ TimerManager: deinit 清理完成")
    }
}

// MARK: - 計時器 ID 常數
extension TimerManager {
    enum TimerID {
        static let bingoDrawTimer = "bingo.draw"
        static let bingoCountdown = "bingo.countdown"
        static let bingoSync = "bingo.sync"
        static let bingoHeartbeat = "bingo.heartbeat"
        static let bingoReconnect = "bingo.reconnect"
        static let bingoHostPromotion = "bingo.hostPromotion"
        static let chatCleanup = "chat.cleanup"
        static let chatTyping = "chat.typing"
        static let chatStatus = "chat.status"
    }
}

// MARK: - 便利方法
extension TimerManager {
    /// 創建賓果遊戲相關計時器
    func createBingoTimer(type: String, interval: TimeInterval, repeats: Bool, handler: @escaping () -> Void) {
        let id = "bingo.\(type)"
        createTimer(id: id, interval: interval, repeats: repeats, handler: handler)
    }
    
    /// 清理所有賓果遊戲計時器
    func invalidateAllBingoTimers() {
        let bingoTimerIDs = timers.keys.filter { $0.hasPrefix("bingo.") }
        bingoTimerIDs.forEach { invalidateTimer(id: $0) }
        print("⏰ TimerManager: 清理所有賓果計時器 (\(bingoTimerIDs.count) 個)")
    }
    
    /// 創建聊天相關計時器
    func createChatTimer(type: String, interval: TimeInterval, repeats: Bool, handler: @escaping () -> Void) {
        let id = "chat.\(type)"
        createTimer(id: id, interval: interval, repeats: repeats, handler: handler)
    }
    
    /// 清理所有聊天計時器
    func invalidateAllChatTimers() {
        let chatTimerIDs = timers.keys.filter { $0.hasPrefix("chat.") }
        chatTimerIDs.forEach { invalidateTimer(id: $0) }
        print("⏰ TimerManager: 清理所有聊天計時器 (\(chatTimerIDs.count) 個)")
    }
}