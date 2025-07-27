import Foundation

// MARK: - 純二進制訊息解碼器
// 專為30萬用戶大規模網狀網路優化

public class BinaryMessageDecoder {
    
    // MARK: - 協議版本和常數
    private static let PROTOCOL_VERSION: UInt8 = 1
    private static let MIN_HEADER_SIZE = 10 // 最小頭部大小
    
    // MARK: - 訊息類型映射 (與編碼器保持一致)
    // 使用統一的 MeshMessageType，不再重複定義
    // private enum BinaryMessageType: UInt8 已移除，改用 MeshMessageType
    
    // MARK: - MeshMessage解碼 (核心功能，替換JSON)
    static func decode(_ data: Data) throws -> MeshMessage {
        return try decodeCurrentFormat(data)
    }
    
    
    // MARK: - 當前版本格式解碼器
    private static func decodeCurrentFormat(_ data: Data) throws -> MeshMessage {
        var offset = 0
        
        // 驗證協議版本 (1 byte)
        let version = data[offset]
        guard version == PROTOCOL_VERSION else {
            throw BinaryDecodingError.unsupportedVersion
        }
        offset += 1
        
        // 解析訊息類型 (1 byte) - 直接使用 MeshMessageType
        guard let messageType = MeshMessageType(rawValue: data[offset]) else {
            throw BinaryDecodingError.invalidMessageType
        }
        offset += 1
        
        // 🔧 FIX: 統一UUID解析處理
        guard offset < data.count else {
            print("❌ BinaryMessageDecoder: 數據在訊息ID長度位置太短，offset: \(offset), 總長度: \(data.count)")
            throw BinaryDecodingError.invalidDataSize
        }
        
        let idLength = Int(data[offset])
        offset += 1
        
        // 驗證ID長度合理性，防止記憶體耗盡攻擊
        guard idLength > 0 && idLength <= 64 else {
            print("🚨 SECURITY: 訊息ID長度異常: \(idLength)")
            throw BinaryDecodingError.invalidDataSize
        }
        
        guard offset + idLength <= data.count else {
            print("❌ BinaryMessageDecoder: 訊息ID數據不足 - 需要: \(idLength), 可用: \(data.count - offset)")
            throw BinaryDecodingError.invalidDataSize
        }
        
        let idData = data.subdata(in: offset..<offset+idLength)
        let rawMessageID = String(data: idData, encoding: .utf8) ?? ""
        
        // 🔧 使用統一的UUID正規化處理
        let messageID = normalizeUUID(rawMessageID)
        
        guard !messageID.isEmpty else {
            print("❌ BinaryMessageDecoder: ID字符串解碼失敗 - 長度: \(idLength), 數據: \(idData.map { String(format: "%02X", $0) }.joined(separator: " "))")
            throw BinaryDecodingError.stringDecodingFailed
        }
        offset += idLength
        
        // 解析數據長度 (4 bytes, Little Endian)
        guard offset + 4 <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let dataLength = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        
        // 解析時間戳 (4 bytes) - 可用於消息時效性檢查
        guard offset + 4 <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let _ = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        
        // 驗證數據長度
        let expectedEndOffset = offset + Int(dataLength)
        guard expectedEndOffset <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        
        // 提取實際數據
        let messageData = data.subdata(in: offset..<expectedEndOffset)
        
        // 轉換為MeshMessage（使用完整初始化器）
        let meshType = messageType
        return MeshMessage(id: messageID, type: meshType, data: messageData)
    }
    
