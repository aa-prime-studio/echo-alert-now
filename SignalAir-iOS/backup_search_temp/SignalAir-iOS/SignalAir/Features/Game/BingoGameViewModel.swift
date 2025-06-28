import Foundation
import SwiftUI

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
    
    // MARK: - 遊戲結果回調
    var onGameWon: ((String, Int) -> Void)?
    
    // MARK: - 服務依賴
    private let meshManager: MeshManager
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
    
    // MARK: - 網路狀態
    private var isNetworkActive: Bool = false
    private var lastSyncTime: Date = Date()
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    
    // MARK: - 初始化
    init(
        meshManager: MeshManager = MeshManager(),
        securityService: SecurityService = SecurityService(),
        settingsViewModel: SettingsViewModel = SettingsViewModel()
    ) {
        self.meshManager = meshManager
        self.securityService = securityService
        self.settingsViewModel = settingsViewModel
        self.languageService = LanguageService()
        
        // 初始化玩家資訊
        self.deviceName = self.settingsViewModel.userNickname
        self.playerID = UUID().uuidString
        
        // 設置初始狀態文字
        self.connectionStatus = self.languageService.t("offline")
        self.syncStatus = self.languageService.t("waiting_sync")
        
        setupMeshNetworking()
        startHeartbeat()
        
        print("🎮 BingoGameViewModel: 初始化完成")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Mesh 網路設定
    
    private func setupMeshNetworking() {
        meshManager.startMeshNetwork()
        isNetworkActive = true
        
        // 設定遊戲訊息接收回調
        meshManager.onMessageReceived = { [weak self] meshMessage in
            if meshMessage.type == .game {
                self?.handleIncomingGameMessage(meshMessage)
            }
        }
        
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
        
        addSystemMessage("\(languageService.t("room_created")) \(gameRoomID.prefix(8))")
    }
    
    func joinGameRoom(_ roomID: String) {
        gameRoomID = roomID
        isHost = false
        
        let requestData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.reconnectRequest, data: requestData)
        
        bingoCard = generateBingoCard()
        addSystemMessage("\(languageService.t("joining_room")) \(roomID.prefix(8))")
        
        startSyncTimer()
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
    
    private func handleIncomingGameMessage(_ meshMessage: MeshMessage) {
        do {
            let gameMessage = try JSONDecoder().decode(GameMessage.self, from: meshMessage.data)
            
            guard gameMessage.gameRoomID == gameRoomID || gameMessage.type == GameMessageType.roomSync else { return }
            
            DispatchQueue.main.async {
                self.processGameMessage(gameMessage)
            }
            
        } catch {
            print("❌ 解析遊戲訊息失敗: \(error)")
        }
    }
    
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
        }
    }
    
    // MARK: - 訊息處理器
    
    private func handlePlayerJoined(_ message: GameMessage) {
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 2 else { return }
        
        let playerState = PlayerState(id: components[0], name: components[1])
        
        if !roomPlayers.contains(where: { $0.id == playerState.id }) {
            roomPlayers.append(playerState)
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
        do {
            let roomState = try JSONDecoder().decode(GameRoomState.self, from: message.data)
            
            gameRoomState = roomState
            roomPlayers = roomState.players
            gameState = roomState.gameState
            drawnNumbers = roomState.drawnNumbers
            currentNumber = roomState.currentNumber
            countdown = roomState.countdown
            
        } catch {
            print("❌ 房間同步失敗: \(error)")
        }
    }
    
    private func handleReconnectRequest(_ message: GameMessage) {
        guard isHost else { return }
        
        let components = String(data: message.data, encoding: .utf8)?.components(separatedBy: "|") ?? []
        guard components.count >= 2 else { return }
        
        let playerState = PlayerState(id: components[0], name: components[1])
        
        if !roomPlayers.contains(where: { $0.id == playerState.id }) {
            roomPlayers.append(playerState)
        }
        
        broadcastGameMessage(.roomSync, data: encodeGameRoomState())
    }
    
    private func handleGameStateUpdate(_ message: GameMessage) {
        do {
            let newState = try JSONDecoder().decode(GameRoomState.GameState.self, from: message.data)
            gameState = newState
        } catch {
            print("❌ 遊戲狀態更新失敗: \(error)")
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
        do {
            let playerState = try JSONDecoder().decode(PlayerState.self, from: message.data)
            
            if let index = roomPlayers.firstIndex(where: { $0.id == playerState.id }) {
                roomPlayers[index] = playerState
            }
            
        } catch {
            print("❌ 玩家進度更新失敗: \(error)")
        }
    }
    
    private func handleChatMessage(_ message: GameMessage) {
        do {
            let chatMessage = try JSONDecoder().decode(RoomChatMessage.self, from: message.data)
            roomChatMessages.append(chatMessage)
            
            // 保持最多 100 條訊息
            if roomChatMessages.count > 100 {
                roomChatMessages.removeFirst()
            }
            
        } catch {
            print("❌ 聊天訊息處理失敗: \(error)")
        }
    }
    
    private func handleGameStart(_ message: GameMessage) {
        gameState = .playing
        broadcastGameMessage(.gameStateUpdate, data: encodeGameState(.playing))
    }
    
    private func handleGameEnd(_ message: GameMessage) {
        gameState = .finished
        broadcastGameMessage(.gameEnd, data: Data())
    }
    
    // MARK: - 遊戲控制
    
    func startGame() {
        guard isHost && gameState == .waitingForPlayers else { return }
        
        gameState = .countdown
        countdown = 5
        
        broadcastGameMessage(.gameStart, data: Data())
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.countdown -= 1
                
                if self.countdown <= 0 {
                    self.countdownTimer?.invalidate()
                    self.gameState = .playing
                    self.startDrawing()
                }
            }
        }
    }
    
    private func startDrawing() {
        guard isHost && gameState == .playing else { return }
        
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
            card.marked[index] = true
            bingoCard = card
            
            let lines = calculateCompletedLines(card)
            if lines > completedLines {
                completedLines = lines
                updatePlayerProgress()
                
                if lines >= 5 { // 假設需要5條線才獲勝
                    gameWon = true
                    onGameWon?(deviceName, lines)
                }
            }
        }
    }
    
    private func calculateCompletedLines(_ card: BingoCard) -> Int {
        var completedLines = 0
        let marked = card.marked
        
        // 檢查行
        for row in 0..<5 {
            let start = row * 5
            if (start..<start+5).allSatisfy({ marked[$0] }) {
                completedLines += 1
            }
        }
        
        // 檢查列
        for col in 0..<5 {
            if (0..<5).allSatisfy({ marked[$0 * 5 + col] }) {
                completedLines += 1
            }
        }
        
        // 檢查對角線
        if (0..<5).allSatisfy({ marked[$0 * 6] }) {
            completedLines += 1
        }
        if (0..<5).allSatisfy({ marked[($0 + 1) * 4] }) {
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
        
        do {
            let data = try JSONEncoder().encode(playerState)
            broadcastGameMessage(.playerProgress, data: data)
        } catch {
            print("❌ 編碼玩家進度失敗: \(error)")
        }
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
        
        do {
            let data = try JSONEncoder().encode(chatMessage)
            broadcastGameMessage(.chatMessage, data: data)
        } catch {
            print("❌ 編碼聊天訊息失敗: \(error)")
        }
        
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
        let gameMessage = GameMessage(
            type: type,
            senderID: playerID,
            senderName: deviceName,
            data: data,
            timestamp: Date(),
            gameRoomID: gameRoomID
        )
        
        do {
            let messageData = try JSONEncoder().encode(gameMessage)
            let meshMessage = MeshMessage(type: .game, data: messageData)
            meshManager.onMessageReceived?(meshMessage)
        } catch {
            print("❌ 廣播遊戲訊息失敗: \(error)")
        }
    }
    
    private func encodeGameRoomState() -> Data {
        guard let roomState = gameRoomState else { return Data() }
        
        do {
            return try JSONEncoder().encode(roomState)
        } catch {
            print("❌ 編碼房間狀態失敗: \(error)")
            return Data()
        }
    }
    
    private func encodeGameState(_ state: GameRoomState.GameState) -> Data {
        do {
            return try JSONEncoder().encode(state)
        } catch {
            print("❌ 編碼遊戲狀態失敗: \(error)")
            return Data()
        }
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
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard isNetworkActive else { return }
        
        let heartbeatData = "\(playerID)|\(deviceName)".data(using: .utf8) ?? Data()
        broadcastGameMessage(.roomSync, data: heartbeatData)
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
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
}
