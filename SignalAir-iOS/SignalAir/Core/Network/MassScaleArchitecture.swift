import Foundation
import MultipeerConnectivity

// MARK: - Mass Scale Architecture for 300K Users
// 專為30萬人同時使用設計的分層網路架構

/// 節點類型 - 分層架構
enum NodeType {
    case regular      // 普通節點（大多數用戶）
    case relay        // 中繼節點（連接數20-50）
    case superNode    // 超級節點（連接數50-100）
    case backbone     // 骨幹節點（連接數100+）
}

/// 30萬人規模的網路架構管理器
class MassScaleNetworkArchitecture {
    
    // MARK: - 分層網路設計
    /*
     300,000 人分層架構：
     
     第1層：骨幹節點 (30個)
     - 每個連接100個超級節點
     - 互相全連接（30×29/2 = 435個連接）
     
     第2層：超級節點 (3,000個)
     - 每個連接50個中繼節點
     - 連接10個骨幹節點
     
     第3層：中繼節點 (30,000個)
     - 每個連接30個普通節點
     - 連接5個超級節點
     
     第4層：普通節點 (267,000個)
     - 每個連接5-10個其他節點
     - 至少連接1個中繼節點
     */
    
    private var currentNodeType: NodeType = .regular
    private var connectionScore: Int = 0
    private var resourceScore: Int = 0
    
    // MARK: - 智能節點升級機制
    
    func evaluateNodePromotion(
        connectionCount: Int,
        batteryLevel: Float,
        networkQuality: Float,
        cpuUsage: Float
    ) -> NodeType {
        
        // 計算資源評分
        resourceScore = Int(
            batteryLevel * 30 +        // 電池權重30%
            networkQuality * 40 +      // 網路品質40%
            (1 - cpuUsage) * 30       // CPU空閒率30%
        )
        
        // 根據連接數和資源決定節點類型
        switch (connectionCount, resourceScore) {
        case (100..., 80...):
            return .backbone
        case (50..<100, 70...):
            return .superNode
        case (20..<50, 60...):
            return .relay
        default:
            return .regular
        }
    }
    
    // MARK: - 消息優先級路由
    
    func determineRoutingPriority(for message: BinaryMessageType, nodeType: NodeType) -> RoutingPriority {
        switch (message, nodeType) {
        case (.signal, .backbone), (.signal, .superNode):
            return .express  // 緊急信號走快速通道
        case (.signal, _):
            return .high
        case (.chat, .regular):
            return .normal
        default:
            return .low
        }
    }
    
    enum RoutingPriority {
        case express   // 立即轉發，跳過隊列
        case high      // 高優先級隊列
        case normal    // 標準隊列
        case low       // 低優先級，可延遲
    }
}

// MARK: - 進階消息傳播策略

class AdvancedPropagationStrategy {
    
    /// 智能廣播策略 - 避免網路風暴
    static func smartBroadcast(
        message: Data,
        from nodeType: NodeType,
        to peers: [MCPeerID],
        priority: MassScaleNetworkArchitecture.RoutingPriority
    ) -> [MCPeerID] {
        
        switch nodeType {
        case .backbone:
            // 骨幹節點：全部轉發
            return peers
            
        case .superNode:
            // 超級節點：選擇性轉發
            let maxForward = priority == .express ? 30 : 20
            return selectBestPeers(from: peers, limit: maxForward)
            
        case .relay:
            // 中繼節點：限制轉發
            let maxForward = priority == .express ? 15 : 10
            return selectBestPeers(from: peers, limit: maxForward)
            
        case .regular:
            // 普通節點：最小轉發
            let maxForward = priority == .express ? 5 : 3
            return selectBestPeers(from: peers, limit: maxForward)
        }
    }
    
    /// 選擇最佳轉發目標
    private static func selectBestPeers(from peers: [MCPeerID], limit: Int) -> [MCPeerID] {
        // TODO: 基於以下因素選擇：
        // 1. 節點類型（優先上級節點）
        // 2. 地理位置（優先不同區域）
        // 3. 負載狀況（避免過載節點）
        // 4. 歷史可靠性
        
        return Array(peers.prefix(limit))
    }
}

// MARK: - 地理分區優化

class GeographicPartitioning {
    
    /// 基於網格的地理分區
    struct GeoCluster {
        let id: String
        let centerGrid: String
        let radius: Int  // 網格半徑
        var nodeCount: Int
        var backboneNodes: Set<String>
        
        /// 是否需要更多骨幹節點
        var needsMoreBackbone: Bool {
            return nodeCount > 10000 && backboneNodes.count < 3
        }
    }
    
    private var clusters: [String: GeoCluster] = [:]
    
    /// 動態集群管理
    func updateCluster(for gridCode: String, nodeCount: Int) {
        let clusterId = getClusterId(for: gridCode)
        
        if var cluster = clusters[clusterId] {
            cluster.nodeCount = nodeCount
            
            // 如果集群過大，考慮分裂
            if cluster.nodeCount > 20000 {
                splitCluster(cluster)
            }
            
            clusters[clusterId] = cluster
        }
    }
    
    private func splitCluster(_ cluster: GeoCluster) {
        print("📍 分裂過大集群：\(cluster.id)，當前節點數：\(cluster.nodeCount)")
        // 實施集群分裂邏輯
    }
    
