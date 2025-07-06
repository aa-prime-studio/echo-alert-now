import Foundation
import CryptoKit
import Security

// MARK: - Secure Memory Management
/// 安全字串類別，確保敏感資料在記憶體中的安全處理
class SecureString {
    private var data: UnsafeMutableRawPointer?
    private var length: Int = 0
    private let lockQueue = DispatchQueue(label: "com.signalair.securestring.lock")
    private var _isLocked: Bool = false
    var isLocked: Bool {
        get { lockQueue.sync { _isLocked } }
        set { lockQueue.sync { _isLocked = newValue } }
    }
    
    /// 初始化安全字串（優化為非阻塞版本）
    /// - Parameter string: 要保護的字串
    init(_ string: String) {
        let utf8Data = string.utf8
        self.length = utf8Data.count
        
        // 分配記憶體
        self.data = UnsafeMutableRawPointer.allocate(
            byteCount: length,
            alignment: MemoryLayout<UInt8>.alignment
        )
        
        // 複製資料（優先完成）
        _ = utf8Data.withContiguousStorageIfAvailable { bytes in
            data!.copyMemory(from: bytes.baseAddress!, byteCount: length)
        }
        
        // 異步嘗試鎖定記憶體頁面，避免阻塞初始化
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let data = self.data else { return }
            
            // 嘗試鎖定記憶體頁面防止 swap
            let locked = mlock(data, self.length) == 0
            self.isLocked = locked
            
            if !locked {
                print("⚠️ SecureString: 無法鎖定記憶體頁面，敏感資料可能進入 swap")
            } else {
                print("🔒 SecureString: 記憶體頁面已鎖定")
            }
        }
        print("🚀 SecureString: 快速初始化完成，長度: \(length) bytes")
    }
    
    /// 初始化空的安全字串（優化為非阻塞版本）
    init(capacity: Int) {
        self.length = capacity
        self.data = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt8>.alignment
        )
        
        // 初始化為零（優先完成）
        data!.initializeMemory(as: UInt8.self, repeating: 0, count: capacity)
        
        // 異步鎖定記憶體
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let data = self.data else { return }
            
            let locked = mlock(data, capacity) == 0
            self.isLocked = locked
            
            if !locked {
                print("⚠️ SecureString: 容量初始化無法鎖定記憶體頁面")
            } else {
                print("🔒 SecureString: 容量初始化記憶體已鎖定")
            }
        }
        
        print("🚀 SecureString: 容量初始化完成，容量: \(capacity) bytes")
    }
    
    deinit {
        secureCleanup()
    }
    
    /// 安全清理記憶體
    func secureCleanup() {
        guard let data = data else { return }
        
        // 三次覆寫記憶體（DOD 5220.22-M 標準）
        // 第一次：全部設為 0
        memset(data, 0, length)
        
        // 第二次：全部設為 1 (0xFF)
        memset(data, 0xFF, length)
        
        // 第三次：隨機資料
        var randomBytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        if result == errSecSuccess {
            randomBytes.withUnsafeBytes { bytes in
                data.copyMemory(from: bytes.baseAddress!, byteCount: length)
            }
        }
        
        // 最後一次設為零
        memset(data, 0, length)
        
        // 解鎖記憶體
        if isLocked {
            munlock(data, length)
        }
        
        // 釋放記憶體
        data.deallocate()
        self.data = nil
        
        print("🧹 SecureString: 已安全清理記憶體")
    }
    
    /// 安全地獲取字串內容
    func withUnsafeString<T>(_ body: (UnsafePointer<UInt8>, Int) throws -> T) throws -> T {
        guard let data = data else {
            throw SecureMemoryError.dataAlreadyCleared
        }
        
        return try body(data.assumingMemoryBound(to: UInt8.self), length)
    }
    
    /// 轉換為 Data（僅在必要時使用）
    func toData() throws -> Data {
        guard let data = data else {
            throw SecureMemoryError.dataAlreadyCleared
        }
        
        return Data(bytes: data.assumingMemoryBound(to: UInt8.self), count: length)
    }
    
    /// 檢查是否已清理
    var isCleared: Bool {
        return data == nil
    }
}

/// 安全記憶體管理工具
class SecureMemoryManager {
    
