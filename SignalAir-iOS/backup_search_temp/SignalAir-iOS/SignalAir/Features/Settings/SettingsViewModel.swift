import Foundation
import Combine
import MultipeerConnectivity
import SwiftUI

// 設定 ViewModel - 管理應用程式設定
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userNickname: String = "使用者"
    @Published var broadcastRange: Double = 100.0
    @Published var autoAcceptConnections: Bool = true
    @Published var enableNotifications: Bool = true
    @Published var darkMode: Bool = false
    @Published var language: String = "zh-Hant"
    @Published var connectedPeers: [String] = []
    @Published var connectionHistory: [String] = []
    @Published var deviceID: String = ""
    @Published var connectionStatus: String = "未連線"
    @Published var connectedPeerCount: Int = 0
    @Published var isNetworkActive: Bool = false
    @Published var deviceIDStats: DeviceIDStats?
    
    // MARK: - Services
    private let temporaryIDManager: TemporaryIDManager
    private let networkService: NetworkService
    private let nicknameService: NicknameService
    
    // MARK: - Timer
    private var statusUpdateTimer: Timer?
    
    // MARK: - Initialization
    init(
        temporaryIDManager: TemporaryIDManager = TemporaryIDManager(),
        networkService: NetworkService = NetworkService(),
        nicknameService: NicknameService = NicknameService()
    ) {
        self.temporaryIDManager = temporaryIDManager
        self.networkService = networkService
        self.nicknameService = nicknameService
        
        loadSettings()
        setupBindings()
        setupInitialState()
        setupNetworkObservers()
        startStatusUpdates()
        
        print("⚙️ SettingsViewModel: 初始化完成")
    }
    
    deinit {
        statusUpdateTimer?.invalidate()
        removeNetworkObservers()
    }
    
    // MARK: - Public Methods
    
    /// 更新使用者暱稱
    func updateNickname(_ newNickname: String) {
        guard !newNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        userNickname = trimmedNickname
        
        // 使用 NicknameService 更新暱稱
        nicknameService.setNickname(trimmedNickname)
        
        print("⚙️ SettingsViewModel: 更新暱稱為: \(trimmedNickname)")
    }
    
    /// 強制更新裝置ID
    func forceUpdateDeviceID() {
        temporaryIDManager.forceUpdate()
        updateDeviceIDInfo()
        
        print("⚙️ SettingsViewModel: 強制更新裝置ID")
    }
    
    /// 開始網路連線
    func startNetworking() {
        networkService.startNetworking()
        isNetworkActive = true
        updateConnectionStatus()
        
        print("⚙️ SettingsViewModel: 啟動網路服務")
    }
    
    /// 停止網路連線
    func stopNetworking() {
        networkService.stopNetworking()
        isNetworkActive = false
        updateConnectionStatus()
        
        print("⚙️ SettingsViewModel: 停止網路服務")
    }
    
    /// 重新連線
    func reconnect() {
        stopNetworking()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startNetworking()
        }
        
        print("⚙️ SettingsViewModel: 重新連線")
    }
    
    /// 取得裝置ID剩餘時間字串
    func getDeviceIDTimeRemaining() -> String {
        guard let stats = deviceIDStats else { return "載入中..." }
        
        let hours = Int(stats.timeRemainingSeconds / 3600)
        let minutes = Int((stats.timeRemainingSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小時\(minutes)分鐘後更新"
        } else if minutes > 0 {
            return "\(minutes)分鐘後更新"
        } else {
            return "即將更新"
        }
    }
    
    /// 取得連線狀態描述
    func getConnectionStatusDescription() -> String {
        if !isNetworkActive {
            return "網路服務已停止"
        }
        
        switch connectionStatus {
        case "已連線":
            return "已連線 - \(connectedPeerCount) 個裝置"
        case "連線中":
            return "正在搜尋其他裝置..."
        default:
            return "未連線 - 正在搜尋"
        }
    }
    
    /// 取得連線狀態顏色
    func getConnectionStatusColor() -> Color {
        if !isNetworkActive {
            return .gray
        }
        
        switch connectionStatus {
        case "已連線":
            return .green
        case "連線中":
            return .orange
        default:
            return .red
        }
    }
    
    /// 檢查是否可以變更暱稱
    func canChangeNickname() -> Bool {
        return nicknameService.canChangeNickname()
    }
    
    /// 取得暱稱變更限制文字
    func getNicknameChangeText() -> String {
        return nicknameService.getRemainingChangesText()
    }
    
    // MARK: - Private Methods
    
    /// 設定初始狀態
    private func setupInitialState() {
        // 載入使用者暱稱
        userNickname = nicknameService.nickname
        
        // 更新裝置ID資訊
        updateDeviceIDInfo()
        
        // 更新連線狀態
        updateConnectionStatus()
    }
    
    /// 更新裝置ID資訊
    private func updateDeviceIDInfo() {
        deviceID = temporaryIDManager.deviceID
        deviceIDStats = temporaryIDManager.getDeviceIDStats()
    }
    
    /// 更新連線狀態
    private func updateConnectionStatus() {
        switch networkService.connectionStatus {
        case .connected:
            connectionStatus = "已連線"
        case .connecting:
            connectionStatus = "連線中"
        case .disconnected:
            connectionStatus = "未連線"
        }
        
        connectedPeers = networkService.connectedPeers.map { $0.displayName }
        connectedPeerCount = connectedPeers.count
    }
    
    /// 設定網路觀察者
    private func setupNetworkObservers() {
        // 監聽 peer 連線
        networkService.onPeerConnected = { [weak self] peer in
            DispatchQueue.main.async {
                self?.updateConnectionStatus()
                self?.notifyPeerConnected(peer.displayName)
            }
        }
        
        // 監聽 peer 斷線
        networkService.onPeerDisconnected = { [weak self] peer in
            DispatchQueue.main.async {
                self?.updateConnectionStatus()
                self?.notifyPeerDisconnected(peer.displayName)
            }
        }
    }
    
    /// 移除網路觀察者
    private func removeNetworkObservers() {
        networkService.onPeerConnected = nil
        networkService.onPeerDisconnected = nil
    }
    
    /// 開始定期更新狀態
    private func startStatusUpdates() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateConnectionStatus()
            self?.updateDeviceIDInfo()
        }
    }
    
    /// 通知 peer 連線
    private func notifyPeerConnected(_ peerName: String) {
        print("⚙️ SettingsViewModel: 裝置已連線 - \(peerName)")
        // 可以在這裡添加用戶通知
    }
    
    /// 通知 peer 斷線
    private func notifyPeerDisconnected(_ peerName: String) {
        print("⚙️ SettingsViewModel: 裝置已斷線 - \(peerName)")
        // 可以在這裡添加用戶通知
    }
}

// MARK: - 預覽支援

extension SettingsViewModel {
    /// 創建預覽用的範例資料
    static func preview() -> SettingsViewModel {
        let viewModel = SettingsViewModel()
        
        // 設定範例資料
        viewModel.userNickname = "測試使用者"
        viewModel.deviceID = "珍珠奶茶-42"
        viewModel.connectionStatus = "已連線"
        viewModel.connectedPeers = ["小明的iPhone", "小華的iPad"]
        viewModel.connectedPeerCount = 2
        viewModel.isNetworkActive = true
        
        return viewModel
    }
}

// MARK: - DeviceIDStats 結構（本地定義）

struct DeviceIDStats {
    let deviceID: String
    let createdAt: Date
    let nextUpdateTime: Date
    let updateCount: Int
    let timeRemainingSeconds: TimeInterval
} 