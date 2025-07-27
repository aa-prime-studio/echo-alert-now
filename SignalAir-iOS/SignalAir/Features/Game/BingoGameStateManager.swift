import Foundation
import SwiftUI
import Combine

/// 賓果遊戲狀態管理器 - 負責所有遊戲邏輯和狀態管理
@MainActor
class BingoGameStateManager: BingoGameStateManagerProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    /// 賓果卡片
    @Published var bingoCard: BingoCard?
    
    /// 已抽出的號碼
    @Published var drawnNumbers: [Int] = []
    
    /// 完成的線數
    @Published var completedLines: Int = 0
    
    /// 遊戲是否獲勝
    @Published var gameWon: Bool = false
    
    /// 遊戲狀態
    @Published var gameState: GameRoomState.GameState = .waitingForPlayers
    
    /// 倒數計時
    @Published var countdown: Int = 0
    
    /// 當前號碼
    @Published var currentNumber: Int?
    
    // MARK: - Dependencies
    
    private let timerManager: UnifiedTimerManager
    private let networkManager: BingoNetworkManager
    
    // MARK: - Private Properties
    
    private var gameWinCallbacks: [(String, Int) -> Void] = []
    private var drawnNumbersSet: Set<Int> = []
    private let totalNumbers = 99  // 1-99 (原始設計)
    
    // MARK: - Initialization
    
    init(timerManager: UnifiedTimerManager, networkManager: BingoNetworkManager) {
        print("🎮 BingoGameStateManager: 開始初始化")
        
        self.timerManager = timerManager
        self.networkManager = networkManager
        
        // 【FIX】避免 MainActor 死鎖 - 移除 init 中的異步操作
        
        // 設置初始遊戲狀態（同步）
        gameState = .waitingForPlayers
    }
    
    /// 【NEW】在 UI 出現時執行初始化，避免 MainActor 死鎖
    func onAppear() {
        Task { @MainActor in
            await self.performAsyncInitialization()
        }
    }
    
    /// 異步初始化方法
    private func performAsyncInitialization() async {
        print("🎮 BingoGameStateManager: 執行異步初始化")
        
        // 可以在這裡執行需要異步的初始化操作
        
        print("🎮 BingoGameStateManager: 異步初始化完成")
    }
    
    // MARK: - Game Lifecycle
    
    /// 開始遊戲
    func startGame() {
        print("🎮 BingoGameStateManager: 開始遊戲")
        
        // 【對齊主線】先設置為倒數狀態
        gameState = .countdown  
        countdown = 3
        gameWon = false
        drawnNumbers = []
        drawnNumbersSet = []
        currentNumber = nil
        
        // 生成賓果卡
        generateBingoCard()
        
        // 開始倒數計時，倒數結束後自動抽號
        startCountdown()
        
        // 廣播遊戲開始
        let startData = "game_start".data(using: .utf8) ?? Data()
        networkManager.broadcastGameMessage(.gameStart, data: startData)
    }
    
    /// 結束遊戲
    func endGame() {
        print("🎮 BingoGameStateManager: 結束遊戲")
        
        gameState = .finished
        stopAllTimers()
        
        // 廣播遊戲結束
        let endData = "game_end".data(using: .utf8) ?? Data()
        networkManager.broadcastGameMessage(.gameEnd, data: endData)
    }
    
    /// 重置遊戲狀態
    func resetGameState() {
        print("🎮 BingoGameStateManager: 重置遊戲狀態")
        
        gameState = .waitingForPlayers
        gameWon = false
        bingoCard = nil
        drawnNumbers = []
        drawnNumbersSet = []
        completedLines = 0
        countdown = 0
        currentNumber = nil
        
        stopAllTimers()
    }
    
    /// 重新開始遊戲
    func restartGame() {
        print("🎮 BingoGameStateManager: 重新開始遊戲")
        
        resetGameState()
        
        // 延遲開始新遊戲
        let config = TimerConfiguration(interval: 2.0, repeats: false)
        timerManager.schedule(id: "game.restart.delay", configuration: config) { [weak self] in
            self?.startGame()
        }
        
        // 廣播重新開始
        let restartData = "game_restart".data(using: .utf8) ?? Data()
        networkManager.broadcastGameMessage(.gameRestart, data: restartData)
    }
    
    // MARK: - Bingo Card Generation
    
    /// 生成賓果卡片 (1-99 系統)
    func generateBingoCard() {
        // 【FIXED】檢查是否已有賓果卡，避免重複生成
        if bingoCard != nil {
            print("🎮 BingoGameStateManager: 賓果卡已存在，跳過生成")
            return
        }
        
        print("🎮 BingoGameStateManager: 生成賓果卡片 (1-99 系統)")
        
        var cardNumbers: [[Int]] = []
        
        // 1-99 系統：每列分配不同範圍
        // 第1列: 1-20
        let col1 = Array(1...20).shuffled().prefix(5)
        // 第2列: 21-40
        let col2 = Array(21...40).shuffled().prefix(5)
        // 第3列: 41-60 (中心為FREE)
        var col3 = Array(41...60).shuffled().prefix(5)
        col3[2] = 0 // FREE space
        // 第4列: 61-80
        let col4 = Array(61...80).shuffled().prefix(5)
        // 第5列: 81-99
        let col5 = Array(81...99).shuffled().prefix(5)
        
        // 組合成5x5矩陣
        for row in 0..<5 {
            let rowNumbers = [
                Int(col1[row]),
                Int(col2[row]),
                Int(col3[row]),
                Int(col4[row]),
                Int(col5[row])
            ]
            cardNumbers.append(rowNumbers)
        }
        
        var card = BingoCard(numbers: cardNumbers.flatMap { $0 })
        
        // 中心格自動標記為已確認（FREE space）
        card.marked[12] = true  // 5x5網格的中心位置是索引12 (第3行第3列)
        card.drawn[12] = true   // 中心格也視為已抽中
        
        bingoCard = card
        print("✅ BingoGameStateManager: 賓果卡片生成完成 (1-99 系統)，中心格已自動標記")
    }
    
    // MARK: - Number Drawing
    
    /// 手動抽號 (由玩家觸發)
    func manualDrawNumber() {
        print("🎮 BingoGameStateManager: 手動抽號")
        
        // 確保遊戲正在進行中
        guard gameState == .playing else {
            print("⚠️ BingoGameStateManager: 遊戲未在進行中，無法抽號")
            return
        }
        
        // 找出尚未抽出的號碼
        let availableNumbers = Set(1...totalNumbers).subtracting(drawnNumbersSet)
        
        guard !availableNumbers.isEmpty else {
            print("🎮 BingoGameStateManager: 所有號碼已抽完")
            endGame()
            return
        }
        
        // 隨機選擇一個號碼
        let nextNumber = availableNumbers.randomElement()!
        currentNumber = nextNumber
        drawnNumbers.append(nextNumber)
        drawnNumbersSet.insert(nextNumber)
        
        print("🎮 BingoGameStateManager: 手動抽出號碼 \(nextNumber)")
        
        // 廣播抽出的號碼
        let numberData = withUnsafeBytes(of: Int32(nextNumber).littleEndian) { Data($0) }
        print("📡 【重要】廣播抽號消息:")
        print("📡   - 號碼: \(nextNumber)")
        print("📡   - 數據長度: \(numberData.count) 字節")
        print("📡   - 數據內容: \(numberData.map { String(format: "%02x", $0) }.joined(separator: " "))")
        networkManager.broadcastGameMessage(.numberDrawn, data: numberData)
        print("📡   ✅ 抽號消息廣播完成")
        
        // 檢查是否有玩家獲勝
        checkWinConditionInternal()
    }
    
    /// 【廢棄】自動抽號 (舊版本，現在不使用)
    private func startDrawing() {
        print("🎮 BingoGameStateManager: 【廢棄】自動抽號功能")
        // 此功能已廢棄，改為手動抽號
    }
    
    /// 自動抽取下一個號碼
    private func drawNextNumber() {
        print("🎲 BingoGameStateManager: 自動抽取下一個號碼")
        
        // 確保遊戲正在進行中
        guard gameState == .playing else {
            print("⚠️ BingoGameStateManager: 遊戲未在進行中，停止抽號")
            return
        }
        
        // 找出尚未抽出的號碼
        let availableNumbers = Set(1...totalNumbers).subtracting(drawnNumbersSet)
        
        guard !availableNumbers.isEmpty else {
            print("🎮 BingoGameStateManager: 所有號碼已抽完，結束遊戲")
            endGame()
            return
        }
        
        // 隨機選擇一個號碼
        let nextNumber = availableNumbers.randomElement()!
        currentNumber = nextNumber
        drawnNumbers.append(nextNumber)
        drawnNumbersSet.insert(nextNumber)
        
        print("🎲 BingoGameStateManager: 自動抽出號碼 \(nextNumber)")
        
        // 【新增】在聊天室顯示抽號結果
        broadcastSystemMessage("🎲 抽出號碼：\(nextNumber)")
        
        // 廣播抽出的號碼
        let numberData = withUnsafeBytes(of: Int32(nextNumber).littleEndian) { Data($0) }
        networkManager.broadcastGameMessage(.numberDrawn, data: numberData)
        
        // 檢查是否有玩家獲勝
        checkWinConditionInternal()
    }
    
    // MARK: - Number Marking
    
    /// 標記號碼
    func markNumber(_ number: Int) {
        print("🎮 BingoGameStateManager: 標記號碼 \(number)")
        
        guard let card = bingoCard else {
            print("⚠️ BingoGameStateManager: 沒有賓果卡片")
            return
        }
        
        // 檢查號碼是否已經抽出
        guard drawnNumbersSet.contains(number) else {
            print("⚠️ BingoGameStateManager: 號碼 \(number) 尚未抽出")
            return
        }
        
        // 在卡片上標記號碼（用戶確認）
        var newCard = card
        for row in 0..<5 {
            for col in 0..<5 {
                if newCard.numbers[row * 5 + col] == number {
                    newCard.marked[row * 5 + col] = true  // 修復：應該設置marked，不是drawn
                    print("✅ BingoGameStateManager: 用戶確認標記位置 (\(row),\(col))")
                }
            }
        }
        
        bingoCard = newCard
        
        // 檢查獲勝條件
        checkWinConditionInternal()
        
        // 廣播玩家進度
        let progressData = createProgressData()
        networkManager.broadcastGameMessage(.playerProgress, data: progressData)
    }
    
    // MARK: - Win Condition
    
    /// 檢查獲勝條件
    private func checkWinConditionInternal() {
        guard let card = bingoCard else { return }
        
        let lines = checkBingoLines(card: card)
        completedLines = lines
        
        // 【FIX】只有達到5條線才算獲勝
        if lines >= 5 && !gameWon {
            gameWon = true
            print("🎉 BingoGameStateManager: 獲勝！完成 \(lines) 條線")
            
            // 【FIX】立即停止自動抽號
            timerManager.invalidate(id: "gameDraw")
            
            // 廣播獲勝訊息到聊天室
            broadcastSystemMessage("🎉 遊戲結束！有玩家完成 \(lines) 條線！")
            
            // 觸發獲勝回調
            for callback in gameWinCallbacks {
                callback("current_player", lines)
            }
            
            // 廣播獲勝
            broadcastWin(lines: lines)
            
            // 【NEW】延遲3秒後自動結束遊戲並踢出玩家
            let config = TimerConfiguration(interval: 3.0, repeats: false)
            timerManager.schedule(id: "gameEnd.delay", configuration: config) { [weak self] in
                self?.autoEndGameAndKickPlayers()
            }
        }
    }
    
    /// 【NEW】自動結束遊戲並踢出所有玩家
    private func autoEndGameAndKickPlayers() {
        print("🔚 BingoGameStateManager: 自動結束遊戲並踢出玩家")
        
        // 停止所有定時器（包括自動抽號）
        stopAllTimers()
        
        // 廣播遊戲結束訊息
        broadcastSystemMessage("🚪 遊戲結束，所有玩家將被踢出房間")
        
        // 設置遊戲狀態為結束
        gameState = .finished
        
        // 廣播踢出玩家的訊息
        let kickData = "auto_kick_all".data(using: .utf8) ?? Data()
        networkManager.broadcastGameMessage(.gameEnd, data: kickData)
        
        // 延遲1秒後重置狀態，準備下一輪
        let resetConfig = TimerConfiguration(interval: 1.0, repeats: false)
        timerManager.schedule(id: "gameReset.delay", configuration: resetConfig) { [weak self] in
            self?.resetGameState()
        }
    }
    
    /// 檢查賓果線數
    private func checkBingoLines(card: BingoCard) -> Int {
        var lines = 0
        
        // 檢查橫線
        for row in 0..<5 {
            var complete = true
            for col in 0..<5 {
                if !card.marked[row * 5 + col] && !(row == 2 && col == 2) {
                    complete = false
                    break
                }
            }
            if complete { lines += 1 }
        }
        
        // 檢查直線
        for col in 0..<5 {
            var complete = true
            for row in 0..<5 {
                if !card.marked[row * 5 + col] && !(row == 2 && col == 2) {
                    complete = false
                    break
                }
            }
            if complete { lines += 1 }
        }
        
        // 檢查對角線
        var diag1Complete = true
        var diag2Complete = true
        
        for i in 0..<5 {
            if !card.marked[i * 5 + i] && !(i == 2) {
                diag1Complete = false
            }
            if !card.marked[i * 5 + (4-i)] && !(i == 2) {
                diag2Complete = false
            }
        }
        
        if diag1Complete { lines += 1 }
        if diag2Complete { lines += 1 }
        
        return lines
    }
    
    /// 廣播獲勝
    private func broadcastWin(lines: Int) {
        let winData = createWinData(lines: lines)
        networkManager.broadcastGameMessage(.winnerAnnouncement, data: winData)
    }
    
    // MARK: - Message Handling
    
    /// 處理號碼抽出消息
    func handleNumberDrawn(_ number: Int) {
        print("📨 【重要】BingoGameStateManager: 接收到號碼抽出 \(number)")
        print("📨   - 當前遊戲狀態: \(gameState)")
        print("📨   - 已抽號碼列表: \(drawnNumbers)")
        print("📨   - 是否為重複號碼: \(drawnNumbers.contains(number))")
        
        currentNumber = number
        if !drawnNumbers.contains(number) {
            drawnNumbers.append(number)
            drawnNumbersSet.insert(number)
            print("📨   ✅ 號碼 \(number) 已加入已抽列表")
        } else {
            print("📨   ⚠️ 號碼 \(number) 重複，跳過")
        }
        
        // 更新賓果卡上該號碼的drawn狀態（顯示為藍色）
        if var card = bingoCard {
            var foundAndMarked = false
            for i in 0..<card.numbers.count {
                if card.numbers[i] == number {
                    card.drawn[i] = true
                    foundAndMarked = true
                    print("✅ BingoGameStateManager: 號碼 \(number) 在位置 \(i) 標記為已抽中（藍色顯示）")
                }
            }
            bingoCard = card
            
            if foundAndMarked {
                print("📨   ✅ 賓果卡已更新，號碼 \(number) 將顯示為藍色")
            } else {
                print("📨   ⚠️ 號碼 \(number) 不在我的賓果卡上")
            }
        } else {
            print("📨   ❌ 沒有賓果卡，無法標記號碼")
        }
        
        print("📨   🎯 號碼抽出處理完成，當前已抽號碼: \(drawnNumbers)")
        
        // 檢查獲勝條件
        checkWinConditionInternal()
    }
    
    /// 處理遊戲開始消息
    func handleGameStart() {
        print("🎮 BingoGameStateManager: 處理遊戲開始消息")
        
        gameState = .playing
        generateBingoCard()
        // 現在改為手動抽號，不自動開始抽號
        print("🎮 BingoGameStateManager: 遊戲開始，等待手動抽號")
    }
    
    /// 處理遊戲結束消息
    func handleGameEnd() {
        print("🎮 BingoGameStateManager: 處理遊戲結束消息")
        
        gameState = .finished
        stopAllTimers()
    }
    
    /// 處理遊戲重新開始消息
    func handleGameRestart() {
        print("🎮 BingoGameStateManager: 處理遊戲重新開始消息")
        
        resetGameState()
        
        let config = TimerConfiguration(interval: 1.0, repeats: false)
        timerManager.schedule(id: "game.restart.handle", configuration: config) { [weak self] in
            self?.startGame()
        }
    }
    
    // MARK: - Countdown
    
    /// 開始倒數計時
    private func startCountdown() {
        print("⏰ BingoGameStateManager: 開始倒數計時")
        
        // 【對齊主線】使用正確的計時器配置
        let config = TimerConfiguration(interval: 1.0, repeats: true)
        timerManager.schedule(id: "gameCountdown", configuration: config) { [weak self] in
            guard let self = self else { return }
            
            if self.countdown > 0 {
                // 【新增】在聊天室顯示倒數  
                self.broadcastSystemMessage("⏰ \(self.countdown)...")
                print("⏰ 倒數: \(self.countdown)")
                
                self.countdown -= 1
            } else {
                // 倒數結束
                self.timerManager.invalidate(id: "gameCountdown")
                
                // 倒數結束後自動開始抽號
                print("🎮 BingoGameStateManager: 倒數結束，開始自動抽號！")
                self.actuallyStartGame()
            }
        }
    }
    
    /// 真正開始遊戲（倒數結束後）
    private func actuallyStartGame() {
        print("🎮 BingoGameStateManager: 真正開始遊戲")
        
        gameState = .playing
        
        // 在聊天室顯示遊戲開始
        broadcastSystemMessage("🎮 遊戲開始！系統將自動抽號")
        
        // 開始自動抽號
        startAutoDrawing()
    }
    
    /// 開始自動抽號
    private func startAutoDrawing() {
        print("🎲 BingoGameStateManager: 開始自動抽號")
        
        // 每3秒自動抽一個號碼
        let config = TimerConfiguration(interval: 3.0, repeats: true)
        timerManager.schedule(id: "gameDraw", configuration: config) { [weak self] in
            guard let self = self else { return }
            self.drawNextNumber()
        }
    }
    
    /// 廣播系統訊息到聊天室（對齊主線實現）
    private func broadcastSystemMessage(_ message: String) {
        print("💬 系統訊息: \(message)")
        
        // 【FIX】使用正確的二進制格式發送系統訊息
        let systemData = createSystemMessageData(message: message)
        networkManager.broadcastGameMessage(.chatMessage, data: systemData)
    }
    
    /// 創建系統訊息的二進制數據
    private func createSystemMessageData(message: String) -> Data {
        var data = Data()
        
        // 房間ID（使用空字符串）
        data.append(UInt8(0))
        
        // 發送者名稱（使用"系統"）
        let senderName = "系統"
        let senderData = senderName.data(using: .utf8) ?? Data()
        let senderLength = min(senderData.count, 255)
        data.append(UInt8(senderLength))
        data.append(senderData.prefix(senderLength))
        
        // 消息內容長度和數據
        let messageData = message.data(using: .utf8) ?? Data()
        let messageLength = UInt16(messageData.count)
        data.append(contentsOf: withUnsafeBytes(of: messageLength.littleEndian) { Array($0) })
        data.append(messageData)
        
        // 時間戳
        let timestamp = UInt64(Date().timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian) { Array($0) })
        
        return data
    }
    
    // MARK: - Timer Management
    
    /// 停止所有計時器
    private func stopAllTimers() {
        timerManager.invalidate(id: "gameCountdown")
        timerManager.invalidate(id: "gameDraw")
        timerManager.invalidate(id: "gameEnd.delay")
        timerManager.invalidate(id: "gameReset.delay")
        print("⏹️ BingoGameStateManager: 已停止所有計時器")
    }
    
    // MARK: - Data Creation
    
    /// 創建進度數據
    private func createProgressData() -> Data {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: Int32(completedLines).littleEndian) { Array($0) })
        return data
    }
    
    /// 創建獲勝數據
    private func createWinData(lines: Int) -> Data {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: Int32(lines).littleEndian) { Array($0) })
        return data
    }
    
    // MARK: - Publishers for Protocol Compliance
    
    var gameStatePublisher: AnyPublisher<GameRoomState.GameState, Never> {
        $gameState.eraseToAnyPublisher()
    }
    
    var bingoCardPublisher: AnyPublisher<BingoCard?, Never> {
        $bingoCard.eraseToAnyPublisher()
    }
    
    var drawnNumbersPublisher: AnyPublisher<[Int], Never> {
        $drawnNumbers.eraseToAnyPublisher()
    }
    
    var currentNumberPublisher: AnyPublisher<Int?, Never> {
        $currentNumber.eraseToAnyPublisher()
    }
    
    var gameWonPublisher: AnyPublisher<Bool, Never> {
        $gameWon.eraseToAnyPublisher()
    }
    
    // MARK: - Callbacks
    
    /// 註冊獲勝回調
    func onGameWon(_ callback: @escaping (String, Int) -> Void) {
        gameWinCallbacks.append(callback)
    }
    
    /// 檢查獲勝條件 (公開方法)
    func checkWinCondition() {
        checkWinConditionInternal()
    }
    
    // MARK: - Lifecycle
    
    /// 清理資源
    func cleanup() {
        print("🧹 BingoGameStateManager: 清理資源")
        stopAllTimers()
        gameWinCallbacks.removeAll()
    }
    
    deinit {
        print("🗑️ BingoGameStateManager: deinit")
        // 清理資源不使用 MainActor 方法以避免管理生命周期問題
        gameWinCallbacks.removeAll()
    }
}

// MARK: - Supporting Types
// 所有型別定義已移至 SharedTypes.swift