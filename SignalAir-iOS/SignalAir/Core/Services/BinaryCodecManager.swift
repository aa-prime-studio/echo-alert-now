import Foundation

/// 二進制編碼解碼管理器 - 消除重複的編碼/解碼邏輯
@MainActor
class BinaryCodecManager {
    
    // MARK: - Singleton
    static let shared = BinaryCodecManager()
    private init() {}
    
    // MARK: - 編碼方法
    
    /// 編碼字符串到二進制數據（帶長度前綴）
    /// - Parameter string: 要編碼的字符串
    /// - Returns: 編碼後的二進制數據
    func encodeString(_ string: String) -> Data {
        let data = string.data(using: .utf8) ?? Data()
        let safeLength = min(data.count, 255)
        
        var result = Data()
        result.append(UInt8(safeLength))
        result.append(data.prefix(safeLength))
        
        return result
    }
    
    /// 編碼玩家ID
    /// - Parameter playerID: 玩家ID
    /// - Returns: 編碼後的數據
    func encodePlayerID(_ playerID: String) -> Data {
        return encodeString(playerID)
    }
    
    /// 編碼玩家名稱
    /// - Parameter playerName: 玩家名稱
    /// - Returns: 編碼後的數據
    func encodePlayerName(_ playerName: String) -> Data {
        return encodeString(playerName)
    }
    
    /// 編碼房間ID
    /// - Parameter roomID: 房間ID
    /// - Returns: 編碼後的數據
    func encodeRoomID(_ roomID: String) -> Data {
        return encodeString(roomID)
    }
    
    /// 編碼主機ID
    /// - Parameter hostID: 主機ID
    /// - Returns: 編碼後的數據
    func encodeHostID(_ hostID: String) -> Data {
        return encodeString(hostID)
    }
    
    /// 編碼發送者名稱
    /// - Parameter senderName: 發送者名稱
    /// - Returns: 編碼後的數據
    func encodeSenderName(_ senderName: String) -> Data {
        return encodeString(senderName)
    }
    
    /// 編碼遊戲訊息類型
    /// - Parameter messageType: 遊戲訊息類型
    /// - Returns: 編碼後的數據
    func encodeGameMessageType(_ messageType: String) -> Data {
        return encodeString(messageType)
    }
    
    /// 編碼聊天訊息內容
    /// - Parameter message: 聊天訊息內容
    /// - Returns: 編碼後的數據
    func encodeChatMessage(_ message: String) -> Data {
        return encodeString(message)
    }
    
