import Foundation

/// 服務條款內容管理器
/// 獨立管理服務條款的多語言內容，遵循專業法律文件格式
class TermsOfServiceContent {
    
    enum Language {
        case chinese
        case english
    }
    
    // MARK: - 公開方法
    
    static func getLastUpdated(language: Language) -> String {
        switch language {
        case .chinese:
            return "最後更新日期：2025年6月\n版本：1.1"
        case .english:
            return "Last Updated: June 2025\nVersion: 1.1"
        }
    }
    
    static func getTermsTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "SignalAir Rescue 服務條款"
        case .english:
            return "SignalAir Rescue Terms of Service"
        }
    }
    
    static func getTermsIntro(language: Language) -> String {
        switch language {
        case .chinese:
            return "SignalAir Rescue（以下簡稱「本應用」或「我們」）是一款去中心化、完全離線運作的緊急通訊應用，專為無網路環境下的點對點訊息傳遞而設計。下列為完整服務條款內容："
        case .english:
            return "SignalAir Rescue (hereinafter referred to as \"this Application\" or \"we\") is a decentralized, fully offline emergency communication application designed specifically for peer-to-peer messaging in network-disconnected environments. The following constitutes the full Terms of Service:"
        }
    }
    
    static func getCorePrinciplesTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "1. 服務核心原則 / Core Principles of the Service"
        case .english:
            return "1. Core Principles of the Service / 服務核心原則"
        }
    }
    
    static func getCorePrinciplesContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
1.1 無中央伺服器：所有資料僅於本地設備處理，絕不上傳雲端。我們無法接觸、控管或監視任何使用者通訊內容或行為。
1.2 端到端加密：訊息僅限發送者與接收者可讀，採用 Curve25519 和 AES-256-GCM 技術。
1.3 最小化資料收集：僅收集維持服務運作所需資訊。
1.4 完全離線可用：不依賴任何網際網路基礎設施，訊息以裝置間短距點對點方式傳遞。
"""
        case .english:
            return """
1.1 No Central Server: All data is processed solely on local devices and never uploaded to the cloud. We have no access to, control over, or ability to monitor any user communication content or behavior.
1.2 End-to-End Encryption: Messages are readable only by the sender and recipient, utilizing Curve25519 and AES-256-GCM encryption technologies.
1.3 Minimal Data Collection: Only information strictly necessary to operate the service is collected.
1.4 Fully Offline Availability: The service operates entirely offline via short-range, peer-to-peer device transmission without relying on any internet infrastructure.
"""
        }
    }
    
    static func getAcceptanceTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "2. 條款接受與年齡限制 / Acceptance of Terms and Age Restrictions"
        case .english:
            return "2. Acceptance of Terms and Age Restrictions / 條款接受與年齡限制"
        }
    }
    
    static func getAcceptanceContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
2.1 當您下載、安裝、存取或使用「SignalAir Rescue」時，即表示您已閱讀、理解並同意接受本《服務條款與隱私權政策》的所有內容。
2.2 如果您不同意本條款的任何部分，請勿下載、安裝或使用本應用。
2.3 台灣地區用戶須年滿13歲。我們有權要求年齡證明，未達法定年齡者將限制或終止使用。
"""
        case .english:
            return """
2.1 By downloading, installing, accessing, or using SignalAir Rescue, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and Privacy Policy.
2.2 If you do not agree with any part of these Terms, do not download, install, or use the Application.
2.3 Users in Taiwan must be at least 13 years old. We reserve the right to request proof of age and may restrict or terminate access for underage users.
"""
        }
    }
    
    static func getSystemTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "3. 系統定位、技術架構與法律聲明 / System Classification, Technical Architecture, and Legal Disclaimer"
        case .english:
            return "3. System Classification, Technical Architecture, and Legal Disclaimer / 系統定位、技術架構與法律聲明"
        }
    }
    
    static func getSystemContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
