import Foundation
import SwiftUI

/// 狀態更新協調器 - 消除重複的狀態管理邏輯
@MainActor
class StateUpdateCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StateUpdateCoordinator()
    private init() {}
    
    // MARK: - 狀態更新類型
    
    /// 狀態更新類型
    enum UpdateType {
        case player(PlayerUpdateType)
        case room(RoomUpdateType)
        case game(GameUpdateType)
        case network(NetworkUpdateType)
        case ui(UIUpdateType)
        
        enum PlayerUpdateType {
            case add, remove, update, progress, status
        }
        
        enum RoomUpdateType {
            case create, join, leave, sync, settings
        }
        
        enum GameUpdateType {
            case start, end, restart, state, draw, win
        }
        
        enum NetworkUpdateType {
            case connect, disconnect, reconnect, status
        }
        
        enum UIUpdateType {
            case loading, error, success, refresh
        }
    }
    
    /// 狀態更新結果
    enum UpdateResult {
        case success
        case failure(reason: String)
        case partial(completed: [String], failed: [String])
        
        var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failure, .partial: return false
            }
        }
    }
    
    // MARK: - 狀態管理
    
    /// 玩家狀態更新
    /// - Parameters:
    ///   - players: 玩家列表
    ///   - player: 要更新的玩家
    ///   - updateType: 更新類型
    /// - Returns: 更新結果和新的玩家列表
    func updatePlayerState(
        players: [PlayerState],
        player: PlayerState,
        updateType: UpdateType.PlayerUpdateType
    ) -> (result: UpdateResult, updatedPlayers: [PlayerState]) {
        
        var updatedPlayers = players
        
        switch updateType {
        case .add:
            // 檢查是否已存在
            if players.contains(where: { $0.id == player.id }) {
                return (.failure(reason: "玩家已存在"), players)
            }
            updatedPlayers.append(player)
            print("✅ 玩家已添加: \(player.name)")
            
        case .remove:
            updatedPlayers.removeAll { $0.id == player.id }
            print("✅ 玩家已移除: \(player.name)")
            
        case .update:
            if let index = updatedPlayers.firstIndex(where: { $0.id == player.id }) {
                updatedPlayers[index] = player
                print("✅ 玩家已更新: \(player.name)")
            } else {
                return (.failure(reason: "找不到要更新的玩家"), players)
            }
            
        case .progress:
            if let index = updatedPlayers.firstIndex(where: { $0.id == player.id }) {
                updatedPlayers[index].completedLines = player.completedLines
                print("✅ 玩家進度已更新: \(player.name) - \(player.completedLines) 條線")
            } else {
                return (.failure(reason: "找不到要更新進度的玩家"), players)
            }
            
        case .status:
            if let index = updatedPlayers.firstIndex(where: { $0.id == player.id }) {
                updatedPlayers[index].isConnected = player.isConnected
                updatedPlayers[index].hasWon = player.hasWon
                print("✅ 玩家狀態已更新: \(player.name) - 連接: \(player.isConnected), 獲勝: \(player.hasWon)")
            } else {
                return (.failure(reason: "找不到要更新狀態的玩家"), players)
            }
        }
        
        return (.success, updatedPlayers)
    }
    
    /// 批量更新玩家狀態
    /// - Parameters:
    ///   - players: 當前玩家列表
    ///   - updates: 要更新的玩家和更新類型
    /// - Returns: 更新結果和新的玩家列表
    func batchUpdatePlayerState(
        players: [PlayerState],
        updates: [(player: PlayerState, updateType: UpdateType.PlayerUpdateType)]
    ) -> (result: UpdateResult, updatedPlayers: [PlayerState]) {
        
        var currentPlayers = players
        var completed: [String] = []
        var failed: [String] = []
        
        for (player, updateType) in updates {
            let (result, updatedPlayers) = updatePlayerState(
                players: currentPlayers,
                player: player,
                updateType: updateType
            )
            
            currentPlayers = updatedPlayers
            
            if result.isSuccess {
                completed.append(player.name)
            } else {
                failed.append(player.name)
            }
        }
        
        if failed.isEmpty {
            return (.success, currentPlayers)
        } else if completed.isEmpty {
            return (.failure(reason: "所有更新都失敗"), players)
        } else {
            return (.partial(completed: completed, failed: failed), currentPlayers)
        }
    }
    
    /// 房間狀態更新
    /// - Parameters:
    ///   - roomState: 當前房間狀態
    ///   - updateType: 更新類型
    ///   - data: 更新數據
    /// - Returns: 更新結果
    func updateRoomState(
        roomState: inout GameRoomState?,
        updateType: UpdateType.RoomUpdateType,
        data: [String: Any] = [:]
    ) -> UpdateResult {
        
        switch updateType {
        case .create:
            guard let roomID = data["roomID"] as? String,
                  let hostID = data["hostID"] as? String else {
                return .failure(reason: "創建房間缺少必要參數")
            }
            
            roomState = GameRoomState(
                id: roomID,
                hostID: hostID,
                players: [],
                gameState: .waitingForPlayers,
                drawnNumbers: [],
                settings: GameRoomSettings()
            )
            print("✅ 房間已創建: \(roomID)")
            
        case .join:
            guard roomState != nil else {
                return .failure(reason: "房間不存在")
            }
            print("✅ 房間加入成功")
            
        case .leave:
            roomState = nil
            print("✅ 已離開房間")
            
        case .sync:
            guard let newState = data["roomState"] as? GameRoomState else {
                return .failure(reason: "房間同步數據無效")
            }
            roomState = newState
            print("✅ 房間狀態已同步")
            
        case .settings:
            guard roomState != nil,
                  let settings = data["settings"] as? GameRoomSettings else {
                return .failure(reason: "房間設置更新失敗")
            }
            roomState?.settings = settings
            print("✅ 房間設置已更新")
        }
        
        return .success
    }
    
    /// 遊戲狀態更新
    /// - Parameters:
    ///   - gameState: 當前遊戲狀態
    ///   - updateType: 更新類型
    ///   - data: 更新數據
    /// - Returns: 更新結果
    func updateGameState(
        gameState: inout GameRoomState.GameState,
        updateType: UpdateType.GameUpdateType,
        data: [String: Any] = [:]
    ) -> UpdateResult {
        
        switch updateType {
        case .start:
            gameState = .playing
            print("✅ 遊戲已開始")
            
        case .end:
            gameState = .finished
            print("✅ 遊戲已結束")
            
        case .restart:
            gameState = .waitingForPlayers
            print("✅ 遊戲已重新開始")
            
        case .state:
            guard let newState = data["state"] as? GameRoomState.GameState else {
                return .failure(reason: "遊戲狀態更新數據無效")
            }
            gameState = newState
            print("✅ 遊戲狀態已更新: \(newState)")
            
        case .draw:
            // 抽號相關邏輯
            if let number = data["number"] as? Int {
                print("✅ 已抽出號碼: \(number)")
            }
            
        case .win:
            gameState = .finished
            if let winner = data["winner"] as? String {
                print("✅ 遊戲結束，獲勝者: \(winner)")
            }
        }
        
        return .success
    }
    
    /// 網絡狀態更新
    /// - Parameters:
    ///   - connectionStatus: 連接狀態
    ///   - isNetworkActive: 網絡是否活躍
    ///   - updateType: 更新類型
    ///   - data: 更新數據
    /// - Returns: 更新結果
    func updateNetworkState(
        connectionStatus: inout String,
        isNetworkActive: inout Bool,
        updateType: UpdateType.NetworkUpdateType,
        data: [String: Any] = [:]
    ) -> UpdateResult {
        
        switch updateType {
        case .connect:
            connectionStatus = "已連接"
            isNetworkActive = true
            print("✅ 網絡連接成功")
            
        case .disconnect:
            connectionStatus = "已斷線"
            isNetworkActive = false
            print("✅ 網絡已斷開")
            
        case .reconnect:
            connectionStatus = "重新連接中..."
            print("✅ 網絡重新連接中")
            
        case .status:
            if let status = data["status"] as? String {
                connectionStatus = status
                print("✅ 網絡狀態已更新: \(status)")
            }
            if let active = data["active"] as? Bool {
                isNetworkActive = active
                print("✅ 網絡活躍狀態: \(active)")
            }
        }
        
        return .success
    }
    
    // MARK: - 複雜狀態更新
    
    /// 同步房間玩家狀態
    /// - Parameters:
    ///   - currentPlayers: 當前玩家列表
    ///   - receivedPlayers: 接收到的玩家列表
    /// - Returns: 更新結果和合併後的玩家列表
    func syncRoomPlayers(
        currentPlayers: [PlayerState],
        receivedPlayers: [PlayerState]
    ) -> (result: UpdateResult, syncedPlayers: [PlayerState]) {
        
        var syncedPlayers = currentPlayers
        var completed: [String] = []
        var failed: [String] = []
        
        // 更新現有玩家或添加新玩家
        for receivedPlayer in receivedPlayers {
            if let index = syncedPlayers.firstIndex(where: { $0.id == receivedPlayer.id }) {
                // 更新現有玩家
                syncedPlayers[index] = receivedPlayer
                completed.append(receivedPlayer.name)
            } else {
                // 添加新玩家
                syncedPlayers.append(receivedPlayer)
                completed.append(receivedPlayer.name)
            }
        }
        
        // 移除不在接收列表中的玩家
        let receivedPlayerIDs = Set(receivedPlayers.map { $0.id })
        syncedPlayers = syncedPlayers.filter { receivedPlayerIDs.contains($0.id) }
        
        print("✅ 房間玩家同步完成: \(completed.count) 個玩家")
        
        return (.success, syncedPlayers)
    }
    
    /// 更新玩家進度
    /// - Parameters:
    ///   - players: 玩家列表
    ///   - playerID: 玩家ID
    ///   - completedLines: 完成的線數
    ///   - hasWon: 是否獲勝
    /// - Returns: 更新結果和新的玩家列表
    func updatePlayerProgress(
        players: [PlayerState],
        playerID: String,
        completedLines: Int,
        hasWon: Bool = false
    ) -> (result: UpdateResult, updatedPlayers: [PlayerState]) {
        
        var updatedPlayers = players
        
        if let index = updatedPlayers.firstIndex(where: { $0.id == playerID }) {
            updatedPlayers[index].completedLines = completedLines
            updatedPlayers[index].hasWon = hasWon
            
            let playerName = updatedPlayers[index].name
            print("✅ 玩家進度更新: \(playerName) - \(completedLines) 條線\(hasWon ? "，已獲勝" : "")")
            
            return (.success, updatedPlayers)
        } else {
            return (.failure(reason: "找不到要更新的玩家"), players)
        }
    }
    
    /// 重置遊戲狀態
    /// - Parameters:
    ///   - players: 玩家列表
    ///   - gameState: 遊戲狀態
    ///   - drawnNumbers: 已抽出的號碼
    ///   - currentNumber: 當前號碼
    ///   - countdown: 倒數計時
    /// - Returns: 更新結果
    func resetGameState(
        players: inout [PlayerState],
        gameState: inout GameRoomState.GameState,
        drawnNumbers: inout [Int],
        currentNumber: inout Int?,
        countdown: inout Int
    ) -> UpdateResult {
        
        // 重置遊戲狀態
        gameState = .waitingForPlayers
        drawnNumbers = []
        currentNumber = nil
        countdown = 0
        
        // 重置所有玩家狀態
        for i in 0..<players.count {
            players[i].completedLines = 0
            players[i].hasWon = false
        }
        
        print("✅ 遊戲狀態已重置")
        return .success
    }
    
    // MARK: - 狀態驗證
    
    /// 驗證玩家狀態更新
    /// - Parameters:
    ///   - player: 玩家狀態
    ///   - updateType: 更新類型
    /// - Returns: 驗證結果
    func validatePlayerUpdate(player: PlayerState, updateType: UpdateType.PlayerUpdateType) -> Bool {
        switch updateType {
        case .add:
            return !player.id.isEmpty && !player.name.isEmpty
        case .remove:
            return !player.id.isEmpty
        case .update, .progress, .status:
            return !player.id.isEmpty
        }
    }
    
    /// 驗證房間狀態更新
    /// - Parameters:
    ///   - updateType: 更新類型
    ///   - data: 更新數據
    /// - Returns: 驗證結果
    func validateRoomUpdate(updateType: UpdateType.RoomUpdateType, data: [String: Any]) -> Bool {
        switch updateType {
        case .create:
            return data["roomID"] as? String != nil && data["hostID"] as? String != nil
        case .join, .leave:
            return true
        case .sync:
            return data["roomState"] as? GameRoomState != nil
        case .settings:
            return data["settings"] as? GameRoomSettings != nil
        }
    }
    
    // MARK: - 工具方法
    
    /// 獲取玩家索引
    /// - Parameters:
    ///   - players: 玩家列表
    ///   - playerID: 玩家ID
    /// - Returns: 玩家索引，如果不存在返回 nil
    func getPlayerIndex(players: [PlayerState], playerID: String) -> Int? {
        return players.firstIndex(where: { $0.id == playerID })
    }
    
    /// 檢查玩家是否存在
    /// - Parameters:
    ///   - players: 玩家列表
    ///   - playerID: 玩家ID
    /// - Returns: 是否存在
    func playerExists(players: [PlayerState], playerID: String) -> Bool {
        return players.contains(where: { $0.id == playerID })
    }
    
    /// 獲取活躍玩家數量
    /// - Parameter players: 玩家列表
    /// - Returns: 活躍玩家數量
    func getActivePlayerCount(players: [PlayerState]) -> Int {
        return players.filter { $0.isConnected }.count
    }
    
    /// 獲取獲勝玩家
    /// - Parameter players: 玩家列表
    /// - Returns: 獲勝的玩家列表
    func getWinners(players: [PlayerState]) -> [PlayerState] {
        return players.filter { $0.hasWon }
    }
    
    /// 記錄狀態更新
    /// - Parameters:
    ///   - updateType: 更新類型
    ///   - result: 更新結果
    ///   - context: 上下文信息
    func logStateUpdate(updateType: UpdateType, result: UpdateResult, context: String = "") {
        let typeString = String(describing: updateType)
        let resultString = result.isSuccess ? "✅ 成功" : "❌ 失敗"
        print("📊 狀態更新 [\(context)]: \(typeString) - \(resultString)")
        
        if case .failure(let reason) = result {
            print("   失敗原因: \(reason)")
        }
    }
}

// MARK: - 支持類型

/// 玩家狀態
struct PlayerState: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var completedLines: Int
    var hasWon: Bool
    var isConnected: Bool
    
    init(id: String, name: String, completedLines: Int = 0, hasWon: Bool = false, isConnected: Bool = true) {
        self.id = id
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
        self.isConnected = isConnected
    }
}

/// 遊戲房間狀態
struct GameRoomState: Codable {
    let id: String
    let hostID: String
    var players: [PlayerState]
    var gameState: GameState
    var drawnNumbers: [Int]
    var settings: GameRoomSettings
    
    enum GameState: String, Codable, CaseIterable {
        case waitingForPlayers = "waiting"
        case playing = "playing"
        case finished = "finished"
    }
}

/// 遊戲房間設置
struct GameRoomSettings: Codable {
    var maxPlayers: Int = 6
    var minPlayers: Int = 2
    var drawInterval: TimeInterval = 5.0
    var autoStart: Bool = false
    
    init(maxPlayers: Int = 6, minPlayers: Int = 2, drawInterval: TimeInterval = 5.0, autoStart: Bool = false) {
        self.maxPlayers = maxPlayers
        self.minPlayers = minPlayers
        self.drawInterval = drawInterval
        self.autoStart = autoStart
    }
}