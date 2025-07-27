import Foundation
import UIKit
import MultipeerConnectivity

// MARK: - 協議調試器
class ProtocolDebugger {
    static let shared = ProtocolDebugger()
    
    // 診斷模式開關
    var diagnosticMode = true
    private let debugQueue = DispatchQueue(label: "com.signalAir.debug", qos: .utility)
    
    // MARK: - 數據日誌記錄
    static func logData(_ data: Data, label: String, peer: String, showFullData: Bool = false) {
        guard shared.diagnosticMode else { return }
        
        print("\n🔍 [\(label)] from/to \(peer)")
        print("   時間: \(Date())")
        print("   大小: \(data.count) bytes")
        print("   HEX前綴: \(data.prefix(20).hexString)")
        print("   前20字節: \(Array(data.prefix(20)))")
        
        // 嘗試解析為字符串
        if let string = String(data: data, encoding: .utf8) {
            print("   UTF8: \(string.prefix(100))...")
        }
        
        // 完整數據（僅在需要時）
        if showFullData && data.count < 1000 {
            print("   完整HEX: \(data.hexString)")
        }
        
        // 嘗試解析協議頭
        if data.count >= 2 {
            print("   協議版本: \(data[0])")
            print("   訊息類型: \(data[1])")
        }
        
        print("   ----")
    }
    
    // MARK: - 設備診斷
    static func logDeviceInfo() {
        print("\n📱 設備診斷信息:")
        print("   設備型號: \(UIDevice.current.model)")
        print("   系統版本: \(UIDevice.current.systemVersion)")
        print("   設備名稱: \(UIDevice.current.name)")
        
        // 檢查時區和語言設置
        print("   時區: \(TimeZone.current.identifier)")
        print("   語言: \(Locale.current.identifier)")
        
        // 檢查處理器架構
        print("   處理器: \(getProcessorInfo())")
        
        // 檢查網路配置
        print("   網路介面: \(getNetworkInterfaces())")
        
        // 檢查內存狀態
        print("   內存狀態: \(getMemoryInfo())")
        print("   ----\n")
    }
    
    // MARK: - 密鑰交換調試
    static func debugKeyExchange(_ data: Data, from peer: String) {
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
        print("   ----\n")
    }
    
    // MARK: - 測試消息
    static func sendTestMessage(to peer: String, using networkService: NetworkService) {
        let testMessage = "TEST:\(Date().timeIntervalSince1970):\(UIDevice.current.name)"
        if let testData = testMessage.data(using: .utf8) {
            print("\n📤 發送測試消息: \(testMessage)")
            logData(testData, label: "測試消息", peer: peer)
            
            Task {
                do {
                    try await networkService.send(testData, to: [peer])
                    print("✅ 測試消息發送成功")
                } catch {
                    print("❌ 測試消息發送失敗: \(error)")
                }
            }
        }
    }
    
    static func handleTestMessage(_ data: Data, from peer: String) -> Bool {
        if let message = String(data: data, encoding: .utf8), message.hasPrefix("TEST:") {
            print("\n📥 收到測試消息: \(message) from \(peer)")
            
            // 解析測試消息
            let components = message.split(separator: ":")
            if components.count >= 3 {
                let timestamp = components[1]
                let deviceName = components[2]
                print("   發送時間: \(timestamp)")
                print("   發送設備: \(deviceName)")
            }
            
            return true
        }
        return false
    }
    
