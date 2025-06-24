import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var deviceName: String = "我的裝置"
    @Published var connectionStatus: String = "離線模式"
    @Published var connectedPeers: [String] = []
    @Published var isTyping: Bool = false
    @Published var encryptionStatus: String = "等待加密"
    @Published var meshNetworkActive: Bool = false
    @Published var messagesSent: Int = 0
    @Published var messagesReceived: Int = 0
    
    // MARK: - Mesh 網路服務依賴
    private let meshManager: MeshManager
    private let securityService: SecurityService
    private let selfDestructManager: SelfDestructManager
    private let settingsViewModel: SettingsViewModel
    
    // 訊息去重和緩存
    private var messageHashes: Set<String> = []
    private var pendingMessages: [String: ChatMessage] = [:]
    
    // 清理定時器
    private var cleanupTimer: Timer?
    private var typingTimer: Timer?
    private var statusUpdateTimer: Timer?
    
    // MARK: - 初始化
    init(
        meshManager: MeshManager = MeshManager(),
        securityService: SecurityService = SecurityService(),
        selfDestructManager: SelfDestructManager = SelfDestructManager(),
        settingsViewModel: SettingsViewModel = SettingsViewModel()
    ) {
        self.meshManager = meshManager
        self.securityService = securityService
        self.selfDestructManager = selfDestructManager
        self.settingsViewModel = settingsViewModel
        
        setupMeshNetworking()
        setupCleanupTimer()
        setupStatusUpdates()
        
        print("💬 ChatViewModel: Mesh 網路版本初始化完成")
    }
    
    deinit {
        cleanupTimer?.invalidate()
        typingTimer?.invalidate()
        statusUpdateTimer?.invalidate()
        meshManager.stopMeshNetwork()
    }
    
    // MARK: - Mesh 網路設定
    
    private func setupMeshNetworking() {
        // 啟動 Mesh 網路
        meshManager.startMeshNetwork()
        
        // 設定訊息接收回調
        meshManager.onMessageReceived = { [weak self] message in
            self?.handleIncomingMeshMessage(message)
        }
        
        // 設定 Peer 連線狀態回調
        meshManager.onPeerConnected = { [weak self] peerID in
            DispatchQueue.main.async {
                self?.updateConnectionStatus()
                self?.addSystemMessage("🟢 \(peerID) 已加入聊天室")
            }
        }
        
        meshManager.onPeerDisconnected = { [weak self] peerID in
            DispatchQueue.main.async {
                self?.updateConnectionStatus()
                self?.addSystemMessage("🔴 \(peerID) 已離開聊天室")
            }
        }
        
        // 更新裝置名稱
        deviceName = settingsViewModel.userNickname
        meshNetworkActive = true
    }
    
    // MARK: - 公開方法
    
    /// 發送訊息（Mesh 網路加密版本）
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard meshNetworkActive else {
            addSystemMessage("⚠️ 網路未連線，無法發送訊息")
            return
        }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentDeviceName = settingsViewModel.userNickname
        
        let chatMessage = ChatMessage(
            id: UUID().uuidString,
            message: messageText,
            deviceName: currentDeviceName,
            timestamp: Date().timeIntervalSince1970,
            isOwn: true,
            isEncrypted: true
        )
        
        // 本地添加訊息
        addMessageToList(chatMessage)
        
        // 透過 Mesh 網路廣播加密訊息
        do {
            let messageData = try JSONEncoder().encode(chatMessage)
            meshManager.broadcastMessage(messageData, messageType: .chat)
            
            // 追蹤訊息以便自毀
            selfDestructManager.trackMessage(chatMessage.id, type: .chat, priority: .normal)
            
            messagesSent += 1
            newMessage = ""
            
            print("💬 ChatViewModel: 已發送加密訊息: \(messageText)")
            
        } catch {
            print("❌ ChatViewModel: 發送訊息失敗: \(error)")
            addSystemMessage("❌ 訊息發送失敗")
        }
    }
    
    /// 處理接收到的 Mesh 訊息
    private func handleIncomingMeshMessage(_ meshMessage: MeshMessage) {
        guard meshMessage.type == .chat else { return }
        
        do {
            let chatMessage = try JSONDecoder().decode(ChatMessage.self, from: meshMessage.data)
            
            DispatchQueue.main.async {
                // 檢查訊息去重
                if !self.messageHashes.contains(chatMessage.messageHash) {
                    self.addMessageToList(chatMessage)
                    self.messagesReceived += 1
                    
                    // 追蹤接收的訊息以便自毀
                    self.selfDestructManager.trackMessage(chatMessage.id, type: .chat, priority: .normal)
                    
                    print("💬 ChatViewModel: 接收到加密訊息: \(chatMessage.message)")
                }
            }
            
        } catch {
            print("❌ ChatViewModel: 解析訊息失敗: \(error)")
        }
    }
    
    /// 添加訊息到列表
    private func addMessageToList(_ message: ChatMessage) {
        // 檢查去重
        guard !messageHashes.contains(message.messageHash) else { return }
        
        messageHashes.insert(message.messageHash)
        messages.insert(message, at: 0)
        
        // 限制訊息數量
        if messages.count > 100 {
            let removedMessage = messages.removeLast()
            messageHashes.remove(removedMessage.messageHash)
        }
    }
    
    /// 添加系統訊息
    private func addSystemMessage(_ text: String) {
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            message: text,
            deviceName: "系統",
            timestamp: Date().timeIntervalSince1970,
            isOwn: false,
            isEncrypted: false
        )
        
        addMessageToList(systemMessage)
    }
    
    /// 開始打字指示
    func startTyping() {
        isTyping = true
        
        // 廣播打字狀態
        if meshNetworkActive {
            let typingData = "\(settingsViewModel.userNickname) 正在輸入...".data(using: .utf8) ?? Data()
            meshManager.broadcastMessage(typingData, messageType: .system)
        }
        
        // 重置打字定時器
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.stopTyping()
        }
    }
    
    /// 停止打字指示
    func stopTyping() {
        isTyping = false
        typingTimer?.invalidate()
    }
    
    /// 清除訊息
    func clearMessages() {
        // 清除自毀管理器中的追蹤
        for message in messages {
            selfDestructManager.removeMessage(message.id)
        }
        
        messages.removeAll()
        messageHashes.removeAll()
        pendingMessages.removeAll()
        
        print("💬 ChatViewModel: 清除所有聊天訊息")
    }
    
    /// 更新連線狀態
    private func updateConnectionStatus() {
        let peers = meshManager.getConnectedPeers()
        connectedPeers = peers
        
        if peers.isEmpty {
            connectionStatus = "未連線"
            encryptionStatus = "等待加密"
        } else {
            connectionStatus = "已連線 (\(peers.count) 個裝置)"
            encryptionStatus = "端到端加密"
        }
        
        // 更新裝置名稱
        deviceName = settingsViewModel.userNickname
    }
    
    /// 重新連線 Mesh 網路
    func reconnectMeshNetwork() {
        meshManager.stopMeshNetwork()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.meshManager.startMeshNetwork()
            self.addSystemMessage("🔄 已重新連線 Mesh 網路")
        }
    }
    
    /// 格式化時間
    func formatTime(_ timestamp: TimeInterval) -> String {
        let now = Date().timeIntervalSince1970
        let diff = now - timestamp
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        
        if hours > 0 {
            return "\(hours)小時前"
        } else if minutes > 0 {
            return "\(minutes)分鐘前"
        } else {
            return "剛剛"
        }
    }
    
    /// 取得加密狀態描述
    func getEncryptionStatusText() -> String {
        let connectedCount = connectedPeers.count
        if connectedCount == 0 {
            return "等待連線以啟用加密"
        } else {
            return "端到端加密 (\(connectedCount) 個連線)"
        }
    }
    
    /// 取得網路統計
    func getNetworkStats() -> String {
        return "已發送: \(messagesSent) | 已接收: \(messagesReceived)"
    }
    
    // MARK: - 私有方法
    
    /// 設定清理定時器
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupOldMessages()
        }
    }
    
    /// 設定狀態更新定時器
    private func setupStatusUpdates() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateConnectionStatus()
        }
    }
    
    /// 清理舊訊息（與自毀管理器協作）
    private func cleanupOldMessages() {
        let twentyFourHoursAgo = Date().timeIntervalSince1970 - (24 * 60 * 60)
        
        DispatchQueue.main.async {
            let expiredMessages = self.messages.filter { $0.timestamp < twentyFourHoursAgo }
            
            // 從自毀管理器中移除
            for message in expiredMessages {
                self.selfDestructManager.removeMessage(message.id)
                self.messageHashes.remove(message.messageHash)
            }
            
            // 從列表中移除
            self.messages = self.messages.filter { $0.timestamp >= twentyFourHoursAgo }
            
            if !expiredMessages.isEmpty {
                print("💬 ChatViewModel: 清理了 \(expiredMessages.count) 個過期訊息")
            }
        }
    }
}

