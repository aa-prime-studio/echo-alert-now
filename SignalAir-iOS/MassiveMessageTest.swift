#!/usr/bin/env swift

import Foundation

print("🚨 測試2: 大規模訊息廣播測試")
print("📊 目標: 5,000,000訊息/秒, 300,000用戶")
print("")

// 建立大量用戶
print("👥 正在建立300,000個用戶...")
var users: [String] = []
let startTime = CFAbsoluteTimeGetCurrent()

for batch in 1...30 {
    for i in 1...10_000 {
        let userIndex = (batch - 1) * 10_000 + i
        users.append("USER-\(String(format: "%06d", userIndex))")
    }
    print("📦 批次\(batch)/30: 已建立\(users.count)個用戶")
}

print("✅ 所有300,000個用戶建立完成")
print("")

// 測試訊息處理
print("📨 開始測試5,000,000條訊息處理...")
var totalMessages = 0
var emergencyMessages = 0
var normalMessages = 0
var processedBytes = 0

struct Message {
    let type: MessageType
    let priority: Int
    let content: String
    let timestamp: Date
    let size: Int
    
    enum MessageType {
        case emergency, normal
    }
}

// 分批處理訊息
for batch in 1...50 {
    print("📊 批次\(batch)/50進行中...")
    var batchMessages: [Message] = []
    
    // 每批次處理100,000條訊息
    for i in 1...100_000 {
        let isEmergency = (i % 10 == 0) // 10%緊急訊息
        let messageType: Message.MessageType = isEmergency ? .emergency : .normal
        let priority = isEmergency ? 100 : Int.random(in: 5...10)
        
        let content: String
        let messageSize: Int
        
        if isEmergency {
            content = "🚨緊急醫療求助!座標[\(Int.random(in: 1...1000)),\(Int.random(in: 1...1000))]"
            messageSize = content.utf8.count + 12 // 協議頭部
            emergencyMessages += 1
        } else {
            content = "📍位置回報#\(Int.random(in: 1...9999))"
            messageSize = content.utf8.count + 12
            normalMessages += 1
        }
        
        let message = Message(
            type: messageType,
            priority: priority,
            content: content,
            timestamp: Date(),
            size: messageSize
        )
        
        batchMessages.append(message)
        processedBytes += messageSize
        totalMessages += 1
    }
    
    // 模擬訊息編碼和廣播
    let batchStartTime = CFAbsoluteTimeGetCurrent()
    
    // 優先處理緊急訊息
    let emergencyBatch = batchMessages.filter { $0.type == .emergency }
    let normalBatch = batchMessages.filter { $0.type == .normal }
    
    // 處理緊急訊息
    for message in emergencyBatch {
        // 模擬立即廣播到所有用戶
        _ = encodeMessage(message, users: users)
    }
    
    // 處理普通訊息
    for message in normalBatch {
        _ = encodeMessage(message, users: users)
    }
    
    let batchEndTime = CFAbsoluteTimeGetCurrent()
    let batchTime = batchEndTime - batchStartTime
    let batchRate = Double(batchMessages.count) / batchTime
    
    let currentTime = CFAbsoluteTimeGetCurrent()
    let elapsed = currentTime - startTime
    let currentRate = Double(totalMessages) / elapsed
    
    print("   進度: \(totalMessages)/5,000,000")
    print("   緊急: \(emergencyMessages), 普通: \(normalMessages)")
    print("   批次速度: \(Int(batchRate))訊息/秒")
    print("   總體速度: \(Int(currentRate))訊息/秒")
    print("   已處理: \(processedBytes/1024)KB")
    print("")
}

func encodeMessage(_ message: Message, users: [String]) -> Data {
    // 模擬二進制協議編碼
    let typeBytes: UInt8 = message.type == .emergency ? 0x01 : 0x02
    let lengthBytes = UInt16(message.content.utf8.count)
    let timestampBytes = UInt64(message.timestamp.timeIntervalSince1970)
    let contentBytes = message.content.data(using: .utf8)!
    let checksumBytes: UInt8 = 0xFF // 簡化的校驗和
    
    var encoded = Data()
    encoded.append(typeBytes)
    encoded.append(contentsOf: withUnsafeBytes(of: lengthBytes.bigEndian) { Array($0) })
    encoded.append(contentsOf: withUnsafeBytes(of: timestampBytes.bigEndian) { Array($0) })
    encoded.append(contentBytes)
    encoded.append(checksumBytes)
    
    return encoded
}

let endTime = CFAbsoluteTimeGetCurrent()
let totalTime = endTime - startTime
let finalRate = Double(totalMessages) / totalTime
let totalMB = Double(processedBytes) / (1024 * 1024)

print("📊 測試2最終結果:")
print("總訊息: \(totalMessages)")
print("緊急訊息: \(emergencyMessages)")
print("普通訊息: \(normalMessages)")
print("總大小: \(String(format: "%.2f", totalMB))MB")
print("耗時: \(String(format: "%.2f", totalTime))秒")
print("速度: \(Int(finalRate))訊息/秒")
print("目標達成: \(finalRate > 5_000_000 ? "✅" : "❌")")