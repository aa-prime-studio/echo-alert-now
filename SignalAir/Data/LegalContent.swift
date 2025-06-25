import Foundation

// 法律文件內容管理
struct LegalContent {
    
    // MARK: - 隱私權政策內容
    static let privacyPolicyZhTW = """
SignalAir Rescue 隱私權政策（Privacy Policy）
最後更新日期：2025年6月
版本：1.1

本隱私權政策說明 SignalAir Rescue 如何處理您的個人資料與隱私權：

1. 資料收集與用途
位置資訊：採用網格化處理（100~500公尺），僅計算相對距離與方向，模糊處理，無實際地理位置儲存。
設備資訊：僅收集型號、OS版本、隨機匿名設備ID（不追溯身份）。
通訊內容：端對端加密，僅本機儲存，24小時自動刪除，不傳送至伺服器。
不收集項目：姓名、電話、Email、IP、聯絡人、照片、錄音、付款資訊等個資。

2. 資料分享與傳輸
資料僅於裝置間以點對點方式傳輸，不經任何伺服器或中介存取。
我們不出售、出租、交換、分享任何資料予第三方，除非法律要求。
由於去中心化架構，所有訊息一旦傳送即無法遠端撤回或刪除。

3. 用戶權利
您可於應用程式內檢視、刪除或清除本地資料。
由於本服務採本地離線儲存與無中心架構，資料無法進行集中備份或符合一般「資料可攜性」標準（如 CSV、JSON 輸出格式）。
採用 iOS Keychain 加密保護密鑰，資料分散儲存於用戶裝置中，無單點故障風險。

4. 資料安全措施
採用 Curve25519 + AES-256-GCM 實作端對端加密與前向保密機制，並透過 iOS Keychain 加密儲存本地機密金鑰。
資料分散儲存於各使用者設備，無單點故障風險。
誠實揭露：因系統完全去中心化與本地儲存特性，無法防止下列風險：
收件者截圖或記錄
設備遭竊或遺失
其他使用者轉傳訊息

5. 使用者資料控制與刪除
所有資料預設僅儲存於本機，訊息將於24小時內自動刪除。
用戶可於應用內一鍵清除所有歷史紀錄。
因系統設計無法進行遠端刪除、封鎖、撤回、召回，請用戶自行妥善管理裝置與內容。

6. 聯絡方式
如對隱私政策有任何疑問，請來信 Email：aa.prime.studio@gmail.com。
"""
    
    static let privacyPolicyEnUS = """
SignalAir Rescue Privacy Policy
Last Updated: June 2025
Version: 1.1

This Privacy Policy explains how SignalAir Rescue handles your personal data and privacy:

1. Data Collection and Usage
Location Data: Collected using a grid-based system (within 100–500 meters), calculating only relative distance and direction. Data is obfuscated and does not store precise geographic locations.

Device Information: Only device model, OS version, and a randomly generated anonymous device ID are collected. No identifiable information is traced.

Communication Content: All content is end-to-end encrypted, stored only locally, and automatically deleted within 24 hours. No data is transmitted to any server.

Data Not Collected: The Application does not collect your name, phone number, email address, IP address, contacts, photos, audio recordings, or payment information.

2. Data Sharing and Transmission
All data is transmitted directly between devices using peer-to-peer (P2P) technology. No servers or intermediaries are involved in the transmission process.

We do not sell, rent, trade, or share any data with third parties unless required by law.

Due to the decentralized architecture, messages cannot be remotely recalled or deleted once sent.

3. User Rights
You may view, delete, or clear local data within the Application at any time.

As the service uses offline local storage and has no central server, we cannot provide centralized backups or standard "data portability" formats (e.g., CSV, JSON).

Encryption keys are protected via iOS Keychain. Data is distributed across users' devices, avoiding single points of failure.

4. Data Security Measures
SignalAir Rescue uses Curve25519 and AES-256-GCM to implement end-to-end encryption and forward secrecy. Local secret keys are encrypted and stored using iOS Keychain.

All user data is stored on individual user devices, eliminating centralized vulnerabilities.

Transparency Notice: Due to the fully decentralized and local storage design, the following risks cannot be technically prevented:

Screenshots or recordings made by recipients;

Device theft or loss;

Forwarding of messages by other users.

5. User Data Control and Deletion
By default, all data is stored only on the device. Messages are automatically deleted within 24 hours.

Users may use an in-app feature to erase all history with a single action.

Due to system design, remote deletion, blocking, revocation, or recall is not possible. Users are responsible for the appropriate handling of their devices and content.

6. Contact Information
If you have any questions regarding this Privacy Policy, please contact us at:
Email: aa.prime.studio@gmail.com
"""
    
