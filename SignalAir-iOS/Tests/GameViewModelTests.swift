import XCTest
@testable import SignalAir

// MARK: - GameView ViewModel 測試
class GameViewModelTests: XCTestCase {
    
    var viewModel: BingoGameViewModel!
    var mockMeshManager: MockMeshManager!
    var mockSecurityService: MockSecurityService!
    
    override func setUp() {
        super.setUp()
        // 設置測試環境
        mockMeshManager = MockMeshManager()
        mockSecurityService = MockSecurityService()
    }
    
    override func tearDown() {
        viewModel = nil
        mockMeshManager = nil
        mockSecurityService = nil
        super.tearDown()
    }
    
    // MARK: - 延遲初始化測試
    
    func testDelayedInitialization() {
        // 測試：ViewModel 應該在進入房間時才初始化網路
        XCTAssertFalse(mockMeshManager.isNetworkStarted, "網路不應該在初始化時啟動")
        
        // 模擬進入房間
        viewModel?.createGameRoom()
        
        // 驗證網路已啟動
        XCTAssertTrue(mockMeshManager.isNetworkStarted, "網路應該在進入房間時啟動")
    }
    
    // MARK: - 連鎖崩潰防護測試
    
    func testChainCrashPrevention() {
        // 測試：一個設備的錯誤不應該傳播到其他設備
        
        // 模擬網路錯誤
        mockMeshManager.simulateNetworkError("Not in connected state")
        
        // 驗證 ViewModel 狀態
        XCTAssertFalse(viewModel?.isNetworkActive ?? true, "網路應該標記為不活躍")
        
        // 驗證錯誤不會導致崩潰
        XCTAssertNoThrow({
            viewModel?.broadcastGameMessage(.gameStart, data: Data())
        }, "廣播訊息不應該拋出異常")
    }
    
    // MARK: - 資源清理測試
    
    func testResourceCleanup() {
        // 測試：離開房間時應該正確清理資源
        
        viewModel?.createGameRoom()
        XCTAssertTrue(viewModel?.isInRoom ?? false, "應該在房間內")
        
        // 離開房間
        viewModel?.leaveRoom()
        
        // 驗證資源已清理
        XCTAssertFalse(viewModel?.isInRoom ?? true, "應該已離開房間")
        XCTAssertFalse(viewModel?.isNetworkActive ?? true, "網路應該已停止")
        XCTAssertTrue(viewModel?.roomPlayers.isEmpty ?? false, "玩家列表應該已清空")
    }
}

// MARK: - Mock Objects

class MockMeshManager: MeshManagerProtocol {
    var isNetworkStarted = false
    var lastError: String?
    
    func startMeshNetwork() {
        isNetworkStarted = true
    }
    
    func stopMeshNetwork() {
        isNetworkStarted = false
    }
    
    func isNetworkReady() -> Bool {
        return isNetworkStarted && lastError == nil
    }
    
    func getConnectedPeers() -> [String] {
        return isNetworkStarted ? ["TestPeer1", "TestPeer2"] : []
    }
    
    func simulateNetworkError(_ error: String) {
        lastError = error
    }
    
    // 其他協議方法的空實現...
    func broadcastMessage(_ data: Data, messageType: MeshMessageType) {}
    func sendDirectMessage(_ data: Data, to peerID: String, messageType: MeshMessageType) {}
    func getNetworkTopology() -> [String: Set<String>] { return [:] }
}

class MockSecurityService: SecurityService {
    // Mock 實現
}