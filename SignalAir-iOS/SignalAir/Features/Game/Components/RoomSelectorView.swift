import SwiftUI

struct RoomSelectorView: View {
    let rooms: [BingoRoom]
    let onJoinRoom: (BingoRoom) -> Void
    @EnvironmentObject var languageService: LanguageService
    
    // 防抖動機制
    @State private var isJoiningRoom = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageService.t("select_room"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(rooms) { room in
                    Button(action: { 
                        // 防止多次點擊
                        guard !isJoiningRoom else { return }
                        isJoiningRoom = true
                        
                        Task {
                            onJoinRoom(room)
                            await MainActor.run {
                                // 延遲重置按鈕狀態，確保房間進入流程完成
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    isJoiningRoom = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text(room.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                            if isJoiningRoom {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("加入中...")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                            } else {
                                Text("\(room.players.count) \(languageService.t("players"))")
                                    .font(.subheadline)
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isJoiningRoom ? Color.gray.opacity(0.3) : Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
                        .cornerRadius(8)
                    }
                    .disabled(isJoiningRoom)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    RoomSelectorView(
        rooms: [
            BingoRoom(id: 1, name: "room A", players: [], currentNumbers: [], isActive: false),
            BingoRoom(id: 2, name: "room B", players: [], currentNumbers: [], isActive: false),
            BingoRoom(id: 3, name: "room C", players: [], currentNumbers: [], isActive: false)
        ],
        onJoinRoom: { _ in }
    )
    .padding()
} 