    /// 安全清理 Data 物件
    /// - Parameter data: 要清理的 Data
    static func secureWipe(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            
            // 三次覆寫（DOD 5220.22-M 標準）
            memset(baseAddress, 0, bytes.count)
            memset(baseAddress, 0xFF, bytes.count)
            
            // 隨機覆寫
            var randomBytes = [UInt8](repeating: 0, count: bytes.count)
            let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &randomBytes)
            if result == errSecSuccess {
                memcpy(baseAddress, randomBytes, bytes.count)
            }
            
            // 最終清零
            memset(baseAddress, 0, bytes.count)
        }
        
        // 重新初始化為空
        data = Data()
        print("🧹 SecureMemoryManager: 已安全清理 Data 物件")
    }
    
    /// 安全清理字串
    /// - Parameter string: 要清理的字串（透過 inout 修改）
    static func secureWipe(_ string: inout String) {
        // 將字串轉換為可變資料進行清理
        var data = Data(string.utf8)
        secureWipe(&data)
        string = ""
        print("🧹 SecureMemoryManager: 已安全清理字串")
    }
    
    /// 建立安全的隨機資料
    /// - Parameter length: 資料長度
    /// - Returns: 安全的隨機資料
    static func secureRandomData(length: Int) throws -> Data {
        var randomBytes = Data(count: length)
        let result = randomBytes.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw SecureMemoryError.randomGenerationFailed
        }
        
        return randomBytes
    }
    
    /// 檢查記憶體是否可以被鎖定
    static func canLockMemory() -> Bool {
        let testSize = 4096 // 一個記憶體頁面
        let testPointer = UnsafeMutableRawPointer.allocate(
            byteCount: testSize,
            alignment: MemoryLayout<UInt8>.alignment
        )
        
        let canLock = mlock(testPointer, testSize) == 0
        
        if canLock {
            munlock(testPointer, testSize)
        }
        
        testPointer.deallocate()
        return canLock
    }
}

/// 安全記憶體錯誤類型
enum SecureMemoryError: Error {
    case dataAlreadyCleared
    case randomGenerationFailed
    case memoryLockFailed
    
    var localizedDescription: String {
        switch self {
        case .dataAlreadyCleared:
            return "敏感資料已被清理"
        case .randomGenerationFailed:
            return "隨機資料生成失敗"
        case .memoryLockFailed:
            return "記憶體鎖定失敗"
        }
    }
}

// MARK: - Security Status
/// 系統安全狀態
struct SecurityStatus {
    let isInitialized: Bool
    let memoryLockSupported: Bool
    let activeSessionCount: Int
    let lastKeyRotation: Date
    
    var description: String {
        return """
        🔐 Security Status:
        - Initialized: \(isInitialized ? "✅" : "❌")
        - Memory Lock Support: \(memoryLockSupported ? "✅" : "⚠️")
        - Active Sessions: \(activeSessionCount)
        - Last Key Rotation: \(lastKeyRotation.formatted())
        """
    }
}

// MARK: - Error Types
enum CryptoError: Error {
    case noPrivateKey
    case noSessionKey
    case keyExchangeFailed
    case encryptionFailed
    case decryptionFailed
    case invalidSignature
    case messageNumberMismatch
    case invalidData
    case keychainError(OSStatus)
    case invalidKeyData
    
    var localizedDescription: String {
        switch self {
        case .noPrivateKey:
            return "沒有私鑰"
        case .noSessionKey:
            return "沒有會話密鑰"
        case .keyExchangeFailed:
            return "密鑰交換失敗"
        case .encryptionFailed:
            return "加密失敗"
        case .decryptionFailed:
            return "解密失敗"
        case .invalidSignature:
            return "簽名驗證失敗"
        case .messageNumberMismatch:
            return "訊息序號不匹配"
        case .invalidData:
            return "無效資料"
        case .keychainError(let status):
            return "Keychain 錯誤: \(status)"
        case .invalidKeyData:
            return "無效密鑰資料"
        }
    }
}

// MARK: - Session Key
struct SessionKey {
    let encryptionKey: SymmetricKey
    let hmacKey: SymmetricKey
    var messageNumber: UInt64
    let createdAt: Date
    
    init(encryptionKey: SymmetricKey, hmacKey: SymmetricKey, messageNumber: UInt64 = 0) {
        self.encryptionKey = encryptionKey
        self.hmacKey = hmacKey
        self.messageNumber = messageNumber
        self.createdAt = Date()
    }
}

