import Foundation
import MultipeerConnectivity

// 測試消息路由修復 - 驗證 playerJoined 消息能正確流轉
class MessageRoutingTest {
    
    static func testPlayerJoinedMessageFlow() {
        print("🧪 ===== 開始測試 playerJoined 消息流轉 =====")
        
        // 1. 創建測試用的 playerJoined 消息
        let testPlayerInfo = PlayerInfo(
            playerID: "test-player-123",
            playerName: "測試玩家",
            isHost: false,
            bingoCard: Array(1...25), // 簡單的1-25號碼
            deviceName: "Test Device"
        )
        
        do {
            // 2. 使用二進制協議編碼 playerJoined 消息
            let playerJoinedData = try BinaryGameProtocol.encodePlayerJoined(testPlayerInfo)
            print("✅ 成功編碼 playerJoined 數據: \(playerJoinedData.count) bytes")
            print("   數據內容: \(playerJoinedData.map { String(format: "%02x", $0) }.joined(separator: " "))")
            
            // 3. 創建完整的遊戲消息
            let gameMessage = createTestGameMessage(
                type: .playerJoined,
                data: playerJoinedData,
                senderID: "test-sender-456",
                senderName: "測試發送者"
            )
            
            // 4. 編碼為二進制格式
            let binaryData = try BinaryMessageEncoder.encode(gameMessage)
            print("✅ 成功編碼完整遊戲消息: \(binaryData.count) bytes")
            
            // 5. 測試解碼流程
            testDecodeFlow(binaryData: binaryData)
            
            // 6. 測試 BingoNetworkManager 解碼
            testBingoNetworkManagerDecoding(binaryData: binaryData)
            
        } catch {
            print("❌ 測試失敗: \(error)")
        }
        
        print("🧪 ===== 測試完成 =====")
    }
    
    private static func createTestGameMessage(type: GameMessageType, data: Data, senderID: String, senderName: String) -> MeshMessage {
        // 創建遊戲消息數據包
        var gameData = Data()
        
        // 添加遊戲消息類型
        gameData.append(type.rawValue)
        
        // 添加房間ID（空）
        gameData.append(UInt8(0))
        
        // 添加發送者名稱
        let senderNameData = senderName.data(using: .utf8) ?? Data()
        let safeSenderNameLength = min(senderNameData.count, 255)
        gameData.append(UInt8(safeSenderNameLength))
        gameData.append(senderNameData.prefix(safeSenderNameLength))
        
        // 添加實際數據
        let dataLength = UInt16(data.count)
        gameData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        gameData.append(data)
        
        return MeshMessage(
            type: .game,
            sourceID: senderID,
            targetID: nil,
            data: gameData,
            ttl: 5
        )
    }
    
    private static func testDecodeFlow(binaryData: Data) {
        print("\n🔍 測試解碼流程...")
        
        do {
            // 1. 測試 BinaryMessageDecoder 解碼
            let decodedMessage = try BinaryMessageDecoder.decode(binaryData)
            print("✅ BinaryMessageDecoder 解碼成功")
            print("   消息類型: \(decodedMessage.type.stringValue)")
            print("   發送者ID: \(decodedMessage.sourceID ?? "無")")
            print("   數據大小: \(decodedMessage.data.count) bytes")
            
            // 2. 驗證是否為遊戲消息
            if decodedMessage.type == .game {
                print("✅ 確認為遊戲消息")
                testGameMessageDecoding(decodedMessage.data, sourceID: decodedMessage.sourceID ?? "unknown")
            } else {
                print("❌ 不是遊戲消息類型")
            }
            
        } catch {
            print("❌ 解碼失敗: \(error)")
        }
    }
    
    private static func testGameMessageDecoding(_ data: Data, sourceID: String) {
        print("\n🎮 測試遊戲消息解碼...")
        
        guard data.count >= 3 else {
            print("❌ 遊戲消息數據太短")
            return
        }
        
        var offset = 0
        
        // 讀取遊戲消息類型
        let rawValue = data[offset]
        print("🔍 遊戲消息原始值: 0x\(String(rawValue, radix: 16)) (\(rawValue))")
        
        guard let gameType = GameMessageType(rawValue: rawValue) else {
            print("❌ 無法識別的遊戲消息類型")
            return
        }
        
        print("✅ 遊戲消息類型: \(gameType.stringValue)")
        offset += 1
        
        // 讀取房間ID長度和內容
        let roomIDLength = Int(data[offset])
        offset += 1
        
        let roomID: String
        if roomIDLength > 0 && offset + roomIDLength <= data.count {
            let roomIDData = data.subdata(in: offset..<(offset + roomIDLength))
            roomID = String(data: roomIDData, encoding: .utf8) ?? ""
            offset += roomIDLength
        } else {
            roomID = ""
        }
        
        // 讀取發送者名稱長度和內容
        guard offset < data.count else {
            print("❌ 數據不完整：無發送者名稱長度")
            return
        }
        
        let senderNameLength = Int(data[offset])
        offset += 1
        
        let senderName: String
        if senderNameLength > 0 && offset + senderNameLength <= data.count {
            let senderNameData = data.subdata(in: offset..<(offset + senderNameLength))
            senderName = String(data: senderNameData, encoding: .utf8) ?? sourceID
            offset += senderNameLength
        } else {
            senderName = sourceID
        }
        
        // 讀取實際數據長度
        guard offset + 2 <= data.count else {
            print("❌ 數據不完整：無數據長度字段")
            return
        }
        
        let dataLength = data.subdata(in: offset..<(offset + 2)).withUnsafeBytes { 
            $0.load(as: UInt16.self).littleEndian 
        }
        offset += 2
        
        // 讀取實際數據
        guard offset + Int(dataLength) <= data.count else {
            print("❌ 數據不完整：實際數據不足")
            return
        }
        
        let messageData = data.subdata(in: offset..<(offset + Int(dataLength)))
        
        print("✅ 成功解析遊戲消息:")
        print("   類型: \(gameType.stringValue)")
        print("   房間ID: '\(roomID)'")
        print("   發送者: '\(senderName)'")
        print("   數據大小: \(messageData.count) bytes")
        
        // 如果是 playerJoined，進一步解碼
        if gameType == .playerJoined {
            testPlayerJoinedDecoding(messageData)
        }
    }
    
