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
