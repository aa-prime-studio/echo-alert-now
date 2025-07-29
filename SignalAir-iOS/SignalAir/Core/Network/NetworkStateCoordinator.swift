import Foundation
import Combine
import MultipeerConnectivity

// MARK: - 網絡連接狀態統一定義
enum NetworkConnectionState: String, CaseIterable {
    case disconnected = "disconnected"      // 完全斷線
    case connecting = "connecting"          // 正在連接
    case connected = "connected"            // 已連接但未就緒
    case ready = "ready"                   // 完全就緒（包含密鑰交換）
    case reconnecting = "reconnecting"      // 重新連接中
    case failed = "failed"                 // 連接失敗
    
    var isActive: Bool {
        return self == .connected || self == .ready
    }
    
    var canSendMessages: Bool {
        return self == .ready
    }
    
    var displayName: String {
        switch self {
        case .disconnected: return "離線"
        case .connecting: return "連接中"
        case .connected: return "已連接"
        case .ready: return "就緒"
        case .reconnecting: return "重新連接"
        case .failed: return "連接失敗"
        }
    }
}

// MARK: - 網絡層級定義
enum NetworkLayer: String, CaseIterable {
    case physical = "physical"      // 物理層 (NetworkService)
    case mesh = "mesh"             // 網格層 (MeshManager)
    case application = "application" // 應用層 (BingoNetworkManager)
    
    var priority: Int {
        switch self {
        case .physical: return 3      // 最高優先級
        case .mesh: return 2
        case .application: return 1   // 最低優先級
        }
    }
}

// MARK: - 網絡狀態報告
struct NetworkLayerState {
    let layer: NetworkLayer
    let state: NetworkConnectionState
    let peerCount: Int
    let lastUpdate: Date
    let metadata: [String: Any]
    
    init(layer: NetworkLayer, state: NetworkConnectionState, peerCount: Int = 0, metadata: [String: Any] = [:]) {
        self.layer = layer
        self.state = state
        self.peerCount = peerCount
        self.lastUpdate = Date()
        self.metadata = metadata
    }
}

