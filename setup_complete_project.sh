#!/bin/bash

# SignalAir iOS 專案完整建立腳本
# 此腳本會按順序執行所有需要的腳本來建立完整的 Xcode 專案

set -e  # 遇到錯誤時停止執行

echo "🚀 開始建立 SignalAir iOS 完整專案..."
echo ""

# 檢查必要檔案是否存在
required_scripts=(
    "create_xcode_project.sh"
    "create_app_files.sh" 
    "create_model_files.sh"
    "create_service_files.sh"
    "create_feature_files.sh"
    "create_legal_purchase_files.sh"
    "create_remaining_features.sh"
)

echo "📋 檢查必要腳本檔案..."
for script in "${required_scripts[@]}"; do
    if [ ! -f "$script" ]; then
        echo "❌ 錯誤：找不到 $script"
        exit 1
    fi
    echo "✅ 找到 $script"
done
echo ""

# 給所有腳本執行權限
echo "🔧 設定腳本執行權限..."
for script in "${required_scripts[@]}"; do
    chmod +x "$script"
done
echo "✅ 權限設定完成"
echo ""

# 清理舊專案（如果存在）
if [ -d "SignalAir-iOS" ]; then
    echo "🗑️  清理舊專案資料夾..."
    rm -rf SignalAir-iOS
    echo "✅ 清理完成"
    echo ""
fi

# 步驟 1: 建立基本專案結構和 Xcode 專案檔案
echo "📁 步驟 1/7: 建立基本專案結構..."
./create_xcode_project.sh
echo "✅ 專案結構建立完成"
echo ""

# 步驟 2: 建立應用程式核心檔案
echo "📱 步驟 2/7: 建立應用程式核心檔案..."
./create_app_files.sh
echo "✅ 應用程式檔案建立完成"
echo ""

# 步驟 3: 建立資料模型檔案
echo "📊 步驟 3/7: 建立資料模型檔案..."
./create_model_files.sh
echo "✅ 模型檔案建立完成"
echo ""

# 步驟 4: 建立服務層檔案
echo "⚙️  步驟 4/7: 建立服務層檔案..."
./create_service_files.sh
echo "✅ 服務檔案建立完成"
echo ""

# 步驟 5: 建立功能模組檔案
echo "🎯 步驟 5/7: 建立功能模組檔案..."
./create_feature_files.sh
echo "✅ 功能模組檔案建立完成"
echo ""

# 步驟 6: 建立法律頁面和購買相關檔案
echo "📜 步驟 6/7: 建立法律頁面和購買檔案..."
./create_legal_purchase_files.sh
echo "✅ 法律頁面檔案建立完成"
echo ""

# 步驟 7: 建立剩餘功能檔案
echo "🔧 步驟 7/7: 建立剩餘功能檔案..."
./create_remaining_features.sh
echo "✅ 剩餘功能檔案建立完成"
echo ""

# 最終檢查
echo "🔍 最終檢查專案結構..."
if [ -f "SignalAir-iOS/SignalAir Rescue.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode 專案檔案建立成功"
else
    echo "❌ Xcode 專案檔案建立失敗"
    exit 1
fi

if [ -d "SignalAir-iOS/SignalAir" ]; then
    echo "✅ 原始碼資料夾建立成功"
else
    echo "❌ 原始碼資料夾建立失敗"
    exit 1
fi

# 顯示專案統計
echo ""
echo "📊 專案統計："
echo "Swift 檔案數量: $(find SignalAir-iOS/SignalAir -name "*.swift" | wc -l)"
echo "總檔案數量: $(find SignalAir-iOS/SignalAir -type f | wc -l)"
echo ""

# 完成訊息
echo "🎉 SignalAir iOS 專案建立完成！"
echo ""
echo "📖 下一步："
echo "1. 開啟 Xcode：open \"SignalAir-iOS/SignalAir Rescue.xcodeproj\""
echo "2. 開啟 Cursor：code SignalAir-iOS/"
echo "3. 在 Xcode 中選擇模擬器並按 Cmd+R 執行"
echo ""
echo "📂 專案位置：$(pwd)/SignalAir-iOS/"
echo ""
echo "🚀 開始享受 Cursor + Xcode 雙編輯器工作流程！" 