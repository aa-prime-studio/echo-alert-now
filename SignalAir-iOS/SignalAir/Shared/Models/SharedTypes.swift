import Foundation
import SwiftUI
import MultipeerConnectivity

// MARK: - 共享的基本類型定義

// 信號類型
enum SignalType: String, CaseIterable, Codable {
    case safe = "safe"
    case supplies = "supplies"
    case medical = "medical"
    case danger = "danger"
    
    // 移除硬編碼的 label，改用翻譯鍵
    var translationKey: String {
        switch self {
        case .safe: return "signal_safe"
        case .supplies: return "signal_supplies"
        case .medical: return "signal_medical"
        case .danger: return "signal_danger"
        }
    }
    
    var iconName: String {
        switch self {
        case .safe: return "shield.fill"
        case .supplies: return "shippingbox.fill"
        case .medical: return "heart.fill"
        case .danger: return "exclamationmark.triangle.fill"
        }
    }
}

// 羅盤方向
enum CompassDirection: String, CaseIterable, Codable {
    case north = "北"
    case northeast = "東北"
    case east = "東"
    case southeast = "東南"
    case south = "南"
    case southwest = "西南"
    case west = "西"
    case northwest = "西北"
    
    var angle: Double {
        switch self {
        case .north: return 0
        case .northeast: return 45
        case .east: return 90
        case .southeast: return 135
        case .south: return 180
        case .southwest: return 225
        case .west: return 270
        case .northwest: return 315
        }
    }
}

// 位置數據
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
}

// 緊急信號
struct EmergencySignal: Codable {
    let id: String
    let type: SignalType
    let location: LocationData?
    let message: String
    let deviceID: String
    let senderNickname: String
    let timestamp: Date
}

// 信號訊息（UI 顯示用）
struct SignalMessage: Identifiable, Codable {
    let id: UUID
    let type: SignalType
    let deviceName: String
    let distance: Double?
    let direction: CompassDirection?
    let timestamp: Date
    let gridCode: String?
    
    init(type: SignalType, deviceName: String, distance: Double? = nil, direction: CompassDirection? = nil, timestamp: Date = Date(), gridCode: String? = nil) {
        self.id = UUID()
        self.type = type
        self.deviceName = deviceName
        self.distance = distance
        self.direction = direction
        self.timestamp = timestamp
        self.gridCode = gridCode
    }
}

// 聊天訊息
struct ChatMessage: Identifiable {
    let id: String
    let message: String
    let deviceName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    let isEncrypted: Bool
    let messageHash: String // 用於去重
    let mentions: [String] // 被提及的使用者列表
    let mentionsMe: Bool // 是否提及了我
    
    init(id: String = UUID().uuidString, message: String, deviceName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isOwn: Bool = false, isEncrypted: Bool = false, mentions: [String] = [], mentionsMe: Bool = false) {
        self.id = id
        self.message = message
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.isOwn = isOwn
        self.isEncrypted = isEncrypted
        self.mentions = mentions
        self.mentionsMe = mentionsMe
        self.messageHash = ChatMessage.generateHash(message: message, deviceName: deviceName, timestamp: timestamp)
    }
    
    static func generateHash(message: String, deviceName: String, timestamp: TimeInterval) -> String {
        let combined = "\(message)_\(deviceName)_\(Int(timestamp))"
        return String(combined.hashValue)
    }
    
    // 解析訊息中的@提及
    static func extractMentions(from message: String) -> [String] {
        let pattern = "@([\\w\\u4e00-\\u9fff]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: message, options: [], range: NSRange(location: 0, length: message.count)) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: message) else { return nil }
            return String(message[range])
        }
    }
    
    // 檢查是否提及了指定使用者
    static func checkMentionsUser(_ userNickname: String, in message: String) -> Bool {
        let cleanUserNickname = NicknameFormatter.cleanNickname(userNickname)
        let mentions = extractMentions(from: message)
        return mentions.contains { mention in
            NicknameFormatter.cleanNickname(mention) == cleanUserNickname
        }
    }
}

