import Foundation
import SwiftUI

/// 網絡廣播服務 - 消除重複的廣播邏輯
@MainActor
class NetworkBroadcastService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NetworkBroadcastService()
    private init() {}
    
    // MARK: - 依賴服務
    private let codecManager = BinaryCodecManager.shared
    private let validator = MessageValidationService.shared
    
    // MARK: - 廣播配置
    
    /// 廣播配置
    struct BroadcastConfig {
        let maxRetries: Int
        let retryDelay: TimeInterval
        let timeout: TimeInterval
        let enableLogging: Bool
        
        static let `default` = BroadcastConfig(
            maxRetries: 3,
            retryDelay: 1.0,
            timeout: 10.0,
            enableLogging: true
        )
    }
    
    /// 廣播結果
    enum BroadcastResult {
        case success(messageID: String)
        case failure(reason: String, messageID: String)
        case timeout(messageID: String)
        case retryExhausted(messageID: String, lastError: String)
        
        var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failure, .timeout, .retryExhausted: return false
            }
        }
        
        var messageID: String {
            switch self {
            case .success(let id), .failure(_, let id), .timeout(let id), .retryExhausted(let id, _):
                return id
            }
        }
    }
    
    // MARK: - 廣播統計
    
    /// 廣播統計
    struct BroadcastStats {
        var totalMessages: Int = 0
        var successfulMessages: Int = 0
        var failedMessages: Int = 0
        var retriedMessages: Int = 0
        var averageLatency: TimeInterval = 0
        
        var successRate: Double {
            guard totalMessages > 0 else { return 0 }
            return Double(successfulMessages) / Double(totalMessages)
        }
    }
    
    @Published private var stats = BroadcastStats()
    
    // MARK: - 基礎廣播方法
    
    /// 廣播遊戲消息
    /// - Parameters:
    ///   - messageType: 消息類型
    ///   - data: 消息數據
    ///   - roomID: 房間ID
    ///   - senderName: 發送者名稱
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastGameMessage(
        messageType: String,
        data: Data = Data(),
        roomID: String,
        senderName: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        let messageID = UUID().uuidString
        
        // 驗證參數
        let validationResult = validator.validateGameMessage(
            messageType: messageType,
            roomID: roomID,
            senderName: senderName,
            data: data
        )
        
        guard validationResult.isValid else {
            let result = BroadcastResult.failure(
                reason: validationResult.errorMessage ?? "參數驗證失敗",
                messageID: messageID
            )
            completion(result)
            updateStats(result: result)
            return
        }
        
        // 編碼消息
        let encodedMessage = codecManager.encodeGameMessage(
            messageType: messageType,
            roomID: roomID,
            senderName: senderName,
            data: data
        )
        
        // 執行廣播
        performBroadcast(
            messageID: messageID,
            encodedData: encodedMessage,
            messageType: messageType,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播聊天消息
    /// - Parameters:
    ///   - message: 聊天內容
    ///   - senderName: 發送者名稱
    ///   - roomID: 房間ID
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastChatMessage(
        message: String,
        senderName: String,
        roomID: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        let messageID = UUID().uuidString
        
        // 驗證聊天消息
        let validationResult = validator.validateChatMessageInfo(
            message: message,
            senderName: senderName,
            roomID: roomID
        )
        
        guard validationResult.isValid else {
            let result = BroadcastResult.failure(
                reason: validationResult.errorMessage ?? "聊天消息驗證失敗",
                messageID: messageID
            )
            completion(result)
            updateStats(result: result)
            return
        }
        
        // 編碼聊天消息
        let chatData = codecManager.encodeChatMessageFull(
            message: message,
            senderName: senderName
        )
        
        // 廣播聊天消息
        broadcastGameMessage(
            messageType: "chat_message",
            data: chatData,
            roomID: roomID,
            senderName: senderName,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播房間狀態
    /// - Parameters:
    ///   - roomState: 房間狀態
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastRoomState(
        roomState: GameRoomState,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        // 編碼房間狀態
        let roomData = encodeRoomState(roomState)
        
        // 廣播房間同步消息
        broadcastGameMessage(
            messageType: "room_sync",
            data: roomData,
            roomID: roomState.id,
            senderName: "system",
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播玩家進度
    /// - Parameters:
    ///   - player: 玩家狀態
    ///   - roomID: 房間ID
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastPlayerProgress(
        player: PlayerState,
        roomID: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        // 編碼玩家進度
        let progressData = encodePlayerProgress(player)
        
        // 廣播玩家進度
        broadcastGameMessage(
            messageType: "player_progress",
            data: progressData,
            roomID: roomID,
            senderName: player.name,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播遊戲狀態更新
    /// - Parameters:
    ///   - gameState: 遊戲狀態
    ///   - roomID: 房間ID
    ///   - hostName: 主機名稱
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastGameStateUpdate(
        gameState: GameRoomState.GameState,
        roomID: String,
        hostName: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        // 編碼遊戲狀態
        let stateData = encodeGameState(gameState)
        
        // 廣播遊戲狀態
        broadcastGameMessage(
            messageType: "game_state_update",
            data: stateData,
            roomID: roomID,
            senderName: hostName,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播號碼抽出
    /// - Parameters:
    ///   - number: 抽出的號碼
    ///   - roomID: 房間ID
    ///   - hostName: 主機名稱
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastNumberDraw(
        number: Int,
        roomID: String,
        hostName: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        // 驗證號碼
        let validationResult = validator.validateBingoNumber(number)
        guard validationResult.isValid else {
            let messageID = UUID().uuidString
            let result = BroadcastResult.failure(
                reason: validationResult.errorMessage ?? "號碼驗證失敗",
                messageID: messageID
            )
            completion(result)
            updateStats(result: result)
            return
        }
        
        // 編碼號碼
        let numberData = codecManager.encodeInt32(Int32(number))
        
        // 廣播號碼抽出
        broadcastGameMessage(
            messageType: "number_draw",
            data: numberData,
            roomID: roomID,
            senderName: hostName,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    /// 廣播獲勝宣告
    /// - Parameters:
    ///   - winnerID: 獲勝者ID
    ///   - winnerName: 獲勝者名稱
    ///   - lines: 完成的線數
    ///   - roomID: 房間ID
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func broadcastWinnerAnnouncement(
        winnerID: String,
        winnerName: String,
        lines: Int,
        roomID: String,
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void = { _ in }
    ) {
        // 驗證獲勝信息
        let idValidation = validator.validatePlayerID(winnerID)
        let nameValidation = validator.validatePlayerName(winnerName)
        let linesValidation = validator.validateBingoLines(lines)
        
        let validationResult = validator.validateMultiple([idValidation, nameValidation, linesValidation])
        
        guard validationResult.isValid else {
            let messageID = UUID().uuidString
            let result = BroadcastResult.failure(
                reason: validationResult.errorMessage ?? "獲勝信息驗證失敗",
                messageID: messageID
            )
            completion(result)
            updateStats(result: result)
            return
        }
        
        // 編碼獲勝信息
        let winnerData = encodeWinnerInfo(winnerID: winnerID, winnerName: winnerName, lines: lines)
        
        // 廣播獲勝宣告
        broadcastGameMessage(
            messageType: "winner_announcement",
            data: winnerData,
            roomID: roomID,
            senderName: winnerName,
            config: config,
            meshManager: meshManager,
            completion: completion
        )
    }
    
    // MARK: - 批量廣播
    
    /// 批量廣播消息
    /// - Parameters:
    ///   - messages: 消息列表
    ///   - config: 廣播配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    func batchBroadcast(
        messages: [(messageType: String, data: Data, roomID: String, senderName: String)],
        config: BroadcastConfig = .default,
        meshManager: MeshManagerProtocol,
        completion: @escaping ([BroadcastResult]) -> Void = { _ in }
    ) {
        var results: [BroadcastResult] = []
        let group = DispatchGroup()
        
        for message in messages {
            group.enter()
            
            broadcastGameMessage(
                messageType: message.messageType,
                data: message.data,
                roomID: message.roomID,
                senderName: message.senderName,
                config: config,
                meshManager: meshManager
            ) { result in
                results.append(result)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    // MARK: - 核心廣播實現
    
    /// 執行廣播
    /// - Parameters:
    ///   - messageID: 消息ID
    ///   - encodedData: 編碼的數據
    ///   - messageType: 消息類型
    ///   - config: 配置
    ///   - meshManager: 網絡管理器
    ///   - completion: 完成回調
    private func performBroadcast(
        messageID: String,
        encodedData: Data,
        messageType: String,
        config: BroadcastConfig,
        meshManager: MeshManagerProtocol,
        completion: @escaping (BroadcastResult) -> Void
    ) {
        let startTime = Date()
        
        Task {
            await performBroadcastWithRetry(
                messageID: messageID,
                encodedData: encodedData,
                messageType: messageType,
                config: config,
                meshManager: meshManager,
                attempt: 1,
                startTime: startTime,
                completion: completion
            )
        }
    }
    
    /// 帶重試的廣播實現
    /// - Parameters:
    ///   - messageID: 消息ID
    ///   - encodedData: 編碼的數據
    ///   - messageType: 消息類型
    ///   - config: 配置
    ///   - meshManager: 網絡管理器
    ///   - attempt: 當前嘗試次數
    ///   - startTime: 開始時間
    ///   - completion: 完成回調
    private func performBroadcastWithRetry(
        messageID: String,
        encodedData: Data,
        messageType: String,
        config: BroadcastConfig,
        meshManager: MeshManagerProtocol,
        attempt: Int,
        startTime: Date,
        completion: @escaping (BroadcastResult) -> Void
    ) async {
        
        do {
            // 檢查超時
            if Date().timeIntervalSince(startTime) > config.timeout {
                await MainActor.run {
                    let result = BroadcastResult.timeout(messageID: messageID)
                    completion(result)
                    updateStats(result: result)
                }
                return
            }
            
            // 嘗試廣播
            try await meshManager.broadcastMessage(data: encodedData, type: messageType)
            
            // 成功
            await MainActor.run {
                let result = BroadcastResult.success(messageID: messageID)
                completion(result)
                updateStats(result: result)
                
                if config.enableLogging {
                    let latency = Date().timeIntervalSince(startTime)
                    print("📡 廣播成功: \(messageType) (ID: \(messageID.prefix(8)), 延遲: \(latency)ms)")
                }
            }
            
        } catch {
            // 檢查是否需要重試
            if attempt < config.maxRetries {
                if config.enableLogging {
                    print("⚠️ 廣播失敗，準備重試: \(messageType) (嘗試 \(attempt)/\(config.maxRetries))")
                }
                
                // 等待重試延遲
                try? await Task.sleep(nanoseconds: UInt64(config.retryDelay * 1_000_000_000))
                
                // 遞歸重試
                await performBroadcastWithRetry(
                    messageID: messageID,
                    encodedData: encodedData,
                    messageType: messageType,
                    config: config,
                    meshManager: meshManager,
                    attempt: attempt + 1,
                    startTime: startTime,
                    completion: completion
                )
            } else {
                // 重試次數用盡
                await MainActor.run {
                    let result = BroadcastResult.retryExhausted(
                        messageID: messageID,
                        lastError: error.localizedDescription
                    )
                    completion(result)
                    updateStats(result: result)
                    
                    if config.enableLogging {
                        print("❌ 廣播最終失敗: \(messageType) (ID: \(messageID.prefix(8)), 錯誤: \(error))")
                    }
                }
            }
        }
    }
    
    // MARK: - 編碼輔助方法
    
    /// 編碼房間狀態
    /// - Parameter roomState: 房間狀態
    /// - Returns: 編碼的數據
    private func encodeRoomState(_ roomState: GameRoomState) -> Data {
        var data = Data()
        
        // 編碼房間基本信息
        data.append(codecManager.encodeRoomInfo(roomID: roomState.id, hostID: roomState.hostID))
        
        // 編碼遊戲狀態
        data.append(codecManager.encodeString(roomState.gameState.rawValue))
        
        // 編碼玩家數量
        data.append(codecManager.encodeInt32(Int32(roomState.players.count)))
        
        // 編碼每個玩家
        for player in roomState.players {
            data.append(encodePlayerState(player))
        }
        
        return data
    }
    
    /// 編碼玩家狀態
    /// - Parameter player: 玩家狀態
    /// - Returns: 編碼的數據
    private func encodePlayerState(_ player: PlayerState) -> Data {
        var data = Data()
        
        data.append(codecManager.encodePlayerInfo(playerID: player.id, playerName: player.name))
        data.append(codecManager.encodeInt32(Int32(player.completedLines)))
        data.append(Data([player.hasWon ? 1 : 0]))
        data.append(Data([player.isConnected ? 1 : 0]))
        
        return data
    }
    
    /// 編碼玩家進度
    /// - Parameter player: 玩家狀態
    /// - Returns: 編碼的數據
    private func encodePlayerProgress(_ player: PlayerState) -> Data {
        var data = Data()
        
        data.append(codecManager.encodePlayerID(player.id))
        data.append(codecManager.encodeInt32(Int32(player.completedLines)))
        data.append(Data([player.hasWon ? 1 : 0]))
        
        return data
    }
    
    /// 編碼遊戲狀態
    /// - Parameter gameState: 遊戲狀態
    /// - Returns: 編碼的數據
    private func encodeGameState(_ gameState: GameRoomState.GameState) -> Data {
        return codecManager.encodeString(gameState.rawValue)
    }
    
    /// 編碼獲勝信息
    /// - Parameters:
    ///   - winnerID: 獲勝者ID
    ///   - winnerName: 獲勝者名稱
    ///   - lines: 完成的線數
    /// - Returns: 編碼的數據
    private func encodeWinnerInfo(winnerID: String, winnerName: String, lines: Int) -> Data {
        var data = Data()
        
        data.append(codecManager.encodePlayerInfo(playerID: winnerID, playerName: winnerName))
        data.append(codecManager.encodeInt32(Int32(lines)))
        
        return data
    }
    
    // MARK: - 統計管理
    
    /// 更新統計信息
    /// - Parameter result: 廣播結果
    private func updateStats(result: BroadcastResult) {
        stats.totalMessages += 1
        
        if result.isSuccess {
            stats.successfulMessages += 1
        } else {
            stats.failedMessages += 1
        }
        
        if case .retryExhausted = result {
            stats.retriedMessages += 1
        }
    }
    
    /// 獲取統計信息
    /// - Returns: 統計信息
    func getStats() -> BroadcastStats {
        return stats
    }
    
    /// 重置統計信息
    func resetStats() {
        stats = BroadcastStats()
    }
    
    // MARK: - 工具方法
    
    /// 檢查網絡狀態
    /// - Parameter meshManager: 網絡管理器
    /// - Returns: 網絡是否可用
    func isNetworkAvailable(meshManager: MeshManagerProtocol) -> Bool {
        return meshManager.isNetworkReady()
    }
    
    /// 獲取連接的節點數量
    /// - Parameter meshManager: 網絡管理器
    /// - Returns: 連接的節點數量
    func getConnectedPeerCount(meshManager: MeshManagerProtocol) -> Int {
        return meshManager.getConnectedPeers().count
    }
}

// MARK: - 協議定義

/// 網絡管理器協議
protocol MeshManagerProtocol {
    func broadcastMessage(data: Data, type: String) async throws
    func isNetworkReady() -> Bool
    func getConnectedPeers() -> [String]
}