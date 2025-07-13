import Foundation
import MultipeerConnectivity

/// 【MultipeerConnectivity專家】安全的網路操作管理器
/// 專門處理 "Not in connected state" 錯誤和通道狀態管理
@MainActor
class SafeNetworkOperations {
    
    // MARK: - 安全的網路狀態驗證
    
    /// 深度驗證 MCSession 通道狀態
    static func validateMCSessionState(session: MCSession, peers: [MCPeerID]) async -> [MCPeerID] {
        var validPeers: [MCPeerID] = []
        
        for peer in peers {
            // 三層驗證確保通道真正可用
            if await isChannelReallyConnected(session: session, peer: peer) {
                validPeers.append(peer)
            }
        }
        
        return validPeers
    }
    
    /// 檢查通道是否真正連接（解決狀態不一致問題）
    private static func isChannelReallyConnected(session: MCSession, peer: MCPeerID) async -> Bool {
        // 第一層：基本連接檢查
        guard session.connectedPeers.contains(peer) else {
            print("🔍 SafeNetworkOperations: \(peer.displayName) 不在連接列表中")
            return false
        }
        
        // 第二層：短暫延遲後重新檢查（防止狀態更新延遲）
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        guard session.connectedPeers.contains(peer) else {
            print("🔍 SafeNetworkOperations: \(peer.displayName) 連接狀態已變化")
            return false
        }
        
        // 第三層：嘗試發送測試數據（最終驗證）
        let testData = "ping".data(using: .utf8) ?? Data()
        do {
            try session.send(testData, toPeers: [peer], with: .unreliable)
            print("✅ SafeNetworkOperations: \(peer.displayName) 通道驗證通過")
            return true
        } catch {
            if error.localizedDescription.contains("Not in connected state") {
                print("❌ SafeNetworkOperations: \(peer.displayName) 檢測到 'Not in connected state' 錯誤")
            } else {
                print("❌ SafeNetworkOperations: \(peer.displayName) 其他發送錯誤: \(error)")
            }
            return false
        }
    }
    
    // MARK: - 安全的資料發送
    
    /// 安全發送資料，自動處理 "Not in connected state" 錯誤
    static func safeSendData(
        _ data: Data,
        to peers: [MCPeerID],
        via session: MCSession,
        mode: MCSessionSendDataMode = .reliable,
        maxRetries: Int = 3
    ) async throws -> Int {
        
        // 預先驗證所有 peers
        let validPeers = await validateMCSessionState(session: session, peers: peers)
        
        guard !validPeers.isEmpty else {
            throw NetworkSendError.noPeersAvailable
        }
        
        var successCount = 0
        var lastError: Error?
        
        for peer in validPeers {
            var retryCount = 0
            
            while retryCount < maxRetries {
                do {
                    // 發送前最後一次檢查
                    guard session.connectedPeers.contains(peer) else {
                        print("⚠️ SafeNetworkOperations: \(peer.displayName) 發送前檢查失敗")
                        break
                    }
                    
                    try session.send(data, toPeers: [peer], with: mode)
                    print("✅ SafeNetworkOperations: 成功發送給 \(peer.displayName) (\(data.count) bytes)")
                    successCount += 1
                    break
                    
                } catch {
                    retryCount += 1
                    lastError = error
                    
                    if error.localizedDescription.contains("Not in connected state") {
                        print("🔄 SafeNetworkOperations: \(peer.displayName) 'Not in connected state' 錯誤，重試 \(retryCount)/\(maxRetries)")
                        
                        // 短暫等待後重試
                        try? await Task.sleep(nanoseconds: 100_000_000 * UInt64(retryCount)) // 遞增延遲
                        
                    } else {
                        print("❌ SafeNetworkOperations: \(peer.displayName) 其他錯誤，不重試: \(error)")
                        break
                    }
                }
            }
        }
        
        if successCount == 0 {
            throw lastError ?? NetworkSendError.allPeersFailed
        }
        
        return successCount
    }
    
    // MARK: - 連接狀態監控
    
    /// 連續監控連接狀態，檢測潛在問題
    static func monitorConnectionHealth(session: MCSession, peer: MCPeerID, interval: TimeInterval = 1.0) -> AsyncThrowingStream<ConnectionHealth, Error> {
        return AsyncThrowingStream { continuation in
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task {
                    let health = await checkConnectionHealth(session: session, peer: peer)
                    continuation.yield(health)
                }
            }
            
            continuation.onTermination = { _ in
                timer.invalidate()
            }
        }
    }
    
    /// 檢查連接健康狀態
    private static func checkConnectionHealth(session: MCSession, peer: MCPeerID) async -> ConnectionHealth {
        let startTime = Date()
        
        // 檢查基本連接
        guard session.connectedPeers.contains(peer) else {
            return ConnectionHealth(peer: peer, status: .disconnected, latency: nil, timestamp: startTime)
        }
        
        // 測試實際通訊
        let testData = "health_check".data(using: .utf8) ?? Data()
        do {
            try session.send(testData, toPeers: [peer], with: .unreliable)
            let latency = Date().timeIntervalSince(startTime)
            return ConnectionHealth(peer: peer, status: .healthy, latency: latency, timestamp: startTime)
        } catch {
            if error.localizedDescription.contains("Not in connected state") {
                return ConnectionHealth(peer: peer, status: .stateInconsistent, latency: nil, timestamp: startTime)
            } else {
                return ConnectionHealth(peer: peer, status: .error(error), latency: nil, timestamp: startTime)
            }
        }
    }
}

// MARK: - 輔助類型

enum NetworkSendError: Error {
    case noPeersAvailable
    case allPeersFailed
    case sessionNotReady
}

struct ConnectionHealth {
    let peer: MCPeerID
    let status: ConnectionStatus
    let latency: TimeInterval?
    let timestamp: Date
    
    enum ConnectionStatus {
        case healthy
        case disconnected
        case stateInconsistent  // "Not in connected state" 狀況
        case error(Error)
    }
}

// MARK: - BingoGameViewModel 擴展

extension BingoGameViewModel {
    
    /// 使用安全網路操作發送遊戲訊息
    func safeBroadcastGameMessage(_ message: GameMessage) async {
        do {
            let data = try BinaryGameProtocol.encodeGameMessage(
                type: message.type,
                senderID: message.senderID,
                senderName: message.senderName,
                gameRoomID: message.gameRoomID,
                data: message.data
            )
            
            let connectedPeers = meshManager.getConnectedPeers().compactMap { MCPeerID(displayName: $0) }
            
            // 使用 SafeNetworkOperations 發送
            let successCount = try await SafeNetworkOperations.safeSendData(
                data,
                to: connectedPeers,
                via: getSessionFromMeshManager(), // 需要實現
                mode: .reliable,
                maxRetries: 3
            )
            
            print("✅ SafeNetworkOperations: 遊戲訊息成功發送給 \(successCount) 個設備")
            
        } catch {
            print("❌ SafeNetworkOperations: 遊戲訊息發送失敗: \(error)")
            
            // 觸發網路恢復程序
            performNetworkRecovery()
        }
    }
    
    /// 從 MeshManager 獲取 MCSession（需要擴展 MeshManager）
    private func getSessionFromMeshManager() -> MCSession {
        // 這需要 MeshManager 提供對 MCSession 的訪問
        // 可能需要修改 MeshManagerProtocol
        fatalError("需要實現 MCSession 訪問")
    }
}