import Foundation
import Security
import CryptoKit

/// 簡單的 Keychain 測試
class KeychainTest {
    private let service = "com.signalair.keychain.test"
    private let account = "test.key"
    
    /// 測試 Keychain 基本操作
    func runKeychainTest() -> Bool {
        print("🧪 開始 Keychain 測試...")
        
        // 1. 測試儲存
        let testData = "Test Keychain Data".data(using: .utf8)!
        if !saveToKeychain(data: testData) {
            print("❌ Keychain 儲存測試失敗")
            return false
        }
        print("✅ Keychain 儲存測試通過")
        
        // 2. 測試讀取
        guard let retrievedData = loadFromKeychain(),
              String(data: retrievedData, encoding: .utf8) == "Test Keychain Data" else {
            print("❌ Keychain 讀取測試失敗")
            return false
        }
        print("✅ Keychain 讀取測試通過")
        
        // 3. 測試刪除
        if !deleteFromKeychain() {
            print("❌ Keychain 刪除測試失敗")
            return false
        }
        print("✅ Keychain 刪除測試通過")
        
        // 4. 測試安全屬性
        if !testSecurityAttributes() {
            print("❌ Keychain 安全屬性測試失敗")
            return false
        }
        print("✅ Keychain 安全屬性測試通過")
        
        print("🎉 所有 Keychain 測試通過！")
        return true
    }
    
    /// 儲存資料到 Keychain
    private func saveToKeychain(data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 先刪除舊的
        SecItemDelete(query as CFDictionary)
        
        // 添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 從 Keychain 讀取資料
    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return item as? Data
    }
    
    /// 從 Keychain 刪除資料
    private func deleteFromKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// 測試安全屬性
    private func testSecurityAttributes() -> Bool {
        let testData = "Secure Test Data".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".secure",
            kSecAttrAccount as String: account + ".secure",
            kSecValueData as String: testData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 儲存
        SecItemDelete(query as CFDictionary)
        let saveStatus = SecItemAdd(query as CFDictionary, nil)
        
        if saveStatus != errSecSuccess {
            return false
        }
        
        // 讀取並驗證
        let readQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".secure",
            kSecAttrAccount as String: account + ".secure",
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &item)
        
        guard readStatus == errSecSuccess,
              let result = item as? [String: Any],
              let data = result[kSecValueData as String] as? Data,
              let accessible = result[kSecAttrAccessible as String] as? String else {
            return false
        }
        
        // 清理
        SecItemDelete(query as CFDictionary)
        
        // 驗證安全屬性
        return data == testData && accessible == (kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }
}

/// 執行測試
func runKeychainTests() {
    let test = KeychainTest()
    let success = test.runKeychainTest()
    
    if success {
        print("🎯 Keychain 權限檢查：✅ 通過")
    } else {
        print("🎯 Keychain 權限檢查：❌ 失敗")
    }
} 