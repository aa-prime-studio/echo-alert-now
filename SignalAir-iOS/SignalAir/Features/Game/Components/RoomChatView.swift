import SwiftUI

struct RoomChatView: View {
    let roomName: String
    let messages: [RoomChatMessage]
    let newMessage: String
    let onMessageChange: (String) -> Void
    let onSendMessage: () -> Void
    @EnvironmentObject var languageService: LanguageService
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(roomName) \(languageService.t("chat_room"))")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Messages List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        ChatMessageRow(message: message)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Input Section
            HStack(spacing: 12) {
                TextField(languageService.t("enter_message"), text: Binding(
                    get: { newMessage },
                    set: onMessageChange
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .onSubmit {
                    if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSendMessage()
                        isTextFieldFocused = false // 發送後關閉鍵盤
                    }
                }
                
                Button(action: {
                    onSendMessage()
                    isTextFieldFocused = false // 點擊發送後關閉鍵盤
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                        .cornerRadius(18)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct ChatMessageRow: View {
    let message: RoomChatMessage
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        HStack {
            if message.isOwn {
                Spacer()
            }
            
            VStack(alignment: message.isOwn ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if !message.isOwn {
                        Text(NicknameFormatter.cleanNickname(message.playerName))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                    }
                    
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if message.isOwn {
                        Text(languageService.t("me"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                    }
                }
                
                Text(message.message)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isOwn ? 
                        Color(red: 0.149, green: 0.243, blue: 0.894) : // #263ee4
                        Color.gray.opacity(0.2)
                    )
                    .foregroundColor(message.isOwn ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !message.isOwn {
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    RoomChatView(
        roomName: "room A",
        messages: [
            RoomChatMessage(
                message: "加油！",
                playerName: "BingoKing",
                timestamp: Date().timeIntervalSince1970 - 60,
                isOwn: false
            ),
            RoomChatMessage(
                message: "我差一條線就贏了！",
                playerName: "iPhone",
                timestamp: Date().timeIntervalSince1970 - 30,
                isOwn: true
            ),
            RoomChatMessage(
                message: "好運氣！",
                playerName: "LuckyStrike",
                timestamp: Date().timeIntervalSince1970,
                isOwn: false
            )
        ],
        newMessage: "",
        onMessageChange: { _ in },
        onSendMessage: { }
    )
} 