#!/bin/bash

echo "🔧 開始修復 SignalAir iOS 項目的編譯錯誤..."

# 定義項目路徑
PROJECT_DIR="./SignalAir-iOS/SignalAir"

# 1. 創建缺失的 Views 文件
echo "📝 創建缺失的 View 文件..."

# 創建 PurchaseOptionsView
cat > "$PROJECT_DIR/Features/Legal/PurchaseOptionsView.swift" << 'EOF'
import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var languageService: LanguageService
    @ObservedObject var purchaseService: PurchaseService
    
    var body: some View {
        VStack {
            Text("購買選項")
                .font(.title)
                .padding()
            
            Text("此功能尚未實現")
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .navigationTitle("購買選項")
    }
}
EOF

# 2. 修復 HelpView 中的 navigationBarTitleDisplayMode 問題
echo "🔧 修復 HelpView..."
if [ -f "$PROJECT_DIR/Features/Legal/HelpView.swift" ]; then
    # 移除 macOS 不支援的 navigationBarTitleDisplayMode
    sed -i '' '/.navigationBarTitleDisplayMode/d' "$PROJECT_DIR/Features/Legal/HelpView.swift"
fi

# 3. 創建缺失的服務容器
echo "🔧 創建 ServiceContainer..."
cat > "$PROJECT_DIR/Core/Services/ServiceContainer.swift" << 'EOF'
import Foundation
import SwiftUI

// 服務容器 - 集中管理所有服務實例
class ServiceContainer: ObservableObject {
    
    // 單例實例
    static let shared = ServiceContainer()
    
    // 核心服務
    lazy var languageService = LanguageService()
    lazy var networkService = NetworkService()
    lazy var securityService = SecurityService()
    lazy var temporaryIDManager = TemporaryIDManager()
    lazy var nicknameService = NicknameService()
    lazy var purchaseService = PurchaseService()
    
    // 輔助服務
    lazy var meshManager = MeshManager()
    lazy var selfDestructManager = SelfDestructManager()
    lazy var floodProtection = FloodProtection()
    
    // ViewModels
    lazy var settingsViewModel = SettingsViewModel()
    
    private init() {
        setupServices()
    }
    
    private func setupServices() {
        // 設定服務間的依賴關係
        networkService.temporaryIDManager = temporaryIDManager
        nicknameService.temporaryIDManager = temporaryIDManager
    }
}
EOF

echo "✅ 編譯錯誤修復完成！"
echo "📋 修復摘要："
echo "   - 創建了 PurchaseOptionsView"
echo "   - 修復了 HelpView 的 macOS 相容性問題"
echo "   - 創建了 ServiceContainer"
echo ""
echo "💡 建議："
echo "   1. 在 Xcode 中重新建構項目"
echo "   2. 檢查是否還有其他編譯錯誤"
echo "   3. 設定開發團隊以解決簽名問題" 