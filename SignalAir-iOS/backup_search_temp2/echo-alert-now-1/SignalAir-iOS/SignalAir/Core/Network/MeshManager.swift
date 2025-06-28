import Foundation
import MultipeerConnectivity
import Observation

// MARK: - Message Priority
enum MessagePriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case emergency = "emergency"
}

// MARK: - Mesh Network Protocol
protocol MeshNetworkProtocol {
    func broadcastMessage(_ data: Data, messageType: MeshMessageType)
    func sendDirectMessage(_ data: Data, to peerID: String, messageType: MeshMessageType)
    func getConnectedPeers() -> [String]
    func getNetworkTopology() -> [String: Set<String>]
}

// MARK: - Message Types with Emergency Priority
enum MeshMessageType: String, CaseIterable, Codable {
    case emergencyMedical = "emergency_medical"  // 最高優先級
    case emergencyDanger = "emergency_danger"    // 最高優先級
    case signal = "signal"
    case chat = "chat"
    case game = "game"
    case heartbeat = "heartbeat"
    case routingUpdate = "routing_update"
    case keyExchange = "key_exchange"
    case system = "system"
    
    var priority: Int {
        switch self {
        case .emergencyMedical: return 100  // 緊急醫療求助
        case .emergencyDanger: return 100   // 緊急危險警報
        case .signal: return 10
        case .keyExchange: return 9
        case .system: return 8
        case .heartbeat: return 7
        case .routingUpdate: return 6
        case .chat: return 5
        case .game: return 4
        }
    }
    
    var isEmergency: Bool {
        return self == .emergencyMedical || self == .emergencyDanger
    }
}

// MARK: - Simple Route Quality (簡化的路由品質)
struct SimpleRouteMetrics: Codable {
    let peerID: String
    var signalStrength: Float = -50.0        // -100 到 0 dBm，越接近0越好
    var packetLoss: Float = 0.0              // 0.0-1.0，越低越好
    var isReachable: Bool = true             // 是否可達
    var lastHeartbeat: Date = Date()         // 最後心跳時間
    
    // 簡單的路由評分（0.0-1.0）
    var routeScore: Float {
        guard isReachable else { return 0.0 }
        
        // 檢查是否超時（超過60秒沒心跳視為不可達）
        if Date().timeIntervalSince(lastHeartbeat) > 60.0 {
            return 0.0
        }
        
        // 信號強度評分：-100dBm=0分，-50dBm=1分
        let signalScore = max(0.0, min(1.0, (signalStrength + 100.0) / 50.0))
        
        // 丟包率評分：0%丟包=1分，100%丟包=0分
        let lossScore = max(0.0, 1.0 - packetLoss)
        
        // 簡單加權：信號強度60%，丟包率40%
        return signalScore * 0.6 + lossScore * 0.4
    }
    
    var isStale: Bool {
        return Date().timeIntervalSince(lastHeartbeat) > 60.0
    }
}

// MARK: - Emergency Route Cache (緊急路由快取)
class EmergencyRouteCache {
    private var metrics: [String: SimpleRouteMetrics] = [:]
    private var emergencyPaths: [String: [String]] = [:]  // 快取緊急路徑
    private let lock = NSLock()
    
    func updateMetrics(_ metrics: SimpleRouteMetrics) {
        lock.lock()
        defer { lock.unlock() }
        
        self.metrics[metrics.peerID] = metrics
        
        // 清理失效的節點
        self.metrics = self.metrics.filter { !$0.value.isStale }
    }
    
    func getMetrics(for peerID: String) -> SimpleRouteMetrics? {
        lock.lock()
        defer { lock.unlock() }
        
        return metrics[peerID]
    }
    
    func cacheEmergencyPath(to destination: String, path: [String]) {
        lock.lock()
        defer { lock.unlock() }
        
        emergencyPaths[destination] = path
    }
    
    func getEmergencyPath(to destination: String) -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        
        return emergencyPaths[destination]
    }
    
    func clearStaleData() {
        lock.lock()
        defer { lock.unlock() }
        
        metrics = metrics.filter { !$0.value.isStale }
        
        // 清理無效的緊急路徑
        for (destination, path) in emergencyPaths {
            for nodeID in path {
                if let nodeMetrics = metrics[nodeID], !nodeMetrics.isReachable {
                    emergencyPaths.removeValue(forKey: destination)
                    break
                }
            }
        }
    }
    
    func getAllMetrics() -> [String: SimpleRouteMetrics] {
        lock.lock()
        defer { lock.unlock() }
        
        return metrics
    }
}

