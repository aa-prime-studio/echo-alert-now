import Foundation
import SwiftUI

class BingoGameViewModel: ObservableObject {
    @Published var bingoCard: BingoCard?
    @Published var drawnNumbers: [Int] = []
    @Published var completedLines: Int = 0
    @Published var gameWon: Bool = false
    @Published var roomPlayers: [RoomPlayer] = []
    @Published var roomChatMessages: [RoomChatMessage] = []
    @Published var newChatMessage: String = ""
    @Published var gameState: GameState = .waitingForPlayers
    @Published var countdown: Int = 0
    
    let deviceName = UIDevice.current.name
    private var drawTimer: Timer?
    private var simulationTimer: Timer?
    private var countdownTimer: Timer?
    private var playerCheckTimer: Timer?
    
    enum GameState {
        case waitingForPlayers  // 等待玩家加入 (需要4人)
        case countdown         // 倒數準備開始 (10秒倒數)
        case playing          // 遊戲進行中
        case finished         // 遊戲結束
    }
    
    func joinRoom(_ room: BingoRoom) {
        // Generate new bingo card
        bingoCard = generateBingoCard()
        
        // Reset game state
        drawnNumbers = []
        completedLines = 0
        gameWon = false
        roomChatMessages = []
        newChatMessage = ""
        gameState = .waitingForPlayers
        countdown = 0
        
        // Generate room players (including self)
        roomPlayers = generateRoomPlayers()
        
        // Start checking player count
        startPlayerCountCheck()
    }
    
    func leaveRoom() {
        drawTimer?.invalidate()
        simulationTimer?.invalidate()
        countdownTimer?.invalidate()
        playerCheckTimer?.invalidate()
        
        bingoCard = nil
        drawnNumbers = []
        completedLines = 0
        gameWon = false
        roomPlayers = []
        roomChatMessages = []
        newChatMessage = ""
        gameState = .waitingForPlayers
        countdown = 0
    }
    
    private func generateBingoCard() -> BingoCard {
        var numbers: [Int] = []
        var used = Set<Int>()
        
        // Generate 25 unique numbers from 1-60
        while numbers.count < 25 {
            let num = Int.random(in: 1...60)
            if !used.contains(num) {
                used.insert(num)
                numbers.append(num)
            }
        }
        
        return BingoCard(numbers: numbers)
    }
    
    private func generateRoomPlayers() -> [RoomPlayer] {
        let playerNames = ["BingoKing", "LuckyStrike", "NumberHunter", "LineChaser", "BingoMaster"]
        
        // 模擬其他玩家加入房間 (1-5個其他玩家，總共最多6人)
        let otherPlayersCount = Int.random(in: 1...5)
        var players = playerNames.prefix(otherPlayersCount).map { name in
            RoomPlayer(name: name)
        }
        
        // Add self
        players.append(RoomPlayer(name: deviceName))
        
        return players
    }
    
    private func startPlayerCountCheck() {
        playerCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPlayerCount()
        }
        