    // MARK: - 拓撲數據專用解碼 (30萬用戶優化)
    static func decodeTopology(_ data: Data, expectedType: MeshMessageType = .topology) throws -> [String: Set<String>] {
        guard data.count >= 6 else { // 版本(1) + 類型(1) + 節點數(4)
            print("❌ BinaryMessageDecoder: 拓撲數據長度不足 - 實際: \(data.count), 最小需要: 6")
            throw BinaryDecodingError.invalidDataSize
        }
        
        var offset = 0
        
        // 驗證協議版本和類型
        let version = data[offset]
        guard version == PROTOCOL_VERSION else {
            print("❌ BinaryMessageDecoder: 協議版本不符 - 預期: \(PROTOCOL_VERSION), 實際: \(version)")
            throw BinaryDecodingError.unsupportedVersion
        }
        offset += 1
        
        let messageType = data[offset]
        guard messageType == expectedType.rawValue else {
            print("❌ BinaryMessageDecoder: 訊息類型不符 - 預期: \(expectedType.rawValue) (\(expectedType)), 實際: \(messageType)")
            throw BinaryDecodingError.invalidMessageType
        }
        offset += 1
        
        // 解析節點數量
        let nodeCount = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        
        // 跳過時間戳
        offset += 4
        
        var topology: [String: Set<String>] = [:]
        
        // 解析每個節點
        for _ in 0..<nodeCount {
            guard offset < data.count else {
                throw BinaryDecodingError.invalidDataSize
            }
            
            // 節點ID長度和內容
            let nodeIDLength = Int(data[offset])
            offset += 1
            
            // 驗證節點ID長度合理性，防止記憶體耗盡攻擊
            guard nodeIDLength > 0 && nodeIDLength <= 64 else {
                print("🚨 SECURITY: 節點ID長度異常: \(nodeIDLength)")
                throw BinaryDecodingError.invalidDataSize
            }
            
            guard offset + nodeIDLength <= data.count else {
                throw BinaryDecodingError.invalidDataSize
            }
            
            let nodeIDData = data.subdata(in: offset..<offset+nodeIDLength)
            guard let nodeID = String(data: nodeIDData, encoding: .utf8) else {
                print("❌ BinaryMessageDecoder: 節點ID字符串解碼失敗 - 長度: \(nodeIDLength), 數據: \(nodeIDData.map { String(format: "%02X", $0) }.joined(separator: " "))")
                throw BinaryDecodingError.stringDecodingFailed
            }
            offset += nodeIDLength
            
            // 連接數量
            guard offset < data.count else {
                throw BinaryDecodingError.invalidDataSize
            }
            let connectionCount = Int(data[offset])
            offset += 1
            
            // 解析連接列表
            var connections: Set<String> = []
            for _ in 0..<connectionCount {
                guard offset < data.count else {
                    throw BinaryDecodingError.invalidDataSize
                }
                
                let connectionLength = Int(data[offset])
                offset += 1
                
                // 驗證連接長度合理性，防止記憶體耗盡攻擊
                guard connectionLength > 0 && connectionLength <= 64 else {
                    print("🚨 SECURITY: 連接長度異常: \(connectionLength)")
                    throw BinaryDecodingError.invalidDataSize
                }
                
                guard offset + connectionLength <= data.count else {
                    throw BinaryDecodingError.invalidDataSize
                }
                
                let connectionData = data.subdata(in: offset..<offset+connectionLength)
                guard let connection = String(data: connectionData, encoding: .utf8) else {
                    throw BinaryDecodingError.stringDecodingFailed
                }
                offset += connectionLength
                
                connections.insert(connection)
            }
            
            topology[nodeID] = connections
        }
        
        return topology
    }
    
