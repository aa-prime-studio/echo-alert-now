import Foundation
import Combine

/// 遊戲聊天服務 - 負責聊天和表情符號功能
@MainActor
class GameChatService: GameChatServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var chatMessages: [RoomChatMessage] = []
    
    // MARK: - Dependencies
    
    private let networkManager: BingoNetworkManagerProtocol
    private let deviceName: String
    
    // MARK: - Private Properties
    
    private let maxChatHistory = 100 // 最大聊天記錄數
    private var messageIdCounter = 0
    
    // MARK: - Publishers
    
    private let chatMessagesSubject = CurrentValueSubject<[RoomChatMessage], Never>([])
    private let emoteReceivedSubject = PassthroughSubject<(EmoteType, String), Never>()
    
    var chatMessagesPublisher: AnyPublisher<[RoomChatMessage], Never> {
        chatMessagesSubject.eraseToAnyPublisher()
    }
    
    var emoteReceived: AnyPublisher<(EmoteType, String), Never> {
        emoteReceivedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(networkManager: BingoNetworkManagerProtocol, deviceName: String) {
        self.networkManager = networkManager
        self.deviceName = deviceName
        
        print("💬 GameChatService: 初始化完成")
    }
    
    // MARK: - Chat Messages
    
    /// 發送聊天消息
    func sendChatMessage(_ message: String, to roomID: String) async throws {
        print("💬 GameChatService: 發送聊天消息 - \(message)")
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GameServiceError.invalidGameState
        }
        
        // 創建聊天消息數據
        let chatData = createChatMessageData(message: message, roomID: roomID)
        
        // 廣播聊天消息
        try await networkManager.broadcastGameAction(
            type: .chatMessage,
            data: chatData,
            priority: .normal
        )
        
        // 添加到本地聊天記錄
        addLocalChatMessage(message: message, senderName: deviceName, isLocal: true)
        
        print("✅ GameChatService: 聊天消息發送成功")
    }
    
    /// 處理接收到的聊天消息
    func handleReceivedChatMessage(_ message: GameMessage) {
        print("💬 GameChatService: 處理接收聊天消息")
        
        guard let chatData = decodeChatMessage(message.data) else {
            print("❌ GameChatService: 解析聊天消息失敗")
            return
        }
        
        // 添加到聊天記錄
        addLocalChatMessage(
            message: chatData.message,
            senderName: chatData.senderName,
            isLocal: false
        )
    }
    
    /// 添加本地聊天消息
    private func addLocalChatMessage(message: String, senderName: String, isLocal: Bool) {
        let chatMessage = RoomChatMessage(
            id: generateMessageId(),
            sender: senderName,
            content: message,
            timestamp: Date(),
            isLocal: isLocal
        )
        
        chatMessages.append(chatMessage)
        
        // 限制聊天記錄數量
        if chatMessages.count > maxChatHistory {
            chatMessages.removeFirst(chatMessages.count - maxChatHistory)
        }
        
        // 發布更新
        chatMessagesSubject.send(chatMessages)
        
        print("💬 GameChatService: 聊天消息已添加 - \(senderName): \(message)")
    }
    
    // MARK: - Emotes
    
    /// 發送表情符號
    func sendEmote(_ emote: EmoteType, to roomID: String) async throws {
        print("😊 GameChatService: 發送表情符號 - \(emote.rawValue) (\(emote.emoji))")
        
        // 創建表情數據
        let emoteData = createEmoteData(emote: emote, roomID: roomID)
        
        // 廣播表情消息
        try await networkManager.broadcastGameAction(
            type: .emote,
            data: emoteData,
            priority: .normal
        )
        
        // 添加到本地聊天記錄作為表情消息
        addEmoteToChat(emote: emote, senderName: deviceName, isLocal: true)
        
        print("✅ GameChatService: 表情符號發送成功 - \(emote.emoji)")
    }
    
    /// 處理接收到的表情符號
    func handleReceivedEmote(_ message: GameMessage) {
        print("😊 GameChatService: 處理接收表情符號")
        
        guard let emoteData = decodeEmoteMessage(message.data) else {
            print("❌ GameChatService: 解析表情消息失敗")
            return
        }
        
        print("✅ GameChatService: 成功解析表情 - \(emoteData.emote.rawValue) (\(emoteData.emote.emoji))")
        
        // 發布表情接收事件
        emoteReceivedSubject.send((emoteData.emote, emoteData.senderName))
        
        // 添加到聊天記錄
        addEmoteToChat(emote: emoteData.emote, senderName: emoteData.senderName, isLocal: false)
    }
    
    /// 添加表情到聊天記錄
    private func addEmoteToChat(emote: EmoteType, senderName: String, isLocal: Bool) {
        // 【FIX】使用主線的模板系統：暱稱 + 表情
        let formattedMessage = String(format: emote.template, senderName)
        
        let emoteMessage = RoomChatMessage(
            id: generateMessageId(),
            sender: senderName,
            content: formattedMessage,
            timestamp: Date(),
            isLocal: isLocal,
            isEmote: true,
            emoteType: emote
        )
        
        chatMessages.append(emoteMessage)
        
        // 限制聊天記錄數量
        if chatMessages.count > maxChatHistory {
            chatMessages.removeFirst(chatMessages.count - maxChatHistory)
        }
        
        // 發布更新
        chatMessagesSubject.send(chatMessages)
        
        print("😊 GameChatService: 表情已添加到聊天 - \(senderName): \(emote.emoji)")
    }
    
    // MARK: - Chat History Management
    
    /// 清除聊天記錄
    func clearChatHistory() {
        print("🧹 GameChatService: 清除聊天記錄")
        
        chatMessages.removeAll()
        chatMessagesSubject.send(chatMessages)
    }
    
    /// 獲取最近的聊天消息
    func getRecentMessages(count: Int) -> [RoomChatMessage] {
        let recentCount = min(count, chatMessages.count)
        return Array(chatMessages.suffix(recentCount))
    }
    
    /// 搜索聊天消息
    func searchMessages(containing text: String) -> [RoomChatMessage] {
        return chatMessages.filter { message in
            message.message.localizedCaseInsensitiveContains(text) ||
            message.playerName.localizedCaseInsensitiveContains(text)
        }
    }
    
    // MARK: - Message Encoding/Decoding
    
    /// 創建聊天消息數據
    private func createChatMessageData(message: String, roomID: String) -> Data {
        var data = Data()
        
        // 房間ID長度和數據
        let roomIDData = roomID.data(using: .utf8) ?? Data()
        let roomIDLength = min(roomIDData.count, 255)
        data.append(UInt8(roomIDLength))
        data.append(roomIDData.prefix(roomIDLength))
        
        // 發送者名稱長度和數據
        let senderData = deviceName.data(using: .utf8) ?? Data()
        let senderLength = min(senderData.count, 255)
        data.append(UInt8(senderLength))
        data.append(senderData.prefix(senderLength))
        
        // 消息內容長度和數據
        let messageData = message.data(using: .utf8) ?? Data()
        let messageLength = UInt16(messageData.count)
        data.append(contentsOf: withUnsafeBytes(of: messageLength.littleEndian) { Array($0) })
        data.append(messageData)
        
        // 時間戳
        let timestamp = UInt64(Date().timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian) { Array($0) })
        
        return data
    }
    
    /// 創建表情數據
    private func createEmoteData(emote: EmoteType, roomID: String) -> Data {
        var data = Data()
        
        // 房間ID
        let roomIDData = roomID.data(using: .utf8) ?? Data()
        let roomIDLength = min(roomIDData.count, 255)
        data.append(UInt8(roomIDLength))
        data.append(roomIDData.prefix(roomIDLength))
        
        // 發送者名稱
        let senderData = deviceName.data(using: .utf8) ?? Data()
        let senderLength = min(senderData.count, 255)
        data.append(UInt8(senderLength))
        data.append(senderData.prefix(senderLength))
        
        // 【FIX】使用rawValue確保編碼解碼一致性
        let emoteData = emote.rawValue.data(using: .utf8) ?? Data()
        let emoteLength = min(emoteData.count, 255)
        data.append(UInt8(emoteLength))
        data.append(emoteData.prefix(emoteLength))
        
        // 時間戳
        let timestamp = UInt64(Date().timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian) { Array($0) })
        
        return data
    }
    
    /// 解碼聊天消息
    private func decodeChatMessage(_ data: Data) -> (message: String, senderName: String, roomID: String)? {
        guard data.count > 4 else { return nil }
        
        var offset = 0
        
        // 房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        guard offset + roomIDLength <= data.count else { return nil }
        let roomIDData = data.subdata(in: offset..<(offset + roomIDLength))
        let roomID = String(data: roomIDData, encoding: .utf8) ?? ""
        offset += roomIDLength
        
        // 發送者名稱
        guard offset < data.count else { return nil }
        let senderLength = Int(data[offset])
        offset += 1
        
        guard offset + senderLength <= data.count else { return nil }
        let senderData = data.subdata(in: offset..<(offset + senderLength))
        let senderName = String(data: senderData, encoding: .utf8) ?? ""
        offset += senderLength
        
        // 消息內容長度
        guard offset + 2 <= data.count else { return nil }
        let messageLength = data.subdata(in: offset..<(offset + 2)).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
        offset += 2
        
        // 消息內容
        guard offset + Int(messageLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<(offset + Int(messageLength)))
        let message = String(data: messageData, encoding: .utf8) ?? ""
        
        return (message: message, senderName: senderName, roomID: roomID)
    }
    
    /// 解碼表情消息
    private func decodeEmoteMessage(_ data: Data) -> (emote: EmoteType, senderName: String, roomID: String)? {
        guard data.count > 3 else { return nil }
        
        var offset = 0
        
        // 房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        guard offset + roomIDLength <= data.count else { return nil }
        let roomIDData = data.subdata(in: offset..<(offset + roomIDLength))
        let roomID = String(data: roomIDData, encoding: .utf8) ?? ""
        offset += roomIDLength
        
        // 發送者名稱
        guard offset < data.count else { return nil }
        let senderLength = Int(data[offset])
        offset += 1
        
        guard offset + senderLength <= data.count else { return nil }
        let senderData = data.subdata(in: offset..<(offset + senderLength))
        let senderName = String(data: senderData, encoding: .utf8) ?? ""
        offset += senderLength
        
        // 【FIX】表情符號解碼
        guard offset < data.count else { return nil }
        let emoteLength = Int(data[offset])
        offset += 1
        
        guard offset + emoteLength <= data.count else { return nil }
        let emoteData = data.subdata(in: offset..<(offset + emoteLength))
        let emojiString = String(data: emoteData, encoding: .utf8) ?? ""
        
        // 從emoji字符串找到對應的EmoteType
        let emote = EmoteType.allCases.first { $0.emoji == emojiString } ?? .happy
        
        return (emote: emote, senderName: senderName, roomID: roomID)
    }
    
    // MARK: - Utilities
    
    /// 生成消息ID
    private func generateMessageId() -> String {
        messageIdCounter += 1
        return "msg_\(messageIdCounter)_\(Date().timeIntervalSince1970)"
    }
    
    /// 驗證消息內容
    private func validateMessageContent(_ message: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 500 // 最大500字符
    }
    
    /// 過濾不當內容（基本實現）
    private func filterInappropriateContent(_ message: String) -> String {
        // 這裡可以實現更複雜的內容過濾邏輯
        return message
    }
    
    // MARK: - Statistics
    
    /// 獲取聊天統計
    func getChatStatistics() -> (totalMessages: Int, uniqueSenders: Int, emoteCount: Int) {
        let totalMessages = chatMessages.count
        let uniqueSenders = Set(chatMessages.map { $0.playerName }).count
        let emoteCount = chatMessages.filter { $0.isEmote }.count
        
        return (totalMessages: totalMessages, uniqueSenders: uniqueSenders, emoteCount: emoteCount)
    }
    
    /// 獲取最活躍的發送者
    func getMostActiveSender() -> String? {
        let senderCounts = Dictionary(grouping: chatMessages, by: { $0.playerName })
            .mapValues { $0.count }
        
        return senderCounts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Lifecycle
    
    /// 清理資源
    func cleanup() {
        print("🧹 GameChatService: 清理資源")
        
        clearChatHistory()
        messageIdCounter = 0
    }
    
    deinit {
        print("🗑️ GameChatService: deinit")
        // 在 deinit 中避免所有 MainActor 操作
    }
}

// MARK: - Supporting Types
// RoomChatMessage 初始化方法已移至 SharedTypes.swift