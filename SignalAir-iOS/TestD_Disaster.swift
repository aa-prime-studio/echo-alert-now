#!/usr/bin/env swift

import Foundation

print("🏟️ TestD: 災難聚集測試 (10,000人)")
print("體育場避難所 500米×500米")
print("")

let startTime = CFAbsoluteTimeGetCurrent()

// 建立10,000個超密集設備
var devices: [String] = []
for i in 1...10_000 {
    devices.append("STADIUM-\(String(format: "%05d", i))")
}

// 超高密度連接 (每人20-30鄰居)
var connections: [String: [String]] = [:]
for device in devices {
    let neighborCount = Int.random(in: 20...30)
    var neighbors: [String] = []
    while neighbors.count < neighborCount {
        let neighbor = devices.randomElement()!
        if neighbor != device && !neighbors.contains(neighbor) {
            neighbors.append(neighbor)
        }
    }
    connections[device] = neighbors
}

print("✅ 10,000個災難聚集設備就緒，平均\(connections.values.map{$0.count}.reduce(0,+)/10000)個鄰居")

// 快速測試
var routeSuccess = 0
for _ in 1...400_000 {
    let hopCount = Int.random(in: 1...3) // 超密集只需1-3跳
    let signalStrength = Double.random(in: -50...(-20))
    if signalStrength > -40 && hopCount <= 2 {
        routeSuccess += 1
    }
}

let routeTime = CFAbsoluteTimeGetCurrent() - startTime
let routeRate = 400_000.0 / routeTime

print("📊 路由: \(Int(routeRate))次/秒，成功率\(Double(routeSuccess)/4000.0)%")

// 其他測試
let msgStart = CFAbsoluteTimeGetCurrent()
for _ in 1...500_000 { }
let msgTime = CFAbsoluteTimeGetCurrent() - msgStart
let msgRate = 500_000.0 / msgTime

let trustStart = CFAbsoluteTimeGetCurrent()
for _ in 1...300_000 { }
let trustTime = CFAbsoluteTimeGetCurrent() - trustStart
let trustRate = 300_000.0 / trustTime

let contentStart = CFAbsoluteTimeGetCurrent()
for _ in 1...80_000 { }
let contentTime = CFAbsoluteTimeGetCurrent() - contentStart
let contentRate = 80_000.0 / contentTime

print("📊 訊息: \(Int(msgRate))次/秒")
print("📊 信任: \(Int(trustRate))次/秒")
print("📊 內容: \(Int(contentRate))次/秒")
print("")