import Foundation
import Combine

// MARK: - 緊急訊息速率限制器
/// 專門為緊急訊息設計的特殊速率限制，保持高優先級但防止濫用
class EmergencyRateLimiter: ObservableObject {
    
    // MARK: - 配置
    private struct EmergencyConfig {
        static let maxEmergencyPerMinute = 5        // 每分鐘最多5個緊急訊息
        static let maxEmergencyPer5Minutes = 10     // 每5分鐘最多10個緊急訊息
        static let maxEmergencyPerHour = 20         // 每小時最多20個緊急訊息
        static let emergencyBurstWindow: TimeInterval = 10.0   // 10秒內最多2個
        static let maxEmergencyBurst = 2            // 爆發窗口內最大數量
        static let emergencyBanDuration: TimeInterval = 3600   // 濫用者封禁1小時
    }
    
    // MARK: - 緊急訊息追蹤
    private var emergencyTracker: [String: [Date]] = [:]  // 節點 -> 緊急訊息時間戳
    private var emergencyViolators: [String: Date] = [:]  // 濫用者封禁記錄
    private var emergencyBurstTracker: [String: [Date]] = [:] // 爆發追蹤
    private let lock = NSLock()
    
    // MARK: - 統計資料
    @Published var emergencyMessagesAllowed: Int = 0
    @Published var emergencyMessagesBlocked: Int = 0
    @Published var emergencyViolatorsCount: Int = 0
    
    // MARK: - 緊急訊息速率檢查
    /// 檢查緊急訊息是否應該被阻止
    /// 即使是緊急訊息也需要基本的濫用防護
    func shouldAllowEmergencyMessage(from peerID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        
        // 1. 檢查是否被封禁（濫用緊急訊息者）
        if let banUntil = emergencyViolators[peerID] {
            if now < banUntil {
                emergencyMessagesBlocked += 1
                print("🚫 緊急訊息濫用者被封禁: \(peerID)，封禁至: \(banUntil)")
                
                // 記錄安全事件
                logSecurityEvent(
                    eventType: "emergency_message_abuse_blocked",
                    peerID: peerID,
                    details: "已封禁的緊急訊息濫用者嘗試發送緊急訊息"
                )
                
                return false
            } else {
                // 封禁期滿，移除記錄
                emergencyViolators.removeValue(forKey: peerID)
                updateViolatorsCount()
                print("✅ 緊急訊息濫用者封禁期滿: \(peerID)")
            }
        }
        
        // 2. 檢查爆發限制（10秒內最多2個）
        let burstCutoff = now.addingTimeInterval(-EmergencyConfig.emergencyBurstWindow)
        emergencyBurstTracker[peerID] = emergencyBurstTracker[peerID]?.filter { $0 > burstCutoff } ?? []
        
        if emergencyBurstTracker[peerID]?.count ?? 0 >= EmergencyConfig.maxEmergencyBurst {
            emergencyMessagesBlocked += 1
            print("⚠️ 緊急訊息爆發限制觸發: \(peerID)，10秒內超過\(EmergencyConfig.maxEmergencyBurst)個")
            
            // 記錄違規但不立即封禁
            logSecurityEvent(
                eventType: "emergency_burst_limit_exceeded",
                peerID: peerID,
                details: "緊急訊息爆發限制超出 - 10秒內超過\(EmergencyConfig.maxEmergencyBurst)個"
            )
            
            return false
        }
        
        // 3. 檢查時間窗口限制
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        // 清理過期記錄
        emergencyTracker[peerID] = emergencyTracker[peerID]?.filter { $0 > oneHourAgo } ?? []
        
        let emergencyTimes = emergencyTracker[peerID] ?? []
        let recentEmergencies1min = emergencyTimes.filter { $0 > oneMinuteAgo }.count
        let recentEmergencies5min = emergencyTimes.filter { $0 > fiveMinutesAgo }.count
        let recentEmergencies1hour = emergencyTimes.count
        
        // 4. 分級檢查
        if recentEmergencies1min >= EmergencyConfig.maxEmergencyPerMinute {
            emergencyMessagesBlocked += 1
            print("🚫 緊急訊息1分鐘限制觸發: \(peerID)，\(recentEmergencies1min)/\(EmergencyConfig.maxEmergencyPerMinute)")
            
            // 考慮暫時標記為可疑
            logSecurityEvent(
                eventType: "emergency_minute_limit_exceeded",
                peerID: peerID,
                details: "緊急訊息每分鐘限制超出: \(recentEmergencies1min)/\(EmergencyConfig.maxEmergencyPerMinute)"
            )
            
            return false
        }
        
        if recentEmergencies5min >= EmergencyConfig.maxEmergencyPer5Minutes {
            emergencyMessagesBlocked += 1
            print("🚫 緊急訊息5分鐘限制觸發: \(peerID)，\(recentEmergencies5min)/\(EmergencyConfig.maxEmergencyPer5Minutes)")
            
            logSecurityEvent(
                eventType: "emergency_5minute_limit_exceeded",
                peerID: peerID,
                details: "緊急訊息每5分鐘限制超出: \(recentEmergencies5min)/\(EmergencyConfig.maxEmergencyPer5Minutes)"
            )
            
            return false
        }
        
        if recentEmergencies1hour >= EmergencyConfig.maxEmergencyPerHour {
            emergencyMessagesBlocked += 1
            
            // 嚴重濫用 - 封禁1小時
            banEmergencyAbuser(peerID)
            
            print("🚨 緊急訊息嚴重濫用，執行封禁: \(peerID)，\(recentEmergencies1hour)/\(EmergencyConfig.maxEmergencyPerHour)")
            
            logSecurityEvent(
                eventType: "emergency_abuse_ban_applied",
                peerID: peerID,
                details: "緊急訊息嚴重濫用，封禁1小時: \(recentEmergencies1hour)/\(EmergencyConfig.maxEmergencyPerHour)"
            )
            
            return false
        }
        
        // 5. 通過所有檢查，允許緊急訊息
        emergencyTracker[peerID, default: []].append(now)
        emergencyBurstTracker[peerID, default: []].append(now)
        emergencyMessagesAllowed += 1
        
        print("✅ 緊急訊息通過檢查: \(peerID)")
        return true
    }
    
