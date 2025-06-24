# Bingo Game 真實排行榜數據實現

## 概述

已將 Bingo Game Room 中的今日排行榜從假數據改為真實數據實現，準備進行實機測試。

## 實現功能

### 1. 數據持久化存儲
- **存儲位置**: UserDefaults
- **存儲鍵**: `SignalAir_BingoLeaderboard`
- **數據格式**: JSON 編碼的 `[BingoScore]` 陣列

### 2. 排行榜記錄機制
- **觸發時機**: 當玩家完成 6 條線或以上時自動記錄
- **記錄數據**:
  - 玩家暱稱 (deviceName)
  - 完成線數 (score)
  - 遊戲時間戳記 (timestamp)
  - 遊戲日期 (date)

### 3. 排行榜顯示邏輯
- **過濾**: 只顯示當日數據
- **排序**: 按完成線數降序排列
- **限制**: 最多顯示前 10 名

## 測試方法

### 實機測試步驟

1. **初次啟動測試**
   ```
   - 啟動 SignalAir 應用
   - 進入 Bingo Game Room
   - 確認排行榜為空（無假數據）
   ```

2. **遊戲完成測試**
   ```
   - 選擇任一房間 (Room A/B/C)
   - 進行遊戲直到完成 6 條線
   - 確認獲勝時顯示 "🏆 恭喜您獲勝！"
   - 返回主頁面檢查排行榜是否記錄
   ```

3. **多次遊戲測試**
   ```
   - 進行多次遊戲，每次完成不同線數
   - 確認排行榜按分數高低正確排序
   - 測試相同分數的排序（按時間先後）
   ```

4. **跨日測試**
   ```
   - 更改系統日期到隔天
   - 確認排行榜重置為空
   - 進行新遊戲確認新記錄正確保存
   ```

### 驗證要點

- ✅ 無假數據顯示
- ✅ 獲勝時自動記錄
- ✅ 使用真實玩家暱稱
- ✅ 分數正確計算（完成線數）
- ✅ 日期過濾正確
- ✅ 排序邏輯正確
- ✅ 數據持久化保存

## 技術實現細節

### 核心方法

1. **`loadLeaderboardFromStorage()`**
   - 從 UserDefaults 讀取歷史數據
   - 過濾當日記錄
   - 排序並限制顯示數量

2. **`addGameResult(deviceName:score:)`**
   - 創建新的 BingoScore 記錄
   - 追加到歷史數據
   - 保存到 UserDefaults
   - 刷新當日排行榜顯示

3. **遊戲獲勝回調**
   - BingoGameViewModel 中的 `onGameWon` 回調
   - 在完成 6 條線時自動觸發
   - 傳遞玩家名稱和分數

### 數據結構

```swift
struct BingoScore: Identifiable, Codable {
    let id: UUID
    let deviceName: String    // 玩家暱稱
    let score: Int           // 完成線數
    let timestamp: TimeInterval // 遊戲時間
    let date: String         // 遊戲日期 (yyyy-MM-dd)
}
```

## 測試準備

### 實機測試環境
- iOS 裝置 (iPhone/iPad)
- SignalAir 應用已安裝
- 系統日期時間正確
- 足夠的存儲空間

### 測試數據重置
如需重置排行榜數據進行測試：
```swift
// 在開發期間可通過以下方式清除數據
UserDefaults.standard.removeObject(forKey: "SignalAir_BingoLeaderboard")
```

## 注意事項

1. **玩家暱稱**: 使用 NicknameService 中設定的暱稱
2. **獲勝條件**: 完成 6 條線或以上
3. **數據保存**: 每次獲勝自動保存，無需手動操作
4. **性能考慮**: 歷史數據會持續累積，建議定期清理舊數據

---

**實機測試準備完成** ✅
可以開始進行真實數據的排行榜功能測試。 