#!/bin/bash

echo "⚖️ Creating legal and purchase files..."

# === LEGAL PAGES ===

# PrivacyPolicyView.swift
cat > "SignalAir/Features/Legal/PrivacyPolicyView.swift" << 'EOF'
import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隱私權政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最後更新：2024年1月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        PolicySection(
                            title: "資料收集",
                            content: "SignalAir 會收集以下資料：\n• 裝置名稱（用於識別訊號來源）\n• 位置資訊（僅限計算距離和方向）\n• 使用統計（改善應用程式體驗）"
                        )
                        
                        PolicySection(
                            title: "資料使用",
                            content: "我們收集的資料僅用於：\n• 提供緊急通訊服務\n• 顯示訊號距離和方向\n• 改善應用程式功能\n• 提供技術支援"
                        )
                        
                        PolicySection(
                            title: "資料儲存",
                            content: "• 所有通訊資料僅在本地裝置儲存\n• 聊天訊息會在24小時後自動刪除\n• 不會將個人資料傳送至外部伺服器\n• 使用端對端加密保護資料安全"
                        )
                        
                        PolicySection(
                            title: "資料分享",
                            content: "SignalAir 承諾：\n• 絕不販售用戶資料\n• 不與第三方分享個人資訊\n• 僅在法律要求時提供必要資料\n• 匿名統計資料可能用於改善服務"
                        )
                        
                        PolicySection(
                            title: "用戶權利",
                            content: "您有權：\n• 隨時刪除應用程式及其資料\n• 要求查看收集的資料\n• 關閉位置服務（但會影響功能）\n• 聯繫我們處理隱私相關問題"
                        )
                        
                        PolicySection(
                            title: "聯繫方式",
                            content: "如有隱私權相關問題，請透過以下方式聯繫：\n• Email: privacy@signalair.com\n• 應用程式內回報功能"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("隱私權政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
EOF

# TermsOfServiceView.swift
cat > "SignalAir/Features/Legal/TermsOfServiceView.swift" << 'EOF'
import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("服務條款")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最後更新：2024年1月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        TermsSection(
                            title: "服務說明",
                            content: "SignalAir 提供緊急情況下的通訊服務，包括：\n• 緊急訊號發送\n• 附近裝置通訊\n• 聊天室功能\n• 娛樂遊戲功能"
                        )
                        
                        TermsSection(
                            title: "使用限制",
                            content: "使用本服務時，您同意：\n• 不濫用緊急訊號功能\n• 不發送違法或不當內容\n• 尊重其他使用者\n• 遵守當地法律法規"
                        )
                        
                        WarningSection(
                            title: "免責聲明",
                            content: "• SignalAir 無法保證在所有情況下都能正常運作\n• 不應完全依賴本應用程式進行緊急救援\n• 建議同時使用官方緊急救援系統\n• 使用者需自行承擔使用風險"
                        )
                        
                        WarningSection(
                            title: "技術限制",
                            content: "本服務可能受以下因素影響：\n• 裝置電量不足\n• 網路連線品質\n• 系統相容性問題\n• 硬體故障"
                        )
                        
                        TermsSection(
                            title: "購買條款",
                            content: "付費功能說明：\n• 所有購買均為一次性付費\n• 付費後即可使用對應功能\n• 退款政策依照 App Store 規定\n• 功能可能因技術原因暫時無法使用"
                        )
                        
                        TermsSection(
                            title: "服務變更",
                            content: "我們保留權利：\n• 隨時修改或終止服務\n• 更新應用程式功能\n• 修改服務條款\n• 在必要時暫停服務"
                        )
                        
                        TermsSection(
                            title: "聯繫方式",
                            content: "如有服務相關問題，請聯繫：\n• Email: support@signalair.com\n• 應用程式內客服功能"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("服務條款")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WarningSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
EOF

# HelpView.swift
cat > "SignalAir/Features/Legal/HelpView.swift" << 'EOF'
import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用說明")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        HelpSection(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "緊急訊號",
                            content: "快速發送求救訊號：\n• 藍色「我安全」- 告知他人您的安全狀況\n• 紫色「需要物資」- 請求食物、水或其他物資\n• 紅色「需要醫療」- 緊急醫療協助\n• 黃色「危險警告」- 警告他人周遭危險"
                        )
                        
                        HelpSection(
                            icon: "message",
                            title: "聊天室功能",
                            content: "與附近使用者溝通：\n• 輸入文字訊息並發送\n• 查看其他人的訊息\n• 訊息會在24小時後自動刪除\n• 支援最多50條訊息記錄"
                        )
                        
                        HelpSection(
                            icon: "gamecontroller",
                            title: "賓果遊戲",
                            content: "多人連線娛樂功能：\n• 需要付費解鎖\n• 3個遊戲房間可選擇\n• 與其他玩家即時互動\n• 自動產生隨機賓果卡"
                        )
                        
                        HelpSection(
                            icon: "gear",
                            title: "設定選項",
                            content: "個人化設定：\n• 切換語言（中文/English）\n• 查看訂購狀態\n• 升級到付費版本\n• 恢復之前的購買"
                        )
                        
                        HelpSection(
                            icon: "location",
                            title: "位置資訊",
                            content: "距離與方向顯示：\n• 自動計算與訊號源的距離\n• 顯示相對方向（北、東南等）\n• 僅用於改善使用體驗\n• 可在設定中關閉位置服務"
                        )
                        
                        HelpSection(
                            icon: "exclamationmark.triangle",
                            title: "注意事項",
                            content: "使用時請注意：\n• 確保裝置有足夠電量\n• 在真正緊急情況下，請同時聯繫官方救援單位\n• 不要濫用緊急訊號功能\n• 保持裝置在通訊範圍內"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("使用說明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
EOF

# === PURCHASE OPTIONS ===

# PurchaseOptionsView.swift
cat > "SignalAir/Features/Settings/PurchaseOptionsView.swift" << 'EOF'
import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseService.PurchaseTier?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(PurchaseService.PurchaseTier.allCases, id: \.self) { tier in
                            PurchaseCardView(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: { selectedTier = tier }
                            )
                        }
                    }
                    .padding()
                }
                
                purchaseButton
            }
            .navigationTitle("升級選項")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") { dismiss() }
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("解鎖完整功能")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("選擇最適合您的方案")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            if let selectedTier = selectedTier {
                Button(action: {
                    Task {
                        await purchaseService.purchase(selectedTier)
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("購買 \(selectedTier.displayName)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(purchaseService.isLoading)
            }
            
            Button(action: {
                Task {
                    await purchaseService.restorePurchases()
                }
            }) {
                Text("恢復購買")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .disabled(purchaseService.isLoading)
        }
        .padding()
    }
}

struct PurchaseCardView: View {
    let tier: PurchaseService.PurchaseTier
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(tier.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            Text(tier.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if tier == .fullVersion {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("推薦方案")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            onSelect()
        }
    }
}
EOF

echo "✅ Legal and purchase files created" 