import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var nicknameService: NicknameService
    @State private var showingPurchaseSheet = false
    @State private var showingLanguageSheet = false
    @State private var showingNicknameSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 20) {
                        languageSection
                        subscriptionSection
                        upgradeSection
                        deviceSection
                        legalSection
                    }
                    .padding()
                }
            }
            .background(Color.gray.opacity(0.05))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPurchaseSheet) {
            PurchaseOptionsView(purchaseService: purchaseService)
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionView(languageService: languageService)
        }
        .sheet(isPresented: $showingNicknameSheet) {
            NicknameEditView(nicknameService: nicknameService)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Spacer()
            Button(action: { showingPurchaseSheet = true }) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
    }
    
    private var languageSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("語言")
                    .font(.headline)
                Spacer()
                Text(languageService.currentLanguage.displayName)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                showingLanguageSheet = true
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("訂購狀態")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchaseService.isPremiumUser ? "付費用戶" : "免費用戶")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(purchaseService.isPremiumUser ? .green : .orange)
                    
                    if purchaseService.isPremiumUser {
                        Text("享有完整功能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("訊號、聊天室功能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                if purchaseService.isPremiumUser {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Image(systemName: "lock.circle")
                        .foregroundColor(.orange)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private var upgradeSection: some View {
        VStack(spacing: 12) {
            if !purchaseService.isPremiumUser {
                Button(action: { showingPurchaseSheet = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("升級解鎖遊戲功能")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.67, green: 0.57, blue: 0.89))
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                Task {
                    await purchaseService.restorePurchases()
                }
            }) {
                Text("恢復購買")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
    }
    
    private var deviceSection: some View {
        VStack(spacing: 0) {
            SettingsRowView(
                icon: "person.circle",
                title: "暱稱",
                value: nicknameService.nickname,
                action: nicknameService.canChangeNickname() ? { showingNicknameSheet = true } : nil
            )
            
            if !nicknameService.canChangeNickname() {
                HStack {
                    Spacer()
                    Text(nicknameService.getRemainingChangesText())
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            SettingsRowView(
                icon: "iphone",
                title: "裝置名稱",
                value: UIDevice.current.name,
                action: nil
            )
            
            Divider()
            
            SettingsRowView(
                icon: "info.circle",
                title: "版本",
                value: "1.0.0",
                action: nil
            )
        }
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var legalSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: PrivacyPolicyView()) {
                SettingsRowView(
                    icon: "lock.shield",
                    title: "隱私權政策",
                    value: nil,
                    action: {}
                )
            }
            
            Divider()
            
            NavigationLink(destination: TermsOfServiceView()) {
                SettingsRowView(
                    icon: "doc.text",
                    title: "服務條款",
                    value: nil,
                    action: {}
                )
            }
            
            Divider()
            
            NavigationLink(destination: HelpView()) {
                SettingsRowView(
                    icon: "questionmark.circle",
                    title: "使用說明",
                    value: nil,
                    action: {}
                )
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let value: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

struct LanguageSelectionView: View {
    @ObservedObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ForEach(LanguageService.Language.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                            .font(.headline)
                        Spacer()
                        if languageService.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        languageService.setLanguage(language)
                        dismiss()
                    }
                    
                    if language != LanguageService.Language.allCases.last {
                        Divider()
                    }
                }
                Spacer()
            }
            .background(Color.white)
            .navigationTitle("選擇語言")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") { dismiss() })
        }
    }
}

struct NicknameEditView: View {
    @ObservedObject var nicknameService: NicknameService
    @Environment(\.dismiss) private var dismiss
    @State private var tempNickname: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("設定暱稱")
                        .font(.headline)
                    
                    Text(nicknameService.getRemainingChangesText())
                        .font(.caption)
                        .foregroundColor(nicknameService.canChangeNickname() ? .secondary : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("輸入新暱稱", text: $tempNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!nicknameService.canChangeNickname())
                    
                    Text("暱稱最多20個字元")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("編輯暱稱")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("儲存") {
                    saveNickname()
                }
                .disabled(!nicknameService.canChangeNickname() || tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
        .onAppear {
            tempNickname = nicknameService.nickname
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("確定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveNickname() {
        let trimmedNickname = tempNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNickname.isEmpty {
            alertMessage = "暱稱不能為空"
            showingAlert = true
            return
        }
        
        if trimmedNickname.count > 20 {
            alertMessage = "暱稱不能超過20個字元"
            showingAlert = true
            return
        }
        
        if nicknameService.updateNickname(trimmedNickname) {
            alertMessage = "暱稱更新成功！\n\(nicknameService.getRemainingChangesText())"
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else if !nicknameService.canChangeNickname() {
            alertMessage = "已用完修改次數"
            showingAlert = true
        } else {
            alertMessage = "暱稱沒有變更"
            showingAlert = true
        }
    }
}
