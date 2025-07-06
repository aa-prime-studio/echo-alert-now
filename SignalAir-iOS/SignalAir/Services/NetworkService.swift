import Foundation
@preconcurrency import MultipeerConnectivity

// MARK: - Connection State Manager Actor
actor ConnectionStateManager {
    private var pendingOperations: [String: [() -> Void]] = [:]
    private var connectionAttempts: Set<String> = []
    private var retryAttempts: [String: Int] = [:]
    
    func validatePeers(_ targetPeers: [MCPeerID], sessionPeers: [MCPeerID], threadSafePeers: [MCPeerID]) -> [MCPeerID] {
        return targetPeers.filter { peer in
            let isSessionConnected = sessionPeers.contains(peer)
            let isThreadSafeConnected = threadSafePeers.contains(peer)
            let isConnected = isSessionConnected && isThreadSafeConnected
            
            if !isConnected {
                print("⚠️ Peer \(peer.displayName) 不在連接狀態 (session: \(isSessionConnected), safe: \(isThreadSafeConnected))")
            }
            return isConnected
        }
    }
    
    func cleanupPeer(_ peerName: String) {
        if let operations = pendingOperations[peerName] {
            print("🧹 清理 \(peerName) 的 \(operations.count) 個待處理操作")
            pendingOperations.removeValue(forKey: peerName)
        }
        
        connectionAttempts.remove(peerName)
        retryAttempts.removeValue(forKey: peerName)
    }
    
    func addConnectionAttempt(_ peerName: String) {
        connectionAttempts.insert(peerName)
    }
    
    func removeConnectionAttempt(_ peerName: String) {
        connectionAttempts.remove(peerName)
    }
    
    func hasConnectionAttempt(_ peerName: String) -> Bool {
        return connectionAttempts.contains(peerName)
    }
    
    func getRetryCount(_ peerName: String) -> Int {
        return retryAttempts[peerName] ?? 0
    }
    
    func setRetryCount(_ peerName: String, count: Int) {
        retryAttempts[peerName] = count
    }
    
    func removeRetryRecord(_ peerName: String) {
        retryAttempts.removeValue(forKey: peerName)
    }
}

// MARK: - NetworkService Protocol (forward declaration)
@MainActor
protocol NetworkServiceProtocol: AnyObject, Sendable {
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
@MainActor
class NetworkService: NSObject, ObservableObject, NetworkServiceProtocol, @unchecked Sendable {
    // MARK: - Configuration  
    private let serviceType = "signalair"
    
    // 動態連線數限制：根據設備性能調整
    private var maxConnections: Int {
        let deviceMemory = ProcessInfo.processInfo.physicalMemory
        if deviceMemory > 4_000_000_000 { // 4GB+
            return 15
        } else if deviceMemory > 2_000_000_000 { // 2GB+
            return 10
        } else {
            return 6
        }
    }
    
    // MARK: - Thread-Safe Properties
    private let sessionQueue = DispatchQueue(label: "com.signalair.session", qos: .userInitiated)
    private let maxRetries = 3  // 最大重試次數
    
    // MARK: - 診斷工具 🔍
    private var sessionCreationCount = 0
    private var dataChannelUsageCount = 0
    private var streamChannelUsageCount = 0
    private var lastChannelError: (operation: String, error: Error, timestamp: Date)?
    
    // 連接狀態管理器 (使用Actor模式)
    private let connectionStateManager = ConnectionStateManager()
    
    // MARK: - Properties
    private var _myPeerID: MCPeerID?
    var myPeerID: MCPeerID { 
        return _myPeerID ?? MCPeerID(displayName: "Unknown-\(UUID().uuidString.suffix(4))")
    }
    
    // MainActor-isolated connectedPeers (執行緒安全由 @MainActor 保證)
    private var _connectedPeers: [MCPeerID] = []
    var connectedPeers: [MCPeerID] {
        get {
            return _connectedPeers
        }
        set {
            _connectedPeers = newValue
        }
    }
    
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
    
