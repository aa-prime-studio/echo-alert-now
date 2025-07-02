import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity

// MARK: - 二進制協議支持
// 直接使用全局 BinaryEncoder 和 BinaryDecoder

// MARK: - 內聯重要類型定義（解決編譯範圍問題）

// 密鑰交換狀態
enum LocalKeyExchangeStatus: UInt8 {
    case success = 0
    case alreadyEstablished = 1
    case error = 2
}

// 簡化版本的 BinaryEncoder 和 BinaryDecoder 方法（內聯）
class LocalBinaryDecoder {
    static func decodeKeyExchange(_ data: Data) -> (
        publicKey: Data,
        senderID: String,
        retryCount: UInt8,
        timestamp: Date
    )? {
        guard data.count >= 8 else { return nil }
        
        var offset = 0
        
        // 跳過協議版本和消息類型
        offset += 2
        
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
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
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
        
        // 跳過協議版本和消息類型
        offset += 2
        
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
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
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
                errorMessage = String(data: data.subdata(in: offset..<offset+errorLength), encoding: .utf8)
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

class LocalBinaryEncoder {
    static func encodeKeyExchange(
        publicKey: Data,
        senderID: String,
        retryCount: UInt8 = 0,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(1) // BinaryProtocolVersion.v1.rawValue
        
        // 1 byte: 消息類型
        data.append(5) // 使用正確的密鑰交換類型 0x05
        
        // 1 byte: 重試次數
        data.append(retryCount)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        data.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        data.append(publicKey)
        
        return data
    }
    
    static func encodeKeyExchangeResponse(
        publicKey: Data,
        senderID: String,
        status: LocalKeyExchangeStatus,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) -> Data {
        var data = Data()
        
        // 1 byte: 協議版本
        data.append(1) // BinaryProtocolVersion.v1.rawValue
        
        // 1 byte: 消息類型
        data.append(7) // 專用密鑰交換回應類型
        
        // 1 byte: 狀態
        data.append(status.rawValue)
        
        // 4 bytes: 時間戳
        let ts = UInt32(timestamp.timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: ts.littleEndian) { Array($0) })
        
        // 發送者ID
        if let senderData = senderID.data(using: .utf8) {
            data.append(UInt8(min(senderData.count, 255)))
            data.append(senderData.prefix(255))
        } else {
            data.append(0)
        }
        
        // 2 bytes: 公鑰長度
        let keyLength = UInt16(publicKey.count)
        data.append(contentsOf: withUnsafeBytes(of: keyLength.littleEndian) { Array($0) })
        
        // N bytes: 公鑰數據
        data.append(publicKey)
        
        // 錯誤訊息（可選）
        if let errorMessage = errorMessage, let errorData = errorMessage.data(using: .utf8) {
            data.append(UInt8(min(errorData.count, 255)))
            data.append(errorData.prefix(255))
        } else {
            data.append(0)
        }
        
        return data
    }
}

// MARK: - 臨時二進制協議支持（內聯）
class TempBinaryDataValidator {
    static func validateBinaryData(_ data: Data) throws {
        guard data.count >= 3 else {
            throw NSError(domain: "BinaryValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "數據太短"])
        }
    }
}

class TempBinaryProtocolMetrics {
    static let shared = TempBinaryProtocolMetrics()
    
    func recordDecoding(time: TimeInterval) {
        print("📊 解碼時間: \(String(format: "%.3f", time * 1000))ms")
    }
    
    func recordError() {
        print("❌ 二進制協議錯誤")
    }
    
    func printReport() {
        print("📊 臨時性能統計（完整版本在 BinaryProtocol.swift 中）")
    }
    
