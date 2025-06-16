#!/bin/bash

echo "📱 Creating App files..."

# SignalAirApp.swift
cat > "SignalAir/App/SignalAirApp.swift" << 'EOF'
import SwiftUI
import StoreKit

@main
struct SignalAirApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    configureStoreKit()
                }
        }
    }
    
    private func configureStoreKit() {
        print("SignalAir App Started - StoreKit Ready")
    }
}
EOF

# ContentView.swift
cat > "SignalAir/App/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var languageService = LanguageService()
    
    var body: some View {
        TabView {
            SignalTabView()
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text(languageService.t("signals"))
                }
                .tag(0)
            
            ChatTabView()
                .tabItem {
                    Image(systemName: "message")
                    Text(languageService.t("chat"))
                }
                .tag(1)
            
            GameTabView(isPremiumUser: purchaseService.isPremiumUser)
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text(languageService.t("games"))
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text(languageService.t("settings"))
                }
                .tag(3)
        }
        .accentColor(.blue)
        .environmentObject(purchaseService)
        .environmentObject(languageService)
    }
}

struct SignalTabView: View {
    @StateObject private var signalViewModel = SignalViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("緊急訊號")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        SignalButtonView(
                            type: .safe,
                            onSend: signalViewModel.sendSignal,
                            disabled: false,
                            size: .large
                        )
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 12) {
                            SignalButtonView(type: .supplies, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                            SignalButtonView(type: .medical, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                            SignalButtonView(type: .danger, onSend: signalViewModel.sendSignal, disabled: false, size: .small)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                
                Divider().padding(.horizontal)
                
                ScrollView {
                    MessageListView(messages: signalViewModel.messages)
                        .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ChatTabView: View {
    var body: some View {
        NavigationView {
            ChatView()
                .navigationBarHidden(true)
        }
    }
}

struct GameTabView: View {
    let isPremiumUser: Bool
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showingUpgradeSheet = false
    
    var body: some View {
        NavigationView {
            if isPremiumUser {
                GameView()
                    .navigationBarHidden(true)
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("遊戲功能")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("升級解鎖賓果遊戲，享受完整體驗")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: { showingUpgradeSheet = true }) {
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
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showingUpgradeSheet) {
                    PurchaseOptionsView(purchaseService: purchaseService)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
EOF

echo "✅ App files created" 