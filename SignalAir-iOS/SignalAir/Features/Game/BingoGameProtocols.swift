import Foundation
import Combine

// MARK: - Service Protocols for Bingo Game Refactoring

// MARK: - Network Manager Protocol
@MainActor
protocol BingoNetworkManagerProtocol: AnyObject {
    // 網路消息發送
    func sendGameMessage(type: GameMessageType, data: Data, to roomID: String) async throws
    func broadcastGameAction(type: GameMessageType, data: Data, priority: MessagePriority) async throws
    
    // 消息接收處理
    func startMessageHandling()
    func stopMessageHandling()
    
    // 網路狀態
    var isConnected: Bool { get }
    var isNetworkActive: Bool { get }
    var connectedPeers: [String] { get }
    
    // Publishers for received messages
    var receivedGameMessages: AnyPublisher<GameMessage, Never> { get }
    var networkConnectionState: AnyPublisher<Bool, Never> { get }
}

// MARK: - State Manager Protocol
@MainActor
protocol BingoGameStateManagerProtocol: AnyObject {
    // 遊戲狀態
    var gameState: GameRoomState.GameState { get }
    var bingoCard: BingoCard? { get }
    var drawnNumbers: [Int] { get }
    var currentNumber: Int? { get }
    var completedLines: Int { get }
    var gameWon: Bool { get }
    
    // 遊戲生命週期
    func startGame()
    func endGame()
    func resetGameState()
    func restartGame()
    
    // 號碼相關
    func generateBingoCard()
    func manualDrawNumber()
    func markNumber(_ number: Int)
    
    // 消息處理
    func handleNumberDrawn(_ number: Int)
    func handleGameStart()
    func handleGameEnd()
    func handleGameRestart()
    
    // 獲勝檢查
    func checkWinCondition()
    
    // 回調註冊
    func onGameWon(_ callback: @escaping (String, Int) -> Void)
    
    // Publishers
    var gameStatePublisher: AnyPublisher<GameRoomState.GameState, Never> { get }
    var bingoCardPublisher: AnyPublisher<BingoCard?, Never> { get }
    var drawnNumbersPublisher: AnyPublisher<[Int], Never> { get }
    var currentNumberPublisher: AnyPublisher<Int?, Never> { get }
    var gameWonPublisher: AnyPublisher<Bool, Never> { get }
}

// MARK: - Host Election Protocol
@MainActor
protocol HostElectionServiceProtocol: AnyObject {
    // 主機狀態
    var isHost: Bool { get }
    var currentHost: String? { get }
    var hostElectionInProgress: Bool { get }
    
    // 主機選舉
    func startHostElection()
    func electHost(from candidates: [String]) -> String?
    func becomeHost()
    func resignAsHost()
    
    // 主機心跳
    func startHostHeartbeat()
    func stopHostHeartbeat()
    func handleHostHeartbeat(from hostID: String)
    
    // 主機切換
    func handleHostDisconnected()
    func migrateHost(to newHostID: String)
    
    // Publishers
    var isHostPublisher: AnyPublisher<Bool, Never> { get }
    var currentHostPublisher: AnyPublisher<String?, Never> { get }
    var hostElectionProgressPublisher: AnyPublisher<Bool, Never> { get }
}

// MARK: - Timer Service Protocol
@MainActor
protocol GameTimerServiceProtocol: AnyObject {
    // 遊戲計時器
    func startGameCountdown(duration: Int, onUpdate: @escaping (Int) -> Void, onComplete: @escaping () -> Void)
    func stopGameCountdown()
    
    // 自動開始計時器
    func scheduleAutoStart(delay: TimeInterval, action: @escaping () -> Void)
    func cancelAutoStart()
    
    // 心跳計時器
    func startHeartbeat(interval: TimeInterval, action: @escaping () -> Void)
    func stopHeartbeat()
    
    // 重新開始延遲
    func scheduleRestart(delay: TimeInterval, action: @escaping () -> Void)
    func cancelRestart()
    
    // 計時器狀態
    var isCountdownActive: Bool { get }
    var currentCountdown: Int { get }
    
    // Publishers
    var countdownPublisher: AnyPublisher<Int, Never> { get }
    var heartbeatPublisher: AnyPublisher<Void, Never> { get }
}

// MARK: - Chat Service Protocol
@MainActor
protocol GameChatServiceProtocol: AnyObject {
    // 聊天消息
    func sendChatMessage(_ message: String, to roomID: String) async throws
    func handleReceivedChatMessage(_ message: GameMessage)
    
    // 表情符號
    func sendEmote(_ emote: EmoteType, to roomID: String) async throws
    func handleReceivedEmote(_ message: GameMessage)
    
    // 聊天歷史
    var chatMessages: [RoomChatMessage] { get }
    func clearChatHistory()
    
    // Publishers
    var chatMessagesPublisher: AnyPublisher<[RoomChatMessage], Never> { get }
    var emoteReceived: AnyPublisher<(EmoteType, String), Never> { get }
}

// MessagePriority 已移至 SharedTypes.swift 以避免重複定義

// MARK: - Refactoring Support Types

/// 用於協調各服務間通訊的事件類型
enum GameCoordinationEvent {
    case gameStartRequested
    case gameEndRequested
    case hostElectionStarted
    case hostElectionCompleted(hostID: String)
    case numberDrawRequested
    case numberDrawn(number: Int)
    case playerWon(playerID: String, lines: Int)
    case chatMessageReceived(message: String, senderID: String)
    case emoteReceived(emote: EmoteType, senderID: String)
    case networkConnectionChanged(isConnected: Bool)
    case timerExpired(timerID: String)
}

/// 遊戲服務間的錯誤類型
enum GameServiceError: Error {
    case networkNotInitialized
    case stateManagerNotReady
    case hostElectionFailed
    case timerServiceUnavailable
    case chatServiceUnavailable
    case invalidGameState
    case encodingFailed
    case decodingFailed
    case broadcastFailed
    case unknownError(Error)
    
    var localizedDescription: String {
        switch self {
        case .networkNotInitialized:
            return "網路服務未初始化"
        case .stateManagerNotReady:
            return "遊戲狀態管理器未就緒"
        case .hostElectionFailed:
            return "主機選舉失敗"
        case .timerServiceUnavailable:
            return "計時器服務不可用"
        case .chatServiceUnavailable:
            return "聊天服務不可用"
        case .invalidGameState:
            return "無效的遊戲狀態"
        case .encodingFailed:
            return "編碼失敗"
        case .decodingFailed:
            return "解碼失敗"
        case .broadcastFailed:
            return "廣播失敗"
        case .unknownError(let error):
            return "未知錯誤: \(error.localizedDescription)"
        }
    }
}