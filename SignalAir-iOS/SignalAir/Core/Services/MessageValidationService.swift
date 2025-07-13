import Foundation

/// 消息驗證服務 - 消除重複的驗證邏輯
@MainActor
class MessageValidationService {
    
    // MARK: - Singleton
    static let shared = MessageValidationService()
    private init() {}
    
    // MARK: - 驗證結果
    
    /// 驗證結果枚舉
    enum ValidationResult {
        case success
        case failure(reason: String)
        
        var isValid: Bool {
            switch self {
            case .success: return true
            case .failure: return false
            }
        }
        
        var errorMessage: String? {
            switch self {
            case .success: return nil
            case .failure(let reason): return reason
            }
        }
    }
    
    // MARK: - 基礎驗證方法
    
    /// 驗證字符串是否有效
    /// - Parameters:
    ///   - string: 要驗證的字符串
    ///   - maxLength: 最大長度限制
    ///   - allowEmpty: 是否允許空字符串
    /// - Returns: 驗證結果
    func validateString(_ string: String?, maxLength: Int = 255, allowEmpty: Bool = false) -> ValidationResult {
        guard let string = string else {
            return .failure(reason: "字符串不能為 nil")
        }
        
        if !allowEmpty && string.isEmpty {
            return .failure(reason: "字符串不能為空")
        }
        
        if string.count > maxLength {
            return .failure(reason: "字符串長度超過限制 (\(maxLength))")
        }
        
        return .success
    }
    
    /// 驗證數據是否有效
    /// - Parameters:
    ///   - data: 要驗證的數據
    ///   - maxSize: 最大大小限制
    ///   - allowEmpty: 是否允許空數據
    /// - Returns: 驗證結果
    func validateData(_ data: Data?, maxSize: Int = 65536, allowEmpty: Bool = true) -> ValidationResult {
        guard let data = data else {
            return .failure(reason: "數據不能為 nil")
        }
        
        if !allowEmpty && data.isEmpty {
            return .failure(reason: "數據不能為空")
        }
        
        if data.count > maxSize {
            return .failure(reason: "數據大小超過限制 (\(maxSize) bytes)")
        }
        
        return .success
    }
    
    /// 驗證數組是否有效
    /// - Parameters:
    ///   - array: 要驗證的數組
    ///   - maxCount: 最大元素數量
    ///   - allowEmpty: 是否允許空數組
    /// - Returns: 驗證結果
    func validateArray<T>(_ array: [T]?, maxCount: Int = 100, allowEmpty: Bool = true) -> ValidationResult {
        guard let array = array else {
            return .failure(reason: "數組不能為 nil")
        }
        
        if !allowEmpty && array.isEmpty {
            return .failure(reason: "數組不能為空")
        }
        
        if array.count > maxCount {
            return .failure(reason: "數組元素數量超過限制 (\(maxCount))")
        }
        
        return .success
    }
    
    /// 驗證數值範圍
    /// - Parameters:
    ///   - value: 要驗證的數值
    ///   - min: 最小值
    ///   - max: 最大值
    /// - Returns: 驗證結果
    func validateNumberRange<T: Comparable>(_ value: T, min: T, max: T) -> ValidationResult {
        if value < min {
            return .failure(reason: "數值小於最小值 (\(min))")
        }
        
        if value > max {
            return .failure(reason: "數值大於最大值 (\(max))")
        }
        
        return .success
    }
    
    // MARK: - 業務邏輯驗證
    
    /// 驗證玩家ID
    /// - Parameter playerID: 玩家ID
    /// - Returns: 驗證結果
    func validatePlayerID(_ playerID: String?) -> ValidationResult {
        let stringValidation = validateString(playerID, maxLength: 64, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let playerID = playerID!
        
        // 檢查是否為有效的 UUID 格式
        if UUID(uuidString: playerID) == nil {
            return .failure(reason: "玩家ID格式無效")
        }
        
        return .success
    }
    
    /// 驗證玩家名稱
    /// - Parameter playerName: 玩家名稱
    /// - Returns: 驗證結果
    func validatePlayerName(_ playerName: String?) -> ValidationResult {
        let stringValidation = validateString(playerName, maxLength: 20, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let playerName = playerName!
        
        // 檢查是否包含非法字符
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet.whitespaces)
        if playerName.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .failure(reason: "玩家名稱包含非法字符")
        }
        
        // 檢查是否全為空格
        if playerName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(reason: "玩家名稱不能全為空格")
        }
        