    /// 編碼 UInt16 到二進制（小端序）
    /// - Parameter value: UInt16 值
    /// - Returns: 編碼後的數據
    func encodeUInt16(_ value: UInt16) -> Data {
        return withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
    
    /// 編碼 Int32 到二進制（小端序）
    /// - Parameter value: Int32 值
    /// - Returns: 編碼後的數據
    func encodeInt32(_ value: Int32) -> Data {
        return withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
    
    /// 編碼數據長度並附加數據
    /// - Parameter data: 要編碼的數據
    /// - Returns: 帶長度前綴的編碼數據
    func encodeDataWithLength(_ data: Data) -> Data {
        let dataLength = UInt16(data.count)
        var result = Data()
        result.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        result.append(data)
        return result
    }
    
    // MARK: - 解碼方法
    
    /// 解碼結果結構
    struct DecodeResult<T> {
        let value: T
        let bytesConsumed: Int
    }
    
    /// 從數據中解碼字符串（帶長度前綴）
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果，包含字符串和消耗的字節數
    func decodeString(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        guard offset < data.count else { return nil }
        
        let length = Int(data[offset])
        let newOffset = offset + 1
        
        guard newOffset + length <= data.count else { return nil }
        
        let subdata = data.subdata(in: newOffset..<newOffset + length)
        guard let string = String(data: subdata, encoding: .utf8) else { return nil }
        
        return DecodeResult(value: string, bytesConsumed: 1 + length)
    }
    
    /// 解碼玩家ID
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodePlayerID(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼玩家名稱
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodePlayerName(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼房間ID
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeRoomID(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼主機ID
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeHostID(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼發送者名稱
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeSenderName(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼遊戲訊息類型
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeGameMessageType(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼聊天訊息內容
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeChatMessage(from data: Data, offset: Int = 0) -> DecodeResult<String>? {
        return decodeString(from: data, offset: offset)
    }
    
    /// 解碼 UInt16（小端序）
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeUInt16(from data: Data, offset: Int = 0) -> DecodeResult<UInt16>? {
        guard offset + 2 <= data.count else { return nil }
        
        let subdata = data.subdata(in: offset..<offset + 2)
        let value = subdata.withUnsafeBytes { $0.load(as: UInt16.self) }.littleEndian
        
        return DecodeResult(value: value, bytesConsumed: 2)
    }
    
    /// 解碼 Int32（小端序）
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeInt32(from data: Data, offset: Int = 0) -> DecodeResult<Int32>? {
        guard offset + 4 <= data.count else { return nil }
        
        let subdata = data.subdata(in: offset..<offset + 4)
        let value = subdata.withUnsafeBytes { $0.load(as: Int32.self) }.littleEndian
        
        return DecodeResult(value: value, bytesConsumed: 4)
    }
    
    /// 解碼帶長度前綴的數據
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果
    func decodeDataWithLength(from data: Data, offset: Int = 0) -> DecodeResult<Data>? {
        guard let lengthResult = decodeUInt16(from: data, offset: offset) else { return nil }
        
        let dataOffset = offset + lengthResult.bytesConsumed
        let length = Int(lengthResult.value)
        
        guard dataOffset + length <= data.count else { return nil }
        
        let subdata = data.subdata(in: dataOffset..<dataOffset + length)
        
        return DecodeResult(value: subdata, bytesConsumed: lengthResult.bytesConsumed + length)
    }
    
    // MARK: - 高級編碼方法
    
    /// 編碼玩家信息
    /// - Parameters:
    ///   - playerID: 玩家ID
    ///   - playerName: 玩家名稱
    /// - Returns: 編碼後的數據
    func encodePlayerInfo(playerID: String, playerName: String) -> Data {
        var result = Data()
        result.append(encodePlayerID(playerID))
        result.append(encodePlayerName(playerName))
        return result
    }
    
    /// 編碼房間信息
    /// - Parameters:
    ///   - roomID: 房間ID
    ///   - hostID: 主機ID
    /// - Returns: 編碼後的數據
    func encodeRoomInfo(roomID: String, hostID: String) -> Data {
        var result = Data()
        result.append(encodeRoomID(roomID))
        result.append(encodeHostID(hostID))
        return result
    }
    
    /// 編碼遊戲訊息
    /// - Parameters:
    ///   - messageType: 訊息類型
    ///   - roomID: 房間ID
    ///   - senderName: 發送者名稱
    ///   - data: 附加數據
    /// - Returns: 編碼後的完整遊戲訊息
    func encodeGameMessage(messageType: String, roomID: String, senderName: String, data: Data = Data()) -> Data {
        var result = Data()
        result.append(encodeGameMessageType(messageType))
        result.append(encodeRoomID(roomID))
        result.append(encodeSenderName(senderName))
        result.append(encodeDataWithLength(data))
        return result
    }
    
    /// 編碼聊天訊息
    /// - Parameters:
    ///   - message: 聊天內容
    ///   - senderName: 發送者名稱
    /// - Returns: 編碼後的聊天訊息
    func encodeChatMessageFull(message: String, senderName: String) -> Data {
        var result = Data()
        result.append(encodeChatMessage(message))
        result.append(encodeSenderName(senderName))
        return result
    }
    
    // MARK: - 高級解碼方法
    
    /// 解碼玩家信息
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果，包含玩家ID和名稱
    func decodePlayerInfo(from data: Data, offset: Int = 0) -> DecodeResult<(playerID: String, playerName: String)>? {
        var currentOffset = offset
        
        guard let playerIDResult = decodePlayerID(from: data, offset: currentOffset) else { return nil }
        currentOffset += playerIDResult.bytesConsumed
        
        guard let playerNameResult = decodePlayerName(from: data, offset: currentOffset) else { return nil }
        currentOffset += playerNameResult.bytesConsumed
        
        let totalBytesConsumed = currentOffset - offset
        return DecodeResult(
            value: (playerID: playerIDResult.value, playerName: playerNameResult.value),
            bytesConsumed: totalBytesConsumed
        )
    }
    
    /// 解碼房間信息
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果，包含房間ID和主機ID
    func decodeRoomInfo(from data: Data, offset: Int = 0) -> DecodeResult<(roomID: String, hostID: String)>? {
        var currentOffset = offset
        
        guard let roomIDResult = decodeRoomID(from: data, offset: currentOffset) else { return nil }
        currentOffset += roomIDResult.bytesConsumed
        
        guard let hostIDResult = decodeHostID(from: data, offset: currentOffset) else { return nil }
        currentOffset += hostIDResult.bytesConsumed
        
        let totalBytesConsumed = currentOffset - offset
        return DecodeResult(
            value: (roomID: roomIDResult.value, hostID: hostIDResult.value),
            bytesConsumed: totalBytesConsumed
        )
    }
    
    /// 解碼完整遊戲訊息
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果，包含訊息類型、房間ID、發送者名稱和附加數據
    func decodeGameMessage(from data: Data, offset: Int = 0) -> DecodeResult<(messageType: String, roomID: String, senderName: String, data: Data)>? {
        var currentOffset = offset
        
        guard let messageTypeResult = decodeGameMessageType(from: data, offset: currentOffset) else { return nil }
        currentOffset += messageTypeResult.bytesConsumed
        
        guard let roomIDResult = decodeRoomID(from: data, offset: currentOffset) else { return nil }
        currentOffset += roomIDResult.bytesConsumed
        
        guard let senderNameResult = decodeSenderName(from: data, offset: currentOffset) else { return nil }
        currentOffset += senderNameResult.bytesConsumed
        
        guard let dataResult = decodeDataWithLength(from: data, offset: currentOffset) else { return nil }
        currentOffset += dataResult.bytesConsumed
        
        let totalBytesConsumed = currentOffset - offset
        return DecodeResult(
            value: (
                messageType: messageTypeResult.value,
                roomID: roomIDResult.value,
                senderName: senderNameResult.value,
                data: dataResult.value
            ),
            bytesConsumed: totalBytesConsumed
        )
    }
    
    /// 解碼完整聊天訊息
    /// - Parameters:
    ///   - data: 二進制數據
    ///   - offset: 起始偏移量
    /// - Returns: 解碼結果，包含聊天內容和發送者名稱
    func decodeChatMessageFull(from data: Data, offset: Int = 0) -> DecodeResult<(message: String, senderName: String)>? {
        var currentOffset = offset
        
        guard let messageResult = decodeChatMessage(from: data, offset: currentOffset) else { return nil }
        currentOffset += messageResult.bytesConsumed
        
        guard let senderNameResult = decodeSenderName(from: data, offset: currentOffset) else { return nil }
        currentOffset += senderNameResult.bytesConsumed
        
        let totalBytesConsumed = currentOffset - offset
        return DecodeResult(
            value: (message: messageResult.value, senderName: senderNameResult.value),
            bytesConsumed: totalBytesConsumed
        )
    }
    
    // MARK: - 工具方法
    
    /// 驗證數據長度是否安全
    /// - Parameter length: 要驗證的長度
    /// - Returns: 安全的長度（最大255）
    func safeBoundary(_ length: Int) -> Int {
        return min(max(0, length), 255)
    }
    
    /// 驗證數值是否在安全範圍內
    /// - Parameter value: 要驗證的數值
    /// - Returns: 安全範圍內的數值
    func safeBoundary(_ value: Int) -> Int {
        return min(max(0, value), 255)
    }
}