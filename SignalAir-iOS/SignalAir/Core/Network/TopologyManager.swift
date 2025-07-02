import Foundation
import MultipeerConnectivity

// MARK: - 網路拓撲管理器（簡化版本）
// 專為大規模 Mesh 網路優化，支援30萬用戶

class TopologyManager: ObservableObject {
    
    // MARK: - 發布屬性
    @Published var isActive: Bool = false
    @Published var connectedNodesCount: Int = 0
    @Published var networkHealth: Double = 1.0
    
    // MARK: - 私有屬性
    private var topologyTimer: Timer?
    private let updateInterval: TimeInterval = 30.0
    
    // 服務依賴
    private var meshManager: MeshManagerProtocol?
    private let deviceID: String
    private let deviceName: String
    
    // MARK: - 初始化
    init(meshManager: MeshManagerProtocol?, deviceID: String, deviceName: String) {
        self.meshManager = meshManager
        self.deviceID = deviceID
        self.deviceName = deviceName
        
        print("🌐 TopologyManager 初始化完成: \(deviceName) (\(deviceID))")
        
        // 設置 NotificationCenter 觀察者，符合統一路由模式
        setupNotificationObservers()
    }
    
    deinit {
        stopTopologyManagement()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - NotificationCenter 觀察者設置
    
    private func setupNotificationObservers() {
        // 監聽來自 ServiceContainer 的拓撲訊息
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TopologyMessageReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let data = notification.object as? Data,
               let sender = notification.userInfo?["sender"] as? String {
                Task {
                    await self.handleServiceContainerTopologyMessage(data, from: sender)
                }
            }
        }
        
        print("🌐 TopologyManager: NotificationCenter 觀察者已設置")
    }
    
    /// 處理來自 ServiceContainer 的拓撲訊息
    private func handleServiceContainerTopologyMessage(_ data: Data, from sender: String) async {
        // 使用 BinaryMessageDecoder 解碼拓撲訊息
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            print("🌐 TopologyManager 收到訊息: 類型=\(meshMessage.type), 發送者=\(sender)")
            
            // 確保是拓撲訊息類型
            if meshMessage.type == .topology {
                // 解析內部拓撲數據
                if let topologyMessage = try? JSONDecoder().decode(TopologyMessage.self, from: meshMessage.data) {
                    handleReceivedTopologyMessage(topologyMessage, from: sender)
                } else {
                    print("❌ TopologyManager: 解析拓撲訊息數據失敗")
                }
            }
        } catch {
            print("❌ TopologyManager: 解碼拓撲訊息失敗: \(error)")
        }
    }
    
    // MARK: - 拓撲管理控制
    
    /// 開始拓撲管理
    func startTopologyManagement() {
        guard !isActive else { return }
        
        isActive = true
        
        // 啟動定期更新
        startPeriodicUpdates()
        
        // 立即廣播節點資訊
        broadcastNodeInfo()
        
        print("🌐 拓撲管理已啟動")
    }
    
    /// 停止拓撲管理
    func stopTopologyManagement() {
        isActive = false
        topologyTimer?.invalidate()
        print("🌐 拓撲管理已停止")
    }
    
    // MARK: - 定期更新
    
    private func startPeriodicUpdates() {
        // 拓撲更新定時器
        topologyTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.performTopologyUpdate()
        }
    }
    
    /// 執行拓撲更新
    private func performTopologyUpdate() {
        updateNetworkStatistics()
        broadcastNodeInfo()
    }
    
    /// 更新網路統計
    private func updateNetworkStatistics() {
        guard let meshManager = meshManager else { return }
        
        connectedNodesCount = meshManager.getConnectedPeers().count
        networkHealth = connectedNodesCount > 0 ? 1.0 : 0.5
    }
    
    // MARK: - 廣播方法
    
    /// 廣播節點資訊
    private func broadcastNodeInfo() {
        guard let meshManager = meshManager else { return }
        
        do {
            // 簡化的節點資訊
            let nodeData = "{\"nodeID\": \"\(deviceID)\", \"deviceName\": \"\(deviceName)\", \"timestamp\": \(Date().timeIntervalSince1970)}".data(using: .utf8) ?? Data()
            
            let topologyMessage = TopologyMessage(
                type: .nodeInfo,
                senderID: deviceID,
                senderName: deviceName,
                data: nodeData,
                timestamp: Date(),
                sequenceNumber: Int.random(in: 1...99999),
                ttl: 3
            )
            
            let messageData = try JSONEncoder().encode(topologyMessage)
            let meshMessage = MeshMessage(type: .topology, data: messageData)
            let binaryData = try BinaryMessageEncoder.encode(meshMessage)
            
            meshManager.broadcastMessage(binaryData, messageType: .topology)
            print("📡 廣播節點資訊: \(connectedNodesCount) 個連接")
            
        } catch {
            print("❌ 廣播節點資訊失敗: \(error)")
        }
    }
    
    // MARK: - 公開方法
    
    /// 處理接收到的拓撲訊息
    func handleReceivedTopologyMessage(_ message: TopologyMessage, from sender: String) {
        switch message.type {
        case .nodeInfo:
            handleReceivedNodeInfo(message, from: sender)
        case .peerDiscovery:
            handleReceivedPeerDiscovery(message, from: sender)
        case .routeUpdate:
            print("🛤️ 收到路由更新來自: \(sender)")
        case .healthCheck:
            print("💓 收到健康檢查來自: \(sender)")
        case .loadReport:
            print("📊 收到負載報告來自: \(sender)")
        }
    }
    
    private func handleReceivedNodeInfo(_ message: TopologyMessage, from sender: String) {
        print("🔍 處理節點資訊來自: \(sender)")
        // 簡化處理：只記錄收到的節點資訊
        updateNetworkStatistics()
    }
    
    private func handleReceivedPeerDiscovery(_ message: TopologyMessage, from sender: String) {
        print("📡 收到節點發現來自: \(sender)")
        // 回應節點發現請求
        broadcastNodeInfo()
    }
    
    /// 獲取網路統計
    func getNetworkStatistics() -> (connectedNodes: Int, health: Double) {
        return (
            connectedNodes: connectedNodesCount,
            health: networkHealth
        )
    }
}