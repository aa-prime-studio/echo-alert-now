import Foundation
import MultipeerConnectivity

// 實際網絡集成測試 - 測試完整的消息路由鏈
class NetworkIntegrationTest {
    
    static func testRealNetworkMessageFlow() {
        print("🌐 ===== 開始實際網絡消息流轉測試 =====")
        
        // 獲取 ServiceContainer 實例
        let serviceContainer = ServiceContainer.shared
        
        // 測試 1: 驗證 MeshManager 回調設置
        testMeshManagerCallbackSetup(serviceContainer)
        
        // 測試 2: 驗證 BingoNetworkManager 回調設置
        testBingoNetworkManagerCallbackSetup(serviceContainer)
        
        // 測試 3: 模擬實際消息接收
        testActualMessageReception(serviceContainer)
        
        print("🌐 ===== 實際網絡測試完成 =====")
    }
    
    private static func testMeshManagerCallbackSetup(_ serviceContainer: ServiceContainer) {
        print("\n🔧 測試 MeshManager 回調設置...")
        
        let meshManager = serviceContainer.meshManager
        
        // 檢查 onGameMessageReceived 回調是否已設置
        if meshManager.onGameMessageReceived != nil {
            print("✅ MeshManager.onGameMessageReceived 回調已設置")
        } else {
            print("❌ MeshManager.onGameMessageReceived 回調未設置")
        }
        
        // 檢查 NetworkService 回調設置
        let networkService = serviceContainer.networkService
        if networkService.onDataReceived != nil {
            print("✅ NetworkService.onDataReceived 回調已設置")
        } else {
            print("❌ NetworkService.onDataReceived 回調未設置")
        }
    }
    
