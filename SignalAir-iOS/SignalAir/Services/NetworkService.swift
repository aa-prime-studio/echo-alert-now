import Foundation
import MultipeerConnectivity

// MARK: - NetworkService
class NetworkService: NSObject, ObservableObject {
    // MARK: - Configuration
    private let serviceType = "signalair"
    var temporaryIDManager: TemporaryIDManager?
    
    // MARK: - Properties
    var myPeerID: MCPeerID!
    var connectedPeers: [MCPeerID] = []
    var onDataReceived: ((Data, String) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    
    // MARK: - MultipeerConnectivity Components
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    
    // MARK: - Published State
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isConnected: Bool = false
    @Published var nearbyPeers: [MCPeerID] = []
    
    // MARK: - Legacy Callbacks (for backward compatibility)
    var onReceiveData: ((Data, MCPeerID) -> Void)?
    
    // MARK: - Initialization
    override init() {
        // 初始化 myPeerID
        let idManager = TemporaryIDManager()
        self.temporaryIDManager = idManager
        self.myPeerID = MCPeerID(displayName: idManager.deviceID)
        
        // 初始化空的connectedPeers數組
        self.connectedPeers = []
        
        self.session = MCSession(
            peer: myPeerID, 
            securityIdentity: nil, 
            encryptionPreference: .required
        )
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID, 
            discoveryInfo: ["version": "1.0"], 
            serviceType: serviceType
        )
        
        self.browser = MCNearbyServiceBrowser(
            peer: myPeerID, 
            serviceType: serviceType
        )
        
        super.init()
        
        // Set delegates
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        
        print("NetworkService initialized with peer: \(myPeerID.displayName)")
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
        
        do {
            try session.send(data, toPeers: targetPeers, with: .reliable)
            print("📤 Sent \(data.count) bytes to \(targetPeers.count) peers")
        } catch {
            print("❌ Failed to send data: \(error)")
            throw NetworkError.sendFailed
        }
    }
    
    /// 發送資料到所有連接的 peers
    func broadcast(_ data: Data) async throws {
        try await send(data, to: nil)
    }
    
    /// 手動連接到特定 peer
    func connect(to peer: MCPeerID) {
        print("🤝 Connecting to peer: \(peer.displayName)")
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
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
        }
    }
    
    private func handlePeerDisconnection(_ peer: MCPeerID) {
        DispatchQueue.main.async {
            print("❌ Peer disconnected: \(peer.displayName)")
            self.updateConnectionStatus()
            self.onPeerDisconnected?(peer.displayName)
        }
    }
}

// MARK: - MCSessionDelegate
extension NetworkService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            print("🔄 Connecting to: \(peerID.displayName)")
            
        case .connected:
            handlePeerConnection(peerID)
            
        case .notConnected:
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
        print("📁 Finished receiving resource from: \(peerID.displayName)")
        // Resource handling if needed in the future
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
        
        // 自動嘗試連接
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