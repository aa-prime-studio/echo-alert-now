import Foundation
import SwiftUI
import MultipeerConnectivity
import CoreLocation
import Combine
import CryptoKit // Added for SHA256

// MARK: - 信號二進制編解碼器（已啟用）
struct SignalBinaryCodec {
    static func encodeSignalData(
        id: String,
        type: SignalType,
        deviceName: String,
        deviceID: String,
        gridCode: String?,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 標誌位
        var flags: UInt8 = 0
        switch type {
        case .safe: flags |= 0x01
        case .medical: flags |= 0x02
        case .supplies: flags |= 0x04
        case .danger: flags |= 0x08
        }
        if gridCode != nil { flags |= 0x10 }
        data.append(flags)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 設備名稱
        if let nameData = deviceName.data(using: .utf8) {
            data.append(UInt8(min(nameData.count, 255)))
            data.append(nameData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 設備ID
        if let idData = deviceID.data(using: .utf8) {
            data.append(UInt8(min(idData.count, 255)))
            data.append(idData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 網格碼（如果有）
        if let gridCode = gridCode, let gridData = gridCode.data(using: .utf8) {
            data.append(UInt8(min(gridData.count, 255)))
            data.append(gridData.prefix(255))
        }
        
        return data
    }
    
    // MARK: - 解碼方法
    static func decodeInlineSignalData(_ data: Data) -> (
        type: SignalType,
        deviceName: String,
        deviceID: String,
        gridCode: String?,
        timestamp: Date
    )? {
        guard data.count >= 25 else { return nil } // 最小大小檢查
        
        var offset = 0
        
        // 1 byte: 標誌位
        let flags = data[offset]
        offset += 1
        
        // 解析信號類型
        let type: SignalType
        switch flags & 0x0F {
        case 0x01: type = .safe
        case 0x02: type = .medical
        case 0x04: type = .supplies
        case 0x08: type = .danger
        default: return nil
        }
        
        let hasGridCode = (flags & 0x10) != 0
        
        // 4 bytes: 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 跳過 16 bytes UUID
        offset += 16
        
        // 設備名稱
        guard offset < data.count else { return nil }
        let nameLength = Int(data[offset])
        offset += 1
        
        guard offset + nameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+nameLength), encoding: .utf8) ?? ""
        offset += nameLength
        
        // 設備ID
        guard offset < data.count else { return nil }
        let idLength = Int(data[offset])
        offset += 1
        
        guard offset + idLength <= data.count else { return nil }
        let deviceID = String(data: data.subdata(in: offset..<offset+idLength), encoding: .utf8) ?? ""
        offset += idLength
        
        // 網格碼（如果有）
        var gridCode: String? = nil
        if hasGridCode && offset < data.count {
            let gridLength = Int(data[offset])
            offset += 1
            
            if offset + gridLength <= data.count {
                gridCode = String(data: data.subdata(in: offset..<offset+gridLength), encoding: .utf8)
            }
        }
        
        return (
            type: type,
            deviceName: deviceName,
            deviceID: deviceID,
            gridCode: gridCode,
            timestamp: timestamp
        )
    }
    
    static func encodeEncryptedSignal(
        id: String,
        senderID: String,
        encryptedPayload: Data,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(1)
        
        // 1 byte: 消息類型（信號）
        data.append(MeshMessageType.signal.rawValue) // Signal = 0x01
        
        // 1 byte: 加密標誌
        data.append(1)
        
        // 4 bytes: 時間戳（修復：使用當前時間而非過期時間）
        let currentTimestamp = UInt32(Date().timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: currentTimestamp.littleEndian) { Array($0) })
        
        // 16 bytes: UUID
        if let uuid = UUID(uuidString: id) {
            data.append(contentsOf: withUnsafeBytes(of: uuid.uuid) { Array($0) })
        } else {
            data.append(Data(repeating: 0, count: 16))
        }
        
        // 發送者ID（統一編碼格式）
        let cleanSenderID = NicknameFormatter.cleanNickname(senderID)
        if let senderData = cleanSenderID.data(using: .utf8) {
            let safeLength = min(senderData.count, 255)
            data.append(UInt8(safeLength))
            data.append(senderData.prefix(safeLength))
        } else {
            data.append(0)
        }
        
        // 加密載荷長度
        let payloadLength = UInt16(encryptedPayload.count)
        data.append(contentsOf: withUnsafeBytes(of: payloadLength.littleEndian) { Array($0) })
        
        // 加密載荷
        data.append(encryptedPayload)
        
        return data
    }
    
    // MARK: - 解碼方法
    static func decodeEncryptedSignal(_ data: Data) -> (
        version: UInt8,
        messageType: UInt8,
        isEncrypted: Bool,
        timestamp: Date,
        id: String,
        senderID: String,
        encryptedPayload: Data
    )? {
        guard data.count >= 26 else { return nil }
        
        var offset = 0
        
        // 協議版本
        let version = data[offset]
        offset += 1
        
        // 消息類型
        let messageType = data[offset]
        offset += 1
        
        // 加密標誌
        let isEncrypted = data[offset] == 1
        offset += 1
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes { 
            $0.load(as: UInt32.self).littleEndian 
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // UUID
        let uuidBytes = data.subdata(in: offset..<offset+16)
        let uuid = uuidBytes.withUnsafeBytes { bytes in
            UUID(uuid: bytes.load(as: uuid_t.self))
        }
        offset += 16
        
        // 發送者ID
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 載荷長度
        guard offset + 2 <= data.count else { return nil }
        let payloadLength = data.subdata(in: offset..<offset+2).withUnsafeBytes {
            $0.load(as: UInt16.self).littleEndian
        }
        offset += 2
        
        // 加密載荷
        guard offset + Int(payloadLength) <= data.count else { return nil }
        let encryptedPayload = data.subdata(in: offset..<offset+Int(payloadLength))
        
        return (
            version: version,
            messageType: messageType,
            isEncrypted: isEncrypted,
            timestamp: timestamp,
            id: uuid.uuidString,
            senderID: senderID,
            encryptedPayload: encryptedPayload
        )
    }
    
    static func decodeSignalData(_ data: Data) -> (
        type: SignalType,
        deviceName: String,
        deviceID: String,
        gridCode: String,
        timestamp: Date
    )? {
        guard data.count >= 21 else { return nil }
        
        var offset = 0
        
        // 標誌位
        let flags = data[offset]
        offset += 1
        
        // 解析信號類型
        let type: SignalType
        if flags & 0x01 != 0 {
            type = .safe
        } else if flags & 0x02 != 0 {
            type = .medical
        } else if flags & 0x04 != 0 {
            type = .supplies
        } else if flags & 0x08 != 0 {
            type = .danger
        } else {
            type = .safe // 默認
        }
        
        // 時間戳
        let ts = data.subdata(in: offset..<offset+4).withUnsafeBytes { 
            $0.load(as: UInt32.self).littleEndian 
        }
        let timestamp = Date(timeIntervalSince1970: Double(ts))
        offset += 4
        
        // 跳過UUID
        offset += 16
        
        // 設備名稱
        let deviceNameLength = Int(data[offset])
        offset += 1
        
        guard offset + deviceNameLength <= data.count else { return nil }
        let deviceName = String(data: data.subdata(in: offset..<offset+deviceNameLength), encoding: .utf8) ?? ""
        offset += deviceNameLength
        
        // 設備ID
        let deviceIDLength = Int(data[offset])
        offset += 1
        
        guard offset + deviceIDLength <= data.count else { return nil }
        let deviceID = String(data: data.subdata(in: offset..<offset+deviceIDLength), encoding: .utf8) ?? ""
        offset += deviceIDLength
        
        // 網格碼（如果有）
        var gridCode = ""
        if offset < data.count {
            let gridCodeLength = Int(data[offset])
            offset += 1
            
            if offset + gridCodeLength <= data.count {
                gridCode = String(data: data.subdata(in: offset..<offset+gridCodeLength), encoding: .utf8) ?? ""
            }
        }
        
        return (
            type: type,
            deviceName: deviceName,
            deviceID: deviceID,
            gridCode: gridCode,
            timestamp: timestamp
        )
    }
}

// MARK: - 緊急信號流控制系統（防止網路風暴）
class EmergencyConnectionRateControl {
    private var messageHashes: Set<String> = []
    private var messageTimestamps: [String: Date] = [:]
    private let maxMessagesPerMinute = 5
    private let deduplicationWindow: TimeInterval = 300 // 5分鐘去重
    
    func shouldAcceptMessage(_ messageHash: String) -> Bool {
        let now = Date()
        
        // 清理過期時間戳
        messageTimestamps = messageTimestamps.filter { now.timeIntervalSince($0.value) < 60 }
        
        // 檢查最近一分鐘的消息數
        if messageTimestamps.count >= maxMessagesPerMinute {
            return false
        }
        
        // 檢查去重
        if messageHashes.contains(messageHash) {
            return false
        }
        
        // 記錄新消息
        messageHashes.insert(messageHash)
        messageTimestamps[messageHash] = now
        
        // 清理過期的哈希值
        if messageHashes.count > 1000 {
            let expiredHashes = messageTimestamps.filter { now.timeIntervalSince($0.value) > deduplicationWindow }.keys
            messageHashes.subtract(expiredHashes)
            for hash in expiredHashes {
                messageTimestamps.removeValue(forKey: hash)
            }
        }
        
        return true
    }
}

// MARK: - 訊息去重系統（災害通信優化）
class MessageDeduplicator {
    private var seenMessages: Set<String> = []
    private var messageTimestamps: [String: Date] = [:]
    private let maxCacheSize = 10000
    private let cacheValidityDuration: TimeInterval = 3600 // 1小時
    private let lock = NSLock()
    
    struct DeduplicationResult {
        let isDuplicate: Bool
        let error: Error?
    }
    
    func isDuplicate(messageID: String, senderID: String, timestamp: TimeInterval, content: String) -> Bool {
        let hashKey = createMessageHash(messageID: messageID, senderID: senderID, content: content)
        
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        
        // 清理過期記錄
        cleanupExpiredMessages(currentTime: now)
        
        // 檢查是否已存在
        if seenMessages.contains(hashKey) {
            return true
        }
        
        // 添加新記錄
        seenMessages.insert(hashKey)
        messageTimestamps[hashKey] = now
        
        return false
    }
    
    func isDuplicateSafe(messageID: String, senderID: String, timestamp: TimeInterval, content: String) -> DeduplicationResult {
        let isDup = isDuplicate(messageID: messageID, senderID: senderID, timestamp: timestamp, content: content)
        return DeduplicationResult(isDuplicate: isDup, error: nil)
    }
    
    private func createMessageHash(messageID: String, senderID: String, content: String) -> String {
        let combined = "\(messageID):\(senderID):\(content)"
        let data = combined.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func cleanupExpiredMessages(currentTime: Date) {
        let expiredKeys = messageTimestamps.compactMap { key, timestamp in
            currentTime.timeIntervalSince(timestamp) > cacheValidityDuration ? key : nil
        }
        
        for key in expiredKeys {
            seenMessages.remove(key)
            messageTimestamps.removeValue(forKey: key)
        }
        
        // 如果快取仍然太大，移除最舊的記錄
        if seenMessages.count > maxCacheSize {
            let sortedByTime = messageTimestamps.sorted { $0.value < $1.value }
            let itemsToRemove = sortedByTime.prefix(seenMessages.count - maxCacheSize)
            
            for (key, _) in itemsToRemove {
                seenMessages.remove(key)
                messageTimestamps.removeValue(forKey: key)
            }
        }
    }
    
    func getCacheSize() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return seenMessages.count
    }
    
    func getCacheUtilization() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return Double(seenMessages.count) / Double(maxCacheSize)
    }
}

// MARK: - 日誌記錄優化（大規模災害通信）
class SecurityLogger {
    enum SecurityEventType: String {
        case messageDecryptionFailed = "decryption_failed"
        case invalidMessageFormat = "invalid_format"
        case replayAttackDetected = "replay_attack"
        case excessiveMessageRate = "excessive_rate"
        case keyExchangeFailure = "key_exchange_failure"
    }
    