3.1 本應用基於網際網路協定（IP）與近距無線技術（藍牙、Wi-Fi Direct），並非無線電設備，不涉及無線電頻譜授權。您必須了解本服務不同於 FRS、GMRS、HAM 等傳統通訊工具，僅作為災害或通訊中斷時之補充性協調工具。請依所在國家法律規範使用本服務，若您所在地限制使用加密通訊或特定頻率設備，請自行確認並承擔風險。
3.2 禁止行為：
I. 不得從事詐騙、販毒、人口販運、恐怖活動、洗錢等非法行為。
II. 不得散布色情、仇恨、暴力、歧視內容或未經授權之機密資訊。
III. 不得進行逆向工程、破解、掃描、植入惡意軟體、冒充他人、騷擾或干擾他人正常使用。
IV. 不得架設未經授權的中繼站或節點從事非本條款規定用途。
V. 不得以自動化工具、大規模掃描或模擬裝置方式使用本服務，或以 AI 模型進行批次訊息生成干擾網路。
3.3 可接受使用政策（AUP）：
I. 合法用途僅限於真實災害、緊急協調、公民人道援助、防災演練、教育訓練及法律允許下之個人非商業用途。
II. 本應用所採加密僅用於保障用戶通訊與資料隱私，不作軍事、情報或其他限制用途之使用。
III. 用戶須遵守當地與出口法規，不得於受限制國家或地區使用本應用。
"""
        case .english:
            return """
3.1 This Application utilizes Internet Protocol (IP) and short-range wireless technologies (Bluetooth, Wi-Fi Direct) and does not constitute a radio device or involve radio spectrum licensing. You acknowledge that the service differs from FRS, GMRS, or HAM radios and is intended solely as a supplementary coordination tool during disasters or communication failures. You must comply with applicable laws in your jurisdiction. If encryption communications or specific frequency devices are restricted in your area, you are solely responsible for verifying legality and assuming associated risks.
3.2 Prohibited Conduct:
I. You may not engage in fraud, drug trafficking, human trafficking, terrorism, money laundering, or any illegal activity.
II. You may not distribute pornographic, hateful, violent, discriminatory content, or unauthorized confidential information.
III. You may not reverse-engineer, tamper with, scan, inject malware, impersonate others, harass, or interfere with legitimate usage by others.
IV. You may not set up unauthorized relays or nodes for purposes outside the scope of these Terms.
V. You may not use automated tools, mass scanning, simulated devices, or AI models to generate batch messages disrupting the network.
3.3 Acceptable Use Policy (AUP):
I. Permitted lawful uses include real disaster response, emergency coordination, civic humanitarian aid, disaster drills, educational training, and legally allowed non-commercial personal use.
II. Encryption provided by the Application is solely for protecting user communications and data privacy, not for military, intelligence, or restricted uses.
III. Users must comply with local and export control laws and may not use the Application in restricted countries or regions.
"""
        }
    }
    
    static func getEnforcementTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "4. 實作性防堵與賠償 / Technical Enforcement and Indemnity"
        case .english:
            return "4. Technical Enforcement and Indemnity / 實作性防堵與賠償"
        }
    }
    
    static func getEnforcementContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
4.1 我們有權於發現用戶有違反上述禁止行為時，採取階梯式技術措施，包括但不限於：阻擋裝置連線能力、封鎖部分中繼協議參與權、暫時性排除部分通訊功能等，採取偵測性封包濾除、拒絕轉發違規訊息之技術手段。
4.2 您同意賠償、辯護並使我們免受任何因以下原因產生的索賠：您違反本條款、您的不當使用、您發送之內容或您侵犯他人權利。惟本服務無法預先檢視、監控、管理或刪除任何訊息傳輸，我們不承擔使用者間行為之任何連帶責任。
4.3 若發現違規行為，我們有權採取階段性技術防堵，包括封鎖協議參與權、濾除違規封包等，等其他並不限於此處理方式，並可能通報司法機關。
4.4 您同意對於因違規、侵權、內容不當所引起之一切法律責任，承擔因違反本條款導致的責任，並在合理範圍內補償本應用可能因此遭受之損害，並使本應用免於任何第三方請求。
"""
        case .english:
            return """
4.1 We reserve the right to implement tiered technical measures upon detection of violations, including but not limited to: disabling device connectivity, blocking relay protocol participation, or temporarily suspending messaging features. We may apply detection-based packet filtering or deny transmission of infringing messages.
4.2 You agree to indemnify, defend, and hold us harmless against any claims arising from your violations of these Terms, misuse, content transmission, or infringement of others' rights. However, we cannot preview, monitor, manage, or delete any message transmissions in advance and assume no joint liability for user interactions.
4.3 Upon discovering violations, we may take progressive enforcement steps including, but not limited to, revoking protocol participation rights, filtering offending packets, and reporting to legal authorities.
4.4 You agree to bear full legal responsibility for any violations, infringements, or inappropriate content and shall compensate us for any damages caused by such violations within a reasonable scope, and hold us harmless from any third-party claims.
"""
        }
    }
    
    static func getEmergencyTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "5. 緊急服務與免責聲明 / Emergency Services and Disclaimers"
        case .english:
            return "5. Emergency Services and Disclaimers / 緊急服務與免責聲明"
        }
    }
    
    static func getEmergencyContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