    // MARK: - 聊天訊息解碼 (保持現有功能)
    static func decodeChatMessage(_ data: Data) throws -> ChatMessage {
        guard data.count >= 8 else { // 基本頭部大小
            throw BinaryDecodingError.invalidDataSize
        }
        
        var offset = 0
        
        // 驗證協議版本和類型
        let version = data[offset]
        guard version == PROTOCOL_VERSION else {
            throw BinaryDecodingError.unsupportedVersion
        }
        offset += 1
        
        let messageType = data[offset]
        guard messageType == MeshMessageType.chat.rawValue else {
            throw BinaryDecodingError.invalidMessageType
        }
        offset += 1
        
        // 解析時間戳
        let timestamp = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        let _ = Date(timeIntervalSince1970: Double(timestamp))
        
        // 解析發送者
        guard offset < data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let senderLength = Int(data[offset])
        offset += 1
        
        // 驗證發送者長度合理性，防止記憶體耗盡攻擊
        guard senderLength > 0 && senderLength <= 64 else {
            print("🚨 SECURITY: 發送者長度異常: \(senderLength)")
            throw BinaryDecodingError.invalidDataSize
        }
        
        guard offset + senderLength <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let senderData = data.subdata(in: offset..<offset+senderLength)
        guard let sender = String(data: senderData, encoding: .utf8) else {
            throw BinaryDecodingError.stringDecodingFailed
        }
        offset += senderLength
        
        // 解析設備ID
        guard offset < data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let deviceIDLength = Int(data[offset])
        offset += 1
        
        // 驗證設備ID長度合理性，防止記憶體耗盡攻擊
        guard deviceIDLength > 0 && deviceIDLength <= 64 else {
            print("🚨 SECURITY: 設備ID長度異常: \(deviceIDLength)")
            throw BinaryDecodingError.invalidDataSize
        }
        
        guard offset + deviceIDLength <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let deviceIDData = data.subdata(in: offset..<offset+deviceIDLength)
        guard let deviceID = String(data: deviceIDData, encoding: .utf8) else {
            throw BinaryDecodingError.stringDecodingFailed
        }
        offset += deviceIDLength
        
        // 解析訊息內容
        guard offset + 2 <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let messageLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(messageLength) <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let messageData = data.subdata(in: offset..<offset+Int(messageLength))
        guard let message = String(data: messageData, encoding: .utf8) else {
            throw BinaryDecodingError.stringDecodingFailed
        }
        
        return ChatMessage(
            id: deviceID, // 使用解碼的ID
            message: message,
            deviceName: sender,
            timestamp: Double(timestamp),
            isOwn: false,
            isEncrypted: true
        )
    }
    
    // MARK: - 快速類型檢測 (性能優化)
    static func detectMessageType(_ data: Data) -> MeshMessageType? {
        guard data.count >= 2 else { return nil }
        guard data[0] == PROTOCOL_VERSION else { return nil }
        
        guard let messageType = MeshMessageType(rawValue: data[1]) else { return nil }
        return messageType
    }
    
    // MARK: - 🔍 增強診斷工具
    static func analyzeFailedData(_ data: Data) -> String {
        guard data.count >= 2 else {
            return "❌ 數據太短 (\(data.count) bytes) - 至少需要2字節"
        }
        
        let hex = data.prefix(min(20, data.count)).map { String(format: "%02X", $0) }.joined(separator: " ")
        var analysis = "🔍 數據分析 (前\(min(20, data.count))字節): \(hex)\n"
        
        let protocolVersion = data[0]
        let messageType = data[1]
        
        analysis += "📊 基本信息:\n"
        analysis += "   總大小: \(data.count) bytes\n"
        analysis += "   協議版本: \(protocolVersion)\n"
        analysis += "   訊息類型: \(messageType)\n"
        
        // 檢查協議版本
        if protocolVersion == PROTOCOL_VERSION {
            analysis += "✅ 協議版本正確\n"
        } else {
            analysis += "❌ 協議版本錯誤 (期望: \(PROTOCOL_VERSION))\n"
        }
        
        // 檢查訊息類型
        if let msgType = MeshMessageType(rawValue: messageType) {
            analysis += "✅ 訊息類型有效: \(msgType)\n"
        } else {
            analysis += "❌ 未知訊息類型: \(messageType)\n"
        }
        
        analysis += "📋 使用統一新版本格式\n"
        
        // ID分析（如果存在）
        if data.count >= 3 {
            let idLength = Int(data[2])
            analysis += "📝 ID信息:\n"
            analysis += "   ID長度: \(idLength)\n"
            
            if idLength > 0 && idLength <= 40 && data.count >= 3 + idLength {
                let idData = data.subdata(in: 3..<3+idLength)
                let idHex = idData.map { String(format: "%02X", $0) }.joined(separator: " ")
                analysis += "   ID數據: \(idHex)\n"
                
                if let idString = String(data: idData, encoding: .utf8) {
                    analysis += "   ID字符串: \"\(idString)\"\n"
                } else {
                    analysis += "   ID字符串: 無效UTF-8編碼\n"
                }
            } else {
                analysis += "   ⚠️ ID長度異常或數據不足\n"
            }
        }
        
        // 解碼建議
        analysis += "\n🔧 解碼建議:\n"
        if data.count < MIN_HEADER_SIZE {
            analysis += "   建議: 數據太短，檢查是否為完整訊息\n"
        } else {
            analysis += "   建議: 使用標準新版本格式解碼\n"
        }
        
        return analysis
    }
    