// MARK: - Simple Intelligent Router (簡化智能路由器)
class SimpleIntelligentRouter {
    private let routeCache = EmergencyRouteCache()
    private var failedNodes: Set<String> = []
    private let lock = NSLock()
    
    // 尋找最佳路由（優先考慮緊急訊息）
    func findBestRoute(from source: String, to destination: String, 
                      topology: NetworkTopology, isEmergency: Bool = false) -> [String]? {
        
        // 1. 如果是緊急訊息，先檢查快取的緊急路徑
        if isEmergency, let emergencyPath = routeCache.getEmergencyPath(to: destination) {
            if isPathValid(emergencyPath) {
                return emergencyPath
            }
        }
        
        // 2. 尋找所有可能路徑
        let availablePaths = findMultiplePaths(from: source, to: destination, topology: topology)
        
        // 3. 評估路徑並選擇最佳的
        let bestPath = selectBestPath(availablePaths, isEmergency: isEmergency)
        
        // 4. 如果是緊急訊息，快取最佳路徑
        if isEmergency, let path = bestPath {
            routeCache.cacheEmergencyPath(to: destination, path: path)
        }
        
        return bestPath
    }
    
    // 尋找多條路徑（最多3條，避免過度計算）
    private func findMultiplePaths(from source: String, to destination: String, 
                                  topology: NetworkTopology) -> [[String]] {
        var paths: [[String]] = []
        var excludeNodes: Set<String> = failedNodes
        
        // 最多找3條路徑
        for _ in 0..<3 {
            if let path = topology.findRoute(from: source, to: destination, excluding: excludeNodes) {
                paths.append(path)
                
                // 排除此路徑的中間節點以找到不同路徑
                if path.count > 2 {
                    for node in path[1..<path.count-1] {
                        excludeNodes.insert(node)
                    }
                }
            } else {
                break
            }
        }
        
        return paths
    }
    
    // 選擇最佳路徑（簡單但有效）
    private func selectBestPath(_ paths: [[String]], isEmergency: Bool) -> [String]? {
        guard !paths.isEmpty else { return nil }
        
        // 緊急訊息：選擇最短且最可靠的路徑
        if isEmergency {
            return paths.min { path1, path2 in
                let score1 = calculatePathReliability(path1)
                let score2 = calculatePathReliability(path2)
                
                // 如果可靠性相近，選擇較短的路徑
                if abs(score1 - score2) < 0.1 {
                    return path1.count < path2.count
                }
                return score1 > score2
            }
        }
        
        // 一般訊息：綜合考慮路徑品質和跳數
        return paths.max { path1, path2 in
            let score1 = calculatePathScore(path1)
            let score2 = calculatePathScore(path2)
            return score1 < score2
        }
    }
    
    // 計算路徑可靠性（用於緊急訊息）
    private func calculatePathReliability(_ path: [String]) -> Float {
        guard path.count > 1 else { return 0.0 }
        
        var totalReliability: Float = 1.0
        
        for nodeID in path {
            if let metrics = routeCache.getMetrics(for: nodeID) {
                // 只考慮是否可達和基本品質
                if metrics.isReachable && metrics.routeScore > 0.3 {
                    totalReliability *= metrics.routeScore
                } else {
                    return 0.0  // 任何一個節點不可靠，整條路徑就不可靠
                }
            } else {
                totalReliability *= 0.5  // 未知節點給予保守評分
            }
        }
        
        return totalReliability
    }
    
    // 計算路徑評分（用於一般訊息）
    private func calculatePathScore(_ path: [String]) -> Float {
        guard path.count > 1 else { return 0.0 }
        
        let reliability = calculatePathReliability(path)
        
        // 跳數懲罰：每增加一跳減少10%評分
        let hopPenalty = pow(0.9, Float(path.count - 2))
        
        return reliability * hopPenalty
    }
    
    // 檢查路徑是否有效
    private func isPathValid(_ path: [String]) -> Bool {
        for nodeID in path {
            if failedNodes.contains(nodeID) {
                return false
            }
            
            if let metrics = routeCache.getMetrics(for: nodeID), !metrics.isReachable {
                return false
            }
        }
        return true
    }
    
    // 標記故障節點
    func markNodeAsFailed(_ nodeID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        failedNodes.insert(nodeID)
        print("🚫 Marked node as failed: \(nodeID)")
    }
    
    // 恢復節點
    func markNodeAsRecovered(_ nodeID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        failedNodes.remove(nodeID)
        print("✅ Marked node as recovered: \(nodeID)")
    }
    
