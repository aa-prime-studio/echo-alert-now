import SwiftUI

struct BingoCardView: View {
    let bingoCard: BingoCard
    let drawnNumbers: [Int]
    let gameWon: Bool
    let onMarkNumber: (Int) -> Void
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(spacing: 16) {
            // Bingo Card Grid - 完全對齊 React 版本
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { col in
                            let index = row * 5 + col
                            let number = bingoCard.numbers[index]
                            let isMarked = bingoCard.marked[index]
                            let isDrawn = bingoCard.drawn[index]
                            
                            Button(action: {
                                onMarkNumber(number)
                            }) {
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
                            .disabled(!isDrawn || gameWon)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
            
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
        onMarkNumber: { _ in }
    )
    .padding()
} 