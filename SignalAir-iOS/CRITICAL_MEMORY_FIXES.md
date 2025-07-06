# 🚨 CRITICAL MEMORY FIXES - 崩潰問題根本解決方案

## 問題總結
經過3天的調查，發現了多個嚴重的記憶體管理問題導致實機崩潰：

1. **Timer 循環引用**
2. **MainActor 隔離違規**  
3. **初始化競態條件**
4. **NotificationCenter 觀察者洩漏**
5. **Force Unwrapping 崩潰**

---

## 具體重構範例

### 🔴 問題 1: Timer 循環引用導致記憶體洩漏

**❌ 問題代碼 (Before)**:
```swift
// Line 400 in BingoGameViewModel.swift
hostPromotionTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
    Task { @MainActor in
        guard let self = self else { return }
        if !self.isHost && self.roomPlayers.count == 1 {
            print("⏰ 連接超時，成為主機")
            // 問題：Task 中的 self 仍然創建循環引用
            self.becomeRoomHost()
        }
    }
}

// Line 1471 - heartbeatTimer 同樣問題
heartbeatTimer = Timer.scheduledTimer(withTimeInterval: NetworkConstants.heartbeatInterval, repeats: true) { [weak self] _ in
    Task { @MainActor in
        await self?.sendHeartbeat()  // 仍有循環引用風險
    }
}
```

**✅ 修復代碼 (After)**:
```swift
// 安全的 Timer 模式
private func scheduleHostPromotion() {
    hostPromotionTimer?.invalidate()
    
    hostPromotionTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] timer in
        guard let self = self else {
            timer.invalidate()
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if !self.isHost && self.roomPlayers.count == 1 {
                self.becomeRoomHost()
            }
        }
    }
}

// 修復 heartbeat timer
private func startHeartbeatSafely() {
    heartbeatTimer?.invalidate()
    
    let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] timer in
        guard let self = self else {
            timer.invalidate()
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.sendHeartbeat()
        }
    }
    
    heartbeatTimer = timer
}
```

**解釋為什麼這樣改**:
- **雙重弱引用**: Timer 回調和 Task 中都使用 [weak self]
- **提前失效檢查**: 在 Timer 回調中立即檢查 self 有效性
- **顯式失效**: 當 self 為 nil 時主動 invalidate timer

**潛在風險**:
- 需要確保所有 timer 都在 deinit 中被清理
- Timer 可能在 self 釋放前仍執行一次

---

### 🔴 問題 2: deinit 中的異步清理導致崩潰

**❌ 問題代碼 (Before)**:
```swift
// Line 222 in BingoGameViewModel.swift
deinit {
    NotificationCenter.default.removeObserver(self)
    // 立即同步清理 Timer，避免競態條件
    drawTimer?.invalidate()
    drawTimer = nil
    countdownTimer?.invalidate()
    countdownTimer = nil
    // ... 其他 timer 清理
    print("🎮 BingoGameViewModel: 已清理計時器，網路服務由系統管理")
}

// 問題：在其他地方有異步清理
private nonisolated func performTimerCleanup() {
    Task { @MainActor in
        drawTimer?.invalidate()  // 可能在 deinit 後執行
        drawTimer = nil
    }
}
```

**✅ 修復代碼 (After)**:
```swift
deinit {
    // 立即同步清理所有 Timer - 避免任何異步操作
    cleanupAllTimersSync()
    
    // 清理觀察者
    cleanupObserversSync()
    
    print("🎮 BingoGameViewModel: 完全清理完成")
}

private func cleanupAllTimersSync() {
    // 同步清理，避免競態條件
    drawTimer?.invalidate()
    drawTimer = nil
    
    countdownTimer?.invalidate()
    countdownTimer = nil
    
    syncTimer?.invalidate()
    syncTimer = nil
    
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
    
    reconnectTimer?.invalidate()
    reconnectTimer = nil
    
    hostPromotionTimer?.invalidate()
    hostPromotionTimer = nil
}

private func cleanupObserversSync() {
    // 安全地移除所有觀察者
    NotificationCenter.default.removeObserver(self)
    
    // 如果有自定義觀察者 token，也要清理
    notificationTokens.forEach { 
        NotificationCenter.default.removeObserver($0)
    }
    notificationTokens.removeAll()
}
```

**解釋為什麼這樣改**:
- **同步清理**: deinit 中必須同步執行，避免異步競態
- **完整清理**: 確保所有 Timer 都被 invalidate
- **防禦性**: 即使某個 timer 為 nil 也不會崩潰

---

### 🔴 問題 3: MainActor 隔離違規

