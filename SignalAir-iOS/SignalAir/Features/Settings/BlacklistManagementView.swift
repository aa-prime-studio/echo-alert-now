import SwiftUI

struct BlacklistManagementView: View {
    @StateObject private var blacklistManager = ServiceContainer.shared.localBlacklistManager
    @State private var showingClearAllDialog = false
    @State private var userToRemove: String?
    @State private var showingRemoveDialog = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            if blacklistManager.blacklistedUsers.isEmpty {
                emptyStateView
            } else {
                blacklistListView
            }
        }
        .background(Color.gray.opacity(0.05))
        .navigationBarHidden(true)
        .confirmationDialog("移除黑名單", isPresented: $showingRemoveDialog) {
            Button("移除", role: .destructive) {
                if let userId = userToRemove {
                    blacklistManager.removeFromBlacklist(userId: userId)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("確定要將此用戶從黑名單中移除嗎？")
        }
        .confirmationDialog("清空黑名單", isPresented: $showingClearAllDialog) {
            Button("清空", role: .destructive) {
                blacklistManager.clearBlacklist()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("確定要清空整個黑名單嗎？此操作無法撤銷。")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    // 返回上一頁
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                }
                
                Spacer()
                
                Text("黑名單管理")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 清空按鈕
                Button(action: {
                    showingClearAllDialog = true
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .disabled(blacklistManager.blacklistedUsers.isEmpty)
            }
            .padding(.horizontal)
            
            // 統計信息
            HStack(spacing: 20) {
                StatCard(
                    title: "已封禁",
                    value: "\(blacklistManager.blacklistedUsers.count)",
                    icon: "person.fill.xmark"
                )
                
                StatCard(
                    title: "今日新增",
                    value: "\(blacklistManager.getBlacklistStats().blockedToday)",
                    icon: "calendar"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.white)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("黑名單為空")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("在聊天室中長按用戶暱稱即可加入黑名單")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var blacklistListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(blacklistManager.blacklistedUsers) { user in
                    BlacklistUserCard(
                        user: user,
                        onRemove: {
                            userToRemove = user.id.uuidString
                            showingRemoveDialog = true
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BlacklistUserCard: View {
    let user: BlacklistedUser
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // 用戶頭像
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.deviceName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("封禁時間：\(formatDate(user.blockedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    BlacklistManagementView()
}