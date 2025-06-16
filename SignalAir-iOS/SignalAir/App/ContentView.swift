import SwiftUI

struct ContentView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    var body: some View {
        TabView {
            SignalTabView()
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
    @StateObject private var signalViewModel = SignalViewModel()
    @EnvironmentObject var nicknameService: NicknameService
    
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
                                onSend: signalViewModel.sendSignal,
                                disabled: false,
                                size: .large
                            )
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 12) {
                                SignalButtonView(type: .supplies, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                                SignalButtonView(type: .medical, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                                SignalButtonView(type: .danger, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
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
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("已連線 - 可發送和接收訊號")
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
                // Toggle connection action
            }) {
                Image(systemName: "wifi")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color(red: 0.898, green: 0.847, blue: 0.016)) // #e5d804
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
