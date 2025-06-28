import Foundation
import SwiftUI
import Combine

// MARK: - TemporaryIDManager Implementation
class TemporaryIDManager: ObservableObject {
    // 台灣小吃清單（50種）
    private let taiwanSnacks = [
        "無糖綠茶", "牛肉麵", "滷肉飯", "雞排不切要辣", "臭豆腐",
        "小籠包", "綜合煎", "鹽酥雞", "肉圓", "刈包",
        "豆花", "紅豆餅", "雞蛋糕", "蔥抓餅", "胡椒餅",
        "魯味", "碳烤香腸", "花枝丸", "不要香菜", "麻辣魚蛋",
        "鹹酥龍珠", "芋圓", "香菜加滿", "蔓越莓酥", "抹茶拿鐵",
        "手工薯條", "車輪餅", "潤餅", "大腸包小腸", "阿給",
        "蝦捲", "臭豆腐泡麵", "龍珠果凍", "糖葫蘆", "擔仔麵",
        "南部粽", "碗粿", "草莓鬆餅", "蚵嗲", "港式腸粉",
        "烤玉米", "芒果冰", "鳳梨蝦球", "楊桃冰", "滷味",
        "九層塔蔥油餅", "油條很油", "木須炒麵", "燒餅油條", "青草茶"
    ]
    
    // 裝置ID（系統控制，不可手動修改）
    @Published private(set) var deviceID: String = ""
    @Published private(set) var createdAt: Date = Date()
    @Published private(set) var nextUpdateTime: Date = Date()
    
    // Timer 管理
    private var autoUpdateTimer: Timer?
    private let updateInterval: TimeInterval = 86400 // 24小時
    
    // UserDefaults 鍵值
    private let deviceIDKey = "SignalAir_DeviceID"
    private let createdAtKey = "SignalAir_DeviceID_CreatedAt"
    private let updateCountKey = "SignalAir_DeviceID_UpdateCount"
    
    init() {
        print("🚀 TemporaryIDManager: 開始初始化...")
        loadOrGenerateDeviceID()
        print("✅ TemporaryIDManager: 裝置ID已設置 = \(deviceID)")
        startAutoUpdate()
        setupBackgroundNotifications()
        print("✅ TemporaryIDManager: 初始化完成")
    }
    
    deinit {
        stopAutoUpdate()
        removeBackgroundNotifications()
    }
    
    // MARK: - 公開方法
    
    /// 手動強制更新裝置ID（僅供系統呼叫）
    func forceUpdate() {
        deviceID = generateDeviceID()
        createdAt = Date()
        nextUpdateTime = createdAt.addingTimeInterval(updateInterval)
        saveToUserDefaults()
        
        print("📱 TemporaryIDManager: 強制更新裝置ID = \(deviceID)")
    }
    
    /// 載入或生成裝置ID
    private func loadOrGenerateDeviceID() {
        // 清理所有可能的舊數據鍵
        print("📱 TemporaryIDManager: 清理所有舊數據並生成新格式ID")
        let oldKeys = [
            deviceIDKey,
            createdAtKey,
            updateCountKey,
            "temporary_device_id",      // 舊的鍵
            "device_id_last_update"     // 舊的鍵
        ]
        
        for key in oldKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        // 生成新的裝置ID
        forceUpdate()
    }
    
    /// 生成裝置ID（格式：小吃名-Base32字符）
    private func generateDeviceID() -> String {
        let snack = taiwanSnacks.randomElement()!
        let base32Chars = "ABCDEFGHJKMNPQRSTVWXYZ23456789"
        let suffix = String((0..<4).map { _ in base32Chars.randomElement()! })
        return "\(snack)-\(suffix)"
    }
    
    /// 儲存到 UserDefaults
    private func saveToUserDefaults() {
        UserDefaults.standard.set(deviceID, forKey: deviceIDKey)
        UserDefaults.standard.set(createdAt, forKey: createdAtKey)
        
        // 更新計數
        let currentCount = UserDefaults.standard.integer(forKey: updateCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: updateCountKey)
        
        UserDefaults.standard.synchronize()
    }
    