    // 更新節點指標
    func updateNodeMetrics(_ metrics: SimpleRouteMetrics) {
        routeCache.updateMetrics(metrics)
        
        // 如果節點恢復，從故障清單移除
        if metrics.isReachable && failedNodes.contains(metrics.peerID) {
            markNodeAsRecovered(metrics.peerID)
        }
    }
    
    // 獲取節點指標
    func getNodeMetrics(for peerID: String) -> SimpleRouteMetrics? {
        return routeCache.getMetrics(for: peerID)
    }
    
    // 獲取所有節點指標
    func getAllNodeMetrics() -> [String: SimpleRouteMetrics] {
        return routeCache.getAllMetrics()
    }
    
    // 清理過期資料
    func cleanup() {
        routeCache.clearStaleData()
        
        lock.lock()
        defer { lock.unlock() }
        
        // 清理長期故障的節點（超過5分鐘）
        let staleFailures = failedNodes.filter { nodeID in
            if let metrics = routeCache.getMetrics(for: nodeID) {
                return Date().timeIntervalSince(metrics.lastHeartbeat) > 300
            }
            return true
        }
        
        for nodeID in staleFailures {
            failedNodes.remove(nodeID)
        }
    }
}

// MARK: - Mesh Message Structure
struct MeshMessage: Codable {
    let id: String
    let type: MeshMessageType
    let sourceID: String
    let targetID: String? // nil for broadcast
    let data: Data
    let timestamp: Date
    let ttl: Int // Time To Live
    let hopCount: Int
    let routePath: [String] // 記錄路由路徑
    
    init(type: MeshMessageType, sourceID: String, targetID: String? = nil, data: Data, ttl: Int? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.sourceID = sourceID
        self.targetID = targetID
        self.data = data
        self.timestamp = Date()
        // 緊急訊息有更長的TTL
        self.ttl = ttl ?? (type.isEmergency ? 20 : 10)
        self.hopCount = 0
        self.routePath = [sourceID]
    }
    
    // 私有初始化器用於轉發
    private init(type: MeshMessageType, sourceID: String, targetID: String?, data: Data, 
                timestamp: Date, ttl: Int, hopCount: Int, routePath: [String]) {
        self.id = UUID().uuidString
        self.type = type
        self.sourceID = sourceID
        self.targetID = targetID
        self.data = data
        self.timestamp = timestamp
        self.ttl = ttl
        self.hopCount = hopCount
        self.routePath = routePath
    }
    
    // 創建轉發副本
    func forwarded(through peerID: String) -> MeshMessage {
        return MeshMessage(
            type: self.type,
            sourceID: self.sourceID,
            targetID: self.targetID,
            data: self.data,
            timestamp: self.timestamp,
            ttl: self.ttl - 1,
            hopCount: self.hopCount + 1,
            routePath: self.routePath + [peerID]
        )
    }
    
    var isExpired: Bool {
        let maxAge: TimeInterval = type.isEmergency ? 600 : 300  // 緊急訊息10分鐘，一般5分鐘
        return ttl <= 0 || Date().timeIntervalSince(timestamp) > maxAge
    }
}

// MARK: - Network Topology (簡化版)
class NetworkTopology {
    private var connections: [String: Set<String>] = [:]
    private let lock = NSLock()
    
    func addConnection(from: String, to: String) {
        lock.lock()
        defer { lock.unlock() }
        
        connections[from, default: Set()].insert(to)
        connections[to, default: Set()].insert(from)
    }
    
    func removeConnection(from: String, to: String) {
        lock.lock()
        defer { lock.unlock() }
        
        connections[from]?.remove(to)
        connections[to]?.remove(from)
        
        if connections[from]?.isEmpty == true {
            connections.removeValue(forKey: from)
        }
        if connections[to]?.isEmpty == true {
            connections.removeValue(forKey: to)
        }
    }
    
    func removePeer(_ peerID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if let connectedPeers = connections[peerID] {
            for peer in connectedPeers {
                connections[peer]?.remove(peerID)
                if connections[peer]?.isEmpty == true {
                    connections.removeValue(forKey: peer)
                }
            }
        }
        connections.removeValue(forKey: peerID)
    }
    
    func getConnections() -> [String: Set<String>] {
        lock.lock()
        defer { lock.unlock() }
        return connections
    }
    
    // 使用BFS尋找路徑（簡單可靠）
    func findRoute(from source: String, to target: String, excluding excludeNodes: Set<String> = []) -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        
        guard source != target else { return [source] }
        guard !excludeNodes.contains(source) && !excludeNodes.contains(target) else { return nil }
        
