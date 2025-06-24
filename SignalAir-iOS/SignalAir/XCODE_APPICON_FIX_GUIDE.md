# 🔧 Xcode App Icon 顯示修正指南

## 📋 當前狀況
✅ 已清理重複的 Assets 目錄
✅ Assets.xcassets 結構完整 (18個圖檔)
✅ Contents.json 配置正確
✅ Info.plist 已更新

## 🎯 Xcode 設定步驟

### 步驟 1: 移除舊的 Assets 引用
1. 在 Xcode 中打開 SignalAir Rescue.xcodeproj
2. 在左側導航器中找到任何舊的 Assets 引用
3. 右鍵點擊 → 選擇 "Delete" → 選擇 "Remove Reference"

### 步驟 2: 重新添加正確的 Assets.xcassets
1. 右鍵點擊 "SignalAir" 資料夾
2. 選擇 "Add Files to 'SignalAir'..."
3. 瀏覽到 SignalAir 資料夾
4. 選擇 "Assets.xcassets" 資料夾
5. **重要**: 取消勾選 "Copy items if needed"
6. 確保勾選 Target "SignalAir"
7. 點擊 "Add"

### 步驟 3: 檢查 Target 設定
1. 選擇最上層的專案名稱
2. 選擇 Target "SignalAir"
3. 點擊 "General" 標籤頁
4. 在 "App Icons and Launch Screen" 區域
5. 確保 "App Icon Source" 顯示 "AppIcon"
6. 應該能看到所有尺寸的圖標預覽

### 步驟 4: 清理建置
1. 按 Cmd+Shift+K (Clean Build)
2. 按 Cmd+Option+Shift+K (Clean Build Folder)
3. 關閉模擬器

### 步驟 5: 重新建置測試
1. 按 Cmd+R (Run)
2. 等待 App 安裝到模擬器
3. 檢查主畫面圖標

## 🚨 故障排除

### 如果圖標仍未顯示:
1. **重置模擬器**:
   - 模擬器選單 → Device → Erase All Content and Settings
   - 重新運行 App

2. **檢查圖檔**:
   - 在 Xcode 中點擊 Assets.xcassets/AppIcon
   - 確保所有方格都有圖片預覽
   - 檢查是否有黃色警告圖示

3. **檢查建置設定**:
   - Target → Build Settings
   - 搜尋 "ASSETCATALOG_COMPILER_APPICON_NAME"
   - 確保值為 "AppIcon"

## 📱 預期結果
- Xcode 中 AppIcon 應顯示所有尺寸預覽
- 模擬器主畫面應顯示 App 圖標
- 無黃色警告圖示
