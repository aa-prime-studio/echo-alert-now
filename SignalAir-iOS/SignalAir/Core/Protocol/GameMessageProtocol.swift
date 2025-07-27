import Foundation

// MARK: - 遊戲訊息類型
enum GameMessageType: String, CaseIterable {
    case reconnectRequest = "reconnect_request"
    case reconnectResponse = "reconnect_response"
    case roomSync = "room_sync"
    case playerJoin = "player_join"
    case playerLeave = "player_leave"
    case gameStart = "game_start"
    case numberDraw = "number_draw"
    case gameRestart = "game_restart"
    case emote = "emote"
    case hostPromotion = "host_promotion"
    case gameState = "game_state"
    case heartbeat = "heartbeat"
}

// MARK: - 統一的遊戲訊息格式
/// 統一的二進制編碼/解碼協議，解決格式不一致問題
struct GameMessageProtocol {
    
    // MARK: - 編碼
    /// 編碼遊戲訊息為二進制格式
    static func encode(type: GameMessageType, data: [String: Any]) -> Data {
        var result = Data()
        
        // 1. 協議版本 (1 byte)
        let protocolVersion: UInt8 = 1
        result.append(protocolVersion)
        
        // 2. 訊息類型
        let typeString = type.rawValue
        result.append(UInt8(min(typeString.count, 255)))
        if let typeData = typeString.data(using: .utf8) {
            result.append(typeData)
        }
        
        // 3. 數據項數量
        result.append(UInt8(min(data.count, 255)))
        
        // 4. 每個數據項
        for (key, value) in data {
            // Key長度和內容
            let keyData = key.data(using: .utf8) ?? Data()
            result.append(UInt8(min(keyData.count, 255)))
            result.append(keyData)
            
            // Value類型和內容
            if let stringValue = value as? String {
                // 字符串類型 (0x00)
                result.append(0x00)
                let valueData = stringValue.data(using: .utf8) ?? Data()
                let length = UInt16(min(valueData.count, 65535))
                result.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Array($0) })
                result.append(valueData)
                
            } else if let intValue = value as? Int {
                // 整數類型 (0x01)
                result.append(0x01)
                let int32Value = Int32(intValue)
                result.append(contentsOf: withUnsafeBytes(of: int32Value.littleEndian) { Array($0) })
                
            } else if let boolValue = value as? Bool {
                // 布爾類型 (0x02)
                result.append(0x02)
                result.append(boolValue ? 0x01 : 0x00)
                
            } else if let arrayValue = value as? [String] {
                // 字符串數組類型 (0x03)
                result.append(0x03)
                result.append(UInt8(min(arrayValue.count, 255)))
                for item in arrayValue.prefix(255) {
                    let itemData = item.data(using: .utf8) ?? Data()
                    result.append(UInt8(min(itemData.count, 255)))
                    result.append(itemData)
                }
                
            } else if let dictValue = value as? [String: Any] {
                // 嵌套字典類型 (0x04) - 遞歸編碼
                result.append(0x04)
                let nestedData = encode(type: type, data: dictValue)
                let length = UInt16(min(nestedData.count, 65535))
                result.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Array($0) })
                result.append(nestedData)
                
            } else {
                // 未知類型，跳過
                print("⚠️ GameMessageProtocol: 跳過未知類型的值 - key: \(key)")
                continue
            }
        }
        
        return result
    }
    
    // MARK: - 解碼
    /// 解碼二進制數據為遊戲訊息
    static func decode(_ data: Data) -> (type: GameMessageType, data: [String: Any])? {
        var offset = 0
        
        // 1. 檢查協議版本
        guard offset < data.count else { return nil }
        let protocolVersion = data[offset]
        guard protocolVersion == 1 else {
            print("❌ GameMessageProtocol: 不支援的協議版本: \(protocolVersion)")
            return nil
        }
        offset += 1
        
        // 2. 讀取訊息類型
        guard offset < data.count else { return nil }
        let typeLength = Int(data[offset])
        offset += 1
        
        guard offset + typeLength <= data.count else { return nil }
        guard let typeString = String(data: data[offset..<offset+typeLength], encoding: .utf8),
              let messageType = GameMessageType(rawValue: typeString) else {
            print("❌ GameMessageProtocol: 無效的訊息類型")
            return nil
        }
        offset += typeLength
        
        // 3. 讀取數據項數量
        guard offset < data.count else { return nil }
        let itemCount = Int(data[offset])
        offset += 1
        
        // 4. 讀取每個數據項
        var result: [String: Any] = [:]
        
        for _ in 0..<itemCount {
            // 讀取 key
            guard offset < data.count else { return nil }
            let keyLength = Int(data[offset])
            offset += 1
            
            guard offset + keyLength <= data.count else { return nil }
            guard let key = String(data: data[offset..<offset+keyLength], encoding: .utf8) else {
                print("❌ GameMessageProtocol: 無效的 key")
                return nil
            }
            offset += keyLength
            
            // 讀取 value 類型
            guard offset < data.count else { return nil }
            let valueType = data[offset]
            offset += 1
            
            // 根據類型讀取 value
            switch valueType {
            case 0x00: // 字符串
                guard offset + 2 <= data.count else { return nil }
                let valueLength = data[offset..<offset+2].withUnsafeBytes {
                    $0.load(as: UInt16.self).littleEndian
                }
                offset += 2
                
                guard offset + Int(valueLength) <= data.count else { return nil }
                if let value = String(data: data[offset..<offset+Int(valueLength)], encoding: .utf8) {
                    result[key] = value
                }
                offset += Int(valueLength)
                
            case 0x01: // 整數
                guard offset + 4 <= data.count else { return nil }
                let value = data[offset..<offset+4].withUnsafeBytes {
                    $0.load(as: Int32.self).littleEndian
                }
                result[key] = Int(value)
                offset += 4
                
            case 0x02: // 布爾
                guard offset < data.count else { return nil }
                result[key] = data[offset] != 0x00
                offset += 1
                
            case 0x03: // 字符串數組
                guard offset < data.count else { return nil }
                let arrayCount = Int(data[offset])
                offset += 1
                
                var array: [String] = []
                for _ in 0..<arrayCount {
                    guard offset < data.count else { return nil }
                    let itemLength = Int(data[offset])
                    offset += 1
                    
                    guard offset + itemLength <= data.count else { return nil }
                    if let item = String(data: data[offset..<offset+itemLength], encoding: .utf8) {
                        array.append(item)
                    }
                    offset += itemLength
                }
                result[key] = array
                
            case 0x04: // 嵌套字典
                guard offset + 2 <= data.count else { return nil }
                let nestedLength = data[offset..<offset+2].withUnsafeBytes {
                    $0.load(as: UInt16.self).littleEndian
                }
                offset += 2
                
                guard offset + Int(nestedLength) <= data.count else { return nil }
                let nestedData = data[offset..<offset+Int(nestedLength)]
                if let (_, nestedDict) = decode(nestedData) {
                    result[key] = nestedDict
                }
                offset += Int(nestedLength)
                
            default:
                print("⚠️ GameMessageProtocol: 未知的值類型: \(valueType)")
                return nil
            }
        }
        
        print("✅ GameMessageProtocol: 成功解碼 \(messageType.rawValue) 訊息")
        return (messageType, result)
    }
    
    // MARK: - 便利方法
    
    /// 編碼簡單的重連請求
    static func encodeReconnectRequest(playerID: String, playerName: String, roomID: String) -> Data {
        return encode(type: .reconnectRequest, data: [
            "playerID": playerID,
            "playerName": playerName,
            "roomID": roomID,
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
    
    /// 編碼房間同步訊息
    static func encodeRoomSync(roomState: [String: Any]) -> Data {
        return encode(type: .roomSync, data: roomState)
    }
    
    /// 編碼表情訊息
    static func encodeEmote(emoteType: String, fromPlayer: String) -> Data {
        return encode(type: .emote, data: [
            "emoteType": emoteType,
            "fromPlayer": fromPlayer,
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
    
    /// 編碼遊戲開始訊息
    static func encodeGameStart(hostID: String, gameSettings: [String: Any]) -> Data {
        return encode(type: .gameStart, data: [
            "hostID": hostID,
            "settings": gameSettings,
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
    
    /// 編碼號碼抽取訊息
    static func encodeNumberDraw(number: Int, drawnNumbers: [Int]) -> Data {
        return encode(type: .numberDraw, data: [
            "number": number,
            "drawnNumbers": drawnNumbers.map { String($0) },
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
    
    // MARK: - 向後相容性支援
    
    /// 嘗試解析舊格式的字符串訊息
    static func decodeLegacyStringFormat(_ data: Data) -> (type: GameMessageType, data: [String: Any])? {
        guard let stringData = String(data: data, encoding: .utf8) else { return nil }
        
        print("🔄 GameMessageProtocol: 嘗試解析舊格式字符串: \(stringData)")
        
        let components = stringData.components(separatedBy: "|")
        guard components.count >= 2 else { return nil }
        
        // 根據內容猜測訊息類型
        if components.count == 2 {
            // playerID|playerName 格式 - 可能是重連請求
            return (.reconnectRequest, [
                "playerID": components[0],
                "playerName": components[1]
            ])
        } else if components.count >= 3 {
            // 可能包含更多資訊
            var data: [String: Any] = [
                "playerID": components[0],
                "playerName": components[1]
            ]
            
            // 如果有第三個參數，可能是房間ID或其他資訊
            if components.count > 2 {
                data["roomID"] = components[2]
            }
            
            return (.roomSync, data)
        }
        
        return nil
    }
    
    /// 智能解碼 - 自動判斷格式
    static func smartDecode(_ data: Data) -> (type: GameMessageType, data: [String: Any])? {
        // 首先嘗試新的二進制格式
        if let result = decode(data) {
            return result
        }
        
        // 如果失敗，嘗試舊的字符串格式
        print("⚠️ GameMessageProtocol: 二進制解碼失敗，嘗試舊格式")
        return decodeLegacyStringFormat(data)
    }
}

// MARK: - 擴展：便利的訊息建構器
extension GameMessageProtocol {
    
    struct MessageBuilder {
        private var type: GameMessageType
        private var data: [String: Any] = [:]
        
        init(type: GameMessageType) {
            self.type = type
        }
        
        func with(_ key: String, _ value: Any) -> MessageBuilder {
            var newBuilder = self
            newBuilder.data[key] = value
            return newBuilder
        }
        
        func build() -> Data {
            return GameMessageProtocol.encode(type: type, data: data)
        }
    }
    
    static func builder(type: GameMessageType) -> MessageBuilder {
        return MessageBuilder(type: type)
    }
}

// MARK: - 錯誤定義
enum GameMessageError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case unsupportedFormat
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "遊戲訊息編碼失敗"
        case .decodingFailed:
            return "遊戲訊息解碼失敗"
        case .unsupportedFormat:
            return "不支援的訊息格式"
        case .invalidData:
            return "無效的訊息數據"
        }
    }
}