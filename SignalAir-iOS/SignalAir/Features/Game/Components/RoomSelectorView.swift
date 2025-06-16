import SwiftUI

struct RoomSelectorView: View {
    let rooms: [BingoRoom]
    let onJoinRoom: (BingoRoom) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇房間")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(rooms) { room in
                    Button(action: { onJoinRoom(room) }) {
                        HStack {
                            Text(room.name)
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(room.players.count) 玩家")
                                .font(.subheadline)
                                .opacity(0.8)
                        }
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
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