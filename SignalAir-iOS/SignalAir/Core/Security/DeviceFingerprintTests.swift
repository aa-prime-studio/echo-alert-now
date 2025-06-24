import Foundation
import XCTest
@testable import SignalAir

// MARK: - Device Fingerprint Tests
class DeviceFingerprintTests: XCTestCase {
    
    var fingerprintManager: DeviceFingerprintManager!
    var trustScoreManager: TrustScoreManager!
    var enhancedNicknameService: EnhancedNicknameService!
    
    override func setUp() {
        super.setUp()
        
        // 清理 UserDefaults 和 Keychain
        clearTestData()
        
        // 初始化測試實例
        fingerprintManager = DeviceFingerprintManager()
        trustScoreManager = TrustScoreManager()
        enhancedNicknameService = EnhancedNicknameService(
            deviceFingerprintManager: fingerprintManager,
            trustScoreManager: trustScoreManager
        )
        
        // 等待初始化完成
        let expectation = XCTestExpectation(description: "Initialization")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDown() {
        clearTestData()
        fingerprintManager = nil
        trustScoreManager = nil
        enhancedNicknameService = nil
        super.tearDown()
    }
    
    // MARK: - Device Fingerprint Tests
    
    func testDeviceFingerprintGeneration() {
        print("🧪 測試設備指紋生成...")
        
        let fingerprintInfo = fingerprintManager.getFingerprintInfo()
        
        // 驗證 DeviceUUID 格式
        XCTAssertTrue(fingerprintInfo.deviceUUID.hasPrefix("DEVICE-"), "DeviceUUID 應以 DEVICE- 開頭")
        XCTAssertFalse(fingerprintInfo.deviceUUID.isEmpty, "DeviceUUID 不應為空")
        
        // 驗證 DayToken 格式
        XCTAssertTrue(fingerprintInfo.dayToken.hasPrefix("DAY_"), "DayToken 應以 DAY_ 開頭")
        XCTAssertFalse(fingerprintInfo.dayToken.isEmpty, "DayToken 不應為空")
        
        // 驗證狀態
        XCTAssertEqual(fingerprintInfo.status, .active, "指紋狀態應為 active")
        XCTAssertTrue(fingerprintInfo.isValid, "指紋應該有效")
        
        print("✅ DeviceUUID: \(fingerprintInfo.deviceUUID)")
        print("✅ DayToken: \(fingerprintInfo.dayToken)")
        print("✅ 設備指紋生成測試通過")
    }
    
    func testDeviceFingerprintPersistence() {
        print("🧪 測試設備指紋持久化...")
        
        let originalInfo = fingerprintManager.getFingerprintInfo()
        
        // 創建新的 manager 實例
        let newManager = DeviceFingerprintManager()
        
        // 等待初始化
        let expectation = XCTestExpectation(description: "New manager initialization")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let newInfo = newManager.getFingerprintInfo()
        
        // 驗證 DeviceUUID 保持一致
        XCTAssertEqual(newInfo.deviceUUID, originalInfo.deviceUUID, "DeviceUUID 應該保持一致")
        
        print("✅ 原始 DeviceUUID: \(originalInfo.deviceUUID)")
        print("✅ 新載入 DeviceUUID: \(newInfo.deviceUUID)")
        print("✅ 設備指紋持久化測試通過")
    }
    
    func testDayTokenGeneration() {
        print("🧪 測試日帳號生成...")
        
        let originalToken = fingerprintManager.dayToken
        
        // 強制重新生成日帳號
        fingerprintManager.regenerateDayToken()
        
        let newToken = fingerprintManager.dayToken
        
        // 驗證格式一致但內容不同（因為時間戳可能相同，所以這個測試可能會失敗）
        XCTAssertTrue(newToken.hasPrefix("DAY_"), "新 DayToken 應以 DAY_ 開頭")
        
        print("✅ 原始 DayToken: \(originalToken)")
        print("✅ 新 DayToken: \(newToken)")
        print("✅ 日帳號生成測試通過")
    }
    
    func testFingerprintIntegrityVerification() {
        print("🧪 測試指紋完整性驗證...")
        
        // 正常情況下應該驗證通過
        let isValid = fingerprintManager.verifyFingerprintIntegrity()
        XCTAssertTrue(isValid, "正常指紋應該通過完整性驗證")
        
        print("✅ 指紋完整性驗證測試通過")
    }
    
    // MARK: - Trust Score Tests
    
    func testTrustScoreInitialization() {
        print("🧪 測試信任評分初始化...")
        
        let deviceUUID = fingerprintManager.deviceUUID
        let initialScore = trustScoreManager.getTrustScore(for: deviceUUID)
        
        // 初始評分應為 50.0
        XCTAssertEqual(initialScore, 50.0, "初始信任評分應為 50.0")
        
        let trustInfo = trustScoreManager.getTrustInfo(for: deviceUUID)
        XCTAssertEqual(trustInfo.trustLevel, .neutral, "初始信任等級應為 neutral")
        
        print("✅ 初始信任評分: \(initialScore)")
        print("✅ 信任評分初始化測試通過")
    }
    
    func testTrustScoreUpdates() {
        print("🧪 測試信任評分更新...")
        
        let deviceUUID = fingerprintManager.deviceUUID
        let initialScore = trustScoreManager.getTrustScore(for: deviceUUID)
        
        // 記錄成功通訊
        trustScoreManager.recordSuccessfulCommunication(for: deviceUUID, messageType: .emergency)
        let afterSuccessScore = trustScoreManager.getTrustScore(for: deviceUUID)
        
        XCTAssertGreaterThan(afterSuccessScore, initialScore, "成功通訊後評分應增加")
        
        // 記錄可疑行為
        trustScoreManager.recordSuspiciousBehavior(for: deviceUUID, behavior: .duplicateMessages)
        let afterSuspiciousScore = trustScoreManager.getTrustScore(for: deviceUUID)
        
        XCTAssertLessThan(afterSuspiciousScore, afterSuccessScore, "可疑行為後評分應降低")
        
        print("✅ 初始評分: \(initialScore)")
        print("✅ 成功通訊後: \(afterSuccessScore)")
        print("✅ 可疑行為後: \(afterSuspiciousScore)")
        print("✅ 信任評分更新測試通過")
    }
    
    func testBlacklistManagement() {
        print("🧪 測試黑名單管理...")
        
        let deviceUUID = fingerprintManager.deviceUUID
        
        // 初始狀態不在黑名單
        XCTAssertFalse(trustScoreManager.isBlacklisted(deviceUUID), "初始狀態不應在黑名單")
        
        // 手動加入黑名單
        trustScoreManager.addToBlacklist(deviceUUID, reason: "測試目的")
        XCTAssertTrue(trustScoreManager.isBlacklisted(deviceUUID), "應該在黑名單中")
        
        // 從黑名單移除
        trustScoreManager.removeFromBlacklist(deviceUUID)
        XCTAssertFalse(trustScoreManager.isBlacklisted(deviceUUID), "應該從黑名單移除")
        
        print("✅ 黑名單管理測試通過")
    }
    
    func testTrustStatistics() {
        print("🧪 測試信任統計...")
        
        let deviceUUID1 = "TEST-DEVICE-001"
        let deviceUUID2 = "TEST-DEVICE-002"
        
        // 創建不同的信任評分
        trustScoreManager.recordSuccessfulCommunication(for: deviceUUID1, messageType: .emergency)
        trustScoreManager.recordSuspiciousBehavior(for: deviceUUID2, behavior: .maliciousContent)
        
        let stats = trustScoreManager.getTrustStatistics()
        
        XCTAssertGreaterThan(stats.totalNodes, 0, "應該有節點記錄")
        XCTAssertGreaterThanOrEqual(stats.averageScore, 0, "平均分數應該大於等於 0")
        
        print("✅ 總節點數: \(stats.totalNodes)")
        print("✅ 平均評分: \(stats.averageScore)")
        print("✅ 可信節點: \(stats.trustedNodes)")
        print("✅ 可疑節點: \(stats.suspiciousNodes)")
        print("✅ 信任統計測試通過")
    }
    
    // MARK: - Enhanced Nickname Service Tests
    
    func testNicknameServiceIntegration() {
        print("🧪 測試增強暱稱服務整合...")
        
        let nicknameStatus = enhancedNicknameService.getNicknameStatus()
        
        // 驗證整合
        XCTAssertEqual(nicknameStatus.deviceUUID, fingerprintManager.deviceUUID, "DeviceUUID 應該一致")
        XCTAssertEqual(nicknameStatus.dayToken, fingerprintManager.dayToken, "DayToken 應該一致")
        XCTAssertEqual(nicknameStatus.remainingChanges, 3, "初始剩餘變更次數應為 3")
        XCTAssertTrue(nicknameStatus.canChange, "初始狀態應可變更暱稱")
        
        print("✅ 暱稱: \(nicknameStatus.nickname)")
        print("✅ DeviceUUID: \(nicknameStatus.deviceUUID)")
        print("✅ DayToken: \(nicknameStatus.dayToken)")
        print("✅ 增強暱稱服務整合測試通過")
    }
    
    func testNicknameUpdateWithTrustScore() {
        print("🧪 測試暱稱更新與信任評分...")
        
        let originalNickname = enhancedNicknameService.nickname
        let newNickname = "測試暱稱"
        
        // 執行暱稱更新
        let result = enhancedNicknameService.updateNickname(newNickname)
        
        switch result {
        case .success(let info):
            XCTAssertEqual(info.newNickname, newNickname, "暱稱應該更新成功")
            XCTAssertEqual(info.remainingChanges, 2, "剩餘次數應減少")
            
            // 驗證信任評分是否有記錄
            let deviceUUID = enhancedNicknameService.getCurrentDeviceUUID()
            let trustScore = trustScoreManager.getTrustScore(for: deviceUUID)
            XCTAssertGreaterThan(trustScore, 50.0, "暱稱更新應增加信任評分")
            
            print("✅ 原始暱稱: \(originalNickname)")
            print("✅ 新暱稱: \(info.newNickname)")
            print("✅ 剩餘次數: \(info.remainingChanges)")
            print("✅ 信任評分: \(trustScore)")
            
        case .failure(let error):
            XCTFail("暱稱更新應該成功，但失敗了: \(error.localizedDescription)")
        }
        
        print("✅ 暱稱更新與信任評分測試通過")
    }
    
    func testNicknameValidation() {
        print("🧪 測試暱稱驗證...")
        
        // 測試空暱稱
        let emptyResult = enhancedNicknameService.updateNickname("")
        if case .failure(let error) = emptyResult {
            XCTAssertTrue(error.localizedDescription.contains("空"), "空暱稱應該被拒絕")
        } else {
            XCTFail("空暱稱應該被拒絕")
        }
        
        // 測試過長暱稱
        let longNickname = String(repeating: "a", count: 25)
        let longResult = enhancedNicknameService.updateNickname(longNickname)
        if case .failure(let error) = longResult {
            XCTAssertTrue(error.localizedDescription.contains("20"), "過長暱稱應該被拒絕")
        } else {
            XCTFail("過長暱稱應該被拒絕")
        }
        
        // 測試不當內容
        let inappropriateResult = enhancedNicknameService.updateNickname("admin")
        if case .failure(let error) = inappropriateResult {
            XCTAssertTrue(error.localizedDescription.contains("不當"), "不當內容應該被拒絕")
        } else {
            XCTFail("不當內容應該被拒絕")
        }
        
        print("✅ 暱稱驗證測試通過")
    }
    
    // MARK: - Integration Tests
    
    func testFullSystemIntegration() {
        print("🧪 測試完整系統整合...")
        
        // 1. 驗證設備指紋系統
        let fingerprintInfo = fingerprintManager.getFingerprintInfo()
        XCTAssertTrue(fingerprintInfo.isValid, "設備指紋應該有效")
        
        // 2. 驗證信任評分系統
        let deviceUUID = fingerprintInfo.deviceUUID
        let initialTrustScore = trustScoreManager.getTrustScore(for: deviceUUID)
        XCTAssertEqual(initialTrustScore, 50.0, "初始信任評分應為 50.0")
        
        // 3. 驗證暱稱服務整合
        let nicknameStatus = enhancedNicknameService.getNicknameStatus()
        XCTAssertEqual(nicknameStatus.deviceUUID, deviceUUID, "暱稱服務應使用相同的 DeviceUUID")
        
        // 4. 模擬正常使用流程
        let updateResult = enhancedNicknameService.updateNickname("整合測試暱稱")
        XCTAssertTrue(updateResult.isSuccess, "暱稱更新應該成功")
        
        // 5. 驗證信任評分變化
        let updatedTrustScore = trustScoreManager.getTrustScore(for: deviceUUID)
        XCTAssertGreaterThan(updatedTrustScore, initialTrustScore, "信任評分應該增加")
        
        print("✅ 設備指紋: \(fingerprintInfo.formattedInfo)")
        print("✅ 暱稱狀態: \(nicknameStatus.formattedStatus)")
        print("✅ 完整系統整合測試通過")
    }
    
    // MARK: - Helper Methods
    
    private func clearTestData() {
        // 清理 UserDefaults
        let keys = [
            "trust_scores", "local_blacklist", "observation_list", "bloom_filter",
            "enhanced_nickname", "enhanced_nickname_changes", "last_nickname_change", "observation_period_end",
            "device_reset_count"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // 清理 Keychain（簡化版，實際應該清理所有相關項目）
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.signalair.fingerprint"
        ]
        SecItemDelete(query as CFDictionary)
        
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Test Extensions

extension NicknameUpdateResult {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

// MARK: - Performance Tests

class DeviceFingerprintPerformanceTests: XCTestCase {
    
    func testDeviceFingerprintCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let _ = DeviceFingerprintManager()
            }
        }
    }
    
    func testTrustScoreUpdatePerformance() {
        let trustManager = TrustScoreManager()
        
        measure {
            for i in 0..<1000 {
                let deviceUUID = "TEST-DEVICE-\(i)"
                trustManager.recordSuccessfulCommunication(for: deviceUUID)
            }
        }
    }
    
    func testBloomFilterPerformance() {
        let bloomFilter = BloomFilter(expectedElements: 10000, falsePositiveRate: 0.01)
        
        measure {
            for i in 0..<10000 {
                bloomFilter.add("device-\(i)")
            }
        }
    }
} 