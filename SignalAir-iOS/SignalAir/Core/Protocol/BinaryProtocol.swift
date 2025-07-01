import Foundation

// MARK: - Binary Protocol for SignalAir
// 優化用於大規模斷網場景的二進制協議

/// 協議版本
public enum BinaryProtocolVersion: UInt8 {
    case v1 = 1
}

/// 密鑰交換狀態
public enum KeyExchangeStatus: UInt8 {
    case success = 0
    case alreadyEstablished = 1
    case error = 2
}

/// 消息類型（與其他文件保持一致）
public enum BinaryMessageType: UInt8 {
    case chat = 1
    case game = 2  
    case signal = 3
    case keyExchange = 4
    case keyExchangeResponse = 5
    case system = 6
}

/// 信號標誌位（使用位運算節省空間）
struct SignalFlags: OptionSet {
    let rawValue: UInt8
    
    // 信號類型（0-3位）
    static let safe = SignalFlags(rawValue: 1 << 0)
    static let medical = SignalFlags(rawValue: 1 << 1)
    static let supplies = SignalFlags(rawValue: 1 << 2)
    static let danger = SignalFlags(rawValue: 1 << 3)
    
    // 附加信息（4-7位）
    static let hasLocation = SignalFlags(rawValue: 1 << 4)
    static let isEncrypted = SignalFlags(rawValue: 1 << 5)
    static let highPriority = SignalFlags(rawValue: 1 << 6)
    static let hasGridCode = SignalFlags(rawValue: 1 << 7)
}

// MARK: - Binary Encoder

class BinaryEncoder {
    
    // MARK: - Signal Encoding
    
    /// 編碼加密信號外層結構
    static func encodeEncryptedSignal(
        id: String,
        senderID: String,
        encryptedPayload: Data,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(BinaryProtocolVersion.v1.rawValue)
        
        // 1 byte: 消息類型
        data.append(BinaryMessageType.signal.rawValue)
        
        // 1 byte: 加密標誌（固定為1）
        data.append(1)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID（二進制形式）
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            // 填充16個0
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 加密載荷長度
        let payloadLength = UInt16(encryptedPayload.count)
        data.append(contentsOf: withUnsafeBytes(of: payloadLength.littleEndian) { Array($0) })
        
        // N bytes: 加密載荷
        data.append(encryptedPayload)
        
        return data
    }
    
    // MARK: - 高性能編碼器（零拷貝優化）
    
    /// 高性能編碼加密信號（優化版本）
    static func encodeEncryptedSignalOptimized(
        id: String,
        senderID: String,
        encryptedPayload: Data,
        timestamp: Date = Date()
    ) -> Data {
        // 預分配精確大小避免多次內存重新分配
        let senderData = senderID.data(using: .utf8) ?? Data()
        let capacity = 1 + 1 + 1 + 4 + 16 + 1 + senderData.count + 2 + encryptedPayload.count
        var data = Data(count: capacity)
        
        var offset = 0
        
        // 協議版本 (1 byte)
        data[offset] = BinaryProtocolVersion.v1.rawValue
        offset += 1
        
        // 消息類型 (1 byte)
        data[offset] = BinaryMessageType.signal.rawValue
        offset += 1
        
        // 加密標誌 (1 byte)
        data[offset] = 1
        offset += 1
        
        // 時間戳 (4 bytes)
        let ts = UInt32(timestamp.timeIntervalSince1970).littleEndian
        withUnsafeBytes(of: ts) { bytes in
            data.replaceSubrange(offset..<offset+4, with: bytes)
        }
        offset += 4
        
        // UUID (16 bytes)
        if let uuid = UUID(uuidString: id) {
            withUnsafeBytes(of: uuid.uuid) { bytes in
                data.replaceSubrange(offset..<offset+16, with: bytes)
            }
        }
        offset += 16
        
        // 發送者ID長度 (1 byte)
        data[offset] = UInt8(min(senderData.count, 255))
        offset += 1
        
        // 發送者ID
        if !senderData.isEmpty {
            let length = min(senderData.count, 255)
            data.replaceSubrange(offset..<offset+length, with: senderData.prefix(length))
            offset += length
        }
        
        // 載荷長度 (2 bytes)
        let payloadLength = UInt16(encryptedPayload.count).littleEndian
        withUnsafeBytes(of: payloadLength) { bytes in
            data.replaceSubrange(offset..<offset+2, with: bytes)
        }
        offset += 2
        
        // 載荷
        if !encryptedPayload.isEmpty {
            data.replaceSubrange(offset..<offset+encryptedPayload.count, with: encryptedPayload)
        }
        
        return data
    }
    
