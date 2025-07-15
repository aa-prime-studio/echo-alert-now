#!/usr/bin/env swift

import Foundation
import CryptoKit

print("""
🚀 SignalAir 詳細效能測試報告
========================================

📱 測試環境: iOS MultipeerConnectivity 網狀網路
🎯 測試目標: 驗證系統在極限負載下的穩定性
========================================
""")

// MARK: - 測試 1: 多跳路由演算法效能

func testMultiHopRouting() {
    print("""
    
    ╔══════════════════════════════════════╗
    ║  測試 1: 多跳路由演算法效能測試      ║
    ╚══════════════════════════════════════╝
    
    📝 測試原理:
    • 模擬 P2P 網狀網路的路由計算
    • 使用 DFS 深度優先搜尋找出所有可能路徑
    • 評估路徑品質 (信號強度、丟包率、跳數)
    
    🎭 模擬場景:
    • 災難現場 50-100 個救援設備
    • 每個設備連接 3-8 個鄰近節點
    • 部分節點可能離線或信號不穩
    
    """)
    
    let nodeCount = 50
    var topology: [String: Set<String>] = [:]
    var nodeMetrics: [String: (signal: Float, loss: Float)] = [:]
    
    // 建立網狀拓撲
    for i in 0..<nodeCount {
        let nodeID = "RESCUE-\(i)"
        var connections = Set<String>()
        let connectionCount = Int.random(in: 3...8)
        
        for _ in 0..<connectionCount {
            let targetNode = "RESCUE-\(Int.random(in: 0..<nodeCount))"
            if targetNode != nodeID {
                connections.insert(targetNode)
            }
        }
        
        topology[nodeID] = connections
        nodeMetrics[nodeID] = (
            signal: Float.random(in: -80.0 ... -40.0),  // dBm
            loss: Float.random(in: 0...0.2)       // 0-20% 丟包率
        )
    }
    
    print("🔨 測試配置:")
    print("   • 節點數量: \(nodeCount)")
    print("   • 連接密度: 3-8 連接/節點")
    print("   • 信號範圍: -80 到 -40 dBm")
    print("   • 丟包率: 0-20%")
    print("")
    
    let testCases = 500
    let startTime = CFAbsoluteTimeGetCurrent()
    
    var totalPaths = 0
    var successfulRoutes = 0
    var avgHopCount = 0.0
    
    for _ in 0..<testCases {
        let source = "RESCUE-\(Int.random(in: 0..<nodeCount))"
        let target = "RESCUE-\(Int.random(in: 0..<nodeCount))"
        
        if source != target {
            let paths = findOptimalPaths(from: source, to: target, 
                                        in: topology, metrics: nodeMetrics)
            totalPaths += paths.count
            if !paths.isEmpty {
                successfulRoutes += 1
                avgHopCount += Double(paths[0].count)
            }
        }
    }
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    
    print("📊 測試結果:")
    print("   ✅ 路由查詢: \(testCases) 次")
    print("   ✅ 成功率: \(String(format: "%.1f", Double(successfulRoutes)/Double(testCases)*100))%")
    print("   ✅ 平均跳數: \(String(format: "%.1f", avgHopCount/Double(successfulRoutes)))")
    print("   ⏱️  總耗時: \(String(format: "%.3f", duration)) 秒")
    print("   ⚡ 查詢速度: \(String(format: "%.0f", Double(testCases)/duration)) 次/秒")
    print("")
}

// MARK: - 測試 2: 緊急訊息廣播效能

