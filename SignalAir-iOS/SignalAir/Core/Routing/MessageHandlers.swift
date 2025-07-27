import Foundation

// MARK: - 智能訊息處理器集合
// 為不同類型的訊息提供專用處理器，支援智能檢測和分派

// MARK: - 網狀網路訊息處理器
@MainActor
class MeshMessageHandler: MessageHandler {
    
    private weak var meshManager: MeshManager?
    
    var middleware: [String] { ["security", "validation", "metrics"] }
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 5 }
    
    init(meshManager: MeshManager) {
        self.meshManager = meshManager
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let meshManager = meshManager else {
            throw RoutingError.handlerNotFound
        }
        
        switch message.type {
        case .heartbeat, .topology:
            // 直接處理拓撲相關訊息
            try await handleTopologyMessage(message, meshManager: meshManager)
            
        case .signal, .chat, .game, .emergency:
            // 需要路由的訊息
            try await handleRoutableMessage(message, destination: destination, meshManager: meshManager)
            
        default:
            print("⚠️ MeshMessageHandler: 不支援的訊息類型 \(message.type)")
        }
    }
    
    private func handleTopologyMessage(_ message: UniversalMessage, meshManager: MeshManager) async throws {
        // 處理網路拓撲更新
        if message.type == .heartbeat {
            try await meshManager.handleHeartbeat(message.payload, from: message.source)
        } else if message.type == .topology {
            try await meshManager.handleTopologyUpdate(message.payload, from: message.source)
        }
    }
    
    private func handleRoutableMessage(_ message: UniversalMessage, destination: MessageDestination, meshManager: MeshManager) async throws {
        switch destination {
        case .direct(let peerID):
            try await meshManager.sendDirectMessage(message.payload, to: peerID, messageType: message.type)
            
        case .broadcast(_):
            try await meshManager.broadcastMessage(message.payload, messageType: message.type)
            
        case .multicast(let targets):
            for target in targets {
                try await meshManager.sendDirectMessage(message.payload, to: target, messageType: message.type)
            }
            
        case .conditional(_):
            // 條件性路由由路由器處理目標選擇
            try await meshManager.broadcastMessage(message.payload, messageType: message.type)
        }
    }
}

// MARK: - 信號訊息處理器
@MainActor
class SignalMessageHandler: MessageHandler {
    
    private weak var signalViewModel: SignalViewModel?
    
    var middleware: [String] { ["security", "validation", "location"] }
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 8 } // 信號處理優先級較高
    
    init(signalViewModel: SignalViewModel) {
        self.signalViewModel = signalViewModel
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let signalViewModel = signalViewModel else {
            throw RoutingError.handlerNotFound
        }
        
        // 解析信號數據
        let signalData = try parseSignalData(message.payload)
        
        // 位置驗證
        if let location = signalData.location {
            let isValidLocation = await validateLocation(location, for: message.source)
            if !isValidLocation {
                print("⚠️ 信號位置驗證失敗: \(message.source)")
                return
            }
        }
        
        // 處理信號
        await signalViewModel.processReceivedSignal(signalData, from: message.source)
        
        // 緊急信號自動轉發
        if signalData.isEmergency {
            try await forwardEmergencySignal(message, signalViewModel: signalViewModel)
        }
    }
    
    private func parseSignalData(_ payload: Data) throws -> SignalData {
        // 使用 SignalBinaryCodec 解析二進制數據
        let (signal, nickname, emoteType, trustScore, deviceFingerprint) = try SignalBinaryCodec.decode(from: payload)
        
        return SignalData(
            signal: signal,
            nickname: nickname,
            emoteType: emoteType,
            trustScore: trustScore,
            deviceFingerprint: deviceFingerprint,
            isEmergency: signal.contains("🆘") || signal.contains("急救")
        )
    }
    
    private func validateLocation(_ location: LocationData, for source: String) async -> Bool {
        // 位置合理性檢查（距離、時間等）
        return true // 簡化實現
    }
    
    private func forwardEmergencySignal(_ message: UniversalMessage, signalViewModel: SignalViewModel) async throws {
        // 緊急信號自動廣播轉發
        let emergencyMessage = UniversalMessage(
            type: .emergency,
            category: .emergency,
            priority: .emergency,
            source: message.source,
            destination: .broadcast(scope: .emergency),
            payload: message.payload
        )
        
        // 通過路由器轉發（避免直接依賴其他組件）
        if let router = signalViewModel.serviceContainer?.unifiedRouter {
            try await router.routeMessage(emergencyMessage, from: message.source)
        }
    }
}

// MARK: - 聊天訊息處理器
@MainActor
class ChatMessageHandler: MessageHandler {
    
