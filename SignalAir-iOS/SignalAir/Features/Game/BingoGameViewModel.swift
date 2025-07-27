import Foundation
import SwiftUI
import Combine
import AudioToolbox

/// 賓果遊戲視圖模型 - 重構為純協調器模式
/// 負責協調各個服務，不包含具體業務邏輯
@MainActor
class BingoGameViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI Bindings)
    
    @Published var bingoCard: BingoCard?
    @Published var drawnNumbers: [Int] = []
    @Published var completedLines: Int = 0
    @Published var gameWon: Bool = false
    @Published var gameState: GameRoomState.GameState = .waitingForPlayers
    @Published var countdown: Int = 0
    @Published var currentNumber: Int?
    @Published var roomPlayers: [RoomPlayer] = []
    @Published var roomChatMessages: [RoomChatMessage] = []
    @Published var newChatMessage: String = ""
    @Published var isHost: Bool = false
    @Published var gameRoomID: String = ""
    @Published var connectionStatus: String = "初始化中"
    @Published var syncStatus: String = "未同步"
    @Published var isNetworkActive: Bool = false
    
    // MARK: - Room Management
    
    var roomID: String = ""
    var isInRoom: Bool = false
    var isGameActive: Bool = false
    var deviceName: String
    
    // MARK: - Service Dependencies
    
    private let networkManager: BingoNetworkManager
    private let stateManager: BingoGameStateManager
    private let hostElectionService: HostElectionService
    private let timerService: GameTimerService
    private let chatService: GameChatService
    
    // MARK: - Legacy Dependencies (for compatibility)
    
    private let meshManager: MeshManagerProtocol
    private let securityService: SecurityService
    private let settingsViewModel: SettingsViewModel
    private let languageService: LanguageService
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let maxPlayersPerRoom = 6
    private let minPlayersToStart = 2
    
    // MARK: - Memory Management Constants
    
    private enum PlayerListConstants {
        static let maxPlayerMapSize = 50
        static let cleanupThreshold = 40
        static let playerExpirationTime: TimeInterval = 300 // 5分鐘
    }
    
    // 消息去重機制
    private var lastProcessedMessageIds = Set<String>()
    private let maxProcessedMessageIds = 100
    private let emoteSubject = PassthroughSubject<EmoteEvent, Never>()
    private var lastEmoteTime: Date = Date.distantPast
    private let emoteCooldown: TimeInterval = 2.0
    
    // 【FIX】防止重複觸發自動開始
    private var autoStartTimer: Timer?
    private var lastAutoStartCheck: Date = Date.distantPast
    private let autoStartDebounceInterval: TimeInterval = 0.5
    
    // 主機選舉狀態追蹤
    private var hasHostBeenElected: Bool = false
    
    // MARK: - Publishers
    
    var emotePublisher: AnyPublisher<EmoteEvent, Never> {
        emoteSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Callbacks
    
    var onGameWon: ((String, Int) -> Void)?
    
    // MARK: - Initialization
    
    init(
        meshManager: MeshManagerProtocol,
        securityService: SecurityService,
        settingsViewModel: SettingsViewModel,
        languageService: LanguageService,
        nicknameService: NicknameService
    ) {
        print("🎮 BingoGameViewModel: 開始協調器模式初始化")
        
        // 設置基本屬性
        self.meshManager = meshManager
        self.securityService = securityService
        self.settingsViewModel = settingsViewModel
        self.languageService = languageService
        self.deviceName = nicknameService.nickname.isEmpty ? "用戶" : nicknameService.nickname
        
        // 創建服務實例
        let timerManager = UnifiedTimerManager.shared
        self.networkManager = BingoNetworkManager(
            meshManager: meshManager,
            timerManager: UnifiedTimerManager.shared,
            settingsViewModel: settingsViewModel,
            languageService: languageService
        )
        self.stateManager = BingoGameStateManager(
            timerManager: timerManager,
            networkManager: self.networkManager
        )
        self.hostElectionService = HostElectionService(
            networkManager: self.networkManager,
            deviceName: self.deviceName
        )
        self.timerService = GameTimerService(timerManager: timerManager)
        self.chatService = GameChatService(
            networkManager: self.networkManager,
            deviceName: self.deviceName
        )
        
        print("🎮 BingoGameViewModel: 協調器模式初始化完成")
        
        // 設置服務間的協調
        setupServiceCoordination()
    }
    
    // MARK: - Service Coordination Setup
    
    private func setupServiceCoordination() {
        print("🔗 BingoGameViewModel: 設置服務協調")
        
        // 訂閱狀態管理器的狀態變化
        stateManager.gameStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$gameState)
        
        stateManager.bingoCardPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$bingoCard)
        
        stateManager.drawnNumbersPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$drawnNumbers)
        
        stateManager.currentNumberPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentNumber)
        
        stateManager.gameWonPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$gameWon)
        
        // 訂閱主機選舉服務
        hostElectionService.isHostPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isHost)
        
        // 訂閱計時器服務
        timerService.countdownPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$countdown)
        
        // 訂閱聊天服務
        chatService.chatMessagesPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$roomChatMessages)
        
        // 訂閱網路管理器
        networkManager.networkConnectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$isNetworkActive)
        
        // 處理接收到的遊戲消息
        networkManager.receivedGameMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleReceivedGameMessage(message)
            }
            .store(in: &cancellables)
        
        // 【NEW】監聽房間玩家變化，自動開始遊戲（防抖動）
        $roomPlayers
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates { $0.count == $1.count }
            .sink { [weak self] players in
                self?.checkAndAutoStartGame()
            }
            .store(in: &cancellables)
        
        // 註冊獲勝回調
        stateManager.onGameWon { [weak self] playerID, lines in
            self?.handlePlayerWon(playerID: playerID, lines: lines)
        }
        
        print("✅ BingoGameViewModel: 服務協調設置完成")
    }
    
    // MARK: - Game Lifecycle (Coordinator Methods)
    
    /// 廣播房間狀態消息（用於GameView兼容性）
    func broadcastRoomStateMessage(type: GameMessageType, roomStateData: Data) async {
        do {
            try await networkManager.broadcastGameAction(
                type: type,
                data: roomStateData,
                priority: .normal
            )
        } catch {
            print("❌ BingoGameViewModel: 廣播房間狀態失敗 - \(error)")
        }
    }
    
    /// 發送房間聊天消息（用於GameView兼容性）
    func sendRoomChatMessage() {
        guard !newChatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                try await chatService.sendChatMessage(newChatMessage, to: gameRoomID)
                await MainActor.run {
                    newChatMessage = ""
                }
            } catch {
                print("❌ 發送聊天消息失敗: \(error)")
            }
        }
    }
    
    /// 嘗試加入或創建房間（用於GameView兼容性）
    func attemptToJoinOrCreateRoom(roomID: String) {
        print("🎮 BingoGameViewModel: 嘗試加入或創建房間 \(roomID)")
        joinRoom(roomID)
    }
    
    /// 離開遊戲房間（用於GameView兼容性）
    func leaveGameRoom() {
        print("🎮 BingoGameViewModel: 離開遊戲房間")
        leaveRoom()
    }
    
    /// 開始遊戲
    func startGame() {
        print("🎮 BingoGameViewModel: 協調開始遊戲")
        
        guard isHost else {
            print("⚠️ 只有主機可以開始遊戲")
            return
        }
        
        guard roomPlayers.count >= minPlayersToStart else {
            print("⚠️ 玩家數量不足，需要至少 \(minPlayersToStart) 人")
            return
        }
        
        // 委託給狀態管理器
        stateManager.startGame()
    }
    
    /// 結束遊戲
    func endGame() {
        print("🎮 BingoGameViewModel: 協調結束遊戲")
        stateManager.endGame()
    }
    
    /// 重新開始遊戲
    func restartGame() {
        print("🎮 BingoGameViewModel: 協調重新開始遊戲")
        stateManager.restartGame()
    }
    
    /// 手動抽號
    func drawNumber() {
        print("🎮 BingoGameViewModel: 協調手動抽號")
        
        guard isHost else {
            print("⚠️ 只有主機可以抽號")
            return
        }
        
        stateManager.manualDrawNumber()
    }
    
    /// 標記號碼
    func markNumber(_ number: Int) {
        print("🎮 BingoGameViewModel: 協調標記號碼 \(number)")
        stateManager.markNumber(number)
    }
    
    // MARK: - Host Election (Coordinator Methods)
    
    /// 開始主機選舉
    func startHostElection() {
        print("🗳️ BingoGameViewModel: 協調主機選舉")
        hostElectionService.startHostElection()
    }
    
    /// 成為主機
    func becomeHost() {
        print("🗳️ BingoGameViewModel: 協調成為主機")
        
        // 【FIX】防止重複成為主機
        guard !isHost else {
            print("⚠️ BingoGameViewModel: 已經是主機了")
            return
        }
        
        hostElectionService.becomeHost()
        
        // 成為主機後檢查是否可以自動開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkAndAutoStartGame()
        }
    }
    
    /// 辭去主機
    func resignAsHost() {
        print("🗳️ BingoGameViewModel: 協調辭去主機")
        hostElectionService.resignAsHost()
    }
    
    // MARK: - Chat and Emotes (Coordinator Methods)
    
    /// 發送聊天消息
    func sendChatMessage() {
        guard !newChatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let message = newChatMessage
        newChatMessage = ""
        
        Task {
            do {
                try await chatService.sendChatMessage(message, to: gameRoomID)
            } catch {
                print("❌ 發送聊天消息失敗: \(error)")
            }
        }
    }
    
    /// 【修復】發送表情 - 增強廣播機制
    func sendEmote(_ emote: EmoteType) {
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
        let playerID = ServiceContainer.shared.temporaryIDManager.deviceID
        let normalizedName = deviceName.isEmpty ? "匿名玩家" : deviceName
        
        print("😄 發送表情廣播: \(emote.rawValue) 玩家=\(normalizedName) ID=\(playerID.prefix(8))")
        
        // 使用網路管理器發送表情訊息
        networkManager.broadcastGameMessage(.emote, data: emote.rawValue.data(using: .utf8) ?? Data(), gameRoomID: gameRoomID, deviceName: normalizedName)
        
        // 本地也顯示表情
        triggerEmoteDisplay(nickname: normalizedName, emote: emote)
    }
    
    /// 【修復】處理收到的表情訊息 - 增強容錯性和廣播支持
    private func handleEmote(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 1,
              let emoteType = EmoteType(rawValue: components[0]) else {
            print("❌ 表情訊息格式錯誤: \(String(data: message.data, encoding: .utf8) ?? "無法解析")")
            return
        }
        
        let senderPlayerID = message.senderID
        let senderName = roomPlayers.first(where: { $0.id.uuidString == senderPlayerID })?.name ?? "未知玩家"
        
        // 確保發送者在房間內（防止惡意廣播）
        guard roomPlayers.contains(where: { $0.id.uuidString == senderPlayerID }) else {
            print("⚠️ 忽略來自未知玩家的表情: \(senderName) (\(senderPlayerID.prefix(8)))")
            return
        }
        
        print("😄 收到表情廣播: \(emoteType.rawValue) 來自 \(senderName) (\(senderPlayerID.prefix(8)))")
        triggerEmoteDisplay(nickname: senderName, emote: emoteType)
    }
    
    /// 觸發表情顯示和震動
    private func triggerEmoteDisplay(nickname: String, emote: EmoteType) {
        let translationKey = getEmoteTranslationKey(for: emote)
        let text = languageService.t(translationKey).replacingOccurrences(of: "%@", with: nickname)
        
        emoteSubject.send(EmoteEvent(type: emote, senderName: nickname, timestamp: Date()))
        
        // 觸發震動反饋
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        print("💬 表情: \(text)")
    }
    
    /// 獲取表情的翻譯鍵
    private func getEmoteTranslationKey(for emote: EmoteType) -> String {
        switch emote {
        // 文字表情使用特殊翻譯鍵
        case .bingo: return "emote_bingo"    // "%@ 喊出 BINGO!"
        case .nen: return "emote_nen"        // "%@ 說你嫩！"
        case .wow: return "emote_wow"        // "%@ 大叫太扯！"
        case .dizzy: return "emote_dizzy"    // "%@ 頭暈了"
        case .ring: return "emote_ring"      // "%@ 問你要不要嫁給他"
        
        // 純emoji表情使用原來的template
        default: return emote.template
        }
    }
    
    /// 檢查訊息是否包含表情符號
    private func containsEmote(_ message: String) -> Bool {
        // 簡單檢查是否包含emoji字符
        return message.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji && scalar.value > 0x238C
        }
    }
    
    // MARK: - Room Management (Coordinator Methods)
    
    /// 加入房間
    /// 【ULTRA-SIMPLIFIED】超簡化加入房間 - 第一個加入立即成為主機
    func joinRoom(_ roomID: String) {
        print("🏠 超簡化加入房間: \(roomID)")
        
        self.gameRoomID = roomID
        self.roomID = roomID
        self.isInRoom = true
        
        // 設置網路並開始消息處理
        networkManager.setupMeshNetworking()
        networkManager.startMessageHandling()
        
        // 添加自己到房間玩家列表
        addSelfToRoomPlayers()
        
        // 【簡化】如果沒有連接的設備，立即成為主機
        let connectedPeers = networkManager.connectedPeers
        if connectedPeers.isEmpty {
            print("👑 沒有其他設備，立即成為主機")
            becomeHost()
            hasHostBeenElected = true
            checkAndAutoStartGame()
        } else {
            print("🔍 有其他設備(\(connectedPeers.count)個)，嘗試確定主機")
            performInitialHostElection()
        }
        
        // 【FIXED】等待網路初始化完成後再廣播
        Task {
            // 等待網路完全初始化
            await waitForNetworkInitialization()
            
            do {
                let joinData = createPlayerJoinData()
                try await networkManager.broadcastGameAction(
                    type: .playerJoined,
                    data: joinData,
                    priority: .normal
                )
                print("✅ 已廣播玩家加入消息（二進制）")
                
                // 如果是主機，立即廣播玩家列表
                await MainActor.run {
                    if isHost {
                        Task {
                            await forceBroadcastPlayerListToAll()
                        }
                    }
                }
            } catch {
                print("❌ 廣播玩家加入失敗: \(error)")
                
                // 【NEW】如果失敗，重試機制
                await retryPlayerJoinedBroadcast()
            }
        }
    }
    
    /// 離開房間
    func leaveRoom() {
        print("🏠 BingoGameViewModel: 協調離開房間")
        
        // 【FIX】停止自動開始定時器
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        
        // 停止所有服務
        timerService.stopAllTimers()
        networkManager.stopMessageHandling()
        hostElectionService.cleanup()
        stateManager.resetGameState()
        chatService.clearChatHistory()
        
        // 重置狀態
        gameRoomID = ""
        roomID = ""
        isInRoom = false
        isGameActive = false
        roomPlayers.removeAll()
    }
    
    // MARK: - Network Management (Coordinator Methods)
    
    /// 設置網路
    func setupMeshNetworking() {
        print("🌐 BingoGameViewModel: 協調設置網路")
        networkManager.setupMeshNetworking()
    }
    
    /// 重新連接網路
    func reconnectNetwork() {
        print("🔄 BingoGameViewModel: 協調重新連接網路")
        Task {
            await networkManager.reconnectNetwork()
        }
    }
    
    // MARK: - Message Handling (Coordinator Methods)
    
    /// 處理接收到的遊戲消息
    private func handleReceivedGameMessage(_ message: GameMessage) {
        // 檢查消息是否已經處理過
        let messageId = createMessageId(message)
        guard !lastProcessedMessageIds.contains(messageId) else {
            print("⚠️ 重複消息，跳過處理: \(messageId.prefix(8))")
            return
        }
        
        // 添加到已處理列表
        lastProcessedMessageIds.insert(messageId)
        
        // 限制已處理消息列表大小
        if lastProcessedMessageIds.count > maxProcessedMessageIds {
            let oldestIds = Array(lastProcessedMessageIds.prefix(lastProcessedMessageIds.count - maxProcessedMessageIds))
            for oldId in oldestIds {
                lastProcessedMessageIds.remove(oldId)
            }
        }
        
        print("📥 BingoGameViewModel: 協調處理消息 - \(message.type.stringValue)")
        print("   消息ID: \(messageId.prefix(8))")
        
        switch message.type {
        case .numberDrawn:
            handleNumberDrawMessage(message)
        case .gameStart:
            stateManager.handleGameStart()
        case .gameEnd:
            stateManager.handleGameEnd()
        case .gameRestart:
            stateManager.handleGameRestart()
        case .chatMessage:
            chatService.handleReceivedChatMessage(message)
        case .emote:
            handleEmote(message)
        case .heartbeat:
            handleHeartbeatMessage(message)
        case .playerJoined:
            handlePlayerJoinedMessage(message)
        case .playerLeft:
            handlePlayerLeftMessage(message)
        // 【SIMPLIFIED】移除複雜的房間狀態請求處理
        case .roomStateRequest:
            handleRoomStateRequest(message)
        case .roomStateUpdate:
            handleRoomStateUpdate(message)
        case .keyExchangeResponse:
            handleKeyExchangeResponse(message)
        default:
            print("⚠️ 未處理的消息類型: \(message.type.stringValue)")
        }
    }
    
    /// 處理號碼抽出消息
    private func handleNumberDrawMessage(_ message: GameMessage) {
        print("🎯 ===== 處理號碼抽出消息 =====")
        print("🎯 發送者: \(message.senderName) (\(message.senderID.prefix(8)))")
        print("🎯 數據大小: \(message.data.count) bytes")
        print("🎯 數據內容: \(message.data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        guard message.data.count >= 4 else { 
            print("❌ 號碼抽出消息數據太短: \(message.data.count) bytes")
            return 
        }
        
        let number = message.data.withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
        print("🎯 解析出的號碼: \(number)")
        print("🎯 當前已抽號碼: \(stateManager.drawnNumbers)")
        
        Task { @MainActor in
            print("🎯 開始更新UI - 號碼: \(number)")
            stateManager.handleNumberDrawn(Int(number))
            print("🎯 UI更新完成")
        }
        print("🎯 ===== 處理完成 =====")
    }
    
    /// 處理心跳消息
    private func handleHeartbeatMessage(_ message: GameMessage) {
        hostElectionService.handleHostHeartbeat(from: message.senderID)
    }
    
    /// 【SIMPLIFIED】處理玩家加入消息 - 簡化邏輯移除複雜身份驗證
    private func handlePlayerJoinedMessage(_ message: GameMessage) {
        print("👤 ===== 收到玩家加入消息 =====")
        print("👤 訊息發送者ID: \(message.senderID.prefix(8))")
        print("👤 訊息房間ID: \(message.roomID)")
        print("👤 訊息數據大小: \(message.data.count) bytes")
        print("👤 當前房間玩家數: \(roomPlayers.count)")
        print("👤 當前房間玩家列表: \(roomPlayers.map { $0.name })")
        
        // 【SIMPLIFIED】只解析玩家名稱，不驗證 ID
        guard let playerName = parseSimplePlayerName(message.data) else {
            print("❌ 無法解析玩家名稱")
            return
        }
        
        print("📝 解析到玩家名稱: \(playerName)")
        
        // 【FIX】統一格式化暱稱
        let cleanName = NicknameFormatter.cleanNickname(playerName)
        print("📝 清理後的玩家名稱: \(cleanName)")
        
        // 【SIMPLIFIED】檢查是否為自己 - 只比較名稱
        let myName = NicknameFormatter.cleanNickname(deviceName)
        let isFromSelf = (cleanName == myName)
        
        print("📝 是否為自己: \(isFromSelf) (我的名稱: \(myName))")
        
        if isFromSelf {
            print("📝 這是自己的 playerJoined 訊息，跳過處理")
            print("👤 ===== 玩家加入處理完成 (自己) =====\n")
            return
        }
        
        print("👥 這是其他玩家的 playerJoined 訊息，開始處理...")
        
        // 檢查是否為重複添加
        let isPlayerExists = roomPlayers.contains(where: { $0.name == cleanName })
        print("🔍 玩家是否已存在: \(isPlayerExists)")
        
        if !isPlayerExists {
            let roomPlayer = RoomPlayer(
                name: cleanName,
                playerID: message.senderID.isEmpty ? "peer_\(Date().timeIntervalSince1970)" : message.senderID,
                completedLines: 0,
                hasWon: false
            )
            roomPlayers.append(roomPlayer)
            print("✅ 新玩家已加入: \(cleanName)")
            print("📊 更新後房間玩家數量: \(roomPlayers.count)")
            print("📊 更新後玩家列表: \(roomPlayers.map { $0.name })")
            
            // 【ENHANCED】主機處理新玩家加入
            if isHost {
                print("👑 【主機】新玩家加入，同步遊戲狀態")
                Task {
                    // 1. 立即廣播更新的玩家列表
                    await forceBroadcastPlayerListToAll()
                    
                    // 2. 如果遊戲已在進行，立即同步遊戲狀態給新玩家
                    if gameState == .playing {
                        print("🎲 遊戲進行中，同步當前狀態給新玩家")
                        await broadcastCompleteDrawnNumbers()
                        
                        let gameStateData = createGameStateSyncData()
                        try? await networkManager.broadcastGameAction(
                            type: .gameStart,
                            data: gameStateData,
                            priority: .high
                        )
                    }
                    
                    // 3. 檢查是否可以自動開始遊戲
                    await MainActor.run {
                        print("🎯 主機檢查自動開始條件: 玩家數=\(roomPlayers.count), 需要≥2, 遊戲狀態=\(gameState)")
                        checkAndAutoStartGame()
                    }
                }
            } else {
                // 【SIMPLIFIED】非主機也嘗試成為主機
                if roomPlayers.count >= 2 && !hasHostBeenElected {
                    print("🗳️ 達到玩家數，嘗試成為主機")
                    performInitialHostElection()
                    hasHostBeenElected = true
                }
            }
            
        } else {
            print("⚠️ 玩家已存在，跳過重複添加: \(cleanName)")
        }
        
        print("👤 ===== 玩家加入處理完成 =====\n")
    }
    
    /// 處理房間狀態請求
    private func handleRoomStateRequest(_ message: GameMessage) {
        print("📋 收到房間狀態請求，來源: \(message.senderID.prefix(8))")
        
        // 回覆當前房間狀態
        Task {
            do {
                let roomStateData = createRoomStateData()
                try await networkManager.broadcastGameAction(
                    type: .roomStateUpdate,
                    data: roomStateData,
                    priority: .high
                )
                print("✅ 已回覆房間狀態")
            } catch {
                print("❌ 回覆房間狀態失敗: \(error)")
            }
        }
    }
    
    /// 處理房間狀態更新（僅支援二進制格式）
    private func handleRoomStateUpdate(_ message: GameMessage) {
        print("📋 ===== 收到房間狀態更新 =====")
        print("📋 來源: \(message.senderID.prefix(8))")
        print("📋 房間ID: \(message.roomID)")
        print("📋 數據大小: \(message.data.count) bytes")
        
        // 解析 RoomStateData (二進制格式)
        guard let roomStateData = BinaryGameProtocol.decodeRoomStateData(message.data) else {
            print("❌ 無法解析房間狀態數據（需要二進制格式）")
            return
        }
        
        print("📋 解析為 RoomStateData 格式")
        print("📋 RoomStateData: roomId=\(roomStateData.roomId), playerCount=\(roomStateData.playerCount), isActive=\(roomStateData.isActive), action=\(roomStateData.action)")
        print("📋 遊戲狀態: \(roomStateData.gameState ?? "未知")")
        print("📋 歷史抽中號碼: \(roomStateData.drawnNumbers ?? [])")
        
        // 檢查是否為同一房間
        let receivedRoomID = String(roomStateData.roomId)
        guard receivedRoomID == gameRoomID else {
            print("⚠️ 不同房間的狀態更新，忽略: \(receivedRoomID) vs \(gameRoomID)")
            return
        }
        
        // 【NEW】處理歷史抽中號碼同步
        if let drawnNumbers = roomStateData.drawnNumbers, !drawnNumbers.isEmpty {
            print("🎯 同步歷史抽中號碼: \(drawnNumbers)")
            syncHistoricalDrawnNumbers(drawnNumbers)
        }
        
        // 根據 action 類型處理
        switch roomStateData.action {
        case "player_list_update":
            print("📋 【重要】收到主機的玩家列表更新")
            handlePlayerListUpdate(roomStateData)
        case "request":
            print("📋 收到房間狀態請求，回覆當前狀態")
            broadcastRoomState()
            
        case "update":
            print("📋 收到房間狀態更新")
            
            // 如果包含玩家列表，更新本地狀態
            if let players = roomStateData.players {
                print("📋 更新玩家列表，收到 \(players.count) 位玩家")
                updateRoomPlayersFromRemote(players)
            }
            
            // 【簡化】如果沒有確定主機，進行選舉
            if roomStateData.isActive && !hasHostBeenElected {
                print("📋 檢測到活躍玩家且沒有主機，觸發選舉")
                performInitialHostElection()
            } else if roomStateData.isActive {
                print("📋 檢測到活躍玩家，但已有主機，跳過選舉")
            }
            
            // 檢查自動開始條件
            checkAndAutoStartGame()
            
        default:
            print("⚠️ 未知的房間狀態 action: \(roomStateData.action)")
        }
        
        print("📊 當前房間玩家數: \(roomPlayers.count)")
        print("📊 玩家列表: \(roomPlayers.map { $0.name })")
        
        print("📋 ===== 房間狀態更新完成 =====\n")
    }
    
    /// 處理密鑰交換響應消息
    private func handleKeyExchangeResponse(_ message: GameMessage) {
        print("🔐 收到密鑰交換響應消息，來源: \(message.senderID.prefix(8))")
        print("🔐 數據大小: \(message.data.count) bytes")
        
        // 目前僅記錄，實際密鑰交換邏輯由其他組件處理
        // 可以在此處添加特定的密鑰交換邏輯
    }
    
    /// 創建消息唯一ID（用於去重）
    private func createMessageId(_ message: GameMessage) -> String {
        // 使用消息類型、發送者ID、時間戳和數據哈希創建唯一ID
        let typeString = message.type.stringValue
        let senderString = message.senderID
        let dataHash = message.data.hashValue
        let timestamp = message.timestamp
        
        return "\(typeString)_\(senderString)_\(timestamp)_\(dataHash)"
    }
    
    /// 創建房間狀態數據（使用二進制格式，包含完整玩家列表）
    private func createRoomStateData() -> Data {
        // 將 RoomPlayer 轉換為 RoomPlayerData
        let playersData = roomPlayers.map { roomPlayer in
            RoomPlayerData(
                playerID: roomPlayer.playerID,
                name: roomPlayer.name,
                completedLines: roomPlayer.completedLines,
                hasWon: roomPlayer.hasWon
            )
        }
        
        // 確保房間ID不為空
        let roomIdInt = Int(gameRoomID) ?? {
            print("⚠️ gameRoomID 為空或無效: '\(gameRoomID)'，使用默認值 0")
            return 0
        }()
        
        // 【NEW】獲取歷史抽中號碼和遊戲狀態
        let drawnNumbers = stateManager.drawnNumbers
        let currentGameState = stateManager.gameState
        
        let roomStateData = RoomStateData(
            roomId: roomIdInt,
            playerCount: roomPlayers.count,
            isActive: gameState != .waitingForPlayers,
            action: "update",
            players: playersData,
            drawnNumbers: drawnNumbers.isEmpty ? nil : drawnNumbers,
            gameState: String(describing: currentGameState)
        )
        
        print("📊 創建房間狀態數據:")
        print("   - 房間ID: \(roomIdInt) (原始: '\(gameRoomID)')")
        print("   - 玩家數量: \(roomPlayers.count)")
        print("   - 是否活躍: \(gameState != .waitingForPlayers)")
        print("   - 遊戲狀態: \(currentGameState)")
        print("   - 歷史抽中號碼: \(drawnNumbers)")
        print("   - 玩家列表: \(playersData.map { "\($0.name)(\($0.playerID.prefix(8)))" })")
        
        let binaryData = BinaryGameProtocol.encodeRoomStateData(roomStateData)
        
        if binaryData.isEmpty {
            print("❌ 房間狀態編碼失敗")
        } else {
            print("✅ 房間狀態編碼成功，數據大小: \(binaryData.count) bytes，包含 \(playersData.count) 位玩家")
            print("✅ 玩家列表: \(playersData.map { "\($0.name)(\($0.playerID.prefix(8)))" })")
        }
        
        return binaryData
    }
    
    /// 【FIXED】合併遠程玩家列表而非覆蓋
    private func updateRoomPlayersFromRemote(_ remotePlayers: [RoomPlayerData]) {
        print("🔄 ===== 開始合併房間玩家列表 =====")
        print("🔄 遠程玩家數量: \(remotePlayers.count)")
        print("🔄 本地玩家數量: \(roomPlayers.count)")
        print("🔄 本地玩家: \(roomPlayers.map { "\($0.name)(\($0.playerID.prefix(8)))" })")
        print("🔄 遠程玩家: \(remotePlayers.map { "\($0.name)(\($0.playerID.prefix(8)))" })")
        
        let myDeviceID = ServiceContainer.shared.temporaryIDManager.deviceID
        
        // 【關鍵修復】使用字典來合併玩家，避免重複
        var playerMap: [String: RoomPlayer] = [:]
        
        // 1. 先添加所有本地玩家到字典
        for player in roomPlayers {
            playerMap[player.playerID] = player
            print("📌 保留本地玩家: \(player.name) (\(player.playerID.prefix(8)))")
        }
        
        // 2. 合併遠程玩家（不覆蓋已存在的）
        for remotePlayer in remotePlayers {
            // 如果玩家不存在，添加到字典
            if playerMap[remotePlayer.playerID] == nil {
                let roomPlayer = RoomPlayer(
                    name: remotePlayer.name,
                    playerID: remotePlayer.playerID,
                    completedLines: remotePlayer.completedLines,
                    hasWon: remotePlayer.hasWon
                )
                playerMap[remotePlayer.playerID] = roomPlayer
                print("➕ 新增遠程玩家: \(remotePlayer.name) (\(remotePlayer.playerID.prefix(8)))")
            } else {
                // 更新已存在玩家的狀態（如完成線數、獲勝狀態）
                if let existingPlayer = playerMap[remotePlayer.playerID] {
                    // 由於 RoomPlayer 屬性是不可變的，創建新實例
                    let updatedPlayer = RoomPlayer(
                        name: existingPlayer.name,
                        playerID: existingPlayer.playerID,
                        completedLines: max(existingPlayer.completedLines, remotePlayer.completedLines),
                        hasWon: existingPlayer.hasWon || remotePlayer.hasWon
                    )
                    playerMap[remotePlayer.playerID] = updatedPlayer
                    print("🔄 更新玩家狀態: \(updatedPlayer.name) 線數=\(updatedPlayer.completedLines) 獲勝=\(updatedPlayer.hasWon)")
                }
            }
        }
        
        // 3. 確保自己在列表中
        if playerMap[myDeviceID] == nil {
            let myself = RoomPlayer(
                name: deviceName,
                playerID: myDeviceID,
                completedLines: 0,
                hasWon: false
            )
            playerMap[myDeviceID] = myself
            print("🆕 添加自己到列表: \(myself.name) (\(myDeviceID.prefix(8)))")
        }
        
        // 4. 更新房間玩家列表
        roomPlayers = Array(playerMap.values).sorted { $0.name < $1.name }
        
        // 5. 【NEW】檢查是否需要清理內存
        cleanupPlayerMapIfNeeded()
        
        print("🔄 更新後玩家數量: \(roomPlayers.count)")
        print("🔄 更新後玩家列表: \(roomPlayers.map { "\($0.name)(\($0.playerID.prefix(8)))" })")
        print("🔄 ===== 房間玩家列表更新完成 =====\n")
    }
    
    /// 廣播完整房間狀態
    private func broadcastRoomState() {
        print("📡 ===== 廣播房間狀態 =====")
        print("📡 房間ID: \(gameRoomID)")
        print("📡 玩家數量: \(roomPlayers.count)")
        print("📡 玩家列表: \(roomPlayers.map { $0.name })")
        
        Task {
            do {
                let roomStateData = createRoomStateData()
                try await networkManager.broadcastGameAction(
                    type: .roomStateUpdate,
                    data: roomStateData,
                    priority: .high
                )
                print("✅ 已廣播完整房間狀態，包含 \(roomPlayers.count) 位玩家")
            } catch {
                print("❌ 廣播房間狀態失敗: \(error)")
            }
        }
        
        print("📡 ===== 房間狀態廣播完成 =====\n")
    }
    
    /// 處理玩家離開消息
    private func handlePlayerLeftMessage(_ message: GameMessage) {
        // 從 roomPlayers 移除玩家 - 使用清理後的名稱比較
        let cleanLeavingName = NicknameFormatter.cleanNickname(message.senderName)
        roomPlayers.removeAll { NicknameFormatter.cleanNickname($0.name) == cleanLeavingName }
        print("👋 玩家離開: \(cleanLeavingName)")
        print("📊 房間玩家數量: \(roomPlayers.count)")
    }
    
    /// 處理玩家獲勝
    private func handlePlayerWon(playerID: String, lines: Int) {
        print("🎉 BingoGameViewModel: 玩家獲勝 - \(playerID), \(lines)條線")
        onGameWon?(playerID, lines)
    }
    
    /// 【ENHANCED】增強自動開始檢查 - 處理狀態同步和號碼映射
    private func checkAndAutoStartGame() {
        print("🔍 增強自動開始檢查")
        
        // 防抖：避免頻繁檢查
        let now = Date()
        guard now.timeIntervalSince(lastAutoStartCheck) >= autoStartDebounceInterval else {
            print("   → 防抖中，跳過")
            return
        }
        lastAutoStartCheck = now
        
        let playerCount = roomPlayers.count
        print("   📊 狀態: 主機(\(isHost)) 在房間(\(isInRoom)) 遊戲狀態(\(gameState)) 玩家數(\(playerCount))")
        
        // 【NEW】處理新玩家加入進行中遊戲的情況
        if gameState == .playing && isHost && playerCount >= minPlayersToStart {
            print("🎲 遊戲進行中檢測到新玩家，同步當前狀態")
            syncCurrentGameStateToAllPlayers()
            return
        }
        
        // 【核心條件】檢查是否可以開始新遊戲
        guard isInRoom && 
              gameState == .waitingForPlayers && 
              isHost && 
              playerCount >= minPlayersToStart else {
            print("   → 條件不滿足，跳過")
            return
        }
        
        print("🚀 立即自動開始！玩家: \(roomPlayers.map { $0.name })")
        
        // 【無延遲】直接開始遊戲，減少複雜性
        autoStartTimer?.invalidate()
        startGame()
    }
    
    /// 【NEW】同步當前遊戲狀態給所有玩家（特別是新加入的）
    private func syncCurrentGameStateToAllPlayers() {
        print("🔄 開始同步當前遊戲狀態給所有玩家")
        
        Task {
            do {
                // 1. 廣播已抽中的號碼列表
                await broadcastCompleteDrawnNumbers()
                
                // 2. 廣播當前遊戲狀態
                let gameStateData = createGameStateSyncData()
                try await networkManager.broadcastGameAction(
                    type: .gameStart, // 復用 gameStart 讓新玩家知道遊戲在進行
                    data: gameStateData,
                    priority: .high
                )
                
                // 3. 廣播玩家列表
                await forceBroadcastPlayerListToAll()
                
                print("✅ 遊戲狀態同步完成")
                
            } catch {
                print("❌ 同步遊戲狀態失敗: \(error)")
            }
        }
    }
    
    /// 【NEW】廣播完整的已抽號碼列表
    private func broadcastCompleteDrawnNumbers() async {
        let drawnNumbers = stateManager.drawnNumbers
        print("🎲 廣播已抽號碼列表: \(drawnNumbers)")
        
        for number in drawnNumbers {
            let numberData = withUnsafeBytes(of: Int32(number).littleEndian) { Data($0) }
            do {
                try await networkManager.broadcastGameAction(
                    type: .numberDrawn,
                    data: numberData,
                    priority: .normal
                )
                print("📡 已廣播號碼: \(number)")
                
                // 避免廣播過快
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            } catch {
                print("❌ 廣播號碼 \(number) 失敗: \(error)")
            }
        }
    }
    
    /// 【NEW】創建遊戲狀態同步數據
    private func createGameStateSyncData() -> Data {
        // 簡單的遊戲狀態信息
        let stateInfo = "game_sync".data(using: .utf8) ?? Data()
        return stateInfo
    }
    
    /// 【NEW】等待網路初始化完成
    private func waitForNetworkInitialization() async {
        print("⏳ 等待網路初始化完成...")
        
        let maxWaitTime: TimeInterval = 5.0  // 最多等待5秒
        let checkInterval: TimeInterval = 0.1 // 每0.1秒檢查一次
        let startTime = Date()
        
        while !networkManager.isNetworkActive {
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            if elapsedTime >= maxWaitTime {
                print("⚠️ 網路初始化超時，強制繼續")
                break
            }
            
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        if networkManager.isNetworkActive {
            print("✅ 網路初始化完成")
        } else {
            print("❌ 網路初始化失敗或超時")
        }
    }
    
    /// 【NEW】重試玩家加入廣播
    private func retryPlayerJoinedBroadcast() async {
        print("🔄 重試玩家加入廣播...")
        
        for attempt in 1...3 {
            print("🔄 嘗試第 \(attempt) 次廣播")
            
            // 等待1秒後重試
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // 確保網路仍然活躍
            guard networkManager.isNetworkActive else {
                print("❌ 網路未活躍，跳過重試")
                continue
            }
            
            do {
                let joinData = createPlayerJoinData()
                try await networkManager.broadcastGameAction(
                    type: .playerJoined,
                    data: joinData,
                    priority: .high  // 使用高優先級
                )
                print("✅ 重試成功：已廣播玩家加入消息")
                return
            } catch {
                print("❌ 第 \(attempt) 次重試失敗: \(error)")
            }
        }
        
        print("❌ 所有重試都失敗，放棄廣播")
    }
    
    /// 【SIMPLIFIED】超簡化主機選舉 - 第一個加入的直接成為主機
    private func performInitialHostElection() {
        print("👑 簡單主機選舉：第一個加入的成為主機")
        
        // 如果房間裡只有我，直接成為主機
        if roomPlayers.count <= 1 {
            print("👑 我是第一個或唯一玩家，直接成為主機")
            becomeHost()
            hasHostBeenElected = true
            return
        }
        
        // 如果已經有其他玩家且沒有主機，檢查誰先加入
        let myDeviceID = ServiceContainer.shared.temporaryIDManager.deviceID
        let isMyPlayerInList = roomPlayers.contains { $0.playerID == myDeviceID }
        
        if isMyPlayerInList {
            // 檢查是否有比我更早加入的玩家
            let hasEarlierPlayer = roomPlayers.contains { $0.playerID != myDeviceID }
            
            if !hasEarlierPlayer {
                print("👑 沒有更早的玩家，我成為主機")
                becomeHost()
            } else {
                print("👥 有更早的玩家，我是普通玩家")
                isHost = false
            }
        } else {
            print("👑 找不到自己在玩家列表中，強制成為主機")
            becomeHost()
        }
        
        hasHostBeenElected = true
    }
    
    /// 【NEW】添加自己到房間玩家列表
    private func addSelfToRoomPlayers() {
        // 統一格式化自己的暱稱
        let cleanDeviceName = NicknameFormatter.cleanNickname(deviceName)
        let selfPlayer = RoomPlayer(
            name: cleanDeviceName,
            playerID: ServiceContainer.shared.temporaryIDManager.deviceID,
            completedLines: 0,
            hasWon: false
        )
        
        // 避免重複添加 - 使用清理後的名稱比較
        if !roomPlayers.contains(where: { NicknameFormatter.cleanNickname($0.name) == cleanDeviceName }) {
            roomPlayers.append(selfPlayer)
            print("✅ 自己已添加到房間: \(cleanDeviceName)")
            print("📊 房間玩家數量: \(roomPlayers.count)")
        } else {
            print("⚠️ 自己已存在房間列表中: \(cleanDeviceName)")
        }
    }
    
    /// 【SIMPLIFIED】簡化已連接玩家處理 - 專注於基本消息傳遞
    private func addConnectedPlayersToRoom() {
        let connectedPeers = networkManager.connectedPeers
        
        print("🔍 BingoGameViewModel: 基本房間狀態：")
        print("  📡 網路層連接設備: \(connectedPeers)")
        print("  ✅ 房間內確認玩家: \(roomPlayers.map { $0.name })")
        print("  📊 當前房間玩家數: \(roomPlayers.count)")
        
        // 【簡化】不再進行複雜的房間確認
        // 依賴正常的 playerJoined 消息流程
        
        // 如果有連接的設備但房間玩家數不足，給一點時間讓消息傳遞
        if connectedPeers.count > 0 && roomPlayers.count < minPlayersToStart {
            print("⏳ 等待其他設備發送 playerJoined 消息...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.checkAndAutoStartGame()
            }
        }
    }
    
    /// 【NEW】加入房間時的智能主機選舉
    private func handleHostElectionOnJoin() async {
        print("🔍 BingoGameViewModel: 進行智能主機選舉")
        
        // 等待網路穩定
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        let peers = networkManager.connectedPeers
        print("🔍 已連接設備: \(peers)")
        
        if peers.isEmpty {
            // 只有自己，成為主機
            print("👑 BingoGameViewModel: 無其他設備，成為主機")
            await MainActor.run {
                becomeHost()
            }
        } else {
            // 有其他設備，等待主機心跳或開始選舉
            print("🕰️ BingoGameViewModel: 有其他設備，等待主機心跳")
            await waitForHostOrStartElection()
        }
    }
    
    /// 【NEW】等待主機心跳或開始選舉
    private func waitForHostOrStartElection() async {
        // 等待3秒看是否有主機心跳
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
        
        await MainActor.run {
            // 如果還沒有主機，開始選舉
            if !isHost && (hostElectionService.currentHost?.isEmpty ?? true) {
                print("🗳️ BingoGameViewModel: 無主機心跳，開始選舉")
                startHostElection()
            }
        }
    }
    
    // MARK: - Computed Properties (UI Support)
    
    /// 是否可以開始遊戲
    var canStartGame: Bool {
        return isHost && roomPlayers.count >= minPlayersToStart && gameState == .waitingForPlayers
    }
    
    /// 是否可以抽號
    var canDrawNumber: Bool {
        return isHost && gameState == .playing
    }
    
    /// 房間是否已滿
    var isRoomFull: Bool {
        return roomPlayers.count >= maxPlayersPerRoom
    }
    
    // MARK: - Room Confirmation Methods - REMOVED (已移除複雜的房間確認機制)
    
    // MARK: - Player List Update Methods
    
    /// 【NEW】處理主機廣播的玩家列表更新
    private func handlePlayerListUpdate(_ roomStateData: RoomStateData) {
        print("👥 ===== 處理玩家列表更新 =====")
        print("   - 收到玩家數: \(roomStateData.playerCount)")
        print("   - 當前玩家數: \(roomPlayers.count)")
        print("   - 遊戲狀態: \(roomStateData.gameState ?? "未知")")
        print("   - 歷史抽中號碼: \(roomStateData.drawnNumbers ?? [])")
        
        // 如果自己是主機，忽略自己發送的更新
        if isHost {
            print("👑 主機忽略自己的玩家列表更新")
            return
        }
        
        // 【NEW】先同步歷史抽中號碼
        if let drawnNumbers = roomStateData.drawnNumbers, !drawnNumbers.isEmpty {
            print("🎯 玩家列表更新包含歷史抽中號碼: \(drawnNumbers)")
            syncHistoricalDrawnNumbers(drawnNumbers)
        }
        
        // 【SIMPLIFIED】直接使用主機的玩家列表，不進行複雜驗證
        if let players = roomStateData.players {
            print("📝 同步主機的玩家列表:")
            
            var newRoomPlayers: [RoomPlayer] = []
            for playerData in players {
                let roomPlayer = RoomPlayer(
                    name: playerData.name,
                    playerID: playerData.playerID,
                    completedLines: playerData.completedLines,
                    hasWon: playerData.hasWon
                )
                newRoomPlayers.append(roomPlayer)
                print("   - \(playerData.name)")
            }
            
            // 【CRITICAL】直接替換玩家列表
            roomPlayers = newRoomPlayers
            print("✅ 玩家列表已同步: \(roomPlayers.count) 人")
            print("📊 同步後玩家列表: \(roomPlayers.map { $0.name })")
            
            // 檢查是否滿足遊戲開始條件
            if roomPlayers.count >= 2 {
                print("🎯 玩家數量滿足，等待主機開始遊戲")
            }
        } else {
            print("⚠️ 房間狀態數據中沒有玩家列表信息")
        }
        
        print("👥 ===== 玩家列表更新完成 =====")
    }
    
    /// 【NEW】內存管理 - 清理過期玩家數據
    private func cleanupPlayerMapIfNeeded() {
        guard roomPlayers.count > PlayerListConstants.cleanupThreshold else { return }
        
        let deviceID = ServiceContainer.shared.temporaryIDManager.deviceID
        let originalCount = roomPlayers.count
        
        // 分離自己和其他玩家
        let selfPlayer = roomPlayers.filter { $0.playerID == deviceID }
        let otherPlayers = roomPlayers.filter { $0.playerID != deviceID }
        
        // 限制其他玩家數量
        let maxOtherPlayers = PlayerListConstants.maxPlayerMapSize - selfPlayer.count
        let keepOtherPlayers = Array(otherPlayers.prefix(maxOtherPlayers))
        
        // 重新組合列表
        roomPlayers = selfPlayer + keepOtherPlayers
        
        print("🧹 清理玩家列表: \(originalCount) → \(roomPlayers.count) 個玩家")
    }
    
    /// 【NEW】同步歷史抽中號碼到本地賓果卡
    private func syncHistoricalDrawnNumbers(_ drawnNumbers: [Int]) {
        print("🎯 ===== 同步歷史抽中號碼 =====")
        print("🎯 接收到的歷史號碼: \(drawnNumbers)")
        print("🎯 本地已抽號碼: \(stateManager.drawnNumbers)")
        
        // 找出需要同步的新號碼
        let currentDrawnNumbers = Set(stateManager.drawnNumbers)
        let newNumbers = drawnNumbers.filter { !currentDrawnNumbers.contains($0) }
        
        if !newNumbers.isEmpty {
            print("🎯 需要同步的新號碼: \(newNumbers)")
            
            // 批量同步歷史號碼到狀態管理器
            for number in newNumbers {
                print("🎯 同步號碼: \(number)")
                stateManager.handleNumberDrawn(number)
            }
            
            print("✅ 歷史抽中號碼同步完成")
            print("✅ 更新後的本地已抽號碼: \(stateManager.drawnNumbers)")
        } else {
            print("ℹ️ 沒有需要同步的新號碼")
        }
        
        print("🎯 ===== 歷史號碼同步完成 =====")
    }
    
    // MARK: - Force Broadcast Methods
    
    /// 【NEW】主機強制廣播完整玩家列表給所有設備
    private func forceBroadcastPlayerListToAll() async {
        guard isHost else { 
            print("⚠️ 非主機無法廣播玩家列表")
            return 
        }
        
        print("👑 【主機】強制廣播完整玩家列表")
        print("   - 房間玩家數: \(roomPlayers.count)")
        print("   - 玩家列表: \(roomPlayers.map { $0.name })")
        
        // 【NEW】包含歷史抽中號碼和遊戲狀態
        let drawnNumbers = stateManager.drawnNumbers
        let currentGameState = stateManager.gameState
        
        print("   - 遊戲狀態: \(currentGameState)")
        print("   - 歷史抽中號碼: \(drawnNumbers)")
        
        // 創建房間狀態數據
        let roomStateData = RoomStateData(
            roomId: Int(gameRoomID) ?? 0,
            playerCount: roomPlayers.count,
            isActive: roomPlayers.count >= 2,
            action: "player_list_update",
            players: roomPlayers.map { player in
                RoomPlayerData(
                    playerID: player.playerID,
                    name: player.name,
                    completedLines: player.completedLines,
                    hasWon: player.hasWon
                )
            },
            drawnNumbers: drawnNumbers.isEmpty ? nil : drawnNumbers,
            gameState: String(describing: currentGameState)
        )
        
        // 使用二進制編碼
        let stateData = BinaryGameProtocol.encodeRoomStateData(roomStateData)
        
        do {
            try await networkManager.broadcastGameAction(
                type: .roomStateUpdate,
                data: stateData,
                priority: .high
            )
            print("✅ 主機已廣播完整玩家列表及遊戲狀態")
        } catch {
            print("❌ 廣播玩家列表失敗: \(error)")
        }
    }
    
    // MARK: - Data Creation Methods
    
    /// 【FIXED】創建玩家加入數據 - 簡化格式
    private func createPlayerJoinData() -> Data {
        let playerName = NicknameFormatter.cleanNickname(deviceName)
        let deviceID = ServiceContainer.shared.temporaryIDManager.deviceID
        
        print("📦 【FIXED】創建玩家加入數據:")
        print("   - 設備ID: \(deviceID.prefix(8))")
        print("   - 玩家名稱: \(playerName)")
        print("   - 房間ID: \(gameRoomID)")
        
        // 使用二進制協議編碼玩家加入數據
        return BinaryGameProtocol.encodePlayerJoined(playerID: deviceID, playerName: playerName)
    }
    
    /// 【FIXED】解析玩家加入數據 - 使用標準二進制格式
    /// 使用二進制協議解析玩家加入數據
    private func parsePlayerJoinDataBinary(_ data: Data) -> (playerID: String, playerName: String)? {
        do {
            let playerInfo = try BinaryGameProtocol.decodePlayerJoined(from: data)
            print("📦 二進制解析玩家加入數據成功: \(playerInfo.playerName) (\(playerInfo.playerID.prefix(8)))")
            return playerInfo
        } catch {
            print("❌ 二進制解析失敗: \(error)")
            
            // 備用：嘗試字符串解析（為了兼容性）
            return parsePlayerJoinDataLegacy(data)
        }
    }
    
    /// 簡化的玩家名稱解析 - 只提取名稱
    private func parseSimplePlayerName(_ data: Data) -> String? {
        // 首先嘗試二進制解析
        do {
            let playerInfo = try BinaryGameProtocol.decodePlayerJoined(from: data)
            print("📦 二進制解析成功，提取玩家名稱: \(playerInfo.playerName)")
            return playerInfo.playerName
        } catch {
            print("⚠️ 二進制解析失敗，嘗試字符串解析: \(error)")
        }
        
        // 備用：字符串解析
        guard let dataString = String(data: data, encoding: .utf8) else {
            print("❌ 無法解析數據為字符串")
            return nil
        }
        
        // 如果包含 "|" 分隔符，提取名稱部分
        let components = dataString.components(separatedBy: "|")
        if components.count >= 2 {
            let playerName = components[1]
            print("📦 字符串解析成功，提取玩家名稱: \(playerName)")
            return playerName
        }
        
        // 如果沒有分隔符，整個字符串就是名稱
        print("📦 直接使用字符串作為玩家名稱: \(dataString)")
        return dataString
    }
    
    /// 備用字符串解析方法（保持兼容性）
    private func parsePlayerJoinDataLegacy(_ data: Data) -> (playerID: String, playerName: String)? {
        guard let dataString = String(data: data, encoding: .utf8) else {
            print("❌ 無法解析數據為字符串")
            return nil
        }
        
        let components = dataString.components(separatedBy: "|")
        guard components.count >= 2 else {
            print("❌ playerJoined 數據格式錯誤: \(dataString)")
            return nil
        }
        
        let playerID = components[0]
        let playerName = components[1]
        
        print("📦 字符串解析玩家加入數據成功: \(playerName) (\(playerID.prefix(8)))")
        return (playerID: playerID, playerName: playerName)
    }
    
    
    // MARK: - Lifecycle
    
    /// 清理資源
    func cleanup() {
        print("🧹 BingoGameViewModel: 協調器清理資源")
        
        cancellables.removeAll()
        timerService.cleanup()
        networkManager.cleanup()
        hostElectionService.cleanup()
        stateManager.cleanup()
        chatService.cleanup()
    }
    
    deinit {
        print("🗑️ BingoGameViewModel: 協調器 deinit")
        // 【FIX】避免deinit中調用MainActor方法，直接清理
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

/// 【NEW】玩家加入信息結構

/// 表情事件
struct EmoteEvent {
    let type: EmoteType
    let senderName: String
    let timestamp: Date
    
    /// 表情文本表示（用於GameView兼容性）
    var text: String {
        return type.rawValue
    }
    
    /// 是否為純表情符號（用於GameView兼容性）
    var isPureEmoji: Bool {
        // 簡單檢查是否只包含emoji字符
        return type.rawValue.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji
        }
    }
}

// MARK: - Legacy Compatibility

extension BingoGameViewModel {
    
    /// 觸發異步初始化（兼容性方法）
    func triggerAsyncInitialization() {
        print("🔄 BingoGameViewModel: 兼容性異步初始化（無操作）")
        // 在新架構中不需要複雜的異步初始化
    }
    
    /// 獲取連接的對等點
    var connectedPeers: [String] {
        return meshManager.getConnectedPeers()
    }
    
    /// 更新連接狀態
    func updateConnectionStatus(_ status: String) {
        connectionStatus = status
    }
    
    /// 更新同步狀態
    func updateSyncStatus(_ status: String) {
        syncStatus = status
    }
}