    func resetStats() {
        print("📊 統計已重置")
    }
}

class TempBinaryDecoder {
    static func decodeEncryptedSignalOptimized(_ data: Data) -> (
        version: UInt8,
        messageType: UInt8,
        isEncrypted: Bool,
        timestamp: Date,
        id: String,
        senderID: String,
        encryptedPayload: Data
    )? {
        // 使用內聯解碼邏輯（從移除的 InlineBinaryDecoder 複製）
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
        guard offset < data.count else { return nil }
        let senderIDLength = Int(data[offset])
        offset += 1
        
        guard offset + senderIDLength <= data.count else { return nil }
        let senderID = String(data: data.subdata(in: offset..<offset+senderIDLength), encoding: .utf8) ?? ""
        offset += senderIDLength
        
        // 加密載荷長度
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
}

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

// MARK: - 臨時ID管理器（簡化版）
class TemporaryIDManager: ObservableObject {
    @Published var deviceID: String = "台灣小吃#A1B2"
    
    init() {
        print("📱 TemporaryIDManager: 簡化初始化完成")
    }
}


// MARK: - Service Container
/// 應用程式服務容器，負責管理所有服務的依賴注入和生命週期
class ServiceContainer: ObservableObject {
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
    var floodProtection = FloodProtection()
    var settingsViewModel = SettingsViewModel()
    var connectionOptimizer = ConnectionOptimizer()
    // var connectionKeepAlive: ConnectionKeepAlive?
    // var autoReconnectManager: AutoReconnectManager?
    
    // MARK: - Basic Initialization
    private init() {
        print("🚀 ServiceContainer: 開始初始化完整服務容器...")
        
        // 初始化 MeshManager，需要依賴其他服務
        self.meshManager = MeshManager(
            networkService: self.networkService,
            securityService: self.securityService,
            floodProtection: self.floodProtection
        )
        
        // 設置密鑰交換回調
        setupKeyExchangeCallbacks()
        
        // 設置定期檢查會話密鑰
        setupSessionKeyMonitoring()
        
        // 初始化連接保持和自動重連服務（暫時註解，等文件正確加入項目後再啟用）
        // self.connectionKeepAlive = ConnectionKeepAlive(networkService: networkService)
        // self.autoReconnectManager = AutoReconnectManager(networkService: networkService)
        
        self.isInitialized = true
        print("✅ ServiceContainer: 完整服務容器初始化完成")
        
        // 延遲啟動網路服務，避免阻塞主線程
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            self.networkService.startNetworking()
            // self.connectionKeepAlive?.start()
            // self.autoReconnectManager?.start()
        }
    }
    
    // MARK: - Factory Methods（真正實現）
    func createChatViewModel() -> ChatViewModel {
        print("💬 創建 ChatViewModel")
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
        return BingoGameViewModel(languageService: self.languageService)
    }
    
    // MARK: - 密鑰交換設置
    private func setupKeyExchangeCallbacks() {
        print("🔑 設置密鑰交換回調...")
        
        // 當新設備連接時自動進行密鑰交換和連接優化
        networkService.onPeerConnected = { [weak self] peerDisplayName in
            guard let self = self else { return }
            
            // 檢查是否應該接受新連接
            guard self.connectionOptimizer.shouldAcceptNewConnection() else {
                print("🚫 連接數已達上限，拒絕連接 \(peerDisplayName)")
                return
            }
            
            // 通知連接優化器
            self.connectionOptimizer.onPeerConnected(peerDisplayName)
            
            print("🔑 開始與 \(peerDisplayName) 進行密鑰交換...")
            
            // 延遲5秒確保連接完全穩定後再進行密鑰交換
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                Task {
                    // 先驗證連接穩定性
                    if await self.verifyConnectionStability(with: peerDisplayName) {
                        await self.initiateKeyExchange(with: peerDisplayName)
                    } else {
                        print("⚠️ 連接不穩定，跳過與 \(peerDisplayName) 的密鑰交換")
                    }
                }
            }
        }
        
        // 當設備斷開連接時，清理會話密鑰和優化器狀態
        networkService.onPeerDisconnected = { [weak self] peerDisplayName in
            guard let self = self else { return }
            
            print("❌ 設備斷開連接: \(peerDisplayName)")
            
            // 清理會話密鑰
            self.securityService.removeSessionKey(for: peerDisplayName)
            
            // 通知連接優化器
            self.connectionOptimizer.onPeerDisconnected(peerDisplayName)
        }
        
