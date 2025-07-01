import Foundation
import MultipeerConnectivity

// MARK: - 連接優化器
class ConnectionOptimizer: ObservableObject {
    
    // MARK: - 連接質量監控
    struct ConnectionQuality {
        let peerID: String
        let latency: TimeInterval
        let packetLoss: Double
        let bandwidth: Double
        let lastUpdate: Date
        let isStable: Bool
        
        var qualityScore: Double {
            let latencyScore = max(0, 1.0 - latency / 1000.0) // 1秒為最差
            let lossScore = max(0, 1.0 - packetLoss)
            let bandwidthScore = min(1.0, bandwidth / 1024.0) // 1KB/s為滿分
            return (latencyScore + lossScore + bandwidthScore) / 3.0
        }
    }
    
    // MARK: - 屬性
    @Published var connectionQualities: [String: ConnectionQuality] = [:]
    @Published var totalConnections: Int = 0
    @Published var averageQuality: Double = 0.0
    
    private var qualityCheckTimer: Timer?
    private let maxConnections = 30 // 支持最多30個同時連接
    
    // MARK: - 初始化
    init() {
        print("🔧 ConnectionOptimizer: 初始化連接優化器")
        startQualityMonitoring()
    }
    
    deinit {
        qualityCheckTimer?.invalidate()
    }
    
    // MARK: - 連接質量監控
    private func startQualityMonitoring() {
        qualityCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateConnectionQualities()
        }
    }
    
    func updateConnectionQualities() {
        let currentTime = Date()
        
        // 清理過期的連接記錄（超過30秒無更新）
        connectionQualities = connectionQualities.filter { _, quality in
            currentTime.timeIntervalSince(quality.lastUpdate) < 30.0
        }
        
        // 更新統計
        totalConnections = connectionQualities.count
        averageQuality = connectionQualities.values.map { $0.qualityScore }.reduce(0, +) / Double(max(1, connectionQualities.count))
        
        print("📊 連接質量更新: \(totalConnections) 個連接，平均質量: \(String(format: "%.2f", averageQuality))")
    }
    
    // MARK: - 智能路由選擇
    func selectBestPeersForBroadcast(count: Int = 5) -> [String] {
        let sortedPeers = connectionQualities
            .filter { $0.value.isStable }
            .sorted { $0.value.qualityScore > $1.value.qualityScore }
            .prefix(count)
            .map { $0.key }
        
        print("🎯 選擇最佳 \(sortedPeers.count) 個節點進行廣播")
        return Array(sortedPeers)
    }
    
    func shouldAcceptNewConnection() -> Bool {
        let result = totalConnections < maxConnections
        if !result {
            print("⚠️ 連接數已達上限 \(maxConnections)，拒絕新連接")
        }
        return result
    }
    
    // MARK: - 連接事件處理
    func onPeerConnected(_ peerID: String) {
        print("✅ 新連接: \(peerID)")
        
        // 初始化連接質量
        connectionQualities[peerID] = ConnectionQuality(
            peerID: peerID,
            latency: 100.0, // 初始估值
            packetLoss: 0.0,
            bandwidth: 512.0,
            lastUpdate: Date(),
            isStable: false // 新連接暫時標記為不穩定
        )
        
        // 延遲3秒後標記為穩定（如果仍然連接）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if var quality = self?.connectionQualities[peerID] {
                quality = ConnectionQuality(
                    peerID: quality.peerID,
                    latency: quality.latency,
                    packetLoss: quality.packetLoss,
                    bandwidth: quality.bandwidth,
                    lastUpdate: Date(),
                    isStable: true
                )
                self?.connectionQualities[peerID] = quality
                print("🔄 \(peerID) 連接已穩定")
            }
        }
        
        updateConnectionQualities()
    }
    
    func onPeerDisconnected(_ peerID: String) {
        print("❌ 連接斷開: \(peerID)")
        connectionQualities.removeValue(forKey: peerID)
        updateConnectionQualities()
    }
    
    func onMessageSent(to peerID: String, size: Int, latency: TimeInterval) {
        if var quality = connectionQualities[peerID] {
            // 更新連接質量指標
            let newLatency = (quality.latency * 0.7) + (latency * 0.3) // 平滑更新
            let newBandwidth = Double(size) / max(latency, 0.001) // bytes/sec
            
            connectionQualities[peerID] = ConnectionQuality(
                peerID: quality.peerID,
                latency: newLatency,
                packetLoss: quality.packetLoss * 0.9, // 成功發送，降低丟包率
                bandwidth: (quality.bandwidth * 0.8) + (newBandwidth * 0.2),
                lastUpdate: Date(),
                isStable: quality.isStable
            )
        }
    }
    
    func onMessageFailed(to peerID: String) {
        if var quality = connectionQualities[peerID] {
            // 增加丟包率
            let newPacketLoss = min(1.0, quality.packetLoss + 0.1)
            
            connectionQualities[peerID] = ConnectionQuality(
                peerID: quality.peerID,
                latency: quality.latency * 1.1, // 增加延遲估值
                packetLoss: newPacketLoss,
                bandwidth: quality.bandwidth * 0.9, // 降低帶寬估值
                lastUpdate: Date(),
                isStable: newPacketLoss < 0.3 // 丟包率過高時標記為不穩定
            )
        }
    }
    
    // MARK: - 統計報告
    func getConnectionReport() -> String {
        let stableConnections = connectionQualities.values.filter { $0.isStable }.count
        let unstableConnections = totalConnections - stableConnections
        
        return """
        📊 連接狀態報告
        ═══════════════════════════════
        總連接數: \(totalConnections)/\(maxConnections)
        穩定連接: \(stableConnections)
        不穩定連接: \(unstableConnections)
        平均質量: \(String(format: "%.1f%%", averageQuality * 100))
        
        最佳連接:
        \(getBestConnectionsList())
        ═══════════════════════════════
        """
    }
    
    private func getBestConnectionsList() -> String {
        let topConnections = connectionQualities
            .sorted { $0.value.qualityScore > $1.value.qualityScore }
            .prefix(5)
        
        return topConnections.map { peerID, quality in
            "  • \(peerID): \(String(format: "%.1f%%", quality.qualityScore * 100))"
        }.joined(separator: "\n")
    }
}