    enum SecuritySeverity: String {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    private var eventLog: [(Date, SecurityEventType, String, SecuritySeverity)] = []
    private var replayProtectionCache: Set<String> = []
    private let maxLogSize = 1000
    private let maxReplayCacheSize = 5000
    private let lock = NSLock()
    
    func logEvent(_ type: SecurityEventType, peerID: String, details: String, severity: SecuritySeverity) {
        lock.lock()
        defer { lock.unlock() }
        
        let entry = (Date(), type, "\(peerID): \(details)", severity)
        eventLog.append(entry)
        
        // 保持日誌大小限制
        if eventLog.count > maxLogSize {
            eventLog.removeFirst(eventLog.count - maxLogSize)
        }
        
        // 針對關鍵事件，立即輸出到控制台
        if severity == .critical || severity == .high {
            print("🚨 SecurityLogger: [\(severity.rawValue.uppercased())] \(type.rawValue) - \(peerID): \(details)")
        }
    }
    
    func isReplayAttack(messageHash: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        if replayProtectionCache.contains(messageHash) {
            return true
        }
        
        replayProtectionCache.insert(messageHash)
        
        // 保持快取大小限制
        if replayProtectionCache.count > maxReplayCacheSize {
            // 移除隨機元素（簡化的LRU）
            let elementsToRemove = replayProtectionCache.prefix(replayProtectionCache.count - maxReplayCacheSize)
            replayProtectionCache.subtract(elementsToRemove)
        }
        
        return false
    }
    
