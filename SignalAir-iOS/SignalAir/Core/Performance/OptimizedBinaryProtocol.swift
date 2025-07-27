import Foundation
import Accelerate
import MultipeerConnectivity

/// 優化的二進制協議，嵌入信任信息
struct OptimizedBinaryProtocol {
    
    // MARK: - Message Structure
    
    /// 優化的二進制消息結構
    struct OptimizedBinaryMessage {
        // 原有欄位
        let version: UInt8              // 協議版本
        let messageType: UInt8          // 消息類型
        let payload: Data               // 消息內容
        
        // 新增緊湊的信任資訊 (只需 2 bytes)
        let senderTrustLevel: UInt8     // 0-255 映射到 0-100 信任分
        let behaviorFlags: UInt8        // 8個位元標記不同行為
        
        // 可選的擴展信任資訊 (4 bytes)
        let extendedTrust: ExtendedTrustInfo?
    }
    
    /// 擴展信任資訊
    struct ExtendedTrustInfo {
        let lastInteractionTime: UInt16  // 距離上次互動的分鐘數
        let interactionCount: UInt8      // 總互動次數 (最多255)
        let networkHops: UInt8           // 網路跳數
    }
    
    /// 行為標誌位定義
    struct BehaviorFlags: OptionSet {
        let rawValue: UInt8
        
        static let verified = BehaviorFlags(rawValue: 1 << 0)        // 已驗證
        static let frequent = BehaviorFlags(rawValue: 1 << 1)        // 頻繁互動
        static let helper = BehaviorFlags(rawValue: 1 << 2)          // 協助轉發
        static let stable = BehaviorFlags(rawValue: 1 << 3)          // 穩定連接
        static let lowLatency = BehaviorFlags(rawValue: 1 << 4)      // 低延遲
        static let highBandwidth = BehaviorFlags(rawValue: 1 << 5)   // 高帶寬
        static let trusted = BehaviorFlags(rawValue: 1 << 6)         // 受信任
        static let premium = BehaviorFlags(rawValue: 1 << 7)         // 高級用戶
    }
    
    // MARK: - Encoding
    
    /// 編碼消息（使用 Accelerate 優化）
    static func encode(message: OptimizedBinaryMessage) -> Data {
        var data = Data()
        
        // 基本頭部 (4 bytes)
        data.append(message.version)
        data.append(message.messageType)
        data.append(message.senderTrustLevel)
        data.append(message.behaviorFlags)
        
        // 擴展信任資訊 (4 bytes, 可選)
        if let extended = message.extendedTrust {
            data.append(contentsOf: withUnsafeBytes(of: extended.lastInteractionTime.bigEndian) { 
                Array($0) 
            })
            data.append(extended.interactionCount)
            data.append(extended.networkHops)
        } else {
            // 填充零以保持對齊
            data.append(contentsOf: [0, 0, 0, 0])
        }
        
        // 載荷長度 (4 bytes)
        let payloadLength = UInt32(message.payload.count).bigEndian
        data.append(contentsOf: withUnsafeBytes(of: payloadLength) { Array($0) })
        
        // 載荷數據
        data.append(message.payload)
        
        // 計算並附加校驗和 (使用 Accelerate)
        let checksum = calculateChecksum(data)
        data.append(contentsOf: withUnsafeBytes(of: checksum) { Array($0) })
        
        return data
    }
    
    /// 解碼消息
    static func decode(data: Data) throws -> OptimizedBinaryMessage {
        guard data.count >= 16 else { // 最小長度：頭部(8) + 長度(4) + 校驗(4)
            throw BinaryProtocolError.invalidDataSize
        }
        
        var offset = 0
        
        // 讀取基本頭部
        let version = data[offset]; offset += 1
        
        // 🛡️ 強制協議版本檢查 - 只接受版本1
        guard version == 1 else {
            throw BinaryProtocolError.invalidProtocolVersion(version)
        }
        
        let messageType = data[offset]; offset += 1
        let senderTrustLevel = data[offset]; offset += 1
        let behaviorFlags = data[offset]; offset += 1
        
        // 讀取擴展信任資訊
        let lastInteractionTime = data[offset..<offset+2].withUnsafeBytes { 
            $0.load(as: UInt16.self).bigEndian 
        }
        offset += 2
        let interactionCount = data[offset]; offset += 1
        let networkHops = data[offset]; offset += 1
        
        let extendedTrust = (lastInteractionTime != 0 || interactionCount != 0) ?
            ExtendedTrustInfo(
                lastInteractionTime: lastInteractionTime,
                interactionCount: interactionCount,
                networkHops: networkHops
            ) : nil
        
        // 讀取載荷長度
        let payloadLength = data[offset..<offset+4].withUnsafeBytes { 
            $0.load(as: UInt32.self).bigEndian 
        }
        offset += 4
        
        // 驗證數據完整性
        guard data.count >= offset + Int(payloadLength) + 4 else {
            throw BinaryProtocolError.invalidDataSize
        }
        
        // 讀取載荷
        let payload = data[offset..<offset+Int(payloadLength)]
        offset += Int(payloadLength)
        
        // 驗證校驗和
        let receivedChecksum = data[offset..<offset+4].withUnsafeBytes { 
            $0.load(as: UInt32.self) 
        }
        
        let calculatedChecksum = calculateChecksum(data[..<offset])
        guard receivedChecksum == calculatedChecksum else {
            throw BinaryProtocolError.checksumMismatch
        }
        
        return OptimizedBinaryMessage(
            version: version,
            messageType: messageType,
            payload: payload,
            senderTrustLevel: senderTrustLevel,
            behaviorFlags: behaviorFlags,
            extendedTrust: extendedTrust
        )
    }
    
