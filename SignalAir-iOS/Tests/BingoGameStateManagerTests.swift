import XCTest
import Combine
@testable import SignalAir

/// BingoGameStateManager 單元測試
@MainActor
final class BingoGameStateManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var sut: BingoGameStateManager!
    private var mockTimerManager: MockUnifiedTimerManager!
    private var mockNetworkManager: MockBingoNetworkManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        mockTimerManager = MockUnifiedTimerManager()
        mockNetworkManager = MockBingoNetworkManager()
        cancellables = Set<AnyCancellable>()
        
        sut = BingoGameStateManager(
            timerManager: mockTimerManager,
            networkManager: mockNetworkManager
        )
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        sut?.cleanup()
        sut = nil
        mockTimerManager = nil
        mockNetworkManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When (setup in setUp())
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.gameState, .waitingForPlayers)
        XCTAssertNil(sut.bingoCard)
        XCTAssertTrue(sut.drawnNumbers.isEmpty)
        XCTAssertEqual(sut.completedLines, 0)
        XCTAssertFalse(sut.gameWon)
        XCTAssertNil(sut.currentNumber)
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
    
    // MARK: - Game Lifecycle Tests
    
    func testStartGame() {
        // Given
        XCTAssertEqual(sut.gameState, .waitingForPlayers)
        
        // When
        sut.startGame()
        
        // Then
        XCTAssertEqual(sut.gameState, .playing)
        XCTAssertEqual(sut.countdown, 3)
        XCTAssertFalse(sut.gameWon)
        XCTAssertTrue(sut.drawnNumbers.isEmpty)
        XCTAssertNil(sut.currentNumber)
        XCTAssertNotNil(sut.bingoCard)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testEndGame() {
        // Given
        sut.startGame()
        XCTAssertEqual(sut.gameState, .playing)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertEqual(sut.gameState, .finished)
        XCTAssertTrue(mockTimerManager.invalidateCalled)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testRestartGame() {
        // Given
        sut.startGame()
        sut.endGame()
        XCTAssertEqual(sut.gameState, .finished)
        
        // When
        sut.restartGame()
        
        // Then
        XCTAssertTrue(mockTimerManager.scheduleCalled)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testResetGameState() {
        // Given
        sut.startGame()
        XCTAssertEqual(sut.gameState, .playing)
        XCTAssertNotNil(sut.bingoCard)
        
        // When
        sut.resetGameState()
        
        // Then
        XCTAssertEqual(sut.gameState, .waitingForPlayers)
        XCTAssertFalse(sut.gameWon)
        XCTAssertNil(sut.bingoCard)
        XCTAssertTrue(sut.drawnNumbers.isEmpty)
        XCTAssertEqual(sut.completedLines, 0)
        XCTAssertEqual(sut.countdown, 0)
        XCTAssertNil(sut.currentNumber)
    }
    
    // MARK: - Bingo Card Tests
    
    func testGenerateBingoCard() {
        // Given
        XCTAssertNil(sut.bingoCard)
        
        // When
        sut.generateBingoCard()
        
        // Then
        XCTAssertNotNil(sut.bingoCard)
        let card = sut.bingoCard!
        XCTAssertEqual(card.numbers.count, 25) // 5x5 grid
        XCTAssertTrue(card.marked[12]) // Center should be marked (FREE space)
        XCTAssertTrue(card.drawn[12]) // Center should be drawn (FREE space)
    }
    
    // MARK: - Number Drawing Tests
    
    func testManualDrawNumber() {
        // Given
        sut.startGame()
        let initialDrawnCount = sut.drawnNumbers.count
        
        // When
        sut.manualDrawNumber()
        
        // Then
        XCTAssertEqual(sut.drawnNumbers.count, initialDrawnCount + 1)
        XCTAssertNotNil(sut.currentNumber)
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testManualDrawNumberWhenNotPlaying() {
        // Given
        XCTAssertEqual(sut.gameState, .waitingForPlayers)
        let initialDrawnCount = sut.drawnNumbers.count
        
        // When
        sut.manualDrawNumber()
        
        // Then
        XCTAssertEqual(sut.drawnNumbers.count, initialDrawnCount)
        XCTAssertNil(sut.currentNumber)
    }
    
    // MARK: - Number Marking Tests
    
    func testMarkNumber() {
        // Given
        sut.generateBingoCard()
        let testNumber = sut.bingoCard!.numbers.first { $0 != 0 }!
        sut.handleNumberDrawn(testNumber)
        
        // When
        sut.markNumber(testNumber)
        
        // Then
        let card = sut.bingoCard!
        let index = card.numbers.firstIndex(of: testNumber)!
        XCTAssertTrue(card.marked[index])
        XCTAssertTrue(mockNetworkManager.broadcastGameMessageCalled)
    }
    
    func testMarkNumberNotDrawn() {
        // Given
        sut.generateBingoCard()
        let testNumber = 99 // Unlikely to be drawn
        
        // When
        sut.markNumber(testNumber)
        
        // Then
        let card = sut.bingoCard!
        if let index = card.numbers.firstIndex(of: testNumber) {
            XCTAssertFalse(card.marked[index])
        }
    }
    
    // MARK: - Message Handling Tests
    
    func testHandleNumberDrawn() {
        // Given
        sut.generateBingoCard()
        let testNumber = 42
        
        // When
        sut.handleNumberDrawn(testNumber)
        
        // Then
        XCTAssertEqual(sut.currentNumber, testNumber)
        XCTAssertTrue(sut.drawnNumbers.contains(testNumber))
        
        let card = sut.bingoCard!
        if let index = card.numbers.firstIndex(of: testNumber) {
            XCTAssertTrue(card.drawn[index])
        }
    }
    
    func testHandleGameStart() {
        // Given
        XCTAssertEqual(sut.gameState, .waitingForPlayers)
        
        // When
        sut.handleGameStart()
        
        // Then
        XCTAssertEqual(sut.gameState, .playing)
        XCTAssertNotNil(sut.bingoCard)
    }
    
    func testHandleGameEnd() {
        // Given
        sut.startGame()
        XCTAssertEqual(sut.gameState, .playing)
        
        // When
        sut.handleGameEnd()
        
        // Then
        XCTAssertEqual(sut.gameState, .finished)
    }
    
    // MARK: - Publishers Tests
    
    func testGameStatePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Game state change")
        var receivedStates: [GameRoomState.GameState] = []
        
        sut.gameStatePublisher
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.startGame()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.waitingForPlayers))
        XCTAssertTrue(receivedStates.contains(.playing))
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() {
        // Given
        sut.startGame()
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertTrue(mockTimerManager.invalidateCalled)
    }
}

// MARK: - Mock Objects

class MockBingoNetworkManager: BingoNetworkManagerProtocol {
    var broadcastGameMessageCalled = false
    var isConnected: Bool = false
    var connectedPeers: [String] = []
    
    private let receivedGameMessagesSubject = PassthroughSubject<GameMessage, Never>()
    private let networkConnectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    
    var receivedGameMessages: AnyPublisher<GameMessage, Never> {
        receivedGameMessagesSubject.eraseToAnyPublisher()
    }
    
    var networkConnectionState: AnyPublisher<Bool, Never> {
        networkConnectionStateSubject.eraseToAnyPublisher()
    }
    
    func sendGameMessage(type: GameMessageType, data: Data, to roomID: String) async throws {
        broadcastGameMessageCalled = true
    }
    
    func broadcastGameAction(type: GameMessageType, data: Data, priority: MessagePriority) async throws {
        broadcastGameMessageCalled = true
    }
    
    func broadcastGameMessage(_ type: GameMessageType, data: Data, gameRoomID: String = "", deviceName: String = "") {
        broadcastGameMessageCalled = true
    }
    
    func startMessageHandling() { }
    func stopMessageHandling() { }
}