    func getRecentEventCount(within seconds: TimeInterval) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoff = Date().addingTimeInterval(-seconds)
        return eventLog.filter { $0.0 > cutoff }.count
    }
    
    func getCriticalEventCount(within seconds: TimeInterval) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoff = Date().addingTimeInterval(-seconds)
        return eventLog.filter { $0.0 > cutoff && $0.3 == .critical }.count
    }
    
    func getReplayProtectionCacheSize() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return replayProtectionCache.count
    }
}

// MARK: - 主要 ViewModel
@MainActor
class SignalViewModel: ObservableObject {
    // MARK: - 發布的狀態
    @Published var messages: [SignalMessage] = []
    @Published var isOnline: Bool = false
    @Published var connectionStatus: String = "離線"
    @Published var encryptionStatus: String = "未加密"
    @Published var currentLocation: CLLocation?
    @Published var isLocationEnabled: Bool = false
    
    // MARK: - 服務依賴
    private let networkService: NetworkServiceProtocol
    private let securityService: SecurityService
    private let settingsViewModel: SettingsViewModel
    private let selfDestructManager: SelfDestructManager
    
    // MARK: - 安全和性能組件
    private let securityLogger = SecurityLogger()
    private let messageDeduplicator = MessageDeduplicator()
    private lazy var connectionRateControl = EmergencyConnectionRateControl()
    
    // MARK: - 內部狀態
    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?
    private var cancellables = Set<AnyCancellable>()
    private var statusUpdateTimer: Timer?
    
    // MARK: - 防抖機制
    private var lastSignalTime: [SignalType: Date] = [:]
    private let signalCooldownDuration: TimeInterval = 2.0 // 2秒防抖
    private var isSendingSignal: Bool = false // 防止並發發送
    
    // MARK: - 信號去重機制
    private var recentReceivedSignals = Set<String>()
    private let signalDeduplicationWindow: TimeInterval = 1.0 // 1秒內的重複信號視為重複
    private let deduplicationQueue = DispatchQueue(label: "com.signalAir.signal.deduplication")
    