// MARK: - ChatMessage Codable 實現
extension ChatMessage: Codable {}

// 房間聊天訊息
struct RoomChatMessage: Identifiable, Codable {
    let id: UUID
    let message: String
    let playerName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    let isEmote: Bool
    let emoteType: EmoteType?
    
    // 兼容性初始化器
    init(message: String, playerName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isOwn: Bool = false) {
        self.id = UUID()
        self.message = message
        self.playerName = playerName
        self.timestamp = timestamp
        self.isOwn = isOwn
        self.isEmote = false
        self.emoteType = nil
    }
    
    // 新的表情支持初始化器
    init(id: String, sender: String, content: String, timestamp: Date, isLocal: Bool, isEmote: Bool = false, emoteType: EmoteType? = nil) {
        self.id = UUID(uuidString: id) ?? UUID()
        self.message = content
        self.playerName = sender
        self.timestamp = timestamp.timeIntervalSince1970
        self.isOwn = isLocal
        self.isEmote = isEmote
        self.emoteType = emoteType
    }
    
    var formattedTime: String {
        let now = Date().timeIntervalSince1970
        let diff = now - timestamp
        let minutes = Int(diff / 60)
        
        if minutes < 1 {
            return "剛剛"
        } else if minutes < 60 {
            return "\(minutes)分鐘前"
        } else {
            let hours = Int(diff / 3600)
            return "\(hours)小時前"
        }
    }
}

// 遊戲排行榜分數（保留原有的日榜結構）
struct BingoScore: Identifiable, Codable {
    let id: UUID
    let deviceName: String
    let score: Int
    let timestamp: TimeInterval
    let date: String
    
    init(deviceName: String, score: Int, timestamp: TimeInterval = Date().timeIntervalSince1970, date: String) {
        self.id = UUID()
        self.deviceName = deviceName
        self.score = score
        self.timestamp = timestamp
        self.date = date
    }
}

// 本週排行榜相關類型
struct WeeklyLeaderboard: Codable {
    let weekStartTime: Date
    let winsBoard: [WeeklyScore]     // 勝場榜
    let djBoard: [WeeklyScore]       // DJ榜
    let reactionBoard: [WeeklyScore] // 等車榜
    let lastUpdate: Date
    
    init(weekStartTime: Date) {
        self.weekStartTime = weekStartTime
        self.winsBoard = []
        self.djBoard = []
        self.reactionBoard = []
        self.lastUpdate = Date()
    }
    
    init(weekStartTime: Date, winsBoard: [WeeklyScore], djBoard: [WeeklyScore] = [], reactionBoard: [WeeklyScore] = []) {
        self.weekStartTime = weekStartTime
        self.winsBoard = winsBoard
        self.djBoard = djBoard
        self.reactionBoard = reactionBoard
        self.lastUpdate = Date()
    }
}

struct WeeklyScore: Identifiable, Codable {
    let id: UUID
    let playerID: String
    let nickname: String
    let value: Float        // 勝場數/互動次數/平均反應時間(ms)
    let lastUpdate: Date
    
    init(playerID: String, nickname: String, value: Float) {
        self.id = UUID()
        self.playerID = playerID
        self.nickname = NicknameFormatter.cleanNickname(nickname)
        self.value = value
        self.lastUpdate = Date()
    }
}

// 房間玩家
struct RoomPlayer: Identifiable, Codable {
    let id: UUID
    let name: String
    let playerID: String  // 設備ID，用於主機選舉
    let completedLines: Int
    let hasWon: Bool
    
    init(name: String, playerID: String, completedLines: Int = 0, hasWon: Bool = false) {
        self.id = UUID()
        self.name = name
        self.playerID = playerID
        self.completedLines = completedLines
        self.hasWon = hasWon
    }
}

// Bingo 房間
struct BingoRoom: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let players: [String]
    let currentNumbers: [Int]
    let isActive: Bool
    
    init(id: Int, name: String, players: [String] = [], currentNumbers: [Int] = [], isActive: Bool = false) {
        self.id = id
        self.name = name
        self.players = players
        self.currentNumbers = currentNumbers
        self.isActive = isActive
    }
}


