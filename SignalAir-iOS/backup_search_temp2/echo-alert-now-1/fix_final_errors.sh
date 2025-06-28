#!/bin/bash

echo "🔧 修復最後的編譯錯誤..."

PROJECT_DIR="./SignalAir-iOS/SignalAir"

# 1. 檢查類型定義位置
echo "📝 檢查類型定義位置..."
echo "TemporaryIDManager: $(find $PROJECT_DIR -name "*.swift" -exec grep -l "class TemporaryIDManager" {} \;)"
echo "ConnectionStatus: $(find $PROJECT_DIR -name "*.swift" -exec grep -l "enum ConnectionStatus" {} \;)"
echo "NetworkError: $(find $PROJECT_DIR -name "*.swift" -exec grep -l "enum NetworkError" {} \;)"

# 2. 檢查是否所有檔案都在 Xcode target 中
echo "📝 檢查 Xcode 項目檔案引用..."
PBXPROJ_FILE="./SignalAir-iOS/SignalAir Rescue.xcodeproj/project.pbxproj"

echo "SharedTypes.swift: $(grep -c "SharedTypes.swift" "$PBXPROJ_FILE" || echo 0) 次引用"
echo "TemporaryIDManager.swift: $(grep -c "TemporaryIDManager.swift" "$PBXPROJ_FILE" || echo 0) 次引用"
echo "NetworkService.swift: $(grep -c "NetworkService.swift" "$PBXPROJ_FILE" || echo 0) 次引用"

# 3. 嘗試簡單的建構測試
echo "📝 測試建構..."
cd SignalAir-iOS
xcodebuild -project "SignalAir Rescue.xcodeproj" -scheme "SignalAir" -destination "platform=macOS" build CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "(error|Cannot find)" | head -10

echo "✅ 檢查完成！" 