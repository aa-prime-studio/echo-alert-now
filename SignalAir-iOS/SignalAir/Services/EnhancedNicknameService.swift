import Foundation
import SwiftUI

// MARK: - Enhanced Nickname Service
/// 增強版暱稱服務 - 整合設備指紋與信任評分系統
class EnhancedNicknameService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var nickname: String
    @Published var remainingChanges: Int
    @Published var isInObservationPeriod: Bool = false
    @Published var trustLevel: TrustLevel = .neutral
    
    // MARK: - Dependencies
    private let deviceFingerprintManager: DeviceFingerprintManager
    private let trustScoreManager: TrustScoreManager
    
    // MARK: - Configuration
    private let userDefaults = UserDefaults.standard
    private let nicknameKey = "enhanced_nickname"
    private let remainingChangesKey = "enhanced_nickname_changes"
    private let lastChangeTimestampKey = "last_nickname_change"
    private let observationPeriodKey = "observation_period_end"
    
    // MARK: - Constants
    private let maxNicknameChanges = 3
    private let maxNicknameLength = 20
    private let observationPeriodDuration: TimeInterval = 86400 * 7 // 7 days
    
    // MARK: - Initialization
    init(
        deviceFingerprintManager: DeviceFingerprintManager = DeviceFingerprintManager(),
        trustScoreManager: TrustScoreManager = TrustScoreManager()
    ) {
        self.deviceFingerprintManager = deviceFingerprintManager
        self.trustScoreManager = trustScoreManager
        
        // 初始化暱稱（優先使用儲存的暱稱，否則使用設備指紋的 DayToken）
        self.nickname = userDefaults.string(forKey: nicknameKey) ?? deviceFingerprintManager.dayToken
        
        // 初始化剩餘變更次數
        if userDefaults.object(forKey: remainingChangesKey) == nil {
            self.remainingChanges = maxNicknameChanges
            userDefaults.set(maxNicknameChanges, forKey: remainingChangesKey)
        } else {
            self.remainingChanges = userDefaults.integer(forKey: remainingChangesKey)
        }
        
        // 檢查觀察期狀態
        checkObservationPeriod()
        
        // 更新信任等級
        updateTrustLevel()
        
        print("📝 EnhancedNicknameService: 初始化完成 - \(nickname)")
    }
    
    // MARK: - Public Methods
    
    /// 更新暱稱
    /// - Parameter newNickname: 新的暱稱
    /// - Returns: 更新是否成功
    func updateNickname(_ newNickname: String) -> NicknameUpdateResult {
        // 1. 基本驗證
        guard let validationResult = validateNickname(newNickname) else {
            return .failure(.invalidNickname("暱稱格式無效"))
        }
        
        if case .failure(let error) = validationResult {
            return .failure(error)
        }
        
        // 2. 檢查是否在觀察期
        if isInObservationPeriod {
            return .failure(.inObservationPeriod)
        }
        
        // 3. 檢查剩餘變更次數
        guard remainingChanges > 0 else {
            return .failure(.noRemainingChanges)
        }
        
        // 4. 檢查是否真的有變更
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNickname != nickname else {
            return .failure(.noChange)
        }
        
        // 5. 執行變更
        performNicknameUpdate(trimmedNickname)
        
        // 6. 記錄行為到信任評分系統
        let deviceUUID = deviceFingerprintManager.deviceUUID
        trustScoreManager.recordSuccessfulCommunication(for: deviceUUID, messageType: .system)
        
        return .success(NicknameUpdateInfo(
            oldNickname: nickname,
            newNickname: trimmedNickname,
            remainingChanges: remainingChanges,
            trustLevel: trustLevel
        ))
    }
    
    /// 檢查是否可以變更暱稱
    func canChangeNickname() -> Bool {
        return remainingChanges > 0 && !isInObservationPeriod
    }
    
    /// 獲取暱稱變更限制文字
    func getRemainingChangesText() -> String {
        if isInObservationPeriod {
            let endDate = getObservationPeriodEndDate()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "觀察期中，至 \(formatter.string(from: endDate)) 結束"
        }
        
        if remainingChanges > 0 {
            return "剩餘 \(remainingChanges) 次修改機會"
        } else {
            return "已用完修改次數"
        }
    }
    
    /// 獲取暱稱狀態資訊
    func getNicknameStatus() -> NicknameStatus {
        let deviceInfo = deviceFingerprintManager.getFingerprintInfo()
        let trustScore = trustScoreManager.getTrustScore(for: deviceInfo.deviceUUID)
        
        return NicknameStatus(
            nickname: nickname,
            deviceUUID: deviceInfo.deviceUUID,
            dayToken: deviceInfo.dayToken,
            remainingChanges: remainingChanges,
            trustScore: trustScore,
            trustLevel: trustLevel,
            isInObservationPeriod: isInObservationPeriod,
            canChange: canChangeNickname()
        )
    }
    
    /// 重設暱稱變更次數（系統維護功能）
    func resetNicknameChanges() {
        remainingChanges = maxNicknameChanges
        userDefaults.set(maxNicknameChanges, forKey: remainingChangesKey)
        
        // 結束觀察期
        isInObservationPeriod = false
        userDefaults.removeObject(forKey: observationPeriodKey)
        
        print("🔄 EnhancedNicknameService: 重設暱稱變更次數")
    }
    
    /// 進入觀察期（當檢測到可疑行為時）
    func enterObservationPeriod(reason: String) {
        isInObservationPeriod = true
        let endDate = Date().addingTimeInterval(observationPeriodDuration)
        userDefaults.set(endDate, forKey: observationPeriodKey)
        
        // 記錄到信任評分系統
        let deviceUUID = deviceFingerprintManager.deviceUUID
        trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .protocolViolation)
        
        updateTrustLevel()
        
        print("👁️ EnhancedNicknameService: 進入觀察期 - \(reason)")
    }
    
    /// 獲取當前的 DayToken（用於訊息識別）
    func getCurrentDayToken() -> String {
        return deviceFingerprintManager.dayToken
    }
    
    /// 獲取當前的 DeviceUUID（用於信任評分）
    func getCurrentDeviceUUID() -> String {
        return deviceFingerprintManager.deviceUUID
    }
    
    // MARK: - Private Methods
    
    /// 驗證暱稱格式
    private func validateNickname(_ nickname: String) -> NicknameUpdateResult? {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 檢查是否為空
        if trimmed.isEmpty {
            return .failure(.invalidNickname("暱稱不能為空"))
        }
        
        // 檢查長度
        if trimmed.count > maxNicknameLength {
            return .failure(.invalidNickname("暱稱不能超過 \(maxNicknameLength) 個字元"))
        }
        
        // 檢查是否包含不當內容
        if containsInappropriateContent(trimmed) {
            return .failure(.inappropriateContent)
        }
        
        return .success(NicknameUpdateInfo(
            oldNickname: nickname,
            newNickname: trimmed,
            remainingChanges: remainingChanges,
            trustLevel: trustLevel
        ))
    }
    
    /// 檢查是否包含不當內容
    private func containsInappropriateContent(_ nickname: String) -> Bool {
        let inappropriateWords = [
            "system", "root", "null", "undefined",
            "測試", "test", "系統"
        ]
        
        let lowercased = nickname.lowercased()
        return inappropriateWords.contains { lowercased.contains($0) }
    }
    
    /// 執行暱稱更新
    private func performNicknameUpdate(_ newNickname: String) {
        let oldNickname = nickname
        
        // 更新暱稱
        nickname = newNickname
        userDefaults.set(newNickname, forKey: nicknameKey)
        
        // 減少剩餘次數
        remainingChanges -= 1
        userDefaults.set(remainingChanges, forKey: remainingChangesKey)
        
        // 記錄變更時間
        userDefaults.set(Date(), forKey: lastChangeTimestampKey)
        
        // 如果用完所有次數，進入觀察期
        if remainingChanges == 0 {
            enterObservationPeriod(reason: "用完所有暱稱變更次數")
        }
        
        userDefaults.synchronize()
        
        print("📝 EnhancedNicknameService: 暱稱已更新 '\(oldNickname)' → '\(newNickname)'")
    }
    
    /// 檢查觀察期狀態
    private func checkObservationPeriod() {
        guard let endDate = userDefaults.object(forKey: observationPeriodKey) as? Date else {
            isInObservationPeriod = false
            return
        }
        
        if Date() > endDate {
            // 觀察期結束
            isInObservationPeriod = false
            userDefaults.removeObject(forKey: observationPeriodKey)
            print("✅ EnhancedNicknameService: 觀察期結束")
        } else {
            isInObservationPeriod = true
        }
    }
    
    /// 獲取觀察期結束日期
    private func getObservationPeriodEndDate() -> Date {
        return userDefaults.object(forKey: observationPeriodKey) as? Date ?? Date()
    }
    
    /// 更新信任等級
    private func updateTrustLevel() {
        let deviceUUID = deviceFingerprintManager.deviceUUID
        let trustScore = trustScoreManager.getTrustScore(for: deviceUUID)
        
        switch trustScore {
        case 80...100:
            trustLevel = .trusted
        case 60..<80:
            trustLevel = .reliable
        case 40..<60:
            trustLevel = .neutral
        case 20..<40:
            trustLevel = .suspicious
        default:
            trustLevel = .untrusted
        }
    }
}

