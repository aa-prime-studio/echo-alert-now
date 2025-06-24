import SwiftUI

/// 用於測試 SplashScreen 動畫效果的專用視圖
struct SplashTestView: View {
    @State private var showDemo = false
    @State private var animationCount = 0
    
    var body: some View {
        ZStack {
            // 測試背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 62/255, blue: 228/255),
                    Color.blue.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            if showDemo {
                SplashScreenView {
                    // 動畫完成後的處理
                    animationCount += 1
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showDemo = false
                    }
                }
            } else {
                // 測試控制界面
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("SplashScreen 測試")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("測試新設計功能：")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Logo 放大 400%", systemImage: "plus.magnifyingglass")
                        Label("滿版網格 (12x5)", systemImage: "grid")
                        Label("5秒動畫時長", systemImage: "timer")
                        Label("無白色過渡", systemImage: "eye.slash")
                        Label("提前進入功能", systemImage: "hand.tap")
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 16))
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Button(action: {
                            startDemo()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("開始測試動畫")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if animationCount > 0 {
                            Text("已測試 \(animationCount) 次")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Text("提示：動畫播放中可點擊「點擊進入」測試提前進入功能")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func startDemo() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showDemo = true
        }
    }
}

// MARK: - Preview
struct SplashTestView_Previews: PreviewProvider {
    static var previews: some View {
        SplashTestView()
    }
}