        // 模擬玩家逐漸加入
        simulatePlayersJoining()
    }
    
    private func simulatePlayersJoining() {
        // 每3-5秒隨機增加一個玩家，直到達到6人滿房
        guard roomPlayers.count < 6 else { return }
        
        let delay = Double.random(in: 3...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.addRandomPlayer()
            self.simulatePlayersJoining()
        }
    }
    
    private func addRandomPlayer() {
        guard roomPlayers.count < 6, gameState == .waitingForPlayers else { return }
        
        let availableNames = ["BingoKing", "LuckyStrike", "NumberHunter", "LineChaser", "BingoMaster", "WinnerTaker"]
        let usedNames = Set(roomPlayers.map { $0.name })
        let availableNewNames = availableNames.filter { !usedNames.contains($0) }
        
        guard let newName = availableNewNames.randomElement() else { return }
        
        let newPlayer = RoomPlayer(name: newName)
        roomPlayers.append(newPlayer)
        
        // 添加系統訊息通知新玩家加入
        let joinMessage = RoomChatMessage(
            message: "\(newName) 加入了房間！",
            playerName: "系統",
            timestamp: Date().timeIntervalSince1970,
            isOwn: false
        )
        roomChatMessages.insert(joinMessage, at: 0)
    }
    
    private func checkPlayerCount() {
        let playerCount = roomPlayers.count
        
        switch gameState {
        case .waitingForPlayers:
            if playerCount >= 4 {
                // 4人及以上可以開始遊戲，開始倒數
                startCountdown()
            }
        case .countdown:
            // 倒數期間，如果人數不足4人，回到等待狀態
            if playerCount < 4 {
                gameState = .waitingForPlayers
                countdown = 0
                countdownTimer?.invalidate()
            }
        case .playing, .finished:
            break // 遊戲中或結束時不檢查人數
        }
    }
    
    private func startCountdown() {
        guard gameState == .waitingForPlayers else { return }
        
        playerCheckTimer?.invalidate()
        gameState = .countdown
        countdown = 10
        
        // 添加倒數開始訊息
        let countdownMessage = RoomChatMessage(
            message: "人數已達4人！遊戲將在10秒後開始...",
            playerName: "系統",
            timestamp: Date().timeIntervalSince1970,
            isOwn: false
        )
        roomChatMessages.insert(countdownMessage, at: 0)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        countdown -= 1
        
        if countdown <= 0 {
            countdownTimer?.invalidate()
            startGame()
        } else if countdown <= 3 {
            // 最後3秒倒數提醒
            let countdownMessage = RoomChatMessage(
                message: "遊戲開始倒數：\(countdown)",
                playerName: "系統",
                timestamp: Date().timeIntervalSince1970,
                isOwn: false
            )
            roomChatMessages.insert(countdownMessage, at: 0)
        }
    }
    
    private func startGame() {
        gameState = .playing
        
        // 添加遊戲開始訊息
        let startMessage = RoomChatMessage(
            message: "🎯 遊戲開始！祝大家好運！",
            playerName: "系統",
            timestamp: Date().timeIntervalSince1970,
            isOwn: false
        )
        roomChatMessages.insert(startMessage, at: 0)
        
        // 開始抽號碼
        startDrawingNumbers()
    }
    
    private func startDrawingNumbers() {
        guard gameState == .playing else { return }
        
        drawTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            self.drawNextNumber()
        }
        
        // Start player simulation
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.simulateOtherPlayersProgress()
        }
        
        // Stop after 3 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
            self.finishGame()
        }
    }
    
    private func finishGame() {
        drawTimer?.invalidate()
        simulationTimer?.invalidate()
        gameState = .finished
        
        // 添加遊戲結束訊息
        let endMessage = RoomChatMessage(
            message: "⏰ 遊戲時間結束！",
            playerName: "系統",
            timestamp: Date().timeIntervalSince1970,
            isOwn: false
        )
        roomChatMessages.insert(endMessage, at: 0)
    }
    
    private func drawNextNumber() {
        let availableNumbers = Array(1...60).filter { !drawnNumbers.contains($0) }
        
        guard !availableNumbers.isEmpty else {
            drawTimer?.invalidate()
            return
        }
        
        let newNumber = availableNumbers.randomElement()!
        drawnNumbers.append(newNumber)
    }
    
    private func simulateOtherPlayersProgress() {
        roomPlayers = roomPlayers.map { player in
            if player.name == deviceName || player.hasWon {
                return player
            }
            
            // Random chance to increase lines
            if Double.random(in: 0...1) < 0.3 {
                let newLines = player.completedLines + 1
                let hasWon = newLines >= 6
                
                var updatedPlayer = player
                updatedPlayer.completedLines = newLines
                updatedPlayer.hasWon = hasWon
                
                return updatedPlayer
            }
            
            return player
        }
    }
    
    func markNumber(at index: Int) {
        guard let card = bingoCard, !gameWon else { return }
        
        let number = card.numbers[index]
        guard drawnNumbers.contains(number) && !card.marked[index] else { return }
        
        // Mark the number
        var newCard = card
        newCard.marked[index] = true
        bingoCard = newCard
        
        // Check completed lines
        let lines = checkCompletedLines(newCard.marked)
        completedLines = lines
        
        // Update self in players list
        roomPlayers = roomPlayers.map { player in
            if player.name == deviceName {
                var updatedPlayer = player
                updatedPlayer.completedLines = lines
                updatedPlayer.hasWon = lines >= 6
                return updatedPlayer
            }
            return player
        }
        
        // Check for win
        if lines >= 6 && !gameWon {
            gameWon = true
            // Could add win notification here
        }
    }
    
    private func checkCompletedLines(_ marked: [Bool]) -> Int {
        var lines = 0
        
        // Check horizontal lines
        for row in 0..<5 {
            let start = row * 5
            let end = start + 5
            if marked[start..<end].allSatisfy({ $0 }) {
                lines += 1
            }
        }
        
        // Check vertical lines
        for col in 0..<5 {
            let indices = (0..<5).map { row in row * 5 + col }
            if indices.allSatisfy({ marked[$0] }) {
                lines += 1
            }
        }
        
        // Check diagonal lines
        let diagonal1 = [0, 6, 12, 18, 24]
        if diagonal1.allSatisfy({ marked[$0] }) {
            lines += 1
        }
        
        let diagonal2 = [4, 8, 12, 16, 20]
        if diagonal2.allSatisfy({ marked[$0] }) {
            lines += 1
        }
        
        return lines
    }
    
    func sendRoomChatMessage() {
        guard !newChatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = RoomChatMessage(
            message: newChatMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            playerName: deviceName,
            timestamp: Date().timeIntervalSince1970,
            isOwn: true
        )
        
        roomChatMessages.insert(message, at: 0)
        if roomChatMessages.count > 30 {
            roomChatMessages = Array(roomChatMessages.prefix(30))
        }
        
        newChatMessage = ""
    }
    

} 