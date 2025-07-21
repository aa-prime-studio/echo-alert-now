import Foundation
import Combine

// MARK: - ⚠️ DEPRECATED ⚠️
// 此檔案已被 UnifiedTimerManager 取代
// 請使用 UnifiedTimerManager.shared 替代此實作
// 計劃移除日期: 下個主要版本
@available(*, deprecated, message: "使用 UnifiedTimerManager.shared 替代")

// MARK: - Timer 配置
struct TimerConfiguration {
    let interval: TimeInterval
    let repeats: Bool
    let tolerance: TimeInterval?
    let runLoop: RunLoop
    let mode: RunLoop.Mode
    
    init(interval: TimeInterval, 
         repeats: Bool = true, 
         tolerance: TimeInterval? = nil,
         runLoop: RunLoop = .main,
         mode: RunLoop.Mode = .common) {
        self.interval = interval
        self.repeats = repeats
        self.tolerance = tolerance
        self.runLoop = runLoop
        self.mode = mode
    }
    
    // 預設配置
    static let gameSync = TimerConfiguration(interval: 1.0, repeats: true)
    static let heartbeat = TimerConfiguration(interval: 5.0, repeats: true) 
    static let countdown = TimerConfiguration(interval: 1.0, repeats: true)
    static let roomMonitoring = TimerConfiguration(interval: 2.0, repeats: true)
    static let healthCheck = TimerConfiguration(interval: 10.0, repeats: true)
}

// MARK: - Timer 資訊
private class TimerInfo {
    let id: String
    let configuration: TimerConfiguration
    let action: () -> Void
    var timer: Timer?
    let createdAt: Date
    var lastTriggered: Date?
    var triggerCount: Int = 0
    
    init(id: String, configuration: TimerConfiguration, action: @escaping () -> Void) {
        self.id = id
        self.configuration = configuration
        self.action = action
        self.createdAt = Date()
    }
}

// MARK: - 統一 Timer 管理器
@available(*, deprecated, message: "使用 UnifiedTimerManager.shared 替代")
@MainActor
class TimerManager: ObservableObject {
    
    // MARK: - Singleton (用於全局管理)
    static let shared = TimerManager()
    
    // MARK: - Private Properties
    private var timers: [String: TimerInfo] = [:]
    private var isActive = true
    
    // 性能監控
    @Published private(set) var activeTimerCount: Int = 0
    @Published private(set) var totalTriggerCount: Int = 0
    
    private init() {
        setupApplicationLifecycleObservers()
        print("✅ TimerManager: 已初始化")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Interface
    
    /// 調度新的 Timer
    func schedule(
        id: String,
        configuration: TimerConfiguration = .gameSync,
        action: @escaping () -> Void
    ) {
        // 如果已存在相同ID的Timer，先取消
        cancel(id: id)
        
        let timerInfo = TimerInfo(id: id, configuration: configuration, action: action)
        
        // 創建Timer
        let timer = Timer.scheduledTimer(withTimeInterval: configuration.interval, repeats: configuration.repeats) { [weak self] _ in
            self?.handleTimerFire(id: id)
        }
        
        // 設置容錯
        if let tolerance = configuration.tolerance {
            timer.tolerance = tolerance
        }
        
        timerInfo.timer = timer
        timers[id] = timerInfo
        
        updateMetrics()
        
        print("⏰ Timer已調度: \(id), 間隔: \(configuration.interval)s, 重複: \(configuration.repeats)")
    }
    
    /// 取消指定的 Timer
    func cancel(id: String) {
        guard let timerInfo = timers[id] else { return }
        
        timerInfo.timer?.invalidate()
        timers.removeValue(forKey: id)
        
        updateMetrics()
        
        print("⏹️ Timer已取消: \(id)")
    }
    
    /// 暫停指定的 Timer
    func pause(id: String) {
        guard let timerInfo = timers[id] else { return }
        
        timerInfo.timer?.invalidate()
        timerInfo.timer = nil
        
        print("⏸️ Timer已暫停: \(id)")
    }
    
    /// 恢復指定的 Timer
    func resume(id: String) {
        guard let timerInfo = timers[id], timerInfo.timer == nil else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: timerInfo.configuration.interval, repeats: timerInfo.configuration.repeats) { [weak self] _ in
            self?.handleTimerFire(id: id)
        }
        
        timerInfo.timer = timer
        
        print("▶️ Timer已恢復: \(id)")
    }
    
    /// 取消所有 Timer
    func cancelAll() {
        let timerIds = Array(timers.keys)
        timerIds.forEach { cancel(id: $0) }
        
        print("🧹 已取消所有Timer: \(timerIds.count)個")
    }
    