// MARK: - 統一網絡狀態協調器
@MainActor
class NetworkStateCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NetworkStateCoordinator()
    
    // MARK: - Published Properties
    @Published private(set) var overallState: NetworkConnectionState = .disconnected
    @Published private(set) var layerStates: [NetworkLayer: NetworkLayerState] = [:]
    @Published private(set) var connectedPeers: Set<String> = []
    @Published private(set) var activePeerCount: Int = 0
    @Published private(set) var isStable: Bool = false
    @Published private(set) var lastStateChange: Date = Date()
    
    // MARK: - State Publishers
    private let stateChangeSubject = PassthroughSubject<NetworkConnectionState, Never>()
    private let layerStateSubject = PassthroughSubject<NetworkLayerState, Never>()
    
    var stateChanges: AnyPublisher<NetworkConnectionState, Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    var layerStateChanges: AnyPublisher<NetworkLayerState, Never> {
        layerStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Internal State
    private var stateHistory: [NetworkConnectionState] = []
    private let maxHistorySize = 10
    private var stabilityTimer: Timer?
    private let stabilityThreshold: TimeInterval = 5.0 // 5秒穩定才算真正穩定
    
    // MARK: - Thread-Safe State Access
    private let stateQueue = DispatchQueue(label: "com.signalair.networkstate", attributes: .concurrent)
    private var _internalStates: [NetworkLayer: NetworkLayerState] = [:]
    
    private var internalStates: [NetworkLayer: NetworkLayerState] {
        get {
            return stateQueue.sync { _internalStates }
        }
        set {
            stateQueue.async(flags: .barrier) { [weak self] in
                self?._internalStates = newValue
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupStabilityMonitoring()
        print("🔗 NetworkStateCoordinator: 初始化完成")
    }
    
    // MARK: - Public API - Layer State Reporting
    
    /// 報告層級狀態更新
    func reportLayerState(_ layer: NetworkLayer, state: NetworkConnectionState, peerCount: Int = 0, metadata: [String: Any] = [:]) {
        let layerState = NetworkLayerState(layer: layer, state: state, peerCount: peerCount, metadata: metadata)
        
        // 線程安全更新
        var currentStates = internalStates
        currentStates[layer] = layerState
        internalStates = currentStates
        
        // 主線程更新發布屬性
        layerStates[layer] = layerState
        
        // 重新計算整體狀態
        calculateOverallState()
        
        // 發布層級狀態變更
        layerStateSubject.send(layerState)
        
        print("🔗 NetworkStateCoordinator: \(layer.rawValue) 層報告狀態 \(state.rawValue) (對等體: \(peerCount))")
    }
    
    /// 報告對等體連接變更
    func reportPeerConnection(_ peerID: String, connected: Bool, layer: NetworkLayer) {
        if connected {
            connectedPeers.insert(peerID)
        } else {
            connectedPeers.remove(peerID)
        }
        
        activePeerCount = connectedPeers.count
        
        // 更新對應層級的對等體數量
        if let layerState = layerStates[layer] {
            let updatedState = NetworkLayerState(
                layer: layer,
                state: layerState.state,
                peerCount: connected ? layerState.peerCount + 1 : max(0, layerState.peerCount - 1),
                metadata: layerState.metadata
            )
            reportLayerState(layer, state: layerState.state, peerCount: updatedState.peerCount, metadata: layerState.metadata)
        }
        
        print("🔗 NetworkStateCoordinator: 對等體 \(peerID) \(connected ? "連接" : "斷開") (\(layer.rawValue) 層)")
    }
    
    // MARK: - State Calculation
    
    /// 計算整體網絡狀態（基於所有層級狀態）
    private func calculateOverallState() {
        let states = Array(layerStates.values)
        
        // 如果沒有任何層級報告，保持斷線狀態
        guard !states.isEmpty else {
            updateOverallState(.disconnected)
            return
        }
        
        // 按優先級排序層級狀態
        let sortedStates = states.sorted { $0.layer.priority > $1.layer.priority }
        
        // 檢查各層級狀態
        let physicalState = layerStates[.physical]?.state ?? .disconnected
        let meshState = layerStates[.mesh]?.state ?? .disconnected
        let applicationState = layerStates[.application]?.state ?? .disconnected
        
        let newState: NetworkConnectionState
        
        // 狀態計算邏輯：必須所有層級都正常才算正常
        if physicalState == .failed || meshState == .failed || applicationState == .failed {
            newState = .failed
        } else if physicalState == .reconnecting || meshState == .reconnecting || applicationState == .reconnecting {
            newState = .reconnecting
        } else if physicalState == .connecting || meshState == .connecting || applicationState == .connecting {
            newState = .connecting
        } else if physicalState == .ready && meshState == .ready && applicationState == .ready {
            newState = .ready
        } else if physicalState.isActive && meshState.isActive && applicationState.isActive {
            newState = .connected
        } else {
            newState = .disconnected
        }
        
        updateOverallState(newState)
    }
    
    /// 更新整體狀態
    private func updateOverallState(_ newState: NetworkConnectionState) {
        guard newState != overallState else { return }
        
        let previousState = overallState
        overallState = newState
        lastStateChange = Date()
        
        // 更新狀態歷史
        stateHistory.append(newState)
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
        }
        
        // 重置穩定性計時器
        resetStabilityTimer()
        
        // 發布狀態變更
        stateChangeSubject.send(newState)
        
        print("🔗 NetworkStateCoordinator: 整體狀態變更 \(previousState.rawValue) → \(newState.rawValue)")
    }
    
    // MARK: - Stability Monitoring
    
    /// 設置穩定性監控
    private func setupStabilityMonitoring() {
        // 穩定性檢查將在狀態變更時重置
    }
    
    /// 重置穩定性計時器
    private func resetStabilityTimer() {
        stabilityTimer?.invalidate()
        isStable = false
        
        stabilityTimer = Timer.scheduledTimer(withTimeInterval: stabilityThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.markAsStable()
            }
        }
    }
    
    /// 標記為穩定狀態
    private func markAsStable() {
        isStable = true
        print("🔗 NetworkStateCoordinator: 網絡狀態已穩定 (\(overallState.rawValue))")
    }
    
    // MARK: - State Query API
    
    /// 檢查是否可以發送消息
    func canSendMessages() -> Bool {
        return overallState.canSendMessages && isStable
    }
    
    /// 檢查網絡是否活躍
    func isNetworkActive() -> Bool {
        return overallState.isActive
    }
    
    /// 獲取特定層級狀態
    func getLayerState(_ layer: NetworkLayer) -> NetworkLayerState? {
        return layerStates[layer]
    }
    
    /// 獲取所有層級狀態摘要
    func getStatesSummary() -> [String: String] {
        var summary: [String: String] = [:]
        summary["overall"] = overallState.rawValue
        summary["stable"] = isStable ? "yes" : "no"
        summary["peerCount"] = "\(activePeerCount)"
        
        for (layer, state) in layerStates {
            summary[layer.rawValue] = state.state.rawValue
        }
        
        return summary
    }
    
    /// 獲取狀態歷史
    func getStateHistory() -> [NetworkConnectionState] {
        return stateHistory
    }
    
    // MARK: - Recovery API
    
    /// 觸發網絡恢復
    func triggerNetworkRecovery() {
        print("🔗 NetworkStateCoordinator: 觸發網絡恢復程序")
        
        // 通知所有層級進行恢復
        NotificationCenter.default.post(
            name: NSNotification.Name("NetworkRecoveryTriggered"),
            object: nil,
            userInfo: [
                "trigger": "NetworkStateCoordinator",
                "timestamp": Date()
            ]
        )
        
        // 重置狀態為重新連接中
        updateOverallState(.reconnecting)
    }
    
    /// 強制同步所有層級狀態
    func forceSyncAllLayers() {
        print("🔗 NetworkStateCoordinator: 強制同步所有層級狀態")
        
        // 通知各層級報告當前狀態
        NotificationCenter.default.post(
            name: NSNotification.Name("NetworkStateSyncRequested"),
            object: nil
        )
    }
    
    // MARK: - Debugging
    
    /// 診斷網絡狀態
    func diagnoseNetworkState() -> String {
        var diagnosis = "🔍 NetworkStateCoordinator 診斷報告\n"
        diagnosis += "整體狀態: \(overallState.displayName) (\(overallState.rawValue))\n"
        diagnosis += "穩定性: \(isStable ? "穩定" : "不穩定")\n"
        diagnosis += "連接對等體數: \(activePeerCount)\n"
        diagnosis += "最後狀態變更: \(lastStateChange)\n\n"
        
        diagnosis += "各層級狀態:\n"
        for layer in NetworkLayer.allCases.sorted(by: { $0.priority > $1.priority }) {
            if let state = layerStates[layer] {
                diagnosis += "  \(layer.rawValue): \(state.state.displayName) (對等體: \(state.peerCount))\n"
            } else {
                diagnosis += "  \(layer.rawValue): 未報告\n"
            }
        }
        
        if !stateHistory.isEmpty {
            diagnosis += "\n狀態歷史: "
            diagnosis += stateHistory.map { $0.rawValue }.joined(separator: " → ")
        }
        
        return diagnosis
    }
    
    // MARK: - Cleanup
    deinit {
        stabilityTimer?.invalidate()
        print("🔗 NetworkStateCoordinator: 已清理")
    }
}

