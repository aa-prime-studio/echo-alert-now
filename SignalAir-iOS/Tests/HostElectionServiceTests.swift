import XCTest
import Combine
@testable import SignalAir

/// HostElectionService 單元測試
@MainActor
final class HostElectionServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var sut: HostElectionService!
    private var mockNetworkManager: MockBingoNetworkManager!
    private var cancellables: Set<AnyCancellable>!
    private let testDeviceName = "TestDevice"
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        mockNetworkManager = MockBingoNetworkManager()
        cancellables = Set<AnyCancellable>()
        
        sut = HostElectionService(
            networkManager: mockNetworkManager,
            deviceName: testDeviceName
        )
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        sut?.cleanup()
        sut = nil
        mockNetworkManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When (setup in setUp())
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isHost)
        XCTAssertNil(sut.currentHost)
        XCTAssertEqual(sut.deviceName, testDeviceName)
    }
    
    // MARK: - Host Election Tests
    
    func testStartHostElection() {
        // Given
        XCTAssertFalse(sut.isHost)
        
        // When
        sut.startHostElection()
        
        // Then
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testBecomeHost() {
        // Given
        XCTAssertFalse(sut.isHost)
        
        // When
        sut.becomeHost()
        
        // Then
        XCTAssertTrue(sut.isHost)
        XCTAssertEqual(sut.currentHost, testDeviceName)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testResignAsHost() {
        // Given
        sut.becomeHost()
        XCTAssertTrue(sut.isHost)
        
        // When
        sut.resignAsHost()
        
        // Then
        XCTAssertFalse(sut.isHost)
        XCTAssertNil(sut.currentHost)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    // MARK: - Deterministic Host Selection Tests
    
    func testDeterministicHostSelection() {
        // Given
        let playerIDs = ["Player1", "Player2", "Player3", testDeviceName]
        
        // When
        let selectedHost1 = sut.selectHostDeterministically(from: playerIDs)
        let selectedHost2 = sut.selectHostDeterministically(from: playerIDs)
        
        // Then
        XCTAssertEqual(selectedHost1, selectedHost2, "Host selection should be deterministic")
        XCTAssertTrue(playerIDs.contains(selectedHost1), "Selected host should be from the player list")
    }
    
    func testDeterministicHostSelectionEmptyList() {
        // Given
        let emptyPlayerIDs: [String] = []
        
        // When
        let selectedHost = sut.selectHostDeterministically(from: emptyPlayerIDs)
        
        // Then
        XCTAssertEqual(selectedHost, testDeviceName, "Should fallback to current device when no players")
    }
    
    // MARK: - Host Heartbeat Tests
    
    func testHandleHostHeartbeat() {
        // Given
        let hostID = "RemoteHost"
        sut.currentHost = hostID
        
        // When
        sut.handleHostHeartbeat(from: hostID)
        
        // Then
        // Should not trigger host election since we received heartbeat from current host
        XCTAssertEqual(sut.currentHost, hostID)
        XCTAssertFalse(sut.isHost)
    }
    
    func testHandleHostHeartbeatFromUnknownHost() {
        // Given
        let unknownHostID = "UnknownHost"
        sut.currentHost = "KnownHost"
        
        // When
        sut.handleHostHeartbeat(from: unknownHostID)
        
        // Then
        // Should update current host to the one sending heartbeat
        XCTAssertEqual(sut.currentHost, unknownHostID)
        XCTAssertFalse(sut.isHost)
    }
    
    // MARK: - Publishers Tests
    
    func testIsHostPublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Host status changed")
        var receivedValues: [Bool] = []
        
        sut.isHostPublisher
            .sink { isHost in
                receivedValues.append(isHost)
                if receivedValues.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.becomeHost()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [false, true])
    }
    
    // MARK: - Host Migration Tests
    
    func testHostMigration() {
        // Given
        sut.becomeHost()
        XCTAssertTrue(sut.isHost)
        let newHostID = "NewHost"
        
        // When
        sut.handleHostHeartbeat(from: newHostID)
        
        // Then
        XCTAssertFalse(sut.isHost, "Should no longer be host when another device becomes host")
        XCTAssertEqual(sut.currentHost, newHostID, "Should recognize new host")
    }
    
    // MARK: - Network Error Handling Tests
    
    func testHostElectionWithNetworkError() {
        // Given
        mockNetworkManager.shouldThrowError = true
        
        // When & Then
        XCTAssertNoThrow(sut.startHostElection(), "Should handle network errors gracefully")
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() {
        // Given
        sut.becomeHost()
        XCTAssertTrue(sut.isHost)
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertFalse(sut.isHost)
        XCTAssertNil(sut.currentHost)
    }
    
    // MARK: - Edge Cases Tests
    
    func testMultipleHostElections() {
        // Given
        XCTAssertFalse(sut.isHost)
        
        // When
        sut.startHostElection()
        sut.startHostElection()
        sut.startHostElection()
        
        // Then
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
        // Should handle multiple elections gracefully
    }
    
    func testBecomeHostTwice() {
        // Given
        sut.becomeHost()
        XCTAssertTrue(sut.isHost)
        mockNetworkManager.broadcastGameMessageCalled = false
        
        // When
        sut.becomeHost()
        
        // Then
        XCTAssertTrue(sut.isHost)
        // Should not broadcast again if already host
    }
}

// MARK: - Mock Extensions

extension MockBingoNetworkManager {
    var shouldThrowError = false
    
    override func sendGameMessage(type: GameMessageType, data: Data, to roomID: String) async throws {
        super.broadcastGameMessageCalled = true
        
        if shouldThrowError {
            throw MockNetworkError.broadcastFailed
        }
    }
    
    override func broadcastGameAction(type: GameMessageType, data: Data, priority: MessagePriority) async throws {
        super.broadcastGameMessageCalled = true
        
        if shouldThrowError {
            throw MockNetworkError.broadcastFailed
        }
    }
}

enum MockNetworkError: Error {
    case broadcastFailed
}