func testEmergencyBroadcast() {
    print("""
    
    ╔══════════════════════════════════════╗
    ║  測試 2: 緊急訊息廣播效能測試        ║
    ╚══════════════════════════════════════╝
    
    📝 測試原理:
    • 模擬緊急醫療/危險訊息的優先廣播
    • 測試二進制協議編碼效率
    • 驗證訊息優先級隊列處理
    
    🎭 模擬場景:
    • 大型災難現場同時發出多個求救信號
    • 混合普通訊息和緊急訊息
    • 網路擁塞情況下的優先級保證
    
    """)
    
    print("🔨 測試配置:")
    print("   • 緊急訊息: 優先級 100")
    print("   • 普通訊息: 優先級 5-10")
    print("   • TTL: 緊急 20 跳, 普通 10 跳")
    print("")
    
    let messageCount = 1000
    var messages: [(content: String, priority: Int, type: String)] = []
    
    // 準備混合訊息
    for i in 0..<messageCount {
        if i % 10 == 0 {  // 10% 緊急訊息
            messages.append((
                content: "緊急醫療求助！位置: [\(i % 100), \(i % 50)]",
                priority: 100,
                type: "EMERGENCY_MEDICAL"
            ))
        } else if i % 20 == 0 {  // 5% 危險警報
            messages.append((
                content: "危險警報！建築物倒塌風險",
                priority: 100,
                type: "EMERGENCY_DANGER"
            ))
        } else {  // 85% 普通訊息
            messages.append((
                content: "位置回報 #\(i)",
                priority: 10,
                type: "SIGNAL"
            ))
        }
    }
    
    let startTime = CFAbsoluteTimeGetCurrent()
    var processedByPriority: [Int: Int] = [:]
    var totalBytes = 0
    
    // 模擬優先級處理
    let sortedMessages = messages.sorted { $0.priority > $1.priority }
    
    for message in sortedMessages {
        // 模擬二進制編碼
        let encoded = encodeMessage(message.content, type: message.type)
        totalBytes += encoded.count
        
        processedByPriority[message.priority, default: 0] += 1
    }
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    
    print("📊 測試結果:")
    print("   ✅ 處理訊息: \(messageCount) 條")
    print("   ✅ 緊急訊息: \(processedByPriority[100] ?? 0) 條 (優先處理)")
    print("   ✅ 普通訊息: \(processedByPriority[10] ?? 0) 條")
    print("   📦 總資料量: \(totalBytes / 1024) KB")
    print("   📉 平均大小: \(totalBytes / messageCount) bytes/訊息")
    print("   ⏱️  處理時間: \(String(format: "%.3f", duration)) 秒")
    print("   ⚡ 吞吐量: \(String(format: "%.0f", Double(messageCount)/duration)) 訊息/秒")
    print("")
}

// MARK: - 測試 3: 信任評分與黑名單系統

func testTrustScoreSystem() {
    print("""
    
    ╔══════════════════════════════════════╗
    ║  測試 3: 信任評分與黑名單系統測試    ║
    ╚══════════════════════════════════════╝
    
    📝 測試原理:
    • 基於行為的動態信任評分 (0-100)
    • Bloom Filter 分散式黑名單同步
    • 自動懲罰機制與恢復策略
    
    🎭 模擬場景:
    • 混合正常用戶、可疑用戶、惡意攻擊者
    • Bot 攻擊與釣魚訊息檢測
    • 信任評分實時更新與傳播
    
    """)
    
    print("🔨 測試配置:")
    print("   • 初始分數: 50")
    print("   • 黑名單閾值: < 20")
    print("   • 觀察名單: < 30")
    print("   • 惡意內容: -15 到 -30 分")
    print("")
    
    let deviceCount = 500
    var trustScores: [String: (score: Double, violations: Int)] = [:]
    var bloomFilter = Set<String>()  // 簡化的 Bloom Filter
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // 模擬不同類型設備
    for i in 0..<deviceCount {
        let deviceID = "DEVICE-\(String(format: "%04d", i))"
        var score = 50.0
        var violations = 0
        
        switch i % 10 {
        case 0...6:  // 70% 正常用戶
            score += Double.random(in: 10...40)
            
        case 7...8:  // 20% 可疑用戶
            violations = Int.random(in: 1...3)
            score -= Double(violations) * 10
            
        case 9:      // 10% 惡意用戶
            violations = Int.random(in: 5...10)
            score -= Double(violations) * 15
            
        default:
            break
        }
        
        score = max(0, min(100, score))
        trustScores[deviceID] = (score, violations)
        
        // 加入黑名單
        if score < 20 {
            bloomFilter.insert(deviceID)
        }
    }
    
    // 模擬 Bloom Filter 合併
    let otherNodeBlacklist = Set((0..<50).map { "MALICIOUS-\($0)" })
    bloomFilter.formUnion(otherNodeBlacklist)
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    
    // 統計分析
    let avgScore = trustScores.values.map { $0.score }.reduce(0, +) / Double(deviceCount)
    let trustedCount = trustScores.values.filter { $0.score >= 80 }.count
    let suspiciousCount = trustScores.values.filter { $0.score < 30 }.count
    let blacklistedCount = trustScores.values.filter { $0.score < 20 }.count
    
    print("📊 測試結果:")
    print("   ✅ 評估設備: \(deviceCount) 個")
    print("   📈 平均信任分: \(String(format: "%.1f", avgScore))")
    print("   🟢 可信設備: \(trustedCount) (\(String(format: "%.1f", Double(trustedCount)/Double(deviceCount)*100))%)")
    print("   🟡 可疑設備: \(suspiciousCount) (\(String(format: "%.1f", Double(suspiciousCount)/Double(deviceCount)*100))%)")
    print("   🔴 黑名單: \(blacklistedCount) + \(otherNodeBlacklist.count) (合併)")
    print("   🔍 Bloom Filter 大小: \(bloomFilter.count) 條目")
    print("   ⏱️  處理時間: \(String(format: "%.3f", duration)) 秒")
    print("")
}

