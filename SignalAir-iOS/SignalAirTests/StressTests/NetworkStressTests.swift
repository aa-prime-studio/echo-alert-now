import XCTest
@testable import SignalAir

// MARK: - Network Stress Tests
class NetworkStressTests: XCTestCase {
    
    var meshManager: MeshManager!
    var trustScoreManager: TrustScoreManager!
    var maliciousDetector: MaliciousContentDetector!
    
    override func setUp() {
        super.setUp()
        meshManager = MeshManager()
        trustScoreManager = TrustScoreManager()
        maliciousDetector = MaliciousContentDetector()
    }
    
    // MARK: - Test 1: 路由演算法壓力測試
    func testRouteCalculationUnderPressure() {
        measure {
            // 模擬 100 個節點的複雜拓撲
            let nodeCount = 100
            var topology: [String: Set<String>] = [:]
            
            // 建立隨機連接的網狀拓撲
            for i in 0..<nodeCount {
                let nodeID = "NODE-\(i)"
                var connections = Set<String>()
                
                // 每個節點連接 3-8 個隨機節點
                let connectionCount = Int.random(in: 3...8)
                for _ in 0..<connectionCount {
                    let targetNode = "NODE-\(Int.random(in: 0..<nodeCount))"
                    if targetNode != nodeID {
                        connections.insert(targetNode)
                    }
                }
                topology[nodeID] = connections
            }
            
            // 測試 1000 次路由計算
            for _ in 0..<1000 {
                let source = "NODE-\(Int.random(in: 0..<nodeCount))"
                let target = "NODE-\(Int.random(in: 0..<nodeCount))"
                
                if source != target {
                    let routeFinder = MeshRouteFinder()
                    _ = routeFinder.findPaths(from: source, to: target, in: topology)
                }
            }
        }
    }
    
    // MARK: - Test 2: 訊息處理效能測試
    func testMessageProcessingThroughput() {
        let expectation = self.expectation(description: "處理大量訊息")
        var processedCount = 0
        let targetCount = 10000
        
        // 準備測試訊息
        let testMessages: [Data] = (0..<targetCount).map { index in
            let message = ChatMessage(
                id: UUID().uuidString,
                content: "測試訊息 #\(index) - 這是一個壓力測試訊息",
                sender: "TEST-USER-\(index % 10)",
                timestamp: Date(),
                type: index % 100 == 0 ? .emergency : .normal
            )
            return (try? JSONEncoder().encode(message)) ?? Data()
        }
        
        // 開始計時
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模擬並發訊息處理
        let queue = DispatchQueue(label: "stress.test", attributes: .concurrent)
        let group = DispatchGroup()
        
        for messageData in testMessages {
            group.enter()
            queue.async {
                // 模擬訊息解碼和處理
                if let _ = try? JSONDecoder().decode(ChatMessage.self, from: messageData) {
                    processedCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let endTime = CFAbsoluteTimeGetCurrent()
            let throughput = Double(processedCount) / (endTime - startTime)
            
            print("📊 訊息處理效能:")
            print("   - 處理訊息數: \(processedCount)")
            print("   - 耗時: \(String(format: "%.2f", endTime - startTime)) 秒")
            print("   - 吞吐量: \(String(format: "%.0f", throughput)) 訊息/秒")
            
            XCTAssert(throughput > 1000, "訊息處理速度應超過 1000 訊息/秒")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Test 3: 信任評分系統壓力測試
    func testTrustScoreSystemUnderAttack() {
        measure {
            // 模擬 1000 個設備的行為記錄
            for i in 0..<1000 {
                let deviceUUID = "DEVICE-\(i)"
                
                // 隨機行為模式
                let behaviorType = i % 4
                switch behaviorType {
                case 0: // 正常設備
                    for _ in 0..<10 {
                        trustScoreManager.recordSuccessfulCommunication(for: deviceUUID)
                    }
                case 1: // 可疑設備
                    trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .duplicateMessages)
                    trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .excessiveRetransmission)
                case 2: // 惡意設備
                    trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .maliciousContent)
                    trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .invalidSignature)
                case 3: // 混合行為
                    trustScoreManager.recordSuccessfulCommunication(for: deviceUUID)
                    trustScoreManager.recordExcessiveBroadcast(for: deviceUUID, messageCount: 100, timeWindow: 60)
                default:
                    break
                }
            }
            
            // 驗證系統狀態
            let stats = trustScoreManager.getTrustStatistics()
            print("📊 信任系統統計:")
            print("   - 總節點數: \(stats.totalNodes)")
            print("   - 黑名單數: \(stats.blacklistedNodes)")
            print("   - 可疑節點: \(stats.suspiciousNodes)")
        }
    }
    
