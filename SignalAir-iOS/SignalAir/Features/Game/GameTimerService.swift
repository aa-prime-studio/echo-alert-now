import Foundation
import Combine

/// 遊戲計時器服務 - 負責所有計時器管理邏輯
@MainActor
class GameTimerService: GameTimerServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isCountdownActive: Bool = false
    @Published private(set) var currentCountdown: Int = 0
    
    // MARK: - Dependencies
    
    private let timerManager: UnifiedTimerManager
    
    // MARK: - Private Properties
    
    private var countdownTimer: Timer?
    private var autoStartTimer: Timer?
    private var heartbeatTimer: Timer?
    private var restartTimer: Timer?
    
    private var countdownDuration: Int = 0
    private var countdownUpdateCallback: ((Int) -> Void)?
    private var countdownCompleteCallback: (() -> Void)?
    
    // MARK: - Publishers
    
    private let countdownSubject = CurrentValueSubject<Int, Never>(0)
    private let heartbeatSubject = PassthroughSubject<Void, Never>()
    
    var countdownPublisher: AnyPublisher<Int, Never> {
        countdownSubject.eraseToAnyPublisher()
    }
    
    var heartbeatPublisher: AnyPublisher<Void, Never> {
        heartbeatSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(timerManager: UnifiedTimerManager) {
        self.timerManager = timerManager
        
        print("⏰ GameTimerService: 初始化完成")
    }
    
    // MARK: - Game Countdown
    
    /// 開始遊戲倒數計時
    func startGameCountdown(duration: Int, onUpdate: @escaping (Int) -> Void, onComplete: @escaping () -> Void) {
        print("⏰ GameTimerService: 開始遊戲倒數 - \(duration)秒")
        
        // 停止現有的倒數計時
        stopGameCountdown()
        
        countdownDuration = duration
        currentCountdown = duration
        isCountdownActive = true
        countdownUpdateCallback = onUpdate
        countdownCompleteCallback = onComplete
        
        // 立即觸發第一次更新
        onUpdate(currentCountdown)
        countdownSubject.send(currentCountdown)
        
        // 開始計時器
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
    }
    
    /// 停止遊戲倒數計時
    func stopGameCountdown() {
        guard isCountdownActive else { return }
        
        print("⏰ GameTimerService: 停止遊戲倒數")
        
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountdownActive = false
        currentCountdown = 0
        countdownUpdateCallback = nil
        countdownCompleteCallback = nil
        
        countdownSubject.send(0)
    }
    
    /// 更新倒數計時
    private func updateCountdown() {
        guard isCountdownActive else { return }
        
        if currentCountdown > 0 {
            currentCountdown -= 1
            countdownUpdateCallback?(currentCountdown)
            countdownSubject.send(currentCountdown)
            
            print("⏰ GameTimerService: 倒數更新 - \(currentCountdown)")
        } else {
            // 倒數結束
            stopGameCountdown()
            countdownCompleteCallback?()
            
            print("⏰ GameTimerService: 倒數結束")
        }
    }
    
    // MARK: - Auto Start Timer
    
    /// 安排自動開始
    func scheduleAutoStart(delay: TimeInterval, action: @escaping () -> Void) {
        print("⏰ GameTimerService: 安排自動開始 - \(delay)秒後")
        
        cancelAutoStart()
        
        autoStartTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            print("⏰ GameTimerService: 自動開始觸發")
            action()
        }
    }
    
    /// 取消自動開始
    func cancelAutoStart() {
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        print("⏰ GameTimerService: 取消自動開始")
    }
    
    // MARK: - Heartbeat Timer
    
    /// 開始心跳計時器
    func startHeartbeat(interval: TimeInterval, action: @escaping () -> Void) {
        print("💓 GameTimerService: 開始心跳計時器 - 間隔\(interval)秒")
        
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                print("💓 GameTimerService: 心跳觸發")
                action()
                self?.heartbeatSubject.send(())
            }
        }
    }
    
    /// 停止心跳計時器
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        print("💓 GameTimerService: 停止心跳計時器")
    }
    
    // MARK: - Restart Timer
    
    /// 安排重新開始
    func scheduleRestart(delay: TimeInterval, action: @escaping () -> Void) {
        print("🔄 GameTimerService: 安排重新開始 - \(delay)秒後")
        
        cancelRestart()
        
        restartTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            print("🔄 GameTimerService: 重新開始觸發")
            action()
        }
    }
    
    /// 取消重新開始
    func cancelRestart() {
        restartTimer?.invalidate()
        restartTimer = nil
        print("🔄 GameTimerService: 取消重新開始")
    }
    
    // MARK: - Timer Utilities
    
    /// 停止所有計時器
    func stopAllTimers() {
        print("⏰ GameTimerService: 停止所有計時器")
        
        stopGameCountdown()
        cancelAutoStart()
        stopHeartbeat()
        cancelRestart()
    }
    
    /// 檢查是否有活躍的計時器
    var hasActiveTimers: Bool {
        return isCountdownActive || 
               autoStartTimer != nil || 
               heartbeatTimer != nil || 
               restartTimer != nil
    }
    
    // MARK: - Convenience Methods
    
    /// 快速開始3秒倒數
    func startDefaultCountdown(onComplete: @escaping () -> Void) {
        startGameCountdown(duration: 3, onUpdate: { count in
            print("⏰ GameTimerService: 預設倒數 - \(count)")
        }, onComplete: onComplete)
    }
    
    /// 開始主機心跳（5秒間隔）
    func startHostHeartbeat(action: @escaping () -> Void) {
        startHeartbeat(interval: 5.0, action: action)
    }
    
    /// 開始玩家心跳（10秒間隔）
    func startPlayerHeartbeat(action: @escaping () -> Void) {
        startHeartbeat(interval: 10.0, action: action)
    }
    
    /// 快速安排2秒後重新開始
    func scheduleQuickRestart(action: @escaping () -> Void) {
        scheduleRestart(delay: 2.0, action: action)
    }
    
    /// 延遲執行動作
    func scheduleDelayedAction(delay: TimeInterval, action: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
    
    // MARK: - Status Methods
    
    /// 獲取計時器狀態報告
    func getTimerStatus() -> String {
        var status: [String] = []
        
        if isCountdownActive {
            status.append("倒數: \(currentCountdown)")
        }
        if autoStartTimer != nil {
            status.append("自動開始: 已安排")
        }
        if heartbeatTimer != nil {
            status.append("心跳: 活躍")
        }
        if restartTimer != nil {
            status.append("重新開始: 已安排")
        }
        
        return status.isEmpty ? "無活躍計時器" : status.joined(separator: ", ")
    }
    
    // MARK: - Lifecycle
    
    /// 清理資源
    func cleanup() {
        print("🧹 GameTimerService: 清理資源")
        
        // 停止所有計時器（避免記憶體洩漏）
        stopAllTimers()
        
        // 清理回調以避免記憶體洩漏
        countdownUpdateCallback = nil
        countdownCompleteCallback = nil
    }
    
    deinit {
        print("🗑️ GameTimerService: deinit")
        // 在 deinit 中避免所有 MainActor 操作
    }
}

// MARK: - Timer Extensions

extension GameTimerService {
    
    /// 計時器ID枚舉，用於管理不同類型的計時器
    enum TimerID: String, CaseIterable {
        case gameCountdown = "game.countdown"
        case autoStart = "game.autostart"
        case heartbeat = "game.heartbeat"
        case restart = "game.restart"
        case delayedAction = "game.delayed"
        
        var description: String {
            switch self {
            case .gameCountdown: return "遊戲倒數"
            case .autoStart: return "自動開始"
            case .heartbeat: return "心跳檢測"
            case .restart: return "重新開始"
            case .delayedAction: return "延遲動作"
            }
        }
    }
    
    /// 計時器狀態
    enum TimerState {
        case inactive
        case running
        case paused
        case completed
        
        var description: String {
            switch self {
            case .inactive: return "未活躍"
            case .running: return "運行中"
            case .paused: return "已暫停"
            case .completed: return "已完成"
            }
        }
    }
}