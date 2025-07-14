import Foundation

//
// MaliciousContentDetector.swift
// SignalAir
//
// 惡意內容檢測和分類系統
//

/// 惡意內容類型定義
enum MaliciousContentType: String, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case hateSpeech = "hate_speech"
    case threats = "threats"
    case phishing = "phishing"
    case adultContent = "adult_content"
    case misinformation = "misinformation"
    case botGenerated = "bot_generated"
    
    var severity: MaliciousContentSeverity {
        switch self {
        case .spam:
            return .low
        case .harassment, .misinformation:
            return .medium
        case .hateSpeech, .phishing, .adultContent:
            return .high
        case .threats, .botGenerated:
            return .critical
        }
    }
    
    var description: String {
        switch self {
        case .spam:
            return "垃圾訊息"
        case .harassment:
            return "騷擾內容"
        case .hateSpeech:
            return "仇恨言論"
        case .threats:
            return "威脅恐嚇"
        case .phishing:
            return "網路釣魚"
        case .adultContent:
            return "成人內容"
        case .misinformation:
            return "錯誤訊息"
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
        case .critical: return 25.0
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
    
    // MARK: - 擴展的禁用詞彙庫
    
    private let spamKeywords = [
        "spam", "垃圾", "廣告", "促銷", "優惠", "免費", "賺錢",
        "投資", "理財", "貸款", "信用卡", "中獎", "抽獎"
    ]
    
    private let harassmentKeywords = [
        "死", "殺", "笨蛋", "白痴", "智障", "廢物", "垃圾人",
        "get out", "stupid", "idiot", "loser", "freak"
    ]
    
    private let hateSpeechKeywords = [
        "種族", "歧視", "仇恨", "排斥", "劣等", "優等",
        "racist", "discrimination", "hate", "inferior", "superior"
    ]
    
    private let threatKeywords = [
        "威脅", "恐嚇", "報復", "傷害", "殺害", "毀掉",
        "threat", "kill", "destroy", "harm", "revenge", "attack"
    ]
    
    private let phishingKeywords = [
        "點擊連結", "輸入密碼", "緊急驗證", "帳號異常", "立即處理",
        "click here", "verify account", "urgent", "suspended", "login"
    ]
    
    private let adultKeywords = [
        // 基本成人內容關鍵字（可依需要擴展）
        "色情", "性愛", "裸體", "成人", "18+",
        "porn", "sex", "nude", "adult", "xxx"
    ]
    
    // MARK: - 主要檢測方法
    
    /// 分析文字內容是否包含惡意內容
    func analyzeContent(_ text: String) -> ContentAnalysisResult {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var detectedTypes: [MaliciousContentType] = []
        var confidence: Double = 0.0
        
        // 檢測垃圾訊息
        if containsKeywords(cleanText, from: spamKeywords) {
            detectedTypes.append(.spam)
            confidence = max(confidence, 0.7)
        }
        
        // 檢測騷擾內容
        if containsKeywords(cleanText, from: harassmentKeywords) {
            detectedTypes.append(.harassment)
            confidence = max(confidence, 0.8)
        }
        
        // 檢測仇恨言論
        if containsKeywords(cleanText, from: hateSpeechKeywords) {
            detectedTypes.append(.hateSpeech)
            confidence = max(confidence, 0.9)
        }
        
        // 檢測威脅內容
        if containsKeywords(cleanText, from: threatKeywords) {
            detectedTypes.append(.threats)
            confidence = max(confidence, 0.95)
        }
        
        // 檢測網路釣魚
        if containsKeywords(cleanText, from: phishingKeywords) {
            detectedTypes.append(.phishing)
            confidence = max(confidence, 0.85)
        }
        
        // 檢測成人內容
        if containsKeywords(cleanText, from: adultKeywords) {
            detectedTypes.append(.adultContent)
            confidence = max(confidence, 0.8)
        }
        
        // 檢測機器人生成內容（基於模式）
        if detectBotPattern(cleanText) {
            detectedTypes.append(.botGenerated)
            confidence = max(confidence, 0.75)
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