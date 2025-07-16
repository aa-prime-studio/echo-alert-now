import SwiftUI
import Foundation

struct GameView: View {
    @State private var currentRoomID: Int = -1
    @State private var leaderboard: [BingoScore] = []
    @State private var roomPlayerCounts: [Int: Int] = [1: 0, 2: 0, 3: 0] // 房間ID到玩家數量的映射
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    // 將 ViewModel 提升到父視圖層級，只創建一次
    @StateObject private var bingoViewModel: BingoGameViewModel = ServiceContainer.shared.createBingoGameViewModel()
    
    // 持久化存儲鍵
    private let leaderboardKey = "SignalAir_Rescue_BingoLeaderboard"
    private let weeklyLeaderboardPrefix = "SignalAir_WeeklyLeaderboard_"
    
    // 統計追蹤
    @State private var interactionCount = 0  // DJ榜：互動次數統計
    @State private var reactionTimes: [Double] = []  // 烏龜神：反應時間統計
    
    // Timer 管理
    @State private var roomMonitoringTimer: Timer?
    
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
            if currentRoomID > 0 {
                // 傳遞已存在的 ViewModel，而不是創建新的
                BingoGameView(
                    viewModel: bingoViewModel,
                    currentRoomID: currentRoomID,
                    onLeaveRoom: { 
                        // 當離開房間時，重置該房間的玩家數量並保存統計
                        roomPlayerCounts[currentRoomID] = 0
                        saveInteractionStats()
                        currentRoomID = -1
                    }, 
                    onGameWon: { deviceName, score in
                        addGameResult(deviceName: deviceName, score: score)
                        // 保存統計數據
                        saveInteractionStats()
                    },
                    onPlayerCountChanged: { roomId, playerCount in
                        roomPlayerCounts[roomId] = playerCount
                    },
                    onInteraction: {
                        interactionCount += 1
                    },
                    onReactionTime: { reactionTime in
                        reactionTimes.append(reactionTime)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoomListView(
                    rooms: rooms,
                    leaderboard: leaderboard,
                    onJoinRoom: { room in
                        print("🚨🚨🚨 ROOM SELECTED: id=\(room.id) name=\(room.name) 🚨🚨🚨")
                        DispatchQueue.main.async {
                            currentRoomID = room.id
                            print("🚨🚨🚨 CURRENT ROOM SET ON MAIN THREAD: \(room.id) 🚨🚨🚨")
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            print("🚨🚨🚨 GAME VIEW APPEARED, currentRoomID: \(currentRoomID) 🚨🚨🚨")
            setupLeaderboard()
            startRoomMonitoring()
        }
        .onDisappear {
            // 清理所有 Timer 防止記憶體洩漏
            roomMonitoringTimer?.invalidate()
            roomMonitoringTimer = nil
            print("🧹 GameView: 已清理房間監控 Timer")
        }
        .onChange(of: currentRoomID) { newRoomID in
            print("🚨🚨🚨 CURRENT ROOM CHANGED TO: \(newRoomID) 🚨🚨🚨")
            if newRoomID > 0 {
                print("🚨🚨🚨 SHOULD SHOW BINGO GAME VIEW NOW 🚨🚨🚨")
                // 更新現有 ViewModel 的房間
                bingoViewModel.updateRoom(newRoomID)
            } else {
                print("🚨🚨🚨 SHOULD SHOW ROOM LIST NOW 🚨🚨🚨")
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bingo\nGame Room")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                
                if currentRoomID > 0 {
                    Text("\(languageService.t("playing_in")) room \(currentRoomID)")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.8)) // #263ee4
                }
            }
            Spacer()
            
            if currentRoomID > 0 {
                Button(languageService.t("leave")) {
                    currentRoomID = -1
                }
                .font(.headline)
                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
            }
        }
        .padding()
        .background(.white)
    }
    
    private func setupLeaderboard() {
        loadLeaderboardFromStorage()
    }
    
    private func startRoomMonitoring() {
        // 清理現有 Timer - 完整清理避免記憶體洩漏
        roomMonitoringTimer?.invalidate()
        roomMonitoringTimer = nil
        
        // 監聽來自其他房間的玩家數量廣播 - 安全的 Timer 管理
        roomMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            // 實際實現時這裡會監聽網路廣播
            // 暫時保持現有邏輯
        }
        
        // 檢查是否需要重置本週排行榜
        checkAndResetWeeklyLeaderboard()
    }
    
    /// 檢查並重置本週排行榜（如果跨週了）
    private func checkAndResetWeeklyLeaderboard() {
        let lastResetKey = "SignalAir_LastWeeklyReset"
        let currentWeekStart = getThisWeekMonday()
        let currentWeekTimestamp = Int(currentWeekStart.timeIntervalSince1970)
        
        // 獲取上次重置的週開始時間
        let lastResetTimestamp = UserDefaults.standard.integer(forKey: lastResetKey)
        
        // 如果當前週與上次重置週不同，需要重置
        if lastResetTimestamp != currentWeekTimestamp {
            print("🗓️ 檢測到新週，重置本週排行榜")
            
            // 清除舊的排行榜數據
            clearOldWeeklyLeaderboards()
            
            // 更新最後重置時間
            UserDefaults.standard.set(currentWeekTimestamp, forKey: lastResetKey)
            
            print("✅ 本週排行榜重置完成")
        }
    }
    
    /// 清除舊的本週排行榜數據
    private func clearOldWeeklyLeaderboards() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let weeklyKeys = allKeys.filter { $0.hasPrefix(weeklyLeaderboardPrefix) }
        
        // 計算保留週數（保留最近4週的數據）
        let currentWeekStart = getThisWeekMonday()
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart) ?? currentWeekStart
        let cutoffTimestamp = Int(fourWeeksAgo.timeIntervalSince1970)
        
