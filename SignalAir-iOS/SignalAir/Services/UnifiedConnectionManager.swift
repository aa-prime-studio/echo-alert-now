import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Connection Event Types
enum ConnectionEvent {
    case peerConnected(MCPeerID)
    case peerDisconnected(MCPeerID)
    case connectionLost(MCPeerID, reason: String)
    case reconnectAttempt(MCPeerID, attempt: Int)
    case reconnectSuccess(MCPeerID)
    case reconnectFailed(MCPeerID, reason: String)
    case keepAliveReceived(MCPeerID)
    case qualityDegraded(MCPeerID)
}

// MARK: - Connection Configuration
struct ConnectionConfiguration {
    let keepAliveInterval: TimeInterval
    let reconnectInterval: TimeInterval
    let maxReconnectAttempts: Int
    let dataActivityTimeout: TimeInterval
    let qualityCheckInterval: TimeInterval
    
    static let `default` = ConnectionConfiguration(
        keepAliveInterval: 30.0,
        reconnectInterval: 10.0,
        maxReconnectAttempts: 5,
        dataActivityTimeout: 60.0,
        qualityCheckInterval: 15.0
    )
    
    static let aggressive = ConnectionConfiguration(
        keepAliveInterval: 15.0,
        reconnectInterval: 5.0,
        maxReconnectAttempts: 8,
        dataActivityTimeout: 30.0,
        qualityCheckInterval: 10.0
    )
}

// MARK: - Connection Metrics
struct ConnectionMetrics {
    var packetsSent: Int = 0
    var packetsReceived: Int = 0
    var lastPingTime: Date?
    var averageLatency: Double = 0
    var connectionLossCount: Int = 0
    var lastDataActivity: Date = Date()
    var qualityScore: Double = 1.0
    
    var isStable: Bool {
        return connectionLossCount < 3 && averageLatency < 200 && qualityScore > 0.7
    }
    
    var needsKeepAlive: Bool {
        return Date().timeIntervalSince(lastDataActivity) > 30.0
    }
}

