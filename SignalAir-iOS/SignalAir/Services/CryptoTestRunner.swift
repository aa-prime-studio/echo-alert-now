import Foundation
import SwiftUI

// MARK: - Crypto Test Runner
struct CryptoTestRunner {
    
    /// 運行所有加密測試
    static func runAllCryptoTests() async {
        print("🔐 Starting Crypto Tests...")
        print("=" * 60)
        
        await SecurityServiceTests.runAllTests()
        
        print("")
        print("⚡ Running Performance Test...")
        await SecurityServiceTests.performanceTest()
        
        print("")
        print("=" * 60)
        print("🎉 All Crypto Tests Completed!")
    }
    
    /// 快速加密測試
    static func quickCryptoTest() async -> Bool {
        print("⚡ Quick Crypto Test...")
        
        do {
            // 基本初始化測試
            let securityService = SecurityService()
            Thread.sleep(forTimeInterval: 0.5)
            
            guard securityService.isInitialized else {
                print("❌ SecurityService initialization failed")
                return false
            }
            
            // 公鑰生成測試
            let publicKey = try securityService.getPublicKey()
            guard publicKey.count == 32 else {
                print("❌ Public key generation failed")
                return false
            }
            
            // 基本加密/解密測試
            let alice = SecurityService()
            let bob = SecurityService()
            Thread.sleep(forTimeInterval: 0.5)
            
            let alicePublicKey = try alice.getPublicKey()
            let bobPublicKey = try bob.getPublicKey()
            
            try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
            try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
            
            let testMessage = "Quick test message"
            let messageData = testMessage.data(using: .utf8)!
            
            let encrypted = try alice.encrypt(messageData, for: "Bob")
            let decrypted = try bob.decrypt(encrypted.data, from: "Alice")
            let decryptedMessage = String(data: decrypted, encoding: .utf8)!
            
            guard decryptedMessage == testMessage else {
                print("❌ Encryption/Decryption test failed")
                return false
            }
            
            print("✅ Quick Crypto Test Passed!")
            return true
            
        } catch {
            print("❌ Quick Crypto Test Failed: \(error)")
            return false
        }
    }
    
    /// 檢查加密系統狀態
    static func checkCryptoSystemStatus() -> CryptoSystemStatus {
        print("🔍 Checking Crypto System Status...")
        
        var status = CryptoSystemStatus()
        
        // 檢查 SecurityService 初始化
        do {
            let securityService = SecurityService()
            Thread.sleep(forTimeInterval: 0.5)
            status.isSecurityServiceInitialized = securityService.isInitialized
        } catch {
            status.isSecurityServiceInitialized = false
            status.errors.append("SecurityService initialization failed: \(error)")
        }
        
        // 檢查密鑰生成
        do {
            let securityService = SecurityService()
            Thread.sleep(forTimeInterval: 0.5)
            let publicKey = try securityService.getPublicKey()
            status.isKeyGenerationWorking = publicKey.count == 32
        } catch {
            status.isKeyGenerationWorking = false
            status.errors.append("Key generation failed: \(error)")
        }
        
        // 檢查加密/解密
        do {
            let alice = SecurityService()
            let bob = SecurityService()
            Thread.sleep(forTimeInterval: 0.5)
            
            let alicePublicKey = try alice.getPublicKey()
            let bobPublicKey = try bob.getPublicKey()
            
            try alice.performKeyExchange(with: bobPublicKey, peerID: "Bob")
            try bob.performKeyExchange(with: alicePublicKey, peerID: "Alice")
            
            let testData = "Test".data(using: .utf8)!
            let encrypted = try alice.encrypt(testData, for: "Bob")
            let decrypted = try bob.decrypt(encrypted.data, from: "Alice")
            
            status.isEncryptionDecryptionWorking = decrypted == testData
        } catch {
            status.isEncryptionDecryptionWorking = false
            status.errors.append("Encryption/Decryption failed: \(error)")
        }
        
        status.overallStatus = status.isSecurityServiceInitialized && 
                              status.isKeyGenerationWorking && 
                              status.isEncryptionDecryptionWorking
        
        print("📊 Crypto System Status:")
        print("   - SecurityService: \(status.isSecurityServiceInitialized ? "✅" : "❌")")
        print("   - Key Generation: \(status.isKeyGenerationWorking ? "✅" : "❌")")
        print("   - Encryption/Decryption: \(status.isEncryptionDecryptionWorking ? "✅" : "❌")")
        print("   - Overall: \(status.overallStatus ? "✅ PASS" : "❌ FAIL")")
        
        if !status.errors.isEmpty {
            print("⚠️ Errors:")
            for error in status.errors {
                print("   - \(error)")
            }
        }
        
        return status
    }
}

// MARK: - Crypto System Status
struct CryptoSystemStatus {
    var isSecurityServiceInitialized: Bool = false
    var isKeyGenerationWorking: Bool = false
    var isEncryptionDecryptionWorking: Bool = false
    var overallStatus: Bool = false
    var errors: [String] = []
}

// MARK: - SwiftUI Test View
struct CryptoTestView: View {
    @State private var testOutput: String = "準備運行加密測試..."
    @State private var isRunning: Bool = false
    @State private var systemStatus: CryptoSystemStatus?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("加密功能測試")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 系統狀態顯示
            if let status = systemStatus {
                VStack(alignment: .leading, spacing: 8) {
                    Text("系統狀態")
                        .font(.headline)
                    
                    HStack {
                        Text("SecurityService:")
                        Spacer()
                        Text(status.isSecurityServiceInitialized ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("密鑰生成:")
                        Spacer()
                        Text(status.isKeyGenerationWorking ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("加密/解密:")
                        Spacer()
                        Text(status.isEncryptionDecryptionWorking ? "✅" : "❌")
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("整體狀態:")
                            .fontWeight(.bold)
                        Spacer()
                        Text(status.overallStatus ? "✅ 通過" : "❌ 失敗")
                            .fontWeight(.bold)
                            .foregroundColor(status.overallStatus ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            ScrollView {
                Text(testOutput)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 300)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            HStack(spacing: 15) {
                Button("系統檢查") {
                    checkSystem()
                }
                .disabled(isRunning)
                
                Button("快速測試") {
                    runQuickTest()
                }
                .disabled(isRunning)
                
                Button("完整測試") {
                    runFullTest()
                }
                .disabled(isRunning)
                
                Button("清除") {
                    testOutput = "準備運行加密測試..."
                    systemStatus = nil
                }
                .disabled(isRunning)
            }
            .padding()
        }
        .padding()
    }
    
    private func checkSystem() {
        isRunning = true
        testOutput = "🔍 檢查加密系統狀態...\n"
        
        Task {
            let status = CryptoTestRunner.checkCryptoSystemStatus()
            
            DispatchQueue.main.async {
                self.systemStatus = status
                self.testOutput += "\n✅ 系統檢查完成！"
                self.isRunning = false
            }
        }
    }
    
    private func runQuickTest() {
        isRunning = true
        testOutput = "⚡ 開始快速加密測試...\n"
        
        Task {
            let success = await CryptoTestRunner.quickCryptoTest()
            
            DispatchQueue.main.async {
                self.testOutput += success ? "\n✅ 快速測試通過！" : "\n❌ 快速測試失敗！"
                self.isRunning = false
            }
        }
    }
    
    private func runFullTest() {
        isRunning = true
        testOutput = "🔐 開始完整加密測試...\n"
        
        Task {
            await CryptoTestRunner.runAllCryptoTests()
            
            DispatchQueue.main.async {
                self.testOutput += "\n🎉 完整測試完成！"
                self.isRunning = false
            }
        }
    }
}