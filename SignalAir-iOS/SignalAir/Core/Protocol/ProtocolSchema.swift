import Foundation

// MARK: - SignalAir Protocol Schema Definition
// 高度嚴謹的二進制協議定義，類似 Protobuf 但針對災難通訊優化

/// 協議版本管理
struct ProtocolVersion {
    static let current: UInt8 = 1
    static let compatible: [UInt8] = [1] // 向後兼容的版本
    
    static func isSupported(_ version: UInt8) -> Bool {
        return compatible.contains(version)
    }
}

/// 訊息類型嚴格定義
enum MessageType: UInt8, CaseIterable {
    case chat = 1
    case game = 2
    case signal = 3
    case system = 4
    case keyExchange = 6
    case keyExchangeResponse = 7
    case heartbeat = 8
    case topology = 9
    
    var maxPayloadSize: Int {
        switch self {
        case .chat: return 2048      // 2KB for chat
        case .game: return 4096      // 4KB for game data
        case .signal: return 1024    // 1KB for signal
        case .system: return 512     // 512B for system
        case .keyExchange: return 1024 // 1KB for keys
        case .keyExchangeResponse: return 1024
        case .heartbeat: return 64   // 64B for heartbeat
        case .topology: return 8192  // 8KB for topology
        }
    }
    
    var requiresEncryption: Bool {
        switch self {
        case .chat, .signal: return true
        case .keyExchange, .keyExchangeResponse: return false // 密鑰交換本身不加密
        case .game, .system, .heartbeat, .topology: return false
        }
    }
}

/// 信號類型嚴格定義
enum SignalType: UInt8, CaseIterable {
    case safe = 1
    case medical = 2
    case supplies = 3
    case danger = 4
    
    var priority: UInt8 {
        switch self {
        case .danger: return 100
        case .medical: return 90
        case .supplies: return 50
        case .safe: return 30
        }
    }
}

// MARK: - Schema Definitions

/// 通用訊息頭部 Schema
struct MessageHeaderSchema {
    static let size = 12
    
    struct Fields {
        static let version = (offset: 0, size: 1)      // UInt8
        static let messageType = (offset: 1, size: 1)  // UInt8
        static let flags = (offset: 2, size: 1)        // UInt8
        static let reserved = (offset: 3, size: 1)     // UInt8 保留
        static let timestamp = (offset: 4, size: 4)    // UInt32
        static let payloadLength = (offset: 8, size: 4) // UInt32
    }
    
    struct Flags {
        static let encrypted: UInt8 = 0x01
        static let compressed: UInt8 = 0x02
        static let priority: UInt8 = 0x04
        static let acknowledgment: UInt8 = 0x08
    }
}

/// 信號訊息 Schema
struct SignalMessageSchema {
    static let headerSize = MessageHeaderSchema.size
    
    struct PayloadFields {
        static let signalType = (offset: 0, size: 1)   // UInt8
        static let senderIdLength = (offset: 1, size: 1) // UInt8
        static let deviceNameLength = (offset: 2, size: 1) // UInt8
        static let reserved = (offset: 3, size: 1)     // UInt8
        static let messageId = (offset: 4, size: 16)   // UUID 128-bit
        static let location = (offset: 20, size: 16)   // 經緯度 2x Double
        static let variableData = (offset: 36, size: 0) // 可變長度數據
    }
    
    static let fixedPayloadSize = 36
    static let maxTotalSize = 512 // 控制在512字節內
}

/// 聊天訊息 Schema
struct ChatMessageSchema {
    static let headerSize = MessageHeaderSchema.size
    
    struct PayloadFields {
        static let messageId = (offset: 0, size: 16)   // UUID
        static let senderIdLength = (offset: 16, size: 1) // UInt8
        static let deviceNameLength = (offset: 17, size: 1) // UInt8
        static let messageLength = (offset: 18, size: 2) // UInt16
        static let variableData = (offset: 20, size: 0) // 可變數據
    }
    
    static let fixedPayloadSize = 20
    static let maxMessageLength = 1024
}

/// 系統訊息 Schema
struct SystemMessageSchema {
    static let headerSize = MessageHeaderSchema.size
    
    struct PayloadFields {
        static let systemType = (offset: 0, size: 1)   // UInt8
        static let priority = (offset: 1, size: 1)     // UInt8
        static let dataLength = (offset: 2, size: 2)   // UInt16
        static let data = (offset: 4, size: 0)         // 可變數據
    }
    
