import Foundation

struct LocalStatistics: Codable {
    // 網路效能統計
    var totalLatencySum: TimeInterval = 0
    var latencyCount: Int = 0
    var successfulConnections: Int = 0
    var totalConnectionAttempts: Int = 0
    var avgConnections: Int = 0
    var totalRouteQueries: Int = 0
    
    // 訊息統計
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var emergencyMessages: Int = 0
    var successfulMessageDeliveries: Int = 0
    
    // 使用統計
    var totalUsageHours: Double = 0
    var bingoGamesPlayed: Int = 0
    var trustScoreUpdates: Int = 0
    var contentDetections: Int = 0
    
    // 系統健康
    var crashCount: Int = 0
    var batteryDrainSum: Double = 0
    var batteryDrainCount: Int = 0
    var peakMemoryUsage: Int = 0
    var lastUpdated: Date = Date()
    
    // 計算屬性
    var avgLatency: TimeInterval {
        return latencyCount > 0 ? totalLatencySum / TimeInterval(latencyCount) : 0
    }
    
    var successRate: Double {
        return totalConnectionAttempts > 0 ? Double(successfulConnections) / Double(totalConnectionAttempts) : 0
    }
    
    var messageSuccessRate: Double {
        return messagesSent > 0 ? Double(successfulMessageDeliveries) / Double(messagesSent) : 0
    }
    
    var avgBatteryDrain: Double {
        return batteryDrainCount > 0 ? batteryDrainSum / Double(batteryDrainCount) : 0
    }
    
    // 記錄方法
    mutating func recordLatency(_ latency: TimeInterval) {
        totalLatencySum += latency
        latencyCount += 1
    }
    
    mutating func recordConnection(_ success: Bool) {
        totalConnectionAttempts += 1
        if success {
            successfulConnections += 1
        }
    }
    
    mutating func recordBatteryDrain(_ percentage: Double) {
        batteryDrainSum += percentage
        batteryDrainCount += 1
    }
    
    // 匯出為可讀格式
    func generateReadableReport() -> String {
        return """
        === SignalAir 本地統計報告 ===
        
        網路效能:
        - 平均延遲: \(Int(avgLatency * 1000))ms
        - 連接成功率: \(String(format: "%.1f", successRate * 100))%
        - 平均連接數: \(avgConnections)
        - 總路由查詢: \(totalRouteQueries)
        
        訊息統計:
        - 發送訊息: \(messagesSent)
        - 接收訊息: \(messagesReceived)
        - 緊急訊息: \(emergencyMessages)
        - 訊息成功率: \(String(format: "%.1f", messageSuccessRate * 100))%
        
        使用統計:
        - 總使用時間: \(String(format: "%.1f", totalUsageHours))小時
        - Bingo遊戲: \(bingoGamesPlayed)次
        - 信任評分更新: \(trustScoreUpdates)次
        - 內容檢測: \(contentDetections)次
        
        系統健康:
        - 崩潰次數: \(crashCount)
        - 平均電池消耗: \(String(format: "%.1f", avgBatteryDrain))%/小時
        - 記憶體峰值: \(peakMemoryUsage)MB
        
        最後更新: \(lastUpdated.formatted())
        """
    }
}