    private static func testBingoNetworkManagerCallbackSetup(_ serviceContainer: ServiceContainer) {
        print("\n🎮 測試 BingoNetworkManager 回調設置...")
        
        // 檢查是否有 BingoNetworkManager 實例
        if let bingoNetworkManager = serviceContainer.bingoNetworkManager {
            print("✅ BingoNetworkManager 實例存在")
            
            // 測試訂閱消息流
            let cancellable = bingoNetworkManager.receivedGameMessages.sink { gameMessage in
                print("🎮 接收到遊戲消息: \(gameMessage.type.stringValue) 來自 \(gameMessage.senderName)")
            }
            
            print("✅ BingoNetworkManager 消息訂閱已設置")
            
            // 清理訂閱（避免記憶體洩漏）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                cancellable.cancel()
            }
        } else {
            print("❌ BingoNetworkManager 實例不存在")
        }
    }
    
    private static func testActualMessageReception(_ serviceContainer: ServiceContainer) {
        print("\n📨 測試實際消息接收...")
        
        // 創建測試用的 playerJoined 消息
        let testPlayerInfo = PlayerInfo(
            playerID: "integration-test-player",
            playerName: "集成測試玩家",
            isHost: false,
            bingoCard: Array(1...25),
            deviceName: "Integration Test Device"
        )
        
        do {
            // 1. 編碼 playerJoined 數據
            let playerJoinedData = try BinaryGameProtocol.encodePlayerJoined(testPlayerInfo)
            print("✅ 成功編碼測試 playerJoined 數據: \(playerJoinedData.count) bytes")
            
            // 2. 創建遊戲消息
            let gameMessageData = createGameMessageData(
                type: .playerJoined,
                data: playerJoinedData,
                senderName: "集成測試發送者"
            )
            
            // 3. 編碼為 MeshMessage
            let meshMessage = MeshMessage(
                type: .game,
                sourceID: "integration-test-source",
                targetID: nil,
                data: gameMessageData,
                ttl: 5
            )
            
            let binaryData = try BinaryMessageEncoder.encode(meshMessage)
            print("✅ 成功編碼 MeshMessage: \(binaryData.count) bytes")
            
            // 4. 模擬 NetworkService 接收到數據
            simulateNetworkDataReception(serviceContainer, data: binaryData, fromPeer: "integration-test-peer")
            
        } catch {
            print("❌ 實際消息測試失敗: \(error)")
        }
    }
    
    private static func createGameMessageData(type: GameMessageType, data: Data, senderName: String) -> Data {
        var gameData = Data()
        
        // 添加遊戲消息類型
        gameData.append(type.rawValue)
        
        // 添加房間ID（空）
        gameData.append(UInt8(0))
        
        // 添加發送者名稱
        let senderNameData = senderName.data(using: .utf8) ?? Data()
        let safeSenderNameLength = min(senderNameData.count, 255)
        gameData.append(UInt8(safeSenderNameLength))
        gameData.append(senderNameData.prefix(safeSenderNameLength))
        
        // 添加實際數據
        let dataLength = UInt16(data.count)
        gameData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        gameData.append(data)
        
        return gameData
    }
    
    private static func simulateNetworkDataReception(_ serviceContainer: ServiceContainer, data: Data, fromPeer peerID: String) {
        print("\n📡 模擬 NetworkService 接收數據...")
        
        let networkService = serviceContainer.networkService
        
        // 直接調用 onDataReceived 回調來模擬數據接收
        if let onDataReceived = networkService.onDataReceived {
            print("🔄 調用 NetworkService.onDataReceived 回調...")
            onDataReceived(data, peerID)
            print("✅ 模擬數據接收完成")
        } else {
            print("❌ NetworkService.onDataReceived 回調不存在")
        }
    }
    
    // MARK: - 深度診斷方法
    
    static func diagnoseMeshManagerState() {
        print("\n🔍 ===== MeshManager 狀態診斷 =====")
        
        let serviceContainer = ServiceContainer.shared
        let meshManager = serviceContainer.meshManager
        
        print("MeshManager 基本狀態:")
        print("  - isActive: \(meshManager.isActive)")
        print("  - 連接的對等體數量: \(meshManager.getConnectedPeers().count)")
        print("  - 連接的對等體: \(meshManager.getConnectedPeers())")
        
        print("\nMeshManager 回調狀態:")
        print("  - onMessageReceived: \(meshManager.onMessageReceived != nil ? "已設置" : "未設置")")
        print("  - onGameMessageReceived: \(meshManager.onGameMessageReceived != nil ? "已設置" : "未設置")")
        print("  - onPeerConnected: \(meshManager.onPeerConnected != nil ? "已設置" : "未設置")")
        print("  - onPeerDisconnected: \(meshManager.onPeerDisconnected != nil ? "已設置" : "未設置")")
        
        print("=================================")
    }
    
    static func diagnoseBingoNetworkManagerState() {
        print("\n🔍 ===== BingoNetworkManager 狀態診斷 =====")
        
        let serviceContainer = ServiceContainer.shared
        
        if let bingoNetworkManager = serviceContainer.bingoNetworkManager {
            print("BingoNetworkManager 基本狀態:")
            print("  - connectionStatus: \(bingoNetworkManager.connectionStatus)")
            print("  - isNetworkActive: \(bingoNetworkManager.isNetworkActive)")
            print("  - isConnected: \(bingoNetworkManager.isConnected)")
            print("  - connectedPeers: \(bingoNetworkManager.connectedPeers)")
            print("  - syncStatus: \(bingoNetworkManager.syncStatus)")
        } else {
            print("❌ BingoNetworkManager 實例不存在")
        }
        
        print("=====================================")
    }
    
    static func diagnoseNetworkServiceState() {
        print("\n🔍 ===== NetworkService 狀態診斷 =====")
        
        let serviceContainer = ServiceContainer.shared
        let networkService = serviceContainer.networkService
        
        print("NetworkService 基本狀態:")
        print("  - isConnected: \(networkService.isConnected)")
        print("  - myPeerID: \(networkService.myPeerID.displayName)")
        print("  - connectedPeers: \(networkService.connectedPeers.map { $0.displayName })")
        
        print("NetworkService 回調狀態:")
        print("  - onDataReceived: \(networkService.onDataReceived != nil ? "已設置" : "未設置")")
        print("  - onPeerConnected: \(networkService.onPeerConnected != nil ? "已設置" : "未設置")")
        print("  - onPeerDisconnected: \(networkService.onPeerDisconnected != nil ? "已設置" : "未設置")")
        
        print("==================================")
    }
}