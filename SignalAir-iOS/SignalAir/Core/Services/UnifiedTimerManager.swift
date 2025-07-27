import Foundation
import Combine
import UIKit

// MARK: - Timer Configuration
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
    static let connectionKeepAlive = TimerConfiguration(interval: 30.0, repeats: true)
    static let autoReconnect = TimerConfiguration(interval: 10.0, repeats: true)
}

// MARK: - Timer Info
private class TimerInfo: @unchecked Sendable {
    let id: String
    let configuration: TimerConfiguration
    weak var timer: Timer?
    let createdAt: Date
    var lastTriggered: Date?
    var triggerCount: Int = 0
    let action: () -> Void
    
    init(id: String, configuration: TimerConfiguration, action: @escaping () -> Void) {
        self.id = id
        self.configuration = configuration
        self.action = action
        self.createdAt = Date()
    }
}

// MARK: - Unified Timer Manager
@MainActor
class UnifiedTimerManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = UnifiedTimerManager()
    
    // MARK: - Published Properties
    @Published private(set) var isInitialized: Bool = false
    @Published private(set) var activeTimerCount: Int = 0
    @Published private(set) var totalTriggerCount: Int = 0
    
    // MARK: - Private Properties
    private var timers: [String: TimerInfo] = [:]
    private var isActive = true
    private let cleanupQueue = DispatchQueue(label: "com.signalair.timer.cleanup", qos: .utility)
    
    private init() {
        setupApplicationLifecycleObservers()
        self.isInitialized = true
        print("⏰ UnifiedTimerManager: 初始化完成")
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
        guard isActive else {
            print("⚠️ TimerManager: 已停用，無法調度 Timer \(id)")
            return
        }
        
        // 清除現有的同名 Timer
        invalidate(id: id)
        
        let info = TimerInfo(id: id, configuration: configuration, action: action)
        
        // 🔧 SWIFT 6 FIX: 最簡潔的解決方案 - 避免所有非必要的捕獲
        let timer = Timer.scheduledTimer(withTimeInterval: configuration.interval, repeats: configuration.repeats) { [weak self, id] _ in
            // 確保在MainActor上執行
            Task { @MainActor [weak self, id] in
                self?.timerDidFire(id: id)
            }
        }
        
        // 設置容差以節省電量
        if let tolerance = configuration.tolerance {
            timer.tolerance = tolerance
        }
        
        info.timer = timer
        timers[id] = info
        
        updateActiveTimerCount()
        print("⏰ Timer 已調度: \(id) (間隔: \(configuration.interval)s)")
    }
    
    /// 取消特定 Timer
    func invalidate(id: String) {
        guard let info = timers[id] else { return }
        
        info.timer?.invalidate()
        timers.removeValue(forKey: id)
        
        updateActiveTimerCount()
        print("⏰ Timer 已取消: \(id)")
    }
    
    /// 取消所有 Timer
    func invalidateAll() {
        for (id, info) in timers {
            info.timer?.invalidate()
            print("⏰ Timer 已取消: \(id)")
        }
        
        timers.removeAll()
        updateActiveTimerCount()
        print("⏰ 所有 Timer 已清除")
    }
    
    /// 暫停所有 Timer
    func pauseAll() {
        isActive = false
        invalidateAll()
        print("⏰ 所有 Timer 已暫停")
    }
    
    /// 恢復 Timer 管理器
    func resume() {
        isActive = true
        print("⏰ Timer 管理器已恢復")
    }
    
    /// 檢查 Timer 是否存在
    func isActive(id: String) -> Bool {
        return timers[id]?.timer?.isValid == true
    }
    
    /// 獲取 Timer 統計信息
    func getTimerStats(id: String) -> (triggerCount: Int, lastTriggered: Date?, createdAt: Date)? {
        guard let info = timers[id] else { return nil }
        return (info.triggerCount, info.lastTriggered, info.createdAt)
    }
    
    // MARK: - Application Lifecycle
    
    private func setupApplicationLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleAppDidEnterBackground()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleAppWillEnterForeground()
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        print("⏰ App 進入背景，暫停非關鍵 Timer")
        // 保留關鍵 Timer，暫停其他
        let criticalTimers = ["heartbeat", "connectionKeepAlive", "autoReconnect"]
        for (id, info) in timers {
            if !criticalTimers.contains(id) {
                info.timer?.invalidate()
            }
        }
    }
    
    private func handleAppWillEnterForeground() {
        print("⏰ App 恢復前台，重新啟動 Timer")
        // 在恢復前台時，由各個模組重新調度需要的 Timer
    }
    
    // MARK: - Helper Methods
    
    /// 🔧 SWIFT 6 FIX: 統一的Timer觸發處理方法
    private func timerDidFire(id: String) {
        guard isActive, let info = timers[id] else {
            invalidate(id: id)
            return
        }
        
        // 更新統計
        info.lastTriggered = Date()
        info.triggerCount += 1
        totalTriggerCount += 1
        
        // 執行回調
        info.action()
    }
    
    private func updateActiveTimerCount() {
        activeTimerCount = timers.values.compactMap { $0.timer?.isValid == true ? 1 : nil }.count
    }
    
    nonisolated private func cleanup() {
        Task { @MainActor in
            invalidateAll()
            NotificationCenter.default.removeObserver(self)
            print("⏰ UnifiedTimerManager: 清理完成")
        }
    }
}

// MARK: - Convenience Extensions

extension UnifiedTimerManager {
    
    /// 遊戲專用 Timer 方法
    func scheduleGameTimer(id: String, interval: TimeInterval = 1.0, action: @escaping () -> Void) {
        let config = TimerConfiguration(interval: interval, repeats: true)
        schedule(id: id, configuration: config, action: action)
    }
    
    /// 心跳檢測 Timer
    func scheduleHeartbeat(action: @escaping () -> Void) {
        schedule(id: "heartbeat", configuration: .heartbeat, action: action)
    }
    
    /// 連接保活 Timer
    func scheduleConnectionKeepAlive(action: @escaping () -> Void) {
        schedule(id: "connectionKeepAlive", configuration: .connectionKeepAlive, action: action)
    }
    
    /// 自動重連 Timer
    func scheduleAutoReconnect(action: @escaping () -> Void) {
        schedule(id: "autoReconnect", configuration: .autoReconnect, action: action)
    }
    
    /// 倒數計時 Timer
    func scheduleCountdown(id: String, action: @escaping () -> Void) {
        schedule(id: id, configuration: .countdown, action: action)
    }
}