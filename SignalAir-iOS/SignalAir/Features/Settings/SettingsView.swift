import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var nicknameService: NicknameService
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var showingPurchaseSheet = false
    @State private var showingLanguageSheet = false
    @State private var isEditingNickname = false
    @State private var tempNickname: String = ""
    @State private var showingTestResults = false
    @State private var testOutput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 20) {
                        upgradeSection
                        
                        // 語言和訂購區塊
                        VStack(spacing: 0) {
                            languageSection
                            Divider()
                            subscriptionSection
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // 裝置資訊區塊
                        VStack(spacing: 0) {
                            deviceSection
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // 安全和法律區塊
                        VStack(spacing: 0) {
                            securitySection
                            Divider()
                            legalSection
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // DEBUG: 測試區塊
                        #if DEBUG
                        VStack(spacing: 0) {
                            debugTestSection
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        #endif
                        
                        // 恢復購買按鈕移到法律條款下方
                        HStack {
                            Spacer()
                            Button(action: {
                                Task {
                                    await purchaseService.restorePurchases()
                                }
                            }) {
                                Text(languageService.t("restore_purchases"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .disabled(purchaseService.isLoading)
                        }
                        .padding(.top, 8)
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
        .sheet(isPresented: $showingTestResults) {
            NavigationView {
                ScrollView {
                    Text(testOutput)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .navigationTitle("網絡測試結果")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("關閉") {
                            showingTestResults = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionView(languageService: languageService)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
            Spacer()
            Button(action: { showingPurchaseSheet = true }) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
            }
        }
        .padding()
        .background(.white)
    }
    
    private var languageSection: some View {
        SettingsRowView(
            icon: "globe",
            title: languageService.t("language"),
            value: languageService.currentLanguage.displayName,
            action: { showingLanguageSheet = true }
        )
    }
    
    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            SettingsRowView(
                icon: "heart.fill",
                title: languageService.t("subscription_status"),
                value: {
                    if let tierName = purchaseService.getPurchasedTierDisplayName(language: PurchaseService.convertLanguage(languageService.currentLanguage)) {
                        return tierName
                    } else {
                        return languageService.t("free_user")
                    }
                }(),
                action: nil
            )
            
            if purchaseService.isPremiumUser {
                Divider()
                
                SettingsRowView(
                    icon: "checkmark.circle.fill",
                    title: languageService.t("full_features"),
                    value: nil,
                    action: nil
                )
            } else {
                Divider()
                
                SettingsRowView(
                    icon: "antenna.radiowaves.left.and.right",
                    title: languageService.t("signal_chat_features"),
                    value: nil,
                    action: nil
                )
            }
        }
    }
    
    private var upgradeSection: some View {
        VStack(spacing: 12) {
            if !purchaseService.isPremiumUser {
                Button(action: { showingPurchaseSheet = true }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(languageService.t("upgrade_unlock_games"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.843, blue: 0.416))
                    .cornerRadius(12)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var deviceSection: some View {
        VStack(spacing: 0) {
            if isEditingNickname {
                // 編輯模式
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                            .frame(width: 24)
                        
                        Text(languageService.t("nickname"))
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(languageService.t("cancel")) {
                            isEditingNickname = false
                        }
                        .foregroundColor(.gray)
                        .font(.caption)
                        
                        Button(languageService.t("done")) {
                            saveNickname()
                        }
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .font(.caption)
                        .disabled(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                 tempNickname.trimmingCharacters(in: .whitespacesAndNewlines) == nicknameService.nickname)
                    }
                    .padding()
                    
                    TextField(languageService.t("enter_new_nickname"), text: $tempNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    HStack {
                        Spacer()
                        Text(nicknameService.getRemainingChangesText(languageService: languageService))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            } else {
                // 顯示模式
                SettingsRowView(
                    icon: "person.circle",
                    title: languageService.t("nickname"),
                    value: nicknameService.displayName,
                    action: { 
                        tempNickname = nicknameService.nickname
                        isEditingNickname = true
                    }
                )
                
                HStack {
                    Spacer()
                    Text(nicknameService.getRemainingChangesText(languageService: languageService))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            SettingsRowView(
                icon: "iphone",
                title: languageService.t("device_name"),
                value: serviceContainer.temporaryIDManager.deviceID,
                action: nil
            )
            
            HStack {
                Spacer()
                Text(languageService.t("midnight_auto_update"))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            SettingsRowView(
                icon: "info.circle",
                title: languageService.t("version"),
                value: "1.0.0",
                action: nil
            )
        }
    }
    
    
    private var securitySection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: BlacklistManagementView()) {
                HStack {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 24)
                    
                    Text("黑名單管理")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // 顯示黑名單數量
                    Text("\(serviceContainer.localBlacklistManager.blacklistedUsers.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            
            Divider()
            
            NavigationLink(destination: SecurityLogView(securityLogManager: serviceContainer.securityLogManager).environmentObject(languageService)) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 24)
                    
                    Text("安全日誌")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // 顯示最近日誌數量
                    Text("\(serviceContainer.securityLogManager.recentLogs.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: TermsOfServiceView().environmentObject(languageService)) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 24)
                    
                    Text(languageService.t("terms_of_service"))
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            
            Divider()
            
            NavigationLink(destination: PrivacyPolicyView().environmentObject(languageService)) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 24)
                    
                    Text(languageService.t("privacy_policy"))
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            
            Divider()
            
            NavigationLink(destination: HelpView().environmentObject(languageService)) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        .frame(width: 24)
                    
                    Text(languageService.t("help_guide"))
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            
            // 🔍 診斷工具（僅開發/測試用）
            Divider()
            
            Button(action: {
                serviceContainer.networkService.performQuickDiagnostic()
                print(serviceContainer.networkService.getDiagnosticReport())
            }) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text(languageService.t("network_diagnosis"))
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                .padding()
            }
        }
    }
    
    private var debugTestSection: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Image(systemName: "ladybug")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                Text("🧪 網絡測試工具")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("DEBUG")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding()
            
            Divider()
            
            // 測試按鈕們
            VStack(spacing: 0) {
                Button(action: {
                    runMessageRoutingTest()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("🧪 測試消息路由")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle")
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
                
                Divider()
                
                Button(action: {
                    runNetworkIntegrationTest()
                }) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text("🌐 測試網絡集成")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle")
                            .foregroundColor(.purple)
                    }
                    .padding()
                }
                
                Divider()
                
                Button(action: {
                    runNetworkDiagnosis()
                }) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Text("🔍 診斷網絡狀態")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle")
                            .foregroundColor(.orange)
                    }
                    .padding()
                }
                
                Divider()
                
                Button(action: {
                    testKeyExchangeOptimization()
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text("🔑 測試密鑰交換優化")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle")
                            .foregroundColor(.purple)
                    }
                    .padding()
                }
                
                Divider()
                
                Button(action: {
                    showingTestResults = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text("📋 查看測試結果")
                            .font(.body)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "eye")
                            .foregroundColor(.green)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func runMessageRoutingTest() {
        appendToTestOutput("🧪 開始執行消息路由測試...")
        
        // 簡化測試 - 檢查基本的消息路由組件
        appendToTestOutput("📡 檢查消息路由組件:")
        
        // 檢查 NetworkService
        let networkService = serviceContainer.networkService
        appendToTestOutput("  - NetworkService.onDataReceived: \(networkService.onDataReceived != nil ? "已設置" : "未設置")")
        
        // 檢查 MeshManager
        if let meshManager = serviceContainer.meshManager {
            appendToTestOutput("  - MeshManager.onGameMessageReceived: \(meshManager.onGameMessageReceived != nil ? "已設置" : "未設置")")
        } else {
            appendToTestOutput("  - MeshManager: 未初始化")
        }
        
        appendToTestOutput("✅ 消息路由測試完成")
    }
    
    private func runNetworkIntegrationTest() {
        appendToTestOutput("🌐 開始執行網絡集成測試...")
        
        // 簡化的網絡集成測試
        if let meshManager = serviceContainer.meshManager {
            appendToTestOutput("✅ MeshManager 實例存在")
            appendToTestOutput("🔗 連接狀態: \(meshManager.isActive ? "活躍" : "非活躍")")
            appendToTestOutput("👥 連接的對等體: \(meshManager.getConnectedPeers().count)")
        } else {
            appendToTestOutput("❌ MeshManager 實例不存在")
        }
        
        appendToTestOutput("✅ 網絡集成測試完成")
    }
    
    private func runNetworkDiagnosis() {
        appendToTestOutput("🔍 開始執行網絡診斷...")
        
        // 診斷 NetworkService
        let networkService = serviceContainer.networkService
        appendToTestOutput("📡 NetworkService 狀態:")
        appendToTestOutput("  - isConnected: \(networkService.isConnected)")
        appendToTestOutput("  - myPeerID: \(networkService.myPeerID.displayName)")
        appendToTestOutput("  - connectedPeers: \(networkService.connectedPeers.count)")
        
        // 診斷 MeshManager
        if let meshManager = serviceContainer.meshManager {
            appendToTestOutput("🌐 MeshManager 狀態:")
            appendToTestOutput("  - isActive: \(meshManager.isActive)")
            appendToTestOutput("  - connectedPeers: \(meshManager.getConnectedPeers().count)")
            appendToTestOutput("  - onGameMessageReceived: \(meshManager.onGameMessageReceived != nil ? "已設置" : "未設置")")
        } else {
            appendToTestOutput("❌ MeshManager 實例不存在")
        }
        
        // 診斷完成
        
        appendToTestOutput("✅ 網絡診斷完成")
    }
    
    private func testKeyExchangeOptimization() {
        appendToTestOutput("🔑 開始測試密鑰交換優化...")
        
        // 測試密鑰交換狀態追蹤
        let connectedPeers = serviceContainer.networkService.connectedPeers
        if connectedPeers.isEmpty {
            appendToTestOutput("⚠️ 沒有連接的對等設備進行測試")
            return
        }
        
        appendToTestOutput("📊 密鑰交換狀態檢查:")
        Task {
            for peer in connectedPeers {
                let hasKey = await serviceContainer.securityService.hasSessionKey(for: peer.displayName)
                appendToTestOutput("  - \(peer.displayName): \(hasKey ? "已有密鑰" : "無密鑰")")
            }
            
            appendToTestOutput("⚡ 優化內容:")
            appendToTestOutput("  - 監控頻率: 60秒 → 180秒 (減少66%)")
            appendToTestOutput("  - 密鑰交換超時: 15秒 → 8秒 (減少47%)")
            appendToTestOutput("  - 等待超時: 3秒 → 2秒 (減少33%)")
            appendToTestOutput("  - 重試延遲: 2秒 → 1秒 (減少50%)")
            appendToTestOutput("  - 添加狀態追蹤防止重複交換")
            appendToTestOutput("  - 失敗設備5分鐘後才重試")
            
            appendToTestOutput("✅ 密鑰交換優化測試完成")
        }
    }
    
    private func appendToTestOutput(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        testOutput += "[\(timestamp)] \(message)\n"
    }
    
    private func saveNickname() {
        let trimmedNickname = tempNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNickname.isEmpty {
            return
        }
        
        if trimmedNickname.count > 8 {
            return
        }
        
        if nicknameService.updateNickname(trimmedNickname) {
            isEditingNickname = false
        }
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
                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                .frame(width: 24)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
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
    @State private var shouldDismiss = false
    
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
                                .foregroundColor(Color(red: 0.0, green: 0.843, blue: 0.416))
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        languageService.setLanguage(language)
                        shouldDismiss = true
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
            .navigationBarItems(trailing: Button(languageService.t("done")) { 
                // 簡化關閉邏輯
            })
        }
    }
}

struct NicknameEditView: View {
    @ObservedObject var nicknameService: NicknameService
    @EnvironmentObject var languageService: LanguageService
    @Binding var tempNickname: String
    @Binding var isPresented: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(languageService.t("cancel")) {
                    isPresented = false
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Text(languageService.t("edit_nickname"))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(languageService.t("save")) {
                    saveNickname()
                }
                .fontWeight(.semibold)
                .disabled(tempNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                         tempNickname.trimmingCharacters(in: .whitespacesAndNewlines) == nicknameService.nickname)
            }
            .padding()
            
            // Content
            VStack(spacing: 16) {
                TextField(languageService.t("enter_new_nickname"), text: $tempNickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.headline)
                
                Text(nicknameService.getRemainingChangesText())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .alert(languageService.t("alert"), isPresented: $showingAlert) {
            Button(languageService.t("confirm")) { 
                if alertMessage.contains(languageService.t("nickname_updated")) {
                    isPresented = false
                }
            }
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
            alertMessage = languageService.t("nickname_updated")
            showingAlert = true
        } else if !nicknameService.canChangeNickname() {
            alertMessage = languageService.t("nickname_max_reached")
            showingAlert = true
        } else {
            alertMessage = languageService.t("nickname_no_change")
            showingAlert = true
        }
    }
} 