import Foundation
import SwiftUI

// MARK: - Test Runner for NetworkService
struct TestRunner {
    
    /// 在 App 中運行 NetworkService 測試
    static func runNetworkServiceTests() {
        print("🚀 Starting NetworkService Tests from App...")
        
        Task {
            await NetworkServiceTests.runAllTests()
        }
    }
    
    /// 快速測試 NetworkService 基本功能
    static func quickNetworkTest() async {
        print("⚡ Quick NetworkService Test...")
        
        let networkService = NetworkService()
        
        // 測試初始化
        print("✅ NetworkService initialized")
        print("   - Status: \(networkService.connectionStatus)")
        print("   - Device: \(UIDevice.current.name)")
        
        // 測試開始網路
        networkService.startNetworking()
        print("✅ Networking started")
        
        // 等待 2 秒
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        print("📊 After 2 seconds:")
        print("   - Status: \(networkService.connectionStatus)")
        print("   - Connected Peers: \(networkService.connectedPeers.count)")
        print("   - Nearby Peers: \(networkService.nearbyPeers.count)")
        
        // 停止網路
        networkService.stopNetworking()
        print("✅ Networking stopped")
        print("⚡ Quick test completed!")
    }
}

// MARK: - Test View for SwiftUI
struct NetworkTestView: View {
    @State private var testOutput: String = "準備運行測試..."
    @State private var isRunning: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("NetworkService 測試")
                .font(.largeTitle)
                .fontWeight(.bold)
            
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
                Button("快速測試") {
                    runQuickTest()
                }
                .disabled(isRunning)
                
                Button("完整測試") {
                    runFullTest()
                }
                .disabled(isRunning)
                
                Button("清除") {
                    testOutput = "準備運行測試..."
                }
                .disabled(isRunning)
            }
            .padding()
        }
        .padding()
    }
    
    private func runQuickTest() {
        isRunning = true
        testOutput = "🚀 開始快速測試...\n"
        
        Task {
            await TestRunner.quickNetworkTest()
            
            DispatchQueue.main.async {
                self.testOutput += "\n✅ 快速測試完成！"
                self.isRunning = false
            }
        }
    }
    
    private func runFullTest() {
        isRunning = true
        testOutput = "🚀 開始完整測試...\n"
        
        Task {
            await NetworkServiceTests.runAllTests()
            
            DispatchQueue.main.async {
                self.testOutput += "\n🎉 所有測試完成！"
                self.isRunning = false
            }
        }
    }
} 