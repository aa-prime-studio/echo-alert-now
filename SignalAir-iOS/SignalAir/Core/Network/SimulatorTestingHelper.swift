import Foundation
import Network

/// 模擬器測試輔助工具
/// 用於在模擬器環境下模擬 P2P 網路連接
class SimulatorTestingHelper {
    
    static let shared = SimulatorTestingHelper()
    
    private init() {}
    
    /// 檢查是否運行在模擬器
    static var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// 模擬設備列表
    private var simulatedDevices: [SimulatedDevice] = []
    
    /// 模擬設備結構
    struct SimulatedDevice {
        let id: String
        let name: String
        let isAvailable: Bool
        let lastSeen: Date
    }
    
    /// 初始化模擬器測試環境
    func setupSimulatorTestEnvironment() {
        guard Self.isRunningOnSimulator else { return }
        
        // 創建模擬的附近設備
        simulatedDevices = [
            SimulatedDevice(id: "sim-device-1", name: "煎餅-TEST1", isAvailable: true, lastSeen: Date()),
            SimulatedDevice(id: "sim-device-2", name: "湯圓-TEST2", isAvailable: true, lastSeen: Date()),
            SimulatedDevice(id: "sim-device-3", name: "月餅-TEST3", isAvailable: false, lastSeen: Date().addingTimeInterval(-60))
        ]
        
        print("🧪 模擬器測試環境已設置，模擬設備數: \(simulatedDevices.count)")
    }
    
    /// 模擬發現附近設備
    func simulateDeviceDiscovery() -> [SimulatedDevice] {
        guard Self.isRunningOnSimulator else { return [] }
        
        // 模擬設備發現的隨機性
        let availableDevices = simulatedDevices.filter { $0.isAvailable }
        let visibleCount = Int.random(in: 0...availableDevices.count)
        
        let visibleDevices = Array(availableDevices.prefix(visibleCount))
        
        if !visibleDevices.isEmpty {
            print("📡 模擬器發現 \(visibleDevices.count) 個設備: \(visibleDevices.map { $0.name })")
        }
        
        return visibleDevices
    }
    
    /// 模擬發送訊息到模擬設備
    func simulateMessageSend(to deviceId: String, message: Data) -> Bool {
        guard Self.isRunningOnSimulator else { return false }
        
        if let device = simulatedDevices.first(where: { $0.id == deviceId && $0.isAvailable }) {
            print("📤 模擬發送訊息到 \(device.name): \(message.count) bytes")
            
            // 模擬回應
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.simulateMessageReceive(from: device, originalMessage: message)
            }
            
            return true
        }
        
        return false
    }
    
    /// 模擬接收訊息
    private func simulateMessageReceive(from device: SimulatedDevice, originalMessage: Data) {
        // 模擬回應訊息
        let responseData = "ACK from \(device.name)".data(using: .utf8) ?? Data()
        
        print("📥 模擬接收來自 \(device.name) 的回應: \(responseData.count) bytes")
        
        // 通知網路服務有新訊息
        NotificationCenter.default.post(
            name: .simulatorMessageReceived,
            object: nil,
            userInfo: [
                "deviceId": device.id,
                "deviceName": device.name,
                "message": responseData
            ]
        )
    }
    
    /// 模擬異步處理測試
    func simulateAsyncTrustScoreUpdates() {
        guard Self.isRunningOnSimulator else { return }
        
        print("🧪 開始模擬異步信任評分更新測試...")
        
        // 模擬多個設備的信任評分更新
        let deviceIds = simulatedDevices.map { $0.id }
        
        for (index, deviceId) in deviceIds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                // 模擬成功通訊
                if index % 2 == 0 {
                    NotificationCenter.default.post(
                        name: .simulatorTrustScoreUpdate,
                        object: nil,
                        userInfo: [
                            "deviceId": deviceId,
                            "action": "success",
                            "increment": 1.0
                        ]
                    )
                } else {
                    // 模擬可疑行為
                    NotificationCenter.default.post(
                        name: .simulatorTrustScoreUpdate,
                        object: nil,
                        userInfo: [
                            "deviceId": deviceId,
                            "action": "suspicious",
                            "decrement": 2.0
                        ]
                    )
                }
            }
        }
    }
    
    /// 創建模擬器測試面板
    func createTestControlPanel() -> SimulatorTestControlPanel {
        return SimulatorTestControlPanel()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let simulatorMessageReceived = Notification.Name("simulatorMessageReceived")
    static let simulatorTrustScoreUpdate = Notification.Name("simulatorTrustScoreUpdate")
    static let simulatorDeviceDiscovered = Notification.Name("simulatorDeviceDiscovered")
}

// MARK: - 模擬器測試控制面板
import SwiftUI

struct SimulatorTestControlPanel: View {
    @State private var isTestingActive = false
    @State private var messageCount = 0
    @State private var discoveredDevices: [SimulatorTestingHelper.SimulatedDevice] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 模擬器測試控制面板")
                .font(.title2)
                .fontWeight(.bold)
            
            if SimulatorTestingHelper.isRunningOnSimulator {
                VStack(spacing: 15) {
                    // 設備發現測試
                    Button("📡 模擬設備發現") {
                        discoveredDevices = SimulatorTestingHelper.shared.simulateDeviceDiscovery()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 訊息發送測試
                    Button("📤 模擬訊息發送") {
                        let testMessage = "Test message \(Date())".data(using: .utf8) ?? Data()
                        let success = SimulatorTestingHelper.shared.simulateMessageSend(
                            to: "sim-device-1",
                            message: testMessage
                        )
                        if success {
                            messageCount += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 異步處理測試
                    Button("⚡ 測試異步信任評分") {
                        SimulatorTestingHelper.shared.simulateAsyncTrustScoreUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 統計顯示
                    VStack(alignment: .leading, spacing: 8) {
                        Text("測試統計:")
                            .font(.headline)
                        
                        Text("發現設備: \(discoveredDevices.count)")
                        Text("發送訊息: \(messageCount)")
                        
                        if !discoveredDevices.isEmpty {
                            Text("設備列表:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(discoveredDevices, id: \.id) { device in
                                Text("• \(device.name)")
                                    .font(.caption)
                                    .foregroundColor(device.isAvailable ? .green : .red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } else {
                Text("⚠️ 此面板僅在模擬器中可用")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .onAppear {
            SimulatorTestingHelper.shared.setupSimulatorTestEnvironment()
        }
    }
}

#Preview {
    SimulatorTestControlPanel()
}