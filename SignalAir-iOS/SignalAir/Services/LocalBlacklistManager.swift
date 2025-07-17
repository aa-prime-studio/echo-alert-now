import Foundation
import SwiftUI

// MARK: - 本地黑名單管理器
/// 斷網環境下的本地用戶封禁系統
class LocalBlacklistManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var blacklistedUsers: [BlacklistedUser] = []
    
    // MARK: - Configuration
    private let userDefaultsKey = "local_blacklist"
    private let maxBlacklistSize = 1000 // 防止過度膨脹
    
    // MARK: - Initialization
    init() {
        loadBlacklist()
        print("📵 LocalBlacklistManager: 本地黑名單系統已初始化")
    }
    
    // MARK: - Public Methods
    
    /// 添加用戶到黑名單
    func addToBlacklist(deviceName: String, deviceUUID: String? = nil) {
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        
        // 檢查是否已存在
        if isBlacklisted(deviceName: normalizedName) {
            print("⚠️ 用戶已在黑名單中: \(normalizedName)")
            return
        }
        
        let blacklistedUser = BlacklistedUser(
            deviceName: normalizedName,
            deviceUUID: deviceUUID,
            blockedAt: Date()
        )
        
        blacklistedUsers.append(blacklistedUser)
        saveBlacklist()
        
        print("🚫 已添加到黑名單: \(normalizedName)")
    }
    
    /// 從黑名單移除用戶
    func removeFromBlacklist(userId: String) {
        if let index = blacklistedUsers.firstIndex(where: { $0.id.uuidString == userId }) {
            let removedUser = blacklistedUsers.remove(at: index)
            saveBlacklist()
            print("✅ 已從黑名單移除: \(removedUser.deviceName)")
        }
    }
    
    /// 檢查用戶是否在黑名單中（根據暱稱）
    func isBlacklisted(deviceName: String) -> Bool {
        let normalizedName = NicknameFormatter.cleanNickname(deviceName)
        return blacklistedUsers.contains { user in
            user.deviceName == normalizedName
        }
    }
    
    /// 檢查用戶是否在黑名單中（根據設備UUID）
    func isBlacklisted(deviceUUID: String) -> Bool {
        return blacklistedUsers.contains { user in
            user.deviceUUID == deviceUUID
        }
    }
    
    /// 獲取黑名單統計
    func getBlacklistStats() -> BlacklistStats {
        return BlacklistStats(
            totalBlocked: blacklistedUsers.count,
            blockedToday: blacklistedUsers.filter { Calendar.current.isDateInToday($0.blockedAt) }.count,
            oldestBlock: blacklistedUsers.map { $0.blockedAt }.min()
        )
    }
    
    /// 清空黑名單
    func clearBlacklist() {
        blacklistedUsers.removeAll()
        saveBlacklist()
        print("🧹 黑名單已清空")
    }
    
    // MARK: - Private Methods
    
    /// 從本地存儲載入黑名單
    private func loadBlacklist() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([BlacklistedUser].self, from: data) else {
            print("📂 未找到本地黑名單數據，使用空列表")
            return
        }
        
        blacklistedUsers = decoded
        print("📂 已載入 \(blacklistedUsers.count) 個黑名單用戶")
    }
    
    /// 保存黑名單到本地存儲
    private func saveBlacklist() {
        // 限制黑名單大小
        if blacklistedUsers.count > maxBlacklistSize {
            blacklistedUsers = Array(blacklistedUsers.suffix(maxBlacklistSize))
        }
        
        do {
            let encoded = try JSONEncoder().encode(blacklistedUsers)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 黑名單已保存: \(blacklistedUsers.count) 個用戶")
        } catch {
            print("❌ 保存黑名單失敗: \(error)")
        }
    }
}

// MARK: - 數據模型

/// 黑名單用戶
struct BlacklistedUser: Codable, Identifiable {
    let id: UUID
    let deviceName: String
    let deviceUUID: String?
    let blockedAt: Date
    
    init(deviceName: String, deviceUUID: String? = nil, blockedAt: Date) {
        self.id = UUID()
        self.deviceName = deviceName
        self.deviceUUID = deviceUUID
        self.blockedAt = blockedAt
    }
}

/// 黑名單統計
struct BlacklistStats {
    let totalBlocked: Int
    let blockedToday: Int
    let oldestBlock: Date?
}

// MARK: - 擴展現有的 NicknameFormatter
extension NicknameFormatter {
    /// 檢查暱稱是否被本地封禁
    static func isLocallyBlacklisted(_ nickname: String) -> Bool {
        // 這個方法會在整合時實現
        return false
    }
}