    // MARK: - Initialization (優化為非阻塞初始化)
    override init() {
        // 使用UUID確保設備ID唯一性，避免多設備衝突
        let uniqueID = UUID().uuidString.suffix(8)
        self._myPeerID = MCPeerID(displayName: "SignalAir-\(uniqueID)")
        
        // 初始化空的connectedPeers數組（留到 super.init() 之後）
        
        // 使用安全的可選值解包
        guard let safePeerID = _myPeerID else {
            fatalError("Unable to create MCPeerID")
        }
        
        // 針對離線災難通信優化 MCSession 配置
        self.session = MCSession(
            peer: safePeerID, 
            securityIdentity: nil, 
            encryptionPreference: .optional  // 可選加密，提高兼容性
        )
        
        // 快速初始化 advertiser 和 browser（不啟動）
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: safePeerID, 
            discoveryInfo: ["version": "1.0"], 
            serviceType: serviceType
        )
        
        self.browser = MCNearbyServiceBrowser(
            peer: safePeerID, 
            serviceType: serviceType
        )
        
        super.init()
        
        // 🔍 追蹤 Session 創建（現在可以安全使用 self）
        trackSessionCreation()
        
        // 初始化 connectedPeers（現在可以安全使用 self）
        self.connectedPeers = []
        
        // 設置 delegates - 改為同步設置，確保立即可用
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        
        // 確保 delegates 設置完成後才標記初始化完成
        print("✅ NetworkService: 同步初始化完成，delegates 已設置，peer: \(self.myPeerID.displayName)")
        
        print("🚀 NetworkService: 快速初始化完成，peer: \(self.myPeerID.displayName)")
    }
    
    deinit {
        // 立即同步停止網路服務，避免異步調用風險
        print("🔄 NetworkService: 開始清理資源...")
        
        // 直接在當前線程清理，確保資源被正確釋放
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        
        print("✅ NetworkService: 資源清理完成")
    }
    
    // MARK: - Public Methods
    
    /// 開始網路服務（非阻塞版本）
    func startNetworking() {
        print("🚀 Starting networking (non-blocking)...")
        
        DispatchQueue.main.async { @Sendable in
            self.connectionStatus = .connecting
        }
        
        // 在背景線程延遲後回到主線程啟動網路服務
        Task.detached {
            // 小延遲確保初始化完成
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                // 確保 delegates 已設置
                if self.session.delegate == nil || self.advertiser.delegate == nil || self.browser.delegate == nil {
                    print("⚠️ NetworkService: Delegates 未完全設置，但繼續啟動")
                }
                
                // 啟動廣播和瀏覽
                self.advertiser.startAdvertisingPeer()
                self.browser.startBrowsingForPeers()
                
                print("✅ NetworkService: 廣播和瀏覽已啟動（非阻塞）")
            }
        }
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
    
    /// 發送資料到指定的 peers（強化連接狀態檢查）
    @MainActor
    func send(_ data: Data, to peers: [MCPeerID]? = nil) async throws {
        let targetPeers = peers ?? session.connectedPeers
        
        guard !targetPeers.isEmpty else {
            print("❌ NetworkService: 沒有目標 peers")
            throw NetworkError.notConnected
        }
        
        // 🚨 強化連接狀態檢查 - 三重驗證機制
        let currentlyConnected = session.connectedPeers
        let threadSafeConnected = self.connectedPeers
        
        // 1. 使用Actor保護連接狀態檢查
        let validPeers = await connectionStateManager.validatePeers(
            targetPeers, 
            sessionPeers: currentlyConnected, 
            threadSafePeers: threadSafeConnected
        )
        
        guard !validPeers.isEmpty else {
            print("❌ NetworkService: 所有目標 peers 都已斷開連接，跳過發送")
            throw NetworkError.notConnected
        }
        
        // 2. 最終發送前再次檢查連接狀態（防止競態條件）
        let finalValidPeers = validPeers.filter { peer in
            let isConnected = session.connectedPeers.contains(peer)
            if !isConnected {
                print("⚠️ NetworkService: Peer \(peer.displayName) 在發送前已斷開")
            }
            return isConnected
        }
        
        guard !finalValidPeers.isEmpty else {
            print("❌ NetworkService: 發送前最終檢查：所有 peers 都已斷開")
            throw NetworkError.notConnected
        }
        
        print("📤 NetworkService: 準備發送 \(data.count) bytes 到 \(finalValidPeers.count) 個 peers")
        
        // 3. 帶有連接狀態保護的重試發送機制
        try await sendWithConnectionProtection(data, to: finalValidPeers, maxRetries: 3)
    }
    
