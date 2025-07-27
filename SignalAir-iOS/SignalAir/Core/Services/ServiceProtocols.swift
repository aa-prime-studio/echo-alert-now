import Foundation
import MultipeerConnectivity

// MARK: - 服務協議定義
// 為了支持依賴注入和測試，我們為主要服務定義協議

// MARK: - 網路服務協議
protocol NetworkServiceProtocol: AnyObject {
    var isConnected: Bool { get }
    var myPeerID: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    var onDataReceived: ((Data, String) -> Void)? { get set }
    var onPeerConnected: ((String) -> Void)? { get set }
    var onPeerDisconnected: ((String) -> Void)? { get set }
    
    func startNetworking()
    func stopNetworking()
    func send(_ data: Data, to peers: [MCPeerID]) async throws
}

// MARK: - 安全服務協議
protocol SecurityServiceProtocol: AnyObject {
    func generateSessionKey() -> Data?
    func encryptData(_ data: Data) -> Data?
    func decryptData(_ data: Data) -> Data?
    func hasSessionKey(for peerID: String) async -> Bool
    func encrypt(_ data: Data, for peerID: String) throws -> Data
    func decrypt(_ data: Data, from peerID: String) throws -> Data
    func getPublicKey() throws -> Data
    func removeSessionKey(for peerID: String)
}

// MARK: - 語言服務協議
protocol LanguageServiceProtocol: AnyObject {
    var currentLanguage: String { get }
    func setLanguage(_ language: String)
    func localizedString(for key: String) -> String
}

// MARK: - 暱稱服務協議
protocol NicknameServiceProtocol: AnyObject {
    var currentNickname: String { get }
    func setNickname(_ nickname: String)
    func generateRandomNickname() -> String
}

// MARK: - 購買服務協議
protocol PurchaseServiceProtocol: AnyObject {
    var hasPremiumAccess: Bool { get }
    func checkPurchaseStatus() async
    func restorePurchases() async
}

// MARK: - 設定視圖模型協議
protocol SettingsViewModelProtocol: AnyObject {
    var isDebugMode: Bool { get }
    var maxConnections: Int { get }
    func updateSetting<T>(_ key: String, value: T)
}

// MARK: - 協議擴展 - 預設實現
extension NetworkServiceProtocol {
    func startNetworking() {
        print("🌐 NetworkService: 預設啟動網路")
    }
    
    func stopNetworking() {
        print("🌐 NetworkService: 預設停止網路")
    }
}

extension SecurityServiceProtocol {
    func generateSessionKey() -> Data? {
        #if DEBUG
        print("🔐 SecurityService: 預設產生會話密鑰")
        #endif
        return Data()
    }
}

extension LanguageServiceProtocol {
    func setLanguage(_ language: String) {
        print("🌍 LanguageService: 預設設定語言 \(language)")
    }
    
    func localizedString(for key: String) -> String {
        return key // 預設返回 key 本身
    }
}

extension NicknameServiceProtocol {
    func setNickname(_ nickname: String) {
        print("👤 NicknameService: 預設設定暱稱 \(nickname)")
    }
    
    func generateRandomNickname() -> String {
        return "用戶\(Int.random(in: 1000...9999))"
    }
}

extension PurchaseServiceProtocol {
    func checkPurchaseStatus() async {
        print("💰 PurchaseService: 預設檢查購買狀態")
    }
    
    func restorePurchases() async {
        print("💰 PurchaseService: 預設恢復購買")
    }
}

extension SettingsViewModelProtocol {
    func updateSetting<T>(_ key: String, value: T) {
        print("⚙️ SettingsViewModel: 預設更新設定 \(key) = \(value)")
    }
}

// MARK: - 服務組合協議
protocol CoreServicesProtocol {
    var networkService: NetworkServiceProtocol { get }
    var securityService: SecurityServiceProtocol { get }
    var languageService: LanguageServiceProtocol { get }
    var nicknameService: NicknameServiceProtocol { get }
}

// MARK: - 遊戲服務協議
protocol GameServicesProtocol {
    var timerManager: UnifiedTimerManager { get }
    var networkManager: BingoNetworkManager { get }
    var stateManager: BingoGameStateManager { get }
}

// MARK: - 測試模擬協議
protocol MockServiceProtocol {
    var isMockService: Bool { get }
    func resetMockState()
}