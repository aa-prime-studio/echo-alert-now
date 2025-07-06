import Foundation
import SwiftUI
import Combine

@MainActor
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
    private var meshManager: MeshManagerProtocol
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
    
    // NotificationCenter 觀察者
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(
        meshManager: MeshManagerProtocol? = nil,
        securityService: SecurityService? = nil,
        selfDestructManager: SelfDestructManager? = nil,
        settingsViewModel: SettingsViewModel? = nil
    ) {
        // 使用 ServiceContainer 中的正確初始化服務
        guard let resolvedMeshManager = meshManager ?? ServiceContainer.shared.meshManager else {
            fatalError("❌ ChatViewModel: 無法獲取 meshManager")
        }
        self.meshManager = resolvedMeshManager
        self.securityService = securityService ?? ServiceContainer.shared.securityService
        self.selfDestructManager = selfDestructManager ?? ServiceContainer.shared.selfDestructManager
        self.settingsViewModel = settingsViewModel ?? ServiceContainer.shared.settingsViewModel
        
        setupMeshNetworking()
        setupCleanupTimer()
        setupStatusUpdates()
        setupNotificationObservers()
        
        print("💬 ChatViewModel: Mesh 網路版本初始化完成")
    }
    
    deinit {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        typingTimer?.invalidate()
        typingTimer = nil
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
        // meshManager.stopMeshNetwork() 在 deinit 中無法安全調用，由系統自動管理
        print("🧹 ChatViewModel: 計時器已清理，網路服務由系統管理")
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
        // 使用 NicknameService 的純暱稱，而不是 SettingsViewModel
        let currentDeviceName = ServiceContainer.shared.nicknameService.userNickname
        let networkID = ServiceContainer.shared.networkService.myPeerID.displayName
        
        let chatMessage = ChatMessage(
            id: UUID().uuidString,
            message: messageText,
            deviceName: "\(currentDeviceName) (\(networkID))", // 使用 "暱稱 (網路ID)" 格式
            timestamp: Date().timeIntervalSince1970,
            isOwn: true,
            isEncrypted: true
        )
        
        // 檢查是否有連接的設備
        let connectedPeers = meshManager.getConnectedPeers()
        guard !connectedPeers.isEmpty else {
            addSystemMessage("⚠️ 沒有連接的設備，無法發送訊息")
            newMessage = ""
            return
        }
        
        // 本地添加訊息
        addMessageToList(chatMessage)
        
        // 使用純二進制協議發送聊天訊息
        // 創建聊天訊息的二進制數據
        let chatData = encodeChatMessage(chatMessage)
        
        // 添加協議頭部
        var binaryPacket = Data()
        binaryPacket.append(1) // 協議版本
        binaryPacket.append(MeshMessageType.chat.rawValue) // 聊天訊息類型 (0x03)
        binaryPacket.append(chatData)
        
        // 透過 meshManager 廣播
        meshManager.broadcastMessage(binaryPacket, messageType: .chat)
        
        // 追蹤訊息以便自毀
        selfDestructManager.trackMessage(chatMessage.id, type: .chat, priority: .normal)
        messagesSent += 1
        print("💬 ChatViewModel: 已發送二進制聊天訊息: \(messageText) (\(binaryPacket.count) bytes)")
        newMessage = ""
    }
    
    /// 編碼聊天訊息為二進制格式
    private func encodeChatMessage(_ message: ChatMessage) -> Data {
        var data = Data()
        
        // 1 byte: 標誌位（聊天訊息）
        data.append(0x01)
        
        // 4 bytes: 時間戳
        let ts = UInt32(message.timestamp)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 訊息ID（16 bytes UUID）
        if let uuid = UUID(uuidString: message.id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 設備名稱
        if let nameData = message.deviceName.data(using: .utf8) {
            data.append(UInt8(min(nameData.count, 255)))
            data.append(nameData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 訊息內容
        if let messageData = message.message.data(using: .utf8) {
            let length = UInt16(min(messageData.count, 65535))
            data.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Array($0) })
            data.append(messageData.prefix(65535))
        } else {
            data.append(contentsOf: [0, 0]) // 空訊息
        }
        
        return data
    }
    
    /// 解碼聊天訊息從二進制格式
    private func decodeChatMessage(_ data: Data) -> ChatMessage? {
        guard data.count >= 25 else { return nil } // 最小大小檢查
        
        var offset = 0
        
        // 跳過標誌位
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = TimeInterval(ts)
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 設備名稱
        guard offset < data.count else { return nil }
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 訊息內容
        guard offset + 2 <= data.count else { return nil }
        let messageLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(messageLength) <= data.count else { return nil }
        let message = String(data: data.subdata(in: offset..<offset+Int(messageLength)), encoding: .utf8) ?? ""
        
        // 如果解碼出的設備名稱不包含設備ID，則添加發送者信息以便區分
        let finalDeviceName: String
        if deviceName.contains("(") && deviceName.contains(")") {
            // 已經是新格式 "暱稱 (設備ID)"
            finalDeviceName = deviceName
        } else {
            // 舊格式，添加來源標識
            finalDeviceName = "\(deviceName) (來源未知)"
        }
        
        return ChatMessage(
            id: uuid.uuidString,
            message: message,
            deviceName: finalDeviceName,
            timestamp: timestamp,
            isOwn: false,
            isEncrypted: true
        )
    }
    
    /// 處理接收到的 Mesh 訊息
    private func handleIncomingMeshMessage(_ meshMessage: MeshMessage) {
        guard meshMessage.type == .chat else { return }
        
        // 解碼二進制聊天數據
        guard let chatMessage = decodeChatMessage(meshMessage.data) else {
            print("❌ ChatViewModel: 無法解碼聊天訊息")
            return
        }
        
        // 檢查是否是自己的訊息（避免重複）
        guard !chatMessage.isOwn else { return }
        
        DispatchQueue.main.async {
            self.addMessageToList(chatMessage)
            self.messagesReceived += 1
            print("💬 ChatViewModel: 收到聊天訊息: \(chatMessage.message) 來自: \(chatMessage.deviceName)")
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
            Task { @MainActor in
                self?.stopTyping()
            }
        }
    }
    
    /// 停止打字指示
    func stopTyping() {
        isTyping = false
        typingTimer?.invalidate()
        typingTimer = nil
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
    
    /// 設置 NotificationCenter 觀察者
    private func setupNotificationObservers() {
        // 監聽來自 ServiceContainer 的二進制聊天訊息
        NotificationCenter.default.publisher(for: NSNotification.Name("ChatMessageReceived"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let binaryData = notification.object as? Data {
                    self?.handleReceivedBinaryChatData(binaryData)
                } else if let chatMessage = notification.object as? ChatMessage {
                    // 向後兼容 ChatMessage 格式
                    self?.handleReceivedChatMessage(chatMessage)
                }
            }
            .store(in: &cancellables)
        
        // 監聽暱稱變更通知
        NotificationCenter.default.publisher(for: NSNotification.Name("NicknameDidChange"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let newNickname = userInfo["newNickname"] as? String {
                    self?.deviceName = newNickname
                    self?.addSystemMessage("👤 暱稱已更新為：\(newNickname)")
                    print("💬 ChatViewModel: 暱稱已更新為 \(newNickname)")
                }
            }
            .store(in: &cancellables)
        
        print("📡 ChatViewModel: NotificationCenter 觀察者已設置")
    }
    
    /// 處理接收到的二進制聊天數據
    private func handleReceivedBinaryChatData(_ data: Data) {
        guard let chatMessage = decodeChatMessage(data) else {
            print("❌ ChatViewModel: 無法解碼二進制聊天數據")
            return
        }
        
        // 接收到的訊息一律標記為非本人發送
        // 使用網路層的 PeerID 來區分，而不是可能被污染的設備ID
        let myNetworkID = ServiceContainer.shared.networkService.myPeerID.displayName
        
        // 檢查是否包含我的網路ID（更可靠的判斷）
        if chatMessage.deviceName.contains(myNetworkID) {
            print("⚠️ ChatViewModel: 跳過來自同設備的訊息: \(chatMessage.deviceName) (我的網路ID: \(myNetworkID))")
            return
        }
        
        // 檢查消息去重（使用修改後的hash，不依賴設備名稱）
        let messageHash = "\(chatMessage.message)_\(chatMessage.id)_\(Int(chatMessage.timestamp))"
        if messageHashes.contains(messageHash) {
            print("⚠️ ChatViewModel: 跳過重複訊息: \(chatMessage.message)")
            return
        }
        
        // 創建新的聊天訊息（確保標記為非本人）
        let receivedMessage = ChatMessage(
            id: chatMessage.id,
            message: chatMessage.message,
            deviceName: chatMessage.deviceName,
            timestamp: chatMessage.timestamp,
            isOwn: false,  // 強制標記為非本人
            isEncrypted: chatMessage.isEncrypted
        )
        
        // 添加自定義 hash 到去重集合
        messageHashes.insert(messageHash)
        
        handleReceivedChatMessage(receivedMessage)
    }
    
    /// 處理接收到的聊天訊息
    private func handleReceivedChatMessage(_ chatMessage: ChatMessage) {
        // 檢查訊息去重
        if !messageHashes.contains(chatMessage.messageHash) {
            addMessageToList(chatMessage)
            messagesReceived += 1
            
            // 追蹤接收的訊息以便自毀
            selfDestructManager.trackMessage(chatMessage.id, type: .chat, priority: .normal)
            
            print("💬 ChatViewModel: 接收到加密訊息: \(chatMessage.message) 來自: \(chatMessage.deviceName)")
        }
    }
    
    /// 設定清理定時器
    private func setupCleanupTimer() {
        // 計算到下一個午夜的時間
        scheduleNextMidnightCleanup()
    }
    
    /// 安排下一次午夜清理
    private func scheduleNextMidnightCleanup() {
        let calendar = Calendar.current
        let now = Date()
        
        // 獲取明天00:00的時間
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let todayMidnight = calendar.date(from: components) else { return }
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayMidnight) ?? todayMidnight
        
        let timeInterval = nextMidnight.timeIntervalSince(now)
        
        // 設定Timer在午夜觸發
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.performMidnightCleanup()
            }
        }
        
        print("💬 ChatViewModel: 下次訊息清理時間 - \(nextMidnight)")
    }
    
    /// 執行午夜清理
    private func performMidnightCleanup() {
        // 清除所有訊息
        let messageCount = messages.count
        clearMessages()
        
        if messageCount > 0 {
            addSystemMessage("🕐 系統已於00:00自動清除聊天記錄")
            print("💬 ChatViewModel: 午夜清理完成，已清除 \(messageCount) 則訊息")
        }
        
        // 安排下一次午夜清理
        scheduleNextMidnightCleanup()
    }
    
    /// 設定狀態更新定時器
    private func setupStatusUpdates() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnectionStatus()
            }
        }
    }
    
    /// 清理舊訊息（保留供手動調用）
    private func cleanupOldMessages() {
        // 此方法現在主要由午夜清理使用
        // 保留此方法以供未來可能的手動清理需求
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
