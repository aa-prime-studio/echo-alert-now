#!/usr/bin/env swift

import Foundation

print("🎯 TestA: 密集市區測試")
print("場景: 台北西門町 10,000人")
print("範圍: 1公里×1公里")
print("連接: 每人8-15鄰居")
print("")

let startTime = CFAbsoluteTimeGetCurrent()

// 建立10,000個設備 (密集市區)
print("📱 建立10,000個市區設備...")
var devices: [String] = []
for i in 1...10_000 {
    devices.append("TAIPEI-\(String(format: "%05d", i))")
}
print("✅ 建立完成: \(devices.count)個設備")
print("")

// 模擬密集網狀連接 (每人8-15鄰居)
print("🔗 建立密集網狀連接...")
var connections: [String: [String]] = [:]
for device in devices {
    let neighborCount = Int.random(in: 8...15) // 密集市區
    var neighbors: [String] = []
    
    // 隨機選擇鄰居
    while neighbors.count < neighborCount {
        let neighbor = devices.randomElement()!
        if neighbor != device && !neighbors.contains(neighbor) {
            neighbors.append(neighbor)
        }
    }
    connections[device] = neighbors
}
print("✅ 連接建立完成，平均每設備\(connections.values.map{$0.count}.reduce(0,+)/10000)個鄰居")
print("")

// 測試1: 路由查詢 (密集網路)
print("🔄 測試1: 路由查詢 (100萬次)")
var routeSuccess = 0
for i in 1...1_000_000 {
    let source = devices.randomElement()!
    let target = devices.randomElement()!
    
    // 模擬密集網路路由 (短跳躍)
    let hopCount = Int.random(in: 2...5) // 密集網路只需2-5跳
    let signalStrength = Double.random(in: -60...(-30)) // 市區信號較強
    
    if signalStrength > -50 && hopCount <= 4 {
        routeSuccess += 1
    }
    
    if i % 200_000 == 0 {
        let progress = Double(i) / 1_000_000 * 100
        print("   進度: \(Int(progress))% - 成功率: \(Double(routeSuccess)/Double(i)*100)%")
    }
}

let routeTime = CFAbsoluteTimeGetCurrent() - startTime
let routeRate = 1_000_000.0 / routeTime

print("📊 路由測試結果:")
print("   查詢數: 1,000,000")
print("   成功數: \(routeSuccess)")
print("   成功率: \(Double(routeSuccess)/10000.0)%")
print("   速度: \(Int(routeRate))查詢/秒")
print("   目標: >10,000,000查詢/秒 \(routeRate > 10_000_000 ? "✅" : "❌")")
print("")