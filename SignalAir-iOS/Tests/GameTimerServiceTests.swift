import XCTest
import Combine
@testable import SignalAir

/// GameTimerService 單元測試
@MainActor
final class GameTimerServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var sut: GameTimerService!
    private var mockTimerManager: MockUnifiedTimerManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        mockTimerManager = MockUnifiedTimerManager()
        cancellables = Set<AnyCancellable>()
        
        sut = GameTimerService(timerManager: mockTimerManager)
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        sut?.cleanup()
        sut = nil
        mockTimerManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When (setup in setUp())
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.currentCountdown, 0)
        XCTAssertFalse(sut.isGameCountdownActive)
        XCTAssertFalse(sut.isDrawTimerActive)
        XCTAssertFalse(sut.isHeartbeatActive)
        XCTAssertFalse(sut.isRestartTimerActive)
    }
    
    // MARK: - Game Countdown Tests
    
    func testStartGameCountdown() {
        // Given
        let duration = 5
        var updateCallbackCalled = false
        var completeCallbackCalled = false
        
        // When
        sut.startGameCountdown(
            duration: duration,
            onUpdate: { countdown in
                updateCallbackCalled = true
                XCTAssertGreaterThanOrEqual(countdown, 0)
                XCTAssertLessThanOrEqual(countdown, duration)
            },
            onComplete: {
                completeCallbackCalled = true
            }
        )
        
        // Then
        XCTAssertTrue(sut.isGameCountdownActive)
        XCTAssertTrue(mockTimerManager.scheduleCalled)
        
        // Simulate timer update
        mockTimerManager.triggerLastCallback()
        XCTAssertTrue(updateCallbackCalled)
    }
    
    func testStopGameCountdown() {
        // Given
        sut.startGameCountdown(duration: 5, onUpdate: { _ in }, onComplete: { })
        XCTAssertTrue(sut.isGameCountdownActive)
        
        // When
        sut.stopGameCountdown()
        
        // Then
        XCTAssertFalse(sut.isGameCountdownActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
    
    // MARK: - Draw Timer Tests
    
    func testStartDrawTimer() {
        // Given
        let interval: TimeInterval = 2.0
        var callbackCalled = false
        
        // When
        sut.startDrawTimer(interval: interval) {
            callbackCalled = true
        }
        
        // Then
        XCTAssertTrue(sut.isDrawTimerActive)
        XCTAssertTrue(mockTimerManager.scheduleCalled)
        
        // Simulate timer callback
        mockTimerManager.triggerLastCallback()
        XCTAssertTrue(callbackCalled)
    }
    
    func testStopDrawTimer() {
        // Given
        sut.startDrawTimer(interval: 1.0) { }
        XCTAssertTrue(sut.isDrawTimerActive)
        
        // When
        sut.stopDrawTimer()
        
        // Then
        XCTAssertFalse(sut.isDrawTimerActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
    
    // MARK: - Heartbeat Timer Tests
    
    func testStartHeartbeat() {
        // Given
        var callbackCalled = false
        
        // When
        sut.startHeartbeat {
            callbackCalled = true
        }
        
        // Then
        XCTAssertTrue(sut.isHeartbeatActive)
        XCTAssertTrue(mockTimerManager.scheduleCalled)
        
        // Simulate heartbeat
        mockTimerManager.triggerLastCallback()
        XCTAssertTrue(callbackCalled)
    }
    
    func testStopHeartbeat() {
        // Given
        sut.startHeartbeat { }
        XCTAssertTrue(sut.isHeartbeatActive)
        
        // When
        sut.stopHeartbeat()
        
        // Then
        XCTAssertFalse(sut.isHeartbeatActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
    
    // MARK: - Restart Timer Tests
    
    func testStartRestartTimer() {
        // Given
        let delay: TimeInterval = 3.0
        var callbackCalled = false
        
        // When
        sut.startRestartTimer(delay: delay) {
            callbackCalled = true
        }
        
        // Then
        XCTAssertTrue(sut.isRestartTimerActive)
        XCTAssertTrue(mockTimerManager.scheduleCalled)
        
        // Simulate restart timer callback
        mockTimerManager.triggerLastCallback()
        XCTAssertTrue(callbackCalled)
    }
    
    func testStopRestartTimer() {
        // Given
        sut.startRestartTimer(delay: 1.0) { }
        XCTAssertTrue(sut.isRestartTimerActive)
        
        // When
        sut.stopRestartTimer()
        
        // Then
        XCTAssertFalse(sut.isRestartTimerActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
    
    // MARK: - Stop All Timers Tests
    
    func testStopAllTimers() {
        // Given
        sut.startGameCountdown(duration: 5, onUpdate: { _ in }, onComplete: { })
        sut.startDrawTimer(interval: 1.0) { }
        sut.startHeartbeat { }
        sut.startRestartTimer(delay: 2.0) { }
        
        XCTAssertTrue(sut.isGameCountdownActive)
        XCTAssertTrue(sut.isDrawTimerActive)
        XCTAssertTrue(sut.isHeartbeatActive)
        XCTAssertTrue(sut.isRestartTimerActive)
        
        // When
        sut.stopAllTimers()
        
        // Then
        XCTAssertFalse(sut.isGameCountdownActive)
        XCTAssertFalse(sut.isDrawTimerActive)
        XCTAssertFalse(sut.isHeartbeatActive)
        XCTAssertFalse(sut.isRestartTimerActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
    
    // MARK: - Publishers Tests
    
    func testCountdownPublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Countdown publisher")
        var receivedValues: [Int] = []
        
        sut.countdownPublisher
            .sink { countdown in
                receivedValues.append(countdown)
                if receivedValues.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.startGameCountdown(duration: 3, onUpdate: { _ in }, onComplete: { })
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedValues.contains(0)) // Initial value
    }
    
    func testHeartbeatPublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Heartbeat publisher")
        
        sut.heartbeatPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.startHeartbeat { }
        mockTimerManager.triggerLastCallback()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Timer Status Tests
    
    func testGetTimerStatus() {
        // Given
        sut.startGameCountdown(duration: 5, onUpdate: { _ in }, onComplete: { })
        sut.startHeartbeat { }
        
        // When
        let status = sut.getTimerStatus()
        
        // Then
        XCTAssertTrue(status.contains("遊戲倒數"))
        XCTAssertTrue(status.contains("心跳"))
    }
    
    func testGetTimerStatusNoActiveTimers() {
        // Given (no active timers)
        
        // When
        let status = sut.getTimerStatus()
        
        // Then
        XCTAssertEqual(status, "無活躍計時器")
    }
    
    // MARK: - Edge Cases Tests
    
    func testStartSameTimerTwice() {
        // Given
        sut.startHeartbeat { }
        XCTAssertTrue(sut.isHeartbeatActive)
        mockTimerManager.scheduleCalled = false
        
        // When
        sut.startHeartbeat { }
        
        // Then
        XCTAssertTrue(sut.isHeartbeatActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled) // Should stop previous timer
        XCTAssertTrue(mockTimerManager.scheduleCalled) // Should start new timer
    }
    
    func testStopNonActiveTimer() {
        // Given (no active heartbeat)
        XCTAssertFalse(sut.isHeartbeatActive)
        
        // When & Then
        XCTAssertNoThrow(sut.stopHeartbeat())
        XCTAssertFalse(sut.isHeartbeatActive)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() {
        // Given
        sut.startGameCountdown(duration: 5, onUpdate: { _ in }, onComplete: { })
        sut.startHeartbeat { }
        XCTAssertTrue(sut.isGameCountdownActive)
        XCTAssertTrue(sut.isHeartbeatActive)
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertFalse(sut.isGameCountdownActive)
        XCTAssertFalse(sut.isHeartbeatActive)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
}

// MARK: - Mock Extensions

extension MockUnifiedTimerManager {
    var scheduleCalled = false
    private var lastCallback: (() -> Void)?
    
    override func schedule(id: String, configuration: TimerConfiguration, action: @escaping () -> Void) {
        scheduleCalled = true
        lastCallback = action
        super.schedule(id: id, configuration: configuration, action: action)
    }
    
    func triggerLastCallback() {
        lastCallback?()
    }
}