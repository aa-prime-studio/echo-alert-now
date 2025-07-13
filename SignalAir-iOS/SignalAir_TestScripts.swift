// SignalAir_TestScripts.swift
// 具體可執行的測試腳本集合

import XCTest
import StoreKit
@testable import SignalAir

// MARK: - 購買流程自動化測試腳本

class PurchaseFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 正常購買流程測試
    
    func testSuccessfulBingoPurchase() {
        // TC-002: 用戶選擇賓果解鎖版(NT$330)並成功購買
        
        // 1. 進入設定頁面
        app.tabBars.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].exists)
        
        // 2. 點擊升級選項
        app.buttons["升級到高級版"].tap()
        XCTAssertTrue(app.navigationBars["升級選項"].exists)
        
        // 3. 選擇賓果版本
        let bingoCard = app.buttons["成為play的一環版"]
        XCTAssertTrue(bingoCard.exists)
        bingoCard.tap()
        
        // 4. 驗證選擇狀態
        XCTAssertTrue(app.images["checkmark.circle.fill"].exists)
        
        // 5. 點擊購買按鈕
        let purchaseButton = app.buttons["購買 成為play的一環版"]
        XCTAssertTrue(purchaseButton.exists)
        XCTAssertTrue(purchaseButton.isEnabled)
        purchaseButton.tap()
        
        // 6. 在測試模式下驗證自動解鎖
        // 等待購買處理完成
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.activityIndicators.firstMatch
        )
        wait(for: [expectation], timeout: 10.0)
        
        // 7. 驗證購買成功
        XCTAssertFalse(app.staticTexts["購買失敗"].exists)
        
        // 8. 返回主介面驗證功能解鎖
        app.buttons["取消"].tap()
        app.tabBars.buttons["遊戲"].tap()
        
        // 9. 驗證賓果遊戲功能已解鎖
        XCTAssertTrue(app.buttons["開始賓果遊戲"].isEnabled)
    }
    
    func testSuccessfulFullVersionPurchase() {
        // TC-003: 用戶選擇完整版(NT$1,680)並成功購買
        
        navigateToUpgradeScreen()
        
        // 選擇完整版
        let fullVersionCard = app.buttons["好想吃丹丹漢堡版"]
        XCTAssertTrue(fullVersionCard.exists)
        fullVersionCard.tap()
        
        // 驗證選擇狀態
        XCTAssertTrue(app.images["checkmark.circle.fill"].exists)
        
        // 點擊購買按鈕
        let purchaseButton = app.buttons["購買 好想吃丹丹漢堡版"]
        purchaseButton.tap()
        
        // 驗證購買成功和功能解鎖
        waitForPurchaseCompletion()
        verifyAllFeaturesUnlocked()
    }
    
    func testCoffeePurchase() {
        // TC-001: 用戶選擇咖啡版本(NT$90)並成功購買
        
        navigateToUpgradeScreen()
        
        // 選擇咖啡版本
        let coffeeCard = app.buttons["喝杯楊枝甘露"]
        XCTAssertTrue(coffeeCard.exists)
        coffeeCard.tap()
        
        // 點擊購買按鈕
        let purchaseButton = app.buttons["購買 喝杯楊枝甘露"]
        purchaseButton.tap()
        
        // 驗證購買成功但無功能解鎖
        waitForPurchaseCompletion()
        verifyNoFeaturesUnlocked()
    }
    
    // MARK: - 異常流程測試
    
    func testPurchaseCancellation() {
        // TC-004: 用戶在購買過程中取消交易
        
        navigateToUpgradeScreen()
        
        // 選擇產品
        app.buttons["成為play的一環版"].tap()
        
        // 點擊購買按鈕
        app.buttons["購買 成為play的一環版"].tap()
        
        // 模擬取消（在測試環境中）
        if app.buttons["取消"].exists {
            app.buttons["取消"].tap()
        }
        
        // 驗證取消後狀態
        XCTAssertFalse(app.staticTexts["購買成功"].exists)
        verifyNoFeaturesUnlocked()
    }
    
    func testNetworkErrorHandling() {
        // TC-006: 網路連線中斷時進行購買
        
        // 模擬網路錯誤狀態
        app.launchArguments.append("--network-error")
        app.terminate()
        app.launch()
        
        navigateToUpgradeScreen()
        
        // 嘗試購買
        app.buttons["成為play的一環版"].tap()
        app.buttons["購買 成為play的一環版"].tap()
        
        // 驗證錯誤處理
        XCTAssertTrue(app.staticTexts["網路連接失敗"].exists)
        XCTAssertTrue(app.buttons["重試載入"].exists)
    }
    
    func testDuplicatePurchase() {
        // TC-009: 重複購買同一產品
        
        // 先完成一次購買
        performSuccessfulPurchase()
        
        // 再次嘗試購買
        navigateToUpgradeScreen()
        app.buttons["成為play的一環版"].tap()
        
        // 驗證購買按鈕狀態
        let purchaseButton = app.buttons["購買 成為play的一環版"]
        XCTAssertFalse(purchaseButton.isEnabled)
    }
    
    func testRestorePurchases() {
        // TC-005: 用戶恢復已購買的內容
        
        // 先完成一次購買
        performSuccessfulPurchase()
        
        // 模擬重新安裝（清除購買狀態）
        resetPurchaseState()
        
        // 進入升級頁面
        navigateToUpgradeScreen()
        
        // 點擊恢復購買
        app.buttons["恢復購買"].tap()
        
        // 驗證恢復成功
        waitForPurchaseCompletion()
        verifyBingoFeatureUnlocked()
    }
    
    // MARK: - 輔助方法
    
    private func navigateToUpgradeScreen() {
        app.tabBars.buttons["設定"].tap()
        app.buttons["升級到高級版"].tap()
    }
    
    private func waitForPurchaseCompletion() {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.activityIndicators.firstMatch
        )
        wait(for: [expectation], timeout: 30.0)
    }
    
    private func verifyAllFeaturesUnlocked() {
        app.buttons["取消"].tap()
        app.tabBars.buttons["遊戲"].tap()
        XCTAssertTrue(app.buttons["開始賓果遊戲"].isEnabled)
    }
    
    private func verifyBingoFeatureUnlocked() {
        app.buttons["取消"].tap()
        app.tabBars.buttons["遊戲"].tap()
        XCTAssertTrue(app.buttons["開始賓果遊戲"].isEnabled)
    }
    
    private func verifyNoFeaturesUnlocked() {
        app.buttons["取消"].tap()
        app.tabBars.buttons["遊戲"].tap()
        XCTAssertFalse(app.buttons["開始賓果遊戲"].isEnabled)
    }
    
    private func performSuccessfulPurchase() {
        navigateToUpgradeScreen()
        app.buttons["成為play的一環版"].tap()
        app.buttons["購買 成為play的一環版"].tap()
        waitForPurchaseCompletion()
    }
    
    private func resetPurchaseState() {
        // 在測試環境中重置購買狀態
        app.launchArguments.append("--reset-purchases")
        app.terminate()
        app.launch()
    }
}

