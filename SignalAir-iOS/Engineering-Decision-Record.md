# 🚀 SignalAir Engineering Decision Record (EDR)

## 概述
本文檔記錄 SignalAir 應用程式的重要架構決策、最佳實踐和技術選擇。每個決策都包含背景、考慮因素、選擇原因和實施細節。

---

## 📋 目錄

1. [架構決策](#1-架構決策)
2. [Swift 6 並發安全](#2-swift-6-並發安全)
3. [MultipeerConnectivity 實施](#3-multipeerconnectivity-實施)
4. [錯誤處理策略](#4-錯誤處理策略)
5. [記憶體管理](#5-記憶體管理)
6. [最佳實踐](#6-最佳實踐)
7. [測試策略](#7-測試策略)
8. [監控與診斷](#8-監控與診斷)

---

## 1. 架構決策

### 1.1 服務容器模式 (Service Container Pattern)

**決策**: 使用 `ServiceContainer` 作為依賴注入容器

**背景**: 
- 需要管理多個服務間的依賴關係
- 避免循環依賴和記憶體洩漏
- 提供統一的服務初始化和生命週期管理

**考慮方案**:
1. **單例模式** - 簡單但難以測試，容易產生隱藏依賴
2. **依賴注入** - 靈活但需要更多設置
3. **服務定位器** - 平衡方案，易於使用和測試

**選擇原因**:
```swift
// ✅ 採用服務容器模式
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // 核心服務
    let networkService: NetworkService
    let securityService: SecurityService
    let temporaryIDManager: TemporaryIDManager
    
    // 優點：
    // 1. 統一管理依賴注入
    // 2. 易於單元測試
    // 3. 清晰的服務邊界
    // 4. 支援 MainActor 隔離
}
```

**實施細節**:
- 所有服務都在 `ServiceContainer` 中初始化
- 使用 `@MainActor` 確保執行緒安全
- 提供 `deinit` 清理機制避免記憶體洩漏

---

### 1.2 MVVM + SwiftUI 架構

**決策**: 採用 MVVM (Model-View-ViewModel) 架構配合 SwiftUI

**背景**:
- SwiftUI 的聲明式特性與 MVVM 完美配合
- 需要清晰分離業務邏輯和 UI 邏輯
- 支援複雜的狀態管理和數據綁定

**架構圖**:
```
View (SwiftUI) ↔ ViewModel (@ObservableObject) ↔ Model/Service
     ↑                    ↑                        ↑
  UI 事件              業務邏輯                 數據/網路
```

**實施策略**:
```swift
// ✅ ViewModel 模式
@MainActor
class BingoGameViewModel: ObservableObject {
    // 🔒 私有服務依賴
    private let meshManager: MeshManagerProtocol
    private let securityService: SecurityService
    
    // 📡 公開狀態
    @Published var gameState: GameState = .waiting
    @Published var connectionStatus: String = ""
    
    // 🎯 明確的依賴注入
    init(meshManager: MeshManagerProtocol, 
         securityService: SecurityService) {
        self.meshManager = meshManager
        self.securityService = securityService
        // 延遲初始化避免競態條件
        DispatchQueue.main.async { [weak self] in
            self?.setupNetworking()
        }
    }
}
```

---

### 1.3 協議導向程式設計 (Protocol-Oriented Programming)

**決策**: 使用協議定義服務介面，支援依賴注入和測試

**實施範例**:
```swift
// ✅ 定義協議介面
@MainActor
protocol NetworkServiceProtocol: AnyObject, Sendable {
    var connectedPeers: [MCPeerID] { get }
    func send(_ data: Data, to peers: [MCPeerID]) async throws
    func getConnectedPeers() -> [String]
}

@MainActor  
protocol MeshManagerProtocol: AnyObject {
    func startMeshNetwork()
    func sendMessage(_ data: Data, toPeer peer: String, messageType: MeshMessageType)
}

// ✅ 實際實施
@MainActor
class NetworkService: NetworkServiceProtocol {
    // 具體實施...
}
```

**優點**:
- 易於單元測試 (Mock 實施)
- 降低耦合度
- 支援多種實施方式
- 清晰的 API 契約

---

## 2. Swift 6 並發安全

### 2.1 MainActor 隔離策略

**決策**: 所有 UI 相關類別使用 `@MainActor` 註解

**背景**: Swift 6 嚴格並發檢查要求明確的執行緒安全保證

**實施策略**:
```swift
// ✅ UI 類別的 MainActor 隔離
@MainActor
class NetworkService: ObservableObject, @unchecked Sendable {
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isConnected = false
    
    // 所有屬性和方法都自動在主執行緒執行
    func updateConnectionStatus() {
        // 安全存取 @Published 屬性
        self.connectedPeers = session.connectedPeers
    }
}

// ✅ ViewModel 的 MainActor 隔離
@MainActor  
class BingoGameViewModel: ObservableObject {
    @Published var gameState: GameState = .waiting
    
    // 確保所有 UI 更新都在主執行緒
    private func updateGameState(_ newState: GameState) {
        self.gameState = newState
    }
}
```

### 2.2 Sendable 合規性

**決策**: 使用 `@unchecked Sendable` 處理 MultipeerConnectivity 相容性

**原因**: MCSession 等 MultipeerConnectivity 類別尚未完全支援 Swift 6 並發

**實施**:
```swift
// ✅ 預先相容性匯入
@preconcurrency import MultipeerConnectivity

// ✅ 安全的 Sendable 實施
@MainActor
class NetworkService: NSObject, ObservableObject, @unchecked Sendable {
    // MultipeerConnectivity 在 MainActor 隔離下是安全的
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
}
```

### 2.3 跨 Actor 通訊

**決策**: 使用 `Task` 和 `await` 進行安全的跨執行緒通訊

**實施範例**:
```swift
// ✅ 安全的跨 Actor 呼叫
func sendHeartbeat() async {
    let stableConnections = await connectionStateManager.getStableConnections()
    
    await MainActor.run {
        // 更新 UI 狀態
        self.connectionStatus = "已連接 \(stableConnections.count) 個設備"
    }
}

// ✅ 回調函式的執行緒安全處理
func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    Task { @MainActor in
        // 確保 UI 更新在主執行緒
        self.updateConnectionStatus()
    }
}
```

---

## 3. MultipeerConnectivity 實施

### 3.1 連接管理策略

**決策**: 使用 Actor 模式管理連接狀態，避免競態條件

**實施**:
```swift
// ✅ Actor 模式連接管理
actor ConnectionStateManager {
    private var connectionAttempts: Set<String> = []
    private var retryAttempts: [String: Int] = [:]
    
    func validatePeers(_ targetPeers: [MCPeerID], 
                      sessionPeers: [MCPeerID], 
                      threadSafePeers: [MCPeerID]) -> [MCPeerID] {
        return targetPeers.filter { peer in
            sessionPeers.contains(peer) && threadSafePeers.contains(peer)
        }
    }
    
    func cleanupPeer(_ peerName: String) {
        connectionAttempts.remove(peerName)
        retryAttempts.removeValue(forKey: peerName)
    }
}

// ✅ 使用方式
private let connectionStateManager = ConnectionStateManager()

func handlePeerDisconnection(_ peer: MCPeerID) {
    Task {
        await connectionStateManager.cleanupPeer(peer.displayName)
    }
}
```

### 3.2 錯誤處理和重試機制

**決策**: 實施指數退避重試機制

**實施**:
```swift
// ✅ 智慧重試機制
private func attemptReconnection(to peer: MCPeerID) async {
    let currentAttempts = await connectionStateManager.getRetryCount(peer.displayName)
    
    guard currentAttempts < maxRetries else {
        print("🚫 達到最大重試次數，停止重連 \(peer.displayName)")
        return
    }
    
    // 指數退避延遲
    let delay = min(pow(2.0, Double(currentAttempts)), 30.0)
    
    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    
    await connectionStateManager.setRetryCount(peer.displayName, count: currentAttempts + 1)
    
    // 執行重連
    browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
}
```

### 3.3 動態連線數限制

**決策**: 根據設備性能動態調整最大連線數

**實施**:
```swift
// ✅ 動態連線數限制
private var maxConnections: Int {
    let deviceMemory = ProcessInfo.processInfo.physicalMemory
    switch deviceMemory {
    case 4_000_000_000...: return 15  // 4GB+
    case 2_000_000_000...: return 10  // 2GB+
    default: return 6                  // < 2GB
    }
}

private func shouldAcceptNewConnection() -> Bool {
    return connectedPeers.count < maxConnections
}
```

---

## 4. 錯誤處理策略

### 4.1 統一錯誤定義

**決策**: 定義應用程式特定的錯誤類型

**實施**:
```swift
// ✅ 統一錯誤定義
enum SignalAirError: LocalizedError {
    case networkUnavailable
    case encryptionFailed(reason: String)
    case meshNetworkError(underlying: Error)
    case gameStateInvalid(expected: GameState, actual: GameState)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "網路連接不可用"
        case .encryptionFailed(let reason):
            return "加密失敗: \(reason)"
        case .meshNetworkError(let error):
            return "網狀網路錯誤: \(error.localizedDescription)"
        case .gameStateInvalid(let expected, let actual):
            return "遊戲狀態錯誤: 期望 \(expected)，實際 \(actual)"
        }
    }
}
```

### 4.2 錯誤傳播策略

**決策**: 使用 Result 類型和 async/await 錯誤處理

**實施**:
```swift
// ✅ Result 類型錯誤處理
func sendMessage(_ data: Data) -> Result<Void, SignalAirError> {
    guard !connectedPeers.isEmpty else {
        return .failure(.networkUnavailable)
    }
    
    do {
        try session.send(data, toPeers: connectedPeers, with: .reliable)
        return .success(())
    } catch {
        return .failure(.meshNetworkError(underlying: error))
    }
}

// ✅ async/await 錯誤處理
func sendMessageAsync(_ data: Data) async throws {
    guard !connectedPeers.isEmpty else {
        throw SignalAirError.networkUnavailable
    }
    
    try await withCheckedThrowingContinuation { continuation in
        do {
            try session.send(data, toPeers: connectedPeers, with: .reliable)
            continuation.resume()
        } catch {
            continuation.resume(throwing: SignalAirError.meshNetworkError(underlying: error))
        }
    }
}
```

---

## 5. 記憶體管理

### 5.1 生命週期管理

**決策**: 明確的資源清理和弱引用使用

**問題分析**: BingoGameViewModel 崩潰的原因
```swift
// ❌ 問題代碼 - 初始化順序問題
init(...) {
    // 屬性初始化不完整就開始使用
    setupMeshNetworking()  // 可能存取未初始化的屬性
    setupNotificationObservers()
    startHeartbeat()
}
```

**✅ 修復方案**:
```swift
// ✅ 安全的初始化順序
init(meshManager: MeshManagerProtocol, ...) {
    // 1. 先初始化所有必要屬性
    self.meshManager = meshManager
    self.playerID = UUID().uuidString
    self.deviceName = nicknameService.nickname
    
    // 2. 初始化簡單狀態
    self.connectionStatus = languageService.t("offline")
    
    // 3. 延遲複雜初始化，確保所有屬性都已設置
    DispatchQueue.main.async { [weak self] in
        self?.setupMeshNetworking()
        self?.setupNotificationObservers()
        self?.startHeartbeat()
    }
}
```

### 5.2 Timer 管理

**決策**: 統一的 Timer 清理機制

**實施**:
```swift
// ✅ 安全的 Timer 管理
class BingoGameViewModel: ObservableObject {
    private var timers: Set<Timer> = []
    
    private func createTimer(interval: TimeInterval, 
                           repeats: Bool = true, 
                           block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, 
                                       repeats: repeats, 
                                       block: block)
        timers.insert(timer)
        return timer
    }
    
    deinit {
        // 統一清理所有 Timer
        timers.forEach { $0.invalidate() }
        timers.removeAll()
        
        // 清理 NotificationCenter 觀察者
        NotificationCenter.default.removeObserver(self)
    }
}
```

### 5.3 弱引用模式

**決策**: 在閉包和回調中使用弱引用避免循環引用

**實施**:
```swift
// ✅ 弱引用模式
private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
        forName: .meshMessageReceived,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        self?.handleMeshMessage(notification)
    }
}

// ✅ 異步操作的弱引用
private func startPeriodicSync() {
    Task { [weak self] in
        while let self = self, !Task.isCancelled {
            await self.performSync()
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30秒
        }
    }
}
```

---

## 6. 最佳實踐

### 6.1 Swift Concurrency 最佳實踐

**實施指南**:
```swift
// ✅ 正確的 async 函式實施
private func sendHeartbeat() async {
    // 1. 檢查前置條件
    guard isNetworkActive else { return }
    
    // 2. 準備數據（非 UI 操作）
    let heartbeatData = createHeartbeatData()
    
    // 3. 網路操作
    do {
        try await networkService.send(heartbeatData, to: connectedPeers)
        
        // 4. UI 更新必須在 MainActor
        await MainActor.run {
            self.lastHeartbeatTime = Date()
            self.connectionStatus = "心跳已發送"
        }
    } catch {
        await MainActor.run {
            print("❌ 心跳發送失敗: \(error)")
            self.handleNetworkError(error)
        }
    }
}

// ✅ 正確的 Task 使用
private func startHeartbeat() {
    heartbeatTask = Task { [weak self] in
        while let self = self, !Task.isCancelled {
            await self.sendHeartbeat()
            
            // 使用 Task.sleep 而非 Thread.sleep
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10秒
        }
    }
}
```

### 6.2 錯誤處理統一策略

**實施**:
```swift
// ✅ 統一錯誤處理
protocol ErrorHandling {
    func handleError(_ error: Error, context: String)
}

extension BingoGameViewModel: ErrorHandling {
    func handleError(_ error: Error, context: String) {
        // 1. 記錄錯誤
        print("🚨 [\(context)] 錯誤: \(error)")
        
        // 2. 用戶友好的錯誤訊息
        let userMessage: String
        if let signalAirError = error as? SignalAirError {
            userMessage = signalAirError.localizedDescription
        } else {
            userMessage = "發生未知錯誤，請稍後再試"
        }
        
        // 3. UI 更新
        DispatchQueue.main.async {
            self.errorMessage = userMessage
            self.showError = true
        }
        
        // 4. 錯誤恢復策略
        attemptErrorRecovery(for: error, in: context)
    }
}
```

### 6.3 效能優化策略

**實施**:
```swift
// ✅ 節流機制 (Throttling)
private var lastUpdateTime = Date.distantPast
private let updateThrottle: TimeInterval = 1.0

private func updateConnectionStatus() {
    let now = Date()
    guard now.timeIntervalSince(lastUpdateTime) >= updateThrottle else {
        return // 跳過過於頻繁的更新
    }
    lastUpdateTime = now
    
    // 執行實際更新
    performConnectionStatusUpdate()
}

// ✅ 批次處理
private var pendingMessages: [Data] = []
private var batchTimer: Timer?

private func queueMessage(_ data: Data) {
    pendingMessages.append(data)
    
    // 設置批次發送計時器
    batchTimer?.invalidate()
    batchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
        self.sendBatchedMessages()
    }
}
```

---

## 7. 測試策略

### 7.1 單元測試架構

**決策**: 使用依賴注入支援單元測試

**實施**:
```swift
// ✅ 可測試的設計
protocol NetworkServiceProtocol {
    func send(_ data: Data, to peers: [MCPeerID]) async throws
    var connectedPeers: [MCPeerID] { get }
}

// ✅ Mock 實施
class MockNetworkService: NetworkServiceProtocol {
    var mockConnectedPeers: [MCPeerID] = []
    var shouldThrowError = false
    var sentMessages: [Data] = []
    
    var connectedPeers: [MCPeerID] { mockConnectedPeers }
    
    func send(_ data: Data, to peers: [MCPeerID]) async throws {
        if shouldThrowError {
            throw SignalAirError.networkUnavailable
        }
        sentMessages.append(data)
    }
}

// ✅ 單元測試
class BingoGameViewModelTests: XCTestCase {
    var viewModel: BingoGameViewModel!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        mockNetworkService = MockNetworkService()
        viewModel = BingoGameViewModel(networkService: mockNetworkService)
    }
    
    func testHeartbeatSending() async {
        // Given
        mockNetworkService.mockConnectedPeers = [MCPeerID(displayName: "TestPeer")]
        
        // When
        await viewModel.sendHeartbeat()
        
        // Then
        XCTAssertEqual(mockNetworkService.sentMessages.count, 1)
    }
}
```

### 7.2 整合測試策略

**實施範例**:
```swift
// ✅ 整合測試
class NetworkIntegrationTests: XCTestCase {
    func testRealNetworkConnection() async {
        let expectation = XCTestExpectation(description: "Network connection")
        
        let networkService = NetworkService()
        networkService.onPeerConnected = { peerName in
            expectation.fulfill()
        }
        
        networkService.startNetworking()
        
        await fulfillment(of: [expectation], timeout: 30)
    }
}
```

---

## 8. 監控與診斷

### 8.1 診斷系統設計

**決策**: 內建診斷工具支援生產環境除錯

**實施**:
```swift
// ✅ 診斷工具
extension NetworkService {
    func getDiagnosticReport() -> String {
        let sessionInfo = getSessionDiagnostics()
        let channelInfo = getChannelDiagnostics() 
        let errorInfo = getErrorDiagnostics()
        
        return """
        📊 NetworkService 診斷報告
        ═══════════════════════════
        
        🔗 MCSession 狀態:
        \(sessionInfo)
        
        📡 通道使用統計:
        \(channelInfo)
        
        ❌ 錯誤記錄:
        \(errorInfo)
        """
    }
    
    func performQuickDiagnostic() {
        print("""
        🔍 即時診斷檢查:
        - Session 連接數: \(session.connectedPeers.count)
        - Published 連接數: \(connectedPeers.count)
        - 連接狀態一致性: \(session.connectedPeers.count == connectedPeers.count ? "✅" : "❌")
        """)
    }
}
```

### 8.2 日誌系統

**實施**:
```swift
// ✅ 結構化日誌
enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "🚨"
}

struct Logger {
    static func log(_ message: String, 
                   level: LogLevel = .info, 
                   file: String = #file, 
                   function: String = #function, 
                   line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        print("[\(timestamp)] \(level.rawValue) [\(fileName):\(line)] \(function): \(message)")
    }
}

// ✅ 使用方式
Logger.log("網路連接已建立", level: .info)
Logger.log("發生網路錯誤", level: .error)
```

---

## 🎯 總結

### 關鍵決策摘要

1. **架構**: MVVM + SwiftUI + 服務容器模式
2. **並發**: Swift 6 嚴格模式 + MainActor 隔離
3. **網路**: MultipeerConnectivity + Actor 狀態管理
4. **錯誤處理**: 統一錯誤類型 + Result 模式
5. **記憶體**: 明確生命週期 + 弱引用模式
6. **測試**: 協議導向 + 依賴注入
7. **診斷**: 內建診斷工具 + 結構化日誌

### 效能考量

- **初始化延遲**: 避免同步初始化造成 UI 阻塞
- **記憶體管理**: 主動清理 Timer 和觀察者
- **網路節流**: 避免過度頻繁的網路操作
- **UI 響應**: 確保所有 UI 更新在主執行緒

### 維護性

- **模組化設計**: 清晰的服務邊界
- **協議導向**: 易於擴展和測試
- **文檔化**: 每個重要決策都有說明
- **診斷工具**: 支援生產環境除錯

這個架構設計考慮了初學者理解、效能優化、可維護性和生產環境穩定性的平衡。