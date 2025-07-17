import SwiftUI

// MARK: - ViewModel Container for Lazy Initialization
@MainActor
class ViewModelContainer: ObservableObject, @unchecked Sendable {
    @Published var isReady = false
    @Published var initializationError: String?
    
    private var _chatViewModel: ChatViewModel?
    private var _signalViewModel: SignalViewModel?
    private var _bingoGameViewModel: BingoGameViewModel?
    
    // 同步鎖以防止競爭條件
    private let viewModelLock = NSLock()
    
    var chatViewModel: ChatViewModel {
        viewModelLock.lock()
        defer { viewModelLock.unlock() }
        
        if _chatViewModel == nil {
            _chatViewModel = ServiceContainer.shared.createChatViewModel()
        }
        return _chatViewModel ?? ChatViewModel(
            meshManager: nil,
            securityService: ServiceContainer.shared.securityService,
            selfDestructManager: ServiceContainer.shared.selfDestructManager,
            settingsViewModel: ServiceContainer.shared.settingsViewModel
        )
    }
    
    var signalViewModel: SignalViewModel {
        viewModelLock.lock()
        defer { viewModelLock.unlock() }
        
        if _signalViewModel == nil {
            _signalViewModel = ServiceContainer.shared.createSignalViewModel()
        }
        return _signalViewModel ?? SignalViewModel(
            networkService: ServiceContainer.shared.networkService,
            securityService: ServiceContainer.shared.securityService,
            settingsViewModel: ServiceContainer.shared.settingsViewModel,
            selfDestructManager: ServiceContainer.shared.selfDestructManager
        )
    }
    
    var bingoGameViewModel: BingoGameViewModel {
        viewModelLock.lock()
        defer { viewModelLock.unlock() }
        
        if _bingoGameViewModel == nil {
            _bingoGameViewModel = ServiceContainer.shared.createBingoGameViewModel()
        }
        return _bingoGameViewModel ?? ServiceContainer.shared.createBingoGameViewModel()
    }
    