    /// 發送資料到所有連接的 peers
    func broadcast(_ data: Data) async throws {
        try await send(data, to: nil)
    }
    
    /// NetworkServiceProtocol 兼容的 send 方法
    @MainActor
    func send(_ data: Data, to peers: [MCPeerID]) async throws {
        try await send(data, to: peers as [MCPeerID]?)
    }
    
    /// 手動連接到特定 peer
    func connect(to peer: MCPeerID) {
        print("🤝 Connecting to peer: \(peer.displayName)")
        // 動態超時設定
        let timeout: TimeInterval = 30
        browser.invitePeer(peer, to: session, withContext: nil, timeout: timeout)
    }
    
    /// 斷開與特定 peer 的連接
    func disconnect(from peer: MCPeerID) {
        session.cancelConnectPeer(peer)
        print("🔌 Disconnected from peer: \(peer.displayName)")
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionStatus() {
        DispatchQueue.main.async { @Sendable in
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
        DispatchQueue.main.async { @Sendable in
            print("✅ Peer connected: \(peer.displayName)")
            self.updateConnectionStatus()
            self.onPeerConnected?(peer.displayName)
            
            // 通知自動重連管理器清除斷線記錄（暫時註解）
            // ServiceContainer.shared.autoReconnectManager?.clearDisconnectionRecord(peerID: peer)
        }
    }
    
    private func handlePeerDisconnection(_ peer: MCPeerID) {
        DispatchQueue.main.async { @Sendable in
            print("❌ Peer disconnected: \(peer.displayName)")
            
            // 清理該 peer 的所有待處理操作
            self.cleanupPendingOperations(for: peer)
            
            self.updateConnectionStatus()
            self.onPeerDisconnected?(peer.displayName)
            
            // 記錄斷線以便自動重連（暫時註解）
            // ServiceContainer.shared.autoReconnectManager?.recordDisconnection(peerID: peer)
        }
    }
    
    /// 清理特定 peer 的待處理操作
    private func cleanupPendingOperations(for peer: MCPeerID) {
        let peerName = peer.displayName
        Task {
            await connectionStateManager.cleanupPeer(peerName)
        }
    }
}

// MARK: - MCSessionDelegate
extension NetworkService: @preconcurrency MCSessionDelegate {
    @MainActor
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // 防禦性檢查：確保 session 仍然有效
        guard self.session == session else {
            print("⚠️ 收到來自舊 session 的狀態變更，忽略")
            return
        }
        
        print("🔄 Session state changed for \(peerID.displayName): \(state)")
        
        switch state {
        case .connecting:
            print("🔄 Connecting to: \(peerID.displayName)")
            
        case .connected:
            print("✅ Connected to: \(peerID.displayName)")
            // 連接成功，清理重試記錄
            Task {
                await connectionStateManager.removeRetryRecord(peerID.displayName)
                await connectionStateManager.removeConnectionAttempt(peerID.displayName)
            }
            
            // 立即更新連接狀態
            updateConnectionStatus()
            
            // 稍微延遲以確保連接穩定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { @Sendable [weak self] in
                guard let self = self else { return }
                self.handlePeerConnection(peerID)
            }
            
        case .notConnected:
            print("❌ Peer disconnected: \(peerID.displayName)")
            // 立即更新連接狀態
            updateConnectionStatus()
            
            // 清理連接嘗試記錄
            Task {
                await connectionStateManager.removeConnectionAttempt(peerID.displayName)
            }
            
            // 處理斷開連接
            handlePeerDisconnection(peerID)
            
            // 離線環境重試機制（降低重試頻率避免衝突）
            Task { [weak self] in
                guard let self = self else { return }
                let currentRetries = await self.connectionStateManager.getRetryCount(peerID.displayName)
                if currentRetries < self.maxRetries {
                    await self.connectionStateManager.setRetryCount(peerID.displayName, count: currentRetries + 1)
                    print("🔄 離線重連嘗試 \(currentRetries + 1)/\(self.maxRetries) for \(peerID.displayName)")
                    
                    // 增加延遲時間，避免與密鑰交換流程衝突
                    let delay = Double(currentRetries + 1) * 5.0 // 從2秒改為5秒
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { @Sendable [weak self] in
                        guard let self = self else { return }
                        // 重試前檢查是否已經重新連接
                        if !self.session.connectedPeers.contains(peerID) {
                            self.retryConnection(to: peerID)
                        } else {
                            print("✅ \(peerID.displayName) 已重新連接，跳過重試")
                            Task {
                                await self.connectionStateManager.removeRetryRecord(peerID.displayName)
                            }
                        }
                    }
                } else {
                    print("⚠️ 達到最大重試次數，停止嘗試連接 \(peerID.displayName)")
                    await self.connectionStateManager.removeRetryRecord(peerID.displayName)
                }
            }
            
        @unknown default:
            print("⚠️ Unknown session state for peer: \(peerID.displayName)")
        }
    }
    
