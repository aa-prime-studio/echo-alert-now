import Foundation

// MARK: - 純二進制訊息解碼器
// 專為30萬用戶大規模網狀網路優化

public class BinaryMessageDecoder {
    
    // MARK: - 協議版本和常數
    private static let PROTOCOL_VERSION: UInt8 = 1
    private static let MIN_HEADER_SIZE = 10 // 最小頭部大小
    
    // MARK: - 訊息類型映射 (與編碼器保持一致)
    private enum BinaryMessageType: UInt8 {
        case chat = 1
        case game = 2
        case signal = 3
        case system = 4
        case topology = 5
    }
    
    // MARK: - MeshMessage解碼 (核心功能，替換JSON)
    static func decode(_ data: Data) throws -> MeshMessage {
        guard data.count >= MIN_HEADER_SIZE else {
            throw BinaryDecodingError.invalidDataSize
        }
        
        var offset = 0
        
        // 驗證協議版本 (1 byte)
        let version = data[offset]
        guard version == PROTOCOL_VERSION else {
            throw BinaryDecodingError.unsupportedVersion
        }
        offset += 1
        
        // 解析訊息類型 (1 byte)
        guard let binaryType = BinaryMessageType(rawValue: data[offset]) else {
            throw BinaryDecodingError.invalidMessageType
        }
        offset += 1
        
        // 解析訊息ID
        guard offset < data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let idLength = Int(data[offset])
        offset += 1
        
        guard offset + idLength <= data.count else {
            throw BinaryDecodingError.invalidDataSize
        }
        let idData = data.subdata(in: offset..<offset+idLength)
        guard let messageID = String(data: idData, encoding: .utf8) else {
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
        let meshType = binaryToMeshType(binaryType)
        return MeshMessage(id: messageID, type: meshType, data: messageData)
    }
    
    // MARK: - 拓撲數據專用解碼 (30萬用戶優化)
    static func decodeTopology(_ data: Data) throws -> [String: Set<String>] {
        guard data.count >= 6 else { // 版本(1) + 類型(1) + 節點數(4)
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
        guard messageType == BinaryMessageType.topology.rawValue else {
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
            
            guard offset + nodeIDLength <= data.count else {
                throw BinaryDecodingError.invalidDataSize
            }
            
            let nodeIDData = data.subdata(in: offset..<offset+nodeIDLength)
            guard let nodeID = String(data: nodeIDData, encoding: .utf8) else {
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
        guard messageType == BinaryMessageType.chat.rawValue else {
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
        
        guard let binaryType = BinaryMessageType(rawValue: data[1]) else { return nil }
        return binaryToMeshType(binaryType)
    }
    
    // MARK: - 數據驗證 (安全性)
    static func isValidBinaryData(_ data: Data) -> Bool {
        guard data.count >= MIN_HEADER_SIZE else { return false }
        guard data[0] == PROTOCOL_VERSION else { return false }
        guard BinaryMessageType(rawValue: data[1]) != nil else { return false }
        
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
    private static func binaryToMeshType(_ binaryType: BinaryMessageType) -> MeshMessageType {
        switch binaryType {
        case .chat:
            return .chat
        case .game:
            return .game
        case .signal:
            return .signal
        case .system:
            return .system
        case .topology:
            return .system // 拓撲訊息歸類為系統訊息
        }
    }
    
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
}

// MARK: - 解碼錯誤處理
enum BinaryDecodingError: Error {
    case invalidDataSize
    case unsupportedVersion
    case invalidMessageType
    case stringDecodingFailed
    case corruptedData
    
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
        }
    }
}