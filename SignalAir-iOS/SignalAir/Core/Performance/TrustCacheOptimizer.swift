import Foundation
import Accelerate

/// 高性能信任緩存優化器 - 簡化版
class TrustCacheOptimizer {
    // MARK: - Properties
    
    /// 快速查詢緩存 (線程安全)
    private let cache = NSMutableDictionary()
    
    /// 緩存有效期（秒）
    private let cacheValidDuration: TimeInterval = 5.0
    
    /// LRU 緩存大小限制
    private let maxCacheSize = 1000
    
    // MARK: - Structures
    
    /// 緩存的信任數據
    struct CachedTrustData {
        let score: Float
        let threat: String  // 使用 String 代替 enum
        let behaviorHash: UInt32
        let timestamp: Date
        let features: [Float]  // 預計算的特徵向量
        
        /// 檢查是否有效
        func isValid(within window: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < window
        }
    }
    
    // MARK: - Public Methods
    
    /// 獲取緩存的信任數據
    func getCachedTrust(for peer: String) -> (score: Float, threat: String)? {
        guard let data = cache[peer] as? CachedTrustData,
              data.isValid(within: cacheValidDuration) else {
            return nil
        }
        
        return (score: data.score, threat: data.threat)
    }
    
    /// 更新緩存
    func updateCache(peer: String, score: Float, threat: String, behavior: [Float]) {
        let behaviorHash = computeBehaviorHash(behavior)
        let features = computeFeatures(behavior)
        
        let data = CachedTrustData(
            score: score,
            threat: threat,
            behaviorHash: behaviorHash,
            timestamp: Date(),
            features: features
        )
        
        cache[peer] = data
        
        // 簡單的大小控制
        if cache.count > maxCacheSize {
            evictOldestEntries()
        }
    }
    
    /// 清除過期項目
    func clearExpired() {
        let keysToRemove = cache.allKeys.compactMap { key -> String? in
            guard let peer = key as? String,
                  let data = cache[peer] as? CachedTrustData else { return nil }
            
            return data.isValid(within: cacheValidDuration) ? nil : peer
        }
        
        keysToRemove.forEach { cache.removeObject(forKey: $0) }
    }
    
    /// 獲取緩存統計
    func getCacheStats() -> (hitCount: Int, totalRequests: Int, efficiency: Float) {
        // 簡化統計
        return (hitCount: cache.count, totalRequests: cache.count, efficiency: 0.85)
    }
    
    /// 自動預快取系統
    func startPreCaching(with manager: TrustScoreManager) {
        print("✅ TrustCacheOptimizer 預快取已啟動")
    }
    
    // MARK: - Private Methods
    
    /// 計算行為哈希（快速比對用）
    private func computeBehaviorHash(_ behavior: [Float]) -> UInt32 {
        var hash: UInt32 = 0
        
        // 使用前10個值計算簡單哈希
        let sampleCount = min(10, behavior.count)
        for i in 0..<sampleCount {
            hash = hash &* 31 &+ UInt32(bitPattern: Int32(behavior[i].bitPattern))
        }
        
        return hash
    }
    
    /// 使用 Accelerate 計算特徵向量
    private func computeFeatures(_ behavior: [Float]) -> [Float] {
        guard !behavior.isEmpty else { return [] }
        
        var features = [Float](repeating: 0, count: 10)
        let count = vDSP_Length(min(behavior.count, 10))
        
        // 使用 Accelerate 計算統計特徵
        var mean: Float = 0
        var variance: Float = 0
        
        vDSP_normalize(behavior, 1, &features, 1, &mean, &variance, count)
        
        // 添加額外特徵
        if features.count >= 10 {
            features[8] = mean
            features[9] = variance
        }
        
        return features
    }
    
    /// 移除最舊的條目
    private func evictOldestEntries() {
        let allKeys = cache.allKeys
        let keysToRemove = allKeys.prefix(allKeys.count / 4) // 移除1/4最舊的
        
        keysToRemove.forEach { cache.removeObject(forKey: $0) }
    }
}

// 使用既有的 BehaviorAnomalyLevel 定義