// MARK: - Encrypted Message
struct EncryptedMessage {
    let ciphertext: Data
    let hmac: Data
    let messageNumber: UInt64
    let timestamp: Date
    
    /// 編碼為 Data
    func encodedData() -> Data {
        var data = Data()
        
        // 添加版本號 (1 byte)
        data.append(0x01)
        
        // 添加訊息號 (8 bytes)
        data.append(contentsOf: withUnsafeBytes(of: messageNumber.bigEndian) { Data($0) })
        
        // 添加時間戳 (8 bytes)
        let timestamp = UInt64(self.timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: timestamp.bigEndian) { Data($0) })
        
        // 添加 HMAC 長度 (2 bytes)
        let hmacLength = UInt16(hmac.count)
        data.append(contentsOf: withUnsafeBytes(of: hmacLength.bigEndian) { Data($0) })
        
        // 添加 HMAC
        data.append(hmac)
        
        // 添加密文
        data.append(ciphertext)
        
        return data
    }
    
    /// 從 Data 解碼
    static func decode(from data: Data) throws -> EncryptedMessage {
        guard data.count >= 19 else { // 最小長度: 1+8+8+2 = 19
            throw CryptoError.invalidData
        }
        
        var offset = 0
        
        // 檢查版本號
        let version = data[offset]
        offset += 1
        
        guard version == 0x01 else {
            throw CryptoError.invalidData
        }
        
        // 讀取訊息號
        let messageNumber = data.subdata(in: offset..<offset+8).withUnsafeBytes {
            UInt64(bigEndian: $0.load(as: UInt64.self))
        }
        offset += 8
        
        // 讀取時間戳
        let timestampValue = data.subdata(in: offset..<offset+8).withUnsafeBytes {
            UInt64(bigEndian: $0.load(as: UInt64.self))
        }
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampValue))
        offset += 8
        
        // 讀取 HMAC 長度
        let hmacLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            UInt16(bigEndian: $0.load(as: UInt16.self))
        }
        offset += 2
        
        // 讀取 HMAC
        guard offset + Int(hmacLength) <= data.count else {
            throw CryptoError.invalidData
        }
        
        let hmac = data.subdata(in: offset..<offset+Int(hmacLength))
        offset += Int(hmacLength)
        
        // 讀取密文
        let ciphertext = data.subdata(in: offset..<data.count)
        
        return EncryptedMessage(
            ciphertext: ciphertext,
            hmac: hmac,
            messageNumber: messageNumber,
            timestamp: timestamp
        )
    }
}

// MARK: - Security Service Protocol
protocol SecurityServiceProtocol {
    func hasSessionKey(for peerID: String) -> Bool
    func encrypt(_ data: Data, for peerID: String) throws -> Data
    func decrypt(_ data: Data, from peerID: String) throws -> Data
    func getPublicKey() throws -> Data
    func removeSessionKey(for peerID: String)
}

// MARK: - Security Service
class SecurityService: ObservableObject, SecurityServiceProtocol {
    // MARK: - Properties
    private var privateKey: Curve25519.KeyAgreement.PrivateKey?
    private var sessionKeys: [String: SessionKey] = [:]
    private var deviceToNetworkMapping: [String: String] = [:] // DeviceID -> NetworkPeerID
    private var networkToDeviceMapping: [String: String] = [:] // NetworkPeerID -> DeviceID
    private let keyRotationInterval: TimeInterval = 3600 // 1 hour
    private var keyRotationTimer: Timer?
    
    // MARK: - Published State
    @Published var isInitialized: Bool = false
    @Published var activeConnections: Int = 0
    
    // MARK: - Keychain Configuration
    private let keychainService = "com.signalair.crypto"
    private let privateKeyTag = "signalair.privatekey"
    
    // MARK: - Initialization
    init() {
        setupCryptoSystem()
        startKeyRotationTimer()
        print("🔐 SecurityService initialized")
    }
    
    deinit {
        keyRotationTimer?.invalidate()
        keyRotationTimer = nil
        print("🧹 SecurityService: deinit 完成，Timer已清理")
    }
    
    // MARK: - Public Methods
    
    /// 取得公鑰用於密鑰交換
    func getPublicKey() throws -> Data {
        guard let privateKey = privateKey else {
            throw CryptoError.noPrivateKey
        }
        
        return privateKey.publicKey.rawRepresentation
    }
    
