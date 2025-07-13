# 🏗️ BingoGameViewModel 模塊化架構設計

## 🎯 設計目標
- 創建清晰的模塊邊界和職責劃分
- 設計高效的組件間通信機制
- 建立可擴展和可維護的架構
- 保持高性能和低耦合

## 📐 整體架構設計

### 🏛️ 架構層次圖

```
┌─────────────────────────────────────────────────────────────┐
│                    🎮 BingoGameViewModel                    │
│                      (主協調器)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   UI State  │  │   Events    │  │ Lifecycle   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    🎯 BingoGameCoordinator                  │
│                      (業務邏輯協調)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Game Flow  │  │  State Sync │  │ Error Handle│       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    🔄 EventBus & StateStore                │
│                      (事件總線和狀態管理)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ Event Queue │  │ State Cache │  │ Subscription│       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        🧩 Core Managers                    │
│                        (核心管理器)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   Network   │  │    Game     │  │    Room     │       │
│  │   Manager   │  │   Manager   │  │   Manager   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │    Chat     │  │    Timer    │  │    Emote    │       │
│  │   Manager   │  │   Manager   │  │   Manager   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    🔧 Services & Utils                     │
│                      (服務和工具層)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Mesh       │  │  Security   │  │  Language   │       │
│  │  Manager    │  │   Service   │  │   Service   │       │
│  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## 🧩 模塊詳細設計

### 1. 🎮 BingoGameViewModel (主協調器)
**職責**：UI 狀態管理、用戶交互處理、生命週期管理

```swift
@MainActor
class BingoGameViewModel: ObservableObject {
    // UI State Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentView: BingoViewState = .lobby
    
    // Core Dependencies
    private let coordinator: BingoGameCoordinator
    private let eventBus: EventBus
    private let stateStore: StateStore
    
    // UI Actions
    func createRoom() { coordinator.createRoom() }
    func joinRoom(_ id: String) { coordinator.joinRoom(id) }
    func startGame() { coordinator.startGame() }
    func markNumber(_ number: Int) { coordinator.markNumber(number) }
    func sendChatMessage(_ message: String) { coordinator.sendChatMessage(message) }
    func sendEmote(_ emote: EmoteType) { coordinator.sendEmote(emote) }
    
    // Lifecycle
    func onAppear() { coordinator.initialize() }
    func onDisappear() { coordinator.cleanup() }
}
```

### 2. 🎯 BingoGameCoordinator (業務邏輯協調)
**職責**：業務邏輯協調、狀態同步、錯誤處理

```swift
@MainActor
class BingoGameCoordinator {
    // Core Managers
    private let networkManager: BingoNetworkManager
    private let gameManager: BingoGameManager
    private let roomManager: BingoRoomManager
    private let chatManager: BingoChatManager
    private let timerManager: TimerManager
    private let emoteManager: EmoteManager
    
    // State Management
    private let eventBus: EventBus
    private let stateStore: StateStore
    
    // Business Logic
    func createRoom() async throws { ... }
    func joinRoom(_ id: String) async throws { ... }
    func startGame() async throws { ... }
    func markNumber(_ number: Int) async throws { ... }
    func sendChatMessage(_ message: String) async throws { ... }
    func sendEmote(_ emote: EmoteType) async throws { ... }
    
    // State Synchronization
    func syncGameState() async { ... }
    func syncRoomState() async { ... }
    func syncPlayerState() async { ... }
    
    // Error Handling
    func handleError(_ error: Error) { ... }
    func recoverFromError() async { ... }
}
```

### 3. 🔄 EventBus & StateStore (事件總線和狀態管理)
**職責**：組件間通信、狀態緩存、事件分發

```swift
// Event Bus
@MainActor
class EventBus {
    private var subscriptions: [EventType: [EventHandler]] = [:]
    
    func publish<T: Event>(_ event: T) { ... }
    func subscribe<T: Event>(_ eventType: T.Type, handler: @escaping EventHandler<T>) { ... }
    func unsubscribe(_ subscription: EventSubscription) { ... }
}

// State Store
@MainActor
class StateStore {
    @Published var gameState: GameState = .waitingForPlayers
    @Published var roomState: RoomState = .lobby
    @Published var networkState: NetworkState = .disconnected
    @Published var playersState: [PlayerState] = []
    
    func updateGameState(_ state: GameState) { ... }
    func updateRoomState(_ state: RoomState) { ... }
    func updateNetworkState(_ state: NetworkState) { ... }
    func updatePlayersState(_ players: [PlayerState]) { ... }
}
```

### 4. 🧩 Core Managers (核心管理器)

#### 4.1 🌐 BingoNetworkManager
**職責**：網絡連接管理、消息廣播、連接狀態監控

```swift
class BingoNetworkManager {
    @Published var connectionStatus: NetworkConnectionStatus = .disconnected
    @Published var connectedPeers: [PeerInfo] = []
    @Published var networkQuality: NetworkQuality = .unknown
    
