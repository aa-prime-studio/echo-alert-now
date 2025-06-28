import Foundation

// MARK: - Cache Retention Policy

/// 快取保留策略
enum CacheRetentionPolicy: String, CaseIterable {
    case conservative = "conservative"  // 保守：15分鐘
    case balanced = "balanced"         // 平衡：30分鐘  
    case relaxed = "relaxed"          // 寬鬆：60分鐘
    
    /// 獲取對應的時間窗口（秒）
    var timeWindow: TimeInterval {
        switch self {
        case .conservative:
            return 900   // 15分鐘
        case .balanced:
            return 1800  // 30分鐘
        case .relaxed:
            return 3600  // 60分鐘
        }
    }
    
    /// 獲取清理間隔（秒）
    var cleanupInterval: TimeInterval {
        switch self {
        case .conservative:
            return 300   // 5分鐘清理一次
        case .balanced:
            return 600   // 10分鐘清理一次
        case .relaxed:
            return 900   // 15分鐘清理一次
        }
    }
    
    /// 獲取最大快取大小
    var maxCacheSize: Int {
        switch self {
        case .conservative:
            return 500   // 較小的快取
        case .balanced:
            return 1000  // 中等快取
        case .relaxed:
            return 2000  // 較大的快取
        }
    }
    
    /// 顯示名稱
    var displayName: String {
        switch self {
        case .conservative:
            return "保守模式 (15分鐘)"
        case .balanced:
            return "平衡模式 (30分鐘)"
        case .relaxed:
            return "寬鬆模式 (60分鐘)"
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .conservative:
            return "最短保留時間，最高安全性，較低記憶體使用"
        case .balanced:
            return "平衡安全性與效能，推薦設定"
        case .relaxed:
            return "較長保留時間，更好的去重效果，較高記憶體使用"
        }
    }
    
    /// 安全等級
    var securityLevel: SecurityLevel {
        switch self {
        case .conservative:
            return .high
        case .balanced:
            return .medium
        case .relaxed:
            return .low
        }
    }
}

// MARK: - Security Level

enum SecurityLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "orange"
        case .medium:
            return "blue"
        case .high:
            return "green"
        }
    }
}

// MARK: - Cache Configuration Manager

class CacheConfigurationManager: ObservableObject {
    static let shared = CacheConfigurationManager()
    
    @Published var currentPolicy: CacheRetentionPolicy = .balanced
    
    private let userDefaults = UserDefaults.standard
    private let policyKey = "CacheRetentionPolicy"
    
    private init() {
        loadConfiguration()
    }
    
    /// 載入配置
    private func loadConfiguration() {
        if let savedPolicy = userDefaults.string(forKey: policyKey),
           let policy = CacheRetentionPolicy(rawValue: savedPolicy) {
            currentPolicy = policy
        } else {
            // 預設使用平衡模式
            currentPolicy = .balanced
            saveConfiguration()
        }
        
        print("📋 CacheConfiguration: 載入快取策略 - \(currentPolicy.displayName)")
    }
    
    /// 儲存配置
    private func saveConfiguration() {
        userDefaults.set(currentPolicy.rawValue, forKey: policyKey)
        userDefaults.synchronize()
        print("💾 CacheConfiguration: 儲存快取策略 - \(currentPolicy.displayName)")
    }
    
    /// 更新快取策略
    func updatePolicy(_ newPolicy: CacheRetentionPolicy) {
        let oldPolicy = currentPolicy
        currentPolicy = newPolicy
        saveConfiguration()
        
        // 發送通知給其他元件
        NotificationCenter.default.post(
            name: .cacheConfigurationChanged,
            object: nil,
            userInfo: [
                "oldPolicy": oldPolicy,
                "newPolicy": newPolicy
            ]
        )
        
        print("🔄 CacheConfiguration: 更新快取策略 \(oldPolicy.displayName) → \(newPolicy.displayName)")
    }
    
    /// 獲取當前配置
    func getCurrentConfiguration() -> CacheConfiguration {
        return CacheConfiguration(
            policy: currentPolicy,
            timeWindow: currentPolicy.timeWindow,
            cleanupInterval: currentPolicy.cleanupInterval,
            maxCacheSize: currentPolicy.maxCacheSize
        )
    }
    
    /// 根據系統狀態自動調整策略
    func autoAdjustPolicy() {
        let memoryPressure = getMemoryPressure()
        let batteryLevel = getBatteryLevel()
        
        var recommendedPolicy: CacheRetentionPolicy
        
        if memoryPressure > 0.8 || batteryLevel < 0.2 {
            recommendedPolicy = .conservative
        } else if memoryPressure > 0.6 || batteryLevel < 0.5 {
            recommendedPolicy = .balanced
        } else {
            recommendedPolicy = .relaxed
        }
        
        if recommendedPolicy != currentPolicy {
            print("🤖 CacheConfiguration: 自動調整策略建議 - \(recommendedPolicy.displayName)")
            // 可以選擇自動應用或僅記錄建議
        }
    }
    
    /// 獲取記憶體壓力（模擬）
    private func getMemoryPressure() -> Double {
        // 實際實作中應該使用真實的記憶體監控
        return 0.5 // 模擬值
    }
    
    /// 獲取電池電量（模擬）
    private func getBatteryLevel() -> Double {
        // 實際實作中應該使用 UIDevice.current.batteryLevel
        return 0.8 // 模擬值
    }
}

// MARK: - Cache Configuration

struct CacheConfiguration {
    let policy: CacheRetentionPolicy
    let timeWindow: TimeInterval
    let cleanupInterval: TimeInterval
    let maxCacheSize: Int
    
    var summary: String {
        return """
        快取策略: \(policy.displayName)
        時間窗口: \(Int(timeWindow/60)) 分鐘
        清理間隔: \(Int(cleanupInterval/60)) 分鐘
        最大大小: \(maxCacheSize) 項目
        安全等級: \(policy.securityLevel.displayName)
        """
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let cacheConfigurationChanged = Notification.Name("CacheConfigurationChanged")
}

// MARK: - Cache Performance Monitor

class CachePerformanceMonitor {
    private var hitCount = 0
    private var missCount = 0
    private var evictionCount = 0
    private var startTime = Date()
    
    func recordHit() {
        hitCount += 1
    }
    
    func recordMiss() {
        missCount += 1
    }
    
    func recordEviction() {
        evictionCount += 1
    }
    
    func getStatistics() -> CacheStatistics {
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
        let runTime = Date().timeIntervalSince(startTime)
        
        return CacheStatistics(
            hitCount: hitCount,
            missCount: missCount,
            evictionCount: evictionCount,
            hitRate: hitRate,
            totalRequests: totalRequests,
            runTime: runTime
        )
    }
    
    func reset() {
        hitCount = 0
        missCount = 0
        evictionCount = 0
        startTime = Date()
    }
}

struct CacheStatistics {
    let hitCount: Int
    let missCount: Int
    let evictionCount: Int
    let hitRate: Double
    let totalRequests: Int
    let runTime: TimeInterval
    
    var summary: String {
        return """
        命中次數: \(hitCount)
        未命中次數: \(missCount)
        驅逐次數: \(evictionCount)
        命中率: \(String(format: "%.1f", hitRate * 100))%
        總請求數: \(totalRequests)
        運行時間: \(String(format: "%.1f", runTime/60)) 分鐘
        """
    }
} 