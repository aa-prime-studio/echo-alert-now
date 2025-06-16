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
    
    let deviceName = UIDevice.current.name
    private var drawTimer: Timer?
    private var simulationTimer: Timer?
    
    func joinRoom(_ room: BingoRoom) {
        // Generate new bingo card
        bingoCard = generateBingoCard()
        
        // Reset game state
        drawnNumbers = []
        completedLines = 0
        gameWon = false
        roomChatMessages = []
        newChatMessage = ""
        
        // Generate room players
        roomPlayers = generateRoomPlayers()
        
        // Start drawing numbers after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.startDrawingNumbers()
        }
    }
    
    func leaveRoom() {
        drawTimer?.invalidate()
        simulationTimer?.invalidate()
        
        bingoCard = nil
        drawnNumbers = []
        completedLines = 0
        gameWon = false
        roomPlayers = []
        roomChatMessages = []
        newChatMessage = ""
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
        let randomCount = Int.random(in: 2...4)
        var players = playerNames.prefix(randomCount).map { name in
            RoomPlayer(name: name)
        }
        
        // Add self
        players.append(RoomPlayer(name: deviceName))
        
        return players
    }
    
    private func startDrawingNumbers() {
        drawTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            self.drawNextNumber()
        }
        
        // Start player simulation
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.simulateOtherPlayersProgress()
        }
        
        // Stop after 3 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
            self.drawTimer?.invalidate()
            self.simulationTimer?.invalidate()
        }
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