    // MARK: - 封禁管理
    
    /// 封禁緊急訊息濫用者
    private func banEmergencyAbuser(_ peerID: String) {
        let banUntil = Date().addingTimeInterval(EmergencyConfig.emergencyBanDuration)
        emergencyViolators[peerID] = banUntil
        updateViolatorsCount()
        
        print("🚨 封禁緊急訊息濫用者: \(peerID)，封禁至: \(banUntil)")
    }
    
    /// 手動解封緊急訊息濫用者
    func unbanEmergencyAbuser(_ peerID: String) {
        emergencyViolators.removeValue(forKey: peerID)
        updateViolatorsCount()
        print("✅ 手動解封緊急訊息濫用者: \(peerID)")
    }
    
    /// 獲取被封禁的緊急訊息濫用者
    func getBannedEmergencyAbusers() -> [String: Date] {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        emergencyViolators = emergencyViolators.filter { $0.value > now }
        return emergencyViolators
    }
    
    /// 清除所有封禁
    func clearAllEmergencyBans() {
        lock.lock()
        defer { lock.unlock() }
        
        emergencyViolators.removeAll()
        updateViolatorsCount()
        print("🧹 清除所有緊急訊息濫用者封禁")
    }
    
    // MARK: - 統計管理
    
    /// 獲取緊急訊息統計
    func getEmergencyStats() -> EmergencyMessageStats {
        lock.lock()
        defer { lock.unlock() }
        
        return EmergencyMessageStats(
            allowed: emergencyMessagesAllowed,
            blocked: emergencyMessagesBlocked,
            violatorsCount: emergencyViolators.count,
            blockingRate: emergencyMessagesBlocked + emergencyMessagesAllowed > 0 
                ? Double(emergencyMessagesBlocked) / Double(emergencyMessagesBlocked + emergencyMessagesAllowed)
                : 0.0
        )
    }
    
    /// 重置統計
    func resetEmergencyStats() {
        lock.lock()
        defer { lock.unlock() }
        
        emergencyMessagesAllowed = 0
        emergencyMessagesBlocked = 0
        emergencyTracker.removeAll()
        emergencyBurstTracker.removeAll()
        
        print("📊 緊急訊息統計已重置")
    }
    
    /// 獲取節點的緊急訊息歷史
    func getEmergencyHistory(for peerID: String) -> [Date] {
        lock.lock()
        defer { lock.unlock() }
        
        return emergencyTracker[peerID] ?? []
    }
    
    // MARK: - 私有方法
    
    private func updateViolatorsCount() {
        DispatchQueue.main.async {
            self.emergencyViolatorsCount = self.emergencyViolators.count
        }
    }
    
    /// 記錄安全事件
    private func logSecurityEvent(eventType: String, peerID: String, details: String) {
        // 使用通知機制記錄安全事件，避免循環依賴
        NotificationCenter.default.post(
            name: NSNotification.Name("SecurityEvent"),
            object: nil,
            userInfo: [
                "event": eventType,
                "source": "EmergencyRateLimiter",
                "peerID": peerID,
                "details": details,
                "timestamp": Date()
            ]
        )
    }
    
    // MARK: - 清理任務
    
    /// 執行定期清理
    func performCleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        // 清理過期的緊急訊息記錄
        for (peerID, timestamps) in emergencyTracker {
            let validTimestamps = timestamps.filter { $0 > oneHourAgo }
            if validTimestamps.isEmpty {
                emergencyTracker.removeValue(forKey: peerID)
            } else {
                emergencyTracker[peerID] = validTimestamps
            }
        }
        
        // 清理過期的爆發追蹤記錄
        let tenMinutesAgo = now.addingTimeInterval(-600)
        for (peerID, timestamps) in emergencyBurstTracker {
            let validTimestamps = timestamps.filter { $0 > tenMinutesAgo }
            if validTimestamps.isEmpty {
                emergencyBurstTracker.removeValue(forKey: peerID)
            } else {
                emergencyBurstTracker[peerID] = validTimestamps
            }
        }
        
        // 清理過期的封禁記錄
        emergencyViolators = emergencyViolators.filter { $0.value > now }
        updateViolatorsCount()
        
        print("🧹 緊急訊息速率限制器清理完成")
    }
}

// MARK: - 緊急訊息統計結構
struct EmergencyMessageStats {
    let allowed: Int
    let blocked: Int
    let violatorsCount: Int
    let blockingRate: Double
}

