import Foundation
import Combine

class LocalAnalyticsManager: ObservableObject {
    static let shared = LocalAnalyticsManager()
    
    @Published var stats = LocalStatistics()
    @Published var isEnabled = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadStats()
        startPeriodicSave()
    }
    
    // 網路效能記錄
    func recordNetworkLatency(_ latency: TimeInterval) {
        guard isEnabled else { return }
        stats.recordLatency(latency)
        saveStats()
    }
    
    func recordConnectionSuccess(_ success: Bool) {
        guard isEnabled else { return }
        stats.recordConnection(success)
        saveStats()
    }
    
    func recordRouteQuery() {
        guard isEnabled else { return }
        stats.totalRouteQueries += 1
        saveStats()
    }
    
    // 訊息統計記錄
    func recordMessageSent(_ isEmergency: Bool = false) {
        guard isEnabled else { return }
        stats.messagesSent += 1
        if isEmergency {
            stats.emergencyMessages += 1
        }
        saveStats()
    }
    
    func recordMessageReceived() {
        guard isEnabled else { return }
        stats.messagesReceived += 1
        saveStats()
    }
    
    // 使用統計記錄
    func recordBingoGame() {
        guard isEnabled else { return }
        stats.bingoGamesPlayed += 1
        saveStats()
    }
    
    func recordTrustScoreUpdate() {
        guard isEnabled else { return }
        stats.trustScoreUpdates += 1
        saveStats()
    }
    
    func recordContentDetection() {
        guard isEnabled else { return }
        stats.contentDetections += 1
        saveStats()
    }
    
    // 系統健康記錄
    func recordCrash() {
        guard isEnabled else { return }
        stats.crashCount += 1
        saveStats()
    }
    
    func recordBatteryDrain(_ percentage: Double) {
        guard isEnabled else { return }
        stats.recordBatteryDrain(percentage)
        saveStats()
    }
    
    func recordMemoryUsage(_ megabytes: Int) {
        guard isEnabled else { return }
        stats.peakMemoryUsage = max(stats.peakMemoryUsage, megabytes)
        saveStats()
    }
    
    // 數據管理
    func refreshStats() {
        loadStats()
    }
    
    func clearAllStats() {
        stats = LocalStatistics()
        saveStats()
    }
    
    func exportToJSON() -> Data? {
        return try? JSONEncoder().encode(stats)
    }
    
    // 私有方法
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "LocalAnalytics"),
           let loadedStats = try? JSONDecoder().decode(LocalStatistics.self, from: data) {
            self.stats = loadedStats
        }
    }
    
    private func saveStats() {
        stats.lastUpdated = Date()
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "LocalAnalytics")
        }
    }
    
    private func startPeriodicSave() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.saveStats()
            }
            .store(in: &cancellables)
    }
}