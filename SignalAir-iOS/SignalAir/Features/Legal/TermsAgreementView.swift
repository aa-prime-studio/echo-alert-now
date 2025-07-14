import SwiftUI

struct TermsAgreementView: View {
    @Binding var isPresented: Bool
    @State private var hasAgreed = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("使用條款同意")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("歡迎使用 SignalAir")
                            .font(.subheadline.weight(.bold))
                            .lineSpacing(16)
                        
                        Text("在使用本應用程式之前，請仔細閱讀並同意以下使用條款：")
                            .font(.subheadline.weight(.regular))
                            .lineSpacing(16)
                        
                        Group {
                            Text("1. 服務使用")
                                .font(.subheadline.weight(.bold))
                                .lineSpacing(16)
                            Text("您同意僅將本應用程式用於合法目的，不得進行任何可能損害系統或其他用戶的行為。")
                                .font(.subheadline.weight(.regular))
                                .lineSpacing(16)
                            
                            Text("2. 隱私保護")
                                .font(.subheadline.weight(.bold))
                                .lineSpacing(16)
                            Text("我們重視您的隱私，所有通訊均經過加密處理，我們不會收集或儲存您的個人資訊。")
                                .font(.subheadline.weight(.regular))
                                .lineSpacing(16)
                            
                            Text("3. 責任限制")
                                .font(.subheadline.weight(.bold))
                                .lineSpacing(16)
                            Text("本應用程式按「現況」提供，我們不對使用過程中可能出現的任何問題承擔責任。")
                                .font(.subheadline.weight(.regular))
                                .lineSpacing(16)
                            
                            Text("4. 條款變更")
                                .font(.subheadline.weight(.bold))
                                .lineSpacing(16)
                            Text("我們保留隨時修改這些條款的權利，修改後的條款將在應用程式中公佈。")
                                .font(.subheadline.weight(.regular))
                                .lineSpacing(16)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: {
                        hasAgreed.toggle()
                    }) {
                        Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                            .foregroundColor(hasAgreed ? .blue : .gray)
                    }
                    
                    Text("我已閱讀並同意上述使用條款")
                        .font(.body)
                    
                    Spacer()
                }
                .padding()
                
                HStack {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("同意並繼續") {
                        if hasAgreed {
                            // 儲存同意狀態
                            UserDefaults.standard.set(true, forKey: "hasAgreedToTerms")
                            isPresented = false
                        }
                    }
                    .disabled(!hasAgreed)
                    .foregroundColor(hasAgreed ? .blue : .gray)
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .leading) {
                    EmptyView()
                }
            }
        }
    }
}

struct TermsAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAgreementView(isPresented: .constant(true))
    }
} 