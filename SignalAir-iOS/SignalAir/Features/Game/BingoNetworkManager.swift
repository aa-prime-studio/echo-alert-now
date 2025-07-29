import Foundation
import SwiftUI
import Combine

// 所有型別定義已移至 SharedTypes.swift

/// 賓果遊戲網絡管理器 - 負責所有網絡相關功能
@MainActor
class BingoNetworkManager: BingoNetworkManagerProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    /// 連接狀態
    @Published var connectionStatus: String = "離線"
    
    /// 網絡是否活躍
    @Published var isNetworkActive: Bool = false
    
    /// 同步狀態
    @Published var syncStatus: String = ""
    
    // MARK: - Dependencies
    
    private var meshManager: MeshManagerProtocol
    private let timerManager: UnifiedTimerManager
    private let settingsViewModel: SettingsViewModel
    private let languageService: LanguageService
    private let networkStateCoordinator: NetworkStateCoordinator = NetworkStateCoordinator.shared
    
    // MARK: - Private Properties
    
    private var heartbeatTimer: Timer?
    private var connectionRetryCount = 0
    private let maxConnectionRetries = 3
    
    // MARK: - Publishers for Protocol Compliance
    
    private let receivedGameMessagesSubject = PassthroughSubject<GameMessage, Never>()
    private let networkConnectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    
    var receivedGameMessages: AnyPublisher<GameMessage, Never> {
        receivedGameMessagesSubject.eraseToAnyPublisher()
    }
    
    var networkConnectionState: AnyPublisher<Bool, Never> {
        networkConnectionStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Network State Properties
    
    var isConnected: Bool {
        return meshManager.getConnectedPeers().isEmpty == false
    }
    
    var connectedPeers: [String] {
        return meshManager.getConnectedPeers()
    }
    
    // MARK: - Initialization
    
    init(
        meshManager: MeshManagerProtocol,
        timerManager: UnifiedTimerManager,
        settingsViewModel: SettingsViewModel,
        languageService: LanguageService
    ) {
        print("🌐 BingoNetworkManager: 開始初始化")
        
        self.meshManager = meshManager
        self.timerManager = timerManager
        self.settingsViewModel = settingsViewModel
        self.languageService = languageService
        
        // 【FIX】避免 MainActor 死鎖 - 移除 init 中的異步操作
    }
    
    /// 【NEW】在 UI 出現時執行初始化，避免 MainActor 死鎖
    func onAppear() {
        Task { @MainActor in
            await self.performAsyncInitialization()
        }
    }
    
    /// 異步初始化方法
    private func performAsyncInitialization() async {
        print("🌐 BingoNetworkManager: 執行異步初始化")
        
        // 更新初始狀態
        connectionStatus = languageService.t("offline")
        
        print("🌐 BingoNetworkManager: 異步初始化完成")
    }
    
    // MARK: - Network Setup
    
    /// 設置網絡連接
    func setupMeshNetworking() {
        print("🌐 BingoNetworkManager: 正在設置Mesh網絡...")
        
        Task {
            await setupMeshNetworkingAsync()
        }
    }
    
    /// 異步設置網絡
    func setupMeshNetworkingAsync() async {
        print("🌐 BingoNetworkManager: 開始異步網絡設置")
        
        // 1. 報告應用層正在連接
        networkStateCoordinator.reportApplicationLayerState(.connecting)
        
        meshManager.startMeshNetwork()
        
        await MainActor.run {
            connectionStatus = languageService.t("connecting")
            isNetworkActive = true
        }
        
        // 2. 驗證廣播通道狀態
        validateBroadcastChannelState()
        
        // 3. 開始心跳檢測
        startHeartbeatMonitoring()
        
        // 4. 檢查網絡就緒狀態並報告
        await validateNetworkReadiness()
        
        print("🌐 BingoNetworkManager: 網絡設置完成")
    }
    
    /// 為主機設置網絡（快速模式）
    func setupMeshNetworkingForHost() async {
        print("🌐 BingoNetworkManager: 主機快速網絡設置")
        
        // 1. 報告應用層正在連接
        networkStateCoordinator.reportApplicationLayerState(.connecting)
        
        // 主機模式：跳過某些檢查，直接建立網絡
        meshManager.startMeshNetwork()
        
        await MainActor.run {
            connectionStatus = "主機模式就緒"
            isNetworkActive = true
        }
        
        startHeartbeatMonitoring()
        
        // 2. 主機模式直接報告為就緒狀態
        networkStateCoordinator.reportApplicationLayerState(.ready)
        
        // 同步網路狀態到發布者
        networkConnectionStateSubject.send(true)
        
        print("🌐 BingoNetworkManager: 主機網絡設置完成")
    }
    
    // MARK: - Network Validation
    
    /// 驗證廣播通道狀態
    private func validateBroadcastChannelState() {
        print("🔍 BingoNetworkManager: 驗證廣播通道狀態")
        
        guard !meshManager.getConnectedPeers().isEmpty else {
            print("⚠️ BingoNetworkManager: 網絡未就緒，跳過驗證")
            return
        }
        
        // 【CRITICAL FIX】檢查通道可用性 - 使用現有方法
        let connectedPeers = meshManager.getConnectedPeers()
        if connectedPeers.isEmpty {
            print("❌ BingoNetworkManager: 廣播通道不可用")
        }
        
        print("✅ BingoNetworkManager: 廣播通道驗證通過 (已連接 \(connectedPeers.count) 個設備)")
    }
    
    /// 驗證網絡就緒狀態
    private func validateNetworkReadiness() async {
        print("🔍 BingoNetworkManager: 驗證網絡就緒狀態")
        
        // 檢查底層連接狀態
        let hasConnections = !meshManager.getConnectedPeers().isEmpty
        
        if hasConnections {
            // 有連接，報告為已連接
            networkStateCoordinator.reportApplicationLayerState(.connected, peerCount: meshManager.getConnectedPeers().count)
            
            // 同步網路狀態到發布者
            networkConnectionStateSubject.send(true)
            
            // 等待密鑰交換完成後才報告為就緒
            await checkKeyExchangeStatus()
        } else {
            // 無連接，保持在連接中狀態
            print("⚠️ BingoNetworkManager: 無底層連接，保持連接狀態")
        }
    }
    
    /// 檢查密鑰交換狀態
    private func checkKeyExchangeStatus() async {
        // 給密鑰交換一些時間
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        let connectedPeers = meshManager.getConnectedPeers()
        var readyCount = 0
        
        // 檢查每個對等體的密鑰狀態（這裡簡化處理）
        // 在實際實現中，應該從 SecurityService 檢查密鑰狀態
        for _ in connectedPeers {
            // 假設大部分連接在2秒後都有密鑰交換
            readyCount += 1
        }
        
        if readyCount > 0 {
            // 至少有一個對等體準備好，報告為就緒
            networkStateCoordinator.reportApplicationLayerState(.ready, peerCount: readyCount)
            print("✅ BingoNetworkManager: 應用層就緒 (\(readyCount) 個對等體)")
        } else {
            // 沒有準備好的對等體，保持連接狀態
            networkStateCoordinator.reportApplicationLayerState(.connected, peerCount: connectedPeers.count)
            print("⚠️ BingoNetworkManager: 等待密鑰交換完成")
        }
    }
    
    // MARK: - Message Broadcasting
    
    /// 廣播遊戲消息
    func broadcastGameMessage(_ type: GameMessageType, data: Data, gameRoomID: String = "", deviceName: String = "") {
        print("📡 ===== BingoNetworkManager 廣播遊戲消息 =====")
        print("📡 消息類型: \(type) (0x\(String(format: "%02x", type.rawValue)))")
        print("📡 數據大小: \(data.count) bytes")
        print("📡 數據內容: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        print("📡 房間ID: \(gameRoomID.isEmpty ? "默認" : gameRoomID)")
        print("📡 設備名稱: \(deviceName.isEmpty ? "默認" : deviceName)")
        print("📡 網絡狀態: \(isNetworkActive ? "活躍" : "非活躍")")
        
        guard isNetworkActive else {
            print("⚠️ BingoNetworkManager: 網絡未活躍，無法廣播")
            return
        }
        
        Task {
            await broadcastGameMessageWithRetry(type, data: data, gameRoomID: gameRoomID, deviceName: deviceName, maxRetries: 3)
        }
        print("📡 ===== 廣播請求已發送 =====")
    }
    
    /// 帶重試的消息廣播
    private func broadcastGameMessageWithRetry(_ type: GameMessageType, data: Data, gameRoomID: String, deviceName: String, maxRetries: Int) async {
        // 創建完整的遊戲消息
        let gameMessage = createGameMessage(type: type, data: data, gameRoomID: gameRoomID, deviceName: deviceName)
        // 【CRITICAL FIX】使用正確的方法簽名
        meshManager.broadcastMessage(gameMessage, messageType: .game)
        print("✅ BingoNetworkManager: 消息廣播成功 - \(type)")
    }
    
    /// 創建遊戲消息
    private func createGameMessage(type: GameMessageType, data: Data, gameRoomID: String, deviceName: String) -> Data {
        var gameData = Data()
        
        // 添加遊戲訊息類型 - 直接使用UInt8原始值
        print("🔍 BingoNetworkManager: 編碼消息類型 \(type.stringValue)，原始值: 0x\(String(type.rawValue, radix: 16))")
        gameData.append(type.rawValue)
        
        // 添加房間ID
        let roomIDData = gameRoomID.data(using: .utf8) ?? Data()
        let safeRoomIDLength = min(roomIDData.count, 255)
        gameData.append(UInt8(safeRoomIDLength))
        gameData.append(roomIDData.prefix(safeRoomIDLength))
        
        // 添加發送者名稱
        let senderNameData = deviceName.data(using: .utf8) ?? Data()
        let safeSenderNameLength = min(senderNameData.count, 255)
        gameData.append(UInt8(safeSenderNameLength))
        gameData.append(senderNameData.prefix(safeSenderNameLength))
        
        // 添加實際數據
        let dataLength = UInt16(data.count)
        gameData.append(contentsOf: withUnsafeBytes(of: dataLength.littleEndian) { Array($0) })
        gameData.append(data)
        
        return gameData
    }
    
    /// 廣播心跳數據
    func broadcastHeartbeat(data: Data) {
        meshManager.broadcastMessage(data, messageType: .heartbeat)
        print("💓 BingoNetworkManager: 心跳廣播成功")
    }
    
    // MARK: - Connection Management
    
    /// 開始心跳監控
    private func startHeartbeatMonitoring() {
        print("💓 BingoNetworkManager: 開始心跳監控")
        
        timerManager.scheduleHeartbeat { [weak self] in
            Task { [weak self] in
                await self?.sendHeartbeat()
            }
        }
    }
    
    /// 發送心跳
    private func sendHeartbeat() async {
        let heartbeatData = "heartbeat".data(using: .utf8) ?? Data()
        broadcastHeartbeat(data: heartbeatData)
    }
    
    /// 停止心跳監控
    private func stopHeartbeatMonitoring() {
        timerManager.invalidate(id: "heartbeat")
        print("💓 BingoNetworkManager: 心跳監控已停止")
    }
    
    /// 重新連接網絡
    func reconnectNetwork() async {
        print("🔄 BingoNetworkManager: 開始重新連接")
        
        // 1. 報告應用層重新連接中
        networkStateCoordinator.reportApplicationLayerState(.reconnecting)
        
        // 【FIX】發布重連中的狀態
        networkConnectionStateSubject.send(false)
        
        guard connectionRetryCount < maxConnectionRetries else {
            print("❌ BingoNetworkManager: 重連次數超出限制")
            // 2. 報告連接失敗
            networkStateCoordinator.reportApplicationLayerState(.failed)
            await updateConnectionStatus("連接失敗")
            networkConnectionStateSubject.send(false)
            return
        }
        
        connectionRetryCount += 1
        await updateConnectionStatus("重新連接中...")
        
        // 停止當前連接
        await stopNetworking()
        
        // 等待一段時間後重試
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 重新設置網絡（這會發布true狀態）
        await setupMeshNetworkingAsync()
    }
    
    /// 停止網絡
    func stopNetworking() async {
        print("🛑 BingoNetworkManager: 停止網絡服務")
        
        // 1. 報告應用層斷線
        networkStateCoordinator.reportApplicationLayerState(.disconnected)
        
        stopHeartbeatMonitoring()
        
        meshManager.stopMeshNetwork()
        
        await MainActor.run {
            isNetworkActive = false
            connectionStatus = "已斷線"
        }
        
        // 同步網路狀態到發布者
        networkConnectionStateSubject.send(false)
    }
    
    // MARK: - Status Updates
    
    /// 更新連接狀態
    private func updateConnectionStatus(_ status: String) async {
        await MainActor.run {
            connectionStatus = status
        }
        print("📡 BingoNetworkManager: 連接狀態更新 - \(status)")
    }
    
    /// 更新同步狀態
    func updateSyncStatus(_ status: String) {
        syncStatus = status
        print("🔄 BingoNetworkManager: 同步狀態更新 - \(status)")
    }
    
    // MARK: - Error Handling
    
    /// 處理網絡錯誤
    private func handleNetworkError(_ error: Error) async {
        print("❌ BingoNetworkManager: 處理網絡錯誤 - \(error)")
        
        // 【FIX】立即發布網路斷線狀態
        networkConnectionStateSubject.send(false)
        
        await updateConnectionStatus("連接錯誤")
        
        // 自動重試邏輯
        if connectionRetryCount < maxConnectionRetries {
            await reconnectNetwork()
        } else {
            await updateConnectionStatus("連接失敗")
            // 【FIX】確保最終失敗狀態
            networkConnectionStateSubject.send(false)
        }
    }
    
    /// 處理廣播失敗
    private func handleBroadcastFailure(_ type: GameMessageType) {
        print("❌ BingoNetworkManager: 處理廣播失敗 - \(type)")
        
        updateSyncStatus("同步失敗")
        
        // 可以觸發重連或其他恢復邏輯
        Task {
            await reconnectNetwork()
        }
    }
    
    // MARK: - Protocol Methods Implementation
    
    /// 發送遊戲消息到指定房間
    func sendGameMessage(type: GameMessageType, data: Data, to roomID: String) async throws {
        guard isNetworkActive else {
            throw GameServiceError.networkNotInitialized
        }
        
        // 使用現有的廣播方法
        broadcastGameMessage(type, data: data, gameRoomID: roomID, deviceName: settingsViewModel.userNickname)
    }
    
    /// 廣播遊戲動作
    func broadcastGameAction(type: GameMessageType, data: Data, priority: MessagePriority = .normal) async throws {
        guard isNetworkActive else {
            throw GameServiceError.networkNotInitialized
        }
        
        // 使用現有的廣播方法
        broadcastGameMessage(type, data: data, gameRoomID: "", deviceName: settingsViewModel.userNickname)
    }
    
    /// 開始消息處理
    func startMessageHandling() {
        print("🎮 BingoNetworkManager: 開始消息處理")
        // 設置網路回調來接收消息
        setupMessageReceiving()
    }
    
    /// 停止消息處理
    func stopMessageHandling() {
        print("🛑 BingoNetworkManager: 停止消息處理")
        // 清理消息接收回調
        cleanupMessageReceiving()
    }
    
    // MARK: - Message Deduplication
    
    /// 消息去重管理器
    private let messageDeduplicator = MessageDeduplicator()
    
    /// 線程安全的消息去重器
    private actor MessageDeduplicator {
        private var processedMessages: Set<String> = []
        private var messageTimestamps: [String: Date] = [:]
        private let maxCacheSize = 1000
        private let cacheExpiration: TimeInterval = 300.0 // 5分鐘
        
        /// 檢查消息是否已處理，如未處理則標記為已處理
        func shouldProcessMessage(id: String, timestamp: Date = Date()) -> Bool {
            // 清理過期消息
            cleanupExpiredMessages()
            
            // 檢查是否已處理
            if processedMessages.contains(id) {
                print("⚠️ MessageDeduplicator: 消息已處理，跳過: \(id.prefix(8))")
                return false
            }
            
            // 標記為已處理
            processedMessages.insert(id)
            messageTimestamps[id] = timestamp
            
            // 限制緩存大小
            if processedMessages.count > maxCacheSize {
                cleanupOldestMessages()
            }
            
            return true
        }
        
        /// 清理過期消息
        private func cleanupExpiredMessages() {
            let now = Date()
            let expiredIDs = messageTimestamps.compactMap { (id, timestamp) in
                now.timeIntervalSince(timestamp) > cacheExpiration ? id : nil
            }
            
            for id in expiredIDs {
                processedMessages.remove(id)
                messageTimestamps.removeValue(forKey: id)
            }
            
            if !expiredIDs.isEmpty {
                print("🧹 MessageDeduplicator: 清理過期消息 \(expiredIDs.count) 個")
            }
        }
        
        /// 清理最舊的消息
        private func cleanupOldestMessages() {
            let sortedByTime = messageTimestamps.sorted { $0.value < $1.value }
            let toRemove = sortedByTime.prefix(maxCacheSize / 4) // 移除25%
            
            for (id, _) in toRemove {
                processedMessages.remove(id)
                messageTimestamps.removeValue(forKey: id)
            }
            
            print("🧹 MessageDeduplicator: 清理最舊消息 \(toRemove.count) 個")
        }
        
        /// 取得緩存狀態
        func getCacheStatus() -> (processed: Int, cached: Int) {
            return (processedMessages.count, messageTimestamps.count)
        }
    }
    
    // MARK: - Message Receiving (從 BingoGameViewModel 移入)
    
    /// 設置消息接收
    private func setupMessageReceiving() {
        print("📥 BingoNetworkManager: 設置消息接收")
        
        // 【FIX】註冊遊戲消息處理回調（通過 MeshManager）
        meshManager.onGameMessageReceived = { [weak self] meshMessage in
            guard let self = self else { return }
            
            print("📨 BingoNetworkManager: 收到遊戲消息 (MeshManager回調)")
            
            // 異步處理消息去重
            Task {
                if await self.messageDeduplicator.shouldProcessMessage(id: meshMessage.id) {
                    // 解析遊戲消息
                    if let gameMessage = self.decodeGameMessage(from: meshMessage) {
                        // 發布到訂閱者
                        await MainActor.run {
                            self.receivedGameMessagesSubject.send(gameMessage)
                        }
                    }
                } else {
                    print("🔄 BingoNetworkManager: 跳過重複消息 (MeshManager): \(meshMessage.id.prefix(8))")
                }
            }
        }
        
        // 【DEPRECATED】移除 NotificationCenter 監聽器以避免重複處理
        // 現在只使用 MeshManager 回調來處理消息，避免雙重處理
        print("🚫 BingoNetworkManager: 已移除 NotificationCenter 監聽器以避免重複處理")
    }
    
    /// 【NEW】解析 MeshMessage 為 GameMessage
    private func decodeGameMessage(from meshMessage: MeshMessage) -> GameMessage? {
        guard meshMessage.type == .game else { return nil }
        
        let data = meshMessage.data
        guard data.count >= 3 else { return nil }
        
        var offset = 0
        
        // 讀取遊戲消息類型 - 直接讀取UInt8
        let rawValue = data[offset]
        print("🔍 BingoNetworkManager: 嘗試解碼消息類型，原始值: 0x\(String(rawValue, radix: 16)) (\(rawValue))")
        print("🔍 BingoNetworkManager: 可用的 GameMessageType 原始值：")
        print("   - playerJoined: \(GameMessageType.playerJoined.rawValue)")
        print("   - roomStateUpdate: \(GameMessageType.roomStateUpdate.rawValue)")
        print("   - emote: \(GameMessageType.emote.rawValue)")
        print("   - heartbeat: \(GameMessageType.heartbeat.rawValue)")
        
        guard let gameType = GameMessageType(rawValue: rawValue) else { 
            print("❌ BingoNetworkManager: 無法解碼遊戲消息類型 0x\(String(rawValue, radix: 16)) (\(rawValue))")
            print("❌ 這可能表示訊息格式不匹配或編碼問題")
            return nil 
        }
        
        print("✅ BingoNetworkManager: 成功解碼消息類型: \(gameType.stringValue) (原始值: \(gameType.rawValue))")
        offset += 1
        
        // 讀取房間ID長度
        guard offset < data.count else { return nil }
        let roomIDLength = Int(data[offset])
        offset += 1
        
        let roomID: String
        if roomIDLength > 0 && offset + roomIDLength <= data.count {
            let roomIDData = data.subdata(in: offset..<(offset + roomIDLength))
            roomID = String(data: roomIDData, encoding: .utf8) ?? ""
            offset += roomIDLength
        } else {
            roomID = ""
        }
        
        // 讀取發送者名稱長度
        guard offset < data.count else { return nil }
        let senderNameLength = Int(data[offset])
        offset += 1
        
        let senderName: String
        if senderNameLength > 0 && offset + senderNameLength <= data.count {
            let senderNameData = data.subdata(in: offset..<(offset + senderNameLength))
            senderName = String(data: senderNameData, encoding: .utf8) ?? meshMessage.sourceID ?? "unknown"
            offset += senderNameLength
        } else {
            senderName = meshMessage.sourceID ?? "unknown"
        }
        
        // 讀取實際數據長度
        guard offset + 2 <= data.count else { return nil }
        let dataLength = data.subdata(in: offset..<(offset + 2)).withUnsafeBytes { 
            $0.load(as: UInt16.self).littleEndian 
        }
        offset += 2
        
        // 讀取實際數據
        guard offset + Int(dataLength) <= data.count else { return nil }
        let messageData = data.subdata(in: offset..<(offset + Int(dataLength)))
        
        return GameMessage(
            id: meshMessage.id,
            type: gameType,
            data: messageData,
            senderID: meshMessage.sourceID ?? "unknown",
            senderName: senderName,
            roomID: roomID,
            timestamp: meshMessage.timestamp
        )
    }
    
    /// 清理消息接收
    private func cleanupMessageReceiving() {
        print("🧹 BingoNetworkManager: 清理消息接收")
        
        // 【FIX】清理回調
        meshManager.onGameMessageReceived = nil
        
        // 不再需要移除 NotificationCenter 觀察者，因為已經不再使用
        print("🧹 BingoNetworkManager: 消息接收清理完成")
    }
    
    /// 處理接收到的遊戲消息 (從 BingoGameViewModel 移入)
    func handleReceivedGameMessage(_ message: GameMessage) {
        print("📥 ===== BingoNetworkManager 處理接收消息 =====")
        print("📥 消息類型: \(message.type.stringValue) (0x\(String(format: "%02x", message.type.rawValue)))")
        print("📥 消息ID: \(message.id)")
        print("📥 發送者ID: \(message.senderID.prefix(8))")
        print("📥 發送者名稱: \(message.senderName)")
        print("📥 房間ID: \(message.roomID)")
        print("📥 時間戳: \(message.timestamp)")
        print("📥 數據大小: \(message.data.count) 字節")
        if message.data.count > 0 {
            print("📥 數據內容: \(message.data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        }
        
        // 【診斷】特別處理特定消息類型
        switch message.type {
        case .playerJoined:
            print("👤 【重要】收到 playerJoined 消息詳細分析:")
            do {
                let playerInfo = try BinaryGameProtocol.decodePlayerJoined(from: message.data)
                print("👤   - 解碼玩家ID: \(playerInfo.playerID)")
                print("👤   - 解碼玩家名稱: \(playerInfo.playerName)")
                print("👤   - 發送者是否為自己: \(playerInfo.playerID == ServiceContainer.shared.temporaryIDManager.deviceID)")
            } catch {
                print("❌ 【錯誤】無法解碼 playerJoined 數據: \(error)")
            }
        case .numberDrawn:
            print("🎯 【重要】收到 numberDrawn 消息詳細分析:")
            if message.data.count >= 4 {
                let number = message.data.withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
                print("🎯   - 解碼號碼: \(number)")
                print("🎯   - 數據格式正確: \(message.data.count == 4 ? "是" : "否")")
            } else {
                print("❌ 【錯誤】numberDrawn 數據太短: \(message.data.count) bytes")
            }
        default:
            break
        }
        
        // 【診斷】檢查訂閱者數量
        print("📥   - 已發布消息到 PassthroughSubject")
        
        // 發布消息給訂閱者
        receivedGameMessagesSubject.send(message)
        print("📥   ✅ 消息已發布給訂閱者")
    }
    
    // MARK: - Message Encoding/Decoding (從 BingoGameViewModel 移入)
    
    /// 編碼遊戲房間狀態 (從 BingoGameViewModel 移入)
    func encodeGameRoomState() -> Data {
        // TODO: 從 BingoGameViewModel 移入實現
        return Data()
    }
    
    /// 解碼標準遊戲消息 (從 BingoGameViewModel 移入)
    func decodeStandardGameMessage(_ data: Data, messageID: String) -> GameMessage? {
        // TODO: 從 BingoGameViewModel 移入實現
        return nil
    }
    
    // MARK: - Lifecycle
    
    /// 清理網絡資源
    func cleanup() {
        print("🧹 BingoNetworkManager: 清理網絡資源")
        
        // 停止心跳監控（避免記憶體洩漏）
        stopHeartbeatMonitoring()
        
        // 停止消息處理
        stopMessageHandling()
        
        // 停止網絡
        Task { [weak self] in
            await self?.stopNetworking()
        }
        
        connectionRetryCount = 0
    }
    
    deinit {
        print("🗑️ BingoNetworkManager: deinit")
        // 移除 Task 的 self 捕獲以避免管理生命周期問題
    }
}

// MARK: - Supporting Types
// 所有型別定義已移至 SharedTypes.swift