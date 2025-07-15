#!/usr/bin/env swift

import Foundation

print("🔍 測試4: 大規模內容檢測測試")
print("📊 目標: 2,000,000檢測/秒")
print("")

// 內容檢測系統
struct ContentDetector {
    
    // 釣魚關鍵詞詞庫
    static let phishingKeywords = [
        "點擊連結", "輸入密碼", "驗證帳號", "緊急處理", "立即確認",
        "帳戶異常", "安全驗證", "點擊此處", "身份驗證", "緊急通知"
    ]
    
    enum ThreatLevel: Int {
        case normal = 0, low = 1, medium = 2, high = 3, critical = 4
    }
    
    enum ContentType {
        case normal, phishing, bot
    }
    
    static func detectContent(_ content: String) -> (type: ContentType, threat: ThreatLevel, confidence: Double) {
        
        // 第一層: 關鍵詞檢測
        var phishingScore = 0.0
        for keyword in phishingKeywords {
            if content.contains(keyword) {
                phishingScore += 0.3
            }
        }
        
        if phishingScore > 0.9 {
            return (.phishing, .critical, 0.95)
        } else if phishingScore > 0.6 {
            return (.phishing, .high, 0.8)
        } else if phishingScore > 0.3 {
            return (.phishing, .medium, 0.6)
        }
        
        // 第二層: Bot檢測
        let uniqueChars = Set(content).count
        let totalChars = content.count
        let specialCharCount = content.filter { "!@#$%^&*()".contains($0) }.count
        let uppercaseCount = content.filter { $0.isUppercase }.count
        
        let uniqueRatio = Double(uniqueChars) / Double(max(totalChars, 1))
        let specialRatio = Double(specialCharCount) / Double(max(totalChars, 1))
        let uppercaseRatio = Double(uppercaseCount) / Double(max(totalChars, 1))
        
        if uniqueRatio < 0.3 || specialRatio > 0.7 || uppercaseRatio > 0.8 {
            if uniqueRatio < 0.1 && specialRatio > 0.8 {
                return (.bot, .critical, 0.9)
            } else if uniqueRatio < 0.2 && specialRatio > 0.5 {
                return (.bot, .high, 0.75)
            } else {
                return (.bot, .medium, 0.6)
            }
        }
        
        return (.normal, .normal, 0.1)
    }
}

// 生成測試內容
func generateTestContent() -> String {
    let contentTypes = Int.random(in: 1...10)
    
    if contentTypes <= 3 { // 30% 釣魚內容
        let phishingTemplates = [
            "緊急通知：您的帳戶異常，請立即點擊連結進行身份驗證",
            "安全警報：檢測到異常登入，請點擊此處輸入密碼確認",
            "重要：您的帳號將被凍結，請緊急處理並驗證帳號",
            "系統通知：發現可疑活動，請立即確認並輸入密碼"
        ]
        return phishingTemplates.randomElement()!
    } else if contentTypes <= 5 { // 20% Bot內容
        let botPatterns = [
            "!!!AAAA!!!BBBB!!!CCCC!!!",
            "$$$$$$$$$$$$$$$$$$$$$$$$",
            "WWWWWWWWWWWWWWWWWWWWWWWW",
            "#@#@#@#@#@#@#@#@#@#@#@#@"
        ]
        return botPatterns.randomElement()!
    } else { // 50% 正常內容
        let normalContent = [
            "大家好，今天天氣很不錯",
            "我現在在公園散步，很舒服",
            "謝謝大家的幫助和支持",
            "希望大家都平安健康"
        ]
        return normalContent.randomElement()!
    }
}

// 開始大規模內容檢測測試
print("🔄 開始執行6,000,000次內容檢測...")
let startTime = CFAbsoluteTimeGetCurrent()

var totalDetections = 0
var normalCount = 0
var phishingCount = 0
var botCount = 0
var criticalThreats = 0
var highThreats = 0
var mediumThreats = 0
var lowThreats = 0

for batch in 1...60 {
    print("📊 批次\(batch)/60進行中...")
    
    for _ in 1...100_000 {
        let content = generateTestContent()
        let result = ContentDetector.detectContent(content)
        
        switch result.type {
        case .normal:
            normalCount += 1
        case .phishing:
            phishingCount += 1
        case .bot:
            botCount += 1
        }
        
        switch result.threat {
        case .normal:
            break
        case .low:
            lowThreats += 1
        case .medium:
            mediumThreats += 1
        case .high:
            highThreats += 1
        case .critical:
            criticalThreats += 1
        }
        
        totalDetections += 1
    }
    
    let currentTime = CFAbsoluteTimeGetCurrent()
    let elapsed = currentTime - startTime
    let currentRate = Double(totalDetections) / elapsed
    
    if batch % 10 == 0 {
        print("   進度: \(totalDetections)/6,000,000")
        print("   正常: \(normalCount), 釣魚: \(phishingCount), Bot: \(botCount)")
        print("   威脅等級 - 低:\(lowThreats) 中:\(mediumThreats) 高:\(highThreats) 極:\(criticalThreats)")
        print("   檢測速度: \(Int(currentRate))次/秒")
        print("")
    }
}

let endTime = CFAbsoluteTimeGetCurrent()
let totalTime = endTime - startTime
let finalRate = Double(totalDetections) / totalTime

let normalPercent = Double(normalCount) / Double(totalDetections) * 100
let phishingPercent = Double(phishingCount) / Double(totalDetections) * 100
let botPercent = Double(botCount) / Double(totalDetections) * 100

print("📊 測試4最終結果:")
print("總檢測次數: \(totalDetections)")
print("正常內容: \(normalCount) (\(String(format: "%.1f", normalPercent))%)")
print("釣魚內容: \(phishingCount) (\(String(format: "%.1f", phishingPercent))%)")
print("Bot內容: \(botCount) (\(String(format: "%.1f", botPercent))%)")
print("威脅統計:")
print("  低風險: \(lowThreats)")
print("  中風險: \(mediumThreats)")
print("  高風險: \(highThreats)")
print("  極高風險: \(criticalThreats)")
print("耗時: \(String(format: "%.2f", totalTime))秒")
print("速度: \(Int(finalRate))檢測/秒")
print("目標達成: \(finalRate > 2_000_000 ? "✅" : "❌")")