    /// 編碼內部信號數據（加密前）
    static func encodeSignalData(
        id: String,
        type: SignalType,
        deviceName: String,
        deviceID: String,
        gridCode: String? = nil,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 標誌位
        var flags = SignalFlags()
        switch type {
        case .safe: flags.insert(.safe)
        case .medical: flags.insert(.medical)
        case .supplies: flags.insert(.supplies)
        case .danger: flags.insert(.danger)
        }
        
        if gridCode != nil {
            flags.insert(.hasGridCode)
        }
        
        data.append(flags.rawValue)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 設備名稱
        if let nameData = deviceName.data(using: .utf8) {
            data.append(UInt8(min(nameData.count, 255)))
            data.append(nameData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 設備ID
        if let idData = deviceID.data(using: .utf8) {
            data.append(UInt8(min(idData.count, 255)))
            data.append(idData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 網格碼（如果有）
        if let gridCode = gridCode, let gridData = gridCode.data(using: .utf8) {
            data.append(UInt8(min(gridData.count, 255)))
            data.append(gridData.prefix(255))
        }
        
        return data
    }
    
    // MARK: - Game Encoding
    
    static func encodeGameMessage(
        id: String,
        type: GameMessageType,
        senderID: String,
        senderName: String,
        gameRoomID: String,
        data: Data,
        timestamp: Date = Date()
    ) -> Data {
        var result = Data()
        
        // 1 byte: 協議版本
        result.append(BinaryProtocolVersion.v1.rawValue)
        
        // 1 byte: 消息類型
        result.append(BinaryMessageType.game.rawValue)
        
        // 1 byte: 遊戲消息子類型（使用GameMessageType的rawValue哈希）
        let gameTypeHash = UInt8(abs(type.rawValue.hashValue) % 256)
        result.append(gameTypeHash)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        result.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            result.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            result.append(Data(repeating: 0, count: 16))
        }
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            result.append(UInt8(min(senderData.count, 255)))
            result.append(senderData.prefix(255))
        } else {
            result.append(0)
        }
        
        // 發送者名稱
        if let nameData = senderName.data(using: .utf8) {
            result.append(UInt8(min(nameData.count, 255)))
            result.append(nameData.prefix(255))
        } else {
            result.append(0)
        }
        
        // 遊戲房間ID
        if let roomData = gameRoomID.data(using: .utf8) {
            result.append(UInt8(min(roomData.count, 255)))
            result.append(roomData.prefix(255))
        } else {
            result.append(0)
        }
        
        // 2 bytes: 數據長度
        let dataLength = UInt16(data.count)
        result.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        
        // N bytes: 數據
        result.append(data)
        
        return result
    }
    
    // MARK: - Key Exchange Encoding
    
    static func encodeKeyExchange(
        publicKey: Data,
        senderID: String,
        retryCount: UInt8 = 0,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(BinaryProtocolVersion.v1.rawValue)
        
        // 1 byte: 消息類型
        data.append(BinaryMessageType.keyExchange.rawValue)
        
        // 1 byte: 重試次數
        data.append(retryCount)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        data.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        data.append(publicKey)
        
        return data
    }
    
    static func encodeKeyExchangeResponse(
        publicKey: Data,
        senderID: String,
        status: KeyExchangeStatus,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(BinaryProtocolVersion.v1.rawValue)
        
        // 1 byte: 消息類型
        data.append(BinaryMessageType.keyExchangeResponse.rawValue)
        
        // 1 byte: 狀態
        data.append(status.rawValue)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        data.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        data.append(publicKey)
        
        // 錯誤訊息（可選）
        if let errorMessage = errorMessage, let errorData = errorMessage.data(using: .utf8) {
            data.append(UInt8(min(errorData.count, 255)))
            data.append(errorData.prefix(255))
        } else {
            data.append(0)
        }
        
        return data
    }
    
    // MARK: - Chat Encoding
    
    static func encodeChatMessage(
        id: String,
        message: String,
        deviceName: String,
        isEncrypted: Bool = true,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(BinaryProtocolVersion.v1.rawValue)
        
        // 1 byte: 消息類型
        data.append(BinaryMessageType.chat.rawValue)
        
        // 1 byte: 加密標誌
        data.append(isEncrypted ? 1 : 0)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 設備名稱
        if let nameData = deviceName.data(using: .utf8) {
            data.append(UInt8(min(nameData.count, 255)))
            data.append(nameData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 消息內容
        if let msgData = message.data(using: .utf8) {
            let length = UInt16(min(msgData.count, 65535))
            data.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Array($0) })
            data.append(msgData.prefix(Int(length)))
        } else {
            data.append(contentsOf: [0, 0])
        }
        
        return data
    }
}

// MARK: - Binary Decoder

class BinaryDecoder {
    
    // MARK: - Signal Decoding
    
    /// 解碼加密信號外層結構
    static func decodeEncryptedSignal(_ data: Data) -> (
        version: UInt8,
        messageType: BinaryMessageType,
        isEncrypted: Bool,
        timestamp: Date,
        id: String,
        senderID: String,
        encryptedPayload: Data
    )? {
        guard data.count >= 26 else { return nil } // 最小長度檢查
        
        var offset = 0
        
        // 協議版本
        let version = data[offset]
        offset += 1
        
        // 消息類型
        guard let messageType = BinaryMessageType(rawValue: data[offset]) else { return nil }
        offset += 1
        
        // 加密標誌
        let isEncrypted = data[offset] == 1
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes { 
            $0.load(as: UInt32.self).littleEndian 
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 發送者ID
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 加密載荷長度
        guard offset + 2 <= data.count else { return nil }
        let payloadLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 加密載荷
        guard offset + Int(payloadLength) <= data.count else { return nil }
        let encryptedPayload = data.subdata(in: offset..<offset+Int(payloadLength))
        
        return (
            version: version,
            messageType: messageType,
            isEncrypted: isEncrypted,
            timestamp: timestamp,
            id: uuid.uuidString,
            senderID: senderID,
            encryptedPayload: encryptedPayload
        )
    }
    
    /// 解碼內部信號數據（解密後）
    static func decodeSignalData(_ data: Data) -> (
        type: SignalType,
        timestamp: Date,
        id: String,
        deviceName: String,
        deviceID: String,
        gridCode: String?
    )? {
        guard data.count >= 23 else { return nil } // 最小長度檢查
        
        var offset = 0
        
        // 標誌位
        let flags = SignalFlags(rawValue: data[offset])
        offset += 1
        
        // 解析信號類型
        let type: SignalType
        if flags.contains(.safe) {
            type = .safe
        } else if flags.contains(.medical) {
            type = .medical
        } else if flags.contains(.supplies) {
            type = .supplies
        } else if flags.contains(.danger) {
            type = .danger
        } else {
            return nil
        }
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 設備名稱
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 設備ID
        guard offset < data.count else { return nil }
        let idLength = Int(data[offset])
        offset += 1
        
        guard offset + idLength <= data.count else { return nil }
        let deviceID = String(data: data.subdata(in: offset..<offset+idLength), encoding: .utf8) ?? ""
        offset += idLength
        
        // 網格碼（如果有）
        var gridCode: String?
        if flags.contains(.hasGridCode) && offset < data.count {
            let gridLength = Int(data[offset])
            offset += 1
            
            if offset + gridLength <= data.count {
                gridCode = String(data: data.subdata(in: offset..<offset+gridLength), encoding: .utf8)
            }
        }
        
        return (
            type: type,
            timestamp: timestamp,
            id: uuid.uuidString,
            deviceName: deviceName,
            deviceID: deviceID,
            gridCode: gridCode
        )
    }
    
    // MARK: - Key Exchange Decoding
    
    static func decodeKeyExchange(_ data: Data) -> (
        publicKey: Data,
        senderID: String,
        retryCount: UInt8,
        timestamp: Date
    )? {
        guard data.count >= 8 else { return nil }
        
        var offset = 0
        
        // 跳過協議版本和消息類型
        offset += 2
        
        // 重試次數
        let retryCount = data[offset]
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 發送者ID
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 公鑰長度
        guard offset + 2 <= data.count else { return nil }
        let keyLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 公鑰數據
        guard offset + Int(keyLength) <= data.count else { return nil }
        let publicKey = data.subdata(in: offset..<offset+Int(keyLength))
        
        return (
            publicKey: publicKey,
            senderID: senderID,
            retryCount: retryCount,
            timestamp: timestamp
        )
    }
    
    static func decodeKeyExchangeResponse(_ data: Data) -> (
        publicKey: Data,
        senderID: String,
        status: KeyExchangeStatus,
        errorMessage: String?,
        timestamp: Date
    )? {
        guard data.count >= 8 else { return nil }
        
        var offset = 0
        
        // 跳過協議版本和消息類型
        offset += 2
        
        // 狀態
        let statusRaw = data[offset]
        guard let status = KeyExchangeStatus(rawValue: statusRaw) else { return nil }
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 發送者ID
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 公鑰長度
        guard offset + 2 <= data.count else { return nil }
        let keyLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 公鑰數據
        guard offset + Int(keyLength) <= data.count else { return nil }
        let publicKey = data.subdata(in: offset..<offset+Int(keyLength))
        offset += Int(keyLength)
        
        // 錯誤訊息（可選）
        var errorMessage: String? = nil
        if offset < data.count {
            let errorLength = Int(data[offset])
            offset += 1
            
            if errorLength > 0 && offset + errorLength <= data.count {
                errorMessage = String(data: data.subdata(in: offset..<offset+errorLength), encoding: .utf8)
            }
        }
        
        return (
            publicKey: publicKey,
            senderID: senderID,
            status: status,
            errorMessage: errorMessage,
            timestamp: timestamp
        )
    }
    
    // MARK: - Chat Decoding
    
    static func decodeChatMessage(_ data: Data) -> ChatMessage? {
        guard data.count >= 26 else { return nil }
        
        var offset = 0
        
        // 跳過協議版本和消息類型
        offset += 2
        
        // 加密標誌
        let isEncrypted = data[offset] == 1
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = TimeInterval(ts)
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 設備名稱
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 消息內容
        guard offset + 2 <= data.count else { return nil }
        let msgLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(msgLength) <= data.count else { return nil }
        let message = String(data: data.subdata(in: offset..<offset+Int(msgLength)), encoding: .utf8) ?? ""
        
        return ChatMessage(
            id: uuid.uuidString,
            message: message,
            deviceName: deviceName,
            timestamp: timestamp,
            isOwn: false,
            isEncrypted: isEncrypted
        )
    }
    
    // MARK: - 高性能解碼器（優化版本）
    
    /// 高性能解碼加密信號（零拷貝優化）
    static func decodeEncryptedSignalOptimized(_ data: Data) -> (
        version: UInt8,
        messageType: UInt8,
        isEncrypted: Bool,
        timestamp: Date,
        id: String,
        senderID: String,
        encryptedPayload: Data
    )? {
        guard data.count >= 26 else { return nil }
        
        return data.withUnsafeBytes { bytes in
            var offset = 0
            
            // 協議版本
            let version = bytes.load(fromByteOffset: offset, as: UInt8.self)
            offset += 1
            
            // 消息類型
            let messageType = bytes.load(fromByteOffset: offset, as: UInt8.self)
            offset += 1
            
            // 加密標誌
            let isEncrypted = bytes.load(fromByteOffset: offset, as: UInt8.self) == 1
            offset += 1
            
            // 時間戳
            let ts = bytes.load(fromByteOffset: offset, as: UInt32.self).littleEndian
            let timestamp = Date(timeIntervalSince1970: Double(ts))
            offset += 4
            
            // UUID
            let uuidBytes = bytes.loadUnaligned(fromByteOffset: offset, as: uuid_t.self)
            let uuid = UUID(uuid: uuidBytes)
            offset += 16
            
            // 發送者ID長度
            let senderIDLength = Int(bytes.load(fromByteOffset: offset, as: UInt8.self))
            offset += 1
            
            guard offset + senderIDLength <= data.count else { return nil }
            
            // 發送者ID
            let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
            offset += senderIDLength
            
            // 載荷長度
            guard offset + 2 <= data.count else { return nil }
            let payloadLength = bytes.load(fromByteOffset: offset, as: UInt16.self).littleEndian
            offset += 2
            
            // 載荷
            guard offset + Int(payloadLength) <= data.count else { return nil }
            let encryptedPayload = data.subdata(in: offset..<offset+Int(payloadLength))
            
            return (
                version: version,
                messageType: messageType,
                isEncrypted: isEncrypted,
                timestamp: timestamp,
                id: uuid.uuidString,
                senderID: senderID,
                encryptedPayload: encryptedPayload
            )
        }
    }
}

// MARK: - 二進制數據驗證器

class BinaryDataValidator {
    
    // MARK: - 驗證錯誤類型
    enum ValidationError: Error, LocalizedError {
        case invalidProtocolVersion(UInt8)
        case invalidMessageType(UInt8)
        case corruptedData(String)
        case payloadSizeExceeded(Int, max: Int)
        case invalidUUID
        case invalidTimestamp(Double)
        case checksumMismatch
        
        var errorDescription: String? {
            switch self {
            case .invalidProtocolVersion(let version):
                return "不支持的協議版本: \(version)"
            case .invalidMessageType(let type):
                return "未知的消息類型: \(type)"
            case .corruptedData(let reason):
                return "數據損壞: \(reason)"
            case .payloadSizeExceeded(let size, let max):
                return "載荷大小超限: \(size) > \(max)"
            case .invalidUUID:
                return "無效的UUID格式"
            case .invalidTimestamp(let timestamp):
                return "無效的時間戳: \(timestamp)"
            case .checksumMismatch:
                return "校驗和不匹配"
            }
        }
    }
    
    // MARK: - 配置常數
    private static let maxPayloadSize = 1024 * 1024 // 1MB
    private static let maxStringLength = 1024
    private static let maxTimestampDrift: TimeInterval = 86400 // 24小時
    
    /// 驗證二進制數據完整性
    static func validateBinaryData(_ data: Data) throws {
        guard data.count >= 3 else {
            throw ValidationError.corruptedData("數據太短，至少需要3字節")
        }
        
        // 檢查協議版本
        let version = data[0]
        guard version == BinaryProtocolVersion.v1.rawValue else {
            throw ValidationError.invalidProtocolVersion(version)
        }
        
        // 檢查消息類型
        let messageType = data[1]
        let validTypes: [UInt8] = [
            BinaryMessageType.signal.rawValue,
            BinaryMessageType.chat.rawValue,
            BinaryMessageType.game.rawValue,
            BinaryMessageType.keyExchange.rawValue,
            BinaryMessageType.system.rawValue
        ]
        
        guard validTypes.contains(messageType) else {
            throw ValidationError.invalidMessageType(messageType)
        }
        
        // 根據消息類型進行具體驗證
        switch BinaryMessageType(rawValue: messageType) {
        case .signal:
            try validateSignalData(data)
        case .chat:
            try validateChatData(data)
        case .game:
            try validateGameData(data)
        default:
            break
        }
    }
    
    /// 驗證信號數據
    private static func validateSignalData(_ data: Data) throws {
        guard data.count >= 26 else {
            throw ValidationError.corruptedData("信號數據長度不足")
        }
        
        var offset = 3 // 跳過版本、類型、加密標誌
        
        // 驗證時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = TimeInterval(ts)
        let now = Date().timeIntervalSince1970
        
        if abs(timestamp - now) > maxTimestampDrift {
            throw ValidationError.invalidTimestamp(timestamp)
        }
        
        offset += 4 + 16 // 跳過時間戳和UUID
        
        // 驗證發送者ID長度
        guard offset < data.count else {
            throw ValidationError.corruptedData("無法讀取發送者ID長度")
        }
        
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard senderIDLength <= maxStringLength else {
            throw ValidationError.payloadSizeExceeded(senderIDLength, max: maxStringLength)
        }
        
        guard offset + senderIDLength <= data.count else {
            throw ValidationError.corruptedData("發送者ID數據不完整")
        }
        
        offset += senderIDLength
        
        // 驗證載荷長度
        guard offset + 2 <= data.count else {
            throw ValidationError.corruptedData("無法讀取載荷長度")
        }
        
        let payloadLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        
        guard Int(payloadLength) <= maxPayloadSize else {
            throw ValidationError.payloadSizeExceeded(Int(payloadLength), max: maxPayloadSize)
        }
        
        offset += 2
        
        guard offset + Int(payloadLength) <= data.count else {
            throw ValidationError.corruptedData("載荷數據不完整")
        }
    }
    
    /// 驗證聊天數據
    private static func validateChatData(_ data: Data) throws {
        // 類似的聊天數據驗證邏輯
        guard data.count >= 23 else {
            throw ValidationError.corruptedData("聊天數據長度不足")
        }
        // 更多驗證邏輯...
    }
    
    /// 驗證遊戲數據
    private static func validateGameData(_ data: Data) throws {
        // 類似的遊戲數據驗證邏輯
        guard data.count >= 20 else {
            throw ValidationError.corruptedData("遊戲數據長度不足")
        }
        // 更多驗證邏輯...
    }
}

// MARK: - 二進制協議性能統計

class BinaryProtocolMetrics {
    
    struct PerformanceStats {
        var totalEncodingTime: TimeInterval = 0
        var totalDecodingTime: TimeInterval = 0
        var encodingCount: Int = 0
        var decodingCount: Int = 0
        var averageEncodingTime: TimeInterval { 
            encodingCount > 0 ? totalEncodingTime / Double(encodingCount) : 0 
        }
        var averageDecodingTime: TimeInterval { 
            decodingCount > 0 ? totalDecodingTime / Double(decodingCount) : 0 
        }
        var compressionRatio: Double = 0
        var errorCount: Int = 0
    }
    
    static var shared = BinaryProtocolMetrics()
    private var stats = PerformanceStats()
    private let queue = DispatchQueue(label: "BinaryProtocolMetrics", qos: .utility)
    
    func recordEncoding(time: TimeInterval, originalSize: Int, compressedSize: Int) {
        queue.async {
            self.stats.totalEncodingTime += time
            self.stats.encodingCount += 1
            
            if originalSize > 0 {
                let ratio = Double(compressedSize) / Double(originalSize)
                self.stats.compressionRatio = (self.stats.compressionRatio + ratio) / 2.0
            }
        }
    }
    
    func recordDecoding(time: TimeInterval) {
        queue.async {
            self.stats.totalDecodingTime += time
            self.stats.decodingCount += 1
        }
    }
    
    func recordError() {
        queue.async {
            self.stats.errorCount += 1
        }
    }
    
    func getStats() -> PerformanceStats {
        return queue.sync { stats }
    }
    
    func resetStats() {
        queue.async {
            self.stats = PerformanceStats()
        }
    }
    
    func printReport() {
        let currentStats = getStats()
        print("""
        📊 二進制協議性能報告
        ═══════════════════════════════
        編碼次數: \(currentStats.encodingCount)
        解碼次數: \(currentStats.decodingCount)
        平均編碼時間: \(String(format: "%.3f", currentStats.averageEncodingTime * 1000))ms
        平均解碼時間: \(String(format: "%.3f", currentStats.averageDecodingTime * 1000))ms
        平均壓縮率: \(String(format: "%.1f%%", currentStats.compressionRatio * 100))
        錯誤次數: \(currentStats.errorCount)
        錯誤率: \(String(format: "%.2f%%", Double(currentStats.errorCount) / Double(max(1, currentStats.encodingCount + currentStats.decodingCount)) * 100))
        ═══════════════════════════════
        """)
    }
}