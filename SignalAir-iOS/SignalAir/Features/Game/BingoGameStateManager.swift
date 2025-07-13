import Foundation
import SwiftUI
import Combine

/// 賓果遊戲狀態管理器 - 負責所有遊戲邏輯和狀態管理
@MainActor
class BingoGameStateManager: ObservableObject {
    
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
    
    private let timerManager: TimerManager
    private let networkManager: BingoNetworkManager
    
    // MARK: - Private Properties
    
    private var gameWinCallbacks: [(String, Int) -> Void] = []
    private var drawnNumbersSet: Set<Int> = []
    private let totalNumbers = 99  // 1-99 (原始設計)
    
    // MARK: - Initialization
    
    init(timerManager: TimerManager, networkManager: BingoNetworkManager) {
        print("🎮 BingoGameStateManager: 開始初始化")
        
        self.timerManager = timerManager
        self.networkManager = networkManager
        
        // 【FIX】添加初始化狀態跟蹤
        Task { @MainActor in
            await self.performInitialStateSetup()
        }
    }
    
    /// 【NEW】執行初始狀態設置，避免阻塞主初始化
    private func performInitialStateSetup() async {
        print("🎮 BingoGameStateManager: 執行初始狀態設置")
        
        // 設置初始遊戲狀態
        gameState = .waitingForPlayers
        
        print("🎮 BingoGameStateManager: 初始狀態設置完成")
    }
    
    // MARK: - Game Lifecycle
    
    /// 開始遊戲
    func startGame() {
        print("🎮 BingoGameStateManager: 開始遊戲")
        
        gameState = .playing
        countdown = 3
        gameWon = false
        drawnNumbers = []
        drawnNumbersSet = []
        currentNumber = nil
        
        // 生成賓果卡
        generateBingoCard()
        
        // 開始倒數計時 (倒數結束後進入手動抽號模式)
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
        timerManager.scheduleOnce(id: "game.restart.delay", delay: 2.0) { [weak self] in
            self?.startGame()
        }
        
        // 廣播重新開始
        let restartData = "game_restart".data(using: .utf8) ?? Data()
        networkManager.broadcastGameMessage(.gameRestart, data: restartData)
    }
    
    // MARK: - Bingo Card Generation
    
    /// 生成賓果卡片 (1-99 系統)
    func generateBingoCard() {
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
        networkManager.broadcastGameMessage(.numberDraw, data: numberData)
        
        // 檢查是否有玩家獲勝
        checkWinCondition()
    }
    
    /// 【廢棄】自動抽號 (舊版本，現在不使用)
    private func startDrawing() {
        print("🎮 BingoGameStateManager: 【廢棄】自動抽號功能")
        // 此功能已廢棄，改為手動抽號
    }
    
    /// 【廢棄】抽取下一個號碼 (舊版本，現在不使用)
    private func drawNextNumber() {
        print("🎮 BingoGameStateManager: 【廢棄】自動抽號功能")
        // 此功能已廢棄，改為手動抽號
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
        checkWinCondition()
        
        // 廣播玩家進度
        let progressData = createProgressData()
        networkManager.broadcastGameMessage(.playerProgress, data: progressData)
    }
    
    // MARK: - Win Condition
    
    /// 檢查獲勝條件
    private func checkWinCondition() {
        guard let card = bingoCard else { return }
        
        let lines = checkBingoLines(card: card)
        completedLines = lines
        
        if lines > 0 && !gameWon {
            gameWon = true
            print("🎉 BingoGameStateManager: 獲勝！完成 \(lines) 條線")
            
            // 觸發獲勝回調
            for callback in gameWinCallbacks {
                callback("current_player", lines)
            }
            
            // 廣播獲勝
            broadcastWin(lines: lines)
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
        networkManager.broadcastGameMessage(.gameWin, data: winData)
    }
    
    // MARK: - Message Handling
    
    /// 處理號碼抽出消息
    func handleNumberDrawn(_ number: Int) {
        print("🎮 BingoGameStateManager: 處理號碼抽出 \(number)")
        
        currentNumber = number
        if !drawnNumbers.contains(number) {
            drawnNumbers.append(number)
            drawnNumbersSet.insert(number)
        }
        
        // 更新賓果卡上該號碼的drawn狀態（顯示為藍色）
        if var card = bingoCard {
            for i in 0..<card.numbers.count {
                if card.numbers[i] == number {
                    card.drawn[i] = true
                    print("✅ BingoGameStateManager: 號碼 \(number) 在位置 \(i) 標記為已抽中")
                }
            }
            bingoCard = card
        }
    }
    
    /// 處理遊戲開始消息
    func handleGameStart() {
        print("🎮 BingoGameStateManager: 處理遊戲開始消息")
        
        gameState = .playing
        generateBingoCard()
        startDrawing()
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
        
        timerManager.scheduleOnce(id: "game.restart.handle", delay: 1.0) { [weak self] in
            self?.startGame()
        }
    }
    
    // MARK: - Countdown
    
    /// 開始倒數計時
    private func startCountdown() {
        timerManager.scheduleRepeating(id: TimerManager.TimerID.gameCountdown, interval: 1.0) { [weak self] in
            guard let self = self else { return }
            
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.timerManager.cancelTimer(id: TimerManager.TimerID.gameCountdown)
                // 【重要修復】移除自動抽號，改為手動抽號模式
                print("🎮 BingoGameStateManager: 倒數結束，現在進入手動抽號模式")
                self.gameState = .playing
            }
        }
    }
    
    // MARK: - Timer Management
    
    /// 停止所有計時器
    private func stopAllTimers() {
        timerManager.cancelTimer(id: TimerManager.TimerID.gameCountdown)
        timerManager.cancelTimer(id: TimerManager.TimerID.gameDraw)
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
    
    // MARK: - Callbacks
    
    /// 註冊獲勝回調
    func onGameWon(_ callback: @escaping (String, Int) -> Void) {
        gameWinCallbacks.append(callback)
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