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
                            PurchaseCardView(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: { selectedTier = tier },
                                language: languageService.currentLanguage
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
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("\(languageService.t("purchase")) \(selectedTier.displayName(language: languageService.currentLanguage))")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.843, blue: 0.416))
                    .cornerRadius(12)
                }
                .disabled(purchaseService.isLoading)
            }
            
            Button(action: {
                Task {
                    await purchaseService.restorePurchases()
                }
            }) {
                Text(languageService.t("restore_purchases"))
                    .font(.caption)
                    .foregroundColor(.gray)
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
    let language: LanguageService.Language
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName(language: language))
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
            
            Text(tier.description(language: language))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if tier == .bingoUnlock {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                    Text(language == .chinese ? "推薦方案" : "Recommended")
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
