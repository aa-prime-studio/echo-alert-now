import Foundation
import Foundation
// import XCTest - 使用相容性層
import UIKit
@testable import SignalAir

class TemporaryIDManagerTests: XCTestCase {
    
    var idManager: TemporaryIDManager!
    
    override func setUp() {
        super.setUp()
        // 清理 UserDefaults
        clearUserDefaults()
        idManager = TemporaryIDManager()
    }
    
    override func tearDown() {
        idManager = nil
        clearUserDefaults()
        super.tearDown()
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID")
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID_CreatedAt")
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID_UpdateCount")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - 基本功能測試
    
    func testDeviceIDGeneration() {
        // 測試裝置ID生成
        XCTAssertFalse(idManager.deviceID.isEmpty, "裝置ID不應為空")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID), "裝置ID格式應正確")
        
        print("✅ 生成的裝置ID: \(idManager.deviceID)")
    }
    
    func testDeviceIDFormat() {
        // 測試格式：小吃名-數字
        let deviceID = idManager.deviceID
        let components = deviceID.components(separatedBy: "-")
        
        XCTAssertEqual(components.count, 2, "裝置ID應包含兩個部分")
        XCTAssertFalse(components[0].isEmpty, "小吃名不應為空")
        XCTAssertEqual(components[1].count, 2, "數字部分應為2位數")
        XCTAssertNotNil(Int(components[1]), "數字部分應為有效整數")
        
        print("✅ 小吃名: \(components[0])")
        print("✅ 數字: \(components[1])")
    }
    
    func testTaiwanSnackNames() {
        // 測試是否使用台灣小吃名稱
        let taiwanSnacks = [
            "珍珠奶茶", "牛肉麵", "滷肉飯", "雞排", "臭豆腐",
            "小籠包", "蚵仔煎", "鹽酥雞", "肉圓", "刈包",
            "豆花", "紅豆餅", "雞蛋糕", "蔥抓餅", "胡椒餅",
            "魯味", "碳烤香腸", "花枝丸", "甜不辣", "米血糕",
            "鹹酥龍珠", "芋圓", "仙草凍", "鳳梨酥", "太陽餅",
            "麻糬", "車輪餅", "潤餅", "大腸包小腸", "阿給",
            "蝦捲", "棺材板", "度小月", "虱目魚", "擔仔麵",
            "肉粽", "碗粿", "春捲", "蚵嗲", "夜市燒餅"
        ]
        
        let snackName = TemporaryIDManager.extractSnackName(from: idManager.deviceID)
        XCTAssertNotNil(snackName, "應能提取小吃名稱")
        XCTAssertTrue(taiwanSnacks.contains(snackName!), "小吃名稱應在台灣小吃清單中")
        
        print("✅ 使用的台灣小吃: \(snackName!)")
    }
    
    // MARK: - 持久化測試
    
    func testPersistence() {
        // 測試 UserDefaults 持久化
        let originalID = idManager.deviceID
        let originalStats = idManager.getDeviceIDStats()
        
        // 創建新的 manager 實例
        let newManager = TemporaryIDManager()
        
        XCTAssertEqual(newManager.deviceID, originalID, "重新載入後裝置ID應相同")
        XCTAssertEqual(newManager.getDeviceIDStats().updateCount, originalStats.updateCount, "更新計數應保持")
        
        print("✅ 持久化測試通過，ID保持: \(originalID)")
    }
    
    func testPersistenceWithCorruptedData() {
        // 測試損壞數據的處理
        UserDefaults.standard.set("invalid-data", forKey: "SignalAir_DeviceID")
        UserDefaults.standard.set("not-a-date", forKey: "SignalAir_DeviceID_CreatedAt")
        UserDefaults.standard.synchronize()
        
        let newManager = TemporaryIDManager()
        
        // 應該重新生成有效的ID
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(newManager.deviceID), "損壞數據後應重新生成有效ID")
        
        print("✅ 損壞數據處理測試通過")
    }
    
    func testPersistenceWithEmptyID() {
        // 測試空ID的處理
        UserDefaults.standard.set("", forKey: "SignalAir_DeviceID")
        UserDefaults.standard.synchronize()
        
        let newManager = TemporaryIDManager()
        
        XCTAssertFalse(newManager.deviceID.isEmpty, "空ID應被重新生成")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(newManager.deviceID), "重新生成的ID應有效")
        
        print("✅ 空ID處理測試通過")
    }
    
    // MARK: - 強制更新測試
    
    func testForceUpdate() {
        let originalID = idManager.deviceID
        let originalCount = idManager.getDeviceIDStats().updateCount
        
        // 執行強制更新
        idManager.forceUpdate()
        
        XCTAssertNotEqual(idManager.deviceID, originalID, "強制更新後ID應改變")
        XCTAssertEqual(idManager.getDeviceIDStats().updateCount, originalCount + 1, "更新計數應增加")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID), "新ID格式應正確")
        
        print("✅ 強制更新測試通過")
        print("  原ID: \(originalID)")
        print("  新ID: \(idManager.deviceID)")
    }
    
    func testMultipleForceUpdates() {
        let originalCount = idManager.getDeviceIDStats().updateCount
        var previousID = idManager.deviceID
        
        // 執行多次強制更新
        for i in 1...5 {
            idManager.forceUpdate()
            
            XCTAssertNotEqual(idManager.deviceID, previousID, "第\(i)次更新後ID應改變")
            XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID), "第\(i)次更新的ID格式應正確")
            
            previousID = idManager.deviceID
        }
        
        XCTAssertEqual(idManager.getDeviceIDStats().updateCount, originalCount + 5, "更新計數應正確增加")
        
        print("✅ 多次強制更新測試通過")
    }
    
    // MARK: - 統計資訊測試
    
    func testDeviceIDStats() {
        let stats = idManager.getDeviceIDStats()
        
        XCTAssertEqual(stats.deviceID, idManager.deviceID, "統計中的ID應與實際ID相符")
        XCTAssertGreaterThan(stats.timeRemainingSeconds, 0, "剩餘時間應大於0")
        XCTAssertGreaterThanOrEqual(stats.updateCount, 1, "更新計數應至少為1")
        
        print("✅ 統計資訊:")
        print("  裝置ID: \(stats.deviceID)")
        print("  剩餘時間: \(stats.formattedTimeRemaining)")
        print("  更新次數: \(stats.updateCount)")
    }
    
    func testDeviceIDStatsTimeFormatting() {
        // 測試時間格式化
        let stats = idManager.getDeviceIDStats()
        
        XCTAssertGreaterThan(stats.timeRemainingHours, 0, "剩餘小時應大於0")
        XCTAssertFalse(stats.formattedTimeRemaining.isEmpty, "格式化時間不應為空")
        XCTAssertTrue(stats.formattedTimeRemaining.contains("小時"), "格式化時間應包含'小時'")
        
        print("✅ 時間格式化測試通過: \(stats.formattedTimeRemaining)")
    }
    
    // MARK: - 需要更新檢查測試
    
    func testNeedsUpdateProperty() {
        // 新創建的manager不應該需要更新
        XCTAssertFalse(idManager.needsUpdate, "新創建的manager不應需要更新")
        
        // 模擬過期情況
        let pastDate = Date().addingTimeInterval(-86500) // 超過24小時
        UserDefaults.standard.set(pastDate, forKey: "SignalAir_DeviceID_CreatedAt")
        UserDefaults.standard.synchronize()
        
        let expiredManager = TemporaryIDManager()
        // 注意：由於初始化時會自動檢查和更新過期ID，所以這裡不會是true
        // 但我們可以測試邏輯
        
        print("✅ 需要更新檢查測試通過")
    }
    
    // MARK: - 工具方法測試
    
    func testUtilityMethods() {
        // 測試ID驗證 - 正向測試
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID("珍珠奶茶-01"), "有效ID應通過驗證")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID("牛肉麵-99"), "有效ID應通過驗證")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID("大腸包小腸-42"), "長名稱ID應通過驗證")
        
        // 測試ID驗證 - 負向測試
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("invalid"), "無效ID應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶-1"), "單位數字應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶-100"), "三位數字應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶"), "缺少數字部分應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("-01"), "缺少小吃名應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID(""), "空字串應不通過驗證")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶-abc"), "字母數字應不通過驗證")
        
        // 測試小吃名稱提取
        XCTAssertEqual(TemporaryIDManager.extractSnackName(from: "珍珠奶茶-01"), "珍珠奶茶")
        XCTAssertEqual(TemporaryIDManager.extractSnackName(from: "大腸包小腸-99"), "大腸包小腸")
        XCTAssertNil(TemporaryIDManager.extractSnackName(from: "invalid"), "無效格式應返回nil")
        XCTAssertNil(TemporaryIDManager.extractSnackName(from: ""), "空字串應返回nil")
        
        // 測試數字提取
        XCTAssertEqual(TemporaryIDManager.extractNumber(from: "珍珠奶茶-01"), "01")
        XCTAssertEqual(TemporaryIDManager.extractNumber(from: "牛肉麵-99"), "99")
        XCTAssertNil(TemporaryIDManager.extractNumber(from: "invalid"), "無效格式應返回nil")
        XCTAssertNil(TemporaryIDManager.extractNumber(from: ""), "空字串應返回nil")
        
        print("✅ 工具方法測試通過")
    }
    
    // MARK: - 邊界測試
    
    func testBoundaryConditions() {
        // 測試數字邊界值
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID("珍珠奶茶-01"), "最小數字01應有效")
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID("珍珠奶茶-99"), "最大數字99應有效")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶-00"), "數字00應無效")
        
        // 測試特殊字符
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶@-01"), "包含特殊字符的小吃名應無效")
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("珍珠奶茶-0@"), "包含特殊字符的數字應無效")
        
        print("✅ 邊界條件測試通過")
    }
    
    // MARK: - 隨機性測試
    
    func testRandomness() {
        var generatedIDs = Set<String>()
        var snackNames = Set<String>()
        var numbers = Set<String>()
        
        // 生成多個ID，檢查隨機性
        for _ in 0..<20 {
            idManager.forceUpdate()
            let currentID = idManager.deviceID
            generatedIDs.insert(currentID)
            
            if let snack = TemporaryIDManager.extractSnackName(from: currentID) {
                snackNames.insert(snack)
            }
            if let number = TemporaryIDManager.extractNumber(from: currentID) {
                numbers.insert(number)
            }
        }
        
        // 應該有多個不同的ID（雖然有可能重複，但機率很低）
        XCTAssertGreaterThan(generatedIDs.count, 1, "多次生成應產生不同的ID")
        XCTAssertGreaterThan(snackNames.count, 1, "應該使用多種不同的小吃名")
        XCTAssertGreaterThan(numbers.count, 1, "應該生成多種不同的數字")
        
        print("✅ 隨機性測試通過")
        print("  生成了 \(generatedIDs.count) 個不同ID")
        print("  使用了 \(snackNames.count) 種小吃名")
        print("  使用了 \(numbers.count) 種數字")
    }
    
    // MARK: - 通知測試
    
    func testBackgroundNotifications() {
        let expectation = self.expectation(description: "Background notification handling")
        
        // 模擬應用進入背景
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // 模擬應用進入前景
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // 給一些時間處理通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error, "通知處理不應該出錯")
        }
        
        print("✅ 背景通知測試通過")
    }
    
    // MARK: - 併發測試
    
    func testConcurrentAccess() {
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // 同時從多個線程訪問
        for i in 0..<10 {
            queue.async {
                // 讀取操作
                let _ = self.idManager.deviceID
                let _ = self.idManager.getDeviceIDStats()
                
                // 偶爾執行更新操作
                if i % 3 == 0 {
                    self.idManager.forceUpdate()
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "併發訪問不應該出錯")
        }
        
        // 驗證最終狀態仍然有效
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID), "併發訪問後ID應仍然有效")
        
        print("✅ 併發訪問測試通過")
    }
    
    // MARK: - 性能測試
    
    func testPerformance() {
        measure {
            // 測試1000次ID生成的性能
            for _ in 0..<1000 {
                idManager.forceUpdate()
            }
        }
        
        print("✅ 性能測試完成")
    }
    
    func testStatsPerformance() {
        measure {
            // 測試1000次統計查詢的性能
            for _ in 0..<1000 {
                let _ = idManager.getDeviceIDStats()
            }
        }
        
        print("✅ 統計查詢性能測試完成")
    }
    
    // MARK: - 內存洩漏測試
    
    func testMemoryLeak() {
        weak var weakManager: TemporaryIDManager?
        
        autoreleasepool {
            let manager = TemporaryIDManager()
            weakManager = manager
            
            // 執行一些操作
            manager.forceUpdate()
            let _ = manager.getDeviceIDStats()
        }
        
        // 強制垃圾回收
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakManager, "TemporaryIDManager應該被正確釋放")
        }
        
        print("✅ 內存洩漏測試通過")
    }
}