        // BFS搜尋
        var queue: [(String, [String])] = [(source, [source])]
        var visited: Set<String> = [source]
        
        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            
            if let neighbors = connections[current] {
                for neighbor in neighbors {
                    if neighbor == target {
                        return path + [neighbor]
                    }
                    
                    if !visited.contains(neighbor) && !excludeNodes.contains(neighbor) {
                        visited.insert(neighbor)
                        queue.append((neighbor, path + [neighbor]))
                    }
                }
            }
        }
        
        return nil // 無路徑
    }
}

// MARK: - Message Queue (緊急訊息優先)
class MessageQueue {
    private var emergencyQueue: [MeshMessage] = []  // 緊急訊息隊列
    private var normalQueue: [MeshMessage] = []     // 一般訊息隊列
    private let lock = NSLock()
    private let maxSize = 500  // 減少記憶體使用
    
    func enqueue(_ message: MeshMessage) {
        lock.lock()
        defer { lock.unlock() }
        
        if message.type.isEmergency {
            emergencyQueue.append(message)
            
            // 限制緊急隊列大小
            if emergencyQueue.count > maxSize / 4 {
                emergencyQueue.removeFirst()
            }
        } else {
            // 一般訊息按優先級插入
            let insertIndex = normalQueue.firstIndex { $0.type.priority < message.type.priority } ?? normalQueue.count
            normalQueue.insert(message, at: insertIndex)
            
            // 限制一般隊列大小
            if normalQueue.count > maxSize {
                normalQueue.removeLast()
            }
        }
    }
    
    func dequeue() -> MeshMessage? {
        lock.lock()
        defer { lock.unlock() }
        
        // 清理過期訊息
        emergencyQueue.removeAll { $0.isExpired }
        normalQueue.removeAll { $0.isExpired }
        
        // 緊急訊息優先
        if !emergencyQueue.isEmpty {
            return emergencyQueue.removeFirst()
        }
        
        return normalQueue.isEmpty ? nil : normalQueue.removeFirst()
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        emergencyQueue.removeAll()
        normalQueue.removeAll()
    }
    
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return emergencyQueue.count + normalQueue.count
    }
    
    var emergencyCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return emergencyQueue.count
    }
}

// MARK: - Network Statistics
struct NetworkStats {
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var messagesForwarded: Int = 0
    var emergencyMessagesSent: Int = 0
    var emergencyMessagesReceived: Int = 0
    var connectedPeersCount: Int = 0
    var averageRouteLength: Double = 0.0
    var networkReliability: Float = 1.0
}

// MARK: - Flood Protection Protocol
protocol FloodProtectionProtocol {
    func shouldBlock(_ message: MeshMessage, from peerID: String) -> Bool
}

// MARK: - Network Service Protocol  
protocol NetworkServiceProtocol: AnyObject {
    var myPeerID: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    var onDataReceived: ((Data, String) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
    
    func send(_ data: Data, to peers: [MCPeerID]) async throws
}

// MARK: - Security Service Protocol
protocol SecurityServiceProtocol {
    func hasSessionKey(for peerID: String) -> Bool
    func encrypt(_ data: Data, for peerID: String) throws -> Data
    func decrypt(_ data: Data, from peerID: String) throws -> Data
    func getPublicKey() throws -> Data
    func removeSessionKey(for peerID: String)
}

// MARK: - Simple Flood Protection
class SimpleFloodProtection: FloodProtectionProtocol {
    private var messageHistory: [String: [Date]] = [:]
    private let lock = NSLock()
    private let maxMessagesPerMinute = 60
    private let windowSize: TimeInterval = 60.0
    
    func shouldBlock(_ message: MeshMessage, from peerID: String) -> Bool {
        // 緊急訊息永不阻擋
        guard !message.type.isEmergency else { return false }
        
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-windowSize)
        
        // 清理過期記錄
        messageHistory[peerID] = messageHistory[peerID]?.filter { $0 > cutoffTime } ?? []
        
        // 檢查是否超過限制
        let recentCount = messageHistory[peerID]?.count ?? 0
        if recentCount >= maxMessagesPerMinute {
            print("🚫 Blocking flood from \(peerID): \(recentCount) messages in last minute")
            return true
        }
        
        // 記錄此次訊息
        messageHistory[peerID, default: []].append(now)
        return false
    }
}

// MARK: - Mesh Manager (智能路由整合版)
@Observable
class MeshManager: MeshNetworkProtocol {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let floodProtection: FloodProtectionProtocol
    
    // MARK: - Core Components
    private var topology = NetworkTopology()
    private let messageQueue = MessageQueue()
    private let intelligentRouter = SimpleIntelligentRouter()
    private var processedMessages: Set<String> = []
    private let processedMessagesLimit = 5000  // 減少記憶體使用
    
