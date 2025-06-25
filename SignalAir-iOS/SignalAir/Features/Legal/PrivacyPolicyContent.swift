import Foundation

/// 隱私權政策內容管理器
/// 獨立管理隱私權政策的多語言內容，遵循專業法律文件格式
class PrivacyPolicyContent {
    
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
    
    static func getPrivacyPolicyIntro(language: Language) -> String {
        switch language {
        case .chinese:
            return "本隱私權政策說明 SignalAir Rescue 如何處理您的個人資料與隱私權："
        case .english:
            return "This Privacy Policy explains how SignalAir Rescue handles your personal data and privacy rights:"
        }
    }
    
    static func getDataCollectionTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "1. 資料收集與用途 / Data Collection and Usage"
        case .english:
            return "1. Data Collection and Usage / 資料收集與用途"
        }
    }
    
    static func getDataCollectionContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
1.1 位置資訊：採用網格化處理（100~500公尺），僅計算相對距離與方向，模糊處理，無實際地理位置儲存。
1.2 設備資訊：僅收集型號、OS版本、隨機匿名設備ID（不追溯身份）。
1.3 通訊內容：端對端加密，僅本機儲存，24小時自動刪除，不傳送至伺服器。
1.4 不收集項目：姓名、電話、Email、IP、聯絡人、照片、錄音、付款資訊等個資。
"""
        case .english:
            return """
1.1 Location Data: Collected using a grid-based system (within 100–500 meters), calculating only relative distance and direction. Data is obfuscated and does not store precise geographic locations.
1.2 Device Information: Only device model, OS version, and a randomly generated anonymous device ID are collected. No identifiable information is traced.
1.3 Communication Content: All content is end-to-end encrypted, stored only locally, and automatically deleted within 24 hours. No data is transmitted to any server.
1.4 Data Not Collected: The Application does not collect your name, phone number, email address, IP address, contacts, photos, audio recordings, or payment information.
"""
        }
    }
    
    static func getDataSharingTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "2. 資料分享與傳輸 / Data Sharing and Transmission"
        case .english:
            return "2. Data Sharing and Transmission / 資料分享與傳輸"
        }
    }
    
    static func getDataSharingContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
2.1 資料僅於裝置間以點對點方式傳輸，不經任何伺服器或中介存取。
2.2 我們不出售、出租、交換、分享任何資料予第三方，除非法律要求。
2.3 由於去中心化架構，所有訊息一旦傳送即無法遠端撤回或刪除。
"""
        case .english:
            return """
2.1 All data is transmitted directly between devices using peer-to-peer (P2P) technology. No servers or intermediaries are involved in the transmission process.
2.2 We do not sell, rent, trade, or share any data with third parties unless required by law.
2.3 Due to the decentralized architecture, messages cannot be remotely recalled or deleted once sent.
"""
        }
    }
    
    static func getUserRightsTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "3. 用戶權利 / User Rights"
        case .english:
            return "3. User Rights / 用戶權利"
        }
    }
    
    static func getUserRightsContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
3.1 您可於應用程式內檢視、刪除或清除本地資料。
3.2 由於本服務採本地離線儲存與無中心架構，資料無法進行集中備份或符合一般「資料可攜性」標準（如 CSV、JSON 輸出格式）。
3.3 採用 iOS Keychain 加密保護密鑰，資料分散儲存於用戶裝置中，無單點故障風險。
"""
        case .english:
            return """
3.1 You may view, delete, or clear local data within the Application at any time.
3.2 As the service uses offline local storage and has no central server, we cannot provide centralized backups or standard "data portability" formats (e.g., CSV, JSON).
3.3 Encryption keys are protected via iOS Keychain. Data is distributed across users' devices, avoiding single points of failure.
"""
        }
    }
    
    static func getDataSecurityTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "4. 資料安全措施 / Data Security Measures"
        case .english:
            return "4. Data Security Measures / 資料安全措施"
        }
    }
    
    static func getDataSecurityContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
4.1 採用 Curve25519 + AES-256-GCM 實作端對端加密與前向保密機制，並透過 iOS Keychain 加密儲存本地機密金鑰。
4.2 資料分散儲存於各使用者設備，無單點故障風險。
4.3 誠實揭露：因系統完全去中心化與本地儲存特性，無法防止下列風險：
    • 收件者截圖或記錄
    • 設備遭竊或遺失
    • 其他使用者轉傳訊息
"""
        case .english:
            return """
4.1 SignalAir Rescue uses Curve25519 and AES-256-GCM to implement end-to-end encryption and forward secrecy. Local secret keys are encrypted and stored using iOS Keychain.
4.2 All user data is stored on individual user devices, eliminating centralized vulnerabilities.
4.3 Transparency Notice: Due to the fully decentralized and local storage design, the following risks cannot be technically prevented:
    • Screenshots or recordings made by recipients
    • Device theft or loss
    • Forwarding of messages by other users
"""
        }
    }
    
    static func getDataControlTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "5. 使用者資料控制與刪除 / User Data Control and Deletion"
        case .english:
            return "5. User Data Control and Deletion / 使用者資料控制與刪除"
        }
    }
    
    static func getDataControlContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
5.1 所有資料預設僅儲存於本機，訊息將於24小時內自動刪除。
5.2 用戶可於應用內一鍵清除所有歷史紀錄。
5.3 因系統設計無法進行遠端刪除、封鎖、撤回、召回，請用戶自行妥善管理裝置與內容。
"""
        case .english:
            return """
5.1 By default, all data is stored only on the device. Messages are automatically deleted within 24 hours.
5.2 Users may use an in-app feature to erase all history with a single action.
5.3 Due to system design, remote deletion, blocking, revocation, or recall is not possible. Users are responsible for the appropriate handling of their devices and content.
"""
        }
    }
    
    static func getContactTitle(language: Language) -> String {
        switch language {
        case .chinese:
            return "6. 聯絡方式 / Contact Information"
        case .english:
            return "6. Contact Information / 聯絡方式"
        }
    }
    
    static func getContactContent(language: Language) -> String {
        switch language {
        case .chinese:
            return """
如對隱私政策有任何疑問，請來信：
Email：aa.prime.studio@gmail.com
處理時間：7個工作天內（不含例假日與國定假日）
"""
        case .english:
            return """
If you have any questions regarding this Privacy Policy, please contact us at:
Email: aa.prime.studio@gmail.com
Response Time: Within 7 business days (excluding weekends and public holidays)
"""
        }
    }
    
    // MARK: - 完整內容獲取方法
    
    static func getFullContent(language: Language) -> String {
        let sections = [
            
            getLastUpdated(language: language),
            "",
            getPrivacyPolicyIntro(language: language),
            "",
            getDataCollectionTitle(language: language),
            getDataCollectionContent(language: language),
            getDataSharingTitle(language: language),
            getDataSharingContent(language: language),
            getUserRightsTitle(language: language),
            getUserRightsContent(language: language),
            getDataSecurityTitle(language: language),
            getDataSecurityContent(language: language),
            getDataControlTitle(language: language),
            getDataControlContent(language: language),
            getContactTitle(language: language),
            getContactContent(language: language)
        ]
        
        return sections.joined(separator: "\n")
    }
} 