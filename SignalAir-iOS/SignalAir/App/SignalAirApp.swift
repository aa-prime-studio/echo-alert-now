import SwiftUI
import StoreKit

@main
struct SignalAirApp: App {
    @StateObject private var languageService = LanguageService()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var nicknameService = NicknameService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageService)
                .environmentObject(purchaseService)
                .environmentObject(nicknameService)
                .onAppear {
                    configureStoreKit()
                }
        }
    }
    
    private func configureStoreKit() {
        print("SignalAir App Started - StoreKit Ready")
    }
}