**❌ 問題代碼 (Before)**:
```swift
// MultipeerConnectivity 回調在後台線程
func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    // 直接在後台線程存取 @Published 屬性
    updateConnectionStatus()  // 危險！可能崩潰
    onPeerConnected?(peerID.displayName)
}

// 在 BingoGameViewModel 中
private func handleMeshMessage(_ message: GameMessage) {
    // 可能在後台線程被呼叫
    roomPlayers.append(newPlayer)  // @Published 屬性，線程不安全
}
```

**✅ 修復代碼 (After)**:
```swift
// NetworkService.swift
nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    // 安全地轉到主線程
    Task { @MainActor in
        await handlePeerStateChangeSafely(peerID: peerID, state: state)
    }
}

@MainActor
private func handlePeerStateChangeSafely(peerID: MCPeerID, state: MCSessionState) {
    // 現在安全地更新 @Published 屬性
    updateConnectionStatus()
    onPeerConnected?(peerID.displayName)
}

// BingoGameViewModel.swift
@MainActor
private func handleMeshMessage(_ message: GameMessage) {
    // 確保在主線程執行
    guard Thread.isMainThread else {
        Task { @MainActor in
            await self.handleMeshMessage(message)
        }
        return
    }
    
    // 安全地更新 UI 狀態
    roomPlayers.append(newPlayer)
}
```

**解釋為什麼這樣改**:
- **線程隔離**: MultipeerConnectivity 回調在後台線程，需轉到主線程
- **MainActor 保護**: 所有 @Published 屬性更新都在主線程
- **防禦性檢查**: 檢查當前線程，必要時轉換

---

### 🔴 問題 4: 初始化競態條件

**❌ 問題代碼 (Before)**:
```swift
// BingoGameViewModel init
init(meshManager: MeshManagerProtocol, ...) {
    self.meshManager = meshManager
    // ...
    
    // 立即呼叫，可能存取未完全初始化的屬性
    DispatchQueue.main.async { [weak self] in
        self?.setupMeshNetworking()      // 可能崩潰
        self?.setupNotificationObservers()
        self?.startHeartbeat()
    }
}

private func setupMeshNetworking() {
    // 存取可能未初始化的屬性
    updateConnectionStatus()  // 崩潰點！
}
```

**✅ 修復代碼 (After)**:
```swift
init(meshManager: MeshManagerProtocol, ...) {
    // 1. 初始化所有必要屬性
    self.meshManager = meshManager
    self.securityService = securityService
    self.settingsViewModel = settingsViewModel
    self.languageService = languageService
    
    // 2. 初始化簡單屬性
    self.playerID = UserDefaults.standard.string(forKey: "BingoPlayerID") ?? UUID().uuidString
    self.deviceName = nicknameService.nickname.isEmpty ? "用戶" : nicknameService.nickname
    
    // 3. 設置初始狀態
    self.connectionStatus = ""
    self.syncStatus = ""
    
    // 4. 使用安全的延遲初始化
    scheduleDelayedSetup()
}

private func scheduleDelayedSetup() {
    Task { @MainActor in
        // 等待一個運行循環，確保初始化完成
        await Task.yield()
        
        // 現在安全地設置狀態
        self.connectionStatus = self.languageService.t("offline")
        self.syncStatus = self.languageService.t("waiting_sync")
        
        // 安全地啟動網路功能
        await setupMeshNetworkingSafely()
        await setupNotificationObserversSafely()
        await startHeartbeatSafely()
    }
}

@MainActor
private func setupMeshNetworkingSafely() async {
    guard !isNetworkActive else { return }
    
    meshManager.startMeshNetwork()
    isNetworkActive = true
    updateConnectionStatus()
}
```

**解釋為什麼這樣改**:
- **分階段初始化**: 先初始化屬性，再設置複雜狀態
- **Task.yield()**: 確保初始化完全完成再繼續
- **安全檢查**: 在每個步驟都檢查狀態有效性

---

### 🔴 問題 5: NotificationCenter 觀察者洩漏

**❌ 問題代碼 (Before)**:
```swift
private func setupNotificationObservers() {
    // 使用 selector 模式，容易忘記移除
    NotificationCenter.default.addObserver(
        self, 
        selector: #selector(handleGameMessage), 
        name: .gameMessageReceived, 
        object: nil
    )
    
    // 沒有保存 token，難以清理
}

deinit {
    NotificationCenter.default.removeObserver(self)  // 可能不完整
}
```

