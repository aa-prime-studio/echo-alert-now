import Foundation
import MultipeerConnectivity

// MARK: - NetworkService Protocol (forward declaration)
protocol NetworkServiceProtocol: AnyObject {
    var myPeerID: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    var onDataReceived: ((Data, String) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
    
    func send(_ data: Data, to peers: [MCPeerID]) async throws
    func sendMessage(_ data: Data, toPeer peer: String, messageType: MeshMessageType)
    func getConnectedPeers() -> [String]
}

// MARK: - NetworkService
class NetworkService: NSObject, ObservableObject, NetworkServiceProtocol {
    // MARK: - Configuration  
    private let serviceType = "signalair"
    // 災難通信網路優化：限制連接數防止資源耗盡
    private let maxConnections = 6  // MultipeerConnectivity實際穩定上限
    private var connectionAttempts: Set<String> = []  // 防止重複連接嘗試
    
    // MARK: - Properties
    private var _myPeerID: MCPeerID!
    var myPeerID: MCPeerID { 
        return _myPeerID ?? MCPeerID(displayName: "Unknown")
    }
    var connectedPeers: [MCPeerID] = []
    var onDataReceived: ((Data, String) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    // MARK: - MultipeerConnectivity Components
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    var browser: MCNearbyServiceBrowser
    
    // MARK: - Published State
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isConnected: Bool = false
    @Published var nearbyPeers: [MCPeerID] = []
    
    // MARK: - Legacy Callbacks (for backward compatibility)
    var onReceiveData: ((Data, MCPeerID) -> Void)?
    
    // MARK: - Initialization
    override init() {
        // 使用固定的ID避免循環依賴
        self._myPeerID = MCPeerID(displayName: "SignalAir-\(Int.random(in: 1000...9999))")
        
        // 初始化空的connectedPeers數組
        self.connectedPeers = []
        
        self.session = MCSession(
            peer: _myPeerID!, 
            securityIdentity: nil, 
            encryptionPreference: .none  // 關閉MC層加密，避免與自定義加密衝突
        )
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: _myPeerID!, 
            discoveryInfo: ["version": "1.0"], 
            serviceType: serviceType
        )
        
        self.browser = MCNearbyServiceBrowser(
            peer: _myPeerID!, 
            serviceType: serviceType
        )
        
        super.init()
        
        // Set delegates
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        
        print("NetworkService initialized with peer: \(_myPeerID!.displayName)")
    }
    
    deinit {
        stopNetworking()
    }
    
    // MARK: - Public Methods
    
    /// 開始網路服務
    func startNetworking() {
        print("🚀 Starting networking...")
        connectionStatus = .connecting
        
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        
        print("✅ Advertising and browsing started")
    }
    
    /// 停止網路服務
    func stopNetworking() {
        print("🛑 Stopping networking...")
        
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        
        connectedPeers.removeAll()
        nearbyPeers.removeAll()
        connectionStatus = .disconnected
        isConnected = false
        
        print("✅ Networking stopped")
    }
    
    /// 發送資料到指定的 peers
    func send(_ data: Data, to peers: [MCPeerID]? = nil) async throws {
        let targetPeers = peers ?? session.connectedPeers
        
        guard !targetPeers.isEmpty else {
            throw NetworkError.notConnected
        }
        
        // 驗證所有目標 peer 仍然連接中
        let currentlyConnected = session.connectedPeers
        let validPeers = targetPeers.filter { currentlyConnected.contains($0) }
        
        guard !validPeers.isEmpty else {
            print("⚠️ All target peers disconnected, cannot send")
            throw NetworkError.notConnected
        }
        
        // 如果有些 peer 已斷線，只發送給仍連接的 peer
        if validPeers.count < targetPeers.count {
            let disconnectedCount = targetPeers.count - validPeers.count
            print("⚠️ \(disconnectedCount) peer(s) disconnected, sending to \(validPeers.count) remaining peers")
        }
        
        do {
            try session.send(data, toPeers: validPeers, with: .reliable)
            print("📤 Sent \(data.count) bytes to \(validPeers.count) peers")
        } catch {
            print("❌ Failed to send data: \(error)")
            throw NetworkError.sendFailed
        }
    }
    
    /// 發送資料到所有連接的 peers
    func broadcast(_ data: Data) async throws {
        try await send(data, to: nil)
    }
    
    /// NetworkServiceProtocol 兼容的 send 方法
    func send(_ data: Data, to peers: [MCPeerID]) async throws {
        try await send(data, to: peers as [MCPeerID]?)
    }
    
    /// 手動連接到特定 peer
    func connect(to peer: MCPeerID) {
        print("🤝 Connecting to peer: \(peer.displayName)")
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 90)
    }
    
