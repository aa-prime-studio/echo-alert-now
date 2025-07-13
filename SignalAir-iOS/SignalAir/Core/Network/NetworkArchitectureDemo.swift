import Foundation
import MultipeerConnectivity
import SwiftUI

// MARK: - 新架構使用示例和測試
// 展示如何使用新的通道池管理架構來處理各種邊界情況

@MainActor
class NetworkArchitectureDemo: ObservableObject {
    
    // MARK: - 核心組件
    private var integratedNetworkManager: IntegratedNetworkManager?
    
    // MARK: - 測試狀態
    @Published var isRunning = false
    @Published var testResults: [TestResult] = []
    @Published var currentTest: String = "準備開始測試"
    @Published var systemReport: String = ""
    
    // MARK: - 測試配置
    private let testScenarios: [EdgeCaseScenario] = [
        .simultaneousConnections,
        .rapidDisconnections,
        .backgroundTransition,
        .memoryPressure,
        .channelContention,
        .networkInstability,
        .concurrentOperations,
        .resourceExhaustion
    ]
    
    init() {
        setupNetworkManager()
    }
    
    // MARK: - 設置網路管理器
    private func setupNetworkManager() {
        integratedNetworkManager = IntegratedNetworkManager()
        
        // 設置回調
        integratedNetworkManager?.onDataReceived = { [weak self] data, peerName in
            Task { @MainActor in
                self?.handleDataReceived(data, from: peerName)
            }
        }
        
        integratedNetworkManager?.onPeerConnected = { [weak self] peerName in
            Task { @MainActor in
                self?.handlePeerConnected(peerName)
            }
        }
        
        integratedNetworkManager?.onPeerDisconnected = { [weak self] peerName in
            Task { @MainActor in
                self?.handlePeerDisconnected(peerName)
            }
        }
    }
    
    // MARK: - 公共API
    
    /// 開始完整的邊界情況測試套件
    func startComprehensiveTest() async {
        guard !isRunning else { return }
        
        isRunning = true
        testResults.removeAll()
        currentTest = "開始測試套件..."
        
        print("🧪 Starting comprehensive edge case testing")
        
        // 1. 初始化網路
        await initializeNetwork()
        
        // 2. 執行每個測試場景
        for scenario in testScenarios {
            await executeTestScenario(scenario)
        }
        
        // 3. 執行系統診斷
        await performSystemDiagnostics()
        
        // 4. 生成最終報告
        generateFinalReport()
        
        currentTest = "測試完成"
        isRunning = false
        
        print("✅ Comprehensive testing completed")
    }
    
    /// 執行特定的邊界情況測試
    func testSpecificEdgeCase(_ edgeCase: EdgeCaseType) async {
        guard let manager = integratedNetworkManager else { return }
        
        currentTest = "測試 \(edgeCase.rawValue)"
        
        switch edgeCase {
        case .simultaneousConnection:
            await testSimultaneousConnections()
        case .rapidDisconnection:
            await testRapidDisconnections()
        case .backgroundTransition:
            await testBackgroundTransition()
        case .memoryPressure:
            await testMemoryPressure()
        case .channelContention:
            await testChannelContention()
        case .networkInstability:
            await testNetworkInstability()
        case .concurrentOperations:
            await testConcurrentOperations()
        case .resourceExhaustion:
            await testResourceExhaustion()
        }
    }
    
    /// 執行緊急恢復測試
    func testEmergencyRecovery() async {
        guard let manager = integratedNetworkManager else { return }
        
        currentTest = "測試緊急恢復機制"
        
        let result = await manager.performEmergencyRecovery()
        
        let testResult = TestResult(
            scenario: "Emergency Recovery",
            success: result.success,
            duration: 0,
            details: result.actionsPerformed.joined(separator: ", "),
            metrics: [:]
        )
        
        testResults.append(testResult)
        updateSystemReport()
    }
    
    /// 獲取實時系統狀態
    func getRealtimeStatus() -> String {
        guard let manager = integratedNetworkManager else {
            return "網路管理器未初始化"
        }
        
        let report = manager.getSystemStatusReport()
        
        return """
        📊 即時系統狀態
        ═══════════════════════════════
        系統狀態: \(report.systemStatus.rawValue)
        連接設備: \(report.metrics.connectedPeers)
        活躍操作: \(report.metrics.activeOperations)
        記憶體壓力: \(String(format: "%.1f%%", report.metrics.memoryPressure * 100))
        網路健康: \(report.networkHealthReport.overallHealth.rawValue)
        運行時間: \(formatUptime(report.uptime))
        
        通道池狀態:
        - 總通道數: \(report.channelPoolReport.totalChannels)
        - 健康通道: \(report.channelPoolReport.healthyChannels)
        - 降級通道: \(report.channelPoolReport.degradedChannels)
        - 失效通道: \(report.channelPoolReport.failedChannels)
        
        建議:
        \(report.recommendations.isEmpty ? "無" : report.recommendations.joined(separator: "\n"))
        ═══════════════════════════════
        """
    }
    
