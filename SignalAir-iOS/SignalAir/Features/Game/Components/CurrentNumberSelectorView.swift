import SwiftUI

/// 【NEW】號碼選擇器 - 顯示1-99所有數字網格供選擇
struct CurrentNumberSelectorView: View {
    @Binding var selectedNumber: Int
    let isMyTurn: Bool
    let currentPlayerName: String
    let playerCount: Int
    let gameState: GameRoomState.GameState
    let drawnNumbers: [Int] // 已抽取的號碼列表（藍色顯示）
    let confirmedNumbers: [Int] // 已確認的號碼列表（綠色顯示）
    let onNumberSelected: (Int) -> Void
    let onNumberConfirmed: ((Int) -> Void)? // 新增：號碼確認回調
    @EnvironmentObject var languageService: LanguageService
    
    init(selectedNumber: Binding<Int>, isMyTurn: Bool, currentPlayerName: String, playerCount: Int = 0, gameState: GameRoomState.GameState = .waitingForPlayers, drawnNumbers: [Int] = [], confirmedNumbers: [Int] = [], onNumberSelected: @escaping (Int) -> Void, onNumberConfirmed: ((Int) -> Void)? = nil) {
        self._selectedNumber = selectedNumber
        self.isMyTurn = isMyTurn
        self.currentPlayerName = currentPlayerName
        self.playerCount = playerCount
        self.gameState = gameState
        self.drawnNumbers = drawnNumbers
        self.confirmedNumbers = confirmedNumbers
        self.onNumberSelected = onNumberSelected
        self.onNumberConfirmed = onNumberConfirmed
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題和輪流狀態
            VStack(spacing: 8) {
                Text("號碼選擇器")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if playerCount < 2 {
                    Text("等待更多玩家加入... (\(playerCount)/2)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                } else if gameState == .waitingForPlayers {
                    Text("準備開始遊戲...")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                } else if isMyTurn {
                    Text("輪到你抽號！")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    Text("輪到 \(currentPlayerName)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
            
            // 1-99 號碼顯示（類似 DrawnNumbersView 的風格）
            VStack(spacing: 12) {
                HStack {
                    Text("選擇號碼 (1-99)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("已抽取 \(drawnNumbers.count) 個")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(1...99, id: \.self) { number in
                                Button(action: {
                                    // 【FIX】放寬點選條件，允許更多場景下的號碼選擇
                                    if !confirmedNumbers.contains(number) {
                                        if drawnNumbers.contains(number) {
                                            // 點選已抽取但未確認的號碼，將其確認
                                            onNumberConfirmed?(number)
                                        } else {
                                            // 選擇未抽取的號碼
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedNumber = number
                                            }
                                        }
                                    }
                                }) {
                                    Text("\(number)")
                                        .font(.system(size: min(14, geometry.size.width * 0.04), weight: .bold))
                                        .foregroundColor(textColor(for: number))
                                        .frame(width: min(32, geometry.size.width * 0.08), 
                                               height: min(32, geometry.size.width * 0.08))
                                        .background(backgroundColor(for: number))
                                        .cornerRadius(min(16, geometry.size.width * 0.04))
                                        .overlay(
                                            Circle()
                                                .stroke(borderColor(for: number), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(confirmedNumbers.contains(number)) // 【FIX】只禁用已確認的號碼
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .frame(height: min(40, UIScreen.main.bounds.width * 0.1))
            }
            
            // 確認按鈕 - 【FIX】放寬顯示條件
            if selectedNumber >= 1 && selectedNumber <= 99 {
                Button(action: {
                    onNumberSelected(selectedNumber)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("確認抽號：\(selectedNumber)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((drawnNumbers.contains(selectedNumber) || confirmedNumbers.contains(selectedNumber)) ? Color.gray : Color(red: 0.063, green: 0.843, blue: 0.416))
                    )
                }
                .disabled(selectedNumber < 1 || selectedNumber > 99 || confirmedNumbers.contains(selectedNumber)) // 【FIX】允許選擇已抽取但未確認的號碼
                .buttonStyle(ScaleButtonStyle())
            } else {
                // 選擇提示 - 【FIX】更友好的提示文字
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16))
                    Text("請選擇一個1-99的號碼")
                        .fontWeight(.medium)
                }
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 數字顏色邏輯 - 與賓果卡保持一致
    private func textColor(for number: Int) -> Color {
        if confirmedNumbers.contains(number) {
            return .white // 已確認：白字
        } else if drawnNumbers.contains(number) {
            return .white // 已抽取：白字
        } else if selectedNumber == number {
            return .white // 已選擇：白字
        } else {
            return .black // 【FIX】所有未確認的號碼都可選擇：黑字
        }
    }
    
    private func backgroundColor(for number: Int) -> Color {
        if confirmedNumbers.contains(number) {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // 已確認：綠色（與賓果卡一致）
        } else if drawnNumbers.contains(number) {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // 已抽取但未確認：藍色（與賓果卡一致）
        } else if selectedNumber == number {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // 當前選擇：藍色
        } else {
            return Color.white // 【FIX】所有未確認的號碼都可選擇：白色
        }
    }
    
    private func borderColor(for number: Int) -> Color {
        if confirmedNumbers.contains(number) {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // 已確認：綠色邊框
        } else if drawnNumbers.contains(number) {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // 已抽取但未確認：藍色邊框
        } else if selectedNumber == number {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // 當前選擇：藍色邊框
        } else {
            return Color.gray.opacity(0.3) // 【FIX】所有未確認的號碼都可選擇：淺灰邊框
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 我的回合
        CurrentNumberSelectorView(
            selectedNumber: .constant(42),
            isMyTurn: true,
            currentPlayerName: "玩家A",
            onNumberSelected: { number in
                print("選擇號碼: \(number)")
            }
        )
        
        // 等待其他玩家
        CurrentNumberSelectorView(
            selectedNumber: .constant(25),
            isMyTurn: false,
            currentPlayerName: "玩家B",
            onNumberSelected: { number in
                print("選擇號碼: \(number)")
            }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}