import SwiftUI

struct MentionAutocompleteView: View {
    let users: [String]
    let onSelectUser: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        if !users.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(users, id: \.self) { user in
                    Button(action: {
                        onSelectUser(user)
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Color(red: 38/255, green: 62/255, blue: 234/255)) // 訊號頁面"我安全"按鈕藍色
                                .font(.system(size: 16))
                            
                            Text(user)
                                .foregroundColor(.primary)
                                .font(.system(size: 16))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if user != users.last {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

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
                }
                .onChange(of: text) { newValue in
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
        // 在實際應用中，你可能需要更精確的游標位置檢測
        return text.endIndex
    }
    
    private func filterUsers(with prefix: String) {
        if prefix.isEmpty {
            filteredUsers = Array(availableUsers.prefix(5)) // 最多顯示5個使用者
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

#Preview {
    VStack {
        MentionTextField(
            text: .constant("Hello @"),
            placeholder: "輸入訊息...",
            availableUsers: ["小明", "小華", "小美", "阿強"],
            onSubmit: {}
        )
        .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}