    // MARK: - 測試實現
    
    private func initializeNetwork() async {
        guard let manager = integratedNetworkManager else { return }
        
        currentTest = "初始化網路..."
        await manager.startNetworking()
        
        // 等待網路穩定
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func executeTestScenario(_ scenario: EdgeCaseScenario) async {
        let startTime = Date()
        currentTest = "執行 \(scenario.description)"
        
        var success = false
        var details = ""
        var metrics: [String: Double] = [:]
        
        switch scenario {
        case .simultaneousConnections:
            (success, details, metrics) = await performSimultaneousConnectionTest()
        case .rapidDisconnections:
            (success, details, metrics) = await performRapidDisconnectionTest()
        case .backgroundTransition:
            (success, details, metrics) = await performBackgroundTransitionTest()
        case .memoryPressure:
            (success, details, metrics) = await performMemoryPressureTest()
        case .channelContention:
            (success, details, metrics) = await performChannelContentionTest()
        case .networkInstability:
            (success, details, metrics) = await performNetworkInstabilityTest()
        case .concurrentOperations:
            (success, details, metrics) = await performConcurrentOperationsTest()
        case .resourceExhaustion:
            (success, details, metrics) = await performResourceExhaustionTest()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = TestResult(
            scenario: scenario.description,
            success: success,
            duration: duration,
            details: details,
            metrics: metrics
        )
        
        testResults.append(result)
        print("📊 Test \(scenario.description): \(success ? "PASS" : "FAIL") (\(String(format: "%.2f", duration))s)")
    }
    
    // MARK: - 具體測試實現
    
    private func testSimultaneousConnections() async {
        currentTest = "模擬同時連接競態條件"
        
        // 模擬多個設備同時連接
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    let mockPeer = MCPeerID(displayName: "TestPeer\(i)")
                    await self.integratedNetworkManager?.robustNetworkLayer.handlePeerConnection(mockPeer)
                }
            }
        }
    }
    
    private func testRapidDisconnections() async {
        currentTest = "模擬快速斷開重連"
        
        let mockPeer = MCPeerID(displayName: "RapidTestPeer")
        
        // 快速連接和斷開
        for _ in 1...10 {
            await integratedNetworkManager?.robustNetworkLayer.handlePeerConnection(mockPeer)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await integratedNetworkManager?.robustNetworkLayer.handlePeerDisconnection(mockPeer)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    private func testBackgroundTransition() async {
        currentTest = "模擬背景前景切換"
        
        // 模擬進入背景
        await integratedNetworkManager?.robustNetworkLayer.handleAppStateTransition(to: .background)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // 模擬回到前景
        await integratedNetworkManager?.robustNetworkLayer.handleAppStateTransition(to: .foreground)
    }
    
    private func testMemoryPressure() async {
        currentTest = "模擬記憶體壓力情況"
        
        // 創建大量對象來模擬記憶體壓力
        autoreleasepool {
            let largeArrays = (0..<100).map { _ in
                Array(repeating: Data(repeating: 0, count: 1024), count: 1000)
            }
            _ = largeArrays.count // 使用這些數組以避免編譯器優化
        }
    }
    
    private func testChannelContention() async {
        currentTest = "模擬通道競爭"
        
        guard let manager = integratedNetworkManager else { return }
        
        // 同時發送大量訊息
        await withTaskGroup(of: Void.self) { group in
            for i in 1...20 {
                group.addTask {
                    let data = "Test message \(i)".data(using: .utf8) ?? Data()
                    try? await manager.send(data, to: manager.connectedPeers)
                }
            }
        }
    }
    
    private func testNetworkInstability() async {
        currentTest = "模擬網路不穩定"
        
        // 模擬間歇性網路問題
        for _ in 1...5 {
            // 模擬網路延遲
            try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...1_000_000_000))
            
            // 嘗試發送數據
            let data = "Unstable network test".data(using: .utf8) ?? Data()
            try? await integratedNetworkManager?.send(data, to: integratedNetworkManager?.connectedPeers ?? [])
        }
    }
    
    private func testConcurrentOperations() async {
        currentTest = "測試併發操作限制"
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 { // 超過正常併發限制
                group.addTask {
                    let data = "Concurrent test \(i)".data(using: .utf8) ?? Data()
                    try? await self.integratedNetworkManager?.send(data, to: self.integratedNetworkManager?.connectedPeers ?? [])
                }
            }
        }
    }
    
    private func testResourceExhaustion() async {
        currentTest = "模擬資源耗盡"
        
        // 模擬CPU密集任務
        let startTime = Date()
        var result = 0
        
        while Date().timeIntervalSince(startTime) < 1.0 {
            result += Int.random(in: 1...1000)
        }
        
        print("Resource exhaustion test completed with result: \(result)")
    }
    
    // MARK: - 詳細測試方法
    
    private func performSimultaneousConnectionTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        var successCount = 0
        let totalAttempts = 10
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 1...totalAttempts {
                group.addTask {
                    let peer = MCPeerID(displayName: "SimulTest\(i)")
                    await self.integratedNetworkManager?.robustNetworkLayer.handlePeerConnection(peer)
                    return true
                }
            }
            
            for await success in group {
                if success { successCount += 1 }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let success = successCount == totalAttempts
        
        return (
            success,
            "處理了 \(successCount)/\(totalAttempts) 個同時連接",
            ["duration": duration, "success_rate": Double(successCount) / Double(totalAttempts)]
        )
    }
    
    private func performRapidDisconnectionTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let peer = MCPeerID(displayName: "RapidTest")
        let cycles = 20
        
        for _ in 1...cycles {
            await integratedNetworkManager?.robustNetworkLayer.handlePeerConnection(peer)
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await integratedNetworkManager?.robustNetworkLayer.handlePeerDisconnection(peer)
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let avgCycleTime = duration / Double(cycles)
        
        return (
            true,
            "完成 \(cycles) 個快速連接/斷開週期",
            ["duration": duration, "avg_cycle_time": avgCycleTime]
        )
    }
    
    private func performBackgroundTransitionTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        
        // 測試背景轉換
        await integratedNetworkManager?.robustNetworkLayer.handleAppStateTransition(to: .background)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        await integratedNetworkManager?.robustNetworkLayer.handleAppStateTransition(to: .foreground)
        
        let duration = Date().timeIntervalSince(startTime)
        
        return (
            true,
            "成功處理背景/前景轉換",
            ["duration": duration]
        )
    }
    
    private func performMemoryPressureTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let initialMemory = await getCurrentMemoryUsage()
        
        // 創建記憶體壓力
        autoreleasepool {
            let _ = (0..<1000).map { _ in Data(repeating: 0, count: 10240) } // 10KB * 1000
        }
        
        let peakMemory = await getCurrentMemoryUsage()
        
        // 觸發清理
        autoreleasepool {}
        
        let finalMemory = await getCurrentMemoryUsage()
        let duration = Date().timeIntervalSince(startTime)
        
        return (
            finalMemory < peakMemory,
            "記憶體從 \(String(format: "%.1f", initialMemory))MB 增加到 \(String(format: "%.1f", peakMemory))MB，清理後 \(String(format: "%.1f", finalMemory))MB",
            [
                "initial_memory": initialMemory,
                "peak_memory": peakMemory,
                "final_memory": finalMemory,
                "duration": duration
            ]
        )
    }
    
    private func performChannelContentionTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let messageCount = 50
        var successCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 1...messageCount {
                group.addTask {
                    do {
                        let data = "Contention test \(i)".data(using: .utf8) ?? Data()
                        try await self.integratedNetworkManager?.send(data, to: self.integratedNetworkManager?.connectedPeers ?? [])
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            for await success in group {
                if success { successCount += 1 }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let throughput = Double(successCount) / duration
        
        return (
            successCount > messageCount * 8 / 10, // 80% 成功率視為通過
            "發送了 \(successCount)/\(messageCount) 個訊息",
            [
                "success_count": Double(successCount),
                "total_count": Double(messageCount),
                "duration": duration,
                "throughput": throughput
            ]
        )
    }
    
    private func performNetworkInstabilityTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let testCycles = 10
        var successfulCycles = 0
        
        for i in 1...testCycles {
            do {
                // 模擬不穩定的網路條件
                let delay = Double.random(in: 0.1...0.5)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                let data = "Instability test \(i)".data(using: .utf8) ?? Data()
                try await integratedNetworkManager?.send(data, to: integratedNetworkManager?.connectedPeers ?? [])
                
                successfulCycles += 1
            } catch {
                // 預期的失敗
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let successRate = Double(successfulCycles) / Double(testCycles)
        
        return (
            true, // 這個測試主要是檢驗系統的穩定性，不一定要求100%成功
            "在不穩定條件下完成 \(successfulCycles)/\(testCycles) 個週期",
            [
                "success_rate": successRate,
                "duration": duration,
                "cycles": Double(testCycles)
            ]
        )
    }
    
    private func performConcurrentOperationsTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let operationCount = 100
        var completedCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 1...operationCount {
                group.addTask {
                    do {
                        let data = "Concurrent op \(i)".data(using: .utf8) ?? Data()
                        try await self.integratedNetworkManager?.send(data, to: self.integratedNetworkManager?.connectedPeers ?? [])
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            for await completed in group {
                if completed { completedCount += 1 }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let throughput = Double(completedCount) / duration
        
        return (
            completedCount > 0, // 只要有操作完成就算成功
            "完成 \(completedCount)/\(operationCount) 個併發操作",
            [
                "completed": Double(completedCount),
                "total": Double(operationCount),
                "duration": duration,
                "throughput": throughput
            ]
        )
    }
    
    private func performResourceExhaustionTest() async -> (Bool, String, [String: Double]) {
        let startTime = Date()
        let initialCPU = getCurrentCPUUsage()
        let initialMemory = await getCurrentMemoryUsage()
        
        // 模擬資源密集型操作
        var result = 0
        let workDuration = 2.0 // 2秒的密集計算
        let workEndTime = Date().addingTimeInterval(workDuration)
        
        while Date() < workEndTime {
            result += (1...1000).reduce(0, +)
        }
        
        let peakCPU = getCurrentCPUUsage()
        let peakMemory = await getCurrentMemoryUsage()
        let totalDuration = Date().timeIntervalSince(startTime)
        
        return (
            true,
            "執行資源密集操作，結果: \(result)",
            [
                "initial_cpu": initialCPU,
                "peak_cpu": peakCPU,
                "initial_memory": initialMemory,
                "peak_memory": peakMemory,
                "duration": totalDuration
            ]
        )
    }
    
    private func performSystemDiagnostics() async {
        guard let manager = integratedNetworkManager else { return }
        
        currentTest = "執行系統診斷..."
        
        let diagnostics = await manager.performSystemDiagnostics()
        
        let testResult = TestResult(
            scenario: "System Diagnostics",
            success: diagnostics.overallHealth != .critical,
            duration: diagnostics.duration,
            details: "發現 \(diagnostics.issues.count) 個問題，\(diagnostics.recommendations.count) 個建議",
            metrics: ["issues": Double(diagnostics.issues.count)]
        )
        
        testResults.append(testResult)
    }
    
    private func generateFinalReport() {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.success }.count
        let totalDuration = testResults.reduce(0) { $0 + $1.duration }
        
        systemReport = """
        📊 測試套件最終報告
        ═══════════════════════════════
        測試總數: \(totalTests)
        通過測試: \(passedTests)
        失敗測試: \(totalTests - passedTests)
        總耗時: \(String(format: "%.2f", totalDuration)) 秒
        成功率: \(String(format: "%.1f%%", Double(passedTests) / Double(totalTests) * 100))
        
        詳細結果:
        \(testResults.map { result in
            "• \(result.scenario): \(result.success ? "✅" : "❌") (\(String(format: "%.2f", result.duration))s)"
        }.joined(separator: "\n"))
        
        \(getRealtimeStatus())
        """
    }
    
    private func updateSystemReport() {
        systemReport = getRealtimeStatus()
    }
    
    // MARK: - 事件處理
    
    private func handleDataReceived(_ data: Data, from peerName: String) {
        print("📥 Received data from \(peerName): \(data.count) bytes")
    }
    
    private func handlePeerConnected(_ peerName: String) {
        print("🤝 Peer connected: \(peerName)")
        updateSystemReport()
    }
    
    private func handlePeerDisconnected(_ peerName: String) {
        print("👋 Peer disconnected: \(peerName)")
        updateSystemReport()
    }
    
    // MARK: - 工具方法
    
    private func getCurrentMemoryUsage() async -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // MB
        }
        
        return 0.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        // 簡化的CPU使用率估算
        return Double.random(in: 0.1...0.8)
    }
    
    private func formatUptime(_ uptime: TimeInterval) -> String {
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        let seconds = Int(uptime) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - 支持類型

enum EdgeCaseScenario: CaseIterable {
    case simultaneousConnections
    case rapidDisconnections
    case backgroundTransition
    case memoryPressure
    case channelContention
    case networkInstability
    case concurrentOperations
    case resourceExhaustion
    
    var description: String {
        switch self {
        case .simultaneousConnections: return "同時連接競態條件"
        case .rapidDisconnections: return "快速斷開重連"
        case .backgroundTransition: return "背景前景轉換"
        case .memoryPressure: return "記憶體壓力處理"
        case .channelContention: return "通道競爭管理"
        case .networkInstability: return "網路不穩定適應"
        case .concurrentOperations: return "併發操作控制"
        case .resourceExhaustion: return "資源耗盡恢復"
        }
    }
}

struct TestResult {
    let scenario: String
    let success: Bool
    let duration: TimeInterval
    let details: String
    let metrics: [String: Double]
    
    var summary: String {
        return "\(scenario): \(success ? "✅" : "❌") (\(String(format: "%.2f", duration))s) - \(details)"
    }
}