    private weak var bingoNetworkManager: BingoNetworkManager?
    
    var middleware: [String] { ["security", "validation", "content_filter"] }
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 3 }
    
    init(bingoNetworkManager: BingoNetworkManager) {
        self.bingoNetworkManager = bingoNetworkManager
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let bingoNetworkManager = bingoNetworkManager else {
            throw RoutingError.handlerNotFound
        }
        
        // 解析聊天訊息
        let chatMessage = try parseChatMessage(message.payload)
        
        // 內容過濾
        if await isContentBlocked(chatMessage) {
            print("⚠️ 聊天訊息被內容過濾器阻止")
            return
        }
        
        // 路由到對應房間
        switch destination {
        case .direct(let peerID):
            await bingoNetworkManager.handleDirectMessage(chatMessage, from: message.source, to: peerID)
            
        case .broadcast(let scope):
            if scope == .local {
                await bingoNetworkManager.handleRoomMessage(chatMessage, from: message.source)
            }
            
        case .multicast(let targets):
            for target in targets {
                await bingoNetworkManager.handleDirectMessage(chatMessage, from: message.source, to: target)
            }
            
        case .conditional(_):
            await bingoNetworkManager.handleRoomMessage(chatMessage, from: message.source)
        }
    }
    
    private func parseChatMessage(_ payload: Data) throws -> ChatMessage {
        // 使用二進制協議解析聊天訊息
        // 實際實現需要根據聊天訊息的二進制格式來解析
        // 這裡簡化處理
        let content = String(data: payload, encoding: .utf8) ?? ""
        return ChatMessage(
            content: content,
            roomID: nil,
            timestamp: Date(),
            mentions: nil
        )
    }
    
    private func isContentBlocked(_ message: ChatMessage) async -> Bool {
        // 內容過濾邏輯
        return false // 簡化實現
    }
}

// MARK: - 遊戲訊息處理器
@MainActor
class GameMessageHandler: MessageHandler {
    
    private weak var gameStateManager: BingoGameStateManager?
    
    var middleware: [String] { ["security", "validation", "game_rules"] }
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 4 }
    
    init(gameStateManager: BingoGameStateManager) {
        self.gameStateManager = gameStateManager
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let gameStateManager = gameStateManager else {
            throw RoutingError.handlerNotFound
        }
        
        // 解析遊戲訊息
        let gameMessage = try parseGameMessage(message.payload)
        
        // 遊戲規則驗證
        if !await isValidGameAction(gameMessage) {
            print("⚠️ 無效的遊戲動作")
            return
        }
        
        // 處理遊戲動作
        await gameStateManager.handleGameAction(gameMessage, from: message.source)
        
        // 遊戲狀態同步
        if gameMessage.requiresSync {
            try await syncGameState(gameMessage, destination: destination)
        }
    }
    
    private func parseGameMessage(_ payload: Data) throws -> GameMessage {
        // 使用二進制協議解析遊戲訊息
        guard let gameMessage = BinaryGameProtocol.decodeGameMessage(payload) else {
            throw RoutingError.invalidMessage("無法解析遊戲訊息")
        }
        return gameMessage
    }
    
    private func isValidGameAction(_ message: GameMessage) async -> Bool {
        // 遊戲規則驗證
        return true // 簡化實現
    }
    
    private func syncGameState(_ message: GameMessage, destination: MessageDestination) async throws {
        // 遊戲狀態同步邏輯
    }
}

// MARK: - 安全訊息處理器
@MainActor
class SecurityMessageHandler: MessageHandler {
    
    private weak var securityService: SecurityService?
    
    var middleware: [String] { ["validation", "metrics"] } // 安全訊息跳過安全中間件避免循環
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 9 } // 安全訊息最高優先級
    
    init(securityService: SecurityService) {
        self.securityService = securityService
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let securityService = securityService else {
            throw RoutingError.handlerNotFound
        }
        
        // 解析安全訊息
        let securityMessage = try parseSecurityMessage(message.payload)
        
        // 處理不同類型的安全事件
        switch securityMessage.type {
        case .keyExchange:
            try await securityService.handleKeyExchange(securityMessage.data, from: message.source)
            
        case .threatAlert:
            await securityService.handleThreatAlert(securityMessage.data, from: message.source)
            
        case .trustUpdate:
            await securityService.handleTrustUpdate(securityMessage.data, from: message.source)
            
        case .securityEvent:
            await securityService.logSecurityEvent(securityMessage.data, from: message.source)
        }
    }
    
    private func parseSecurityMessage(_ payload: Data) throws -> SecurityMessage {
        // 使用二進制協議解析安全訊息
        // 實際實現需要根據安全訊息的二進制格式來解析
        return SecurityMessage(
            type: .securityEvent,
            data: payload,
            timestamp: Date()
        )
    }
}

