import Foundation
import SwiftUI
import Combine

// MARK: - Admin Dashboard ViewModel

class AdminDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var isLocked = false
    @Published var lockoutTimeRemaining = ""
    
    // 系統狀態
    @Published var systemStatus = SystemStatus(
        isInitialized: false,
        securityStatus: SecurityStatus(isInitialized: false),
        fingerprintInfo: FingerprintInfo(isValid: false, deviceUUID: "", dayToken: "", trustLevel: .unknown),
        trustStatistics: TrustStatistics(totalNodes: 0, trustedNodes: 0, suspiciousNodes: 0, blacklistedNodes: 0, averageScore: 0.0),
        nicknameStatus: NicknameStatus(canChange: true, remainingChanges: 3, isInObservationPeriod: false),
        connectedPeers: 0
    )
    
    // 快取統計
    @Published var cacheStats = CacheStatistics(
        deduplicationCount: 0,
        replayProtectionCount: 0,
        utilizationRate: 0.0
    )
    
    // 訊息資料
    @Published var safeMessages: [SafeMessageFingerprint] = []
    @Published var fullMessages: [MessageFingerprint] = []
    @Published var securityEvents: [SecurityEvent] = []
    
    // 會話資訊
    @Published var sessionInfo = AdminSessionInfo(
        isActive: false,
        sessionId: nil,
        remainingTime: nil,
        isLocked: false,
        failedAttempts: 0
    )
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var lockoutTimer: Timer?
    private var sessionTimer: Timer?
    
    // 服務引用（應該從 ServiceContainer 注入）
    private var signalViewModel: SignalViewModel?
    
    // MARK: - Initialization
    
    init() {
        setupTimers()
        loadServiceReferences()
    }
    
    deinit {
        lockoutTimer?.invalidate()
        sessionTimer?.invalidate()
    }
    
    // MARK: - Authentication Methods
    
    func authenticate(passcode: String) {
        let success = AdminPermissionValidator.authenticateAdmin(passcode: passcode)
        
        DispatchQueue.main.async {
            if success {
                self.isAuthenticated = true
                self.authenticationError = nil
                self.updateSessionInfo()
                self.refreshData()
                print("✅ AdminDashboard: 管理員認證成功")
            } else {
                self.authenticationError = "認證失敗，請檢查密碼"
                self.updateLockoutStatus()
                print("❌ AdminDashboard: 管理員認證失敗")
            }
        }
    }
    
    func logout() {
        AdminPermissionValidator.logoutAdmin()
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.authenticationError = nil
            self.clearData()
            print("👋 AdminDashboard: 管理員已登出")
        }
    }
    
    func checkAuthenticationStatus() {
        let hasValidSession = AdminPermissionValidator.hasValidAdminSession()
        
        DispatchQueue.main.async {
            self.isAuthenticated = hasValidSession
            self.updateSessionInfo()
            self.updateLockoutStatus()
            
            if hasValidSession {
                self.refreshData()
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    func refreshData() {
        guard isAuthenticated else { return }
        
        Task {
            await refreshSystemStats()
            await refreshMessages()
            await refreshSecurityEvents()
            await refreshCacheStats()
        }
    }
    
    @MainActor
    func refreshSystemStats() {
        guard let signalViewModel = signalViewModel else { return }
        
        // 這裡需要從 ServiceContainer 獲取實際的系統狀態
        // 暫時使用模擬資料
        systemStatus = SystemStatus(
            isInitialized: true,
            securityStatus: SecurityStatus(isInitialized: true),
            fingerprintInfo: FingerprintInfo(
                isValid: true,
                deviceUUID: "DEVICE-12345678",
                dayToken: "DAY_ABCDEF123456",
                trustLevel: .trusted
            ),
            trustStatistics: TrustStatistics(
                totalNodes: 25,
                trustedNodes: 20,
                suspiciousNodes: 3,
                blacklistedNodes: 2,
                averageScore: 72.5
            ),
            nicknameStatus: NicknameStatus(
                canChange: true,
                remainingChanges: 2,
                isInObservationPeriod: false
            ),
            connectedPeers: 8
        )
        
        print("📊 AdminDashboard: 系統統計已更新")
    }
    
    func loadMessages() {
        guard isAuthenticated else { return }
        
        Task {
            await refreshMessages()
        }
    }
    
    @MainActor
    func refreshMessages() {
        guard let signalViewModel = signalViewModel else { return }
        
        // 載入安全訊息（一般權限）
        safeMessages = signalViewModel.getRecentProcessedMessages(limit: 50, includeContent: false)
        
        // 載入完整訊息（管理員權限）
        // 注意：這裡需要重新認證
        // fullMessages = signalViewModel.getRecentProcessedMessagesAdmin(limit: 50, adminPasscode: "密碼")
        
        // 暫時使用模擬資料
        fullMessages = generateMockFullMessages()
        
        print("📨 AdminDashboard: 訊息資料已更新 - 安全: \(safeMessages.count), 完整: \(fullMessages.count)")
    }
    
    func loadSecurityEvents() {
        guard isAuthenticated else { return }
        
        Task {
            await refreshSecurityEvents()
        }
    }
    
    @MainActor
    func refreshSecurityEvents() {
        guard let signalViewModel = signalViewModel else { return }
        
        securityEvents = signalViewModel.getRecentSecurityEvents(limit: 100)
        
        print("🛡️ AdminDashboard: 安全事件已更新 - \(securityEvents.count) 個事件")
    }
    
    @MainActor
    func refreshCacheStats() {
        guard let signalViewModel = signalViewModel else { return }
        
        let deduplicationStats = signalViewModel.getDeduplicationStats()
        let replayStats = signalViewModel.getReplayProtectionStats()
        
        cacheStats = CacheStatistics(
            deduplicationCount: deduplicationStats.count,
            replayProtectionCount: replayStats.count,
            utilizationRate: deduplicationStats.utilizationRate
        )
        
        print("💾 AdminDashboard: 快取統計已更新")
    }
    
    // MARK: - System Operations
    
    func clearCaches() {
        guard isAuthenticated else { return }
        
        signalViewModel?.clearDeduplicationCache()
        signalViewModel?.clearReplayProtectionCache()
        
        Task {
            await refreshCacheStats()
        }
        
        print("🧹 AdminDashboard: 快取已清除")
    }
    
    func exportSecurityLogs() {
        guard isAuthenticated else { return }
        
        // 實作安全日誌匯出功能
        let logData = securityEvents.map { event in
            [
                "timestamp": event.timestamp.ISO8601Format(),
                "type": event.type.rawValue,
                "peerID": event.peerID,
                "severity": event.severity.rawValue,
                "details": event.details
            ]
        }
        
        // 這裡可以實作實際的檔案匯出邏輯
        print("📄 AdminDashboard: 安全日誌匯出 - \(logData.count) 個事件")
    }
    
    func showSessionInfo() {
        updateSessionInfo()
        print("ℹ️ AdminDashboard: 會話資訊 - \(sessionInfo.statusDescription)")
    }
    
    // MARK: - Private Methods
    
    private func setupTimers() {
        // 設定鎖定狀態檢查計時器
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateLockoutStatus()
        }
        
        // 設定會話狀態檢查計時器
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateSessionInfo()
        }
    }
    
    private func loadServiceReferences() {
        // 這裡應該從 ServiceContainer 獲取服務引用
        // 暫時留空，等待整合
        print("🔗 AdminDashboard: 載入服務引用")
    }
    
    private func updateSessionInfo() {
        sessionInfo = AdminPermissionValidator.getSessionInfo()
    }
    
    private func updateLockoutStatus() {
        let sessionInfo = AdminPermissionValidator.getSessionInfo()
        
        DispatchQueue.main.async {
            self.isLocked = sessionInfo.isLocked
            
            if sessionInfo.isLocked {
                // 計算鎖定剩餘時間（這裡需要從 AdminPermissionValidator 獲取）
                self.lockoutTimeRemaining = "15:00" // 暫時硬編碼
            }
        }
    }
    
    private func clearData() {
        safeMessages.removeAll()
        fullMessages.removeAll()
        securityEvents.removeAll()
        systemStatus = SystemStatus(
            isInitialized: false,
            securityStatus: SecurityStatus(isInitialized: false),
            fingerprintInfo: FingerprintInfo(isValid: false, deviceUUID: "", dayToken: "", trustLevel: .unknown),
            trustStatistics: TrustStatistics(totalNodes: 0, trustedNodes: 0, suspiciousNodes: 0, blacklistedNodes: 0, averageScore: 0.0),
            nicknameStatus: NicknameStatus(canChange: true, remainingChanges: 3, isInObservationPeriod: false),
            connectedPeers: 0
        )
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockFullMessages() -> [MessageFingerprint] {
        return (0..<10).map { index in
            MessageFingerprint(
                messageID: "MSG_\(String(format: "%08d", index))",
                senderID: "DEVICE_\(String(format: "%08d", index % 5))",
                timestamp: Date().addingTimeInterval(-Double(index * 300)),
                contentHash: "hash_\(String(format: "%032d", index))"
            )
        }
    }
}

// MARK: - Supporting Types

struct CacheStatistics {
    let deduplicationCount: Int
    let replayProtectionCount: Int
    let utilizationRate: Double
}

// 這些類型應該已經在其他地方定義，這裡提供佔位符
struct SystemStatus {
    let isInitialized: Bool
    let securityStatus: SecurityStatus
    let fingerprintInfo: FingerprintInfo
    let trustStatistics: TrustStatistics
    let nicknameStatus: NicknameStatus
    let connectedPeers: Int
    
    var isHealthy: Bool {
        return isInitialized && securityStatus.isInitialized && fingerprintInfo.isValid
    }
}

struct SecurityStatus {
    let isInitialized: Bool
}

struct FingerprintInfo {
    let isValid: Bool
    let deviceUUID: String
    let dayToken: String
    let trustLevel: TrustLevel
}

enum TrustLevel {
    case unknown, untrusted, suspicious, normal, trusted
}

struct TrustStatistics {
    let totalNodes: Int
    let trustedNodes: Int
    let suspiciousNodes: Int
    let blacklistedNodes: Int
    let averageScore: Double
}

struct NicknameStatus {
    let canChange: Bool
    let remainingChanges: Int
    let isInObservationPeriod: Bool
} 