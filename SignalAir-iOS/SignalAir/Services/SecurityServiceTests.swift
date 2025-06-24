import Foundation
import Foundation
import CryptoKit

// MARK: - SecurityService Test Suite
class SecurityServiceTests {
    
    // MARK: - Test Methods
    
    /// 測試 SecurityService 初始化
    static func testSecurityServiceInitialization() {
        print("🧪 Testing SecurityService initialization...")
        
        let securityService = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 驗證初始狀態
        assert(securityService.isInitialized, "SecurityService 應該已初始化")
        assert(securityService.activeConnections == 0, "初始時應無活躍連接")
        
        print("✅ SecurityService initialization test passed")
    }
    
    /// 測試公鑰生成
    static func testPublicKeyGeneration() throws {
        print("🧪 Testing public key generation...")
        
        let securityService = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 取得公鑰
        let publicKey = try securityService.getPublicKey()
        
        // 驗證公鑰
        assert(publicKey.count == 32, "Curve25519 公鑰應為 32 bytes")
        
        print("✅ Public key generation test passed")
        print("   - Public key size: \(publicKey.count) bytes")
    }
    
    /// 測試密鑰交換
    static func testKeyExchange() throws {
        print("🧪 Testing key exchange...")
        
        // 建立兩個 SecurityService 實例模擬兩個設備
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 取得公鑰
        let alicePublicKey = try alice.getPublicKey()
        let bobPublicKey = try bob.getPublicKey()
        
        // 執行密鑰交換
        try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
        try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
        
        // 驗證會話密鑰
        assert(alice.hasSessionKey(for: "Bob"), "Alice 應該有 Bob 的會話密鑰")
        assert(bob.hasSessionKey(for: "Alice"), "Bob 應該有 Alice 的會話密鑰")
        assert(alice.activeConnections == 1, "Alice 應該有 1 個活躍連接")
        assert(bob.activeConnections == 1, "Bob 應該有 1 個活躍連接")
        
        print("✅ Key exchange test passed")
    }
    
    /// 測試加密和解密
    static func testEncryptionDecryption() throws {
        print("🧪 Testing encryption and decryption...")
        
        // 建立兩個 SecurityService 實例
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 執行密鑰交換
        let alicePublicKey = try alice.getPublicKey()
        let bobPublicKey = try bob.getPublicKey()
        try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
        try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
        
        // 測試數據
        let originalMessage = "Hello, this is a secret message from Alice to Bob! 🔐"
        let messageData = originalMessage.data(using: .utf8)!
        
        // Alice 加密訊息
        let encryptedMessage = try alice.encrypt(messageData, for: "Bob")
        
        // Bob 解密訊息
        let decryptedData = try bob.decrypt(encryptedMessage.data, from: "Alice")
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)!
        
        // 驗證結果
        assert(decryptedMessage == originalMessage, "解密後的訊息應該與原始訊息相同")
        
