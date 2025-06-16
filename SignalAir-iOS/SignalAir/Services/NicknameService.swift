import Foundation
import SwiftUI

class NicknameService: ObservableObject {
    @Published var nickname: String
    @Published var remainingChanges: Int
    
    private let userDefaults = UserDefaults.standard
    private let nicknameKey = "user_nickname"
    private let remainingChangesKey = "nickname_remaining_changes"
    
    init() {
        // 從 UserDefaults 讀取，如果沒有則使用裝置名稱作為預設暱稱
        self.nickname = userDefaults.string(forKey: nicknameKey) ?? UIDevice.current.name
        
        // 檢查是否第一次使用，如果是則給予3次修改機會
        if userDefaults.object(forKey: remainingChangesKey) == nil {
            self.remainingChanges = 3
            userDefaults.set(3, forKey: remainingChangesKey)
        } else {
            self.remainingChanges = userDefaults.integer(forKey: remainingChangesKey)
        }
    }
    
    func updateNickname(_ newNickname: String) -> Bool {
        guard remainingChanges > 0 else { return false }
        guard !newNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard newNickname.count <= 20 else { return false } // 限制暱稱長度
        
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 只有在暱稱真的改變時才扣除次數
        if trimmedNickname != self.nickname {
            self.nickname = trimmedNickname
            self.remainingChanges -= 1
            
            // 儲存到 UserDefaults
            userDefaults.set(trimmedNickname, forKey: nicknameKey)
            userDefaults.set(remainingChanges, forKey: remainingChangesKey)
            
            return true
        }
        
        return false
    }
    
    func canChangeNickname() -> Bool {
        return remainingChanges > 0
    }
    
    func getRemainingChangesText() -> String {
        if remainingChanges > 0 {
            return "剩餘 \(remainingChanges) 次修改機會"
        } else {
            return "已用完修改次數"
        }
    }
} 