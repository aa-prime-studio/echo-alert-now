import XCTest
@testable import SignalAir

// MARK: - Performance Benchmark Tests
class PerformanceBenchmarkTests: XCTestCase {
    
    // MARK: - Test 1: 二進制協議編解碼效能測試
    func testBinaryProtocolPerformance() {
        let encoder = BinaryMessageEncoder()
        let decoder = BinaryMessageDecoder()
        
        // 準備測試資料
        let testMessages = [
            ("緊急！需要醫療協助", MessageType.emergency),
            ("大家都安全嗎？", MessageType.signal),
            ("我在這裡", MessageType.chat),
            ("BINGO!", MessageType.game)
        ]
        
        measure {
            for _ in 0..<1000 {
                for (content, type) in testMessages {
                    // 測試編碼
                    if let encoded = encoder.encode(content: content, type: type) {
                        // 測試解碼
                        _ = decoder.decode(encoded)
                    }
                }
            }
        }
    }
    
    // MARK: - Test 2: 設備指紋生成效能測試
    func testDeviceFingerprintGenerationPerformance() {
        measure {
            for _ in 0..<100 {
                // 模擬設備指紋生成
                let deviceInfo = "iPhone14,2|iOS16.0|\(arc4random())"
                let data = deviceInfo.data(using: .utf8)!
                
                // SHA256 雜湊計算
                let hash = SHA256.hash(data: data)
                let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
                _ = "DEVICE-\(hashString.prefix(8))"
            }
        }
    }
    
    // MARK: - Test 3: Bloom Filter 效能測試
    func testBloomFilterPerformance() {
        let bloomFilter = BloomFilter(expectedElements: 10000, falsePositiveRate: 0.01)
        
        // 準備測試資料
        let testDeviceIDs = (0..<10000).map { "DEVICE-\($0)" }
        
        measure {
            // 測試插入效能
            for deviceID in testDeviceIDs.prefix(1000) {
                bloomFilter.add(deviceID)
            }
            
            // 測試查詢效能
            for deviceID in testDeviceIDs.prefix(2000) {
                _ = bloomFilter.contains(deviceID)
            }
        }
    }
    
    // MARK: - Test 4: 路由快取效能測試
    func testRouteCachePerformance() {
        let routeCache = EmergencyRouteCache()
        
        // 準備測試資料
        let testMetrics = (0..<1000).map { i in
            SimpleRouteMetrics(
                peerID: "PEER-\(i)",
                signalStrength: Float.random(in: -100...0),
                packetLoss: Float.random(in: 0...0.5),
                isReachable: i % 10 != 0,
                lastHeartbeat: Date()
            )
        }
        
        measure {
            // 測試更新效能
            for metrics in testMetrics {
                routeCache.updateMetrics(metrics)
            }
            
            // 測試查詢效能
            for i in 0..<500 {
                _ = routeCache.getMetrics(for: "PEER-\(i)")
            }
        }
    }
    
    // MARK: - Test 5: 網狀拓撲路徑搜尋效能測試
    func testMeshPathfindingPerformance() {
        // 建立測試拓撲 (50個節點的網狀網路)
        var topology: [String: Set<String>] = [:]
        let nodeCount = 50
        
        // 建立部分連接的網狀拓撲
        for i in 0..<nodeCount {
            let nodeID = "NODE-\(i)"
            var connections = Set<String>()
            
            // 連接到相鄰的節點
            if i > 0 {
                connections.insert("NODE-\(i-1)")
            }
            if i < nodeCount - 1 {
                connections.insert("NODE-\(i+1)")
            }
            
            // 隨機跨節點連接
            for _ in 0..<3 {
                let randomNode = "NODE-\(Int.random(in: 0..<nodeCount))"
                if randomNode != nodeID {
                    connections.insert(randomNode)
                }
            }
            
            topology[nodeID] = connections
        }
        
        let routeFinder = MeshRouteFinder()
        
        measure {
            // 測試 100 次路徑搜尋
            for _ in 0..<100 {
                let source = "NODE-\(Int.random(in: 0..<nodeCount))"
                let target = "NODE-\(Int.random(in: 0..<nodeCount))"
                
                if source != target {
                    let paths = routeFinder.findPaths(
                        from: source,
                        to: target,
                        in: topology,
                        maxPaths: 3
                    )
                    
                    // 選擇最佳路徑
                    if !paths.isEmpty {
                        _ = paths.min { $0.count < $1.count }
                    }
                }
            }
        }
    }
    
    // MARK: - Test 6: 訊息優先級隊列效能測試
    func testMessagePriorityQueuePerformance() {
        var priorityQueue = PriorityMessageQueue()
        
        // 準備不同優先級的訊息
        let messageTypes: [(ExtendedMeshMessageType, Int)] = [
            (.emergencyMedical, 100),
            (.emergencyDanger, 100),
            (.signal, 10),
            (.chat, 5),
            (.game, 4)
        ]
        
        measure {
            // 插入 1000 個訊息
            for i in 0..<1000 {
                let (type, _) = messageTypes[i % messageTypes.count]
                let message = ExtendedMeshMessage(
                    type: type,
                    sourceID: "SOURCE-\(i)",
                    targetID: nil,
                    data: Data("Test message \(i)".utf8)
                )
                priorityQueue.enqueue(message)
            }
            
            // 按優先級取出所有訊息
            while let _ = priorityQueue.dequeue() {
                // 處理訊息
            }
        }
    }
}

// MARK: - Helper Structures for Testing

// 優先級訊息隊列 (簡化版)
struct PriorityMessageQueue {
    private var queues: [Int: [ExtendedMeshMessage]] = [:]
    
    mutating func enqueue(_ message: ExtendedMeshMessage) {
        let priority = message.type.priority
        if queues[priority] == nil {
            queues[priority] = []
        }
        queues[priority]?.append(message)
    }
    
    mutating func dequeue() -> ExtendedMeshMessage? {
        let sortedPriorities = queues.keys.sorted(by: >)
        
        for priority in sortedPriorities {
            if var messages = queues[priority], !messages.isEmpty {
                let message = messages.removeFirst()
                if messages.isEmpty {
                    queues.removeValue(forKey: priority)
                } else {
                    queues[priority] = messages
                }
                return message
            }
        }
        
        return nil
    }
}

// 路由搜尋器 (基於現有架構)
class MeshRouteFinder {
    func findPaths(from source: String, to target: String, 
                   in topology: [String: Set<String>], 
                   maxPaths: Int = 3) -> [[String]] {
        
        var allPaths: [[String]] = []
        var visited = Set<String>()
        var currentPath: [String] = []
        
        // DFS 搜尋所有路徑
        func dfs(current: String) {
            if current == target {
                allPaths.append(currentPath + [current])
                return
            }
            
            if visited.contains(current) || currentPath.count > 10 {
                return
            }
            
            visited.insert(current)
            currentPath.append(current)
            
            if let neighbors = topology[current] {
                for neighbor in neighbors {
                    dfs(current: neighbor)
                }
            }
            
            currentPath.removeLast()
            visited.remove(current)
        }
        
        dfs(current: source)
        
        // 返回最短的幾條路徑
        return Array(allPaths.sorted { $0.count < $1.count }.prefix(maxPaths))
    }
}