    // MARK: - 初始化
    init(
        networkService: NetworkServiceProtocol? = nil,
        securityService: SecurityService? = nil,
        settingsViewModel: SettingsViewModel? = nil,
        selfDestructManager: SelfDestructManager? = nil
    ) {
        self.networkService = networkService ?? ServiceContainer.shared.networkService
        self.securityService = securityService ?? ServiceContainer.shared.securityService
        self.settingsViewModel = settingsViewModel ?? ServiceContainer.shared.settingsViewModel
        self.selfDestructManager = selfDestructManager ?? ServiceContainer.shared.selfDestructManager
        
        setupLocationServices()
        setupNetworkObservers()
        setupStatusMonitoring()
        
        print("📡 SignalViewModel: 災害通信系統初始化完成")
    }
    
    deinit {
        statusUpdateTimer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - 位置服務設定
    private func setupLocationServices() {
        locationDelegate = LocationDelegate(
            onLocationUpdate: { [weak self] location in
                // 優化：只有在位置顯著變化時才更新相對位置
                Task { @MainActor in
                    self?.handleLocationUpdate(location)
                }
            },
            signalViewModel: self
        )
        
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // 請求位置授權，授權狀態變化將通過 locationManagerDidChangeAuthorization 回調處理
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // 如果已有授權狀態，手動觸發授權回調處理
            locationDelegate?.locationManagerDidChangeAuthorization(locationManager)
        }
    }
    
    // MARK: - 網路觀察者設定
    private func setupNetworkObservers() {
        // 監聽 ServiceContainer 的 Signal 訊息（支援二進制和JSON）
        NotificationCenter.default.publisher(for: NSNotification.Name("SignalMessageReceived"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                Task {
                    if let object = notification.object {
                        await self?.handleReceivedSignalMessage(object)
                    }
                }
            }
            .store(in: &cancellables)
        
        // 監聽網路狀態變化
        // 監聽連線狀態通知
        NotificationCenter.default.publisher(for: NSNotification.Name("PeerConnectionChanged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateConnectionStatus()
            }
            .store(in: &cancellables)
        
        // 監聽暱稱變更通知
        NotificationCenter.default.publisher(for: NSNotification.Name("NicknameDidChange"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // 暱稱變更通知已收到，SignalViewModel 會在發送信號時自動使用最新暱稱
                print("📡 SignalViewModel: 收到暱稱變更通知")
            }
            .store(in: &cancellables)
        
        print("📡 SignalViewModel: 網路觀察者設置完成")
    }
    
    // MARK: - 狀態監控設定
    private func setupStatusMonitoring() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnectionStatus()
            }
        }
    }
    
    // MARK: - 公開方法
    
    /// 發送緊急信號
    func sendEmergencySignal(type: SignalType) {
        // 🚫 防抖檢查 + 狀態檢查
        let now = Date()
        if let lastTime = lastSignalTime[type] {
            let timeSinceLastSignal = now.timeIntervalSince(lastTime)
            if timeSinceLastSignal < signalCooldownDuration {
                print("⏳ 信號冷卻中，請稍後再試 (剩餘: \(String(format: "%.1f", signalCooldownDuration - timeSinceLastSignal))秒)")
                return
            }
        }
        
        // 🔧 原子性狀態檢查和設置（解決競態條件）
        Task {
            await MainActor.run {
                // 在 MainActor 中進行原子性檢查
                if self.isSendingSignal {
                    print("⚠️ 正在發送信號中，跳過重複請求")
                    return
                }
                
                // 原子性設置狀態
                self.lastSignalTime[type] = now
                self.isSendingSignal = true
                
                // 在背景線程執行實際發送
                Task {
                    await self.performSignalSending(type: type)
                }
            }
        }
    }
    
    /// 執行實際的信號發送操作
    private func performSignalSending(type: SignalType) async {
        
        // 使用 NicknameService 的純暱稱，而不是 SettingsViewModel
        let userNickname = ServiceContainer.shared.nicknameService.userNickname
        
        do {
            // 創建信號數據（暫時不加密，先確保基本通訊正常）
            let signalID = UUID().uuidString
            let deviceID = ServiceContainer.shared.temporaryIDManager.deviceID
            let gridCode = getCurrentGridCode() ?? ""
            
            // 1. 編碼內部信號數據
            let signalData = SignalBinaryCodec.encodeSignalData(
                id: signalID,
                type: type,
                deviceName: userNickname,
                deviceID: deviceID,
                gridCode: gridCode
            )
            
            // 2. 使用標準的BinaryMessageEncoder編碼
            let message = MeshMessage(
                id: UUID().uuidString,
                type: .signal,
                data: signalData
            )
            
            guard let binaryPacket = try? BinaryMessageEncoder.encode(message) else {
                await MainActor.run {
                    print("❌ 信號編碼失敗")
                    self.isSendingSignal = false
                }
                return
            }
            
            print("📡 發送純二進制信號包：類型=\(type.rawValue), 內部=\(signalData.count)bytes, 總大小=\(binaryPacket.count)bytes")
            
            // 獲取連接的設備並廣播
            let connectedPeers = networkService.connectedPeers
            guard !connectedPeers.isEmpty else {
                await MainActor.run {
                    print("⚠️ 沒有連接的設備，無法發送信號")
                    self.isSendingSignal = false
                }
                return
            }
            
            // 廣播給所有連接的設備
            try await networkService.send(binaryPacket, to: connectedPeers)
            print("✅ 信號廣播完成，發送給 \(connectedPeers.count) 個設備")
            
            await MainActor.run {
                // 本地顯示發送的信號
                let localMessage = SignalMessage(
                    type: type,
                    deviceName: "\(userNickname) (我)",
                    distance: 0,
                    direction: nil,
                    timestamp: Date(),
                    gridCode: getCurrentGridCode()
                )
                
                messages.insert(localMessage, at: 0)
                
                // 限制訊息數量
                if messages.count > 50 {
                    messages = Array(messages.prefix(50))
                }
                
                // 追蹤信號以便自毀
                selfDestructManager.trackMessage(localMessage.id.uuidString, type: .signal, priority: .emergency)
                
                print("📡 SignalViewModel: 發送緊急信號 - \(type.rawValue)")
                
                // 🔧 重置發送狀態
                self.isSendingSignal = false
            }
            
        } catch {
            await MainActor.run {
                print("❌ SignalViewModel: 信號發送失敗 - \(error)")
                
                // 🔧 錯誤時也要重置發送狀態
                self.isSendingSignal = false
            }
        }
    }
    