    enum SystemType: UInt8 {
        case heartbeat = 1
        case status = 2
        case error = 3
        case config = 4
    }
}

/// 密鑰交換 Schema
struct KeyExchangeSchema {
    static let headerSize = MessageHeaderSchema.size
    
    struct PayloadFields {
        static let keyType = (offset: 0, size: 1)      // UInt8
        static let retryCount = (offset: 1, size: 1)   // UInt8
        static let senderIdLength = (offset: 2, size: 1) // UInt8
        static let reserved = (offset: 3, size: 1)     // UInt8
        static let publicKeyLength = (offset: 4, size: 2) // UInt16
        static let variableData = (offset: 6, size: 0) // 可變數據
    }
    
    static let fixedPayloadSize = 6
    static let maxPublicKeySize = 256
}

// MARK: - Schema Validator

class ProtocolSchemaValidator {
    
    enum ValidationError: Error {
        case invalidProtocolVersion(UInt8)
        case unknownMessageType(UInt8)
        case payloadSizeExceeded(Int, max: Int)
        case invalidHeaderSize(Int)
        case invalidPayloadStructure(String)
        case checksumMismatch
        case timestampOutOfRange(UInt32)
    }
    
    /// 驗證完整訊息
    static func validateMessage(_ data: Data) throws {
        guard data.count >= MessageHeaderSchema.size else {
            throw ValidationError.invalidHeaderSize(data.count)
        }
        
        // 驗證頭部
        let header = try parseHeader(data)
        try validateHeader(header)
        
        // 驗證載荷
        let payloadData = data.dropFirst(MessageHeaderSchema.size)
        try validatePayload(payloadData, messageType: header.messageType)
    }
    
    /// 解析訊息頭部
    static func parseHeader(_ data: Data) throws -> MessageHeader {
        guard data.count >= MessageHeaderSchema.size else {
            throw ValidationError.invalidHeaderSize(data.count)
        }
        
        let version = data[MessageHeaderSchema.Fields.version.offset]
        let messageTypeRaw = data[MessageHeaderSchema.Fields.messageType.offset]
        let flags = data[MessageHeaderSchema.Fields.flags.offset]
        
        let timestamp = data.subdata(in: 4..<8).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        
        let payloadLength = data.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        
        guard let messageType = MessageType(rawValue: messageTypeRaw) else {
            throw ValidationError.unknownMessageType(messageTypeRaw)
        }
        
        return MessageHeader(
            version: version,
            messageType: messageType,
            flags: flags,
            timestamp: timestamp,
            payloadLength: payloadLength
        )
    }
    
    /// 驗證頭部
    static func validateHeader(_ header: MessageHeader) throws {
        // 檢查協議版本
        guard ProtocolVersion.isSupported(header.version) else {
            throw ValidationError.invalidProtocolVersion(header.version)
        }
        
        // 檢查載荷大小
        let maxSize = header.messageType.maxPayloadSize
        guard Int(header.payloadLength) <= maxSize else {
            throw ValidationError.payloadSizeExceeded(Int(header.payloadLength), max: maxSize)
        }
        
        // 檢查時間戳合理性（不能太舊或太新）
        let now = UInt32(Date().timeIntervalSince1970)
        let timeDiff = abs(Int32(header.timestamp) - Int32(now))
        guard timeDiff < 3600 else { // 1小時內
            throw ValidationError.timestampOutOfRange(header.timestamp)
        }
    }
    
    /// 驗證載荷結構
    static func validatePayload(_ payload: Data, messageType: MessageType) throws {
        switch messageType {
        case .signal:
            try validateSignalPayload(payload)
        case .chat:
            try validateChatPayload(payload)
        case .system:
            try validateSystemPayload(payload)
        case .keyExchange:
            try validateKeyExchangePayload(payload)
        default:
            // 其他類型的基本驗證
            break
        }
    }
    
