#!/usr/bin/env swift

import Foundation

print("🛡️ TestA: 密集市區信任評分測試")
print("10,000人區域內信任評分")
print("")

let startTime = CFAbsoluteTimeGetCurrent()

// 建立10,000人信任評分
var trustScores: [String: Double] = [:]
for i in 1...10_000 {
    let deviceId = "DEV-\(String(format: "%05d", i))"
    trustScores[deviceId] = 50.0 // 初始分數50
}
print("✅ 10,000個設備信任評分初始化完成")

// 測試區域內信任評分更新
print("🔄 測試區域內信任評分 (100萬次)")
var totalEvaluations = 0
var normalActivity = 0
var suspiciousActivity = 0
var maliciousActivity = 0

for batch in 1...10 {
    print("📊 批次\(batch)/10進行中...")
    
    for _ in 1...100_000 {
        let deviceId = Array(trustScores.keys).randomElement()!
        var currentScore = trustScores[deviceId]!
        
        // 區域內活動模擬 (70%正常, 20%可疑, 10%惡意)
        let activityType = Int.random(in: 1...100)
        
        if activityType <= 70 {
            // 正常活動
            currentScore += Double.random(in: 5...15)
            normalActivity += 1
        } else if activityType <= 90 {
            // 可疑活動
            currentScore -= Double.random(in: 5...10)
            suspiciousActivity += 1
        } else {
            // 惡意活動
            currentScore -= Double.random(in: 15...25)
            maliciousActivity += 1
        }
        
        // 限制分數範圍
        currentScore = max(0, min(100, currentScore))
        trustScores[deviceId] = currentScore
        
        totalEvaluations += 1
    }
    
    let currentTime = CFAbsoluteTimeGetCurrent()
    let elapsed = currentTime - startTime
    let currentRate = Double(totalEvaluations) / elapsed
    
    print("   進度: \(totalEvaluations)/1,000,000")
    print("   速度: \(Int(currentRate))評分/秒")
}

let endTime = CFAbsoluteTimeGetCurrent()
let totalTime = endTime - startTime
let trustRate = Double(totalEvaluations) / totalTime

// 統計結果
let averageScore = trustScores.values.reduce(0, +) / Double(trustScores.count)
let highTrust = trustScores.values.filter { $0 >= 70 }.count
let lowTrust = trustScores.values.filter { $0 <= 30 }.count

print("📊 信任評分測試結果:")
print("總評分: \(totalEvaluations)次")
print("正常: \(normalActivity)次")
print("可疑: \(suspiciousActivity)次")
print("惡意: \(maliciousActivity)次")
print("平均分: \(String(format: "%.1f", averageScore))")
print("高信任: \(highTrust)人")
print("低信任: \(lowTrust)人")
print("速度: \(Int(trustRate))評分/秒")
print("目標: >1,000,000評分/秒 \(trustRate > 1_000_000 ? "✅" : "❌")")
print("")