        for key in weeklyKeys {
            // 從鍵名提取時間戳
            let timestampString = key.replacingOccurrences(of: weeklyLeaderboardPrefix, with: "")
            if let timestamp = Int(timestampString), timestamp < cutoffTimestamp {
                UserDefaults.standard.removeObject(forKey: key)
                print("🗑️ 清除舊排行榜數據: \(key)")
            }
        }
    }
    
    /// 獲取本週一00:00的時間戳
    private func getThisWeekMonday() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 獲取本週一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 週一
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    // MARK: - 排行榜數據管理
    
    /// 從本地存儲讀取週排行榜數據 - 使用二進制協議
    private func loadLeaderboardFromStorage() {
        // 只顯示本週勝場榜作為主要排行榜
        let weekStartTime = getThisWeekMonday()
        let weekKey = "\(weeklyLeaderboardPrefix)\(BinaryGameProtocol.LeaderboardType.wins.rawValue)_\(Int(weekStartTime.timeIntervalSince1970))"
        
        guard let data = UserDefaults.standard.data(forKey: weekKey),
              let (_, _, entries) = BinaryGameProtocol.decodeWeeklyLeaderboard(data) else {
            // 沒有存儲數據時初始化為空
            leaderboard = []
            return
        }
        
        // 將週排行榜條目轉換為 BingoScore 格式以兼容現有UI
        leaderboard = entries.map { entry in
            BingoScore(
                deviceName: entry.nickname,
                score: Int(entry.value), // 勝場數
                timestamp: entry.lastUpdate.timeIntervalSince1970,
                date: getTodayString() // 使用當前日期
            )
        }
        .sorted { $0.score > $1.score }
        .prefix(10) // 最多顯示前10名
        .map { $0 }
        
        print("✅ 成功載入週排行榜數據: \(leaderboard.count) 條記錄")
    }
    
    /// 保存排行榜數據 - 已移除，改用週排行榜二進制協議
    private func saveLeaderboardToStorage() {
        // 此方法已廢棄，週排行榜數據通過 updateWeeklyLeaderboard 方法自動保存
        print("ℹ️ 排行榜數據現在通過週排行榜自動保存")
    }
    
    /// 添加新的遊戲記錄到週排行榜
    func addGameResult(deviceName: String, score: Int) {
        // 只更新本週排行榜（勝場榜）- 使用二進制協議
        updateWeeklyLeaderboard(playerName: deviceName, winCount: 1)
        
        // 重新載入排行榜數據以更新UI顯示
        loadLeaderboardFromStorage()
        
        print("✅ 遊戲結果已添加到週排行榜: \(deviceName) - \(score) 線")
    }
    
    /// 更新本週排行榜數據 - 使用二進制協議
    private func updateWeeklyLeaderboard(playerName: String, winCount: Int) {
        let weekStartTime = getThisWeekMonday()
        let weekKey = "\(weeklyLeaderboardPrefix)\(Int(weekStartTime.timeIntervalSince1970))"
        
        // 獲取當前玩家ID（使用設備名稱作為ID）
        let playerID = nicknameService.nickname
        
        // 讀取現有的本週排行榜數據
        var weeklyWins: [String: Float] = [:]
        
        if let existingData = UserDefaults.standard.data(forKey: weekKey),
           let (_, _, entries) = BinaryGameProtocol.decodeWeeklyLeaderboard(existingData) {
            // 從現有條目中構建映射
            for entry in entries {
                weeklyWins[entry.playerID] = entry.value
            }
        }
        
        // 更新當前玩家的勝場數
        weeklyWins[playerID] = (weeklyWins[playerID] ?? 0) + Float(winCount)
        
        // 轉換為排序的條目列表（只保留前3名）
        let sortedEntries = weeklyWins
            .map { (playerID, wins) in
                BinaryGameProtocol.WeeklyLeaderboardEntry(
                    playerID: playerID,
                    nickname: playerID == self.nicknameService.nickname ? NicknameFormatter.cleanNickname(playerName) : playerID,
                    value: wins,
                    lastUpdate: Date()
                )
            }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0 }
        
        // 編碼為二進制並保存
        let binaryData = BinaryGameProtocol.encodeWeeklyLeaderboard(
            type: .wins,
            entries: sortedEntries,
            weekStartTime: weekStartTime
        )
        
        UserDefaults.standard.set(binaryData, forKey: weekKey)
    }
    
    /// 廣播本週排行榜更新
    private func broadcastWeeklyLeaderboardUpdate(data: Data) {
        // 通過BinaryGameProtocol發送排行榜更新消息
        let gameMessage = BinaryGameProtocol.encodeGameMessage(
            type: .weeklyLeaderboardUpdate,
            senderID: nicknameService.nickname,
            senderName: nicknameService.nickname,
            gameRoomID: "global", // 排行榜是全局的
            data: data
        )
        
        // 通過網路服務廣播排行榜更新
        Task {
            do {
                guard let meshManager = ServiceContainer.shared.meshManager else {
                    print("⚠️ MeshManager 未初始化，無法廣播排行榜更新")
                    return
                }
                
                try await meshManager.broadcast(
                    gameMessage,
                    priority: .normal,
                    userNickname: nicknameService.nickname
                )
                print("✅ 排行榜更新廣播成功: \(data.count) bytes")
            } catch {
                print("❌ 排行榜更新廣播失敗: \(error)")
            }
        }
    }
    
    /// 保存互動統計數據
    private func saveInteractionStats() {
        let playerID = nicknameService.nickname
        
        // 保存DJ榜數據（互動次數）
        if interactionCount > 0 {
            updateWeeklyLeaderboard(
                playerName: playerID,
                value: Float(interactionCount),
                type: .interactions
            )
        }
        
        // 保存烏龜神數據（平均反應時間）
        if !reactionTimes.isEmpty {
            let averageReactionTime = reactionTimes.reduce(0, +) / Double(reactionTimes.count)
            updateWeeklyLeaderboard(
                playerName: playerID,
                value: Float(averageReactionTime),
                type: .reaction
            )
        }
        
        // 重置統計
        interactionCount = 0
        reactionTimes.removeAll()
    }
    
    /// 更新指定類型的本週排行榜數據 - 使用二進制協議
    private func updateWeeklyLeaderboard(playerName: String, value: Float, type: BinaryGameProtocol.LeaderboardType) {
        let weekStartTime = getThisWeekMonday()
        let weekKey = "\(weeklyLeaderboardPrefix)\(type.rawValue)_\(Int(weekStartTime.timeIntervalSince1970))"
        
        let playerID = nicknameService.nickname
        
        // 讀取現有數據
        var playerValues: [String: Float] = [:]
        
        if let existingData = UserDefaults.standard.data(forKey: weekKey),
           let (_, _, entries) = BinaryGameProtocol.decodeWeeklyLeaderboard(existingData) {
            for entry in entries {
                playerValues[entry.playerID] = entry.value
            }
        }
        
        // 更新數據
        if type == .interactions {
            // 互動次數累加
            playerValues[playerID] = (playerValues[playerID] ?? 0) + value
        } else if type == .reaction {
            // 反應時間取平均值
            if let existingValue = playerValues[playerID] {
                playerValues[playerID] = (existingValue + value) / 2.0
            } else {
                playerValues[playerID] = value
            }
        }
        
        // 轉換為排序的條目列表
        let sortedEntries = playerValues
            .map { (playerID, val) in
                BinaryGameProtocol.WeeklyLeaderboardEntry(
                    playerID: playerID,
                    nickname: playerID == self.nicknameService.nickname ? NicknameFormatter.cleanNickname(playerName) : playerID,
                    value: val,
                    lastUpdate: Date()
                )
            }
            .sorted { 
                if type == .reaction {
                    return $0.value > $1.value  // 烏龜神：反應時間越大越好（最慢第一名）
                } else {
                    return $0.value > $1.value  // 其他數值越大越好
                }
            }
            .prefix(3)
            .map { $0 }
        
        // 編碼並保存
        let binaryData = BinaryGameProtocol.encodeWeeklyLeaderboard(
            type: type,
            entries: sortedEntries,
            weekStartTime: weekStartTime
        )
        
        UserDefaults.standard.set(binaryData, forKey: weekKey)
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
    // 使用傳入的 ViewModel，不要創建新的
    @ObservedObject var viewModel: BingoGameViewModel
    let currentRoomID: Int
    let onLeaveRoom: () -> Void
    let onGameWon: (String, Int) -> Void
    let onPlayerCountChanged: (Int, Int) -> Void
    let onInteraction: () -> Void
    let onReactionTime: (Double) -> Void
    
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @State private var showEmoteText = false
    @State private var emoteText = ""
    @State private var isPureEmoji = false
    @State private var showWinnerDisplay = false
    @State private var winnerName = ""
    @State private var winnerScore = 0
    @State private var showCountdown = false
    @State private var countdownNumber = 5
    
    // 移除 init，直接使用傳入的參數
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Debug view to ensure this view is being rendered
                Text("🚨 BINGO GAME VIEW BODY RENDERED: room=\(currentRoomID) 🚨")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top)
                
                // Game Status Info
                VStack(spacing: 8) {
                    // 房間狀態和人數
                    HStack {
                        Text("\(languageService.t("room_status"))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        switch viewModel.gameState {
                        case .waitingForPlayers:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(languageService.t("waiting_players")) (\(viewModel.roomPlayers.count)/6\(languageService.t("people")))")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(languageService.t("needs_2_to_start"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        case .countdown:
                            Text("\(languageService.t("ready_to_start")) (\(viewModel.countdown)\(languageService.t("seconds")))")
                                .font(.headline)
                                .foregroundColor(.blue)
                        case .playing:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(languageService.t("game_in_progress")) (\(viewModel.roomPlayers.count)/6\(languageService.t("people")))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                if viewModel.roomPlayers.count < 6 {
                                    Text(languageService.t("can_join_until_full"))
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
                    if viewModel.gameState == .playing {
                        HStack {
                            Text("\(languageService.t("completed_lines")): \(viewModel.completedLines)/5")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if viewModel.gameWon {
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
                PlayerListView(players: viewModel.roomPlayers.map { player in
                    RoomPlayer(name: player.name, completedLines: player.completedLines, hasWon: player.hasWon)
                }, deviceName: viewModel.deviceName)
                
                // Drawn Numbers Display
                DrawnNumbersView(drawnNumbers: viewModel.drawnNumbers)
                
                // Bingo Card - 完整對齊 React 版本
                if let bingoCard = viewModel.bingoCard {
                    BingoCardView(
                        bingoCard: bingoCard,
                        drawnNumbers: viewModel.drawnNumbers,
                        gameWon: viewModel.gameWon,
                        onMarkNumber: viewModel.markNumber,
                        onReactionTime: onReactionTime
                    )
                }
                
                // Emote Buttons - 互動按鈕
                EmoteButtonsView(
                    viewModel: viewModel,
                    onInteraction: onInteraction
                )
                
                // Room Chat - 放在最下方，可以滑動到這裡
                RoomChatView(
                    roomName: "Room \(currentRoomID)",
                    messages: viewModel.roomChatMessages,
                    newMessage: viewModel.newChatMessage,
                    onMessageChange: { viewModel.newChatMessage = $0 },
                    onSendMessage: viewModel.sendRoomChatMessage
                )
                .frame(minHeight: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            print("🚨🚨🚨 BINGO GAME VIEW APPEARED: room=\(currentRoomID) 🚨🚨🚨")
            print("🚨🚨🚨 BINGO GAME VIEW BODY WAS RENDERED 🚨🚨🚨")
            // 只在第一次出現時加入房間
            if viewModel.gameRoomID != String(currentRoomID) {
                viewModel.attemptToJoinOrCreateRoom(roomID: String(currentRoomID))
            }
            print("🚨🚨🚨 AFTER CALLING attemptToJoinOrCreateRoom 🚨🚨🚨")
            
            // 設置遊戲獲勝回調
            viewModel.onGameWon = { deviceName, score in
                // 顯示冠軍
                winnerName = NicknameFormatter.cleanNickname(deviceName)
                winnerScore = score
                withAnimation {
                    showWinnerDisplay = true
                }
                
                // 記錄到排行榜
                onGameWon(deviceName, score)
                
                // 2秒後開始倒數
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showWinnerDisplay = false
                    }
                    
                    // 檢查房間人數，如果還有≥ 2人則顯示倒數
                    if viewModel.roomPlayers.count >= 2 {
                        print("🔄 房間還有 \(viewModel.roomPlayers.count) 人，開始倒數")
                        
                        // 開始5秒倒數
                        countdownNumber = 5
                        withAnimation {
                            showCountdown = true
                        }
                        
                        // 開始倒數動畫 - 使用簡化的方法避免Timer管理問題
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                            DispatchQueue.main.async {
                                if countdownNumber > 1 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        countdownNumber -= 1
                                    }
                                } else {
                                    timer.invalidate()
                                    withAnimation {
                                        showCountdown = false
                                    }
                                    // 倒數結束後重新開始遊戲
                                    Task { @MainActor in
                                        viewModel.restartGame()
                                    }
                                }
                            }
                        }
                    } else {
                        print("🚪 房間人數不足，不自動重新開始")
                    }
                }
            }
            
            // 請求其他玩家的排行榜數據
            viewModel.requestWeeklyLeaderboardData()
        }
        .onDisappear {
            viewModel.leaveGameRoom()
        }
        .onReceive(viewModel.$roomPlayers) { players in
            // 當房間玩家數量變化時，更新父視圖
            onPlayerCountChanged(currentRoomID, players.count)
        }
        .overlay(
            Group {
                // 冠軍顯示（優先權最高）
                if showWinnerDisplay {
                    VStack(spacing: 16) {
                        // 冠軍圖標
                        Text("🏆")
                            .font(.system(size: 100))
                        
                        // 玩家名稱
                        Text(winnerName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.clear)
                    )
                    .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    .transition(.scale.combined(with: .opacity))
                } else if showCountdown {
                    // 倒數顯示
                    Text("\(countdownNumber)")
                        .font(.system(size: 150, weight: .bold, design: .default)) // 改為默認設計（黑體）
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                        .shadow(color: Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(countdownNumber == 5 ? 1.5 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: countdownNumber)
                        .transition(.scale.combined(with: .opacity))
                } else if showEmoteText {
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
        .onReceive(viewModel.emotePublisher) { emote in
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
    @ObservedObject var viewModel: BingoGameViewModel
    @EnvironmentObject var languageService: LanguageService
    let onInteraction: () -> Void
    
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
            Text(languageService.t("become_player"))
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(allEmotes, id: \.self) { emote in
                    EmojiButton(
                        emoji: emote.emoji,
                        action: { 
                            viewModel.sendEmote(emote)
                            onInteraction() // 記錄互動次數
                        }
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
