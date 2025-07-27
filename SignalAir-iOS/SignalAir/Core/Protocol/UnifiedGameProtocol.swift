import Foundation

// MARK: - 統一遊戲協議
// 🔧 修復：統一使用BinaryMessageEncoder格式，解決遊戲消息編碼不一致問題

struct UnifiedGameProtocol {
    
    // MARK: - 遊戲消息編碼
    /// 編碼遊戲消息為標準MeshMessage格式
    static func encodeGameMessage(
        type: GameMessageType,
        data: Data
    ) -> Data? {
        do {
            // 🔧 FIX: 使用標準MeshMessage包裝遊戲數據
            let meshMessage = MeshMessage(
                id: UUID().uuidString,
                type: .game,  // 使用統一的.game類型
                data: encodeGameDataWithType(type: type, data: data)
            )
            
            // 使用標準BinaryMessageEncoder編碼
            return try BinaryMessageEncoder.encode(meshMessage)
            
        } catch {
            print("❌ UnifiedGameProtocol: 編碼失敗 - \(error)")
            return nil
        }
    }
    
    /// 編碼遊戲內部數據格式
    private static func encodeGameDataWithType(type: GameMessageType, data: Data) -> Data {
        var binaryData = Data()
        
        // 1. 遊戲消息子類型 (1 byte)
        binaryData.append(type.rawValue)
        
        // 2. 時間戳 (4 bytes)
        let timestamp = UInt32(Date().timeIntervalSince1970)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        // 3. 數據長度 (2 bytes)
        let dataLength = UInt16(data.count)
        binaryData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian, Array.init))
        
        // 4. 實際數據
        binaryData.append(data)
        
        return binaryData
    }
    
    // MARK: - 遊戲消息解碼
    /// 解碼遊戲消息從標準MeshMessage格式
    static func decodeGameMessage(_ data: Data) -> (type: GameMessageType, data: Data, timestamp: Date)? {
        do {
            // 🔧 FIX: 使用標準BinaryMessageDecoder解碼
            let meshMessage = try BinaryMessageDecoder.decode(data)
            
            // 檢查是否為遊戲消息
            guard meshMessage.type == .game else {
                print("❌ UnifiedGameProtocol: 不是遊戲消息類型，實際: \(meshMessage.type)")
                return nil
            }
            
            // 解碼遊戲內部數據
            return decodeGameDataWithType(meshMessage.data)
            
        } catch {
            print("❌ UnifiedGameProtocol: 解碼失敗 - \(error)")
            return nil
        }
    }
    
    /// 解碼遊戲內部數據格式
    private static func decodeGameDataWithType(_ data: Data) -> (type: GameMessageType, data: Data, timestamp: Date)? {
        guard data.count >= 7 else { // 最小長度：1 + 4 + 2 = 7
            print("❌ UnifiedGameProtocol: 遊戲數據太短 - \(data.count) bytes")
            return nil
        }
        
        var offset = 0
        
        // 1. 遊戲消息子類型
        guard let gameType = GameMessageType(rawValue: data[offset]) else {
            print("❌ UnifiedGameProtocol: 無效的遊戲消息類型 - \(data[offset])")
            return nil
        }
        offset += 1
        
        // 2. 時間戳
        let timestamp = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let messageDate = Date(timeIntervalSince1970: Double(timestamp))
        offset += 4
        
        // 3. 數據長度
        let dataLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 4. 驗證數據長度
        guard offset + Int(dataLength) <= data.count else {
            print("❌ UnifiedGameProtocol: 數據長度不符 - 期望: \(dataLength), 可用: \(data.count - offset)")
            return nil
        }
        
        // 5. 提取實際數據
        let gameData = data.subdata(in: offset..<offset+Int(dataLength))
        
        print("✅ UnifiedGameProtocol: 成功解碼遊戲消息 - 類型: \(gameType.stringValue), 數據: \(gameData.count) bytes")
        return (gameType, gameData, messageDate)
    }
    
    // MARK: - 便利方法
    
    /// 編碼簡單文本遊戲消息
    static func encodeTextGameMessage(type: GameMessageType, text: String) -> Data? {
        let textData = text.data(using: .utf8) ?? Data()
        return encodeGameMessage(type: type, data: textData)
    }
    
    /// 編碼玩家加入消息
    static func encodePlayerJoined(playerID: String, playerName: String) -> Data? {
        let messageText = "\(playerID)|\(playerName)"
        return encodeTextGameMessage(type: .playerJoined, text: messageText)
    }
    
    /// 編碼房間同步消息
    static func encodeRoomSync(roomState: Data) -> Data? {
        return encodeGameMessage(type: .roomSync, data: roomState)
    }
    
    /// 編碼重連請求
    static func encodeReconnectRequest(playerID: String, playerName: String) -> Data? {
        let messageText = "\(playerID)|\(playerName)"
        return encodeTextGameMessage(type: .reconnectRequest, text: messageText)
    }
    
    /// 編碼表情消息
    static func encodeEmote(emoteType: String, fromPlayer: String, playerID: String) -> Data? {
        let messageText = "\(emoteType)|\(playerID)|\(fromPlayer)"
        return encodeTextGameMessage(type: .emote, text: messageText)
    }
    
    /// 編碼號碼抽取消息
    static func encodeNumberDrawn(number: Int) -> Data? {
        return encodeTextGameMessage(type: .numberDrawn, text: String(number))
    }
    
    // MARK: - 調試工具
    
    /// 分析失敗的遊戲數據
    static func analyzeFailedGameData(_ data: Data) -> String {
        guard data.count >= 2 else {
            return "❌ 數據太短 (\(data.count) bytes) - 至少需要2字節"
        }
        
        let hex = data.prefix(min(20, data.count)).map { String(format: "%02X", $0) }.joined(separator: " ")
        var analysis = "🔍 遊戲數據分析 (前\(min(20, data.count))字節): \(hex)\n"
        
        let protocolVersion = data[0]
        let messageType = data[1]
        
        analysis += "📊 基本信息:\n"
        analysis += "   總大小: \(data.count) bytes\n"
        analysis += "   協議版本: \(protocolVersion)\n"
        analysis += "   訊息類型: \(messageType)\n"
        
        // 檢查是否為標準MeshMessage格式
        if protocolVersion == 1 && messageType == MeshMessageType.game.rawValue {
            analysis += "✅ 標準MeshMessage.game格式\n"
            
            // 分析遊戲子類型
            if data.count >= 10 { // 足夠解析到遊戲子類型
                // 跳過ID長度和ID內容來找到遊戲數據
                var offset = 2
                if offset < data.count {
                    let idLength = Int(data[offset])
                    offset += 1 + idLength + 4 + 4 // ID長度 + ID + 數據長度 + 時間戳
                    
                    if offset < data.count {
                        let gameSubType = data[offset]
                        if let gameType = GameMessageType(rawValue: gameSubType) {
                            analysis += "✅ 遊戲子類型: \(gameType.stringValue) (0x\(String(format: "%02X", gameSubType)))\n"
                        } else {
                            analysis += "❌ 無效遊戲子類型: 0x\(String(format: "%02X", gameSubType))\n"
                        }
                    }
                }
            }
        } else {
            analysis += "❌ 非標準MeshMessage格式\n"
        }
        
        return analysis
    }
    
    /// 檢查是否為有效的遊戲消息
    static func isValidGameMessage(_ data: Data) -> Bool {
        guard data.count >= 2 else { return false }
        
        // 檢查是否為標準MeshMessage格式
        let protocolVersion = data[0]
        let messageType = data[1]
        
        return protocolVersion == 1 && messageType == MeshMessageType.game.rawValue
    }
}

// MARK: - 調試擴展
extension Data {
    func hexString() -> String {
        return map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    func debugPrint(label: String) {
        print("\(label):")
        print("  Size: \(count) bytes")
        print("  Hex: \(prefix(20).hexString())")
        if let string = String(data: self, encoding: .utf8) {
            print("  UTF8: \(string.prefix(50))")
        }
    }
}