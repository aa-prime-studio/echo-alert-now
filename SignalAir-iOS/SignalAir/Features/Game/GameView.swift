import SwiftUI

struct GameView: View {
    @State private var currentRoom: BingoRoom?
    @State private var leaderboard: [BingoScore] = []
    @EnvironmentObject var languageService: LanguageService
    
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
                BingoGameView(room: room) {
                    currentRoom = nil
                }
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
                Text(currentRoom != nil ? "Bingo Game\nRoom" : "Bingo Game\nRoom")
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
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        leaderboard = [
            BingoScore(deviceName: "BingoMaster", score: 6, timestamp: Date().timeIntervalSince1970 - 300, date: todayString),
            BingoScore(deviceName: "LineHunter", score: 5, timestamp: Date().timeIntervalSince1970 - 600, date: todayString),
            BingoScore(deviceName: "NumberWiz", score: 4, timestamp: Date().timeIntervalSince1970 - 900, date: todayString),
            BingoScore(deviceName: "LuckyPlayer", score: 3, timestamp: Date().timeIntervalSince1970 - 1200, date: todayString)
        ]
    }
}

// MARK: - Room List View (第一層)
struct RoomListView: View {
    let rooms: [BingoRoom]
    let leaderboard: [BingoScore]
    let onJoinRoom: (BingoRoom) -> Void
    
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
    
    @StateObject private var gameViewModel = BingoGameViewModel()
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    
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
                            Text("\(languageService.t("waiting_players")) (\(gameViewModel.roomPlayers.count)/6\(languageService.t("people")), \(languageService.t("needs_4_to_start")))")
                                .font(.headline)
                                .foregroundColor(.orange)
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
                            Text("\(languageService.t("completed_lines")): \(gameViewModel.completedLines)/6")
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
                PlayerListView(players: gameViewModel.roomPlayers, deviceName: gameViewModel.deviceName)
                
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
            gameViewModel.joinRoom(room)
        }
        .onDisappear {
            gameViewModel.leaveRoom()
        }
    }
}

#Preview {
    GameView()
}
