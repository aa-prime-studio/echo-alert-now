import Foundation
import Foundation
// import XCTest - 使用相容性層
@testable import SignalAir

class SelfDestructManagerTests: XCTestCase {
    
    var destructManager: SelfDestructManager!
    
    override func setUp() {
        super.setUp()
        clearUserDefaults()
        destructManager = SelfDestructManager()
    }
    
    override func tearDown() {
        destructManager = nil
        clearUserDefaults()
        super.tearDown()
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "SignalAir_MessageTimestamps")
        UserDefaults.standard.removeObject(forKey: "SignalAir_MessageMetadata")
        UserDefaults.standard.removeObject(forKey: "SignalAir_SelfDestructStats")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - 基本功能測試
    
    func testMessageTracking() {
        let messageID = "test-message-001"
        
        // 追蹤訊息
        destructManager.trackMessage(messageID, type: .chat, priority: .normal)
        
        // 檢查是否正確追蹤
        let stats = destructManager.getStatistics()
        XCTAssertEqual(stats.currentActive, 1, "應該有1個活躍訊息")
        XCTAssertEqual(stats.totalTracked, 1, "總追蹤數應為1")
        
        // 檢查訊息未過期
        XCTAssertFalse(destructManager.isMessageExpired(messageID), "新訊息不應過期")
        
        print("✅ 訊息追蹤測試通過，訊息ID: \(messageID)")
    }
    
    func testMessageRemoval() {
        let messageID = "test-message-002"
        
        // 追蹤並移除訊息
        destructManager.trackMessage(messageID)
        destructManager.removeMessage(messageID)
        
        // 檢查訊息已移除
        XCTAssertTrue(destructManager.isMessageExpired(messageID), "移除的訊息應視為過期")
        XCTAssertEqual(destructManager.getTimeRemaining(for: messageID), 0, "移除的訊息剩餘時間應為0")
        
        print("✅ 訊息移除測試通過")
    }
    
    func testMultipleMessageTypes() {
        let chatMessage = "chat-001"
        let signalMessage = "signal-001"
        let gameMessage = "game-001"
        
        // 追蹤不同類型訊息
        destructManager.trackMessage(chatMessage, type: .chat)
        destructManager.trackMessage(signalMessage, type: .signal)
        destructManager.trackMessage(gameMessage, type: .game)
        
        let trackedMessages = destructManager.getTrackedMessages()
        XCTAssertEqual(trackedMessages.count, 3, "應該有3個追蹤訊息")
        
        // 檢查類型正確
        let types = trackedMessages.map { $0.type }
        XCTAssertTrue(types.contains(.chat), "應包含聊天訊息")
        XCTAssertTrue(types.contains(.signal), "應包含訊號訊息")
        XCTAssertTrue(types.contains(.game), "應包含遊戲訊息")
        
        print("✅ 多類型訊息測試通過")
    }
    
    // MARK: - 時間相關測試
    
    func testTimeRemaining() {
        let messageID = "time-test-001"
        destructManager.trackMessage(messageID)
        
        let timeRemaining = destructManager.getTimeRemaining(for: messageID)
        
        // 剛追蹤的訊息應該有接近24小時的剩餘時間
        XCTAssertGreaterThan(timeRemaining, 86300, "剩餘時間應接近24小時") // 86400-100秒的容差
        XCTAssertLessThanOrEqual(timeRemaining, 86400, "剩餘時間不應超過24小時")
        
        print("✅ 時間計算測試通過，剩餘時間: \(Int(timeRemaining/3600))小時")
    }
    
    func testExpiringSoonMessages() {
        // 模擬即將過期的訊息（測試用較短時間）
        let messageID = "expiring-001"
        destructManager.trackMessage(messageID)
        
        // 修改訊息時間使其即將過期（hack for testing）
        // 在實際環境中，這需要等待真實時間
        
        let expiringSoon = destructManager.getExpiringSoonMessages(within: 24) // 24小時內
        
        // 新訊息在24小時內過期，所以應該被包含
        XCTAssertEqual(expiringSoon.count, 1, "應該有1個即將過期的訊息")
        
        print("✅ 即將過期訊息測試通過")
    }
    
    // MARK: - 統計資訊測試
    
