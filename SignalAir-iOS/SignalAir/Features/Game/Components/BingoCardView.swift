import SwiftUI

struct BingoCardView: View {
    let bingoCard: BingoCard
    let drawnNumbers: [Int]
    let gameWon: Bool
    let onMarkNumber: (Int) -> Void
    @StateObject private var languageService = LanguageService()
    
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
                            let isDrawn = drawnNumbers.contains(number)
                            
                            Button(action: {
                                onMarkNumber(index)
                            }) {
                                Text("\(number)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(textColor(isMarked: isMarked))
                                    .frame(width: 48, height: 48)
                                    .background(backgroundColor(isMarked: isMarked, isDrawn: isDrawn))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(borderColor(isMarked: isMarked, isDrawn: isDrawn), lineWidth: 2)
                                    )
                                    .cornerRadius(4)
                                    .opacity(isDrawn ? 1.0 : 0.5)
                            }
                            .disabled(!isDrawn || isMarked || gameWon)
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
    
    // 完全對齊 React 版本的顏色邏輯
    private func backgroundColor(isMarked: Bool, isDrawn: Bool) -> Color {
        if isMarked {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // #10d76a (green for marked)
        } else {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // #263ee4 (blue for available/drawn)
        }
    }
    
    private func borderColor(isMarked: Bool, isDrawn: Bool) -> Color {
        if isMarked {
            return Color(red: 0.063, green: 0.843, blue: 0.416) // #10d76a
        } else {
            return Color(red: 0.149, green: 0.243, blue: 0.894) // #263ee4
        }
    }
    
    private func textColor(isMarked: Bool) -> Color {
        if isMarked {
            return .white
        } else {
            return Color(red: 1.0, green: 0.925, blue: 0.475) // #ffec79 (yellow text)
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