import SwiftUI
import Foundation

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var blacklistManager = ServiceContainer.shared.localBlacklistManager
    @State private var selectedUserForBlacklist: String = ""
    @State private var showBlacklistDialog = false
    
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
            viewModel.deviceName = nicknameService.userNickname
        }
        .onChange(of: nicknameService.nickname) { _, newNickname in
            viewModel.deviceName = newNickname
        }
        .confirmationDialog("用戶操作", isPresented: $showBlacklistDialog) {
            Button("加入黑名單") {
                blacklistManager.addToBlacklist(deviceName: selectedUserForBlacklist)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("要將 \(NicknameFormatter.cleanNickname(selectedUserForBlacklist)) 加入黑名單嗎？")
        }
    }
    
    // MARK: - Computed Properties
    
    /// 過濾黑名單用戶的訊息
    private var filteredMessages: [ChatMessage] {
        return viewModel.messages.filter { message in
            !blacklistManager.isBlacklisted(deviceName: message.deviceName)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 發送訊息並收回鍵盤
    private func sendMessageAndDismissKeyboard() {
        guard !viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage()
        isTextFieldFocused = false // 收回鍵盤
        
        // 強制隱藏鍵盤
        hideKeyboard()
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Support\nChatroom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.671, green: 0.576, blue: 0.898)) // #ab93e5
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.8)) // #263ee4
                    Text(languageService.t("auto_delete_24h"))
                        .font(.caption)
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.8)) // #263ee4
                }
            }
            Spacer()
            HStack(spacing: 12) {
            Text("(\(viewModel.messages.count))")
                .font(.subheadline)
                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894).opacity(0.8)) // #263ee4
            Button(action: { viewModel.clearMessages() }) {
                Image(systemName: "trash")
                    .font(.title3)
                        .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                }
            }
        }
        .padding()
        .background(.white)
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMessages) { message in
                                ChatMessageView(
                                    message: message, 
                                    formatTime: viewModel.formatTime,
                                    selectedUserForBlacklist: $selectedUserForBlacklist,
                                    showBlacklistDialog: $showBlacklistDialog
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                    .onChange(of: filteredMessages.count) { _, _ in
                        // 當有新訊息時自動滾動到底部
                        if let lastMessage = filteredMessages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // 初次載入時滾動到底部
                        if let lastMessage = filteredMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                MentionTextField(
                    text: $viewModel.newMessage,
                    placeholder: languageService.t("enter_message"),
                    availableUsers: viewModel.getAvailableUsers(),
                    onSubmit: { sendMessageAndDismissKeyboard() }
                )
                
                Button(action: { sendMessageAndDismissKeyboard() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.671, green: 0.576, blue: 0.898))
                        .cornerRadius(8)
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Text(languageService.t("auto_delete_info"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let formatTime: (TimeInterval) -> String
    @Binding var selectedUserForBlacklist: String
    @Binding var showBlacklistDialog: Bool
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var nicknameService: NicknameService
    
    var body: some View {
        GeometryReader { geometry in
        HStack {
            if message.isOwn { Spacer() }
            
            VStack(alignment: message.isOwn ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // 提及我的標記
                    if message.mentionsMe && !message.isOwn {
                        Image(systemName: "at.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                    }
                    
                    if !message.isOwn {
                        Text(NicknameFormatter.cleanNickname(message.deviceName))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .onLongPressGesture {
                                selectedUserForBlacklist = message.deviceName
                                showBlacklistDialog = true
                            }
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
                
                // 使用 AttributedString 來支援 @提及高亮
                Text(createAttributedMessage(message.message))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(backgroundColor)
                    .foregroundColor(message.isOwn ? .white : .primary)
                    .cornerRadius(16)
            }
                .frame(maxWidth: geometry.size.width * 0.7, alignment: message.isOwn ? .trailing : .leading)
            
            if !message.isOwn { Spacer() }
        }
        }
        .frame(height: 60) // Set a fixed height for the GeometryReader
    }
    
    private var backgroundColor: Color {
        if message.isOwn {
            return Color.blue
        } else if message.mentionsMe {
            return Color(red: 0.0, green: 0.843, blue: 0.416).opacity(0.1) // 淺綠色背景表示提及我
        } else {
            return Color.white
        }
    }
    
    private func createAttributedMessage(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 找出所有的 @提及
        let mentions = ChatMessage.extractMentions(from: text)
        let myNickname = NicknameFormatter.cleanNickname(nicknameService.userNickname)
        
        for mention in mentions {
            let mentionText = "@\(mention)"
            if let range = attributedString.range(of: mentionText) {
                // 被提及的使用者名稱顯示綠色（設置內文圖標色彩）
                attributedString[range].foregroundColor = Color(red: 0.0, green: 0.843, blue: 0.416)
                attributedString[range].font = .system(size: 16, weight: .medium)
                
                // 如果提及的是我，額外添加底線
                if NicknameFormatter.cleanNickname(mention) == myNickname {
                    attributedString[range].underlineStyle = .single
                }
            }
        }
        
        return attributedString
    }
}

// MARK: - 鍵盤管理擴展
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - MentionTextField Implementation

// MentionAutocompleteView moved to separate file - Components/MentionAutocompleteView.swift

struct MentionTextField: View {
    @Binding var text: String
    @State private var showingMentionList = false
    @State private var filteredUsers: [String] = []
    @State private var currentMentionPrefix = ""
    @State private var mentionStartIndex: String.Index?
    @FocusState private var isFocused: Bool
    
    let placeholder: String
    let availableUsers: [String]
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 自動補全列表 - 顯示在輸入框上方
            if showingMentionList {
                MentionAutocompleteView(
                    users: filteredUsers,
                    onSelectUser: { selectedUser in
                        insertMention(selectedUser)
                    },
                    onDismiss: {
                        dismissMentionList()
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: showingMentionList)
            }
            
            // 輸入框
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .onSubmit {
                    onSubmit()
                    isFocused = false
                    // 強制隱藏鍵盤
                    hideKeyboard()
                }
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(newValue)
                }
                .onTapGesture {
                    // 檢查是否需要顯示提及列表
                    checkForMentionAtCursor()
                }
        }
    }
    
    private func handleTextChange(_ newText: String) {
        // 檢查是否在輸入 @ 提及
        if let cursorPosition = getCursorPosition() {
            checkForMentionAt(position: cursorPosition, in: newText)
        }
    }
    
    private func checkForMentionAt(position: String.Index, in text: String) {
        // 從游標位置向前搜尋 @ 符號
        var searchIndex = position
        var foundAt = false
        var mentionText = ""
        
        // 向前搜尋直到找到 @ 或空白字符
        while searchIndex > text.startIndex {
            searchIndex = text.index(before: searchIndex)
            let char = text[searchIndex]
            
            if char == "@" {
                foundAt = true
                mentionStartIndex = searchIndex
                break
            } else if char.isWhitespace || char.isNewline {
                break
            } else {
                mentionText = String(char) + mentionText
            }
        }
        
        if foundAt {
            // 取得 @ 後面的文字
            let afterAtIndex = text.index(after: searchIndex)
            if afterAtIndex < position {
                mentionText = String(text[afterAtIndex..<position])
            }
            
            currentMentionPrefix = mentionText
            filterUsers(with: mentionText)
            showingMentionList = !filteredUsers.isEmpty
        } else {
            dismissMentionList()
        }
    }
    
    private func checkForMentionAtCursor() {
        if let cursorPosition = getCursorPosition() {
            checkForMentionAt(position: cursorPosition, in: text)
        }
    }
    
    private func getCursorPosition() -> String.Index? {
        // 簡化版本：返回文字結尾位置
        return text.endIndex
    }
    
    private func filterUsers(with prefix: String) {
        if prefix.isEmpty {
            filteredUsers = Array(availableUsers.prefix(5))
        } else {
            filteredUsers = availableUsers.filter { user in
                NicknameFormatter.cleanNickname(user).localizedCaseInsensitiveContains(prefix)
            }.prefix(5).map { $0 }
        }
    }
    
    private func insertMention(_ user: String) {
        guard let startIndex = mentionStartIndex else { return }
        
        let cleanUserName = NicknameFormatter.cleanNickname(user)
        let mentionText = "@\(cleanUserName) "
        
        // 計算要替換的範圍
        let endIndex = text.index(startIndex, offsetBy: currentMentionPrefix.count + 1, limitedBy: text.endIndex) ?? text.endIndex
        
        // 替換文字
        text.replaceSubrange(startIndex..<endIndex, with: mentionText)
        
        dismissMentionList()
    }
    
    private func dismissMentionList() {
        showingMentionList = false
        filteredUsers = []
        currentMentionPrefix = ""
        mentionStartIndex = nil
    }
}