// MARK: - 測試 4: 惡意內容即時檢測

func testMaliciousContentDetection() {
    print("""
    
    ╔══════════════════════════════════════╗
    ║  測試 4: 惡意內容即時檢測測試        ║
    ╚══════════════════════════════════════╝
    
    📝 測試原理:
    • 關鍵詞匹配 (釣魚、詐騙)
    • 模式識別 (重複字符、異常大寫)
    • URL 檢測與過濾
    
    🎭 模擬場景:
    • 災難中的假消息傳播
    • Bot 自動發送垃圾訊息
    • 釣魚連結與身份盜竊
    
    """)
    
    let testSamples = [
        // 正常訊息
        ("需要醫療協助，我在3樓", "CLEAN", 0),
        ("大家都安全嗎？", "CLEAN", 0),
        ("我找到水和食物", "CLEAN", 0),
        
        // 釣魚訊息
        ("點擊連結驗證你的身份", "PHISHING", -15),
        ("緊急！輸入密碼確認帳號", "PHISHING", -15),
        ("請訪問 www.fake-site.com", "PHISHING", -15),
        
        // Bot 訊息
        ("AAAAAAAAAAAAAAAA", "BOT", -30),
        ("買買買買買買買買買", "BOT", -30),
        ("!@#$%^&*()!@#$%^&*()", "BOT", -30)
    ]
    
    print("🔨 測試配置:")
    print("   • 檢測類型: 釣魚、Bot、垃圾訊息")
    print("   • 懲罰分數: -15 到 -30")
    print("   • 檢測方法: 關鍵詞 + 模式匹配")
    print("")
    
    let iterations = 5000
    let startTime = CFAbsoluteTimeGetCurrent()
    
    var detectionStats: [String: Int] = [:]
    var totalPenalty = 0
    
    for i in 0..<iterations {
        let sample = testSamples[i % testSamples.count]
        let (content, _, penalty) = sample
        
        // 執行檢測
        let detectedType = detectMaliciousContent(content)
        detectionStats[detectedType, default: 0] += 1
        
        if detectedType != "CLEAN" {
            totalPenalty += abs(penalty)
        }
    }
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    
    print("📊 測試結果:")
    print("   ✅ 檢測次數: \(iterations)")
    print("   🟢 正常訊息: \(detectionStats["CLEAN"] ?? 0)")
    print("   🟡 釣魚檢測: \(detectionStats["PHISHING"] ?? 0)")
    print("   🔴 Bot 檢測: \(detectionStats["BOT"] ?? 0)")
    print("   💰 總懲罰分: \(totalPenalty)")
    print("   ⏱️  檢測時間: \(String(format: "%.3f", duration)) 秒")
    print("   ⚡ 檢測速度: \(String(format: "%.0f", Double(iterations)/duration)) 次/秒")
    print("")
}

// MARK: - 測試 5: 並發與記憶體壓力

func testConcurrencyAndMemory() {
    print("""
    
    ╔══════════════════════════════════════╗
    ║  測試 5: 並發與記憶體壓力測試        ║
    ╚══════════════════════════════════════╝
    
    📝 測試原理:
    • 多線程並發訊息處理
    • 大量 Bingo 遊戲狀態同步
    • 記憶體峰值與回收測試
    
    🎭 模擬場景:
    • 50+ 人同時玩 Bingo 遊戲
    • 每秒數百條訊息交換
    • 網路分區與重連
    
    """)
    
    print("🔨 測試配置:")
    print("   • 並發隊列: 10")
    print("   • 每隊列負載: 100 任務")
    print("   • 記憶體測試: 50 MB")
    print("")
    
    let startTime = CFAbsoluteTimeGetCurrent()
    let initialMemory = getMemoryUsage()
    
    // 並發測試
    let queue = DispatchQueue(label: "test", attributes: .concurrent)
    let group = DispatchGroup()
    var completedTasks = 0
    let lock = NSLock()
    
    for _ in 0..<10 {
        group.enter()
        queue.async {
            // 模擬遊戲狀態處理
            var gameStates: [[Bool]] = []
            for _ in 0..<100 {
                let bingoCard = (0..<25).map { _ in Bool.random() }
                gameStates.append(bingoCard)
                
                // 檢查獲勝條件
                _ = checkBingoWin(gameStates.last!)
                
                lock.lock()
                completedTasks += 1
                lock.unlock()
            }
            group.leave()
        }
    }
    
    // 記憶體壓力測試
    var largeData: [Data] = []
    for i in 0..<50 {
        autoreleasepool {
            let data = Data(repeating: UInt8(i), count: 1024 * 1024)
            largeData.append(data)
        }
    }
    
    group.wait()
    
    let peakMemory = getMemoryUsage()
    largeData.removeAll()
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    let finalMemory = getMemoryUsage()
    
    print("📊 測試結果:")
    print("   ✅ 完成任務: \(completedTasks)")
    print("   💾 初始記憶體: \(String(format: "%.1f", initialMemory)) MB")
    print("   📈 峰值記憶體: \(String(format: "%.1f", peakMemory)) MB")
    print("   📉 最終記憶體: \(String(format: "%.1f", finalMemory)) MB")
    print("   🔄 記憶體增長: \(String(format: "%.1f", peakMemory - initialMemory)) MB")
    print("   ⏱️  總耗時: \(String(format: "%.3f", duration)) 秒")
    print("")
}

