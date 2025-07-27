import SwiftUI

struct DrawnNumbersView: View {
    let drawnNumbers: [Int]
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageService.t("drawn_numbers"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(languageService.t("total_count")) \(drawnNumbers.count) \(languageService.t("count_unit"))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if drawnNumbers.isEmpty {
                Text(languageService.t("waiting_draw"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(drawnNumbers.reversed(), id: \.self) { number in
                                    Text("\(number)")
                                        .font(.system(size: min(14, geometry.size.width * 0.04), weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: min(32, geometry.size.width * 0.08), 
                                               height: min(32, geometry.size.width * 0.08))
                                        .background(Color(red: 0.149, green: 0.243, blue: 0.894))
                                        .cornerRadius(min(16, geometry.size.width * 0.04))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                        .id(number)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .onChange(of: drawnNumbers.count) { _, _ in
                            if let lastNumber = drawnNumbers.last {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastNumber, anchor: .trailing)
                                }
                            }
                        }
                    }
                }
                .frame(height: min(40, UIScreen.main.bounds.width * 0.1))
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