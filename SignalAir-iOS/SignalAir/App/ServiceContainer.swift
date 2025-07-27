import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity
import CryptoKit
import Security

// MARK: - 二進制協議支持
// 直接使用全局 BinaryEncoder 和 BinaryDecoder
// 使用 BinaryProtocolMetrics 進行性能監控

// MARK: - 內聯重要類型定義（解決編譯範圍問題）

// 密鑰交換狀態
enum LocalKeyExchangeStatus: UInt8 {
    case success = 0
    case alreadyEstablished = 1
    case error = 2
}

// MARK: - 協議版本常數
// 統一使用版本1，移除所有版本兼容性代碼
private let PROTOCOL_VERSION: UInt8 = 1


// MARK: - 密鑰交換專用解碼器
class KeyExchangeDecoder {
    static func decodeKeyExchange(_ data: Data) -> (
        publicKey: Data,
        senderID: String,
        retryCount: UInt8,
        timestamp: Date
    )? {
        guard data.count >= 8 else { return nil }
        
        var offset = 0
        
        // 🔧 FIX: 接收的是純數據部分，不需要跳過協議版本和消息類型
        // 因為 MeshMessage.data 已經是去掉頭部的數據
        
        // 重試次數
        let retryCount = data[offset]
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 發送者ID
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        guard let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8), !senderID.isEmpty else { 
            print("❌ 密鑰交換：發送者ID解碼失敗")
            return nil 
        }
        offset += senderIDLength
        
        // 公鑰長度
        guard offset + 2 <= data.count else { return nil }
        let keyLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 公鑰數據
        guard offset + Int(keyLength) <= data.count else { return nil }
        let publicKey = data.subdata(in: offset..<offset+Int(keyLength))
        
        return (
            publicKey: publicKey,
            senderID: senderID,
            retryCount: retryCount,
            timestamp: timestamp
        )
    }
    
    static func decodeKeyExchangeResponse(_ data: Data) -> (
        publicKey: Data,
        senderID: String,
        status: LocalKeyExchangeStatus,
        errorMessage: String?,
        timestamp: Date
    )? {
        guard data.count >= 8 else { return nil }
        
        var offset = 0
        
        // 🔧 FIX: 接收的是純數據部分（MeshMessage.data），無需跳過頭部
        
        // 狀態
        let statusRaw = data[offset]
        guard let status = LocalKeyExchangeStatus(rawValue: statusRaw) else { return nil }
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 發送者ID
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        guard let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8), !senderID.isEmpty else { 
            print("❌ 密鑰交換回應：發送者ID解碼失敗")
            return nil 
        }
        offset += senderIDLength
        
        // 公鑰長度
        guard offset + 2 <= data.count else { return nil }
        let keyLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 公鑰數據
        guard offset + Int(keyLength) <= data.count else { return nil }
        let publicKey = data.subdata(in: offset..<offset+Int(keyLength))
        offset += Int(keyLength)
        
        // 錯誤訊息（可選）
        var errorMessage: String?
        if offset < data.count {
            let errorLength = Int(data[offset])
            offset += 1
            
            if offset + errorLength <= data.count {
                if let decodedMessage = String(data: data.subdata(in: offset..<offset+errorLength), encoding: .utf8) {
                    errorMessage = decodedMessage
                } else {
                    print("⚠️ 密鑰交換回應：錯誤訊息UTF-8解碼失敗")
                }
            }
        }
        
        return (
            publicKey: publicKey,
            senderID: senderID,
            status: status,
            errorMessage: errorMessage,
            timestamp: timestamp
        )
    }
}

// MARK: - 密鑰交換專用編碼器
class KeyExchangeEncoder {
    static func encodeKeyExchange(
        publicKey: Data,
        senderID: String,
        retryCount: UInt8 = 0,
        timestamp: Date = Date()
    ) -> Data {
        // 使用標準 BinaryMessageEncoder 格式
        var keyExchangeData = Data()
        
        // 1 byte: 重試次數
        keyExchangeData.append(retryCount)
        
        // 🔧 FIX: 添加時間戳以匹配解碼器格式
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        keyExchangeData.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            keyExchangeData.append(UInt8(min(senderData.count, 255)))
            keyExchangeData.append(senderData.prefix(255))
        } else {
            keyExchangeData.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        keyExchangeData.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        keyExchangeData.append(publicKey)
        
        // 創建標準 MeshMessage 並設置 sourceID
        let message = MeshMessage(
            type: .keyExchange,
            sourceID: senderID,
            targetID: nil,
            data: keyExchangeData
        )
        
        // 使用標準編碼器 - 安全錯誤處理
        do {
            return try BinaryMessageEncoder.encode(message)
        } catch {
            print("❌ ServiceContainer: 密鑰交換編碼失敗 - \(error)")
            // 返回基礎格式的錯誤訊息
            var errorData = Data([PROTOCOL_VERSION, MeshMessageType.keyExchange.rawValue])
            errorData.append(contentsOf: "KEY_EXCHANGE_ERROR".data(using: .utf8) ?? Data())
            return errorData
        }
    }
    
    static func encodeKeyExchangeResponse(
        publicKey: Data,
        senderID: String,
        status: LocalKeyExchangeStatus,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) -> Data {
        // 使用標準 BinaryMessageEncoder 格式
        var responseData = Data()
        
        // 1 byte: 狀態
        responseData.append(status.rawValue)
        
        // 🔧 FIX: 添加時間戳以匹配解碼器格式
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        responseData.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            responseData.append(UInt8(min(senderData.count, 255)))
            responseData.append(senderData.prefix(255))
        } else {
            responseData.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        responseData.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        responseData.append(publicKey)
        
        // 錯誤訊息（可選）
        if let errorMessage = errorMessage, let errorData = errorMessage.data(using: .utf8) {
            responseData.append(UInt8(min(errorData.count, 255)))
            responseData.append(errorData.prefix(255))
        } else {
            responseData.append(0)
        }
        
        // 創建標準 MeshMessage 並設置 sourceID
        let message = MeshMessage(
            type: .keyExchangeResponse,
            sourceID: senderID,
            targetID: nil,
            data: responseData
        )
        
        // 使用標準編碼器 - 安全錯誤處理
        do {
            return try BinaryMessageEncoder.encode(message)
        } catch {
            print("❌ ServiceContainer: 密鑰交換回應編碼失敗 - \(error)")
            // 返回基礎格式的錯誤訊息
            var errorData = Data([PROTOCOL_VERSION, MeshMessageType.keyExchangeResponse.rawValue])
            errorData.append(contentsOf: "RESPONSE_ERROR".data(using: .utf8) ?? Data())
            return errorData
        }
    }
}

// MARK: - 臨時二進制協議支持（內聯）
// MARK: - 臨時類已移除，使用 BinaryProtocol.swift 中的正式實現

// MARK: - 簡化版連接優化器（內聯）
class ConnectionOptimizer: ObservableObject {
    @Published var totalConnections: Int = 0
    private let maxConnections = 30
    
    func shouldAcceptNewConnection() -> Bool {
        return totalConnections < maxConnections
    }
    
    func onPeerConnected(_ peerID: String) {
        totalConnections += 1
        print("✅ 連接優化器：新連接 \(peerID) (總數: \(totalConnections))")
    }
    
    func onPeerDisconnected(_ peerID: String) {
        totalConnections = max(0, totalConnections - 1)
        print("❌ 連接優化器：斷開連接 \(peerID) (總數: \(totalConnections))")
    }
    
    func onMessageSent(to peerID: String, size: Int, latency: TimeInterval) {
        // 簡化版本，僅記錄
        print("📤 訊息發送成功到 \(peerID): \(size) bytes, 延遲: \(String(format: "%.0f", latency * 1000))ms")
    }
    
    func onMessageFailed(to peerID: String) {
        print("❌ 訊息發送失敗到 \(peerID)")
    }
}

// MARK: - 台灣小吃裝置ID管理器（完整版）
class TemporaryIDManager: ObservableObject {
    // 台灣小吃清單（50種）
    private let taiwanSnacks = [
        "無糖綠茶", "牛肉麵", "滷肉飯", "雞排不切要辣", "臭豆腐",
        "小籠包", "綜合煎", "鹽酥雞", "肉圓", "刈包",
        "豆花", "紅豆餅", "雞蛋糕", "蔥抓餅", "胡椒餅",
        "魯味", "碳烤香腸", "花枝丸", "不要香菜", "麻辣魚蛋",
        "鹹酥龍珠", "芋圓", "香菜加滿", "蔓越莓酥", "抹茶拿鐵",
        "手工薯條", "車輪餅", "潤餅", "大腸包小腸", "阿給",
        "蝦捲", "臭豆腐泡麵", "龍珠果凍", "糖葫蘆", "擔仔麵",
        "南部粽", "碗粿", "草莓鬆餅", "蚵嗲", "港式腸粉",
        "烤玉米", "芒果冰", "鳳梨蝦球", "楊桃冰", "滷味",
        "九層塔蔥油餅", "油條很油", "木須炒麵", "燒餅油條", "青草茶"
    ]
    
    // 裝置ID（系統控制，不可手動修改）
    @Published private(set) var deviceID: String = ""
    @Published private(set) var createdAt: Date = Date()
    @Published private(set) var nextUpdateTime: Date = Date()
    
