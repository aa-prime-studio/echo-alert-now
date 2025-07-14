import Foundation

//
// MaliciousContentDetector.swift
// SignalAir
//
// 惡意內容檢測和分類系統
//

/// 惡意內容類型定義
enum MaliciousContentType: String, CaseIterable {
    case phishing = "phishing"
    case botGenerated = "bot_generated"
    
    var severity: MaliciousContentSeverity {
        switch self {
        case .phishing:
            return .high
        case .botGenerated:
            return .critical
        }
    }
    
    var description: String {
        switch self {
        case .phishing:
            return "網路釣魚"
        case .botGenerated:
            return "機器人內容"
        }
    }
}

/// 惡意內容嚴重性等級
enum MaliciousContentSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var trustScorePenalty: Double {
        switch self {
        case .low: return 5.0
        case .medium: return 10.0
        case .high: return 15.0
        case .critical: return 30.0
        }
    }
}

/// 內容分析結果
struct ContentAnalysisResult {
    let isClean: Bool
    let detectedTypes: [MaliciousContentType]
    let confidence: Double // 0.0 - 1.0
    let details: String
    
    var maxSeverity: MaliciousContentSeverity {
        return detectedTypes.map { $0.severity }.max() ?? .low
    }
}

/// 惡意內容檢測器
class MaliciousContentDetector {
    
    // MARK: - 惡意內容關鍵詞庫
    
    private let phishingKeywords = [
        // 中文釣魚詞彙
        "點擊連結", "輸入密碼", "緊急驗證", "帳號異常", "立即處理", "帳戶凍結",
        "安全驗證", "身份確認", "更新資料", "重設密碼", "驗證碼", "登入確認",
        
        // 英文釣魚詞彙
        "click here", "verify account", "urgent", "suspended", "login",
        "update payment", "confirm identity", "security alert", "expired"
    ]
    
    // MARK: - 主要檢測方法
    
    /// 分析文字內容是否包含惡意內容
    func analyzeContent(_ text: String) -> ContentAnalysisResult {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var detectedTypes: [MaliciousContentType] = []
        var confidence: Double = 0.0
        
        // 檢測網路釣魚（包含URL檢測）
        if containsKeywords(cleanText, from: phishingKeywords) || containsURL(cleanText) {
            detectedTypes.append(.phishing)
            confidence = max(confidence, 0.9)
        }
        
        // 檢測機器人生成內容（基於模式）
        if detectBotPattern(cleanText) {
            detectedTypes.append(.botGenerated)
            confidence = max(confidence, 0.95)
        }
        
        let details = detectedTypes.isEmpty ? "內容清潔" : "檢測到: \(detectedTypes.map { $0.description }.joined(separator: ", "))"
        
        return ContentAnalysisResult(
            isClean: detectedTypes.isEmpty,
            detectedTypes: detectedTypes,
            confidence: confidence,
            details: details
        )
    }
    
    // MARK: - 輔助檢測方法
    
    private func containsKeywords(_ text: String, from keywords: [String]) -> Bool {
        return keywords.contains { keyword in
            text.contains(keyword)
        }
    }
    
    private func containsURL(_ text: String) -> Bool {
        // 檢測常見URL模式
        let urlPatterns = [
            "http://", "https://", "www.", ".com", ".net", ".org", ".tw", ".cn"
        ]
        
        return urlPatterns.contains { pattern in
            text.contains(pattern)
        }
    }
    
    private func detectBotPattern(_ text: String) -> Bool {
        // 檢測機器人模式：
        // 1. 過度重複的字符
        let repeatingPattern = try? NSRegularExpression(pattern: "(.{1,3})\\1{4,}", options: [])
        if let regex = repeatingPattern,
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return true
        }
        
        // 2. 異常的大寫模式
        let uppercaseRatio = Double(text.filter { $0.isUppercase }.count) / Double(text.count)
        if uppercaseRatio > 0.8 && text.count > 10 {
            return true
        }
        
        // 3. 過多的特殊字符
        let specialCharRatio = Double(text.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count) / Double(text.count)
        if specialCharRatio > 0.5 && text.count > 5 {
            return true
        }
        
        return false
    }
    
    /// 快速檢查是否為明顯惡意內容
    func isObviouslyMalicious(_ text: String) -> Bool {
        let result = analyzeContent(text)
        return !result.isClean && result.confidence > 0.8
    }
    
    /// 取得建議的處理動作
    func getRecommendedAction(for result: ContentAnalysisResult) -> ContentModerationAction {
        if result.isClean {
            return .allow
        }
        
        switch result.maxSeverity {
        case .low:
            return .warn
        case .medium:
            return .filter
        case .high:
            return .block
        case .critical:
            return .blockAndBan
        }
    }
}

/// 內容審核動作
enum ContentModerationAction {
    case allow          // 允許
    case warn           // 警告
    case filter         // 過濾
    case block          // 阻擋
    case blockAndBan    // 阻擋並封禁
}

/// 擴展：與現有信任分數系統整合
extension MaliciousContentDetector {
    
    /// 檢測惡意內容並回報給信任分數系統
    func validateAndReport(_ text: String, from deviceUUID: String, trustManager: TrustScoreManager) -> Bool {
        let result = analyzeContent(text)
        
        if !result.isClean {
            // 觸發信任分數懲罰
            trustManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .maliciousContent)
            
            // 記錄安全事件
            let event = SecurityEvent(
                peerID: deviceUUID,
                type: .suspiciousActivity,
                severity: mapToSecuritySeverity(result.maxSeverity),
                details: "惡意內容檢測: \(result.details)",
                sourceComponent: "MaliciousContentDetector"
            )
            
            print("🚨 檢測到惡意內容: \(result.details) 來自: \(deviceUUID)")
            return false
        }
        
        return true
    }
    
    private func mapToSecuritySeverity(_ contentSeverity: MaliciousContentSeverity) -> SecuritySeverity {
        switch contentSeverity {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .critical: return .critical
        }
    }
}