import SwiftUI
import Foundation

struct GameView: View {
    @State private var currentRoom: BingoRoom?
    @State private var leaderboard: [BingoScore] = []
    @State private var roomPlayerCounts: [Int: Int] = [1: 0, 2: 0, 3: 0] // 房間ID到玩家數量的映射
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    // 持久化存儲鍵
    private let leaderboardKey = "SignalAir_Rescue_BingoLeaderboard"
    
    // 3個賓果房間 - 基礎結構
    private let baseRooms: [BingoRoom] = [
        BingoRoom(id: 1, name: "room A", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 2, name: "room B", players: [], currentNumbers: [], isActive: false),
        BingoRoom(id: 3, name: "room C", players: [], currentNumbers: [], isActive: false)
    ]
    
    // 動態更新玩家數量的房間
    private var rooms: [BingoRoom] {
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section - 與 Signal 頁面相同高度和樣式
            headerSection
            Divider()
            
            // Content Section - 確保可以滑動，使用 Spacer() 佔用剩餘空間
            if let room = currentRoom {
                BingoGameView(
                    room: room, 
                    onLeaveRoom: { 
                        // 當離開房間時，重置該房間的玩家數量
                        roomPlayerCounts[room.id] = 0
                        currentRoom = nil 
                    }, 
                    onGameWon: { deviceName, score in
                        addGameResult(deviceName: deviceName, score: score)
                        // 遊戲結束後自動退出房間回到第一層
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            currentRoom = nil
                        }
                    },
                    onPlayerCountChanged: { roomId, playerCount in
                        roomPlayerCounts[roomId] = playerCount
                    }
                )
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
            startRoomMonitoring()
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
    
    private func startRoomMonitoring() {
        // 監聽來自其他房間的玩家數量廣播
        // 這裡可以添加網路監聽邏輯，暫時使用定時器模擬
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // 實際實現時這裡會監聽網路廣播
            // 暫時保持現有邏輯
        }
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
    let onPlayerCountChanged: (Int, Int) -> Void
    
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @StateObject private var gameViewModel: BingoGameViewModel
    @State private var showEmoteText = false
    @State private var emoteText = ""
    @State private var isPureEmoji = false
    
    init(room: BingoRoom, onLeaveRoom: @escaping () -> Void, onGameWon: @escaping (String, Int) -> Void, onPlayerCountChanged: @escaping (Int, Int) -> Void) {
        self.room = room
        self.onLeaveRoom = onLeaveRoom
        self.onGameWon = onGameWon
        self.onPlayerCountChanged = onPlayerCountChanged
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(languageService.t("waiting_players")) (\(gameViewModel.roomPlayers.count)/6\(languageService.t("people")))")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(languageService.t("needs_2_to_start"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        case .countdown:
                            Text("\(languageService.t("ready_to_start")) (\(gameViewModel.countdown)\(languageService.t("seconds")))")
                                .font(.headline)
                                .foregroundColor(.blue)
                        case .playing:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(languageService.t("game_in_progress")) (\(gameViewModel.roomPlayers.count)/6\(languageService.t("people")))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                if gameViewModel.roomPlayers.count < 6 {
                                    Text("可繼續加入至滿房")
                                        .font(.caption)
                                        .foregroundColor(.green.opacity(0.8))
                                }
                            }
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
                
                // Emote Buttons - 互動按鈕
                EmoteButtonsView(gameViewModel: gameViewModel)
                
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
            // 使用房間ID作為遊戲房間ID，先嘗試加入，如果沒有主機則成為主機
            gameViewModel.attemptToJoinOrCreateRoom(roomID: room.id.description)
            
            // 設置遊戲獲勝回調
            gameViewModel.onGameWon = { deviceName, score in
                onGameWon(deviceName, score)
            }
        }
        .onDisappear {
            gameViewModel.leaveGameRoom()
        }
        .onReceive(gameViewModel.$roomPlayers) { players in
            // 當房間玩家數量變化時，更新父視圖
            onPlayerCountChanged(room.id, players.count)
        }
        .overlay(
            Group {
                if showEmoteText {
                    if isPureEmoji {
                        // 純emoji：大emoji在賓果卡正中央，暱稱在上方
                        VStack(spacing: 8) {
                            // 暱稱顯示在上方
                            Text(getNicknameFromEmoteText(emoteText))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894))
                            
                            // 超大emoji在中央
                            Text(getEmojiFromEmoteText(emoteText))
                                .font(.system(size: 120)) // 500%放大
                        }
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showEmoteText = false }
                            }
                        }
                    } else {
                        // 文字廣播：分成兩行邏輯跟emoji一樣
                        VStack(spacing: 8) {
                            // 暱稱顯示在上方
                            Text(getNicknameFromEmoteText(emoteText))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894))
                            
                            // 文字內容在下方
                            Text(getTextContentFromEmoteText(emoteText))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894))
                        }
                        .padding(16)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showEmoteText = false }
                            }
                        }
                    }
                }
            }
        )
        .onReceive(gameViewModel.emotePublisher) { emote in
            emoteText = emote.text
            isPureEmoji = emote.isPureEmoji
            withAnimation { showEmoteText = true }
        }
    }
    
    // 從表情文字中提取暱稱（%@的部分）
    private func getNicknameFromEmoteText(_ text: String) -> String {
        // 假設格式為 "暱稱 emoji"，提取空格前的部分
        let components = text.components(separatedBy: " ")
        return components.first ?? ""
    }
    
    // 從表情文字中提取emoji（最後的emoji部分）
    private func getEmojiFromEmoteText(_ text: String) -> String {
        // 假設格式為 "暱稱 emoji"，提取最後的emoji
        let components = text.components(separatedBy: " ")
        return components.last ?? ""
    }
    
    // 從表情文字中提取文字內容（去除暱稱部分）
    private func getTextContentFromEmoteText(_ text: String) -> String {
        // 假設格式為 "暱稱 文字內容"，提取暱稱後的所有內容
        let components = text.components(separatedBy: " ")
        if components.count > 1 {
            return Array(components.dropFirst()).joined(separator: " ")
        }
        return text
    }
}

#Preview {
    GameView()
}

// MARK: - Emote Buttons View
struct EmoteButtonsView: View {
    @ObservedObject var gameViewModel: BingoGameViewModel
    @EnvironmentObject var languageService: LanguageService
    
    // 所有可用的表情
    private let allEmotes: [EmoteType] = [
        .bingo, .nen, .wow, .boom, .pirate, .rocket, .bug, .fly, .fire, .poop,
        .clown, .mindBlown, .pinch, .cockroach, .eyeRoll, .burger, .rockOn, .battery,
        .dizzy, .bottle, .skull, .mouse, .trophy, .ring, .juggler
    ]
    
    // 網格佈局配置：每行5個按鈕
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("成為player")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(allEmotes, id: \.self) { emote in
                    EmojiButton(
                        emoji: emote.emoji,
                        action: { gameViewModel.sendEmote(emote) }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Emoji Button
struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 24)) // 較大的emoji顯示
                .frame(width: 44, height: 44) // 固定大小的圓形按鈕
                .background(Color.gray.opacity(0.1))
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(22)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Individual Emote Button (保留舊版以防相容性問題)
struct EmoteButton: View {
    let label: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .bold)) // 從16縮小到10 (60%大小)
                .padding(.horizontal, 12) // 從20縮小到12 (60%大小)
                .padding(.vertical, 7) // 從12縮小到7 (60%大小)
                .background(color)
                .foregroundColor(textColor)
                .cornerRadius(15) // 從25縮小到15 (60%大小)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1) // 陰影也縮小
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
