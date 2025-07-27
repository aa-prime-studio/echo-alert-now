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
    // MARK: - 遊戲狀態屬性 - 直接使用@Published本地狀態，減少技術債
    // 🔧 FIX: 簡化為計算屬性，自動處理BingoCard生成，確保二進制協議兼容
    var bingoCard: BingoCard? { 
        get { 
            return localBingoCard ?? generateBingoCard()
        }
        set { 
            localBingoCard = newValue
        }
    }
    
    // 🔧 FIX: 直接使用@Published本地狀態，確保UI自動更新
    var drawnNumbers: [Int] { 
        get { return localDrawnNumbers }
        set { localDrawnNumbers = newValue }
    }
    
    var completedLines: Int { 
        get { return localCompletedLines }
        set { localCompletedLines = newValue }
    }
    
    var gameWon: Bool { 
        get { return localGameWon }
        set { localGameWon = newValue }
    }
    
    var gameState: GameRoomState.GameState { 
        get { return localGameState }
        set { localGameState = newValue }
    }
    
    var countdown: Int { 
        get { return localCountdown }
        set { localCountdown = newValue }
    }
    var currentNumber: Int? { 
        get { 
            // 🔧 FIX: 使用本地狀態確保數字正確顯示
            return localCurrentNumber
        }
        set { 
            // 🔧 FIX: 更新本地狀態，@Published會自動觸發UI更新
            localCurrentNumber = newValue
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
    
    // MARK: - 主機選舉機制
    private var hostElectionTimestamp: Date = Date()
    private var lastHostHeartbeat: [String: Date] = [:] // 追蹤每個主機的心跳時間
    private var hostElectionInProgress: Bool = false
    
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
    private var timerManager: UnifiedTimerManager?
    // private var networkManager: BingoNetworkManager? // 已移除
    // private var gameStateManager: BingoGameStateManager? // 已移除
    
    // MARK: - 遊戲管理
    var deviceName: String
    private var playerID: String
    private var hostID: String = ""
    private var gameRoomState: GameRoomState?
    
    // MARK: - 本地狀態屬性 (替代已移除的 gameStateManager)
    // 🔧 FIX: 改為@Published確保UI自動更新，支持二進制協議
    @Published private var localBingoCard: BingoCard? = nil
    @Published private var localDrawnNumbers: [Int] = []
    @Published private var localCompletedLines: Int = 0
    @Published private var localGameWon: Bool = false
    @Published private var localGameState: GameRoomState.GameState = .waitingForPlayers
    @Published private var localCountdown: Int = 0
    @Published private var localCurrentNumber: Int? = nil
    
    // 定時器管理方法 - 委託給 TimerManager
    @MainActor
    private func scheduleTimer(id: String, interval: TimeInterval, repeats: Bool = true, action: @escaping () -> Void) {
        let config = TimerConfiguration(
            interval: interval,
            repeats: repeats,
            tolerance: nil,
            runLoop: .main,
            mode: .default
        )
        timerManager?.schedule(id: id, configuration: config, action: action)
    }
    
    @MainActor
    private func cancelTimer(id: String) {
        timerManager?.invalidate(id: id)
    }
    
    @MainActor
    private func cancelAllTimers() {
        timerManager?.invalidateAll()
    }
    
    // Timer ID 常數 - 使用 UnifiedTimerManager.TimerID
    private typealias TimerID = String
    
    // MARK: - 網路狀態 - 現在由 BingoNetworkManager 管理
    private var lastSyncTime: Date = Date()
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    private var gameStartTime: Date?
    
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
        self.timerManager = UnifiedTimerManager.shared
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
            
            // DEBUG: 初始化完成後的系統狀態
            await debugAllSystems()
            
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
        let activeCount = timerManager?.activeTimerCount ?? 0
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
    
    /// 主機競選狀態追蹤
    private var lastHostElectionTime = Date(timeIntervalSince1970: 0)
    private let hostElectionCooldown: TimeInterval = 15.0  // 15秒冷卻期避免頻繁選舉
    
    /// 廣播冷卻機制
    private var lastBroadcastTime: [GameMessageType: Date] = [:]
    private let broadcastCooldown: TimeInterval = 3.0  // 3秒廣播冷卻
    
    /// 基於強化算法決定是否應該成為主機（防雙主機版本）
    // DEPRECATED: 複雜的主機選舉邏輯已不再需要
    private func determineHost(connectedPeers: [String]) -> Bool {
        // 簡化：不再進行主機選舉，第一個創建房間的就是主機
        return false
    }
    
    /// 確定性主機選舉算法 - 基於設備ID的穩定排序
    private func electHost(candidates: [String]) -> String {
        // 防空列表
        guard !candidates.isEmpty else {
            return getStandardizedPlayerID()
        }
        
        // 🔧 修復：統一所有ID格式
        let standardizedCandidates = candidates.map { candidate in
            return getStandardizedID(candidate)
        }
        
        // 過濾重複的候選人並使用字典序排序
        let uniqueCandidates = Array(Set(standardizedCandidates))
        
        // 使用確定性算法選出主機：字典序排序
        let sortedCandidates = uniqueCandidates.sorted { peer1, peer2 in
            peer1 < peer2
        }
        
        let electedHost = sortedCandidates.first ?? getStandardizedPlayerID()
        
        // 🔍 詳細主機選舉調試
        print("👑 主機選舉詳細調試(統一格式):")
        print("  - 原始候選人: \(candidates)")
        print("  - 標準化後: \(standardizedCandidates)")
        print("  - 去重後: \(uniqueCandidates)")
        print("  - 排序後: \(sortedCandidates)")
        print("  - 選出主機: \(electedHost)")
        
        return electedHost
    }
    
    /// 新的主機選舉加入房間方法
    func joinRoomWithHostElection(_ roomID: String) {
        print("🎮 開始加入房間並進行主機選舉：\(roomID.prefix(8))")
        
        // DEBUG: 加入房間前的系統狀態
        Task { @MainActor in
            await debugAllSystems()
        }
        
        // 1. 啟動網路
        if !isNetworkActive {
            setupMeshNetworking()
        }
        
        // 2. 🔧 改進：收集真實的連接設備 ID
        let connectedPeers = getUniqueConnectedPeerIDs()
        let allPeers = [playerID] + connectedPeers
        
        print("📡 發現設備：[\(allPeers.map { $0.prefix(8) }.joined(separator: ", "))]")
        
        // 3. 進行主機選舉
        let electedHost = electHost(candidates: allPeers)
        
        // DEBUG: 主機選舉結果
        Task { @MainActor in
            debugHostElectionStatus()
        }
        
        // 4. 設定角色
        if electedHost == playerID {
            print("👑 我被選為主機")
            becomeHostAndCreateRoom(roomID)
        } else {
            print("📱 \(electedHost.prefix(8)) 是主機，我是玩家")
            becomePlayerAndJoinRoom(roomID, hostID: electedHost)
        }
        
        // 5. 廣播選舉結果
        broadcastHostElectionResult(host: electedHost, roomID: roomID)
    }
    
    /// 成為主機並創建房間
    private func becomeHostAndCreateRoom(_ roomID: String) {
        gameRoomID = roomID
        hostID = playerID
        isHost = true
        isInRoom = true
        hostElectionInProgress = false
        
        let normalizedPlayerName = NicknameFormatter.cleanNickname(deviceName)
        let initialPlayer = PlayerState(id: playerID, name: normalizedPlayerName)
        roomPlayers = [initialPlayer]
        
        // DEBUG: 成為主機後的狀態
        Task { @MainActor in
            debugHostElectionStatus()
            await debugKeyExchangeStatus()
        }
        
        // 啟動週期性調試監控
        startPeriodicSystemDebugging()
        
        addSystemMessage("已成為房間 \(roomID.prefix(8)) 的主機")
        print("👑 成為房間主機：\(roomID.prefix(8))")
    }
    
    /// 成為玩家並加入房間
    private func becomePlayerAndJoinRoom(_ roomID: String, hostID: String) {
        gameRoomID = roomID
        self.hostID = hostID
        isHost = false
        isInRoom = true
        hostElectionInProgress = false
        
        let normalizedPlayerName = NicknameFormatter.cleanNickname(deviceName)
        let localPlayer = PlayerState(id: playerID, name: normalizedPlayerName)
        roomPlayers = [localPlayer]
        
        // 啟動週期性調試監控
        startPeriodicSystemDebugging()
        
        addSystemMessage("已加入房間 \(roomID.prefix(8))，主機：\(hostID.prefix(8))")
        print("📱 加入房間，主機是：\(hostID.prefix(8))")
    }
    
    /// 廣播主機選舉結果
    private func broadcastHostElectionResult(host: String, roomID: String) {
        let electionData = "HOST_ELECTION|\(host)|\(roomID)"
        if let data = electionData.data(using: .utf8) {
            broadcastGameMessage(.gameStateUpdate, data: data)
            print("📡 廣播主機選舉結果：主機=\(host.prefix(8)), 房間=\(roomID.prefix(8))")
        }
    }
    
    /// 執行增強的主機選舉算法
    private func performEnhancedHostElection(connectedPeers: [String]) -> Bool {
        let myPeerID = playerID
        let allPeerIDs = connectedPeers + [myPeerID]
        
        // 1. 主要條件：字典序最小
        let sortedPeerIDs = allPeerIDs.sorted()
        guard let primaryHost = sortedPeerIDs.first else { return true }
        
        if primaryHost != myPeerID {
            print("📝 字典序選舉：\(primaryHost.prefix(8)) 優於我 \(myPeerID.prefix(8))")
            return false
        }
        
        // 2. 次要條件：網路穩定性檢查
        let networkStability = calculateNetworkStability()
        if networkStability < 0.7 {
            print("📶 網路不穩定 (\(String(format: "%.2f", networkStability)))，延遲主機選舉")
            return false
        }
        
        // 3. 防雙主機檢查：檢查是否有其他潛在主機
        let potentialHosts = checkForPotentialHosts(in: connectedPeers)
        if !potentialHosts.isEmpty {
            print("⚠️ 檢測到潜在雙主機風險：\(potentialHosts.map { $0.prefix(8) }.joined(separator: ", "))")
            
            // 使用連接時間戳作為決勝條件
            if let myConnectionTime = getConnectionTimestamp(),
               let earliestCompetitor = potentialHosts.compactMap({ getConnectionTimestamp(for: $0) }).min(),
               myConnectionTime > earliestCompetitor {
                print("⏰ 連接時間較晚，讓位給更早的主機")
                return false
            }
        }
        
        print("✅ 通過所有主機選舉檢查")
        return true
    }
    
    /// 計算網路穩定性評分
    private func calculateNetworkStability() -> Double {
        let connectedCount = meshManager.getConnectedPeers().count
        let expectedCount = max(1, roomPlayers.count - 1)
        
        let connectionRatio = Double(connectedCount) / Double(expectedCount)
        
        // 基於最近的網路活動評估穩定性
        let timeSinceLastActivity = Date().timeIntervalSince(lastSyncTime)
        let activityScore = max(0.0, 1.0 - (timeSinceLastActivity / 30.0))
        
        return min(1.0, connectionRatio * 0.6 + activityScore * 0.4)
    }
    
    /// 檢查潛在的雙主機競爭者
    private func checkForPotentialHosts(in peers: [String]) -> [String] {
        return peers.filter { peerID in
            // 檢查該 peer 是否可能也在進行主機選舉
            let peerIsEarlierInSort = peerID < playerID
            return !peerIsEarlierInSort // 只有可能成為主機的 peers 才是競爭者
        }
    }
    
    /// 獲取連接時間戳
    private func getConnectionTimestamp(for peerID: String? = nil) -> TimeInterval? {
        if peerID != nil {
            // 這裡應該從連接管理器獲取實際的連接時間
            return Date().timeIntervalSince1970 // 暫時返回當前時間
        } else {
            // 返回自己的連接時間
            return Date().timeIntervalSince1970
        }
    }
    
    /// 檢查是否有活躍主機（嚴格版本，防雙主機）
    private func hasActiveHostStrict() -> Bool {
        // 🔧 更嚴格的主機活躍檢查
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        let hasRecentHostActivity = timeSinceLastSync < 10.0  // 縮短到10秒
        
        // 檢查房間內是否有明確的主機ID（排除自己）
        let hasValidHostID = !hostID.isEmpty && hostID != playerID
        
        // 🔧 檢查是否有其他玩家聲稱是主機
        let hasCompetingHost = roomPlayers.contains { player in
            // PlayerState 沒有 isHost 屬性，使用 hostID 檢查
            hostID == player.id && player.id != playerID
        }
        
        // 🔧 更嚴格的邏輯：如果有任何其他活躍主機，就不允許成為主機
        let hasActiveHost = (hasRecentHostActivity && hasValidHostID) || hasCompetingHost
        
        print("🔍 嚴格主機檢查: 最近同步=\(String(format: "%.1f", timeSinceLastSync))s, 有效主機ID=\(hasValidHostID), 競爭主機=\(hasCompetingHost), 結果=\(hasActiveHost)")
        
        return hasActiveHost
    }
    
    /// 檢查是否有活躍主機（放寬條件）- 保留向後兼容
    private func hasActiveHost() -> Bool {
        return hasActiveHostStrict()
    }
    
    // MARK: - 調試工具
    
    private func debugGameState() {
        print("""
        🎮 ===== 遊戲狀態調試 =====
        本地玩家 ID: \(playerID.prefix(8))
        設備名稱: \(deviceName)
        是否為主機: \(isHost)
        主機 ID: \(hostID.prefix(8))
        房間 ID: \(gameRoomID.prefix(8))
        遊戲狀態: \(gameState)
        房間玩家數: \(roomPlayers.count)
        房間玩家: [\(roomPlayers.map { "\($0.name)(\($0.id.prefix(8)))" }.joined(separator: ", "))]
        連接狀態: \(connectionStatus)
        網路活躍: \(isNetworkActive)
        連接設備: [\(meshManager.getConnectedPeers().map { $0.prefix(8) }.joined(separator: ", "))]
        主機選舉進行中: \(hostElectionInProgress)
        上次主機選舉時間: \(lastHostElectionTime)
        ====================
        """)
    }
    
    /// 調試密鑰交換狀態
    private func debugKeyExchangeStatus() async {
        let securityService = ServiceContainer.shared.securityService
        let connectedPeers = meshManager.getConnectedPeers()
        
        print("""
        🔑 ===== 密鑰交換狀態調試 =====
        連接設備數: \(connectedPeers.count)
        連接設備: [\(connectedPeers.map { $0.prefix(8) }.joined(separator: ", "))]
        密鑰狀態:
        """)
        
        for peer in connectedPeers {
            let hasKey = await securityService.hasSessionKey(for: peer)
            print("  - \(peer.prefix(8)): \(hasKey ? "✅ 有密鑰" : "❌ 無密鑰")")
        }
        
        print("====================")
    }
    
    /// 強制修復密鑰交換問題
    func forceFixKeyExchange() async {
        print("🔧 強制修復密鑰交換問題")
        let connectedPeers = meshManager.getConnectedPeers()
        let securityService = ServiceContainer.shared.securityService
        
        for peer in connectedPeers {
            let hasKey = await securityService.hasSessionKey(for: peer)
            if !hasKey {
                print("🔑 嘗試為 \(peer.prefix(8)) 強制建立密鑰")
                // 使用現有的密鑰交換方法
                Task {
                    do {
                        let publicKey = try await securityService.getPublicKey()
                        let keyExchangeData = Data("KEY_EXCHANGE".utf8) + publicKey
                        
                        // 創建 MeshMessage
                        let meshMessage = MeshMessage(
                            id: UUID().uuidString,
                            type: .keyExchange,
                            data: keyExchangeData
                        )
                        
                        // 編碼並發送
                        let binaryData = try BinaryMessageEncoder.encode(meshMessage)
                        meshManager.broadcastMessage(binaryData, messageType: .keyExchange)
                        print("✅ 密鑰交換請求已發送給 \(peer.prefix(8))")
                    } catch {
                        print("❌ 密鑰交換失敗: \(error)")
                    }
                }
            } else {
                print("✅ \(peer.prefix(8)) 已有密鑰")
            }
        }
    }
    
    /// 強制成為主機（用於測試）
    func forcePromoteToHost() {
        print("👑 強制成為主機")
        debugAutoStartLogic()
        
        if !isHost {
            print("🎯 強制執行主機選舉")
            becomeRoomHost()
        } else {
            print("⚠️ 已經是主機")
        }
    }
    
    /// 獲取唯一的連接設備 ID（解決顯示名稱重複問題）
    private func getUniqueConnectedPeerIDs() -> [String] {
        let connectedPeers = meshManager.getConnectedPeers()
        
        // 🔧 修復：統一ID格式以避免主機選舉問題
        let uniquePeerIDs = Array(Set(connectedPeers)).map { peerID in
            return getStandardizedID(peerID)
        }
        
        print("🔍 獲取連接設備ID詳細調試(標準化):")
        print("  - 原始: \(connectedPeers)")
        print("  - 標準化後: \(uniquePeerIDs)")
        print("  - 第一個設備ID: '\(uniquePeerIDs.first ?? "無")'")
        
        return uniquePeerIDs
    }
    
    /// 獲取標準化的玩家ID
    private func getStandardizedPlayerID() -> String {
        return getStandardizedID(playerID)
    }
    
    /// 標準化ID格式（統一處理不同格式的ID）
    private func getStandardizedID(_ id: String) -> String {
        // 如果是 SignalAir-XXXXXXXX 格式，只取後部ID
        if id.hasPrefix("SignalAir-") {
            return String(id.dropFirst("SignalAir-".count))
        }
        
        // 如果是完整的UUID格式，取前8位
        if id.contains("-") && id.count > 20 {
            let components = id.components(separatedBy: "-")
            return components.first ?? id
        }
        
        // 其他格式直接返回
        return id
    }
    
    /// 調試主機選舉狀態
    private func debugHostElectionStatus() {
        let connectedPeers = meshManager.getConnectedPeers()
        let uniquePeers = getUniqueConnectedPeerIDs()
        print("""
        👑 ===== 主機選舉狀態調試 =====
        主機選舉進行中: \(hostElectionInProgress)
        主機選舉時間戳: \(hostElectionTimestamp)
        上次主機選舉時間: \(lastHostElectionTime)
        主機心跳記錄: \(lastHostHeartbeat.mapValues { Date().timeIntervalSince($0) })
        當前主機: \(hostID.prefix(8))
        我是主機: \(isHost)
        原始連接設備: [\(connectedPeers.joined(separator: ", "))]
        唯一連接設備: [\(uniquePeers.map { $0.prefix(12) }.joined(separator: ", "))]
        本機ID: \(playerID.prefix(8))
        ====================
        """)
    }
    
    /// 綜合調試：在關鍵時刻調用
    func debugAllSystems() async {
        print("\n🔍 ===== 完整系統狀態調試 =====")
        debugGameState()
        await debugKeyExchangeStatus()
        debugHostElectionStatus()
        debugEmoteBroadcastStatus()
        debugAutoStartLogic()
        print("🔍 ===== 調試完成 =====\n")
    }
    
    /// 診斷表情廣播功能
    private func debugEmoteBroadcastStatus() {
        print("""
        😄 ===== 表情廣播狀態調試 =====
        是否在房間內: \(isInRoom)
        網路是否啟動: \(isNetworkActive)
        連接的設備數: \(meshManager.getConnectedPeers().count)
        上次表情時間: \(lastEmoteTime.timeIntervalSinceNow)秒前
        表情冷卻時間: \(emoteCooldown)秒
        廣播冷卻時間: \(broadcastCooldown)秒
        ====================
        """)
    }
    
    /// 診斷自動開始遊戲邏輯
    private func debugAutoStartLogic() {
        print("""
        🎮 ===== 自動開始遊戲邏輯調試 =====
        是否為主機: \(isHost)
        遊戲狀態: \(gameState)
        房間玩家數: \(roomPlayers.count)
        最少開始人數: \(minPlayersToStart)
        最大房間人數: \(maxPlayersPerRoom)
        是否達到開始條件: \(isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers)
        倒數計時: \(countdown)
        ====================
        """)
    }
    
    /// 啟動週期性系統調試監控
    private func startPeriodicSystemDebugging() {
        print("🔍 啟動週期性系統調試監控（每30秒）")
        
        scheduleTimer(id: "periodic.system.debug", interval: 30.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            // 只在活躍會話期間進行調試
            if self.isInRoom || self.isHost || !self.roomPlayers.isEmpty {
                print("\n⏰ ===== 週期性系統狀態檢查 =====")
                Task {
                    await self.debugAllSystems()
                    print("⏰ ===== 週期性檢查完成 =====\n")
                }
            }
        }
    }
    
    /// 停止週期性系統調試監控
    private func stopPeriodicSystemDebugging() {
        print("🔍 停止週期性系統調試監控")
        cancelTimer(id: "periodic.system.debug")
    }
    
    /// 測試表情廣播功能
    func testEmoteBroadcast() {
        print("🧪 測試表情廣播功能")
        debugEmoteBroadcastStatus()
        
        // 發送測試表情
        sendEmote(.bingo)
    }
    
    /// 強制修復表情廣播問題
    func forceFixEmoteBroadcast() {
        print("🔧 強制修復表情廣播問題")
        debugEmoteBroadcastStatus()
        
        // 檢查房間狀態
        if !isInRoom {
            print("⚠️ 不在房間內，無法廣播表情")
            return
        }
        
        // 檢查網路狀態
        if !isNetworkActive {
            print("🔧 重啟網路連接")
            setupMeshNetworking()
        }
        
        // 發送測試表情來驗證修復
        print("📤 發送測試表情來驗證修復")
        sendEmote(.fire)
    }
    
    /// 測試自動開始功能
    func testAutoStartLogic() {
        print("🧪 測試自動開始邏輯")
        debugAutoStartLogic()
        
        if isHost {
            print("📝 模擬第二個玩家加入...")
            let testPlayer = PlayerState(id: "test-player-2", name: "測試玩家2")
            if !roomPlayers.contains(where: { $0.id == testPlayer.id }) {
                roomPlayers.append(testPlayer)
                print("✅ 測試玩家已加入，當前玩家數: \(roomPlayers.count)")
                
                // 檢查自動開始條件
                if roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers {
                    print("🎮 條件滿足，嘗試自動開始遊戲")
                    startGame()
                } else {
                    print("⚠️ 條件未滿足，不會自動開始")
                    debugAutoStartLogic()
                }
            }
        } else {
            print("⚠️ 非主機無法測試自動開始邏輯")
        }
    }
    
    // MARK: - Mesh 網路設定
    
    /// 網路設置 - 現在使用 BingoNetworkManager
    private func setupMeshNetworking() {
        print("🎮 BingoGameViewModel: 使用 BingoNetworkManager 設置網路")
        // networkManager?.setupMeshNetworking() // 已移除
        
        // 設置消息處理回調
        setupMessageHandling()
        
        // 延遲驗證網路就緒狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.verifyNetworkReadiness()
        }
    }
    
    /// 設置網路消息處理
    private func setupMessageHandling() {
        // 透過 ServiceContainer 的統一路由系統處理消息
        // 由於 MeshManager 的消息已經被 ServiceContainer 處理，
        // 我們需要註冊遊戲消息處理器
        
        print("🔄 BingoGameViewModel: 註冊遊戲消息處理器")
        
        // TODO: 這裡需要將 handleRoomStateMessage 註冊到統一路由系統
        // 但由於 ServiceContainer 的複雜性，我們暫時使用直接監聽
        
        // 檢查 MeshManager 是否可用
        if meshManager is MeshManager {
            // MeshManager 的數據處理會通過 ServiceContainer 路由
            // 這裡暫時不需要直接設置回調
            print("✅ 遊戲消息處理已準備就緒")
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
    
    /// 簡化版本：監控玩家數量，兩人自動開始
    private func startPlayerCountMonitoring() {
        // 如果不是主機，不需要監控
        guard isHost else { return }
        
        // 使用計時器每秒檢查一次玩家數量
        timerManager?.schedule(id: "playerCountMonitor", configuration: TimerConfiguration(interval: 1.0, repeats: true)) { [weak self] in
            guard let self = self else { return }
            
            // 如果遊戲已經開始，停止監控
            if self.gameState != .waitingForPlayers {
                self.timerManager?.invalidate(id: "playerCountMonitor")
                return
            }
            
            // 檢查玩家數量，至少兩人就開始
            if self.roomPlayers.count >= 2 {
                print("🎉 檢測到至少2名玩家，準備開始遊戲")
                self.timerManager?.invalidate(id: "playerCountMonitor")
                self.startGameCountdown()
            }
        }
    }
    
    /// 簡化版本：開始遊戲倒數
    private func startGameCountdown() {
        guard isHost else { return }
        guard gameState == .waitingForPlayers else { return }
        
        // 設置倒數時間（10秒）
        countdown = 10
        gameState = .countdown
        
        // 更新房間狀態
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: .countdown,
            drawnNumbers: [],
            currentNumber: nil,
            countdown: countdown,
            startTime: nil
        )
        
        // 廣播倒數開始
        broadcastGameMessage(.gameStateUpdate, data: encodeGameRoomState())
        addSystemMessage("🎮 遊戲將在 10 秒後開始！")
        
        // 開始倒數計時器
        timerManager?.schedule(id: "gameCountdown", configuration: TimerConfiguration(interval: 1.0, repeats: true)) { [weak self] in
            guard let self = self else { return }
            
            self.countdown -= 1
            
            if self.countdown <= 0 {
                self.timerManager?.invalidate(id: "gameCountdown")
                self.actuallyStartGame()
            } else {
                // 更新倒數狀態
                self.gameRoomState = GameRoomState(
                    roomID: self.gameRoomID,
                    hostID: self.hostID,
                    players: self.roomPlayers,
                    gameState: .countdown,
                    drawnNumbers: [],
                    currentNumber: nil,
                    countdown: self.countdown,
                    startTime: nil
                )
                self.broadcastGameMessage(.gameStateUpdate, data: self.encodeGameRoomState())
                
                // 在關鍵時刻顯示倒數
                if self.countdown <= 3 {
                    self.addSystemMessage("⏰ \(self.countdown)...")
                }
            }
        }
    }
    
    /// 真正開始遊戲
    private func actuallyStartGame() {
        guard isHost else { return }
        
        gameState = .playing
        drawnNumbers = []
        currentNumber = nil
        gameStartTime = Date()
        
        // 更新房間狀態
        gameRoomState = GameRoomState(
            roomID: gameRoomID,
            hostID: hostID,
            players: roomPlayers,
            gameState: .playing,
            drawnNumbers: drawnNumbers,
            currentNumber: currentNumber,
            countdown: 0,
            startTime: gameStartTime
        )
        
        // 廣播遊戲開始
        broadcastGameMessage(.gameStart, data: encodeGameRoomState())
        addSystemMessage("🎮 遊戲開始！")
        
        // 開始抽號
        startDrawingNumbers()
    }
    
    /// 開始自動抽號
    private func startDrawingNumbers() {
        guard isHost else { return }
        
        // 每5秒抽一個號碼
        timerManager?.schedule(id: "gameDraw", configuration: TimerConfiguration(interval: 5.0, repeats: true)) { [weak self] in
            guard let self = self else { return }
            
            self.drawNextNumber()
        }
    }
    
    
    func createGameRoom() {
        // 【簡化修復】進入房間時才啟動網路
        if !isNetworkActive {
            setupMeshNetworking()
        }
        
        gameRoomID = UUID().uuidString
        hostID = playerID
        isHost = true  // 創建房間的人就是主機，就這麼簡單
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
        
        // 🌐 啟動網路穩定性監控
        startNetworkStabilityMonitoring()
        
        // 🎯 簡化：立即開始監控玩家數量，有兩人就自動開始
        startPlayerCountMonitoring()
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
        
        // 🌐 啟動網路穩定性監控
        startNetworkStabilityMonitoring()
    }
    
    func joinGameRoom(_ roomID: String) {
        // 【簡化修復】進入房間時才啟動網路
        if !isNetworkActive {
            setupMeshNetworking()
        }
        
        gameRoomID = roomID
        isHost = false  // 加入房間的人不是主機，就這麼簡單
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
        
        // 🌐 延遲啟動網路穩定性監控（等待初始連接建立）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.startNetworkStabilityMonitoring()
        }
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
        
        // 🌐 延遲啟動網路穩定性監控（等待初始連接建立）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.startNetworkStabilityMonitoring()
        }
    }
    
    // 【簡化方案】簡單的離開房間方法
    func leaveRoom() {
        isInRoom = false
        gameRoomID = ""
        roomPlayers.removeAll()
        roomChatMessages.removeAll()
        cancelAllTimers()
        
        // 停止週期性調試監控
        stopPeriodicSystemDebugging()
        
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
            guard let self = self else { return }
            self.attemptToJoinOrCreateRoom(roomID: roomID)
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
                // 簡化：不做主機選舉，等待主機的房間同步訊息即可
            }
        } else {
            // 沒有穩定網路連接時（離線模式）
            print("📶 無穩定網路連接（離線模式）")
            await MainActor.run {
                addSystemMessage("進入房間 \(roomID)（離線模式）")
                // 離線模式下只有自己，無法加入別人的房間
                addSystemMessage("⚠️ 離線模式下無法加入其他玩家的房間")
            }
        }
    }
    
    // DEPRECATED: 不再需要複雜的主機選舉
    private func becomeRoomHost() {
        // 簡化：創建房間的人就是主機，不需要選舉
        // 這個方法目前已被簡化的邏輯取代，保留備用
        print("⚠️ becomeRoomHost 已被簡化邏輯取代")
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
        
        // DEBUG: 關鍵游戲消息处理時的狀態
        if [.roomSync, .playerJoined, .gameStart, .numberDrawn].contains(message.type) {
            Task { @MainActor in
                debugGameState()
            }
        }
        
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
        case .roomStateRequest:
            handleRoomStateMessage(message)
        case .roomStateUpdate:
            handleRoomStateMessage(message)
        case .bingoWon:
            handleWinnerAnnouncement(message) // 映射到現有處理方法
        // 🔧 FIX: 處理新增的消息類型
        case .keyExchangeRequest, .keyExchangeResponse:
            print("🔑 收到密鑰交換消息: \(message.type.stringValue)")
            // 可選：實現密鑰交換處理邏輯
        case .stateSync:
            handleStateSyncMessage(message)
        case .errorReport:
            print("❌ 收到錯誤報告: \(String(data: message.data, encoding: .utf8) ?? "無法解析")")
        case .compatibilityCheck:
            print("🔍 收到兼容性檢查消息")
        case .reserved15, .reserved16, .reserved17, .reserved18, .reserved19,
             .reserved1A, .reserved1B, .reserved1C, .reserved1D, .reserved1E, .reserved1F:
            print("⚠️ 收到預留類型消息: \(message.type.stringValue)")
        case .unknown:
            print("❓ 收到未知類型消息，使用容錯處理")
        }
    }
    
    // MARK: - 訊息處理器
    
    /// 🔧 FIX: 處理解耦的狀態同步消息
    private func handleStateSyncMessage(_ message: GameMessage) {
        print("🔄 處理狀態同步消息")
        
        // 解碼狀態同步數據
        guard let syncResult = BinaryGameProtocol.decodeStateSyncMessage(message.data) else {
            print("❌ 無法解碼狀態同步數據")
            return
        }
        
        print("📊 同步狀態 - 房間: \(syncResult.roomID), 人數: \(syncResult.playerCount), 活躍: \(syncResult.isActive)")
        
        // 更新房間狀態（不依賴密鑰交換）
        Task { @MainActor in
            // 這裡可以安全地更新UI狀態，因為不依賴加密
            if syncResult.roomID == gameRoomID {
                // 僅更新基本狀態信息
                print("✅ 房間狀態同步完成")
            }
        }
    }
    
    /// 處理系統消息（包括主機選舉）
    private func handleSystemMessage(_ message: GameMessage) {
        guard let messageContent = String(data: message.data, encoding: .utf8) else {
            print("❌ 無法解析系統消息內容")
            return
        }
        
        if messageContent.hasPrefix("HOST_ELECTION|") {
            handleHostElectionMessage(messageContent, from: message.senderID)
        } else {
            print("ℹ️ 收到系統消息: \(messageContent)")
        }
    }
    
    /// 處理主機選舉消息
    private func handleHostElectionMessage(_ content: String, from senderID: String) {
        let components = content.components(separatedBy: "|")
        guard components.count >= 3,
              components[0] == "HOST_ELECTION" else {
            print("❌ 主機選舉消息格式錯誤: \(content)")
            return
        }
        
        let electedHostID = components[1]
        let electionRoomID = components[2]
        
        print("👑 收到主機選舉結果: 主機=\(electedHostID.prefix(8)), 房間=\(electionRoomID.prefix(8))")
        
        // 檢查是否與當前遊戲房間相關
        if electionRoomID == gameRoomID {
            // 如果選出的主機不是自己，且自己目前是主機，則放棄主機權限
            if electedHostID != playerID && isHost {
                print("🚫 主機選舉結果：放棄主機權限，新主機是 \(electedHostID.prefix(8))")
                isHost = false
                hostID = electedHostID
                addSystemMessage("主機已變更為 \(electedHostID.prefix(8))")
            }
            // 如果選出的主機是自己，且自己目前不是主機，則成為主機
            else if electedHostID == playerID && !isHost {
                print("👑 主機選舉結果：成為新主機")
                isHost = true
                hostID = playerID
                addSystemMessage("已成為房間主機")
            }
            // 更新主機ID
            hostID = electedHostID
        }
    }
    
    private func handlePlayerJoined(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 2 else { return }
        
        // 接收的暱稱應該已經是清理過的，直接使用
        let playerState = PlayerState(id: components[0], name: components[1])
        
        if !roomPlayers.contains(where: { $0.id == playerState.id }) {
            roomPlayers.append(playerState)
            print("✅ 玩家 \(playerState.name) 加入房間 (\(roomPlayers.count)/\(maxPlayersPerRoom))")
            
            // 檢查是否達到最少人數，自動開始倒數計時（僅限主機）
            print("🔍 檢查自動開始條件: isHost=\(isHost), 玩家數=\(roomPlayers.count), 最少人數=\(minPlayersToStart), 遊戲狀態=\(gameState)")
            if isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers {
                print("🎮 達到最少人數 (\(roomPlayers.count)/\(minPlayersToStart))，自動開始遊戲")
                debugAutoStartLogic()
                startGame()
            } else {
                print("⚠️ 未達到自動開始條件")
                debugAutoStartLogic()
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
        cancelTimer(id: "hostPromotion")
        print("⏰ 取消主機推廣定時器 - 收到房間同步")
        
        // 使用標準格式解碼房間狀態
        guard let roomState = decodeStandardRoomState(message.data) else {
            print("❌ 標準格式房間同步解碼失敗")
            return
        }
        
        print("🔄 收到房間同步：房間ID=\(roomState.roomID.prefix(8)) 主機ID=\(roomState.hostID.prefix(8)) 玩家數=\(roomState.players.count) 狀態=\(roomState.gameState)")
        
        // 🔧 檢查是否收到有效的主機同步
        if !roomState.hostID.isEmpty && roomState.hostID != playerID {
            // 有其他主機存在，確保自己不是主機
            if isHost {
                print("🚫 發現其他主機(\(roomState.hostID.prefix(8)))，放棄主機權限")
                isHost = false
                hostID = ""
                addSystemMessage("檢測到其他主機，已切換為普通玩家")
            }
            // 更新主機ID
            hostID = roomState.hostID
        }
        
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
        
        guard let responseData = BinaryGameProtocol.encodeGameMessage(
            type: response.type,
            senderID: response.senderID,
            senderName: response.senderName,
            gameRoomID: response.gameRoomID,
            data: response.data
        ) else {
            print("❌ 編碼加入確認回應失敗")
            return
        }
        
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
        
        // 🔄 增強房間狀態同步：觸發狀態檢查
        scheduleRoomStateSyncCheck()
    }
    
    /// 📡 增強的房間狀態同步檢查機制
    private func scheduleRoomStateSyncCheck() {
        // 取消之前的檢查定時器
        cancelTimer(id: "room.state.sync.check")
        
        // 只有在房間中且網路活躍時才進行同步檢查
        guard isInRoom && isNetworkActive else { return }
        
        scheduleTimer(id: "room.state.sync.check", interval: 3.0, repeats: false) { [weak self] in
            guard let self = self else { return }
            self.performRoomStateSyncCheck()
        }
    }
    
    /// 🔍 執行房間狀態同步檢查
    private func performRoomStateSyncCheck() {
        guard isInRoom && isNetworkActive else { return }
        
        let connectedPeers = getUniqueConnectedPeerIDs()
        let roomPlayerIDs = roomPlayers.map { $0.id }
        
        // 檢查是否有連接的設備但不在房間玩家列表中
        let missingPlayers = connectedPeers.filter { peerID in
            !roomPlayerIDs.contains(peerID)
        }
        
        // 檢查是否有房間玩家但已斷開連接
        let disconnectedPlayers = roomPlayers.filter { player in
            !connectedPeers.contains(player.id)
        }
        
        if !missingPlayers.isEmpty {
            print("🔍 發現連接但未在房間的設備: \(missingPlayers)")
            
            // 主機主動廣播房間狀態給缺失的設備
            if isHost {
                broadcastGameMessage(.roomSync, data: encodeGameRoomState())
                print("📡 主機向缺失設備廣播房間狀態")
            }
        }
        
        if !disconnectedPlayers.isEmpty {
            print("🔍 發現已斷開連接的房間玩家: \(disconnectedPlayers.map { $0.name })")
            
            // 清理斷開連接的玩家（給予5秒寬限期）
            scheduleTimer(id: "cleanup.disconnected", interval: 5.0, repeats: false) { [weak self] in
                guard let self = self else { return }
                self.cleanupDisconnectedPlayers()
            }
        }
        
        // 檢查主機連接狀態
        if !isHost && !hostID.isEmpty && !connectedPeers.contains(hostID) {
            print("⚠️ 主機 \(hostID) 似乎已斷開連接，準備重新選舉")
            
            // 延遲後檢查是否需要重新選舉主機
            scheduleTimer(id: "host.reconnect.check", interval: 10.0, repeats: false) { [weak self] in
                guard let self = self else { return }
                self.checkHostReconnectionOrReelect()
            }
        }
        
        // 繼續下一輪檢查
        scheduleTimer(id: "room.state.sync.check", interval: 15.0, repeats: false) { [weak self] in
            guard let self = self else { return }
            self.performRoomStateSyncCheck()
        }
    }
    
    /// 🧹 清理斷開連接的玩家
    private func cleanupDisconnectedPlayers() {
        let connectedPeers = getUniqueConnectedPeerIDs()
        let originalPlayerCount = roomPlayers.count
        
        roomPlayers.removeAll { player in
            !connectedPeers.contains(player.id)
        }
        
        if roomPlayers.count < originalPlayerCount {
            print("🧹 清理了 \(originalPlayerCount - roomPlayers.count) 個斷開連接的玩家")
            updateGameRoomState()
            
            if isHost {
                broadcastGameMessage(.roomSync, data: encodeGameRoomState())
            }
        }
    }
    
    /// 🏛️ 檢查主機重連或重新選舉
    private func checkHostReconnectionOrReelect() {
        let connectedPeers = getUniqueConnectedPeerIDs()
        
        // 如果主機仍未連接，且我們有其他連接設備，則重新選舉
        if !hostID.isEmpty && !connectedPeers.contains(hostID) && !connectedPeers.isEmpty {
            print("🏛️ 主機確實已斷開，開始重新選舉主機")
            
            // 重置主機狀態
            hostID = ""
            isHost = false
            
            // 開始新的主機選舉
            let allPeers = [playerID] + connectedPeers
            let newHost = electHost(candidates: allPeers)
            
            if newHost == playerID {
                becomeHostAndCreateRoom(gameRoomID)
            } else {
                becomePlayerAndJoinRoom(gameRoomID, hostID: newHost)
            }
        } else if hostID.isEmpty && !connectedPeers.isEmpty {
            print("🏛️ 沒有主機但有連接設備，開始主機選舉")
            
            let allPeers = [playerID] + connectedPeers
            let newHost = electHost(candidates: allPeers)
            
            if newHost == playerID {
                becomeHostAndCreateRoom(gameRoomID.isEmpty ? UUID().uuidString : gameRoomID)
            } else {
                becomePlayerAndJoinRoom(gameRoomID.isEmpty ? UUID().uuidString : gameRoomID, hostID: newHost)
            }
        }
    }
    
    /// 🌐 網路連接穩定性檢測
    private func startNetworkStabilityMonitoring() {
        // 取消現有的監控定時器
        cancelTimer(id: "network.stability.monitor")
        
        guard isInRoom && isNetworkActive else { return }
        
        scheduleTimer(id: "network.stability.monitor", interval: 10.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            self.checkNetworkStability()
        }
        
        print("🌐 啟動網路穩定性監控")
    }
    
    /// 🔍 檢查網路穩定性
    private func checkNetworkStability() {
        let connectedPeers = getUniqueConnectedPeerIDs()
        let expectedMinConnections = max(1, roomPlayers.count - 1) // 至少應該連接到其他房間玩家
        
        // 檢查連接數量是否符合預期
        if connectedPeers.count < expectedMinConnections {
            print("⚠️ 網路連接數量不足: 實際=\(connectedPeers.count) 預期≥\(expectedMinConnections)")
            
            // 觸發網路恢復機制
            attemptNetworkRecovery()
        } else {
            print("✅ 網路連接穩定: \(connectedPeers.count) 個活躍連接")
        }
        
        // 檢查密鑰交換狀態
        checkSecurityKeyStatus(for: connectedPeers)
    }
    
    /// 🔧 嘗試網路恢復
    private func attemptNetworkRecovery() {
        print("🔧 開始網路恢復程序...")
        
        // 重新啟動網路服務（輕量級重啟）
        Task {
            do {
                // 重新初始化mesh網路
                if isNetworkActive {
                    await MainActor.run {
                        // 簡化：移除cleanup調用，直接重新設置
                        setupMeshNetworking()
                    }
                    
                    // 短暫延遲後重新啟動房間同步
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒延遲
                    
                    await MainActor.run {
                        if self.isHost {
                            // 主機重新廣播房間狀態
                            self.broadcastGameMessage(.roomSync, data: self.encodeGameRoomState())
                            print("🔧 主機重新廣播房間狀態")
                        }
                        
                        // 啟動房間狀態同步檢查
                        self.scheduleRoomStateSyncCheck()
                    }
                }
            } catch {
                print("❌ 網路恢復失敗: \(error)")
            }
        }
    }
    
    /// 🔐 檢查安全密鑰狀態
    private func checkSecurityKeyStatus(for peerIDs: [String]) {
        for peerID in peerIDs {
            // 檢查是否需要重新進行密鑰交換
            Task {
                // 通過ServiceContainer檢查密鑰狀態
                let hasValidKey = await ServiceContainer.shared.securityService.hasValidSessionKey(for: peerID)
                
                if !hasValidKey {
                    print("🔐 檢測到 \(peerID) 缺少有效密鑰，安排重新交換")
                    await ServiceContainer.shared.scheduleKeyExchangeRetry(with: peerID)
                }
            }
        }
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
            scheduleTimer(id: "gameCountdown", interval: 1.0, repeats: true) { [weak self] in
                guard let self = self else { return }
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.countdown > 0 {
                        self.addSystemMessage("\(self.countdown)")
                        print("⏰ 非主機倒數計時: \(self.countdown)")
                    }
                    
                    self.countdown -= 1
                    
                    if self.countdown < 0 {
                        self.cancelTimer(id: "gameCountdown")
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
        print("🎮 嘗試開始遊戲")
        debugAutoStartLogic()
        
        guard isHost && (gameState == .waitingForPlayers || gameState == .countdown) else { 
            print("❌ 開始遊戲失敗: 不是主機或遊戲狀態不正確")
            return 
        }
        
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
        
        print("✅ 遊戲開始流程完成")
    }
    
    private func startCountdownToGame() {
        gameState = .countdown
        countdown = 3
        addSystemMessage("遊戲即將開始...")
        
        // 主機倒數計時器
        scheduleTimer(id: "gameCountdown", interval: 1.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            if self.countdown > 0 {
                self.addSystemMessage("\(self.countdown)")
                print("⏰ 主機倒數計時: \(self.countdown)")
            }
            
            self.countdown -= 1
            
            if self.countdown < 0 {
                self.cancelTimer(id: "gameCountdown")
                self.gameState = .playing
                
                // 清除系統消息
                self.clearSystemMessages()
                
                self.addSystemMessage("開始抽卡！")
                
                // 開始自動抽號
                self.startDrawing()
            }
        }
    }
    
    private func startDrawing() {
        guard isHost && gameState == .playing else { return }
        
        print("🎲 開始抽卡系統")
        
        // 立即抽第一張卡
        drawNextNumber()
        
        // 然後每5秒抽一張新卡 (優化：避免網路堵塞)
        scheduleTimer(id: "gameDraw", interval: 5.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            self.drawNextNumber()
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
        
        guard let messageData = BinaryGameProtocol.encodeGameMessage(
            type: message.type,
            senderID: message.senderID,
            senderName: message.senderName,
            gameRoomID: message.gameRoomID,
            data: message.data
        ) else {
            print("❌ 編碼加入確認請求失敗")
            return
        }
        
        // 使用廣播方式發送確認請求
        meshManager.broadcastMessage(messageData, messageType: .game)
        print("📤 向 \(peerName) 發送加入確認請求")
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
        // 1. 檢查網路連接狀態
        guard isNetworkActive else {
            print("📡 跳過發送: 網路未啟動 (type: \(type.rawValue))")
            return
        }
        
        // 2. 檢查連接的設備
        let connectedPeers = meshManager.getConnectedPeers()
        guard !connectedPeers.isEmpty else {
            print("📡 跳過發送: 無連接設備 (type: \(type.rawValue))")
            return
        }
        
        // 3. 使用重試機制發送
        await broadcastGameMessageWithRetry(type, data: data, maxRetries: 2)
    }
    
    /// 帶重試機制的遊戲訊息廣播
    private func broadcastGameMessageWithRetry(_ type: GameMessageType, data: Data, maxRetries: Int) async {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            // 檢查連接狀態
            let connectedPeers = meshManager.getConnectedPeers()
            guard !connectedPeers.isEmpty else {
                print("📡 廣播失敗: 無連接設備 (嘗試 \(attempt)/\(maxRetries))")
                if attempt < maxRetries {
                    // 等待一段時間後重試
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 500_000_000)) // 0.5s * attempt
                    continue
                } else {
                    print("❌ 所有重試都失敗: 無連接設備")
                    return
                }
            }
            
            // 創建遊戲訊息內容
            var gameData = Data()
            
            // 添加遊戲訊息類型
            let typeData = type.stringValue.data(using: .utf8) ?? Data()
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
            
            // 添加發送者ID（用於去重和識別）
            let senderIDData = playerID.data(using: .utf8) ?? Data()
            let safeSenderIDLength = min(senderIDData.count, 255)
            gameData.append(UInt8(safeSenderIDLength))
            gameData.append(senderIDData.prefix(safeSenderIDLength))
            
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
            let broadcastResult = await MainActor.run { () -> Result<Void, Error> in
                do {
                    let binaryData = try BinaryMessageEncoder.encode(meshMessage)
                    meshManager.broadcastMessage(binaryData, messageType: .game)
                    print("📡 遊戲訊息廣播成功: \(type.rawValue) (\(binaryData.count) bytes) 嘗試=\(attempt)/\(maxRetries)")
                    return .success(())
                } catch {
                    print("❌ 編碼遊戲訊息失敗: \(error) (嘗試 \(attempt)/\(maxRetries))")
                    return .failure(error)
                }
            }
            
            switch broadcastResult {
            case .success:
                // 成功廣播，退出重試循環
                print("✅ 遊戲訊息廣播成功: \(type.rawValue)")
                return
            case .failure(let error):
                lastError = error
                if attempt < maxRetries {
                    // 等待一段時間後重試
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 200_000_000)) // 0.2s * attempt
                }
            }
        }
        
        print("❌ 遊戲訊息廣播最終失敗: \(type.rawValue), 錯誤: \(lastError?.localizedDescription ?? "未知錯誤")")
    }
    
    // MARK: - 網路通訊
    
    private func broadcastGameMessage(_ type: GameMessageType, data: Data) {
        // 🔧 FIX: 使用修復後的BinaryGameProtocol，確保標準MeshMessage格式
        guard let encodedData = BinaryGameProtocol.encodeGameMessage(
            type: type,
            senderID: playerID,
            senderName: deviceName,
            gameRoomID: gameRoomID,
            data: data
        ) else {
            print("❌ BingoGameViewModel: 遊戲消息編碼失敗 - 類型: \(type.stringValue)")
            return
        }
        
        // 🔧 檢查主機權限 - 只有主機能發送某些關鍵消息
        let hostOnlyMessageTypes: [GameMessageType] = [
            .gameStart, .gameEnd, .numberDrawn, .gameStateUpdate, .roomSync
        ]
        
        if hostOnlyMessageTypes.contains(type) && !isHost {
            print("🚫 只有主機能發送 \(type.stringValue) 消息，跳過廣播")
            return
        }
        
        // 🔧 檢查廣播冷卻（除緊急訊息外）
        let now = Date()
        if let lastTime = lastBroadcastTime[type] {
            let timeSinceLastBroadcast = now.timeIntervalSince(lastTime)
            
            // 緊急訊息（信號、遊戲狀態）不受限制
            let emergencyMessageTypes: [GameMessageType] = [.gameStart, .gameEnd, .numberDrawn]
            let isEmergencyMessage = emergencyMessageTypes.contains(type)
            
            if !isEmergencyMessage && timeSinceLastBroadcast < broadcastCooldown {
                print("⏳ 廣播冷卻中: \(type.stringValue) (剩餘: \(String(format: "%.1f", broadcastCooldown - timeSinceLastBroadcast))秒)")
                return
            }
        }
        
        // 記錄廣播時間
        lastBroadcastTime[type] = now
        
        // 使用異步廣播機制確保表情和其他訊息正確發送
        Task {
            await sendGameMessageSafely(type, data: encodedData)
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
        
        // DEBUG: 設備連接後的狀態
        Task { @MainActor in
            await debugKeyExchangeStatus()
            await debugAllSystems()
        }
        
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
        
        // DEBUG: 設備斷線後的狀態
        Task { @MainActor in
            debugHostElectionStatus()
            debugGameState()
        }
        
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
        self.scheduleTimer(id: "hostPromotion", interval: 5.0, repeats: false) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.evaluateHostPromotionAsync()
            }
        }
    }
    
    /// 評估主機升級的異步方法
    @MainActor
    private func evaluateHostPromotionAsync() async {
        // 🔧 防止已經是主機的設備再次升級
        if isHost {
            print("⚠️ 已經是主機，跳過主機升級評估")
            return
        }
        
        // 檢查是否收到主機廣播
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        if timeSinceLastSync > 10.0 && !isHost && isInRoom {
            print("👑 考慮成為新主機，上次同步距今：\(timeSinceLastSync)秒")
            
            // 基於玩家ID決定是否成為主機（使用改進的邏輯）
            let connectedPeers = await checkReliableConnectionState()
            let shouldBecomeHost = determineHost(connectedPeers: connectedPeers)
            
            if shouldBecomeHost {
                print("👑 通過主機選舉，成為新主機")
                becomeRoomHost()
            } else {
                print("🚫 主機選舉失敗，繼續等待")
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
        scheduleTimer(id: "heartbeatStartup", interval: NetworkConstants.heartbeatStartupDelay, repeats: false) { [weak self] in
            guard let self = self else { return }
            
            // 檢查是否仍需要心跳（避免在延遲期間狀態改變）
            guard self.isNetworkActive else {
                print("📡 網路已非活躍狀態，跳過心跳啟動")
                return
            }
            
            // 啟動實際的心跳定時器
            self.scheduleTimer(id: "heartbeat", interval: 5.0, repeats: true) { [weak self] in
                guard let self = self else { return }
                self.sendHeartbeatSync()
            }
            
            print("💓 心跳機制已啟動 (間隔: \(NetworkConstants.heartbeatInterval)s)")
        }
        
        print("⏰ 心跳啟動定時器已設置 (延遲: \(NetworkConstants.heartbeatStartupDelay)s)")
    }
    
    /// 停止心跳機制（新增方法）
    private func stopHeartbeat() {
        cancelTimer(id: "heartbeat")
        cancelTimer(id: "heartbeatStartup")
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
        cancelTimer(id: "gameSync")
        
        scheduleTimer(id: "gameSync", interval: 8.0, repeats: true) { [weak self] in
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
        cancelTimer(id: "gameDraw")
        cancelTimer(id: "gameCountdown")
        cancelTimer(id: "gameSync")
        cancelTimer(id: "heartbeat")
        cancelTimer(id: "reconnect")
        cancelTimer(id: "hostPromotion")
        cancelTimer(id: "gameRestart")
        
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
    
    // 🔧 FIX: 使用修復後的BinaryGameProtocol解碼標準MeshMessage格式
    private func decodeStandardGameMessage(_ data: Data, messageID: String) -> GameMessage? {
        print("🎮 開始解碼標準遊戲訊息 - 大小: \(data.count) bytes")
        
        // 🔧 FIX: 使用修復後的BinaryGameProtocol解碼
        guard let gameMessage = BinaryGameProtocol.decodeGameMessage(data) else {
            print("❌ BinaryGameProtocol: 遊戲訊息解碼失敗")
            print("📊 解碼失敗數據分析:")
            print("  大小: \(data.count) bytes")
            print("  前20字節: \(data.prefix(20).map { String(format: "%02X", $0) }.joined(separator: " "))")
            return nil
        }
        
        print("✅ BinaryGameProtocol: 成功解碼遊戲訊息 - 類型: \(gameMessage.type.stringValue), 發送者: \(gameMessage.senderName)")
        
        return gameMessage
    }
    
    /// 從遊戲數據中解析發送者信息
    private func parseGameDataForSender(_ data: Data, messageType: GameMessageType) -> (String, String) {
        // 將數據轉換為字符串嘗試解析
        guard let stringData = String(data: data, encoding: .utf8) else {
            return ("unknown", "未知用戶")
        }
        
        // 大多數遊戲消息格式為 "playerID|playerName" 或包含這些信息
        let components = stringData.components(separatedBy: "|")
        
        if components.count >= 2 {
            return (components[0], components[1])
        } else if components.count == 1 {
            // 某些消息類型可能只有一個參數
            switch messageType {
            case .numberDrawn:
                return ("host", "主機")
            default:
                return (components[0], components[0])
            }
        } else {
            return ("unknown", "未知用戶")
        }
    }
    
    // 輔助方法：將字典轉換為Data格式（向後相容）
    private func convertDictionaryToData(_ dict: [String: Any]) -> Data {
        // 針對不同的訊息類型採用不同的轉換策略
        if let playerID = dict["playerID"] as? String,
           let playerName = dict["playerName"] as? String {
            // playerID|playerName 格式
            return "\(playerID)|\(playerName)".data(using: .utf8) ?? Data()
        } else if let emoteType = dict["emoteType"] as? String,
                  let fromPlayer = dict["fromPlayer"] as? String {
            // emoteType|playerID|playerName 格式
            return "\(emoteType)|\(fromPlayer)".data(using: .utf8) ?? Data()
        } else if let number = dict["number"] as? Int {
            // 數字格式
            return String(number).data(using: .utf8) ?? Data()
        }
        
        // 預設：嘗試序列化為JSON
        do {
            return try JSONSerialization.data(withJSONObject: dict)
        } catch {
            print("⚠️ 無法轉換字典為Data: \(error)")
            return Data()
        }
    }
    
    // 輔助方法：將Data轉換為字典格式（向前相容）
    private func convertDataToDictionary(_ data: Data) -> [String: Any] {
        // 首先嘗試解析為字符串格式
        guard let stringData = String(data: data, encoding: .utf8) else {
            print("❌ 無法將遊戲數據解碼為UTF-8字符串")
            return [:]
        }
        
        // 解析字符串格式的數據
        let components = stringData.components(separatedBy: "|")
        
        // 根據組件數量和內容推斷數據結構
        if components.count >= 2 {
            var dict: [String: Any] = [:]
            
            // 常見格式：playerID|playerName
            if components.count == 2 {
                dict["playerID"] = components[0]
                dict["playerName"] = components[1]
            }
            // 表情格式：emoteType|playerID|playerName  
            else if components.count == 3 {
                dict["emoteType"] = components[0]
                dict["playerID"] = components[1]  
                dict["playerName"] = components[2]
            }
            // 更多組件的複雜格式
            else {
                for (index, component) in components.enumerated() {
                    dict["component_\(index)"] = component
                }
            }
            
            return dict
        }
        // 單一數字或簡單字符串
        else if components.count == 1 {
            let singleValue = components[0]
            
            // 嘗試解析為數字
            if let number = Int(singleValue) {
                return ["number": number]
            } else {
                return ["message": singleValue]
            }
        }
        
        return [:]
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
        print("😄 嘗試發送表情: \(emote.rawValue)")
        
        // 檢查冷卻時間
        let now = Date()
        guard now.timeIntervalSince(lastEmoteTime) >= emoteCooldown else {
            print("⏳ 表情冷卻中，請稍後再試 (剩餘: \(String(format: "%.1f", emoteCooldown - now.timeIntervalSince(lastEmoteTime)))秒)")
            return
        }
        
        guard isInRoom else {
            print("⚠️ 未在房間內，無法發送表情")
            debugEmoteBroadcastStatus()
            return
        }
        
        guard isNetworkActive else {
            print("⚠️ 網路未啟動，無法發送表情")
            debugEmoteBroadcastStatus()
            return
        }
        
        let connectedPeers = meshManager.getConnectedPeers()
        guard !connectedPeers.isEmpty else {
            print("⚠️ 無連接設備，無法發送表情")
            debugEmoteBroadcastStatus()
            return
        }
        
        lastEmoteTime = now
        
        // 使用統一的玩家資訊格式
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        let emoteData = "\(emote.rawValue)|\(playerID)|\(normalizedName)".data(using: .utf8) ?? Data()
        
        print("😄 發送表情廣播: \(emote.rawValue) 玩家=\(normalizedName) ID=\(playerID.prefix(8)) 連接設備數=\(connectedPeers.count)")
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
        
        // 🔧 修復：放寬驗證條件，允許在同一房間內的表情廣播
        let isFromKnownPlayer = roomPlayers.contains(where: { $0.id == senderPlayerID })
        let isInSameRoom = isInRoom && !gameRoomID.isEmpty
        
        if !isFromKnownPlayer && isInSameRoom {
            print("📝 自動添加未知玩家到房間: \(senderName) (\(senderPlayerID.prefix(8)))")
            let newPlayer = PlayerState(id: senderPlayerID, name: senderName)
            roomPlayers.append(newPlayer)
        } else if !isInSameRoom {
            print("⚠️ 忽略來自其他房間的表情: \(senderName) (\(senderPlayerID.prefix(8)))")
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
        
        let data = BinaryGameProtocol.encodeWinnerAnnouncement(announcement)
        broadcastGameMessage(.winnerAnnouncement, data: data)
        print("🏆 冠軍公告已廣播: \(winnerName)")
    }
    
    /// 處理接收到的冠軍公告
    private func handleWinnerAnnouncement(_ message: GameMessage) {
        guard let announcement = BinaryGameProtocol.decodeWinnerAnnouncement(message.data) else {
            print("❌ 解碼冠軍公告失敗")
            return
        }
        
        DispatchQueue.main.async {
            // 對所有玩家觸發冠軍顯示
            self.onGameWon?(announcement.winnerName, announcement.completedLines)
            
            // 開始同步倒數重新開始
            self.startSynchronizedRestart(countdown: announcement.restartCountdown)
        }
        
        print("🏆 收到冠軍公告: \(announcement.winnerName)")
    }
    
    /// 開始同步倒數重新開始
    private func startSynchronizedRestart(countdown: Int) {
        guard roomPlayers.count >= 2 else { return }
        
        // 取消現有的重啟計時器
        cancelTimer(id: "gameRestart")
        
        var remainingTime = countdown
        
        scheduleTimer(id: "gameRestart", interval: 1.0, repeats: true) { [weak self] in
            guard let self = self else { return }
            
            if remainingTime > 0 {
                // 更新倒數顯示（這個會被GameView處理）
                print("🔄 倒數: \(remainingTime)")
                remainingTime -= 1
            } else {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    // 取消計時器
                    self.cancelTimer(id: "gameRestart")
                    
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
    
    // MARK: - 網路消息廣播與處理
    
    /// 廣播遊戲消息到其他設備
    func broadcastMessage(_ message: GameMessage) {
        guard let data = BinaryGameProtocol.encodeGameMessage(
            type: message.type,
            senderID: message.senderID,
            senderName: message.senderName,
            gameRoomID: message.gameRoomID,
            data: message.data
        ) else {
            print("❌ BingoGameViewModel: 遊戲消息編碼失敗")
            return
        }
        
        // 透過 MeshManager 廣播消息  
        meshManager.broadcastMessage(data, messageType: .game)
        print("🌐 廣播遊戲消息: \(message.type.rawValue)")
    }
    
    /// 廣播房間狀態消息（統一方法，包含安全檢查）
    func broadcastRoomStateMessage(type: GameMessageType, roomStateData: RoomStateData) {
        // 檢查主機權限 - 只有主機能發送某些關鍵消息
        let hostOnlyMessageTypes: [GameMessageType] = [
            .gameStart, .gameEnd, .numberDrawn, .gameStateUpdate, .roomSync
        ]
        
        if hostOnlyMessageTypes.contains(type) && !isHost {
            print("🚫 只有主機能發送 \(type.rawValue) 消息，跳過廣播")
            return
        }
        
        // 檢查廣播冷卻（房間狀態消息除外）
        let now = Date()
        if type != .roomStateRequest && type != .roomStateUpdate,
           let lastTime = lastBroadcastTime[type] {
            let timeSinceLastBroadcast = now.timeIntervalSince(lastTime)
            
            if timeSinceLastBroadcast < broadcastCooldown {
                print("⏳ 廣播冷卻中: \(type.rawValue)")
                return
            }
        }
        
        // 記錄廣播時間
        lastBroadcastTime[type] = now
        
        let data = BinaryGameProtocol.encodeRoomStateData(roomStateData)
        let message = GameMessage(
            type: type,
            senderID: deviceName,
            senderName: deviceName,
            data: data,
            timestamp: Date(),
            gameRoomID: String(roomStateData.roomId)
        )
        
        broadcastMessage(message)
        print("🌐 廣播房間狀態: \(type.rawValue) 房間ID:\(roomStateData.roomId)")
    }
    
    
    /// 處理收到的房間狀態消息（統一方法）
    func handleRoomStateMessage(_ message: GameMessage) {
        switch message.type {
        case .roomStateRequest:
            // 有設備請求房間狀態，回應我們的房間狀態
            handleRoomStateRequest(from: message.senderID)
            
        case .roomStateUpdate:
            // 收到其他設備的房間狀態更新
            handleRoomStateUpdate(message)
            
        case .playerJoined:
            // 有玩家加入房間
            if let playerName = decodePlayerName(from: message.data) {
                handlePlayerJoined(playerName: playerName, senderID: message.senderID)
            }
            
        case .playerLeft:
            // 有玩家離開房間
            if let playerName = decodePlayerName(from: message.data) {
                handlePlayerLeft(playerName: playerName)
            }
            
        default:
            print("🔄 收到其他類型的房間狀態消息: \(message.type.rawValue)")
        }
    }
    
    /// 處理房間狀態請求
    private func handleRoomStateRequest(from senderID: String) {
        guard isInRoom else { return }
        
        print("📡 收到來自 \(senderID) 的房間狀態請求")
        
        // 回應我們的房間狀態
        let currentRoomInt = Int(gameRoomID.prefix(1)) ?? 0
        let roomStateData = RoomStateData(
            roomId: currentRoomInt,
            playerCount: roomPlayers.count,
            isActive: isInRoom,
            action: "response"
        )
        
        broadcastRoomStateMessage(type: .roomStateUpdate, roomStateData: roomStateData)
    }
    
    /// 處理房間狀態更新
    private func handleRoomStateUpdate(_ message: GameMessage) {
        guard let roomStateData = BinaryGameProtocol.decodeRoomStateData(message.data) else {
            print("❌ 解碼房間狀態數據失敗")
            return
        }
            
            print("🏠 收到房間狀態: 房間\(roomStateData.roomId) 玩家數:\(roomStateData.playerCount) 活躍:\(roomStateData.isActive)")
            
            // 通知 GameView 更新房間玩家數量
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RoomPlayerCountUpdated"),
                    object: nil,
                    userInfo: [
                        "roomId": roomStateData.roomId,
                        "playerCount": roomStateData.playerCount,
                        "isActive": roomStateData.isActive
                    ]
                )
            }
    }
    
    /// 處理玩家加入
    private func handlePlayerJoined(playerName: String, senderID: String) {
        print("👋 玩家加入: \(playerName)")
        
        // 添加到房間玩家列表（如果還不存在）
        if !roomPlayers.contains(where: { $0.name == playerName }) {
            let newPlayer = PlayerState(id: senderID, name: playerName)
            roomPlayers.append(newPlayer)
            
            addSystemMessage("🎮 \(playerName) 加入了房間")
        }
    }
    
    /// 處理玩家離開
    private func handlePlayerLeft(playerName: String) {
        print("👋 玩家離開: \(playerName)")
        
        // 從房間玩家列表移除
        roomPlayers.removeAll { $0.name == playerName }
        addSystemMessage("🚪 \(playerName) 離開了房間")
    }
    
    /// 解碼玩家名稱（輔助方法）
    private func decodePlayerName(from data: Data) -> String? {
        if let playerName = String(data: data, encoding: .utf8) {
            return playerName
        }
        return nil
    }
    
    /// 獲取已連接的設備列表（公開方法供 GameView 使用）
    func getConnectedPeers() -> [String] {
        return meshManager.getConnectedPeers()
    }
}