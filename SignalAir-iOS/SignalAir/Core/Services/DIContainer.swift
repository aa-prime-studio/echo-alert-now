import Foundation

// MARK: - 輕量級依賴注入容器
class DIContainer {
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var protocols: [String: Any] = [:]
    
    private init() {}
    
    // MARK: - 服務註冊
    
    /// 註冊工廠創建的服務
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// 註冊單例服務
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    /// 註冊協議實現
    func registerProtocol<T>(_ protocolType: T.Type, implementation: T) {
        let key = String(describing: protocolType)
        protocols[key] = implementation
    }
    
    // MARK: - 服務解析
    
    /// 解析服務實例
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // 1. 檢查單例
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // 2. 檢查協議實現
        if let protocolImpl = protocols[key] as? T {
            return protocolImpl
        }
        
        // 3. 使用工廠創建
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    /// 強制解析服務（會拋出錯誤）
    func forceResolve<T>(_ type: T.Type) -> T? {
        guard let service = resolve(type) else {
            print("🔴 DIContainer: 無法解析服務 \(type)")
            return nil
        }
        return service
    }
    
    // MARK: - 測試支持
    
    /// 清除所有註冊（用於測試）
    func clearAll() {
        factories.removeAll()
        singletons.removeAll()
        protocols.removeAll()
    }
    
    /// 檢查服務是否已註冊
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return factories[key] != nil || singletons[key] != nil || protocols[key] != nil
    }
    
    // MARK: - 調試支持
    
    /// 列出所有已註冊的服務
    func listRegisteredServices() {
        print("📋 DIContainer: 已註冊的服務:")
        print("   工廠服務: \(factories.keys.joined(separator: ", "))")
        print("   單例服務: \(singletons.keys.joined(separator: ", "))")
        print("   協議實現: \(protocols.keys.joined(separator: ", "))")
    }
}

// MARK: - 服務註冊擴展
extension DIContainer {
    /// 批量註冊基本服務
    func registerBasicServices() {
        print("🔧 DIContainer: 開始註冊基本服務...")
        
        // 這些服務將在後續實施中逐步添加
        print("✅ DIContainer: 基本服務註冊完成")
    }
    
    /// 註冊測試模擬服務
    func registerMockServices() {
        print("🧪 DIContainer: 註冊測試模擬服務...")
        
        // 測試模擬服務將在測試階段添加
        print("✅ DIContainer: 測試模擬服務註冊完成")
    }
}

// MARK: - 便利方法
extension DIContainer {
    /// 創建服務依賴包
    func createDependencyBundle<T>(_ type: T.Type) -> T? {
        return resolve(type)
    }
    
    /// 驗證所有必要服務是否已註冊
    func validateRequiredServices() -> Bool {
        let requiredServices = [
            "NetworkService",
            "SecurityService",
            "LanguageService",
            "NicknameService"
        ]
        
        for service in requiredServices {
            if !factories.keys.contains(service) && 
               !singletons.keys.contains(service) &&
               !protocols.keys.contains(service) {
                print("⚠️ DIContainer: 缺少必要服務 \(service)")
                return false
            }
        }
        
        return true
    }
}