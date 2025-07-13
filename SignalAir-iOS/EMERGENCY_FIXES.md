# 🚨 緊急修復計劃 - SignalAir iOS

## Phase 1: 關鍵崩潰修復 (48小時內)

### 1. NetworkService 線程安全修復

#### 問題：session.send() 競態條件
```swift
// ❌ BEFORE (崩潰原因)
try session.send(data, toPeers: remainingPeers, with: .reliable)

// ✅ AFTER (安全版本)
private let sessionQueue = DispatchQueue(label: "com.signalair.session", qos: .userInitiated)

private func safeSessionSend(_ data: Data, to peers: [MCPeerID]) async throws {
    return try await withCheckedThrowingContinuation { continuation in
        sessionQueue.async {
            do {
                // 原子性檢查和發送
                let validPeers = peers.filter { self.session.connectedPeers.contains($0) }
                guard !validPeers.isEmpty else {
                    continuation.resume(throwing: NetworkError.notConnected)
                    return
                }
                
                try self.session.send(data, toPeers: validPeers, with: .reliable)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### 2. BingoGameViewModel 狀態管理修復

#### 問題：重複房間加入和空值檢查
```swift
// ❌ BEFORE (崩潰原因)
func attemptToJoinOrCreateRoom(roomID: String) {
    // 直接操作，沒有狀態檢查
    self.gameRoomID = roomID
    isInRoom = true
    
    Task {
        let connectedPeers = await checkReliableConnectionState()
        // meshManager 可能為 nil
        // ...
    }
}

// ✅ AFTER (安全版本)
@MainActor
func attemptToJoinOrCreateRoom(roomID: String) {
    // 防止重複操作
    guard !isInRoom else {
        print("⚠️ 已在房間中，忽略重複加入請求")
        return
    }
    
    // 確保依賴存在
    guard let meshManager = self.meshManager else {
        print("❌ meshManager 未初始化，稍後重試")
        scheduleRetryJoinRoom(roomID)
        return
    }
    
    // 設置原子狀態
    isInRoom = true
    self.gameRoomID = roomID
    
    Task {
        await joinRoomSafely(roomID: roomID, meshManager: meshManager)
    }
}

private func scheduleRetryJoinRoom(_ roomID: String) {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
        Task { @MainActor in
            self?.attemptToJoinOrCreateRoom(roomID: roomID)
        }
    }
}
```

### 3. ServiceContainer 依賴注入修復

#### 問題：循環引用和初始化時序
```swift
// ❌ BEFORE (記憶體洩漏)
self.meshManager = MeshManager(
    networkService: self.networkService,  // 循環引用
    securityService: self.securityService,
    floodProtection: self.floodProtection
)

// ✅ AFTER (安全版本)
private func initializeMeshManagerSafely() async {
    // 確保服務準備完成
    await ensureServicesReady()
    
    let manager = MeshManager(
        networkService: networkService,
        securityService: securityService,
        floodProtection: floodProtection
    )
    
    // 設置回調避免循環引用
    manager.onMessageReceived = { [weak self] message in
        Task { @MainActor in
            await self?.handleMeshMessage(message)
        }
    }
    
    await MainActor.run {
        self.meshManager = manager
    }
}
```

## Phase 2: UI 響應性修復 (1週內)

### 1. 按鈕防抖動機制
```swift
// 防止多次點擊
@State private var isJoiningRoom = false

Button("進入遊戲室") {
    guard !isJoiningRoom else { return }
    isJoiningRoom = true
    
    Task {
        await viewModel.attemptToJoinOrCreateRoom(roomID: room.id)
        await MainActor.run {
            isJoiningRoom = false
        }
    }
}
.disabled(isJoiningRoom)
```

### 2. 載入狀態管理
```swift
enum GameRoomState {
    case idle
    case connecting
    case connected
    case failed(Error)
}

@Published var roomState: GameRoomState = .idle
```

## Phase 3: 效能優化 (2週內)

### 1. 記憶體管理
- 實施 Timer 池管理
- 添加記憶體警告處理
- 優化圖片和資源載入

### 2. 電池優化
- 實施智能睡眠機制
- 背景時停止非必要服務
- 優化網路掃描頻率

## 實施順序

1. **立即修復**：NetworkService 線程安全
2. **24小時內**：BingoGameViewModel 狀態管理
3. **48小時內**：ServiceContainer 依賴注入
4. **測試驗證**：多設備連接測試

## 測試計劃

### 崩潰測試
```swift
// 壓力測試：快速點擊遊戲室按鈕
func testRapidGameRoomEntry() {
    for _ in 0..<10 {
        viewModel.attemptToJoinOrCreateRoom(roomID: "test")
    }
    // 應該不崩潰，只處理第一次請求
}
```

### 記憶體測試
```swift
// 記憶體洩漏測試
func testTimerCleanup() {
    let viewModel = BingoGameViewModel(...)
    viewModel.attemptToJoinOrCreateRoom(roomID: "test")
    viewModel = nil  // 應該正確清理所有 Timer
}
```

## 監控指標

1. **崩潰率**：目標 < 0.1%
2. **連接成功率**：目標 > 95%
3. **記憶體使用**：目標 < 100MB
4. **電池消耗**：目標 < 5%/小時

---

**注意**：這些修復必須按順序進行，每個階段完成後進行完整測試再進入下一階段。