        // 處理收到的數據（包含密鑰交換）
        networkService.onDataReceived = { [weak self] data, peerDisplayName in
            guard let self = self else { return }
            
            Task {
                await self.handleReceivedData(data, from: peerDisplayName)
            }
        }
    }
    
    // MARK: - 數據處理（純二進制）
    private func handleReceivedData(_ data: Data, from peerDisplayName: String) async {
        // ⚡ 純二進制協議，零 JSON 依賴
        guard data.count >= 2 && data[0] == 1 else {
            print("⚠️ 收到無效數據格式，大小: \(data.count) bytes，來自: \(peerDisplayName)")
            return
        }
        
        let messageType = data[1]
        
        switch messageType {
        case 7: // keyExchangeResponse (專用類型)
            await handleBinaryKeyExchangeResponse(data, from: peerDisplayName)
        default:
            // 所有其他消息（包括遊戲訊息類型6）路由到相應的處理器
            await routeMessage(data, from: peerDisplayName)
        }
    }
    
    // MARK: - 二進制密鑰交換處理
    private func handleBinaryKeyExchange(_ data: Data, from peerDisplayName: String) async {
        do {
            guard let keyExchange = LocalBinaryDecoder.decodeKeyExchange(data) else {
                print("❌ 二進制密鑰交換解碼失敗")
                return
            }
            
            print("🔑 收到來自 \(peerDisplayName) 的密鑰交換請求，設備ID: \(keyExchange.senderID)，重試次數: \(keyExchange.retryCount)")
            
            // 檢查是否已經有會話密鑰
            if securityService.hasSessionKey(for: peerDisplayName) {
                print("✅ 與 \(peerDisplayName) 已有會話密鑰，發送確認回應")
                
                // 發送二進制回應
                let responseData = LocalBinaryEncoder.encodeKeyExchangeResponse(
                    publicKey: try securityService.getPublicKey(),
                    senderID: nicknameService.displayName,  // 使用用戶設置的暱稱
                    status: LocalKeyExchangeStatus.alreadyEstablished
                )
                
                if let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) {
                    try await networkService.send(responseData, to: [peer])
                }
                return
            }
            
            // 執行 ECDH 密鑰交換，並建立設備ID映射
            try securityService.performKeyExchange(with: keyExchange.publicKey, peerID: peerDisplayName, deviceID: keyExchange.senderID)
            
            print("✅ 與 \(peerDisplayName) 的密鑰交換完成")
            
            // 發送二進制回應
            let responseData = LocalBinaryEncoder.encodeKeyExchangeResponse(
                publicKey: try securityService.getPublicKey(),
                senderID: nicknameService.displayName,  // 使用用戶設置的暱稱
                status: LocalKeyExchangeStatus.success
            )
            
            if let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) {
                try await networkService.send(responseData, to: [peer])
                print("🔑 二進制密鑰交換回應已發送給 \(peerDisplayName)")
            }
            
        } catch {
            print("❌ 處理二進制密鑰交換失敗: \(error)")
            
            // 發送錯誤回應
            do {
                let errorResponse = LocalBinaryEncoder.encodeKeyExchangeResponse(
                    publicKey: Data(),
                    senderID: nicknameService.displayName,  // 使用用戶設置的暱稱
                    status: LocalKeyExchangeStatus.error,
                    errorMessage: error.localizedDescription
                )
                
                if let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) {
                    try await networkService.send(errorResponse, to: [peer])
                }
            } catch {
                print("❌ 發送錯誤回應失敗: \(error)")
            }
        }
    }
    
    private func handleBinaryKeyExchangeResponse(_ data: Data, from peerDisplayName: String) async {
        do {
            guard let response = LocalBinaryDecoder.decodeKeyExchangeResponse(data) else {
                print("❌ 二進制密鑰交換回應解碼失敗")
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
                if securityService.hasSessionKey(for: peerDisplayName) {
                    print("✅ 與 \(peerDisplayName) 已有會話密鑰")
                    return
                }
                
                try securityService.performKeyExchange(with: response.publicKey, peerID: peerDisplayName, deviceID: response.senderID)
                print("✅ 二進制密鑰交換回應處理完成，與 \(peerDisplayName) 建立安全連接")
            }
            
        } catch {
            print("❌ 處理二進制密鑰交換回應失敗: \(error)")
        }
    }
    
    private func routeMessage(_ data: Data, from peerDisplayName: String) async {
        // ⚡ 純二進制協議路由
        guard data.count >= 2 && data[0] == 1 else {
            print("❌ 無效訊息格式，大小: \(data.count) 字節，來自: \(peerDisplayName)")
            return
        }
        
        let messageType = data[1]
        print("📦 路由簡化二進制訊息類型: \(messageType) 來自: \(peerDisplayName)")
        
        // 使用新的 MeshMessageType 映射
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
        case .topology:    // 0x07
            await routeTopologyMessage(data, from: peerDisplayName)
        case nil:
            print("❓ 未知的二進制訊息類型: \(messageType)")
        }
    }
    
    // MARK: - 系統訊息路由
    private func routeSystemMessage(_ data: Data, from peerDisplayName: String) async {
        do {
            let message = try BinaryMessageDecoder.decode(data)
            
            // 檢查是否為穩定性測試訊息
            if message.id.starts(with: "stability-test-") {
                let testContent = String(data: message.data, encoding: .utf8) ?? ""
                print("✅ 收到穩定性測試回應: \(testContent) 來自: \(peerDisplayName)")
                return
            }
            
            // 其他系統訊息處理
            print("📋 收到系統訊息: \(message.id) 來自: \(peerDisplayName)")
            
        } catch {
            print("❌ 系統訊息解碼失敗: \(error)")
        }
    }
    
    // MARK: - 專用密鑰交換方法
    private func initiateKeyExchange(with peerDisplayName: String) async {
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            let startTime = Date()
            
            do {
                // 檢查是否已經有會話密鑰
                if securityService.hasSessionKey(for: peerDisplayName) {
                    print("✅ \(peerDisplayName) 已有會話密鑰，跳過交換")
                    return
                }
                
                // 獲取我們的公鑰
                let publicKey = try securityService.getPublicKey()
                
                // 創建二進制密鑰交換訊息
                let messageData = LocalBinaryEncoder.encodeKeyExchange(
                    publicKey: publicKey,
                    senderID: nicknameService.displayName,  // 使用用戶設置的暱稱而不是隨機生成的
                    retryCount: UInt8(retryCount)
                )
                
                // 查找對等設備
                if let peer = networkService.connectedPeers.first(where: { $0.displayName == peerDisplayName }) {
                    try await networkService.send(messageData, to: [peer])
                    
                    // 記錄發送成功和延遲
                    let latency = Date().timeIntervalSince(startTime)
                    connectionOptimizer.onMessageSent(to: peerDisplayName, size: messageData.count, latency: latency)
                    
                    print("🔑 二進制密鑰交換請求已發送給 \(peerDisplayName) (嘗試: \(retryCount + 1)/\(maxRetries), 大小: \(messageData.count) bytes, 延遲: \(String(format: "%.0f", latency * 1000))ms)")
                    
                    // 等待1秒檢查是否建立了會話密鑰
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    if securityService.hasSessionKey(for: peerDisplayName) {
                        print("✅ 與 \(peerDisplayName) 的二進制密鑰交換成功")
                        return
                    } else {
                        print("⚠️ 與 \(peerDisplayName) 的密鑰交換未完成，準備重試...")
                        retryCount += 1
                    }
                } else {
                    print("❌ 找不到對等設備 \(peerDisplayName)")
                    break
                }
                
            } catch {
                print("❌ 二進制密鑰交換失敗 (嘗試 \(retryCount + 1)): \(error)")
                connectionOptimizer.onMessageFailed(to: peerDisplayName)
                retryCount += 1
                
                if retryCount < maxRetries {
                    // 指數退避重試
                    let delay = Double(retryCount * 2)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        if retryCount >= maxRetries {
            print("❌ 與 \(peerDisplayName) 的二進制密鑰交換最終失敗，已達最大重試次數")
        }
    }
    
    // MARK: - 會話密鑰監控
    private func setupSessionKeyMonitoring() {
        // 每30秒檢查一次會話密鑰狀態
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndRepairSessionKeys()
            }
        }
    }
    
    private func checkAndRepairSessionKeys() async {
        let connectedPeers = networkService.connectedPeers.map { $0.displayName }
        
        for peerDisplayName in connectedPeers {
            if !securityService.hasSessionKey(for: peerDisplayName) {
                print("🔧 檢測到 \(peerDisplayName) 缺少會話密鑰，嘗試修復...")
                await initiateKeyExchange(with: peerDisplayName)
            }
        }
        
        // 清理已斷開連接的會話密鑰
        let allSessionKeys = securityService.getAllSessionKeyPeerIDs()
        for sessionKeyPeerID in allSessionKeys {
            if !connectedPeers.contains(sessionKeyPeerID) {
                print("🧹 清理已斷開連接的會話密鑰: \(sessionKeyPeerID)")
                securityService.removeSessionKey(for: sessionKeyPeerID)
            }
        }
    }
    
    // MARK: - 純二進制信號路由（零 JSON 依賴）
    private func routeSignalMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 跳過協議頭部（版本+類型），提取內部信號數據
        guard data.count >= 3 else {
            print("⚠️ 信號數據太短: \(data.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        let signalData = data.subdata(in: 2..<data.count) // 跳過版本(1byte)+類型(1byte)
        
        // 解析內部信號數據
        guard let decodedSignal = InlineBinaryEncoder.decodeInlineSignalData(signalData) else {
            print("⚠️ 純二進制信號解析失敗: 內部大小=\(signalData.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        // 基本時間戳檢查
        let timeDiff = abs(Date().timeIntervalSince(decodedSignal.timestamp))
        if timeDiff > 300 { // 5分鐘內的訊息才接受
            print("⚠️ 信號訊息過期: \(timeDiff)秒")
            return
        }
        
        let headerParseTime = Date().timeIntervalSince(startTime) * 1000
        
        // 轉發內部信號數據給 SignalViewModel
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SignalMessageReceived"),
                object: signalData,  // 轉發內部信號數據（不含協議頭部）
                userInfo: ["sender": peerDisplayName]
            )
        }
        
        print("📡 純二進制信號路由完成 - 解析時間: \(String(format: "%.3f", headerParseTime))ms, 類型: \(decodedSignal.type.rawValue), 設備: \(decodedSignal.deviceName), 來源: \(peerDisplayName)")
    }
    
    private func routeChatMessage(_ data: Data, from peerDisplayName: String) async {
        let startTime = Date()
        
        // 跳過協議頭部（版本+類型），提取內部聊天數據
        guard data.count >= 3 else {
            print("⚠️ 聊天數據太短: \(data.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        let chatData = data.subdata(in: 2..<data.count) // 跳過版本(1byte)+類型(1byte)
        
        // 基本格式驗證
        guard chatData.count >= 25 else { // 最小聊天訊息大小
            print("⚠️ 聊天內部數據太短: \(chatData.count)bytes, 來源=\(peerDisplayName)")
            return
        }
        
        let headerParseTime = Date().timeIntervalSince(startTime) * 1000
        
        // 轉發內部聊天數據給 ChatViewModel
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("ChatMessageReceived"),
                object: chatData,  // 轉發內部聊天數據（不含協議頭部）
                userInfo: ["sender": peerDisplayName]
            )
        }
        
        print("💬 純二進制聊天路由完成 - 解析時間: \(String(format: "%.3f", headerParseTime))ms, 大小: \(chatData.count)bytes, 來源: \(peerDisplayName)")
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
        TempBinaryProtocolMetrics.shared.printReport()
    }
    
    /// 重置性能統計
    func resetBinaryProtocolStats() {
        TempBinaryProtocolMetrics.shared.resetStats()
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
}