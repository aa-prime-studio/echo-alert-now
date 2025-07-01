import SwiftUI
import Foundation

struct GameView: View {
    @State private var currentRoom: BingoRoom?
    @State private var leaderboard: [BingoScore] = []
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    // 持久化存儲鍵
    private let leaderboardKey = "SignalAir_Rescue_BingoLeaderboard"
    
    // 3個賓果房間
    private let rooms: [BingoRoom] = [
        BingoRoom(id: 1, name: "room A", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 2, name: "room B", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 3, name: "room C", players: [], currentNumbers: [], isActive: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section - 與 Signal 頁面相同高度和樣式
            headerSection
            Divider()
            
            // Content Section - 確保可以滑動，使用 Spacer() 佔用剩餘空間
            if let room = currentRoom {
                BingoGameView(room: room, onLeaveRoom: { currentRoom = nil }, onGameWon: { deviceName, score in
                    addGameResult(deviceName: deviceName, score: score)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoomListView(
                    rooms: rooms,
                    leaderboard: leaderboard,
                    onJoinRoom: { room in
                        currentRoom = room
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            setupLeaderboard()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bingo\nGame Room")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475)) // #ffec79
                
                if let room = currentRoom {
                    Text("\(languageService.t("playing_in")) \(room.name.uppercased())")
                        .font(.caption)
                        .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475).opacity(0.8))
                }
            }
            Spacer()
            
            if currentRoom != nil {
                Button(languageService.t("leave")) {
                    currentRoom = nil
                }
                .font(.headline)
                .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475)) // #ffec79
            }
        }
        .padding()
        .background(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
    }
    
    private func setupLeaderboard() {
        loadLeaderboardFromStorage()
    }
    
    // MARK: - 排行榜數據管理
    
    /// 從本地存儲讀取排行榜數據
    private func loadLeaderboardFromStorage() {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let savedLeaderboard = try? JSONDecoder().decode([BingoScore].self, from: data) {
            // 過濾今日數據
            let today = getTodayString()
            leaderboard = savedLeaderboard
                .filter { $0.date == today }
                .sorted { $0.score > $1.score }
                .prefix(10) // 最多顯示前10名
                .map { $0 }
        } else {
            leaderboard = []
        }
    }
    
    /// 保存排行榜數據到本地存儲
    private func saveLeaderboardToStorage() {
        if let encoded = try? JSONEncoder().encode(leaderboard) {
            UserDefaults.standard.set(encoded, forKey: leaderboardKey)
        }
    }
    
    /// 添加新的遊戲記錄到排行榜
    func addGameResult(deviceName: String, score: Int) {
        let today = getTodayString()
        let newScore = BingoScore(
            deviceName: deviceName,
            score: score,
            timestamp: Date().timeIntervalSince1970,
            date: today
        )
        
        // 讀取完整的歷史數據
        var allScores: [BingoScore] = []
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let savedScores = try? JSONDecoder().decode([BingoScore].self, from: data) {
            allScores = savedScores
        }
        
        // 添加新記錄
        allScores.append(newScore)
        
        // 保存完整歷史數據
        if let encoded = try? JSONEncoder().encode(allScores) {
            UserDefaults.standard.set(encoded, forKey: leaderboardKey)
        }
        
        // 更新今日排行榜顯示
        loadLeaderboardFromStorage()
    }
    
    /// 獲取今日日期字串
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Room List View (第一層)
struct RoomListView: View {
    let rooms: [BingoRoom]
    let leaderboard: [BingoScore]
    let onJoinRoom: (BingoRoom) -> Void
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Room Selector
                RoomSelectorView(rooms: rooms, onJoinRoom: onJoinRoom)
                
                // Game Rules
                GameRulesView()
                
                // Leaderboard
                LeaderboardView(leaderboard: leaderboard)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Bingo Game View (第二層)
struct BingoGameView: View {
    let room: BingoRoom
    let onLeaveRoom: () -> Void
    let onGameWon: (String, Int) -> Void
    
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @StateObject private var gameViewModel: BingoGameViewModel
    
    init(room: BingoRoom, onLeaveRoom: @escaping () -> Void, onGameWon: @escaping (String, Int) -> Void) {
        self.room = room
        self.onLeaveRoom = onLeaveRoom
        self.onGameWon = onGameWon
        self._gameViewModel = StateObject(wrappedValue: BingoGameViewModel(languageService: LanguageService()))
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 20) {
                // Game Status Info
                VStack(spacing: 8) {
                    // 房間狀態和人數
                    HStack {
                        Text("\(languageService.t("room_status"))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        switch gameViewModel.gameState {
                        case .waitingForPlayers:
                            Text("\(languageService.t("waiting_players")) (\(gameViewModel.roomPlayers.count)/6\(languageService.t("people")), \(languageService.t("needs_2_to_start")))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        case .countdown:
                            Text("\(languageService.t("ready_to_start")) (\(gameViewModel.countdown)\(languageService.t("seconds")))")
                                .font(.headline)
                                .foregroundColor(.blue)
                        case .playing:
                            Text("\(languageService.t("game_in_progress")) (\(gameViewModel.roomPlayers.count)/6\(languageService.t("people")))")
                                .font(.headline)
                                .foregroundColor(.green)
                        case .finished:
                            Text(languageService.t("game_finished"))
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // 個人遊戲狀態
                    if gameViewModel.gameState == .playing {
                        HStack {
                            Text("\(languageService.t("completed_lines")): \(gameViewModel.completedLines)/5")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if gameViewModel.gameWon {
                                Text(languageService.t("won"))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal)
                
                // Player List
                PlayerListView(players: gameViewModel.roomPlayers.map { player in
                    RoomPlayer(name: player.name, completedLines: player.completedLines, hasWon: player.hasWon)
                }, deviceName: gameViewModel.deviceName)
                
                // Drawn Numbers Display
                DrawnNumbersView(drawnNumbers: gameViewModel.drawnNumbers)
                
                // Bingo Card - 完整對齊 React 版本
                if let bingoCard = gameViewModel.bingoCard {
                    BingoCardView(
                        bingoCard: bingoCard,
                        drawnNumbers: gameViewModel.drawnNumbers,
                        gameWon: gameViewModel.gameWon,
                        onMarkNumber: gameViewModel.markNumber
                    )
                }
                
                // Room Chat - 放在最下方，可以滑動到這裡
                RoomChatView(
                    roomName: room.name,
                    messages: gameViewModel.roomChatMessages,
                    newMessage: gameViewModel.newChatMessage,
                    onMessageChange: { gameViewModel.newChatMessage = $0 },
                    onSendMessage: gameViewModel.sendRoomChatMessage
                )
                .frame(minHeight: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            gameViewModel.joinGameRoom(room.id.description)
            // 設置遊戲獲勝回調
            gameViewModel.onGameWon = { deviceName, score in
                onGameWon(deviceName, score)
            }
        }
        .onDisappear {
            gameViewModel.leaveGameRoom()
        }
    }
}

#Preview {
    GameView()
}