// MARK: - Supporting Types

/// 暱稱更新結果
enum NicknameUpdateResult {
    case success(NicknameUpdateInfo)
    case failure(NicknameUpdateError)
}

/// 暱稱更新資訊
struct NicknameUpdateInfo {
    let oldNickname: String
    let newNickname: String
    let remainingChanges: Int
    let trustLevel: TrustLevel
}

/// 暱稱更新錯誤
enum NicknameUpdateError {
    case invalidNickname(String)
    case inappropriateContent
    case noRemainingChanges
    case inObservationPeriod
    case noChange
    
    var localizedDescription: String {
        switch self {
        case .invalidNickname(let reason):
            return reason
        case .inappropriateContent:
            return "暱稱包含不當內容"
        case .noRemainingChanges:
            return "已用完所有變更次數"
        case .inObservationPeriod:
            return "目前在觀察期中，無法變更暱稱"
        case .noChange:
            return "暱稱沒有變更"
        }
    }
}

/// 暱稱狀態
struct NicknameStatus {
    let nickname: String
    let deviceUUID: String
    let dayToken: String
    let remainingChanges: Int
    let trustScore: Double
    let trustLevel: TrustLevel
    let isInObservationPeriod: Bool
    let canChange: Bool
    
    var formattedStatus: String {
        return """
        📝 暱稱狀態:
        - 當前暱稱: \(nickname)
        - 設備UUID: \(deviceUUID)
        - 日帳號: \(dayToken)
        - 剩餘變更: \(remainingChanges) 次
        - 信任分數: \(String(format: "%.1f", trustScore))
        - 信任等級: \(trustLevel.description)
        - 觀察期: \(isInObservationPeriod ? "是" : "否")
        - 可變更: \(canChange ? "是" : "否")
        """
    }
} 