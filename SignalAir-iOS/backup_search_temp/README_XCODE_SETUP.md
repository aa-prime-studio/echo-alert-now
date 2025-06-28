# SignalAir iOS 專案建立腳本

這個腳本包會自動建立完整的 SignalAir iOS Xcode 專案，包含所有 Swift 檔案和專案配置。

## 快速開始

```bash
./create_xcode_project.sh
```

## 執行後會得到什麼

✅ **完整的 Xcode 專案**
- `SignalAir-iOS/SignalAir Rescue.xcodeproj` - Xcode 專案檔案
- 完整的 Swift 原始碼結構
- Info.plist 配置檔案

✅ **專案結構**
```
SignalAir-iOS/
├── SignalAir Rescue.xcodeproj/          # Xcode 專案檔案
└── SignalAir/                    # 主要原始碼
    ├── App/                      # 應用程式進入點
    │   ├── SignalAirApp.swift
    │   └── ContentView.swift
    ├── Features/                 # 功能模組
    │   ├── Signal/              # 訊號功能
    │   ├── Chat/                # 聊天功能
    │   ├── Game/                # 遊戲功能
    │   ├── Settings/            # 設定功能
    │   └── Legal/               # 法律頁面
    ├── Services/                # 服務層
    │   ├── PurchaseService.swift
    │   └── LanguageService.swift
    ├── Shared/Models/           # 資料模型
    │   ├── SignalModels.swift
    │   ├── ChatModels.swift
    │   └── GameModels.swift
    └── Info.plist              # 應用程式配置
```

## 使用方式

### 1. 執行腳本
```bash
./create_xcode_project.sh
```

### 2. 開啟 Xcode
```bash
open SignalAir-iOS/SignalAir Rescue.xcodeproj
```

### 3. 在 Cursor 中編輯
```bash
# 在新視窗開啟專案資料夾
code SignalAir-iOS/
```

## 雙編輯器工作流程

### Xcode（預覽和測試）
- 開啟 `SignalAir Rescue.xcodeproj`
- 選擇模擬器或實體裝置
- 按 `Cmd+R` 執行應用程式
- 使用 SwiftUI 預覽功能

### Cursor（程式碼編輯）
- 開啟 `SignalAir-iOS/` 資料夾
- 編輯任何 `.swift` 檔案
- 修改會自動同步到 Xcode

## 功能特色

### ✅ 已完成功能
- **緊急訊號系統**：4 種訊號類型（安全/物資/醫療/危險）
- **即時聊天室**：24 小時自動清除訊息
- **設定頁面**：語言切換、購買管理
- **法律頁面**：隱私政策、服務條款、使用說明
- **內購系統**：3 階段付費方案（咖啡/賓果/完整版）

### 🚧 Phase 2 待實作
- **賓果遊戲**：多人連線遊戲室
- **MultipeerConnectivity**：P2P 裝置通訊
- **實際內購**：StoreKit 2 整合

## 技術規格

- **目標版本**：iOS 15.0+
- **程式語言**：Swift 5.9
- **UI 框架**：SwiftUI
- **架構**：MVVM
- **裝置支援**：iPhone / iPad

## 故障排除

### 如果 Python 腳本失敗
```bash
# 手動安裝 xcodegen（選用）
brew install xcodegen

# 重新執行
./create_xcode_project.sh
```

### 如果無法開啟專案
1. 確認 Xcode 已安裝並為最新版本
2. 檢查檔案權限：`ls -la SignalAir-iOS/`
3. 手動開啟：`open SignalAir-iOS/SignalAir Rescue.xcodeproj`

## 專案亮點

- 🎨 **UI 設計**：完全符合原 React 應用程式的顏色和布局
- 🔐 **安全性**：本地資料儲存，無外部伺服器
- 💰 **商業模式**：完整的內購系統設計
- 🌐 **國際化**：中英文語言切換
- 📱 **原生體驗**：100% SwiftUI 實作

---

**執行 `./create_xcode_project.sh` 開始使用！** 🚀 