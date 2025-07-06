import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseService.PurchaseTier?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(PurchaseService.PurchaseTier.allCases, id: \.self) { tier in
                            VStack(spacing: 8) {
                                PurchaseCardView(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    onSelect: { selectedTier = tier },
                                    language: languageService.currentLanguage
                                )
                                
                                #if DEBUG
                                // 測試解鎖按鈕（僅在 DEBUG 模式下顯示）
                                if tier != .coffee {
                                    Button(action: {
                                        purchaseService.unlockForTesting(tier)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            dismiss()
                                        }
                                    }) {
                                        Text("🔓 測試解鎖")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                #endif
                            }
                        }
                    }
                    .padding()
                }
                
                purchaseButton
            }
            .navigationTitle(languageService.t("upgrade_options"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(languageService.t("cancel")) { dismiss() }
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
            
            Text(languageService.t("unlock_full_features"))
                .font(.headline)
                .foregroundColor(.black)
            
            Text(languageService.t("choose_best_plan"))
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
                        // 確保 UI 更新在主線程
                        await MainActor.run {
                            // 檢查是否購買成功
                            if purchaseService.errorMessage == nil && purchaseService.isPremiumUser {
                                dismiss()
                            }
                        }
                    }
                }) {
                    HStack {
                        if purchaseService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "heart.fill")
                        }
                        Text("\(languageService.t("purchase")) \(selectedTier.displayName(language: PurchaseService.convertLanguage(languageService.currentLanguage)))")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.843, blue: 0.416))
                    .cornerRadius(12)
                    .opacity(purchaseService.isLoading ? 0.7 : 1.0)
                }
                .disabled(purchaseService.isLoading || purchaseService.purchasedTiers.contains(selectedTier.rawValue))
            }
            
            Button(action: {
                Task {
                    await purchaseService.restorePurchases()
                    // 確保 UI 更新在主線程
                    await MainActor.run {
                        // 檢查是否恢復成功
                        if purchaseService.errorMessage == nil && purchaseService.isPremiumUser {
                            dismiss()
                        }
                    }
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
            
            // 顯示錯誤訊息
            if let errorMessage = purchaseService.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 重試按鈕
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
                    
                    #if DEBUG
                    // 重置購買狀態按鈕（測試用）
                    Button(action: {
                        purchaseService.resetPurchases()
                    }) {
                        Text("🗑️ 重置購買狀態（測試）")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    #endif
                }
            }
        }
        .padding()
    }
}

struct PurchaseCardView: View {
    let tier: PurchaseService.PurchaseTier
    let isSelected: Bool
    let onSelect: () -> Void
    let language: LanguageService.Language
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName(language: PurchaseService.convertLanguage(language)))
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(tier.price)
                        .font(.headline)
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            Text(tier.description(language: PurchaseService.convertLanguage(language)))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if tier == .bingoUnlock {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                    Text(languageService.t("recommended_plan"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? (tier == .coffee ? Color.gray : Color(red: 0.0, green: 0.843, blue: 0.416)) : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
    }
}
