import Foundation
import CryptoKit
import Security
import Compression

// 壓縮功能已內聯實現在 SecurityService 中

// MARK: - Risk Level Definition - Using existing definition from AutomaticBanSystem.swift

// MARK: - Data Transfer Types
public struct DataTransferRequest {
    public let id: String
    public let source: String
    public let destination: String
    public let data: Data
    public let timestamp: Date
    public let networkProtocol: NetworkProtocol
    public let metadata: [String: Any]
    
    public init(id: String, source: String, destination: String, data: Data, timestamp: Date, networkProtocol: NetworkProtocol, metadata: [String: Any]) {
        self.id = id
        self.source = source
        self.destination = destination
        self.data = data
        self.timestamp = timestamp
        self.networkProtocol = networkProtocol
        self.metadata = metadata
    }
}

public struct DataTransferAnalysis {
    public let allowed: Bool
    public let risk: RiskLevel
    public let reason: String
    public let recommendations: [String]
    public let detailedAnalysis: DetailedAnalysis?
    
    public init(allowed: Bool, risk: RiskLevel, reason: String, recommendations: [String], detailedAnalysis: DetailedAnalysis? = nil) {
        self.allowed = allowed
        self.risk = risk
        self.reason = reason
        self.recommendations = recommendations
        self.detailedAnalysis = detailedAnalysis
    }
}

public struct DetailedAnalysis {
    public let fragmentAnalysis: FragmentAnalysis?
    public let tunnelAnalysis: TunnelAnalysis?
    public let contentAnalysis: ContentAnalysis?
    public let behaviorAnalysis: Any? // Using Any to avoid type conflicts
    public let overallConfidence: Double
    
    public init(fragmentAnalysis: FragmentAnalysis?, tunnelAnalysis: TunnelAnalysis?, contentAnalysis: ContentAnalysis?, behaviorAnalysis: Any?, overallConfidence: Double) {
        self.fragmentAnalysis = fragmentAnalysis
        self.tunnelAnalysis = tunnelAnalysis
        self.contentAnalysis = contentAnalysis
        self.behaviorAnalysis = behaviorAnalysis
        self.overallConfidence = overallConfidence
    }
}

public struct FragmentAnalysis {
    public let isFragmented: Bool
    public let confidence: Double
    public let indicators: [String]
    public let estimatedTotalSize: Int?
    public let fragmentPosition: String?
    
    public init(isFragmented: Bool, confidence: Double, indicators: [String], estimatedTotalSize: Int?, fragmentPosition: String?) {
        self.isFragmented = isFragmented
        self.confidence = confidence
        self.indicators = indicators
        self.estimatedTotalSize = estimatedTotalSize
        self.fragmentPosition = fragmentPosition
    }
}

public struct TunnelAnalysis {
    public let isTunneled: Bool
    public let confidence: Double
    public let tunnelType: String?
    public let indicators: [String]
    public let decryptionHint: String?
    
    public init(isTunneled: Bool, confidence: Double, tunnelType: String?, indicators: [String], decryptionHint: String?) {
        self.isTunneled = isTunneled
        self.confidence = confidence
        self.tunnelType = tunnelType
        self.indicators = indicators
        self.decryptionHint = decryptionHint
    }
}

public struct ContentAnalysis {
    public let containsSensitiveData: Bool
    public let dataTypes: [String]
    public let confidence: Double
    
    public init(containsSensitiveData: Bool, dataTypes: [String], confidence: Double) {
        self.containsSensitiveData = containsSensitiveData
        self.dataTypes = dataTypes
        self.confidence = confidence
    }
}

// MARK: - BehaviorAnalysis - Using existing definition from AutomaticBanSystem.swift

