import SwiftUI
import StoreKit

@main
struct SignalAirApp: App {
    // Service Container - 延遲初始化
    @State private var serviceContainer: ServiceContainer?
    @State private var showSplash = true
    @State private var isServicesReady = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 藍色背景確保無白色過渡
                Color(red: 40/255, green: 62/255, blue: 228/255)
                    .ignoresSafeArea(.all)
                
                if showSplash {
                    SplashScreenView {
                        // 1秒後開始過渡動畫
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showSplash = false
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                } else if let serviceContainer = serviceContainer, isServicesReady {
                    // 主應用程式界面 - 只有當服務準備好時才顯示
                    ContentView()
                        .environmentObject(serviceContainer)
                        .environmentObject(serviceContainer.languageService)
                        .environmentObject(serviceContainer.nicknameService)
                        .environmentObject(serviceContainer.purchaseService)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    // 服務加載中
                    ServiceLoadingView()
                }
            }
            .background(Color(red: 40/255, green: 62/255, blue: 228/255))
            .onAppear {
                // 立即開始異步初始化服務，1ms藍屏後即開始
                if serviceContainer == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                        Task {
                            await initializeServices()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 異步服務初始化
    @MainActor
    private func initializeServices() async {
        print("🚀 開始異步初始化服務...")
        
        // 在背景線程初始化 ServiceContainer
        let container = await Task {
            return ServiceContainer.shared
        }.value
        
        // 等待关鍵服務初始化完成
        while !container.isInitialized {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
        
        self.serviceContainer = container
        self.isServicesReady = true
        
        print("✅ 服務初始化完成")
    }
}

// MARK: - 服務加載畫面
struct ServiceLoadingView: View {
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 40/255, green: 62/255, blue: 228/255)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    Image("loading")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .opacity(isLoading ? 1.0 : 0.4)
                    
                    Text("🚀 正在啟動...")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .position(x: geometry.size.width / 2, 
                         y: geometry.size.height / 2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isLoading = true
            }
        }
    }
}

// MARK: - 快速啟動畫面
/// 快速啟動畫面 - 優化版
struct SplashScreenView: View {
    @State private var isFlashing = false
    let onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 40/255, green: 62/255, blue: 228/255)
                    .ignoresSafeArea(.all)
                
                Image("loading")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
                    .opacity(isFlashing ? 1.0 : 0.3)
                    .position(x: geometry.size.width / 2, 
                             y: geometry.size.height / 2)
            }
        }
        .onAppear {
            // 立即開始閃電動畫
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
            
            // 2.5秒logo動畫，給足夠服務初始化時間
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }
}