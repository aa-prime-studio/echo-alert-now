import Foundation

/// 🎯 服務初始化器 - 解決 ServiceContainer 初始化競態條件
@MainActor
actor ServiceInitializer {
    
    // MARK: - 初始化狀態
    enum InitializationState {
        case notStarted
        case basicServices
        case networkServices
        case meshServices
        case completed
        case failed(Error)
    }
    
    private var currentState: InitializationState = .notStarted
    private var initializationError: Error?
    
    // MARK: - 初始化步驟
    func initializeServices(container: ServiceContainer) async throws {
        print("🚀 ServiceInitializer: 開始順序初始化服務...")
        
        do {
            // 第一階段：基礎服務
            currentState = .basicServices
            try await initializeBasicServices(container: container)
            print("✅ 基礎服務初始化完成")
            
            // 第二階段：網路服務
            currentState = .networkServices
            try await initializeNetworkServices(container: container)
            print("✅ 網路服務初始化完成")
            
            // 第三階段：網格服務
            currentState = .meshServices
            try await initializeMeshServices(container: container)
            print("✅ 網格服務初始化完成")
            
            // 完成
            currentState = .completed
            print("🎉 ServiceInitializer: 所有服務初始化完成")
            
        } catch {
            currentState = .failed(error)
            initializationError = error
            print("❌ ServiceInitializer: 初始化失敗 - \(error)")
            throw error
        }
    }
    
    // MARK: - 第一階段：基礎服務
    private func initializeBasicServices(container: ServiceContainer) async throws {
        // 語言服務 - 必須最先初始化
        container.languageService.loadTranslations()
        
        // 暱稱服務
        container.nicknameService.loadNickname()
        
        // 設定服務
        container.settingsViewModel.loadSettings()
        
        // 購買服務
        await container.purchaseService.initialize()
        
        // 等待基礎服務穩定
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
    
    // MARK: - 第二階段：網路服務
    private func initializeNetworkServices(container: ServiceContainer) async throws {
        // 安全服務
        try await container.securityService.initializeKeystore()
        
        // 網路服務
        container.networkService.initializeNetwork()
        
        // 連接優化器
        container.connectionOptimizer.initialize()
        
        // 連線速率管理
        container.connectionRateManager.initialize()
        
        // 等待網路服務穩定
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
    }
    
    // MARK: - 第三階段：網格服務
    private func initializeMeshServices(container: ServiceContainer) async throws {
        // 創建 MeshManager（依賴前面的服務）
        container.meshManager = MeshManager(
            networkService: container.networkService,
            securityService: container.securityService,
            connectionRateManager: container.connectionRateManager
        )
        
        // 設置回調
        container.setupKeyExchangeCallbacks()
        container.setupSessionKeyMonitoring()
        
        // 啟動網路（延遲啟動）
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        container.networkService.startNetworking()
        
        print("🌐 網路服務已啟動")
    }
    
    // MARK: - 狀態查詢
    func getCurrentState() -> InitializationState {
        return currentState
    }
    
    func getInitializationError() -> Error? {
        return initializationError
    }
    
    func isCompleted() -> Bool {
        switch currentState {
        case .completed:
            return true
        default:
            return false
        }
    }
    
    func hasFailed() -> Bool {
        switch currentState {
        case .failed:
            return true
        default:
            return false
        }
    }
}

// MARK: - 服務初始化錯誤
enum ServiceInitializationError: LocalizedError {
    case basicServicesFailed(Error)
    case networkServicesFailed(Error)
    case meshServicesFailed(Error)
    case timeout
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .basicServicesFailed(let error):
            return "基礎服務初始化失敗: \(error.localizedDescription)"
        case .networkServicesFailed(let error):
            return "網路服務初始化失敗: \(error.localizedDescription)"
        case .meshServicesFailed(let error):
            return "網格服務初始化失敗: \(error.localizedDescription)"
        case .timeout:
            return "服務初始化超時"
        case .cancelled:
            return "服務初始化被取消"
        }
    }
}