    // MARK: - Timers
    private var heartbeatTimer: Timer?
    private var queueProcessingTimer: Timer?
    private var metricsCleanupTimer: Timer?
    
    // MARK: - Configuration
    private let heartbeatInterval: TimeInterval = 30.0      // 30秒心跳
    private let queueProcessingInterval: TimeInterval = 0.1  // 100ms處理間隔
    private let metricsCleanupInterval: TimeInterval = 120.0 // 2分鐘清理一次
    
    // MARK: - Published State
    @Published var connectedPeers: [String] = []
    @Published var networkStats: NetworkStats = NetworkStats()
    @Published var isActive: Bool = false
    @Published var routingMetrics: [String: SimpleRouteMetrics] = [:]
    
    // MARK: - Callbacks
    var onMessageReceived: ((Data, MeshMessageType, String) -> Void)?
    var onNetworkTopologyChanged: (([String: Set<String>]) -> Void)?
    var onEmergencyMessage: ((Data, MeshMessageType, String) -> Void)?
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol, 
         securityService: SecurityServiceProtocol,
         floodProtection: FloodProtectionProtocol? = nil) {
        self.networkService = networkService
        self.securityService = securityService
        self.floodProtection = floodProtection ?? SimpleFloodProtection()
        
        setupNetworkCallbacks()
        startServices()
        
        print("🕸️ MeshManager initialized with intelligent routing")
    }
    
    // MARK: - MeshNetworkProtocol Implementation
    
    func broadcastMessage(_ data: Data, messageType: MeshMessageType) {
        let message = MeshMessage(
            type: messageType,
            sourceID: networkService.myPeerID.displayName,
            data: data
        )
        
        processOutgoingMessage(message)
        
        // 更新統計
        updateStats(for: message, isSent: true)
        
        print("📡 Broadcasting \(messageType.rawValue) message")
    }
    
    func sendDirectMessage(_ data: Data, to peerID: String, messageType: MeshMessageType) {
        let message = MeshMessage(
            type: messageType,
            sourceID: networkService.myPeerID.displayName,
            targetID: peerID,
            data: data
        )
        
        processOutgoingMessage(message)
        
        // 更新統計
        updateStats(for: message, isSent: true)
        
        print("📤 Sending \(messageType.rawValue) message to \(peerID)")
    }
    
    func getConnectedPeers() -> [String] {
        return Array(topology.getConnections().keys)
    }
    
    func getNetworkTopology() -> [String: Set<String>] {
        return topology.getConnections()
    }
    
    // MARK: - Emergency Message API
    
    func sendEmergencyMessage(_ data: Data, type: MeshMessageType) {
        guard type.isEmergency else {
            print("❌ Message type \(type.rawValue) is not emergency")
            return
        }
        
        broadcastMessage(data, messageType: type)
        print("🚨 Emergency \(type.rawValue) message sent")
    }
    
    // MARK: - Route Management
    
    func updateNodeMetrics(peerID: String, signalStrength: Float, packetLoss: Float) {
        let metrics = SimpleRouteMetrics(
            peerID: peerID,
            signalStrength: signalStrength,
            packetLoss: packetLoss,
            isReachable: true,
            lastHeartbeat: Date()
        )
        
        intelligentRouter.updateNodeMetrics(metrics)
        
        DispatchQueue.main.async {
            self.routingMetrics[peerID] = metrics
        }
    }
    
    func markNodeAsFailed(_ peerID: String) {
        intelligentRouter.markNodeAsFailed(peerID)
        
        // 從拓撲中移除
        topology.removePeer(peerID)
        updateConnectedPeers()
        
        print("🚫 Node \(peerID) marked as failed")
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkCallbacks() {
        networkService.onDataReceived = { [weak self] data, peerID in
            self?.handleIncomingData(data, from: peerID)
        }
        
        networkService.onPeerConnected = { [weak self] peerID in
            self?.handlePeerConnected(peerID)
        }
        
        networkService.onPeerDisconnected = { [weak self] peerID in
            self?.handlePeerDisconnected(peerID)
        }
    }
    
    private func startServices() {
        isActive = true
        
        // 啟動心跳計時器
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { _ in
            self.sendHeartbeat()
        }
        
        // 啟動訊息佇列處理
        queueProcessingTimer = Timer.scheduledTimer(withTimeInterval: queueProcessingInterval, repeats: true) { _ in
            self.processMessageQueue()
        }
        
        // 啟動清理計時器
        metricsCleanupTimer = Timer.scheduledTimer(withTimeInterval: metricsCleanupInterval, repeats: true) { _ in
            self.performCleanup()
        }
        
        print("🚀 MeshManager services started")
    }
    
    private func stopServices() {
        isActive = false
        
        heartbeatTimer?.invalidate()
        queueProcessingTimer?.invalidate()
        metricsCleanupTimer?.invalidate()
        
        messageQueue.clear()
        
        print("🛑 MeshManager services stopped")
    }
    
    private func handleIncomingData(_ data: Data, from peerID: String) {
        do {
            // 解密數據（如果需要）
            let decryptedData: Data
            if securityService.hasSessionKey(for: peerID) {
                decryptedData = try securityService.decrypt(data, from: peerID)
            } else {
                decryptedData = data
            }
            
            // 解析訊息
            let message = try JSONDecoder().decode(MeshMessage.self, from: decryptedData)
            
            // 防洪檢查
            if floodProtection.shouldBlock(message, from: peerID) {
                print("🚫 Blocked flooding from \(peerID)")
                return
            }
            
            // 重複訊息檢查
            if processedMessages.contains(message.id) {
                print("🔁 Duplicate message ignored: \(message.id)")
                return
            }
            
            // 記錄已處理訊息
            addToProcessedMessages(message.id)
            
            // 處理訊息
            handleMeshMessage(message, from: peerID)
            
            // 更新統計
            updateStats(for: message, isSent: false)
            
        } catch {
            print("❌ Failed to process incoming data from \(peerID): \(error)")
        }
    }
    
    private func handleMeshMessage(_ message: MeshMessage, from peerID: String) {
        let myID = networkService.myPeerID.displayName
        
        // 更新節點指標（基於心跳訊息）
        if message.type == .heartbeat {
            updateNodeMetrics(peerID: peerID, signalStrength: -50.0, packetLoss: 0.0)
        }
        
        // 檢查是否為目標接收者
        if let targetID = message.targetID {
            if targetID == myID {
                // 直接訊息給我
                deliverMessage(message)
                print("📨 Received direct \(message.type.rawValue) from \(message.sourceID)")
            } else {
                // 需要轉發
                forwardMessage(message, from: peerID)
            }
        } else {
            // 廣播訊息
            if message.sourceID != myID {
                deliverMessage(message)
                forwardMessage(message, from: peerID)
                print("📻 Received broadcast \(message.type.rawValue) from \(message.sourceID)")
            }
        }
        
        // 處理特殊訊息類型
        handleSpecialMessageTypes(message, from: peerID)
    }
    
    private func deliverMessage(_ message: MeshMessage) {
        // 緊急訊息特殊處理
        if message.type.isEmergency {
            onEmergencyMessage?(message.data, message.type, message.sourceID)
        }
        
        // 一般訊息處理
        onMessageReceived?(message.data, message.type, message.sourceID)
    }
    
    private func forwardMessage(_ message: MeshMessage, from senderID: String) {
        guard message.ttl > 0 && !message.isExpired else {
            print("⚰️ Message expired, not forwarding")
            return
        }
        
        // 避免路由循環
        let myID = networkService.myPeerID.displayName
        if message.routePath.contains(myID) {
            print("🔄 Avoiding routing loop for message \(message.id)")
            return
        }
        
        // 創建轉發副本
        let forwardedMessage = message.forwarded(through: myID)
        
        // 智能轉發決策
        let connectedPeerIDs = networkService.connectedPeers.map { $0.displayName }
        let validTargets = connectedPeerIDs.filter { 
            $0 != senderID && !message.routePath.contains($0) 
        }
        
        if !validTargets.isEmpty {
            messageQueue.enqueue(forwardedMessage)
            
            // 更新轉發統計
            DispatchQueue.main.async {
                self.networkStats.messagesForwarded += 1
            }
            
            print("🔄 Queued message for forwarding to \(validTargets.count) peers")
        }
    }
    
    private func processOutgoingMessage(_ message: MeshMessage) {
        messageQueue.enqueue(message)
    }
    
    private func processMessageQueue() {
        guard let message = messageQueue.dequeue() else { return }
        
        if let targetID = message.targetID {
            // 直接訊息 - 使用智能路由
            routeDirectMessage(message, to: targetID)
        } else {
            // 廣播訊息
            broadcastToConnectedPeers(message)
        }
    }
    
    private func routeDirectMessage(_ message: MeshMessage, to targetID: String) {
        let myID = networkService.myPeerID.displayName
        let connectedPeers = networkService.connectedPeers
        
        // 檢查是否直接連接
        if let targetPeer = connectedPeers.first(where: { $0.displayName == targetID }) {
            sendMessageToPeer(message, peer: targetPeer)
            return
        }
        
        // 使用智能路由尋找最佳路徑
        if let route = intelligentRouter.findBestRoute(
            from: myID, 
            to: targetID, 
            topology: topology, 
            isEmergency: message.type.isEmergency
        ) {
            if route.count > 1 {
                let nextHop = route[1]
                if let peer = connectedPeers.first(where: { $0.displayName == nextHop }) {
                    sendMessageToPeer(message, peer: peer)
                    print("🛤️ Routed \(message.type.isEmergency ? "EMERGENCY " : "")\(message.type.rawValue) to \(targetID) via \(nextHop)")
                    return
                }
            }
        }
        
        print("🚫 No route found to \(targetID)")
    }
    
    private func broadcastToConnectedPeers(_ message: MeshMessage) {
        let connectedPeers = networkService.connectedPeers
        
        for peer in connectedPeers {
            // 避免回傳給原始發送者
            if !message.routePath.contains(peer.displayName) {
                sendMessageToPeer(message, peer: peer)
            }
        }
    }
    
    private func sendMessageToPeer(_ message: MeshMessage, peer: MCPeerID) {
        Task {
            do {
                let messageData = try JSONEncoder().encode(message)
                
                // 加密數據（如果有會話密鑰）
                let finalData: Data
                if securityService.hasSessionKey(for: peer.displayName) {
                    finalData = try securityService.encrypt(messageData, for: peer.displayName)
                } else {
                    finalData = messageData
                }
                
                try await networkService.send(finalData, to: [peer])
                
            } catch {
                print("❌ Failed to send message to \(peer.displayName): \(error)")
                
                // 標記節點可能有問題
                markNodeAsFailed(peer.displayName)
            }
        }
    }
    
    private func handleSpecialMessageTypes(_ message: MeshMessage, from peerID: String) {
        switch message.type {
        case .heartbeat:
            handleHeartbeat(message, from: peerID)
        case .routingUpdate:
            handleRoutingUpdate(message, from: peerID)
        case .keyExchange:
            handleKeyExchange(message, from: peerID)
        default:
            break
        }
    }
    
    private func handleHeartbeat(_ message: MeshMessage, from peerID: String) {
        // 更新拓撲連接
        topology.addConnection(from: message.sourceID, to: peerID)
        updateConnectedPeers()
        
        // 更新節點指標
        updateNodeMetrics(peerID: peerID, signalStrength: -50.0, packetLoss: 0.0)
    }
    
    private func handleRoutingUpdate(_ message: MeshMessage, from peerID: String) {
        do {
            let remoteTopology = try JSONDecoder().decode([String: Set<String>].self, from: message.data)
            
            // 合併拓撲信息
            for (node, connections) in remoteTopology {
                for connection in connections {
                    topology.addConnection(from: node, to: connection)
                }
            }
            
            updateConnectedPeers()
            
        } catch {
            print("❌ Failed to process routing update from \(peerID): \(error)")
        }
    }
    
    private func handleKeyExchange(_ message: MeshMessage, from peerID: String) {
        // 這裡可以實現密鑰交換邏輯
        print("🔑 Received key exchange from \(peerID)")
    }
    
    private func handlePeerConnected(_ peerID: String) {
        topology.addConnection(from: networkService.myPeerID.displayName, to: peerID)
        updateConnectedPeers()
        sendRoutingUpdate()
        
        // 初始化節點指標
        updateNodeMetrics(peerID: peerID, signalStrength: -50.0, packetLoss: 0.0)
        
        print("🤝 Peer connected: \(peerID)")
    }
    
    private func handlePeerDisconnected(_ peerID: String) {
        topology.removePeer(peerID)
        securityService.removeSessionKey(for: peerID)
        intelligentRouter.markNodeAsFailed(peerID)
        
        updateConnectedPeers()
        sendRoutingUpdate()
        
        // 清理指標
        DispatchQueue.main.async {
            self.routingMetrics.removeValue(forKey: peerID)
        }
        
        print("👋 Peer disconnected: \(peerID)")
    }
    
    private func updateConnectedPeers() {
        DispatchQueue.main.async {
            self.connectedPeers = self.getConnectedPeers()
            self.networkStats.connectedPeersCount = self.connectedPeers.count
            self.onNetworkTopologyChanged?(self.getNetworkTopology())
        }
    }
    
    private func sendHeartbeat() {
        let heartbeatData = "heartbeat".data(using: .utf8) ?? Data()
        broadcastMessage(heartbeatData, messageType: .heartbeat)
    }
    
    private func sendRoutingUpdate() {
        do {
            let topologyData = try JSONEncoder().encode(topology.getConnections())
            broadcastMessage(topologyData, messageType: .routingUpdate)
        } catch {
            print("❌ Failed to send routing update: \(error)")
        }
    }
    
    private func updateStats(for message: MeshMessage, isSent: Bool) {
        DispatchQueue.main.async {
            if isSent {
                self.networkStats.messagesSent += 1
                if message.type.isEmergency {
                    self.networkStats.emergencyMessagesSent += 1
                }
            } else {
                self.networkStats.messagesReceived += 1
                if message.type.isEmergency {
                    self.networkStats.emergencyMessagesReceived += 1
                }
            }
        }
    }
    
    private func addToProcessedMessages(_ messageID: String) {
        processedMessages.insert(messageID)
        
        // 限制記憶體使用
        if processedMessages.count > processedMessagesLimit {
            let excess = processedMessages.count - processedMessagesLimit / 2
            let toRemove = Array(processedMessages.prefix(excess))
            
            for id in toRemove {
                processedMessages.remove(id)
            }
        }
    }
    
    private func performCleanup() {
        // 清理智能路由器
        intelligentRouter.cleanup()
        
        // 更新網路可靠性統計
        updateNetworkReliability()
        
        print("🧹 Performed periodic cleanup")
    }
    
    private func updateNetworkReliability() {
        let allMetrics = intelligentRouter.getAllNodeMetrics()
        let activeNodes = allMetrics.values.filter { $0.isReachable }
        
        if !activeNodes.isEmpty {
            let averageScore = activeNodes.reduce(0.0) { $0 + $1.routeScore } / Float(activeNodes.count)
            
            DispatchQueue.main.async {
                self.networkStats.networkReliability = averageScore
            }
        }
    }
}