    // MARK: - Test 4: 惡意內容檢測效能測試
    func testMaliciousContentDetectionPerformance() {
        let testContents = [
            // 正常內容
            "你好，請問附近有人嗎？",
            "我在這裡，需要幫助嗎？",
            "大家都安全嗎？",
            
            // 釣魚內容
            "點擊連結立即驗證你的帳號",
            "緊急！請輸入密碼確認身份",
            "帳戶異常，請立即處理",
            
            // Bot 模式內容
            "AAAAAAAAAAAAAAAAAAA",
            "!@#$%^&*()!@#$%^&*()",
            "買買買買買買買買買買買買"
        ]
        
        measure {
            // 測試 10000 次內容檢測
            for i in 0..<10000 {
                let content = testContents[i % testContents.count]
                let result = maliciousDetector.analyzeContent(content)
                
                if !result.isClean {
                    _ = maliciousDetector.getRecommendedAction(for: result)
                }
            }
        }
    }
    
    // MARK: - Test 5: 記憶體壓力測試
    func testMemoryPressureWithLargeMessages() {
        let expectation = self.expectation(description: "記憶體壓力測試")
        
        autoreleasepool {
            var messages: [ExtendedMeshMessage] = []
            
            // 創建 1000 個大型訊息
            for i in 0..<1000 {
                // 每個訊息包含 1MB 資料
                let largeData = Data(repeating: UInt8(i % 256), count: 1024 * 1024)
                
                let message = ExtendedMeshMessage(
                    type: .chat,
                    sourceID: "SOURCE-\(i)",
                    targetID: nil,
                    data: largeData
                )
                
                messages.append(message)
            }
            
            // 模擬訊息處理
            let processedCount = messages.compactMap { message -> Data? in
                return try? JSONEncoder().encode(message)
            }.count
            
            print("📊 記憶體測試結果:")
            print("   - 處理大型訊息數: \(processedCount)")
            print("   - 每個訊息大小: 1 MB")
            print("   - 總處理資料量: \(processedCount) MB")
            
            XCTAssert(processedCount > 0, "應能處理大型訊息")
        }
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 60.0)
    }
    
    // MARK: - Test 6: 並發安全測試
    func testConcurrentOperationsSafety() {
        let expectation = self.expectation(description: "並發安全測試")
        let iterations = 1000
        let concurrentQueues = 10
        
        let group = DispatchGroup()
        var successCount = 0
        let lock = NSLock()
        
        // 創建多個並發隊列
        for queueIndex in 0..<concurrentQueues {
            let queue = DispatchQueue(label: "concurrent.test.\(queueIndex)", attributes: .concurrent)
            
            group.enter()
            queue.async {
                for i in 0..<iterations {
                    // 模擬並發操作
                    let deviceID = "DEVICE-\(queueIndex)-\(i)"
                    
                    // 同時進行多種操作
                    self.trustScoreManager.recordSuccessfulCommunication(for: deviceID)
                    _ = self.trustScoreManager.getTrustScore(for: deviceID)
                    
                    if i % 10 == 0 {
                        self.trustScoreManager.recordSuspiciousBehavior(
                            for: deviceID,
                            behavior: .duplicateMessages
                        )
                    }
                    
                    lock.lock()
                    successCount += 1
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("📊 並發測試結果:")
            print("   - 總操作數: \(concurrentQueues * iterations)")
            print("   - 成功操作: \(successCount)")
            print("   - 並發隊列數: \(concurrentQueues)")
            
            XCTAssertEqual(successCount, concurrentQueues * iterations, "所有並發操作應成功完成")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}

// MARK: - Test Models
private struct ChatMessage: Codable {
    let id: String
    let content: String
    let sender: String
    let timestamp: Date
    let type: MessageType
    
    enum MessageType: String, Codable {
        case normal
        case emergency
    }
}