#!/usr/bin/env swift

import Foundation

print("🛡️ 測試3: 大規模信任評分測試")
print("📊 目標: 1,000,000評分/秒, 300,000設備")
print("")

// 建立設備陣列
print("📱 正在建立300,000個設備...")
var devices: [String] = []
let startTime = CFAbsoluteTimeGetCurrent()

for batch in 1...30 {
    for i in 1...10_000 {
        let deviceIndex = (batch - 1) * 10_000 + i
        devices.append("DEV-\(String(format: "%06d", deviceIndex))")
    }
    if batch % 5 == 0 {
        print("📦 批次\(batch)/30: 已建立\(devices.count)個設備")
    }
}

print("✅ 所有300,000個設備建立完成")
print("")

// 設備信任評分系統
struct TrustScore {
    var deviceId: String
    var score: Double = 50.0
    var communicationCount: Int = 0
    var suspiciousActivity: Int = 0
    var maliciousDetections: Int = 0
    var lastActivity: Date = Date()
    
    mutating func updateScore(activityType: ActivityType) {
        switch activityType {
        case .normalCommunication:
            score += Double.random(in: 15...35)
            communicationCount += 1
        case .suspiciousActivity:
            score -= Double.random(in: 10...20)
            suspiciousActivity += 1
        case .maliciousActivity:
            score -= Double.random(in: 30...45)
            maliciousDetections += 1
        }
        
        // 限制分數範圍
        score = max(0, min(100, score))
        lastActivity = Date()
    }
    
    enum ActivityType {
        case normalCommunication, suspiciousActivity, maliciousActivity
    }
}

// 初始化所有設備的信任評分
print("🔄 初始化300,000個設備信任評分...")
var trustScores: [String: TrustScore] = [:]

for (index, deviceId) in devices.enumerated() {
    trustScores[deviceId] = TrustScore(deviceId: deviceId)
    
    if (index + 1) % 50_000 == 0 {
        print("📊 已初始化 \(index + 1) 個設備")
    }
}

print("✅ 所有設備信任評分初始化完成")
print("")

// 模擬大量信任評分更新
print("🔄 開始執行3,000,000次信任評分更新...")
var totalEvaluations = 0
var normalUsers = 0
var suspiciousUsers = 0  
var maliciousUsers = 0
var blacklistedUsers = 0

for batch in 1...30 {
    print("📊 批次\(batch)/30進行中...")
    
    for _ in 1...100_000 {
        let deviceId = devices.randomElement()!
        guard var trustScore = trustScores[deviceId] else { continue }
        
        // 模擬不同類型的活動 (70%正常, 20%可疑, 10%惡意)
        let activityRandom = Int.random(in: 1...100)
        let activityType: TrustScore.ActivityType
        
        if activityRandom <= 70 {
            activityType = .normalCommunication
            normalUsers += 1
        } else if activityRandom <= 90 {
            activityType = .suspiciousActivity
            suspiciousUsers += 1
        } else {
            activityType = .maliciousActivity
            maliciousUsers += 1
        }
        
        trustScore.updateScore(activityType: activityType)
        trustScores[deviceId] = trustScore
        
        // 檢查是否需要加入黑名單
        if trustScore.score <= 20 {
            blacklistedUsers += 1
        }
        
        totalEvaluations += 1
    }
    
    let currentTime = CFAbsoluteTimeGetCurrent()
    let elapsed = currentTime - startTime
    let currentRate = Double(totalEvaluations) / elapsed
    
    print("   進度: \(totalEvaluations)/3,000,000")
    print("   正常: \(normalUsers), 可疑: \(suspiciousUsers), 惡意: \(maliciousUsers)")
    print("   黑名單: \(blacklistedUsers)")
    print("   評分速度: \(Int(currentRate))次/秒")
    print("")
}

// 計算最終統計
let endTime = CFAbsoluteTimeGetCurrent()
let totalTime = endTime - startTime
let finalRate = Double(totalEvaluations) / totalTime

// 計算平均分數
var totalScore = 0.0
var trustedDevices = 0
var untrustedDevices = 0

for (_, trustScore) in trustScores {
    totalScore += trustScore.score
    if trustScore.score >= 70 {
        trustedDevices += 1
    } else if trustScore.score <= 30 {
        untrustedDevices += 1
    }
}

let averageScore = totalScore / Double(trustScores.count)

print("📊 測試3最終結果:")
print("總評分次數: \(totalEvaluations)")
print("正常活動: \(normalUsers)")
print("可疑活動: \(suspiciousUsers)")
print("惡意活動: \(maliciousUsers)")
print("黑名單設備: \(blacklistedUsers)")
print("平均信任分: \(String(format: "%.1f", averageScore))")
print("高信任設備: \(trustedDevices) (≥70分)")
print("低信任設備: \(untrustedDevices) (≤30分)")
print("耗時: \(String(format: "%.2f", totalTime))秒")
print("速度: \(Int(finalRate))評分/秒")
print("目標達成: \(finalRate > 1_000_000 ? "✅" : "❌")")