    private static func testPlayerJoinedDecoding(_ data: Data) {
        print("\n👤 測試 playerJoined 具體解碼...")
        
        do {
            let playerInfo = try BinaryGameProtocol.decodePlayerJoined(from: data)
            print("✅ 成功解碼 playerJoined:")
            print("   玩家ID: \(playerInfo.playerID)")
            print("   玩家名稱: \(playerInfo.playerName)")
            print("   是否主機: \(playerInfo.isHost)")
            print("   賓果卡數量: \(playerInfo.bingoCard.count)")
            print("   設備名稱: \(playerInfo.deviceName)")
        } catch {
            print("❌ playerJoined 解碼失敗: \(error)")
        }
    }
    
    private static func testBingoNetworkManagerDecoding(binaryData: Data) {
        print("\n🌐 測試 BingoNetworkManager 消息解碼...")
        
        // 模擬 MeshMessage
        do {
            let meshMessage = try BinaryMessageDecoder.decode(binaryData)
            
            // 模擬 BingoNetworkManager.decodeGameMessage
            let testGameMessage = simulateBingoNetworkManagerDecoding(meshMessage)
            
            if let gameMessage = testGameMessage {
                print("✅ BingoNetworkManager 解碼成功:")
                print("   消息ID: \(gameMessage.id)")
                print("   消息類型: \(gameMessage.type.stringValue)")
                print("   發送者ID: \(gameMessage.senderID)")
                print("   發送者名稱: \(gameMessage.senderName)")
                print("   房間ID: \(gameMessage.roomID)")
                print("   時間戳: \(gameMessage.timestamp)")
            } else {
                print("❌ BingoNetworkManager 解碼失敗")
            }
            
        } catch {
            print("❌ 模擬測試失敗: \(error)")
        }
    }
    
    private static func simulateBingoNetworkManagerDecoding(_ meshMessage: MeshMessage) -> GameMessage? {
        guard meshMessage.type == .game else { return nil }
        
        let data = meshMessage.data
        guard data.count >= 3 else { return nil }
        
        var offset = 0
        
        // 讀取遊戲消息類型
        let rawValue = data[offset]
        guard let gameType = GameMessageType(rawValue: rawValue) else { return nil }
        offset += 1
        
        // 讀取房間ID
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        let roomID: String
        if roomIDLength > 0 && offset + roomIDLength <= data.count {
            let roomIDData = data.subdata(in: offset..<(offset + roomIDLength))
            roomID = String(data: roomIDData, encoding: .utf8) ?? ""
            offset += roomIDLength
        } else {
            roomID = ""
        }
        
        // 讀取發送者名稱
        guard offset < data.count else { return nil }
        let senderNameLength = Int(data[offset])
        offset += 1
        
        let senderName: String
        if senderNameLength > 0 && offset + senderNameLength <= data.count {
            let senderNameData = data.subdata(in: offset..<(offset + senderNameLength))
            senderName = String(data: senderNameData, encoding: .utf8) ?? meshMessage.sourceID ?? "unknown"
            offset += senderNameLength
        } else {
            senderName = meshMessage.sourceID ?? "unknown"
        }
        
        // 讀取實際數據
        guard offset + 2 <= data.count else { return nil }
        let dataLength = data.subdata(in: offset..<(offset + 2)).withUnsafeBytes { 
            $0.load(as: UInt16.self).littleEndian 
        }
        offset += 2
        
        guard offset + Int(dataLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<(offset + Int(dataLength)))
        
        return GameMessage(
            id: UUID().uuidString,
            type: gameType,
            data: messageData,
            senderID: meshMessage.sourceID ?? "unknown",
            senderName: senderName,
            roomID: roomID,
            timestamp: Date()
        )
    }
}