import SwiftUI

struct ContentView: View {
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    // ViewModels created through service container
    @StateObject private var chatViewModel = ServiceContainer.shared.createChatViewModel()
    @StateObject private var signalViewModel = ServiceContainer.shared.createSignalViewModel()
    @StateObject private var bingoGameViewModel = ServiceContainer.shared.createBingoGameViewModel()
    
    var body: some View {
        TabView {
            SignalTabView(signalViewModel: signalViewModel)
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
    }
}

struct SignalTabView: View {
    @ObservedObject var signalViewModel: SignalViewModel
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    
    private func sendSignalSync(_ type: SignalType) {
        Task {
            await signalViewModel.sendSignal(type)
        }
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
                signalViewModel.deviceName = nicknameService.nickname
                // 添加測試數據以展示方位功能（僅在開發模式下）
                #if DEBUG
                if signalViewModel.messages.isEmpty {
                    signalViewModel.addTestData()
                }
                #endif
            }
            .onChange(of: nicknameService.nickname) { newNickname in
                signalViewModel.deviceName = newNickname
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
                    Text(signalViewModel.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.8))
                }
                Text("Broadcast\nSignal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            Spacer()
            Button(action: {
                toggleConnection()
            }) {
                Image(systemName: connectionIconName)
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color(red: 0.898, green: 0.847, blue: 0.016)) // #e5d804
        .onAppear {
            signalViewModel.updateConnectionStatus()
        }
    }
    
    // 連線狀態顏色
    private var connectionStatusColor: Color {
        switch signalViewModel.connectionStatus {
        case "已連線":
            return .green
        case "連線中":
            return .orange
        case "未連線":
            return .red
        default:
            return .gray
        }
    }
    
    // 連線圖標名稱
    private var connectionIconName: String {
        switch signalViewModel.connectionStatus {
        case "已連線":
            return "wifi"
        case "連線中":
            return "wifi.exclamationmark"
        case "未連線":
            return "wifi.slash"
        default:
            return "wifi.slash"
        }
    }
    
    // 切換連線狀態
    private func toggleConnection() {
        switch signalViewModel.connectionStatus {
        case "已連線", "連線中":
            // 斷開連線
            Task {
                await signalViewModel.disconnect()
            }
        case "未連線":
            // 重新連線
            signalViewModel.reconnect()
        default:
            signalViewModel.reconnect()
        }
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
    
    var body: some View {
        NavigationView {
            // 暫時關閉內購檢查，直接顯示遊戲
            GameView()
                .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