    @MainActor
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📥 Received \(data.count) bytes from: \(peerID.displayName)")
        
        // 調用新的協議回調
        self.onDataReceived?(data, peerID.displayName)
        
        // 保持向後兼容性
        self.onReceiveData?(data, peerID)
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
    @MainActor
    func session(_ session: MCSession, didFailWithError error: Error) {
        print("❌ Session failed with error: \(error)")
        self.connectionStatus = .disconnected
        self.connectedPeers = []
        self.isConnected = false
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NetworkService: @preconcurrency MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received invitation from: \(peerID.displayName)")
        
        // 檢查連接數限制
        let currentConnections = session.connectedPeers.count
        guard currentConnections < maxConnections else {
            print("⚠️ 拒絕連接：已達連接上限 (\(maxConnections))")
            invitationHandler(false, nil)
            return
        }
        
        // 檢查是否已連接
        if session.connectedPeers.contains(peerID) {
            print("ℹ️ 已經連接到 \(peerID.displayName)，拒絕重複邀請")
            invitationHandler(false, nil)
            return
        }
        
        // 立即接受邀請 - 離線環境下不需要延遲
        print("✅ 立即接受來自 \(peerID.displayName) 的邀請")
        invitationHandler(true, session)
    }
    
    @MainActor
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to start advertising: \(error)")
        self.connectionStatus = .disconnected
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NetworkService: @preconcurrency MCNearbyServiceBrowserDelegate {
    @MainActor
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found peer: \(peerID.displayName)")
        
        if !self.nearbyPeers.contains(peerID) {
            self.nearbyPeers.append(peerID)
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
        Task { [weak self] in
            guard let self = self else { return }
            let hasAttempt = await self.connectionStateManager.hasConnectionAttempt(peerName)
            guard !hasAttempt else {
                print("⚠️ 已在嘗試連接 \(peerName)，避免重複")
                return
            }
            
            // 4. 避免連接自己
            guard peerName != self.myPeerID.displayName else {
                return
            }
            
            // 5. 記錄連接嘗試並設置自動清理
            await self.connectionStateManager.addConnectionAttempt(peerName)
            let manager = self.connectionStateManager
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { @Sendable in
                Task {
                    await manager.removeConnectionAttempt(peerName)
                }
            }
            
            print("🤝 嘗試連接 \(peerName) (\(currentConnections+1)/\(self.maxConnections))")
            
            // 立即發送邀請 - 離線環境下直接連接更可靠
            print("📤 立即發送邀請給 \(peerName)")
            // 使用較長的超時時間，給離線設備更多時間響應
            DispatchQueue.main.async { @Sendable in
                self.browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 60)
            }
        }
    }
    
