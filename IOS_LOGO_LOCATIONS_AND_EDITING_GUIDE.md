# 📱 SignalAir iOS Logo 檔案位置與微調指南

## 📍 Logo 檔案位置

### 🎯 主要位置：

#### 1. **原始檔案存放處**
```
SignalAir-iOS/SignalAir/Assets/logo/
```
**說明：** 這是您的原始 logo 檔案存放位置，包含所有 18 個不同尺寸的 PNG 檔案。

#### 2. **Xcode 專案使用的檔案**
```
SignalAir-iOS/SignalAir/Assets.xcassets/AppIcon.appiconset/
```
**說明：** 這是 Xcode 實際編譯使用的檔案，與 `Contents.json` 配置檔案一起使用。

## 🎨 Logo 微調步驟

### 方法 1：替換單個檔案
如果您只想修改特定尺寸的圖標：

```bash
# 例如：替換 120x120 的圖標
cp 您的新logo檔案.png SignalAir-iOS/SignalAir/Assets/logo/logo_120x120.png
cp 您的新logo檔案.png SignalAir-iOS/SignalAir/Assets.xcassets/AppIcon.appiconset/logo_120x120.png
```

### 方法 2：批量更新所有尺寸
如果您有新的設計，想要更新所有尺寸：

1. **準備您的主要 Logo 檔案**（建議 1024x1024 高解析度）

2. **使用 sips 工具生成所有尺寸：**
```bash
# 設定來源檔案
SOURCE_LOGO="您的新logo檔案.png"

# 生成所有需要的尺寸
sips -z 20 20 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_20x20.png
sips -z 29 29 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_29x29.png
sips -z 40 40 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_40x40.png
sips -z 48 48 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_48x48.png
sips -z 58 58 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_58x58.png
sips -z 60 60 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_60x60.png
sips -z 76 76 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_76x76.png
sips -z 80 80 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_80x80.png
sips -z 86 86 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_86x86.png
sips -z 87 87 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_87x87.png
sips -z 120 120 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_120x120.png
sips -z 152 152 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_152x152.png
sips -z 167 167 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_167x167.png
sips -z 172 172 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_172x172.png
sips -z 180 180 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_180x180.png
sips -z 256 256 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_256x256.png
sips -z 512 512 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_512x512.png
sips -z 1024 1024 "$SOURCE_LOGO" --out SignalAir-iOS/SignalAir/Assets/logo/logo_1024x1024.png

# 複製到 Assets.xcassets
cp SignalAir-iOS/SignalAir/Assets/logo/*.png SignalAir-iOS/SignalAir/Assets.xcassets/AppIcon.appiconset/
```

## 🔄 更新後的建置步驟

修改 logo 檔案後，需要執行以下步驟：

```bash
# 1. 進入專案目錄
cd SignalAir-iOS

# 2. Clean Build
xcodebuild -project "SignalAir Rescue.xcodeproj" -scheme "SignalAir" clean

# 3. 重新建置
xcodebuild -project "SignalAir Rescue.xcodeproj" -scheme "SignalAir" -destination "platform=iOS Simulator,name=iPhone 16 Pro" build

# 4. 卸載並重新安裝（替換模擬器 ID）
xcrun simctl uninstall "您的模擬器ID" "com.signalair.app"
xcrun simctl install "您的模擬器ID" "應用包路徑"

# 5. 重啟模擬器刷新圖標快取
xcrun simctl shutdown "您的模擬器ID"
xcrun simctl boot "您的模擬器ID"
```

## 📐 iOS App Icon 尺寸需求

### iPhone 應用程式圖標：
- **20pt:** 20x20 (@1x), 40x40 (@2x), 60x60 (@3x)
- **29pt:** 29x29 (@1x), 58x58 (@2x), 87x87 (@3x)
- **40pt:** 40x40 (@1x), 80x80 (@2x), 120x120 (@3x)
- **60pt:** 120x120 (@2x), 180x180 (@3x)

### iPad 應用程式圖標：
- **20pt:** 20x20 (@1x), 40x40 (@2x)
- **29pt:** 29x29 (@1x), 58x58 (@2x)
- **40pt:** 40x40 (@1x), 80x80 (@2x)
- **76pt:** 76x76 (@1x), 152x152 (@2x)
- **83.5pt:** 167x167 (@2x)

### App Store：
- **1024pt:** 1024x1024 (@1x)

## 🎨 設計建議

### Logo 設計要點：
1. **簡潔明瞭：** 在小尺寸下仍然清晰可見
2. **對比度高：** 確保在各種背景下都能清楚顯示
3. **無透明背景：** iOS 會自動添加圓角和陰影
4. **避免細線：** 在小尺寸下可能會模糊
5. **測試各種尺寸：** 確保在所有尺寸下都看起來良好

### 推薦工具：
- **Sketch** - 向量設計
- **Figma** - 線上設計
- **Photoshop** - 點陣圖編輯
- **sips** - macOS 內建圖片處理工具

## 🚀 快速更新指令

如果您已經有新的 logo 檔案，可以使用以下快速更新指令：

```bash
# 設定新 logo 檔案路徑
NEW_LOGO="路徑/到/您的新logo.png"

# 一鍵更新所有尺寸並重新建置
./update_logo.sh "$NEW_LOGO"
```

（需要先創建 update_logo.sh 腳本）

## 📝 注意事項

1. **備份原始檔案：** 修改前建議備份現有的 logo 檔案
2. **格式要求：** 必須是 PNG 格式
3. **命名規則：** 保持 `logo_尺寸x尺寸.png` 的命名格式
4. **品質要求：** 使用高品質的原始圖像來縮放
5. **測試：** 在多個裝置和模擬器上測試顯示效果

現在您知道所有 logo 檔案的位置了！您可以修改任何您想要調整的尺寸，然後按照上述步驟重新建置應用程式。 