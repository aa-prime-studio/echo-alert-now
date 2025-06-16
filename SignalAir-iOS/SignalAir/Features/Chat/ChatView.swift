import SwiftUI
import Foundation

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    
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
                    Text(languageService.t("auto_delete_24h"))
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
                        Text(languageService.t("no_messages"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(languageService.t("send_first_message"))
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
                TextField(languageService.t("enter_message"), text: $viewModel.newMessage)
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
            
            Text(languageService.t("auto_delete_info"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color.white)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let formatTime: (TimeInterval) -> String
    @EnvironmentObject var languageService: LanguageService
    
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
                        Text(languageService.t("me"))
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
