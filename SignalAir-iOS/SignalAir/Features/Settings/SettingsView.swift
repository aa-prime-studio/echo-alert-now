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
                Text(languageService.t("language"))
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
                Text(languageService.t("subscription_status"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchaseService.isPremiumUser ? languageService.t("premium_user") : languageService.t("free_user"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(purchaseService.isPremiumUser ? .green : .orange)
                    
                    if purchaseService.isPremiumUser {
                        Text(languageService.t("full_features"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(languageService.t("signal_chat_features"))
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
                        Text(languageService.t("upgrade_unlock_games"))
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
                Text(languageService.t("restore_purchases"))
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
                title: languageService.t("nickname"),
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
                title: languageService.t("device_name"),
                value: UIDevice.current.name,
                action: nil
            )
            
            Divider()
            
            SettingsRowView(
                icon: "info.circle",
                title: languageService.t("version"),
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
                    title: languageService.t("privacy_policy"),
                    value: nil,
                    action: {}
                )
            }
            
            Divider()
            
            NavigationLink(destination: TermsOfServiceView()) {
                SettingsRowView(
                    icon: "doc.text",
                    title: languageService.t("terms_of_service"),
                    value: nil,
                    action: {}
                )
            }
            
            Divider()
            
            NavigationLink(destination: HelpView()) {
                SettingsRowView(
                    icon: "questionmark.circle",
                    title: languageService.t("help_guide"),
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
            .navigationTitle(languageService.t("select_language"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(languageService.t("done")) { dismiss() })
        }
    }
}

struct NicknameEditView: View {
    @ObservedObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    @State private var tempNickname: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageService.t("set_nickname"))
                        .font(.headline)
                    
                    Text(nicknameService.getRemainingChangesText())
                        .font(.caption)
                        .foregroundColor(nicknameService.canChangeNickname() ? .secondary : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField(languageService.t("enter_new_nickname"), text: $tempNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!nicknameService.canChangeNickname())
                    
                    Text(languageService.t("nickname_max_chars"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(languageService.t("edit_nickname"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(languageService.t("cancel")) { dismiss() },
                trailing: Button(languageService.t("save")) {
                    saveNickname()
                }
                .disabled(!nicknameService.canChangeNickname() || tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
        .onAppear {
            tempNickname = nicknameService.nickname
        }
        .alert(languageService.t("alert"), isPresented: $showingAlert) {
            Button(languageService.t("confirm")) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveNickname() {
        let trimmedNickname = tempNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNickname.isEmpty {
            alertMessage = languageService.t("nickname_empty")
            showingAlert = true
            return
        }
        
        if trimmedNickname.count > 20 {
            alertMessage = languageService.t("nickname_too_long")
            showingAlert = true
            return
        }
        
        if nicknameService.updateNickname(trimmedNickname) {
            alertMessage = languageService.t("nickname_updated") + "\n\(nicknameService.getRemainingChangesText())"
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else if !nicknameService.canChangeNickname() {
            alertMessage = languageService.t("nickname_max_reached")
            showingAlert = true
        } else {
            alertMessage = languageService.t("nickname_no_change")
            showingAlert = true
        }
    }
}
