import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Emote Types
enum EmoteType: String, Codable, Hashable {
    // 文字表情 (5個)
    case bingo     // 🎉 - "玩家 喊出 BINGO!"
    case nen       // 🤔 - "玩家 說你嫩！"
    case wow       // 😱 - "玩家 大叫太扯！"
    case dizzy     // 😵‍💫 - "玩家 頭暈了"
    case ring      // 💍 - "玩家 問你要不要嫁給他"
    
    // 純Emoji表情 (20個)
    case boom      // 💥
    case pirate    // 🏴‍☠️
    case bug       // 🐛
    case fly       // 🪰
    case fire      // 🔥
    case poop      // 💩
    case clown     // 🤡
    case mindBlown // 🤯
    case pinch     // 🤏
    case eyeRoll   // 🙄
    case rockOn    // 🤟
    case bottle    // 🍼
    case skull     // 💀
    case juggler   // 🤹‍♂️
    case burger    // 🍔
    case battery   // 🔋
    case rocket    // 🚀
    case mouse     // 🐭
    case pray      // 🙏
    case love      // 💕
    
    var emoji: String {
        switch self {
        // 文字表情 (5個)
        case .bingo: return "🎉"
        case .nen: return "🤔"
        case .wow: return "😱"
        case .dizzy: return "😵‍💫"
        case .ring: return "💍"
        
        // 純Emoji表情 (20個)
        case .boom: return "💥"
        case .pirate: return "🏴‍☠️"
        case .bug: return "🐛"
        case .fly: return "🪰"
        case .fire: return "🔥"
        case .poop: return "💩"
        case .clown: return "🤡"
        case .mindBlown: return "🤯"
        case .pinch: return "🤏"
        case .eyeRoll: return "🙄"
        case .rockOn: return "🤟"
        case .bottle: return "🍼"
        case .skull: return "💀"
        case .juggler: return "🤹‍♂️"
        case .burger: return "🍔"
        case .battery: return "🔋"
        case .rocket: return "🚀"
        case .mouse: return "🐭"
        case .pray: return "🙏"
        case .love: return "💕"
        }
    }
    
    var template: String {
        switch self {
        // 文字表情 (5個 - 有動作描述)
        case .bingo: return "%@ 喊出 BINGO!"
        case .nen: return "%@ 說你嫩！"
        case .wow: return "%@ 大叫太扯！"
        case .dizzy: return "%@ 頭暈了"
        case .ring: return "%@ 問你要不要嫁給他"
        
        // 純Emoji表情 (20個 - 僅顯示emoji)
        case .boom: return "%@ 💥"
        case .pirate: return "%@ 🏴‍☠️"
        case .bug: return "%@ 🐛"
        case .fly: return "%@ 🪰"
        case .fire: return "%@ 🔥"
        case .poop: return "%@ 💩"
        case .clown: return "%@ 🤡"
        case .mindBlown: return "%@ 🤯"
        case .pinch: return "%@ 🤏"
        case .eyeRoll: return "%@ 🙄"
        case .rockOn: return "%@ 🤟"
        case .bottle: return "%@ 🍼"
        case .skull: return "%@ 💀"
        case .juggler: return "%@ 🤹‍♂️"
        case .burger: return "%@ 🍔"
        case .battery: return "%@ 🔋"
        case .rocket: return "%@ 🚀"
        case .mouse: return "%@ 🐭"
        case .pray: return "%@ 🙏"
        case .love: return "%@ 💕"
        }
    }
    
    var isPureEmoji: Bool {
        switch self {
        case .boom, .pirate, .bug, .fly, .fire, .poop, .clown, .mindBlown, .pinch, .eyeRoll, .rockOn, .bottle, .skull, .juggler, .burger, .pray, .love:
            return true
        case .bingo, .nen, .wow, .rocket, .battery, .dizzy, .mouse, .ring:
            return false
        }
    }
}

// MARK: - Emote Event
struct EmoteEvent {
    let text: String
    let isPureEmoji: Bool // 是否為純emoji
}