// MARK: - String Extension for Repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Backward Compatibility API
extension MeshManager {
    // 向後兼容的API方法，讓舊的ViewModel能夠正常工作
    
    /// 向後兼容的簡單初始化器
    convenience init() {
        // 創建簡單的實現作為替代
        let dummyNetworkService = DummyNetworkService()
        let dummySecurityService = DummySecurityService()
        
        self.init(
            networkService: dummyNetworkService,
            securityService: dummySecurityService,
            floodProtection: SimpleFloodProtection()
        )
        print("🕸️ MeshManager initialized with dummy services (backward compatibility)")
    }
    
    /// 啟動Mesh網路（兼容舊API）
    func startMeshNetwork() {
        // 新版本在初始化時自動啟動，這裡只是記錄
        print("🕸️ MeshManager: Legacy startMeshNetwork() called")
    }
    
    /// 停止Mesh網路（兼容舊API）
    func stopMeshNetwork() {
        stopServices()
        print("🕸️ MeshManager: Legacy stopMeshNetwork() called")
    }
    
    /// 設置訊息處理器（兼容舊API）
    func setMessageHandler(_ handler: @escaping (Data) -> Void) {
        onMessageReceived = { data, messageType, sourceID in
            handler(data)
        }
        print("🕸️ MeshManager: Legacy message handler set")
    }
    
