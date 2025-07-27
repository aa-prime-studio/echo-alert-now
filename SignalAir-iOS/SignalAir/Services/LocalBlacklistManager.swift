import Foundation
import SwiftUI
import Compression

// MARK: - 本地黑名單管理器
/// 斷網環境下的本地用戶封禁系統 - 使用高性能二進制存儲
class LocalBlacklistManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var blacklistedUsers: [BlacklistedUser] = []
    
    // MARK: - Configuration
    private let userDefaultsKey = "local_blacklist_binary"
    private let legacyKey = "local_blacklist" // 兼容舊的JSON格式
    private let maxBlacklistSize = 1000 // 防止過度膨脹
    private let useCompression = true // 啟用壓縮以節省存儲空間
    
    // MARK: - Initialization
    init() {
        loadBlacklist()
        print("📵 LocalBlacklistManager: 高性能二進制黑名單系統已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 添加用戶到黑名單
    func addToBlacklist(deviceName: String, deviceUUID: String? = nil) {
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        
        // 檢查是否已存在
        if isBlacklisted(deviceName: normalizedName) {
            print("⚠️ 用戶已在黑名單中: \(normalizedName)")
            return
        }
        
        let blacklistedUser = BlacklistedUser(
            deviceName: normalizedName,
            deviceUUID: deviceUUID,
            blockedAt: Date()
        )
        
        blacklistedUsers.append(blacklistedUser)
        saveBlacklist()
        
        print("🚫 已添加到黑名單: \(normalizedName)")
    }
    
    /// 從黑名單移除用戶
    func removeFromBlacklist(userId: String) {
        if let index = blacklistedUsers.firstIndex(where: { $0.id.uuidString == userId }) {
            let removedUser = blacklistedUsers.remove(at: index)
            saveBlacklist()
            print("✅ 已從黑名單移除: \(removedUser.deviceName)")
        }
    }
    
    /// 檢查用戶是否在黑名單中（根據暱稱）
    func isBlacklisted(deviceName: String) -> Bool {
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        return blacklistedUsers.contains { user in
            user.deviceName == normalizedName
        }
    }
    
    /// 檢查用戶是否在黑名單中（根據設備UUID）
    func isBlacklisted(deviceUUID: String) -> Bool {
        return blacklistedUsers.contains { user in
            user.deviceUUID == deviceUUID
        }
    }
    
    /// 獲取黑名單統計
    func getBlacklistStats() -> BlacklistStats {
        return BlacklistStats(
            totalBlocked: blacklistedUsers.count,
            blockedToday: blacklistedUsers.filter { Calendar.current.isDateInToday($0.blockedAt) }.count,
            oldestBlock: blacklistedUsers.map { $0.blockedAt }.min()
        )
    }
    
    /// 清空黑名單
    func clearBlacklist() {
        blacklistedUsers.removeAll()
        saveBlacklist()
        print("🧹 黑名單已清空")
    }
    
    // MARK: - Private Methods
    
    /// 從本地存儲載入黑名單
    private func loadBlacklist() {
        // 首先嘗試載入二進制格式
        if let binaryData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                if useCompression {
                    blacklistedUsers = try BlacklistBinaryProtocol.decodeCompressed(binaryData)
                } else {
                    blacklistedUsers = try BlacklistBinaryProtocol.decode(binaryData)
                }
                print("📂 已載入 \(blacklistedUsers.count) 個黑名單用戶 (二進制格式)")
                return
            } catch {
                print("⚠️ 二進制格式載入失敗: \(error)，嘗試載入舊格式")
            }
        }
        
        // 降級到舊的JSON格式（遷移用）
        if let legacyData = UserDefaults.standard.data(forKey: legacyKey) {
            do {
                let decoded = try JSONDecoder().decode([BlacklistedUser].self, from: legacyData)
                blacklistedUsers = decoded
                print("📂 已載入 \(blacklistedUsers.count) 個黑名單用戶 (JSON格式，將轉換)")
                
                // 立即轉換為二進制格式並保存
                saveBlacklist()
                
                // 清理舊格式數據
                UserDefaults.standard.removeObject(forKey: legacyKey)
                print("🔄 已將JSON格式遷移到二進制格式")
                
            } catch {
                print("❌ JSON格式載入失敗: \(error)")
            }
        } else {
            print("📂 未找到本地黑名單數據，使用空列表")
        }
    }
    
    /// 保存黑名單到本地存儲（二進制格式）
    private func saveBlacklist() {
        // 限制黑名單大小
        if blacklistedUsers.count > maxBlacklistSize {
            blacklistedUsers = Array(blacklistedUsers.suffix(maxBlacklistSize))
        }
        
        do {
            let startTime = Date()
            
            let encodedData: Data
            if useCompression {
                encodedData = try BlacklistBinaryProtocol.encodeCompressed(blacklistedUsers)
            } else {
                encodedData = try BlacklistBinaryProtocol.encode(blacklistedUsers)
            }
            
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
            
            let duration = Date().timeIntervalSince(startTime)
            let compressionInfo = useCompression ? " (壓縮)" : ""
            print("💾 黑名單已保存: \(blacklistedUsers.count) 個用戶, \(encodedData.count) bytes\(compressionInfo), 耗時 \(String(format: "%.2f", duration * 1000))ms")
            
        } catch {
            print("❌ 保存黑名單失敗: \(error)")
        }
    }
    
    // MARK: - 性能統計
    
    /// 獲取存儲性能統計
    func getStorageStats() -> BlacklistStorageStats {
        let binaryData = UserDefaults.standard.data(forKey: userDefaultsKey)
        return BlacklistStorageStats(
            userCount: blacklistedUsers.count,
            binarySize: binaryData?.count ?? 0,
            compressionEnabled: useCompression,
            lastSaved: UserDefaults.standard.object(forKey: "\(userDefaultsKey)_timestamp") as? Date
        )
    }
}