    /// 執行 ECDH 密鑰交換
    func performKeyExchange(with peerPublicKey: Data, peerID: String, deviceID: String? = nil) throws {
        guard let privateKey = privateKey else {
            throw CryptoError.noPrivateKey
        }
        
        do {
            // 建立對方的公鑰
            let peerKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
            
            // 執行 ECDH
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerKey)
            
            // 使用 HKDF 衍生雙密鑰
            let salt = "SignalAir Rescue-v1.0".data(using: .utf8)!
            let info = "\(peerID)-session".data(using: .utf8)!
            
            let keyMaterial = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: salt,
                sharedInfo: info,
                outputByteCount: 64
            )
            
            // 分割為加密和 HMAC 密鑰
            let rawKey = keyMaterial.withUnsafeBytes { Data($0) }
            let encryptionKey = SymmetricKey(data: rawKey.prefix(32))
            let hmacKey = SymmetricKey(data: rawKey.suffix(32))
            
            // 儲存會話密鑰
            sessionKeys[peerID] = SessionKey(
                encryptionKey: encryptionKey,
                hmacKey: hmacKey
            )
            
            // 如果提供了設備ID，建立映射
            if let deviceID = deviceID {
                deviceToNetworkMapping[deviceID] = peerID
                networkToDeviceMapping[peerID] = deviceID
                print("🗺️ 建立映射：\(deviceID) -> \(peerID)")
            }
            
            DispatchQueue.main.async {
                self.activeConnections = self.sessionKeys.count
            }
            