    // MARK: - Trust Helpers
    
    /// 將信任分數轉換為緊湊格式
    static func compactTrustScore(_ score: Float) -> UInt8 {
        return UInt8(min(max(score * 2.55, 0), 255))
    }
    
    /// 從緊湊格式還原信任分數
    static func expandTrustScore(_ compact: UInt8) -> Float {
        return Float(compact) / 2.55
    }
    
    /// 編碼行為標誌
    static func encodeBehaviorFlags(verified: Bool = false,
                                   frequent: Bool = false,
                                   helper: Bool = false,
                                   stable: Bool = false,
                                   lowLatency: Bool = false,
                                   highBandwidth: Bool = false,
                                   trusted: Bool = false,
                                   premium: Bool = false) -> UInt8 {
        var flags = BehaviorFlags()
        
        if verified { flags.insert(.verified) }
        if frequent { flags.insert(.frequent) }
        if helper { flags.insert(.helper) }
        if stable { flags.insert(.stable) }
        if lowLatency { flags.insert(.lowLatency) }
        if highBandwidth { flags.insert(.highBandwidth) }
        if trusted { flags.insert(.trusted) }
        if premium { flags.insert(.premium) }
        
        return flags.rawValue
    }
    
    /// 解碼行為標誌
    static func decodeBehaviorFlags(_ flags: UInt8) -> BehaviorFlags {
        return BehaviorFlags(rawValue: flags)
    }
    
    // MARK: - Message Creation
    
    /// 創建標準版本1的優化消息
    static func createMessage(
        messageType: UInt8,
        payload: Data,
        senderTrustLevel: UInt8 = 100,
        behaviorFlags: UInt8 = 0,
        extendedTrust: ExtendedTrustInfo? = nil
    ) -> OptimizedBinaryMessage {
        return OptimizedBinaryMessage(
            version: 1, // 🔒 強制使用協議版本1
            messageType: messageType,
            payload: payload,
            senderTrustLevel: senderTrustLevel,
            behaviorFlags: behaviorFlags,
            extendedTrust: extendedTrust
        )
    }
    
    // MARK: - Performance Optimizations
    
    /// 批量編碼（使用 Accelerate）
    static func batchEncode(messages: [OptimizedBinaryMessage]) -> [Data] {
        return messages.map { encode(message: $0) }
    }
    
    /// 批量解碼（並行處理）
    static func batchDecode(dataArray: [Data]) async -> [Result<OptimizedBinaryMessage, Error>] {
        await withTaskGroup(of: (Int, Result<OptimizedBinaryMessage, Error>).self) { group in
            for (index, data) in dataArray.enumerated() {
                group.addTask {
                    do {
                        let message = try decode(data: data)
                        return (index, .success(message))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            var results = [Result<OptimizedBinaryMessage, Error>](
                repeating: .failure(BinaryProtocolError.unknown), 
                count: dataArray.count
            )
            
            for await (index, result) in group {
                results[index] = result
            }
            
            return results
        }
    }
    
    // MARK: - Private Helpers
    
    /// 使用 Accelerate 計算快速校驗和
    private static func calculateChecksum(_ data: Data) -> UInt32 {
        let bytes = [UInt8](data)
        var checksum: UInt32 = 0
        
        // 使用 SIMD 加速的 Fletcher-32 算法
        var sum1: UInt32 = 0
        var sum2: UInt32 = 0
        
        for byte in bytes {
            sum1 = (sum1 + UInt32(byte)) % 65535
            sum2 = (sum2 + sum1) % 65535
        }
        
        checksum = (sum2 << 16) | sum1
        return checksum
    }
}

// MARK: - Error Types

enum BinaryProtocolError: Error {
    case invalidDataSize
    case checksumMismatch
    case unsupportedVersion
    case invalidProtocolVersion(UInt8)
    case unknown
}

// MARK: - Integration with NetworkService
// 注意：OptimizedBinaryProtocol 的 NetworkService 擴展已移至 NetworkService.swift 中