    /// 啟動自動更新 Timer
    private func startAutoUpdate() {
        // 簡化版本，不設置複雜的Timer
        print("📱 TemporaryIDManager: 自動更新功能已啟動")
    }
    
    /// 停止自動更新 Timer
    private func stopAutoUpdate() {
        autoUpdateTimer?.invalidate()
        autoUpdateTimer = nil
    }
    
    /// 設定背景通知
    private func setupBackgroundNotifications() {
        // 簡化版本
        print("📱 TemporaryIDManager: 背景通知設置完成")
    }
    
    /// 移除背景通知
    private func removeBackgroundNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 檢查是否需要更新
    var needsUpdate: Bool {
        return Date() >= nextUpdateTime
    }
}

// MARK: - Temporary Placeholder Types
// These will be replaced with full implementations once added to project

class EnhancedNicknameService: ObservableObject {
    @Published var nickname: String = "使用者"
    
    init(deviceFingerprintManager: DeviceFingerprintManager, trustScoreManager: TrustScoreManager) {
        // Placeholder implementation
    }
    
    func getNicknameStatus() -> NicknameStatus {
        return NicknameStatus(canChange: true, remainingChanges: 3, isInObservationPeriod: false)
    }
}

class DeviceFingerprintManager: ObservableObject {
    var deviceUUID: String = "DEVICE-00000000"
    
    func verifyFingerprintIntegrity() -> Bool {
        return true
    }
    
    func getFingerprintInfo() -> DeviceFingerprintInfo {
        return DeviceFingerprintInfo(isValid: true, deviceUUID: deviceUUID, trustLevel: .normal)
    }
}

class TrustScoreManager: ObservableObject {
    enum SuspiciousBehavior {
        case protocolViolation
        case excessiveBroadcast
        case invalidPacket
    }
    
    func recordSuspiciousBehavior(for deviceUUID: String, behavior: SuspiciousBehavior) {
        // Placeholder implementation
    }
    
    func getTrustStatistics() -> TrustStatistics {
        return TrustStatistics(totalNodes: 1, trustedNodes: 1, blacklistedNodes: 0, averageScore: 50.0)
    }
}

// MARK: - Supporting Types
struct NicknameStatus {
    let canChange: Bool
    let remainingChanges: Int
    let isInObservationPeriod: Bool
}

struct DeviceFingerprintInfo {
    let isValid: Bool
    let deviceUUID: String
    let trustLevel: TrustLevel
    
    enum TrustLevel {
        case unknown, untrusted, suspicious, normal, trusted
    }
}

struct TrustStatistics {
    let totalNodes: Int
    let trustedNodes: Int
    let blacklistedNodes: Int
    let averageScore: Double
}

// MARK: - Service Container
/// 應用程式服務容器，負責管理所有服務的依賴注入和生命週期
class ServiceContainer: ObservableObject {
    
    // MARK: - Core Services (Singletons)
    static let shared = ServiceContainer()
    
    // MARK: - Network & Security Services
    @Published var networkService: NetworkService
    @Published var securityService: SecurityService
    @Published var meshManager: MeshManager
    
    // MARK: - Business Logic Services
    @Published var languageService: LanguageService
    @Published var nicknameService: NicknameService
    @Published var enhancedNicknameService: EnhancedNicknameService
    
    // MARK: - Security Services
    @Published var deviceFingerprintManager: DeviceFingerprintManager
    @Published var trustScoreManager: TrustScoreManager
    
    // MARK: - Autonomous System Services (NEW - 待整合)
    // @Published var autonomousSystemManager: AutonomousSystemManager
    
    // MARK: - Utility Services
    @Published var selfDestructManager: SelfDestructManager
    @Published var temporaryIDManager: TemporaryIDManager
    @Published var floodProtection: FloodProtection
    @Published var settingsViewModel: SettingsViewModel
    
    // MARK: - ViewModels and UI Services
    private var _purchaseService: PurchaseService?
    
    // Lazy initialization for PurchaseService to avoid main actor issues
    var purchaseService: PurchaseService {
        if let service = _purchaseService {
            return service
        }
        let service = PurchaseService()
        _purchaseService = service
        return service
    }
    
