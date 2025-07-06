import SwiftUI

struct BingoCardView: View {
    let bingoCard: BingoCard
    let drawnNumbers: [Int]
    let gameWon: Bool
    let onMarkNumber: (Int) -> Void
    let onReactionTime: ((Double) -> Void)?
    @EnvironmentObject var languageService: LanguageService
    @State private var numberDrawnTimes: [Int: Date] = [:] // 記錄號碼被抽中的時間
    
    var body: some View {
        VStack(spacing: 16) {
            // Bingo Card Grid - 完全對齊 React 版本
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { col in
                            let index = row * 5 + col
                            
                            // 安全的數組訪問，防止越界崩潰
                            if index < bingoCard.numbers.count &&
                               index < bingoCard.marked.count &&
                               index < bingoCard.drawn.count {
                                let number = bingoCard.numbers[index]
                                let isMarked = bingoCard.marked[index]
                                let isDrawn = bingoCard.drawn[index]
                                
                                Button(action: {
                                    // 中心格（免費格）不需要點擊
                                    if index != 12 {
                                        // 計算反應時間
                                        if let drawnTime = numberDrawnTimes[number] {
                                            let reactionTime = Date().timeIntervalSince(drawnTime) * 1000 // 轉換為毫秒
                                            onReactionTime?(reactionTime)
                                        }
                                        onMarkNumber(number)
                                    }
                                }) {
                                    if index == 12 {
                                        // 中心格顯示 "FREE"
                                        Text("FREE")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 48, height: 48)
                                            .background(Color(red: 0.063, green: 0.843, blue: 0.416)) // 綠色
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color(red: 0.063, green: 0.843, blue: 0.416), lineWidth: 2)
                                            )
                                            .cornerRadius(4)
                                    } else {
                                        Text("\(number)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(textColor(isMarked: isMarked, isDrawn: isDrawn))
                                            .frame(width: 48, height: 48)
                                            .background(backgroundColor(isMarked: isMarked, isDrawn: isDrawn))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(borderColor(isMarked: isMarked, isDrawn: isDrawn), lineWidth: 2)
                                            )
                                            .cornerRadius(4)
                                            .opacity(isDrawn ? 1.0 : 0.5)
                                    }
                                }
                                .disabled(index == 12 || !isDrawn || gameWon)
                            } else {
                                // 如果數組大小不正確，顯示錯誤格子
                                Button(action: {}) {
                                    Text("ERR")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.red)
                                        .frame(width: 48, height: 48)
                                        .background(Color.gray)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.red, lineWidth: 2)
                                        )
                                }
                                .disabled(true)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
            .onChange(of: drawnNumbers) { newDrawnNumbers in
                // 當有新號碼被抽中時，記錄時間
                for number in newDrawnNumbers {
                    if numberDrawnTimes[number] == nil {
                        numberDrawnTimes[number] = Date()
                    }
                }
            }
            
            // Instructions - 對齊 React 版本
            VStack(spacing: 8) {
                Text(languageService.t("click_drawn_numbers"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 新的顏色邏輯：藍色(已抽中) -> 綠色(已確認)
    private func backgroundColor(isMarked: Bool, isDrawn: Bool) -> Color {
        if isMarked {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // #10d76a (green for confirmed)
        } else if isDrawn {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // #263ee4 (blue for drawn)
        } else {
            return Color(red: 177/255, green: 153/255, blue: 234/255).opacity(0.3) // 未抽中的號碼為紫色（對標物資需求按鈕）
        }
    }
    
    private func borderColor(isMarked: Bool, isDrawn: Bool) -> Color {
        if isMarked {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // #10d76a
        } else if isDrawn {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // #263ee4
        } else {
            return Color(red: 177/255, green: 153/255, blue: 234/255).opacity(0.5) // 未抽中的號碼邊框為紫色
        }
    }
    
    private func textColor(isMarked: Bool, isDrawn: Bool) -> Color {
        if isMarked {
            return .white // 綠色狀態使用白色文字
        } else if isDrawn {
            return .white // 藍色狀態使用白色文字
        } else {
            return .black // 原始狀態數字為黑色
        }
    }
}

#Preview {
    let sampleCard = BingoCard(numbers: Array(1...25))
    BingoCardView(
        bingoCard: sampleCard,
        drawnNumbers: [1, 5, 10, 15, 20],
        gameWon: false,
        onMarkNumber: { _ in },
        onReactionTime: nil
    )
    .padding()
} 