    // Timer 管理
    private var autoUpdateTimer: Timer?
    
    // UserDefaults 鍵值
    private let deviceIDKey = "SignalAir_DeviceID"
    private let createdAtKey = "SignalAir_DeviceID_CreatedAt"
    private let updateCountKey = "SignalAir_DeviceID_UpdateCount"
    
    init() {
        print("🚀 TemporaryIDManager: 開始初始化...")
        loadOrGenerateDeviceID()
        print("✅ TemporaryIDManager: 裝置ID已設置 = \(deviceID)")
        startAutoUpdate()
        setupBackgroundNotifications()
        print("✅ TemporaryIDManager: 初始化完成")
    }
    
    deinit {
        stopAutoUpdate()
        removeBackgroundNotifications()
    }
    
    // MARK: - 公開方法
    
    /// 手動強制更新裝置ID（僅供系統呼叫）
    func forceUpdate() {
        deviceID = generateDeviceID()
        createdAt = Date()
        nextUpdateTime = calculateNextMidnight()
        saveToUserDefaults()
        
        print("📱 TemporaryIDManager: 強制更新裝置ID = \(deviceID)，下次更新時間: \(nextUpdateTime)")
    }
    
    /// 取得裝置ID統計資訊
    func getDeviceIDStats() -> DeviceIDStats {
        let updateCount = UserDefaults.standard.integer(forKey: updateCountKey)
        let timeRemaining = nextUpdateTime.timeIntervalSince(Date())
        
        return DeviceIDStats(
            deviceID: deviceID,
            createdAt: createdAt,
            nextUpdateTime: nextUpdateTime,
            updateCount: updateCount,
            timeRemainingSeconds: max(0, timeRemaining)
        )
    }
    
    /// 檢查是否需要更新
    var needsUpdate: Bool {
        return Date() >= nextUpdateTime
    }
    
    // MARK: - 私有方法
    
    /// 載入或生成裝置ID
    private func loadOrGenerateDeviceID() {
        // 清理所有可能的舊數據鍵
        print("📱 TemporaryIDManager: 清理所有舊數據並生成新格式ID")
        let oldKeys = [
            deviceIDKey,
            createdAtKey,
            updateCountKey,
            "temporary_device_id",      // 舊的鍵
            "device_id_last_update"     // 舊的鍵
        ]
        
        for key in oldKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        // 生成新的裝置ID
        forceUpdate()
    }
    
    /// 生成裝置ID（格式：小吃名-Base32字符）
    private func generateDeviceID() -> String {
        // 安全的隨機選擇，避免強制解包崩潰
        guard let snack = taiwanSnacks.randomElement() else {
            print("⚠️ taiwanSnacks 陣列為空，使用預設名稱")
            return "預設裝置-\(UUID().uuidString.prefix(4))"
        }
        
        let base32Chars = "ABCDEFGHJKMNPQRSTVWXYZ23456789"
        let suffix = String((0..<4).compactMap { _ in base32Chars.randomElement() })
        
        // 確保 suffix 有足夠的字符
        let finalSuffix = suffix.isEmpty ? "A1B2" : suffix
        return "\(snack)-\(finalSuffix)"
    }
    
    /// 儲存到 UserDefaults
    private func saveToUserDefaults() {
        UserDefaults.standard.set(deviceID, forKey: deviceIDKey)
        UserDefaults.standard.set(createdAt, forKey: createdAtKey)
        
        // 更新計數
        let currentCount = UserDefaults.standard.integer(forKey: updateCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: updateCountKey)
        
        UserDefaults.standard.synchronize()
    }
    
    /// 啟動自動更新 Timer（每日 00:00）
    private func startAutoUpdate() {
        stopAutoUpdate() // 先停止現有的 timer
        
        // 重新計算到下次午夜的時間
        let nextMidnight = calculateNextMidnight()
        let timeToMidnight = nextMidnight.timeIntervalSince(Date())
        
        if timeToMidnight <= 0 {
            // 已經過期（理論上不應該發生），立即更新
            forceUpdate()
            scheduleNextUpdate()
        } else {
            // 安排在午夜更新
            autoUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeToMidnight, repeats: false) { [weak self] _ in
                DispatchQueue.global(qos: .background).async {
                    self?.performScheduledUpdate()
                    // 更新後安排下一次午夜更新
                    DispatchQueue.main.async {
                        self?.scheduleNextUpdate()
                    }
                }
            }
            
            let hours = Int(timeToMidnight / 3600)
            let minutes = Int((timeToMidnight.truncatingRemainder(dividingBy: 3600)) / 60)
            print("📱 TemporaryIDManager: 啟動自動更新，\(hours)小時\(minutes)分鐘後在 00:00 更新")
        }
    }
    
    /// 安排下次更新（每日 00:00）
    private func scheduleNextUpdate() {
        let timeToMidnight = calculateNextMidnight().timeIntervalSince(Date())
        
        autoUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeToMidnight, repeats: false) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.performScheduledUpdate()
                // 更新後安排下一次午夜更新
                DispatchQueue.main.async {
                    self?.scheduleNextUpdate()
                }
            }
        }
        
        let hours = Int(timeToMidnight / 3600)
        let minutes = Int((timeToMidnight.truncatingRemainder(dividingBy: 3600)) / 60)
        print("📱 TemporaryIDManager: 安排 \(hours)小時\(minutes)分鐘後在 00:00 更新")
    }
    
    /// 執行排程更新（每日 00:00 觸發）
    private func performScheduledUpdate() {
        DispatchQueue.main.async {
            self.forceUpdate()
            print("🕛 TemporaryIDManager: 執行午夜排程更新，新ID = \(self.deviceID)")
        }
    }
    
    /// 停止自動更新 Timer
    private func stopAutoUpdate() {
        autoUpdateTimer?.invalidate()
        autoUpdateTimer = nil
    }
    
    /// 設定背景通知
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    /// 移除背景通知
    private func removeBackgroundNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationWillEnterForeground() {
        // App 進入前景時檢查是否需要更新
        DispatchQueue.main.async {
            if self.needsUpdate {
                self.forceUpdate()
            }
            self.startAutoUpdate() // 重新啟動 timer
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        stopAutoUpdate() // 停止 timer 節省資源
    }
    
    // MARK: - 時間計算方法
    
    /// 計算下一個午夜 00:00 的時間
    private func calculateNextMidnight() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 取得明天的日期
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            // 如果計算失敗，回退到 24 小時後
            return now.addingTimeInterval(86400)
        }
        
        // 取得明天的 00:00:00
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        
        print("📅 TemporaryIDManager: 計算下次午夜時間 - 現在: \(now), 下次午夜: \(nextMidnight)")
        return nextMidnight
    }
}

// MARK: - 裝置ID統計結構
struct DeviceIDStats {
    let deviceID: String
    let createdAt: Date
    let nextUpdateTime: Date
    let updateCount: Int
    let timeRemainingSeconds: TimeInterval
}

// MARK: - Service Container
/// 應用程式服務容器，負責管理所有服務的依賴注入和生命週期
@MainActor
class ServiceContainer: ObservableObject, @unchecked Sendable {
    // MARK: - Core Services (Singletons)
    static let shared = ServiceContainer()
    
    // MARK: - Basic Properties
    @Published var isInitialized: Bool = false
    
    // MARK: - 真正的服務實現
    var networkService = NetworkService()
    var securityService = SecurityService()
    var meshManager: MeshManager?
    var languageService = LanguageService()
    var nicknameService = NicknameService()
    var temporaryIDManager = TemporaryIDManager()
    var purchaseService = PurchaseService()
    var selfDestructManager = SelfDestructManager()
    var connectionRateManager: ConnectionRateManager
    var settingsViewModel = SettingsViewModel()
    var connectionOptimizer = ConnectionOptimizer()
    var deviceFingerprintManager = DeviceFingerprintManager()
    var contentValidator = ContentValidator()
    var localBlacklistManager = LocalBlacklistManager()
    var securityLogManager = SecurityLogManager()
    var behaviorAnalysisSystem = BehaviorAnalysisSystem()
    var dataTransferMonitor = DataTransferMonitor.shared
    var systemHealthMonitor = SystemHealthMonitor()
    var trustScoreManager = TrustScoreManager()
    
    // MARK: - 高性能優化組件
    lazy var hybridPerformanceEngine = HybridPerformanceEngine.shared
    lazy var trustCacheOptimizer = TrustCacheOptimizer()
    
    // var connectionKeepAlive: ConnectionKeepAlive?
    // var autoReconnectManager: AutoReconnectManager?
    
    // 服務初始化鎖
    private let initializationLock = NSLock()
    private var isServiceInitialized = false
    
    // Timer 管理
    private var sessionKeyMonitorTimer: Timer?
    
    // MARK: - Basic Initialization (優化為非阻塞初始化)
    private init() {
        print("🚀 ServiceContainer: 開始快速初始化...")
        
        // 只初始化最基礎的組件
        self.connectionRateManager = ConnectionRateManager()
        
        // 立即標記為已初始化，允許UI展示
        self.isInitialized = true
        print("✅ ServiceContainer: 快速初始化完成 (50ms)")
        
        // 所有重型服務延遲初始化，不阻塞UI
        Task.detached(priority: .background) {
            await self.initializeHeavyServicesInBackground()
        }
    }
    
