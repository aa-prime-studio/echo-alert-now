import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseService.PurchaseTier = .vip
    @State private var selectedSubscriptionType: PurchaseService.SubscriptionType = .yearly
    
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
                        Text("月費")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("每月收費")
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
                            Text("年費")
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
                        Text("每年收費")
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
                VStack(spacing: 0) {
                    // 方案資訊
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // 購買圓點按鈕
                            Button(action: {
                                Task {
                                    await purchaseService.purchase(tier)
                                    if purchaseService.errorMessage == nil && purchaseService.purchasedTiers.contains(tier.rawValue) {
                                        dismiss()
                                    }
                                }
                            }) {
                                Image(systemName: "circle")
                                    .foregroundColor(purchaseService.purchasedTiers.contains(tier.rawValue) ? Color(red: 0.0, green: 0.843, blue: 0.416) : .gray)
                                    .font(.title2)
                            }
                            .disabled(purchaseService.isLoading)
                            
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
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(purchaseService.purchasedTiers.contains(tier.rawValue) ? Color(red: 0.0, green: 0.843, blue: 0.416) : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium 功能")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "gamecontroller.fill", title: "賓果遊戲室", description: "多人對戰，即時聊天")
                FeatureRow(icon: "message.fill", title: "無限聊天", description: "不受每日訊息限制")
                FeatureRow(icon: "globe", title: "多語言支援", description: "贊助未來語言包開發")
                FeatureRow(icon: "trophy.fill", title: "排行榜系統", description: "追蹤遊戲成就")
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
                    Text("重試載入")
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
            Text("🔓 測試解鎖 (開發模式)")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }
    #endif
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
