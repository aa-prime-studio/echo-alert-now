import SwiftUI
import Foundation

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var nicknameService: NicknameService
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            messagesSection
            Divider()
            inputSection.padding()
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            viewModel.deviceName = nicknameService.nickname
        }
        .onChange(of: nicknameService.nickname) { newNickname in
            viewModel.deviceName = newNickname
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Support\nChatroom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.8))
                    Text("24小時自動清除")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Text("(\(viewModel.messages.count))")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                Button(action: { viewModel.clearMessages() }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(Color(red: 0.671, green: 0.576, blue: 0.898)) // #ab93e5
    }
    
    private var messagesSection: some View {
        Group {
            if viewModel.messages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    VStack(spacing: 8) {
                        Text("目前沒有訊息")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("發送第一條訊息開始對話")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message, formatTime: viewModel.formatTime)
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                TextField("輸入訊息...", text: $viewModel.newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { viewModel.sendMessage() }
                
                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Text("訊息會在24小時後自動刪除 • 最多顯示50條訊息")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color.white)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let formatTime: (TimeInterval) -> String
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                if message.isOwn { Spacer() }
                
                VStack(alignment: message.isOwn ? .trailing : .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if !message.isOwn {
                            Text(message.deviceName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if message.isOwn {
                            Text("我")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(message.message)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(message.isOwn ? Color.blue : Color.white)
                        .foregroundColor(message.isOwn ? .white : .primary)
                        .cornerRadius(16)
                }
                .frame(maxWidth: geometry.size.width * 0.7, alignment: message.isOwn ? .trailing : .leading)
                
                if !message.isOwn { Spacer() }
            }
        }
        .frame(height: 60) // Set a fixed height for the GeometryReader
    }
}