    private let meshManager: MeshManagerProtocol
    private let eventBus: EventBus
    
    // Connection Management
    func startNetworking() async throws { ... }
    func stopNetworking() async { ... }
    func reconnect() async throws { ... }
    
    // Message Broadcasting
    func broadcastMessage<T: Codable>(_ message: T, type: MessageType) async throws { ... }
    func sendDirectMessage<T: Codable>(_ message: T, to peer: PeerInfo) async throws { ... }
    
    // Network Monitoring
    func monitorNetworkHealth() { ... }
    func validateConnection() async -> Bool { ... }
}
```

#### 4.2 🎲 BingoGameManager
**職責**：遊戲邏輯、卡片生成、獲勝檢測

```swift
class BingoGameManager {
    @Published var currentCard: BingoCard?
    @Published var drawnNumbers: Set<Int> = []
    @Published var gamePhase: GamePhase = .waiting
    @Published var winnerInfo: WinnerInfo?
    
    private let eventBus: EventBus
    private let timerManager: TimerManager
    
    // Game Logic
    func generateBingoCard() -> BingoCard { ... }
    func drawNextNumber() async throws -> Int { ... }
    func markNumber(_ number: Int) async throws { ... }
    func checkWinCondition() async -> WinResult { ... }
    
    // Game Flow
    func startGame() async throws { ... }
    func pauseGame() async { ... }
    func endGame() async { ... }
    func resetGame() async { ... }
}
```

#### 4.3 🏠 BingoRoomManager
**職責**：房間管理、玩家狀態、主機選擇

```swift
class BingoRoomManager {
    @Published var currentRoom: RoomInfo?
    @Published var players: [PlayerInfo] = []
    @Published var isHost: Bool = false
    @Published var roomSettings: RoomSettings = .default
    
    private let eventBus: EventBus
    private let networkManager: BingoNetworkManager
    
    // Room Management
    func createRoom(_ settings: RoomSettings) async throws -> RoomInfo { ... }
    func joinRoom(_ roomId: String) async throws { ... }
    func leaveRoom() async { ... }
    func closeRoom() async throws { ... }
    
    // Player Management
    func addPlayer(_ player: PlayerInfo) async { ... }
    func removePlayer(_ playerId: String) async { ... }
    func updatePlayerStatus(_ playerId: String, status: PlayerStatus) async { ... }
    
    // Host Management
    func electNewHost() async throws { ... }
    func transferHost(to playerId: String) async throws { ... }
}
```

#### 4.4 💬 BingoChatManager
**職責**：聊天功能、消息同步、內容過濾

```swift
class BingoChatManager {
    @Published var messages: [ChatMessage] = []
    @Published var unreadCount: Int = 0
    
    private let eventBus: EventBus
    private let networkManager: BingoNetworkManager
    
    // Chat Operations
    func sendMessage(_ content: String) async throws { ... }
    func receiveMessage(_ message: ChatMessage) async { ... }
    func clearMessages() { ... }
    
    // Message Management
    func markAsRead() { ... }
    func deleteMessage(_ messageId: String) async { ... }
    func filterContent(_ content: String) -> String { ... }
}
```

#### 4.5 ⏰ TimerManager
**職責**：定時器管理、任務調度、生命週期控制

```swift
class TimerManager {
    private var timers: [String: Timer] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]
    
    // Timer Operations
    func schedule(id: String, interval: TimeInterval, repeats: Bool, action: @escaping () -> Void) { ... }
    func cancel(id: String) { ... }
    func cancelAll() { ... }
    
    // Task Management
    func scheduleTask(id: String, delay: TimeInterval, action: @escaping () async -> Void) { ... }
    func cancelTask(id: String) { ... }
    func cancelAllTasks() { ... }
    
    // Lifecycle
    deinit { cancelAll(); cancelAllTasks() }
}
```

#### 4.6 😊 EmoteManager
**職責**：表情系統、動畫效果、廣播機制

```swift
class EmoteManager {
    @Published var activeEmotes: [EmoteEvent] = []
    @Published var emoteHistory: [EmoteEvent] = []
    
    private let eventBus: EventBus
    private let networkManager: BingoNetworkManager
    
    // Emote Operations
    func sendEmote(_ emote: EmoteType) async throws { ... }
    func receiveEmote(_ event: EmoteEvent) async { ... }
    func clearEmotes() { ... }
    
