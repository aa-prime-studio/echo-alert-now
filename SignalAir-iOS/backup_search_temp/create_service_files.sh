#!/bin/bash

echo "⚙️ Creating Service files..."

# PurchaseService.swift
cat > "SignalAir/Services/PurchaseService.swift" << 'EOF'
import Foundation
import StoreKit

@MainActor
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
            case .coffee: return "喝杯咖啡"
            case .bingoUnlock: return "解鎖賓果遊戲"
            case .fullVersion: return "完整版"
            }
        }
        
        var price: String {
            switch self {
            case .coffee: return "NT$90"
            case .bingoUnlock: return "NT$330"
            case .fullVersion: return "NT$1,480"
            }
        }
        
        var description: String {
            switch self {
            case .coffee: return "純贊助，無解鎖功能"
            case .bingoUnlock: return "解鎖賓果遊戲室"
            case .fullVersion: return "解鎖賓果遊戲室 + 未來擴充語言包"
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
EOF

# LanguageService.swift
cat > "SignalAir/Services/LanguageService.swift" << 'EOF'
import Foundation

class LanguageService: ObservableObject {
    @Published var currentLanguage: Language = .chinese
    
    enum Language: String, CaseIterable {
        case chinese = "zh"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .chinese: return "中文"
            case .english: return "English"
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "selectedLanguage"
    
    init() {
        loadLanguage()
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        userDefaults.set(language.rawValue, forKey: languageKey)
    }
    
    private func loadLanguage() {
        let savedLanguage = userDefaults.string(forKey: languageKey) ?? Language.chinese.rawValue
        currentLanguage = Language(rawValue: savedLanguage) ?? .chinese
    }
    
    func t(_ key: String) -> String {
        return translations[key] ?? key
    }
    
    private var translations: [String: String] {
        switch currentLanguage {
        case .chinese:
            return [
                "settings": "設定",
                "language": "語言",
                "chinese": "中文",
                "english": "English",
                "signals": "訊號",
                "chat": "聊天室",
                "games": "遊戲",
                "subscription_status": "訂購狀態",
                "premium_user": "付費用戶",
                "free_user": "免費用戶",
                "upgrade_unlock_games": "升級解鎖遊戲功能",
                "restore_purchases": "恢復購買"
            ]
        case .english:
            return [
                "settings": "Settings",
                "language": "Language",
                "chinese": "中文",
                "english": "English",
                "signals": "Signals",
                "chat": "Chat",
                "games": "Games",
                "subscription_status": "Subscription Status",
                "premium_user": "Premium User",
                "free_user": "Free User",
                "upgrade_unlock_games": "Upgrade to Unlock Games",
                "restore_purchases": "Restore Purchases"
            ]
        }
    }
}
EOF

echo "✅ Service files created" 