// MARK: - 數據模型

/// 黑名單用戶（保持JSON兼容性用於遷移）
struct BlacklistedUser: Codable, Identifiable {
    let id: UUID
    let deviceName: String
    let deviceUUID: String?
    let blockedAt: Date
    
    init(deviceName: String, deviceUUID: String? = nil, blockedAt: Date) {
        self.id = UUID()
        self.deviceName = deviceName
        self.deviceUUID = deviceUUID
        self.blockedAt = blockedAt
    }
}

/// 黑名單統計
struct BlacklistStats {
    let totalBlocked: Int
    let blockedToday: Int
    let oldestBlock: Date?
}

/// 黑名單存儲統計
struct BlacklistStorageStats {
    let userCount: Int
    let binarySize: Int
    let compressionEnabled: Bool
    let lastSaved: Date?
    
    var compressionRatio: Double? {
        // 估算壓縮比例（基於典型的黑名單用戶數據大小）
        guard compressionEnabled, userCount > 0 else { return nil }
        
        let estimatedUncompressedSize = userCount * 150 // 每個用戶大約150字節
        return binarySize > 0 ? Double(binarySize) / Double(estimatedUncompressedSize) : nil
    }
    
    var averageBytesPerUser: Double {
        return userCount > 0 ? Double(binarySize) / Double(userCount) : 0
    }
}

// MARK: - 擴展現有的 NicknameFormatter
extension NicknameFormatter {
    /// 檢查暱稱是否被本地封禁
    static func isLocallyBlacklisted(_ nickname: String) -> Bool {
        // 這個方法會在整合時實現
        return false
    }
}

// MARK: - 黑名單二進制協議
// 高性能的黑名單數據編解碼，取代JSON格式

enum BlacklistBinaryProtocol {
    
    // MARK: - 協議常數
    private static let PROTOCOL_VERSION: UInt8 = 0x01
    private static let MAGIC_HEADER: UInt32 = 0x424C4B4C // "BLKL"
    
    // MARK: - 編碼方法
    
    /// 將黑名單用戶數組編碼為二進制數據
    static func encode(_ blacklistedUsers: [BlacklistedUser]) throws -> Data {
        var data = Data()
        
        // 1. 魔法頭部 (4 bytes)
        data.append(contentsOf: withUnsafeBytes(of: MAGIC_HEADER.bigEndian) { Data($0) })
        
        // 2. 協議版本 (1 byte)
        data.append(PROTOCOL_VERSION)
        
        // 3. 用戶數量 (4 bytes)
        let userCount = UInt32(blacklistedUsers.count)
        data.append(contentsOf: withUnsafeBytes(of: userCount.bigEndian) { Data($0) })
        
        // 4. 編碼每個用戶
        for user in blacklistedUsers {
            let userData = try encodeUser(user)
            data.append(userData)
        }
        
        return data
    }
    