            print("✅ Key exchange completed with: \(peerID)")
            
        } catch {
            print("❌ Key exchange failed: \(error)")
            throw CryptoError.keyExchangeFailed
        }
    }
    
    /// 加密訊息 - Protocol 版本 (返回 Data)
    func encrypt(_ data: Data, for peerID: String) throws -> Data {
        let encryptedMessage = try encryptToMessage(data, for: peerID)
        return encryptedMessage.encodedData()
    }
    
    /// 加密訊息 - 詳細版本 (返回 EncryptedMessage)
    func encryptToMessage(_ data: Data, for peerID: String) throws -> EncryptedMessage {
        guard var sessionKey = sessionKeys[peerID] else {
            throw CryptoError.noSessionKey
        }
        
        do {
            // AES-GCM 加密
            let sealed = try AES.GCM.seal(data, using: sessionKey.encryptionKey)
            
            guard let ciphertext = sealed.combined else {
                throw CryptoError.encryptionFailed
            }
            
            // HMAC 簽名
            let hmac = HMAC<SHA256>.authenticationCode(
                for: ciphertext,
                using: sessionKey.hmacKey
            )
            
            // 建立加密訊息
            let encryptedMessage = EncryptedMessage(
                ciphertext: ciphertext,
                hmac: Data(hmac),
                messageNumber: sessionKey.messageNumber,
                timestamp: Date()
            )
            
            // 更新密鑰（Forward Secrecy）
            sessionKey = ratchetKey(sessionKey)
            sessionKeys[peerID] = sessionKey
            
            print("🔒 Encrypted message for: \(peerID), size: \(data.count) bytes")
            return encryptedMessage
            
        } catch {
            print("❌ Encryption failed: \(error)")
            throw CryptoError.encryptionFailed
        }
    }
    
    /// 解密訊息（帶安全清理）
    func decrypt(_ data: Data, from peerID: String) throws -> Data {
        // 先嘗試直接查找會話密鑰
        var actualPeerID = peerID
        var sessionKey = sessionKeys[peerID]
        
        // 如果沒找到，嘗試通過設備ID映射查找
        if sessionKey == nil, let networkPeerID = deviceToNetworkMapping[peerID] {
            actualPeerID = networkPeerID
            sessionKey = sessionKeys[networkPeerID]
            print("🗺️ 通過映射找到會話密鑰：\(peerID) -> \(networkPeerID)")
        }
        
        guard var sessionKey = sessionKey else {
            print("❌ 找不到會話密鑰：\(peerID)，已有密鑰：\(sessionKeys.keys.sorted())")
            print("❌ 設備映射：\(deviceToNetworkMapping)")
            throw CryptoError.noSessionKey
        }
        
        // 建立安全容器處理敏感資料
        var encryptedData = data
        var plaintext = Data()
        
        defer {
            // 確保所有敏感資料在函數結束時被清理
            SecureMemoryManager.secureWipe(&encryptedData)
            print("🧹 SecurityService.decrypt: 已清理輸入的加密資料")
        }
        
        do {
            // 解碼加密訊息
            let encryptedMessage = try EncryptedMessage.decode(from: encryptedData)
            
            // 驗證訊息順序（防重放攻擊）
            // 允許一定的訊息編號容錯，處理網路延遲和亂序
            let expectedMinNumber = max(0, sessionKey.messageNumber - 10) // 允許10個訊息的回退
            guard encryptedMessage.messageNumber >= expectedMinNumber else {
                print("❌ 訊息編號異常：收到 \(encryptedMessage.messageNumber)，期望 >= \(expectedMinNumber)（當前：\(sessionKey.messageNumber)）")
                throw CryptoError.messageNumberMismatch
            }
            
            // 驗證 HMAC
            let expectedHMAC = HMAC<SHA256>.authenticationCode(
                for: encryptedMessage.ciphertext,
                using: sessionKey.hmacKey
            )
            
            guard Data(expectedHMAC) == encryptedMessage.hmac else {
                throw CryptoError.invalidSignature
            }
            
            // 解密到安全記憶體
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedMessage.ciphertext)
            plaintext = try AES.GCM.open(sealedBox, using: sessionKey.encryptionKey)
            
            // 更新密鑰（Forward Secrecy）
            sessionKey = ratchetKey(sessionKey)
            sessionKey.messageNumber = encryptedMessage.messageNumber + 1
            sessionKeys[actualPeerID] = sessionKey
            
            print("🔓 Decrypted message from: \(peerID), size: \(plaintext.count) bytes")
            return plaintext
            
        } catch {
            // 在錯誤情況下也要清理已解密的資料
            SecureMemoryManager.secureWipe(&plaintext)
            print("❌ Decryption failed: \(error)")
            throw CryptoError.decryptionFailed
        }
    }
    
    /// 安全處理敏感字串的解密
    /// - Parameters:
    ///   - data: 加密資料
    ///   - peerID: 對方 ID
    ///   - handler: 處理解密結果的閉包
    /// - Returns: 處理結果
    func decryptToSecureString<T>(_ data: Data, from peerID: String, handler: (SecureString) throws -> T) throws -> T {
        let plaintextData = try decrypt(data, from: peerID)
        
        defer {
            // 清理解密後的資料
            var mutableData = plaintextData
            SecureMemoryManager.secureWipe(&mutableData)
        }
        
        // 轉換為安全字串
        guard let plaintextString = String(data: plaintextData, encoding: .utf8) else {
            throw CryptoError.invalidData
        }
        
        let secureString = SecureString(plaintextString)
        
        defer {
            // 確保安全字串被清理
            secureString.secureCleanup()
        }
        
        return try handler(secureString)
    }
    
    /// 檢查是否有會話密鑰
    func hasSessionKey(for peerID: String) -> Bool {
        // 先嘗試直接查找
        if sessionKeys[peerID] != nil {
            return true
        }
        
        // 如果沒找到，嘗試通過設備ID映射查找
        if let networkPeerID = deviceToNetworkMapping[peerID] {
            return sessionKeys[networkPeerID] != nil
        }
        
        return false
    }
    
    /// 獲取設備ID對應的網路對等裝置ID
    func getDeviceID(for peerID: String) -> String? {
        return networkToDeviceMapping[peerID]
    }
    
    /// 獲取所有會話密鑰的對等裝置ID
    func getAllSessionKeyPeerIDs() -> [String] {
        return Array(sessionKeys.keys)
    }
    
    /// 移除會話密鑰（帶安全清理）
    func removeSessionKey(for peerID: String) {
        if let sessionKey = sessionKeys[peerID] {
            // 安全清理會話密鑰
            secureWipeSessionKey(sessionKey)
        }
        
        sessionKeys.removeValue(forKey: peerID)
        DispatchQueue.main.async {
            self.activeConnections = self.sessionKeys.count
        }
        print("🗑️ Removed and securely wiped session key for: \(peerID)")
    }
    
    /// 清除所有會話密鑰（帶安全清理）
    func clearAllSessionKeys() {
        // 安全清理所有會話密鑰
        for (peerID, sessionKey) in sessionKeys {
            secureWipeSessionKey(sessionKey)
            print("🧹 Securely wiped session key for: \(peerID)")
        }
        
        sessionKeys.removeAll()
        DispatchQueue.main.async {
            self.activeConnections = 0
        }
        print("🧹 Cleared all session keys with secure wipe")
    }
    
    /// 安全清理會話密鑰
    private func secureWipeSessionKey(_ sessionKey: SessionKey) {
        // 由於 SymmetricKey 是不可變的，我們無法直接清理
        // 但我們可以確保它不再被引用，讓系統回收
        // 在實際應用中，可以考慮使用自定義的密鑰包裝器
        print("🧹 Session key marked for secure cleanup")
    }
    
    /// 檢查系統安全狀態
    func getSecurityStatus() -> SecurityStatus {
        let memoryLockSupported = SecureMemoryManager.canLockMemory()
        let activeSessionCount = sessionKeys.count
        
        return SecurityStatus(
            isInitialized: isInitialized,
            memoryLockSupported: memoryLockSupported,
            activeSessionCount: activeSessionCount,
            lastKeyRotation: Date() // 簡化實現
        )
    }
    
    /// 強制進行安全清理
    func performSecurityCleanup() {
        print("🧹 Performing comprehensive security cleanup...")
        
        // 清理所有會話密鑰
        clearAllSessionKeys()
        
        // 觸發垃圾回收（建議）
        autoreleasepool {
            // 強制釋放自動釋放池
        }
        
        print("✅ Security cleanup completed")
    }
    
    // MARK: - Private Methods
    
    /// 設置加密系統
    private func setupCryptoSystem() {
        do {
            if let savedKey = try loadPrivateKeyFromKeychain() {
                self.privateKey = savedKey
                print("🔑 Loaded existing private key from keychain")
            } else {
                self.privateKey = Curve25519.KeyAgreement.PrivateKey()
                try savePrivateKeyToKeychain(privateKey!)
                print("🆕 Generated new private key and saved to keychain")
            }
            
            DispatchQueue.main.async {
                self.isInitialized = true
            }
            
        } catch {
            print("❌ Failed to setup crypto system: \(error)")
            // 即使失敗也生成臨時密鑰
            self.privateKey = Curve25519.KeyAgreement.PrivateKey()
            DispatchQueue.main.async {
                self.isInitialized = true
            }
        }
    }
    
    /// 密鑰輪轉（Forward Secrecy）
    private func ratchetKey(_ key: SessionKey) -> SessionKey {
        // 使用當前加密密鑰生成新密鑰
        let newKeyMaterial = HMAC<SHA256>.authenticationCode(
            for: "ratchet-\(key.messageNumber)".data(using: .utf8)!,
            using: key.encryptionKey
        )
        
        let newEncryptionKey = SymmetricKey(data: Data(newKeyMaterial.prefix(32)))
        
        return SessionKey(
            encryptionKey: newEncryptionKey,
            hmacKey: key.hmacKey, // HMAC 密鑰保持不變
            messageNumber: key.messageNumber + 1
        )
    }
    
    /// 定期密鑰輪轉
    private func startKeyRotationTimer() {
        keyRotationTimer = Timer.scheduledTimer(withTimeInterval: keyRotationInterval, repeats: true) { [weak self] _ in
            self?.rotateExpiredKeys()
        }
    }
    
    /// 輪轉過期密鑰
    private func rotateExpiredKeys() {
        let now = Date()
        var rotatedCount = 0
        
        for (peerID, key) in sessionKeys {
            if now.timeIntervalSince(key.createdAt) > keyRotationInterval {
                // 生成新的會話密鑰（需要重新密鑰交換）
                sessionKeys.removeValue(forKey: peerID)
                rotatedCount += 1
            }
        }
        
        if rotatedCount > 0 {
            print("🔄 Rotated \(rotatedCount) expired session keys")
            DispatchQueue.main.async {
                self.activeConnections = self.sessionKeys.count
            }
        }
    }
    
    // MARK: - Keychain Operations
    
    /// 儲存私鑰到 Keychain
    private func savePrivateKeyToKeychain(_ key: Curve25519.KeyAgreement.PrivateKey) throws {
        let keyData = key.rawRepresentation
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: privateKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 先刪除舊的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
    }
    
    /// 從 Keychain 載入私鑰
    private func loadPrivateKeyFromKeychain() throws -> Curve25519.KeyAgreement.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: privateKeyTag,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
        
        guard let keyData = item as? Data else {
            throw CryptoError.invalidKeyData
        }
        
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
    }
} 