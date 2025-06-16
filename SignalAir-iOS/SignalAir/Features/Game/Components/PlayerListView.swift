import SwiftUI

struct PlayerListView: View {
    let players: [RoomPlayer]
    let deviceName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("房間玩家")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(players) { player in
                    HStack {
                        // Player name with indicator for self
                        HStack(spacing: 8) {
                            if player.name == deviceName {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                            }
                            
                            Text(player.name)
                                .font(.subheadline)
                                .fontWeight(player.name == deviceName ? .semibold : .regular)
                                .foregroundColor(player.name == deviceName ? Color(red: 0.149, green: 0.243, blue: 0.894) : .primary)
                        }
                        
                        Spacer()
                        
                        // Progress and status
                        HStack(spacing: 8) {
                            Text("\(player.completedLines)線")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            if player.hasWon {
                                Text("🎉")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        player.name == deviceName ? 
                        Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.1) : 
                        Color.clear
                    )
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    PlayerListView(
        players: [
            RoomPlayer(name: "BingoKing", completedLines: 3, hasWon: false),
            RoomPlayer(name: "iPhone", completedLines: 2, hasWon: false),
            RoomPlayer(name: "LuckyStrike", completedLines: 6, hasWon: true),
            RoomPlayer(name: "NumberHunter", completedLines: 1, hasWon: false)
        ],
        deviceName: "iPhone"
    )
} 