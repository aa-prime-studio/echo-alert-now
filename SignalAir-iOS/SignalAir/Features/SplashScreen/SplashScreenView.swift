import SwiftUI

/// 完全獨立的啟動畫面，不影響現有的 Signal 系統
struct SplashScreenView: View {
    @State private var isFlashing = false
    @State private var isComplete = false
    @State private var canProceed = false
    @State private var shouldProceed = false
    
    private let animationDuration: Double = 2.0 // 2秒動畫時長 - 優化啟動速度
    
    var onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 藍色背景，確保無白色過渡
                Color(red: 40/255, green: 62/255, blue: 228/255)
                    .ignoresSafeArea(.all)
                
                // 中央閃爍 logo (400x400，置中畫面中心點)
                Image("loading")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400) // 400x400
                    .opacity(isFlashing ? 1.0 : 0.3)
                    .position(x: geometry.size.width / 2, 
                             y: geometry.size.height / 2) // 確保置中畫面中心點
            }
        }
        .background(Color(red: 40/255, green: 62/255, blue: 228/255)) // 確保背景無白色
        .onAppear {
            startAnimation()
        }
        .onChange(of: shouldProceed) { newValue in
            if newValue {
                completeAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // 持續閃爍動畫直到加載完成 - 優化頻率
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            isFlashing = true
        }
        
        // 模擬載入完成 (1.5秒後可以提前進入)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            canProceed = true
        }
        
        // 完整動畫結束 (2秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            if !shouldProceed {
                completeAnimation()
            }
        }
    }
    
    private func handleEarlyEntry() {
        shouldProceed = true
    }
    
    private func completeAnimation() {
        guard !isComplete else { return }
        isComplete = true
        
        // 停止閃爍動畫，直接切換
        withAnimation(.easeOut(duration: 0.3)) {
            onComplete()
        }
    }
}

// MARK: - Preview
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView {
            print("Animation completed")
        }
    }
} 