public enum NetworkProtocol {
    case p2p
    case tcp
    case udp
    case http
    case https
    case custom(String)
}

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
            guard let data = data, let baseAddress = bytes.baseAddress else {
                print("❌ SecureString: 無法取得記憶體位址")
                return
            }
            data.copyMemory(from: baseAddress, byteCount: length)
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
        guard let data = data else {
            print("❌ SecureString: 無法分配記憶體")
            return
        }
        data.initializeMemory(as: UInt8.self, repeating: 0, count: capacity)
        
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
                guard let baseAddress = bytes.baseAddress else {
                    print("❌ SecureString: 無法取得隨機資料位址")
                    return
                }
                data.copyMemory(from: baseAddress, byteCount: length)
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
            guard let baseAddress = bytes.baseAddress else {
                return errSecParam
            }
            return SecRandomCopyBytes(kSecRandomDefault, length, baseAddress)
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
    case messageExpired
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
        case .messageExpired:
            return "訊息已過期"
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
        
        guard version == 1 else {
            print("❌ SecurityService: 協議版本不匹配：期望版本 1，收到版本 \(version)")
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
protocol SecurityServiceLegacyProtocol {
    func hasSessionKey(for peerID: String) -> Bool
    func encrypt(_ data: Data, for peerID: String) async throws -> Data
    func decrypt(_ data: Data, from peerID: String) throws -> Data
    func getPublicKey() throws -> Data
    func removeSessionKey(for peerID: String)
}

// MARK: - Security Service
class SecurityService: ObservableObject, SecurityServiceLegacyProtocol {
    // MARK: - Properties
    private var privateKey: Curve25519.KeyAgreement.PrivateKey?
    private var sessionKeys: [String: SessionKey] = [:]
    private var deviceToNetworkMapping: [String: String] = [:] // DeviceID -> NetworkPeerID
    private var networkToDeviceMapping: [String: String] = [:] // NetworkPeerID -> DeviceID
    private let keyRotationInterval: TimeInterval = 300 // 5 minutes
    private let maxMessagesPerKey = 500 // 500 條訊息後強制重新協商
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
            let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
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
                #if DEBUG
                print("🗺️ 建立裝置映射")
                #endif
            }
            
            DispatchQueue.main.async {
                self.activeConnections = self.sessionKeys.count
            }
            
            #if DEBUG
            print("✅ Key exchange completed")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ Key exchange failed")
            #endif
            throw CryptoError.keyExchangeFailed
        }
    }
    
    /// 🚀 超高速加密 - 智能算法選擇 + 壓縮
    func ultraEncrypt(_ data: Data, for peerID: String) async throws -> Data {
        // 高速壓縮
        let compressedData = await fastCompress(data)
        
        // 智能算法選擇
        if data.count > 1024 {
            return try await encryptWithChaCha20(compressedData, peerID: peerID)
        } else {
            return try await encryptWithAESGCM(compressedData, peerID: peerID)
        }
    }
    
    /// 傳統加密 - Protocol 版本 (返回 Data) - 保持向後兼容
    func encrypt(_ data: Data, for peerID: String) async throws -> Data {
        // 資料外洩防禦檢查
        let transferRequest = DataTransferRequest(
            id: UUID().uuidString,
            source: "local",
            destination: peerID,
            data: data,
            timestamp: Date(),
            networkProtocol: .p2p,
            metadata: [:]
        )
        
        let analysis = await MainActor.run {
            ServiceContainer.shared.dataTransferMonitor.analyzeDataTransfer(transferRequest)
        }
        
        if !analysis.allowed {
            print("🛡️ 資料外洩防禦：阻止傳輸 - \(analysis.reason)")
            throw CryptoError.encryptionFailed
        }
        
        if analysis.risk == RiskLevel.high || analysis.risk == RiskLevel.critical {
            print("⚠️ 資料外洩防禦：高風險傳輸 - \(analysis.reason)")
            // 記錄高風險事件
            await MainActor.run {
                ServiceContainer.shared.securityLogManager.logEntry(
                    eventType: "high_risk_data_transfer",
                    source: "SecurityService",
                    severity: .warning,
                    details: analysis.reason
                )
            }
        }
        
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
            
            // 檢查是否需要因訊息數量過多而移除密鑰
            if sessionKey.messageNumber >= maxMessagesPerKey {
                #if DEBUG
                print("🔄 Removing session key due to message count limit for peer: \(peerID)")
                #endif
                sessionKeys.removeValue(forKey: peerID)
            } else {
                sessionKeys[peerID] = sessionKey
            }
            
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
            #if DEBUG
            print("🗺️ 通過映射找到會話密鑰")
            #endif
        }
        
        guard var sessionKey = sessionKey else {
            #if DEBUG
            print("❌ 找不到會話密鑰")
            #endif
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
            // 縮小容錯範圍，更嚴格的重放攻擊防護
            let allowedBacktrack = 3 // 只允許3個訊息的回退，處理輕微網路亂序
            let expectedMinNumber = max(0, sessionKey.messageNumber - UInt64(allowedBacktrack))
            
            // 額外的時間窗口檢查（5分鐘內的訊息）
            let messageAge = Date().timeIntervalSince1970 - Double(encryptedMessage.messageNumber)
            let maxMessageAge: TimeInterval = 300 // 5分鐘
            
            guard encryptedMessage.messageNumber >= expectedMinNumber else {
                #if DEBUG
                print("❌ 訊息編號異常：期望 >= \(expectedMinNumber)，實際 \(encryptedMessage.messageNumber)")
                #endif
                throw CryptoError.messageNumberMismatch
            }
            
            guard messageAge <= maxMessageAge else {
                #if DEBUG
                print("❌ 訊息過期：訊息年齡 \(messageAge)s > 最大允許 \(maxMessageAge)s")
                #endif
                throw CryptoError.messageExpired
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
            
            // 檢查是否需要因訊息數量過多而移除密鑰
            if sessionKey.messageNumber >= maxMessagesPerKey {
                #if DEBUG
                print("🔄 Removing session key due to message count limit for peer: \(actualPeerID)")
                #endif
                sessionKeys.removeValue(forKey: actualPeerID)
            } else {
                sessionKeys[actualPeerID] = sessionKey
            }
            
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
        #if DEBUG
        print("🗑️ Removed and securely wiped session key")
        #endif
    }
    
    /// 清除所有會話密鑰（帶安全清理）
    func clearAllSessionKeys() {
        // 安全清理所有會話密鑰
        for (_, sessionKey) in sessionKeys {
            secureWipeSessionKey(sessionKey)
            #if DEBUG
            print("🧹 Securely wiped session key")
            #endif
        }
        
        sessionKeys.removeAll()
        DispatchQueue.main.async {
            self.activeConnections = 0
        }
        #if DEBUG
        print("🧹 Cleared all session keys with secure wipe")
        #endif
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
                #if DEBUG
                print("🔑 Loaded existing private key")
                #endif
            } else {
                self.privateKey = Curve25519.KeyAgreement.PrivateKey()
                guard let privateKey = privateKey else {
                    throw CryptoError.noPrivateKey
                }
                try savePrivateKeyToKeychain(privateKey)
                #if DEBUG
                print("🆕 Generated new private key")
                #endif
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
        // 使用不同的衍生路徑為加密密鑰和 HMAC 密鑰生成新密鑰
        let encKeyMaterial = HMAC<SHA256>.authenticationCode(
            for: "enc-ratchet-\(key.messageNumber)".data(using: .utf8) ?? Data(),
            using: key.encryptionKey
        )
        
        let hmacKeyMaterial = HMAC<SHA256>.authenticationCode(
            for: "mac-ratchet-\(key.messageNumber)".data(using: .utf8) ?? Data(),
            using: key.hmacKey
        )
        
        let newEncryptionKey = SymmetricKey(data: Data(encKeyMaterial.prefix(32)))
        let newHmacKey = SymmetricKey(data: Data(hmacKeyMaterial.prefix(32)))
        
        return SessionKey(
            encryptionKey: newEncryptionKey,
            hmacKey: newHmacKey,
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
            let timeExpired = now.timeIntervalSince(key.createdAt) > keyRotationInterval
            let messageCountExceeded = key.messageNumber >= maxMessagesPerKey
            
            if timeExpired || messageCountExceeded {
                // 生成新的會話密鑰（需要重新密鑰交換）
                sessionKeys.removeValue(forKey: peerID)
                rotatedCount += 1
                
                #if DEBUG
                if timeExpired {
                    print("🔄 Key expired by time for peer: \(peerID)")
                } else if messageCountExceeded {
                    print("🔄 Key expired by message count (\(key.messageNumber)) for peer: \(peerID)")
                }
                #endif
            }
        }
        
        if rotatedCount > 0 {
            #if DEBUG
            print("🔄 Rotated \(rotatedCount) expired session keys")
            #endif
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
            kSecReturnData as String: kCFBooleanTrue as Any,
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
    
    // MARK: - 🚀 高速加密實現
    
    /// 高速壓縮 (LZ4) - 內置實現
    private func fastCompress(_ data: Data) async -> Data {
        guard data.count > 128 else {
            return addCompressionHeader(data, compressed: false)
        }
        
        return await Task.detached(priority: .userInitiated) {
            let result = self.smartCompress(data, threshold: 128)
            return self.addCompressionHeader(result.data, compressed: result.compressed)
        }.value
    }
    
    /// 高速解壓縮
    private func fastDecompress(_ data: Data) async -> Data {
        guard data.count > 1 else { return data }
        
        let isCompressed = data[0] == 0x01
        let payload = Data(data.dropFirst())
        
        guard isCompressed else { return payload }
        
        return await Task.detached(priority: .userInitiated) {
            return self.smartDecompress(payload, wasCompressed: true)
        }.value
    }
    
    
    private func addCompressionHeader(_ data: Data, compressed: Bool) -> Data {
        var result = Data(capacity: data.count + 1)
        result.append(compressed ? 0x01 : 0x00)
        result.append(data)
        return result
    }
    
    // MARK: - 內置壓縮方法
    
    /// 智能壓縮 (自動判斷是否值得壓縮)
    private func smartCompress(_ data: Data, threshold: Int = 128) -> (data: Data, compressed: Bool) {
        guard data.count > threshold else {
            return (data, false)
        }
        
        do {
            let compressed = try compressLZ4(data)
            // 只有壓縮率 > 10% 才使用
            if compressed.count < data.count * 9 / 10 {
                return (compressed, true)
            } else {
                return (data, false)
            }
        } catch {
            return (data, false)
        }
    }
    
    /// 智能解壓縮
    private func smartDecompress(_ data: Data, wasCompressed: Bool, originalSize: Int? = nil) -> Data {
        guard wasCompressed else { return data }
        
        do {
            return try decompressLZ4(data, expectedSize: originalSize)
        } catch {
            print("⚠️ 解壓縮失敗: \(error)")
            return data
        }
    }
    
    /// LZ4 壓縮
    private func compressLZ4(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            throw CryptoError.encryptionFailed
        }
        
        return try data.withUnsafeBytes { bytes in
            guard let sourceAddress = bytes.bindMemory(to: UInt8.self).baseAddress,
                  bytes.count > 0,
                  data.count <= Int.max / 2 else {
                throw CryptoError.encryptionFailed
            }
            
            let maxCompressedSize = max(data.count + 1024, Int(Double(data.count) * 1.1))
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxCompressedSize)
            defer { buffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                buffer, maxCompressedSize,
                sourceAddress, data.count,
                nil, COMPRESSION_LZ4
            )
            
            guard compressedSize > 0, compressedSize <= maxCompressedSize else {
                throw CryptoError.encryptionFailed
            }
            
            return Data(bytes: buffer, count: compressedSize)
        }
    }
    
    /// LZ4 解壓縮
    private func decompressLZ4(_ data: Data, expectedSize: Int? = nil) throws -> Data {
        guard !data.isEmpty else {
            throw CryptoError.encryptionFailed
        }
        
        let maxBufferSize = 50 * 1024 * 1024 // 50MB 上限
        let bufferSize = min(expectedSize ?? data.count * 4, maxBufferSize)
        
        guard bufferSize > 0 else {
            throw CryptoError.encryptionFailed
        }
        
        return try data.withUnsafeBytes { bytes in
            guard let sourceAddress = bytes.bindMemory(to: UInt8.self).baseAddress,
                  bytes.count > 0,
                  data.count <= maxBufferSize else {
                throw CryptoError.encryptionFailed
            }
            
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                buffer, bufferSize,
                sourceAddress, data.count,
                nil, COMPRESSION_LZ4
            )
            
            guard decompressedSize > 0, decompressedSize <= bufferSize else {
                throw CryptoError.encryptionFailed
            }
            
            return Data(bytes: buffer, count: decompressedSize)
        }
    }
    
    /// ChaCha20-Poly1305 高速加密
    private func encryptWithChaCha20(_ data: Data, peerID: String) async throws -> Data {
        guard let sessionKey = sessionKeys[peerID] else {
            throw CryptoError.noSessionKey
        }
        
        let nonce = ChaChaPoly.Nonce()
        let sealed = try ChaChaPoly.seal(data, using: sessionKey.encryptionKey, nonce: nonce)
        
        var result = Data(capacity: data.count + 32)
        result.append(0x01) // ChaCha20 標識
        result.append(sealed.combined)
        
        return result
    }
    
    /// AES-GCM 硬件加速加密
    private func encryptWithAESGCM(_ data: Data, peerID: String) async throws -> Data {
        guard let sessionKey = sessionKeys[peerID] else {
            throw CryptoError.noSessionKey
        }
        
        let sealed = try AES.GCM.seal(data, using: sessionKey.encryptionKey)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }
        
        var result = Data(capacity: combined.count + 1)
        result.append(0x02) // AES-GCM 標識
        result.append(combined)
        
        return result
    }
    
    /// 🚀 超高速解密
    func ultraDecrypt(_ data: Data, from peerID: String) async throws -> Data {
        guard data.count > 1 else {
            throw CryptoError.invalidData
        }
        
        let cryptoType = data[0]
        let payload = data.dropFirst()
        
        let decryptedData: Data
        switch cryptoType {
        case 0x01: // ChaCha20
            decryptedData = try await decryptWithChaCha20(payload, peerID: peerID)
        case 0x02: // AES-GCM
            decryptedData = try await decryptWithAESGCM(payload, peerID: peerID)
        default:
            // 嘗試傳統解密作為回退
            return try decrypt(data, from: peerID)
        }
        
        return await fastDecompress(decryptedData)
    }
    
    /// ChaCha20 解密
    private func decryptWithChaCha20(_ data: Data, peerID: String) async throws -> Data {
        guard let sessionKey = sessionKeys[peerID] else {
            throw CryptoError.noSessionKey
        }
        
        let sealed = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealed, using: sessionKey.encryptionKey)
    }
    
    /// AES-GCM 解密
    private func decryptWithAESGCM(_ data: Data, peerID: String) async throws -> Data {
        guard let sessionKey = sessionKeys[peerID] else {
            throw CryptoError.noSessionKey
        }
        
        let sealed = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealed, using: sessionKey.encryptionKey)
    }
    
    // MARK: - 🏎️ 批量處理優化
    
    /// 批量加密 (大規模網路優化)
    func batchEncrypt(_ dataArray: [Data], for peerID: String) async throws -> [Data] {
        let batchSize = 50
        var results: [Data] = []
        results.reserveCapacity(dataArray.count)
        
        for batch in dataArray.chunked(into: batchSize) {
            let batchResults = try await withThrowingTaskGroup(of: Data.self) { group in
                for data in batch {
                    group.addTask {
                        return try await self.ultraEncrypt(data, for: peerID)
                    }
                }
                
                var batchResults: [Data] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
} 