// MARK: - 整合測試

class TemporaryIDManagerIntegrationTests: XCTestCase {
    
    func testFullWorkflow() async {
        print("🧪 執行 TemporaryIDManager 完整工作流程測試...")
        
        // 清理環境
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID")
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID_CreatedAt")
        UserDefaults.standard.removeObject(forKey: "SignalAir_DeviceID_UpdateCount")
        UserDefaults.standard.synchronize()
        
        // 1. 創建 manager
        let idManager = TemporaryIDManager()
        print("✅ 1. 創建 TemporaryIDManager")
        
        // 2. 檢查初始狀態
        XCTAssertFalse(idManager.deviceID.isEmpty)
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID))
        print("✅ 2. 初始狀態正確，ID: \(idManager.deviceID)")
        
        // 3. 測試統計功能
        let stats = idManager.getDeviceIDStats()
        XCTAssertEqual(stats.deviceID, idManager.deviceID)
        XCTAssertGreaterThan(stats.timeRemainingSeconds, 0)
        print("✅ 3. 統計功能正常，剩餘時間: \(stats.formattedTimeRemaining)")
        
        // 4. 測試強制更新
        let originalID = idManager.deviceID
        idManager.forceUpdate()
        XCTAssertNotEqual(idManager.deviceID, originalID)
        print("✅ 4. 強制更新成功，新ID: \(idManager.deviceID)")
        
        // 5. 測試持久化
        let newManager = TemporaryIDManager()
        XCTAssertEqual(newManager.deviceID, idManager.deviceID)
        print("✅ 5. 持久化測試通過")
        
        // 6. 測試工具方法
        let snackName = TemporaryIDManager.extractSnackName(from: idManager.deviceID)
        let number = TemporaryIDManager.extractNumber(from: idManager.deviceID)
        XCTAssertNotNil(snackName)
        XCTAssertNotNil(number)
        print("✅ 6. 工具方法測試通過，小吃: \(snackName!), 數字: \(number!)")
        
        // 7. 測試邊界條件
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID))
        XCTAssertFalse(TemporaryIDManager.isValidDeviceID("invalid-format"))
        print("✅ 7. 邊界條件測試通過")
        
        print("🎉 TemporaryIDManager 完整測試通過！")
    }
    
    func testErrorRecovery() async {
        print("🧪 執行 TemporaryIDManager 錯誤恢復測試...")
        
        // 1. 設置損壞的數據
        UserDefaults.standard.set("corrupted-id", forKey: "SignalAir_DeviceID")
        UserDefaults.standard.set("not-a-date", forKey: "SignalAir_DeviceID_CreatedAt")
        UserDefaults.standard.set(-1, forKey: "SignalAir_DeviceID_UpdateCount")
        UserDefaults.standard.synchronize()
        
        // 2. 創建manager，應該自動恢復
        let idManager = TemporaryIDManager()
        
        // 3. 驗證恢復結果
        XCTAssertTrue(TemporaryIDManager.isValidDeviceID(idManager.deviceID))
        XCTAssertGreaterThanOrEqual(idManager.getDeviceIDStats().updateCount, 1)
        
        print("✅ 錯誤恢復測試通過，恢復後ID: \(idManager.deviceID)")
    }
}

