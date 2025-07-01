import Foundation
import MultipeerConnectivity

/// 連接保持機制 - 防止iOS系統斷開MultipeerConnectivity連接
class ConnectionKeepAlive {
    
    // MARK: - Properties
    
    private let networkService: NetworkServiceProtocol
    private var keepAliveTimer: Timer?
    private var dataActivityTimer: Timer?
    private let keepAliveInterval: TimeInterval = 5.0  // 每5秒發送保活包
    private let dataActivityTimeout: TimeInterval = 30.0  // 30秒無活動則加強保活
    private var lastDataActivityTime = Date()
    private let queue = DispatchQueue(label: "com.signalAir.keepAlive", qos: .utility)
    
    // 連接品質監控
    private var connectionQualityMetrics: [String: ConnectionMetrics] = [:]
    
    // MARK: - Types
    
    struct ConnectionMetrics {
        var packetsSent: Int = 0
        var packetsReceived: Int = 0
        var lastPingTime: Date?
        var averageLatency: Double = 0
        var connectionLossCount: Int = 0
        var isStable: Bool {
            return connectionLossCount < 3 && averageLatency < 100
        }
    }
    
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        print("🔌 ConnectionKeepAlive: 初始化連接保持機制")
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 開始連接保持
    func start() {
        stop() // 確保清理舊的計時器
        
        queue.async { [weak self] in
            self?.startKeepAliveTimer()
            self?.startDataActivityMonitor()
        }
        
        print("🔌 ConnectionKeepAlive: 開始連接保持服務")
    }
    
    /// 停止連接保持
    func stop() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        dataActivityTimer?.invalidate()
        dataActivityTimer = nil
        
        print("🔌 ConnectionKeepAlive: 停止連接保持服務")
    }
    
    /// 記錄數據活動
    func recordDataActivity() {
        lastDataActivityTime = Date()
    }
    
    /// 記錄連接品質指標
    func recordConnectionMetrics(for peer: String, sent: Bool, latency: Double? = nil) {
        queue.async { [weak self] in
            var metrics = self?.connectionQualityMetrics[peer] ?? ConnectionMetrics()
            
            if sent {
                metrics.packetsSent += 1
            } else {
                metrics.packetsReceived += 1
            }
            
            if let latency = latency {
                // 計算移動平均延遲
                if metrics.averageLatency == 0 {
                    metrics.averageLatency = latency
                } else {
                    metrics.averageLatency = (metrics.averageLatency * 0.8) + (latency * 0.2)
                }
            }
            
            metrics.lastPingTime = Date()
            self?.connectionQualityMetrics[peer] = metrics
        }
    }
    
    /// 記錄連接丟失
    func recordConnectionLoss(for peer: String) {
        queue.async { [weak self] in
            self?.connectionQualityMetrics[peer]?.connectionLossCount += 1
        }
    }
    
    // MARK: - Private Methods
    
    private func startKeepAliveTimer() {
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: keepAliveInterval, repeats: true) { [weak self] _ in
            self?.sendKeepAlivePackets()
        }
        
        // 確保計時器在主運行循環中運行
        if let timer = keepAliveTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func startDataActivityMonitor() {
        dataActivityTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkDataActivity()
        }
        
        if let timer = dataActivityTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func sendKeepAlivePackets() {
        let connectedPeers = networkService.getConnectedPeers()
        
        guard !connectedPeers.isEmpty else {
            print("🔌 KeepAlive: 無連接設備，跳過保活")
            return
        }
        
        // 根據數據活動情況決定保活包類型
        let timeSinceLastActivity = Date().timeIntervalSince(lastDataActivityTime)
        let isInactive = timeSinceLastActivity > dataActivityTimeout
        
        for peerName in connectedPeers {
            queue.async { [weak self] in
                self?.sendKeepAlivePacket(to: peerName, enhanced: isInactive)
            }
        }
    }
    
    private func sendKeepAlivePacket(to peer: String, enhanced: Bool) {
        // 創建保活包
        let keepAliveData: Data
        
        if enhanced {
            // 增強型保活包 - 包含更多數據以保持連接活躍
            let payload = EnhancedKeepAlive(
                timestamp: Date(),
                sequence: Int.random(in: 0...Int.max),
                dataSize: 1024  // 1KB 數據
            )
            keepAliveData = payload.toBinaryData()
            print("🔌 發送增強型保活包到 \(peer) (長時間無活動)")
        } else {
            // 標準保活包
            let payload = StandardKeepAlive(
                timestamp: Date(),
                sequence: Int.random(in: 0...Int.max)
            )
            keepAliveData = payload.toBinaryData()
        }
        
        // 發送保活包
        networkService.sendMessage(keepAliveData, toPeer: peer, messageType: .system)
        recordConnectionMetrics(for: peer, sent: true)
    }
    
    private func checkDataActivity() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastDataActivityTime)
        
        if timeSinceLastActivity > 60.0 {
            print("⚠️ KeepAlive: 檢測到長時間無數據活動 (\(Int(timeSinceLastActivity))秒)")
            
            // 檢查連接品質
            for (peer, metrics) in connectionQualityMetrics {
                if !metrics.isStable {
                    print("⚠️ KeepAlive: 設備 \(peer) 連接不穩定，需要重新連接")
                    // 通知重連機制
                    NotificationCenter.default.post(
                        name: Notification.Name("ConnectionUnstable"),
                        object: peer
                    )
                }
            }
        }
    }
}

// MARK: - Keep Alive Payloads

struct StandardKeepAlive {
    let timestamp: Date
    let sequence: Int
    
    func toBinaryData() -> Data {
        var data = Data()
        
        // 協議版本
        data.append(1)
        
        // 消息類型 - 系統消息
        data.append(6)
        
        // 子類型 - 標準保活
        data.append(1)
        
        // 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 序列號
        let seq = UInt32(sequence)
        data.append(contentsOf: withUnsafeBytes(of: seq.littleEndian) { Array($0) })
        
        return data
    }
}

struct EnhancedKeepAlive {
    let timestamp: Date
    let sequence: Int
    let dataSize: Int
    
    func toBinaryData() -> Data {
        var data = Data()
        
        // 協議版本
        data.append(1)
        
        // 消息類型 - 系統消息
        data.append(6)
        
        // 子類型 - 增強保活
        data.append(2)
        
        // 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 序列號
        let seq = UInt32(sequence)
        data.append(contentsOf: withUnsafeBytes(of: seq.littleEndian) { Array($0) })
        
        // 填充數據 - 用於保持連接活躍
        let paddingData = Data(repeating: UInt8.random(in: 0...255), count: dataSize)
        data.append(paddingData)
        
        return data
    }
}