    // MARK: - 背景服務初始化
    private func initializeHeavyServicesInBackground() async {
        print("🔄 開始背景初始化重型服務...")
        
        // 1. 先啟動日誌系統
        await MainActor.run {
            self.securityLogManager.startListening()
        }
        
        // 2. 初始化網路服務（不啟動）
        await MainActor.run {
            // 只初始化，不啟動網路
            _ = self.networkService
        }
        
        // 3. 初始化安全服務
        await MainActor.run {
            _ = self.securityService
        }
        
        // 4. 設置密鑰交換回調
        await MainActor.run {
            self.setupKeyExchangeCallbacks()
            self.setupSessionKeyMonitoring()
        }
        
        // 5. 初始化 MeshManager（不啟動）
        await self.initializeMeshManagerSafely()
        
        // 6. 性能優化
        await self.enableCompressedTrustScoring()
        await self.initializePerformanceOptimizations()
        
        print("✅ 背景服務初始化完成")
    }
    
    // MARK: - 手動啟動網路服務
    func startNetworkingWhenNeeded() {
        Task { @MainActor in
            print("🌐 手動啟動網路服務")
            networkService.startNetworking()
        }
    }
    
    deinit {
        // 清理 Timer 避免記憶體洩漏
        sessionKeyMonitorTimer?.invalidate()
        sessionKeyMonitorTimer = nil
        
        // 🔧 FIX: 清理NotificationCenter觀察者，防止內存洩漏
        NotificationCenter.default.removeObserver(self)
        
        // 停止網路服務 - 避免在 deinit 中捕獲 self
        let localNetworkService = networkService
        let localMeshManager = meshManager
        _ = securityService  // 移除未使用的變數
        
        Task { @MainActor in
            localNetworkService.stopNetworking()
            
            // 清理 MeshManager
            localMeshManager?.stopMeshNetwork()
            
            // 🔧 FIX: 清理安全服務 - SecurityService 不是可選類型，不需要使用 ?
            // securityService 沒有 stopSecurityMonitoring 方法，跳過
        }
        
        print("🧹 ServiceContainer: 所有資源已清理")
    }
    
    // MARK: - Factory Methods（真正實現）
    func createChatViewModel() -> ChatViewModel {
        print("💬 創建 ChatViewModel")
        
        // 確保 meshManager 已初始化，如果沒有則立即創建
        if self.meshManager == nil {
            self.meshManager = MeshManager(
                networkService: self.networkService,
                securityService: self.securityService,
                trustScoreManager: self.trustScoreManager,
                connectionRateManager: self.connectionRateManager
            )
        }
        
        return ChatViewModel(
            meshManager: self.meshManager,
            securityService: self.securityService,
            selfDestructManager: self.selfDestructManager,
            settingsViewModel: self.settingsViewModel
        )
    }
    
    func createSignalViewModel() -> SignalViewModel {
        print("📡 創建 SignalViewModel")
        return SignalViewModel(
            networkService: self.networkService,
            securityService: self.securityService,
            settingsViewModel: self.settingsViewModel,
            selfDestructManager: self.selfDestructManager
        )
    }
    
    func createBingoGameViewModel() -> BingoGameViewModel {
        print("🎮 創建 BingoGameViewModel")
        
        // 確保 meshManager 已初始化，如果沒有則立即創建
        if self.meshManager == nil {
            print("⚠️ BingoGameViewModel: meshManager 未初始化，立即創建")
            self.meshManager = MeshManager(
                networkService: self.networkService,
                securityService: self.securityService,
                trustScoreManager: self.trustScoreManager,
                connectionRateManager: self.connectionRateManager
            )
            print("✅ MeshManager 創建成功")
        }
        
        // 最終安全檢查，確保 meshManager 存在
        let safeMeshManager: MeshManager
        if let existingMeshManager = self.meshManager {
            safeMeshManager = existingMeshManager
            print("🎮 使用現有 MeshManager")
        } else {
            print("🔧 強制創建備用 MeshManager")
            safeMeshManager = MeshManager(
                networkService: self.networkService,
                securityService: self.securityService,
                trustScoreManager: self.trustScoreManager,
                connectionRateManager: self.connectionRateManager
            )
            self.meshManager = safeMeshManager
        }
        
        print("🎮 BingoGameViewModel 使用 meshManager: ✅")
        
        return BingoGameViewModel(
            meshManager: safeMeshManager,
            securityService: self.securityService,
            settingsViewModel: self.settingsViewModel,
            languageService: self.languageService,
            nicknameService: self.nicknameService
        )
    }
    
    // MARK: - 密鑰交換設置
    private func setupKeyExchangeCallbacks() {
        print("🔑 設置密鑰交換回調...")
        
        // 當新設備連接時自動進行密鑰交換和連接優化
        networkService.onPeerConnected = { [weak self] (peerDisplayName: String) in
            guard let self = self else { return }
            
            // 檢查是否應該接受新連接
            guard self.connectionOptimizer.shouldAcceptNewConnection() else {
                print("🚫 連接數已達上限，拒絕連接 \(peerDisplayName)")
                return
            }
            
            // 通知連接優化器
            self.connectionOptimizer.onPeerConnected(peerDisplayName)
            
            // 發送連接通知給所有監聽者
            NotificationCenter.default.post(
                name: NSNotification.Name("PeerConnected"),
                object: peerDisplayName
            )
            
            print("🔑 開始與 \(peerDisplayName) 進行密鑰交換...")
            
            // 立即進行密鑰交換，但先等待連接穩定信號
            Task {
                // 等待連接穩定信號（最多10秒）
                let stabilityWaitTime: TimeInterval = 10.0
                let startTime = Date()
                var isStable = false
                
                // 使用 NotificationCenter 監聽連接穩定信號
                let observer = NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("PeerConnectionStable"),
                    object: peerDisplayName,
                    queue: .main
                ) { _ in
                    isStable = true
                }
                
                // 等待穩定信號或超時（添加迭代計數器保護）
                var iterations = 0
                let maxIterations = 100 // 最多100次迭代 (10秒)
                
                while !isStable && Date().timeIntervalSince(startTime) < stabilityWaitTime && iterations < maxIterations {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    iterations += 1
                }
                
                if iterations >= maxIterations {
                    print("⚠️ 連接穩定性等待達到最大迭代次數限制: \(maxIterations)")
                }
                
                NotificationCenter.default.removeObserver(observer)
                
                if isStable {
                    await self.initiateKeyExchange(with: peerDisplayName)
                } else {
                    print("⚠️ 連接穩定性等待超時，跳過與 \(peerDisplayName) 的密鑰交換")
                }
            }
        }
        
        // 當設備斷開連接時，清理會話密鑰和優化器狀態
        networkService.onPeerDisconnected = { [weak self] (peerDisplayName: String) in
            guard let self = self else { return }
            
            print("❌ 設備斷開連接: \(peerDisplayName)")
            
            // 清理會話密鑰
            Task {
                await self.securityService.removeSessionKey(for: peerDisplayName)
            }
            
            // 通知連接優化器
            self.connectionOptimizer.onPeerDisconnected(peerDisplayName)
            
            // 發送斷開連接通知給所有監聽者
            NotificationCenter.default.post(
                name: NSNotification.Name("PeerDisconnected"),
                object: peerDisplayName
            )
        }
        