5.1 非官方緊急服務：本服務無法連接官方緊急熱線，不具備備援通報功能或法定通報機制，僅供輔助溝通使用。僅作為災害或網路癱瘓時的補助通訊工具。
5.2 完全免責層（AS IS 條款）：本服務以「現狀」與「可用」方式提供，不對其可用性、準確性、相容性、持續性或效能提供任何保證。請勿將本應用用於醫療急救、飛航安全、生命維繫等關鍵用途，請使用者自行承擔。
5.3 特定免責-緊急通訊風險：因依賴本服務造成之任何傷害、損失、訊息延遲、誤傳、錯誤路由或未送達等風險，使用者應自行承擔。建議在可用時優先使用官方緊急聯繫方式。本應用不為第三方於衝突地區或跨境人道行動中之使用後果負責，使用者應評估當地法律與倫理風險。
5.4 損害限制層－賠償上限：在法律允許範圍內，您明確同意對於本服務所引起之任何申訴、請求、損害或爭議，我們的全部責任以您於該爭議發生前30日內實際支付給本服務的單次應用內購買金額為限，且該金額不得累計或合併其他時期的付款紀錄。我們不承擔任何因本服務之使用或無法使用所導致的間接、附帶、衍生性、懲罰性或特別損害，包括但不限於利潤損失、資料毀損、名譽受損、業務中斷、通訊失敗或人身傷亡。如任何司法管轄區禁止或限制上述賠償限制條款之適用，則本應用僅於該地以法律所允許之最小限度承擔責任。
"""
        case .english:
            return """
5.1 No Official Emergency Services: This service does not connect to official emergency hotlines and lacks backup reporting or statutory emergency mechanisms. It serves solely as an auxiliary communication tool during disasters or internet outages.
5.2 AS IS Disclaimer: This service is provided "as is" and "as available" without any warranties regarding availability, accuracy, compatibility, continuity, or performance. Do not use this Application for critical purposes such as medical emergencies, aviation safety, or life support.
5.3 Specific Disclaimer – Emergency Communication Risks: Users assume all risks for injuries, losses, message delays, misdelivery, misrouting, or failed transmissions caused by reliance on this service. Official emergency contact methods should be used when available. We assume no responsibility for third-party use in conflict zones or cross-border humanitarian missions. Users should assess legal and ethical risks in such situations.
5.4 Limitation of Liability: To the fullest extent permitted by law, our total liability for any claim, demand, damage, or dispute arising from this service shall be limited to the amount you paid for any in-app purchase within 30 days prior to the event in question. This amount is not cumulative or aggregable with other transactions. We are not liable for any indirect, incidental, consequential, punitive, or special damages, including but not limited to lost profits, data loss, reputational damage, business interruption, communication failure, or personal injury. If any jurisdiction prohibits or limits these disclaimers, we shall assume liability only to the minimal extent permitted by law in that jurisdiction.
"""
        }
    }
    
    static func getDisputeTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "6. 爭議解決與法律適用 / Dispute Resolution and Governing Law"
        case .english:
            return "6. Dispute Resolution and Governing Law / 爭議解決與法律適用"
        }
    }
    
    static func getDisputeContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
本條款僅適用中華民國（台灣）法律，並以台北地方法院為專屬第一審管轄法院。
"""
        case .english:
            return """
These Terms are governed exclusively by the laws of the Republic of China (Taiwan), with the Taipei District Court as the court of first instance with exclusive jurisdiction.
"""
        }
    }
    
    static func getDataControlTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "7. 使用者資料控制與刪除 / User Data Control and Deletion"
        case .english:
            return "7. User Data Control and Deletion / 使用者資料控制與刪除"
        }
    }
    
    static func getDataControlContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
7.1 所有資料預設僅儲存於本機，訊息將於24小時內自動刪除，用戶可於應用內一鍵清除所有歷史紀錄。
7.2 因系統設計無法進行遠端刪除、封鎖、撤回、召回，請用戶自行妥善管理裝置與內容。
"""
        case .english:
            return """