// MARK: - Unified Connection Manager
class UnifiedConnectionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isActive: Bool = false
    @Published private(set) var connectedPeers: Set<MCPeerID> = []
    @Published private(set) var connectionMetrics: [String: ConnectionMetrics] = [:]
    @Published private(set) var reconnectAttempts: [String: Int] = [:]
    
    // MARK: - Private Properties
    private weak var networkService: NetworkServiceProtocol?
    private let configuration: ConnectionConfiguration
    private let eventSubject = PassthroughSubject<ConnectionEvent, Never>()
    
    // Timer references
    private let timerManager = UnifiedTimerManager.shared
    
    // Thread safety
    private let queue = DispatchQueue(label: "com.signalair.connection", qos: .utility)
    private let metricsLock = NSLock()
    
    // Recently disconnected peers for smart reconnection
    private var recentlyDisconnectedPeers: Set<MCPeerID> = []
    private let disconnectedPeersLock = NSLock()
    
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol, configuration: ConnectionConfiguration = .default) {
        self.networkService = networkService
        self.configuration = configuration
        
        setupObservers()
        print("🔗 UnifiedConnectionManager: 初始化統一連接管理器")
    }
    
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// 啟動連接管理服務
    func start() {
        guard !isActive else { return }
        
        isActive = true
        startKeepAliveTimer()
        startQualityMonitoring()
        startReconnectTimer()
        
        print("🔗 UnifiedConnectionManager: 服務已啟動")
    }
    
    /// 停止連接管理服務
    func stop() {
        guard isActive else { return }
        
        isActive = false
        stopAllTimers()
        
        print("🔗 UnifiedConnectionManager: 服務已停止")
    }
    
    /// 註冊 peer 連接
    func registerPeerConnection(_ peerID: MCPeerID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.connectedPeers.insert(peerID)
            }
            
            // 初始化連接指標
            self.metricsLock.lock()
            self.connectionMetrics[peerID.displayName] = ConnectionMetrics()
            self.reconnectAttempts[peerID.displayName] = 0
            self.metricsLock.unlock()
            
            // 從重連列表中移除
            self.disconnectedPeersLock.lock()
            self.recentlyDisconnectedPeers.remove(peerID)
            self.disconnectedPeersLock.unlock()
            
            self.eventSubject.send(.peerConnected(peerID))
            print("🔗 Peer 已連接: \(peerID.displayName)")
        }
    }
    
    /// 註冊 peer 斷線
    func registerPeerDisconnection(_ peerID: MCPeerID, reason: String = "未知") {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.connectedPeers.remove(peerID)
            }
            
            // 更新指標
            self.metricsLock.lock()
            if var metrics = self.connectionMetrics[peerID.displayName] {
                metrics.connectionLossCount += 1
                metrics.qualityScore *= 0.8 // 降低品質評分
                self.connectionMetrics[peerID.displayName] = metrics
            }
            self.metricsLock.unlock()
            
            // 加入重連列表
            self.disconnectedPeersLock.lock()
            self.recentlyDisconnectedPeers.insert(peerID)
            self.disconnectedPeersLock.unlock()
            
            self.eventSubject.send(.peerDisconnected(peerID))
            print("🔗 Peer 已斷線: \(peerID.displayName) - 原因: \(reason)")
        }
    }
    
    /// 記錄數據活動
    func recordDataActivity(for peerID: MCPeerID, type: DataActivityType) {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        guard var metrics = connectionMetrics[peerID.displayName] else { return }
        
        switch type {
        case .sent:
            metrics.packetsSent += 1
        case .received:
            metrics.packetsReceived += 1
        case .keepAlive:
            eventSubject.send(.keepAliveReceived(peerID))
        }
        
        metrics.lastDataActivity = Date()
        connectionMetrics[peerID.displayName] = metrics
    }
    
    /// 獲取連接事件流
    var connectionEvents: AnyPublisher<ConnectionEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    /// 獲取 peer 連接品質
    func getConnectionQuality(for peerID: MCPeerID) -> Double {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        return connectionMetrics[peerID.displayName]?.qualityScore ?? 0.0
    }
    
    /// 強制重連特定 peer
    func forceReconnect(to peerID: MCPeerID) {
        queue.async { [weak self] in
            self?.attemptReconnection(to: peerID)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 應用生命週期觀察
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    private func startKeepAliveTimer() {
        timerManager.schedule(
            id: "connectionKeepAlive",
            configuration: TimerConfiguration(interval: configuration.keepAliveInterval, repeats: true)
        ) { [weak self] in
            self?.performKeepAlive()
        }
    }
    
    private func startQualityMonitoring() {
        timerManager.schedule(
            id: "qualityMonitoring",
            configuration: TimerConfiguration(interval: configuration.qualityCheckInterval, repeats: true)
        ) { [weak self] in
            self?.monitorConnectionQuality()
        }
    }
    
    private func startReconnectTimer() {
        timerManager.schedule(
            id: "autoReconnect",
            configuration: TimerConfiguration(interval: configuration.reconnectInterval, repeats: true)
        ) { [weak self] in
            self?.attemptReconnections()
        }
    }
    
    private func stopAllTimers() {
        timerManager.invalidate(id: "connectionKeepAlive")
        timerManager.invalidate(id: "qualityMonitoring")
        timerManager.invalidate(id: "autoReconnect")
    }
    
    private func performKeepAlive() {
        guard isActive else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let peersNeedingKeepAlive = self.metricsLock.withLock {
                return self.connectionMetrics.compactMap { (peerName, metrics) -> MCPeerID? in
                    if metrics.needsKeepAlive {
                        return self.connectedPeers.first { $0.displayName == peerName }
                    }
                    return nil
                }
            }
            
            for peerID in peersNeedingKeepAlive {
                self.sendKeepAlivePacket(to: peerID)
            }
        }
    }
    
    private func monitorConnectionQuality() {
        guard isActive else { return }
        
        metricsLock.lock()
        let degradedPeers = connectionMetrics.compactMap { (peerName, metrics) -> MCPeerID? in
            if !metrics.isStable {
                return connectedPeers.first { $0.displayName == peerName }
            }
            return nil
        }
        metricsLock.unlock()
        
        for peerID in degradedPeers {
            eventSubject.send(.qualityDegraded(peerID))
            print("⚠️ 連接品質降低: \(peerID.displayName)")
        }
    }
    
    private func attemptReconnections() {
        guard isActive else { return }
        
        disconnectedPeersLock.lock()
        let peersToReconnect = Array(recentlyDisconnectedPeers)
        disconnectedPeersLock.unlock()
        
        for peerID in peersToReconnect {
            attemptReconnection(to: peerID)
        }
    }
    
    private func attemptReconnection(to peerID: MCPeerID) {
        let peerName = peerID.displayName
        let currentAttempts = reconnectAttempts[peerName] ?? 0
        
        guard currentAttempts < configuration.maxReconnectAttempts else {
            print("🔗 達到最大重連次數，停止重連: \(peerName)")
            disconnectedPeersLock.lock()
            recentlyDisconnectedPeers.remove(peerID)
            disconnectedPeersLock.unlock()
            
            eventSubject.send(.reconnectFailed(peerID, reason: "達到最大重連次數"))
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.reconnectAttempts[peerName] = currentAttempts + 1
        }
        
        eventSubject.send(.reconnectAttempt(peerID, attempt: currentAttempts + 1))
        print("🔗 嘗試重連 (\(currentAttempts + 1)/\(configuration.maxReconnectAttempts)): \(peerName)")
        
        // 委託給 NetworkService 處理實際重連
        networkService?.attemptReconnection(to: peerID) { [weak self] success in
            if success {
                self?.eventSubject.send(.reconnectSuccess(peerID))
                print("✅ 重連成功: \(peerName)")
            } else {
                print("❌ 重連失敗: \(peerName)")
            }
        }
    }
    
    private func sendKeepAlivePacket(to peerID: MCPeerID) {
        let keepAliveData = "KEEP_ALIVE".data(using: .utf8) ?? Data()
        
        networkService?.sendData(keepAliveData, to: [peerID]) { [weak self] result in
            switch result {
            case .success:
                self?.recordDataActivity(for: peerID, type: .keepAlive)
            case .failure(let error):
                print("⚠️ 保活包發送失敗: \(peerID.displayName) - \(error)")
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        print("🔗 App 進入背景，調整連接管理策略")
        // 增加 keep-alive 頻率以維持連接
        timerManager.invalidate(id: "connectionKeepAlive")
        timerManager.schedule(
            id: "connectionKeepAlive",
            configuration: TimerConfiguration(interval: configuration.keepAliveInterval / 2, repeats: true)
        ) { [weak self] in
            self?.performKeepAlive()
        }
    }
    
    private func handleAppWillEnterForeground() {
        print("🔗 App 恢復前台，重置連接管理策略")
        // 恢復正常的 keep-alive 頻率
        timerManager.invalidate(id: "connectionKeepAlive")
        startKeepAliveTimer()
        
        // 檢查所有連接狀態
        queue.async { [weak self] in
            self?.validateAllConnections()
        }
    }
    
    private func validateAllConnections() {
        for peerID in connectedPeers {
            sendKeepAlivePacket(to: peerID)
        }
    }
}

// MARK: - Data Activity Type

enum DataActivityType {
    case sent
    case received
    case keepAlive
}

// MARK: - NetworkServiceProtocol Extension

extension NetworkServiceProtocol {
    func attemptReconnection(to peerID: MCPeerID, completion: @escaping (Bool) -> Void) {
        // 預設實作 - 子類應該覆寫此方法
        completion(false)
    }
}

// MARK: - NSLock Extension

extension NSLock {
    func withLock<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}