    private func getClusterId(for gridCode: String) -> String {
        // 簡化：使用網格碼前4位作為集群ID
        return String(gridCode.prefix(4))
    }
}

// MARK: - 流量控制與擁塞避免

class TrafficControl {
    
    /// 令牌桶算法實現
    class TokenBucket {
        private let capacity: Int
        private let refillRate: Double  // 每秒補充的令牌數
        private var tokens: Double
        private var lastRefill: Date
        private let queue = DispatchQueue(label: "tokenbucket")
        
        init(capacity: Int, refillRate: Double) {
            self.capacity = capacity
            self.refillRate = refillRate
            self.tokens = Double(capacity)
            self.lastRefill = Date()
        }
        
        func consume(_ count: Int = 1) -> Bool {
            return queue.sync {
                refill()
                
                if tokens >= Double(count) {
                    tokens -= Double(count)
                    return true
                }
                return false
            }
        }
        
        private func refill() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRefill)
            tokens = min(Double(capacity), tokens + elapsed * refillRate)
            lastRefill = now
        }
    }
    
    /// 自適應流量控制
    static func createAdaptiveTokenBucket(for nodeType: NodeType) -> TokenBucket {
        switch nodeType {
        case .backbone:
            return TokenBucket(capacity: 1000, refillRate: 100)  // 每秒100個消息
        case .superNode:
            return TokenBucket(capacity: 500, refillRate: 50)
        case .relay:
            return TokenBucket(capacity: 200, refillRate: 20)
        case .regular:
            return TokenBucket(capacity: 50, refillRate: 5)
        }
    }
}

// MARK: - 消息去重優化（30萬人規模）

class MassScaleDeduplication {
    
    /// 布隆過濾器實現 - 極省記憶體的去重方案
    class BloomFilter {
        private var bitArray: [Bool]
        private let size: Int
        private let hashCount: Int
        
        init(expectedElements: Int, falsePositiveRate: Double = 0.01) {
            // 計算最優大小
            let m = -Double(expectedElements) * log(falsePositiveRate) / pow(log(2), 2)
            self.size = Int(ceil(m))
            self.bitArray = Array(repeating: false, count: size)
            
            // 計算最優哈希函數數量
            let k = Double(size) / Double(expectedElements) * log(2)
            self.hashCount = max(1, Int(round(k)))
        }
        
        func insert(_ data: Data) {
            for i in 0..<hashCount {
                let hash = getHash(data, seed: i)
                bitArray[hash % size] = true
            }
        }
        
        func contains(_ data: Data) -> Bool {
            for i in 0..<hashCount {
                let hash = getHash(data, seed: i)
                if !bitArray[hash % size] {
                    return false
                }
            }
            return true
        }
        
        private func getHash(_ data: Data, seed: Int) -> Int {
            var hasher = Hasher()
            hasher.combine(data)
            hasher.combine(seed)
            return abs(hasher.finalize())
        }
    }
    
    /// 30萬人場景的消息去重
    static func createDeduplicator() -> BloomFilter {
        // 預期30萬人，每人每分鐘1條消息，保留10分鐘
        // = 3,000,000 條消息
        return BloomFilter(expectedElements: 3_000_000, falsePositiveRate: 0.001)
    }
}

// MARK: - 效能監控（30萬人規模）

class MassScalePerformanceMonitor {
    
    struct Metrics {
        // 網路指標
        var totalNodes: Int = 0
        var activeNodes: Int = 0
        var messageRate: Double = 0  // 每秒消息數
        var avgLatency: Double = 0   // 平均延遲(ms)
        
        // 分層統計
        var backboneNodes: Int = 0
        var superNodes: Int = 0
        var relayNodes: Int = 0
        var regularNodes: Int = 0
        
        // 地理分佈
        var clusterCount: Int = 0
        var largestCluster: Int = 0
        var isolatedNodes: Int = 0
        
        // 系統資源
        var cpuUsage: Double = 0
        var memoryUsage: Double = 0
        var batteryDrain: Double = 0  // 每小時耗電%
    }
    
    /// 生成效能報告
    static func generateReport(_ metrics: Metrics) -> String {
        let efficiency = Double(metrics.activeNodes) / Double(max(1, metrics.totalNodes)) * 100
        
        return """
        📊 30萬人網路效能報告
        ════════════════════════════════
        總節點數: \(metrics.totalNodes.formatted())
        活躍節點: \(metrics.activeNodes.formatted()) (\(String(format: "%.1f%%", efficiency)))
        
        分層架構:
        ├─ 骨幹: \(metrics.backboneNodes)
        ├─ 超級: \(metrics.superNodes)
        ├─ 中繼: \(metrics.relayNodes)
        └─ 普通: \(metrics.regularNodes)
        
        網路性能:
        ├─ 消息速率: \(String(format: "%.0f", metrics.messageRate))/秒
        ├─ 平均延遲: \(String(format: "%.0f", metrics.avgLatency))ms
        └─ 最大集群: \(metrics.largestCluster.formatted())
        
        資源使用:
        ├─ CPU: \(String(format: "%.1f%%", metrics.cpuUsage))
        ├─ 記憶體: \(String(format: "%.0f", metrics.memoryUsage))MB
        └─ 耗電: \(String(format: "%.1f%%", metrics.batteryDrain))/小時
        ════════════════════════════════
        """
    }
}