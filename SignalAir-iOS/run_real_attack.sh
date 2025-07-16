#!/bin/bash

echo "🚀 SignalAir 真實設備攻擊器"
echo "================================="
echo ""

# 確保在正確的目錄中
cd "$(dirname "$0")"

# 檢查檔案是否存在
if [ ! -f "RealDeviceAttacker.swift" ]; then
    echo "❌ 找不到 RealDeviceAttacker.swift 檔案"
    exit 1
fi

echo "📍 當前目錄: $(pwd)"
echo ""

# 重要提醒
echo "⚠️  重要提醒："
echo "================================="
echo "1. 請確保兩台設備都在運行 SignalAir"
echo "2. 設備必須在同一個 Wi-Fi 網路"
echo "3. 藍牙必須開啟"
echo "4. 此工具僅用於測試自己的設備"
echo ""

echo "🎯 這個攻擊器將會："
echo "- 搜索並連接到您的 SignalAir 設備"
echo "- 執行 5 種不同的攻擊類型"
echo "- 測試您的安全系統是否正常運作"
echo "- 生成詳細的攻擊報告"
echo ""

echo "按 Enter 開始真實攻擊..."
read

echo "🔥 正在啟動攻擊器..."
echo ""

# 運行真實攻擊器
swift RealDeviceAttacker.swift

echo ""
echo "✅ 攻擊測試完成！"
echo "📊 請查看上方的詳細報告"
echo ""