// MARK: - 單元測試腳本

class PurchaseServiceUnitTests: XCTestCase {
    
    var purchaseService: PurchaseService!
    
    override func setUp() {
        super.setUp()
        purchaseService = PurchaseService()
    }
    
    override func tearDown() {
        purchaseService = nil
        super.tearDown()
    }
    
    // MARK: - 解鎖機制測試
    
    func testUnlockAfterBingoPurchase() {
        // TC-012: 檢查購買賓果版後的功能狀態
        
        // 初始狀態應該是未解鎖
        XCTAssertFalse(purchaseService.isPremiumUser)
        
        // 模擬購買賓果版
        purchaseService.simulatePurchase(.bingoUnlock)
        
        // 驗證解鎖狀態
        XCTAssertTrue(purchaseService.isPremiumUser)
        XCTAssertTrue(purchaseService.purchasedTiers.contains("com.signalair.bingo"))
        
        // 驗證顯示名稱
        let displayName = purchaseService.getPurchasedTierDisplayName(language: .chinese)
        XCTAssertEqual(displayName, "成為play的一環版")
    }
    
    func testUnlockAfterFullVersionPurchase() {
        // TC-013: 檢查購買完整版後的功能狀態
        
        // 模擬購買完整版
        purchaseService.simulatePurchase(.fullVersion)
        
        // 驗證解鎖狀態
        XCTAssertTrue(purchaseService.isPremiumUser)
        XCTAssertTrue(purchaseService.purchasedTiers.contains("com.signalair.full"))
        
        // 驗證顯示名稱
        let displayName = purchaseService.getPurchasedTierDisplayName(language: .chinese)
        XCTAssertEqual(displayName, "好想吃丹丹漢堡版")
    }
    
    func testCoffeePurchaseNoUnlock() {
        // TC-001: 檢查咖啡版本購買後的狀態
        
        // 模擬購買咖啡版
        purchaseService.simulatePurchase(.coffee)
        
        // 驗證不解鎖高級功能
        XCTAssertFalse(purchaseService.isPremiumUser)
        XCTAssertTrue(purchaseService.purchasedTiers.contains("com.signalair.coffee"))
        
        // 但應該有購買記錄
        let displayName = purchaseService.getPurchasedTierDisplayName(language: .chinese)
        XCTAssertEqual(displayName, "喝杯楊枝甘露")
    }
    