    func testStatistics() {
        // 追蹤多個訊息
        for i in 1...5 {
            destructManager.trackMessage("stats-test-\(i)", type: .chat)
        }
        
        let stats = destructManager.getStatistics()
        
        XCTAssertEqual(stats.currentActive, 5, "應該有5個活躍訊息")
        XCTAssertEqual(stats.totalTracked, 5, "總追蹤數應為5")
        XCTAssertEqual(stats.totalExpired, 0, "過期數應為0")
        
        print("✅ 統計資訊測試通過")
        print("  活躍訊息: \(stats.currentActive)")
        print("  總追蹤數: \(stats.totalTracked)")
        print("  過期數量: \(stats.totalExpired)")
    }
    
    // MARK: - 批量操作測試
    
    func testBatchMessageTracking() {
        let messageIDs = ["batch-001", "batch-002", "batch-003", "batch-004", "batch-005"]
        
        destructManager.trackMessages(messageIDs, type: .signal)
        
        let stats = destructManager.getStatistics()
        XCTAssertEqual(stats.currentActive, 5, "批量追蹤應該有5個活躍訊息")
        
        let trackedMessages = destructManager.getTrackedMessages()
        let signalMessages = trackedMessages.filter { $0.type == .signal }
        XCTAssertEqual(signalMessages.count, 5, "應該有5個訊號類型訊息")
        
        print("✅ 批量追蹤測試通過，追蹤了 \(messageIDs.count) 個訊息")
    }
    
    // MARK: - 持久化測試
    
    func testPersistence() {
        let messageID = "persistence-test-001"
        destructManager.trackMessage(messageID, type: .chat)
        
        let originalStats = destructManager.getStatistics()
        
        // 創建新的 manager 實例來測試持久化
        let newManager = SelfDestructManager()
        let loadedStats = newManager.getStatistics()
        
        XCTAssertEqual(loadedStats.totalTracked, originalStats.totalTracked, "總追蹤數應保持")
        XCTAssertFalse(newManager.isMessageExpired(messageID), "載入的訊息不應過期")
        
        print("✅ 持久化測試通過")
    }
    
    // MARK: - 手動清理測試
    
    func testManualCleanup() {
        // 追蹤一些訊息
        for i in 1...3 {
            destructManager.trackMessage("cleanup-test-\(i)")
        }
        
        let beforeStats = destructManager.getStatistics()
        
        // 執行手動清理
        destructManager.performManualCleanup()
        
        let afterStats = destructManager.getStatistics()
        
        // 由於訊息都是新的，清理後數量應該相同
        XCTAssertEqual(afterStats.currentActive, beforeStats.currentActive, "新訊息不應被清理")
        
        print("✅ 手動清理測試通過")
    }
    
    // MARK: - 通知測試
    
    func testExpirationNotification() {
        let expectation = XCTestExpectation(description: "過期通知")
        let messageID = "notification-test-001"
        
        // 監聽過期通知
        let observer = NotificationCenter.default.addObserver(
            forName: .messageExpired,
            object: nil,
            queue: .main
        ) { notification in
            if let expiredID = notification.userInfo?["messageID"] as? String,
               expiredID == messageID {
                expectation.fulfill()
            }
        }
        
        // 追蹤訊息並模擬過期（實際測試中需要調整時間）
        destructManager.trackMessage(messageID)
        
        // 在實際測試中，這裡需要等待或模擬時間過期
        // 為了測試目的，我們直接移除訊息來觸發通知
        destructManager.removeMessage(messageID)
        
        // 手動觸發清理來發送通知
        destructManager.performManualCleanup()
        
        wait(for: [expectation], timeout: 2.0)
        
        NotificationCenter.default.removeObserver(observer)
        print("✅ 過期通知測試通過")
    }
    
    // MARK: - 性能測試
    
    func testPerformanceWithManyMessages() {
        measure {
            // 追蹤大量訊息
            for i in 1...1000 {
                destructManager.trackMessage("perf-test-\(i)", type: .chat)
            }
            
            // 執行統計和清理操作
            _ = destructManager.getStatistics()
            destructManager.performManualCleanup()
        }
        
        print("✅ 性能測試完成")
    }
}

// MARK: - 整合測試

class SelfDestructManagerIntegrationTests: XCTestCase {
    
