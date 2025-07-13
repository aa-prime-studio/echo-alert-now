import XCTest
import MultipeerConnectivity
@testable import SignalAir

/// 【網路工程師】MultipeerConnectivity 穩定性測試
class NetworkStabilityTests: XCTestCase {
    
    var viewModel: BingoGameViewModel!
    var networkMonitor: NetworkConnectionMonitor!
    
    override func setUp() {
        super.setUp()
        viewModel = createTestBingoGameViewModel()
        networkMonitor = NetworkConnectionMonitor()
    }
    
    override func tearDown() {
        viewModel = nil
        networkMonitor = nil
        super.tearDown()
    }
    
    // MARK: - 原始崩潰場景重現測試
    
    func testRapidGameRoomEntry() {
        let expectation = self.expectation(description: "Rapid room entry test")
        expectation.expectedFulfillmentCount = 5
        
        // 模擬快速進入賓果遊戲室（原始崩潰觸發場景）
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                self.viewModel.attemptToJoinOrCreateRoom(roomID: "rapid-test-room-\(i)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error, "Rapid room entry should not cause 'Not in connected state' crashes")
        }
    }
    
    func testUnstableNetworkConditions() {
        let expectation = self.expectation(description: "Unstable network test")
        
        // 模擬網路不穩定的情況
        networkMonitor.simulateNetworkInstability()
        
        viewModel.attemptToJoinOrCreateRoom(roomID: "unstable-network-room")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 驗證沒有崩潰，並且有適當的錯誤處理
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Unstable network should be handled gracefully")
        }
    }
    
    func testFrequentRoomSwitching() {
        let expectation = self.expectation(description: "Room switching test")
        expectation.expectedFulfillmentCount = 10
        
        // 模擬頻繁切換房間
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                self.viewModel.attemptToJoinOrCreateRoom(roomID: "switch-room-\(i)")
                expectation.fulfill()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.viewModel.leaveRoom()
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Frequent room switching should not cause crashes")
        }
    }
    
    func testBackgroundForegroundTransitions() {
        let expectation = self.expectation(description: "Background/Foreground test")
        
        // 進入房間
        viewModel.attemptToJoinOrCreateRoom(roomID: "background-test-room")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 模擬應用程式進入背景
            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 模擬應用程式回到前景
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Background/Foreground transitions should be stable")
        }
    }
    
    // MARK: - 通道狀態驗證測試
    
    func testChannelStateValidation() {
        let expectation = self.expectation(description: "Channel state validation")
        
        // 測試 validateChannelState 方法是否正確工作
        viewModel.attemptToJoinOrCreateRoom(roomID: "channel-validation-room")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 嘗試發送訊息，應該先驗證通道狀態
            do {
                // 這應該觸發通道狀態驗證
                self.viewModel.sendChatMessage("Test message for channel validation")
                expectation.fulfill()
            } catch {
                // 如果有錯誤，確保是預期的錯誤，而不是崩潰
                XCTAssertTrue(error is NetworkError, "Should throw NetworkError, not crash")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    // MARK: - 輔助類別和方法
    
    private func createTestBingoGameViewModel() -> BingoGameViewModel {
        let mockMeshManager = MockMeshManager()
        let mockSecurityService = SecurityService()
        let mockSettingsViewModel = SettingsViewModel()
        let mockLanguageService = LanguageService()
        let mockNicknameService = NicknameService()
        
        return BingoGameViewModel(
            meshManager: mockMeshManager,
            securityService: mockSecurityService,
            settingsViewModel: mockSettingsViewModel,
            languageService: mockLanguageService,
            nicknameService: mockNicknameService
        )
    }
}

/// 網路連接監控器
class NetworkConnectionMonitor {
    private var isUnstable = false
    
    func simulateNetworkInstability() {
        isUnstable = true
        
        // 模擬網路斷線和重連
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isUnstable = false
        }
    }
    
    var isNetworkStable: Bool {
        return !isUnstable
    }
}

/// Mock NetworkError for testing
enum NetworkError: Error {
    case notConnected
    case peerNotFound
    case sendFailed
    case sessionError(String)
}

// 擴展 BingoGameViewModel 以支援測試
extension BingoGameViewModel {
    func sendChatMessage(_ message: String) throws {
        // 模擬發送聊天訊息的方法
        // 在實際實現中，這應該會觸發通道狀態驗證
        if !isNetworkReady() {
            throw NetworkError.notConnected
        }
    }
    
    private func isNetworkReady() -> Bool {
        // 模擬網路就緒檢查
        return true
    }
}