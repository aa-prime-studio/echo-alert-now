import SwiftUI

struct DrawnNumbersView: View {
    let drawnNumbers: [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("已抽取號碼")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("共 \(drawnNumbers.count) 個")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if drawnNumbers.isEmpty {
                Text("等待抽號中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(drawnNumbers.reversed(), id: \.self) { number in
                            Text("\(number)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                                .cornerRadius(16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 40)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    DrawnNumbersView(drawnNumbers: [15, 23, 7, 42, 8, 31, 19, 56, 3, 44])
} 