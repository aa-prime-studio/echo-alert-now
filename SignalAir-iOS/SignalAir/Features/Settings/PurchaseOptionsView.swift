import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseService.PurchaseTier = .vip
    @State private var selectedSubscriptionType: PurchaseService.SubscriptionType = .yearly
    @State private var showPurchaseConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題區域
                    VStack(spacing: 16) {
                        // 關閉按鈕
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 10)
                        
                        // 主要圖示
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        
                        Text(languageService.t("unlock_full_features"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text(languageService.t("choose_best_plan"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // 訂閱類型選擇器
                    subscriptionTypeSelector
                    
                    // 方案選項
                    planOptions
                    
                    // 購買按鈕（選中方案後顯示）
                    if !purchaseService.purchasedTiers.contains(selectedTier.rawValue) {
                        purchaseButton
                    }
                    
                    // 功能列表
                    featuresSection
                    
                    // 說明文字
                    disclaimerText
                    
                    // 恢復購買按鈕
                    restoreButton
                    
                    // 錯誤訊息
                    if let errorMessage = purchaseService.errorMessage {
                        errorSection(errorMessage)
                    }
                    
                    #if DEBUG
                    debugButton
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    // MARK: - UI Components
    
    private var subscriptionTypeSelector: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                // 月費按鈕
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSubscriptionType = .monthly
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(languageService.t("monthly"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(languageService.t("monthly_billing"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(selectedSubscriptionType == .monthly ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedSubscriptionType == .monthly ? Color.blue : Color.clear
                    )
                }
                
                // 年費按鈕
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSubscriptionType = .yearly
                    }
                }) {
                    VStack(spacing: 4) {
                        HStack {
                            Text(languageService.t("yearly"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("15% OFF")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Text(languageService.t("yearly_billing"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(selectedSubscriptionType == .yearly ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedSubscriptionType == .yearly ? Color.blue : Color.clear
                    )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
    
    private var planOptions: some View {
        VStack(spacing: 16) {
            ForEach(PurchaseService.PurchaseTier.allCases, id: \.self) { tier in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTier = tier
                    }
                }) {
                    VStack(spacing: 0) {
                        // 方案資訊
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                // 選擇圓點指示器
                                Image(systemName: getCircleIcon(for: tier))
                                    .foregroundColor(getCircleColor(for: tier))
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tier.displayName(language: PurchaseService.convertLanguage(languageService.currentLanguage)))
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                
                                Spacer()
                                
                                Text(tier.priceForType(selectedSubscriptionType))
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                            }
                            
                            Text(tier.description(language: PurchaseService.convertLanguage(languageService.currentLanguage)))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                        }
                        .padding()
                    }
                }
                .disabled(purchaseService.isLoading)
                .background(getCardBackground(for: tier))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getCardBorderColor(for: tier), lineWidth: getCardBorderWidth(for: tier))
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var purchaseButton: some View {
        VStack(spacing: 16) {
            // 購買按鈕
            Button(action: {
                Task {
                    await purchaseService.purchase(selectedTier)
                    if purchaseService.errorMessage == nil && purchaseService.purchasedTiers.contains(selectedTier.rawValue) {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if purchaseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(purchaseService.isLoading ? languageService.t("processing") : languageService.t("purchase_now"))
                        .font(.system(size: 16, weight: .medium))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.0, green: 0.843, blue: 0.416))
                .cornerRadius(12)
            }
            .disabled(purchaseService.isLoading)
        }
        .padding(.horizontal)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedTier.displayName(language: PurchaseService.convertLanguage(languageService.currentLanguage))) 功能")
                .font(.system(size: 16, weight: .medium))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(getFeaturesForTier(selectedTier), id: \.title) { feature in
                    FeatureRow(icon: feature.icon, title: feature.title, description: feature.description)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var disclaimerText: some View {
        VStack(spacing: 8) {
            Text("• 訂閱將在當前期間結束時自動續費")
            Text("• 可隨時在設定中取消訂閱")
            Text("• 付款將在確認購買時從您的Apple ID帳戶收取")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    
    
    private var restoreButton: some View {
        Button(action: {
            Task {
                await purchaseService.restorePurchases()
            }
        }) {
            if purchaseService.isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.6)
                    Text(languageService.t("restore_purchases"))
                }
                .font(.caption)
                .foregroundColor(.gray)
            } else {
                Text(languageService.t("restore_purchases"))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .disabled(purchaseService.isLoading)
    }
    
    private func errorSection(_ errorMessage: String) -> some View {
        VStack(spacing: 8) {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await purchaseService.reloadProducts()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(languageService.t("retry_loading"))
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(purchaseService.isLoading)
        }
        .padding(.horizontal)
    }
    
    #if DEBUG
    private var debugButton: some View {
        Button(action: {
            purchaseService.unlockForTesting(.vip)
            dismiss()
        }) {
            Text(languageService.t("test_unlock_dev"))
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }
    #endif
    
    // MARK: - Feature Management
    
    private struct Feature {
        let icon: String
        let title: String
        let description: String
    }
    
    /// 根據方案等級取得對應功能
    private func getFeaturesForTier(_ tier: PurchaseService.PurchaseTier) -> [Feature] {
        switch tier {
        case .basicVIP:
            return [
                Feature(icon: "message.fill", title: "無限聊天", description: "不受每日50則訊息限制"),
                Feature(icon: "shield.fill", title: "基礎會員", description: "享受基本進階功能")
            ]
        case .vip:
            return [
                Feature(icon: "message.fill", title: "無限聊天", description: "不受每日訊息限制"),
                Feature(icon: "gamecontroller.fill", title: "賓果遊戲室", description: "多人對戰，即時聊天"),
                Feature(icon: "trophy.fill", title: "排行榜系統", description: "追蹤遊戲成就")
            ]
        case .vvip:
            return [
                Feature(icon: "message.fill", title: "無限聊天", description: "不受每日訊息限制"),
                Feature(icon: "gamecontroller.fill", title: "賓果遊戲室", description: "多人對戰，即時聊天"),
                Feature(icon: "trophy.fill", title: "排行榜系統", description: "追蹤遊戲成就"),
                Feature(icon: "globe", title: "多語言支援", description: "贊助未來語言包開發"),
                Feature(icon: "star.fill", title: "全功能解鎖", description: "享受所有進階功能")
            ]
        }
    }
    
    // MARK: - UI Helper Methods
    
    /// 取得圓點圖示
    private func getCircleIcon(for tier: PurchaseService.PurchaseTier) -> String {
        if purchaseService.purchasedTiers.contains(tier.rawValue) {
            return "checkmark.circle.fill"
        } else if selectedTier == tier {
            return "circle.fill"
        } else {
            return "circle"
        }
    }
    
    /// 取得圓點顏色
    private func getCircleColor(for tier: PurchaseService.PurchaseTier) -> Color {
        if purchaseService.purchasedTiers.contains(tier.rawValue) {
            return Color(red: 0.0, green: 0.843, blue: 0.416)
        } else if selectedTier == tier {
            return Color(red: 0.0, green: 0.843, blue: 0.416)
        } else {
            return .gray
        }
    }
    
    /// 取得卡片背景
    private func getCardBackground(for tier: PurchaseService.PurchaseTier) -> Color {
        if selectedTier == tier && !purchaseService.purchasedTiers.contains(tier.rawValue) {
            return Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.05)
        } else {
            return Color.white
        }
    }
    
    /// 取得卡片邊框顏色
    private func getCardBorderColor(for tier: PurchaseService.PurchaseTier) -> Color {
        if purchaseService.purchasedTiers.contains(tier.rawValue) {
            return Color(red: 0.0, green: 0.843, blue: 0.416)
        } else if selectedTier == tier {
            return Color(red: 0.0, green: 0.843, blue: 0.416)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    /// 取得卡片邊框寬度
    private func getCardBorderWidth(for tier: PurchaseService.PurchaseTier) -> CGFloat {
        if purchaseService.purchasedTiers.contains(tier.rawValue) || selectedTier == tier {
            return 2
        } else {
            return 1
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                .frame(width: 32, height: 32)
                .background(Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