// MARK: - Convenience Extensions
extension NetworkStateCoordinator {
    
    /// 快速報告物理層狀態
    func reportPhysicalLayerState(_ state: NetworkConnectionState, peerCount: Int = 0) {
        reportLayerState(.physical, state: state, peerCount: peerCount)
    }
    
    /// 快速報告網格層狀態
    func reportMeshLayerState(_ state: NetworkConnectionState, peerCount: Int = 0) {
        reportLayerState(.mesh, state: state, peerCount: peerCount)
    }
    
    /// 快速報告應用層狀態
    func reportApplicationLayerState(_ state: NetworkConnectionState, peerCount: Int = 0) {
        reportLayerState(.application, state: state, peerCount: peerCount)
    }
}

// MARK: - Integration Helper
extension NetworkStateCoordinator {
    
    /// 集成到現有服務的輔助方法
    func integrateWithNetworkService(_ networkService: NetworkServiceProtocol) {
        // 這將在後續的集成中實現
        print("🔗 NetworkStateCoordinator: 準備集成 NetworkService")
    }
    
    func integrateWithMeshManager(_ meshManager: MeshManager) {
        // 這將在後續的集成中實現
        print("🔗 NetworkStateCoordinator: 準備集成 MeshManager")
    }
    
    func integrateWithBingoNetworkManager(_ bingoNetworkManager: BingoNetworkManager) {
        // 這將在後續的集成中實現
        print("🔗 NetworkStateCoordinator: 準備集成 BingoNetworkManager")
    }
}