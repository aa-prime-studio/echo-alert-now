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
