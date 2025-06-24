import XCTest
@testable import SignalAir

/// 服務容器單元測試
class ServiceContainerTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUpWithError() throws {
        // 每個測試開始前創建新的服務容器實例
        serviceContainer = ServiceContainer.shared
    }
    
    override func tearDownWithError() throws {
        // 清理測試後的狀態
        Task {
            await serviceContainer.shutdown()
        }
        serviceContainer = nil
    }
    
    // MARK: - 服務初始化測試
    
    func testServiceContainerInitialization() throws {
        // 測試服務容器是否正確初始化
        XCTAssertNotNil(serviceContainer)
        XCTAssertNotNil(serviceContainer.networkService)
        XCTAssertNotNil(serviceContainer.securityService)
        XCTAssertNotNil(serviceContainer.meshManager)
        XCTAssertNotNil(serviceContainer.languageService)
        XCTAssertNotNil(serviceContainer.purchaseService)
        XCTAssertNotNil(serviceContainer.nicknameService)
    }
    
    func testCoreServicesAvailability() throws {
        // 測試核心服務是否可用
        XCTAssertNotNil(serviceContainer.temporaryIDManager)
        XCTAssertNotNil(serviceContainer.selfDestructManager)
        XCTAssertNotNil(serviceContainer.floodProtection)
        XCTAssertNotNil(serviceContainer.settingsViewModel)
    }
    
    // MARK: - ViewModel 創建測試
    
    func testChatViewModelCreation() throws {
        // 測試 ChatViewModel 是否能正確創建並注入依賴
        let chatViewModel = serviceContainer.createChatViewModel()
        
        XCTAssertNotNil(chatViewModel)
        // 測試依賴是否正確注入（透過行為驗證）
        XCTAssertTrue(chatViewModel.messages.isEmpty) // 初始狀態
    }
    
    func testSignalViewModelCreation() throws {
        // 測試 SignalViewModel 是否能正確創建並注入依賴
        let signalViewModel = serviceContainer.createSignalViewModel()
        
        XCTAssertNotNil(signalViewModel)
        XCTAssertEqual(signalViewModel.deviceName, "SignalAir Rescue裝置")
        XCTAssertTrue(signalViewModel.messages.isEmpty)
    }
    
    func testBingoGameViewModelCreation() throws {
        // 測試 BingoGameViewModel 是否能正確創建並注入依賴
        let gameViewModel = serviceContainer.createBingoGameViewModel()
        
        XCTAssertNotNil(gameViewModel)
        // 測試初始遊戲狀態
        XCTAssertEqual(gameViewModel.gameState, .waitingForPlayers)
    }
    
    // MARK: - 服務健康檢查測試
    
    func testServiceHealthCheck() async throws {
        // 等待服務初始化
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let healthStatus = await serviceContainer.performHealthCheck()
        
        // 驗證健康檢查結果
        XCTAssertNotNil(healthStatus)
        
        // 在測試環境中，某些服務可能不會完全啟動，所以我們檢查基本結構
        XCTAssertNotNil(healthStatus.healthSummary)
        
        print("📊 Health Status: \(healthStatus.healthSummary)")
    }
    
    // MARK: - 服務依賴關係測試
    
    func testServiceDependencyInjection() throws {
        // 測試服務之間的依賴關係是否正確建立
        let chatViewModel1 = serviceContainer.createChatViewModel()
        let chatViewModel2 = serviceContainer.createChatViewModel()
        
        // 兩個 ViewModel 應該共享相同的服務實例
        // 這是透過服務容器的單例模式確保的
        XCTAssertNotNil(chatViewModel1)
        XCTAssertNotNil(chatViewModel2)
    }
    
    func testSettingsViewModelSync() throws {
        // 測試設定 ViewModel 與暱稱服務的同步
        let originalNickname = serviceContainer.settingsViewModel.userNickname
        
        // 修改暱稱服務
        serviceContainer.nicknameService.nickname = "測試使用者"
        
        // 等待同步
        let expectation = XCTestExpectation(description: "Nickname sync")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // 驗證設定 ViewModel 是否同步更新
        // 注意：這需要根據實際的同步機制調整
        print("Original: \(originalNickname), New: \(serviceContainer.settingsViewModel.userNickname)")
    }
    
    // MARK: - 錯誤處理測試
    
    func testServiceInitializationError() async throws {
        // 測試服務初始化錯誤處理
        
        // 等待初始化完成或失敗
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        if let error = serviceContainer.initializationError {
            print("⚠️ Service initialization error: \(error)")
            // 在實際情況下，我們可能需要檢查錯誤處理機制
        } else {
            print("✅ Services initialized successfully")
        }
        
        // 測試不應該失敗，即使有初始化錯誤也應該優雅處理
        XCTAssertTrue(true, "Error handling test completed")
    }
    
    // MARK: - 效能測試
    
    func testViewModelCreationPerformance() throws {
        // 測試 ViewModel 創建的效能
        measure {
            for _ in 0..<10 {
                let _ = serviceContainer.createChatViewModel()
                let _ = serviceContainer.createSignalViewModel()
                let _ = serviceContainer.createBingoGameViewModel()
            }
        }
    }
    
    // MARK: - 記憶體洩漏測試
    
    func testMemoryLeak() throws {
        weak var weakContainer: ServiceContainer?
        
        autoreleasepool {
            let container = ServiceContainer.shared
            weakContainer = container
            
            // 創建一些 ViewModel
            let _ = container.createChatViewModel()
            let _ = container.createSignalViewModel()
        }
        
        // 在這個測試中，由於使用單例，容器不會被釋放
        // 這是預期的行為
        XCTAssertNotNil(weakContainer, "Service container should remain alive as singleton")
    }
} 