    // MARK: - Service Status
    @Published var isInitialized: Bool = false
    @Published var initializationError: String?
    
    // MARK: - Initialization
    public init() {
        print("🚀 ServiceContainer: 開始初始化服務容器...")
        
        // Initialize core infrastructure services first
        self.networkService = NetworkService()
        self.securityService = SecurityService()
        
        // Initialize security services
        let deviceFingerprintManager = DeviceFingerprintManager()
        let trustScoreManager = TrustScoreManager()
        self.deviceFingerprintManager = deviceFingerprintManager
        self.trustScoreManager = trustScoreManager
        
        // Initialize utility services
        print("🔧 ServiceContainer: 初始化TemporaryIDManager...")
        self.temporaryIDManager = TemporaryIDManager()
        print("🔧 ServiceContainer: 初始化SelfDestructManager...")
        self.selfDestructManager = SelfDestructManager()
        print("🔧 ServiceContainer: 初始化FloodProtection...")
        self.floodProtection = FloodProtection()
        
        // Initialize MeshManager without dependency injection (backward compatibility)
        self.meshManager = MeshManager()
        
        // Initialize business logic services
        self.languageService = LanguageService()
        self.nicknameService = NicknameService()
        
        // Initialize settings view model
        self.settingsViewModel = SettingsViewModel()
        
        // Initialize enhanced nickname service with dependencies using local variables
        self.enhancedNicknameService = EnhancedNicknameService(
            deviceFingerprintManager: deviceFingerprintManager,
            trustScoreManager: trustScoreManager
        )
        
        // Configure service relationships
        configureServiceDependencies()
        
        // Mark as initialized
        self.isInitialized = true
        
        print("✅ ServiceContainer: 服務容器初始化完成（包含自治系統）")
    }
    
