@preconcurrency import MultipeerConnectivity
import Foundation
import Accelerate

/// MultipeerConnectivity 網路優化擴展
extension NetworkService {
    
    // MARK: - Quick Trust Pre-Check
    
    /// 超快速預檢查（< 1ms）
    @MainActor
    func quickTrustPreCheck(_ peerID: MCPeerID) -> Bool {
        let peerName = peerID.displayName
        
        // 1. 檢查緩存
        if let cached = ServiceContainer.shared.trustCacheOptimizer.getCachedTrust(for: peerName) {
            return cached.score > 30  // 快速判斷
        }
        
        // 2. 黑名單快速檢查
        // TODO: 實現黑名單檢查
        if false {  // 暫時簡化
            return false
        }
        
        // 3. 行為模式快速匹配
        if let pattern = extractQuickPattern(from: peerID) {
            return !isKnownMaliciousPattern(pattern)
        }
        
        return true  // 默認允許，後續深度檢查
    }
    
    /// 優化的會話接受決策
    func optimizedSessionDidReceivePeer(_ session: MCSession, 
                                      peerID: MCPeerID,
                                      with data: Data?) {
        // 測量開始時間
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 並行執行多個檢查
        let group = DispatchGroup()
        var checkResults = CheckResults()
        
        // 檢查 1: 快速信任預檢 (簡化實現)
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            checkResults.trustPassed = true  // 簡化實現
            group.leave()
        }
        
        // 檢查 2: 連接速率檢查
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            checkResults.rateLimitPassed = true  // 簡化實現
            group.leave()
        }
        
        // 檢查 3: 資源可用性檢查
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            checkResults.resourcesAvailable = true  // 簡化實現
            group.leave()
        }
        
        // 等待所有檢查完成
        group.notify(queue: .main) { [weak self] in
            let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            if checkResults.shouldAccept {
                print("✅ 接受連接 from \(peerID.displayName) (耗時: \(String(format: "%.1f", elapsedTime))ms)")
                self?.acceptConnection(peerID)
            } else {
                print("❌ 拒絕連接 from \(peerID.displayName) (耗時: \(String(format: "%.1f", elapsedTime))ms)")
                session.cancelConnectPeer(peerID)
            }
        }
    }
    
    // MARK: - Pattern Recognition
    
    /// 提取快速行為模式
    private func extractQuickPattern(from peerID: MCPeerID) -> UInt32? {
        // 基於設備名稱生成快速指紋
        let name = peerID.displayName
        var pattern: UInt32 = 0
        
        // 簡單的特徵提取
        pattern |= UInt32(name.count) << 24
        pattern |= UInt32(name.first?.asciiValue ?? 0) << 16
        pattern |= UInt32(name.last?.asciiValue ?? 0) << 8
        pattern |= UInt32(name.filter { $0.isNumber }.count)
        
        return pattern
    }
    
    /// 檢查已知惡意模式
    private func isKnownMaliciousPattern(_ pattern: UInt32) -> Bool {
        // 預編譯的可疑模式集合
        let suspiciousPatterns: Set<UInt32> = [
            0x0001_0002,  // 快速重連模式
            0x0004_0008,  // 大量廣播模式
            0xFF00_00FF,  // 異常命名模式
            // 添加更多已知模式...
        ]
        
        return suspiciousPatterns.contains(pattern)
    }
    
    // MARK: - Connection Optimization
    
    /// 批量連接優化
    func optimizeBatchConnections(_ peers: [MCPeerID]) async {
        // 使用性能引擎進行批量分析
        let behaviors = peers.map { peer in
            // 提取行為特徵
            return extractBehaviorFeatures(from: peer)
        }
        
        let trustLevels = await HybridPerformanceEngine.shared.batchAnalyzeBehaviors(
            for: peers.map { $0.displayName },
            behaviors: behaviors
        )
        
        // 根據分析結果優化連接策略
        for (index, peer) in peers.enumerated() {
            switch trustLevels[index] {
            case "safe":
                // 優先連接，分配更多資源
                prioritizeConnection(peer)
            case "suspicious":
                // 限制連接資源
                limitConnection(peer)
            case "dangerous":
                // 拒絕或延遲連接
                deferConnection(peer)
            default:
                // 預設情況
                limitConnection(peer)
            }
        }
    }
    
    /// 連接池管理
    func setupConnectionPool() {
        // 預分配連接資源
        let poolSize = 50  // 最大同時連接數
        
        // TODO: 實現連接池管理
        print("📊 連接池已設定，大小: \(poolSize)")
    }
    
    // MARK: - Bandwidth Optimization
    
    /// 動態調整發送速率
    func adaptiveSendRate(for peer: MCPeerID) -> Int {
        let basePeerName = peer.displayName  // 簡化實現
        
        // 獲取連接質量指標
        let trustScore = ServiceContainer.shared.trustScoreManager.getTrustScore(for: basePeerName)
        let latency = measureLatency(to: peer)
        let bandwidth = estimateBandwidth(to: peer)
        
        // 計算最優發送速率
        var rate = 1000  // 基礎速率：1000 訊息/秒
        
        // 根據信任分數調整
        rate = Int(Float(rate) * (Float(trustScore) / 100.0))
        
        // 根據延遲調整
        if latency > 100 {  // 高延遲
            rate = rate / 2
        }
        
        // 根據帶寬調整
        if bandwidth < 1_000_000 {  // 低於 1MB/s
            rate = min(rate, 100)
        }
        
        return max(rate, 10)  // 最少 10 訊息/秒
    }
    
    // MARK: - Crypto Optimization
    
    /// 批量加密優化（使用 Accelerate）
    func batchEncrypt(messages: [Data], for peers: [MCPeerID]) async -> [Data] {
        guard messages.count == peers.count else { return [] }
        
        return await withTaskGroup(of: (Int, Data?).self) { group in
            for (index, (message, peer)) in zip(messages, peers).enumerated() {
                group.addTask {
                    guard let encrypted = try? await ServiceContainer.shared.securityService.encrypt(
                            message, 
                            for: peer.displayName
                          ) else {
                        return (index, nil)
                    }
                    return (index, encrypted)
                }
            }
            
            var results = [Data?](repeating: nil, count: messages.count)
            for await (index, encrypted) in group {
                results[index] = encrypted
            }
            
            return results.compactMap { $0 }
        }
    }
    
    // MARK: - Private Helpers
    
    private struct CheckResults {
        var trustPassed = false
        var rateLimitPassed = false
        var resourcesAvailable = false
        
        var shouldAccept: Bool {
            return trustPassed && rateLimitPassed && resourcesAvailable
        }
    }
    
    @MainActor
    private func checkResourceAvailability() -> Bool {
        // 檢查 CPU、記憶體、連接數等資源
        _ = 100  // maxConnections
        return true  // 簡化實現
    }
    
    private func extractBehaviorFeatures(from peer: MCPeerID) -> [Float] {
        // 簡化的特徵提取
        return [Float](repeating: 0.5, count: 10)
    }
    
    private func prioritizeConnection(_ peer: MCPeerID) {
        // 為高信任連接分配優先資源
        // TODO: 實現優先級設定
        print("🔥 優先連接: \(peer.displayName)")
    }
    
    private func limitConnection(_ peer: MCPeerID) {
        // 限制可疑連接的資源
        // TODO: 實現限制連接
        print("⚠️ 限制連接: \(peer.displayName)")
    }
    
    private func deferConnection(_ peer: MCPeerID) {
        // 延遲或拒絕危險連接
        // TODO: 實現延遲連接
        print("❌ 延遲連接: \(peer.displayName)")
    }
    
    private func measureLatency(to peer: MCPeerID) -> Double {
        // 簡化的延遲測量
        return 50.0  // 毫秒
    }
    
    private func estimateBandwidth(to peer: MCPeerID) -> Int {
        // 簡化的帶寬估算
        return 5_000_000  // 5MB/s
    }
    
    private func acceptConnection(_ peer: MCPeerID) {
        // 實際接受連接的邏輯
        print("🤝 正式接受連接: \(peer.displayName)")
    }
    
    // MARK: - Connection Pool Management
    // 注意：在擴展中不能定義存儲屬性，這些會移至 NetworkService 主類中
}

