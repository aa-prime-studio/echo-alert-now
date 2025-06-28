#!/bin/bash

echo "🎮 Creating remaining features..."

# === GAME FEATURE ===

# GameView.swift
cat > "SignalAir/Features/Game/GameView.swift" << 'EOF'
import SwiftUI

struct GameView: View {
    @State private var selectedRoom: Int = 1
    @State private var showingRoomSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("賓果遊戲功能")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("TODO: Phase 2 - 完整賓果遊戲實作")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(spacing: 16) {
                        Text("計劃功能：")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 3個賓果遊戲室 (A/B/C)")
                            Text("• 房間內多人同時遊戲")
                            Text("• 即時同步遊戲狀態")
                            Text("• 完成連線計分系統")
                            Text("• 自動產生隨機賓果卡")
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("賓果遊戲")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("多人連線遊戲")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { showingRoomSelection = true }) {
                HStack {
                    Text("房間 \(selectedRoom)")
                    Image(systemName: "chevron.down")
                }
                .font(.headline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
    }
}
EOF

# === SETTINGS FEATURE ===

# SettingsView.swift
cat > "SignalAir/Features/Settings/SettingsView.swift" << 'EOF'
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageService: LanguageService
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showingPurchaseSheet = false
    @State private var showingLanguageSheet = false
    
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
    }
    
    private var headerSection: some View {
        HStack {
            Text("設定")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: { showingPurchaseSheet = true }) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white)
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
EOF

echo "✅ Game and Settings features created" 