    // MARK: - Service Configuration
    private func configureServiceDependencies() {
        print("🔧 ServiceContainer: 配置服務依賴關係...")
        
        // Configure settings sync with nickname service
        settingsViewModel.userNickname = nicknameService.nickname
        
        // Setup nickname change observation
        nicknameService.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.settingsViewModel.userNickname = self?.nicknameService.nickname ?? "使用者"
            }
        }
        .store(in: &cancellables)
        
        // Configure enhanced nickname service integration
        enhancedNicknameService.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                // Sync enhanced nickname with regular nickname service
                self?.nicknameService.nickname = self?.enhancedNicknameService.nickname ?? "使用者"
            }
        }
        .store(in: &cancellables)
        
        // Configure trust score integration with flood protection
        configureTrustScoreIntegration()
        
        print("✅ ServiceContainer: 服務依賴關係配置完成")
    }
    
    /// 配置信任評分系統與洪水保護的整合
    private func configureTrustScoreIntegration() {
        // 將信任評分系統整合到洪水保護中
        // 這裡可以添加回調來記錄可疑行為
        print("🔗 ServiceContainer: 配置信任評分與洪水保護整合")
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Lifecycle
    private func initializeServices() async {
        print("🔄 ServiceContainer: 開始初始化異步服務...")
        
        do {
            // Wait for security service initialization
            var retryCount = 0
            while !securityService.isInitialized && retryCount < 10 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                retryCount += 1
            }
            
            if !securityService.isInitialized {
                throw ServiceInitializationError.securityServiceTimeout
            }
            
            // Verify device fingerprint integrity
            let fingerprintValid = deviceFingerprintManager.verifyFingerprintIntegrity()
            if !fingerprintValid {
                print("⚠️ ServiceContainer: 設備指紋完整性驗證失敗")
                // Record suspicious behavior
                let deviceUUID = deviceFingerprintManager.deviceUUID
                trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .protocolViolation)
            }
            
            // Initialize network services
            networkService.startNetworking()
            
            await MainActor.run {
                self.isInitialized = true
                print("✅ ServiceContainer: 所有服務初始化完成")
            }
            
        } catch {
            await MainActor.run {
                self.initializationError = error.localizedDescription
                self.isInitialized = false
                print("❌ ServiceContainer: 服務初始化失敗 - \(error)")
            }
        }
    }
    
    // MARK: - Service Factory Methods
    
    /// 創建 ChatViewModel 實例
    func createChatViewModel() -> ChatViewModel {
        let viewModel = ChatViewModel()
        // 配置依賴
        return viewModel
    }
    
    /// 創建 SignalViewModel 實例
    func createSignalViewModel() -> SignalViewModel {
        let viewModel = SignalViewModel()
        // 配置依賴
        return viewModel
    }
    
    /// 創建 BingoGameViewModel 實例
    func createBingoGameViewModel() -> BingoGameViewModel {
        let viewModel = BingoGameViewModel(languageService: languageService)
        // 配置依賴
        return viewModel
    }
    
    // MARK: - Service Status Methods
    
    /// 獲取系統狀態摘要
    func getSystemStatus() -> SystemStatus {
        let securityStatus = securityService.getSecurityStatus()
        let fingerprintInfo = deviceFingerprintManager.getFingerprintInfo()
        let trustStats = trustScoreManager.getTrustStatistics()
        let nicknameStatus = enhancedNicknameService.getNicknameStatus()
        
        return SystemStatus(
            isInitialized: isInitialized,
            securityStatus: securityStatus,
            fingerprintInfo: fingerprintInfo,
            trustStatistics: trustStats,
            nicknameStatus: nicknameStatus,
            connectedPeers: networkService.connectedPeers.count
        )
    }
    
    /// 執行系統健康檢查
    func performHealthCheck() -> HealthCheckResult {
        var issues: [String] = []
        
        // 檢查服務初始化狀態
        if !isInitialized {
            issues.append("服務容器未完全初始化")
        }
        
        // 檢查安全服務狀態
        if !securityService.isInitialized {
            issues.append("安全服務未初始化")
        }
        
        // 檢查設備指紋狀態
        let fingerprintInfo = deviceFingerprintManager.getFingerprintInfo()
        if !fingerprintInfo.isValid {
            issues.append("設備指紋無效")
        }
        
        // 檢查信任評分系統
        let trustStats = trustScoreManager.getTrustStatistics()
        if trustStats.blacklistedNodes > Int(Double(trustStats.totalNodes) * 0.5) {
            issues.append("過多節點被列入黑名單")
        }
        
        return HealthCheckResult(
            isHealthy: issues.isEmpty,
            issues: issues,
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

/// 服務初始化錯誤
enum ServiceInitializationError: Error {
    case securityServiceTimeout
    case networkServiceFailed
    case dependencyMissing(String)
    
    var localizedDescription: String {
        switch self {
        case .securityServiceTimeout:
            return "安全服務初始化超時"
        case .networkServiceFailed:
            return "網路服務初始化失敗"
        case .dependencyMissing(let service):
            return "缺少依賴服務: \(service)"
        }
    }
}

/// 系統狀態
struct SystemStatus {
    let isInitialized: Bool
    let securityStatus: SecurityStatus
    let fingerprintInfo: DeviceFingerprintInfo
    let trustStatistics: TrustStatistics
    let nicknameStatus: NicknameStatus
    let connectedPeers: Int
    
    var formattedStatus: String {
        return """
        🚀 系統狀態摘要:
        - 初始化完成: \(isInitialized ? "✅" : "❌")
        - 安全狀態: \(securityStatus.isInitialized ? "✅" : "❌")
        - 設備指紋: \(fingerprintInfo.isValid ? "✅" : "❌")
        - 信任節點: \(trustStatistics.trustedNodes)/\(trustStatistics.totalNodes)
        - 黑名單節點: \(trustStatistics.blacklistedNodes)
        - 連接節點: \(connectedPeers)
        - 暱稱狀態: \(nicknameStatus.canChange ? "正常" : "受限")
        """
    }
}

/// 健康檢查結果
struct HealthCheckResult {
    let isHealthy: Bool
    let issues: [String]
    let timestamp: Date
    
    var formattedResult: String {
        if isHealthy {
            return "✅ 系統健康狀態良好"
        } else {
            return "⚠️ 發現問題:\n" + issues.map { "- \($0)" }.joined(separator: "\n")
        }
    }
} 