import Foundation
import Security
import CryptoKit
import UIKit

// MARK: - Device Fingerprint Manager
/// 設備指紋管理器 - 實現匿名身份一致性與信任追蹤
class DeviceFingerprintManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var deviceUUID: String = ""
    @Published private(set) var dayToken: String = ""
    @Published private(set) var fingerprintStatus: FingerprintStatus = .initializing
    @Published private(set) var trustworthiness: TrustworthinessLevel = .unknown
    
    // MARK: - Configuration
    private let keychainService = "com.signalair.fingerprint"
    private let deviceUUIDKey = "device_uuid"
    private let installationSeedKey = "installation_seed"
    private let dayTokenPrefix = "DAY_"
    
    // MARK: - Internal State
    private var installationSeed: Data?
    private var lastDayTokenGeneration: Date?
    private var deviceResetDetectionCount: Int = 0
    
    // MARK: - Constants
    private let maxResetDetectionThreshold = 3
    private let dayTokenUpdateInterval: TimeInterval = 86400 // 24 hours
    
    // MARK: - Initialization
    init() {
        setupDeviceFingerprint()
        startDayTokenUpdateTimer()
        print("🔐 DeviceFingerprintManager: 初始化完成")
    }
    
    // MARK: - Public Methods
    
    /// 獲取當前設備指紋信息
    func getFingerprintInfo() -> DeviceFingerprintInfo {
        return DeviceFingerprintInfo(
            deviceUUID: deviceUUID,
            dayToken: dayToken,
            status: fingerprintStatus,
            trustworthiness: trustworthiness,
            lastTokenUpdate: lastDayTokenGeneration ?? Date(),
            resetDetectionCount: deviceResetDetectionCount
        )
    }
    
    /// 驗證設備指紋完整性
    func verifyFingerprintIntegrity() -> Bool {
        guard !deviceUUID.isEmpty,
              !dayToken.isEmpty,
              let seed = installationSeed else {
            print("❌ DeviceFingerprintManager: 指紋數據不完整")
            return false
        }
        
        // 驗證 DeviceUUID 是否基於正確的種子生成
        let expectedUUID = generateDeviceUUID(from: seed)
        let isValid = expectedUUID == deviceUUID
        
        if !isValid {
            print("⚠️ DeviceFingerprintManager: 檢測到指紋篡改")
            deviceResetDetectionCount += 1
            updateTrustworthiness()
        }
        
        return isValid
    }
    
    /// 強制重新生成日帳號
    func regenerateDayToken() {
        dayToken = generateDayToken()
        lastDayTokenGeneration = Date()
        print("🔄 DeviceFingerprintManager: 已重新生成日帳號 - \(dayToken)")
    }
    
    /// 檢查是否需要更新日帳號
    func shouldUpdateDayToken() -> Bool {
        guard let lastUpdate = lastDayTokenGeneration else { return true }
        return Date().timeIntervalSince(lastUpdate) >= dayTokenUpdateInterval
    }
    
    /// 獲取設備可信度評分
    func getTrustworthinessScore() -> Double {
        switch trustworthiness {
        case .unknown:
            return 0.5
        case .untrusted:
            return 0.1
        case .suspicious:
            return 0.3
        case .normal:
            return 0.7
        case .trusted:
            return 0.9
        }
    }
    
    // MARK: - Private Methods
    
    /// 設置設備指紋系統
    private func setupDeviceFingerprint() {
        fingerprintStatus = .initializing
        
        do {
            // 1. 嘗試從 Keychain 載入現有的 DeviceUUID
            if let existingUUID = try loadDeviceUUIDFromKeychain() {
                deviceUUID = existingUUID
                print("🔑 DeviceFingerprintManager: 載入現有 DeviceUUID")
            } else {
                // 2. 首次安裝，生成新的指紋
                try generateNewFingerprint()
                print("🆕 DeviceFingerprintManager: 生成新的設備指紋")
            }
            
            // 3. 生成或更新日帳號
            updateDayTokenIfNeeded()
            
            // 4. 檢查設備重設狀態
            checkDeviceResetStatus()
            
            fingerprintStatus = .active
            
        } catch {
            print("❌ DeviceFingerprintManager: 初始化失敗 - \(error)")
            fingerprintStatus = .error
            
            // 降級處理：生成臨時指紋
            generateFallbackFingerprint()
        }
    }
    
    /// 生成新的設備指紋
    private func generateNewFingerprint() throws {
        // 1. 生成安裝種子（一次性，永不變更）
        installationSeed = try generateInstallationSeed()
        
        // 2. 基於種子生成 DeviceUUID
        deviceUUID = generateDeviceUUID(from: installationSeed!)
        
        // 3. 儲存到 Keychain
        try saveDeviceUUIDToKeychain(deviceUUID)
        try saveInstallationSeedToKeychain(installationSeed!)
        
        // 4. 設定初始可信度
        trustworthiness = .normal
        
        print("✅ DeviceFingerprintManager: 新指紋生成完成")
    }
    
    /// 生成安裝種子
    private func generateInstallationSeed() throws -> Data {
        // 結合設備不可變資訊
        let deviceInfo = collectDeviceInfo()
        let randomSalt = try generateSecureRandomData(length: 32)
        var timestamp = Date().timeIntervalSince1970.bitPattern
        
        var seedComponents = Data()
        seedComponents.append(deviceInfo)
        seedComponents.append(randomSalt)
        seedComponents.append(Data(bytes: &timestamp, count: MemoryLayout<UInt64>.size))
        
        // 使用 SHA256 產生最終種子
        return Data(SHA256.hash(data: seedComponents))
    }
    
    /// 收集設備資訊
    private func collectDeviceInfo() -> Data {
        var deviceInfo = Data()
        
        // 設備型號
        let deviceModel = UIDevice.current.model
        deviceInfo.append(deviceModel.data(using: .utf8) ?? Data())
        
        // 系統版本
        let systemVersion = UIDevice.current.systemVersion
        deviceInfo.append(systemVersion.data(using: .utf8) ?? Data())
        
        // 設備類型標識符
        var deviceType = UIDevice.current.userInterfaceIdiom.rawValue
        deviceInfo.append(Data(bytes: &deviceType, count: MemoryLayout<Int>.size))
        
        // 螢幕解析度（相對穩定）
        let screenBounds = UIScreen.main.bounds
        let screenScale = UIScreen.main.scale
        var screenData = [screenBounds.width, screenBounds.height, Double(screenScale)]
        deviceInfo.append(Data(bytes: &screenData, count: MemoryLayout<Double>.size * 3))
        
        return deviceInfo
    }
    
    /// 基於種子生成 DeviceUUID
    private func generateDeviceUUID(from seed: Data) -> String {
        let hash = SHA256.hash(data: seed)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // 格式化為 UUID 樣式（但保持唯一性）
        let prefix = "DEVICE"
        let suffix = String(hashString.prefix(8))
        return "\(prefix)-\(suffix.uppercased())"
    }
    
    /// 生成日帳號
    private func generateDayToken() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let dayStamp = Int(today.timeIntervalSince1970 / 86400)
        
        // 結合 DeviceUUID 和日期戳生成日帳號
        let tokenData = "\(deviceUUID)-\(dayStamp)".data(using: .utf8)!
        let hash = SHA256.hash(data: tokenData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        return "\(dayTokenPrefix)\(String(hashString.prefix(12)).uppercased())"
    }
    
    /// 更新日帳號（如果需要）
    private func updateDayTokenIfNeeded() {
        if shouldUpdateDayToken() {
            regenerateDayToken()
        }
    }
    
    /// 檢查設備重設狀態
    private func checkDeviceResetStatus() {
        // 檢查是否有異常的重設模式
        let resetCount = UserDefaults.standard.integer(forKey: "device_reset_count")
        
        if resetCount > maxResetDetectionThreshold {
            trustworthiness = .suspicious
            print("⚠️ DeviceFingerprintManager: 檢測到頻繁重設，降低信任度")
        }
        
        deviceResetDetectionCount = resetCount
    }
    
    /// 更新可信度等級
    private func updateTrustworthiness() {
        switch deviceResetDetectionCount {
        case 0:
            trustworthiness = .trusted
        case 1...2:
            trustworthiness = .normal
        case 3...5:
            trustworthiness = .suspicious
        default:
            trustworthiness = .untrusted
        }
        
        // 儲存重設計數
        UserDefaults.standard.set(deviceResetDetectionCount, forKey: "device_reset_count")
        
        print("📊 DeviceFingerprintManager: 更新信任度 - \(trustworthiness)")
    }
    
    /// 生成降級指紋（錯誤處理）
    private func generateFallbackFingerprint() {
        let fallbackUUID = "FALLBACK-\(UUID().uuidString.prefix(8))"
        deviceUUID = fallbackUUID
        dayToken = generateDayToken()
        trustworthiness = .suspicious
        fingerprintStatus = .fallback
        
        print("⚠️ DeviceFingerprintManager: 使用降級指紋 - \(fallbackUUID)")
    }
    
    /// 生成安全隨機資料
    private func generateSecureRandomData(length: Int) throws -> Data {
        var randomBytes = Data(count: length)
        let result = randomBytes.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw FingerprintError.randomGenerationFailed
        }
        
        return randomBytes
    }
    
    /// 啟動日帳號更新定時器
    private func startDayTokenUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            if self.shouldUpdateDayToken() {
                self.updateDayTokenIfNeeded()
            }
        }
    }
    
    // MARK: - Keychain Operations
    
    /// 儲存 DeviceUUID 到 Keychain
    private func saveDeviceUUIDToKeychain(_ uuid: String) throws {
        let data = uuid.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: deviceUUIDKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 刪除舊的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw FingerprintError.keychainError(status)
        }
    }
    
    /// 從 Keychain 載入 DeviceUUID
    private func loadDeviceUUIDFromKeychain() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: deviceUUIDKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw FingerprintError.keychainError(status)
        }
        
        guard let data = item as? Data,
              let uuid = String(data: data, encoding: .utf8) else {
            throw FingerprintError.invalidData
        }
        
        return uuid
    }
    
    /// 儲存安裝種子到 Keychain
    private func saveInstallationSeedToKeychain(_ seed: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: installationSeedKey,
            kSecValueData as String: seed,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 刪除舊的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw FingerprintError.keychainError(status)
        }
    }
}

