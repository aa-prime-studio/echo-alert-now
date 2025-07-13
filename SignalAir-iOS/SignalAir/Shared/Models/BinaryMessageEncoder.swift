import Foundation

// MARK: - 純二進制訊息編碼器
// 專為30萬用戶大規模網狀網路優化

public class BinaryMessageEncoder {
    
    // MARK: - 協議版本和常數
    private static let PROTOCOL_VERSION: UInt8 = 1
    private static let HEADER_SIZE = 12
    
    // MARK: - 訊息類型映射 (與現有MeshMessageType兼容)
    private enum BinaryMessageType: UInt8 {
        case signal = 1     // 0x01 - 對應 MeshMessageType.signal
        case emergency = 2  // 0x02 - 對應 MeshMessageType.emergency
        case chat = 3       // 0x03 - 對應 MeshMessageType.chat
        case system = 4     // 0x04 - 對應 MeshMessageType.system
        case keyExchange = 5 // 0x05 - 對應 MeshMessageType.keyExchange
        case game = 6       // 0x06 - 對應 MeshMessageType.game
        case topology = 7   // 0x07 - 內部拓撲協議
    }
    
    // MARK: - MeshMessage編碼 (核心功能，替換JSON)
    static func encode(_ message: MeshMessage) throws -> Data {
        var binaryData = Data()
        
        // 協議版本 (1 byte)
        binaryData.append(PROTOCOL_VERSION)
        
        // 訊息類型 (1 byte)
        let binaryType = meshTypeToBinary(message.type)
        binaryData.append(binaryType.rawValue)
        
        // 訊息ID長度和內容 (1 byte + ID data)
        let idData = message.id.data(using: .utf8) ?? Data()
        binaryData.append(UInt8(idData.count))
        binaryData.append(idData)
        
        // 數據長度 (4 bytes, Little Endian)
        let dataLength = UInt32(message.data.count)
        binaryData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian, Array.init))
        
        // 時間戳 (4 bytes, Unix timestamp)
        let timestamp = UInt32(Date().timeIntervalSince1970)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        // 實際數據
        binaryData.append(message.data)
        
        return binaryData
    }
    
    // MARK: - 拓撲數據專用編碼 (30萬用戶優化)
    static func encodeTopology(_ topology: [String: Set<String>]) throws -> Data {
        var binaryData = Data()
        
        // 協議版本和類型
        binaryData.append(PROTOCOL_VERSION)
        binaryData.append(BinaryMessageType.topology.rawValue)
        
        // 節點數量 (4 bytes)
        let nodeCount = UInt32(topology.count)
        binaryData.append(contentsOf: withUnsafeBytes(of: nodeCount.littleEndian, Array.init))
        
        // 時間戳
        let timestamp = UInt32(Date().timeIntervalSince1970)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        // 編碼每個節點的連接
        for (nodeID, connections) in topology {
            // 節點ID長度 (1 byte) + 節點ID
            let nodeIDData = nodeID.data(using: .utf8) ?? Data()
            binaryData.append(UInt8(nodeIDData.count))
            binaryData.append(nodeIDData)
            
            // 連接數量 (1 byte, 最多255個直接連接)
            let connectionCount = min(connections.count, 255)
            binaryData.append(UInt8(connectionCount))
            
            // 連接列表
            for connection in connections.prefix(255) {
                let connectionData = connection.data(using: .utf8) ?? Data()
                binaryData.append(UInt8(connectionData.count))
                binaryData.append(connectionData)
            }
        }
        
        return binaryData
    }
    
    // MARK: - 聊天訊息編碼 (保持現有功能)
    static func encodeChatMessage(_ message: ChatMessage) throws -> Data {
        var binaryData = Data()
        
        // 基礎頭部
        binaryData.append(PROTOCOL_VERSION)
        binaryData.append(BinaryMessageType.chat.rawValue)
        
        // 訊息內容
        let messageData = message.message.data(using: .utf8) ?? Data()
        let deviceNameData = message.deviceName.data(using: .utf8) ?? Data()
        let messageIDData = message.id.data(using: .utf8) ?? Data()
        
        // 時間戳 (TimeInterval 已經是 Double)
        let timestamp = UInt32(message.timestamp)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        // 設備名稱長度 + 設備名稱
        binaryData.append(UInt8(deviceNameData.count))
        binaryData.append(deviceNameData)
        
        // 消息ID長度 + 消息ID  
        binaryData.append(UInt8(messageIDData.count))
        binaryData.append(messageIDData)
        
        // 訊息長度 + 訊息內容
        let messageLengthBytes = withUnsafeBytes(of: UInt16(messageData.count).littleEndian, Array.init)
        binaryData.append(contentsOf: messageLengthBytes)
        binaryData.append(messageData)
        
        return binaryData
    }
    
    // MARK: - 工具方法
    private static func meshTypeToBinary(_ meshType: MeshMessageType) -> BinaryMessageType {
        switch meshType {
        case .signal:
            return .signal
        case .emergency:
            return .emergency
        case .chat:
            return .chat
        case .system:
            return .system
        case .keyExchange:
            return .keyExchange
        case .game:
            return .game
        case .topology:
            return .topology
        case .keyExchangeResponse:
            return .keyExchange  // 使用相同的二進制類型
        }
    }
    
    // MARK: - 性能優化：預分配緩衝區 (大規模網路優化)
    private static var sharedBuffer = Data(capacity: 1024) // 重用緩衝區減少分配
    
    static func encodeOptimized(_ message: MeshMessage) throws -> Data {
        sharedBuffer.removeAll(keepingCapacity: true)
        
        // 使用預分配緩衝區提升性能
        sharedBuffer.append(PROTOCOL_VERSION)
        sharedBuffer.append(meshTypeToBinary(message.type).rawValue)
        
        let dataLength = UInt32(message.data.count)
        sharedBuffer.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian, Array.init))
        
        let timestamp = UInt32(Date().timeIntervalSince1970)
        sharedBuffer.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        sharedBuffer.append(message.data)
        
        return Data(sharedBuffer) // 復制返回，保護共享緩衝區
    }
}

// MARK: - 編碼錯誤處理
enum BinaryEncodingError: Error {
    case invalidMessageType
    case dataTooLarge
    case stringEncodingFailed
    case topologyTooLarge
    
    var localizedDescription: String {
        switch self {
        case .invalidMessageType:
            return "無效的訊息類型"
        case .dataTooLarge:
            return "數據大小超過限制"
        case .stringEncodingFailed:
            return "字符串編碼失敗"
        case .topologyTooLarge:
            return "拓撲數據過大"
        }
    }
}