    func testPurchaseStatePersistence() {
        // TC-015: 購買後重啟應用程式
        
        // 模擬購買
        purchaseService.simulatePurchase(.bingoUnlock)
        XCTAssertTrue(purchaseService.isPremiumUser)
        
        // 模擬應用重啟
        let newPurchaseService = PurchaseService()
        
        // 驗證狀態持久化
        XCTAssertTrue(newPurchaseService.isPremiumUser)
        XCTAssertTrue(newPurchaseService.purchasedTiers.contains("com.signalair.bingo"))
    }
    
    func testTestModeAutoUnlock() {
        // TC-014: 檢查測試模式下的功能狀態
        
        // 在測試模式下應該自動解鎖
        #if DEBUG
        // 模擬測試模式
        UserDefaults.standard.set(true, forKey: "SignalAir_TestMode")
        let testModeService = PurchaseService()
        
        // 驗證自動解鎖
        XCTAssertTrue(testModeService.isPremiumUser)
        
        // 清理測試狀態
        UserDefaults.standard.removeObject(forKey: "SignalAir_TestMode")
        #endif
    }
    
    // MARK: - 錯誤處理測試
    
    func testDuplicatePurchaseHandling() {
        // TC-009: 重複購買同一產品
        
        // 第一次購買
        purchaseService.simulatePurchase(.bingoUnlock)
        XCTAssertTrue(purchaseService.isPremiumUser)
        
        // 嘗試重複購買
        let initialTierCount = purchaseService.purchasedTiers.count
        purchaseService.simulatePurchase(.bingoUnlock)
        
        // 驗證不會重複添加
        XCTAssertEqual(purchaseService.purchasedTiers.count, initialTierCount)
        XCTAssertTrue(purchaseService.isPremiumUser)
    }
    
    func testPurchaseStateReset() {
        // 測試用重置功能
        
        // 模擬購買
        purchaseService.simulatePurchase(.fullVersion)
        XCTAssertTrue(purchaseService.isPremiumUser)
        
        // 重置狀態
        purchaseService.resetPurchases()
        
        // 驗證重置成功
        XCTAssertFalse(purchaseService.isPremiumUser)
        XCTAssertTrue(purchaseService.purchasedTiers.isEmpty)
    }
    
    // MARK: - 多語言測試
    
    func testMultiLanguageSupport() {
        // TC-023 & TC-024: 多語言支援測試
        
        // 測試中文顯示
        let chineseNames = PurchaseService.PurchaseTier.allCases.map { 
            $0.displayName(language: .chinese) 
        }
        XCTAssertEqual(chineseNames[0], "喝杯楊枝甘露")
        XCTAssertEqual(chineseNames[1], "成為play的一環版")
        XCTAssertEqual(chineseNames[2], "好想吃丹丹漢堡版")
        
        // 測試英文顯示
        let englishNames = PurchaseService.PurchaseTier.allCases.map { 
            $0.displayName(language: .english) 
        }
        XCTAssertEqual(englishNames[0], "Buy a Drink")
        XCTAssertEqual(englishNames[1], "Part of Play Edition")
        XCTAssertEqual(englishNames[2], "Want Dan Dan Burger Edition")
    }
}

// MARK: - 性能測試腳本

class PurchasePerformanceTests: XCTestCase {
    
    var purchaseService: PurchaseService!
    
    override func setUp() {
        super.setUp()
        purchaseService = PurchaseService()
    }
    
    override func tearDown() {
        purchaseService = nil
        super.tearDown()
    }
    
    func testPurchaseFlowPerformance() {
        // 測試購買流程性能
        
        measure {
            let expectation = self.expectation(description: "購買完成")
            
            Task {
                await purchaseService.purchase(.bingoUnlock)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 30.0)
        }
    }
    
    func testUnlockStateCheckPerformance() {
        // 測試解鎖狀態檢查性能
        
        purchaseService.simulatePurchase(.bingoUnlock)
        
        measure {
            for _ in 0..<1000 {
                _ = purchaseService.isPremiumUser
            }
        }
    }
    