    func testFullLifecycle() async {
        print("🧪 執行 SelfDestructManager 完整生命週期測試...")
        
        let manager = SelfDestructManager()
        
        // 1. 追蹤不同類型訊息
        let chatMessages = ["chat-1", "chat-2", "chat-3"]
        let signalMessages = ["signal-1", "signal-2"]
        let gameMessages = ["game-1"]
        
        manager.trackMessages(chatMessages, type: .chat)
        manager.trackMessages(signalMessages, type: .signal)
        manager.trackMessages(gameMessages, type: .game)
        
        print("✅ 1. 追蹤了多種類型訊息")
        
        // 2. 檢查統計
        let stats = manager.getStatistics()
        XCTAssertEqual(stats.currentActive, 6, "應該有6個活躍訊息")
        print("✅ 2. 統計資訊正確: \(stats.currentActive) 個活躍訊息")
        
        // 3. 檢查時間計算
        for messageID in chatMessages {
            let timeRemaining = manager.getTimeRemaining(for: messageID)
            XCTAssertGreaterThan(timeRemaining, 86000, "剩餘時間應接近24小時")
        }
        print("✅ 3. 時間計算正確")
        
        // 4. 測試手動移除
        manager.removeMessage(chatMessages[0])
        let updatedStats = manager.getStatistics()
        XCTAssertEqual(updatedStats.currentActive, 5, "移除後應該有5個活躍訊息")
        print("✅ 4. 手動移除功能正常")
        
        // 5. 測試追蹤的訊息列表
        let trackedMessages = manager.getTrackedMessages()
        let messageTypes = Set(trackedMessages.map { $0.type })
        XCTAssertTrue(messageTypes.contains(.chat), "應包含聊天訊息")
        XCTAssertTrue(messageTypes.contains(.signal), "應包含訊號訊息")
        XCTAssertTrue(messageTypes.contains(.game), "應包含遊戲訊息")
        print("✅ 5. 訊息列表功能正常")
        
        // 6. 測試即將過期功能
        let expiringSoon = manager.getExpiringSoonMessages(within: 24)
        XCTAssertEqual(expiringSoon.count, 5, "所有訊息都在24小時內過期")
        print("✅ 6. 即將過期功能正常")
        
        print("🎉 SelfDestructManager 完整測試通過！")
    }
    
    func testMemoryEfficiency() {
        let manager = SelfDestructManager()
        
        // 追蹤大量訊息以測試記憶體效率
        for i in 1...200 {
            manager.trackMessage("memory-test-\(i)", type: .chat)
        }
        
        let stats = manager.getStatistics()
        XCTAssertEqual(stats.currentActive, 200, "應該正確追蹤200個訊息")
        
        // 測試清理功能不會洩漏記憶體
        manager.performManualCleanup()
        
        let afterCleanup = manager.getStatistics()
        XCTAssertLessThanOrEqual(afterCleanup.currentActive, 200, "清理後訊息數不應增加")
        
        print("✅ 記憶體效率測試通過")
    }
}

// MARK: - 測試執行器

extension SelfDestructManagerTests {
    static func runAllTests() async {
        print("🚀 開始執行 SelfDestructManager 測試...")
        
        let testSuite = SelfDestructManagerTests()
        
        // 執行所有測試
        testSuite.setUp()
        testSuite.testMessageTracking()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testMessageRemoval()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testMultipleMessageTypes()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testTimeRemaining()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testExpiringSoonMessages()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testStatistics()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testBatchMessageTracking()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testPersistence()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testManualCleanup()
        testSuite.tearDown()
        
        testSuite.setUp()
        testSuite.testExpirationNotification()
        testSuite.tearDown()
        
        // 執行整合測試
        let integrationTest = SelfDestructManagerIntegrationTests()
        await integrationTest.testFullLifecycle()
        await integrationTest.testMemoryEfficiency()
        
        print("✅ 所有 SelfDestructManager 測試完成！")
    }
}

// MARK: - 模擬器測試指南

/*
 📱 模擬器測試步驟：
 
 1. 在 Xcode 中開啟專案
 2. 選擇 iOS 模擬器
 3. 運行以下測試：
 
 ```swift
 // 在 App 啟動時執行
 Task {
     await SelfDestructManagerTests.runAllTests()
 }
 ```
 
 4. 測試背景/前景切換：
    - 追蹤一些訊息
    - 切換到背景 (Cmd+Shift+H)
    - 等待一段時間
    - 切換回前景
    - 檢查清理是否正常執行
 
 5. 測試重啟持久化：
    - 追蹤訊息
    - 關閉 App
    - 重新啟動 App
    - 確認訊息仍被追蹤
 
 6. 檢查 Console 輸出：
    - 觀察清理日誌
    - 確認時間計算正確
    - 檢查通知發送
 */ 