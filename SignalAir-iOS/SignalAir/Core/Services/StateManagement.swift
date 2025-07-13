import Foundation
import SwiftUI
import Combine

// MARK: - 🎯 SOLID 原則狀態管理架構

/// 單一職責原則 (SRP)：遊戲狀態管理協議
/// 只負責管理遊戲狀態，不處理網路或 UI
protocol GameStateManaging: AnyObject {
    // 狀態屬性
    var bingoCard: [[Int]] { get set }
    var drawnNumbers: [Int] { get set }
    var completedLines: Int { get set }
    var isHosting: Bool { get set }
    var gamePhase: GamePhase { get set }
    
    // 狀態查詢
    func isBingo() -> Bool
    func isNumberDrawn(_ number: Int) -> Bool
    func checkCompletedLines() -> Int
    
    // 狀態轉換
    func markNumber(_ number: Int)
    func resetGame()
    func generateNewCard()
}

/// 單一職責原則 (SRP)：網路協調器協議
/// 只負責網路通信，不處理遊戲邏輯
protocol NetworkCoordinating: AnyObject {
    // 網路狀態
    var isConnected: Bool { get }
    var connectedPeers: [String] { get }
    
    // 訊息發送
    func sendToAll<T: Codable>(_ message: T, type: MeshMessageType)
    func sendToPeer<T: Codable>(_ message: T, peer: String, type: MeshMessageType)
    
    // 連接管理
    func startHostMode() async throws
    func joinGame() async throws
    func leaveGame()
}

/// 單一職責原則 (SRP)：聊天管理協議
/// 只負責聊天功能，不處理遊戲狀態
protocol ChatManaging: AnyObject {
    var messages: [ChatMessage] { get }
    func sendMessage(_ content: String)
    func sendEmote(_ emote: EmoteType)
    func clearMessages()
}

/// 介面隔離原則 (ISP)：統一狀態容器協議
/// 提供各個子系統的統一訪問點
protocol GameStateContainer: AnyObject {
    var gameState: GameStateManaging { get }
    var networkCoordinator: NetworkCoordinating { get }
    var chatManager: ChatManaging { get }
}

// MARK: - 🏗️ 實際實現

/// 依賴反轉原則 (DIP)：狀態管理器工廠
/// 高層模組依賴抽象，不依賴具體實現
protocol StateManagerFactory {
    func createGameStateManager() -> GameStateManaging
    func createNetworkCoordinator(meshManager: MeshManagerProtocol) -> NetworkCoordinating
    func createChatManager(networkCoordinator: NetworkCoordinating) -> ChatManaging
}

/// 開放封閉原則 (OCP)：狀態事件通知系統
/// 對擴展開放，對修改封閉
protocol StateEventPublisher {
    func publish<T>(_ event: T) where T: StateEvent
    func subscribe<T>(_ eventType: T.Type, handler: @escaping (T) -> Void) where T: StateEvent
}

/// 狀態事件基礎協議
protocol StateEvent {
    var timestamp: Date { get }
    var eventId: UUID { get }
}

// MARK: - 具體事件類型

struct GameStateChangedEvent: StateEvent {
    let timestamp = Date()
    let eventId = UUID()
    let previousPhase: GamePhase
    let newPhase: GamePhase
}

struct NumberDrawnEvent: StateEvent {
    let timestamp = Date()
    let eventId = UUID()
    let number: Int
    let drawnBy: String
}

struct BingoAchievedEvent: StateEvent {
    let timestamp = Date()
    let eventId = UUID()
    let player: String
    let completedLines: Int
}

// MARK: - 線程安全狀態管理器

/// 線程安全的狀態管理基類
@MainActor
class ThreadSafeStateManager: ObservableObject {
    private let stateQueue = DispatchQueue(label: "com.signalair.state", qos: .userInitiated)
    
    func updateState<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, value: T) {
        Task { @MainActor in
            self[keyPath: keyPath] = value
        }
    }
    
    func readState<T>(_ keyPath: KeyPath<Self, T>) -> T {
        return self[keyPath: keyPath]
    }
}

// MARK: - 📊 狀態監控和診斷

/// 狀態變化追踪器
class StateChangeTracker {
    private var changes: [(timestamp: Date, description: String)] = []
    private let maxChanges = 1000
    
    func recordChange(_ description: String) {
        changes.append((Date(), description))
        if changes.count > maxChanges {
            changes.removeFirst()
        }
    }
    
    func getRecentChanges(limit: Int = 10) -> [(timestamp: Date, description: String)] {
        return Array(changes.suffix(limit))
    }
    
    func exportChanges() -> String {
        return changes.map { "[\($0.timestamp)] \($0.description)" }.joined(separator: "\n")
    }
}

// MARK: - 🔧 SOLID 原則驗證器

/// 用於驗證 SOLID 原則合規性的診斷工具
struct SOLIDComplianceChecker {
    
    /// 檢查單一職責原則：每個類別應該只有一個變更理由
    static func checkSingleResponsibility<T>(of type: T.Type) -> Bool {
        let mirror = Mirror(reflecting: type)
        let methodCount = mirror.children.count
        
        // 簡單的方法數量檢查（實際項目中需要更精密的分析）
        return methodCount < 15 // 經驗值：超過 15 個方法可能承擔過多職責
    }
    
    /// 檢查依賴反轉：是否依賴抽象而非具體實現
    static func checkDependencyInversion<T>(dependencies: [T]) -> Bool {
        // 檢查依賴是否都是協議類型
        return dependencies.allSatisfy { dep in
            String(describing: type(of: dep)).contains("Protocol")
        }
    }
}