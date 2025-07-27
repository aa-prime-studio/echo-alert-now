import XCTest
import Combine
@testable import SignalAir

/// BingoNetworkManager 單元測試
@MainActor
final class BingoNetworkManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var sut: BingoNetworkManager!
    private var mockMeshManager: MockMeshManager!
    private var mockTimerManager: MockUnifiedTimerManager!
    private var mockSettingsViewModel: MockSettingsViewModel!
    private var mockLanguageService: MockLanguageService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        mockMeshManager = MockMeshManager()
        mockTimerManager = MockUnifiedTimerManager()
        mockSettingsViewModel = MockSettingsViewModel()
        mockLanguageService = MockLanguageService()
        cancellables = Set<AnyCancellable>()
        
        sut = BingoNetworkManager(
            meshManager: mockMeshManager,
            timerManager: mockTimerManager,
            settingsViewModel: mockSettingsViewModel,
            languageService: mockLanguageService
        )
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        sut?.cleanup()
        sut = nil
        mockMeshManager = nil
        mockTimerManager = nil
        mockSettingsViewModel = nil
        mockLanguageService = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When (setup in setUp())
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.connectionStatus, "離線")
        XCTAssertFalse(sut.isNetworkActive)
        XCTAssertFalse(sut.isConnected)
        XCTAssertTrue(sut.connectedPeers.isEmpty)
    }
    
    func testOnAppearTriggersAsyncInitialization() {
        // Given
        let expectation = XCTestExpectation(description: "Async initialization")
        
        // When
        sut.onAppear()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Network Setup Tests
    
    func testSetupMeshNetworking() {
        // Given
        let expectation = XCTestExpectation(description: "Network setup")
        mockMeshManager.shouldSucceedNetworking = true
        
        // When
        sut.setupMeshNetworking()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockMeshManager.startNetworkingCalled)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Message Broadcasting Tests
    
    func testBroadcastGameMessage() {
        // Given
        let messageType = GameMessageType.playerJoined
        let data = "test".data(using: .utf8)!
        let roomID = "test-room"
        let deviceName = "test-device"
        
        // When
        sut.broadcastGameMessage(messageType, data: data, gameRoomID: roomID, deviceName: deviceName)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockMeshManager.broadcastMessageCalled)
        }
    }
    
    // MARK: - Connection State Tests
    
    func testNetworkConnectionStatePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Connection state changed")
        
        // When
        sut.networkConnectionState
            .sink { isConnected in
                if !isConnected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() {
        // Given
        sut.setupMeshNetworking()
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertTrue(mockTimerManager.invalidateCalled)
        XCTAssertTrue(mockMeshManager.stopNetworkingCalled)
    }
}

// MARK: - Mock Objects

class MockMeshManager: MeshManagerProtocol {
    var startNetworkingCalled = false
    var stopNetworkingCalled = false
    var broadcastMessageCalled = false
    var shouldSucceedNetworking = true
    
    func startNetworking() async throws {
        startNetworkingCalled = true
        if !shouldSucceedNetworking {
            throw NetworkError.connectionFailed
        }
    }
    
    func stopNetworking() async {
        stopNetworkingCalled = true
    }
    
    func broadcastMessage(_ data: Data, messageType: MeshMessageType) {
        broadcastMessageCalled = true
    }
    
    func getConnectedPeers() -> [String] { return [] }
    func isNetworkReady() -> Bool { return true }
    func startHostMode() async throws { }
    func broadcastMessage(data: Data, type: String) async throws { }
}

class MockUnifiedTimerManager: UnifiedTimerManager {
    var scheduleHeartbeatCalled = false
    var invalidateCalled = false
    
    override func scheduleHeartbeat(action: @escaping () -> Void) {
        scheduleHeartbeatCalled = true
        super.scheduleHeartbeat(action: action)
    }
    
    override func invalidate(id: String) {
        invalidateCalled = true
        super.invalidate(id: id)
    }
}

class MockSettingsViewModel: SettingsViewModel {
    override init() {
        super.init()
        self.userNickname = "TestUser"
    }
}

class MockLanguageService: LanguageService {
    override func localizedString(forKey key: String) -> String {
        return key
    }
}

enum NetworkError: Error {
    case connectionFailed
}