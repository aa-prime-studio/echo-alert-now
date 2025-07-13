# 賓果遊戲室索引文件

## 📁 關鍵文件位置

### 主要視圖文件
- **GameView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/GameView.swift`
  - 主要遊戲視圖，包含整體佈局結構

### 組件文件
- **BingoCardView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/BingoCardView.swift`
- **LeaderboardView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/LeaderboardView.swift`
- **RoomSelectorView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/RoomSelectorView.swift`
- **PlayerListView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/PlayerListView.swift`
- **DrawnNumbersView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/DrawnNumbersView.swift`
- **RoomChatView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/RoomChatView.swift`
- **GameRulesView.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/Components/GameRulesView.swift`

### ViewModel
- **BingoGameViewModel.swift**: `/Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS/SignalAir/Features/Game/BingoGameViewModel.swift`

## 🎯 設計目標 (Commit 17ec1bb)

### 原始設計：整頁模式
- **UI 結構**: ScrollView + LazyVStack
- **內容排列**: 垂直滾動，所有組件在同一頁面
- **用戶體驗**: 一目了然，無需切換標籤

### 當前問題：TabView 模式
- **UI 結構**: TabView with 4 tabs
- **內容分散**: 需要點擊底部 icon 切換
- **用戶體驗**: 分散注意力，需要頻繁切換

## 🛠️ 修復要點

1. 將 TabView 改為 ScrollView
2. 使用 LazyVStack 排列所有組件
3. 保持原有的覆蓋層系統（倒數、表情、獲勝）
4. 確保所有功能在同一頁面可見

## 📌 注意事項

- 每次修改前先讀取此索引文件
- 確認文件路徑正確
- 保持與 commit 17ec1bb 的視覺一致性