// 時間格式化工具
struct TimeFormatter {
    static func formatRelativeTime(_ timestamp: TimeInterval, languageService: LanguageService) -> String {
        let now = Date().timeIntervalSince1970
        let diff = now - timestamp
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        
        if hours > 0 {
            return "\(hours)小時前"
        } else if minutes > 0 {
            return "\(minutes)分鐘前"
        } else {
            return "剛剛"
        }
    }
}

// 距離格式化工具
struct DistanceFormatter {
    static func format(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// 遊戲卡片
struct BingoCard {
    let numbers: [Int]
    var marked: [Bool] // true表示用戶已點擊確認（綠色）
    var drawn: [Bool]  // true表示號碼已被抽中（藍色）
    
    init(numbers: [Int]) {
        self.numbers = numbers
        self.marked = Array(repeating: false, count: 25)
        self.drawn = Array(repeating: false, count: 25)
    }
}

// MARK: - 協議常數定義

/// 二進制協議共享常數 - 🔧 FIX: 添加版本控制
struct BinaryProtocolConstants {
    static let VERSION: UInt8 = 2                    // 🔧 FIX: 升級至版本2
    static let MIN_SUPPORTED_VERSION: UInt8 = 1      // 最低支持版本
    static let MAX_SUPPORTED_VERSION: UInt8 = 2      // 最高支持版本
    static let HEADER_SIZE = 12
    static let MIN_HEADER_SIZE = 10
    static let ENCRYPTED_FLAG: UInt8 = 1
    static let UNENCRYPTED_FLAG: UInt8 = 0
    
    // 🔧 FIX: 版本兼容性檢查
    static func isVersionSupported(_ version: UInt8) -> Bool {
        return version >= MIN_SUPPORTED_VERSION && version <= MAX_SUPPORTED_VERSION
    }
    
    // 🔧 FIX: 獲取兼容的協議版本
    static func getCompatibleVersion(for peerVersion: UInt8) -> UInt8 {
        return min(VERSION, min(peerVersion, MAX_SUPPORTED_VERSION))
    }
}

// MARK: - 網路和服務相關類型

// 網路連線狀態
enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
}


// 連線的對等裝置
struct ConnectedPeer {
    let displayName: String
}

// Mesh 訊息類型（支援二進制協議）
enum MeshMessageType: UInt8, Codable {
    case signal = 0x01          // 信號訊息
    case emergency = 0x02       // 緊急訊息  
    case chat = 0x03            // 聊天訊息
    case system = 0x04          // 系統訊息
    case keyExchange = 0x05     // 密鑰交換請求
    case game = 0x06            // 遊戲訊息
    case topology = 0x07        // 網路拓撲
    case keyExchangeResponse = 0x08 // 密鑰交換響應
    case heartbeat = 0x09       // 心跳訊息
    case routingUpdate = 0x0A   // 路由更新
    
    var stringValue: String {
        switch self {
        case .signal: return "signal"
        case .emergency: return "emergency"
        case .chat: return "chat"
        case .system: return "system"
        case .keyExchange: return "keyExchange"
        case .game: return "game"
        case .topology: return "topology"
        case .keyExchangeResponse: return "keyExchangeResponse"
        case .heartbeat: return "heartbeat"
        case .routingUpdate: return "routingUpdate"
        }
    }
    
    var isEmergency: Bool {
        return self == .emergency
    }
    
}

// Mesh 訊息
struct MeshMessage {
    let id: String
    let type: MeshMessageType
    let data: Data
    var sourceID: String?
    var targetID: String?
    var ttl: Int = 10
    var routePath: [String] = []
    var forwarded: Bool = false
    let timestamp: Date = Date()
    
    // 為二進制協議添加便利初始化器
    init(type: MeshMessageType, data: Data) {
        self.id = UUID().uuidString
        self.type = type
        self.data = data
    }
    
