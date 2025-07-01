import Foundation
import MultipeerConnectivity

/// 自動重連管理器 - 處理 MultipeerConnectivity 斷線重連
class AutoReconnectManager {
    
    // MARK: - Properties
    
    private weak var networkService: NetworkService?
    private var reconnectTimer: Timer?
    private var reconnectAttempts: [String: Int] = [:]
    private let maxReconnectAttempts = 5
    private let reconnectInterval: TimeInterval = 10.0
    private let queue = DispatchQueue(label: "com.signalAir.autoReconnect", qos: .utility)
    
    // 最近斷線的設備列表
    private var recentlyDisconnectedPeers: Set<MCPeerID> = []
    private let disconnectedPeersLock = NSLock()
    
    // MARK: - Initialization
    
    init(networkService: NetworkService) {
        self.networkService = networkService
        setupObservers()
        print("🔄 AutoReconnectManager: 初始化自動重連機制")
    }
    
    deinit {
        stopReconnectTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 開始自動重連服務
    func start() {
        startReconnectTimer()
        print("🔄 AutoReconnectManager: 開始自動重連服務")
    }
    
    /// 停止自動重連服務
    func stop() {
        stopReconnectTimer()
        reconnectAttempts.removeAll()
        clearDisconnectedPeers()
        print("🔄 AutoReconnectManager: 停止自動重連服務")
    }
    
    /// 記錄設備斷線
    func recordDisconnection(peerID: MCPeerID) {
        disconnectedPeersLock.lock()
        defer { disconnectedPeersLock.unlock() }
        
        recentlyDisconnectedPeers.insert(peerID)
        reconnectAttempts[peerID.displayName] = 0
        
        print("🔄 記錄設備斷線：\(peerID.displayName)")
    }
    
    /// 清除斷線記錄
    func clearDisconnectionRecord(peerID: MCPeerID) {
        disconnectedPeersLock.lock()
        defer { disconnectedPeersLock.unlock() }
        
        recentlyDisconnectedPeers.remove(peerID)
        reconnectAttempts.removeValue(forKey: peerID.displayName)
        
        print("🔄 清除斷線記錄：\(peerID.displayName)")
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 監聽連接不穩定通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionUnstable),
            name: Notification.Name("ConnectionUnstable"),
            object: nil
        )
        
        // 監聽設備發現通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePeerFound),
            name: Notification.Name("PeerFound"),
            object: nil
        )
    }
    
    @objc private func handleConnectionUnstable(_ notification: Notification) {
        if let peerName = notification.object as? String {
            print("⚠️ AutoReconnect: 檢測到不穩定連接 - \(peerName)")
            // 主動斷開並重連
            queue.async { [weak self] in
                self?.initiateReconnection(peerName: peerName)
            }
        }
    }
    
    @objc private func handlePeerFound(_ notification: Notification) {
        if let peerID = notification.object as? MCPeerID {
            // 檢查是否是最近斷線的設備
            disconnectedPeersLock.lock()
            let shouldReconnect = recentlyDisconnectedPeers.contains(peerID)
            disconnectedPeersLock.unlock()
            
            if shouldReconnect {
                print("🔄 發現之前斷線的設備：\(peerID.displayName)，嘗試重連")
                attemptReconnection(peerID: peerID)
            }
        }
    }
    
    private func startReconnectTimer() {
        stopReconnectTimer()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            self?.performReconnectCheck()
        }
        
        if let timer = reconnectTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func performReconnectCheck() {
        guard let networkService = networkService else { return }
        
        // 獲取當前連接的設備
        let connectedPeers = networkService.connectedPeers
        let connectedNames = Set(connectedPeers.map { $0.displayName })
        
        // 檢查是否有需要重連的設備
        disconnectedPeersLock.lock()
        let peersToReconnect = recentlyDisconnectedPeers.filter { peer in
            !connectedNames.contains(peer.displayName)
        }
        disconnectedPeersLock.unlock()
        
        if !peersToReconnect.isEmpty {
            print("🔄 檢測到 \(peersToReconnect.count) 個設備需要重連")
            
            // 重新啟動瀏覽服務以發現設備
            queue.async { [weak self] in
                self?.restartBrowsing()
            }
        }
    }
    
    private func restartBrowsing() {
        guard let networkService = networkService else { return }
        
        print("🔄 重啟設備瀏覽服務...")
        
        // 短暫停止然後重新啟動瀏覽
        networkService.browser.stopBrowsingForPeers()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, let networkService = self.networkService else { return }
            
            networkService.browser.startBrowsingForPeers()
            print("🔄 設備瀏覽服務已重啟")
        }
    }
    
    private func initiateReconnection(peerName: String) {
        // 檢查重連次數
        let attempts = reconnectAttempts[peerName] ?? 0
        guard attempts < maxReconnectAttempts else {
            print("❌ 已達到最大重連次數：\(peerName)")
            reconnectAttempts.removeValue(forKey: peerName)
            return
        }
        
        print("🔄 開始重連程序：\(peerName) (嘗試 \(attempts + 1)/\(maxReconnectAttempts))")
        
        // 重啟瀏覽服務
        restartBrowsing()
        
        // 更新重連次數
        reconnectAttempts[peerName] = attempts + 1
    }
    
    private func attemptReconnection(peerID: MCPeerID) {
        guard let networkService = networkService else { return }
        
        // 檢查重連次數
        let attempts = reconnectAttempts[peerID.displayName] ?? 0
        guard attempts < maxReconnectAttempts else {
            print("❌ 跳過重連，已達到最大次數：\(peerID.displayName)")
            clearDisconnectionRecord(peerID: peerID)
            return
        }
        
        // 嘗試連接
        networkService.connect(to: peerID)
        
        // 更新重連次數
        reconnectAttempts[peerID.displayName] = attempts + 1
        
        print("🔄 嘗試重連：\(peerID.displayName) (第 \(attempts + 1) 次)")
        
        // 設置超時檢查
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            self?.checkReconnectionResult(peerID: peerID)
        }
    }
    
    private func checkReconnectionResult(peerID: MCPeerID) {
        guard let networkService = networkService else { return }
        
        let isConnected = networkService.connectedPeers.contains { $0.displayName == peerID.displayName }
        
        if isConnected {
            print("✅ 重連成功：\(peerID.displayName)")
            clearDisconnectionRecord(peerID: peerID)
        } else {
            let attempts = reconnectAttempts[peerID.displayName] ?? 0
            if attempts >= maxReconnectAttempts {
                print("❌ 重連失敗，已達到最大次數：\(peerID.displayName)")
                clearDisconnectionRecord(peerID: peerID)
            } else {
                print("⚠️ 重連失敗：\(peerID.displayName)，稍後再試")
            }
        }
    }
    
    private func clearDisconnectedPeers() {
        disconnectedPeersLock.lock()
        defer { disconnectedPeersLock.unlock() }
        
        recentlyDisconnectedPeers.removeAll()
    }
}