    // Animation Management
    func startEmoteAnimation(_ emote: EmoteType) { ... }
    func stopEmoteAnimation(_ emoteId: String) { ... }
}
```

## 🔄 組件間通信機制

### 1. 事件系統設計

```swift
// Base Event Protocol
protocol Event {
    var id: String { get }
    var timestamp: Date { get }
    var source: String { get }
}

// Specific Events
struct GameStartedEvent: Event { ... }
struct PlayerJoinedEvent: Event { ... }
struct NumberDrawnEvent: Event { ... }
struct ChatMessageEvent: Event { ... }
struct EmoteEvent: Event { ... }
struct NetworkStatusEvent: Event { ... }

// Event Handler
typealias EventHandler<T: Event> = (T) -> Void
```

### 2. 狀態同步機制

```swift
// State Synchronization
@MainActor
class StateSynchronizer {
    private let stateStore: StateStore
    private let eventBus: EventBus
    
    func syncState<T: Codable>(_ state: T, type: StateType) async { ... }
    func requestStateSync() async { ... }
    func handleStateUpdate<T: Codable>(_ update: StateUpdate<T>) { ... }
}
```

### 3. 錯誤處理機制

```swift
// Error Management
class ErrorManager {
    private let eventBus: EventBus
    
    func handleError(_ error: Error, source: String) { ... }
    func recoverFromError(_ error: Error) async throws { ... }
    func logError(_ error: Error) { ... }
}
```

## 📊 性能考慮

### 1. 內存管理
- 使用 weak references 避免循環引用
- 及時清理不需要的訂閱和定時器
- 實現對象池來重用頻繁創建的對象

### 2. 異步處理
- 使用 async/await 替代回調地獄
- 合理使用 Task 和 TaskGroup 進行並發處理
- 避免在主線程進行重計算

### 3. 狀態更新優化
- 使用 @Published 的 debounce 機制
- 批量更新狀態以減少 UI 重繪
- 實現增量更新而非全量更新

## 🔧 依賴注入設計

```swift
// Dependency Container
class BingoGameContainer {
    // Singletons
    lazy var eventBus = EventBus()
    lazy var stateStore = StateStore()
    lazy var timerManager = TimerManager()
    
    // Factories
    func createNetworkManager() -> BingoNetworkManager { ... }
    func createGameManager() -> BingoGameManager { ... }
    func createRoomManager() -> BingoRoomManager { ... }
    func createChatManager() -> BingoChatManager { ... }
    func createEmoteManager() -> EmoteManager { ... }
    
    // Coordinator
    func createCoordinator() -> BingoGameCoordinator { ... }
    
    // ViewModel
    func createViewModel() -> BingoGameViewModel { ... }
}
```

## 🧪 測試策略

### 1. 單元測試
- 每個 Manager 獨立測試
- Mock 外部依賴
- 測試覆蓋率 > 90%

### 2. 集成測試
- 組件間交互測試
- 事件流測試
- 狀態同步測試

### 3. 端到端測試
- 完整遊戲流程測試
- 網絡異常恢復測試
- 並發場景測試

## 🚀 部署和監控

### 1. 性能監控
- 內存使用監控
- 網絡延遲監控
- 狀態更新頻率監控

### 2. 錯誤追蹤
- 崩潰日誌收集
- 錯誤恢復統計
- 用戶行為追蹤

### 3. 版本管理
- 向後兼容性
- 漸進式升級
- 功能開關控制

## 📝 實施檢查清單

### 階段一：基礎架構
- [ ] 創建 EventBus 和 StateStore
- [ ] 實現 TimerManager
- [ ] 建立依賴注入容器
- [ ] 設計錯誤處理機制

### 階段二：核心管理器
- [ ] 實現 BingoNetworkManager
- [ ] 實現 BingoGameManager
- [ ] 實現 BingoRoomManager
- [ ] 建立狀態同步機制

### 階段三：業務邏輯
- [ ] 實現 BingoGameCoordinator
- [ ] 實現 BingoChatManager
- [ ] 實現 EmoteManager
- [ ] 完善事件系統

### 階段四：UI 整合
- [ ] 重構 BingoGameViewModel
- [ ] 更新 SwiftUI 視圖
- [ ] 實現狀態綁定
- [ ] 測試用戶交互

### 階段五：測試和優化
- [ ] 編寫單元測試
- [ ] 執行集成測試
- [ ] 性能優化
- [ ] 文檔完善

## 🎯 成功指標

### 定量指標
- 代碼行數減少 > 40%
- 平均方法複雜度 < 10
- 測試覆蓋率 > 90%
- 編譯時間減少 > 30%

### 定性指標
- 模塊職責邊界清晰
- 組件間依賴最小化
- 代碼可讀性大幅提升
- 維護和擴展便利性

這個模塊化架構設計提供了一個清晰、可維護、可擴展的解決方案，將大幅改善 BingoGameViewModel 的代碼品質和開發效率。