    // MARK: - 服務條款內容
    static let termsOfServiceZhTW = """
SignalAir Rescue 服務條款（Terms of Service）
最後更新日期：2025年6月
版本：1.1

SignalAir Rescue（以下簡稱「本應用」或「我們」）是一款去中心化、完全離線運作的緊急通訊應用，專為無網路環境下的點對點訊息傳遞而設計。下列為完整服務條款內容：

1. 服務核心原則
無中央伺服器：所有資料僅於本地設備處理，絕不上傳雲端。我們無法接觸、控管或監視任何使用者通訊內容或行為。
端到端加密：訊息僅限發送者與接收者可讀，採用 Curve25519 和 AES-256-GCM 技術。
最小化資料收集：僅收集維持服務運作所需資訊。
完全離線可用：不依賴任何網際網路基礎設施，訊息以裝置間短距點對點方式傳遞。

2. 條款接受與年齡限制
當您下載、安裝、存取或使用「SignalAir Rescue」時，即表示您已閱讀、理解並同意接受本《服務條款與隱私權政策》的所有內容。
如果您不同意本條款的任何部分，請勿下載、安裝或使用本應用。
台灣地區用戶須年滿13歲。我們有權要求年齡證明，未達法定年齡者將限制或終止使用。

3. 系統定位、技術架構與法律聲明
3.1 本應用基於網際網路協定（IP）與近距無線技術（藍牙、Wi-Fi Direct），並非無線電設備，不涉及無線電頻譜授權。您必須了解本服務不同於 FRS、GMRS、HAM 等傳統通訊工具，僅作為災害或通訊中斷時之補充性協調工具。
請依所在國家法律規範使用本服務，若您所在地限制使用加密通訊或特定頻率設備，請自行確認並承擔風險。

3.2 禁止行為：
不得從事詐騙、販毒、人口販運、恐怖活動、洗錢等非法行為。
不得散布色情、仇恨、暴力、歧視內容或未經授權之機密資訊。
不得進行逆向工程、破解、掃描、植入惡意軟體、冒充他人、騷擾或干擾他人正常使用。
不得架設未經授權的中繼站或節點從事非本條款規定用途。
不得以自動化工具、大規模掃描或模擬裝置方式使用本服務，或以 AI 模型進行批次訊息生成干擾網路。

3.3 可接受使用政策（AUP）：
合法用途僅限於真實災害、緊急協調、公民人道援助、防災演練、教育訓練及法律允許下之個人非商業用途。
本應用所採加密僅用於保障用戶通訊與資料隱私，不作軍事、情報或其他限制用途之使用。
用戶須遵守當地與出口法規，不得於受限制國家或地區使用本應用。

4. 實作性防堵與賠償
我們有權於發現用戶有違反上述禁止行為時，採取階梯式技術措施，包括但不限於：阻擋裝置連線能力、封鎖部分中繼協議參與權、暫時性排除部分通訊功能等，採取偵測性封包濾除、拒絕轉發違規訊息之技術手段。
您同意賠償、辯護並使我們免受任何因以下原因產生的索賠：您違反本條款、您的不當使用、您發送之內容或您侵犯他人權利。惟本服務無法預先檢視、監控、管理或刪除任何訊息傳輸，我們不承擔使用者間行為之任何連帶責任。
若發現違規行為，我們有權採取階段性技術防堵，包括封鎖協議參與權、濾除違規封包等，等其他並不限於此處理方式，並可能通報司法機關。
您同意對於因違規、侵權、內容不當所引起之一切法律責任，承擔因違反本條款導致的責任，並在合理範圍內補償本應用可能因此遭受之損害，並使本應用免於任何第三方請求。

6. 緊急服務與免責聲明
6.1 非官方緊急服務：本服務無法連接官方緊急熱線，不具備備援通報功能或法定通報機制，僅供輔助溝通使用。僅作為災害或網路癱瘓時的補助通訊工具。
6.2 完全免責層（AS IS 條款）：本服務以「現狀」與「可用」方式提供，不對其可用性、準確性、相容性、持續性或效能提供任何保證。請勿將本應用用於醫療急救、飛航安全、生命維繫等關鍵用途，請使用者自行承擔。
6.3 特定免責-緊急通訊風險：因依賴本服務造成之任何傷害、損失、訊息延遲、誤傳、錯誤路由或未送達等風險，使用者應自行承擔。
建議在可用時優先使用官方緊急聯繫方式。
本應用不為第三方於衝突地區或跨境人道行動中之使用後果負責，使用者應評估當地法律與倫理風險。
6.4 損害限制層－賠償上限：在法律允許範圍內，您明確同意對於本服務所引起之任何申訴、請求、損害或爭議，我們的全部責任以您於該爭議發生前30日內實際支付給本服務的單次應用內購買金額為限，且該金額不得累計或合併其他時期的付款紀錄。我們不承擔任何因本服務之使用或無法使用所導致的間接、附帶、衍生性、懲罰性或特別損害，包括但不限於利潤損失、資料毀損、名譽受損、業務中斷、通訊失敗或人身傷亡。
如任何司法管轄區禁止或限制上述賠償限制條款之適用，則本應用僅於該地以法律所允許之最小限度承擔責任。

7. 爭議解決與法律適用
本條款僅適用中華民國（台灣）法律，並以台北地方法院為專屬第一審管轄法院。

8. 使用者資料控制與刪除
所有資料預設僅儲存於本機，訊息將於24小時內自動刪除，用戶可於應用內一鍵清除所有歷史紀錄。
因系統設計無法進行遠端刪除、封鎖、撤回、召回，請用戶自行妥善管理裝置與內容。

9. 智慧財產權與授權
SignalAir Rescue 的名稱、標誌、原始程式碼、設計、文件等均為我們所有。用戶所傳送內容之著作權歸用戶本人所有，但您授權本服務為完成通訊所需進行必要之編碼、封裝、加密與傳輸處理。

10. 條款變更與通知
本條款可能因法律變動、平台規定、功能修改而進行更新。重大變更將透過應用登入提示及推播通知提醒，並於通知後30天生效。若用戶於變更生效後仍持續使用，即視為同意新條款。若不同意，請立即停止使用並刪除應用程式。

11. 聯絡方式
Email：aa.prime.studio@gmail.com
處理時間：7個工作天內（不含例假日與國定假日）

12. 國際使用條款
本應用目前僅於台灣 App Store 上架與營運，暫不支援其他國家或地區之法律要求與消費者權益請求。未來如擴展至其他市場，將另行公告補充該區域適用之權利義務與隱私條款。
其他地區：若您於台灣以外地區使用本服務，請依當地法令自我審查並承擔相關使用風險。如需協助，請聯絡我們信箱。

13. 服務變更與終止
13.1 我們保留隨時調整、改進、中止服務或其任何部分的權利，無需事前通知。
13.2 您可隨時停止使用，並自行移除應用程式。
13.3 雖無遠端停權功能，但若偵測嚴重違規濫用行為，我們得採取技術手段避免系統資源被持續濫用。

14. 應用內購買與退款政策
14.1 某些功能為付費項目，由 Apple App Store 處理交易。
14.2 所有退款請依 Apple 規定進行，我們無法直接介入或核發退款。
14.3 若包含訂閱服務，用戶可於 iOS 裝置的系統設定中管理與取消。

15. 出口管制
本服務涉及強加密技術，可能受美國及其他國家之出口管制規定限制，使用者須遵守所有適用出口法規。本應用涉及通訊加密機制，若未來擴展至海外市場，使用者應自行查明其所在地法律對加密技術之規範與出口限制。本應用並無設計或行銷用途指向軍事或雙重用途。

16. 一般條款補述
16.1 本文件為您與我們之完整協議，取代一切口頭或書面先前協議。
16.2 可分割性：若部分條款被判定為無效或不可執行，不影響其他條款之效力。
16.3 豁免：我們未主張或執行本條款中任何權利，並不構成放棄該權利。
16.4 轉讓：您不得將本協議之權利與義務轉讓予第三人。我們得自由轉讓本條款之權利予第三方。
16.5 不可抗力：因自然災害、戰爭、政變、停電、系統毀損等不可抗力因素導致之服務中斷、失效，我們不承擔責任。

如您對本條款內容有任何疑問，請來信 Email：aa.prime.studio@gmail.com，我們將竭誠協助。
"""
    