// MARK: - Supporting Types

/// 設備指紋狀態
enum FingerprintStatus: String, CaseIterable {
    case initializing = "INITIALIZING"
    case active = "ACTIVE"
    case fallback = "FALLBACK"
    case error = "ERROR"
    
    var description: String {
        switch self {
        case .initializing:
            return "初始化中"
        case .active:
            return "正常運行"
        case .fallback:
            return "降級模式"
        case .error:
            return "錯誤狀態"
        }
    }
}

/// 可信度等級
enum TrustworthinessLevel: String, CaseIterable {
    case unknown = "UNKNOWN"
    case untrusted = "UNTRUSTED"
    case suspicious = "SUSPICIOUS"
    case normal = "NORMAL"
    case trusted = "TRUSTED"
    
    var description: String {
        switch self {
        case .unknown:
            return "未知"
        case .untrusted:
            return "不可信"
        case .suspicious:
            return "可疑"
        case .normal:
            return "正常"
        case .trusted:
            return "可信"
        }
    }
    
    var color: UIColor {
        switch self {
        case .unknown:
            return .systemGray
        case .untrusted:
            return .systemRed
        case .suspicious:
            return .systemOrange
        case .normal:
            return .systemBlue
        case .trusted:
            return .systemGreen
        }
    }
}