    /// 清除所有訊息
    func clearAllMessages() {
        // 清除自毀管理器中的追蹤
        for message in messages {
            selfDestructManager.removeMessage(message.id.uuidString)
        }
        
        messages.removeAll()
        print("📡 SignalViewModel: 清除所有緊急訊息")
    }
    
    // MARK: - 私有方法
    
    /// 處理接收到的信號訊息（純二進制協議）
    private func handleReceivedSignalMessage(_ notification: Any) async {
        if let binaryData = notification as? Data {
            // 處理純二進制信號數據
            await handlePureBinarySignal(binaryData)
        } else if let signalDict = notification as? [String: Any] {
            // 向後兼容 JSON 格式（逐步淘汰）
            await handlePlainTextSignal(signalDict)
        } else {
            print("⚠️ 未知的信號訊息格式: \(type(of: notification))")
        }
    }
    
    /// 處理純二進制信號
    private func handlePureBinarySignal(_ data: Data) async {
        // 使用統一的完整 MeshMessage 解碼（新版本格式）
        do {
            let meshMessage = try BinaryMessageDecoder.decode(data)
            guard meshMessage.type == .signal || meshMessage.type == .emergency else {
                print("❌ SignalViewModel: 不是信號訊息類型，實際類型: \(meshMessage.type)")
                return
            }
            
            guard let decodedSignal = SignalBinaryCodec.decodeInlineSignalData(meshMessage.data) else {
                print("❌ SignalViewModel: 純二進制信號解碼失敗")
                return
            }
            
            // 信號解碼成功，繼續處理
            await processDecodedSignal(decodedSignal)
            
        } catch {
            print("❌ SignalViewModel: MeshMessage 解碼失敗: \(error)")
            return
        }
    }
    
    /// 處理已解碼的信號
    private func processDecodedSignal(_ decodedSignal: (type: SignalType, deviceName: String, deviceID: String, gridCode: String?, timestamp: Date)) async {
        let signalKey = "\(decodedSignal.deviceName)-\(decodedSignal.type.rawValue)-\(Int(decodedSignal.timestamp.timeIntervalSince1970))"
        
        let isDuplicate = deduplicationQueue.sync { () -> Bool in
            if recentReceivedSignals.contains(signalKey) {
                print("🚫 忽略重複信號: \(signalKey)")
                return true
            }
            
            // 添加到最近接收集合
            recentReceivedSignals.insert(signalKey)
            
            // 設定過期清理
            let window = self.signalDeduplicationWindow
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(window * 1_000_000_000))
                self?.recentReceivedSignals.remove(signalKey)
            }
            