**✅ 修復代碼 (After)**:
```swift
private var notificationTokens: [NSObjectProtocol] = []

@MainActor
private func setupNotificationObservers() async {
    // 使用 token 模式，確保完全清理
    let gameMessageToken = NotificationCenter.default.addObserver(
        forName: .gameMessageReceived,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        Task { @MainActor in
            await self?.handleGameMessageSafely(notification)
        }
    }
    notificationTokens.append(gameMessageToken)
    
    let peerConnectedToken = NotificationCenter.default.addObserver(
        forName: .meshPeerConnected,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        Task { @MainActor in
            await self?.handlePeerConnectedSafely(notification)
        }
    }
    notificationTokens.append(peerConnectedToken)
}

deinit {
    // 完全清理所有觀察者
    notificationTokens.forEach { 
        NotificationCenter.default.removeObserver($0)
    }
    notificationTokens.removeAll()
    
    // 雙重保險
    NotificationCenter.default.removeObserver(self)
}
```

**解釋為什麼這樣改**:
- **Token 管理**: 保存所有觀察者 token 確保完全清理
- **弱引用**: 回調中使用 weak self 避免循環引用
- **主線程安全**: 所有回調都在主線程執行

---

### 🔴 問題 6: Force Unwrapping 導致崩潰

**❌ 問題代碼 (Before)**:
```swift
// 在 BinaryMessageDecoder 中
let uuid = data.subdata(in: offset..<offset+16).withUnsafeBytes {
    $0.load(as: UUID.self)  // 可能崩潰！
}

// 在 GameMessage 處理中
let components = String(data: message.data, encoding: .utf8)!.components(separatedBy: "|")  // 崩潰點！
let playerID = components[0]  // 可能 index out of bounds
```

**✅ 修復代碼 (After)**:
```swift
// 安全的數據解析
func decodeUUID(from data: Data, at offset: Int) -> UUID? {
    guard data.count >= offset + 16 else {
        print("❌ UUID 數據不足: 需要 \(offset + 16) bytes，實際 \(data.count) bytes")
        return nil
    }
    
    let uuidData = data.subdata(in: offset..<offset+16)
    guard uuidData.count == 16 else {
        print("❌ UUID 數據大小錯誤: \(uuidData.count)")
        return nil
    }
    
    return uuidData.withUnsafeBytes { bytes in
        guard bytes.count == 16 else { return nil }
        return UUID(uuid: bytes.load(as: uuid_t.self))
    }
}

// 安全的訊息解析
private func parseHeartbeatMessage(_ data: Data) -> (playerID: String, playerName: String)? {
    guard let messageString = String(data: data, encoding: .utf8) else {
        print("❌ 無法解析心跳訊息為字符串")
        return nil
    }
    
    let components = messageString.components(separatedBy: "|")
    guard components.count >= 2 else {
        print("❌ 心跳訊息格式錯誤: \(messageString)")
        return nil
    }
    
    let playerID = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
    let playerName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !playerID.isEmpty, !playerName.isEmpty else {
        print("❌ 玩家 ID 或名稱為空")
        return nil
    }
    
    return (playerID: playerID, playerName: playerName)
}
```

**解釋為什麼這樣改**:
- **邊界檢查**: 所有數組/數據存取都檢查邊界
- **可選返回**: 失敗時返回 nil 而非崩潰
- **詳細錯誤**: 記錄具體的失敗原因便於調試

---

## 🛠️ 實施步驟

### 1. 立即修復 (高優先級)
```bash
# 替換所有問題 Timer 模式
grep -n "Timer.scheduledTimer" SignalAir/Features/Game/BingoGameViewModel.swift
# 修復所有發現的 Timer 創建

# 修復 deinit 清理
# 檢查所有 ViewModel 的 deinit 實現
```

### 2. MainActor 隔離修復
```swift
// 在所有 MultipeerConnectivity delegate 方法前加上
nonisolated func session(...) {
    Task { @MainActor in
        // 原有邏輯
    }
}
```

### 3. 驗證修復
```bash
# 在實機上測試
# 1. 快速進入/退出賓果房間
# 2. 在網路狀況不佳時測試
# 3. 多設備同時連接測試
```

## 🎯 潛在風險和注意事項

1. **Timer 清理**: 確保所有 Timer 都在正確的時機被 invalidate
2. **MainActor 邊界**: 小心跨線程存取 @Published 屬性
3. **初始化順序**: 確保屬性完全初始化後再進行複雜操作
4. **記憶體洩漏**: 定期使用 Instruments 檢查記憶體使用
5. **網路異常**: 在網路不穩定時測試所有修復是否有效

## ✅ 驗證清單

- [ ] 所有 Timer 使用雙重弱引用
- [ ] deinit 中同步清理所有資源
- [ ] 所有 MultipeerConnectivity 回調都轉到主線程
- [ ] 沒有 force unwrapping 在關鍵路徑
- [ ] NotificationCenter 觀察者使用 token 管理
- [ ] 初始化延遲到屬性完全設置後
- [ ] 實機測試無崩潰
- [ ] 記憶體洩漏測試通過

這些修復應該能完全解決賓果遊戲室的崩潰問題！