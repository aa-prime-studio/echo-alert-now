import Foundation
// import XCTest - 使用相容性層
import Foundation
@testable import SignalAir

class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var mockTempIDManager: MockTemporaryIDManager!
    var mockNetworkService: MockNetworkService!
    var mockNicknameService: MockNicknameService!
    
    override func setUp() {
        super.setUp()
        
        // 創建 mock 服務
        mockTempIDManager = MockTemporaryIDManager()
        mockNetworkService = MockNetworkService()
        mockNicknameService = MockNicknameService()
        
        // 初始化 ViewModel
        viewModel = SettingsViewModel(
            temporaryIDManager: mockTempIDManager,
            networkService: mockNetworkService,
            nicknameService: mockNicknameService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockTempIDManager = nil
        mockNetworkService = nil
        mockNicknameService = nil
        super.tearDown()
    }
    
    // MARK: - 初始化測試
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.userNickname, mockNicknameService.nickname)
        XCTAssertEqual(viewModel.deviceID, mockTempIDManager.deviceID)
        XCTAssertEqual(viewModel.connectionStatus, "未連線")
        XCTAssertFalse(viewModel.isNetworkActive)
    }
    
    // MARK: - 暱稱管理測試
    
    func testUpdateNickname() {
        let newNickname = "新暱稱"
        
        viewModel.updateNickname(newNickname)
        
        XCTAssertEqual(viewModel.userNickname, newNickname)
        XCTAssertEqual(mockNicknameService.nickname, newNickname)
    }
    
    func testUpdateNicknameWithEmptyString() {
        let originalNickname = viewModel.userNickname
        
        viewModel.updateNickname("")
        
        XCTAssertEqual(viewModel.userNickname, originalNickname)
    }
    
    func testUpdateNicknameWithWhitespace() {
        let originalNickname = viewModel.userNickname
        
        viewModel.updateNickname("   ")
        
        XCTAssertEqual(viewModel.userNickname, originalNickname)
    }
    
    func testCanChangeNickname() {
        mockNicknameService.mockCanChangeNickname = true
        XCTAssertTrue(viewModel.canChangeNickname())
        
        mockNicknameService.mockCanChangeNickname = false
        XCTAssertFalse(viewModel.canChangeNickname())
    }
    
    // MARK: - 裝置ID測試
    
    func testForceUpdateDeviceID() {
        let originalID = viewModel.deviceID
        mockTempIDManager.deviceID = "新ID-99"
        
        viewModel.forceUpdateDeviceID()
        
        XCTAssertNotEqual(viewModel.deviceID, originalID)
        XCTAssertEqual(viewModel.deviceID, "新ID-99")
        XCTAssertTrue(mockTempIDManager.forceUpdateCalled)
    }
    
    func testGetDeviceIDTimeRemaining() {
        // 測試小時顯示
        mockTempIDManager.mockStats = DeviceIDStats(
            deviceID: "test-01",
            createdAt: Date(),
            nextUpdateTime: Date().addingTimeInterval(7200), // 2小時
            updateCount: 1,
            timeRemainingSeconds: 7200
        )
        
        viewModel.updateDeviceIDInfo()
        let timeString = viewModel.getDeviceIDTimeRemaining()
        XCTAssertTrue(timeString.contains("2小時"))
        
        // 測試分鐘顯示
        mockTempIDManager.mockStats = DeviceIDStats(
            deviceID: "test-01",
            createdAt: Date(),
            nextUpdateTime: Date().addingTimeInterval(1800), // 30分鐘
            updateCount: 1,
            timeRemainingSeconds: 1800
        )
        
        viewModel.updateDeviceIDInfo()
        let timeString2 = viewModel.getDeviceIDTimeRemaining()
        XCTAssertTrue(timeString2.contains("30分鐘"))
    }
    
    // MARK: - 網路連線測試
    
    func testStartNetworking() {
        viewModel.startNetworking()
        
        XCTAssertTrue(viewModel.isNetworkActive)
        XCTAssertTrue(mockNetworkService.startNetworkingCalled)
    }
    
    func testStopNetworking() {
        viewModel.startNetworking()
        viewModel.stopNetworking()
        
        XCTAssertFalse(viewModel.isNetworkActive)
        XCTAssertTrue(mockNetworkService.stopNetworkingCalled)
    }
    
    func testReconnect() {
        let expectation = XCTestExpectation(description: "Reconnect completed")
        
        viewModel.startNetworking()
        viewModel.reconnect()
        
        // 等待重新連線延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.mockNetworkService.stopNetworkingCalled)
            XCTAssertTrue(self.mockNetworkService.startNetworkingCalled)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - 連線狀態測試
    
    func testConnectionStatusDescription() {
        // 測試未啟動狀態
        viewModel.isNetworkActive = false
        XCTAssertEqual(viewModel.getConnectionStatusDescription(), "網路服務已停止")
        
        // 測試已連線狀態
        viewModel.isNetworkActive = true
        viewModel.connectionStatus = "已連線"
        viewModel.connectedPeerCount = 2
        XCTAssertEqual(viewModel.getConnectionStatusDescription(), "已連線 - 2 個裝置")
        
        // 測試連線中狀態
        viewModel.connectionStatus = "連線中"
        XCTAssertEqual(viewModel.getConnectionStatusDescription(), "正在搜尋其他裝置...")
    }
    
    func testConnectionStatusColor() {
        // 測試未啟動
        viewModel.isNetworkActive = false
        XCTAssertEqual(viewModel.getConnectionStatusColor(), .gray)
        
        // 測試已連線
        viewModel.isNetworkActive = true
        viewModel.connectionStatus = "已連線"
        XCTAssertEqual(viewModel.getConnectionStatusColor(), .green)
        
        // 測試連線中
        viewModel.connectionStatus = "連線中"
        XCTAssertEqual(viewModel.getConnectionStatusColor(), .orange)
        
        // 測試未連線
        viewModel.connectionStatus = "未連線"
        XCTAssertEqual(viewModel.getConnectionStatusColor(), .red)
    }
    
    // MARK: - 預覽測試
    
    func testPreviewCreation() {
        let previewViewModel = SettingsViewModel.preview()
        
        XCTAssertNotNil(previewViewModel)
        XCTAssertEqual(previewViewModel.userNickname, "測試使用者")
        XCTAssertEqual(previewViewModel.deviceID, "珍珠奶茶-42")
        XCTAssertEqual(previewViewModel.connectionStatus, "已連線")
        XCTAssertEqual(previewViewModel.connectedPeerCount, 2)
        XCTAssertTrue(previewViewModel.isNetworkActive)
    }
}

