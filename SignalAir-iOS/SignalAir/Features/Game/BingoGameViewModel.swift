import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Emote Types
enum EmoteType: String, Codable, Hashable {
    case bingo
    case nen
    case wow
    case boom // 💥
    case pirate // 🏴‍☠️
    case rocket // 🚀
    case bug // 🐛
    case fly // 🪰
    case fire // 🔥
    case poop // 💩
    case clown // 🤡
    case mindBlown // 🤯
    case pinch // 🤏
    case cockroach // 🪳
    case eyeRoll // 🙄
    case burger // 🍔
    case rockOn // 🤟
    case battery // 🔋
    case dizzy // 😵‍💫
    case bottle // 🍼
    case skull // 💀
    case mouse // 🐭
    case trophy // 🏆
    case ring // 💍
    case juggler // 🤹‍♂️
    
    var emoji: String {
        switch self {
        case .bingo: return "🎉"
        case .nen: return "🤔"
        case .wow: return "😱"
        case .boom: return "💥"
        case .pirate: return "🏴‍☠️"
        case .rocket: return "🚀"
        case .bug: return "🐛"
        case .fly: return "🪰"
        case .fire: return "🔥"
        case .poop: return "💩"
        case .clown: return "🤡"
        case .mindBlown: return "🤯"
        case .pinch: return "🤏"
        case .cockroach: return "🪳"
        case .eyeRoll: return "🙄"
        case .burger: return "🍔"
        case .rockOn: return "🤟"
        case .battery: return "🔋"
        case .dizzy: return "😵‍💫"
        case .bottle: return "🍼"
        case .skull: return "💀"
        case .mouse: return "🐭"
        case .trophy: return "🏆"
        case .ring: return "💍"
        case .juggler: return "🤹‍♂️"
        }
    }
    
    var template: String {
        switch self {
        case .bingo: return "%@ 喊出 BINGO!"
        case .nen: return "%@ 說你嫩！"
        case .wow: return "%@ 大叫太扯！"
        case .boom: return "%@ 💥"
        case .pirate: return "%@ 🏴‍☠️"
        case .rocket: return "%@ 說一起飛向宇宙"
        case .bug: return "%@ 🐛"
        case .fly: return "%@ 🪰"
        case .fire: return "%@ 🔥"
        case .poop: return "%@ 💩"
        case .clown: return "%@ 🤡"
        case .mindBlown: return "%@ 🤯"
        case .pinch: return "%@ 🤏"
        case .cockroach: return "%@ 🪳"
        case .eyeRoll: return "%@ 🙄"
        case .burger: return "%@ 想吃漢堡 "
        case .rockOn: return "%@ 🤟"
        case .battery: return "%@ 需要充電 "
        case .dizzy: return "%@ 頭暈了 "
        case .bottle: return "%@ 🍼"
        case .skull: return "%@ 💀"
        case .mouse: return "%@ 説家裡有老鼠 "
        case .trophy: return "%@ 🏆"
        case .ring: return "%@ 問你要不要嫁給他"
        case .juggler: return "%@ 🤹‍♂️"
        }
    }
    
    var isPureEmoji: Bool {
        switch self {
        case .boom, .pirate, .bug, .fly, .fire, .poop, .clown, .mindBlown, .pinch, .cockroach, .eyeRoll, .rockOn, .bottle, .skull, .trophy, .juggler:
            return true
        case .bingo, .nen, .wow, .rocket, .burger, .battery, .dizzy, .mouse, .ring:
            return false
        }
    }
}

// MARK: - Emote Event
struct EmoteEvent {
    let text: String
    let isPureEmoji: Bool // 是否為純emoji
}

class BingoGameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bingoCard: BingoCard?
    @Published var drawnNumbers: [Int] = []
    @Published var completedLines: Int = 0
    @Published var gameWon: Bool = false
    @Published var roomPlayers: [PlayerState] = []
    @Published var roomChatMessages: [RoomChatMessage] = []
    @Published var newChatMessage: String = ""
    @Published var gameState: GameRoomState.GameState = .waitingForPlayers
    @Published var countdown: Int = 0
    @Published var currentNumber: Int?
    @Published var isHost: Bool = false
    @Published var gameRoomID: String = ""
    @Published var connectionStatus: String = ""
    @Published var syncStatus: String = ""
    @Published var roomID: String = ""
    @Published var isInRoom: Bool = false
    @Published var isGameActive: Bool = false
    
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
    private var meshManager: MeshManagerProtocol
    private let securityService: SecurityService
    private let settingsViewModel: SettingsViewModel
    private let languageService: LanguageService
    
    // MARK: - 遊戲管理
    var deviceName: String
    private var playerID: String
    private var hostID: String = ""
    private var gameRoomState: GameRoomState?
    
    // MARK: - 定時器
    private var drawTimer: Timer?
    private var countdownTimer: Timer?
    private var syncTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var hostPromotionTimer: Timer?
    
    // MARK: - 網路狀態
    private var isNetworkActive: Bool = false
    private var lastSyncTime: Date = Date()
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    
    // MARK: - 初始化
    init(
        meshManager: MeshManagerProtocol? = nil,
        securityService: SecurityService? = nil,
        settingsViewModel: SettingsViewModel? = nil,
        languageService: LanguageService
    ) {
        self.meshManager = meshManager ?? ServiceContainer.shared.meshManager!
        self.securityService = securityService ?? ServiceContainer.shared.securityService
        self.settingsViewModel = settingsViewModel ?? ServiceContainer.shared.settingsViewModel
        self.languageService = languageService
        
        // 初始化玩家資訊 (使用正確的暱稱服務)
        let nicknameService = ServiceContainer.shared.nicknameService
        let userNickname = nicknameService.nickname
        self.deviceName = userNickname // nicknameService已經返回清理後的暱稱，避免重複清理
        
        // 持久化玩家ID（修復每次重新生成的問題）
        if let savedPlayerID = UserDefaults.standard.string(forKey: "BingoPlayerID") {
            self.playerID = savedPlayerID
            print("🎮 使用已保存的玩家ID: \(savedPlayerID.prefix(8))")
        } else {
            self.playerID = UUID().uuidString
            UserDefaults.standard.set(self.playerID, forKey: "BingoPlayerID")
            print("🎮 創建新的玩家ID: \(self.playerID.prefix(8))")
        }
        
        print("🎮 BingoGameViewModel: 初始化暱稱 來源=NicknameService 暱稱='\(self.deviceName)'")
        
        // 設置初始狀態文字
        self.connectionStatus = self.languageService.t("offline")
        self.syncStatus = self.languageService.t("waiting_sync")
        
        setupMeshNetworking()
        setupNotificationObservers()
        setupNicknameObserver()
        startHeartbeat()
        
        print("🎮 BingoGameViewModel: 初始化完成")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
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
    
    private func setupMeshNetworking() {
        meshManager.startMeshNetwork()
        isNetworkActive = true
        
        // 改用 NotificationCenter 接收遊戲訊息
        // meshManager.onMessageReceived 已由 ServiceContainer 統一處理
        
        meshManager.onPeerConnected = { [weak self] peerID in
            DispatchQueue.main.async {
                self?.handlePeerConnected(peerID)
            }
        }
        
        meshManager.onPeerDisconnected = { [weak self] peerID in
            DispatchQueue.main.async {
                self?.handlePeerDisconnected(peerID)
            }
        }
        
        updateConnectionStatus()
    }
    
    // MARK: - 遊戲房間管理
    
    func createGameRoom() {
        gameRoomID = UUID().uuidString
        hostID = playerID
        isHost = true
        isInRoom = true
        
        let initialPlayer = PlayerState(id: playerID, name: deviceName)
        roomPlayers = [initialPlayer]
        
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
    
    func joinGameRoom(_ roomID: String) {
        gameRoomID = roomID
        isHost = false
        isInRoom = true
        
        // 添加本機玩家到玩家列表
        let localPlayer = PlayerState(id: playerID, name: deviceName)
        roomPlayers = [localPlayer]
        
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
        
        bingoCard = generateBingoCard()
        print("🚪 加入房間：\(roomID.prefix(8)) 玩家=\(deviceName) ID=\(playerID)")
        addSystemMessage("\(languageService.t("joining_room")) \(roomID.prefix(8))")
        
        startSyncTimer()
    }
    
    func attemptToJoinOrCreateRoom(roomID: String) {
        self.gameRoomID = roomID
        isInRoom = true
        
        // 添加本機玩家到玩家列表
        let localPlayer = PlayerState(id: playerID, name: deviceName)
        roomPlayers = [localPlayer]
        
        print("🔄 嘗試加入或創建房間：\(roomID) 玩家=\(deviceName) ID=\(playerID)")
        
        // 先嘗試加入現有房間
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
        
        // 設置主機推廣定時器，如果5秒內沒有收到房間同步，則成為主機
        hostPromotionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // 如果還沒有收到其他主機的房間同步，則成為主機
            if !self.isHost && self.roomPlayers.count == 1 {
                self.becomeRoomHost()
            }
        }
        
        bingoCard = generateBingoCard()
        addSystemMessage("正在連接房間 \(roomID)...")
        startSyncTimer()
    }
    
    private func becomeRoomHost() {
        // 取消主機推廣定時器
        hostPromotionTimer?.invalidate()
        hostPromotionTimer = nil
        
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
        addSystemMessage("已成為房間主機")
        
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
        hostPromotionTimer?.invalidate()
        hostPromotionTimer = nil
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
        
        // 確保本機玩家存在於玩家列表中
        var updatedPlayers = roomState.players
        let localPlayerExists = updatedPlayers.contains { $0.id == playerID }
        
        if !localPlayerExists && isInRoom {
            let localPlayer = PlayerState(id: playerID, name: deviceName)
            updatedPlayers.append(localPlayer)
            print("➕ 添加本機玩家到同步列表：\(deviceName) (\(playerID))")
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
        guard isHost else { 
            print("🚫 非主機收到 reconnect_request，忽略")
            return 
        }
        
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
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
        
        // 檢查玩家是否已在房間內
        DispatchQueue.main.async {
            if let existingIndex = self.roomPlayers.firstIndex(where: { $0.id == playerState.id }) {
                // 更新現有玩家資訊
                self.roomPlayers[existingIndex] = playerState
                print("🔄 更新現有玩家：\(playerState.name) (\(playerState.id))")
            } else {
                // 添加新玩家
                self.roomPlayers.append(playerState)
                print("✅ 新玩家加入房間：\(playerState.name) (\(playerState.id)) 房間人數：(\(self.roomPlayers.count)/\(self.maxPlayersPerRoom))")
                
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
            self.broadcastGameMessage(.roomSync, data: self.encodeGameRoomState())
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
        
        if let index = roomPlayers.firstIndex(where: { $0.id == playerState.id }) {
            roomPlayers[index] = playerState
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
        roomChatMessages.append(chatMessage)
        
        // 保持最多 100 條訊息
        if roomChatMessages.count > 100 {
            roomChatMessages.removeFirst()
        }
    }
    
    private func handleGameStart(_ message: GameMessage) {
        // 非主機玩家收到遊戲開始訊息
        if !isHost {
            gameState = .countdown
            countdown = 3
            addSystemMessage("遊戲即將開始...")
            
            // 非主機玩家也顯示倒數計時
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if self.countdown > 0 {
                        self.addSystemMessage("\(self.countdown)")
                        print("⏰ 非主機倒數計時: \(self.countdown)")
                    }
                    
                    self.countdown -= 1
                    
                    if self.countdown < 0 {
                        self.countdownTimer?.invalidate()
                        self.gameState = .playing
                        self.addSystemMessage("開始抽卡！")
                    }
                }
            }
        } else {
            // 主機玩家廣播狀態更新
            gameState = .playing
            broadcastGameMessage(.gameStateUpdate, data: encodeGameState(.playing))
        }
    }
    
    private func handleGameEnd(_ message: GameMessage) {
        gameState = .finished
        broadcastGameMessage(.gameEnd, data: Data())
    }
    
    // MARK: - 遊戲控制
    
    func startGame() {
        guard isHost && (gameState == .waitingForPlayers || gameState == .countdown) else { return }
        
        // 檢查最少人數要求
        if roomPlayers.count < minPlayersToStart {
            print("⚠️ 房間人數不足，需要至少 \(minPlayersToStart) 人才能開始遊戲")
            addSystemMessage("需要至少 \(minPlayersToStart) 人才能開始遊戲")
            return
        }
        
        gameState = .countdown
        countdown = 3  // 改為3秒倒數
        
        print("🎮 開始遊戲，房間人數：\(roomPlayers.count)/\(maxPlayersPerRoom)")
        
        // 顯示遊戲即將開始的系統訊息
        addSystemMessage("遊戲即將開始...")
        
        broadcastGameMessage(.gameStart, data: Data())
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if self.countdown > 0 {
                    // 在聊天室顯示倒數
                    self.addSystemMessage("\(self.countdown)")
                    print("⏰ 倒數計時: \(self.countdown)")
                }
                
                self.countdown -= 1
                
                if self.countdown < 0 {
                    self.countdownTimer?.invalidate()
                    self.gameState = .playing
                    self.addSystemMessage("開始抽卡！")
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
        
        // 然後每3秒抽一張新卡
        drawTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.drawNextNumber()
        }
    }
    
    private func drawNextNumber() {
        let availableNumbers = Array(1...60).filter { !drawnNumbers.contains($0) }
        guard !availableNumbers.isEmpty else {
            endGame()
            return
        }
        
        let randomNumber = availableNumbers.randomElement()!
        drawnNumbers.append(randomNumber)
        currentNumber = randomNumber
        
        let numberData = String(randomNumber).data(using: .utf8) ?? Data()
        broadcastGameMessage(.numberDrawn, data: numberData)
        
        checkBingoCard(for: randomNumber)
    }
    
    func endGame() {
        drawTimer?.invalidate()
        countdownTimer?.invalidate()
        
        gameState = .finished
        broadcastGameMessage(.gameEnd, data: Data())
    }
    
    // MARK: - Bingo 卡片管理
    
    private func generateBingoCard() -> BingoCard {
        var numbers: [Int] = []
        
        // B列: 1-12
        numbers.append(contentsOf: Array(1...12).shuffled().prefix(5))
        // I列: 13-24
        numbers.append(contentsOf: Array(13...24).shuffled().prefix(5))
        // N列: 25-36（中心為免費格）
        let nNumbers = Array(25...36).shuffled().prefix(4)
        numbers.append(contentsOf: nNumbers.prefix(2))
        numbers.append(0) // 免費格
        numbers.append(contentsOf: nNumbers.suffix(2))
        // G列: 37-48
        numbers.append(contentsOf: Array(37...48).shuffled().prefix(5))
        // O列: 49-60
        numbers.append(contentsOf: Array(49...60).shuffled().prefix(5))
        
        return BingoCard(numbers: numbers)
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
    
    // MARK: - 網路通訊
    
    private func broadcastGameMessage(_ type: GameMessageType, data: Data) {
        // 檢查網路連接狀態
        guard isNetworkActive else {
            print("📡 廣播跳過: 網路未啟動 (type: \(type.rawValue))")
            return
        }
        
        // 檢查是否有連接的設備
        guard meshManager.getConnectedPeers().count > 0 else {
            print("📡 廣播跳過: 無連接設備 (type: \(type.rawValue))")
            return
        }
        
        Task {
            do {
                // 創建遊戲訊息內容（包含遊戲特定信息）
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
                
                // 添加發送者名稱（deviceName已經是清理過的暱稱）
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
                
                // 使用標準 BinaryMessageEncoder 編碼並廣播
                let binaryData = try BinaryMessageEncoder.encode(meshMessage)
                meshManager.broadcastMessage(binaryData, messageType: .game)
                
                print("📡 標準格式遊戲訊息已廣播: \(type.rawValue) (\(binaryData.count) bytes)")
                
            } catch {
                print("❌ 遊戲訊息廣播失敗: \(error)")
            }
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
        updateConnectionStatus()
        
        if isHost {
            broadcastGameMessage(.roomSync, data: encodeGameRoomState())
        }
    }
    
    private func handlePeerDisconnected(_ peerID: String) {
        updateConnectionStatus()
        
        roomPlayers.removeAll { $0.id == peerID }
    }
    
    private func updateConnectionStatus() {
        let connectedCount = meshManager.getConnectedPeers().count
        connectionStatus = connectedCount > 0 ? 
            String(format: languageService.t("connected_devices"), connectedCount) : 
            languageService.t("offline")
    }
    
    private func startHeartbeat() {
        // 延遲啟動 heartbeat，等待網路連接穩定
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
    }
    
    private func sendHeartbeat() {
        guard isNetworkActive else { return }
        
        // 檢查是否有連接的設備再發送
        guard meshManager.getConnectedPeers().count > 0 else {
            print("📡 Heartbeat: 無連接設備，跳過廣播")
            return
        }
        
        let heartbeatData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.heartbeat, data: heartbeatData)
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.requestRoomSync()
        }
    }
    
    private func requestRoomSync() {
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
    }
    
    // MARK: - 清理
    
    private func cleanup() {
        drawTimer?.invalidate()
        countdownTimer?.invalidate()
        syncTimer?.invalidate()
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()
        hostPromotionTimer?.invalidate() // 清理主機推廣定時器
        
        meshManager.stopMeshNetwork()
        isNetworkActive = false
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
        guard var card = bingoCard else { return }
        
        if let index = card.numbers.firstIndex(of: number) {
            // 只有已被抽中(drawn)的號碼才能被標記(marked)
            guard card.drawn[index] else { return }
            
            card.marked[index] = true
            bingoCard = card
            
            let lines = calculateCompletedLines(card)
            if lines > completedLines {
                completedLines = lines
                updatePlayerProgress()
                
                if lines >= 5 {
                    gameWon = true
                    onGameWon?(deviceName, lines)
                }
            }
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
                self.handleServiceContainerGameMessage(data, from: sender)
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
            guard let self = self else { return }
            
            if let userInfo = notification.userInfo,
               let newNickname = userInfo["newNickname"] as? String {
                self.deviceName = newNickname // NicknameService已處理清理，避免重複
                print("🎮 BingoGameViewModel: 暱稱已更新為='\(newNickname)'")
                
                // 向其他玩家廣播暱稱更新
                if self.isInRoom {
                    let updateData = "\(self.playerID)|\(self.deviceName)".data(using: .utf8) ?? Data()
                    self.broadcastGameMessage(.heartbeat, data: updateData)
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
    
    /// 發送表情
    func sendEmote(_ emote: EmoteType) {
        // 檢查冷卻時間
        let now = Date()
        guard now.timeIntervalSince(lastEmoteTime) >= emoteCooldown else {
            print("⏳ 表情冷卻中，請稍後再試")
            return
        }
        
        lastEmoteTime = now
        
        // 編碼表情數據
        let emoteData = "\(emote.rawValue)|\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.emote, data: emoteData)
        
        // 本地也顯示表情
        triggerEmoteDisplay(nickname: deviceName, emote: emote)
    }
    
    /// 處理收到的表情訊息
    private func handleEmote(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 3,
              let emoteType = EmoteType(rawValue: components[0]) else {
            print("❌ 表情訊息格式錯誤")
            return
        }
        
        let senderName = components[2]
        triggerEmoteDisplay(nickname: senderName, emote: emoteType)
    }
    
    /// 觸發表情顯示和震動
    private func triggerEmoteDisplay(nickname: String, emote: EmoteType) {
        let text = String(format: emote.template, nickname)
        emoteSubject.send(EmoteEvent(text: text, isPureEmoji: emote.isPureEmoji))
        
        // 觸發震動
        #if !targetEnvironment(simulator)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
        
        print("💬 表情: \(text)")
    }
}
