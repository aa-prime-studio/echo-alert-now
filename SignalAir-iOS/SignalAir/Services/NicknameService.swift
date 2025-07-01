import Foundation
import SwiftUI

class NicknameService: ObservableObject {
    @Published var nickname: String
    @Published var remainingChanges: Int
    @Published var discriminator: String
    @Published var discriminatorType: DiscriminatorType
    
    enum DiscriminatorType: String, CaseIterable {
        case numeric = "numeric"
        case base32 = "base32"
    }
    
    private let userDefaults = UserDefaults.standard
    private let nicknameKey = "user_nickname"
    private let remainingChangesKey = "nickname_remaining_changes"
    private let discriminatorKey = "userDiscriminator"
    private let discriminatorTypeKey = "discriminatorType"
    // 移除對舊TemporaryIDManager的依賴，改用ServiceContainer
    private func getDeviceID() -> String {
        return ServiceContainer.shared.temporaryIDManager.deviceID
    }
    
    init() {
        // 從 UserDefaults 讀取，如果沒有則使用預設暱稱
        self.nickname = userDefaults.string(forKey: nicknameKey) ?? "使用者"
        
        // 檢查是否第一次使用，如果是則給予3次修改機會
        if userDefaults.object(forKey: remainingChangesKey) == nil {
            self.remainingChanges = 3
            userDefaults.set(3, forKey: remainingChangesKey)
        } else {
            self.remainingChanges = userDefaults.integer(forKey: remainingChangesKey)
        }
        
        // 載入 discriminator 類型
        let typeString = userDefaults.string(forKey: discriminatorTypeKey) ?? DiscriminatorType.numeric.rawValue
        let loadedType = DiscriminatorType(rawValue: typeString) ?? .numeric
        self.discriminatorType = loadedType
        
        // 載入或生成 discriminator
        if let savedDiscriminator = userDefaults.string(forKey: discriminatorKey), !savedDiscriminator.isEmpty {
            self.discriminator = savedDiscriminator
            
            // 實機測試階段：檢查是否為舊數字格式，直接升級到Base32
            if isNumericFormat(savedDiscriminator) && loadedType == .numeric {
                print("🏷️ NicknameService: 偵測到舊數字格式 discriminator = \(savedDiscriminator)，實機測試階段直接升級到Base32格式")
                // 升級到Base32格式
                self.discriminatorType = .base32
                self.discriminator = Self.generateDiscriminator(type: .base32)
                // 保存新設定
                userDefaults.set(DiscriminatorType.base32.rawValue, forKey: discriminatorTypeKey)
                userDefaults.set(self.discriminator, forKey: discriminatorKey)
            }
        } else {
            // 首次載入時自動分配 discriminator (新用戶直接使用Base32)
            let targetType: DiscriminatorType = .base32  // 新用戶直接使用Base32
            let generatedDiscriminator = Self.generateDiscriminator(type: targetType)
            self.discriminator = generatedDiscriminator
            self.discriminatorType = targetType
            userDefaults.set(generatedDiscriminator, forKey: discriminatorKey)
            userDefaults.set(targetType.rawValue, forKey: discriminatorTypeKey)
        }
    }
    
    func updateNickname(_ newNickname: String) -> Bool {
        guard remainingChanges > 0 else { return false }
        guard !newNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard newNickname.count <= 8 else { return false } // 限制暱稱長度
        
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 只有在暱稱真的改變時才扣除次數
        if trimmedNickname != self.nickname {
            let oldNickname = self.nickname
            self.nickname = trimmedNickname
            self.remainingChanges -= 1
            
            // 儲存到 UserDefaults
            userDefaults.set(trimmedNickname, forKey: nicknameKey)
            userDefaults.set(remainingChanges, forKey: remainingChangesKey)
            
            // 發送暱稱變更通知給所有界面
            NotificationCenter.default.post(
                name: Notification.Name("NicknameDidChange"),
                object: nil,
                userInfo: [
                    "oldNickname": oldNickname,
                    "newNickname": trimmedNickname,
                    "discriminator": discriminator,
                    "remainingChanges": remainingChanges
                ]
            )
            
            print("📢 NicknameService: 暱稱已更新為「\(trimmedNickname)」並發送通知")
            
            return true
        }
        
        return false
    }
    
    func canChangeNickname() -> Bool {
        return remainingChanges > 0
    }
    
    func getRemainingChangesText(languageService: LanguageService? = nil) -> String {
        if remainingChanges > 0 {
            if let languageService = languageService {
                return "\(languageService.t("remaining_changes")) \(remainingChanges)"
            } else {
                return "剩餘 \(remainingChanges) 次 ——— 僅3次"
            }
        } else {
            if let languageService = languageService {
                return languageService.t("no_changes_left")
            } else {
                return "已用完修改次數"
            }
        }
    }
    
    func setNickname(_ newNickname: String) {
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
        
        self.nickname = trimmedNickname
        userDefaults.set(trimmedNickname, forKey: nicknameKey)
    }
    
    // MARK: - Discriminator Management
    
    /// 檢查是否為數字格式的 discriminator
    private func isNumericFormat(_ discriminator: String) -> Bool {
        return discriminator.range(of: "^\\d{4}$", options: .regularExpression) != nil
    }
    
    private static func generateDiscriminator(type: DiscriminatorType) -> String {
        switch type {
        case .numeric:
            return String(format: "%04d", Int.random(in: 0...9999))
        case .base32:
            // Base32 字符集 (不包含容易混淆的字符)
            let base32Chars = "ABCDEFGHJKMNPQRSTVWXYZ23456789"
            return String((0..<4).map { _ in base32Chars.randomElement()! })
        }
    }
    
    func switchDiscriminatorType(_ newType: DiscriminatorType) {
        guard newType != discriminatorType else { return }
        
        discriminatorType = newType
        discriminator = Self.generateDiscriminator(type: newType)
        
        // 保存新設定
        userDefaults.set(discriminatorType.rawValue, forKey: discriminatorTypeKey)
        userDefaults.set(discriminator, forKey: discriminatorKey)
    }
    
    // UI 顯示用的完整名稱
    var displayName: String {
        return "\(nickname)#\(discriminator)"
    }
    
    // SignalViewModel 使用的原始暱稱（保持向後相容）
    var userNickname: String {
        return nickname
    }
} 