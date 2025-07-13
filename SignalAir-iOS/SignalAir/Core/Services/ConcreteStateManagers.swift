import Foundation
import SwiftUI
import Combine

// MARK: - 🎮 具體的遊戲狀態管理器

/// 單一職責：只管理遊戲狀態
@MainActor
class ConcreteGameStateManager: ThreadSafeStateManager, GameStateManaging {
    
    // MARK: - 狀態屬性
    @Published var bingoCard: [[Int]] = []
    @Published var drawnNumbers: [Int] = []
    @Published var completedLines: Int = 0
    @Published var isHosting: Bool = false
    @Published var gamePhase: GameState = .waitingForPlayers
    
    private let stateTracker = StateChangeTracker()
    
    // MARK: - 初始化
    override init() {
        super.init()
        generateNewCard()
        stateTracker.recordChange("GameStateManager initialized")
    }
    
    // MARK: - 狀態查詢方法
    func isBingo() -> Bool {
        stateTracker.recordChange("Checked bingo status")
        return completedLines >= 5 // 完成 5 條線算 Bingo
    }
    
    func isNumberDrawn(_ number: Int) -> Bool {
        return drawnNumbers.contains(number)
    }
    
    func checkCompletedLines() -> Int {
        let lines = countCompletedLines()
        if lines != completedLines {
            completedLines = lines
            stateTracker.recordChange("Completed lines updated to \(lines)")
        }
        return lines
    }
    
    // MARK: - 狀態轉換方法
    func markNumber(_ number: Int) {
        guard !drawnNumbers.contains(number) else { return }
        
        drawnNumbers.append(number)
        checkCompletedLines()
        stateTracker.recordChange("Number \(number) marked")
    }
    
    func resetGame() {
        drawnNumbers.removeAll()
        completedLines = 0
        gamePhase = .waitingForPlayers
        generateNewCard()
        stateTracker.recordChange("Game reset")
    }
    
    func generateNewCard() {
        // 生成 5x5 賓果卡
        var newCard: [[Int]] = []
        var usedNumbers: Set<Int> = []
        
        for row in 0..<5 {
            var cardRow: [Int] = []
            for col in 0..<5 {
                if row == 2 && col == 2 {
                    // 中央是 FREE 空間
                    cardRow.append(0)
                } else {
                    // 每欄有特定的數字範圍：B(1-20), I(21-40), N(41-60), G(61-80), O(81-99)
                    let min = col * 20 + 1
                    let max = col == 4 ? 99 : (col + 1) * 20  // O列限制為99
                    
                    var number: Int
                    repeat {
                        number = Int.random(in: min...max)
                    } while usedNumbers.contains(number)
                    
                    usedNumbers.insert(number)
                    cardRow.append(number)
                }
            }
            newCard.append(cardRow)
        }
        
        bingoCard = newCard
        stateTracker.recordChange("New bingo card generated")
    }
    
    // MARK: - 私有輔助方法
    private func countCompletedLines() -> Int {
        var lines = 0
        
        // 檢查橫線
        for row in bingoCard {
            if row.allSatisfy({ $0 == 0 || drawnNumbers.contains($0) }) {
                lines += 1
            }
        }
        
        // 檢查直線
        for col in 0..<5 {
            let column = bingoCard.map { $0[col] }
            if column.allSatisfy({ $0 == 0 || drawnNumbers.contains($0) }) {
                lines += 1
            }
        }
        
        // 檢查對角線
        let diagonal1 = (0..<5).map { bingoCard[$0][$0] }
        if diagonal1.allSatisfy({ $0 == 0 || drawnNumbers.contains($0) }) {
            lines += 1
        }
        
        let diagonal2 = (0..<5).map { bingoCard[$0][4-$0] }
        if diagonal2.allSatisfy({ $0 == 0 || drawnNumbers.contains($0) }) {
            lines += 1
        }
        
        return lines
    }
}

// MARK: - 🌐 網路協調器實現

/// 單一職責：只處理網路通信
@MainActor
class ConcreteNetworkCoordinator: ObservableObject, NetworkCoordinating {
    
    // MARK: - 依賴注入（依賴反轉原則）
    private let meshManager: MeshManagerProtocol
    private let stateTracker = StateChangeTracker()
    
    // MARK: - 網路狀態
    @Published var isConnected: Bool = false
    @Published var connectedPeers: [String] = []
    
    // MARK: - 初始化
    init(meshManager: MeshManagerProtocol) {
        self.meshManager = meshManager
        setupNetworkCallbacks()
        stateTracker.recordChange("NetworkCoordinator initialized")
    }
    
    // MARK: - 網路狀態屬性
    var isNetworkReady: Bool {
        return meshManager.isNetworkReady()
    }
    
