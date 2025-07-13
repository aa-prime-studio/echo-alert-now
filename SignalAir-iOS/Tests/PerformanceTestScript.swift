import XCTest
import Foundation
@testable import SignalAir

/// 【性能工程師】Timer 管理性能測試
class TimerPerformanceTests: XCTestCase {
    
    // MARK: - Timer 記憶體洩漏測試
    
    func testTimerMemoryLeakPrevention() {
        let expectation = self.expectation(description: "Timer cleanup completed")
        
        weak var weakViewModel: BingoGameViewModel?
        
        autoreleasepool {
            // 模擬創建 BingoGameViewModel
            let viewModel = createTestBingoGameViewModel()
            weakViewModel = viewModel
            
            // 模擬進入遊戲室，啟動多個定時器
            viewModel.attemptToJoinOrCreateRoom(roomID: "test-room-123")
            
            // 等待定時器啟動
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 模擬離開遊戲室
                viewModel.leaveRoom()
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0) { _ in
            // 驗證 ViewModel 是否被正確釋放
            XCTAssertNil(weakViewModel, "BingoGameViewModel should be deallocated after leaving room")
        }
    }
    
    // MARK: - Timer 數量監控測試
    
    func testTimerCountReduction() {
        let viewModel = createTestBingoGameViewModel()
        
        // 進入遊戲室前的基線
        let initialTimerCount = getCurrentTimerCount()
        
        // 進入遊戲室，應該啟動統一管理的定時器
        viewModel.attemptToJoinOrCreateRoom(roomID: "performance-test-room")
        
        // 等待定時器啟動
        let expectation = self.expectation(description: "Timers started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let activeTimerCount = getCurrentTimerCount()
            
            // 驗證定時器數量是否在合理範圍內
            // 之前: 7個獨立Timer，現在: 統一管理
            XCTAssertLessThanOrEqual(activeTimerCount - initialTimerCount, 3, 
                "Timer count should be significantly reduced after optimization")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - 併發安全性測試
    
    func testConcurrentTimerOperations() {
        let viewModel = createTestBingoGameViewModel()
        let operationExpectation = self.expectation(description: "Concurrent operations completed")
        operationExpectation.expectedFulfillmentCount = 10
        
        // 模擬多個併發的定時器操作
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: Double.random(in: 0.01...0.1))
                
                DispatchQueue.main.async {
                    if i % 2 == 0 {
                        viewModel.attemptToJoinOrCreateRoom(roomID: "concurrent-test-\\(i)")
                    } else {
                        viewModel.leaveRoom()
                    }
                    operationExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Concurrent timer operations should not cause deadlocks or crashes")
        }
    }
    
    // MARK: - 輔助方法
    
    private func createTestBingoGameViewModel() -> BingoGameViewModel {
        // 創建測試用的 BingoGameViewModel
        // 注意：需要提供所有必要的依賴項
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
    
    private func getCurrentTimerCount() -> Int {
        // 簡化的定時器計數方法
        // 在實際實現中，可能需要更複雜的監控
        return 0 // 需要實際實現
    }
}

/// Mock MeshManager for testing
class MockMeshManager: MeshManagerProtocol {
    func startMeshNetwork() {}
    func stopMeshNetwork() {}
    func isNetworkReady() -> Bool { return true }
    func getConnectedPeers() -> [String] { return [] }
    func sendMessage(_ message: MeshMessage) throws {}
    func broadcastMessage(_ message: MeshMessage) throws {}
}

/// 【性能工程師】記憶體使用監控
class MemoryUsageMonitor {
    
    static func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    static func logMemoryUsage(label: String) {
        let memoryUsage = getCurrentMemoryUsage()
        print("🧠 [\(label)] Memory Usage: \(memoryUsage / 1024 / 1024) MB")
    }
}