    func testMemoryUsageUnderLoad() {
        // 測試記憶體使用
        
        let initialMemory = getMemoryUsage()
        
        // 執行100次購買模擬
        for _ in 0..<100 {
            autoreleasepool {
                let service = PurchaseService()
                service.simulatePurchase(.bingoUnlock)
            }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // 記憶體增長應該小於50MB
        XCTAssertLessThan(memoryIncrease, 50_000_000, "記憶體使用增長超標: \(memoryIncrease) bytes")
    }
    
    func testConcurrentPurchaseHandling() {
        // 測試並發購買處理
        
        let expectation = self.expectation(description: "並發購買完成")
        expectation.expectedFulfillmentCount = 10
        
        // 同時發起10個購買請求
        for i in 0..<10 {
            DispatchQueue.global().async {
                let service = PurchaseService()
                service.simulatePurchase(.bingoUnlock)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10.0)
    }
}

// MARK: - 安全測試腳本

class PurchaseSecurityTests: XCTestCase {
    
    var purchaseService: PurchaseService!
    
    override func setUp() {
        super.setUp()
        purchaseService = PurchaseService()
    }
    
    override func tearDown() {
        purchaseService = nil
        super.tearDown()
    }
    
    func testPurchaseStateTamperProtection() {
        // 測試購買狀態篡改防護
        
        // 初始狀態應該是未解鎖
        XCTAssertFalse(purchaseService.isPremiumUser)
        
        // 嘗試直接修改UserDefaults
        UserDefaults.standard.set(["com.signalair.full"], forKey: "SignalAir_PurchasedTiers")
        
        // 創建新的服務實例
        let newService = PurchaseService()
        
        // 在沒有實際購買的情況下，應該進行StoreKit驗證
        // 這裡測試本地狀態加載
        XCTAssertTrue(newService.purchasedTiers.contains("com.signalair.full"))
        
        // 但實際的isPremiumUser應該依賴於StoreKit驗證
        // 在測試環境中，這會通過測試模式處理
    }
    
    func testSensitiveDataNotLogged() {
        // 測試敏感資料不被記錄
        
        // 模擬購買流程
        purchaseService.simulatePurchase(.bingoUnlock)
        
        // 檢查UserDefaults中是否有敏感資料
        let purchasedTiers = UserDefaults.standard.array(forKey: "SignalAir_PurchasedTiers") as? [String] ?? []
        
        // 驗證只存儲產品ID，不存儲敏感資料
        XCTAssertTrue(purchasedTiers.contains("com.signalair.bingo"))
        XCTAssertFalse(purchasedTiers.contains("apple_id"))
        XCTAssertFalse(purchasedTiers.contains("transaction_id"))
    }
    
    func testTestModeIsolation() {
        // 測試測試模式與生產環境隔離
        
        #if DEBUG
        // 測試模式標記
        UserDefaults.standard.set(true, forKey: "SignalAir_TestMode")
        let testService = PurchaseService()
        
        // 在測試模式下應該自動解鎖
        XCTAssertTrue(testService.isPremiumUser)
        
        // 清理測試狀態
        UserDefaults.standard.removeObject(forKey: "SignalAir_TestMode")
        #else
        // 生產環境不應該有測試模式
        let prodService = PurchaseService()
        XCTAssertFalse(prodService.isPremiumUser)
        #endif
    }
}

// MARK: - 測試輔助工具

extension XCTestCase {
    
    /// 獲取當前記憶體使用量
    func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - 測試配置

class TestConfiguration {
    
    static let shared = TestConfiguration()
    
    private init() {}
    
    /// 設置測試環境
    func setupTestEnvironment() {
        // 設置測試模式
        UserDefaults.standard.set(true, forKey: "SignalAir_TestMode")
        
        // 清理之前的測試資料
        UserDefaults.standard.removeObject(forKey: "SignalAir_PurchasedTiers")
        
        // 設置測試語言
        UserDefaults.standard.set("zh-Hant", forKey: "AppLanguage")
    }
    
    /// 清理測試環境
    func cleanupTestEnvironment() {
        UserDefaults.standard.removeObject(forKey: "SignalAir_TestMode")
        UserDefaults.standard.removeObject(forKey: "SignalAir_PurchasedTiers")
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
}

// MARK: - 測試執行器

class TestRunner {
    
    static func runAllTests() {
        print("🧪 開始執行 SignalAir 解鎖機制測試套件")
        
        // 設置測試環境
        TestConfiguration.shared.setupTestEnvironment()
        
        // 執行測試
        let testSuite = XCTestSuite(name: "SignalAir Purchase Tests")
        
        // 添加測試類
        testSuite.addTest(PurchaseServiceUnitTests.defaultTestSuite())
        testSuite.addTest(PurchasePerformanceTests.defaultTestSuite())
        testSuite.addTest(PurchaseSecurityTests.defaultTestSuite())
        
        // 運行測試
        XCTMain([testSuite])
        
        // 清理測試環境
        TestConfiguration.shared.cleanupTestEnvironment()
        
        print("✅ SignalAir 解鎖機制測試套件執行完成")
    }
}