        print("✅ Encryption/Decryption test passed")
        print("   - Original: \(originalMessage)")
        print("   - Decrypted: \(decryptedMessage)")
        print("   - Encrypted size: \(encryptedMessage.ciphertext.count) bytes")
    }
    
    /// 測試 Forward Secrecy（密鑰輪轉）
    static func testForwardSecrecy() throws {
        print("🧪 Testing Forward Secrecy...")
        
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 執行密鑰交換
        let alicePublicKey = try alice.getPublicKey()
        let bobPublicKey = try bob.getPublicKey()
        try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
        try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
        
        // 發送多條訊息測試密鑰輪轉
        var messageNumbers: [UInt64] = []
        
        for i in 1...5 {
            let message = "Message \(i)"
            let messageData = message.data(using: .utf8)!
            
            // Alice 加密
            let encrypted = try alice.encrypt(messageData, for: "Bob")
            messageNumbers.append(encrypted.messageNumber)
            
            // Bob 解密
            let decrypted = try bob.decrypt(encrypted.data, from: "Alice")
            let decryptedMessage = String(data: decrypted, encoding: .utf8)!
            
            assert(decryptedMessage == message, "訊息 \(i) 解密失敗")
        }
        
        // 驗證訊息號碼遞增（證明密鑰輪轉）
        for i in 1..<messageNumbers.count {
            assert(messageNumbers[i] > messageNumbers[i-1], "訊息號碼應該遞增")
        }
        
        print("✅ Forward Secrecy test passed")
        print("   - Message numbers: \(messageNumbers)")
    }
    
    /// 測試防重放攻擊
    static func testReplayProtection() throws {
        print("🧪 Testing replay protection...")
        
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 執行密鑰交換
        let alicePublicKey = try alice.getPublicKey()
        let bobPublicKey = try bob.getPublicKey()
        try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
        try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
        
        // 發送訊息
        let message = "Test message"
        let messageData = message.data(using: .utf8)!
        let encrypted = try alice.encrypt(messageData, for: "Bob")
        
        // 第一次解密應該成功
        let decrypted1 = try bob.decrypt(encrypted.data, from: "Alice")
        assert(String(data: decrypted1, encoding: .utf8) == message, "第一次解密應該成功")
        
        // 嘗試重放攻擊（重複解密同一條訊息）
        do {
            let _ = try bob.decrypt(encrypted.data, from: "Alice")
            assert(false, "重放攻擊應該被阻止")
        } catch CryptoError.messageNumberMismatch {
            print("✅ Replay attack correctly blocked")
        } catch {
            assert(false, "應該拋出 messageNumberMismatch 錯誤")
        }
        
        print("✅ Replay protection test passed")
    }
    
    /// 測試 HMAC 驗證
    static func testHMACVerification() throws {
        print("🧪 Testing HMAC verification...")
        
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 執行密鑰交換
        let alicePublicKey = try alice.getPublicKey()
        let bobPublicKey = try bob.getPublicKey()
        try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
        try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
        
        // 加密訊息
        let message = "Important message"
        let messageData = message.data(using: .utf8)!
        let encrypted = try alice.encrypt(messageData, for: "Bob")
        
        // 修改 HMAC（模擬篡改攻擊）
        var tamperedData = try encrypted.data
        tamperedData[tamperedData.count - 1] ^= 0xFF // 修改最後一個 byte
        
        // 嘗試解密被篡改的訊息
        do {
            let _ = try bob.decrypt(tamperedData, from: "Alice")
            assert(false, "篡改的訊息應該被拒絕")
        } catch CryptoError.invalidSignature {
            print("✅ Tampered message correctly rejected")
        } catch {
            print("❌ Unexpected error: \(error)")
            assert(false, "應該拋出 invalidSignature 錯誤")
        }
        
        print("✅ HMAC verification test passed")
    }
    
    /// 測試會話密鑰管理
    static func testSessionKeyManagement() throws {
        print("🧪 Testing session key management...")
        
        let securityService = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 驗證初始狀態
        assert(!securityService.hasSessionKey(for: "TestPeer"), "初始時應無會話密鑰")
        assert(securityService.activeConnections == 0, "初始時應無活躍連接")
        
        // 模擬密鑰交換（生成假的公鑰）
        let fakePublicKey = Data(repeating: 0x42, count: 32)
        try securityService.performKeyExchange(with: fakePublicKey, peerID: "TestPeer")
        
        // 驗證會話密鑰已建立
        assert(securityService.hasSessionKey(for: "TestPeer"), "應該有 TestPeer 的會話密鑰")
        assert(securityService.activeConnections == 1, "應該有 1 個活躍連接")
        
        // 移除會話密鑰
        securityService.removeSessionKey(for: "TestPeer")
        assert(!securityService.hasSessionKey(for: "TestPeer"), "會話密鑰應該已移除")
        assert(securityService.activeConnections == 0, "應該無活躍連接")
        
        print("✅ Session key management test passed")
    }
    
    // MARK: - Test Runner
    
    /// 運行所有測試
    static func runAllTests() async {
        print("🚀 Starting SecurityService Tests...")
        print("=" * 50)
        
        do {
            // 基礎測試
            testSecurityServiceInitialization()
            print("")
            
            try testPublicKeyGeneration()
            print("")
            
            try testKeyExchange()
            print("")
            
            try testEncryptionDecryption()
            print("")
            
            try testForwardSecrecy()
            print("")
            
            try testReplayProtection()
            print("")
            
            try testHMACVerification()
            print("")
            
            try testSessionKeyManagement()
            print("")
            
            print("=" * 50)
            print("🎉 All SecurityService tests passed!")
            
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
    
    /// 效能測試
    static func performanceTest() async {
        print("🚀 Starting SecurityService Performance Test...")
        
        let alice = SecurityService()
        let bob = SecurityService()
        
        // 等待初始化完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 執行密鑰交換
        do {
            let alicePublicKey = try alice.getPublicKey()
            let bobPublicKey = try bob.getPublicKey()
            try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
            try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
            
            // 效能測試：加密/解密 100 條訊息
            let messageCount = 100
            let testMessage = "This is a performance test message with some content."
            let messageData = testMessage.data(using: .utf8)!
            
            let startTime = Date()
            
            for i in 0..<messageCount {
                let encrypted = try alice.encrypt(messageData, for: "Bob")
                let _ = try bob.decrypt(encrypted.data, from: "Alice")
            }
            
            let endTime = Date()
            let totalTime = endTime.timeIntervalSince(startTime)
            let averageTime = totalTime / Double(messageCount)
            
            print("📊 Performance Test Results:")
            print("   - Total messages: \(messageCount)")
            print("   - Total time: \(String(format: "%.2f", totalTime)) seconds")
            print("   - Average time per message: \(String(format: "%.4f", averageTime)) seconds")
            print("   - Messages per second: \(String(format: "%.1f", Double(messageCount) / totalTime))")
            
        } catch {
            print("❌ Performance test failed: \(error)")
        }
    }
} 