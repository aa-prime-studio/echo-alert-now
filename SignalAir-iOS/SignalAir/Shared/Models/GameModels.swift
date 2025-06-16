import Foundation

// MARK: - Bingo Room
struct BingoRoom: Identifiable, Codable {
    let id: Int
    let name: String
    var players: [RoomPlayer]
    var currentNumbers: [Int]
    var isActive: Bool
}

// MARK: - Bingo Card
struct BingoCard: Codable {
    var numbers: [Int]
    var marked: [Bool]
    
    init() {
        self.numbers = []
        self.marked = Array(repeating: false, count: 25)
    }
    
    init(numbers: [Int]) {
        self.numbers = numbers
        self.marked = Array(repeating: false, count: 25)
    }
}

// MARK: - Bingo Score
struct BingoScore: Identifiable, Codable {
    let id = UUID()
    let deviceName: String
    let score: Int
    let timestamp: TimeInterval
    let date: String
}

// MARK: - Room Player
struct RoomPlayer: Identifiable, Codable {
    let id = UUID()
    let name: String
    var completedLines: Int
    var hasWon: Bool
    
    init(name: String, completedLines: Int = 0, hasWon: Bool = false) {
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
    }
}

// MARK: - Room Chat Message
struct RoomChatMessage: Identifiable, Codable {
    let id = UUID()
    let message: String
    let playerName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    
    var formattedTime: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
