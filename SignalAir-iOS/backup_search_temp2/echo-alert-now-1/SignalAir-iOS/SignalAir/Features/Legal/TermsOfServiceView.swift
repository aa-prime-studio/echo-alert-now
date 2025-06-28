import SwiftUI

struct TermsOfServiceView: View {
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 最後更新日期
                Text(getLastUpdated())
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                // 一、接受條款
                TermsSection(
                    title: getAcceptTermsTitle(),
                    content: getAcceptTermsContent()
                )
                
                // 二、服務描述
                TermsSection(
                    title: getServiceDescriptionTitle(),
                    content: getServiceDescriptionContent()
                )
                
                // 三、使用規範
                VStack(alignment: .leading, spacing: 12) {
                    Text(getUsageGuidelinesTitle())
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    
                    // 您同意
                    SubTermsSection(
                        title: getUsageAgreeTitle(),
                        content: getUsageAgreeContent()
                    )
                    
                    // 禁止行為
                    SubTermsSection(
                        title: getProhibitedActionsTitle(),
                        content: getProhibitedActionsContent()
                    )
                }
                .padding()
                
                // 四、內容責任
                TermsSection(
                    title: getContentResponsibilityTitle(),
                    content: getContentResponsibilityContent()
                )
                
                // 五、系統限制
                VStack(alignment: .leading, spacing: 12) {
                    Text(getSystemLimitationsTitle())
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    
                    // 技術限制
                    SubTermsSection(
                        title: getTechnicalLimitationsTitle(),
                        content: getTechnicalLimitationsContent()
                    )
                    
                    // 使用限制
                    SubTermsSection(
                        title: getUsageLimitationsTitle(),
                        content: getUsageLimitationsContent()
                    )
                }
                .padding()
                
                // 六、內購項目
                VStack(alignment: .leading, spacing: 12) {
                    Text(getIAPTitle())
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    
                    // 購買方案
                    SubTermsSection(
                        title: getPurchasePlansTitle(),
                        content: getPurchasePlansContent()
                    )
                    
                    // 付款條款
                    SubTermsSection(
                        title: getPaymentTermsTitle(),
                        content: getPaymentTermsContent()
                    )
                    
                    // 退款政策
                    SubTermsSection(
                        title: getRefundPolicyTitle(),
                        content: getRefundPolicyContent()
                    )
                }
                .padding()
                
                // 七、免責聲明
                TermsSection(
                    title: getDisclaimerTitle(),
                    content: getDisclaimerContent()
                )
                
                // 八、責任限制
                TermsSection(
                    title: getLiabilityLimitationTitle(),
                    content: getLiabilityLimitationContent()
                )
                
                // 九、智慧財產權
                TermsSection(
                    title: getIntellectualPropertyTitle(),
                    content: getIntellectualPropertyContent()
                )
                
                // 十、條款修改
                TermsSection(
                    title: getTermsModificationTitle(),
                    content: getTermsModificationContent()
                )
                
                // 十一、終止
                TermsSection(
                    title: getTerminationTitle(),
                    content: getTerminationContent()
                )
                
                // 十二、管轄法律
                TermsSection(
                    title: getGoverningLawTitle(),
                    content: getGoverningLawContent()
                )
                
                // 十三、完整協議
                TermsSection(
                    title: getEntireAgreementTitle(),
                    content: getEntireAgreementContent()
                )
                