7.1 All data is stored locally by default, with messages automatically deleted within 24 hours. Users may delete all history with a single in-app action.
7.2 Due to system architecture, remote deletion, blocking, retraction, or recall is not possible. Users must manage devices and content independently.
"""
        }
    }
    
    static func getIntellectualTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "8. 智慧財產權與授權 / Intellectual Property and License"
        case .english:
            return "8. Intellectual Property and License / 智慧財產權與授權"
        }
    }
    
    static func getIntellectualContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
SignalAir Rescue 的名稱、標誌、原始程式碼、設計、文件等均為我們所有。用戶所傳送內容之著作權歸用戶本人所有，但您授權本服務為完成通訊所需進行必要之編碼、封裝、加密與傳輸處理。
"""
        case .english:
            return """
The name, logo, source code, design, and documentation of SignalAir Rescue are our property. Copyright of user-generated content remains with the user, but you grant us a license to encode, package, encrypt, and transmit such content as necessary for communication.
"""
        }
    }
    
    static func getAmendmentsTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "9. 條款變更與通知 / Amendments and Notifications"
        case .english:
            return "9. Amendments and Notifications / 條款變更與通知"
        }
    }
    
    static func getAmendmentsContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
9.1 本條款可能因法律變動、平台規定、功能修改而進行更新。重大變更將透過應用登入提示及推播通知提醒，並於通知後30天生效。
9.2 若用戶於變更生效後仍持續使用，即視為同意新條款。若不同意，請立即停止使用並刪除應用程式。
"""
        case .english:
            return """
9.1 These Terms may be updated due to legal changes, platform policies, or feature modifications. Material changes will be notified via app login prompts and push notifications, taking effect 30 days after such notice.
9.2 Continued use after changes take effect constitutes acceptance. If you do not agree, cease using and uninstall the Application immediately.
"""
        }
    }
    
    
    static func getInternationalTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "10. 國際使用條款 / International Use Terms"
        case .english:
            return "10. International Use Terms / 國際使用條款"
        }
    }
    
    static func getInternationalContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
10.1 本應用目前僅於台灣 App Store 上架與營運，暫不支援其他國家或地區之法律要求與消費者權益請求。未來如擴展至其他市場，將另行公告補充該區域適用之權利義務與隱私條款。
10.2 其他地區：若您於台灣以外地區使用本服務，請依當地法令自我審查並承擔相關使用風險。如需協助，請聯絡我們信箱。
"""
        case .english:
            return """
10.1 This Application is currently available and operated only via the Taiwan App Store and does not support legal or consumer requirements of other countries or regions. Should expansion occur, applicable rights and privacy terms for those regions will be announced separately.
10.2 Users outside Taiwan must self-assess legal compliance and assume all associated risks. For assistance, contact the email above.
"""
        }
    }
    
    static func getServiceChangesTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "11. 服務變更與終止 / Service Modifications and Termination"
        case .english:
            return "11. Service Modifications and Termination / 服務變更與終止"
        }
    }
    
    static func getServiceChangesContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
11.1 我們保留隨時調整、改進、中止服務或其任何部分的權利，無需事前通知。
11.2 您可隨時停止使用，並自行移除應用程式。
11.3 雖無遠端停權功能，但若偵測嚴重違規濫用行為，我們得採取技術手段避免系統資源被持續濫用。
"""
        case .english:
            return """
11.1 We reserve the right to modify, improve, or suspend the service or any portion thereof at any time without prior notice.
11.2 You may stop using the service and remove the application at any time.
11.3 While remote suspension is not possible, we may apply technical controls to prevent system abuse if severe misconduct is detected.
"""
        }
    }
    
    static func getPurchaseTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "12. 應用內購買與退款政策 / In-App Purchases and Refund Policy"
        case .english:
            return "12. In-App Purchases and Refund Policy / 應用內購買與退款政策"
        }
    }
    
    static func getPurchaseContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
12.1 某些功能為付費項目，由 Apple App Store 處理交易。
12.2 所有退款請依 Apple 規定進行，我們無法直接介入或核發退款。
12.3 若包含訂閱服務，用戶可於 iOS 裝置的系統設定中管理與取消。
"""
        case .english:
            return """
12.1 Certain features are paid items processed by Apple App Store.
12.2 Refunds must follow Apple's policies. We cannot directly intervene or issue refunds.
12.3 For subscription services, users may manage or cancel them through iOS system settings.
"""
        }
    }
    
    static func getExportControlTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "13. 出口管制 / Export Control"
        case .english:
            return "13. Export Control / 出口管制"
        }
    }
    
    static func getExportControlContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
