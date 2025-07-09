import Foundation
import SwiftUI

/// 定時器管理器 - 負責所有定時器的生命週期管理
@MainActor
class TimerManager: ObservableObject {
    
    // MARK: - Initialization
    
    /// 【FIX】添加明確的初始化狀態跟蹤
    @Published private(set) var isInitialized: Bool = false
    
    init() {
        print("⏰ TimerManager: 開始初始化")
        
        // 【DEADLOCK FIX】直接在 MainActor 上初始化，避免嵌套 Task
        // 移除 Task 包裝，直接設置狀態
        self.isInitialized = true
        print("⏰ TimerManager: 初始化完成")
    }
    
    // MARK: - Properties
    
    /// 活躍的定時器集合
    private var activeTimers: [String: Timer] = [:]
    
    /// 活躍的異步任務集合
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Timer IDs
    
    /// 定時器ID常量
    struct TimerID {
        static let hostPromotion = "host.promotion"
        static let gameCountdown = "game.countdown"
        static let gameDraw = "game.draw"
        static let heartbeat = "network.heartbeat"
        static let heartbeatStartup = "network.heartbeat.startup"
        static let gameSync = "game.sync"
        static let gameRestart = "game.restart"
        static let reconnect = "network.reconnect"
        static let initTimeout = "initialization.timeout"
    }
    
    // MARK: - Timer Management
    
    /// 調度定時器
    /// - Parameters:
    ///   - id: 定時器唯一標識
    ///   - interval: 時間間隔（秒）
    ///   - repeats: 是否重複執行
    ///   - action: 執行的動作
    func scheduleTimer(id: String, interval: TimeInterval, repeats: Bool = true, action: @escaping () -> Void) {
        cancelTimer(id: id)  // 先取消現有的，確保原子性
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                action()
                if !repeats {
                    self.cancelTimer(id: id)
                }
            }
        }
        activeTimers[id] = timer
        print("⏰ TimerManager: 已建立計時器: \(id)，間隔: \(interval)秒，重複: \(repeats)")
    }
    
    /// 取消指定的定時器
    /// - Parameter id: 定時器ID
    func cancelTimer(id: String) {
        activeTimers[id]?.invalidate()
        activeTimers.removeValue(forKey: id)
        print("⏰ TimerManager: 已取消計時器: \(id)")
    }
    
    /// 取消所有定時器
    func cancelAllTimers() {
        activeTimers.values.forEach { $0.invalidate() }
        activeTimers.removeAll()
        print("⏰ TimerManager: 已取消所有計時器")
    }
    
    // MARK: - Async Task Management
    
    /// 調度異步任務
    /// - Parameters:
    ///   - id: 任務唯一標識
    ///   - delay: 延遲時間（秒）
    ///   - action: 執行的異步動作
    func scheduleAsyncTask(id: String, delay: TimeInterval, action: @escaping () async -> Void) {
        cancelAsyncTask(id: id)  // 先取消現有的
        
        let task = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await action()
                self?.cancelAsyncTask(id: id)
            } catch {
                // 任務被取消
                print("⏰ TimerManager: 異步任務被取消: \(id)")
            }
        }
        activeTasks[id] = task
        print("⏰ TimerManager: 已調度異步任務: \(id)，延遲: \(delay)秒")
    }
    
    /// 取消指定的異步任務
    /// - Parameter id: 任務ID
    func cancelAsyncTask(id: String) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
        print("⏰ TimerManager: 已取消異步任務: \(id)")
    }
    
    /// 取消所有異步任務
    func cancelAllAsyncTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        print("⏰ TimerManager: 已取消所有異步任務")
    }
    
    // MARK: - Status
    
    /// 檢查定時器是否活躍
    /// - Parameter id: 定時器ID
    /// - Returns: 是否活躍
    func isTimerActive(id: String) -> Bool {
        return activeTimers[id] != nil
    }
    
    /// 檢查異步任務是否活躍
    /// - Parameter id: 任務ID
    /// - Returns: 是否活躍
    func isAsyncTaskActive(id: String) -> Bool {
        return activeTasks[id] != nil
    }
    
    /// 獲取所有活躍的定時器ID
    /// - Returns: 活躍的定時器ID數組
    func getActiveTimerIDs() -> [String] {
        return Array(activeTimers.keys)
    }
    
    /// 獲取所有活躍的異步任務ID
    /// - Returns: 活躍的異步任務ID數組
    func getActiveAsyncTaskIDs() -> [String] {
        return Array(activeTasks.keys)
    }
    
    // MARK: - Lifecycle
    
    /// 清理所有資源
    nonisolated func cleanup() {
        Task { @MainActor in
            cancelAllTimers()
            cancelAllAsyncTasks()
            print("⏰ TimerManager: 完全清理完成")
        }
    }
    
    deinit {
        // 🚨 CRITICAL: 立即同步清理所有資源，避免崩潰
        
        // 同步清理所有 Timer
        for timer in activeTimers.values {
            timer.invalidate()
        }
        activeTimers.removeAll()
        
        // 同步清理所有 Task
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        
        print("⏰ TimerManager: deinit 清理完成")
    }
}

// MARK: - Convenience Extensions

extension TimerManager {
    
    /// 便捷方法：創建單次執行的定時器
    /// - Parameters:
    ///   - id: 定時器ID
    ///   - delay: 延遲時間
    ///   - action: 執行動作
    func scheduleOnce(id: String, delay: TimeInterval, action: @escaping () -> Void) {
        scheduleTimer(id: id, interval: delay, repeats: false, action: action)
    }
    
    /// 便捷方法：創建重複執行的定時器
    /// - Parameters:
    ///   - id: 定時器ID
    ///   - interval: 時間間隔
    ///   - action: 執行動作
    func scheduleRepeating(id: String, interval: TimeInterval, action: @escaping () -> Void) {
        scheduleTimer(id: id, interval: interval, repeats: true, action: action)
    }
    
    /// 便捷方法：重新調度定時器
    /// - Parameters:
    ///   - id: 定時器ID
    ///   - interval: 新的時間間隔
    ///   - repeats: 是否重複
    ///   - action: 執行動作
    func rescheduleTimer(id: String, interval: TimeInterval, repeats: Bool = true, action: @escaping () -> Void) {
        scheduleTimer(id: id, interval: interval, repeats: repeats, action: action)
    }
}