/// 設備指紋資訊
struct DeviceFingerprintInfo {
    let deviceUUID: String
    let dayToken: String
    let status: FingerprintStatus
    let trustworthiness: TrustworthinessLevel
    let lastTokenUpdate: Date
    let resetDetectionCount: Int
    
    var isValid: Bool {
        return !deviceUUID.isEmpty && !dayToken.isEmpty && status == .active
    }
    
    var formattedInfo: String {
        return """
        🔐 設備指紋資訊:
        - DeviceUUID: \(deviceUUID)
        - DayToken: \(dayToken)
        - 狀態: \(status.description)
        - 可信度: \(trustworthiness.description)
        - 最後更新: \(lastTokenUpdate.formatted())
        - 重設次數: \(resetDetectionCount)
        """
    }
}

/// 指紋錯誤類型
enum FingerprintError: Error {
    case keychainError(OSStatus)
    case randomGenerationFailed
    case invalidData
    case deviceInfoUnavailable
    
    var localizedDescription: String {
        switch self {
        case .keychainError(let status):
            return "Keychain 錯誤: \(status)"
        case .randomGenerationFailed:
            return "隨機數生成失敗"
        case .invalidData:
            return "無效資料格式"
        case .deviceInfoUnavailable:
            return "設備資訊不可用"
        }
    }
} 