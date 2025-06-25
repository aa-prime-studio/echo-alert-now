import Foundation

// This class is deprecated - use TermsOfServiceContent.swift and PrivacyPolicyContent.swift instead
class LegalContent {
    
    // MARK: - 語言選擇函數
    static func getPrivacyPolicy(language: String = "zh-TW") -> String {
        // Use PrivacyPolicyContent.swift instead
        return ""
    }
    
    static func getTermsOfService(language: String = "zh-TW") -> String {
        // Use TermsOfServiceContent.swift instead
        return ""
    }
    
    // MARK: - 標題獲取函數
    static func getPrivacyPolicyTitle(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return "Privacy Policy"
        default:
            return "隱私權政策"
        }
    }
    
    static func getTermsOfServiceTitle(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return "Terms of Service"
        default:
            return "服務條款"
        }
    }
}
