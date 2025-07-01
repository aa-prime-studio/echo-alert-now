import Foundation
import SwiftUI

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
struct ChatMessage: Identifiable, Codable {
    let id: String
    let message: String
    let deviceName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    let isEncrypted: Bool
    let messageHash: String // 用於去重
    
    init(id: String = UUID().uuidString, message: String, deviceName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isOwn: Bool = false, isEncrypted: Bool = false) {
        self.id = id
        self.message = message
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.isOwn = isOwn
        self.isEncrypted = isEncrypted
        self.messageHash = ChatMessage.generateHash(message: message, deviceName: deviceName, timestamp: timestamp)
    }
    
    static func generateHash(message: String, deviceName: String, timestamp: TimeInterval) -> String {
        let combined = "\(message)_\(deviceName)_\(Int(timestamp))"
        return String(combined.hashValue)
    }
}

// 房間聊天訊息
struct RoomChatMessage: Identifiable, Codable {
    let id: UUID
    let message: String
    let playerName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    
    init(message: String, playerName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isOwn: Bool = false) {
        self.id = UUID()
        self.message = message
        self.playerName = playerName
        self.timestamp = timestamp
        self.isOwn = isOwn
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

// 遊戲排行榜分數
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

// 房間玩家
struct RoomPlayer: Identifiable, Codable {
    let id: UUID
    let name: String
    let completedLines: Int
    let hasWon: Bool
    
    init(name: String, completedLines: Int = 0, hasWon: Bool = false) {
        self.id = UUID()
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
    }
}

// Bingo 房間
struct BingoRoom: Identifiable, Codable {
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
    var marked: [Bool]
    
    init(numbers: [Int]) {
        self.numbers = numbers
        self.marked = Array(repeating: false, count: 25)
    }
}

// MARK: - 網路和服務相關類型

// 網路連線狀態
enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
}

// 網路錯誤
enum NetworkError: Error {
    case notConnected
    case peerNotFound
    case sendFailed
    case connectionFailed
    case invalidData
    case timeout
    case sessionError(String)
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "Not connected to any peers"
        case .peerNotFound:
            return "Peer not found"
        case .sendFailed:
            return "Failed to send data"
        case .connectionFailed:
            return "Failed to establish connection"
        case .invalidData:
            return "Invalid data format"
        case .timeout:
            return "Operation timed out"
        case .sessionError(let message):
            return "Session error: \(message)"
        }
    }
}

// 連線的對等裝置
struct ConnectedPeer {
    let displayName: String
}

// Mesh 訊息類型（支援二進制協議）
enum MeshMessageType: UInt8, Codable {
    case signal = 0x01      // 信號訊息
    case emergency = 0x02   // 緊急訊息  
    case chat = 0x03        // 聊天訊息
    case system = 0x04      // 系統訊息
    case keyExchange = 0x05 // 密鑰交換
    case game = 0x06        // 遊戲訊息
    
    var stringValue: String {
        switch self {
        case .signal: return "signal"
        case .emergency: return "emergency"
        case .chat: return "chat"
        case .system: return "system"
        case .keyExchange: return "keyExchange"
        case .game: return "game"
        }
    }
}

// Mesh 訊息
struct MeshMessage {
    let id: String
    let type: MeshMessageType
    let data: Data
    
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
}

// MARK: - 遊戲相關類型

// 遊戲訊息類型
enum GameMessageType: String, Codable, CaseIterable {
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case gameStateUpdate = "game_state_update"
    case numberDrawn = "number_drawn"
    case playerProgress = "player_progress"
    case chatMessage = "chat_message"
    case gameStart = "game_start"
    case gameEnd = "game_end"
    case roomSync = "room_sync"
    case reconnectRequest = "reconnect_request"
    case heartbeat = "heartbeat"
}

// 遊戲訊息
struct GameMessage: Codable {
    let type: GameMessageType
    let senderID: String
    let senderName: String
    let data: Data
    let timestamp: Date
    let gameRoomID: String
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
enum MessagePriority: String {
    case normal = "normal"
    case high = "high"
    case emergency = "emergency"
}

// MARK: - 基本服務類型（避免重複定義）

// MARK: - Protocols for Services
protocol MeshManagerProtocol {
    // 基本方法
    func broadcastMessage(_ data: Data, messageType: MeshMessageType)
    func getConnectedPeers() -> [String]
    
    // 網路管理
    func startMeshNetwork()
    func stopMeshNetwork()
    
    // 回調屬性
    var onMessageReceived: ((MeshMessage) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
}

protocol FloodProtectionProtocol {
    func shouldAcceptMessage(from deviceID: String, content: Data, size: Int, priority: MessagePriority) -> Bool
}

class SelfDestructManager {
    init() {}
    func trackMessage(_ messageID: String, type: MessageType, priority: MessagePriority) {}
    func removeMessage(_ messageID: String) {}
}

// MARK: - Simple FloodProtection Implementation
class FloodProtection: FloodProtectionProtocol {
    init() {}
    func shouldAcceptMessage(from deviceID: String, content: Data, size: Int, priority: MessagePriority) -> Bool {
        return true
    }
}

// MARK: - Fallback MeshManager Implementation
// 注意：這是備用版本，優先使用 SignalAir/Core/Network/MeshManager.swift
class MeshManager: MeshManagerProtocol {
    var onMessageReceived: ((MeshMessage) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    // 基本版本使用簡化的屬性（協議不能使用 weak）
    var networkService: NetworkServiceProtocol?
    var securityService: SecurityServiceProtocol?
    var floodProtection: FloodProtectionProtocol?
    
    // 無參數初始化（兼容性）
    init() {
        // 空初始化，用於預設情報下
    }
    
    // 完整初始化
    init(networkService: NetworkServiceProtocol, 
         securityService: SecurityServiceProtocol,
         floodProtection: FloodProtectionProtocol) {
        self.networkService = networkService
        self.securityService = securityService
        self.floodProtection = floodProtection
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
    
    func getConnectedPeers() -> [String] { 
        return networkService?.connectedPeers.map { $0.displayName } ?? []
    }
    
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

class SettingsViewModel: ObservableObject {
    @Published var userNickname: String = "使用者"
    init() {}
}

 
 