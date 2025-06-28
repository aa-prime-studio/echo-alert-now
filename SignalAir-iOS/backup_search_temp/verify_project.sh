#!/bin/bash

# SignalAir iOS 專案驗證腳本
# 檢查專案是否正確建立並可以運行

echo "🔍 SignalAir iOS 專案驗證中..."
echo ""

# 檢查專案根目錄
if [ ! -d "SignalAir-iOS" ]; then
    echo "❌ 錯誤：找不到 SignalAir-iOS 專案資料夾"
    echo "💡 請先執行：./setup_complete_project.sh"
    exit 1
fi

# 檢查 Xcode 專案檔案
if [ ! -f "SignalAir-iOS/SignalAir Rescue.xcodeproj/project.pbxproj" ]; then
    echo "❌ 錯誤：找不到 Xcode 專案檔案"
    exit 1
fi
echo "✅ Xcode 專案檔案存在"

# 檢查主要資料夾結構
required_dirs=(
    "SignalAir-iOS/SignalAir/App"
    "SignalAir-iOS/SignalAir/Features"
    "SignalAir-iOS/SignalAir/Services"
    "SignalAir-iOS/SignalAir/Shared/Models"
)

echo ""
echo "📁 檢查資料夾結構..."
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ 錯誤：找不到 $dir"
        exit 1
    fi
    echo "✅ $dir"
done

# 檢查核心檔案
required_files=(
    "SignalAir-iOS/SignalAir/App/SignalAirApp.swift"
    "SignalAir-iOS/SignalAir/App/ContentView.swift"
    "SignalAir-iOS/SignalAir/Services/PurchaseService.swift"
    "SignalAir-iOS/SignalAir/Services/LanguageService.swift"
    "SignalAir-iOS/SignalAir/Shared/Models/SignalModels.swift"
    "SignalAir-iOS/SignalAir/Features/Settings/SettingsView.swift"
    "SignalAir-iOS/SignalAir/Info.plist"
)

echo ""
echo "📄 檢查核心檔案..."
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 錯誤：找不到 $file"
        exit 1
    fi
    echo "✅ $(basename "$file")"
done

# 檢查功能模組
feature_dirs=(
    "SignalAir-iOS/SignalAir/Features/Signal"
    "SignalAir-iOS/SignalAir/Features/Chat"
    "SignalAir-iOS/SignalAir/Features/Game"
    "SignalAir-iOS/SignalAir/Features/Settings"
    "SignalAir-iOS/SignalAir/Features/Legal"
)

echo ""
echo "🎯 檢查功能模組..."
for dir in "${feature_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ 錯誤：找不到 $dir"
        exit 1
    fi
    echo "✅ $(basename "$dir") 模組"
done

# 統計檔案數量
swift_files=$(find SignalAir-iOS/SignalAir -name "*.swift" | wc -l)
total_files=$(find SignalAir-iOS/SignalAir -type f | wc -l)

echo ""
echo "📊 專案統計："
echo "Swift 檔案：$swift_files 個"
echo "總檔案數：$total_files 個"

# 檢查是否有基本的 Swift 語法
echo ""
echo "🔧 檢查 Swift 語法基礎..."

# 檢查 SignalAirApp.swift 是否包含 @main
if grep -q "@main" "SignalAir-iOS/SignalAir/App/SignalAirApp.swift"; then
    echo "✅ App 進入點正確"
else
    echo "❌ App 進入點可能有問題"
fi

# 檢查 ContentView.swift 是否包含 TabView
if grep -q "TabView" "SignalAir-iOS/SignalAir/App/ContentView.swift"; then
    echo "✅ 主介面結構正確"
else
    echo "❌ 主介面結構可能有問題"
fi

# 檢查購買服務是否包含 StoreKit
if grep -q "import StoreKit" "SignalAir-iOS/SignalAir/Services/PurchaseService.swift"; then
    echo "✅ 內購系統已整合"
else
    echo "❌ 內購系統可能有問題"
fi

# 最終結果
echo ""
echo "🎉 專案驗證完成！"
echo ""
echo "📖 下一步："
echo "1. 開啟 Xcode：open \"SignalAir-iOS/SignalAir Rescue.xcodeproj\""
echo "2. 選擇 iPhone 模擬器"
echo "3. 按 Cmd+R 執行應用程式"
echo ""
echo "💡 提示："
echo "- 如果編譯失敗，請檢查 Xcode 版本是否為最新"
echo "- 首次執行可能需要等待 Swift Package 下載"
echo "- 使用 Cursor 編輯 .swift 檔案時，Xcode 會自動更新"
echo ""
echo "🚀 準備就緒！開始開發吧！" 