// MARK: - 系統訊息處理器
@MainActor
class SystemMessageHandler: MessageHandler {
    
    private weak var autonomousManager: AutonomousSystemManager?
    
    var middleware: [String] { ["validation", "metrics"] }
    var routingConditions: [RoutingCondition] { [.always] }
    var priority: Int { 6 }
    
    init(autonomousManager: AutonomousSystemManager) {
        self.autonomousManager = autonomousManager
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        guard let autonomousManager = autonomousManager else {
            throw RoutingError.handlerNotFound
        }
        
        // 解析系統訊息
        let systemMessage = try parseSystemMessage(message.payload)
        
        // 處理系統事件
        switch systemMessage.type {
        case .healthCheck:
            await autonomousManager.handleHealthCheck(systemMessage.data, from: message.source)
            
        case .maintenance:
            await autonomousManager.scheduleMaintenance(systemMessage.data, from: message.source)
            
        case .diagnostics:
            await autonomousManager.handleDiagnostics(systemMessage.data, from: message.source)
            
        case .configuration:
            try await autonomousManager.updateConfiguration(systemMessage.data, from: message.source)
        }
    }
    
    private func parseSystemMessage(_ payload: Data) throws -> SystemMessage {
        // 使用二進制協議解析系統訊息
        // 實際實現需要根據系統訊息的二進制格式來解析
        return SystemMessage(
            type: .diagnostics,
            data: payload,
            timestamp: Date()
        )
    }
}

// MARK: - 支援數據結構

struct SignalData {
    let signal: String
    let nickname: String
    let emoteType: EmoteType
    let trustScore: Double
    let deviceFingerprint: String?
    let location: LocationData?
    let isEmergency: Bool
}

struct SignalMessage: Codable {
    let signal: String
    let nickname: String
    let emoteType: String
    let trustScore: Double?
    let location: LocationData?
    let isEmergency: Bool
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
}

struct ChatMessage: Codable {
    let content: String
    let roomID: String?
    let timestamp: Date
    let mentions: [String]?
}

struct GameMessage: Codable {
    let action: String
    let gameID: String
    let playerID: String
    let data: [String: Any]
    let requiresSync: Bool
    
    private enum CodingKeys: String, CodingKey {
        case action, gameID, playerID, requiresSync
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        gameID = try container.decode(String.self, forKey: .gameID)
        playerID = try container.decode(String.self, forKey: .playerID)
        requiresSync = try container.decode(Bool.self, forKey: .requiresSync)
        data = [:] // 簡化實現
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(gameID, forKey: .gameID)
        try container.encode(playerID, forKey: .playerID)
        try container.encode(requiresSync, forKey: .requiresSync)
    }
}

struct SecurityMessage: Codable {
    let type: SecurityMessageType
    let data: Data
    let timestamp: Date
}

enum SecurityMessageType: String, Codable {
    case keyExchange = "key_exchange"
    case threatAlert = "threat_alert"
    case trustUpdate = "trust_update"
    case securityEvent = "security_event"
}

struct SystemMessage: Codable {
    let type: SystemMessageType
    let data: Data
    let timestamp: Date
}

enum SystemMessageType: String, Codable {
    case healthCheck = "health_check"
    case maintenance = "maintenance"
    case diagnostics = "diagnostics"
    case configuration = "configuration"
}

// MARK: - 處理器工廠
class MessageHandlerFactory {
    
    static func createHandlers(serviceContainer: ServiceContainer) -> [MessageType: any MessageHandler] {
        var handlers: [MessageType: any MessageHandler] = [:]
        
        // 網狀網路處理器
        if let meshManager = serviceContainer.meshManager {
            let meshHandler = MeshMessageHandler(meshManager: meshManager)
            handlers[.heartbeat] = meshHandler
            handlers[.topology] = meshHandler
        }
        
        // 信號處理器
        // 這裡需要根據實際的 ServiceContainer 結構調整
        // handlers[.signal] = SignalMessageHandler(signalViewModel: ...)
        
        // 聊天處理器
        // handlers[.chat] = ChatMessageHandler(bingoNetworkManager: ...)
        
        // 遊戲處理器
        // handlers[.game] = GameMessageHandler(gameStateManager: ...)
        
        // 安全處理器
        if let securityService = serviceContainer.securityService {
            handlers[.security] = SecurityMessageHandler(securityService: securityService)
        }
        
        // 系統處理器
        if let autonomousManager = serviceContainer.autonomousSystemManager {
            handlers[.system] = SystemMessageHandler(autonomousManager: autonomousManager)
        }
        
        return handlers
    }
}