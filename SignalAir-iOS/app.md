# SignalAir iOS App 技術文檔

## 應用程式概覽

SignalAir 是一個安全的 P2P 即時通訊應用程式，支援多種通訊模式和遊戲功能。

## 核心功能

### 1. 即時通訊系統
- P2P 網狀網路通訊
- @提及功能與自動補全
- 本地黑名單管理
- 多語言支援

### 2. 遊戲功能
- 賓果遊戲 (BingoGame)
- 多人遊戲支援
- 即時遊戲狀態同步

### 3. 安全防禦系統

#### 連線速率管理 (ConnectionRateManager)
- **實作檔案**: `/SignalAir/Core/Network/ConnectionRateManager.swift`
- **配置檔案**: `/SignalAir/Core/Configuration/NetworkSecurityConfig.swift`
- **功能**:
  - 訊息頻率限制 (預設: 10條/秒)
  - 分層封禁機制 (2小時 → 2小時 → 5天)
  - 緊急訊息繞過機制
  - 自動清理過期封禁記錄

#### APT 防禦系統 (Advanced Persistent Threat Defense)
- **實作檔案**: `/SignalAir/Core/Security/APTDefenseSystem.swift`
- **版本**: iOS 17+
- **功能**:
  - 行為模式分析：時間模式偵測、頻率異常分析、內容模式識別
  - 信任評分系統：0-100分動態評分機制
  - 威脅等級分類：正常、可疑、危險
  - Apple 合規訊息：使用者友善的警告文字，無攻擊術語

- **測試驗證**:
  - ✅ 獨立自檢系統已完成 (2025-07-18)
  - ✅ 全部8項測試通過
  - ✅ Apple App Store 合規性驗證
  - ✅ 行為分析算法驗證
  - ✅ 線程安全性測試
  - ✅ 記憶體管理測試

#### 安全日誌系統 (SecurityLogManager)
- **實作檔案**: `/SignalAir/Core/Security/SecurityLogManager.swift`
- **介面檔案**: `/SignalAir/Features/Security/SecurityLogView.swift`
- **功能**:
  - 隱私保護：個人訊息內容自動過濾
  - 三層清理機制：每月自動清理、容量限制清理、手動清理
  - 安全儲存：Documents/ 目錄存放
  - 事件記錄：連線失敗、大型封包、重複連線、未知協定請求、資料驗證失敗
  - 分析功能：攻擊統計、高風險時段分析
  - CSV 導出功能

### 4. 網路架構
- **MeshManager**: P2P 網狀網路管理
- **NetworkService**: 底層網路通訊服務
- **ServiceContainer**: 依賴注入容器，統一管理所有服務

## 技術架構

### 服務層
```
ServiceContainer
├── MeshManager (網狀網路管理)
├── NetworkService (網路通訊)
├── ConnectionRateManager (連線速率管理)
├── APTDefenseSystem (APT防禦)
├── SecurityLogManager (安全日誌)
├── TrustScoreManager (信任評分)
└── LocalBlacklistManager (本地黑名單)
```

### 安全集成流程
1. **連線建立**: NetworkService → APT防禦檢查 → 信任評分評估
2. **訊息處理**: MeshManager → 洪水防護檢查 → 內容驗證
3. **事件記錄**: 所有安全事件 → SecurityLogManager → 用戶可視化介面

## 開發規範

### 安全標準
- 所有安全功能必須符合 Apple App Store 審核規範
- 使用者介面不得包含攻擊相關術語
- 實作前必須建立獨立測試系統
- 測試通過後必須清理測試代碼

### 檔案組織
- 安全相關檔案放置於 `/Core/Security/`
- 網路相關檔案放置於 `/Core/Network/`
- 測試檔案使用清楚的命名規則並在測試後刪除

### 部署注意事項
- 上架前必須移除所有測試檔案和測試代碼
- 確保所有檔案都已正確加入 Xcode 專案
- 驗證 iOS 17+ 目標版本相容性

---

*最後更新: 2025-07-18*
*當前版本: iOS 17+*