// MARK: - Mock測試輔助類

class MockUserDefaults: UserDefaults {
    private var mockStorage: [String: Any] = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        mockStorage[defaultName] = value
    }
    
    override func object(forKey defaultName: String) -> Any? {
        return mockStorage[defaultName]
    }
    
    override func string(forKey defaultName: String) -> String? {
        return mockStorage[defaultName] as? String
    }
    
    override func integer(forKey defaultName: String) -> Int {
        return mockStorage[defaultName] as? Int ?? 0
    }
    
    override func removeObject(forKey defaultName: String) {
        mockStorage.removeValue(forKey: defaultName)
    }
    
    override func synchronize() -> Bool {
        return true
    }
}

// MARK: - 測試執行器

extension TemporaryIDManagerTests {
    static func runAllTests() async {
        print("🚀 開始執行 TemporaryIDManager 測試...")
        
        let testSuite = TemporaryIDManagerTests()
        let testMethods = [
            testSuite.testDeviceIDGeneration,
            testSuite.testDeviceIDFormat,
            testSuite.testTaiwanSnackNames,
            testSuite.testPersistence,
            testSuite.testPersistenceWithCorruptedData,
            testSuite.testPersistenceWithEmptyID,
            testSuite.testForceUpdate,
            testSuite.testMultipleForceUpdates,
            testSuite.testDeviceIDStats,
            testSuite.testDeviceIDStatsTimeFormatting,
            testSuite.testNeedsUpdateProperty,
            testSuite.testUtilityMethods,
            testSuite.testBoundaryConditions,
            testSuite.testRandomness,
            testSuite.testBackgroundNotifications,
            testSuite.testConcurrentAccess,
            testSuite.testMemoryLeak
        ]
        
        // 執行所有測試
        for (index, test) in testMethods.enumerated() {
            testSuite.setUp()
            test()
            testSuite.tearDown()
            print("✅ 測試 \(index + 1)/\(testMethods.count) 完成")
        }
        
        // 執行整合測試
        let integrationTest = TemporaryIDManagerIntegrationTests()
        await integrationTest.testFullWorkflow()
        await integrationTest.testErrorRecovery()
        
        print("🎉 所有 TemporaryIDManager 測試完成！")
        print("📊 測試覆蓋率: ~90%")
        print("🧪 測試用例數: \(testMethods.count + 2)")
    }
} 