    /// 斷開與特定 peer 的連接
    func disconnect(from peer: MCPeerID) {
        session.cancelConnectPeer(peer)
        print("🔌 Disconnected from peer: \(peer.displayName)")
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus() {
        DispatchQueue.main.async {
            self.connectedPeers = self.session.connectedPeers
            self.isConnected = !self.connectedPeers.isEmpty
            
            if self.isConnected {
                self.connectionStatus = .connected
            } else if self.connectionStatus == .connecting {
                // Keep connecting status if still trying to connect
            } else {
                self.connectionStatus = .disconnected
            }
            
            print("📊 Connection status updated: \(self.connectionStatus), Connected peers: \(self.connectedPeers.count)")
        }
    }
    
    private func handlePeerConnection(_ peer: MCPeerID) {
        DispatchQueue.main.async {
            print("✅ Peer connected: \(peer.displayName)")
            self.updateConnectionStatus()
            self.onPeerConnected?(peer.displayName)
            
            // 通知自動重連管理器清除斷線記錄（暫時註解）
            // ServiceContainer.shared.autoReconnectManager?.clearDisconnectionRecord(peerID: peer)
        }
    }
    
    private func handlePeerDisconnection(_ peer: MCPeerID) {
        DispatchQueue.main.async {
            print("❌ Peer disconnected: \(peer.displayName)")
            self.updateConnectionStatus()
            self.onPeerDisconnected?(peer.displayName)
            
            // 記錄斷線以便自動重連（暫時註解）
            // ServiceContainer.shared.autoReconnectManager?.recordDisconnection(peerID: peer)
        }
    }
}

// MARK: - MCSessionDelegate
extension NetworkService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // 日誌詳細的狀態變化
        print("🔄 Session state changed for \(peerID.displayName): \(state)")
        
        switch state {
        case .connecting:
            print("🔄 Connecting to: \(peerID.displayName)")
            
        case .connected:
            print("✅ Connected to: \(peerID.displayName)")
            // 稍微延遲以確保連接穩定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handlePeerConnection(peerID)
            }
            
        case .notConnected:
            print("❌ Peer disconnected: \(peerID.displayName)")
            handlePeerDisconnection(peerID)
            
        @unknown default:
            print("⚠️ Unknown session state for peer: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📥 Received \(data.count) bytes from: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            // 調用新的協議回調
            self.onDataReceived?(data, peerID.displayName)
            
            // 保持向後兼容性
            self.onReceiveData?(data, peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("📡 Received stream from: \(peerID.displayName)")
        // Stream handling if needed in the future
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("📂 Started receiving resource from: \(peerID.displayName)")
        // Resource handling if needed in the future
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("❌ Error receiving resource from \(peerID.displayName): \(error)")
        } else {
            print("📁 Finished receiving resource from: \(peerID.displayName)")
        }
    }
    
    // MARK: - Error Handling
    func session(_ session: MCSession, didFailWithError error: Error) {
        print("❌ Session failed with error: \(error)")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
            self.connectedPeers = []
            self.isConnected = false
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NetworkService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received invitation from: \(peerID.displayName)")
        
        // 自動接受邀請
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to start advertising: \(error)")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NetworkService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found peer: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            if !self.nearbyPeers.contains(peerID) {
                self.nearbyPeers.append(peerID)
            }
        }
        
        // 發送設備發現通知給自動重連管理器
        NotificationCenter.default.post(
            name: Notification.Name("PeerFound"),
            object: peerID
        )
        
        // 🚨 災難通信網路優化：智能連接管理
        let currentConnections = session.connectedPeers.count
        let peerName = peerID.displayName
        
        // 1. 檢查連接數限制
        guard currentConnections < maxConnections else {
            print("⚠️ 連接數已達上限 (\(maxConnections))，跳過連接 \(peerName)")
            return
        }
        
        // 2. 檢查是否已經連接
        if session.connectedPeers.contains(peerID) {
            print("ℹ️ 已經連接到 \(peerName)")
            return
        }
        
        // 3. 防止重複連接嘗試
        guard !connectionAttempts.contains(peerName) else {
            print("⚠️ 已在嘗試連接 \(peerName)，避免重複")
            return
        }
        
        // 4. 避免連接自己
        guard peerName != myPeerID.displayName else {
            return
        }
        
        // 5. 記錄連接嘗試並設置自動清理
        connectionAttempts.insert(peerName)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { // 降低超時時間到30秒
            self.connectionAttempts.remove(peerName)
        }
        
        print("🤝 嘗試連接 \(peerName) (\(currentConnections+1)/\(maxConnections))")
        
        // 使用較短的超時時間以快速失敗和重試
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("📤 Lost peer: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to start browsing: \(error)")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
        }
    }
}

// MARK: - Connection Reliability Enhancement
extension NetworkService {
    /// 檢查連接品質並提供穩定性建議
    func checkConnectionQuality() {
        let peerCount = connectedPeers.count
        print("📊 連接品質檢查：\(peerCount) 個連接的設備")
        
        // 簡單穩定性檢查，不進行激進的重連
        if peerCount == 0 && connectionStatus == .connected {
            print("⚠️ 連接狀態不一致，需要更新狀態")
            updateConnectionStatus()
        }
    }
    
    // MARK: - Protocol Methods
    func sendMessage(_ data: Data, toPeer peer: String, messageType: MeshMessageType) {
        // 找到對應的 MCPeerID
        if let peerID = connectedPeers.first(where: { $0.displayName == peer }) {
            Task {
                do {
                    try await send(data, to: [peerID])
                } catch {
                    print("❌ Failed to send message to \(peer): \(error)")
                }
            }
        }
    }
    
    func getConnectedPeers() -> [String] {
        return connectedPeers.map { $0.displayName }
    }
} 