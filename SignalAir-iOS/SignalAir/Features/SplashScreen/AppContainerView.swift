import SwiftUI

/// 應用程式容器視圖 - 管理啟動畫面和主應用程式的顯示
struct AppContainerView: View {
    @State private var showSplash = true
    @State private var isAppReady = false
    
    var body: some View {
        ZStack {
            // 藍色背景確保無白色過渡
            Color(red: 40/255, green: 62/255, blue: 228/255)
                .ignoresSafeArea(.all)
            
            if showSplash {
                SplashScreenView {
                    // 動畫完成回調 - 無縫切換
                    showSplash = false
                }
                .transition(.identity) // 無過渡動畫
            } else {
                // 主應用程式界面
                MainAppContentView()
                    .transition(.identity) // 無過渡動畫
            }
        }
        .onAppear {
            // 模擬實際載入時間 (3秒後即可提前進入)
            simulateAppLoading()
        }
        .background(Color(red: 40/255, green: 62/255, blue: 228/255))
    }
    
    private func simulateAppLoading() {
        // 模擬應用程式載入 - 3秒後載入完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isAppReady = true
        }
    }
}

/// 主應用程式內容視圖 - 包裝現有的 ContentView 和所有服務
struct MainAppContentView: View {
    @StateObject private var serviceContainer = ServiceContainer.shared
    
    var body: some View {
        ContentView()
            .environmentObject(serviceContainer)
            .environmentObject(serviceContainer.languageService)
            .environmentObject(serviceContainer.nicknameService)
            .environmentObject(serviceContainer.purchaseService)
            .onAppear {
                configureStoreKit()
            }
    }
    
    private func configureStoreKit() {
        print("SignalAir Rescue App Started - StoreKit Ready")
    }
}

// MARK: - Preview
struct AppContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AppContainerView()
    }
}

