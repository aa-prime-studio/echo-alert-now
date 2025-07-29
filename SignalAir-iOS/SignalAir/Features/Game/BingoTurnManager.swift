import Foundation
import Combine

/// 【Architect】賓果遊戲輪流管理器 - 支持玩家輪流抽號機制
@MainActor
class BingoTurnManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 當前輪到的玩家ID
    @Published var currentPlayerTurn: String = ""
    
    /// 玩家輪流順序
    @Published var turnOrder: [String] = []
    
    /// 是否輪到當前設備
    @Published var isMyTurn: Bool = false
    
    /// 輪流索引
    @Published var currentTurnIndex: Int = 0
    
    // MARK: - Dependencies
    
    private let networkManager: BingoNetworkManager
    private let localPeerID: String
    
    // MARK: - Initialization
    
    init(networkManager: BingoNetworkManager, localPeerID: String) {
        self.networkManager = networkManager
        self.localPeerID = localPeerID
        print("🎯 BingoTurnManager: 初始化輪流管理器")
    }
    
    // MARK: - Turn Management
    
    /// 初始化輪流順序
    func initializeTurnOrder(players: [String]) {
        print("🎯 BingoTurnManager: 初始化輪流順序")
        print("🎯 玩家列表: \(players)")
        
        // 按照設備ID排序確保所有設備的順序一致
        turnOrder = players.sorted()
        currentTurnIndex = 0
        currentPlayerTurn = turnOrder.first ?? ""
        
        updateMyTurnStatus()
        
        print("🎯 輪流順序: \(turnOrder)")
        print("🎯 當前輪到: \(currentPlayerTurn)")
        print("🎯 是否我的回合: \(isMyTurn)")
    }
    
    /// 輪到下一位玩家
    func nextTurn() {
        guard !turnOrder.isEmpty else {
            print("⚠️ BingoTurnManager: 沒有玩家，無法切換輪流")
            return
        }
        
        let previousPlayer = currentPlayerTurn
        currentTurnIndex = (currentTurnIndex + 1) % turnOrder.count
        currentPlayerTurn = turnOrder[currentTurnIndex]
        
        updateMyTurnStatus()
        
        print("🎯 BingoTurnManager: 輪流切換")
        print("🎯 從 \(previousPlayer) → \(currentPlayerTurn)")
        print("🎯 是否我的回合: \(isMyTurn)")
        
        // 廣播輪流變更（使用二進制格式）
        broadcastTurnChange()
    }
    
    /// 處理收到的輪流變更消息
    func handleTurnChange(nextPlayerID: String, turnIndex: Int) {
        print("📨 BingoTurnManager: 收到輪流變更")
        print("📨 下一位玩家: \(nextPlayerID)")
        print("📨 輪流索引: \(turnIndex)")
        
        // 驗證輪流索引和玩家ID的一致性
        guard turnIndex < turnOrder.count,
              turnOrder[turnIndex] == nextPlayerID else {
            print("⚠️ BingoTurnManager: 輪流變更數據不一致，忽略")
            return
        }
        
        currentPlayerTurn = nextPlayerID
        currentTurnIndex = turnIndex
        updateMyTurnStatus()
        
        print("📨 輪流同步完成，當前輪到: \(currentPlayerTurn)")
    }
    
    /// 重置輪流狀態
    func resetTurnState() {
        print("🔄 BingoTurnManager: 重置輪流狀態")
        
        currentPlayerTurn = ""
        turnOrder = []
        currentTurnIndex = 0
        isMyTurn = false
    }
    
    // MARK: - Player Management
    
    /// 移除玩家並調整輪流順序
    func removePlayer(_ playerID: String) {
        print("👤 BingoTurnManager: 移除玩家 \(playerID)")
        
        guard let playerIndex = turnOrder.firstIndex(of: playerID) else {
            print("⚠️ 玩家不在輪流列表中")
            return
        }
        
        turnOrder.remove(at: playerIndex)
        
        // 調整當前輪流索引
        if currentTurnIndex >= turnOrder.count {
            currentTurnIndex = 0
        }
        
        // 更新當前輪到的玩家
        if !turnOrder.isEmpty {
            currentPlayerTurn = turnOrder[currentTurnIndex]
        } else {
            currentPlayerTurn = ""
        }
        
        updateMyTurnStatus()
        
        print("👤 移除後輪流順序: \(turnOrder)")
        print("👤 當前輪到: \(currentPlayerTurn)")
    }
    
    /// 添加新玩家到輪流順序
    func addPlayer(_ playerID: String) {
        print("👤 BingoTurnManager: 添加玩家 \(playerID)")
        
        guard !turnOrder.contains(playerID) else {
            print("⚠️ 玩家已在輪流列表中")
            return
        }
        
        turnOrder.append(playerID)
        turnOrder.sort() // 保持排序一致性
        
        // 重新計算當前玩家的索引
        if let newIndex = turnOrder.firstIndex(of: currentPlayerTurn) {
            currentTurnIndex = newIndex
        }
        
        updateMyTurnStatus()
        
        print("👤 添加後輪流順序: \(turnOrder)")
    }
    
    // MARK: - Private Methods
    
    /// 更新是否輪到自己的狀態
    private func updateMyTurnStatus() {
        isMyTurn = (currentPlayerTurn == localPeerID) && !turnOrder.isEmpty
    }
    
    /// 廣播輪流變更（使用二進制格式）
    private func broadcastTurnChange() {
        let turnData = BinaryGameProtocol.encodeTurnChange(
            nextPlayerID: currentPlayerTurn,
            turnIndex: currentTurnIndex
        )
        
        Task {
            do {
                try await networkManager.broadcastGameAction(
                    type: .turnChange,
                    data: turnData,
                    priority: .high
                )
                print("📡 輪流變更廣播成功")
            } catch {
                print("❌ 輪流變更廣播失敗: \(error)")
            }
        }
    }
    
    // MARK: - Validation
    
    /// 驗證輪流狀態是否有效
    var isValidTurnState: Bool {
        return !turnOrder.isEmpty && 
               currentTurnIndex < turnOrder.count && 
               turnOrder[currentTurnIndex] == currentPlayerTurn
    }
    
    /// 獲取下一位玩家ID
    var nextPlayerID: String? {
        guard !turnOrder.isEmpty else { return nil }
        let nextIndex = (currentTurnIndex + 1) % turnOrder.count
        return turnOrder[nextIndex]
    }
    
    /// 獲取輪流進度信息
    var turnProgress: String {
        guard !turnOrder.isEmpty else { return "無玩家" }
        return "\(currentTurnIndex + 1)/\(turnOrder.count)"
    }
}

// MARK: - Extensions

extension BingoTurnManager {
    
    /// 調試信息
    var debugDescription: String {
        return """
        BingoTurnManager State:
        - 輪流順序: \(turnOrder)
        - 當前玩家: \(currentPlayerTurn)
        - 輪流索引: \(currentTurnIndex)
        - 是否我的回合: \(isMyTurn)
        - 本地設備ID: \(localPeerID)
        - 輪流狀態有效: \(isValidTurnState)
        """
    }
}