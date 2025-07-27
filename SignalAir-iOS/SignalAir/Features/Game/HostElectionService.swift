import Foundation
import Combine

/// 主機選舉服務 - 負責主機選舉和管理邏輯
@MainActor
class HostElectionService: HostElectionServiceProtocol, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isHost: Bool = false
    @Published private(set) var currentHost: String?
    @Published private(set) var hostElectionInProgress: Bool = false
    
    // MARK: - Dependencies
    
    private let networkManager: BingoNetworkManagerProtocol
    private let deviceName: String
    
    // MARK: - Private Properties
    
    private var hostHeartbeatTimer: Timer?
    private var hostTimeouts: [String: Date] = [:]
    private let hostTimeoutDuration: TimeInterval = 15.0
    private var electionCandidates: Set<String> = []
    
    // MARK: - Publishers
    
    var isHostPublisher: AnyPublisher<Bool, Never> {
        $isHost.eraseToAnyPublisher()
    }
    
    var currentHostPublisher: AnyPublisher<String?, Never> {
        $currentHost.eraseToAnyPublisher()
    }
    
    var hostElectionProgressPublisher: AnyPublisher<Bool, Never> {
        $hostElectionInProgress.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(networkManager: BingoNetworkManagerProtocol, deviceName: String) {
        self.networkManager = networkManager
        self.deviceName = deviceName
        
        print("🗳️ HostElectionService: 初始化完成")
    }
    
    // MARK: - Host Election
    
    /// 開始主機選舉
    func startHostElection() {
        print("🗳️ HostElectionService: 開始主機選舉")
        
        hostElectionInProgress = true
        electionCandidates = Set(networkManager.connectedPeers)
        electionCandidates.insert(deviceName)
        
        // 【NEW】使用確定性算法選擇主機
        let selectedHost = selectHostDeterministically(from: Array(electionCandidates))
        
        if selectedHost == deviceName {
            print("🗳️ HostElectionService: 被選為主機")
            becomeHost()
        } else {
            print("🗳️ HostElectionService: \(selectedHost) 被選為主機")
            currentHost = selectedHost
            isHost = false
        }
        
        hostElectionInProgress = false
        
        // 廣播選舉開始
        Task {
            do {
                let electionData = "start_election".data(using: .utf8) ?? Data()
                try await networkManager.broadcastGameAction(
                    type: .keyExchangeRequest, // 使用現有類型
                    data: electionData,
                    priority: .high
                )
            } catch {
                print("❌ HostElectionService: 廣播選舉失敗 - \(error)")
            }
        }
        
        // 延遲進行選舉
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.performElection()
        }
    }
    
    /// 執行選舉
    private func performElection() {
        guard let electedHost = electHost(from: Array(electionCandidates)) else {
            print("❌ HostElectionService: 選舉失敗")
            hostElectionInProgress = false
            return
        }
        
        currentHost = electedHost
        isHost = (electedHost == deviceName)
        hostElectionInProgress = false
        
        print("🗳️ HostElectionService: 選舉完成 - 主機: \(electedHost), 我是主機: \(isHost)")
        
        if isHost {
            startHostHeartbeat()
        }
    }
    
    /// 選舉主機
    func electHost(from candidates: [String]) -> String? {
        guard !candidates.isEmpty else { return nil }
        
        // 【FIX】使用確定性算法選舉主機 - 基於設備ID的字母順序
        // 所有設備都會選出相同的主機（字母順序最前的）
        let sortedCandidates = candidates.sorted()
        let electedHost = sortedCandidates.first!
        
        print("🗳️ HostElectionService: 選舉結果 - \(electedHost)")
        print("🗳️ HostElectionService: 候選人列表 - \(sortedCandidates)")
        print("🗳️ HostElectionService: 我的設備名稱 - \(deviceName)")
        
        return electedHost
    }
    
    /// 成為主機
    func becomeHost() {
        print("🗳️ HostElectionService: 成為主機")
        
        isHost = true
        currentHost = deviceName
        startHostHeartbeat()
        
        // 廣播主機身份
        Task {
            do {
                let hostData = deviceName.data(using: .utf8) ?? Data()
                try await networkManager.broadcastGameAction(
                    type: .keyExchangeResponse, // 使用現有類型
                    data: hostData,
                    priority: .high
                )
            } catch {
                print("❌ HostElectionService: 廣播主機身份失敗 - \(error)")
            }
        }
    }
    
    /// 辭去主機
    func resignAsHost() {
        print("🗳️ HostElectionService: 辭去主機")
        
        stopHostHeartbeat()
        isHost = false
        currentHost = nil
        
        // 觸發新的選舉
        startHostElection()
    }
    
    // MARK: - Host Heartbeat
    
    /// 開始主機心跳
    func startHostHeartbeat() {
        print("💓 HostElectionService: 開始主機心跳")
        
        stopHostHeartbeat()
        
        hostHeartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHostHeartbeat()
            }
        }
    }
    
    /// 停止主機心跳
    func stopHostHeartbeat() {
        hostHeartbeatTimer?.invalidate()
        hostHeartbeatTimer = nil
        print("💓 HostElectionService: 停止主機心跳")
    }
    
    /// 發送主機心跳
    private func sendHostHeartbeat() {
        guard isHost else { return }
        
        Task {
            do {
                let heartbeatData = "host_heartbeat".data(using: .utf8) ?? Data()
                try await networkManager.broadcastGameAction(
                    type: .heartbeat,
                    data: heartbeatData,
                    priority: .normal
                )
                print("💓 HostElectionService: 發送主機心跳")
            } catch {
                print("❌ HostElectionService: 發送心跳失敗 - \(error)")
            }
        }
    }
    
    /// 處理主機心跳
    func handleHostHeartbeat(from hostID: String) {
        print("💓 HostElectionService: 收到主機心跳 - \(hostID)")
        
        hostTimeouts[hostID] = Date()
        
        if currentHost != hostID {
            currentHost = hostID
            isHost = false
            stopHostHeartbeat()
        }
    }
    
    // MARK: - Host Management
    
    /// 處理主機斷線
    func handleHostDisconnected() {
        print("🗳️ HostElectionService: 主機斷線")
        
        guard let host = currentHost else { return }
        
        // 檢查主機是否真的斷線
        let lastHeartbeat = hostTimeouts[host] ?? Date.distantPast
        let timeSinceHeartbeat = Date().timeIntervalSince(lastHeartbeat)
        
        if timeSinceHeartbeat > hostTimeoutDuration {
            print("🗳️ HostElectionService: 確認主機斷線，開始重新選舉")
            currentHost = nil
            isHost = false
            stopHostHeartbeat()
            startHostElection()
        }
    }
    
    /// 遷移主機
    func migrateHost(to newHostID: String) {
        print("🗳️ HostElectionService: 遷移主機到 \(newHostID)")
        
        currentHost = newHostID
        isHost = (newHostID == deviceName)
        
        if isHost {
            startHostHeartbeat()
        } else {
            stopHostHeartbeat()
        }
    }
    
    // MARK: - Network Event Handling
    
    /// 處理網路連接變化
    func handleNetworkConnectionChanged() {
        // 當網路連接發生變化時，可能需要重新選舉
        if isHost && networkManager.connectedPeers.isEmpty {
            print("🗳️ HostElectionService: 網路斷開，辭去主機")
            resignAsHost()
        }
    }
    
    // MARK: - Deterministic Host Selection
    
    /// 【NEW】確定性主機選擇算法（對齊主線實現）
    func selectHostDeterministically(from candidates: [String]) -> String {
        print("🗳️ HostElectionService: 確定性選擇主機，候選人: \(candidates)")
        
        guard !candidates.isEmpty else {
            print("⚠️ HostElectionService: 無候選人，回到當前設備")
            return deviceName
        }
        
        // 【對齊主線】基於字母順序選擇主機（確定性算法）
        let sortedCandidates = candidates.sorted()
        let selectedHost = sortedCandidates.first!
        
        print("✅ HostElectionService: 確定性選擇結果: \(selectedHost)")
        return selectedHost
    }
    
    // MARK: - Lifecycle
    
    /// 清理資源
    func cleanup() {
        print("🧹 HostElectionService: 清理資源")
        
        stopHostHeartbeat()
        hostTimeouts.removeAll()
        electionCandidates.removeAll()
        hostElectionInProgress = false
        isHost = false
        currentHost = nil
    }
    
    deinit {
        print("🗑️ HostElectionService: deinit")
        // 在 deinit 中避免所有 MainActor 操作
    }
}