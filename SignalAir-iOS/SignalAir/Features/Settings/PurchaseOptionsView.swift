import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseService.PurchaseTier = .vip
    @State private var selectedSubscriptionType: PurchaseService.SubscriptionType = .yearly
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題和關閉按鈕
                headerSection
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 主要標題
                        titleSection
                        
                        // 訂閱週期選擇器（月費/年費）
                        billingCycleSelector
                        
                        // 方案卡片
                        planCards
                        
                        // 功能特色
                        featuresSection
                        
                        // 底部說明文字
                        disclaimerSection
                        
                        Spacer(minLength: 120) // 為底部按鈕留空間
                    }
                    .padding(.horizontal, 16)
                }
                
                // 底部購買按鈕區域
                bottomActionSection
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(languageService.t("upgrade_options"))
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // 平衡佈局的透明按鈕
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.clear)
            }
            .disabled(true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            // 主圖示
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.843, blue: 0.416),
                                Color(red: 0.0, green: 0.7, blue: 0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("升級到 Premium")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("解鎖完整功能，享受最佳體驗")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 16)
    }
    
    private var billingCycleSelector: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                // 月費選項
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSubscriptionType = .monthly
                    }
                }) {
                    Text("月付")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedSubscriptionType == .monthly ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedSubscriptionType == .monthly ? 
                            Color.primary : Color.clear
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                                .path(in: CGRect(x: 0, y: 0, width: 100, height: 44))
                        )
                }
                
                // 年費選項
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSubscriptionType = .yearly
                    }
                }) {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text("年付")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("省15%")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(selectedSubscriptionType == .yearly ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        selectedSubscriptionType == .yearly ? 
                        Color.primary : Color.clear
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                            .path(in: CGRect(x: 0, y: 0, width: 100, height: 44))
                    )
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 4)
        }
    }
    
    private var planCards: some View {
        VStack(spacing: 12) {
            ForEach(PurchaseService.PurchaseTier.allCases, id: \.self) { tier in
                PlanCardRow(
                    tier: tier,
                    subscriptionType: selectedSubscriptionType,
                    isSelected: selectedTier == tier,
                    onSelect: { selectedTier = tier },
                    language: languageService.currentLanguage
                )
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium 功能")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "gamecontroller.fill", title: "賓果遊戲室", description: "多人對戰，即時聊天")
                FeatureRow(icon: "message.fill", title: "無限聊天", description: "不受每日訊息限制")
                FeatureRow(icon: "globe", title: "多語言支援", description: "贊助未來語言包開發")
                FeatureRow(icon: "trophy.fill", title: "排行榜系統", description: "追蹤遊戲成就")
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("• 訂閱將在當前期間結束時自動續費")
            Text("• 可隨時在設定中取消訂閱")
            Text("• 付款將在確認購買時從您的Apple ID帳戶收取")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }
    
    private var bottomActionSection: some View {
        VStack(spacing: 12) {
            // 主要購買按鈕
            Button(action: {
                Task {
                    await purchaseService.purchase(selectedTier)
                    if purchaseService.errorMessage == nil && purchaseService.isPremiumUser {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if purchaseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    
                    Text("立即升級")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.843, blue: 0.416),
                            Color(red: 0.0, green: 0.7, blue: 0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(purchaseService.isLoading)
            
            // 恢復購買按鈕
            Button(action: {
                Task {
                    await purchaseService.restorePurchases()
                }
            }) {
                Text("恢復購買")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .disabled(purchaseService.isLoading)
            
            // 錯誤訊息
            if let errorMessage = purchaseService.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Button("重試") {
                        Task {
                            await purchaseService.reloadProducts()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            #if DEBUG
            Button("🔓 測試解鎖 (開發模式)") {
                purchaseService.unlockForTesting(.vip)
                dismiss()
            }
            .font(.caption)
            .foregroundColor(.orange)
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
        )
    }
}

// MARK: - Supporting Views

struct PlanCardRow: View {
    let tier: PurchaseService.PurchaseTier
    let subscriptionType: PurchaseService.SubscriptionType
    let isSelected: Bool
    let onSelect: () -> Void
    let language: LanguageService.Language
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 選擇指示器
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(red: 0.0, green: 0.843, blue: 0.416) : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.843, blue: 0.416))
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.displayName(language: PurchaseService.convertLanguage(language)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if tier == .vip {
                            Text("推薦")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    Text(tier.description(language: PurchaseService.convertLanguage(language)))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tier.priceForType(subscriptionType))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subscriptionType == .monthly ? "/月" : "/年")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color(red: 0.0, green: 0.843, blue: 0.416) : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
