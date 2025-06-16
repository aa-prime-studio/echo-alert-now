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