    /// 編碼單個黑名單用戶
    private static func encodeUser(_ user: BlacklistedUser) throws -> Data {
        var data = Data()
        
        // 1. UUID (16 bytes)
        let uuidBytes = user.id.uuid
        data.append(contentsOf: [
            uuidBytes.0, uuidBytes.1, uuidBytes.2, uuidBytes.3,
            uuidBytes.4, uuidBytes.5, uuidBytes.6, uuidBytes.7,
            uuidBytes.8, uuidBytes.9, uuidBytes.10, uuidBytes.11,
            uuidBytes.12, uuidBytes.13, uuidBytes.14, uuidBytes.15
        ])
        
        // 2. 設備名稱長度 + 內容
        let deviceNameData = user.deviceName.data(using: .utf8) ?? Data()
        let nameLength = UInt16(deviceNameData.count)
        data.append(contentsOf: withUnsafeBytes(of: nameLength.bigEndian) { Data($0) })
        data.append(deviceNameData)
        
        // 3. 設備UUID存在標識 + 內容
        if let deviceUUID = user.deviceUUID {
            data.append(0x01) // 存在標識
            let deviceUUIDData = deviceUUID.data(using: .utf8) ?? Data()
            let uuidLength = UInt16(deviceUUIDData.count)
            data.append(contentsOf: withUnsafeBytes(of: uuidLength.bigEndian) { Data($0) })
            data.append(deviceUUIDData)
        } else {
            data.append(0x00) // 不存在標識
        }
        
        // 4. 封禁時間戳 (8 bytes)
        let timestamp = user.blockedAt.timeIntervalSince1970
        let timestampBits = timestamp.bitPattern
        data.append(contentsOf: withUnsafeBytes(of: timestampBits.bigEndian) { Data($0) })
        
        return data
    }
    
    // MARK: - 解碼方法
    
    /// 從二進制數據解碼黑名單用戶數組
    static func decode(_ data: Data) throws -> [BlacklistedUser] {
        guard data.count >= 9 else { // 最小：4+1+4 bytes
            throw BlacklistProtocolError.invalidDataSize
        }
        
        var offset = 0
        
        // 1. 驗證魔法頭部
        let header = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard header == MAGIC_HEADER else {
            throw BlacklistProtocolError.invalidHeader
        }
        offset += 4
        
        // 2. 檢查協議版本
        let version = data[offset]
        guard version == PROTOCOL_VERSION else {
            throw BlacklistProtocolError.unsupportedVersion(version)
        }
        offset += 1
        
        // 3. 讀取用戶數量
        let userCount = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        offset += 4
        
        // 4. 解碼每個用戶
        var users: [BlacklistedUser] = []
        users.reserveCapacity(Int(userCount))
        
        for _ in 0..<userCount {
            let (user, bytesRead) = try decodeUser(data, from: offset)
            users.append(user)
            offset += bytesRead
        }
        
        return users
    }
    
    /// 解碼單個黑名單用戶
    private static func decodeUser(_ data: Data, from offset: Int) throws -> (BlacklistedUser, Int) {
        var currentOffset = offset
        
        // 檢查剩餘數據大小
        guard currentOffset + 16 <= data.count else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        // 1. 讀取UUID (16 bytes)
        let uuidData = data.subdata(in: currentOffset..<currentOffset+16)
        let uuid = UUID(uuid: (
            uuidData[0], uuidData[1], uuidData[2], uuidData[3],
            uuidData[4], uuidData[5], uuidData[6], uuidData[7],
            uuidData[8], uuidData[9], uuidData[10], uuidData[11],
            uuidData[12], uuidData[13], uuidData[14], uuidData[15]
        ))
        currentOffset += 16
        
        // 2. 讀取設備名稱
        guard currentOffset + 2 <= data.count else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        let nameLength = data.subdata(in: currentOffset..<currentOffset+2).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        currentOffset += 2
        
        guard currentOffset + Int(nameLength) <= data.count else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        let deviceNameData = data.subdata(in: currentOffset..<currentOffset+Int(nameLength))
        guard let deviceName = String(data: deviceNameData, encoding: .utf8) else {
            throw BlacklistProtocolError.invalidStringEncoding
        }
        currentOffset += Int(nameLength)
        
        // 3. 讀取設備UUID（可選）
        guard currentOffset + 1 <= data.count else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        let hasDeviceUUID = data[currentOffset] == 0x01
        currentOffset += 1
        
        var deviceUUID: String? = nil
        if hasDeviceUUID {
            guard currentOffset + 2 <= data.count else {
                throw BlacklistProtocolError.invalidDataSize
            }
            
            let uuidLength = data.subdata(in: currentOffset..<currentOffset+2).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
            currentOffset += 2
            
            guard currentOffset + Int(uuidLength) <= data.count else {
                throw BlacklistProtocolError.invalidDataSize
            }
            
            let deviceUUIDData = data.subdata(in: currentOffset..<currentOffset+Int(uuidLength))
            deviceUUID = String(data: deviceUUIDData, encoding: .utf8)
            currentOffset += Int(uuidLength)
        }
        
        // 4. 讀取封禁時間戳
        guard currentOffset + 8 <= data.count else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        let timestampBits = data.subdata(in: currentOffset..<currentOffset+8).withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        let timestamp = Double(bitPattern: timestampBits)
        let blockedAt = Date(timeIntervalSince1970: timestamp)
        currentOffset += 8
        
        // 創建用戶對象
        let user = BlacklistedUser(
            id: uuid,
            deviceName: deviceName,
            deviceUUID: deviceUUID,
            blockedAt: blockedAt
        )
        
        return (user, currentOffset - offset)
    }
    
