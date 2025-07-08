import SwiftUI
import Foundation

struct GameView: View {
    @State private var currentRoom: BingoRoom?
    @State private var leaderboard: [BingoScore] = []
    @State private var roomPlayerCounts: [Int: Int] = [1: 0, 2: 0, 3: 0] // 房間ID到玩家數量的映射
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    // 【簡化重構】安全的 ViewModel 創建，防止崩潰
    @State private var bingoViewModel: BingoGameViewModel?
    @State private var viewModelCreationError: String?
    @State private var isCreatingViewModel = false
    
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
            if let room = currentRoom {
                // 【簡化重構】安全的 ViewModel 檢查
                if let viewModel = bingoViewModel {
                    TabView {
                        // Game Tab - Bingo Card
                        VStack(spacing: 16) {
                            Text("房間: \(room.name.uppercased())")
                                .font(.headline)
                                .padding()
                            
                            if let bingoCard = viewModel.bingoCard {
                                BingoCardView(
                                    bingoCard: bingoCard,
                                    drawnNumbers: Array(viewModel.drawnNumbers),
                                    gameWon: viewModel.gameWon,
                                    onMarkNumber: { number in
                                        viewModel.markNumber(number)
                                        interactionCount += 1
                                    },
                                    onReactionTime: { reactionTime in
                                        reactionTimes.append(reactionTime)
                                    }
                                )
                            }
                            
                            if viewModel.gameWon {
                                Button("離開房間") {
                                    roomPlayerCounts[room.id] = 0
                                    saveInteractionStats()
                                    currentRoom = nil
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .tabItem {
                            Image(systemName: "square.grid.3x3.fill")
                            Text("賓果卡")
                        }
                        
                        // Players Tab
                        VStack(spacing: 16) {
                            Text("房間: \(room.name.uppercased())")
                                .font(.headline)
                                .padding()
                            
                            PlayerListView(
                                players: viewModel.roomPlayers.map { playerState in
                                    RoomPlayer(
                                        name: playerState.name,
                                        completedLines: playerState.completedLines,
                                        hasWon: playerState.hasWon
                                    )
                                },
                                deviceName: viewModel.deviceName
                            )
                        }
                        .tabItem {
                            Image(systemName: "person.3.fill")
                            Text("玩家")
                        }
                        
                        // Numbers Tab
                        VStack(spacing: 16) {
                            Text("已抽號碼")
                                .font(.headline)
                                .padding()
                            
                            DrawnNumbersView(
                                drawnNumbers: Array(viewModel.drawnNumbers)
                            )
                        }
                        .tabItem {
                            Image(systemName: "number.circle.fill")
                            Text("號碼")
                        }
                        
                        // Chat Tab
                        RoomChatView(
                            roomName: room.name,
                            messages: viewModel.roomChatMessages,
                            newMessage: viewModel.newChatMessage,
                            onMessageChange: { newMessage in
                                viewModel.newChatMessage = newMessage
                            },
                            onSendMessage: {
                                viewModel.sendChatMessage()
                                interactionCount += 1
                            }
                        )
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("聊天")
                        }
                    }
                } else if isCreatingViewModel {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在初始化遊戲服務...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                } else if let error = viewModelCreationError {
                    VStack(spacing: 16) {
                        Text("⚠️")
                            .font(.system(size: 60))
                        Text(error)
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Button("重試") {
                            initializeBingoViewModelForRoom(room.id)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                } else {
                    Text("遊戲服務準備中...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.05))
                }
            } else {
                RoomListView(
                    rooms: rooms,
                    leaderboard: leaderboard,
                    onJoinRoom: { room in
                        print("🚨🚨🚨 ROOM SELECTED: id=\(room.id) name=\(room.name) 🚨🚨🚨")
                        DispatchQueue.main.async {
                            currentRoom = room
                            print("🚨🚨🚨 CURRENT ROOM SET ON MAIN THREAD: \(room.id) 🚨🚨🚨")
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            print("🚨🚨🚨 GAME VIEW APPEARED, currentRoom: \(currentRoom?.id ?? -1) 🚨🚨🚨")
            setupLeaderboard()
            startRoomMonitoring()
            // 【簡化修復】移除自動初始化，只在真正需要時初始化
        }
        .onDisappear {
            // 清理所有 Timer 防止記憶體洩漏
            roomMonitoringTimer?.invalidate()
            roomMonitoringTimer = nil
            print("🧹 GameView: 已清理房間監控 Timer")
        }
        .onChange(of: currentRoom) { newRoom in
            if let room = newRoom {
                // 【簡化重構】只有在進入房間時才初始化 ViewModel
                initializeBingoViewModelForRoom(room.id)
            } else {
                // 離開房間時清理 ViewModel
                cleanupBingoViewModel()
            }
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
            // 提取週開始時間戳
            let weekString = String(key.dropFirst(weeklyLeaderboardPrefix.count))
            if let weekTimestamp = Int(weekString), weekTimestamp < cutoffTimestamp {
                UserDefaults.standard.removeObject(forKey: key)
                print("🗑️ 清除舊週排行榜: \(key)")
            }
        }
    }
    
    /// 獲取本週週一的日期
    private func getThisWeekMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // weekday: 1=週日, 2=週一, ..., 7=週六
        // 計算到週一的偏移量
        let daysToMonday = (weekday == 1) ? -6 : (2 - weekday)
        
        return calendar.date(byAdding: .day, value: daysToMonday, to: today) ?? today
    }
    
    // MARK: - 【簡化重構】ViewModel 管理
    
    // 【簡化方案】只在需要時初始化 ViewModel
    private func initializeBingoViewModelForRoom(_ roomID: Int) {
        guard bingoViewModel == nil else {
            // ViewModel 已存在，直接更新房間
            bingoViewModel?.updateRoom(roomID)
            return
        }
        
        isCreatingViewModel = true
        viewModelCreationError = nil
        
        Task { @MainActor in
            do {
                print("🎮 GameView: 開始初始化 ViewModel for room \(roomID)")
                
                // 簡單延遲，等待 UI 準備
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
                print("🎮 GameView: 創建 ViewModel...")
                // 直接創建 ViewModel
                let viewModel = ServiceContainer.shared.createBingoGameViewModel()
                
                print("🎮 GameView: ViewModel 創建成功")
                self.bingoViewModel = viewModel
                
                print("🎮 GameView: 設置 isCreatingViewModel = false")
                self.isCreatingViewModel = false
                
                // 設置房間
                print("🎮 GameView: 更新房間 ID: \(roomID)")
                
                // 延遲一下再加入房間，讓 UI 有時間更新
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                    
                    print("🎮 GameView: 延遲後開始加入房間...")
                    
                    // 異步加入房間，避免阻塞主線程
                    Task {
                        print("🎮 GameView: 開始異步房間操作...")
                        if roomID == 1 {
                            print("🎮 GameView: 創建遊戲房間...")
                            await viewModel.createGameRoomAsync()
                        } else {
                            print("🎮 GameView: 加入遊戲房間 \(roomID)...")
                            await viewModel.joinGameRoomAsync(String(roomID))
                        }
                        print("🎮 GameView: 房間操作完成")
                    }
                    
                    print("🎮 GameView: 房間操作已觸發")
                }
                
                print("🎮 GameView: 初始化完成！")
                
                // 3秒後檢查是否還在載入中
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
                    if self.isCreatingViewModel {
                        print("⚠️ GameView: 初始化可能卡住了")
                        self.viewModelCreationError = "初始化超時，請重試"
                        self.isCreatingViewModel = false
                        
                        // 清理可能卡住的 ViewModel
                        if let vm = self.bingoViewModel {
                            print("🧹 GameView: 清理卡住的 ViewModel")
                            vm.leaveRoom()
                            self.bingoViewModel = nil
                        }
                    }
                }
                
            } catch {
                print("❌ GameView: 初始化失敗 - \(error)")
                self.viewModelCreationError = "初始化失敗: \(error.localizedDescription)"
                self.isCreatingViewModel = false
                self.bingoViewModel = nil
            }
        }
    }
    
    // 清理 ViewModel
    private func cleanupBingoViewModel() {
        bingoViewModel?.leaveRoom()
        bingoViewModel = nil
        viewModelCreationError = nil
        isCreatingViewModel = false
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
    
    // MARK: - 統計追蹤
    
    /// 保存互動統計數據
    private func saveInteractionStats() {
        // 保存互動次數
        UserDefaults.standard.set(interactionCount, forKey: "InteractionCount")
        
        // 保存反應時間數據
        if let encoded = try? JSONEncoder().encode(reactionTimes) {
            UserDefaults.standard.set(encoded, forKey: "ReactionTimes")
        }
        
        print("📊 統計數據已保存: 互動次數=\(interactionCount), 反應時間記錄=\(reactionTimes.count)筆")
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
                if !leaderboard.isEmpty {
                    LeaderboardView(leaderboard: leaderboard)
                }
            }
            .padding()
        }
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