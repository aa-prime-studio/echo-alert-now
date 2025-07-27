import Foundation

//
// NetworkSecurityConfig.swift
// SignalAir
//
// 統一的網路安全配置管理
//

/// 網路安全配置結構
struct NetworkSecurityConfig {
    // MARK: - 連線速率管理配置
    let connectionRateManager: ConnectionRateManagerConfig
    
    // MARK: - 網路層配置
    let maxDataPacketSize: Int
    let connectionTimeout: TimeInterval
    let maxConnections: Int
    let retryAttempts: Int
    
    // MARK: - 安全檢查配置
    let enableMaliciousContentDetection: Bool
    let enableSizeValidation: Bool
    let enableRateLimit: Bool
    let enableSecurityEventLogging: Bool
    
    // MARK: - 緊急訊息配置
    let emergencyBypassEnabled: Bool
    let emergencyMessageTypes: Set<String>
    
    // MARK: - 自動封禁配置
    let autobanEnabled: Bool
    let autobanThreshold: Int
    let autobanDuration: TimeInterval
    
    // MARK: - 預設配置
    static let `default` = NetworkSecurityConfig(
        connectionRateManager: ConnectionRateManagerConfig.default,
        maxDataPacketSize: 1024 * 1024, // 1MB
        connectionTimeout: 30.0,
        maxConnections: 15,
        retryAttempts: 3,
        enableMaliciousContentDetection: true,
        enableSizeValidation: true,
        enableRateLimit: true,
        enableSecurityEventLogging: true,
        emergencyBypassEnabled: true,
        emergencyMessageTypes: ["emergency", "medical", "danger", "keyExchange", "system"],
        autobanEnabled: true,
        autobanThreshold: 5,
        autobanDuration: 300.0 // 5分鐘
    )
    
    // MARK: - 災難環境配置（更嚴格的安全設定）
    static let disaster = NetworkSecurityConfig(
        connectionRateManager: ConnectionRateManagerConfig(
            maxMessagesPerSecond: 5,  // 更嚴格的速率限制
            maxMessagesPerMinute: 50,
            maxBurstSize: 10,
            banDuration: 600, // 10分鐘封禁
            windowSize: 60
        ),
        maxDataPacketSize: 512 * 1024, // 512KB
        connectionTimeout: 20.0,
        maxConnections: 10,
        retryAttempts: 2,
        enableMaliciousContentDetection: true,
        enableSizeValidation: true,
        enableRateLimit: true,
        enableSecurityEventLogging: true,
        emergencyBypassEnabled: true,
        emergencyMessageTypes: ["emergency", "medical", "danger", "keyExchange", "system"],
        autobanEnabled: true,
        autobanThreshold: 3,
        autobanDuration: 600.0 // 10分鐘
    )
    
    // MARK: - 測試環境配置（較寬鬆的設定）
    static let testing = NetworkSecurityConfig(
        connectionRateManager: ConnectionRateManagerConfig(
            maxMessagesPerSecond: 20,
            maxMessagesPerMinute: 200,
            maxBurstSize: 50,
            banDuration: 60, // 1分鐘封禁
            windowSize: 60
        ),
        maxDataPacketSize: 2 * 1024 * 1024, // 2MB
        connectionTimeout: 60.0,
        maxConnections: 20,
        retryAttempts: 5,
        enableMaliciousContentDetection: false,
        enableSizeValidation: true,
        enableRateLimit: false,
        enableSecurityEventLogging: true,
        emergencyBypassEnabled: true,
        emergencyMessageTypes: ["emergency", "medical", "danger", "keyExchange", "system"],
        autobanEnabled: false,
        autobanThreshold: 10,
        autobanDuration: 60.0 // 1分鐘
    )
    
    // MARK: - 方法
    
    /// 根據環境類型獲取配置
    static func forEnvironment(_ environment: Environment) -> NetworkSecurityConfig {
        switch environment {
        case .production:
            return .default
        case .disaster:
            return .disaster
        case .testing:
            return .testing
        case .development:
            return .testing
        }
    }
    