    // MARK: - 數據驗證 (安全性)
    static func isValidBinaryData(_ data: Data) -> Bool {
        guard data.count >= MIN_HEADER_SIZE else { return false }
        guard data[0] == PROTOCOL_VERSION else { return false }
        guard MeshMessageType(rawValue: data[1]) != nil else { return false }
        
        // 驗證數據長度一致性
        if data.count >= 6 {
            let declaredLength = data.subdata(in: 2..<6).withUnsafeBytes {
                $0.load(as: UInt32.self).littleEndian
            }
            let actualDataLength = data.count - MIN_HEADER_SIZE
            return declaredLength == actualDataLength
        }
        
        return true
    }
    
    // MARK: - 工具方法
    // binaryToMeshType 方法已移除 - 直接使用統一的 MeshMessageType
    
    // MARK: - 性能優化：批量解碼 (大規模網路優化)
    static func decodeBatch(_ dataArray: [Data]) throws -> [MeshMessage] {
        var results: [MeshMessage] = []
        results.reserveCapacity(dataArray.count) // 預分配容量
        
        for data in dataArray {
            let message = try decode(data)
            results.append(message)
        }
        
        return results
    }
    
    // MARK: - UUID正規化處理（與編碼器保持一致）
    /// 統一UUID格式處理，確保向後相容性
    static func normalizeUUID(_ uuid: String) -> String {
        var cleanUUID = uuid.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除任何可能的$前綴
        if cleanUUID.hasPrefix("$") {
            cleanUUID = String(cleanUUID.dropFirst())
            print("🔧 UUID正規化（解碼器）：移除$前綴，原始=\(uuid)，清理後=\(cleanUUID)")
        }
        
        // 驗證UUID格式（36字符標準UUID或其他有效格式）
        if cleanUUID.count == 36 && cleanUUID.contains("-") {
            // 標準UUID格式 (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
            return cleanUUID
        } else if cleanUUID.count >= 1 && cleanUUID.count <= 64 {
            // 其他有效ID格式
            return cleanUUID  
        } else {
            // 無效格式，留空讓上層處理
            print("⚠️ UUID格式無效（解碼器）: \(uuid)")
            return ""
        }
    }
}

// MARK: - 解碼錯誤處理
enum BinaryDecodingError: Error {
    case invalidDataSize
    case unsupportedVersion
    case invalidMessageType
    case stringDecodingFailed
    case corruptedData
    case invalidUUIDFormat
    
    var localizedDescription: String {
        switch self {
        case .invalidDataSize:
            return "數據大小無效"
        case .unsupportedVersion:
            return "不支持的協議版本"
        case .invalidMessageType:
            return "無效的訊息類型"
        case .stringDecodingFailed:
            return "字符串解碼失敗"
        case .corruptedData:
            return "數據已損壞"
        case .invalidUUIDFormat:
            return "UUID格式無效"
        }
    }
}