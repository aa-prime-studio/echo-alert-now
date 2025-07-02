import Foundation

// MARK: - 純二進制遊戲協議
// 專為賓果遊戲設計的高效二進制協議

class BinaryGameProtocol {
    
    // MARK: - 遊戲訊息類型
    enum GameMessageTypeBinary: UInt8 {
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
    }
    
    // MARK: - 編碼方法
    
    /// 編碼遊戲訊息為二進制格式
    static func encodeGameMessage(
        type: GameMessageType,
        senderID: String,
        senderName: String,
        gameRoomID: String,
        data: Data
    ) -> Data {
        var binaryData = Data()
        
        // 1. 協議版本 (1 byte)
        binaryData.append(1)
        
        // 2. MeshMessage 類型 (1 byte) - 必須是 0x06 (game)
        binaryData.append(0x06)
        
        // 3. 遊戲訊息子類型 (1 byte)
        binaryData.append(gameMessageTypeToBinary(type).rawValue)
        
        // 4. 時間戳 (4 bytes)
        let timestamp = UInt32(Date().timeIntervalSince1970)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian) { Array($0) })
        
        // 5. 發送者ID長度 + 內容
        let senderIDData = senderID.data(using: .utf8) ?? Data()
        let safeSenderIDLength = min(senderIDData.count, 255)
        binaryData.append(UInt8(safeSenderIDLength))
        binaryData.append(senderIDData.prefix(safeSenderIDLength))
        
        // 6. 發送者名稱長度 + 內容 (使用清理後的暱稱)
        let cleanSenderName = NicknameFormatter.cleanNickname(senderName)
        let senderNameData = cleanSenderName.data(using: .utf8) ?? Data()
        let safeSenderNameLength = min(senderNameData.count, 255)
        binaryData.append(UInt8(safeSenderNameLength))
        binaryData.append(senderNameData.prefix(safeSenderNameLength))
        
        // 7. 遊戲房間ID長度 + 內容
        let roomIDData = gameRoomID.data(using: .utf8) ?? Data()
        let safeRoomIDLength = min(roomIDData.count, 255)
        binaryData.append(UInt8(safeRoomIDLength))
        binaryData.append(roomIDData.prefix(safeRoomIDLength))
        
        // 8. 數據長度 (2 bytes) + 內容
        let dataLength = UInt16(data.count)
        binaryData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        binaryData.append(data)
        
        return binaryData
    }
    
    /// 解碼二進制遊戲訊息
    static func decodeGameMessage(_ data: Data) -> GameMessage? {
        guard data.count >= 11 else { return nil } // 最小長度檢查（增加1個字節）
        
        var offset = 0
        
        // 1. 協議版本
        let version = data[offset]
        guard version == 1 else { return nil }
        offset += 1
        
        // 2. MeshMessage 類型 - 必須是 0x06 (game)
        let meshType = data[offset]
        guard meshType == 0x06 else { return nil }
        offset += 1
        
        // 3. 遊戲訊息子類型
        guard let binaryType = GameMessageTypeBinary(rawValue: data[offset]) else { return nil }
        let type = binaryToGameMessageType(binaryType)
        offset += 1
        
        // 4. 時間戳
        let timestamp = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        
        // 5. 發送者ID
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 6. 發送者名稱
        guard offset < data.count else { return nil }
        let senderNameLength = Int(data[offset])
        offset += 1
        
        guard offset + senderNameLength <= data.count else { return nil }
        let senderName = String(data: data.subdata(in: offset..<offset+senderNameLength), encoding: .utf8) ?? ""
        offset += senderNameLength
        
        // 7. 遊戲房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        guard offset + roomIDLength <= data.count else { return nil }
        let gameRoomID = String(data: data.subdata(in: offset..<offset+roomIDLength), encoding: .utf8) ?? ""
        offset += roomIDLength
        
        // 8. 數據
        guard offset + 2 <= data.count else { return nil }
        let dataLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(dataLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<offset+Int(dataLength))
        
        return GameMessage(
            type: type,
            senderID: senderID,
            senderName: NicknameFormatter.cleanNickname(senderName), // 使用統一的暱稱清理邏輯
            data: messageData,
            timestamp: Date(timeIntervalSince1970: Double(timestamp)),
            gameRoomID: gameRoomID
        )
    }
    
    // MARK: - 特定訊息類型編碼
    
    /// 編碼玩家加入訊息
    static func encodePlayerJoined(playerID: String, playerName: String) -> Data {
        return "\(playerID)|\(playerName)".data(using: .utf8) ?? Data()
    }
    
    /// 編碼房間同步狀態
    static func encodeRoomState(_ state: GameRoomState) -> Data {
        var data = Data()
        
        // 房間ID
        let roomIDData = state.roomID.data(using: .utf8) ?? Data()
        let safeRoomIDLength = min(roomIDData.count, 255)
        data.append(UInt8(safeRoomIDLength))
        data.append(roomIDData.prefix(safeRoomIDLength))
        
        // 主機ID
        let hostIDData = state.hostID.data(using: .utf8) ?? Data()
        let safeHostIDLength = min(hostIDData.count, 255)
        data.append(UInt8(safeHostIDLength))
        data.append(hostIDData.prefix(safeHostIDLength))
        
        // 遊戲狀態
        data.append(gameStateToBinary(state.gameState))
        
        // 玩家數量
        let safePlayerCount = min(state.players.count, 255)
        data.append(UInt8(safePlayerCount))
        
        // 每個玩家資訊
        for player in state.players {
            // 玩家ID
            let playerIDData = player.id.data(using: .utf8) ?? Data()
            let safePlayerIDLength = min(playerIDData.count, 255)
            data.append(UInt8(safePlayerIDLength))
            data.append(playerIDData.prefix(safePlayerIDLength))
            
            // 玩家名稱 (使用清理後的暱稱)
            let cleanName = NicknameFormatter.cleanNickname(player.name)
            let playerNameData = cleanName.data(using: .utf8) ?? Data()
            let safePlayerNameLength = min(playerNameData.count, 255)
            data.append(UInt8(safePlayerNameLength))
            data.append(playerNameData.prefix(safePlayerNameLength))
            
            // 完成線數
            let safeCompletedLines = max(0, min(player.completedLines, 255))
            data.append(UInt8(safeCompletedLines))
            
            // 是否獲勝
            data.append(player.hasWon ? 1 : 0)
            
            // 是否連線
            data.append(player.isConnected ? 1 : 0)
        }
        
        // 已抽數字數量
        let safeDrawnCount = min(state.drawnNumbers.count, 255)
        data.append(UInt8(safeDrawnCount))
        for number in state.drawnNumbers {
            let safeNumber = min(max(number, 1), 255)
            data.append(UInt8(safeNumber))
        }
        
        // 當前數字
        if let currentNumber = state.currentNumber {
            data.append(1) // 有當前數字
            let safeCurrentNumber = min(max(currentNumber, 1), 255)
            data.append(UInt8(safeCurrentNumber))
        } else {
            data.append(0) // 無當前數字
        }
        
        // 倒數計時
        let safeCountdown = max(0, min(state.countdown, 255))
        data.append(UInt8(safeCountdown))
        
        return data
    }
    
    /// 解碼房間同步狀態
    static func decodeRoomState(_ data: Data) -> GameRoomState? {
        guard data.count >= 5 else { return nil }
        
        var offset = 0
        
        // 房間ID
        let roomIDLength = Int(data[offset])
        offset += 1
        guard offset + roomIDLength <= data.count else { return nil }
        let roomID = String(data: data.subdata(in: offset..<offset+roomIDLength), encoding: .utf8) ?? ""
        offset += roomIDLength
        
        // 主機ID
        guard offset < data.count else { return nil }
        let hostIDLength = Int(data[offset])
        offset += 1
        guard offset + hostIDLength <= data.count else { return nil }
        let hostID = String(data: data.subdata(in: offset..<offset+hostIDLength), encoding: .utf8) ?? ""
        offset += hostIDLength
        
        // 遊戲狀態
        guard offset < data.count else { return nil }
        let gameState = binaryToGameState(data[offset])
        offset += 1
        
        // 玩家數量
        guard offset < data.count else { return nil }
        let playerCount = Int(data[offset])
        offset += 1
        
        // 解析玩家
        var players: [PlayerState] = []
        for _ in 0..<playerCount {
            // 玩家ID
            guard offset < data.count else { return nil }
            let playerIDLength = Int(data[offset])
            offset += 1
            guard offset + playerIDLength <= data.count else { return nil }
            let playerID = String(data: data.subdata(in: offset..<offset+playerIDLength), encoding: .utf8) ?? ""
            offset += playerIDLength
            
            // 玩家名稱
            guard offset < data.count else { return nil }
            let playerNameLength = Int(data[offset])
            offset += 1
            guard offset + playerNameLength <= data.count else { return nil }
            let playerName = String(data: data.subdata(in: offset..<offset+playerNameLength), encoding: .utf8) ?? ""
            offset += playerNameLength
            
            // 完成線數
            guard offset < data.count else { return nil }
            let completedLines = Int(data[offset])
            offset += 1
            
            // 是否獲勝
            guard offset < data.count else { return nil }
            let hasWon = data[offset] == 1
            offset += 1
            
            // 是否連線
            guard offset < data.count else { return nil }
            let isConnected = data[offset] == 1
            offset += 1
            
            players.append(PlayerState(
                id: playerID,
                name: NicknameFormatter.cleanNickname(playerName), // 使用統一的暱稱清理邏輯
                completedLines: completedLines,
                hasWon: hasWon,
                isConnected: isConnected
            ))
        }
        
        // 已抽數字
        guard offset < data.count else { return nil }
        let drawnCount = Int(data[offset])
        offset += 1
        
        var drawnNumbers: [Int] = []
        for _ in 0..<drawnCount {
            guard offset < data.count else { return nil }
            drawnNumbers.append(Int(data[offset]))
            offset += 1
        }
        
        // 當前數字
        guard offset < data.count else { return nil }
        let hasCurrentNumber = data[offset] == 1
        offset += 1
        
        var currentNumber: Int?
        if hasCurrentNumber {
            guard offset < data.count else { return nil }
            currentNumber = Int(data[offset])
            offset += 1
        }
        
        // 倒數計時
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
    
    // MARK: - 輔助方法
    
    private static func gameMessageTypeToBinary(_ type: GameMessageType) -> GameMessageTypeBinary {
        switch type {
        case .playerJoined: return .playerJoined
        case .playerLeft: return .playerLeft
        case .roomSync: return .roomSync
        case .reconnectRequest: return .reconnectRequest
        case .gameStateUpdate: return .gameStateUpdate
        case .numberDrawn: return .numberDrawn
        case .playerProgress: return .playerProgress
        case .chatMessage: return .chatMessage
        case .gameStart: return .gameStart
        case .gameEnd: return .gameEnd
        case .heartbeat: return .heartbeat
        case .emote: return .emote
        }
    }
    
    private static func binaryToGameMessageType(_ binary: GameMessageTypeBinary) -> GameMessageType {
        switch binary {
        case .playerJoined: return .playerJoined
        case .playerLeft: return .playerLeft
        case .roomSync: return .roomSync
        case .reconnectRequest: return .reconnectRequest
        case .gameStateUpdate: return .gameStateUpdate
        case .numberDrawn: return .numberDrawn
        case .playerProgress: return .playerProgress
        case .chatMessage: return .chatMessage
        case .gameStart: return .gameStart
        case .gameEnd: return .gameEnd
        case .heartbeat: return .heartbeat
        case .emote: return .emote
        }
    }
    
    private static func gameStateToBinary(_ state: GameRoomState.GameState) -> UInt8 {
        switch state {
        case .waitingForPlayers: return 0
        case .countdown: return 1
        case .playing: return 2
        case .finished: return 3
        }
    }
    
    private static func binaryToGameState(_ value: UInt8) -> GameRoomState.GameState {
        switch value {
        case 0: return .waitingForPlayers
        case 1: return .countdown
        case 2: return .playing
        case 3: return .finished
        default: return .waitingForPlayers
        }
    }
}