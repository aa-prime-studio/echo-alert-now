import Foundation
import MultipeerConnectivity
import Combine

// MARK: - 簡化的連接狀態
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(peerCount: Int)
    case error(NetworkError)
    
    var isStable: Bool {
        switch self {
        case .connected: return true
        default: return false
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected: return true
        default: return false
        }
    }
}

// MARK: - 簡化的狀態機
actor ConnectionStateMachine {
    private var currentState: ConnectionState = .disconnected
    private var stateHistory: [ConnectionState] = []
    private let maxHistorySize = 10
    
    func getCurrentState() -> ConnectionState {
        return currentState
    }
    
    func transition(to newState: ConnectionState) -> Bool {
        // 簡化的狀態轉換驗證
        let isValidTransition = validateTransition(from: currentState, to: newState)
        
        if isValidTransition {
            // 記錄狀態歷史
            stateHistory.append(currentState)
            if stateHistory.count > maxHistorySize {
                stateHistory.removeFirst()
            }
            
            currentState = newState
            print("🔄 網路狀態轉換: \(currentState)")
        }
        
        return isValidTransition
    }
    
    private func validateTransition(from oldState: ConnectionState, to newState: ConnectionState) -> Bool {
        // 簡化的轉換規則
        switch (oldState, newState) {
        case (.disconnected, .connecting),
             (.connecting, .connected),
             (.connecting, .disconnected),
             (.connected, .disconnected),
             (_, .error):
            return true
        default:
            return false
        }
    }
    
    func isStableConnection() -> Bool {
        // 檢查最近的狀態是否穩定
        return currentState.isStable
    }
}

