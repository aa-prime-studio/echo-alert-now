import Foundation
import SwiftUI
import Combine

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
        self.temporaryIDManager = TemporaryIDManager()
        self.selfDestructManager = SelfDestructManager()
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
        
        // Start essential services
        Task {
            await initializeServices()
        }
        
        print("✅ ServiceContainer: 服務容器初始化完成")
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
        let viewModel = BingoGameViewModel()
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