    // 為解碼器添加完整初始化器
    init(id: String, type: MeshMessageType, data: Data) {
        self.id = id
        self.type = type
        self.data = data
    }
    
    // 完整初始化器
    init(type: MeshMessageType, sourceID: String? = nil, targetID: String? = nil, data: Data, ttl: Int = 10) {
        self.id = UUID().uuidString
        self.type = type
        self.sourceID = sourceID
        self.targetID = targetID
        self.data = data
        self.ttl = ttl
    }
    
    var isExpired: Bool {
        return ttl <= 0
    }
}

// MARK: - 遊戲相關類型

// 遊戲訊息類型
// 🔧 FIX: 連續性枚舉設計，避免解碼空隙問題
enum GameMessageType: UInt8, Codable, CaseIterable {
    // 基礎遊戲訊息 (0x01-0x0F)
    case playerJoined = 0x01
    case playerLeft = 0x02
    case roomSync = 0x03
    case reconnectRequest = 0x04
    case gameStateUpdate = 0x05
    case numberDrawn = 0x06
    case playerProgress = 0x07
    case chatMessage = 0x08
    case gameStart = 0x09
    case gameEnd = 0x0A
    case heartbeat = 0x0B
    case emote = 0x0C
    case roomStateRequest = 0x0D
    case roomStateUpdate = 0x0E
    case bingoWon = 0x0F
    
    // 擴展遊戲訊息 (0x10-0x1F) - 填補空隙
    case keyExchangeRequest = 0x10      // 🔧 FIX: 添加遺失的類型
    case keyExchangeResponse = 0x11     // 🔧 FIX: 解決0x11無法解碼問題
    case stateSync = 0x12               // 狀態同步（解耦版本）
    case errorReport = 0x13             // 錯誤報告
    case compatibilityCheck = 0x14      // 兼容性檢查
    case reserved15 = 0x15              // 預留
    case reserved16 = 0x16              // 預留
    case reserved17 = 0x17              // 預留
    case reserved18 = 0x18              // 預留
    case reserved19 = 0x19              // 預留
    case reserved1A = 0x1A              // 預留
    case reserved1B = 0x1B              // 預留
    case reserved1C = 0x1C              // 預留
    case reserved1D = 0x1D              // 預留
    case reserved1E = 0x1E              // 預留
    case reserved1F = 0x1F              // 預留
    
    // 排行榜訊息 (0x20-0x2F)
    case weeklyLeaderboardUpdate = 0x20
    case weeklyLeaderboardSync = 0x21
    case weeklyLeaderboardRequest = 0x22
    
    // 冠軍廣播訊息 (0x30-0x3F)
    case winnerAnnouncement = 0x30
    case gameRestart = 0x31
    
    // 輪流管理訊息 (0x40-0x4F)
    case turnChange = 0x40
    
    // 🔧 FIX: 未知類型處理
    case unknown = 0xFF                 // 未知或不支持的類型
    
