# 🔧 BingoGameViewModel 重構階段一：核心管理器提取

## 🎯 目標
- 提取 TimerManager 和 NetworkManager
- 減少 BingoGameViewModel 的複雜度
- 保持現有功能完整性

## 📋 拆分清單

### 1. TimerManager 提取
**原因**：定時器管理分散在多個方法中，造成資源管理混亂

**拆分內容**：
- `TimerID` enum (行 132-142)
- `scheduleTimer()` (行 162-177)
- `cancelTimer()` (行 179-184)
- `cancelAllTimers()` (行 186-189)
- `deinit` 中的定時器清理 (行 193-205)

**新文件**：`TimerManager.swift`
```swift
// 預計行數：~150 行
class TimerManager {
    private var timers: [String: Timer] = [:]
    
    func scheduleTimer(id: String, interval: TimeInterval, repeats: Bool, block: @escaping () -> Void)
    func cancelTimer(id: String)
    func cancelAllTimers()
}
```

### 2. NetworkManager 提取
**原因**：網絡管理佔用 24.8% 代碼，職責過重

**拆分內容**：
- `setupMeshNetworking()` (行 563-602)
- `validateNetworkChannelState()` (行 681-695)
- `performNetworkRecovery()` (行 753-779)
- `updateConnectionStatus()` (行 2014-2034)
- `broadcastGameMessage()` (行 1811-1849)

**新文件**：`BingoNetworkManager.swift`
```swift
// 預計行數：~400 行
class BingoNetworkManager {
    @Published var connectionStatus: String = "離線"
    @Published var isNetworkActive: Bool = false
    
    func setupMeshNetworking()
    func validateNetworkChannelState()
    func performNetworkRecovery()
    func broadcastGameMessage()
}
```

### 3. GameStateManager 提取
**原因**：遊戲狀態管理邏輯複雜，需要獨立管理

**拆分內容**：
- `generateBingoCard()` (行 1578-1603)
- `startGame()` (行 1480-1526)
- `drawNextNumber()` (行 1547-1566)
- `checkWinCondition()` (行 1604-1635)
- `markNumber()` (行 1636-1657)

**新文件**：`BingoGameStateManager.swift`
```swift
// 預計行數：~500 行
class BingoGameStateManager {
    @Published var gameState: GameState = .waitingForPlayers
    @Published var bingoCard: BingoCard?
    @Published var drawnNumbers: Set<Int> = []
    @Published var gameWon: Bool = false
    
    func generateBingoCard() -> BingoCard
    func startGame()
    func drawNextNumber()
    func checkWinCondition()
}
```

## 🔄 重構步驟

### 步驟 1: 準備工作
1. ✅ 分析現有代碼結構
2. ✅ 識別拆分邊界
3. ✅ 設計新的類別介面
4. ⏳ 創建基礎架構

### 步驟 2: TimerManager 提取
1. 創建 `TimerManager.swift`
2. 遷移定時器相關代碼
3. 更新 BingoGameViewModel 使用 TimerManager
4. 測試定時器功能

### 步驟 3: NetworkManager 提取
1. 創建 `BingoNetworkManager.swift`
2. 遷移網絡相關代碼
3. 設計狀態同步機制
4. 更新 BingoGameViewModel 使用 NetworkManager

### 步驟 4: GameStateManager 提取
1. 創建 `BingoGameStateManager.swift`
2. 遷移遊戲狀態相關代碼
3. 設計狀態變更通知機制
4. 更新 BingoGameViewModel 使用 GameStateManager

### 步驟 5: 整合測試
1. 編譯測試
2. 功能測試
3. 性能測試
4. 代碼審查

## 📊 預期結果

### 代碼行數變化
- **BingoGameViewModel**: 3,232 行 → ~1,800 行 (減少 44%)
- **TimerManager**: ~150 行 (新增)
- **BingoNetworkManager**: ~400 行 (新增)
- **BingoGameStateManager**: ~500 行 (新增)
- **總計**: 3,232 行 → 2,850 行 (減少 12%)

### 複雜度改善
- **職責分離**: 每個類專注單一職責
- **依賴簡化**: 減少內部依賴關係
- **測試性提升**: 各管理器可獨立測試

### 維護性提升
- **代碼可讀性**: 每個文件職責清晰
- **修改影響範圍**: 降低變更影響
- **並行開發**: 不同模塊可並行開發

## ⚠️ 風險評估

### 高風險項目
1. **狀態同步**：@Published 屬性的跨類別同步
2. **生命週期管理**：確保各管理器正確初始化和銷毀
3. **性能影響**：避免過度的對象創建和通信開銷

### 風險緩解措施
1. **逐步驗證**：每個管理器提取後立即測試
2. **保留備份**：保持原始代碼的備份版本
3. **回滾機制**：如果出現問題，可快速回滾

## 🎯 成功指標

### 定量指標
- [ ] 編譯無錯誤
- [ ] 所有現有測試通過
- [ ] 代碼覆蓋率 > 80%
- [ ] 平均方法長度 < 20 行

### 定性指標
- [ ] 代碼職責邊界清晰
- [ ] 易於理解和維護
- [ ] 支持並行開發
- [ ] 便於單元測試

## 📅 時間規劃

### 階段一總時間：5-7 天
- **TimerManager 提取**：1-2 天
- **NetworkManager 提取**：2-3 天
- **GameStateManager 提取**：2-3 天
- **整合測試**：1 天

### 里程碑檢查點
- [ ] Day 2: TimerManager 完成
- [ ] Day 4: NetworkManager 完成
- [ ] Day 6: GameStateManager 完成
- [ ] Day 7: 整合測試完成

## 🚀 下一階段預告

階段二將重構：
- RoomManager (房間管理)
- ChatManager (聊天系統)
- EmoteManager (表情系統)
- 統一事件總線機制