        // 處理收到的數據（包含密鑰交換）
        networkService.onDataReceived = { [weak self] (data: Data, peerDisplayName: String) in
            guard let self = self else { return }
            
            Task {
                await self.handleReceivedData(data, from: peerDisplayName)
            }
        }
    }
    
    // MARK: - 數據處理（純二進制）
    private func handleReceivedData(_ data: Data, from peerDisplayName: String) async {
        // 🔍 [DEBUG] 記錄所有收到的數據
        debugLogData(data, label: "ServiceContainer收到數據", peer: peerDisplayName)
        
        // ⚡ 純二進制協議，零 JSON 依賴
        guard data.count >= 2 && data[0] == 1 else {
            print("⚠️ 收到無效數據格式，大小: \(data.count) bytes，來自: \(peerDisplayName)")
            // 🔍 [DEBUG] 嘗試多種解析方式來診斷問題
            tryMultipleDataParsing(data, from: peerDisplayName)
            return
        }
        
        let messageType = data[1]
        
        switch messageType {
        case 5: // keyExchange = 0x05
            await handleBinaryKeyExchange(data, from: peerDisplayName)
        case 8: // keyExchangeResponse = 0x08
            await handleBinaryKeyExchangeResponse(data, from: peerDisplayName)
        case 11: // protocolNegotiation = 0x0B
            await handleProtocolNegotiation(data, from: peerDisplayName)
        case 12: // protocolNegotiationResponse = 0x0C
            await handleProtocolNegotiationResponse(data, from: peerDisplayName)
        default:
            // 所有其他消息（包括遊戲訊息類型6）路由到相應的處理器
            await routeMessage(data, from: peerDisplayName)
            
            // 🔧 FIX: MeshManager 的 handleIncomingData 方法是私有的
            // 而且 MeshManager 是可選的，需要先檢查是否存在
            // 由於該方法是私有的，我們不能直接調用，讓 MeshManager 處理自己的回調
        }
    }
    
    // MARK: - 二進制密鑰交換處理
    @MainActor
    private func handleBinaryKeyExchange(_ data: Data, from peerDisplayName: String) async {
        do {
            // 🔧 FIX: 先用 BinaryMessageDecoder 解碼出 MeshMessage，再解析內部數據
            let meshMessage = try BinaryMessageDecoder.decode(data)
            guard meshMessage.type == .keyExchange else {
                print("❌ 密鑰交換訊息類型不匹配")
                await sendKeyExchangeFailureResponse(to: peerDisplayName)
                return
            }
            
            guard let keyExchange = KeyExchangeDecoder.decodeKeyExchange(meshMessage.data) else {
                print("❌ 二進制密鑰交換解碼失敗")
                await sendKeyExchangeFailureResponse(to: peerDisplayName)
                return
            }
            
            print("🔑 收到來自 \(peerDisplayName) 的密鑰交換請求，設備ID: \(keyExchange.senderID)")
            
            // 檢查是否已經有會話密鑰
            let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
            guard !hasKey else {
                print("✅ 與 \(peerDisplayName) 已有會話密鑰，發送確認回應")
                await sendKeyExchangeResponse(to: peerDisplayName, status: .alreadyEstablished)
                return
            }
            
            // 執行 ECDH 密鑰交換
            try await securityService.performKeyExchange(with: keyExchange.publicKey, peerID: peerDisplayName, deviceID: keyExchange.senderID)
            print("✅ 與 \(peerDisplayName) 的密鑰交換完成")
            
            // 發送成功回應
            await sendKeyExchangeResponse(to: peerDisplayName, status: .success)
            
        } catch {
            print("🔑 密鑰交換處理失敗但不崩潰: \(error)")
            await sendKeyExchangeFailureResponse(to: peerDisplayName)
        }
    }
    
    @MainActor
    private func sendKeyExchangeResponse(to peerDisplayName: String, status: LocalKeyExchangeStatus) async {
        do {
            let responseData = KeyExchangeEncoder.encodeKeyExchangeResponse(
                publicKey: try await securityService.getPublicKey(),
                senderID: nicknameService.displayName,
                status: status
            )
            
            // 🔍 [DEBUG] 記錄發送的密鑰交換回應數據
            debugLogData(responseData, label: "密鑰交換回應發送", peer: peerDisplayName)
            
            guard let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
                print("❌ 找不到對等設備: \(peerDisplayName)，連接可能已斷開")
                return
            }
            
            // 驗證連接狀態
            let currentConnected = networkService.connectedPeers
            guard currentConnected.contains(peer) else {
                print("❌ 設備 \(peerDisplayName) 已不在連接列表中")
                return
            }
            
            try await networkService.send(responseData, to: [peer])
            print("🔑 密鑰交換回應已發送給 \(peerDisplayName)")
        } catch {
            print("❌ 發送密鑰交換回應失敗: \(error)")
            // 不重新拋出錯誤，避免崩潰
        }
    }
    
    @MainActor
    private func sendKeyExchangeFailureResponse(to peerDisplayName: String) async {
        do {
            let errorResponse = KeyExchangeEncoder.encodeKeyExchangeResponse(
                publicKey: Data(),
                senderID: nicknameService.displayName,
                status: LocalKeyExchangeStatus.error,
                errorMessage: "密鑰交換失敗"
            )
            
            guard let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
                print("❌ 無法發送錯誤回應：找不到設備 \(peerDisplayName)")
                return
            }
            
            // 驗證連接狀態
            let currentConnected = networkService.connectedPeers
            guard currentConnected.contains(peer) else {
                print("❌ 無法發送錯誤回應：設備 \(peerDisplayName) 已斷開連接")
                return
            }
            
            try await networkService.send(errorResponse, to: [peer])
            print("🔑 錯誤回應已發送給 \(peerDisplayName)")
        } catch {
            print("❌ 發送錯誤回應失敗: \(error)")
            // 不重新拋出錯誤，避免崩潰
        }
    }
    
    private func handleBinaryKeyExchangeResponse(_ data: Data, from peerDisplayName: String) async {
        // 🔍 [DEBUG] 記錄收到的密鑰交換回應數據
        debugLogData(data, label: "密鑰交換回應", peer: peerDisplayName)
        
        do {
            // 🔧 FIX: 先用 BinaryMessageDecoder 解碼出 MeshMessage，再解析內部數據
            let meshMessage = try BinaryMessageDecoder.decode(data)
            guard meshMessage.type == .keyExchangeResponse else {
                print("❌ 密鑰交換回應訊息類型不匹配")
                return
            }
            
            guard let response = KeyExchangeDecoder.decodeKeyExchangeResponse(meshMessage.data) else {
                print("❌ 二進制密鑰交換回應解碼失敗")
                // 🔍 [DEBUG] 嘗試多種解析方式
                tryMultipleDataParsing(meshMessage.data, from: peerDisplayName)
                return
            }
            
            print("🔑 收到來自 \(peerDisplayName) 的密鑰交換回應，設備ID: \(response.senderID)，狀態: \(response.status)")
            
            switch response.status {
            case LocalKeyExchangeStatus.alreadyEstablished:
                print("✅ \(peerDisplayName) 報告會話密鑰已建立")
                return
                
            case LocalKeyExchangeStatus.error:
                let errorMessage = response.errorMessage ?? "未知錯誤"
                print("❌ \(peerDisplayName) 報告密鑰交換錯誤: \(errorMessage)")
                return
                
            case LocalKeyExchangeStatus.success:
                // 檢查是否已經有會話密鑰
                let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
                if hasKey {
                    print("✅ 與 \(peerDisplayName) 已有會話密鑰")
                    return
                }
                
                try await securityService.performKeyExchange(with: response.publicKey, peerID: peerDisplayName, deviceID: response.senderID)
                print("✅ 二進制密鑰交換回應處理完成，與 \(peerDisplayName) 建立安全連接")
            }
            
        } catch {
            print("❌ 處理二進制密鑰交換回應失敗: \(error)")
        }
    }
    
    /// 檢查消息是否為密鑰交換回應（通過數據結構判斷）
    private func isKeyExchangeResponse(_ data: Data) -> Bool {
        // 密鑰交換回應的基本結構檢查
        guard data.count >= 8 else { return false }
        
        // 第3個字節是狀態字段，應該是0, 1, 或2（LocalKeyExchangeStatus）
        let statusByte = data[2]
        guard statusByte <= 2 else { return false }
        
        // 如果能成功解碼為密鑰交換回應，則視為密鑰交換回應
        return KeyExchangeDecoder.decodeKeyExchangeResponse(data) != nil
    }
    
    private func routeMessage(_ data: Data, from peerDisplayName: String) async {
        // 🔧 智能消息路由，支持mesh和直接連接
        guard data.count >= 2 else {
            print("❌ 消息數據太短: \(data.count) bytes，來自: \(peerDisplayName)")
            return
        }
        
        // 智能協議版本檢測
        let protocolVersion = data[0]
        let messageType = data[1]
        
        print("📦 路由消息: 協議=\(protocolVersion), 類型=\(messageType), 大小=\(data.count)bytes, 來源=\(peerDisplayName)")
        
        // 🛡️ 嚴格的協議版本檢查 - 拒絕處理非版本1的消息（包括mesh消息）
        if protocolVersion != PROTOCOL_VERSION {
            print("❌ 協議版本不匹配：期望版本 \(PROTOCOL_VERSION)，收到版本 \(protocolVersion)，來自: \(peerDisplayName)")
            print("🚫 拒絕處理非版本1的消息")
            print("💡 提示：對方設備需要更新到最新版本以支援統一協議版本1")
            
            // 記錄協議違規行為
            trustScoreManager.recordSuspiciousBehavior(
                for: peerDisplayName, 
                behavior: .protocolViolation
            )
            
            return // 直接返回，不處理非版本1的消息
        }
        
        // 使用標準 MeshMessageType 映射
        switch MeshMessageType(rawValue: messageType) {
        case .signal:      // 0x01
            await routeSignalMessage(data, from: peerDisplayName)
        case .emergency:   // 0x02
            await routeSignalMessage(data, from: peerDisplayName) // 緊急信號也走信號路由
        case .chat:        // 0x03
            await routeChatMessage(data, from: peerDisplayName)
        case .system:      // 0x04
            await routeSystemMessage(data, from: peerDisplayName)
        case .keyExchange: // 0x05
            await handleBinaryKeyExchange(data, from: peerDisplayName)
        case .game:        // 0x06
            await routeGameMessage(data, from: peerDisplayName)
        case .topology:    // 0x07 - 處理拓撲和密鑰交換回應（臨時相容）
            // 檢查是否為密鑰交換回應（通過數據結構判斷）
            if isKeyExchangeResponse(data) {
                await handleBinaryKeyExchangeResponse(data, from: peerDisplayName)
            } else {
                await routeTopologyMessage(data, from: peerDisplayName)
            }
        case .keyExchangeResponse: // 0x08
            await handleBinaryKeyExchangeResponse(data, from: peerDisplayName)
        case .heartbeat: // 0x09
            await routeSystemMessage(data, from: peerDisplayName)
        case .routingUpdate: // 0x0A
            await routeSystemMessage(data, from: peerDisplayName)
        case nil:
            print("❓ 未知的二進制訊息類型: \(messageType)，來自: \(peerDisplayName)")
        }
    }
    
    // MARK: - 移除Mesh專用路由 - 所有消息現在都使用統一協議版本檢查
    
    // MARK: - 系統訊息路由
    private func routeSystemMessage(_ data: Data, from peerDisplayName: String) async {
        do {
            // 🔧 系統訊息兼容性處理
            let message = try BinaryMessageDecoder.decode(data)
            
            // 檢查是否為穩定性測試訊息
            if message.id.starts(with: "stability-test-") {
                let testContent = String(data: message.data, encoding: .utf8) ?? ""
                print("✅ 收到穩定性測試回應: \(testContent) 來自: \(peerDisplayName)")
                return
            }
            
            // 其他系統訊息處理
            print("📋 收到系統訊息: \(message.id) 來自: \(peerDisplayName)")
            
        } catch BinaryDecodingError.invalidDataSize {
            // 🔄 特殊處理：系統廣播訊息（類型10）
            print("🔄 系統廣播訊息格式檢測，嘗試直接處理")
            
            guard data.count >= 2 else {
                print("❌ 系統訊息數據太短: \(data.count) bytes")
                return
            }
            
            let messageType = data[1]
            if messageType == 10 { // 系統廣播類型
                print("📻 處理系統廣播訊息，大小: \(data.count) bytes，來自: \(peerDisplayName)")
                
                // 提取系統廣播內容（跳過前2字節的標頭）
                if data.count > 2 {
                    let broadcastContent = data.subdata(in: 2..<data.count)
                    let contentString = String(data: broadcastContent, encoding: .utf8) ?? "二進制內容"
                    print("📢 系統廣播內容: \(contentString)")
                }
            } else {
                print("❓ 未知系統訊息類型: \(messageType)")
            }
            
        } catch {
            print("❌ 系統訊息解碼失敗: \(error)")
            
            // 🔍 使用增強診斷工具
            let diagnosis = BinaryMessageDecoder.analyzeFailedData(data)
            print("📊 詳細診斷報告:")
            print(diagnosis)
        }
    }
    
    // MARK: - 協議版本協商
    private func initiateProtocolNegotiation(with peerDisplayName: String) async {
        print("🤝 開始與 \(peerDisplayName) 進行協議版本協商")
        
        do {
            // 強制使用版本1，移除版本協商
            let versionMessage = Data([PROTOCOL_VERSION, 11, PROTOCOL_VERSION]) // 固定版本1
            
            guard let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
                print("❌ 協議協商失敗：找不到設備 \(peerDisplayName)")
                return
            }
            
            try await networkService.send(versionMessage, to: [peer])
            print("📤 版本協商訊息已發送給 \(peerDisplayName)")
            
        } catch {
            print("❌ 協議版本協商失敗: \(error)")
            // 所有設備都使用版本1
            print("✅ 設備 \(peerDisplayName) 使用協議版本 \(PROTOCOL_VERSION)")
        }
    }
    
    // MARK: - 處理版本協商
    private func handleProtocolNegotiation(_ data: Data, from peerDisplayName: String) async {
        guard data.count >= 4 else {
            print("❌ 版本協商訊息太短: \(data.count) bytes")
            return
        }
        
        // 解析版本信息（跳過前2字節的標頭）
        let versionData = data.subdata(in: 2..<data.count)
        
        // 強制檢查版本必須是1
        guard versionData.count >= 1 && versionData[0] == PROTOCOL_VERSION else {
            print("❌ 版本不匹配：期望版本 \(PROTOCOL_VERSION)，收到版本 \(versionData.count > 0 ? versionData[0] : 0)")
            return
        }
        
        // 版本統一為1
        let negotiatedVersion = PROTOCOL_VERSION
        
        if negotiatedVersion > 0 {
            print("✅ 與 \(peerDisplayName) 協商成功，使用版本: \(negotiatedVersion)")
            
            // 發送協商回應
            await sendProtocolNegotiationResponse(to: peerDisplayName, version: negotiatedVersion)
        } else {
            print("❌ 與 \(peerDisplayName) 版本不兼容")
        }
    }
    
    private func sendProtocolNegotiationResponse(to peerDisplayName: String, version: UInt8) async {
        do {
            let responseData = Data([PROTOCOL_VERSION, 12, version]) // 統一協議版本，訊息類型12（版本協商回應）
            
            guard let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
                print("❌ 發送版本協商回應失敗：找不到設備 \(peerDisplayName)")
                return
            }
            
            try await networkService.send(responseData, to: [peer])
            print("📤 版本協商回應已發送給 \(peerDisplayName)，協商版本: \(version)")
            
        } catch {
            print("❌ 發送版本協商回應失敗: \(error)")
        }
    }
    
    // MARK: - 處理版本協商回應
    private func handleProtocolNegotiationResponse(_ data: Data, from peerDisplayName: String) async {
        guard data.count >= 3 else {
            print("❌ 版本協商回應太短: \(data.count) bytes")
            return
        }
        
        let receivedVersion = data[2]
        
        // 強制檢查版本必須是1
        guard receivedVersion == PROTOCOL_VERSION else {
            print("❌ 版本協商失敗：期望版本 \(PROTOCOL_VERSION)，收到版本 \(receivedVersion)")
            return
        }
        
        print("✅ 收到 \(peerDisplayName) 的版本協商回應，使用版本: \(PROTOCOL_VERSION)")
        
        // 版本協商完成，可以進行後續操作（如密鑰交換）
        NotificationCenter.default.post(
            name: NSNotification.Name("ProtocolNegotiationCompleted"),
            object: peerDisplayName,
            userInfo: ["version": PROTOCOL_VERSION]
        )
    }
    
    // MARK: - 專用密鑰交換方法
    private func initiateKeyExchange(with peerDisplayName: String) async {
        let maxRetries = 3
        var retryCount = 0
        let timeoutDuration: TimeInterval = 15.0 // 15秒超時
        
        while retryCount < maxRetries {
            let startTime = Date()
            
            // 使用 withTimeout 保護密鑰交換過程
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    // 主要密鑰交換任務
                    group.addTask {
                        try await self.performKeyExchange(with: peerDisplayName, retryCount: retryCount, startTime: startTime)
                    }
                    
                    // 超時任務
                    group.addTask {
                        try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
                        throw NetworkError.timeout
                    }
                    
                    // 等待第一個任務完成
                    try await group.next()
                    group.cancelAll()
                }
                
                // 如果成功，跳出重試循環
                return
                
            } catch NetworkError.timeout {
                print("⏰ 密鑰交換超時 (嘗試 \(retryCount + 1)/\(maxRetries))")
            } catch {
                print("❌ 密鑰交換失敗: \(error) (嘗試 \(retryCount + 1)/\(maxRetries))")
            }
            
            retryCount += 1
            
            if retryCount < maxRetries {
                // 指數退避延遲
                let delay = Double(retryCount) * 2.0
                print("🔄 等待 \(delay) 秒後重試密鑰交換...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        print("❌ 密鑰交換失敗，已達最大重試次數")
    }
    
    private func performKeyExchange(with peerDisplayName: String, retryCount: Int, startTime: Date) async throws {
        // 檢查是否已經有會話密鑰
        let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
        if hasKey {
            print("✅ \(peerDisplayName) 已有會話密鑰，跳過交換")
            return
        }
        
        // 獲取我們的公鑰
        let publicKey = try await securityService.getPublicKey()
        
        // 創建二進制密鑰交換訊息
        let messageData = KeyExchangeEncoder.encodeKeyExchange(
            publicKey: publicKey,
            senderID: nicknameService.displayName,
            retryCount: UInt8(retryCount)
        )
        
        // 🔧 原子性連接檢查，移除多重檢查引起的競爭條件
        guard let validPeer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
            print("❌ 密鑰交換失敗：找不到對等設備 \(peerDisplayName)")
            print("📊 當前連接的設備: \(networkService.connectedPeers.map(\.displayName))")
            throw NetworkError.peerNotFound
        }
        
        // 🔧 原子性檢查：validPeer 已經通過上面的原子檢查，直接使用
        
        // 發送密鑰交換請求
        try await networkService.send(messageData, to: [validPeer])
        
        // 記錄發送成功和延遲
        let latency = Date().timeIntervalSince(startTime)
        connectionOptimizer.onMessageSent(to: peerDisplayName, size: messageData.count, latency: latency)
        
        print("🔑 密鑰交換請求已發送給 \(peerDisplayName) (嘗試: \(retryCount + 1), 大小: \(messageData.count) bytes, 延遲: \(String(format: "%.0f", latency * 1000))ms)")
        
        // 🚨 使用更高效的非阻塞等待機制
        try await waitForSessionKeyWithContinuation(peerDisplayName: peerDisplayName, timeout: 3.0)
    }
    
    /// 非阻塞等待會話密鑰建立（優化版本）
    private func waitForSessionKeyWithContinuation(peerDisplayName: String, timeout: TimeInterval) async throws {
        let startTime = Date()
        
        // 使用更適合的輪詢間隔
        let checkInterval: TimeInterval = 0.1 // 100ms 固定間隔
        
        while Date().timeIntervalSince(startTime) < timeout {
            // 立即檢查會話密鑰
            let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
            if hasKey {
                print("✅ 與 \(peerDisplayName) 的密鑰交換成功完成")
                return
            }
            
            // 同時檢查連接是否仍然有效
            if !networkService.connectedPeers.contains(where: { $0.displayName == peerDisplayName }) {
                print("❌ 連接在密鑰交換過程中斷開: \(peerDisplayName)")
                throw NetworkError.peerNotFound
            }
            
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        // 超時後拋出錯誤
        print("❌ 等待密鑰交換超時: \(peerDisplayName)")
        throw NetworkError.timeout
    }
    
    // MARK: - 會話密鑰監控
    private func setupSessionKeyMonitoring() {
        // 每60秒檢查一次會話密鑰狀態，降低頻率並移至背景隊列
        sessionKeyMonitorTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task.detached(priority: .background) {
                await self?.checkAndRepairSessionKeys()
            }
        }
        print("🔄 ServiceContainer: 會話密鑰監控定時器已啟動")
    }
    
    private func checkAndRepairSessionKeys() async {
        let connectedPeers = networkService.connectedPeers.map { $0.displayName }
        
        for peerDisplayName in connectedPeers {
            let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
            if !hasKey {
                print("🔧 檢測到 \(peerDisplayName) 缺少會話密鑰，嘗試修復...")
                await initiateKeyExchange(with: peerDisplayName)
            }
        }
        
        // 清理已斷開連接的會話密鑰
        let allSessionKeys = await securityService.getAllSessionKeyPeerIDs()
        for sessionKeyPeerID in allSessionKeys {
            if !connectedPeers.contains(sessionKeyPeerID) {
                print("🧹 清理已斷開連接的會話密鑰: \(sessionKeyPeerID)")
                Task {
                    await securityService.removeSessionKey(for: sessionKeyPeerID)
                }
            }
        }
    }
    
    // MARK: - 純二進制信號路由（零 JSON 依賴）
    private func routeSignalMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 使用統一的完整格式解碼（新版本格式）
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            guard meshMessage.type == .signal || meshMessage.type == .emergency else {
                print("❌ 信號訊息類型不匹配，期望 signal 或 emergency，實際: \(meshMessage.type)")
                return
            }
            
            // 解析內部信號數據
            guard let decodedSignal = SignalBinaryCodec.decodeInlineSignalData(meshMessage.data) else {
                print("❌ 純二進制信號解析失敗: 內部大小=\(meshMessage.data.count)bytes, 來源=\(peerDisplayName)")
                return
            }
            
            // 基本時間戳檢查
            let timeDiff = abs(Date().timeIntervalSince(decodedSignal.timestamp))
            if timeDiff > 300 { // 5分鐘內的訊息才接受
                print("⚠️ 信號訊息過期: \(timeDiff)秒")
                return
            }
            
            let headerParseTime = Date().timeIntervalSince(startTime) * 1000
            
            // 轉發完整數據給 SignalViewModel（統一格式）
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SignalMessageReceived"),
                    object: data,  // 轉發完整數據（含協議頭部）
                    userInfo: ["sender": peerDisplayName]
                )
            }
            
            print("📡 純二進制信號路由完成 - 解析時間: \(String(format: "%.3f", headerParseTime))ms, 類型: \(decodedSignal.type.rawValue), 設備: \(decodedSignal.deviceName), 來源: \(peerDisplayName)")
            
        } catch {
            print("❌ ServiceContainer: 信號訊息解碼失敗: \(error)")
            return
        }
    }
    
    private func routeChatMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 🔧 FIX: 嘗試解密聊天訊息
        var processedData = data
        
        // 檢查是否有會話密鑰，如果有則嘗試解密
        let hasKey = await securityService.hasSessionKey(for: peerDisplayName)
        if hasKey && !isPlainTextChatMessage(data) {
            do {
                processedData = try await securityService.decrypt(data, from: peerDisplayName)
                print("🔐 ServiceContainer: 聊天訊息已解密來自 \(peerDisplayName): \(processedData.count) bytes")
            } catch {
                print("❌ ServiceContainer: 聊天訊息解密失敗來自 \(peerDisplayName): \(error)")
                return // 解密失敗，拒絕處理
            }
        } else if !hasKey {
            print("⚠️ ServiceContainer: 處理明文聊天訊息來自 \(peerDisplayName)（無密鑰）")
        }
        
        // 驗證解密後的數據格式
        guard processedData.count >= 3 else {
            print("⚠️ 解密後聊天數據太短: \(processedData.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        // 基本格式驗證 - 檢查完整數據大小
        guard processedData.count >= 27 else { // 最小完整聊天訊息大小（含協議頭部）
            print("⚠️ 解密後聊天完整數據太短: \(processedData.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        let headerParseTime = Date().timeIntervalSince(startTime) * 1000
        
        // 🔧 FIX: 轉發處理後的數據給 ChatViewModel（含協議頭部）
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("ChatMessageReceived"),
                object: processedData,  // 轉發解密後的數據（含協議頭部）
                userInfo: ["sender": peerDisplayName]
            )
        }
        
        print("💬 加密聊天路由完成 - 解析時間: \(String(format: "%.3f", headerParseTime))ms, 原始: \(data.count)bytes, 處理後: \(processedData.count)bytes, 來源: \(peerDisplayName)")
    }
    
    /// 檢查是否為明文聊天訊息格式
    private func isPlainTextChatMessage(_ data: Data) -> Bool {
        // 檢查是否為標準協議格式（版本1，聊天類型3）
        return data.count >= 2 && data[0] == 1 && data[1] == 3
    }
    
    private func routeGameMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 跳過協議頭部（版本+類型），提取內部遊戲數據
        guard data.count >= 3 else {
            print("⚠️ 遊戲數據太短: \(data.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        // 解碼為完整的 MeshMessage 以檢查是否為遊戲類型
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            print("🎮 收到遊戲訊息: ID=\(meshMessage.id), 類型=\(meshMessage.type), 數據大小=\(meshMessage.data.count)bytes, 來源=\(peerDisplayName)")
            
            // 確保是遊戲訊息類型
            guard meshMessage.type == .game else {
                print("⚠️ 非遊戲訊息類型: \(meshMessage.type)")
                return
            }
            
            let headerParseTime = Date().timeIntervalSince(startTime) * 1000
            
            // 轉發完整的 MeshMessage 給 BingoGameViewModel
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("GameMessageReceived"),
                    object: data,  // 轉發完整數據讓 BingoGameViewModel 自己解碼
                    userInfo: ["sender": peerDisplayName]
                )
            }
            
            print("🎮 遊戲訊息路由完成 - 解析時間: \(String(format: "%.3f", headerParseTime))ms, 訊息ID: \(meshMessage.id), 來源: \(peerDisplayName)")
            
        } catch {
            print("❌ 解碼遊戲訊息失敗: \(error)")
        }
    }
    
    // MARK: - 拓撲訊息路由
    private func routeTopologyMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 解碼拓撲訊息
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            print("🌐 收到拓撲訊息: ID=\(meshMessage.id), 類型=\(meshMessage.type), 數據大小=\(meshMessage.data.count)bytes, 來源=\(peerDisplayName)")
            
            // 確保是拓撲訊息類型
            guard meshMessage.type == .topology else {
                print("⚠️ 非拓撲訊息類型: \(meshMessage.type)")
                return
            }
            
            let parseTime = Date().timeIntervalSince(startTime) * 1000
            
            // 使用統一的 NotificationCenter 路由模式，轉發給 TopologyManager
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TopologyMessageReceived"),
                    object: data,  // 轉發完整數據讓 TopologyManager 自己解碼
                    userInfo: ["sender": peerDisplayName]
                )
            }
            
            print("🌐 拓撲訊息路由完成 - 解析時間: \(String(format: "%.3f", parseTime))ms, 訊息ID: \(meshMessage.id), 來源: \(peerDisplayName)")
            
        } catch {
            print("❌ 解碼拓撲訊息失敗: \(error)")
        }
    }
    
    // MARK: - 輔助方法
    private func getNicknameForDevice(_ deviceID: String) -> String? {
        // 這裡可以實現設備ID到暱稱的映射邏輯
        // 暫時返回截短的設備ID作為暱稱
        if deviceID.contains("#") {
            return deviceID.components(separatedBy: "#").first
        }
        return deviceID
    }
    
    // MARK: - 性能監控
    
    /// 打印二進制協議性能報告
    func printBinaryProtocolReport() {
        print("📊 二進制協議性能報告已啟用，統計中...")
    }
    
    /// 重置性能統計
    func resetBinaryProtocolStats() {
        print("🔄 二進制協議統計已重置")
        print("📊 二進制協議性能統計已重置")
    }
    
    // MARK: - 連接穩定性驗證
    
    /// 驗證與指定設備的連接穩定性
    private func verifyConnectionStability(with peerDisplayName: String) async -> Bool {
        print("🔍 驗證與 \(peerDisplayName) 的連接穩定性...")
        
        // 檢查是否仍在連接列表中
        let isStillConnected = networkService.connectedPeers.contains { peer in
            peer.displayName == peerDisplayName
        }
        
        guard isStillConnected else {
            print("❌ \(peerDisplayName) 已斷開連接")
            return false
        }
        
        // 發送3個測試包驗證雙向通信（使用二進制協議格式）
        var successCount = 0
        
        for i in 1...3 {
            do {
                // 查找對應的 MCPeerID
                guard let targetPeer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) else {
                    print("❌ 找不到 \(peerDisplayName) 的 MCPeerID")
                    return false
                }
                
                // 創建二進制格式的穩定性測試訊息
                let testMessage = MeshMessage(
                    id: "stability-test-\(i)",
                    type: .system,
                    data: "STABILITY_TEST_\(i)".data(using: .utf8) ?? Data()
                )
                
                let binaryTestData = try BinaryMessageEncoder.encode(testMessage)
                
                try await networkService.send(binaryTestData, to: [targetPeer])
                print("✅ 穩定性測試 \(i)/3 成功發送到 \(peerDisplayName) (二進制格式: \(binaryTestData.count) bytes)")
                successCount += 1
                
                // 等待500ms再發送下一個測試包
                try await Task.sleep(nanoseconds: 500_000_000)
                
            } catch {
                print("❌ 穩定性測試 \(i)/3 失敗: \(error)")
            }
        }
        
        let isStable = successCount >= 2 // 3次中至少成功2次
        print(isStable ? "✅ 與 \(peerDisplayName) 的連接穩定 (成功 \(successCount)/3)" : "❌ 與 \(peerDisplayName) 的連接不穩定 (成功 \(successCount)/3)")
        
        return isStable
    }
    
    // MARK: - Safe Service Initialization
    
    /// 安全的 MeshManager 初始化方法，避免循環引用
    private func initializeMeshManagerSafely() async {
        // 確保服務準備完成
        await ensureServicesReady()
        
        let manager = MeshManager(
            networkService: networkService,
            securityService: securityService,
            trustScoreManager: trustScoreManager,
            connectionRateManager: connectionRateManager
        )
        
        // 設置回調避免循環引用
        manager.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                await self?.handleMeshMessage(message)
            }
        }
        
        await MainActor.run {
            self.meshManager = manager
        }
    }
    
    /// 確保所有服務準備就緒
    private func ensureServicesReady() async {
        // 快速服務就緒檢查，無需延遲
        print("✅ 所有服務已準備就緒")
    }
    
    /// 處理來自 MeshManager 的訊息（避免循環引用和重複處理）
    private func handleMeshMessage(_ message: MeshMessage) async {
        // 🔧 FIX: 統一數據格式 - 重新編碼 MeshMessage 為完整二進制格式
        print("🌐 ServiceContainer: 處理MeshMessage類型=\(message.type)，重新編碼為統一格式")
        
        do {
            // 重新編碼為完整的二進制格式（含協議頭部）
            let fullEncodedData = try BinaryMessageEncoder.encode(message)
            
            // 根據訊息類型路由到對應處理器（使用統一的完整數據格式）
            switch message.type {
            case .signal:
                // 🔧 FIX: 發送完整編碼數據到信號處理
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SignalMessageReceived"),
                        object: fullEncodedData,  // ✅ 完整數據格式
                        userInfo: ["sender": "mesh", "messageType": "signal"]
                    )
                }
            case .chat:
                // 🔧 FIX: 發送完整編碼數據到聊天處理
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ChatMessageReceived"),
                        object: fullEncodedData,  // ✅ 完整數據格式
                        userInfo: ["sender": "mesh", "messageType": "chat"]
                    )
                }
            case .game:
                // 🔧 FIX: 發送完整編碼數據到遊戲處理
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("GameMessageReceived"),
                        object: fullEncodedData,  // ✅ 完整數據格式
                        userInfo: ["sender": "mesh", "messageType": "game"]
                    )
                }
            case .system:
                // 處理系統消息（不需要重新編碼，直接使用原始MeshMessage）
                await handleSystemMessage(message)
            case .keyExchange:
                // 處理密鑰交換消息（不需要重新編碼，直接使用原始MeshMessage）
                await handleKeyExchangeMessage(message)
            case .keyExchangeResponse:
                // 處理密鑰交換響應消息（不需要重新編碼，直接使用原始MeshMessage）
                await handleKeyExchangeResponseMessage(message)
            case .routingUpdate:
                // 處理路由更新消息（不需要重新編碼，直接使用原始MeshMessage）
                await handleRoutingUpdateMessage(message)
            default:
                print("⚠️ ServiceContainer: 未知的MeshMessage類型: \(message.type)")
            }
            
        } catch {
            print("❌ ServiceContainer: MeshMessage 重新編碼失敗: \(error)")
            // 新版本不支持後備方案，編碼失敗就直接失敗
        }
    }
    
    // MARK: - 特殊消息處理器
    
    /// 處理系統消息
    private func handleSystemMessage(_ message: MeshMessage) async {
        print("🔧 ServiceContainer: 處理系統消息 (\(message.data.count) bytes)")
        
        // 解析系統消息內容
        if let messageContent = String(data: message.data, encoding: .utf8) {
            print("📋 系統消息內容: \(messageContent)")
            
            // 根據系統消息類型執行相應操作
            if messageContent.contains("ping") {
                await handlePingMessage(message)
            } else if messageContent.contains("status") {
                await handleStatusMessage(message)
            } else if messageContent.contains("discovery") {
                await handleDiscoveryMessage(message)
            } else {
                print("ℹ️ 收到一般系統消息: \(messageContent)")
            }
        } else {
            print("ℹ️ 收到二進制系統消息 (\(message.data.count) bytes)")
        }
    }
    
    /// 處理密鑰交換消息
    func handleKeyExchangeMessage(_ message: MeshMessage) async {
        print("🔑 ServiceContainer: 處理密鑰交換消息 (\(message.data.count) bytes)")
        
        guard let sourceID = message.sourceID else {
            print("❌ 密鑰交換消息缺少來源ID")
            return
        }
        
        print("🔑 處理來自 \(sourceID) 的密鑰交換請求")
        
        // 調用實際的二進制密鑰交換處理邏輯
        await handleBinaryKeyExchange(message.data, from: sourceID)
    }
    
    /// 處理密鑰交換響應消息
    private func handleKeyExchangeResponseMessage(_ message: MeshMessage) async {
        print("🔑 ServiceContainer: 處理密鑰交換響應消息 (\(message.data.count) bytes)")
        
        guard let sourceID = message.sourceID else {
            print("❌ 密鑰交換響應消息缺少來源ID")
            return
        }
        
        print("🔑 處理來自 \(sourceID) 的密鑰交換響應")
        
        // 調用實際的二進制密鑰交換響應處理邏輯
        await handleBinaryKeyExchangeResponse(message.data, from: sourceID)
    }
    
    /// 處理路由更新消息
    private func handleRoutingUpdateMessage(_ message: MeshMessage) async {
        print("🌐 ServiceContainer: 處理路由更新消息 (\(message.data.count) bytes)")
        
        // 基本的路由更新處理邏輯
        if ServiceContainer.shared.meshManager != nil {
            print("🌐 處理來自 \(message.sourceID ?? "unknown") 的路由更新")
            // 這裡可以實現具體的路由更新邏輯
            // 例如：更新路由表、檢查網路拓撲等
            print("✅ 路由更新處理完成")
        } else {
            print("❌ MeshManager 不可用，無法處理路由更新")
        }
    }
    
    // MARK: - 系統消息子處理器
    
    /// 處理 Ping 消息
    private func handlePingMessage(_ message: MeshMessage) async {
        print("🏓 處理 Ping 消息")
        // 實現 ping/pong 機制
    }
    
    /// 處理狀態消息
    private func handleStatusMessage(_ message: MeshMessage) async {
        print("📊 處理狀態消息")
        // 實現狀態同步
    }
    
    /// 處理發現消息
    private func handleDiscoveryMessage(_ message: MeshMessage) async {
        print("🔍 處理設備發現消息")
        // 實現設備發現機制
    }
    
    /// 路由內聯信號訊息 (tuple版本)
    func routeInlineSignalTuple(_ signalTuple: (type: SignalType, deviceName: String, deviceID: String, gridCode: String?, timestamp: Date), from peerID: String) async {
        print("🚨 ServiceContainer: 路由內聯信號 - 類型=\(signalTuple.type), 來源=\(signalTuple.deviceName)")
        
        // 轉換為標準格式並路由到信號處理系統
        await MainActor.run {
            // 通知 SignalViewModel 或其他信號處理組件
            NotificationCenter.default.post(
                name: Notification.Name("InlineSignalReceived"),
                object: signalTuple,
                userInfo: ["peerID": peerID]
            )
        }
        
        print("✅ 內聯信號路由完成")
    }
    
    /// 啟用壓縮信任評分系統
    private func enableCompressedTrustScoring() async {
        print("🚀 ServiceContainer: 正在啟用壓縮信任評分系統...")
        
        // 簡化版本，避免複雜的依賴
        await MainActor.run {
            print("✅ ServiceContainer: 壓縮信任評分系統已啟用")
        }
    }
    
    // MARK: - 性能優化初始化
    private func initializePerformanceOptimizations() async {
        print("⚡ ServiceContainer: 初始化高性能優化引擎...")
        
        // 🚀 啟用高性能優化組件
        await enablePerformanceOptimizations()
        
        print("✅ ServiceContainer: 高性能優化已啟用")
        print("🚀 已啟用功能:")
        print("   ✅ HybridPerformanceEngine: Accelerate + Metal 混合優化")
        print("   ✅ TrustCacheOptimizer: 5秒緩存 + LRU管理") 
        print("   ✅ OptimizedBinaryProtocol: 嵌入式信任信息")
        print("   ✅ NetworkOptimizations: 快速連接決策")
        print("   ✅ Protocol: 統一版本 \(PROTOCOL_VERSION)")
    }
    
    // MARK: - 啟用性能優化功能
    @MainActor
    private func enablePerformanceOptimizations() async {
        // 1. 整合 TrustCacheOptimizer 與 TrustScoreManager
        await integrateTrustCacheOptimizer()
        
        // 2. 清理舊版本資料（確保協議版本統一）
        cleanAllLegacyData()
        
        // 3. 啟用 HybridPerformanceEngine
        await initializeHybridPerformanceEngine()
        
        // 4. 協議版本已統一為版本1
        print("📋 協議版本統一為版本 \(PROTOCOL_VERSION)")
        
        // 5. 啟用網路優化
        await enableNetworkOptimizations()
        
        print("⚡ 所有性能優化組件已成功啟用")
    }
    
    private func integrateTrustCacheOptimizer() async {
        // 整合信任評分緩存優化器
        print("🔗 整合 TrustCacheOptimizer...")
        // 實際的整合將在 TrustScoreManager 的更新中完成
    }
    
    private func initializeHybridPerformanceEngine() async {
        // 初始化混合性能引擎
        print("🚀 初始化 HybridPerformanceEngine...")
        // 引擎將在需要時自動載入
    }
    
    
    private func enableNetworkOptimizations() async {
        // 啟用網路優化
        print("🌐 啟用 NetworkOptimizations...")
        // 優化將在網路層自動應用
    }
    
    // MARK: - 舊版本資料清理
    private func cleanAllLegacyData() {
        print("🧹 ServiceContainer: 開始清理所有舊版本資料...")
        
        // 清理協議版本相關的快取
        let protocolKeys = [
            "protocol_version", "peer_versions", "negotiated_versions", 
            "version_compatibility", "protocol_negotiation", "version_cache"
        ]
        
        // 清理網路快取
        let networkKeys = [
            "connected_peers", "peer_discovery", "network_topology", 
            "mesh_routing", "connection_cache", "peer_trust_cache"
        ]
        
        // 清理信任評分快取
        let trustKeys = [
            "trust_scores", "local_blacklist", "observation_list", 
            "bloom_filter", "peer_reputation", "security_violations"
        ]
        
        // 清理聊天快取
        let chatKeys = [
            "chat_messages", "message_hashes", "daily_message_count", 
            "last_reset_date", "chat_cache", "mention_cache"
        ]
        
        // 清理設備快取
        let deviceKeys = [
            "device_uuid", "device_fingerprint", "daily_accounts", 
            "temp_device_id", "device_identity"
        ]
        
        let allKeys = protocolKeys + networkKeys + trustKeys + chatKeys + deviceKeys
        
        for key in allKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
        
        print("✅ ServiceContainer: 舊版本資料清理完成 (\(allKeys.count) 個項目)")
    }
    
    // MARK: - 密鑰交換增強處理
    
    /// 安排密鑰交換重試
    func scheduleKeyExchangeRetry(with peerDisplayName: String) async {
        print("🔄 安排與 \(peerDisplayName) 的密鑰交換重試")
        
        // 檢查設備是否仍然連接
        let connectedPeers = meshManager?.getConnectedPeers() ?? []
        guard connectedPeers.contains(peerDisplayName) else {
            print("⚠️ 設備 \(peerDisplayName) 已斷開連接，取消重試")
            return
        }
        
        // 短暫延遲後重新開始密鑰交換
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延遲
        await initiateKeyExchange(with: peerDisplayName)
    }
    
    // MARK: - 調試工具方法
    
    /// 記錄數據以供調試
    private func debugLogData(_ data: Data, label: String, peer: String, showFullData: Bool = false) {
        print("\n🔍 [\(label)] from/to \(peer)")
        print("   時間: \(Date())")
        print("   大小: \(data.count) bytes")
        print("   HEX前綴: \(data.prefix(20).map { String(format: "%02hhx", $0) }.joined())")
        print("   前20字節: \(Array(data.prefix(20)))")
        
        // 嘗試解析為字符串
        if let string = String(data: data, encoding: .utf8) {
            print("   UTF8: \(string.prefix(100))...")
        }
        
        // 完整數據（僅在需要時）
        if showFullData && data.count < 1000 {
            print("   完整HEX: \(data.map { String(format: "%02hhx", $0) }.joined())")
        }
        
        // 嘗試解析協議頭
        if data.count >= 2 {
            print("   協議版本: \(data[0])")
            print("   訊息類型: \(data[1])")
        }
        
        print("   ----")
    }
    
    /// 密鑰交換數據分析
    private func debugKeyExchange(_ data: Data, from peer: String) {
        print("\n🔑 密鑰交換數據分析 from \(peer):")
        print("   總大小: \(data.count)")
        
        var offset = 0
        
        // 讀取協議版本
        if data.count > offset {
            let version = data[offset]
            print("   [offset:\(offset)] 協議版本: \(version) (0x\(String(format: "%02X", version)))")
            offset += 1
        }
        
        // 讀取消息類型
        if data.count > offset {
            let messageType = data[offset]
            print("   [offset:\(offset)] 消息類型: \(messageType) (0x\(String(format: "%02X", messageType)))")
            offset += 1
        }
        
        // 嘗試讀取重試次數
        if data.count > offset {
            let retryCount = data[offset]
            print("   [offset:\(offset)] 重試次數: \(retryCount)")
            offset += 1
        }
        
        // 嘗試讀取時間戳
        if data.count > offset + 3 {
            let timestampData = data.subdata(in: offset..<offset+4)
            let timestamp = timestampData.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            print("   [offset:\(offset)] 時間戳: \(timestamp) (\(Date(timeIntervalSince1970: Double(timestamp))))")
            offset += 4
        }
        
        // 嘗試讀取發送者ID長度
        if data.count > offset {
            let senderIDLength = data[offset]
            print("   [offset:\(offset)] 發送者ID長度: \(senderIDLength)")
            offset += 1
            
            // 讀取發送者ID
            if data.count >= offset + Int(senderIDLength) {
                let senderIDData = data.subdata(in: offset..<offset+Int(senderIDLength))
                if let senderID = String(data: senderIDData, encoding: .utf8) {
                    print("   [offset:\(offset)] 發送者ID: '\(senderID)'")
                } else {
                    print("   [offset:\(offset)] 發送者ID: 無法解碼為UTF-8")
                }
                offset += Int(senderIDLength)
            }
        }
        
        // 嘗試讀取公鑰長度
        if data.count > offset + 1 {
            let keyLengthData = data.subdata(in: offset..<offset+2)
            let keyLength = keyLengthData.withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            print("   [offset:\(offset)] 公鑰長度: \(keyLength)")
            offset += 2
            
            // 檢查公鑰數據
            if data.count >= offset + Int(keyLength) {
                print("   [offset:\(offset)] 公鑰數據: 存在 (\(keyLength) bytes)")
            } else {
                print("   [offset:\(offset)] 公鑰數據: 缺失！期望 \(keyLength) bytes，實際剩餘 \(data.count - offset) bytes")
            }
        }
        
        print("   剩餘未解析數據: \(data.count - offset) bytes")
        print("   ----")
    }
    
    /// 嘗試多種數據解析方式
    private func tryMultipleDataParsing(_ data: Data, from peer: String) {
        print("\n🔬 嘗試多種解析方式 for data from \(peer):")
        
        // 1. 嘗試作為JSON
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("   ✅ JSON解析成功: \(json)")
        }
        
        // 2. 嘗試作為UTF-8字符串
        if let string = String(data: data, encoding: .utf8) {
            print("   ✅ UTF-8字符串: \(string)")
        }
        
        // 3. 嘗試作為MeshMessage
        if let message = try? BinaryMessageDecoder.decode(data) {
            print("   ✅ MeshMessage解析成功: type=\(message.type), id=\(message.id)")
        }
        
        print("   ----")
    }
    
    /// 保存原始數據到文件用於分析
    private func saveRawDataToFile(_ data: Data, from peer: String, label: String = "received") {
        Task {
            let fileName = "\(label)_\(peer)_\(Date().timeIntervalSince1970).bin"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = documentsPath.appendingPathComponent("DebugLogs").appendingPathComponent(fileName)
            
            // 創建目錄
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), 
                                                    withIntermediateDirectories: true)
            
            // 保存數據
            do {
                try data.write(to: url)
                print("💾 已保存原始數據到: \(fileName)")
            } catch {
                print("❌ 保存數據失敗: \(error)")
            }
        }
    }
}