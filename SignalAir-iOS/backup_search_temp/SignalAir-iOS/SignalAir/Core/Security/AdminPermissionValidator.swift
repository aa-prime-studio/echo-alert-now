import Foundation
import CryptoKit

// MARK: - Admin Permission System

/// 管理員權限驗證器 - 提供安全的管理員認證機制
class AdminPermissionValidator {
    
    // MARK: - 安全設計考量
    
    /// 🔐 安全密碼（實際應用中應從安全儲存讀取）
    private static let adminPasscode = "SignalAir_Admin_2024"
    
    /// 📱 當前管理員會話ID
    private static var currentAdminSession: String?
    
    /// ⏰ 會話過期時間
    private static var sessionExpiry: Date?
    
    /// ⏱️ 會話持續時間（1小時）
    private static let sessionDuration: TimeInterval = 3600
    
    /// 🔒 最大嘗試次數（防暴力破解）
    private static var failedAttempts = 0
    private static let maxFailedAttempts = 5
    private static var lockoutUntil: Date?
    
    // MARK: - 公開方法
    
    /// 驗證管理員權限
    /// - Parameter passcode: 管理員密碼
    /// - Returns: 是否驗證成功
    static func authenticateAdmin(passcode: String) -> Bool {
        // 檢查是否被鎖定
        if let lockout = lockoutUntil, Date() < lockout {
            let remainingTime = Int(lockout.timeIntervalSinceNow)
            print("🔒 AdminValidator: 帳戶被鎖定，剩餘時間: \(remainingTime)秒")
            return false
        }
        
        // 驗證密碼
        guard passcode == adminPasscode else {
            failedAttempts += 1
            print("🚨 AdminValidator: 管理員認證失敗 (嘗試 \(failedAttempts)/\(maxFailedAttempts))")
            
            // 達到最大嘗試次數，鎖定帳戶
            if failedAttempts >= maxFailedAttempts {
                lockoutUntil = Date().addingTimeInterval(900) // 鎖定15分鐘
                print("🔒 AdminValidator: 帳戶已鎖定15分鐘")
            }
            return false
        }
        
        // 認證成功，重置失敗計數
        failedAttempts = 0
        lockoutUntil = nil
        
        // 創建新的管理員會話
        currentAdminSession = UUID().uuidString
        sessionExpiry = Date().addingTimeInterval(sessionDuration)
        
        print("✅ AdminValidator: 管理員認證成功，會話ID: \(currentAdminSession?.prefix(8) ?? "unknown")")
        return true
    }
    
    /// 檢查當前是否有有效的管理員會話
    static func hasValidAdminSession() -> Bool {
        guard let expiry = sessionExpiry,
              currentAdminSession != nil,
              Date() < expiry else {
            if currentAdminSession != nil {
                print("⏰ AdminValidator: 管理員會話已過期")
                logoutAdmin()
            }
            return false
        }
        return true
    }
    
    /// 登出管理員會話
    static func logoutAdmin() {
        if currentAdminSession != nil {
            print("👋 AdminValidator: 管理員已登出")
        }
        currentAdminSession = nil
        sessionExpiry = nil
    }
    
    /// 獲取會話剩餘時間
    static func getSessionRemainingTime() -> TimeInterval? {
        guard let expiry = sessionExpiry, hasValidAdminSession() else {
            return nil
        }
        return expiry.timeIntervalSinceNow
    }
    
    /// 獲取會話狀態資訊
    static func getSessionInfo() -> AdminSessionInfo {
        return AdminSessionInfo(
            isActive: hasValidAdminSession(),
            sessionId: currentAdminSession?.prefix(8).description,
            remainingTime: getSessionRemainingTime(),
            isLocked: lockoutUntil != nil && Date() < lockoutUntil!,
            failedAttempts: failedAttempts
        )
    }
}

// MARK: - 支援結構

/// 管理員會話資訊
struct AdminSessionInfo {
    let isActive: Bool
    let sessionId: String?
    let remainingTime: TimeInterval?
    let isLocked: Bool
    let failedAttempts: Int
    
    var statusDescription: String {
        if isLocked {
            return "🔒 帳戶已鎖定"
        } else if isActive {
            let minutes = Int((remainingTime ?? 0) / 60)
            return "✅ 活躍會話 (剩餘 \(minutes) 分鐘)"
        } else {
            return "❌ 未認證"
        }
    }
}

// MARK: - 使用範例和安全說明

/*
 🛡️ 安全設計說明：
 
 1. **會話管理**：
    - 每次認證創建唯一會話ID
    - 會話自動過期（1小時）
    - 支援主動登出
 
 2. **暴力破解防護**：
    - 限制失敗嘗試次數（5次）
    - 達到限制後鎖定帳戶（15分鐘）
    - 成功認證後重置計數
 
 3. **審計追蹤**：
    - 記錄所有認證嘗試
    - 追蹤會話狀態變化
    - 提供詳細的狀態資訊
 
 4. **使用方式**：
 
    // 管理員登入
    let success = AdminPermissionValidator.authenticateAdmin(passcode: "密碼")
    
    // 檢查權限
    let hasPermission = AdminPermissionValidator.hasValidAdminSession()
    
    // 安全的API調用
    let messages = viewModel.getRecentProcessedMessages(
        limit: 10,
        includeContent: true,
        hasAdminPermission: hasPermission  // 真實驗證的權限
    )
    
    // 登出
    AdminPermissionValidator.logoutAdmin()
 
 5. **生產環境建議**：
    - 密碼應存儲在 Keychain 中
    - 使用更強的密碼策略
    - 考慮雙因素認證
    - 定期輪換管理員密碼
    - 記錄到安全日誌系統
 */ 