    // MARK: - 壓縮支援
    
    /// 編碼並壓縮黑名單數據
    static func encodeCompressed(_ blacklistedUsers: [BlacklistedUser]) throws -> Data {
        let rawData = try encode(blacklistedUsers)
        
        // 使用內置 LZ4 壓縮
        let compressedData = try compressLZ4(rawData)
        
        // 添加壓縮標識頭部
        var result = Data()
        result.append(0x43) // 'C' for Compressed
        result.append(compressedData)
        
        return result
    }
    
    /// 解壓縮並解碼黑名單數據
    static func decodeCompressed(_ data: Data) throws -> [BlacklistedUser] {
        guard !data.isEmpty else {
            throw BlacklistProtocolError.invalidDataSize
        }
        
        // 檢查壓縮標識
        if data[0] == 0x43 { // 'C' for Compressed
            let compressedData = data.dropFirst()
            let decompressedData = try decompressLZ4(compressedData)
            return try decode(decompressedData)
        } else {
            // 未壓縮數據
            return try decode(data)
        }
    }
    
    // MARK: - 內置壓縮方法
    
    /// LZ4 壓縮
    private static func compressLZ4(_ data: Data) throws -> Data {
        return try data.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, data.count,
                bytes.bindMemory(to: UInt8.self).baseAddress!, data.count,
                nil, COMPRESSION_LZ4
            )
            
            guard compressedSize > 0 else {
                throw BlacklistProtocolError.compressionFailed
            }
            
            return Data(bytes: buffer, count: compressedSize)
        }
    }
    
    /// LZ4 解壓縮
    private static func decompressLZ4(_ data: Data) throws -> Data {
        let bufferSize = data.count * 4 // 預估 4x 解壓縮比例
        
        return try data.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                buffer, bufferSize,
                bytes.bindMemory(to: UInt8.self).baseAddress!, data.count,
                nil, COMPRESSION_LZ4
            )
            
            guard decompressedSize > 0 else {
                throw BlacklistProtocolError.decompressionFailed
            }
            
            return Data(bytes: buffer, count: decompressedSize)
        }
    }
}

// MARK: - 錯誤類型

enum BlacklistProtocolError: Error, LocalizedError {
    case invalidDataSize
    case invalidHeader
    case unsupportedVersion(UInt8)
    case invalidStringEncoding
    case compressionFailed
    case decompressionFailed
    case checksumMismatch
    
    var errorDescription: String? {
        switch self {
        case .invalidDataSize:
            return "黑名單數據大小無效"
        case .invalidHeader:
            return "黑名單數據頭部無效"
        case .unsupportedVersion(let version):
            return "不支援的協議版本: \(version)"
        case .invalidStringEncoding:
            return "字符串編碼無效"
        case .compressionFailed:
            return "壓縮失敗"
        case .decompressionFailed:
            return "解壓縮失敗"
        case .checksumMismatch:
            return "校驗和不匹配"
        }
    }
}

// MARK: - BlacklistedUser 擴展

extension BlacklistedUser {
    /// 使用指定的UUID創建用戶
    init(id: UUID, deviceName: String, deviceUUID: String? = nil, blockedAt: Date) {
        self.id = id
        self.deviceName = deviceName
        self.deviceUUID = deviceUUID
        self.blockedAt = blockedAt
    }
}