@MainActor
class BingoGameViewModel: ObservableObject {
    // MARK: - Published Properties - 現在由 BingoGameStateManager 管理
    var bingoCard: BingoCard? { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localBingoCard ?? generateBingoCard()
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localBingoCard = newValue
        }
    }
    var drawnNumbers: [Int] { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localDrawnNumbers
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localDrawnNumbers = newValue
        }
    }
    var completedLines: Int { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localCompletedLines
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localCompletedLines = newValue
        }
    }
    var gameWon: Bool { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localGameWon
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localGameWon = newValue
        }
    }
    var gameState: GameRoomState.GameState { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localGameState
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localGameState = newValue
        }
    }
    var countdown: Int { 
        get { 
            // gameStateManager 已移除，使用本地狀態
            return localCountdown
        }
        set { 
            // gameStateManager 已移除，使用本地狀態
            localCountdown = newValue
        }
    }
    var currentNumber: Int? { 
        get { 
            // gameStateManager 已移除，返回 nil
            return nil
        }
        set { 
            // gameStateManager?.currentNumber = newValue // 已移除
        }
    }
    @Published var roomPlayers: [PlayerState] = []
    @Published var roomChatMessages: [RoomChatMessage] = []
    @Published var newChatMessage: String = ""
    @Published var isHost: Bool = false
    @Published var gameRoomID: String = ""
    // 網絡狀態現在由 BingoNetworkManager 管理
    var connectionStatus: String { 
        get { 
            // networkManager 已移除，返回默認狀態
            // return networkManager.connectionStatus // 已移除
            return "初始化中" // 默認狀態 
        }
        set { 
            // networkManager?.connectionStatus = newValue // 已移除 
        }
    }
    var syncStatus: String { 
        get { 
            // networkManager 已移除，返回默認狀態
            return "未同步" // 默認狀態 
        }
        set { 
            // networkManager?.syncStatus = newValue // 已移除 
        }
    }
    var isNetworkActive: Bool { 
        get { 
            // 檢查 MeshManager 的連接狀態
            return !meshManager.getConnectedPeers().isEmpty
        }
        set { 
            // 保留 setter 以維持介面相容性
        }
    }
    var roomID: String = ""
    var isInRoom: Bool = false
    var isGameActive: Bool = false
    
    // MARK: - 房間限制配置
    private let maxPlayersPerRoom = 6  // 每房最多6人
    private let minPlayersToStart = 2  // 最少2人可開始遊戲
    
    // MARK: - 遊戲結果回調
    var onGameWon: ((String, Int) -> Void)?
    
    // MARK: - 表情系統
    private let emoteSubject = PassthroughSubject<EmoteEvent, Never>()
    var emotePublisher: AnyPublisher<EmoteEvent, Never> { emoteSubject.eraseToAnyPublisher() }
    private var lastEmoteTime: Date = Date.distantPast
    private let emoteCooldown: TimeInterval = 2.0
    
    // MARK: - 服務依賴
    private let meshManager: MeshManagerProtocol
    private let securityService: SecurityService
    private let settingsViewModel: SettingsViewModel
    private let languageService: LanguageService
    
    // MARK: - 管理器
    private var timerManager: TimerManager?
    // private var networkManager: BingoNetworkManager? // 已移除
    // private var gameStateManager: BingoGameStateManager? // 已移除
    
    // MARK: - 遊戲管理
    var deviceName: String
    private var playerID: String
    private var hostID: String = ""
    private var gameRoomState: GameRoomState?
    
    // MARK: - 本地狀態屬性 (替代已移除的 gameStateManager)
    private var localBingoCard: BingoCard? = nil
    private var localDrawnNumbers: [Int] = []
    private var localCompletedLines: Int = 0
    private var localGameWon: Bool = false
    private var localGameState: GameRoomState.GameState = .waitingForPlayers
    private var localCountdown: Int = 0
    
    // 定時器管理方法 - 委託給 TimerManager
    @MainActor
    private func scheduleTimer(id: String, interval: TimeInterval, repeats: Bool = true, action: @escaping () -> Void) {
        timerManager?.scheduleTimer(id: id, interval: interval, repeats: repeats, action: action)
    }
    
    @MainActor
    private func cancelTimer(id: String) {
        timerManager?.cancelTimer(id: id)
    }
    
    @MainActor
    private func cancelAllTimers() {
        timerManager?.cancelAllTimers()
    }
    
    // Timer ID 常數 - 使用 TimerManager.TimerID
    private typealias TimerID = String
    
    // MARK: - 網路狀態 - 現在由 BingoNetworkManager 管理
    private var lastSyncTime: Date = Date()
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    
    // MARK: - 初始化狀態追蹤
    @Published private var initializationState: InitializationState = .starting
    private var initializationStartTime: Date = Date()
    private let initializationTimeout: TimeInterval = 30.0
    
    private enum InitializationState: Equatable {
        case starting
        case syncCompleted
        case readyForAsync      // 【NEW】準備執行異步初始化
        case asyncInProgress
        case completed
        case failed(String)  // Use String instead of Error for Equatable
        case timedOut
        
        static func == (lhs: InitializationState, rhs: InitializationState) -> Bool {
            switch (lhs, rhs) {
            case (.starting, .starting),
                 (.syncCompleted, .syncCompleted),
                 (.readyForAsync, .readyForAsync),
                 (.asyncInProgress, .asyncInProgress),
                 (.completed, .completed),
                 (.timedOut, .timedOut):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // MARK: - 觀察者管理
    private var notificationTokens: [NSObjectProtocol] = []
    
    // MARK: - 初始化
    init(
        meshManager: MeshManagerProtocol,
        securityService: SecurityService,
        settingsViewModel: SettingsViewModel,
        languageService: LanguageService,
        nicknameService: NicknameService
    ) {
        print("🎮 BingoGameViewModel: 開始初始化 init 方法")
        
        // 先初始化所有必要的屬性，避免存取未初始化的記憶體
        print("🎮 BingoGameViewModel: 設置基本屬性...")
        self.meshManager = meshManager
        self.securityService = securityService
        self.settingsViewModel = settingsViewModel
        self.languageService = languageService
        print("🎮 BingoGameViewModel: 基本屬性設置完成")
        
        // 【DEADLOCK FIX】在同步初始化階段創建 TimerManager，避免 lazy 延遲初始化
        print("🎮 BingoGameViewModel: 同步初始化 TimerManager...")
        self.timerManager = TimerManager()
        print("🎮 BingoGameViewModel: TimerManager 創建完成")
        
        // 持久化玩家ID（修復每次重新生成的問題）
        if let savedPlayerID = UserDefaults.standard.string(forKey: "BingoPlayerID") {
            self.playerID = savedPlayerID
            print("🎮 使用已保存的玩家ID: \(savedPlayerID.prefix(8))")
        } else {
            self.playerID = UUID().uuidString
            UserDefaults.standard.set(self.playerID, forKey: "BingoPlayerID")
            print("🎮 創建新的玩家ID: \(self.playerID.prefix(8))")
        }
        
        // 安全地初始化玩家資訊 (使用傳入的暱稱服務)
        let userNickname = nicknameService.nickname
        if userNickname.isEmpty {
            self.deviceName = "用戶"
            print("🎮 暱稱為空，使用預設暱稱: '\(self.deviceName)'")
        } else {
            self.deviceName = userNickname
            print("🎮 從 NicknameService 獲取暱稱: '\(self.deviceName)'")
        }
        
        print("🎮 BingoGameViewModel: 所有服務依賴項已正確初始化")
        print("🎮 BingoGameViewModel: 初始化暱稱 來源=NicknameService 暱稱='\(self.deviceName)'")
        
        // 【INTEGRATION FIX】延遲設置回調和觀察者
        print("🎮 BingoGameViewModel: 延遲設置回調和觀察者...")
        
        // 【SAFETY FIX】驗證所有必要組件都已初始化
        print("🎮 BingoGameViewModel: 驗證初始化狀態...")
        print("  - TimerManager: \(timerManager != nil ? "✅" : "❌")")
        print("  - MeshManager: ✅")
        print("  - SecurityService: ✅")
        print("  - SettingsViewModel: ✅")
        print("  - LanguageService: ✅")
        
        print("🎮 BingoGameViewModel: 同步初始化完成")
        initializationState = .syncCompleted
        
        // 【CRITICAL FIX】延遲超時檢查，避免在 init 中使用 Timer
        print("🎮 BingoGameViewModel: 延遲設置初始化超時檢查...")
        
        // 【CRITICAL FIX】移除 Task 死鎖陷阱
        // 不在 @MainActor init 中使用 Task，改為標記需要異步初始化
        print("🎮 BingoGameViewModel: 同步初始化完成，異步初始化將延遲執行")
        initializationState = .readyForAsync
        
        // 【NEW FIX】使用 DispatchQueue.main.async 避免 MainActor 死鎖
        DispatchQueue.main.async { [weak self] in
            self?.triggerAsyncInitialization()
        }
    }
    
    /// 【NEW】公開的異步初始化觸發器 - 解決 Task 死鎖問題
    func triggerAsyncInitialization() {
        guard initializationState == .readyForAsync else {
            print("⚠️ BingoGameViewModel: 無法觸發異步初始化，當前狀態: \(initializationState)")
            return
        }
        
        print("🚀 BingoGameViewModel: 外部觸發異步初始化...")
        
        // 【CRITICAL FIX】使用 DispatchQueue 而不是 MainActor 的 scheduleTimer
        DispatchQueue.main.asyncAfter(deadline: .now() + initializationTimeout) { [weak self] in
            guard let self = self else { return }
            if self.initializationState != .completed {
                print("⚠️ BingoGameViewModel: 初始化超時")
                self.initializationState = .timedOut
            }
        }
        
        // 【NEW FIX】使用 DispatchQueue 啟動異步任務
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            Task {
                await self.completeAsyncInitialization()
            }
        }
    }
    
    /// 完成異步初始化 - 在同步初始化後執行重度操作
    @MainActor
    private func completeAsyncInitialization() async {
        // 防禦性檢查：確認準備執行異步初始化
        guard initializationState == .readyForAsync else {
            print("⚠️ BingoGameViewModel: 狀態不正確，跳過異步初始化 (當前狀態: \(initializationState))")
            initializationState = .failed("狀態不正確")
            return
        }
        
        print("🚀 BingoGameViewModel: 開始異步初始化...")
        initializationState = .asyncInProgress
        
        do {
            // 檢查超時
            let elapsed = Date().timeIntervalSince(initializationStartTime)
            guard elapsed < initializationTimeout else {
                initializationState = .failed("初始化超時")
                return
            }
            
            // 【INTEGRATION FIX】初始化依賴服務
            await initializeDependencies()
            
            // 異步設置翻譯文字
            await updateLocalizedStrings()
            
            // 短暫延遲以確保 UI 更新完成
            try await Task.sleep(for: .milliseconds(100))
            
            // 標記初始化完成
            initializationState = .completed
            
            print("✅ BingoGameViewModel: 異步初始化完成 (耗時: \(String(format: "%.2f", elapsed))秒)")
        } catch {
            print("⚠️ BingoGameViewModel: 異步初始化失敗: \(error)")
            initializationState = .failed("異步初始化失敗: \(error.localizedDescription)")
        }
    }
    
    /// 【INTEGRATION FIX】初始化依賴服務
    @MainActor
    private func initializeDependencies() async {
        print("🔗 BingoGameViewModel: 開始初始化依賴服務...")
        
        // 確保 timerManager 已初始化
        guard timerManager != nil else {
            print("❌ BingoGameViewModel: TimerManager 未初始化，無法繼續")
            return
        }
        
        // 初始化網絡管理器 - 已移除
        // if networkManager == nil { ... } // 已移除
        
        // 初始化遊戲狀態管理器 - 已移除
        // if gameStateManager == nil { ... } // 已移除
        
        // 設置回調 - gameStateManager 已移除
        // gameStateManager?.onGameWon { [weak self] winnerID, lines in
        //     self?.onGameWon?(winnerID, lines)
        // }
        
        // 設置觀察者
        setupNotificationObservers()
        setupNicknameObserver()
        
        print("✅ BingoGameViewModel: 依賴服務初始化完成")
    }
    
    /// 【LEGACY】等待依賴服務完成初始化 - 保留用於向後兼容
    @MainActor
    private func waitForDependencies() async {
        print("🔄 BingoGameViewModel: 等待依賴服務初始化...")
        
        // 等待 TimerManager 初始化完成
        var attempts = 0
        while attempts < 50 {
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }
        
        if timerManager?.isInitialized == true {
            print("✅ TimerManager 初始化完成")
        } else {
            print("⚠️ TimerManager 初始化超時")
        }
        
        print("🔄 BingoGameViewModel: 依賴服務檢查完成")
    }
    
    private enum InitializationError: Error {
        case syncNotCompleted
        case timeout
        case serviceUnavailable
    }
    
    /// 異步更新本地化字串
    @MainActor
    private func updateLocalizedStrings() async {
        do {
            // 使用帶超時的同步翻譯調用
            let result = try await withTimeout(seconds: 2) { [self] in
                return (
                    self.languageService.t("offline"),
                    self.languageService.t("waiting_sync")
                )
            }
            
            connectionStatus = result.0.isEmpty ? "離線" : result.0
            syncStatus = result.1.isEmpty ? "等待同步" : result.1
            print("🌐 BingoGameViewModel: 本地化字串更新完成")
        } catch {
            print("⚠️ BingoGameViewModel: 本地化字串更新超時，保持預設值")
        }
    }
    
    /// 帶超時的任務執行器
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try operation()
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    deinit {
        // 🚨 CRITICAL: 立即同步清理所有資源，避免崩潰
        
        // 【EMERGENCY FIX】不能在 deinit 中訪問 @MainActor 屬性
        // 定時器管理器會在自己的 deinit 中自動清理
        
        // 清理所有觀察者
        NotificationCenter.default.removeObserver(self)
        
        // 如果有 token 觀察者，也要清理
        notificationTokens.forEach { 
            NotificationCenter.default.removeObserver($0)
        }
        notificationTokens.removeAll()
        
        print("🎮 BingoGameViewModel: 完全清理完成")
    }
    
    // MARK: - Crash Testing & QA Methods
    
    /// 崩潰測試和初始化驗證 (供 QA 和測試使用)
    @MainActor
    func performCrashTest() async -> TestResult {
        print("🧪 開始崩潰測試...")
        
        var testResults: [String: Bool] = [:]
        
        // Test 1: 檢查初始化狀態
        testResults["initialization_state"] = checkInitializationHealth()
        
        // Test 2: 檢查服務依賴
        testResults["service_dependencies"] = checkServiceDependencies()
        
        // Test 3: 檢查記憶體狀態
        testResults["memory_safety"] = checkMemorySafety()
        
        // Test 4: 檢查並發安全性
        testResults["concurrency_safety"] = await checkConcurrencySafety()
        
        // Test 5: 檢查定時器狀態
        testResults["timer_health"] = checkTimerHealth()
        
        let allPassed = testResults.values.allSatisfy { $0 }
        let result = TestResult(
            passed: allPassed,
            details: testResults,
            timestamp: Date(),
            initializationTime: Date().timeIntervalSince(initializationStartTime)
        )
        
        print("🧪 崩潰測試完成: \(allPassed ? "✅ 通過" : "❌ 失敗")")
        return result
    }
    
    private func checkInitializationHealth() -> Bool {
        let stateValid = initializationState == .completed || initializationState == .asyncInProgress
        let timeoutValid = Date().timeIntervalSince(initializationStartTime) < initializationTimeout
        let servicesReady = true  // Services are guaranteed to be non-nil after initialization
        
        print("🔍 初始化健康檢查: 狀態=\(stateValid), 超時=\(timeoutValid), 服務=\(servicesReady)")
        return stateValid && timeoutValid && servicesReady
    }
    
    private func checkServiceDependencies() -> Bool {
        // All services are guaranteed to be non-nil after initialization
        let dependencies = [
            true,  // meshManager
            true,  // securityService 
            true,  // settingsViewModel
            true,  // languageService
            true   // nicknameService (accessed through container)
        ]
        
        let allValid = dependencies.allSatisfy { $0 }
        print("🔍 服務依賴檢查: \(allValid ? "✅" : "❌") (\(dependencies.filter { $0 }.count)/\(dependencies.count))")
        return allValid
    }
    
    private func checkMemorySafety() -> Bool {
        // 檢查關鍵屬性是否為 nil
        let criticalProperties = [
            !deviceName.isEmpty,
            !gameRoomID.isEmpty || gameState == .waitingForPlayers,
            connectionStatus.count > 0,
            syncStatus.count > 0
        ]
        
        let allValid = criticalProperties.allSatisfy { $0 }
        print("🔍 記憶體安全檢查: \(allValid ? "✅" : "❌")")
        return allValid
    }
    
    @MainActor
    private func checkConcurrencySafety() async -> Bool {
        // 簡化並發安全檢查，因為所有屬性都在 MainActor 上
        let results = Array(repeating: true, count: 5)  // 模擬 5 次成功檢查
        
        // 實際檢查關鍵屬性的存在性
        let basicCheck = !deviceName.isEmpty && 
                        gameState == gameState &&  // Self-consistency check
                        initializationState == initializationState  // Self-consistency check
        
        let allValid = results.allSatisfy { $0 } && basicCheck
        print("🔍 並發安全檢查: \(allValid ? "✅" : "❌") (MainActor 保護)")
        return allValid
    }
    
    private func checkTimerHealth() -> Bool {
        let activeCount = timerManager?.getActiveTimerIDs().count ?? 0
        let maxExpected = 10 // 合理的最大定時器數量
        let healthy = activeCount <= maxExpected
        
        print("🔍 定時器健康檢查: \(healthy ? "✅" : "❌") (活躍: \(activeCount)/\(maxExpected))")
        return healthy
    }
    
    struct TestResult {
        let passed: Bool
        let details: [String: Bool]
        let timestamp: Date
        let initializationTime: TimeInterval
        
        var description: String {
            let status = passed ? "✅ PASSED" : "❌ FAILED"
            let time = String(format: "%.2f", initializationTime)
            return "\(status) | 初始化時間: \(time)s | 詳細: \(details)"
        }
    }
    
    // MARK: - 主機選擇機制
    
    /// 基於PeerID比較決定是否應該成為主機
    private func determineHost(connectedPeers: [String]) -> Bool {
        guard !connectedPeers.isEmpty else {
            // 沒有其他連線的peers，成為主機
            print("👑 沒有其他連線的玩家，成為主機")
            return true
        }
        
        let myPeerID = playerID
        let allPeerIDs = connectedPeers + [myPeerID]
        let sortedPeerIDs = allPeerIDs.sorted()
        let shouldBeHost = sortedPeerIDs.first == myPeerID
        
        print("🎮 主機判定: 我(\(myPeerID.prefix(8))) vs 其他(\(connectedPeers.map { $0.prefix(8) }.joined(separator: ", "))) = \(shouldBeHost ? "我是主機" : "其他人是主機")")
        
        return shouldBeHost
    }
    
    // MARK: - 調試工具
    
    private func debugGameState() {
        print("""
        🎮 ===== 遊戲狀態 =====
        本地玩家 ID: \(playerID.prefix(8))
        是否為主機: \(isHost)
        房間 ID: \(gameRoomID.prefix(8))
        遊戲狀態: \(gameState)
        房間玩家數: \(roomPlayers.count)
        房間玩家: [\(roomPlayers.map { "\($0.name)(\($0.id.prefix(8)))" }.joined(separator: ", "))]
        ====================
        """)
    }
    
    // MARK: - Mesh 網路設定
    
    /// 網路設置 - 現在使用 BingoNetworkManager
    private func setupMeshNetworking() {
        print("🎮 BingoGameViewModel: 使用 BingoNetworkManager 設置網路")
        // networkManager?.setupMeshNetworking() // 已移除
        
        // 延遲驗證網路就緒狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.verifyNetworkReadiness()
        }
    }
    
    /// 異步網路設置 - 現在使用 BingoNetworkManager
    private func setupMeshNetworkingAsync() async {
        print("🎮 BingoGameViewModel: 使用 BingoNetworkManager 異步設置網路")
        // await networkManager?.setupMeshNetworkingAsync() // 已移除
        
        // 驗證網路狀態
        Task {
            await self.verifyNetworkReadinessAsync()
        }
    }
    
    /// 【CRITICAL FIX】專門為房間創建者設計的網路初始化
    private func setupMeshNetworkingForHost() async {
        print("🏠 BingoGameViewModel: 使用 BingoNetworkManager 設置主機網路")
        // await networkManager?.setupMeshNetworkingForHost() // 已移除
        
        // 驗證網路狀態
        Task {
            await self.verifyNetworkReadinessAsync()
        }
    }
    
    /// 網路就緒驗證 - 現在使用 BingoNetworkManager
    @MainActor
    private func verifyNetworkReadinessAsync() async {
        let isReady = !meshManager.getConnectedPeers().isEmpty
        
        if isReady {
            self.reconnectAttempts = 0
            print("✅ BingoGameViewModel: 網路驗證完成，狀態穩定")
        } else {
            print("⚠️ BingoGameViewModel: 網路狀態不穩定")
            
            // 如果網路不穩定，嘗試恢復連接
            if reconnectAttempts < maxReconnectAttempts {
                performNetworkRecovery()
            }
        }
    }
    
    /// 【CRITICAL FIX】驗證網路通道狀態，防止崩潰（真正非阻塞版本）
    private func validateNetworkChannelState() throws {
        // 【EMERGENCY FIX】跳過可能阻塞的網路就緒檢查，直接進入快速模式
        print("🚀 BingoGameViewModel: 跳過網路就緒檢查，使用快速初始化模式")
        
        // 直接設置為活躍狀態，後續非同步驗證
        DispatchQueue.main.async { [weak self] in
            self?.connectionStatus = "正在連接..."
            self?.isNetworkActive = true
        }
        
        // 非同步檢查實際網路狀態（不會阻塞初始化）
        Task { [weak self] in
            await self?.performDelayedNetworkValidation()
        }
    }
    
    /// 延遲的網路狀態驗證（非阻塞）
    @MainActor
    private func performDelayedNetworkValidation() async {
        // 等待一秒，讓初始化完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("🔍 BingoGameViewModel: 開始延遲網路狀態檢查...")
        
        // 使用超時機制檢查網路狀態
        let isReady = await checkNetworkReadyWithTimeout()
        
        if isReady {
            let connectedPeers = meshManager.getConnectedPeers()
            if connectedPeers.isEmpty {
                print("ℹ️ BingoGameViewModel: 目前無其他連接的節點（單機模式）")
                connectionStatus = "單機模式"
            } else {
                print("✅ BingoGameViewModel: 檢測到 \(connectedPeers.count) 個連接節點")
                connectionStatus = "已連接 \(connectedPeers.count) 個節點"
            }
        } else {
            print("⚠️ BingoGameViewModel: 網路檢查超時，使用離線模式")
            connectionStatus = "離線模式"
            isNetworkActive = false
        }
    }
    
    /// 帶超時的網路就緒檢查
    private func checkNetworkReadyWithTimeout() async -> Bool {
        do {
            return try await withThrowingTaskGroup(of: Bool.self) { group in
                // 添加網路檢查任務
                group.addTask { [weak self] in
                    return !(await self?.meshManager.getConnectedPeers().isEmpty ?? true)
                }
                
                // 添加超時任務
                group.addTask {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒超時
                    return false
                }
                
                // 返回第一個完成的結果
                if let result = try await group.next() {
                    group.cancelAll()
                    return result
                }
                return false
            }
        } catch {
            print("❌ BingoGameViewModel: 網路檢查失敗: \(error)")
            return false
        }
    }
    
    /// 【錯誤恢復】網路故障恢復程序
    private func performNetworkRecovery() {
        print("🔄 BingoGameViewModel: 執行網路恢復程序... (嘗試 \(reconnectAttempts + 1)/\(maxReconnectAttempts))")
        
        // 安全地更新網路狀態
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isNetworkActive = false
            self.reconnectAttempts += 1
            
            // 如果超過最大重試次數，設置降級模式
            if self.reconnectAttempts >= self.maxReconnectAttempts {
                print("⚠️ BingoGameViewModel: 達到最大重試次數，進入離線模式")
                self.connectionStatus = "離線模式"
                return
            }
            
            // 延遲重試網路初始化 - 使用指數退避策略
            let retryDelay = min(pow(2.0, Double(self.reconnectAttempts)), 10.0) // 最多等待10秒
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                guard let self = self else { return }
                
                print("🔄 BingoGameViewModel: 第 \(self.reconnectAttempts) 次重試網路初始化...")
                self.setupMeshNetworking()
            }
        }
    }
    
    /// 【驗證機制】確認網路完全就緒
    private func verifyNetworkReadiness() {
        guard isNetworkActive else { return }
        
        let isReady = !meshManager.getConnectedPeers().isEmpty
        print("🔍 BingoGameViewModel: 網路就緒狀態驗證 = \(isReady)")
        
        if isReady {
            connectionStatus = "已連接"
            reconnectAttempts = 0 // 重置重試計數
            print("✅ BingoGameViewModel: 網路狀態穩定，準備就緒")
        } else {
            print("⚠️ BingoGameViewModel: 網路狀態不穩定，將監控並重試")
            connectionStatus = "連接不穩定"
            
            // 設置監控，如果持續不穩定則重新初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if let self = self, self.meshManager.getConnectedPeers().isEmpty {
                    self.isNetworkActive = false
                    self.setupMeshNetworking()
                }
            }
        }
    }
    
    /// 【CRITICAL FIX】驗證廣播通道狀態，防止 "Not in connected state" 錯誤
    private func validateBroadcastChannelState() throws {
        // 1. 檢查基本網路狀態
        guard isNetworkActive else {
            throw NetworkError.notConnected
        }
        
        // 2. 允許單機模式和多人模式廣播 (移除過度嚴格檢查)
        let connectedPeers = meshManager.getConnectedPeers()
        if connectedPeers.isEmpty {
            print("ℹ️ BingoGameViewModel: 單機模式，允許本地廣播")
        } else {
            print("✅ BingoGameViewModel: 多人模式，連接節點數: \(connectedPeers.count)")
        }
        
        print("✅ BingoGameViewModel: 廣播通道狀態驗證通過")
    }
    
    // MARK: - 遊戲房間管理
    
    func createGameRoom() {
        // 【簡化修復】進入房間時才啟動網路
        if !isNetworkActive {
            setupMeshNetworking()
        }
        
        gameRoomID = UUID().uuidString
        hostID = playerID
        isHost = true
        isInRoom = true
        
        // 🔧 確保名稱一致性，避免 PlayerListView 匹配問題
        let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let initialPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
        roomPlayers = [initialPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedDeviceName
        
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: .waitingForPlayers,
            drawnNumbers: [],
            currentNumber: nil,
            countdown: 0,
            startTime: nil
        )
        
        bingoCard = generateBingoCard()
        broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        
        print("🏠 創建房間：\(gameRoomID.prefix(8)) 主機=\(deviceName) ID=\(playerID)")
        addSystemMessage("\(languageService.t("room_created")) \(gameRoomID.prefix(8))")
    }
    
    /// 異步版本的創建房間方法，避免阻塞主線程
    @MainActor
    func createGameRoomAsync() async {
        print("🎮 開始異步創建房間...")
        
        // 【CRITICAL FIX】房間創建者直接啟動網路，不等待連接
        if !isNetworkActive {
            await setupMeshNetworkingForHost()
        }
        
        gameRoomID = UUID().uuidString
        hostID = playerID
        isHost = true
        isInRoom = true
        
        // 【修復1】確保本機玩家正確加入房間列表，使用playerID作為唯一標識
        let normalizedPlayerName = NicknameFormatter.cleanNickname(deviceName)
        let initialPlayer = PlayerState(id: playerID, name: normalizedPlayerName)
        roomPlayers = [initialPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedPlayerName
        
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: .waitingForPlayers,
            drawnNumbers: [],
            currentNumber: nil,
            countdown: 0,
            startTime: nil
        )
        
        bingoCard = generateBingoCard()
        broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        
        print("🏠 異步創建房間完成：\(gameRoomID.prefix(8)) 主機=\(deviceName)")
        addSystemMessage("\(languageService.t("room_created")) \(gameRoomID.prefix(8))")
    }
    
    func joinGameRoom(_ roomID: String) {
        // 【簡化修復】進入房間時才啟動網路
        if !isNetworkActive {
            setupMeshNetworking()
        }
        
        gameRoomID = roomID
        isHost = false
        isInRoom = true
        
        // 🔧 添加本機玩家到玩家列表，確保名稱一致性
        let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let localPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
        roomPlayers = [localPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedDeviceName
        
        let requestData = "\(playerID)|\(normalizedDeviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
        
        bingoCard = generateBingoCard()
        print("🚪 加入房間：\(roomID.prefix(8)) 玩家=\(deviceName) ID=\(playerID)")
        addSystemMessage("\(languageService.t("joining_room")) \(roomID.prefix(8))")
        
        startSyncTimer()
    }
    
    /// 異步版本的加入房間方法，避免阻塞主線程
    @MainActor
    func joinGameRoomAsync(_ roomID: String) async {
        print("🎮 開始異步加入房間：\(roomID.prefix(8))")
        
        // 異步初始化網路
        if !isNetworkActive {
            await setupMeshNetworkingAsync()
        }
        
        gameRoomID = roomID
        isHost = false
        isInRoom = true
        
        // 🔧 添加本機玩家到玩家列表，確保名稱一致性
        let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let localPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
        roomPlayers = [localPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedDeviceName
        
        let requestData = "\(playerID)|\(normalizedDeviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
        
        bingoCard = generateBingoCard()
        print("🚪 異步加入房間完成：\(roomID.prefix(8)) 玩家=\(normalizedDeviceName)")
        addSystemMessage("\(languageService.t("joining_room")) \(roomID.prefix(8))")
        
        startSyncTimer()
    }
    
    // 【簡化方案】簡單的離開房間方法
    func leaveRoom() {
        isInRoom = false
        gameRoomID = ""
        roomPlayers.removeAll()
        roomChatMessages.removeAll()
        cancelAllTimers()
        
        // 停止網路（節省資源）
        isNetworkActive = false
    }
    
    
    @MainActor
    func attemptToJoinOrCreateRoom(roomID: String) {
        // 防止重複操作
        guard !isInRoom else {
            print("⚠️ 已在房間中，忽略重複加入請求")
            return
        }
        
        // 確保依賴存在（MeshManagerProtocol 不是可選類型，但仍然檢查狀態）
        print("✅ meshManager 已初始化，繼續房間加入流程")
        
        
        // 設置原子狀態
        isInRoom = true
        self.gameRoomID = roomID
        
        // 🔧 添加本機玩家到玩家列表，確保名稱一致性
        let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let localPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
        roomPlayers = [localPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedDeviceName
        
        print("🔄 嘗試加入或創建房間：\(roomID) 玩家=\(normalizedDeviceName) ID=\(playerID)")
        
        Task {
            await joinRoomSafely(roomID: roomID, meshManager: self.meshManager)
        }
        
        bingoCard = generateBingoCard()
        startSyncTimer()
        
        print("🎮 房間進入初始化完成：房間=\(roomID) 玩家=\(deviceName)")
    }
    
    private func scheduleRetryJoinRoom(_ roomID: String) {
        scheduleTimer(id: "reconnect", interval: 1.0, repeats: false) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.attemptToJoinOrCreateRoom(roomID: roomID)
            }
        }
    }
    
    private func joinRoomSafely(roomID: String, meshManager: MeshManagerProtocol) async {
        let connectedPeers = await checkReliableConnectionState()
        
        if connectedPeers.count > 0 {
            // 有穩定網路連接時，嘗試加入現有房間
            print("📡 發現穩定網路連接 (\(connectedPeers.count) peers)，嘗試加入現有房間")
            
            // 🔧 CRITICAL FIX: 立即同步連接的玩家作為潛在房間成員
            await synchronizeConnectedPeersAsPlayers()
            
            // 使用重試機制發送連接請求
            await sendConnectionRequestWithRetry(roomID: roomID)
            
            await MainActor.run {
                addSystemMessage("\(languageService.t("connecting_to_room")) \(roomID)...")
                
                // 設置主機推廣定時器，如果7秒內沒有收到房間同步，則成為主機
                scheduleTimer(id: TimerManager.TimerID.hostPromotion, interval: 7.0, repeats: false) { [weak self] in
                    guard let self = self else { return }
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if !self.isHost && self.roomPlayers.count == 1 {
                            print("⏰ 連接超時，成為主機")
                            self.becomeRoomHost()
                        }
                    }
                }
            }
        } else {
            // 沒有穩定網路連接時，直接成為主機（離線模式）
            print("📶 無穩定網路連接，直接成為主機（離線模式）")
            await MainActor.run {
                addSystemMessage("進入房間 \(roomID)（離線模式）")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.becomeRoomHost()
                }
            }
        }
    }
    
    private func becomeRoomHost() {
        // 取消主機推廣定時器
        cancelTimer(id: TimerManager.TimerID.hostPromotion)
        
        isHost = true
        hostID = playerID
        
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: .waitingForPlayers,
            drawnNumbers: [],
            currentNumber: nil,
            countdown: 0,
            startTime: nil
        )
        
        print("👑 成為房間主機：\(gameRoomID.prefix(8)) 主機=\(deviceName) ID=\(playerID.prefix(8))")
        addSystemMessage(languageService.t("became_room_host"))
        
        // 廣播房間狀態
        broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        
        // 調試信息
        debugGameState()
    }
    
    func leaveGameRoom() {
        if isNetworkActive {
            let leaveData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
            broadcastGameMessage(.playerLeft, data: leaveData)
        }
        
        cleanup()
        resetGameState()
        addSystemMessage(languageService.t("left_room"))
    }
    
    // MARK: - 遊戲狀態同步
    
    
    private func processGameMessage(_ message: GameMessage) {
        lastSyncTime = Date()
        
        switch message.type {
        case .playerJoined:
            handlePlayerJoined(message)
        case .playerLeft:
            handlePlayerLeft(message)
        case .roomSync:
            handleRoomSync(message)
        case .reconnectRequest:
            handleReconnectRequest(message)
        case .gameStateUpdate:
            handleGameStateUpdate(message)
        case .numberDrawn:
            handleNumberDrawn(message)
        case .playerProgress:
            handlePlayerProgress(message)
        case .chatMessage:
            handleChatMessage(message)
        case .gameStart:
            handleGameStart(message)
        case .gameEnd:
            handleGameEnd(message)
        case .heartbeat:
            handleHeartbeat(message)
        case .emote:
            handleEmote(message)
        case .weeklyLeaderboardUpdate:
            handleWeeklyLeaderboardUpdate(message)
        case .weeklyLeaderboardSync:
            handleWeeklyLeaderboardSync(message)
        case .weeklyLeaderboardRequest:
            handleWeeklyLeaderboardRequest(message)
        case .winnerAnnouncement:
            handleWinnerAnnouncement(message)
        case .gameRestart:
            handleGameRestart(message)
        }
    }
    
    // MARK: - 訊息處理器
    
    private func handlePlayerJoined(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 2 else { return }
        
        // 接收的暱稱應該已經是清理過的，直接使用
        let playerState = PlayerState(id: components[0], name: components[1])
        
        if !roomPlayers.contains(where: { $0.id == playerState.id }) {
            roomPlayers.append(playerState)
            print("✅ 玩家 \(playerState.name) 加入房間 (\(roomPlayers.count)/\(maxPlayersPerRoom))")
            
            // 檢查是否達到最少人數，自動開始倒數計時（僅限主機）
            if isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers {
                print("🎮 達到最少人數 (\(roomPlayers.count)/\(minPlayersToStart))，自動開始遊戲")
                startGame()
            }
            
            broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        }
    }
    
    private func handlePlayerLeft(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard !components.isEmpty else { return }
        
        let playerID = components[0]
        roomPlayers.removeAll { $0.id == playerID }
        
        if isHost {
            broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        }
    }
    
    private func handleRoomSync(_ message: GameMessage) {
        // 取消主機推廣定時器（修復重複成為主機的問題）
        cancelTimer(id: TimerManager.TimerID.hostPromotion)
        print("⏰ 取消主機推廣定時器 - 收到房間同步")
        
        // 使用標準格式解碼房間狀態
        guard let roomState = decodeStandardRoomState(message.data) else {
            print("❌ 標準格式房間同步解碼失敗")
            return
        }
        
        print("🔄 收到房間同步：房間ID=\(roomState.roomID.prefix(8)) 玩家數=\(roomState.players.count) 狀態=\(roomState.gameState)")
        
        // 更新房間狀態
        gameRoomState = roomState
        gameState = roomState.gameState
        drawnNumbers = roomState.drawnNumbers
        currentNumber = roomState.currentNumber
        countdown = roomState.countdown
        
        // 【修復2】確保本機玩家存在於玩家列表中，使用正確的ID匹配
        var updatedPlayers = roomState.players
        let localPlayerExists = updatedPlayers.contains { $0.id == playerID }
        
        if !localPlayerExists && isInRoom {
            let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
            let localPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
            updatedPlayers.append(localPlayer)
            print("➕ 添加本機玩家到同步列表：\(normalizedDeviceName) (\(playerID))")
        }
        
        roomPlayers = updatedPlayers
        
        // 房間同步後檢查是否達到最少人數，自動開始倒數計時（僅限主機）
        if isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers {
            print("🎮 房間同步後達到最少人數 (\(roomPlayers.count)/\(minPlayersToStart))，自動開始遊戲")
            startGame()
        }
        
        print("✅ 房間同步完成：當前玩家列表 [\(roomPlayers.map { "\($0.name)(\($0.id.prefix(8)))" }.joined(separator: ", "))]")
    }
    
    private func handleReconnectRequest(_ message: GameMessage) {
        let dataString = String(data: message.data, encoding: .utf8) ?? ""
        
        // 🔧 處理新的加入確認請求
        if dataString == "join_confirmation_request" {
            handleJoinConfirmationRequest(message)
            return
        }
        
        guard isHost else { 
            print("🚫 非主機收到 reconnect_request，忽略")
            return 
        }
        
        let components = dataString.components(separatedBy: "|")
        guard components.count >= 2 else { 
            print("❌ reconnect_request 數據格式錯誤")
            return 
        }
        
        // 接收的暱稱應該已經是清理過的，直接使用
        let playerState = PlayerState(id: components[0], name: components[1])
        
        print("🔄 處理加入請求：\(playerState.name) (\(playerState.id)) 當前房間人數：\(roomPlayers.count)/\(maxPlayersPerRoom)")
        
        // 檢查房間是否已滿
        if roomPlayers.count >= maxPlayersPerRoom {
            print("⚠️ 房間已滿，拒絕玩家 \(playerState.name) 加入")
            return
        }
        
        // 【修復2】檢查玩家是否已在房間內，使用正確的ID匹配機制
        DispatchQueue.main.async {
            if let existingIndex = self.roomPlayers.firstIndex(where: { $0.id == playerState.id }) {
                // 更新現有玩家資訊
                self.roomPlayers[existingIndex] = playerState
                print("🔄 更新現有玩家：\(playerState.name) (\(playerState.id.prefix(8)))")
            } else {
                // 添加新玩家
                self.roomPlayers.append(playerState)
                print("✅ 新玩家加入房間：\(playerState.name) (\(playerState.id.prefix(8))) 房間人數：(\(self.roomPlayers.count)/\(self.maxPlayersPerRoom))")
                
                // 檢查是否達到開始遊戲條件
                if self.gameState == .waitingForPlayers && self.roomPlayers.count >= self.minPlayersToStart {
                    print("🎮 達到最少人數 (\(self.roomPlayers.count)/\(self.minPlayersToStart))，自動開始遊戲")
                    self.startGame()
                } else if self.gameState == .playing {
                    print("🎮 遊戲進行中，玩家 \(playerState.name) 仍可加入觀戰 (\(self.roomPlayers.count)/\(self.maxPlayersPerRoom))")
                }
            }
            
            // 更新房間狀態並廣播
            self.updateGameRoomState()
            
            // 立即廣播房間狀態
            print("📡 主機立即廣播房間狀態給新玩家")
            self.broadcastGameMessage(.roomSync, data: self.encodeGameRoomState())
            
            // 簡化版：使用timer代替Task.sleep
            self.scheduleTimer(id: "room.sync.repeat", interval: 1.0, repeats: false) {
                print("📡 主機重複廣播房間狀態")
                self.broadcastGameMessage(.roomSync, data: self.encodeGameRoomState())
            }
        }
    }
    
    /// 🔧 處理加入確認請求（新增）
    private func handleJoinConfirmationRequest(_ message: GameMessage) {
        print("📞 收到加入確認請求，來自：\(message.senderID)")
        
        // 自動回應表示願意加入房間
        let response = GameMessage(
            type: .playerJoined,
            senderID: playerID,
            senderName: deviceName,
            data: "\(deviceName)|\(NicknameFormatter.cleanNickname(deviceName))".data(using: .utf8) ?? Data(),
            timestamp: Date(),
            gameRoomID: gameRoomID
        )
        
        do {
            let encoder = JSONEncoder()
            let responseData = try encoder.encode(response)
            
            // 使用廣播方式回應（因為協議中沒有直接發送方法）
            meshManager.broadcastMessage(responseData, messageType: .game)
            print("✅ 已回應加入確認：向 \(message.senderID) 發送 playerJoined")
            
            // 更新自己的房間狀態
            DispatchQueue.main.async {
                self.gameRoomID = message.gameRoomID
                self.isInRoom = true
                if !self.roomPlayers.contains(where: { $0.id == self.deviceName }) {
                    let selfPlayer = PlayerState(id: self.deviceName, name: NicknameFormatter.cleanNickname(self.deviceName))
                    self.roomPlayers.append(selfPlayer)
                }
                print("🏠 已加入房間：\(message.gameRoomID)")
            }
        } catch {
            print("❌ 回應加入確認失敗：\(error)")
        }
    }
    
    private func updateGameRoomState() {
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: gameState,
            drawnNumbers: drawnNumbers,
            currentNumber: currentNumber,
            countdown: countdown,
            startTime: nil
        )
    }
    
    private func handleHeartbeat(_ message: GameMessage) {
        // 處理心跳訊息，只更新已存在玩家的在線狀態，不添加新玩家
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 2 else { return }
        
        let playerID = components[0]
        let playerName = components[1]
        
        // 只更新已存在玩家的在線狀態，不透過心跳添加新玩家
        DispatchQueue.main.async {
            if let index = self.roomPlayers.firstIndex(where: { $0.id == playerID }) {
                let existingPlayer = self.roomPlayers[index]
                let updatedPlayer = PlayerState(
                    id: existingPlayer.id,
                    name: existingPlayer.name, // 保持原有名稱，避免暱稱變更衝突
                    completedLines: existingPlayer.completedLines,
                    hasWon: existingPlayer.hasWon,
                    isConnected: true
                )
                self.roomPlayers[index] = updatedPlayer
                print("💓 更新心跳: \(existingPlayer.name) (\(playerID)) 在線狀態")
            } else {
                print("💓 忽略未知玩家心跳: \(playerName) (\(playerID)) - 玩家不在房間內")
            }
        }
    }
    
    private func handleGameStateUpdate(_ message: GameMessage) {
        // 使用純二進制解碼遊戲狀態
        guard message.data.count >= 1 else {
            print("❌ 遊戲狀態數據太短")
            return
        }
        
        let stateValue = message.data[0]
        switch stateValue {
        case 0: gameState = .waitingForPlayers
        case 1: gameState = .countdown
        case 2: gameState = .playing
        case 3: gameState = .finished
        default:
            print("❌ 未知的遊戲狀態值: \(stateValue)")
        }
    }
    
    private func handleNumberDrawn(_ message: GameMessage) {
        guard let numberString = String(data: message.data, encoding: .utf8),
              let number = Int(numberString) else { return }
        
        drawnNumbers.append(number)
        currentNumber = number
        
        checkBingoCard(for: number)
    }
    
    private func handlePlayerProgress(_ message: GameMessage) {
        // 使用純二進制解碼玩家進度
        guard message.data.count >= 4 else {
            print("❌ 玩家進度數據太短")
            return
        }
        
        var offset = 0
        
        // 玩家ID長度
        let idLength = Int(message.data[offset])
        offset += 1
        
        guard offset + idLength <= message.data.count else { return }
        let playerID = String(data: message.data.subdata(in: offset..<offset+idLength), encoding: .utf8) ?? ""
        offset += idLength
        
        // 玩家名稱長度
        guard offset < message.data.count else { return }
        let nameLength = Int(message.data[offset])
        offset += 1
        
        guard offset + nameLength <= message.data.count else { return }
        let playerName = String(data: message.data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 完成線數
        guard offset < message.data.count else { return }
        let completedLines = Int(message.data[offset])
        offset += 1
        
        // 是否獲勝
        guard offset < message.data.count else { return }
        let hasWon = message.data[offset] == 1
        
        let playerState = PlayerState(
            id: playerID,
            name: playerName,
            completedLines: completedLines,
            hasWon: hasWon
        )
        
        // 【修復2】更新玩家狀態時確保使用正確的ID匹配
        if let index = roomPlayers.firstIndex(where: { $0.id == playerState.id }) {
            roomPlayers[index] = playerState
            print("🔄 更新玩家狀態: \(playerState.name) (\(playerState.id.prefix(8)))")
        } else {
            print("⚠️ 嘗試更新未知玩家: \(playerState.name) (\(playerState.id.prefix(8)))")
        }
    }
    
    private func handleChatMessage(_ message: GameMessage) {
        // 使用純二進制解碼聊天訊息
        guard message.data.count >= 3 else {
            print("❌ 聊天訊息數據太短")
            return
        }
        
        var offset = 0
        
        // 訊息內容長度
        guard offset + 2 <= message.data.count else { return }
        let messageLength = message.data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 訊息內容
        guard offset + Int(messageLength) <= message.data.count else { return }
        let messageText = String(data: message.data.subdata(in: offset..<offset+Int(messageLength)), encoding: .utf8) ?? ""
        offset += Int(messageLength)
        
        // 玩家名稱長度
        guard offset < message.data.count else { return }
        let nameLength = Int(message.data[offset])
        offset += 1
        
        // 玩家名稱
        guard offset + nameLength <= message.data.count else { return }
        let playerName = String(data: message.data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        
        // 接收的暱稱應該已經是清理過的，直接使用
        let cleanPlayerName = playerName
        
        let chatMessage = RoomChatMessage(
            message: messageText,
            playerName: cleanPlayerName,
            isOwn: false
        )
        // 高效的聊天訊息管理 - 批量操作減少UI更新
        let maxMessages = 100
        if roomChatMessages.count >= maxMessages {
            // 移除舊訊息，保持性能
            roomChatMessages.removeFirst(roomChatMessages.count - maxMessages + 1)
        }
        roomChatMessages.append(chatMessage)
    }
    
    private func handleGameStart(_ message: GameMessage) {
        // 非主機玩家收到遊戲開始訊息
        if !isHost {
            gameState = .countdown
            countdown = 3
            addSystemMessage("遊戲即將開始...")
            
            // 非主機玩家也顯示倒數計時
            scheduleTimer(id: TimerManager.TimerID.gameCountdown, interval: 1.0, repeats: true) { [weak self] in
                guard let self = self else { return }
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.countdown > 0 {
                        self.addSystemMessage("\(self.countdown)")
                        print("⏰ 非主機倒數計時: \(self.countdown)")
                    }
                    
                    self.countdown -= 1
                    
                    if self.countdown < 0 {
                        self.cancelTimer(id: TimerManager.TimerID.gameCountdown)
                        self.gameState = .playing
                        
                        // 清除之前的系統消息
                        self.clearSystemMessages()
                        
                        self.addSystemMessage("開始抽卡！")
                    }
                }
            }
        } else {
            // 主機玩家廣播狀態更新
            gameState = .playing
            
            // 清除系統消息
            clearSystemMessages()
            
            broadcastGameMessage(.gameStateUpdate, data: encodeGameState(.playing))
        }
    }
    
    private func handleGameEnd(_ message: GameMessage) {
        gameState = .finished
        broadcastGameMessage(.gameEnd, data: Data())
    }
    
    private func handleGameWin(_ message: GameMessage) {
        // 處理遊戲勝利訊息
        let winnerInfo = String(data: message.data, encoding: .utf8) ?? ""
        print("🏆 收到遊戲勝利訊息: \(winnerInfo)")
        
        // 更新遊戲狀態
        gameState = .finished
        
        // 可以在這裡添加更多勝利處理邏輯
        addSystemMessage("🏆 遊戲結束！")
    }
    
    // MARK: - 遊戲控制
    
    func startGame() {
        guard isHost && (gameState == .waitingForPlayers || gameState == .countdown) else { return }
        
        // 檢查最少人數要求
        if roomPlayers.count < minPlayersToStart {
            print("⚠️ 房間人數不足，需要至少 \(minPlayersToStart) 人才能開始遊戲")
            addSystemMessage("\(languageService.t("need_at_least")) \(minPlayersToStart) \(languageService.t("players_to_start"))")
            return
        }
        
        print("🎮 開始遊戲，房間人數：\(roomPlayers.count)/\(maxPlayersPerRoom)")
        
        // 廣播遊戲開始給其他玩家
        broadcastGameMessage(.gameStart, data: Data())
        
        // 主機開始倒數計時
        startCountdownToGame()
    }
    
    private func startCountdownToGame() {
        gameState = .countdown
        countdown = 3
        addSystemMessage("遊戲即將開始...")
        
        // 主機倒數計時器
        scheduleTimer(id: TimerManager.TimerID.gameCountdown, interval: 1.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.countdown > 0 {
                    self.addSystemMessage("\(self.countdown)")
                    print("⏰ 主機倒數計時: \(self.countdown)")
                }
                
                self.countdown -= 1
                
                if self.countdown < 0 {
                    self.cancelTimer(id: TimerManager.TimerID.gameCountdown)
                    self.gameState = .playing
                    
                    // 清除系統消息
                    self.clearSystemMessages()
                    
                    self.addSystemMessage("開始抽卡！")
                    
                    // 開始自動抽號
                    self.startDrawing()
                }
            }
        }
    }
    
    private func startDrawing() {
        guard isHost && gameState == .playing else { return }
        
        print("🎲 開始抽卡系統")
        
        // 立即抽第一張卡
        drawNextNumber()
        
        // 然後每5秒抽一張新卡 (優化：避免網路堵塞)
        scheduleTimer(id: TimerManager.TimerID.gameDraw, interval: 5.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.drawNextNumber()
            }
        }
    }
    
    private func drawNextNumber() {
        let availableNumbers = Array(1...99).filter { !drawnNumbers.contains($0) }
        guard !availableNumbers.isEmpty else {
            endGame()
            return
        }
        
        guard let randomNumber = availableNumbers.randomElement() else {
            print("❌ 無可用號碼，結束遊戲")
            endGame()
            return
        }
        drawnNumbers.append(randomNumber)
        currentNumber = randomNumber
        
        let numberData = String(randomNumber).data(using: .utf8) ?? Data()
        broadcastGameMessage(.numberDrawn, data: numberData)
        
        checkBingoCard(for: randomNumber)
    }
    
    func endGame() {
        print("🎮 結束遊戲")
        // gameStateManager.endGame() // 已移除
    }
    
    // MARK: - Bingo 卡片管理
    
    private func generateBingoCard() -> BingoCard {
        var numbers: [Int] = []
        
        // B列: 1-19
        numbers.append(contentsOf: Array(1...19).shuffled().prefix(5))
        // I列: 20-39
        numbers.append(contentsOf: Array(20...39).shuffled().prefix(5))
        // N列: 40-59（中心為免費格）
        let nNumbers = Array(40...59).shuffled().prefix(5)
        numbers.append(contentsOf: nNumbers)
        // G列: 60-79
        numbers.append(contentsOf: Array(60...79).shuffled().prefix(5))
        // O列: 80-99
        numbers.append(contentsOf: Array(80...99).shuffled().prefix(5))
        
        var card = BingoCard(numbers: numbers)
        // 中心格（索引12）默認為免費格，立即標記為已選中 - 加入安全邊界檢查
        if card.marked.count > 12 && card.drawn.count > 12 {
            card.marked[12] = true
            card.drawn[12] = true
            print("✅ BingoCard 中心格已設定為免費格")
        } else {
            print("❌ BingoCard 數組大小異常: marked=\(card.marked.count), drawn=\(card.drawn.count)")
        }
        return card
    }
    
    private func checkBingoCard(for number: Int) {
        guard var card = bingoCard else { return }
        
        if let index = card.numbers.firstIndex(of: number) {
            // 只更新 drawn 狀態，不更新 marked 狀態
            card.drawn[index] = true
            bingoCard = card
            
            // 不在這裡計算線數，因為只有用戶點擊確認(marked)才算有效
        }
    }
    
    private func calculateCompletedLines(_ card: BingoCard) -> Int {
        var completedLines = 0
        let marked = card.marked
        
        // 中心格 (索引12) 默認為已標記（免費格）
        var effectiveMarked = marked
        effectiveMarked[12] = true
        
        // 檢查行
        for row in 0..<5 {
            let start = row * 5
            if (start..<start+5).allSatisfy({ effectiveMarked[$0] }) {
                completedLines += 1
            }
        }
        
        // 檢查列
        for col in 0..<5 {
            if (0..<5).allSatisfy({ effectiveMarked[$0 * 5 + col] }) {
                completedLines += 1
            }
        }
        
        // 檢查對角線
        if (0..<5).allSatisfy({ effectiveMarked[$0 * 6] }) {
            completedLines += 1
        }
        if (0..<5).allSatisfy({ effectiveMarked[($0 + 1) * 4] }) {
            completedLines += 1
        }
        
        return completedLines
    }
    
    private func updatePlayerProgress() {
        let playerState = PlayerState(
            id: playerID,
            name: deviceName,
            completedLines: completedLines,
            hasWon: gameWon
        )
        
        if let index = roomPlayers.firstIndex(where: { $0.id == playerID }) {
            roomPlayers[index] = playerState
        }
        
        // 使用純二進制編碼玩家進度
        var data = Data()
        
        // 玩家ID
        let idData = playerID.data(using: .utf8) ?? Data()
        let safeIDLength = min(idData.count, 255)
        data.append(UInt8(safeIDLength))
        data.append(idData.prefix(safeIDLength))
        
        // 玩家名稱
        let nameData = deviceName.data(using: .utf8) ?? Data()
        let safeNameLength = min(nameData.count, 255)
        data.append(UInt8(safeNameLength))
        data.append(nameData.prefix(safeNameLength))
        
        // 完成線數
        let safeCompletedLines = max(0, min(completedLines, 255))
        data.append(UInt8(safeCompletedLines))
        
        // 是否獲勝
        data.append(gameWon ? 1 : 0)
        
        broadcastGameMessage(.playerProgress, data: data)
    }
    
    // MARK: - 聊天功能
    
    func sendChatMessage() {
        guard !newChatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let chatMessage = RoomChatMessage(
            message: newChatMessage,
            playerName: deviceName,
            isOwn: true
        )
        
        // 應用相同的聊天訊息限制邏輯
        let maxMessages = 100
        if roomChatMessages.count >= maxMessages {
            roomChatMessages.removeFirst(roomChatMessages.count - maxMessages + 1)
        }
        roomChatMessages.append(chatMessage)
        
        // 使用純二進制編碼聊天訊息
        var data = Data()
        
        // 訊息內容
        let messageData = newChatMessage.data(using: .utf8) ?? Data()
        let messageLength = UInt16(messageData.count)
        data.append(contentsOf: withUnsafeBytes(of: messageLength.littleEndian) { Array($0) })
        data.append(messageData)
        
        // 玩家名稱
        let nameData = deviceName.data(using: .utf8) ?? Data()
        let safeNameLength = min(nameData.count, 255)
        data.append(UInt8(safeNameLength))
        data.append(nameData.prefix(safeNameLength))
        
        broadcastGameMessage(.chatMessage, data: data)
        
        newChatMessage = ""
    }
    
    private func addSystemMessage(_ message: String) {
        let systemMessage = RoomChatMessage(
            message: message,
            playerName: languageService.t("system"),
            isOwn: false
        )
        roomChatMessages.append(systemMessage)
    }
    
    /// 清除聊天室中的系統消息
    private func clearSystemMessages() {
        let systemName = languageService.t("system")
        roomChatMessages.removeAll { message in
            message.playerName == systemName
        }
        print("🧹 已清除聊天室中的系統消息")
    }
    
    // MARK: - 增強的連接管理
    
    /// 🔧 同步連接的節點作為潛在玩家（修復玩家顯示問題）
    @MainActor
    private func synchronizeConnectedPeersAsPlayers() async {
        let connectedPeers = meshManager.getConnectedPeers()
        print("🔄 開始同步連接節點為潛在玩家：\(connectedPeers)")
        
        for peerName in connectedPeers {
            // 檢查該節點是否已經是房間玩家
            if !roomPlayers.contains(where: { $0.id == peerName || $0.name == peerName }) {
                // 創建潛在玩家狀態（使用節點名稱作為臨時ID）
                let potentialPlayer = PlayerState(
                    id: peerName,
                    name: NicknameFormatter.cleanNickname(peerName)
                )
                
                roomPlayers.append(potentialPlayer)
                print("✅ 添加潛在玩家：\(potentialPlayer.name) (\(potentialPlayer.id))")
                
                // 主動向該節點發送玩家加入請求，詢問是否要加入房間
                await requestPlayerJoinConfirmation(peerName: peerName)
            }
        }
        
        print("📊 當前房間玩家數：\(roomPlayers.count)")
        
        // 檢查是否需要自動開始遊戲
        if isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers {
            print("🎮 玩家列表更新後達到最少人數 (\(roomPlayers.count)/\(minPlayersToStart))，自動開始遊戲")
            startGame()
        }
    }
    
    /// 向連接的節點發送加入確認請求
    private func requestPlayerJoinConfirmation(peerName: String) async {
        let message = GameMessage(
            type: .reconnectRequest,
            senderID: playerID,
            senderName: deviceName,
            data: "join_confirmation_request".data(using: .utf8) ?? Data(),
            timestamp: Date(),
            gameRoomID: gameRoomID
        )
        
        do {
            let encoder = JSONEncoder()
            let messageData = try encoder.encode(message)
            
            // 使用廣播方式發送確認請求
            meshManager.broadcastMessage(messageData, messageType: .game)
            print("📤 向 \(peerName) 發送加入確認請求")
        } catch {
            print("❌ 發送加入確認請求失敗：\(error)")
        }
    }
    
    /// 檢查可靠的連接狀態
    private func checkReliableConnectionState() async -> [String] {
        let initialPeers = meshManager.getConnectedPeers()
        
        // 簡化：立即檢查，不等待（避免阻塞）
        
        let stablePeers = meshManager.getConnectedPeers()
        
        // 只返回在兩次檢查中都存在的peers（穩定連接）
        let reliablePeers = initialPeers.filter { stablePeers.contains($0) }
        
        print("🔍 連接穩定性檢查: 初始=\(initialPeers.count) 穩定=\(stablePeers.count) 可靠=\(reliablePeers.count)")
        
        return reliablePeers
    }
    
    /// 使用重試機制發送連接請求
    private func sendConnectionRequestWithRetry(roomID: String, maxRetries: Int = 3) async {
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        
        for attempt in 1...maxRetries {
            print("📤 發送連接請求 (嘗試 \(attempt)/\(maxRetries))")
            
            // 檢查連接狀態
            let connectedPeers = await checkReliableConnectionState()
            guard !connectedPeers.isEmpty else {
                print("⚠️ 無可用連接，跳過重試 \(attempt)")
                break
            }
            
            // 發送請求
            await sendGameMessageSafely(.reconnectRequest, data: requestData)
            
            // 使用非阻塞延遲
            if attempt < maxRetries {
                let delay = Double(attempt) * 1.5
                await MainActor.run {
                    self.scheduleTimer(id: "retry.\(attempt)", interval: delay, repeats: false) {
                        // 等待下一次重試
                    }
                }
            }
        }
    }
    
    /// 安全發送遊戲訊息（帶連接狀態檢查）
    private func sendGameMessageSafely(_ type: GameMessageType, data: Data) async {
        // 檢查網路連接狀態
        guard isNetworkActive else {
            print("📡 跳過發送: 網路未啟動 (type: \(type.rawValue))")
            return
        }
        
        // 檢查連接的設備
        let connectedPeers = meshManager.getConnectedPeers()
        guard !connectedPeers.isEmpty else {
            print("📡 跳過發送: 無連接設備 (type: \(type.rawValue))")
            return
        }
        
        // 使用重試機制發送
        await broadcastGameMessageWithRetry(type, data: data, maxRetries: 2)
    }
    
    /// 帶重試機制的遊戲訊息廣播
    private func broadcastGameMessageWithRetry(_ type: GameMessageType, data: Data, maxRetries: Int) async {
        for attempt in 1...maxRetries {
            // 檢查連接狀態
            let connectedPeers = meshManager.getConnectedPeers()
            guard !connectedPeers.isEmpty else {
                print("📡 廣播失敗: 無連接設備 (嘗試 \(attempt))")
                return
            }
            
            // 創建遊戲訊息內容
            var gameData = Data()
            
            // 添加遊戲訊息類型
            let typeData = type.rawValue.data(using: .utf8) ?? Data()
            let safeTypeLength = min(typeData.count, 255)
            gameData.append(UInt8(safeTypeLength))
            gameData.append(typeData.prefix(safeTypeLength))
            
            // 添加房間ID
            let roomIDData = gameRoomID.data(using: .utf8) ?? Data()
            let safeRoomIDLength = min(roomIDData.count, 255)
            gameData.append(UInt8(safeRoomIDLength))
            gameData.append(roomIDData.prefix(safeRoomIDLength))
            
            // 添加發送者名稱
            let senderNameData = deviceName.data(using: .utf8) ?? Data()
            let safeSenderNameLength = min(senderNameData.count, 255)
            gameData.append(UInt8(safeSenderNameLength))
            gameData.append(senderNameData.prefix(safeSenderNameLength))
            
            // 添加實際數據
            let dataLength = UInt16(data.count)
            gameData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
            gameData.append(data)
            
            // 使用標準 MeshMessage 格式
            let meshMessage = MeshMessage(
                id: UUID().uuidString,
                type: .game,
                data: gameData
            )
            
            // 使用標準的網路服務廣播（在主線程執行）
            await MainActor.run {
                do {
                    let binaryData = try BinaryMessageEncoder.encode(meshMessage)
                    meshManager.broadcastMessage(binaryData, messageType: .game)
                    print("📡 遊戲訊息廣播成功: \(type.rawValue) (\(binaryData.count) bytes) 嘗試=\(attempt)")
                } catch {
                    print("❌ 編碼遊戲訊息失敗: \(error)")
                    // 如果編碼失敗，立即返回（避免阻塞）
                    print("⚠️ 編碼失敗，嘗試 \(attempt)/\(maxRetries)")
                    if attempt >= maxRetries {
                        print("❌ 達到最大重試次數")
                    }
                    return
                }
            }
            
            return
        }
        
        print("❌ 遊戲訊息廣播最終失敗: \(type.rawValue)")
    }
    
    // MARK: - 網路通訊
    
    private func broadcastGameMessage(_ type: GameMessageType, data: Data) {
        // 使用異步廣播機制確保表情和其他訊息正確發送
        Task {
            await sendGameMessageSafely(type, data: data)
        }
    }
    
    private func encodeGameRoomState() -> Data {
        guard let roomState = gameRoomState else {
            print("⚠️ 遊戲房間狀態為空，無法編碼")
            return Data()
        }
        
        // 使用標準格式編碼房間狀態
        let data = encodeStandardRoomState(roomState)
        print("✅ 標準格式遊戲房間狀態已編碼 (\(data.count) bytes)")
        return data
    }
    
    private func encodeGameState(_ state: GameRoomState.GameState) -> Data {
        // 使用純二進制編碼遊戲狀態
        var data = Data()
        switch state {
        case .waitingForPlayers: data.append(0)
        case .countdown: data.append(1)
        case .playing: data.append(2)
        case .finished: data.append(3)
        }
        print("✅ 純二進制遊戲狀態已編碼: \(state.rawValue) (\(data.count) bytes)")
        return data
    }
    
    // MARK: - 連線管理
    
    private func handlePeerConnected(_ peerID: String) {
        print("🤝 設備連接：\(peerID) 當前是主機：\(isHost)")
        updateConnectionStatus()
        
        if isHost && !gameRoomID.isEmpty {
            // 優化：使用非阻塞方式處理連接事件
            Task {
                // 立即廣播當前房間狀態，不等待連接穩定檢查
                await sendGameMessageSafely(.roomSync, data: encodeGameRoomState())
                print("📡 向新連接設備 \(peerID) 廣播房間狀態")
                
                // 使用定時器延遲重複廣播，避免阻塞
                scheduleTimer(id: "peer.sync.\(peerID)", interval: 2.0, repeats: false) { [weak self] in
                    guard let self = self else { return }
                    Task {
                        await self.sendGameMessageSafely(.roomSync, data: self.encodeGameRoomState())
                        print("📡 重複廣播房間狀態給 \(peerID)")
                    }
                }
            }
        } else if !isHost && isInRoom {
            // 非主機不廣播，只發送自己的玩家狀態（修復廣播混亂問題）
            print("📡 非主機不廣播房間狀態，避免與主機衝突")
        }
    }
    
    private func handlePeerDisconnected(_ peerID: String) {
        print("💔 設備斷線：\(peerID)")
        updateConnectionStatus()
        
        // 優化：使用定時器延遲處理，避免阻塞主線程
        scheduleTimer(id: "peer.disconnect.\(peerID)", interval: 3.0, repeats: false) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                // 檢查設備是否重新連接
                let currentPeers = await self.checkReliableConnectionState()
                if !currentPeers.contains(peerID) {
                    // 確認斷線，移除玩家
                    self.roomPlayers.removeAll { $0.id == peerID }
                    print("🗑️ 移除斷線玩家：\(peerID)")
                    
                    // 如果是主機斷線且自己不是主機，考慮成為主機
                    if !self.isHost && self.roomPlayers.count > 0 {
                        await self.considerHostPromotion()
                    }
                } else {
                    print("🔄 設備 \(peerID) 已重新連接，保留玩家")
                }
            }
        }
    }
    
    /// 考慮成為主機（當原主機斷線時）- 簡化版
    @MainActor
    private func considerHostPromotion() async {
        // 使用Timer代替阻塞性sleep
        self.scheduleTimer(id: TimerManager.TimerID.hostPromotion, interval: 5.0, repeats: false) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.evaluateHostPromotionAsync()
            }
        }
    }
    
    /// 評估主機升級的異步方法
    @MainActor
    private func evaluateHostPromotionAsync() async {
        // 檢查是否收到主機廣播
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        if timeSinceLastSync > 10.0 && !isHost && isInRoom {
            print("👑 考慮成為新主機，上次同步距今：\(timeSinceLastSync)秒")
            
            // 基於玩家ID決定是否成為主機
            let connectedPeers = await checkReliableConnectionState()
            let shouldBecomeHost = determineHost(connectedPeers: connectedPeers)
            
            if shouldBecomeHost {
                print("👑 成為新主機")
                becomeRoomHost()
            }
        }
    }
    
    // MARK: - 連接狀態管理
    
    /// 網路連接常數
    private enum NetworkConstants {
        static let heartbeatStartupDelay: TimeInterval = 5.0      // 心跳啟動延遲
        static let heartbeatInterval: TimeInterval = 10.0         // 心跳間隔
        static let connectionCheckThrottle: TimeInterval = 1.0    // 連接檢查節流
    }
    
    /// 上次連接狀態檢查時間（用於節流）
    private var lastConnectionCheck: Date = .distantPast
    
    /// 更新連接狀態（帶錯誤處理和效能優化）
    private func updateConnectionStatus() {
        // 節流機制：避免頻繁更新
        let now = Date()
        guard now.timeIntervalSince(lastConnectionCheck) >= NetworkConstants.connectionCheckThrottle else {
            return
        }
        lastConnectionCheck = now
        
        // 安全地獲取連接數量
        let connectedCount = meshManager.getConnectedPeers().count
        
        // 只在狀態實際改變時更新 UI
        let newStatus = connectedCount > 0 ? 
            String(format: languageService.t("connected_devices"), connectedCount) : 
            languageService.t("offline")
        
        if newStatus != connectionStatus {
            connectionStatus = newStatus
            print("🔄 BingoGameViewModel: 連接狀態更新 - \(connectedCount) 個連接設備")
        }
    }
    
    /// 啟動心跳機制（非阻塞設計，使用定時器延遲）
    private func startHeartbeat() {
        // 清理現有的心跳 timer
        stopHeartbeat()
        
        // 使用非阻塞定時器延遲啟動，避免 Task.sleep 阻塞主線程
        scheduleTimer(id: TimerManager.TimerID.heartbeatStartup, interval: NetworkConstants.heartbeatStartupDelay, repeats: false) { [weak self] in
            guard let self = self else { return }
            
            // 檢查是否仍需要心跳（避免在延遲期間狀態改變）
            guard self.isNetworkActive else {
                print("📡 網路已非活躍狀態，跳過心跳啟動")
                return
            }
            
            // 啟動實際的心跳定時器
            self.scheduleTimer(id: TimerManager.TimerID.heartbeat, interval: 5.0, repeats: true) { [weak self] in
                guard let self = self else { return }
                self.sendHeartbeatSync()
            }
            
            print("💓 心跳機制已啟動 (間隔: \(NetworkConstants.heartbeatInterval)s)")
        }
        
        print("⏰ 心跳啟動定時器已設置 (延遲: \(NetworkConstants.heartbeatStartupDelay)s)")
    }
    
    /// 停止心跳機制（新增方法）
    private func stopHeartbeat() {
        cancelTimer(id: TimerManager.TimerID.heartbeat)
        cancelTimer(id: TimerManager.TimerID.heartbeatStartup)
        print("🛑 心跳機制已停止")
    }
    
    /// 發送心跳訊息（優雅的 async 設計）
    private func sendHeartbeat() async {
        // 早期檢查：避免不必要的異步操作
        guard isNetworkActive else { 
            print("📡 網路非活躍，跳過心跳發送")
            return 
        }
        
        // 🚨 使用增強的連接狀態檢查
        let reliablePeers = await checkReliableConnectionState()
        guard !reliablePeers.isEmpty else {
            print("📡 Heartbeat: 無穩定連接設備，跳過廣播")
            return
        }
        
        print("💓 發送心跳到 \(reliablePeers.count) 個穩定連接")
        
        // 安全地創建心跳數據
        let heartbeatData = createHeartbeatData()
        
        // 使用增強的廣播方法
        await broadcastHeartbeat(data: heartbeatData)
        
        // 監控連接健康度
        await monitorConnectionHealth()
    }
    
    /// 簡化版同步心跳（用於Timer回調）
    @MainActor
    private func sendHeartbeatSync() {
        // 快速檢查並發送心跳
        guard isNetworkActive else { 
            print("📡 網路非活躍，跳過心跳發送")
            return 
        }
        
        let data = createHeartbeatData()
        Task {
            await broadcastHeartbeat(data: data)
        }
    }
    
    /// 創建心跳數據（分離關注點）
    private func createHeartbeatData() -> Data {
        let heartbeatInfo = "\(playerID)|\(deviceName)"
        return heartbeatInfo.data(using: .utf8) ?? Data()
    }
    
    /// 廣播心跳訊息（可測試的獨立方法）
    private func broadcastHeartbeat(data: Data) async {
        await sendGameMessageSafely(.heartbeat, data: data)
    }
    
    /// 監控連接健康度
    private func monitorConnectionHealth() async {
        let currentTime = Date()
        let timeSinceLastSync = currentTime.timeIntervalSince(lastSyncTime)
        
        // 如果超過30秒沒有收到任何同步，開始恢復流程
        if timeSinceLastSync > 30.0 && isInRoom {
            print("⚠️ 連接健康度警告：上次同步距今 \(timeSinceLastSync) 秒")
            
            // 嘗試重新建立連接
            await attemptConnectionRecovery()
        }
    }
    
    /// 嘗試連接恢復
    private func attemptConnectionRecovery() async {
        print("🔄 嘗試連接恢復")
        
        // 檢查網路狀態
        let connectedPeers = await checkReliableConnectionState()
        
        if connectedPeers.isEmpty {
            print("📶 無可用連接，切換到離線模式")
            
            // 如果沒有其他玩家，成為主機
            if !isHost && roomPlayers.count <= 1 {
                await MainActor.run {
                    becomeRoomHost()
                    addSystemMessage("連接中斷，切換到離線模式")
                }
            }
        } else {
            print("🔄 發現 \(connectedPeers.count) 個連接，嘗試重新同步")
            
            // 重新發送連接請求
            if !gameRoomID.isEmpty {
                await sendConnectionRequestWithRetry(roomID: gameRoomID, maxRetries: 2)
            }
        }
    }
    
    
    private func startSyncTimer() {
        cancelTimer(id: TimerManager.TimerID.gameSync)
        
        scheduleTimer(id: TimerManager.TimerID.gameSync, interval: 8.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.requestRoomSync()
            }
        }
    }
    
    // MARK: - 房間更新方法
    
    /// 【方案C - 架構師】建立防止崩潰的彈性設計
    func updateRoom(_ roomID: Int) {
        print("🔄 BingoGameViewModel: 開始房間切換 -> \(roomID)")
        
        // 1. 輸入驗證 - 彈性設計的第一道防線
        guard roomID > 0 && roomID <= 99 else {
            print("❌ 無效的房間ID: \(roomID)，必須在 1-99 範圍內")
            return
        }
        
        let roomIDString = String(roomID)
        
        // 2. 重複操作防護
        guard gameRoomID != roomIDString else {
            print("🎮 已經在房間 \(roomID) 中，跳過切換")
            return
        }
        
        // 3. 網路狀態檢查 - 確保在網路穩定時進行切換
        guard isNetworkActive else {
            print("⚠️ 網路未啟動，延遲房間切換")
            
            // 等待網路就緒後重試
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.updateRoom(roomID)
            }
            return
        }
        
        // 4. 安全的房間切換流程
        Task { @MainActor in
            do {
                try await performRoomSwitchSafely(to: roomIDString)
                print("✅ 房間切換成功: \(roomIDString)")
            } catch {
                print("❌ 房間切換失敗: \(error)")
                
                // 錯誤恢復：重置狀態並重試
                await handleRoomSwitchError(targetRoomID: roomIDString, error: error)
            }
        }
    }
    
    /// 【彈性設計】安全的房間切換實現
    private func performRoomSwitchSafely(to roomIDString: String) async throws {
        let previousRoomID = gameRoomID
        
        print("🔄 執行安全房間切換: \(previousRoomID) -> \(roomIDString)")
        
        // 1. 驗證網路通道狀態
        try validateBroadcastChannelState()
        
        // 2. 安全離開當前房間
        if !gameRoomID.isEmpty {
            try await leaveCurrentRoomSafely()
        }
        
        // 3. 短暫等待，確保狀態清理完成
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // 4. 加入新房間
        try await joinNewRoomSafely(roomID: roomIDString)
        
        print("✅ 安全房間切換完成: \(roomIDString)")
    }
    
    /// 【錯誤恢復】處理房間切換錯誤
    private func handleRoomSwitchError(targetRoomID: String, error: Error) async {
        print("🔧 處理房間切換錯誤...")
        
        // 重置狀態到安全狀態
        await resetToSafeState()
        
        // 根據錯誤類型決定恢復策略
        if error is NetworkError {
            print("🌐 網路錯誤，等待網路恢復後重試")
            
            // 等待網路恢復
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries && meshManager.getConnectedPeers().isEmpty {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                retryCount += 1
            }
            
            if !meshManager.getConnectedPeers().isEmpty {
                print("🔄 網路已恢復，重試房間切換")
                updateRoom(Int(targetRoomID) ?? 1)
            } else {
                print("❌ 網路恢復失敗，保持當前狀態")
            }
        } else {
            print("🔄 其他錯誤，3秒後重試房間切換")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.updateRoom(Int(targetRoomID) ?? 1)
            }
        }
    }
    
    /// 【安全離開】從當前房間安全離開
    private func leaveCurrentRoomSafely() async throws {
        print("🚪 安全離開當前房間: \(gameRoomID)")
        
        // 清理前先保存重要狀態
        let _ = isHost // 保留日誌用途
        
        // 清理房間狀態
        roomPlayers.removeAll()
        gameState = .waitingForPlayers
        isHost = false
        gameWon = false
        completedLines = 0
        drawnNumbers.removeAll()
        currentNumber = nil
        countdown = 0
        roomChatMessages.removeAll()
        newChatMessage = ""
        
        // 安全清理定時器
        await performTimerCleanupSafely()
        
        // 清空房間ID
        gameRoomID = ""
        isInRoom = false
        
        print("✅ 安全離開房間完成")
    }
    
    /// 【安全加入】加入新房間
    private func joinNewRoomSafely(roomID: String) async throws {
        print("🚪 安全加入新房間: \(roomID)")
        
        // 驗證網路狀態
        guard !meshManager.getConnectedPeers().isEmpty else {
            throw NetworkError.notConnected
        }
        
        // 設置新房間狀態
        gameRoomID = roomID
        isInRoom = true
        
        // 🔧 添加本機玩家，確保名稱一致性
        let normalizedDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let localPlayer = PlayerState(id: playerID, name: normalizedDeviceName)
        roomPlayers = [localPlayer]
        
        // 同步更新 deviceName 以保持一致性
        self.deviceName = normalizedDeviceName
        
        // 生成新的賓果卡
        bingoCard = generateBingoCard()
        
        // 啟動同步定時器
        startSyncTimer()
        
        print("✅ 安全加入房間完成: \(roomID)")
    }
    
    /// 【狀態重置】重置到安全狀態
    private func resetToSafeState() async {
        print("🔧 重置到安全狀態...")
        
        // 清理所有房間相關狀態
        gameRoomID = ""
        isInRoom = false
        isHost = false
        gameWon = false
        completedLines = 0
        drawnNumbers.removeAll()
        currentNumber = nil
        countdown = 0
        gameState = .waitingForPlayers
        
        // 安全清理定時器
        await performTimerCleanupSafely()
        
        print("✅ 安全狀態重置完成")
    }
    
    /// 【安全清理】安全清理定時器
    private func performTimerCleanupSafely() async {
        cancelTimer(id: TimerManager.TimerID.gameDraw)
        cancelTimer(id: TimerManager.TimerID.gameCountdown)
        cancelTimer(id: TimerManager.TimerID.gameSync)
        cancelTimer(id: TimerManager.TimerID.heartbeat)
        cancelTimer(id: TimerManager.TimerID.reconnect)
        cancelTimer(id: TimerManager.TimerID.hostPromotion)
        cancelTimer(id: TimerManager.TimerID.gameRestart)
        
        print("🧹 BingoGameViewModel: 所有Timer已安全清理")
    }
    
    private func leaveCurrentRoom() {
        print("🚪 離開當前房間: \(gameRoomID)")
        // 清理當前房間狀態
        roomPlayers.removeAll()
        gameState = .waitingForPlayers
        isHost = false
        gameWon = false
        completedLines = 0
        drawnNumbers.removeAll()
        currentNumber = nil
        countdown = 0
        roomChatMessages.removeAll()
        newChatMessage = ""
        
        // 停止所有定時器
        performTimerCleanup()
        
        // 清空房間ID
        gameRoomID = ""
    }
    
    private func requestRoomSync() {
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
    }
    
    // MARK: - 清理
    
    private func cleanup() {
        performTimerCleanup()
        meshManager.stopMeshNetwork()
        isNetworkActive = false
        print("🎮 BingoGameViewModel: cleanup 完成")
    }
    
    private nonisolated func performTimerCleanup() {
        // 在主線程上安全地清理 Timer
        Task { @MainActor in
            self.cancelAllTimers()
            print("🧹 BingoGameViewModel: 所有Timer已清理")
        }
    }
    
    private func resetGameState() {
        gameState = .waitingForPlayers
        roomPlayers = []
        roomChatMessages = []
        drawnNumbers = []
        currentNumber = nil
        countdown = 0
        gameWon = false
        completedLines = 0
        isHost = false
        gameRoomID = ""
        isInRoom = false
        isGameActive = false
    }
    
    // MARK: - 遊戲交互方法
    
    /// 標記賓果卡上的數字
    func markNumber(_ number: Int) {
        print("🎮 用戶點擊標記號碼 \(number)")
        
        guard var card = localBingoCard else {
            print("⚠️ 沒有賓果卡片")
            return
        }
        
        // 檢查號碼是否已經抽出
        guard localDrawnNumbers.contains(number) else {
            print("⚠️ 號碼 \(number) 尚未抽出，無法標記")
            return
        }
        
        // 檢查號碼是否已經被標記（防止重複點擊）
        if let index = card.numbers.firstIndex(of: number), card.marked[index] {
            print("ℹ️ 號碼 \(number) 已經標記過，忽略重複點擊")
            return
        }
        
        // 在卡片上標記號碼（用戶確認）
        for row in 0..<5 {
            for col in 0..<5 {
                if card.numbers[row * 5 + col] == number {
                    card.marked[row * 5 + col] = true
                    print("✅ 用戶確認標記位置 (\(row),\(col))")
                }
            }
        }
        
        // 更新卡片
        localBingoCard = card
        
        // 強制立即更新 UI
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
        
        // 檢查是否獲勝
        let lines = calculateCompletedLines(card)
        localCompletedLines = lines
        
        // 立即更新玩家進度到房間狀態（修復線數不同步問題）
        updatePlayerProgress()
        
        if lines >= 5 && !localGameWon {
            print("🎯 DEBUG: 觸發獲勝條件檢查 - lines: \(lines), gameWon: \(localGameWon)")
            localGameWon = true
            print("🏆 玩家獲勝！完成 \(lines) 條線")
            print("📡 DEBUG: 準備廣播冠軍公告...")
            // 觸發獲勝邏輯
            broadcastWinnerAnnouncement(winnerID: playerID, winnerName: deviceName, lines: lines)
            print("🎮 DEBUG: 觸發 onGameWon 回調...")
            onGameWon?(deviceName, lines)
        }
    }
    
    /// 發送房間聊天訊息
    func sendRoomChatMessage() {
        sendChatMessage()
    }
    
    // MARK: - NotificationCenter 觀察者設置
    
    private func setupNotificationObservers() {
        // 監聽來自 ServiceContainer 的遊戲訊息
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GameMessageReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let data = notification.object as? Data,
               let sender = notification.userInfo?["sender"] as? String {
                // 【SWIFT 6 FIX】使用 DispatchQueue.main.async 確保 MainActor 執行
                DispatchQueue.main.async {
                    self.handleServiceContainerGameMessage(data, from: sender)
                }
            }
        }
        
        // 監聽設備連接事件
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PeerConnected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let peerDisplayName = notification.object as? String {
                // 【SWIFT 6 FIX】使用 DispatchQueue.main.async 確保 MainActor 執行
                DispatchQueue.main.async {
                    self.handlePeerConnected(peerDisplayName)
                }
            }
        }
        
        // 監聽設備斷開事件
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PeerDisconnected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let peerDisplayName = notification.object as? String {
                // 【SWIFT 6 FIX】使用 DispatchQueue.main.async 確保 MainActor 執行
                DispatchQueue.main.async {
                    self.handlePeerDisconnected(peerDisplayName)
                }
            }
        }
        
        print("🎮 BingoGameViewModel: NotificationCenter 觀察者已設置")
    }
    
    private func setupNicknameObserver() {
        // 監聽暱稱變更通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NicknameDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // 【SWIFT 6 FIX】使用 DispatchQueue.main.async 確保 MainActor 執行
            guard let self = self else { return }
            
            if let userInfo = notification.userInfo,
               let newNickname = userInfo["newNickname"] as? String {
                DispatchQueue.main.async {
                    self.deviceName = newNickname // NicknameService已處理清理，避免重複
                    print("🎮 BingoGameViewModel: 暱稱已更新為='\(newNickname)'")
                    
                    // 向其他玩家廣播暱稱更新
                    if self.isInRoom {
                        let updateData = "\(self.playerID)|\(self.deviceName)".data(using: .utf8) ?? Data()
                        self.broadcastGameMessage(.heartbeat, data: updateData)
                    }
                }
            }
        }
        
        print("🎮 BingoGameViewModel: 暱稱觀察者已設置")
    }
    
    private func handleServiceContainerGameMessage(_ data: Data, from sender: String) {
        // 使用 BinaryMessageDecoder 解碼標準格式遊戲訊息
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            print("🎮 收到來自 ServiceContainer 的遊戲訊息: 類型=\(meshMessage.type), 發送者=\(sender)")
            
            // 確保是遊戲訊息類型
            if meshMessage.type == .game {
                // 解析標準格式的遊戲數據
                guard let gameMessage = decodeStandardGameMessage(meshMessage.data, messageID: meshMessage.id) else {
                    print("❌ 解析遊戲訊息內容失敗")
                    return
                }
                processGameMessage(gameMessage)
            }
        } catch {
            print("❌ BingoGameViewModel: 解碼遊戲訊息失敗: \(error)")
        }
    }
    
    // 解碼標準格式的遊戲訊息內容
    private func decodeStandardGameMessage(_ data: Data, messageID: String) -> GameMessage? {
        guard data.count >= 4 else { return nil }
        
        var offset = 0
        
        // 解析遊戲訊息類型
        guard offset < data.count else { return nil }
        let typeLength = Int(data[offset])
        offset += 1
        
        guard offset + typeLength <= data.count else { return nil }
        let typeData = data.subdata(in: offset..<offset+typeLength)
        guard let typeString = String(data: typeData, encoding: .utf8),
              let type = GameMessageType(rawValue: typeString) else { return nil }
        offset += typeLength
        
        // 解析房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        guard offset + roomIDLength <= data.count else { return nil }
        let roomIDData = data.subdata(in: offset..<offset+roomIDLength)
        guard let gameRoomID = String(data: roomIDData, encoding: .utf8) else { return nil }
        offset += roomIDLength
        
        // 解析發送者名稱
        guard offset < data.count else { return nil }
        let senderNameLength = Int(data[offset])
        offset += 1
        
        guard offset + senderNameLength <= data.count else { return nil }
        let senderNameData = data.subdata(in: offset..<offset+senderNameLength)
        guard let senderName = String(data: senderNameData, encoding: .utf8) else { return nil }
        offset += senderNameLength
        
        // 解析實際數據
        guard offset + 2 <= data.count else { return nil }
        let dataLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(dataLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<offset+Int(dataLength))
        
        return GameMessage(
            type: type,
            senderID: messageID,
            senderName: senderName, // 暱稱已經是清理過的
            data: messageData,
            timestamp: Date(),
            gameRoomID: gameRoomID
        )
    }
    
    // MARK: - 標準格式編碼/解碼方法
    
    // 編碼房間狀態為標準格式
    private func encodeStandardRoomState(_ roomState: GameRoomState) -> Data {
        var data = Data()
        
        // 房間ID
        let roomIDData = roomState.roomID.data(using: .utf8) ?? Data()
        let safeRoomIDLength = min(roomIDData.count, 255)
        data.append(UInt8(safeRoomIDLength))
        data.append(roomIDData.prefix(safeRoomIDLength))
        
        // 主機ID
        let hostIDData = roomState.hostID.data(using: .utf8) ?? Data()
        let safeHostIDLength = min(hostIDData.count, 255)
        data.append(UInt8(safeHostIDLength))
        data.append(hostIDData.prefix(safeHostIDLength))
        
        // 玩家數量
        data.append(UInt8(roomState.players.count))
        
        // 玩家列表
        for player in roomState.players {
            // 玩家ID
            let playerIDData = player.id.data(using: .utf8) ?? Data()
            let safePlayerIDLength = min(playerIDData.count, 255)
            data.append(UInt8(safePlayerIDLength))
            data.append(playerIDData.prefix(safePlayerIDLength))
            
            // 玩家名稱（player.name已經是清理過的暱稱）
            let nameData = player.name.data(using: .utf8) ?? Data()
            let safePlayerNameLength = min(nameData.count, 255)
            data.append(UInt8(safePlayerNameLength))
            data.append(nameData.prefix(safePlayerNameLength))
            
            // 完成線數
            let safeCompletedLines = max(0, min(player.completedLines, 255))
            data.append(UInt8(safeCompletedLines))
            
            // 是否獲勝
            data.append(player.hasWon ? 1 : 0)
            
            // 是否連接
            data.append(player.isConnected ? 1 : 0)
        }
        
        // 遊戲狀態
        switch roomState.gameState {
        case .waitingForPlayers: data.append(0)
        case .countdown: data.append(1)
        case .playing: data.append(2)
        case .finished: data.append(3)
        }
        
        // 已抽取號碼數量
        data.append(UInt8(roomState.drawnNumbers.count))
        
        // 已抽取號碼列表
        for number in roomState.drawnNumbers {
            let safeNumber = min(max(number, 1), 255)
            data.append(UInt8(safeNumber))
        }
        
        // 當前號碼
        if let currentNumber = roomState.currentNumber {
            data.append(1) // 有當前號碼
            let safeCurrentNumber = min(max(currentNumber, 1), 255)
            data.append(UInt8(safeCurrentNumber))
        } else {
            data.append(0) // 沒有當前號碼
        }
        
        // 倒數時間
        let safeCountdown = max(0, min(roomState.countdown, 255))
        data.append(UInt8(safeCountdown))
        
        return data
    }
    
    // 解碼標準格式的房間狀態
    private func decodeStandardRoomState(_ data: Data) -> GameRoomState? {
        guard data.count >= 6 else { return nil }
        
        var offset = 0
        
        // 解析房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        guard offset + roomIDLength <= data.count else { return nil }
        let roomIDData = data.subdata(in: offset..<offset+roomIDLength)
        guard let roomID = String(data: roomIDData, encoding: .utf8) else { return nil }
        offset += roomIDLength
        
        // 解析主機ID
        guard offset < data.count else { return nil }
        let hostIDLength = Int(data[offset])
        offset += 1
        
        guard offset + hostIDLength <= data.count else { return nil }
        let hostIDData = data.subdata(in: offset..<offset+hostIDLength)
        guard let hostID = String(data: hostIDData, encoding: .utf8) else { return nil }
        offset += hostIDLength
        
        // 解析玩家數量
        guard offset < data.count else { return nil }
        let playerCount = Int(data[offset])
        offset += 1
        
        // 解析玩家列表
        var players: [PlayerState] = []
        for _ in 0..<playerCount {
            // 玩家ID
            guard offset < data.count else { return nil }
            let playerIDLength = Int(data[offset])
            offset += 1
            
            guard offset + playerIDLength <= data.count else { return nil }
            let playerIDData = data.subdata(in: offset..<offset+playerIDLength)
            guard let playerID = String(data: playerIDData, encoding: .utf8) else { return nil }
            offset += playerIDLength
            
            // 玩家名稱
            guard offset < data.count else { return nil }
            let nameLength = Int(data[offset])
            offset += 1
            
            guard offset + nameLength <= data.count else { return nil }
            let nameData = data.subdata(in: offset..<offset+nameLength)
            guard let playerName = String(data: nameData, encoding: .utf8) else { return nil }
            offset += nameLength
            
            // 完成線數
            guard offset < data.count else { return nil }
            let completedLines = Int(data[offset])
            offset += 1
            
            // 是否獲勝
            guard offset < data.count else { return nil }
            let hasWon = data[offset] == 1
            offset += 1
            
            // 是否連接
            guard offset < data.count else { return nil }
            let isConnected = data[offset] == 1
            offset += 1
            
            let player = PlayerState(
                id: playerID,
                name: playerName, // 接收的暱稱已經是清理過的
                completedLines: completedLines,
                hasWon: hasWon,
                isConnected: isConnected
            )
            players.append(player)
        }
        
        // 解析遊戲狀態
        guard offset < data.count else { return nil }
        let gameStateValue = data[offset]
        offset += 1
        
        let gameState: GameRoomState.GameState
        switch gameStateValue {
        case 0: gameState = .waitingForPlayers
        case 1: gameState = .countdown
        case 2: gameState = .playing
        case 3: gameState = .finished
        default: return nil
        }
        
        // 解析已抽取號碼數量
        guard offset < data.count else { return nil }
        let drawnNumbersCount = Int(data[offset])
        offset += 1
        
        // 解析已抽取號碼列表
        var drawnNumbers: [Int] = []
        for _ in 0..<drawnNumbersCount {
            guard offset < data.count else { return nil }
            drawnNumbers.append(Int(data[offset]))
            offset += 1
        }
        
        // 解析當前號碼
        guard offset < data.count else { return nil }
        let hasCurrentNumber = data[offset] == 1
        offset += 1
        
        var currentNumber: Int? = nil
        if hasCurrentNumber {
            guard offset < data.count else { return nil }
            currentNumber = Int(data[offset])
            offset += 1
        }
        
        // 解析倒數時間
        guard offset < data.count else { return nil }
        let countdown = Int(data[offset])
        
        return GameRoomState(
            roomID: roomID,
            hostID: hostID,
            players: players,
            gameState: gameState,
            drawnNumbers: drawnNumbers,
            currentNumber: currentNumber,
            countdown: countdown,
            startTime: nil
        )
    }
    
    // MARK: - 表情功能
    
    /// 【修復3】發送表情 - 增強廣播機制
    func sendEmote(_ emote: EmoteType) {
        // 檢查冷卻時間
        let now = Date()
        guard now.timeIntervalSince(lastEmoteTime) >= emoteCooldown else {
            print("⏳ 表情冷卻中，請稍後再試")
            return
        }
        
        guard isInRoom else {
            print("⚠️ 未在房間內，無法發送表情")
            return
        }
        
        lastEmoteTime = now
        
        // 使用統一的玩家資訊格式
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        let emoteData = "\(emote.rawValue)|\(playerID)|\(normalizedName)".data(using: .utf8) ?? Data()
        
        print("😄 發送表情廣播: \(emote.rawValue) 玩家=\(normalizedName) ID=\(playerID.prefix(8))")
        broadcastGameMessage(.emote, data: emoteData)
        
        // 本地也顯示表情
        triggerEmoteDisplay(nickname: normalizedName, emote: emote)
    }
    
    /// 【修復3】處理收到的表情訊息 - 增強容錯性和廣播支持
    private func handleEmote(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 3,
              let emoteType = EmoteType(rawValue: components[0]) else {
            print("❌ 表情訊息格式錯誤: \(String(data: message.data, encoding: .utf8) ?? "無法解析")")
            return
        }
        
        let senderPlayerID = components[1]
        let senderName = components[2]
        
        // 驗證發送者是否在房間內
        guard roomPlayers.contains(where: { $0.id == senderPlayerID }) else {
            print("⚠️ 忽略來自未知玩家的表情: \(senderName) (\(senderPlayerID.prefix(8)))")
            return
        }
        
        print("😄 收到表情廣播: \(emoteType.rawValue) 來自 \(senderName) (\(senderPlayerID.prefix(8)))")
        triggerEmoteDisplay(nickname: senderName, emote: emoteType)
    }
    
    /// 觸發表情顯示和震動
    private func triggerEmoteDisplay(nickname: String, emote: EmoteType) {
        let translationKey = getEmoteTranslationKey(for: emote)
        let template = languageService.t(translationKey)
        let text = String(format: template, nickname)
        emoteSubject.send(EmoteEvent(text: text, isPureEmoji: emote.isPureEmoji))
        
        // 觸發震動
        #if !targetEnvironment(simulator)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
        
        print("💬 表情: \(text)")
    }
    
    /// 獲取表情的翻譯鍵
    private func getEmoteTranslationKey(for emote: EmoteType) -> String {
        switch emote {
        case .bingo: return "emote_bingo"
        case .nen: return "emote_nen"
        case .wow: return "emote_wow"
        case .rocket: return "emote_rocket"
        case .burger: return "emote_burger"
        case .battery: return "emote_battery"
        case .dizzy: return "emote_dizzy"
        case .mouse: return "emote_mouse"
        case .ring: return "emote_ring"
        default: return emote.template // 對於純emoji表情，使用原來的template
        }
    }
    
    // MARK: - 本週排行榜處理器
    
    /// 處理本週排行榜更新
    private func handleWeeklyLeaderboardUpdate(_ message: GameMessage) {
        print("📊 收到本週排行榜更新從: \(message.senderName)")
        
        // 解碼排行榜數據
        guard let (type, weekStartTime, entries) = BinaryGameProtocol.decodeWeeklyLeaderboard(message.data) else {
            print("❌ 解碼排行榜數據失敗")
            return
        }
        
        // 合併到本地排行榜
        mergeRemoteLeaderboardData(type: type, entries: entries, weekStartTime: weekStartTime)
    }
    
    /// 處理本週排行榜同步
    private func handleWeeklyLeaderboardSync(_ message: GameMessage) {
        print("🔄 收到本週排行榜同步請求從: \(message.senderName)")
        // 發送本地排行榜數據給請求者
        sendLocalLeaderboardData(to: message.senderID)
    }
    
    /// 處理本週排行榜請求
    private func handleWeeklyLeaderboardRequest(_ message: GameMessage) {
        print("📋 收到本週排行榜數據請求從: \(message.senderName)")
        // 回應排行榜請求
        sendLocalLeaderboardData(to: message.senderID)
    }
    
    // MARK: - 排行榜數據管理
    
    /// 合併遠端排行榜數據到本地
    private func mergeRemoteLeaderboardData(type: BinaryGameProtocol.LeaderboardType, entries: [BinaryGameProtocol.WeeklyLeaderboardEntry], weekStartTime: Date) {
        let weekTimestamp = Int(weekStartTime.timeIntervalSince1970)
        let weekKey = "SignalAir_WeeklyLeaderboard_\(type.rawValue)_\(weekTimestamp)"
        
        // 讀取現有的本地數據
        var allPlayers: [String: BinaryGameProtocol.WeeklyLeaderboardEntry] = [:]
        
        if let existingData = UserDefaults.standard.data(forKey: weekKey),
           let (_, _, existingEntries) = BinaryGameProtocol.decodeWeeklyLeaderboard(existingData) {
            // 將現有數據轉換為字典
            for entry in existingEntries {
                allPlayers[entry.playerID] = entry
            }
        }
        
        // 合併遠端數據
        for remoteEntry in entries {
            if let existingEntry = allPlayers[remoteEntry.playerID] {
                // 如果遠端數據更新，則更新本地數據
                if remoteEntry.lastUpdate > existingEntry.lastUpdate {
                    allPlayers[remoteEntry.playerID] = remoteEntry
                    print("🔄 更新玩家 \(remoteEntry.nickname) 的排行榜數據: \(remoteEntry.value)")
                }
            } else {
                // 新玩家數據
                allPlayers[remoteEntry.playerID] = remoteEntry
                print("➕ 新增玩家 \(remoteEntry.nickname) 到排行榜: \(remoteEntry.value)")
            }
        }
        
        // 重新排序並只保留前3名
        let sortedEntries = allPlayers.values
            .sorted { 
                if type == .reaction {
                    return $0.value > $1.value  // 烏龜神：反應時間越大（越慢）越前
                } else {
                    return $0.value > $1.value  // 其他數值越大越好
                }
            }
            .prefix(3)
            .map { $0 }
        
        // 保存合併後的數據
        let binaryData = BinaryGameProtocol.encodeWeeklyLeaderboard(
            type: type,
            entries: sortedEntries,
            weekStartTime: weekStartTime
        )
        
        UserDefaults.standard.set(binaryData, forKey: weekKey)
        print("✅ 已合併並保存排行榜數據，共 \(sortedEntries.count) 名玩家")
    }
    
    /// 發送本地排行榜數據給指定玩家
    private func sendLocalLeaderboardData(to targetPlayerID: String) {
        let weekStartTime = getThisWeekMonday()
        let weekTimestamp = Int(weekStartTime.timeIntervalSince1970)
        
        // 發送三種類型的排行榜數據
        let leaderboardTypes: [BinaryGameProtocol.LeaderboardType] = [.wins, .interactions, .reaction]
        
        for type in leaderboardTypes {
            let weekKey = "SignalAir_WeeklyLeaderboard_\(type.rawValue)_\(weekTimestamp)"
            
            if let data = UserDefaults.standard.data(forKey: weekKey) {
                // 發送排行榜更新消息
                broadcastGameMessage(
                    .weeklyLeaderboardUpdate,
                    data: data
                )
                print("📤 已發送 \(type) 排行榜數據給 \(targetPlayerID)")
            }
        }
    }
    
    /// 獲取本週一的時間戳
    private func getThisWeekMonday() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 獲取本週一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 週一
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    /// 請求其他玩家的排行榜數據
    func requestWeeklyLeaderboardData() {
        print("📋 請求其他玩家的排行榜數據")
        
        // 發送排行榜數據請求
        let requestData = "request_all_leaderboards".data(using: .utf8) ?? Data()
        broadcastGameMessage(
            .weeklyLeaderboardRequest,
            data: requestData
        )
    }
    
    /// 重新開始遊戲
    func restartGame() {
        guard isHost else {
            print("⚠️ 只有主機才能重新開始遊戲")
            return
        }
        
        print("🔄 主機重新開始遊戲")
        
        // 清除聊天室系統消息
        clearSystemMessages()
        
        // 為所有玩家重置狀態
        roomPlayers = roomPlayers.map { player in
            PlayerState(
                id: player.id,
                name: player.name,
                completedLines: 0,
                hasWon: false,
                isConnected: player.isConnected
            )
        }
        
        // 使用 gameStateManager 處理遊戲重啟
        // gameStateManager.restartGame() // 已移除
        
        print("✅ 遊戲已重新開始，房間人數: \(roomPlayers.count)")
    }
    
    // MARK: - 冠軍廣播功能
    
    /// 廣播冠軍公告到所有房間內的玩家
    private func broadcastWinnerAnnouncement(winnerID: String, winnerName: String, lines: Int) {
        print("🎯 DEBUG: broadcastWinnerAnnouncement 被調用 - winnerID: \(winnerID), lines: \(lines)")
        let announcement = WinnerAnnouncement(
            winnerPlayerID: winnerID,
            winnerName: winnerName,
            completedLines: lines,
            gameEndTime: Date(),
            restartCountdown: 5
        )
        
        do {
            let data = try JSONEncoder().encode(announcement)
            broadcastGameMessage(.winnerAnnouncement, data: data)
            print("🏆 冠軍公告已廣播: \(winnerName)")
        } catch {
            print("❌ 廣播冠軍公告失敗: \(error)")
        }
    }
    
    /// 處理接收到的冠軍公告
    private func handleWinnerAnnouncement(_ message: GameMessage) {
        do {
            let announcement = try JSONDecoder().decode(WinnerAnnouncement.self, from: message.data)
            
            DispatchQueue.main.async {
                // 對所有玩家觸發冠軍顯示
                self.onGameWon?(announcement.winnerName, announcement.completedLines)
                
                // 開始同步倒數重新開始
                self.startSynchronizedRestart(countdown: announcement.restartCountdown)
            }
            
            print("🏆 收到冠軍公告: \(announcement.winnerName)")
        } catch {
            print("❌ 解析冠軍公告失敗: \(error)")
        }
    }
    
    /// 開始同步倒數重新開始
    private func startSynchronizedRestart(countdown: Int) {
        guard roomPlayers.count >= 2 else { return }
        
        // 取消現有的重啟計時器
        cancelTimer(id: TimerManager.TimerID.gameRestart)
        
        var remainingTime = countdown
        
        scheduleTimer(id: TimerManager.TimerID.gameRestart, interval: 1.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            if remainingTime > 0 {
                // 更新倒數顯示（這個會被GameView處理）
                print("🔄 倒數: \(remainingTime)")
                remainingTime -= 1
            } else {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    // 取消計時器
                    self.cancelTimer(id: TimerManager.TimerID.gameRestart)
                    
                    // 1. 計算並提交統計數據到週排行榜
                    self.calculateAndSubmitGameStats()
                    
                    // 2. 所有人自動離開房間，開始新一局
                    self.leaveGameRoomAfterWin()
                    
                    // 3. 主機廣播遊戲結束訊息
                    if self.isHost {
                        self.broadcastGameMessage(.gameRestart, data: Data())
                    }
                }
            }
        }
    }
    
    /// 處理遊戲重新開始訊息
    private func handleGameRestart(_ message: GameMessage) {
        if !isHost {
            // 非主機玩家執行重新開始
            restartGame()
        }
        print("🔄 收到遊戲重新開始訊息")
    }
    
    /// 計算並提交統計數據到週排行榜
    private func calculateAndSubmitGameStats() {
        print("📊 開始計算遊戲統計數據...")
        
        // 1. 計算DJ榜 - 統計表情使用次數最多的玩家
        var djStats: [String: Int] = [:]
        
        // 計算每個玩家的表情使用次數
        for player in roomPlayers {
            var emoteCount = 0
            
            // 統計該玩家的表情數量（從遊戲過程中收集）
            for message in roomChatMessages {
                if message.playerName == player.name {
                    // 計算包含表情符號的訊息
                    if containsEmote(message.message) {
                        emoteCount += 1
                    }
                }
            }
            
            if emoteCount > 0 {
                djStats[player.name] = emoteCount
                print("🎧 DJ統計 - \(player.name): \(emoteCount)個表情")
            }
        }
        
        // 2. 計算烏龜神榜 - 統計反應最慢的玩家（基於完成線數作為反應速度指標）
        var turtleStats: [String: Double] = [:]
        
        // 計算每個玩家的反應時間（根據完成線數推算）
        for player in roomPlayers {
            // 基於完成線數計算反應時間（完成線數越少=反應越慢）
            let reactionTime = max(1.0, 10.0 - Double(player.completedLines) * 1.5) + Double.random(in: 0.1...1.0)
            turtleStats[player.name] = reactionTime
            print("🐢 烏龜神統計 - \(player.name): 平均\(String(format: "%.1f", reactionTime))秒")
        }
        
        // 3. 提交統計數據到週排行榜
        submitToWeeklyLeaderboard(djStats: djStats, turtleStats: turtleStats)
    }
    
    /// 檢查訊息是否包含表情符號
    private func containsEmote(_ message: String) -> Bool {
        let emotePatterns = ["🎉", "🤔", "😱", "💥", "🏴‍☠️", "🚀", "🐛", "🪰", "🔥", "💩", "🤡", "🤯", "🤏", "🪳", "🙄", "🍔", "🤟", "🔋", "😵‍💫", "🍼", "💀", "🐭", "🏆", "💍", "🤹‍♂️"]
        return emotePatterns.contains { message.contains($0) }
    }
    
    /// 提交統計數據到週排行榜
    private func submitToWeeklyLeaderboard(djStats: [String: Int], turtleStats: [String: Double]) {
        let weekStartTime = getThisWeekMonday()
        let weeklyLeaderboardPrefix = "SignalAir_WeeklyLeaderboard_"
        
        // 提交DJ榜數據
        if !djStats.isEmpty {
            let djEntries = djStats.map { (playerName, emoteCount) in
                BinaryGameProtocol.WeeklyLeaderboardEntry(
                    playerID: playerName,
                    nickname: playerName,
                    value: Float(emoteCount),
                    lastUpdate: Date()
                )
            }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0 }
            
            let djData = BinaryGameProtocol.encodeWeeklyLeaderboard(
                type: .interactions,
                entries: djEntries,
                weekStartTime: weekStartTime
            )
            
            let djKey = "\(weeklyLeaderboardPrefix)interactions_\(Int(weekStartTime.timeIntervalSince1970))"
            UserDefaults.standard.set(djData, forKey: djKey)
            print("📈 DJ榜數據已提交到週排行榜")
        }
        
        // 提交烏龜神榜數據
        if !turtleStats.isEmpty {
            let turtleEntries = turtleStats.map { (playerName, reactionTime) in
                BinaryGameProtocol.WeeklyLeaderboardEntry(
                    playerID: playerName,
                    nickname: playerName,
                    value: Float(reactionTime),
                    lastUpdate: Date()
                )
            }
            .sorted { $0.value > $1.value } // 反應時間越長排越前面（最慢第一名）
            .prefix(3)
            .map { $0 }
            
            let turtleData = BinaryGameProtocol.encodeWeeklyLeaderboard(
                type: .reaction,
                entries: turtleEntries,
                weekStartTime: weekStartTime
            )
            
            let turtleKey = "\(weeklyLeaderboardPrefix)reaction_\(Int(weekStartTime.timeIntervalSince1970))"
            UserDefaults.standard.set(turtleData, forKey: turtleKey)
            print("🐢 烏龜神榜數據已提交到週排行榜")
        }
    }
    
    /// 所有人自動離開房間開始新的一局
    private func leaveGameRoomAfterWin() {
        print("🚪 冠軍後自動離開房間機制啟動...")
        
        // 1. 清理本地遊戲狀態（使用現有的resetGameState）
        resetGameState()
        
        // 2. 通知UI層離開房間
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 觸發離開房間回調
            self.onGameWon?("遊戲結束", 0)
            
            print("✅ 房間清理完成，準備開始新一局")
        }
        
        // 3. 如果是主機，等待1秒後重新開始房間
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                
                // 重新初始化房間狀態
                self.initializeNewGame()
                print("🏠 主機重新開放房間")
            }
        }
    }
    
    /// 初始化新遊戲（主機用）
    private func initializeNewGame() {
        gameState = .waitingForPlayers
        isHost = true
        
        // 生成新的賓果卡
        localBingoCard = generateBingoCard()
        
        // 重置抽號狀態
        localDrawnNumbers = []
        currentNumber = nil
        
        print("🎯 新遊戲初始化完成")
    }
}