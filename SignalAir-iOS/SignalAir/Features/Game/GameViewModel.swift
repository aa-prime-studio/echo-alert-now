import Foundation
import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentRoomID: Int = -1
    @Published var roomPlayerCounts: [Int: Int] = [1: 0, 2: 0, 3: 0]
    @Published var leaderboard: [BingoScore] = []
    @Published var interactionCount = 0
    @Published var reactionTimes: [Double] = []
    
    // MARK: - Dependencies
    private let bingoViewModel: BingoGameViewModel
    private let languageService: LanguageService
    private let nicknameService: NicknameService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let leaderboardKey = "SignalAir_Rescue_BingoLeaderboard"
    private let weeklyLeaderboardPrefix = "SignalAir_WeeklyLeaderboard_"
    
    // MARK: - Room Data
    private let baseRooms: [BingoRoom] = [
        BingoRoom(id: 1, name: "room A", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 2, name: "room B", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 3, name: "room C", players: [], currentNumbers: [], isActive: false)
    ]
    
    var rooms: [BingoRoom] {
        return baseRooms.map { room in
            let playerCount = roomPlayerCounts[room.id] ?? 0
            let playerNames = Array(repeating: "Player", count: playerCount)
            return BingoRoom(
                id: room.id,
                name: room.name,
                players: playerNames,
                currentNumbers: room.currentNumbers,
                isActive: playerCount > 0
            )
        }
    }
    
    // MARK: - Computed Properties
    var isInGameRoom: Bool {
        return currentRoomID > 0
    }
    
    var roomPlayers: [RoomPlayer] {
        return bingoViewModel.roomPlayers.map { playerState in
            RoomPlayer(
                name: playerState.name,
                playerID: playerState.playerID,
                completedLines: playerState.completedLines,
                hasWon: playerState.hasWon
            )
        }
    }
    
    var currentRoomLetter: String {
        switch currentRoomID {
        case 1: return "A"
        case 2: return "B"
        case 3: return "C"
        default: return "\(currentRoomID)"
        }
    }
    
    // MARK: - Initialization
    init(bingoViewModel: BingoGameViewModel, languageService: LanguageService, nicknameService: NicknameService) {
        self.bingoViewModel = bingoViewModel
        self.languageService = languageService
        self.nicknameService = nicknameService
        
        setupBindings()
        setupLeaderboard()
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // 監聽房間玩家數量變化
        bingoViewModel.$roomPlayers
            .map { $0.count }
            .sink { [weak self] count in
                guard let self = self, self.currentRoomID > 0 else { return }
                self.roomPlayerCounts[self.currentRoomID] = count
            }
            .store(in: &cancellables)
    }
    
    private func setupLeaderboard() {
        loadLeaderboardFromStorage()
        checkAndResetWeeklyLeaderboard()
    }
    
    // MARK: - Room Management
    func joinRoom(_ room: BingoRoom) {
        currentRoomID = room.id
        bingoViewModel.joinRoom("\(room.id)")
    }
    
    func leaveRoom() {
        if bingoViewModel.gameWon {
            addGameResult(deviceName: bingoViewModel.deviceName, score: bingoViewModel.completedLines)
            saveInteractionStats()
        }
        roomPlayerCounts[currentRoomID] = 0
        currentRoomID = -1
    }
    
    // MARK: - Game Actions
    func markNumber(_ number: Int) {
        bingoViewModel.markNumber(number)
        incrementInteraction()
    }
    
    func sendChatMessage() {
        bingoViewModel.sendChatMessage()
        incrementInteraction()
    }
    
    func sendEmote(_ emote: EmoteType) {
        bingoViewModel.sendEmote(emote)
        incrementInteraction()
    }
    
    // MARK: - Emote Publisher Access
    var emotePublisher: AnyPublisher<EmoteEvent, Never> {
        bingoViewModel.emotePublisher
    }
    
    func recordReactionTime(_ time: Double) {
        reactionTimes.append(time)
    }
    
    private func incrementInteraction() {
        interactionCount += 1
    }
    
    // MARK: - Leaderboard Management
    private func addGameResult(deviceName: String, score: Int) {
        let today = getTodayString()
        let newScore = BingoScore(
            deviceName: deviceName,
            score: score,
            timestamp: Date().timeIntervalSince1970,
            date: today
        )
        
        var allScores: [BingoScore] = []
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let savedScores = try? JSONDecoder().decode([BingoScore].self, from: data) {
            allScores = savedScores
        }
        
        allScores.append(newScore)
        
        if let encoded = try? JSONEncoder().encode(allScores) {
            UserDefaults.standard.set(encoded, forKey: leaderboardKey)
        }
        
        loadLeaderboardFromStorage()
    }
    
    private func loadLeaderboardFromStorage() {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let savedLeaderboard = try? JSONDecoder().decode([BingoScore].self, from: data) {
            let today = getTodayString()
            leaderboard = savedLeaderboard
                .filter { $0.date == today }
                .sorted { $0.score > $1.score }
                .prefix(10)
                .map { $0 }
        } else {
            leaderboard = []
        }
    }
    
    private func saveInteractionStats() {
        UserDefaults.standard.set(interactionCount, forKey: "InteractionCount")
        
        if let encoded = try? JSONEncoder().encode(reactionTimes) {
            UserDefaults.standard.set(encoded, forKey: "ReactionTimes")
        }
        
        print("📊 統計數據已保存: 互動次數=\(interactionCount), 反應時間記錄=\(reactionTimes.count)筆")
    }
    
    private func checkAndResetWeeklyLeaderboard() {
        let lastResetKey = "SignalAir_LastWeeklyReset"
        let currentWeekStart = getThisWeekMonday()
        let currentWeekTimestamp = Int(currentWeekStart.timeIntervalSince1970)
        
        let lastResetTimestamp = UserDefaults.standard.integer(forKey: lastResetKey)
        
        if lastResetTimestamp != currentWeekTimestamp {
            print("🗓️ 檢測到新週，重置本週排行榜")
            clearOldWeeklyLeaderboards()
            UserDefaults.standard.set(currentWeekTimestamp, forKey: lastResetKey)
            print("✅ 本週排行榜重置完成")
        }
    }
    
    private func clearOldWeeklyLeaderboards() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let weeklyKeys = allKeys.filter { $0.hasPrefix(weeklyLeaderboardPrefix) }
        
        let currentWeekStart = getThisWeekMonday()
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart) ?? currentWeekStart
        let cutoffTimestamp = Int(fourWeeksAgo.timeIntervalSince1970)
        
        for key in weeklyKeys {
            let weekString = String(key.dropFirst(weeklyLeaderboardPrefix.count))
            if let weekTimestamp = Int(weekString), weekTimestamp < cutoffTimestamp {
                UserDefaults.standard.removeObject(forKey: key)
                print("🗑️ 清除舊週排行榜: \(key)")
            }
        }
    }
    
    private func getThisWeekMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        let daysToMonday = (weekday == 1) ? -6 : (2 - weekday)
        
        return calendar.date(byAdding: .day, value: daysToMonday, to: today) ?? today
    }
    
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - ViewModel Access
extension GameViewModel {
    var bingoCard: BingoCard? {
        return bingoViewModel.bingoCard
    }
    
    var drawnNumbers: Set<Int> {
        return Set(bingoViewModel.drawnNumbers)
    }
    
    var gameWon: Bool {
        return bingoViewModel.gameWon
    }
    
    var roomChatMessages: [RoomChatMessage] {
        return bingoViewModel.roomChatMessages
    }
    
    var newChatMessage: String {
        get { bingoViewModel.newChatMessage }
        set { bingoViewModel.newChatMessage = newValue }
    }
    
    var deviceName: String {
        return bingoViewModel.deviceName
    }
}