// MARK: - 主要的網路管理器
@MainActor
class StableNetworkManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties (最小化)
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var connectedPeers: [MCPeerID] = []
    @Published private(set) var isReady: Bool = false
    
    // MARK: - Private Properties
    private let stateMachine = ConnectionStateMachine()
    private var mcSession: MCSession
    private var mcAdvertiser: MCNearbyServiceAdvertiser
    private var mcBrowser: MCNearbyServiceBrowser
    
    private let serviceType = "signalair-rescue"
    private let peerID: MCPeerID
    
    // 簡化的重連機制
    private var reconnectionTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    
    // 性能監控
    private var lastHealthCheck = Date()
    private let healthCheckInterval: TimeInterval = 10.0
    
    override init() {
        // 創建穩定的 PeerID
        let deviceName = UIDevice.current.name
        self.peerID = MCPeerID(displayName: deviceName)
        
        // 初始化 MultipeerConnectivity 組件
        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.mcAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        super.init()
        
        // 設置代理
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser.delegate = self
        
        print("✅ StableNetworkManager: 初始化完成, PeerID: \(peerID.displayName)")
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Public Interface
    
    /// 確保網路連接就緒
    func ensureConnection() async -> Bool {
        let currentState = await stateMachine.getCurrentState()
        
        guard !currentState.isStable else {
            return true
        }
        
        // 如果未連接，嘗試建立連接
        if case .disconnected = currentState {
            return await attemptConnection()
        }
        
        // 如果正在連接，等待結果
        if case .connecting = currentState {
            return await waitForConnection()
        }
        
        // 錯誤狀態，嘗試重連
        return await handleErrorState()
    }
    
    /// 發送數據 (簡化且穩定的實現)
    func send(_ data: Data, to peers: [MCPeerID]? = nil) async throws {
        guard await ensureConnection() else {
            throw NetworkError.notConnected
        }
        
        let targetPeers = peers ?? connectedPeers
        guard !targetPeers.isEmpty else {
            throw NetworkError.peerNotFound
        }
        
        do {
            try mcSession.send(data, toPeers: targetPeers, with: .reliable)
            print("✅ 數據發送成功: \(data.count) bytes 到 \(targetPeers.count) 個設備")
        } catch {
            print("❌ 數據發送失敗: \(error)")
            await updateConnectionState(.error(NetworkError.sendFailed))
            throw NetworkError.sendFailed
        }
    }
    
    /// 啟動網路服務
    func startNetworking() {
        Task {
            await updateConnectionState(.connecting)
            
            mcAdvertiser.startAdvertisingPeer()
            mcBrowser.startBrowsingForPeers()
            
            print("🚀 網路服務已啟動")
        }
    }
    
    /// 停止網路服務
    func disconnect() {
        mcAdvertiser.stopAdvertisingPeer()
        mcBrowser.stopBrowsingForPeers()
        mcSession.disconnect()
        
        reconnectionTask?.cancel()
        reconnectionTask = nil
        
        Task {
            await updateConnectionState(.disconnected)
        }
        
        print("🛑 網路服務已停止")
    }
    
    // MARK: - Private Methods
    
    private func attemptConnection() async -> Bool {
        await updateConnectionState(.connecting)
        
        startNetworking()
        
        // 等待連接建立 (最多10秒)
        for _ in 0..<50 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            let state = await stateMachine.getCurrentState()
            if state.isStable {
                return true
            }
        }
        
        await updateConnectionState(.error(NetworkError.connectionFailed))
        return false
    }
    
    private func waitForConnection() async -> Bool {
        // 等待連接狀態變化 (最多5秒)
        for _ in 0..<25 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            let state = await stateMachine.getCurrentState()
            if state.isStable {
                return true
            }
            if case .error = state {
                return false
            }
        }
        return false
    }
    
    private func handleErrorState() async -> Bool {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ 達到最大重連次數，停止重連")
            return false
        }
        
        reconnectAttempts += 1
        print("🔄 錯誤狀態重連嘗試 \(reconnectAttempts)/\(maxReconnectAttempts)")
        
        // 重置連接
        disconnect()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒等待
        
        return await attemptConnection()
    }
    
    private func updateConnectionState(_ newState: ConnectionState) async {
        let transitionSuccess = await stateMachine.transition(to: newState)
        
        if transitionSuccess {
            await MainActor.run {
                self.connectionState = newState
                self.isReady = newState.isStable
            }
        }
    }
    
    private func updateConnectedPeers() {
        let peers = mcSession.connectedPeers
        self.connectedPeers = peers
        
        Task {
            let newState: ConnectionState = peers.isEmpty ? .disconnected : .connected(peerCount: peers.count)
            await updateConnectionState(newState)
        }
        
        // 重置重連計數器（成功連接時）
        if !peers.isEmpty {
            reconnectAttempts = 0
        }
    }
    
    private func performHealthCheck() {
        let now = Date()
        guard now.timeIntervalSince(lastHealthCheck) > healthCheckInterval else { return }
        
        lastHealthCheck = now
        
        // 簡化的健康檢查
        if connectedPeers.isEmpty && connectionState.isConnected {
            Task {
                await updateConnectionState(.disconnected)
            }
        }
    }
}

// MARK: - MCSessionDelegate
extension StableNetworkManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("✅ 設備已連接: \(peerID.displayName)")
            case .connecting:
                print("🔄 正在連接設備: \(peerID.displayName)")
            case .notConnected:
                print("❌ 設備已斷線: \(peerID.displayName)")
            @unknown default:
                print("⚠️ 未知連接狀態: \(peerID.displayName)")
            }
            
            updateConnectedPeers()
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 數據接收處理 - 保持簡單
        print("📨 收到數據: \(data.count) bytes 來自 \(peerID.displayName)")
        
        // 發送通知給其他組件
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NetworkDataReceived"),
                object: nil,
                userInfo: ["data": data, "peerID": peerID.displayName]
            )
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 不使用 stream
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 不使用 resource transfer
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 不使用 resource transfer
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension StableNetworkManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 自動接受連接請求
        invitationHandler(true, mcSession)
        print("📡 自動接受連接邀請來自: \(peerID.displayName)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension StableNetworkManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // 自動邀請發現的設備
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        print("🔍 發現並邀請設備: \(peerID.displayName)")
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("📵 失去設備: \(peerID.displayName)")
    }
}