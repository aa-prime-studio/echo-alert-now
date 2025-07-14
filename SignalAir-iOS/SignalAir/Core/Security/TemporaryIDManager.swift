import Foundation
import SwiftUI

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
    // 移除固定間隔，改用每日 00:00 計算
    
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
        let snack = taiwanSnacks.randomElement()!
        let base32Chars = "ABCDEFGHJKMNPQRSTVWXYZ23456789"
        let suffix = String((0..<4).map { _ in base32Chars.randomElement()! })
        return "\(snack)-\(suffix)"
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

// MARK: - 支援結構

struct DeviceIDStats {
    let deviceID: String
    let createdAt: Date
    let nextUpdateTime: Date
    let updateCount: Int
    let timeRemainingSeconds: TimeInterval
    
    var timeRemainingHours: Int {
        return Int(timeRemainingSeconds / 3600)
    }
    
    var formattedTimeRemaining: String {
        let hours = timeRemainingHours
        let minutes = Int((timeRemainingSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)小時\(minutes)分"
    }
}

// MARK: - 延展功能

extension TemporaryIDManager {
    /// 驗證裝置ID格式（新格式：50種台灣小吃+4位Base32字符）
    static func isValidDeviceID(_ id: String) -> Bool {
        return isNewFormat(id)
    }
    
    /// 判斷是否為新格式（Base32）
    static func isNewFormat(_ id: String) -> Bool {
        let pattern = "^.+-[ABCDEFGHJKMNPQRSTVWXYZ23456789]{4}$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 從裝置ID中提取小吃名稱
    static func extractSnackName(from deviceID: String) -> String? {
        let components = deviceID.components(separatedBy: "-")
        return components.first
    }
    
    /// 從裝置ID中提取Base32後綴
    static func extractSuffix(from deviceID: String) -> String? {
        let components = deviceID.components(separatedBy: "-")
        return components.last
    }
} 