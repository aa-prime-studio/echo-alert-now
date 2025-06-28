import Foundation
import StoreKit

class PurchaseService: ObservableObject {
    @Published var purchasedTiers: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum PurchaseTier: String, CaseIterable {
        case coffee = "com.signalair.coffee"
        case bingoUnlock = "com.signalair.bingo"
        case fullVersion = "com.signalair.full"
        
        func displayName(language: LanguageService.Language) -> String {
            switch language {
            case .chinese:
                switch self {
                case .coffee: return "喝杯楊枝甘露"
                case .bingoUnlock: return "公園同樂版"
                case .fullVersion: return "丹丹漢堡吃不膩版"
                }
            case .english:
                switch self {
                case .coffee: return "Buy a Drink"
                case .bingoUnlock: return "Park Fun Edition"
                case .fullVersion: return "Dan Dan Burger Unlimited"
                }
            }
        }
        
        func description(language: LanguageService.Language) -> String {
            switch language {
            case .chinese:
                switch self {
                case .coffee: return "純贊助，無解鎖功能"
                case .bingoUnlock: return "解鎖賓果遊戲室"
                case .fullVersion: return "全功能 + 未來擴充語言包，幫助更多地球人！"
                }
            case .english:
                switch self {
                case .coffee: return "Pure support, no unlock features"
                case .bingoUnlock: return "Unlock Bingo Game Room"
                case .fullVersion: return "Full features + future language packs, help more people!"
                }
            }
        }
        
        var price: String {
            switch self {
            case .coffee: return "NT$90"
            case .bingoUnlock: return "NT$330"
            case .fullVersion: return "NT$1,680"
            }
        }
        
        // 保持向後相容性的屬性
        var displayName: String {
            return displayName(language: .chinese)
        }
        
        var description: String {
            return description(language: .chinese)
        }
    }
    
    private var products: [Product] = []
    
    init() {
        // TODO: Phase 2 - Initialize StoreKit
    }
    
    var isPremiumUser: Bool {
        return purchasedTiers.contains(PurchaseTier.bingoUnlock.rawValue) || 
               purchasedTiers.contains(PurchaseTier.fullVersion.rawValue)
    }
    
    func getPurchasedTierDisplayName(language: LanguageService.Language) -> String? {
        if purchasedTiers.contains(PurchaseTier.fullVersion.rawValue) {
            return PurchaseTier.fullVersion.displayName(language: language)
        } else if purchasedTiers.contains(PurchaseTier.bingoUnlock.rawValue) {
            return PurchaseTier.bingoUnlock.displayName(language: language)
        } else if purchasedTiers.contains(PurchaseTier.coffee.rawValue) {
            return PurchaseTier.coffee.displayName(language: language)
        }
        return nil
    }
    
    func purchase(_ tier: PurchaseTier) async {
        await MainActor.run {
            isLoading = true
        }
        
        // 模擬購買過程（用於實機測試）
        print("模擬購買: \(tier.displayName)")
        
        // 模擬 2 秒購買過程
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 模擬購買成功
        await MainActor.run {
            purchasedTiers.insert(tier.rawValue)
            isLoading = false
            print("購買成功: \(tier.displayName)")
        }
    }
    
    func restorePurchases() async {
        await MainActor.run {
            isLoading = true
        }
        
        // 模擬恢復購買過程
        print("模擬恢復購買")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // 模擬恢復所有購買
            purchasedTiers.insert(PurchaseTier.bingoUnlock.rawValue)
            purchasedTiers.insert(PurchaseTier.fullVersion.rawValue)
            isLoading = false
            print("恢復購買成功")
        }
    }
    
    // 測試用：重置購買狀態
    func resetPurchases() {
        Task { @MainActor in
            purchasedTiers.removeAll()
            print("已重置購買狀態")
        }
    }
}