本服務涉及強加密技術，可能受美國及其他國家之出口管制規定限制，使用者須遵守所有適用出口法規。本應用涉及通訊加密機制，若未來擴展至海外市場，使用者應自行查明其所在地法律對加密技術之規範與出口限制。本應用並無設計或行銷用途指向軍事或雙重用途。
"""
        case .english:
            return """
This service involves strong encryption technologies and may be subject to export control regulations under U.S. or other applicable laws. Users must comply with all relevant export control laws. If the Application expands to foreign markets, users must investigate local regulations concerning encryption technologies and export restrictions. This Application is not designed or marketed for military or dual-use purposes.
"""
        }
    }
    
    static func getGeneralTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "14. 一般條款補述 / General Provisions"
        case .english:
            return "14. General Provisions / 一般條款補述"
        }
    }
    
    static func getGeneralContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
14.1 本文件為您與我們之完整協議，取代一切口頭或書面先前協議。
14.2 可分割性：若部分條款被判定為無效或不可執行，不影響其他條款之效力。
14.3 豁免：我們未主張或執行本條款中任何權利，並不構成放棄該權利。
14.4 轉讓：您不得將本協議之權利與義務轉讓予第三人。我們得自由轉讓本條款之權利予第三方。
14.5 不可抗力：因自然災害、戰爭、政變、停電、系統毀損等不可抗力因素導致之服務中斷、失效，我們不承擔責任。
"""
        case .english:
            return """
14.1 This document constitutes the entire agreement between you and us, superseding all prior oral or written agreements.
14.2 Severability: If any part of these Terms is found invalid or unenforceable, the remaining provisions remain in full effect.
14.3 Waiver: Our failure to enforce any right does not constitute a waiver of that right.
14.4 Assignment: You may not assign your rights or obligations under these Terms to any third party. We may freely assign our rights.
14.5 Force Majeure: We shall not be liable for service interruptions due to force majeure, including natural disasters, war, coups, power outages, or system failures.
"""
        }
    }
    
    static func getClosingTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "15. 結語 / Closing"
        case .english:
            return "15. Closing / 結語"
        }
    }
    
    static func getClosingContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
感謝您使用 SignalAir Rescue，我們致力於為您提供安全可靠的緊急通訊服務。
"""
        case .english:
            return """
Thank you for using SignalAir Rescue. We are committed to providing you with safe and reliable emergency communication services.
"""
        }
    }
    
    static func getContactTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "聯絡方式 / Contact Information"
        case .english:
            return "Contact Information / 聯絡方式"
        }
    }
    
    static func getContactContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
如您對本條款內容有任何疑問，請來信：
Email：aa.prime.studio@gmail.com
"""
        case .english:
            return """
If you have any questions regarding these Terms, please contact us via email:
Email: aa.prime.studio@gmail.com
"""
        }
    }
    
    // MARK: - 完整內容獲取方法
    
    static func getFullContent(language: Language) -> String {
        let sections = [
            getTermsTitle(language: language),
            getLastUpdated(language: language),
            "",
            getTermsIntro(language: language),
            "",
            getCorePrinciplesTitle(language: language),
            getCorePrinciplesContent(language: language),
            getAcceptanceTitle(language: language),
            getAcceptanceContent(language: language),
            getSystemTitle(language: language),
            getSystemContent(language: language),
            getEnforcementTitle(language: language),
            getEnforcementContent(language: language),
            getEmergencyTitle(language: language),
            getEmergencyContent(language: language),
            getDisputeTitle(language: language),
            getDisputeContent(language: language),
            getDataControlTitle(language: language),
            getDataControlContent(language: language),
            getIntellectualTitle(language: language),
            getIntellectualContent(language: language),
            getAmendmentsTitle(language: language),
            getAmendmentsContent(language: language),
            getInternationalTitle(language: language),
            getInternationalContent(language: language),
            getServiceChangesTitle(language: language),
            getServiceChangesContent(language: language),
            getPurchaseTitle(language: language),
            getPurchaseContent(language: language),
            getExportControlTitle(language: language),
            getExportControlContent(language: language),
            getGeneralTitle(language: language),
            getGeneralContent(language: language),
            getClosingTitle(language: language),
            getClosingContent(language: language),
            "",
            getContactTitle(language: language),
            getContactContent(language: language)
        ]
        
        return sections.joined(separator: "\n")
    }
} 