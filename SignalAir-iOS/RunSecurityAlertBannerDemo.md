# 🚀 如何運行 SecurityAlertBannerDemo.swift

## 📋 運行方法

### 方法1：直接在 Xcode 中運行 (推薦)

1. **打開 Xcode**
   ```
   打開 SignalAir Rescue.xcodeproj
   ```

2. **創建新的 SwiftUI 檔案**
   - 右鍵點擊 `SignalAir` 資料夾
   - 選擇 `New File...`
   - 選擇 `SwiftUI View`
   - 命名為 `SecurityAlertBannerDemo`

3. **複製代碼**
   - 將 `SecurityAlertBannerDemo.swift` 的內容複製到新建的檔案中

4. **在 ContentView 中調用**
   ```swift
   // 在您的 ContentView.swift 或主視圖中添加
   struct ContentView: View {
       var body: some View {
           SecurityAlertBannerDemo()
       }
   }
   ```

5. **運行應用**
   - 選擇模擬器或真機
   - 點擊 ▶️ 運行按鈕

### 方法2：作為獨立的 Swift Playground

1. **打開 Xcode**
2. **創建新的 Playground**
   - File → New → Playground
   - 選擇 iOS 平台
   - 命名為 `SecurityAlertBannerDemo`

3. **導入必要的框架**
   ```swift
   import SwiftUI
   import PlaygroundSupport
   ```

4. **複製完整代碼**
   - 將 `SecurityAlertBannerDemo.swift` 的內容複製到 Playground

5. **在 Playground 末尾添加**
   ```swift
   // 在文件末尾添加
   let hostingController = UIHostingController(rootView: SecurityAlertBannerDemo())
   PlaygroundPage.current.liveView = hostingController
   ```

### 方法3：命令行運行 (僅供參考)

```bash
# 導航到項目目錄
cd /Users/mareen2018/Desktop/echo-alert-now-1/SignalAir-iOS

# 嘗試運行 (可能需要調整導入)
swift SecurityAlertBannerDemo.swift
```

## 🎯 推薦的運行方法：Xcode 集成

### 步驟詳解

1. **打開 Xcode 項目**
   ```
   打開 SignalAir Rescue.xcodeproj
   ```

2. **找到適合的位置**
   - 在 `SignalAir/Features/` 下創建新資料夾 `Demo`
   - 或直接在 `SignalAir/` 根目錄下添加

3. **創建 SwiftUI 檔案**
   - 右鍵點擊目標資料夾
   - New File → SwiftUI View
   - 命名：`SecurityAlertBannerDemo`

4. **複製並調整代碼**
   ```swift
   import SwiftUI

   struct SecurityAlertBannerDemo: View {
       // 複製完整的 SecurityAlertBannerDemo 代碼
       // ...
   }

   struct SecurityAlertBannerDemo_Previews: PreviewProvider {
       static var previews: some View {
           SecurityAlertBannerDemo()
       }
   }
   ```

5. **在現有視圖中調用**
   ```swift
   // 例如在 ContentView 中添加一個按鈕
   Button("Demo Security Alerts") {
       // 導航到 SecurityAlertBannerDemo
   }
   ```

6. **使用 Xcode Preview**
   - 在 SecurityAlertBannerDemo.swift 中
   - 點擊右側的 "Resume" 按鈕
   - 在 Preview 中直接測試

## 🔧 可能遇到的問題和解決方案

### 問題1：編譯錯誤
**解決方案**：
- 確保所有必要的 `import` 語句都已添加
- 檢查是否需要調整某些 iOS 版本特定的 API

### 問題2：找不到某些類型
**解決方案**：
- 確保 `SecurityAlertType` 和相關類型已定義
- 可能需要將這些類型移到單獨的檔案中

### 問題3：預覽不工作
**解決方案**：
```swift
// 在 Preview 中使用
struct SecurityAlertBannerDemo_Previews: PreviewProvider {
    static var previews: some View {
        SecurityAlertBannerDemo()
            .previewDevice("iPhone 14")
    }
}
```

## 🎮 測試指南

### 1. 基本功能測試
- 選擇不同的攻擊類型
- 輸入不同的設備名稱
- 觀察警告橫幅的顯示效果

### 2. UI 測試
- 測試在不同設備上的顯示
- 檢查橫屏和豎屏模式
- 驗證動畫效果

### 3. 交互測試
- 點擊 "立即處理" 按鈕
- 點擊 "稍後處理" 按鈕
- 測試自動消失功能

## 📱 快速啟動指令

如果您想快速測試，可以執行以下步驟：

```bash
# 1. 打開 Xcode
open "SignalAir Rescue.xcodeproj"

# 2. 在 Xcode 中創建新的 SwiftUI 檔案
# File → New → File → SwiftUI View → SecurityAlertBannerDemo

# 3. 複製代碼並運行
```

## 🎯 最佳實踐

### 1. 開發環境
- 使用 Xcode 14+ 
- iOS 16.0+ 目標版本
- 真機或模擬器均可

### 2. 測試建議
- 先在模擬器中測試基本功能
- 在真機上測試性能和動畫
- 測試不同的攻擊類型場景

### 3. 自定義調整
- 可以修改警告文字內容
- 調整顏色和圖示
- 改變自動消失時間

## 📝 注意事項

1. **這是演示程式**：主要用於測試和展示功能
2. **獨立運行**：不依賴真實的安全系統
3. **UI 測試**：專注於用戶界面和體驗測試
4. **教育目的**：幫助理解安全警告系統的工作原理

## 🚀 運行確認

運行成功後，您應該看到：
- 一個包含攻擊類型選擇器的界面
- 設備名稱輸入框
- 觸發警告按鈕
- 警告橫幅顯示區域
- 佇列狀態顯示

享受測試您的安全警告系統！🛡️