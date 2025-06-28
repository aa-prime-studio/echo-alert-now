import Foundation
import SwiftUI

// 服務容器 - 集中管理所有服務實例
class ServiceContainer: ObservableObject {
    
    // 單例實例
    static let shared = ServiceContainer()
    
    // 核心服務
    lazy var languageService = LanguageService()
    lazy var networkService = NetworkService()
    lazy var securityService = SecurityService()
    lazy var temporaryIDManager = TemporaryIDManager()
    lazy var nicknameService = NicknameService()
    lazy var purchaseService = PurchaseService()
    
    // 輔助服務
    lazy var meshManager = MeshManager()
    lazy var selfDestructManager = SelfDestructManager()
    lazy var floodProtection = FloodProtection()
    
    // ViewModels
    lazy var settingsViewModel = SettingsViewModel()
    
    private init() {
        setupServices()
    }
    
    private func setupServices() {
        // 設定服務間的依賴關係
        networkService.temporaryIDManager = temporaryIDManager
        nicknameService.temporaryIDManager = temporaryIDManager
    }
}