    // 向後兼容性支援 - 字符串值
    var stringValue: String {
        switch self {
        case .playerJoined: return "player_joined"
        case .playerLeft: return "player_left"
        case .gameStateUpdate: return "game_state_update"
        case .numberDrawn: return "number_drawn"
        case .playerProgress: return "player_progress"
        case .chatMessage: return "chat_message"
        case .gameStart: return "game_start"
        case .gameEnd: return "game_end"
        case .roomSync: return "room_sync"
        case .reconnectRequest: return "reconnect_request"
        case .heartbeat: return "heartbeat"
        case .emote: return "emote"
        case .roomStateRequest: return "room_state_request"
        case .roomStateUpdate: return "room_state_update"
        case .bingoWon: return "bingo_won"
        // 🔧 FIX: 新增類型的字符串值
        case .keyExchangeRequest: return "key_exchange_request"
        case .keyExchangeResponse: return "key_exchange_response"
        case .stateSync: return "state_sync"
        case .errorReport: return "error_report"
        case .compatibilityCheck: return "compatibility_check"
        case .reserved15, .reserved16, .reserved17, .reserved18, .reserved19,
             .reserved1A, .reserved1B, .reserved1C, .reserved1D, .reserved1E, .reserved1F:
            return "reserved_\(String(format: "%02X", rawValue))"
        case .weeklyLeaderboardUpdate: return "weekly_leaderboard_update"
        case .weeklyLeaderboardSync: return "weekly_leaderboard_sync"
        case .weeklyLeaderboardRequest: return "weekly_leaderboard_request"
        case .winnerAnnouncement: return "winner_announcement"
        case .gameRestart: return "game_restart"
        case .turnChange: return "turn_change"
        case .unknown: return "unknown_type"
        }
    }
}

// 遊戲訊息
struct GameMessage: Codable {
    let id: String
    let type: GameMessageType
    let data: Data
    let senderID: String
    let senderName: String
    let roomID: String
    let timestamp: Date
}

// 房間狀態數據（用於編碼到 GameMessage.data 中）
struct RoomStateData: Codable {
    let roomId: Int
    let playerCount: Int
    let isActive: Bool
    let action: String // "request" 或 "update"
    let players: [RoomPlayerData]? // 玩家列表（可選，為了兼容性）
    let drawnNumbers: [Int]? // 【NEW】歷史抽中號碼（用於斷線重連後同步）
    let gameState: String? // 【NEW】遊戲狀態（waiting/countdown/playing/finished）
    
    init(roomId: Int, playerCount: Int, isActive: Bool, action: String, players: [RoomPlayerData]? = nil, drawnNumbers: [Int]? = nil, gameState: String? = nil) {
        self.roomId = roomId
        self.playerCount = playerCount
        self.isActive = isActive
        self.action = action
        self.players = players
        self.drawnNumbers = drawnNumbers
        self.gameState = gameState
    }
}

// 房間玩家數據（用於網絡傳輸）
struct RoomPlayerData: Codable {
    let playerID: String
    let name: String
    let completedLines: Int
    let hasWon: Bool
    
    init(playerID: String, name: String, completedLines: Int = 0, hasWon: Bool = false) {
        self.playerID = playerID
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
    }
}

// 冠軍廣播訊息
struct WinnerAnnouncement: Codable {
    let winnerPlayerID: String
    let winnerName: String
    let completedLines: Int
    let gameEndTime: Date
    let restartCountdown: Int // 重新開始倒數秒數
}

// 玩家狀態
struct PlayerState: Codable, Identifiable {
    let id: String
    let name: String
    let completedLines: Int
    let hasWon: Bool
    let isConnected: Bool
    let lastSeen: Date
    
    init(id: String = UUID().uuidString, name: String, completedLines: Int = 0, hasWon: Bool = false, isConnected: Bool = true) {
        self.id = id
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
        self.isConnected = isConnected
        self.lastSeen = Date()
    }
}

// 遊戲房間狀態
struct GameRoomState: Codable {
    let roomID: String
    let hostID: String
    let players: [PlayerState]
    let gameState: GameState
    let drawnNumbers: [Int]
    let currentNumber: Int?
    let countdown: Int
    let startTime: Date?
    
    enum GameState: String, Codable, CaseIterable {
        case waitingForPlayers = "waiting"
        case countdown = "countdown"
        case playing = "playing"
        case finished = "finished"
    }
}

// MARK: - 管理器和服務的訊息類型

// 訊息類型（用於自毀管理）
enum MessageType: String {
    case signal = "signal"
    case chat = "chat"
    case game = "game"
}

// 訊息優先級

// MARK: - 暱稱處理工具
struct NicknameFormatter {
    /// 清理暱稱顯示，移除設備ID和只顯示"#"前的部分
    static func cleanNickname(_ fullName: String) -> String {
        var cleanName = fullName
        
        // 移除設備ID格式 "暱稱 (設備ID)" 或 "暱稱 (來源未知)"
        if let parenIndex = cleanName.firstIndex(of: "(") {
            cleanName = String(cleanName[..<parenIndex]).trimmingCharacters(in: .whitespaces)
        }
        
        // 只顯示"#"前的部分
        if let hashIndex = cleanName.firstIndex(of: "#") {
            cleanName = String(cleanName[..<hashIndex])
        }
        
        let finalName = cleanName.trimmingCharacters(in: .whitespaces)
        
        // 如果結果是默認的"使用者"，使用更有意義的顯示名稱
        if finalName == "使用者" || finalName.isEmpty {
            return "用戶"
        }
        
        return finalName
    }
}

// MARK: - 基本服務類型（避免重複定義）

// MARK: - Protocols for Services
@MainActor
protocol MeshManagerProtocol: Sendable {
    // 基本方法
    func broadcastMessage(_ data: Data, messageType: MeshMessageType)
    func getConnectedPeers() -> [String]
    
