import SwiftUI

struct EmoteGridView: View {
    let onEmoteSelected: (EmoteType) -> Void
    @EnvironmentObject var languageService: LanguageService
    
    let emotes: [EmoteType] = [
        .bingo, .nen, .wow, .boom,
        .pirate, .rocket, .bug, .fly,
        .fire, .poop, .clown, .mindBlown,
        .pinch, .cockroach, .eyeRoll, .burger,
        .rockOn, .battery, .dizzy, .bottle,
        .skull, .mouse, .trophy, .ring, .juggler
    ]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageService.t("emote_broadcast"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emotes, id: \.self) { emote in
                        Button(action: {
                            onEmoteSelected(emote)
                        }) {
                            Text(emote.emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.1))
                                .cornerRadius(22)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    EmoteGridView(onEmoteSelected: { _ in })
        .environmentObject(LanguageService())
}