    static let termsOfServiceEnUS = """
SignalAir Rescue Terms of Service
Last Updated: June 2025
Version: 1.1

SignalAir Rescue (hereinafter referred to as "this Application" or "we") is a decentralized, fully offline emergency communication application designed specifically for peer-to-peer messaging in network-disconnected environments. The following constitutes the full Terms of Service:

1. Core Principles of the Service
No Central Server: All data is processed solely on local devices and never uploaded to the cloud. We have no access to, control over, or ability to monitor any user communication content or behavior.

End-to-End Encryption: Messages are readable only by the sender and recipient, utilizing Curve25519 and AES-256-GCM encryption technologies.

Minimal Data Collection: Only information strictly necessary to operate the service is collected.

Fully Offline Availability: The service operates entirely offline via short-range, peer-to-peer device transmission without relying on any internet infrastructure.

2. Acceptance of Terms and Age Restrictions
By downloading, installing, accessing, or using SignalAir Rescue, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and Privacy Policy.

If you do not agree with any part of these Terms, do not download, install, or use the Application.

Users in Taiwan must be at least 13 years old. We reserve the right to request proof of age and may restrict or terminate access for underage users.

3. System Classification, Technical Architecture, and Legal Disclaimer
3.1 Technology and Classification
This Application utilizes Internet Protocol (IP) and short-range wireless technologies (Bluetooth, Wi-Fi Direct) and does not constitute a radio device or involve radio spectrum licensing. You acknowledge that the service differs from FRS, GMRS, or HAM radios and is intended solely as a supplementary coordination tool during disasters or communication failures.

You must comply with applicable laws in your jurisdiction. If encryption communications or specific frequency devices are restricted in your area, you are solely responsible for verifying legality and assuming associated risks.

3.2 Prohibited Conduct
You may not:
Engage in fraud, drug trafficking, human trafficking, terrorism, money laundering, or any illegal activity.
Distribute pornographic, hateful, violent, discriminatory content, or unauthorized confidential information.
Reverse-engineer, tamper with, scan, inject malware, impersonate others, harass, or interfere with legitimate usage by others.
Set up unauthorized relays or nodes for purposes outside the scope of these Terms.
Use automated tools, mass scanning, simulated devices, or AI models to generate batch messages disrupting the network.

3.3 Acceptable Use Policy (AUP)
Permitted lawful uses include real disaster response, emergency coordination, civic humanitarian aid, disaster drills, educational training, and legally allowed non-commercial personal use.

Encryption provided by the Application is solely for protecting user communications and data privacy, not for military, intelligence, or restricted uses.
Users must comply with local and export control laws and may not use the Application in restricted countries or regions.

4. Technical Enforcement and Indemnity
We reserve the right to implement tiered technical measures upon detection of violations, including but not limited to: disabling device connectivity, blocking relay protocol participation, or temporarily suspending messaging features. We may apply detection-based packet filtering or deny transmission of infringing messages.

You agree to indemnify, defend, and hold us harmless against any claims arising from your violations of these Terms, misuse, content transmission, or infringement of others' rights. However, we cannot preview, monitor, manage, or delete any message transmissions in advance and assume no joint liability for user interactions.

Upon discovering violations, we may take progressive enforcement steps including, but not limited to, revoking protocol participation rights, filtering offending packets, and reporting to legal authorities.

You agree to bear full legal responsibility for any violations, infringements, or inappropriate content and shall compensate us for any damages caused by such violations within a reasonable scope, and hold us harmless from any third-party claims.

6. Emergency Services and Disclaimers
6.1 No Official Emergency Services
This service does not connect to official emergency hotlines and lacks backup reporting or statutory emergency mechanisms. It serves solely as an auxiliary communication tool during disasters or internet outages.
6.2 AS IS Disclaimer
This service is provided "as is" and "as available" without any warranties regarding availability, accuracy, compatibility, continuity, or performance. Do not use this Application for critical purposes such as medical emergencies, aviation safety, or life support.
6.3 Specific Disclaimer – Emergency Communication Risks
Users assume all risks for injuries, losses, message delays, misdelivery, misrouting, or failed transmissions caused by reliance on this service. Official emergency contact methods should be used when available.
We assume no responsibility for third-party use in conflict zones or cross-border humanitarian missions. Users should assess legal and ethical risks in such situations.
6.4 Limitation of Liability
To the fullest extent permitted by law, our total liability for any claim, demand, damage, or dispute arising from this service shall be limited to the amount you paid for any in-app purchase within 30 days prior to the event in question. This amount is not cumulative or aggregable with other transactions.

We are not liable for any indirect, incidental, consequential, punitive, or special damages, including but not limited to lost profits, data loss, reputational damage, business interruption, communication failure, or personal injury.

If any jurisdiction prohibits or limits these disclaimers, we shall assume liability only to the minimal extent permitted by law in that jurisdiction.

7. Dispute Resolution and Governing Law
These Terms are governed exclusively by the laws of the Republic of China (Taiwan), with the Taipei District Court as the court of first instance with exclusive jurisdiction.

8. User Data Control and Deletion
All data is stored locally by default, with messages automatically deleted within 24 hours. Users may delete all history with a single in-app action.

Due to system architecture, remote deletion, blocking, retraction, or recall is not possible. Users must manage devices and content independently.

9. Intellectual Property and License
The name, logo, source code, design, and documentation of SignalAir Rescue are our property. Copyright of user-generated content remains with the user, but you grant us a license to encode, package, encrypt, and transmit such content as necessary for communication.

10. Amendments and Notifications
These Terms may be updated due to legal changes, platform policies, or feature modifications. Material changes will be notified via app login prompts and push notifications, taking effect 30 days after such notice.

Continued use after changes take effect constitutes acceptance. If you do not agree, cease using and uninstall the Application immediately.

11. Contact Information
Email: aa.prime.studio@gmail.com
Response Time: Within 7 business days (excluding weekends and public holidays)

12. International Use Terms
This Application is currently available and operated only via the Taiwan App Store and does not support legal or consumer requirements of other countries or regions. Should expansion occur, applicable rights and privacy terms for those regions will be announced separately.

Users outside Taiwan must self-assess legal compliance and assume all associated risks. For assistance, contact the email above.

13. Service Modifications and Termination
13.1 We reserve the right to modify, improve, or suspend the service or any portion thereof at any time without prior notice.
13.2 You may stop using the service and remove the application at any time.
13.3 While remote suspension is not possible, we may apply technical controls to prevent system abuse if severe misconduct is detected.

14. In-App Purchases and Refund Policy
14.1 Certain features are paid items processed by Apple App Store.
14.2 Refunds must follow Apple's policies. We cannot directly intervene or issue refunds.
14.3 For subscription services, users may manage or cancel them through iOS system settings.

15. Export Control
This service involves strong encryption technologies and may be subject to export control regulations under U.S. or other applicable laws. Users must comply with all relevant export control laws.

If the Application expands to foreign markets, users must investigate local regulations concerning encryption technologies and export restrictions. This Application is not designed or marketed for military or dual-use purposes.

16. General Provisions
16.1 This document constitutes the entire agreement between you and us, superseding all prior oral or written agreements.
16.2 Severability: If any part of these Terms is found invalid or unenforceable, the remaining provisions remain in full effect.
16.3 Waiver: Our failure to enforce any right does not constitute a waiver of that right.
16.4 Assignment: You may not assign your rights or obligations under these Terms to any third party. We may freely assign our rights.
16.5 Force Majeure: We shall not be liable for service interruptions due to force majeure, including natural disasters, war, coups, power outages, or system failures.

If you have any questions regarding these Terms, please contact us via email at: aa.prime.studio@gmail.com. We will be happy to assist you.
"""
    
    // MARK: - 語言選擇函數
    static func getPrivacyPolicy(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return privacyPolicyEnUS
        default:
            return privacyPolicyZhTW
        }
    }
    
    static func getTermsOfService(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return termsOfServiceEnUS
        default:
            return termsOfServiceZhTW
        }
    }
    
    // MARK: - 標題獲取函數
    static func getPrivacyPolicyTitle(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return "Privacy Policy"
        default:
            return "隱私權政策"
        }
    }
    
    static func getTermsOfServiceTitle(language: String = "zh-TW") -> String {
        switch language {
        case "en", "en-US":
            return "Terms of Service"
        default:
            return "服務條款"
        }
    }
} 