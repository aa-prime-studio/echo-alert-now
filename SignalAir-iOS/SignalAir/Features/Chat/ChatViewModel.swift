import Foundation
import SwiftUI
import Combine
import UserNotifications

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
    
    // MARK: - 每日訊息限制功能
    @Published var dailyMessageCount: Int = 0
    @Published var dailyLimit: Int = 50  // 免費用戶每日限制
    @Published var isLimitReached: Bool = false
    @Published var remainingMessages: Int = 50
    private var lastResetDate: Date = Date()
    @Published var showUpgradePrompt: Bool = false
    
    // 購買服務依賴
    private var purchaseService: PurchaseService
    
    // 每日限制持久化鍵（本機離線存儲）
    private let dailyCountKey = "SignalAir_DailyMessageCount_Offline"
    private let lastResetDateKey = "SignalAir_LastResetDate_Offline"
    
    // MARK: - Mesh 網路服務依賴
    private var meshManager: MeshManagerProtocol
    private let securityService: SecurityService
    private let selfDestructManager: SelfDestructManager
    
    // MARK: - 狀態緩存和優化
    private var availableUsersCache: [String: [String]] = [:]
    private var lastConnectedPeersState: [String] = []
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
        settingsViewModel: SettingsViewModel? = nil,
        purchaseService: PurchaseService? = nil
    ) {
        // 使用 ServiceContainer 中的正確初始化服務
        if let resolvedMeshManager = meshManager ?? ServiceContainer.shared.meshManager {
            self.meshManager = resolvedMeshManager
        } else {
            print("❌ ChatViewModel: 無法獲取 meshManager，使用預設值")
            // 創建一個預設的 MeshManager
            self.meshManager = MeshManager()
        }
        
        self.securityService = securityService ?? ServiceContainer.shared.securityService
        self.selfDestructManager = selfDestructManager ?? ServiceContainer.shared.selfDestructManager
        self.settingsViewModel = settingsViewModel ?? ServiceContainer.shared.settingsViewModel
        self.purchaseService = purchaseService ?? ServiceContainer.shared.purchaseService
        
        setupMeshNetworking()
        setupCleanupTimer()
        setupStatusUpdates()
        setupNotificationObservers()
        setupDailyLimit()
        
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
                // 🔧 修復：使用真實暱稱和聊天發送按鈕紫色圓圈
                let friendlyName = self?.getFriendlyDeviceName(peerID) ?? peerID
                self?.addSystemMessage("🟪 \(friendlyName) 發送訊息")
            }
        }
        
        meshManager.onPeerDisconnected = { [weak self] peerID in
            DispatchQueue.main.async {
                self?.updateConnectionStatus()
                // 🔧 修復：使用真實暱稱和淺灰色圓圈
                let friendlyName = self?.getFriendlyDeviceName(peerID) ?? peerID
                self?.addSystemMessage("⚪ \(friendlyName) 離開聊天")
            }
        }
        
        // 更新裝置名稱（統一使用 NicknameService）
        deviceName = ServiceContainer.shared.nicknameService.userNickname
        meshNetworkActive = true
        
        // 🔧 監聽暱稱變更通知，用於更新設備暱稱映射
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NicknameDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                if let userInfo = notification.userInfo,
                   let newNickname = userInfo["newNickname"] as? String {
                    // 更新自己的設備名稱
                    self?.deviceName = newNickname
                }
            }
        }
    }
    
    // MARK: - 公開方法
    
    /// 發送訊息（Mesh 網路加密版本）
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard meshNetworkActive else {
            addSystemMessage("⚠️ 網路未連線，無法發送訊息")
            return
        }
        
        // 🚫 檢查臨時黑名單狀態
        let currentDeviceUUID = ServiceContainer.shared.networkService.myPeerID.displayName
        if ServiceContainer.shared.trustScoreManager.checkTemporaryBlacklist(for: currentDeviceUUID) {
            addSystemMessage("⚠️ 您目前被限制操作，請稍後再試")
            return
        }
        
        // 🚨 檢查每日訊息限制
        guard canSendMessage() else {
            showUpgradePrompt = true
            addSystemMessage("🚫 今日免費訊息已達上限 (\(dailyLimit)則)，升級享受無限聊天！")
            return
        }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        // 使用 NicknameService 的純暱稱，而不是 SettingsViewModel
        let currentDeviceName = ServiceContainer.shared.nicknameService.userNickname
        let networkID = ServiceContainer.shared.networkService.myPeerID.displayName
        
        // 解析 @提及
        let mentions = ChatMessage.extractMentions(from: messageText)
        let mentionsMe = false // 自己發送的訊息不會提及自己
        
        let chatMessage = ChatMessage(
            id: UUID().uuidString,
            message: messageText,
            deviceName: "\(currentDeviceName) (\(networkID))", // 使用 "暱稱 (網路ID)" 格式
            timestamp: Date().timeIntervalSince1970,
            isOwn: true,
            isEncrypted: true,
            mentions: mentions,
            mentionsMe: mentionsMe
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
        
        // 🔧 FIX: 直接使用標準MeshMessage格式，不使用專用聊天編碼
        do {
            // 將ChatMessage轉換為二進制數據
            let chatData = encodeChatMessageToBinary(chatMessage)
            
            let message = MeshMessage(
                id: chatMessage.id,
                type: .chat,
                data: chatData  // 使用二進制格式的ChatMessage
            )
            
            let binaryPacket = try BinaryMessageEncoder.encode(message)
            
            // 🔧 FIX: 使用帶加密的發送方法
            Task {
                await sendEncryptedChatMessage(binaryPacket, originalMessage: messageText)
            }
            
        } catch {
            print("❌ 聊天訊息編碼失敗: \(error)")
            return
        }
        
        // 追蹤訊息以便自毀
        selfDestructManager.trackMessage(chatMessage.id, type: .chat, priority: .normal)
        messagesSent += 1
        
        // 🚨 記錄訊息發送並更新限制計數
        recordMessageSent()
        
        newMessage = ""
    }
    
    /// 🔧 FIX: 加密發送聊天訊息
    private func sendEncryptedChatMessage(_ data: Data, originalMessage: String) async {
        let connectedPeerNames = meshManager.getConnectedPeers()
        
        guard !connectedPeerNames.isEmpty else {
            print("⚠️ ChatViewModel: 沒有連接的設備，無法發送聊天訊息")
            return
        }
        
        // 獲取實際的MCPeerID對象
        let networkService = ServiceContainer.shared.networkService
        let connectedPeers = networkService.connectedPeers
        
        for peer in connectedPeers {
            do {
                // 檢查是否有會話密鑰
                let hasKey = await ServiceContainer.shared.securityService.hasSessionKey(for: peer.displayName)
                
                var finalData: Data
                if hasKey {
                    // 使用ChaCha20-Poly1305加密
                    finalData = try await ServiceContainer.shared.securityService.encrypt(data, for: peer.displayName)
                    print("🔐 ChatViewModel: 聊天訊息已加密發送給 \(peer.displayName): \(finalData.count) bytes")
                } else {
                    // 未建立密鑰，發送明文（但記錄警告）
                    finalData = data
                    print("⚠️ ChatViewModel: 聊天訊息明文發送給 \(peer.displayName)（未建立加密）: \(finalData.count) bytes")
                }
                
                try await ServiceContainer.shared.networkService.send(finalData, to: [peer])
                
            } catch {
                print("❌ ChatViewModel: 發送聊天訊息失敗到 \(peer.displayName): \(error)")
            }
        }
        
        print("💬 ChatViewModel: 聊天訊息發送完成: \(originalMessage) → \(connectedPeers.count) 設備")
    }
    
    /// 🔧 FIX: 編碼ChatMessage為二進制格式（與decoder匹配）
    private func encodeChatMessageToBinary(_ message: ChatMessage) -> Data {
        var binaryData = Data()
        
        // 時間戳 (4 bytes)
        let timestamp = UInt32(message.timestamp)
        binaryData.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian, Array.init))
        
        // 設備名稱
        let deviceNameData = message.deviceName.data(using: .utf8) ?? Data()
        binaryData.append(UInt8(deviceNameData.count))
        binaryData.append(deviceNameData)
        
        // 訊息ID
        let messageIDData = message.id.data(using: .utf8) ?? Data()
        binaryData.append(UInt8(messageIDData.count))
        binaryData.append(messageIDData)
        
        // 訊息內容
        let messageData = message.message.data(using: .utf8) ?? Data()
        let messageLengthBytes = withUnsafeBytes(of: UInt16(messageData.count).littleEndian, Array.init)
        binaryData.append(contentsOf: messageLengthBytes)
        binaryData.append(messageData)
        
        return binaryData
    }
    
    /// 🔧 FIX: 解碼聊天訊息從二進制格式（統一標準格式）
    private func decodeChatMessage(_ data: Data) -> ChatMessage? {
        print("📝 ChatViewModel: 嘗試解碼聊天數據 - 大小: \(data.count) bytes")
        print("📝 數據前20字節: \(data.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // 🔧 FIX: 使用標準MeshMessage解碼器，期望二進制格式的ChatMessage
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            print("📝 解碼成功 - 訊息類型: \(meshMessage.type), 內容大小: \(meshMessage.data.count)")
            
            guard meshMessage.type == .chat else {
                print("❌ ChatViewModel: 不是聊天訊息類型，實際類型: \(meshMessage.type)")
                return nil
            }
            
            // 🔧 FIX: 解碼二進制ChatMessage數據
            let chatMessage = decodeChatMessageFromBinary(meshMessage.data)
            
            if let chatMessage = chatMessage {
                print("✅ ChatViewModel: 二進制格式聊天訊息解碼成功 - 訊息: \(chatMessage.message)")
                return chatMessage
            } else {
                print("❌ ChatViewModel: 二進制格式解碼失敗")
                return nil
            }
            
        } catch {
            print("❌ ChatViewModel: 標準格式解碼失敗: \(error)")
            
            // 🔧 FIX: 回退到舊格式解碼（向後兼容）
            print("🔄 ChatViewModel: 嘗試舊格式解碼...")
            let result = tryDecodeDirectChatMessage(data)
            if result == nil {
                print("❌ ChatViewModel: 舊格式解碼也失敗")
            } else {
                print("✅ ChatViewModel: 舊格式解碼成功")
            }
            return result
        }
    }
    
    /// 🔧 FIX: 解碼二進制ChatMessage數據（與encoder匹配）
    private func decodeChatMessageFromBinary(_ data: Data) -> ChatMessage? {
        guard data.count >= 8 else { 
            print("❌ ChatViewModel: 二進制數據太小: \(data.count) bytes")
            return nil 
        }
        
        var offset = 0
        
        // 時間戳 (4 bytes)
        guard offset + 4 <= data.count else { return nil }
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = TimeInterval(ts)
        offset += 4
        
        // 設備名稱長度 + 設備名稱
        guard offset < data.count else { return nil }
        let deviceNameLength = Int(data[offset])
        offset += 1
        
        guard offset + deviceNameLength <= data.count else { return nil }
        let deviceNameData = data.subdata(in: offset..<offset+deviceNameLength)
        let deviceName = String(data: deviceNameData, encoding: .utf8) ?? ""
        offset += deviceNameLength
        
        // 訊息ID長度 + 訊息ID
        guard offset < data.count else { return nil }
        let messageIDLength = Int(data[offset])
        offset += 1
        
        guard offset + messageIDLength <= data.count else { return nil }
        let messageIDData = data.subdata(in: offset..<offset+messageIDLength)
        let messageID = String(data: messageIDData, encoding: .utf8) ?? ""
        offset += messageIDLength
        
        // 訊息長度 (2 bytes) + 訊息內容
        guard offset + 2 <= data.count else { return nil }
        let messageLengthData = data.subdata(in: offset..<offset+2)
        let messageLength = messageLengthData.withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(messageLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<offset+Int(messageLength))
        let message = String(data: messageData, encoding: .utf8) ?? ""
        
        return ChatMessage(
            id: messageID,
            message: message,
            deviceName: deviceName,
            timestamp: timestamp,
            isOwn: false,
            isEncrypted: true,
            mentions: ChatMessage.extractMentions(from: message),
            mentionsMe: false
        )
    }
    
    /// 嘗試直接解碼聊天訊息內容
    private func tryDecodeDirectChatMessage(_ data: Data) -> ChatMessage? {
        guard data.count >= 10 else { 
            print("❌ ChatViewModel: 數據太小: \(data.count) bytes")
            return nil 
        }
        
        var offset = 0
        
        // 跳過協議版本 (1 byte)
        offset += 1
        
        // 跳過訊息類型 (1 byte)
        offset += 1
        
        // 時間戳 (4 bytes)
        guard offset + 4 <= data.count else { return nil }
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = TimeInterval(ts)
        offset += 4
        
        // 設備名稱長度 + 設備名稱
        guard offset < data.count else { return nil }
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 消息ID長度 + 消息ID
        guard offset < data.count else { return nil }
        let idLength = Int(data[offset])
        offset += 1
        
        guard offset + idLength <= data.count else { return nil }
        let messageId = String(data: data.subdata(in: offset..<offset+idLength), encoding: .utf8) ?? UUID().uuidString
        offset += idLength
        
        // 訊息長度 (2 bytes) + 訊息內容
        guard offset + 2 <= data.count else { return nil }
        let messageLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        guard offset + Int(messageLength) <= data.count else { return nil }
        let message = String(data: data.subdata(in: offset..<offset+Int(messageLength)), encoding: .utf8) ?? ""
        offset += Int(messageLength)
        
        // 解碼 @提及列表（如果有）
        var mentions: [String] = []
        var mentionsMe = false
        
        if offset + 2 <= data.count {
            let mentionsLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
                $0.load(as: UInt16.self).littleEndian
            }
            offset += 2
            
            if offset + Int(mentionsLength) <= data.count {
                let mentionsData = data.subdata(in: offset..<offset+Int(mentionsLength))
                if let decodedMentions = try? JSONDecoder().decode([String].self, from: mentionsData) {
                    mentions = decodedMentions
                }
                offset += Int(mentionsLength)
                
                // 解碼 mentionsMe 標誌（如果有）
                if offset < data.count {
                    mentionsMe = data[offset] == 1
                }
            }
        }
        
        // 如果沒有解碼到 @提及資料，從訊息內容中解析
        if mentions.isEmpty {
            mentions = ChatMessage.extractMentions(from: message)
        }
        
        // 檢查是否提及了我
        let myNickname = ServiceContainer.shared.nicknameService.userNickname
        if !mentionsMe {
            mentionsMe = ChatMessage.checkMentionsUser(myNickname, in: message)
        }
        
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
            id: messageId,
            message: message,
            deviceName: finalDeviceName,
            timestamp: timestamp,
            isOwn: false,
            isEncrypted: true,
            mentions: mentions,
            mentionsMe: mentionsMe
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
        
        // 🔧 記錄發送者的暱稱映射
        if let sourceID = meshMessage.sourceID, !chatMessage.deviceName.contains("-") {
            peerNicknameCache[sourceID] = chatMessage.deviceName
        }
        
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
        messages.append(message)  // 新訊息添加到末尾
        
        // 限制訊息數量
        if messages.count > 100 {
            let removedMessage = messages.removeFirst()  // 移除最舊的訊息（列表開頭）
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
        
        // 更新裝置名稱（統一使用 NicknameService）
        deviceName = ServiceContainer.shared.nicknameService.userNickname
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
    
    /// 取得訊息限制狀態文字
    func getMessageLimitStatus() -> String {
        if purchaseService.isPremiumUser {
            return "✅ Premium 用戶 - 無限聊天"
        } else {
            return "📊 今日剩餘: \(remainingMessages)/\(dailyLimit) 則免費訊息"
        }
    }
    
    /// 關閉升級提示
    func dismissUpgradePrompt() {
        showUpgradePrompt = false
    }
    
    /// 手動觸發升級提示（供 UI 調用）
    func triggerUpgradePrompt() {
        showUpgradePrompt = true
    }
    
    /// 取得可用於 @提及的使用者列表
    func getAvailableUsers() -> [String] {
        var users: [String] = []
        
        // 獲取本機的網路 ID 和暱稱，用於過濾
        let _ = ServiceContainer.shared.networkService.myPeerID.displayName
        let _ = ServiceContainer.shared.nicknameService.userNickname
        
        // 🔧 緩存機制：減少重複計算和日誌輸出
        let cacheKey = "\(messages.count)-\(connectedPeers.count)"
        if let cached = availableUsersCache[cacheKey] {
            return cached
        }
        
        // 🔧 只在狀態變化時輸出日誌
        if lastConnectedPeersState != connectedPeers {
            print("💬 ChatViewModel: 連接狀態變化 - 設備數: \(connectedPeers.count)")
            lastConnectedPeersState = connectedPeers
        }
        
        // 從聊天記錄中提取用戶（排除自己）
        let recentUsers = messages.compactMap { message in
            if !message.isOwn {
                return NicknameFormatter.cleanNickname(message.deviceName)
            }
            return nil
        }
        
        // 去重並排序
        users.append(contentsOf: recentUsers)
        let uniqueUsers = Array(Set(users)).sorted()
        
        // 🔧 緩存結果
        availableUsersCache[cacheKey] = uniqueUsers
        
        // 🔧 清理過期緩存
        cleanupAvailableUsersCache()
        
        return uniqueUsers
    }
    
    /// 清理過期的用戶緩存
    private func cleanupAvailableUsersCache() {
        if availableUsersCache.count > 10 {
            availableUsersCache.removeAll()
        }
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
        
        // 創建新的聊天訊息（確保標記為非本人，保留 @提及資料）
        let receivedMessage = ChatMessage(
            id: chatMessage.id,
            message: chatMessage.message,
            deviceName: chatMessage.deviceName,
            timestamp: chatMessage.timestamp,
            isOwn: false,  // 強制標記為非本人
            isEncrypted: chatMessage.isEncrypted,
            mentions: chatMessage.mentions,
            mentionsMe: chatMessage.mentionsMe
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
            
            // 檢查是否提及了我，如果是則發送通知
            if chatMessage.mentionsMe {
                sendMentionNotification(chatMessage)
            }
            
            print("💬 ChatViewModel: 接收到加密訊息: \(chatMessage.message) 來自: \(chatMessage.deviceName)")
        }
    }
    
    /// 發送被提及的通知
    private func sendMentionNotification(_ message: ChatMessage) {
        let cleanSenderName = NicknameFormatter.cleanNickname(message.deviceName)
        let notificationTitle = "有人提及了您"
        let notificationBody = "\(cleanSenderName): \(message.message)"
        
        // 發送本地通知
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = notificationBody
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // 設定通知標識符
        let identifier = "mention_notification_\(message.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ ChatViewModel: 無法發送提及通知: \(error)")
            } else {
                print("✅ ChatViewModel: 已發送提及通知給使用者")
            }
        }
        
        // 發送應用內通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("MentionReceived"),
                object: nil,
                userInfo: [
                    "message": message,
                    "sender": cleanSenderName
                ]
            )
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
    
    /// 設備ID到暱稱的映射緩存
    private var peerNicknameCache: [String: String] = [:]
    
    /// 獲取友好的設備名稱（優先顯示暱稱）
    private func getFriendlyDeviceName(_ peerID: String) -> String {
        // 🔧 修復：使用緩存的暱稱映射
        if let cachedNickname = peerNicknameCache[peerID] {
            return cachedNickname
        }
        
        // 🔧 從最近的聊天記錄中查找該設備的暱稱
        // 查找來自該peerID的訊息，獲取其暱稱
        if let recentMessage = messages.reversed().first(where: { message in
            !message.isOwn && 
            message.deviceName != "系統" && 
            !message.deviceName.contains("-") &&
            message.deviceName.count < 20  // 排除技術性ID
        }) {
            // 緩存找到的暱稱
            peerNicknameCache[peerID] = recentMessage.deviceName
            return recentMessage.deviceName
        }
        
        // 🔧 如果是技術ID，返回設備顯示名稱（通常是用戶設定的暱稱）
        // MultipeerConnectivity中的displayName通常就是用戶暱稱
        if peerID.contains("-") && peerID.count > 15 {
            // 使用peerID作為displayName，這通常包含了用戶暱稱
            let components = peerID.components(separatedBy: "-")
            if let displayName = components.first, !displayName.isEmpty {
                peerNicknameCache[peerID] = displayName
                return displayName
            }
        }
        
        return peerID
    }
    
    /// 清理舊訊息（保留供手動調用）
    private func cleanupOldMessages() {
        // 此方法現在主要由午夜清理使用
        // 保留此方法以供未來可能的手動清理需求
    }
    
    // MARK: - 每日訊息限制功能
    
    /// 設置每日限制相關功能
    private func setupDailyLimit() {
        loadDailyMessageCount()
        resetDailyCountIfNeeded()
        updateRemainingMessages()
        print("📊 ChatViewModel: 每日限制設置完成 - 當前計數: \(dailyMessageCount)/\(dailyLimit)")
    }
    
    /// 載入本機離線儲存的每日訊息計數（無網路依賴）
    private func loadDailyMessageCount() {
        dailyMessageCount = UserDefaults.standard.integer(forKey: dailyCountKey)
        if let savedDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            lastResetDate = savedDate
        }
        print("📱 ChatViewModel: 從本機載入計數 - \(dailyMessageCount)/\(dailyLimit)")
    }
    
    /// 儲存每日訊息計數到本機（離線優先）
    private func saveDailyMessageCount() {
        UserDefaults.standard.set(dailyMessageCount, forKey: dailyCountKey)
        UserDefaults.standard.set(lastResetDate, forKey: lastResetDateKey)
        UserDefaults.standard.synchronize() // 強制同步到磁碟
        print("💾 ChatViewModel: 本機儲存計數 - \(dailyMessageCount)/\(dailyLimit)")
    }
    
    /// 檢查並重置每日計數（基於本機時間，離線可用）
    private func resetDailyCountIfNeeded() {
        let calendar = Calendar.current
        let now = Date() // 使用設備本機時間，無需網路同步
        
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            // 新的一天，重置計數（本機計算）
            dailyMessageCount = 0
            lastResetDate = now
            isLimitReached = false
            showUpgradePrompt = false
            saveDailyMessageCount()
            updateRemainingMessages()
            print("🆕 ChatViewModel: 本機偵測新的一天，重置訊息計數（離線模式）")
        }
    }
    
    /// 更新剩餘訊息數量
    private func updateRemainingMessages() {
        if purchaseService.isPremiumUser {
            remainingMessages = -1 // 無限制
            isLimitReached = false
        } else {
            remainingMessages = max(0, dailyLimit - dailyMessageCount)
            isLimitReached = dailyMessageCount >= dailyLimit
        }
    }
    
    /// 檢查是否可以發送訊息
    private func canSendMessage() -> Bool {
        resetDailyCountIfNeeded()
        return purchaseService.isPremiumUser || dailyMessageCount < dailyLimit
    }
    
    /// 記錄訊息發送並更新計數
    private func recordMessageSent() {
        if !purchaseService.isPremiumUser {
            dailyMessageCount += 1
            saveDailyMessageCount()
            updateRemainingMessages()
            
            // 接近限制時顯示警告
            if dailyMessageCount >= dailyLimit - 5 && dailyMessageCount < dailyLimit {
                addSystemMessage("⚠️ 您今天還剩 \(remainingMessages) 則免費訊息")
            }
            
            // 達到限制時觸發升級提示
            if isLimitReached {
                showUpgradePrompt = true
                addSystemMessage("🚫 今日免費訊息已用完，升級享受無限聊天！")
            }
        }
    }
}

// MARK: - 預覽支援

extension ChatViewModel {
    /// 創建預覽用的範例資料
    static func preview() -> ChatViewModel {
        let viewModel = ChatViewModel()
        
        // 添加一些範例訊息（按時間順序排列，最舊的在前）
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
 6. ConnectionRateManager - 連線速率管理
 7. SettingsViewModel 整合 - 使用者暱稱管理
 */

// MARK: - 擴展

extension UInt16 {
    var littleEndianBytes: [UInt8] {
        let value = self.littleEndian
        return withUnsafeBytes(of: value) { Array($0) }
    }
}