    // MARK: - 訊息發送方法
    func sendToAll<T: Codable>(_ message: T, type: MeshMessageType) {
        do {
            let data = try JSONEncoder().encode(message)
            meshManager.broadcastMessage(data, messageType: type)
            stateTracker.recordChange("Broadcast message of type \(type)")
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    func sendToPeer<T: Codable>(_ message: T, peer: String, type: MeshMessageType) {
        do {
            let data = try JSONEncoder().encode(message)
            meshManager.send(data, to: peer, messageType: type)
            stateTracker.recordChange("Sent message to peer \(peer)")
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    // MARK: - 連接管理方法
    func startHostMode() async throws {
        await meshManager.startHostMode()
        stateTracker.recordChange("Started host mode")
    }
    
    func joinGame() async throws {
        try await meshManager.startNetworking()
        stateTracker.recordChange("Joined game")
    }
    
    func leaveGame() {
        Task {
            await meshManager.stopNetworking()
            stateTracker.recordChange("Left game")
        }
    }
    
    // MARK: - 私有方法
    private func setupNetworkCallbacks() {
        meshManager.onPeerConnected = { [weak self] peer in
            Task { @MainActor in
                self?.connectedPeers.append(peer)
                self?.isConnected = !self?.connectedPeers.isEmpty ?? false
                self?.stateTracker.recordChange("Peer connected: \(peer)")
            }
        }
        
        meshManager.onPeerDisconnected = { [weak self] peer in
            Task { @MainActor in
                self?.connectedPeers.removeAll { $0 == peer }
                self?.isConnected = !self?.connectedPeers.isEmpty ?? false
                self?.stateTracker.recordChange("Peer disconnected: \(peer)")
            }
        }
    }
}

// MARK: - 💬 聊天管理器實現

/// 單一職責：只處理聊天功能
@MainActor
class ConcreteChatManager: ThreadSafeStateManager, ChatManaging {
    
    // MARK: - 依賴注入
    private let networkCoordinator: NetworkCoordinating
    private let stateTracker = StateChangeTracker()
    
    // MARK: - 聊天狀態
    @Published var messages: [ChatMessage] = []
    
    // MARK: - 初始化
    init(networkCoordinator: NetworkCoordinating) {
        self.networkCoordinator = networkCoordinator
        super.init()
        stateTracker.recordChange("ChatManager initialized")
    }
    
    // MARK: - 聊天方法
    func sendMessage(_ content: String) {
        let message = ChatMessage(
            id: UUID(),
            content: content,
            senderName: "本地用戶", // 實際應該從用戶設定取得
            timestamp: Date(),
            isEmote: false
        )
        
        // 添加到本地
        messages.append(message)
        
        // 廣播給其他玩家
        networkCoordinator.sendToAll(message, type: .chat)
        stateTracker.recordChange("Sent text message: \(content.prefix(20))...")
    }
    
    func sendEmote(_ emote: EmoteType) {
        let message = ChatMessage(
            id: UUID(),
            content: emote.template,
            senderName: "本地用戶",
            timestamp: Date(),
            isEmote: true
        )
        
        // 添加到本地
        messages.append(message)
        
        // 廣播給其他玩家
        networkCoordinator.sendToAll(message, type: .emote)
        stateTracker.recordChange("Sent emote: \(emote.rawValue)")
    }
    
    func clearMessages() {
        messages.removeAll()
        stateTracker.recordChange("Cleared all messages")
    }
    
    // MARK: - 接收訊息處理
    func handleReceivedMessage(_ message: ChatMessage) {
        messages.append(message)
        stateTracker.recordChange("Received message from \(message.senderName)")
    }
}

// MARK: - 🏗️ 統一狀態容器實現

/// 介面隔離原則：提供各子系統的統一訪問
@MainActor
class UnifiedGameStateContainer: ObservableObject, GameStateContainer {
    
    // MARK: - 子系統
    let gameState: GameStateManaging
    let networkCoordinator: NetworkCoordinating
    let chatManager: ChatManaging
    
    private let stateTracker = StateChangeTracker()
    
    // MARK: - 初始化
    init(
        gameState: GameStateManaging,
        networkCoordinator: NetworkCoordinating,
        chatManager: ChatManaging
    ) {
        self.gameState = gameState
        self.networkCoordinator = networkCoordinator
        self.chatManager = chatManager
        stateTracker.recordChange("UnifiedGameStateContainer initialized")
    }
    
    // MARK: - 診斷方法
    func getDiagnosticsReport() -> String {
        return """
        === 遊戲狀態容器診斷報告 ===
        初始化時間: \(Date())
        
        遊戲狀態:
        - 階段: \(gameState.gamePhase)
        - 已抽數字: \(gameState.drawnNumbers.count)
        - 完成線數: \(gameState.completedLines)
        - 是否主持: \(gameState.isHosting)
        
        網路狀態:
        - 已連接: \(networkCoordinator.isConnected)
        - 連接節點: \(networkCoordinator.connectedPeers.count)
        
        聊天狀態:
        - 訊息數量: \(chatManager.messages.count)
        
        狀態變更歷史:
        \(stateTracker.exportChanges())
        """
    }
}

// MARK: - 🏭 SOLID 原則工廠實現

/// 開放封閉原則：對擴展開放，對修改封閉
class SOLIDStateManagerFactory: StateManagerFactory {
    
    func createGameStateManager() -> GameStateManaging {
        return ConcreteGameStateManager()
    }
    
    func createNetworkCoordinator(meshManager: MeshManagerProtocol) -> NetworkCoordinating {
        return ConcreteNetworkCoordinator(meshManager: meshManager)
    }
    
    func createChatManager(networkCoordinator: NetworkCoordinating) -> ChatManaging {
        return ConcreteChatManager(networkCoordinator: networkCoordinator)
    }
    
    /// 完整的狀態容器創建
    func createCompleteStateContainer(meshManager: MeshManagerProtocol) -> GameStateContainer {
        let gameState = createGameStateManager()
        let networkCoordinator = createNetworkCoordinator(meshManager: meshManager)
        let chatManager = createChatManager(networkCoordinator: networkCoordinator)
        
        return UnifiedGameStateContainer(
            gameState: gameState,
            networkCoordinator: networkCoordinator,
            chatManager: chatManager
        )
    }
}