// MARK: - Mock 類別

class MockTemporaryIDManager: TemporaryIDManager {
    var forceUpdateCalled = false
    var mockStats: DeviceIDStats?
    
    override init() {
        super.init()
        deviceID = "測試-01"
    }
    
    override func forceUpdate() {
        forceUpdateCalled = true
        deviceID = "新ID-99"
    }
    
    override func getDeviceIDStats() -> DeviceIDStats {
        return mockStats ?? DeviceIDStats(
            deviceID: deviceID,
            createdAt: Date(),
            nextUpdateTime: Date().addingTimeInterval(86400),
            updateCount: 1,
            timeRemainingSeconds: 86400
        )
    }
}

class MockNetworkService: NetworkService {
    var startNetworkingCalled = false
    var stopNetworkingCalled = false
    
    override func startNetworking() {
        startNetworkingCalled = true
        connectionStatus = .connecting
    }
    
    override func stopNetworking() {
        stopNetworkingCalled = true
        connectionStatus = .disconnected
    }
}

class MockNicknameService: NicknameService {
    var mockCanChangeNickname = true
    
    override init() {
        super.init()
        nickname = "測試暱稱"
    }
    
    override func canChangeNickname() -> Bool {
        return mockCanChangeNickname
    }
    
    override func getRemainingChangesText() -> String {
        return mockCanChangeNickname ? "" : "今日已達變更上限"
    }
} 