    /// 驗證配置有效性
    func validate() throws {
        guard maxDataPacketSize > 0 else {
            throw NetworkSecurityConfigError.invalidMaxDataPacketSize
        }
        
        guard connectionTimeout > 0 else {
            throw NetworkSecurityConfigError.invalidConnectionTimeout
        }
        
        guard maxConnections > 0 else {
            throw NetworkSecurityConfigError.invalidMaxConnections
        }
        
        guard retryAttempts >= 0 else {
            throw NetworkSecurityConfigError.invalidRetryAttempts
        }
        
        guard autobanThreshold > 0 else {
            throw NetworkSecurityConfigError.invalidAutobanThreshold
        }
        
        guard autobanDuration > 0 else {
            throw NetworkSecurityConfigError.invalidAutobanDuration
        }
    }
    
    /// 生成配置摘要
    func summary() -> String {
        return """
        NetworkSecurityConfig Summary:
        - Connection Rate Manager: \(connectionRateManager.maxMessagesPerSecond)msg/s, \(connectionRateManager.maxMessagesPerMinute)msg/min
        - Max Packet Size: \(maxDataPacketSize / 1024)KB
        - Max Connections: \(maxConnections)
        - Malicious Detection: \(enableMaliciousContentDetection ? "ON" : "OFF")
        - Rate Limiting: \(enableRateLimit ? "ON" : "OFF")
        - Emergency Bypass: \(emergencyBypassEnabled ? "ON" : "OFF")
        - Auto-ban: \(autobanEnabled ? "ON" : "OFF") (threshold: \(autobanThreshold))
        """
    }
}

// MARK: - 環境類型
enum Environment: String, CaseIterable {
    case production = "production"
    case disaster = "disaster"
    case testing = "testing"
    case development = "development"
    
    var displayName: String {
        switch self {
        case .production:
            return "生產環境"
        case .disaster:
            return "災難環境"
        case .testing:
            return "測試環境"
        case .development:
            return "開發環境"
        }
    }
}

// MARK: - 錯誤定義
enum NetworkSecurityConfigError: Error, LocalizedError {
    case invalidMaxDataPacketSize
    case invalidConnectionTimeout
    case invalidMaxConnections
    case invalidRetryAttempts
    case invalidAutobanThreshold
    case invalidAutobanDuration
    
    var errorDescription: String? {
        switch self {
        case .invalidMaxDataPacketSize:
            return "無效的最大數據包大小"
        case .invalidConnectionTimeout:
            return "無效的連接超時時間"
        case .invalidMaxConnections:
            return "無效的最大連接數"
        case .invalidRetryAttempts:
            return "無效的重試次數"
        case .invalidAutobanThreshold:
            return "無效的自動封禁閾值"
        case .invalidAutobanDuration:
            return "無效的自動封禁持續時間"
        }
    }
}

// MARK: - 配置管理器
class NetworkSecurityConfigManager: ObservableObject {
    @Published var currentConfig: NetworkSecurityConfig
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "NetworkSecurityConfig"
    
    init() {
        // 根據當前環境選擇配置
        #if DEBUG
        self.currentConfig = NetworkSecurityConfig.testing
        #else
        self.currentConfig = NetworkSecurityConfig.default
        #endif
        
        loadConfiguration()
    }
    
    /// 載入配置
    private func loadConfiguration() {
        // 這裡可以從 UserDefaults 或遠端配置載入
        // 目前使用預設配置
        print("🔧 NetworkSecurityConfig: 載入配置 - \(currentConfig.summary())")
    }
    
    /// 保存配置
    func saveConfiguration() {
        // 這裡可以保存到 UserDefaults 或遠端
        print("💾 NetworkSecurityConfig: 配置已保存")
    }
    
    /// 更新配置
    func updateConfiguration(_ newConfig: NetworkSecurityConfig) {
        do {
            try newConfig.validate()
            self.currentConfig = newConfig
            saveConfiguration()
            print("✅ NetworkSecurityConfig: 配置已更新")
        } catch {
            print("❌ NetworkSecurityConfig: 配置更新失敗 - \(error.localizedDescription)")
        }
    }
    
    /// 重置為預設配置
    func resetToDefault() {
        updateConfiguration(.default)
    }
    
    /// 切換到災難模式
    func switchToDisasterMode() {
        updateConfiguration(.disaster)
        print("🚨 NetworkSecurityConfig: 已切換到災難模式")
    }
    
    /// 切換到測試模式
    func switchToTestingMode() {
        updateConfiguration(.testing)
        print("🧪 NetworkSecurityConfig: 已切換到測試模式")
    }
}