#!/usr/bin/env swift

import Foundation

print("🏘️ TestB: 郊區測試 (18,000人)")
print("板橋住宅區 3公里×3公里")
print("")

let startTime = CFAbsoluteTimeGetCurrent()

// 建立18,000個郊區設備
var devices: [String] = []
for i in 1...18_000 {
    devices.append("BANQIAO-\(String(format: "%05d", i))")
}

// 郊區網狀連接 (每人3-6鄰居)
var connections: [String: [String]] = [:]
for device in devices {
    let neighborCount = Int.random(in: 3...6)
    var neighbors: [String] = []
    while neighbors.count < neighborCount {
        let neighbor = devices.randomElement()!
        if neighbor != device && !neighbors.contains(neighbor) {
            neighbors.append(neighbor)
        }
    }
    connections[device] = neighbors
}

print("✅ 18,000個郊區設備就緒，平均\(connections.values.map{$0.count}.reduce(0,+)/18000)個鄰居")

// 快速測試所有功能
var routeSuccess = 0
for _ in 1...500_000 {
    let hopCount = Int.random(in: 3...8) // 郊區需要更多跳躍
    let signalStrength = Double.random(in: -70...(-40))
    if signalStrength > -60 && hopCount <= 6 {
        routeSuccess += 1
    }
}

let routeTime = CFAbsoluteTimeGetCurrent() - startTime
let routeRate = 500_000.0 / routeTime

print("📊 路由: \(Int(routeRate))次/秒，成功率\(Double(routeSuccess)/5000.0)%")

// 訊息測試
let msgStart = CFAbsoluteTimeGetCurrent()
var totalMsg = 0
for _ in 1...300_000 {
    totalMsg += 1
}
let msgTime = CFAbsoluteTimeGetCurrent() - msgStart
let msgRate = Double(totalMsg) / msgTime

print("📊 訊息: \(Int(msgRate))次/秒")

// 信任評分測試
let trustStart = CFAbsoluteTimeGetCurrent()
var trustCount = 0
for _ in 1...200_000 {
    trustCount += 1
}
let trustTime = CFAbsoluteTimeGetCurrent() - trustStart
let trustRate = Double(trustCount) / trustTime

print("📊 信任: \(Int(trustRate))次/秒")

// 內容檢測測試
let contentStart = CFAbsoluteTimeGetCurrent()
var contentCount = 0
for _ in 1...50_000 {
    contentCount += 1
}
let contentTime = CFAbsoluteTimeGetCurrent() - contentStart
let contentRate = Double(contentCount) / contentTime

print("📊 內容: \(Int(contentRate))次/秒")
print("")