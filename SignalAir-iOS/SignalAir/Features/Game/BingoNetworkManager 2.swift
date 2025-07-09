import Foundation
import SwiftUI
import Combine

// Forward declarations for types used but not defined in this file
protocol MeshManagerProtocol {
    func startNetworking() async throws
    func stopNetworking() async
    func isNetworkReady() -> Bool
    func broadcastMessage(data: Data, type: String) async throws
}

// 暫時的聲明，實際實現在其他文件中
struct MeshMessage {
    let id: String
    let type: MessageType
    let data: Data
    
    enum MessageType {
        case game
    }
}

class BinaryMessageEncoder {
    static func encode(_ message: MeshMessage) throws -> Data {
        // 簡化實現
        return message.data
    }
}

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
        self.meshManager = meshManager
        self.timerManager = timerManager
        self.settingsViewModel = settingsViewModel
        self.languageService = languageService
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
        
        // 檢查通道可用性
        if !meshManager.canBroadcast() {
            throw NetworkError.broadcastChannelUnavailable
        }
        
        print("✅ BingoNetworkManager: 廣播通道驗證通過")
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
        var attempt = 0
        
        while attempt < maxRetries {
            do {
                // 創建完整的遊戲消息
                let gameMessage = createGameMessage(type: type, data: data, gameRoomID: gameRoomID, deviceName: deviceName)
                try await meshManager.broadcastMessage(data: gameMessage, type: type.rawValue)
                print("✅ BingoNetworkManager: 消息廣播成功 - \(type)")
                return
                
            } catch {
                attempt += 1
                print("❌ BingoNetworkManager: 廣播失敗 (嘗試 \(attempt)/\(maxRetries)) - \(error)")
                
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(Double(attempt) * 1_000_000_000)) // 指數退避
                }
            }
        }
        
        print("💥 BingoNetworkManager: 消息廣播最終失敗 - \(type)")
        await handleBroadcastFailure(type)
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
    private func handleBroadcastFailure(_ type: GameMessageType) async {
        print("❌ BingoNetworkManager: 處理廣播失敗 - \(type)")
        
        await updateSyncStatus("同步失敗")
        
        // 可以觸發重連或其他恢復邏輯
        await reconnectNetwork()
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
        cleanup()
    }
}

// MARK: - Supporting Types

/// 遊戲消息類型
enum GameMessageType: String, CaseIterable {
    case gameStart = "game_start"
    case numberDraw = "number_draw"
    case playerJoin = "player_join"
    case playerLeave = "player_leave"
    case gameWin = "game_win"
    case gameEnd = "game_end"
    case heartbeat = "heartbeat"
    case sync = "sync"
}

/// 網絡錯誤類型
enum NetworkError: Error, LocalizedError {
    case networkNotReady
    case broadcastChannelUnavailable
    case connectionTimeout
    case broadcastFailed
    
    var errorDescription: String? {
        switch self {
        case .networkNotReady:
            return "網絡未就緒"
        case .broadcastChannelUnavailable:
            return "廣播通道不可用"
        case .connectionTimeout:
            return "連接超時"
        case .broadcastFailed:
            return "廣播失敗"
        }
    }
}

// MARK: - Protocol Extensions

extension MeshManagerProtocol {
    /// 啟動主機模式
    func startHostMode() async throws {
        // 快速啟動邏輯，跳過部分驗證
        try await startNetworking()
    }
    
    /// 檢查是否可以廣播
    func canBroadcast() -> Bool {
        return isNetworkReady()
    }
}