// MARK: - 預覽支援

extension ChatViewModel {
    /// 創建預覽用的範例資料
    static func preview() -> ChatViewModel {
        let viewModel = ChatViewModel()
        
        // 添加一些範例訊息
        viewModel.messages = [
            ChatMessage(
                id: "1",
                message: "大家好！",
                deviceName: "小明",
                timestamp: Date().timeIntervalSince1970 - 3600,
                isOwn: false,
                isEncrypted: true
            ),
            ChatMessage(
                id: "2", 
                message: "Hello！這是加密訊息",
                deviceName: "我的裝置",
                timestamp: Date().timeIntervalSince1970 - 1800,
                isOwn: true,
                isEncrypted: true
            ),
            ChatMessage(
                id: "3",
                message: "有人收到訊息嗎？",
                deviceName: "小華",
                timestamp: Date().timeIntervalSince1970 - 900,
                isOwn: false,
                isEncrypted: true
            )
        ]
        
        viewModel.connectionStatus = "已連線 (3 個裝置)"
        viewModel.encryptionStatus = "端到端加密"
        viewModel.meshNetworkActive = true
        
        return viewModel
    }
}

// TODO: Step 2 - Mesh 網路整合
/*
 待整合的功能（Step 2）：
 1. NetworkService - P2P 網路連接
 2. SecurityService - 端到端加密 
 3. MeshManager - 訊息路由和轉發
 4. TemporaryIDManager - 臨時裝置ID管理
 5. SelfDestructManager - 24小時自動刪除
 6. FloodProtection - 洪水攻擊保護
 7. SettingsViewModel 整合 - 使用者暱稱管理
 */
