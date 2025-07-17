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
    @MainActor
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
            Task { @MainActor [weak self] in
                self?.performTopologyUpdate()
            }
        }
    }
    
    /// 執行拓撲更新（集成 Eclipse 防禦）
    @MainActor
    private func performTopologyUpdate() {
        updateNetworkStatistics()
        broadcastNodeInfo()
        
        // Eclipse 攻擊防禦 - 多樣性檢查
        performEclipseDiversityCheck()
    }
    
    /// 更新網路統計
    @MainActor
    private func updateNetworkStatistics() {
        guard let meshManager = meshManager else { return }
        
        connectedNodesCount = meshManager.getConnectedPeers().count
        networkHealth = connectedNodesCount > 0 ? 1.0 : 0.5
    }
    
    // MARK: - 廣播方法
    
    /// 廣播節點資訊
    @MainActor
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
            Task { @MainActor in
                handleReceivedPeerDiscovery(message, from: sender)
            }
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
        Task { @MainActor in
            updateNetworkStatistics()
        }
    }
    
    @MainActor
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
    
    // MARK: - Eclipse Attack Defense - Passive Topology Diversity Detection
    
    private struct DiversityMetrics {
        let connectionPattern: ConnectionPattern
        let deviceFingerprints: Set<String>
        let networkDistribution: NetworkDistribution
        let temporalPattern: TemporalPattern
        let timestamp: Date
        
        init(connectedPeers: [MCPeerID], deviceFingerprintManager: DeviceFingerprintManager?) {
            self.connectionPattern = ConnectionPattern(peerCount: connectedPeers.count)
            self.deviceFingerprints = Set(connectedPeers.map { $0.displayName })
            self.networkDistribution = NetworkDistribution(peerDistribution: connectedPeers.map { $0.displayName })
            self.temporalPattern = TemporalPattern()
            self.timestamp = Date()
        }
        
        var concentrationRatio: Double {
            return connectionPattern.concentrationRatio
        }
        
        var diversityScore: Double {
            let fingerprintDiversity = min(1.0, Double(deviceFingerprints.count) / 5.0)
            let distributionScore = networkDistribution.diversityScore
            return (fingerprintDiversity + distributionScore) / 2.0
        }
    }
    
    private struct ConnectionPattern {
        let peerCount: Int
        let timestamp: Date = Date()
        
        var concentrationRatio: Double {
            if peerCount <= 1 { return 1.0 }
            if peerCount <= 3 { return 0.8 }
            if peerCount <= 5 { return 0.6 }
            return 0.4
        }
    }
    
    private struct NetworkDistribution {
        let peerDistribution: [String]
        
        var diversityScore: Double {
            let uniquePeers = Set(peerDistribution).count
            if uniquePeers <= 1 { return 0.2 }
            if uniquePeers <= 3 { return 0.6 }
            return 1.0
        }
    }
    
    private struct TemporalPattern {
        let timestamp: Date = Date()
    }
    
    private enum EclipseIndicator {
        case highConcentration
        case lowDeviceDiversity
        case suspiciousPattern
        case normalDiversity
    }
    
    private struct DiversityAnalysisResult {
        let indicators: [EclipseIndicator]
        let overallScore: Double
        let recommendation: String
        
        var isEclipseRiskDetected: Bool {
            return indicators.contains(.highConcentration) || indicators.contains(.lowDeviceDiversity)
        }
    }
    
    private let expectedMinimumDiversity = 3
    private var lastDiversityCheck: Date = Date.distantPast
    private let diversityCheckInterval: TimeInterval = 60.0
    
    /// Eclipse 攻擊防禦 - 分析拓撲多樣性
    @MainActor
    private func analyzeDiversity() -> DiversityAnalysisResult {
        guard let meshManager = meshManager else {
            return DiversityAnalysisResult(
                indicators: [.suspiciousPattern],
                overallScore: 0.0,
                recommendation: "無法獲取網路管理器"
            )
        }
        
        let connectedPeerStrings = meshManager.getConnectedPeers()
        let connectedPeers = connectedPeerStrings.compactMap { peerName -> MCPeerID? in
            return MCPeerID(displayName: peerName)
        }
        let metrics = DiversityMetrics(connectedPeers: connectedPeers, deviceFingerprintManager: nil)
        
        return evaluateConnectionDiversity(metrics)
    }
    
    /// 評估連接多樣性
    private func evaluateConnectionDiversity(_ metrics: DiversityMetrics) -> DiversityAnalysisResult {
        var indicators: [EclipseIndicator] = []
        
        // 檢測連接集中化
        if metrics.concentrationRatio > 0.8 {
            indicators.append(.highConcentration)
        }
        
        // 檢測設備指紋異常
        if metrics.deviceFingerprints.count < expectedMinimumDiversity {
            indicators.append(.lowDeviceDiversity)
        }
        
        // 如果沒有檢測到問題
        if indicators.isEmpty {
            indicators.append(.normalDiversity)
        }
        
        let overallScore = calculateOverallDiversityScore(metrics, indicators: indicators)
        let recommendation = generateDiversityRecommendation(indicators, score: overallScore)
        
        return DiversityAnalysisResult(
            indicators: indicators,
            overallScore: overallScore,
            recommendation: recommendation
        )
    }
    
    /// 計算整體多樣性評分
    private func calculateOverallDiversityScore(_ metrics: DiversityMetrics, indicators: [EclipseIndicator]) -> Double {
        var score = metrics.diversityScore
        
        // 根據指標調整評分
        for indicator in indicators {
            switch indicator {
            case .highConcentration:
                score *= 0.5
            case .lowDeviceDiversity:
                score *= 0.6
            case .suspiciousPattern:
                score *= 0.3
            case .normalDiversity:
                break
            }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    /// 生成多樣性建議
    private func generateDiversityRecommendation(_ indicators: [EclipseIndicator], score: Double) -> String {
        if indicators.contains(.highConcentration) {
            return "檢測到高度連接集中化，建議增加連接多樣性"
        }
        
        if indicators.contains(.lowDeviceDiversity) {
            return "設備多樣性不足，可能存在 Eclipse 攻擊風險"
        }
        
        if score < 0.5 {
            return "網路多樣性偏低，建議監控連接模式"
        }
        
        return "網路拓撲多樣性正常"
    }
    
    /// 執行 Eclipse 防禦多樣性檢查
    @MainActor
    func performEclipseDiversityCheck() {
        let timeSinceLastCheck = Date().timeIntervalSince(lastDiversityCheck)
        guard timeSinceLastCheck >= diversityCheckInterval else { return }
        
        lastDiversityCheck = Date()
        
        let result = analyzeDiversity()
        
        #if DEBUG
        print("🌐 Eclipse 防禦多樣性檢查結果：")
        print("   評分: \(String(format: "%.2f", result.overallScore))")
        print("   指標: \(result.indicators)")
        print("   建議: \(result.recommendation)")
        #endif
        
        if result.isEclipseRiskDetected {
            #if DEBUG
            print("⚠️ 檢測到潛在 Eclipse 攻擊風險")
            #endif
            
            // 通知安全監控系統
            // 暫時禁用通知，避免在正常遊戲中誤報
            // NotificationCenter.default.post(
            //     name: NSNotification.Name("EclipseRiskDetected"),
            //     object: result
            // )
        }
    }
}