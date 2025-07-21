import Foundation

// MARK: - Binary Protocol for SignalAir
// 優化用於大規模斷網場景的二進制協議

/// 協議版本 - 統一使用全局常數
private let PROTOCOL_VERSION: UInt8 = 1

/// 密鑰交換狀態
public enum KeyExchangeStatus: UInt8 {
    case success = 0
    case alreadyEstablished = 1
    case error = 2
}

/// 消息類型 - 使用統一的 MeshMessageType
/// 這個 BinaryMessageType 已廢棄，改用 SharedTypes.swift 中的 MeshMessageType
// public enum BinaryMessageType: UInt8 - 已移除重複定義

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
        data.append(PROTOCOL_VERSION)
        
        // 1 byte: 消息類型
        data.append(MeshMessageType.signal.rawValue)
        
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
        data[offset] = PROTOCOL_VERSION
        offset += 1
        
        // 消息類型 (1 byte)
        data[offset] = MeshMessageType.signal.rawValue
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
        result.append(PROTOCOL_VERSION)
        
        // 1 byte: 消息類型
        result.append(MeshMessageType.game.rawValue)
        
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
    ) throws -> Data {
        // 使用標準 BinaryMessageEncoder 格式
        var keyExchangeData = Data()
        
        // 1 byte: 重試次數
        keyExchangeData.append(retryCount)
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            keyExchangeData.append(UInt8(min(senderData.count, 255)))
            keyExchangeData.append(senderData.prefix(255))
        } else {
            keyExchangeData.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        keyExchangeData.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        keyExchangeData.append(publicKey)
        
        // 創建標準 MeshMessage
        let message = MeshMessage(
            id: UUID().uuidString,
            type: .keyExchange,
            data: keyExchangeData
        )
        
        // 使用標準編碼器，提供適當的錯誤處理
        do {
            return try BinaryMessageEncoder.encode(message)
        } catch {
            // 記錄編碼錯誤並提供降級策略
            print("❌ KeyExchange 編碼失敗: \(error)")
            throw BinaryEncodingError.keyExchangeEncodingFailed(underlying: error)
        }
    }
    
    static func encodeKeyExchangeResponse(
        publicKey: Data,
        senderID: String,
        status: KeyExchangeStatus,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) throws -> Data {
        // 使用標準 BinaryMessageEncoder 格式
        var responseData = Data()
        
        // 1 byte: 狀態
        responseData.append(status.rawValue)
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            responseData.append(UInt8(min(senderData.count, 255)))
            responseData.append(senderData.prefix(255))
        } else {
            responseData.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        responseData.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        responseData.append(publicKey)
        
        // 錯誤訊息（可選）
        if let errorMessage = errorMessage, let errorData = errorMessage.data(using: .utf8) {
            responseData.append(UInt8(min(errorData.count, 255)))
            responseData.append(errorData.prefix(255))
        } else {
            responseData.append(0)
        }
        
        // 創建標準 MeshMessage
        let message = MeshMessage(
            id: UUID().uuidString,
            type: .keyExchangeResponse,
            data: responseData
        )
        
        // 使用標準編碼器，提供適當的錯誤處理
        do {
            return try BinaryMessageEncoder.encode(message)
        } catch {
            // 記錄編碼錯誤並提供降級策略
            print("❌ KeyExchangeResponse 編碼失敗: \(error)")
            throw BinaryEncodingError.keyExchangeResponseEncodingFailed(underlying: error)
        }
    }
    
    // MARK: - Safe Encoding Wrappers
    
    /// 安全的密鑰交換編碼包裝器，提供降級策略
    static func safeEncodeKeyExchange(
        publicKey: Data,
        senderID: String,
        retryCount: UInt8 = 0,
        timestamp: Date = Date()
    ) -> Data? {
        do {
            return try encodeKeyExchange(
                publicKey: publicKey,
                senderID: senderID,
                retryCount: retryCount,
                timestamp: timestamp
            )
        } catch {
            print("⚠️ 密鑰交換編碼失敗，使用降級策略: \(error)")
            // 降級策略：創建最基本的密鑰交換包
            return createFallbackKeyExchange(publicKey: publicKey, senderID: senderID)
        }
    }
    
    /// 安全的密鑰交換回應編碼包裝器
    static func safeEncodeKeyExchangeResponse(
        publicKey: Data,
        senderID: String,
        status: KeyExchangeStatus,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) -> Data? {
        do {
            return try encodeKeyExchangeResponse(
                publicKey: publicKey,
                senderID: senderID,
                status: status,
                errorMessage: errorMessage,
                timestamp: timestamp
            )
        } catch {
            print("⚠️ 密鑰交換回應編碼失敗，使用降級策略: \(error)")
            // 降級策略：創建最基本的回應包
            return createFallbackKeyExchangeResponse(status: status, senderID: senderID)
        }
    }
    
    // MARK: - Fallback Strategies
    
    /// 降級策略：創建最基本的密鑰交換包
    private static func createFallbackKeyExchange(publicKey: Data, senderID: String) -> Data {
        var fallbackData = Data()
        
        // 簡化的格式：協議版本 + 類型 + 基本數據
        fallbackData.append(PROTOCOL_VERSION)
        fallbackData.append(MeshMessageType.keyExchange.rawValue)
        
        // 發送者ID長度和數據
        let senderData = senderID.data(using: .utf8) ?? Data()
        fallbackData.append(UInt8(min(senderData.count, 255)))
        fallbackData.append(senderData.prefix(255))
        
        // 公鑰長度和數據
        let keyLength = UInt16(publicKey.count)
        fallbackData.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        fallbackData.append(publicKey)
        
        return fallbackData
    }
    
    /// 降級策略：創建最基本的密鑰交換回應包
    private static func createFallbackKeyExchangeResponse(status: KeyExchangeStatus, senderID: String) -> Data {
        var fallbackData = Data()
        
        // 簡化的格式
        fallbackData.append(PROTOCOL_VERSION)
        fallbackData.append(MeshMessageType.keyExchangeResponse.rawValue)
        fallbackData.append(status.rawValue)
        
        // 發送者ID
        let senderData = senderID.data(using: .utf8) ?? Data()
        fallbackData.append(UInt8(min(senderData.count, 255)))
        fallbackData.append(senderData.prefix(255))
        
        return fallbackData
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
        data.append(PROTOCOL_VERSION)
        
        // 1 byte: 消息類型
        data.append(MeshMessageType.chat.rawValue)
        
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
        messageType: MeshMessageType,
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
        guard let messageType = MeshMessageType(rawValue: data[offset]) else { return nil }
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
    
    // MARK: - 編碼錯誤類型
    enum BinaryEncodingError: Error, LocalizedError {
        case keyExchangeEncodingFailed(underlying: Error)
        case keyExchangeResponseEncodingFailed(underlying: Error)
        case chatMessageEncodingFailed(underlying: Error)
        case gameDataEncodingFailed(underlying: Error)
        case systemMessageEncodingFailed(underlying: Error)
        case encodingConfigurationError(String)
        
        var errorDescription: String? {
            switch self {
            case .keyExchangeEncodingFailed(let error):
                return "密鑰交換編碼失敗: \(error.localizedDescription)"
            case .keyExchangeResponseEncodingFailed(let error):
                return "密鑰交換回應編碼失敗: \(error.localizedDescription)"
            case .chatMessageEncodingFailed(let error):
                return "聊天訊息編碼失敗: \(error.localizedDescription)"
            case .gameDataEncodingFailed(let error):
                return "遊戲資料編碼失敗: \(error.localizedDescription)"
            case .systemMessageEncodingFailed(let error):
                return "系統訊息編碼失敗: \(error.localizedDescription)"
            case .encodingConfigurationError(let message):
                return "編碼配置錯誤: \(message)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .keyExchangeEncodingFailed:
                return "檢查密鑰格式是否正確，如果問題持續，請嘗試重新生成密鑰"
            case .keyExchangeResponseEncodingFailed:
                return "檢查回應狀態和錯誤訊息格式"
            case .chatMessageEncodingFailed:
                return "檢查訊息內容長度和字符編碼"
            case .gameDataEncodingFailed:
                return "檢查遊戲資料結構是否符合協議規範"
            case .systemMessageEncodingFailed:
                return "檢查系統訊息格式"
            case .encodingConfigurationError:
                return "檢查編碼器配置和參數設定"
            }
        }
    }
    
    // MARK: - 驗證錯誤類型
    enum ValidationError: Error, LocalizedError {
        case invalidProtocolVersion(UInt8)
        case invalidMessageType(UInt8)
        case corruptedData(String)
        case payloadSizeExceeded(Int, max: Int)
        case invalidPayloadSize(String)
        case lengthMismatch(String)
        case checksumMismatch(String)
        case invalidReservedField(String)
        case invalidUUID
        case invalidTimestamp(Double)
        
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
            case .invalidPayloadSize(let message):
                return "載荷大小無效: \(message)"
            case .lengthMismatch(let message):
                return "長度不匹配: \(message)"
            case .checksumMismatch(let message):
                return "校驗和錯誤: \(message)"
            case .invalidReservedField(let message):
                return "保留字段錯誤: \(message)"
            case .invalidUUID:
                return "無效的UUID格式"
            case .invalidTimestamp(let timestamp):
                return "無效的時間戳: \(timestamp)"
            }
        }
    }
    
    // MARK: - 配置常數
    private static let maxPayloadSize = 1024 * 1024 // 1MB
    private static let maxStringLength = 1024
    private static let maxTimestampDrift: TimeInterval = 86400 // 24小時
    
    /// 驗證二進制數據完整性
    static func validateBinaryData(_ data: Data) throws {
        // 基本長度檢查
        guard data.count >= 8 else {
            throw ValidationError.corruptedData("數據太短，至少需要8字節")
        }
        
        // 最大負載限制檢查
        guard data.count <= maxPayloadSize else {
            throw ValidationError.invalidPayloadSize("數據包過大：\(data.count) > \(maxPayloadSize)")
        }
        
        // 檢查協議版本
        let version = data[0]
        guard version == PROTOCOL_VERSION else {
            throw ValidationError.invalidProtocolVersion(version)
        }
        
        // 檢查消息類型
        let messageType = data[1]
        let validTypes: [UInt8] = [
            MeshMessageType.signal.rawValue,
            MeshMessageType.chat.rawValue,
            MeshMessageType.game.rawValue,
            MeshMessageType.keyExchange.rawValue,
            MeshMessageType.system.rawValue
        ]
        
        guard validTypes.contains(messageType) else {
            throw ValidationError.invalidMessageType(messageType)
        }
        
        // 檢查長度字段一致性
        guard data.count >= 6 else {
            throw ValidationError.corruptedData("數據包缺少長度字段")
        }
        
        let declaredLength = UInt32(data[2]) << 24 | UInt32(data[3]) << 16 | UInt32(data[4]) << 8 | UInt32(data[5])
        guard declaredLength == data.count - 6 else {
            throw ValidationError.lengthMismatch("聲明長度 \(declaredLength) 與實際長度 \(data.count - 6) 不符")
        }
        
        // 檢查 checksum (簡單的異或校驗)
        let payloadData = data.dropFirst(6)
        let calculatedChecksum = payloadData.reduce(0) { $0 ^ $1 }
        let declaredChecksum = data[6]
        guard calculatedChecksum == declaredChecksum else {
            throw ValidationError.checksumMismatch("校驗和不匹配")
        }
        
        // 檢查保留字段（第7字節應為0）
        guard data[7] == 0 else {
            throw ValidationError.invalidReservedField("保留字段必須為0")
        }
        
        // 根據消息類型進行具體驗證
        switch MeshMessageType(rawValue: messageType) {
        case .signal:
            try validateSignalData(data)
        case .chat:
            try validateChatData(data)
        case .game:
            try validateGameData(data)
        case .keyExchange:
            try validateKeyExchangeData(data)
        case .system:
            try validateSystemData(data)
        default:
            throw ValidationError.invalidMessageType(messageType)
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