    @MainActor
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("📤 Lost peer: \(peerID.displayName)")
        self.nearbyPeers.removeAll { $0 == peerID }
    }
    
    // MARK: - 離線環境重試機制
    
    private func retryConnection(to peerID: MCPeerID) {
        let peerName = peerID.displayName
        
        // 檢查是否還在附近設備列表中
        guard nearbyPeers.contains(peerID) else {
            print("⚠️ \(peerName) 不再附近，取消重試")
            Task {
                await connectionStateManager.removeRetryRecord(peerName)
            }
            return
        }
        
        // 檢查是否已經連接
        guard !session.connectedPeers.contains(peerID) else {
            print("ℹ️ \(peerName) 已經連接，停止重試")
            Task {
                await connectionStateManager.removeRetryRecord(peerName)
            }
            return
        }
        
        // 檢查連接數限制
        guard session.connectedPeers.count < maxConnections else {
            print("⚠️ 連接數已滿，稍後重試 \(peerName)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { @Sendable [weak self] in
                self?.retryConnection(to: peerID)
            }
            return
        }
        
        print("🔄 重試連接 \(peerName)")
        Task { [weak self] in
            guard let self = self else { return }
            await self.connectionStateManager.addConnectionAttempt(peerName)
            
            // 清理連接嘗試記錄（自動超時）
            let manager = self.connectionStateManager
            DispatchQueue.main.asyncAfter(deadline: .now() + 45) { @Sendable in
                Task {
                    await manager.removeConnectionAttempt(peerName)
                }
            }
        }
        
        // 發送邀請
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 45)
    }
    
    @MainActor
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to start browsing: \(error)")
        self.connectionStatus = .disconnected
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
    
    // MARK: - Enhanced Retry Mechanism with Connection Protection
    
    /// 線程安全的 session.send() 包裝器
    @MainActor
    private func safeSessionSend(_ data: Data, to peers: [MCPeerID]) async throws {
        // 在 MainActor 上下文中執行，確保線程安全
        let validPeers = peers.filter { session.connectedPeers.contains($0) }
        guard !validPeers.isEmpty else {
            throw NetworkError.notConnected
        }
        
        do {
            // 🔍 追蹤 Data Channel 使用
            trackDataChannelUsage()
            try session.send(data, toPeers: validPeers, with: .reliable)
        } catch {
            // 🔍 追蹤 Channel 錯誤
            trackChannelError(operation: "session.send", error: error)
            throw error
        }
    }
    
    /// 帶有連接狀態保護的發送方法
    private func sendWithConnectionProtection(_ data: Data, to peers: [MCPeerID], maxRetries: Int) async throws {
        var retryCount = 0
        var lastError: Error?
        var remainingPeers = peers
        
        while retryCount <= maxRetries && !remainingPeers.isEmpty {
            do {
                // 發送前最後一次連接狀態檢查
                remainingPeers = remainingPeers.filter { peer in
                    let isConnected = session.connectedPeers.contains(peer)
                    if !isConnected {
                        print("⚠️ NetworkService: 跳過已斷開的 peer: \(peer.displayName)")
                    }
                    return isConnected
                }
                
                guard !remainingPeers.isEmpty else {
                    print("❌ NetworkService: 所有 peers 在發送時都已斷開")
                    throw NetworkError.notConnected
                }
                
                try await safeSessionSend(data, to: remainingPeers)
                print("✅ NetworkService: 成功發送 \(data.count) bytes 到 \(remainingPeers.count) peers (嘗試 \(retryCount + 1))")
                return
                
            } catch {
                lastError = error
                retryCount += 1
                print("❌ NetworkService: 發送失敗 (嘗試 \(retryCount)): \(error)")
                
                // 檢查是否是連接相關錯誤
                if let mcError = error as? MCError {
                    switch mcError.code {
                    case .notConnected:
                        print("⚠️ NetworkService: 檢測到 MCError.notConnected，更新連接狀態")
                        updateConnectionStatus()
                        // 移除已斷開的 peers
                        remainingPeers = remainingPeers.filter { session.connectedPeers.contains($0) }
                    default:
                        break
                    }
                }
                
                if retryCount <= maxRetries && !remainingPeers.isEmpty {
                    // 動態延遲：基於重試次數和連接狀態調整
                    let baseDelay = TimeInterval(pow(1.5, Double(retryCount)))
                    let connectionPenalty = remainingPeers.count < peers.count ? 1.0 : 0.0
                    let delay = baseDelay + connectionPenalty
                    
                    print("⏳ NetworkService: 等待 \(String(format: "%.1f", delay))s 後重試")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // 更新連接狀態以反映實際情況
        updateConnectionStatus()
        
        if remainingPeers.isEmpty {
            throw NetworkError.notConnected
        } else {
            throw lastError ?? NetworkError.sendFailed
        }
    }
    
    /// 向後兼容的重試機制
    private func sendWithRetry(_ data: Data, to peers: [MCPeerID], maxRetries: Int) async throws {
        try await sendWithConnectionProtection(data, to: peers, maxRetries: maxRetries)
    }
    
    // MARK: - 🔍 診斷工具（最小侵入性）
    
    /// 獲取完整的連線診斷報告
    func getDiagnosticReport() -> String {
        let sessionInfo = getSessionDiagnostics()
        let channelInfo = getChannelDiagnostics()
        let errorInfo = getErrorDiagnostics()
        
        let report = """
        📊 NetworkService 診斷報告
        ═══════════════════════════
        
        🔗 MCSession 狀態:
        \(sessionInfo)
        
        📡 通道使用統計:
        \(channelInfo)
        
        ❌ 錯誤記錄:
        \(errorInfo)
        
        📱 實例資訊:
        - NetworkService 實例: \(ObjectIdentifier(self))
        - Session 實例: \(ObjectIdentifier(session))
        - 診斷時間: \(Date().formatted())
        """
        
        print("*** DETAILED DIAGNOSTIC REPORT ***")
        print(report)
        print("*** END DIAGNOSTIC REPORT ***")
        
        return report
    }
    
    /// Session 相關診斷
    private func getSessionDiagnostics() -> String {
        let connectedPeers = session.connectedPeers
        let nearbyPeers = nearbyPeers
        
        return """
        - Session 創建次數: \(sessionCreationCount)
        - 當前連接的 Peers: \(connectedPeers.count) [\(connectedPeers.map(\.displayName).joined(separator: ", "))]
        - 附近發現的 Peers: \(nearbyPeers.count) [\(nearbyPeers.map(\.displayName).joined(separator: ", "))]
        - Session State: \(session.connectedPeers.isEmpty ? "無連接" : "有連接")
        - 我的 PeerID: \(myPeerID.displayName)
        - Advertiser 狀態: 已初始化
        - Browser 狀態: 已初始化
        """
    }
    
    /// 通道使用診斷
    private func getChannelDiagnostics() -> String {
        return """
        - Data Channel 使用次數: \(dataChannelUsageCount)
        - Stream Channel 使用次數: \(streamChannelUsageCount)
        - 偏好模式: Data Channel (MCSessionSendDataMode.reliable)
        """
    }
    
    /// 錯誤診斷
    private func getErrorDiagnostics() -> String {
        guard let lastError = lastChannelError else {
            return "- 無記錄的 Channel 錯誤"
        }
        
        let timeAgo = Date().timeIntervalSince(lastError.timestamp)
        return """
        - 最後錯誤操作: \(lastError.operation)
        - 錯誤描述: \(lastError.error.localizedDescription)
        - 發生時間: \(String(format: "%.1f", timeAgo)) 秒前
        """
    }
    
    /// 記錄 Data Channel 使用
    private func trackDataChannelUsage() {
        dataChannelUsageCount += 1
    }
    
    /// 記錄 Stream Channel 使用  
    private func trackStreamChannelUsage() {
        streamChannelUsageCount += 1
    }
    
    /// 記錄 Channel 錯誤
    private func trackChannelError(operation: String, error: Error) {
        lastChannelError = (operation: operation, error: error, timestamp: Date())
        print("🚨 Channel 錯誤 [\(operation)]: \(error.localizedDescription)")
    }
    
    /// 記錄 Session 創建
    private func trackSessionCreation() {
        sessionCreationCount += 1
        print("🔄 Session 創建計數: \(sessionCreationCount)")
    }
    
    /// 即時診斷：檢查當前狀態
    func performQuickDiagnostic() {
        print("===============================")
        print("*** DIAGNOSTIC BUTTON CLICKED ***")
        print("===============================")
        print("""
        
        🔍 即時診斷檢查:
        - 現在時間: \(Date().formatted(.dateTime.hour().minute().second()))
        - Session 連接數: \(session.connectedPeers.count)
        - Published 連接數: \(connectedPeers.count)
        - 連接狀態一致性: \(session.connectedPeers.count == connectedPeers.count ? "✅" : "❌")
        - 近期是否有錯誤: \(lastChannelError != nil ? "⚠️" : "✅")
        - Device ID: \(myPeerID.displayName)
        - Session 創建次數: \(sessionCreationCount)
        
        """)
        print("===============================")
    }
    
} 