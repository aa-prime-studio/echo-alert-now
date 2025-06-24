// import XCTest
// @testable import SignalAir

/// 整合測試 - 測試多個模組之間的協作
/// 注意：暫時禁用XCTest功能，等待正確的測試target設置
class IntegrationTests {
    
    // 暫時註釋掉測試相關代碼
    /*
    var serviceContainer: ServiceContainer!
    var chatViewModel: ChatViewModel!
    var signalViewModel: SignalViewModel!
    var gameViewModel: BingoGameViewModel!
    
    override func setUpWithError() throws {
        serviceContainer = ServiceContainer.shared
        
        // 等待服務初始化
        let expectation = XCTestExpectation(description: "Service initialization")
        
        Task {
            // 等待一段時間讓服務初始化
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // 創建測試用的 ViewModels
        chatViewModel = serviceContainer.createChatViewModel()
        signalViewModel = serviceContainer.createSignalViewModel()
        gameViewModel = serviceContainer.createBingoGameViewModel()
    }
    
    override func tearDownWithError() throws {
        Task {
            await serviceContainer.shutdown()
        }
        chatViewModel = nil
        signalViewModel = nil
        gameViewModel = nil
        serviceContainer = nil
    }
    */
    
    // MARK: - 測試功能已暫時禁用
    
    static func runManualTests() {
        print("📋 整合測試功能已暫時禁用")
        print("💡 要啟用測試，請在Xcode中創建正確的測試target")
        print("🔧 然後取消註釋此文件中的測試代碼")
    }
} 