    /// 廣播訊息（兼容舊API）
    func broadcast(_ data: Data, priority: MessagePriority, userNickname: String) async throws {
        // 將舊的優先級映射到新的訊息類型
        let messageType: MeshMessageType
        switch priority {
        case .emergency:
            messageType = .emergencyMedical  // 緊急訊息
        case .high:
            messageType = .signal
        case .normal:
            messageType = .chat
        case .low:
            messageType = .system
        }
        
        broadcastMessage(data, messageType: messageType)
        print("🕸️ MeshManager: Legacy broadcast called with priority \(priority)")
    }
}

// MARK: - Dummy Implementations for Backward Compatibility
class DummyNetworkService: NetworkServiceProtocol {
    var myPeerID: MCPeerID = MCPeerID(displayName: "DummyPeer")
    var connectedPeers: [MCPeerID] = []
    var onDataReceived: ((Data, String) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    func send(_ data: Data, to peers: [MCPeerID]) async throws {
        print("🔧 DummyNetworkService: send called (no-op)")
    }
}

class DummySecurityService: SecurityServiceProtocol {
    func hasSessionKey(for peerID: String) -> Bool { return false }
    func encrypt(_ data: Data, for peerID: String) throws -> Data { return data }
    func decrypt(_ data: Data, from peerID: String) throws -> Data { return data }
    func getPublicKey() throws -> Data { return Data() }
    func removeSessionKey(for peerID: String) {}
} 