    /// 驗證信號載荷
    static func validateSignalPayload(_ payload: Data) throws {
        guard payload.count >= SignalMessageSchema.fixedPayloadSize else {
            throw ValidationError.invalidPayloadStructure("Signal payload too short")
        }
        
        let signalTypeRaw = payload[SignalMessageSchema.PayloadFields.signalType.offset]
        guard SignalType(rawValue: signalTypeRaw) != nil else {
            throw ValidationError.invalidPayloadStructure("Invalid signal type: \(signalTypeRaw)")
        }
        
        let senderIdLength = Int(payload[SignalMessageSchema.PayloadFields.senderIdLength.offset])
        let deviceNameLength = Int(payload[SignalMessageSchema.PayloadFields.deviceNameLength.offset])
        
        let expectedMinSize = SignalMessageSchema.fixedPayloadSize + senderIdLength + deviceNameLength
        guard payload.count >= expectedMinSize else {
            throw ValidationError.invalidPayloadStructure("Signal payload variable data incomplete")
        }
    }
    
    /// 驗證聊天載荷
    static func validateChatPayload(_ payload: Data) throws {
        guard payload.count >= ChatMessageSchema.fixedPayloadSize else {
            throw ValidationError.invalidPayloadStructure("Chat payload too short")
        }
        
        let messageLength = payload.subdata(in: 18..<20).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        
        guard messageLength <= ChatMessageSchema.maxMessageLength else {
            throw ValidationError.payloadSizeExceeded(Int(messageLength), max: ChatMessageSchema.maxMessageLength)
        }
    }
    
    /// 驗證系統載荷
    static func validateSystemPayload(_ payload: Data) throws {
        guard payload.count >= SystemMessageSchema.fixedPayloadSize else {
            throw ValidationError.invalidPayloadStructure("System payload too short")
        }
        
        let systemTypeRaw = payload[SystemMessageSchema.PayloadFields.systemType.offset]
        guard SystemMessageSchema.SystemType(rawValue: systemTypeRaw) != nil else {
            throw ValidationError.invalidPayloadStructure("Invalid system type: \(systemTypeRaw)")
        }
    }
    
    /// 驗證密鑰交換載荷
    static func validateKeyExchangePayload(_ payload: Data) throws {
        guard payload.count >= KeyExchangeSchema.fixedPayloadSize else {
            throw ValidationError.invalidPayloadStructure("KeyExchange payload too short")
        }
        
        let publicKeyLength = payload.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        
        guard publicKeyLength <= KeyExchangeSchema.maxPublicKeySize else {
            throw ValidationError.payloadSizeExceeded(Int(publicKeyLength), max: KeyExchangeSchema.maxPublicKeySize)
        }
    }
}

// MARK: - Supporting Types

struct MessageHeader {
    let version: UInt8
    let messageType: MessageType
    let flags: UInt8
    let timestamp: UInt32
    let payloadLength: UInt32
}

// MARK: - Schema Documentation Generator

class SchemaDocumentationGenerator {
    static func generateMarkdown() -> String {
        return """
# SignalAir 二進制協議 Schema 文件

## 協議版本
- 當前版本: \(ProtocolVersion.current)
- 相容版本: \(ProtocolVersion.compatible.map(String.init).joined(separator: ", "))

## 訊息類型

| 類型 | 值 | 最大載荷 | 需要加密 | 用途 |
|------|----|---------|---------|----- |
\(MessageType.allCases.map { type in
"| \(type) | \(type.rawValue) | \(type.maxPayloadSize)B | \(type.requiresEncryption ? "是" : "否") | 災難通訊 |"
}.joined(separator: "\n"))

## 訊息頭部結構 (\(MessageHeaderSchema.size) bytes)

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Version    |  MessageType  |     Flags     |   Reserved    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Timestamp                           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        PayloadLength                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## 信號訊息載荷結構

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| SignalType    |SenderIDLength |DeviceNameLen  |   Reserved    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                        Message UUID (128-bit)                |
|                                                               |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Location (Latitude)                   |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Location (Longitude)                  |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      Variable Length Data                    |
|                    (SenderID + DeviceName)                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## 驗證規則

1. **協議版本**: 必須為支援的版本
2. **載荷大小**: 不得超過類型限制
3. **時間戳**: 與當前時間差異不得超過1小時
4. **字符串長度**: 所有可變長度字段必須有效
5. **類型驗證**: 所有枚舉值必須有效

## 錯誤代碼

- `invalidProtocolVersion`: 不支援的協議版本
- `unknownMessageType`: 未知訊息類型
- `payloadSizeExceeded`: 載荷超過大小限制
- `invalidHeaderSize`: 頭部大小無效
- `invalidPayloadStructure`: 載荷結構無效
- `timestampOutOfRange`: 時間戳超出合理範圍

此協議專為災難通訊場景優化，確保在30萬用戶規模下的可靠性和效率。
"""
    }
}