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
        
        var displayName: String {
            switch self {
            case .coffee: return "喝杯楊枝甘露"
            case .bingoUnlock: return "解鎖賓果遊戲"
            case .fullVersion: return "完整版"
            }
        }
        
        var price: String {
            switch self {
            case .coffee: return "NT$90"
            case .bingoUnlock: return "NT$330"
            case .fullVersion: return "NT$1,680"
            }
        }
        
        var description: String {
            switch self {
            case .coffee: return "純贊助，無解鎖功能"
            case .bingoUnlock: return "解鎖賓果遊戲室"
            case .fullVersion: return "全功能 + 未來擴充語言包，幫助更多地球人！"
            }
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
    
    func purchase(_ tier: PurchaseTier) async {
        // TODO: Phase 2 - Implement actual purchase
        print("模擬購買: \(tier.displayName)")
    }
    
    func restorePurchases() async {
        // TODO: Phase 2 - Implement restore
        print("模擬恢復購買")
    }
}
