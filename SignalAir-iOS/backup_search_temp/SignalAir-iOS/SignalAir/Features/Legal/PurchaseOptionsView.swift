import SwiftUI

struct PurchaseOptionsView: View {
    @ObservedObject var languageService: LanguageService
    @ObservedObject var purchaseService: PurchaseService
    
    var body: some View {
        VStack {
            Text("購買選項")
                .font(.title)
                .padding()
            
            Text("此功能尚未實現")
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .navigationTitle("購買選項")
    }
}
