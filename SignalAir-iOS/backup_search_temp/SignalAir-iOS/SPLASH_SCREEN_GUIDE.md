# 🎬 獨立啟動畫面實作指南

## 📱 系統概述

這是一個完全獨立的啟動動畫系統，**不會影響任何現有的 Signal 頁面和後端連結**。

### ✨ 動畫效果
1. **藍色背景** (#283EE4) 全螢幕覆蓋
2. **中央閃電 logo** 閃爍 3 次 (白色)
3. **網格載入動畫** 從上往下依序出現 (5x8 網格)
4. **平滑過渡** 到主應用程式

## 📁 檔案結構

```
SignalAir-iOS/SignalAir/SplashScreen/
├── SplashScreenView.swift      # 主要啟動畫面視圖
├── AppContainerView.swift      # 應用程式容器 (管理切換)
└── SplashTestView.swift        # 測試演示視圖
```

## 🛠 實作方式

### 1. 完全獨立設計
- 所有啟動動畫代碼都在獨立的 `SplashScreen` 目錄中
- 不修改任何現有的 Signal 相關檔案
- 使用容器視圖 (`AppContainerView`) 來包裝整個應用程式

### 2. 最小化修改
只修改了一個檔案：`SignalAirApp.swift`
```swift
// 之前
ContentView()

// 現在  
AppContainerView() // 包含啟動畫面 + 原始 ContentView
```

## 🎯 動畫時序

| 時間 | 動作 |
|------|------|
| 0.0s | 啟動畫面出現，藍色背景 |
| 0.0s | 中央 logo 開始閃爍 |
| 1.8s | 閃爍 3 次完成，logo 消失 |
| 2.1s | 網格動畫開始，從上往下出現 |
| 5.1s | 網格動畫完成 |
| 5.6s | 淡出過渡到主應用程式 |

## 🔧 使用方法

### 方法 1：正常啟動 (推薦)
應用程式啟動時會自動播放啟動動畫，然後進入主程式。

### 方法 2：測試模式
使用 `SplashTestView` 來測試和演示：
```swift
// 在任何地方使用
SplashTestView()
```

## ⚙️ 自訂設定

### 修改動畫時間
在 `SplashScreenView.swift` 中：
```swift
// 閃爍間隔
Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true)

// 網格動畫延遲 (每行)
let delayPerRow: Double = 0.3

// 總動畫時長
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0)
```

### 修改網格大小
```swift
private let gridColumns = 5        // 列數
private let gridRows = 8           // 行數  
private let logoSize: CGFloat = 40 // logo 大小
private let spacing: CGFloat = 20  // 間距
```

### 修改背景顏色
```swift
// 當前：藍色 #283EE4
Color(red: 40/255, green: 62/255, blue: 228/255)

// 自訂顏色
Color(red: yourR/255, green: yourG/255, blue: yourB/255)
```

## 🚀 整合步驟

### 1. 檔案已創建
所有必要檔案都已在正確位置創建。

### 2. 在 Xcode 中添加
1. 打開 Xcode 專案
2. 右鍵點擊專案導航器
3. 選擇 "Add Files to Project"
4. 選擇 `SplashScreen` 資料夾
5. 確保所有檔案都添加到正確的 Target

### 3. 確認 loading.png
確保 `loading.png` 圖片已在 `Assets.xcassets/loading.imageset/` 中。

### 4. 建置並測試
```bash
# 在 Xcode 中按 Cmd+R 運行
# 或使用命令行
xcodebuild -project "SignalAir Rescue.xcodeproj" -scheme "SignalAir" -destination "platform=iOS Simulator,name=iPhone 16 Pro" run
```

## 🔄 復原方法

如果需要移除啟動畫面，只需復原 `SignalAirApp.swift`：
```swift
@main
struct SignalAirApp: App {
    @StateObject private var serviceContainer = ServiceContainer()
    @StateObject private var languageService = LanguageService()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var nicknameService = NicknameService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .environmentObject(languageService)
                .environmentObject(purchaseService)
                .environmentObject(nicknameService)
                .onAppear {
                    configureStoreKit()
                }
        }
    }
    
    private func configureStoreKit() {
        print("SignalAir Rescue App Started - StoreKit Ready")
    }
}
```

## ✅ 安全保證

- ✅ **不影響現有 Signal 功能**
- ✅ **不修改後端連結**
- ✅ **不改變原有服務架構**
- ✅ **可以輕易移除或停用**
- ✅ **完全獨立的代碼模組**

## 🐛 故障排除

### Q: loading.png 不顯示
A: 確認圖片名稱在 Assets 中為 "loading"

### Q: 動畫卡住不消失
A: 檢查 `isPresented` 綁定是否正確

### Q: 編譯錯誤
A: 確認所有檔案都已添加到 Xcode 專案中

### Q: 想要禁用啟動畫面
A: 在 `AppContainerView.swift` 中設置 `showSplashScreen = false`

## 📱 設備支援

- ✅ iPhone (所有尺寸)
- ✅ iPad (所有尺寸)  
- ✅ 橫屏/直屏自動適配
- ✅ iOS 16.0+ 支援
- ✅ Dark/Light Mode 相容