                // 十四、聯絡資訊
                TermsSection(
                    title: getTermsContactTitle(),
                    content: getTermsContactContent()
                )
            }
            .padding()
        }
        .navigationTitle(languageService.t("terms_of_service"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
    
    // MARK: - Helper Methods for Translations
    private func getLastUpdated() -> String {
        return languageService.currentLanguage == .chinese ? "最後更新日期：2025 年 6 月" : "Last Updated: June 2025"
    }
    
    private func getAcceptTermsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "一、接受條款" : "1. Acceptance of Terms"
    }
    
    private func getAcceptTermsContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "使用 SignalAir Rescue（以下簡稱「本服務」）即表示您同意遵守這些服務條款。如果您不同意，請勿使用本服務。"
        : "By using SignalAir Rescue (hereinafter referred to as \"the Service\"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the Service."
    }
    
    private func getServiceDescriptionTitle() -> String {
        return languageService.currentLanguage == .chinese ? "二、服務描述" : "2. Description of Service"
    }
    
    private func getServiceDescriptionContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "SignalAir Rescue 是一個去中心化的緊急通訊平台，提供：\n• 點對點加密通訊\n• 緊急訊號廣播\n• 多人遊戲功能\n• 臨時匿名身份系統"
        : "SignalAir Rescue is a decentralized emergency communication platform offering:\n• Peer-to-peer encrypted messaging\n• Emergency signal broadcasting\n• Multiplayer gaming features\n• Temporary anonymous identity system"
    }
    
    private func getUsageGuidelinesTitle() -> String {
        return languageService.currentLanguage == .chinese ? "三、使用規範" : "3. Usage Guidelines"
    }
    
    private func getUsageAgreeTitle() -> String {
        return languageService.currentLanguage == .chinese ? "您同意：" : "You agree to:"
    }
    
    private func getUsageAgreeContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 僅將緊急功能用於真實緊急情況\n• 不發送垃圾訊息或惡意內容\n• 不嘗試破解或規避安全機制\n• 不使用本服務進行非法活動\n• 尊重其他使用者"
        : "• Use emergency features only in genuine emergency situations\n• Refrain from sending spam or malicious content\n• Not attempt to hack or bypass security mechanisms\n• Not use the Service for illegal activities\n• Respect other users"
    }
    
    private func getProhibitedActionsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "禁止行為：" : "Prohibited actions include:"
    }
    
    private func getProhibitedActionsContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 騷擾、威脅或恐嚇他人\n• 傳播不實緊急訊息\n• 散布惡意軟體或有害內容\n• 冒充他人身份\n• 違反當地法律法規"
        : "• Harassment, threats, or intimidation\n• Spreading false emergency information\n• Distributing malware or harmful content\n• Impersonating others\n• Violating local laws and regulations"
    }
    
    private func getContentResponsibilityTitle() -> String {
        return languageService.currentLanguage == .chinese ? "四、內容責任" : "4. Content Responsibility"
    }
    
    private func getContentResponsibilityContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 您對透過本服務發送的所有內容負責\n• 我們不監控或審查加密訊息內容\n• 訊息會在 24 小時後自動刪除\n• 您不應依賴本服務作為唯一的緊急通訊方式"
        : "• You are solely responsible for all content you transmit through the Service\n• We do not monitor or review the contents of encrypted messages\n• Messages are automatically deleted after 24 hours\n• You should not rely on the Service as your sole means of emergency communication"
    }
    
    private func getSystemLimitationsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "五、系統限制" : "5. System Limitations"
    }
    
    private func getTechnicalLimitationsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "技術限制：" : "Technical limitations:"
    }
    
    private func getTechnicalLimitationsContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 需要 iOS 16.0 或更高版本\n• 依賴藍牙和 Wi-Fi 進行連線\n• 通訊範圍受裝置硬體限制\n• 無法保證在所有情況下都能連線"
        : "• Requires iOS version 16.0 or above\n• Relies on Bluetooth and Wi-Fi connectivity\n• Communication range is limited by device hardware\n• Connectivity is not guaranteed in all situations"
    }
    
    private func getUsageLimitationsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "使用限制：" : "Usage limitations:"
    }
    
    private func getUsageLimitationsContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 暱稱每月最多修改 3 次\n• 防洪水機制限制訊息發送頻率\n• 遊戲房間最多支援 6 名玩家"
        : "• Nicknames can be changed a maximum of 3 times per month\n• Flood control mechanisms limit message sending frequency\n• Game rooms support up to 6 players"
    }
    
    private func getIAPTitle() -> String {
        return languageService.currentLanguage == .chinese ? "六、內購項目" : "6. In-App Purchases"
    }
    
    private func getPurchasePlansTitle() -> String {
        return languageService.currentLanguage == .chinese ? "購買方案：" : "Purchase Options:"
    }
    
    private func getPurchasePlansContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• Level 1：喝杯楊枝甘露 $90 NTD/永久\n• Level 2：解鎖賓果遊戲 $330 NTD/永久\n• Level 3：完整版 $1,680 NTD/永久"
        : "• Level 1: A Cup of Mango Pomelo Sago – $90 NTD / Lifetime\n• Level 2: Unlock Bingo Game – $330 NTD / Lifetime\n• Level 3: Full Version – $1,680 NTD / Lifetime"
    }
    
    private func getPaymentTermsTitle() -> String {
        return languageService.currentLanguage == .chinese ? "付款條款：" : "Payment Terms:"
    }
    
    private func getPaymentTermsContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 透過 Apple 帳戶收費\n• 一次性訂閱費用，永久使用\n• 可在 iOS 設定中查看購買記錄"
        : "• Billed through your Apple account\n• One-time subscription fee with lifetime access\n• Purchase history available in iOS settings"
    }
    
    private func getRefundPolicyTitle() -> String {
        return languageService.currentLanguage == .chinese ? "退款政策：" : "Refund Policy:"
    }
    
    private func getRefundPolicyContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "所有購買均透過 App Store 處理，退款請求需遵循 Apple 的退款政策。"
        : "All purchases are processed via the App Store. Refund requests must comply with Apple's refund policy."
    }
    
    private func getDisclaimerTitle() -> String {
        return languageService.currentLanguage == .chinese ? "七、免責聲明" : "7. Disclaimer"
    }
    
    private func getDisclaimerContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "本服務按「現況」提供，不提供任何明示或暗示的保證，包括但不限於：\n• 適用於特定用途\n• 不中斷或無錯誤\n• 緊急情況下的可用性"
        : "The Service is provided \"as is\" without any express or implied warranties, including but not limited to:\n• Fitness for a particular purpose\n• Uninterrupted or error-free operation\n• Availability during emergencies"
    }
    
    private func getLiabilityLimitationTitle() -> String {
        return languageService.currentLanguage == .chinese ? "八、責任限制" : "8. Limitation of Liability"
    }
    
    private func getLiabilityLimitationContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "在法律允許的最大範圍內，我們不對以下情況負責：\n• 因使用或無法使用本服務造成的損失\n• 資料遺失或損壞\n• 緊急情況下的通訊失敗"
        : "To the maximum extent permitted by law, we shall not be liable for:\n• Any loss resulting from the use or inability to use the Service\n• Data loss or corruption\n• Communication failure during emergencies"
    }
    
    private func getIntellectualPropertyTitle() -> String {
        return languageService.currentLanguage == .chinese ? "九、智慧財產權" : "9. Intellectual Property"
    }
    
    private func getIntellectualPropertyContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• SignalAir Rescue 名稱和標誌為我們所有\n• 您保有您創建內容的所有權\n• 您授予我們運營服務所需的有限授權"
        : "• The name and logo of SignalAir Rescue are our property\n• You retain ownership of content you create\n• You grant us a limited license to use your content as necessary to operate the Service"
    }
    
    private func getTermsModificationTitle() -> String {
        return languageService.currentLanguage == .chinese ? "十、條款修改" : "10. Changes to Terms"
    }
    
    private func getTermsModificationContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "我們可能隨時修改這些條款。重大變更會在應用程式內通知。繼續使用即表示接受新條款。"
        : "We may modify these Terms at any time. Significant changes will be announced within the app. Continued use of the Service constitutes acceptance of the updated Terms."
    }
    
    private func getTerminationTitle() -> String {
        return languageService.currentLanguage == .chinese ? "十一、終止" : "11. Termination"
    }
    
    private func getTerminationContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "• 您可隨時刪除應用程式終止使用\n• 我們保留因違反條款而限制存取的權利\n• 終止後，您的本地資料將被刪除"
        : "• You may stop using the Service at any time by deleting the app\n• We reserve the right to restrict access in case of Terms violation\n• Upon termination, your local data will be deleted"
    }
    
    private func getGoverningLawTitle() -> String {
        return languageService.currentLanguage == .chinese ? "十二、管轄法律" : "12. Governing Law"
    }
    
    private func getGoverningLawContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "本條款受中華民國（台灣）法律管轄，不含其法律衝突條款。任何爭議應提交台北地方法院管轄。"
        : "These Terms are governed by the laws of the Republic of China (Taiwan), excluding its conflict of law provisions. Any disputes shall be submitted to the jurisdiction of the Taipei District Court."
    }
    
    private func getEntireAgreementTitle() -> String {
        return languageService.currentLanguage == .chinese ? "十三、完整協議" : "13. Entire Agreement"
    }
    
    private func getEntireAgreementContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "這些條款構成您與我們之間關於使用本服務的完整協議。"
        : "These Terms constitute the entire agreement between you and us regarding the use of the Service."
    }
    
    private func getTermsContactTitle() -> String {
        return languageService.currentLanguage == .chinese ? "十四、聯絡資訊" : "14. Contact Information"
    }
    
    private func getTermsContactContent() -> String {
        return languageService.currentLanguage == .chinese 
        ? "如有任何問題或建議：\n電子郵件：aa.prime.studio@gmail.com"
        : "For any questions or suggestions, please contact:\nEmail: aa.prime.studio@gmail.com"
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.semibold)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}

struct SubTermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}