    init() {
        // 立即標記為準備好，不等待任何初始化
        Task { @MainActor in
            self.isReady = true
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    // ViewModels - 延遲初始化避免阻塞
    @StateObject private var viewModelContainer = ViewModelContainer()
    
    var body: some View {
        Group {
            if let error = viewModelContainer.initializationError {
                // 錯誤處理視圖
                ErrorView(errorMessage: error) {
                    // 重試動作
                    viewModelContainer.initializationError = nil
                    viewModelContainer.isReady = true
                }
            } else {
                // 直接顯示主界面，忽略初始化狀態
                ZStack {
                    TabView(selection: $selectedTab) {
                        SignalTabView(signalViewModel: viewModelContainer.signalViewModel)
                            .tabItem {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text(languageService.t("signals"))
                            }
                            .tag(0)
                        
                        ChatTabView()
                            .tabItem {
                                Image(systemName: "message")
                                Text(languageService.t("chat"))
                            }
                            .tag(1)
                        
                        GameTabView(isPremiumUser: purchaseService.isPremiumUser)
                            .tabItem {
                                Image(systemName: "gamecontroller")
                                Text(languageService.t("games"))
                            }
                            .tag(2)
                        
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gear")
                                Text(languageService.t("settings"))
                            }
                            .tag(3)
                    }
                    .accentColor(.blue)
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                    
                    // 🛡️ 安全警報橫幅（顯示在最上層）
                    SecurityAlertBannerView()
                        .zIndex(1000)
                }
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(languageService.t("error_occurred"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text(languageService.t("retry"))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Loading Indicator
struct LoadingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0.0, to: 0.8)
                .stroke(Color.blue, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

struct SignalTabView: View {
    @ObservedObject var signalViewModel: SignalViewModel
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    
    private func sendSignalSync(_ type: SignalType) {
        signalViewModel.sendEmergencySignal(type: type)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                Divider()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            SignalButtonView(
                                type: .safe,
                                onSend: sendSignalSync,
                                disabled: false,
                                size: .large
                            )
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 12) {
                                SignalButtonView(type: .supplies, onSend: sendSignalSync, disabled: false, size: .small)
                                SignalButtonView(type: .medical, onSend: sendSignalSync, disabled: false, size: .small)
                                SignalButtonView(type: .danger, onSend: sendSignalSync, disabled: false, size: .small)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                        
                        // 廣播範圍說明
                        Text(languageService.t("broadcast_range_info"))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    ScrollView {
                        MessageListView(messages: signalViewModel.messages)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
            }
            .background(Color.gray.opacity(0.05))
            .navigationBarHidden(true)
            .onAppear {
                // 設備名稱由 settingsViewModel 管理，不需要在這裡設定
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionStatusColor)
                        .frame(width: 8, height: 8)
                    Text(translatedConnectionStatus)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.8)) // #263ee4
                }
                Text("Broadcast\nSignal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
            }
            Spacer()
            Button(action: {
                toggleConnection()
            }) {
                Image(systemName: connectionIconName)
                    .font(.title2)
                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
            }
        }
        .padding()
        .background(Color(red: 0.957, green: 0.957, blue: 0.957)) // #f4f4f4
        .onAppear {
            // 連線狀態會自動更新，不需要手動呼叫
        }
    }
    
    // 連線狀態顏色
    private var connectionStatusColor: Color {
        let status = signalViewModel.connectionStatus
        if status.contains(languageService.t("connected")) || status.contains("Connected") {
            return .green
        } else if status.contains(languageService.t("connecting")) || status.contains("Connecting") {
            return .orange
        } else if status.contains(languageService.t("disconnected")) || status.contains("Disconnected") || status.contains(languageService.t("offline")) {
            return .red
        } else {
            return .gray
        }
    }
    
    // 翻譯後的連線狀態文字
    private var translatedConnectionStatus: String {
        // SignalViewModel 現在已經使用 LanguageService 進行正確的格式化
        return signalViewModel.connectionStatus
    }
    
    // 連線圖標名稱
    private var connectionIconName: String {
        let status = signalViewModel.connectionStatus
        if status.contains(languageService.t("connected")) || status.contains("Connected") {
            return "wifi"
        } else if status.contains(languageService.t("connecting")) || status.contains("Connecting") {
            return "wifi.exclamationmark"
        } else if status.contains(languageService.t("disconnected")) || status.contains("Disconnected") || status.contains(languageService.t("offline")) {
            return "wifi.slash"
        } else {
            return "wifi.slash"
        }
    }
    
    // 切換連線狀態
    private func toggleConnection() {
        // 連線管理應該透過 NetworkService 處理
        // SignalViewModel 只負責信號相關功能
        print("⚠️ 連線管理功能已移至 NetworkService")
    }
}

struct ChatTabView: View {
    var body: some View {
        NavigationView {
            ChatView()
                .navigationBarHidden(true)
        }
    }
}

struct GameTabView: View {
    let isPremiumUser: Bool
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @State private var showingUpgradeSheet = false
    @State private var localIsPremiumUser: Bool
    
    init(isPremiumUser: Bool) {
        self.isPremiumUser = isPremiumUser
        self._localIsPremiumUser = State(initialValue: isPremiumUser)
    }
    
    var body: some View {
        NavigationView {
            if localIsPremiumUser {
                GameView()
                    .navigationBarHidden(true)
            } else {
                UpgradePromptView(showingUpgradeSheet: $showingUpgradeSheet)
                    .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            PurchaseOptionsView(purchaseService: purchaseService)
        }
        .onReceive(purchaseService.$purchasedTiers) { _ in
            // 監聽購買狀態變化，確保在主線程執行
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    localIsPremiumUser = purchaseService.isPremiumUser
                }
            }
        }
    }
}

struct UpgradePromptView: View {
    @Binding var showingUpgradeSheet: Bool
    @EnvironmentObject var languageService: LanguageService
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    HStack {
                        Text("Bingo\nGame Room")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475)) // #ffec79
                        Spacer()
                        
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475))
                    }
                    .padding()
                    .background(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                    
                    // 預覽內容區域
                    VStack(spacing: 20) {
                        // 賓果遊戲室預覽
                        VStack(spacing: 12) {
                            HStack {
                                Text(languageService.t("bingo_game_room"))
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Text(languageService.t("ready"))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.0, green: 0.843, blue: 0.416))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            // 連線互動設計
                            DraggableGameView(showingUpgradeSheet: $showingUpgradeSheet)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .overlay(
                            // 可拖拽的手把圖標 - 限制在賓果遊戲室區塊內
                            DraggableBingoGamepadOverlay(showingUpgradeSheet: $showingUpgradeSheet)
                                .allowsHitTesting(true)
                        )
                        
                        // 功能特色預覽
                        VStack(spacing: 16) {
                            HStack {
                                Text(languageService.t("game_features"))
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                FeatureRowView(
                                    icon: "person.3.fill",
                                    title: languageService.t("multiplayer_battle"),
                                    description: languageService.t("max_6_players")
                                )
                                
                                FeatureRowView(
                                    icon: "trophy.fill",
                                    title: languageService.t("daily_leaderboard_title"),
                                    description: languageService.t("daily_best_scores")
                                )
                                
                                FeatureRowView(
                                    icon: "message.fill",
                                    title: languageService.t("realtime_chat"),
                                    description: languageService.t("interact_with_players")
                                )
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // 鎖定通知卡片 - 移到遊戲特色下方
                        VStack(spacing: 16) {
                            Button(action: {
                                showingUpgradeSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .scaleEffect(0.8)
                                        .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475)) // #ffec79 黃色
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(languageService.t("bingo_locked_title"))
                                            .font(.headline)
                                            .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475)) // #ffec79 黃色
                                        
                                        Text(languageService.t("unlock_full_experience"))
                                            .font(.caption)
                                            .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475).opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .scaleEffect(0.8)
                                        .foregroundColor(Color(red: 1.0, green: 0.925, blue: 0.475).opacity(0.8))
                                }
                                .padding()
                                .background(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4 藍色背景
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Legal Links
                        HStack(spacing: 16) {
                            Button(action: {
                                showingTermsOfService = true
                            }) {
                                Text(languageService.t("terms_of_service"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .underline()
                            }
                            
                            Button(action: {
                                showingPrivacyPolicy = true
                            }) {
                                Text(languageService.t("privacy_policy"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .underline()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            
        }
        .background(Color.gray.opacity(0.05))
        .sheet(isPresented: $showingTermsOfService) {
            NavigationView {
                TermsOfServiceView()
                    .environmentObject(languageService)
                    .navigationBarItems(trailing: Button(languageService.t("done")) {
                        showingTermsOfService = false
                    })
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
                    .environmentObject(languageService)
                    .navigationBarItems(trailing: Button(languageService.t("done")) {
                        showingPrivacyPolicy = false
                    })
            }
        }
    }
}

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .scaleEffect(0.8)
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
        }
        .padding(.vertical, 4)
    }
}

struct CircularTextView: View {
    let text: String
    let radius: CGFloat
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 12, weight: .bold))
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(text.count))))
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct HandGestureView: View {
    @State private var isAnimating = false
    @State private var tapScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 點擊波紋效果
            Circle()
                .stroke(Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(isAnimating ? 1.5 : 0.8)
                .opacity(isAnimating ? 0 : 1)
            
            // 手指圖標
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                .scaleEffect(tapScale)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                tapScale = 1.2
            }
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DraggableGameView: View {
    @Binding var showingUpgradeSheet: Bool
    @State private var gamepadPosition = CGPoint(x: 80, y: 80)
    @State private var isDragging = false
    
    // 固定的解鎖圖標位置（相對於這個view）
    private let unlockPosition = CGPoint(x: 240, y: 80)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 動態連線 - 從手把到解鎖區域
                Path { path in
                    let startPoint = CGPoint(
                        x: gamepadPosition.x + 30, // 手把圓形半徑30pt
                        y: gamepadPosition.y
                    )
                    let endPoint = CGPoint(
                        x: unlockPosition.x - 55, // 線段終點剛好到旋轉文字邊緣（半徑55pt）
                        y: unlockPosition.y
                    )
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.6), lineWidth: 2)
                
                // 可拖拽的手把圖標
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .position(gamepadPosition)
                .gesture(
                    DragGesture(coordinateSpace: .local)
                        .onChanged { value in
                            isDragging = true
                            // 限制在賓果遊戲室區塊內移動
                            let newX = max(30, min(geometry.size.width - 30, value.location.x))
                            let newY = max(30, min(geometry.size.height - 30, value.location.y))
                            
                            gamepadPosition = CGPoint(x: newX, y: newY)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .animation(.spring(response: 0.3), value: isDragging)
                
                // 固定的解鎖圖標與旋轉文字
                ZStack {
                // 外圈繞圈文字
                Circle()
                    .stroke(Color.clear, lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .overlay(
                        CircularTextView(
                            text: "UNLOCK • TO • PLAY • UNLOCK • TO • PLAY • ",
                            radius: 55
                        )
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .font(.system(size: 12, weight: .bold))
                    )
                
                // 可點擊的解鎖按鈕
                Button(action: {
                    showingUpgradeSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.843, blue: 0.416))
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
            .position(unlockPosition)
            
            // 手勢指引動畫 - 避免重疊到旋轉文字，右移2pt增加移動空間
            HandGestureView()
                .position(x: unlockPosition.x + 82, y: unlockPosition.y + 10)
            }
        }
        .frame(height: 160)
        .padding(.vertical, 10)
    }
}

struct DraggableBingoGamepadOverlay: View {
    @Binding var showingUpgradeSheet: Bool
    
    var body: some View {
        // 空的覆蓋層，所有邏輯已移到 DraggableGameView
        Color.clear
            .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
}