    // MARK: - 測試模式
    static func generateTestPattern() -> Data {
        var data = Data()
        
        // 添加已知的測試模式
        data.append(0x01) // 協議版本
        data.append(0x05) // 消息類型 (keyExchange)
        data.append(0x00) // 重試次數
        
        // 時間戳 (4 bytes, little endian)
        let timestamp = UInt32(Date().timeIntervalSince1970)
        data.append(contentsOf: withUnsafeBytes(of: timestamp.littleEndian) { Array($0) })
        
        // 發送者ID
        let senderID = "TEST_DEVICE"
        data.append(UInt8(senderID.count))
        data.append(senderID.data(using: .utf8)!)
        
        // 公鑰長度和數據 (使用假數據)
        let fakeKey = Data(repeating: 0xAB, count: 32)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(fakeKey.count).littleEndian) { Array($0) })
        data.append(fakeKey)
        
        print("\n🧪 生成測試模式:")
        print("   大小: \(data.count) bytes")
        print("   HEX: \(data.hexString)")
        logData(data, label: "測試模式", peer: "SELF", showFullData: true)
        
        return data
    }
    
    // MARK: - 多點連接診斷
    static func debugMCSession(_ session: MCSession) {
        print("\n🔌 MCSession 配置:")
        print("   加密偏好: \(session.encryptionPreference.rawValue)")
        print("   連接的Peers: \(session.connectedPeers.map { $0.displayName })")
        
        // 檢查安全配置
        if let securityIdentity = session.securityIdentity {
            print("   安全身份: 已配置")
        } else {
            print("   安全身份: 未配置")
        }
        print("   ----\n")
    }
    
    // MARK: - 數據保存
    static func saveRawDataToFile(_ data: Data, from peer: String, label: String = "received") {
        shared.debugQueue.async {
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
    
    // MARK: - 多種解析嘗試
    static func tryMultipleParsing(_ data: Data, from peer: String) {
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
        
        // 4. 檢查是否為測試消息
        if handleTestMessage(data, from: peer) {
            print("   ✅ 識別為測試消息")
        }
        
        print("   ----\n")
    }
    
    // MARK: - 清理診斷
    static func debugCleanup() {
        print("\n🧹 清理診斷:")
        
        // UserDefaults
        print("   UserDefaults中的SignalAir數據:")
        UserDefaults.standard.dictionaryRepresentation().forEach { key, value in
            if key.contains("SignalAir") {
                print("     - \(key): \(String(describing: value).prefix(100))...")
            }
        }
        
        // 文件系統
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let files = try? FileManager.default.contentsOfDirectory(at: documentsPath, 
                                                                   includingPropertiesForKeys: nil) {
            print("   Documents目錄文件:")
            files.forEach { url in
                print("     - \(url.lastPathComponent)")
            }
        }
        
        print("   ----\n")
    }
    
    // MARK: - 輔助方法
    private static func getProcessorInfo() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private static func getNetworkInterfaces() -> String {
        var interfaces: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let name = String(cString: (interface?.ifa_name)!)
                
                if !interfaces.contains(name) {
                    interfaces.append(name)
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return interfaces.joined(separator: ", ")
    }
    
    private static func getMemoryInfo() -> String {
        let memoryUsage = ProcessInfo.processInfo.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
}

// MARK: - Data Extension
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var prettyHexString: String {
        return map { String(format: "%02hhx", $0) }
            .enumerated()
            .map { $0.offset % 16 == 15 ? $0.element + "\n" : $0.element + " " }
            .joined()
    }
}

// MARK: - 診斷命令
extension ProtocolDebugger {
    static func runFullDiagnostics(networkService: NetworkService?, securityService: SecurityService?) {
        print("\n🏥 ========== 完整診斷開始 ==========")
        
        // 1. 設備信息
        logDeviceInfo()
        
        // 2. 網路狀態
        if let network = networkService {
            print("🌐 網路狀態:")
            print("   連接設備: \(network.connectedPeers)")
            print("   是否活躍: \(network.isNetworkActive)")
        }
        
        // 3. 安全服務狀態
        if let security = securityService {
            print("🔐 安全服務狀態:")
            print("   公鑰存在: \(security.hasPublicKey)")
            // 列出有會話密鑰的對等節點
            let sessionPeers = networkService?.connectedPeers.filter { 
                security.hasSessionKey(for: $0)
            } ?? []
            print("   有會話密鑰的節點: \(sessionPeers)")
        }
        
        // 4. 清理診斷
        debugCleanup()
        
        // 5. 生成測試模式
        let testPattern = generateTestPattern()
        print("   測試模式準備就緒: \(testPattern.count) bytes")
        
        print("🏥 ========== 診斷完成 ==========\n")
    }
}