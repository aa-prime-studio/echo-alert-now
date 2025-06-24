import Foundation
import Foundation
import MultipeerConnectivity

// MARK: - NetworkService Test Suite
class NetworkServiceTests {
    
    // MARK: - Test Methods
    
    /// 測試網路服務初始化
    static func testNetworkServiceInitialization() {
        print("🧪 Testing NetworkService initialization...")
        
        let networkService = NetworkService()
        
        // 驗證初始狀態
        assert(networkService.connectionStatus == .disconnected, "初始狀態應為 disconnected")
        assert(networkService.connectedPeers.isEmpty, "初始時應無連接的 peers")
        assert(!networkService.isConnected, "初始時應未連線")
        
        print("✅ NetworkService initialization test passed")
    }
    
    /// 測試開始網路服務
    static func testStartNetworking() async {
        print("🧪 Testing start networking...")
        
        let networkService = NetworkService()
        
        // 設置回調來監聽狀態變化
        var statusChanged = false
        networkService.onPeerConnected = { peer in
            print("✅ Peer connected in test: \(peer.displayName)")
            statusChanged = true
        }
        
        // 開始網路服務
        networkService.startNetworking()
        
        // 驗證狀態變化
        assert(networkService.connectionStatus == .connecting, "開始後狀態應為 connecting")
        
        // 等待一段時間看是否有設備連接
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
        
        print("📊 After 3 seconds:")
        print("   - Connection Status: \(networkService.connectionStatus)")
        print("   - Connected Peers: \(networkService.connectedPeers.count)")
        print("   - Nearby Peers: \(networkService.nearbyPeers.count)")
        
        networkService.stopNetworking()
        print("✅ Start networking test completed")
    }
    
    /// 測試停止網路服務
    static func testStopNetworking() {
        print("🧪 Testing stop networking...")
        
        let networkService = NetworkService()
        
        // 先開始服務
        networkService.startNetworking()
        
        // 停止服務
        networkService.stopNetworking()
        
        // 驗證狀態
        assert(networkService.connectionStatus == .disconnected, "停止後狀態應為 disconnected")
        assert(networkService.connectedPeers.isEmpty, "停止後應無連接的 peers")
        assert(!networkService.isConnected, "停止後應未連線")
        
        print("✅ Stop networking test passed")
    }
    
    /// 測試數據發送（模擬）
    static func testDataSending() async {
        print("🧪 Testing data sending...")
        
        let networkService = NetworkService()
        networkService.startNetworking()
        
        // 測試發送數據（沒有連接的情況）
        let testData = "Hello, SignalAir!".data(using: .utf8)!
        
        do {
            try await networkService.send(testData)
            print("❌ Should have thrown an error for no connected peers")
        } catch NetworkError.notConnected {
            print("✅ Correctly threw notConnected error")
        } catch {
            print("❌ Unexpected error: \(error)")
        }
        
        networkService.stopNetworking()
        print("✅ Data sending test completed")
    }
    
    /// 完整的網路測試（需要兩個設備）
    static func testFullNetworkConnection() async {
        print("🧪 Testing full network connection...")
        print("📱 請確保有另一個設備運行相同的測試")
        
        let networkService = NetworkService()
        
        // 設置接收數據回調
        networkService.onReceiveData = { data, peer in
            let message = String(data: data, encoding: .utf8) ?? "Unknown"
            print("📥 Received message: \(message) from \(peer.displayName)")
        }
        
        networkService.onPeerConnected = { peer in
            print("✅ Peer connected: \(peer.displayName)")
            
            // 發送測試訊息
            Task {
                let testMessage = "Hello from \(UIDevice.current.name)!"
                if let data = testMessage.data(using: .utf8) {
                    try? await networkService.send(data, to: [peer])
                    print("📤 Sent test message to \(peer.displayName)")
                }
            }
        }
        
        networkService.onPeerDisconnected = { peer in
            print("❌ Peer disconnected: \(peer.displayName)")
        }
        
        // 開始網路服務
        networkService.startNetworking()
        
        // 等待連接和測試
        try? await Task.sleep(nanoseconds: 10_000_000_000) // 10秒
        
        print("📊 Final test results:")
        print("   - Connection Status: \(networkService.connectionStatus)")
        print("   - Connected Peers: \(networkService.connectedPeers.count)")
        print("   - Peer Names: \(networkService.connectedPeers.map { $0.displayName })")
        
        // 如果有連接的設備，發送最終測試訊息
        if !networkService.connectedPeers.isEmpty {
            let finalMessage = "Test completed successfully!"
            if let data = finalMessage.data(using: .utf8) {
                try? await networkService.broadcast(data)
                print("📡 Broadcasted completion message")
            }
        }
        
        networkService.stopNetworking()
        print("✅ Full network connection test completed")
    }
    
    // MARK: - Test Runner
    
    /// 運行所有測試
    static func runAllTests() async {
        print("🚀 Starting NetworkService Tests...")
        print("=" * 50)
        
        // 基礎測試
        testNetworkServiceInitialization()
        print("")
        
        await testStartNetworking()
        print("")
        
        testStopNetworking()
        print("")
        
        await testDataSending()
        print("")
        
        // 完整網路測試（需要多設備）
        print("🌐 Running full network test...")
        print("💡 提示：在另一個設備上運行此測試以查看完整的 P2P 功能")
        await testFullNetworkConnection()
        
        print("=" * 50)
        print("🎉 All NetworkService tests completed!")
    }
}

// MARK: - String Extension for Pretty Printing
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
} 