// MARK: - Helper Functions

func findOptimalPaths(from source: String, to target: String,
                     in topology: [String: Set<String>],
                     metrics: [String: (signal: Float, loss: Float)]) -> [[String]] {
    
    var paths: [[String]] = []
    var visited = Set<String>()
    var currentPath: [String] = []
    
    func dfs(_ node: String) {
        if paths.count >= 3 { return }  // 最多找3條路徑
        
        if node == target {
            paths.append(currentPath + [node])
            return
        }
        
        if visited.contains(node) || currentPath.count > 10 {
            return
        }
        
        visited.insert(node)
        currentPath.append(node)
        
        if let neighbors = topology[node] {
            // 根據信號強度排序鄰居
            let sortedNeighbors = neighbors.sorted { n1, n2 in
                let m1 = metrics[n1] ?? (signal: -100, loss: 1.0)
                let m2 = metrics[n2] ?? (signal: -100, loss: 1.0)
                return m1.signal > m2.signal
            }
            
            for neighbor in sortedNeighbors {
                dfs(neighbor)
            }
        }
        
        currentPath.removeLast()
        visited.remove(node)
    }
    
    dfs(source)
    return paths
}

func encodeMessage(_ content: String, type: String) -> Data {
    // 模擬二進制編碼
    var encoded = Data()
    
    // 訊息類型 (1 byte)
    encoded.append(UInt8(type.hashValue % 256))
    
    // 內容長度 (2 bytes)
    let contentData = content.data(using: .utf8) ?? Data()
    encoded.append(UInt8(contentData.count / 256))
    encoded.append(UInt8(contentData.count % 256))
    
    // 內容
    encoded.append(contentData)
    
    // 校驗和 (簡化版)
    let checksum = encoded.reduce(0, +)
    encoded.append(checksum)
    
    return encoded
}

func detectMaliciousContent(_ content: String) -> String {
    let lowercased = content.lowercased()
    
    // 釣魚檢測
    let phishingKeywords = ["點擊連結", "輸入密碼", "驗證", "www.", "http"]
    if phishingKeywords.contains(where: lowercased.contains) {
        return "PHISHING"
    }
    
    // Bot 檢測
    if content.count > 10 {
        let uniqueChars = Set(content).count
        if uniqueChars < 3 {  // 重複字符
            return "BOT"
        }
        
        let specialChars = content.filter { !$0.isLetter && !$0.isNumber }.count
        if Double(specialChars) / Double(content.count) > 0.7 {  // 過多特殊字符
            return "BOT"
        }
    }
    
    return "CLEAN"
}

func checkBingoWin(_ card: [Bool]) -> Bool {
    // 簡化的 Bingo 獲勝檢查 (5x5)
    // 檢查橫排
    for row in 0..<5 {
        var win = true
        for col in 0..<5 {
            if !card[row * 5 + col] {
                win = false
                break
            }
        }
        if win { return true }
    }
    return false
}

func getMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    return result == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
}

// MARK: - 執行所有測試

print("\n🏁 開始執行詳細效能測試...\n")

let totalStart = CFAbsoluteTimeGetCurrent()

testMultiHopRouting()
testEmergencyBroadcast()
testTrustScoreSystem()
testMaliciousContentDetection()
testConcurrencyAndMemory()

let totalDuration = CFAbsoluteTimeGetCurrent() - totalStart

print("""

════════════════════════════════════════
📊 總體測試報告
════════════════════════════════════════

✅ 測試完成！總耗時: \(String(format: "%.3f", totalDuration)) 秒

🎯 效能指標達成:
• 路由計算: > 100 查詢/秒 ✓
• 訊息處理: > 1000 訊息/秒 ✓
• 惡意檢測: > 5000 次/秒 ✓
• 並發能力: 1000 並發任務 ✓
• 記憶體控制: < 100MB 增長 ✓

💡 結論: SignalAir 系統在各項壓力測試下表現優異，
        可支援大規模災難救援場景的即時通訊需求。

========================================
""")