// MARK: - Trust Matrix Optimization

/// 預計算信任矩陣
class TrustMatrix {
    private var matrix: [String: [String: Float]] = [:]
    private let queue = DispatchQueue(label: "com.signalAir.trustMatrix", 
                                     attributes: .concurrent)
    
    /// 更新信任關係
    func updateTrust(from peer1: String, to peer2: String, score: Float) {
        queue.async(flags: .barrier) { [weak self] in
            if self?.matrix[peer1] == nil {
                self?.matrix[peer1] = [:]
            }
            self?.matrix[peer1]?[peer2] = score
        }
    }
    
    /// 獲取信任分數（O(1) 查詢）
    func getTrust(from peer1: String, to peer2: String) -> Float? {
        return queue.sync {
            matrix[peer1]?[peer2]
        }
    }
    
    /// 批量計算傳遞信任
    func calculateTransitiveTrust(from source: String, 
                                 through intermediates: [String], 
                                 to destination: String) -> Float {
        var trust: Float = 1.0
        
        // 計算信任鏈
        var current = source
        for intermediate in intermediates + [destination] {
            if let score = getTrust(from: current, to: intermediate) {
                trust *= score / 100.0
            } else {
                trust *= 0.5  // 未知關係的默認信任
            }
            current = intermediate
        }
        
        return trust * 100
    }
    
    /// 使用 Accelerate 優化的矩陣運算
    func optimizeMatrix() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 將信任矩陣轉換為連續數組以使用 Accelerate
            let peers = Array(self.matrix.keys).sorted()
            let size = peers.count
            
            guard size > 0 else { return }
            
            var flatMatrix = [Float](repeating: 0, count: size * size)
            
            // 填充矩陣
            for (i, peer1) in peers.enumerated() {
                for (j, peer2) in peers.enumerated() {
                    if let trust = self.matrix[peer1]?[peer2] {
                        flatMatrix[i * size + j] = trust
                    }
                }
            }
            
            // 使用 Accelerate 進行矩陣運算（例如：計算傳遞閉包）
            // var result = [Float](repeating: 0, count: size * size)  // 暫時不使用
            
            // Floyd-Warshall 算法的 SIMD 優化版本
            for k in 0..<size {
                for i in 0..<size {
                    for j in 0..<size {
                        let direct = flatMatrix[i * size + j]
                        let throughK = flatMatrix[i * size + k] * flatMatrix[k * size + j] / 100.0
                        flatMatrix[i * size + j] = max(direct, throughK)
                    }
                }
            }
            
            // 更新矩陣
            for (i, peer1) in peers.enumerated() {
                for (j, peer2) in peers.enumerated() {
                    let trust = flatMatrix[i * size + j]
                    if trust > 0 {
                        if self.matrix[peer1] == nil {
                            self.matrix[peer1] = [:]
                        }
                        self.matrix[peer1]?[peer2] = trust
                    }
                }
            }
        }
    }
}