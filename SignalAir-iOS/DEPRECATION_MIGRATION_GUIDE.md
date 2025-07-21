# 📋 Deprecation Migration Guide
*重複程式碼重構 - 遷移指南*

## 🔄 已 Deprecated 的檔案

### Timer 管理器 (已統一為 UnifiedTimerManager)

**已棄用檔案：**
- `/Core/Performance/TimerManager.swift` ⚠️ **DEPRECATED**
- `/Core/Services/TimerManager.swift` ⚠️ **DEPRECATED**  
- `/Features/Game/TimerManager.swift` ⚠️ **DEPRECATED**

**新統一檔案：**
- `/Core/Services/UnifiedTimerManager.swift` ✅ **NEW**

### 連接管理器 (已統一為 UnifiedConnectionManager)

**已棄用檔案：**
- `/Services/AutoReconnectManager.swift` ⚠️ **DEPRECATED**
- `/Services/ConnectionKeepAlive.swift` ⚠️ **DEPRECATED**

**新統一檔案：**
- `/Services/UnifiedConnectionManager.swift` ✅ **NEW**

## 🔧 遷移步驟

### 1. Timer 管理器遷移

**舊用法：**
```swift
// 舊的多個 TimerManager 實作
let gameTimer = TimerManager.shared
let serviceTimer = TimerManager() 
let performanceTimer = TimerManager.shared
```

**新用法：**
```swift
// 統一的 UnifiedTimerManager
let timerManager = UnifiedTimerManager.shared

// 遊戲計時器
timerManager.scheduleGameTimer(id: "gameUpdate", interval: 1.0) {
    // 遊戲更新邏輯
}

// 心跳檢測
timerManager.scheduleHeartbeat {
    // 心跳邏輯
}

// 自定義計時器
timerManager.schedule(
    id: "customTimer",
    configuration: .countdown
) {
    // 自定義邏輯
}
```

### 2. 連接管理器遷移

**舊用法：**
```swift
// 分離的連接管理
let autoReconnect = AutoReconnectManager(networkService: networkService)
let keepAlive = ConnectionKeepAlive(networkService: networkService)

autoReconnect.start()
keepAlive.start()
```

**新用法：**
```swift
// 統一的連接管理
let connectionManager = UnifiedConnectionManager(
    networkService: networkService,
    configuration: .default  // 或 .aggressive
)

connectionManager.start()

// 監聽連接事件
connectionManager.connectionEvents
    .sink { event in
        switch event {
        case .peerConnected(let peer):
            print("Peer 已連接: \(peer.displayName)")
        case .reconnectSuccess(let peer):
            print("重連成功: \(peer.displayName)")
        // 其他事件處理...
        }
    }
    .store(in: &cancellables)
```

## 📈 新功能特性

### UnifiedTimerManager 新功能
- 🎯 **統一配置系統** - 預設配置適用於不同場景
- 🔋 **電量優化** - 自動容差設定
- 📱 **應用生命週期感知** - 背景/前台自動調整
- 📊 **統計追蹤** - 計時器觸發次數和效能監控
- 🧹 **記憶體管理** - 自動清理和弱引用

### UnifiedConnectionManager 新功能
- 🔗 **智能重連** - 指數退避和最大嘗試限制
- 📊 **連接品質監控** - 即時延遲和穩定性追蹤
- 🔔 **事件驅動架構** - Combine 支援
- ⚙️ **可配置策略** - Default/Aggressive 模式
- 🛡️ **錯誤恢復** - 自動降級和品質調整

## ⏰ 移除計劃

**階段 1** (目前): 標記為 `@available(*, deprecated)`
- 編譯時會顯示警告
- 功能仍可正常使用
- 建議開始遷移

**階段 2** (下個次要版本): 新增編譯錯誤指引
- 更強烈的遷移提示
- 提供自動遷移工具

**階段 3** (下個主要版本): 完全移除
- 刪除已棄用的檔案
- 清理相關引用

## 🔍 檢查清單

- [ ] 更新所有對舊 TimerManager 的引用
- [ ] 更新所有對 AutoReconnectManager 的引用  
- [ ] 更新所有對 ConnectionKeepAlive 的引用
- [ ] 測試新的統一管理器功能
- [ ] 更新單元測試
- [ ] 更新文件和註解

## 💡 最佳實踐

1. **漸進式遷移** - 一次遷移一個模組
2. **測試覆蓋** - 確保新實作行為一致
3. **配置調優** - 根據使用場景選擇適當配置
4. **監控效能** - 利用新的統計功能監控效能
5. **事件處理** - 善用 Combine 的事件流處理

## 🆘 需要協助？

如果在遷移過程中遇到問題：
1. 檢查編譯錯誤和警告訊息
2. 參考新 API 的內建文件
3. 查看統一管理器的範例用法
4. 確認配置參數設定正確

---
*最後更新: 2025-07-21*
*版本: v1.0*