        return .success
    }
    
    /// 驗證房間ID
    /// - Parameter roomID: 房間ID
    /// - Returns: 驗證結果
    func validateRoomID(_ roomID: String?) -> ValidationResult {
        let stringValidation = validateString(roomID, maxLength: 32, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let roomID = roomID!
        
        // 檢查房間ID格式（只允許字母、數字和連字符）
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        if roomID.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .failure(reason: "房間ID格式無效")
        }
        
        return .success
    }
    
    /// 驗證聊天消息
    /// - Parameter message: 聊天消息
    /// - Returns: 驗證結果
    func validateChatMessage(_ message: String?) -> ValidationResult {
        let stringValidation = validateString(message, maxLength: 500, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let message = message!
        
        // 檢查是否全為空格
        if message.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(reason: "聊天消息不能全為空格")
        }
        
        // 檢查是否包含敏感詞（簡化版）
        let bannedWords = ["spam", "hack", "cheat"]
        let lowerMessage = message.lowercased()
        for word in bannedWords {
            if lowerMessage.contains(word) {
                return .failure(reason: "聊天消息包含禁止詞語")
            }
        }
        
        return .success
    }
    
    /// 驗證遊戲消息類型
    /// - Parameter messageType: 消息類型
    /// - Returns: 驗證結果
    func validateGameMessageType(_ messageType: String?) -> ValidationResult {
        let stringValidation = validateString(messageType, maxLength: 50, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let messageType = messageType!
        
        // 檢查是否為有效的消息類型
        let validTypes = [
            "game_start", "game_end", "game_restart",
            "number_draw", "player_join", "player_leave",
            "player_progress", "chat_message", "emote",
            "heartbeat", "sync", "room_sync", "winner_announcement",
            "reconnect_request", "game_state_update"
        ]
        
        if !validTypes.contains(messageType) {
            return .failure(reason: "無效的遊戲消息類型: \(messageType)")
        }
        
        return .success
    }
    
    /// 驗證數據偏移量
    /// - Parameters:
    ///   - offset: 偏移量
    ///   - dataSize: 數據總大小
    ///   - requiredBytes: 需要的字節數
    /// - Returns: 驗證結果
    func validateDataOffset(_ offset: Int, dataSize: Int, requiredBytes: Int = 1) -> ValidationResult {
        if offset < 0 {
            return .failure(reason: "偏移量不能為負數")
        }
        
        if offset >= dataSize {
            return .failure(reason: "偏移量超出數據範圍")
        }
        
        if offset + requiredBytes > dataSize {
            return .failure(reason: "偏移量加上所需字節數超出數據範圍")
        }
        
        return .success
    }
    
    // MARK: - 網絡相關驗證
    
    /// 驗證網絡連接狀態
    /// - Parameters:
    ///   - isNetworkActive: 網絡是否活躍
    ///   - connectedPeersCount: 連接的對等節點數量
    /// - Returns: 驗證結果
    func validateNetworkState(isNetworkActive: Bool, connectedPeersCount: Int = 0) -> ValidationResult {
        if !isNetworkActive {
            return .failure(reason: "網絡未啟動")
        }
        
        if connectedPeersCount < 0 {
            return .failure(reason: "連接的對等節點數量不能為負數")
        }
        
        return .success
    }
    
    /// 驗證廣播消息
    /// - Parameters:
    ///   - messageType: 消息類型
    ///   - data: 消息數據
    ///   - isNetworkActive: 網絡是否活躍
    /// - Returns: 驗證結果
    func validateBroadcastMessage(messageType: String?, data: Data?, isNetworkActive: Bool) -> ValidationResult {
        // 驗證網絡狀態
        let networkValidation = validateNetworkState(isNetworkActive: isNetworkActive)
        guard networkValidation.isValid else { return networkValidation }
        
        // 驗證消息類型
        let typeValidation = validateGameMessageType(messageType)
        guard typeValidation.isValid else { return typeValidation }
        
        // 驗證消息數據
        let dataValidation = validateData(data, maxSize: 8192, allowEmpty: true)
        guard dataValidation.isValid else { return dataValidation }
        
        return .success
    }
    
    // MARK: - 遊戲相關驗證
    
    /// 驗證遊戲狀態
    /// - Parameter gameState: 遊戲狀態
    /// - Returns: 驗證結果
    func validateGameState(_ gameState: String?) -> ValidationResult {
        let stringValidation = validateString(gameState, maxLength: 20, allowEmpty: false)
        guard stringValidation.isValid else { return stringValidation }
        
        let gameState = gameState!
        
        // 檢查是否為有效的遊戲狀態
        let validStates = ["waiting", "playing", "finished"]
        if !validStates.contains(gameState) {
            return .failure(reason: "無效的遊戲狀態: \(gameState)")
        }
        
        return .success
    }
    
    /// 驗證房間玩家數量
    /// - Parameters:
    ///   - playerCount: 當前玩家數量
    ///   - maxPlayers: 最大玩家數量
    ///   - minPlayers: 最小玩家數量
    /// - Returns: 驗證結果
    func validateRoomPlayerCount(_ playerCount: Int, maxPlayers: Int = 6, minPlayers: Int = 2) -> ValidationResult {
        if playerCount < 0 {
            return .failure(reason: "玩家數量不能為負數")
        }
        
        if playerCount > maxPlayers {
            return .failure(reason: "玩家數量超過最大限制 (\(maxPlayers))")
        }
        
        return .success
    }
    
    /// 驗證賓果號碼
    /// - Parameter number: 賓果號碼
    /// - Returns: 驗證結果
    func validateBingoNumber(_ number: Int) -> ValidationResult {
        return validateNumberRange(number, min: 1, max: 99)
    }
    
    /// 驗證賓果線數
    /// - Parameter lines: 完成的線數
    /// - Returns: 驗證結果
    func validateBingoLines(_ lines: Int) -> ValidationResult {
        return validateNumberRange(lines, min: 0, max: 12)
    }
    
    // MARK: - 組合驗證方法
    
    /// 驗證玩家信息
    /// - Parameters:
    ///   - playerID: 玩家ID
    ///   - playerName: 玩家名稱
    /// - Returns: 驗證結果
    func validatePlayerInfo(playerID: String?, playerName: String?) -> ValidationResult {
        let idValidation = validatePlayerID(playerID)
        guard idValidation.isValid else { return idValidation }
        
        let nameValidation = validatePlayerName(playerName)
        guard nameValidation.isValid else { return nameValidation }
        
        return .success
    }
    
    /// 驗證房間信息
    /// - Parameters:
    ///   - roomID: 房間ID
    ///   - hostID: 主機ID
    ///   - playerCount: 玩家數量
    /// - Returns: 驗證結果
    func validateRoomInfo(roomID: String?, hostID: String?, playerCount: Int) -> ValidationResult {
        let roomValidation = validateRoomID(roomID)
        guard roomValidation.isValid else { return roomValidation }
        
        let hostValidation = validatePlayerID(hostID)
        guard hostValidation.isValid else { return hostValidation }
        
        let countValidation = validateRoomPlayerCount(playerCount)
        guard countValidation.isValid else { return countValidation }
        
        return .success
    }
    
    /// 驗證遊戲消息
    /// - Parameters:
    ///   - messageType: 消息類型
    ///   - roomID: 房間ID
    ///   - senderName: 發送者名稱
    ///   - data: 消息數據
    /// - Returns: 驗證結果
    func validateGameMessage(messageType: String?, roomID: String?, senderName: String?, data: Data?) -> ValidationResult {
        let typeValidation = validateGameMessageType(messageType)
        guard typeValidation.isValid else { return typeValidation }
        
        let roomValidation = validateRoomID(roomID)
        guard roomValidation.isValid else { return roomValidation }
        
        let senderValidation = validatePlayerName(senderName)
        guard senderValidation.isValid else { return senderValidation }
        
        let dataValidation = validateData(data, maxSize: 8192, allowEmpty: true)
        guard dataValidation.isValid else { return dataValidation }
        
        return .success
    }
    
    /// 驗證聊天消息完整信息
    /// - Parameters:
    ///   - message: 聊天消息內容
    ///   - senderName: 發送者名稱
    ///   - roomID: 房間ID
    /// - Returns: 驗證結果
    func validateChatMessageInfo(message: String?, senderName: String?, roomID: String?) -> ValidationResult {
        let messageValidation = validateChatMessage(message)
        guard messageValidation.isValid else { return messageValidation }
        
        let senderValidation = validatePlayerName(senderName)
        guard senderValidation.isValid else { return senderValidation }
        
        let roomValidation = validateRoomID(roomID)
        guard roomValidation.isValid else { return roomValidation }
        
        return .success
    }
    
    // MARK: - 工具方法
    
    /// 記錄驗證失敗
    /// - Parameters:
    ///   - result: 驗證結果
    ///   - context: 上下文信息
    func logValidationFailure(_ result: ValidationResult, context: String = "") {
        if case .failure(let reason) = result {
            print("❌ 驗證失敗 [\(context)]: \(reason)")
        }
    }
    
    /// 檢查多個驗證結果
    /// - Parameter results: 驗證結果數組
    /// - Returns: 綜合驗證結果
    func validateMultiple(_ results: [ValidationResult]) -> ValidationResult {
        for result in results {
            if !result.isValid {
                return result
            }
        }
        return .success
    }
    
    /// 安全執行驗證
    /// - Parameter validation: 驗證閉包
    /// - Returns: 驗證結果
    func safeValidation(_ validation: () throws -> ValidationResult) -> ValidationResult {
        do {
            return try validation()
        } catch {
            return .failure(reason: "驗證過程中發生錯誤: \(error.localizedDescription)")
        }
    }
}