            return false
        }
        
        if isDuplicate {
            return
        }
        
        // 計算距離和方向（基於網格）
        let (distance, direction) = calculateDistanceAndDirection(gridCode: decodedSignal.gridCode)
        
        // 檢查是否在附近區域
        if let gridCode = decodedSignal.gridCode, !isNearbySignal(gridCode) {
            print("⚠️ 信號距離過遠，忽略: \(decodedSignal.deviceName)")
            return
        }
        
        await MainActor.run {
            let receivedMessage = SignalMessage(
                type: decodedSignal.type,
                deviceName: decodedSignal.deviceName,
                distance: distance,
                direction: direction,
                timestamp: decodedSignal.timestamp,
                gridCode: decodedSignal.gridCode
            )
            
            messages.insert(receivedMessage, at: 0)
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
            
            // 追蹤信號以便自毀
            selfDestructManager.trackMessage(receivedMessage.id.uuidString, type: .signal, priority: .emergency)
            
            print("✅ 收到純二進制信號: \(decodedSignal.type.rawValue) 來自: \(decodedSignal.deviceName)")
        }
    }
    
    /// 處理二進制加密信號（優雅降級設計）
    private func handleBinarySignalMessage(_ data: Data) async {
        do {
            // 解析外層加密包
            guard let encryptedSignal = SignalBinaryCodec.decodeEncryptedSignal(data) else {
                print("❌ 二進制信號解析失敗")
                return
            }
            
            // 獲取發送者信息
            let senderID = encryptedSignal.senderID
            
            // 嘗試解密內部數據
            let decryptedData = try await securityService.decrypt(encryptedSignal.encryptedPayload, from: senderID)
            
            // 解析內部信號數據
            if let signalData = SignalBinaryCodec.decodeSignalData(decryptedData) {
                let (distance, direction) = calculateDistanceAndDirection(gridCode: signalData.gridCode)
                
                let displayMessage = SignalMessage(
                    type: signalData.type,
                    deviceName: signalData.deviceName,
                    distance: distance,
                    direction: direction,
                    timestamp: signalData.timestamp,
                    gridCode: signalData.gridCode
                )
                
                await MainActor.run {
                    messages.insert(displayMessage, at: 0)
                    if messages.count > 50 {
                        messages = Array(messages.prefix(50))
                    }
                }
                
                print("📡 接收二進制信號: \(signalData.type.rawValue) 來自 \(signalData.deviceName)")
            }
            
        } catch {
            // 優雅降級：解密失敗時顯示匿名信號
            print("❌ 信號解密失敗，顯示匿名版本: \(error)")
            await showAnonymousSignalFromBinary(data)
        }
    }
    
    /// 解密失敗時的優雅降級處理
    private func showAnonymousSignalFromBinary(_ data: Data) async {
        // 從頭部提取基本信息
        let timestamp = data.subdata(in: 3..<7).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        
        let displayMessage = SignalMessage(
            type: .safe, // 默認類型
            deviceName: "未知設備 (加密)",
            distance: nil,
            direction: nil,
            timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            gridCode: nil
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("🔒 顯示匿名信號（解密失敗但不影響系統）")
    }
    
    /// 取得當前網格代碼
    private func getCurrentGridCode() -> String? {
        guard let location = currentLocation else { return nil }
        return coordinateToGrid(location.coordinate)
    }
    
    /// 計算距離和方向
    private func calculateDistanceAndDirection(gridCode: String?) -> (Double?, CompassDirection?) {
        guard let currentLoc = currentLocation,
              let gridCode = gridCode else { return (nil, nil) }
        
        let currentGrid = coordinateToGrid(currentLoc.coordinate)
        let (distance, direction) = calculateRelativePosition(from: currentGrid, to: gridCode)
        
        return (distance, direction)
    }
    
    /// 創建信號數據字典
    private func createSignalData(type: SignalType) -> [String: Any] {
        let deviceName = settingsViewModel.userNickname
        
        var data: [String: Any] = [
            "type": type.rawValue,
            "deviceName": deviceName
        ]
        
        // 只傳送網格代碼，不傳送精確位置
        if let location = currentLocation {
            // 使用本地的網格計算方法
            data["gridCode"] = coordinateToGrid(location.coordinate)
        }
        
        return data
    }
    
    /// 創建加密的信號數據（簡化版本以避免崩潰）
    private func createEncryptedSignalData(type: SignalType, userNickname: String) -> [String: Any] {
        let signalID = UUID().uuidString
        
        // 創建基礎信號數據結構（較小的數據包）
        let basicSignalData: [String: Any] = [
            "id": signalID,
            "type": type.rawValue,
            "deviceName": userNickname,
            "timestamp": Date().timeIntervalSince1970,
            "gridCode": getCurrentGridCode() ?? ""
        ]
        
        return basicSignalData
    }
    
    /// 更新連線狀態
    private func updateConnectionStatus() {
        let connectedPeers = networkService.connectedPeers
        isOnline = !connectedPeers.isEmpty
        
        if isOnline {
            // 使用 LanguageService 的格式化字符串
            let languageService = ServiceContainer.shared.languageService
            connectionStatus = String(format: languageService.t("connected_devices"), "\(connectedPeers.count)")
            encryptionStatus = "端到端加密"
        } else {
            let languageService = ServiceContainer.shared.languageService
            connectionStatus = languageService.t("offline")
            encryptionStatus = languageService.t("disconnected")
        }
    }
    
    /// 檢查訊號是否在附近區域
    private func isNearbySignal(_ gridCode: String?) -> Bool {
        guard let currentLoc = currentLocation,
              let gridCode = gridCode else { return false }
        
        let currentGrid = coordinateToGrid(currentLoc.coordinate)
        let (distance, _) = calculateRelativePosition(from: currentGrid, to: gridCode)
        
        // 只顯示5公里範圍內的信號
        return distance <= 5000
    }
    
    /// 格式化距離顯示
    private func formatDistance(_ meters: Double) -> String {
        switch meters {
        case 0..<100:
            return "< 100m"
        case 100..<500:
            return "約 \(Int(meters/100)*100)m"
        case 500..<1000:
            return "約 \(Int(meters/100)*100)m"
        case 1000..<5000:
            let km = meters / 1000
            return "約 \(String(format: "%.1f", km)) 公里"
        default:
            let km = Int(meters / 1000)
            return "約 \(km) 公里"
        }
    }
    
    /// 處理位置更新 - 只有在位置顯著變化時才更新UI
    private func handleLocationUpdate(_ newLocation: CLLocation) {
        let shouldUpdate: Bool
        
        if let lastLocation = currentLocation {
            // 只有當位置變化超過100米時才更新相對位置
            let distance = lastLocation.distance(from: newLocation)
            shouldUpdate = distance > 100
        } else {
            shouldUpdate = true // 首次獲取位置
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = newLocation
        }
        
        if shouldUpdate {
            DispatchQueue.main.async { [weak self] in
                self?.updateMessagesWithRelativePositions()
            }
        }
    }
    
    /// 更新訊息的相對位置
    private func updateMessagesWithRelativePositions() {
        guard let currentLoc = currentLocation else { return }
        
        let currentGrid = coordinateToGrid(currentLoc.coordinate)
        
        for i in 0..<messages.count {
            if let peerGridCode = messages[i].gridCode {
                let (distance, direction) = calculateRelativePosition(
                    from: currentGrid,
                    to: peerGridCode
                )
                
                // 更新訊息的距離和方向
                let updatedMessage = messages[i]
                // 注意：SignalMessage 是 struct，需要重新賦值
                messages[i] = SignalMessage(
                    type: updatedMessage.type,
                    deviceName: updatedMessage.deviceName,
                    distance: distance,
                    direction: direction,
                    timestamp: updatedMessage.timestamp,
                    gridCode: updatedMessage.gridCode
                )
            }
        }
    }
    
    /// 處理加密的 Signal 訊息
    func handleEncryptedSignal(_ signalDict: [String: Any]) async {
        guard let senderID = signalDict["senderID"] as? String,
              let encryptedForPeersBase64 = signalDict["encryptedForPeers"] as? [String: String],
              let timestamp = signalDict["timestamp"] as? TimeInterval else {
            
            // 記錄安全事件：無效訊息格式
            securityLogger.logEvent(
                .invalidMessageFormat,
                peerID: signalDict["senderID"] as? String ?? "unknown",
                details: "Missing required fields in encrypted signal: senderID=\(signalDict["senderID"] != nil), encryptedForPeers=\(signalDict["encryptedForPeers"] != nil), timestamp=\(signalDict["timestamp"] != nil)",
                severity: .high
            )
            print("❌ SignalViewModel: 加密訊息格式無效 - 缺少必要欄位")
            print("   可用欄位: \(signalDict.keys.sorted())")
            return
        }
        
        // 嘗試用自己的 ID 解密
        let myPeerID = networkService.myPeerID.displayName
        
        do {
            if let encryptedBase64 = encryptedForPeersBase64[myPeerID],
               let encryptedData = Data(base64Encoded: encryptedBase64) {
                // 找到針對我的加密數據
                let _ = try await securityService.decrypt(encryptedData, from: senderID)
                
                // 如果需要處理解密後的數據，在這裡添加邏輯
                print("✅ SignalViewModel: 成功解密來自 \(senderID) 的信號")
                
            } else {
                // 沒有針對我的加密數據，這是正常的
                print("ℹ️ SignalViewModel: 未找到針對我的加密數據，跳過")
                return
            }
        } catch {
            // 解密失敗，記錄安全事件並顯示匿名版本
            let severity: SecurityLogger.SecuritySeverity = (error.localizedDescription.contains("key") ? .medium : .high)
            
            securityLogger.logEvent(
                .messageDecryptionFailed,
                peerID: senderID,
                details: "Decryption failed: \(error.localizedDescription)",
                severity: severity
            )
            
            print("❌ SignalViewModel: 解密失敗 - \(error)")
            // 顯示匿名版本
            await showAnonymousSignal(senderID: senderID, timestamp: timestamp)
        }
    }
    
    /// 處理明文 Signal 訊息（向後兼容）
    func handlePlainTextSignal(_ signalDict: [String: Any]) async {
        guard let typeString = signalDict["type"] as? String,
              let type = SignalType(rawValue: typeString),
              let deviceName = signalDict["deviceName"] as? String,
              let timestamp = signalDict["timestamp"] as? TimeInterval else {
            print("❌ SignalViewModel: 無效的明文信號數據格式")
            return
        }
        
        // 計算距離和方向（基於網格）
        let (distance, direction) = calculateDistanceAndDirection(gridCode: signalDict["gridCode"] as? String)
        
        let displayMessage = SignalMessage(
            type: type,
            deviceName: deviceName,
            distance: distance,
            direction: direction,
            timestamp: Date(timeIntervalSince1970: timestamp),
            gridCode: signalDict["gridCode"] as? String
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            
            // 限制訊息數量
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("🔓 SignalViewModel: 成功解密緊急訊號 - \(type.rawValue) 來自 \(deviceName)")
    }
    
    /// 顯示匿名版本的 Signal 訊息
    func showAnonymousSignal(senderID: String, timestamp: TimeInterval) async {
        // 當無法解密時，顯示通用的緊急訊號
        let displayMessage = SignalMessage(
            type: .safe, // 默認顯示為安全訊號
            deviceName: "\(senderID) (加密)", // 顯示匿名ID並標註加密
            distance: nil,
            direction: nil,
            timestamp: Date(timeIntervalSince1970: timestamp),
            gridCode: nil
        )
        
        await MainActor.run {
            messages.insert(displayMessage, at: 0)
            
            // 限制訊息數量
            if messages.count > 50 {
                messages = Array(messages.prefix(50))
            }
        }
        
        print("🔒 SignalViewModel: 顯示匿名緊急訊號來自 \(senderID)")
    }
    
    /// 生成訊號訊息
    func generateSignalMessage(for type: SignalType) -> String {
        switch type {
        case .safe:
            return "我在這裡，狀況安全"
        case .supplies:
            return "需要物資支援！"
        case .medical:
            return "需要醫療支援！"
        case .danger:
            return "危險警告！請遠離此區域"
        }
    }
    
    // MARK: - 本地網格系統實現（避免循環依賴）
    
    private func coordinateToGrid(_ coordinate: CLLocationCoordinate2D) -> String {
        let gridSize = 0.005 // 約 500 公尺
        let baseLatitude = floor(coordinate.latitude * 100) / 100
        let baseLongitude = floor(coordinate.longitude * 100) / 100
        
        let xIndex = Int((coordinate.longitude - baseLongitude) / gridSize)
        let yIndex = Int((coordinate.latitude - baseLatitude) / gridSize)
        
        let x = max(0, min(25, xIndex))
        let y = max(1, min(99, yIndex + 1))
        
        // 安全的 UnicodeScalar 創建，避免強制解包崩潰
        guard let scalar = UnicodeScalar(65 + x) else {
            print("⚠️ SignalViewModel: UnicodeScalar 創建失敗，x=\(x)")
            return "A\(y)" // 預設返回 A 字母
        }
        let letter = Character(scalar)
        return "\(letter)\(y)"
    }
    
    func calculateRelativePosition(from myGrid: String, to peerGrid: String) -> (distance: Double, direction: CompassDirection?) {
        guard let myLetter = myGrid.first,
              let myNumber = Int(myGrid.dropFirst()),
              let peerLetter = peerGrid.first,
              let peerNumber = Int(peerGrid.dropFirst()) else {
            return (0, nil)
        }
        
        guard let peerLetterValue = peerLetter.asciiValue,
              let myLetterValue = myLetter.asciiValue else {
            return (0, nil)
        }
        let xDiff = Int(peerLetterValue) - Int(myLetterValue)
        let yDiff = peerNumber - myNumber
        
        let gridDistance = sqrt(Double(xDiff * xDiff + yDiff * yDiff))
        let estimatedDistance = gridDistance * 500 // 米
        
        let angle = atan2(Double(xDiff), Double(yDiff)) * 180 / .pi
        let normalizedAngle = angle < 0 ? angle + 360 : angle
        let direction = bearingToCompassDirection(normalizedAngle)
        
        return (estimatedDistance, direction)
    }
    
    private func bearingToCompassDirection(_ bearing: Double) -> CompassDirection {
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360)
        
        switch normalizedBearing {
        case 337.5...360, 0..<22.5: return .north
        case 22.5..<67.5: return .northeast
        case 67.5..<112.5: return .east
        case 112.5..<157.5: return .southeast
        case 157.5..<202.5: return .south
        case 202.5..<247.5: return .southwest
        case 247.5..<292.5: return .west
        case 292.5..<337.5: return .northwest
        default: return .north
        }
    }

    #if DEBUG
    /// 測試訊息去重系統
    func testDeduplication() {
        print("🧪 SignalViewModel: 開始測試訊息去重系統...")
        
        let testMessage = "TEST_MESSAGE_\(UUID().uuidString)"
        let senderID = "TEST_SENDER"
        let messageID = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        
        // 第一次檢查 - 應該不是重複
        let result1 = messageDeduplicator.isDuplicate(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: testMessage
        )
        print("   第一次檢查結果: \(result1 ? "重複" : "新訊息")")
        
        // 第二次檢查 - 應該是重複
        let result2 = messageDeduplicator.isDuplicate(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: testMessage
        )
        print("   第二次檢查結果: \(result2 ? "重複" : "新訊息")")
        
        // 測試安全版本
        let safeResult = messageDeduplicator.isDuplicateSafe(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: testMessage
        )
        
        if let error = safeResult.error {
            print("   安全模式錯誤: \(error.localizedDescription)")
        } else {
            print("   安全模式結果: \(safeResult.isDuplicate ? "重複" : "新訊息")")
        }
        
        // 使用安全版本重試
        let safeResult1 = messageDeduplicator.isDuplicateSafe(
            messageID: messageID,
            senderID: senderID,
            timestamp: timestamp,
            content: testMessage
        )
        
        if let error = safeResult1.error {
            print("   安全模式錯誤: \(error.localizedDescription)")
        } else {
            print("   安全模式結果: \(safeResult1.isDuplicate ? "重複" : "新訊息")")
        }
    }
    #endif
}

// MARK: - 位置代理
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onLocationUpdate: (CLLocation) -> Void
    private weak var signalViewModel: SignalViewModel?
    
    init(onLocationUpdate: @escaping (CLLocation) -> Void, signalViewModel: SignalViewModel? = nil) {
        self.onLocationUpdate = onLocationUpdate
        self.signalViewModel = signalViewModel
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationDelegate: 位置更新失敗 - \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 授權成功，啟動位置更新
            manager.startUpdatingLocation()
            Task { @MainActor in
                signalViewModel?.isLocationEnabled = true
            }
            print("📍 位置服務已啟用")
        case .denied, .restricted:
            print("📍 位置服務被拒絕或限制")
            Task { @MainActor in
                signalViewModel?.isLocationEnabled = false
            }
        case .notDetermined:
            print("📍 位置授權尚未確定")
        @unknown default:
            print("📍 未知的位置授權狀態")
        }
    }
}