    /// 暫停所有 Timer (應用進入背景時)
    func pauseAll() {
        timers.keys.forEach { pause(id: $0) }
        isActive = false
        
        print("⏸️ 已暫停所有Timer")
    }
    
    /// 恢復所有 Timer (應用回到前景時)
    func resumeAll() {
        timers.keys.forEach { resume(id: $0) }
        isActive = true
        
        print("▶️ 已恢復所有Timer")
    }
    
    /// 檢查Timer是否存在
    func isTimerActive(id: String) -> Bool {
        return timers[id]?.timer?.isValid == true
    }
    
    /// 獲取Timer資訊 (除錯用)
    func getTimerInfo(id: String) -> (interval: TimeInterval, triggerCount: Int, lastTriggered: Date?)? {
        guard let timerInfo = timers[id] else { return nil }
        return (
            interval: timerInfo.configuration.interval,
            triggerCount: timerInfo.triggerCount,
            lastTriggered: timerInfo.lastTriggered
        )
    }
    
    /// 獲取所有活躍Timer的摘要
    func getActiveTimersSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        for (id, timerInfo) in timers {
            summary[id] = [
                "interval": timerInfo.configuration.interval,
                "repeats": timerInfo.configuration.repeats,
                "triggerCount": timerInfo.triggerCount,
                "isValid": timerInfo.timer?.isValid ?? false,
                "createdAt": timerInfo.createdAt,
                "lastTriggered": timerInfo.lastTriggered as Any
            ]
        }
        
        return summary
    }
    
    // MARK: - Private Methods
    
    private func handleTimerFire(id: String) {
        guard let timerInfo = timers[id], isActive else { return }
        
        timerInfo.lastTriggered = Date()
        timerInfo.triggerCount += 1
        totalTriggerCount += 1
        
        // 執行Timer動作
        timerInfo.action()
        
        // 如果是單次Timer，自動清理
        if !timerInfo.configuration.repeats {
            cancel(id: id)
        }
    }
    
    private func updateMetrics() {
        activeTimerCount = timers.count
    }
    
    private func setupApplicationLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAll()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAll()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cleanup()
        }
    }
    
    private func cleanup() {
        cancelAll()
        NotificationCenter.default.removeObserver(self)
        print("🧹 TimerManager: 清理完成")
    }
}

// MARK: - 便利方法擴展
extension TimerManager {
    
    /// 調度遊戲同步Timer
    func scheduleGameSync(id: String, action: @escaping () -> Void) {
        schedule(id: id, configuration: .gameSync, action: action)
    }
    
    /// 調度心跳Timer
    func scheduleHeartbeat(id: String, action: @escaping () -> Void) {
        schedule(id: id, configuration: .heartbeat, action: action)
    }
    
    /// 調度倒數計時Timer
    func scheduleCountdown(id: String, action: @escaping () -> Void) {
        schedule(id: id, configuration: .countdown, action: action)
    }
    
    /// 調度房間監控Timer
    func scheduleRoomMonitoring(id: String, action: @escaping () -> Void) {
        schedule(id: id, configuration: .roomMonitoring, action: action)
    }
    
    /// 調度自定義間隔Timer
    func scheduleCustom(id: String, interval: TimeInterval, repeats: Bool = true, action: @escaping () -> Void) {
        let config = TimerConfiguration(interval: interval, repeats: repeats)
        schedule(id: id, configuration: config, action: action)
    }
}

// MARK: - Timer ID 常數
extension TimerManager {
    enum TimerID {
        // 遊戲相關
        static let gameSync = "game.sync"
        static let gameDraw = "game.draw"
        static let gameCountdown = "game.countdown"
        static let gameRestart = "game.restart"
        
        // 網路相關
        static let heartbeat = "network.heartbeat"
        static let reconnect = "network.reconnect"
        static let healthCheck = "network.healthCheck"
        
        // UI相關
        static let roomMonitoring = "ui.roomMonitoring"
        static let hostPromotion = "ui.hostPromotion"
        
        // 系統相關
        static let cleanup = "system.cleanup"
        static let metrics = "system.metrics"
    }
}

// MARK: - 性能監控擴展
extension TimerManager {
    
    /// 獲取性能統計
    func getPerformanceStats() -> TimerPerformanceStats {
        return TimerPerformanceStats(
            activeTimerCount: activeTimerCount,
            totalTriggerCount: totalTriggerCount,
            averageTriggersPerTimer: activeTimerCount > 0 ? Double(totalTriggerCount) / Double(activeTimerCount) : 0
        )
    }
}

// MARK: - 性能統計結構
struct TimerPerformanceStats {
    let activeTimerCount: Int
    let totalTriggerCount: Int
    let averageTriggersPerTimer: Double
}