    // 網路管理
    func startMeshNetwork()
    func stopMeshNetwork()
    
    // 回調屬性
    var onMessageReceived: ((MeshMessage) -> Void)? { get set }
    var onGameMessageReceived: ((MeshMessage) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
}


class SelfDestructManager {
    init() {}
    func trackMessage(_ messageID: String, type: MessageType, priority: MessagePriority) {}
    func removeMessage(_ messageID: String) {}
}


// MARK: - Protocol Definitions
@MainActor
protocol NetworkServiceProtocol: AnyObject {
    var isConnected: Bool { get }
    var myPeerID: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    var onDataReceived: ((Data, String) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
    
    func startNetworking()
    func stopNetworking()
    func send(_ data: Data, to peers: [MCPeerID]) async throws
}

protocol SecurityServiceProtocol: AnyObject {
    func generateSessionKey() -> Data?
    func encryptData(_ data: Data) -> Data?
    func decryptData(_ data: Data) -> Data?
    func hasSessionKey(for peerID: String) async -> Bool
    func encrypt(_ data: Data, for peerID: String) throws -> Data
    func decrypt(_ data: Data, from peerID: String) throws -> Data
    func getPublicKey() throws -> Data
    func removeSessionKey(for peerID: String)
}

// MARK: - Fallback MeshManager Implementation
// 注意：這是備用版本，優先使用 SignalAir/Core/Network/MeshManager.swift
@MainActor
class MeshManagerFallback: MeshManagerProtocol, @unchecked Sendable {
    var onMessageReceived: ((MeshMessage) -> Void)?
    var onGameMessageReceived: ((MeshMessage) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    // 基本版本使用簡化的屬性（協議不能使用 weak）
    var networkService: NetworkServiceProtocol?
    var securityService: SecurityService?
    var connectionRateManager: ConnectionRateManagerProtocol?
    
    // 無參數初始化（兼容性）
    init() {
        // 空初始化，用於預設情報下
    }
    
    // 完整初始化
    init(networkService: NetworkServiceProtocol, 
         securityService: SecurityService,
         connectionRateManager: ConnectionRateManagerProtocol) {
        self.networkService = networkService
        self.securityService = securityService
        self.connectionRateManager = connectionRateManager
        print("🕸️ MeshManager: 已初始化並連接到實際的網路服務")
    }
    
    func startMeshNetwork() {
        // 基本版本空實現
    }
    
    func stopMeshNetwork() {
        // 基本版本空實現
    }
    
    func broadcastMessage(_ data: Data, messageType: MeshMessageType) {
        Task {
            do {
                try await broadcast(data, priority: .normal, userNickname: "System")
            } catch {
                print("❌ MeshManager: broadcastMessage 失敗: \(error)")
            }
        }
    }
    
    @MainActor
    func getConnectedPeers() -> [String] { 
        return networkService?.connectedPeers.map { $0.displayName } ?? []
    }
    
    @MainActor
    func broadcast(_ data: Data, priority: MessagePriority, userNickname: String) async throws {
        guard let networkService = networkService else {
            print("❌ MeshManager: NetworkService 未初始化")
            throw NetworkError.notConnected
        }
        
        guard !networkService.connectedPeers.isEmpty else {
            print("❌ MeshManager: 沒有連接的設備")
            throw NetworkError.notConnected
        }
        
        print("📡 MeshManager: 開始廣播 \(data.count) 字節的數據到 \(networkService.connectedPeers.count) 個設備")
        
        do {
            try await networkService.send(data, to: networkService.connectedPeers)
            print("✅ MeshManager: 廣播成功完成")
        } catch {
            print("❌ MeshManager: 廣播失敗: \(error)")
            throw error
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userNickname: String = "使用者"
    init() {}
}

// MARK: - 網路拓撲相關類型

// 網路拓撲訊息類型
enum TopologyMessageType: String, Codable {
    case nodeInfo = "node_info"              // 節點資訊廣播
    case peerDiscovery = "peer_discovery"    // 節點發現
    case routeUpdate = "route_update"        // 路由更新
    case healthCheck = "health_check"        // 健康檢查
    case loadReport = "load_report"          // 負載報告
}

// 節點資訊
struct NodeInfo: Codable {
    let nodeID: String                       // 節點唯一ID
    let deviceName: String                   // 設備顯示名稱
    let connectedPeers: [String]             // 直接連接的節點列表
    let signalStrength: [String: Int]        // 各連接的信號強度 (0-100)
    let lastUpdate: Date                     // 最後更新時間
    let hopCount: Int                        // 到根節點的跳數
    let batteryLevel: Int?                   // 電池電量 (0-100)
    let isRootNode: Bool                     // 是否為根節點
}

// 路由資訊
struct RouteInfo: Codable {
    let destination: String                  // 目標節點ID
    let nextHop: String                      // 下一跳節點ID
    let hopCount: Int                        // 跳數
    let latency: Double                      // 延遲(毫秒)
    let reliability: Double                  // 可靠性 (0.0-1.0)
    let lastUsed: Date                       // 最後使用時間
}

// 網路拓撲狀態
struct NetworkTopology: Codable {
    let nodes: [String: NodeInfo]            // 所有已知節點
    let routes: [String: [RouteInfo]]        // 路由表
    let lastUpdate: Date                     // 最後更新時間
    let totalNodes: Int                      // 總節點數
    let connectedNodes: Int                  // 已連接節點數
    let networkHealth: Double                // 網路健康度 (0.0-1.0)
}

// 負載統計
struct LoadStatistics: Codable {
    let nodeID: String                       // 節點ID
    let cpuUsage: Double                     // CPU使用率 (0.0-1.0)
    let memoryUsage: Double                  // 記憶體使用率 (0.0-1.0)
    let messagesSent: Int                    // 已發送訊息數
    let messagesReceived: Int                // 已接收訊息數
    let dataTransferred: Int                 // 傳輸數據量(bytes)
    let timestamp: Date                      // 統計時間
}

// 拓撲訊息
struct TopologyMessage: Codable {
    let type: TopologyMessageType           // 訊息類型
    let senderID: String                    // 發送者ID
    let senderName: String                  // 發送者名稱
    let data: Data                          // 訊息數據
    let timestamp: Date                     // 時間戳
    let sequenceNumber: Int                 // 序列號
    let ttl: Int                           // 生存時間(跳數)
}

// MARK: - 表情符號系統

// 表情符號類型
enum EmoteType: String, Codable, Hashable, CaseIterable {
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
    case happy     // 預設表情 😊
    
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
        case .happy: return "😊"
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
        case .happy: return "%@ 😊"
        }
    }
    
    var isPureEmoji: Bool {
        switch self {
        // 文字表情 (5個 - 有動作描述)
        case .bingo, .nen, .wow, .dizzy, .ring:
            return false
        // 純Emoji表情 (20個 - 僅顯示emoji)
        case .boom, .pirate, .bug, .fly, .fire, .poop, .clown, .mindBlown, .pinch, .eyeRoll, .rockOn, .bottle, .skull, .juggler, .burger, .battery, .rocket, .mouse, .pray, .love, .happy:
            return true
        }
    }
}