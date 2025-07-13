import Foundation
import SwiftUI
import Combine

// 所有型別定義已移至 SharedTypes.swift

/// 賓果遊戲網絡管理器 - 負責所有網絡相關功能
@MainActor
class BingoNetworkManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 連接狀態
    @Published var connectionStatus: String = "離線"
    
    /// 網絡是否活躍
    @Published var isNetworkActive: Bool = false
    
    /// 同步狀態
    @Published var syncStatus: String = ""
    
    // MARK: - Dependencies
    
    private let meshManager: MeshManagerProtocol
    private let timerManager: TimerManager
    private let settingsViewModel: SettingsViewModel
    private let languageService: LanguageService
    
    // MARK: - Private Properties
    
    private var heartbeatTimer: Timer?
    private var connectionRetryCount = 0
    private let maxConnectionRetries = 3
    
    // MARK: - Initialization
    
    init(
        meshManager: MeshManagerProtocol,
        timerManager: TimerManager,
        settingsViewModel: SettingsViewModel,
        languageService: LanguageService
    ) {
        print("🌐 BingoNetworkManager: 開始初始化")
        
        self.meshManager = meshManager
        self.timerManager = timerManager
        self.settingsViewModel = settingsViewModel
        self.languageService = languageService
        
        // 【FIX】延遲執行需要 MainActor 的初始化
        Task { @MainActor in
            await self.performDelayedInitialization()
        }
    }
    
    /// 【NEW】延遲初始化方法，避免阻塞主初始化
    private func performDelayedInitialization() async {
        print("🌐 BingoNetworkManager: 執行延遲初始化")
        
        // 更新初始狀態
        connectionStatus = languageService.localizedString(forKey: "離線")
        
        print("🌐 BingoNetworkManager: 延遲初始化完成")
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
        
        do {
            try await meshManager.startNetworking()
            
            await MainActor.run {
                connectionStatus = languageService.localizedString(forKey: "連接中")
                isNetworkActive = true
            }
            
            // 驗證廣播通道狀態
            try validateBroadcastChannelState()
            
            // 開始心跳檢測
            startHeartbeatMonitoring()
            
            print("🌐 BingoNetworkManager: 網絡設置完成")
            
        } catch {
            print("❌ BingoNetworkManager: 網絡設置失敗 - \(error)")
            await handleNetworkError(error)
        }
    }
    
    /// 為主機設置網絡（快速模式）
    func setupMeshNetworkingForHost() async {
        print("🌐 BingoNetworkManager: 主機快速網絡設置")
        
        do {
            // 主機模式：跳過某些檢查，直接建立網絡
            try await meshManager.startHostMode()
            
            await MainActor.run {
                connectionStatus = "主機模式就緒"
                isNetworkActive = true
            }
            
            startHeartbeatMonitoring()
            
            print("🌐 BingoNetworkManager: 主機網絡設置完成")
            
        } catch {
            print("❌ BingoNetworkManager: 主機網絡設置失敗 - \(error)")
            await handleNetworkError(error)
        }
    }
    
    // MARK: - Network Validation
    
    /// 驗證廣播通道狀態
    private func validateBroadcastChannelState() throws {
        print("🔍 BingoNetworkManager: 驗證廣播通道狀態")
        
        guard meshManager.isNetworkReady() else {
            print("⚠️ BingoNetworkManager: 網絡未就緒，跳過驗證")
            return
        }
        
        // 【CRITICAL FIX】檢查通道可用性 - 使用現有方法
        let connectedPeers = meshManager.getConnectedPeers()
        if connectedPeers.isEmpty {
            throw NetworkError.broadcastChannelUnavailable
        }
        
        print("✅ BingoNetworkManager: 廣播通道驗證通過 (已連接 \(connectedPeers.count) 個設備)")
    }
    
    // MARK: - Message Broadcasting
    
    /// 廣播遊戲消息
    func broadcastGameMessage(_ type: GameMessageType, data: Data, gameRoomID: String = "", deviceName: String = "") {
        print("📡 BingoNetworkManager: 廣播遊戲消息 - \(type)")
        
        guard isNetworkActive else {
            print("⚠️ BingoNetworkManager: 網絡未活躍，無法廣播")
            return
        }
        
        Task {
            await broadcastGameMessageWithRetry(type, data: data, gameRoomID: gameRoomID, deviceName: deviceName, maxRetries: 3)
        }
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
        
        // 添加遊戲訊息類型
        let typeData = type.rawValue.data(using: .utf8) ?? Data()
        let safeTypeLength = min(typeData.count, 255)
        gameData.append(UInt8(safeTypeLength))
        gameData.append(typeData.prefix(safeTypeLength))
        
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
    func broadcastHeartbeat(data: Data) async {
        do {
            try await meshManager.broadcastMessage(data: data, type: "heartbeat")
            print("💓 BingoNetworkManager: 心跳廣播成功")
        } catch {
            print("❌ BingoNetworkManager: 心跳廣播失敗 - \(error)")
        }
    }
    
    // MARK: - Connection Management
    
    /// 開始心跳監控
    private func startHeartbeatMonitoring() {
        print("💓 BingoNetworkManager: 開始心跳監控")
        
        timerManager.scheduleRepeating(
            id: TimerManager.TimerID.heartbeat,
            interval: 5.0
        ) { [weak self] in
            Task { [weak self] in
                await self?.sendHeartbeat()
            }
        }
    }
    
    /// 發送心跳
    private func sendHeartbeat() async {
        let heartbeatData = "heartbeat".data(using: .utf8) ?? Data()
        await broadcastHeartbeat(data: heartbeatData)
    }
    
    /// 停止心跳監控
    private func stopHeartbeatMonitoring() {
        timerManager.cancelTimer(id: TimerManager.TimerID.heartbeat)
        print("💓 BingoNetworkManager: 心跳監控已停止")
    }
    
    /// 重新連接網絡
    func reconnectNetwork() async {
        print("🔄 BingoNetworkManager: 開始重新連接")
        
        guard connectionRetryCount < maxConnectionRetries else {
            print("❌ BingoNetworkManager: 重連次數超出限制")
            await updateConnectionStatus("連接失敗")
            return
        }
        
        connectionRetryCount += 1
        await updateConnectionStatus("重新連接中...")
        
        // 停止當前連接
        await stopNetworking()
        
        // 等待一段時間後重試
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 重新設置網絡
        await setupMeshNetworkingAsync()
    }
    
    /// 停止網絡
    func stopNetworking() async {
        print("🛑 BingoNetworkManager: 停止網絡服務")
        
        stopHeartbeatMonitoring()
        
        await meshManager.stopNetworking()
        
        await MainActor.run {
            isNetworkActive = false
            connectionStatus = "已斷線"
        }
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
        
        await updateConnectionStatus("連接錯誤")
        
        // 自動重試邏輯
        if connectionRetryCount < maxConnectionRetries {
            await reconnectNetwork()
        } else {
            await updateConnectionStatus("連接失敗")
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
    
    // MARK: - Lifecycle
    
    /// 清理網絡資源
    func cleanup() {
        print("🧹 BingoNetworkManager: 清理網絡資源")
        
        Task {
            await stopNetworking()
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