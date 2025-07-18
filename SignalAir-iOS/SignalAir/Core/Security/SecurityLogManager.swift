import Foundation
import CryptoKit

//
// SecurityLogManager.swift
// SignalAir
//
// 開源安全日誌系統 - 本地化實作，隱私保護
//

/// 安全日誌條目
struct SecurityLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: String
    let source: String
    let severity: SecurityLogSeverity
    let details: String
    
    // 隱私保護 - 不記錄個人訊息內容
    init(
        eventType: String,
        source: String,
        severity: SecurityLogSeverity,
        details: String
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.eventType = eventType
        self.source = source
        self.severity = severity
        self.details = SecurityLogManager.sanitizeDetails(details)
    }
    
    /// 格式化顯示
    var formattedEntry: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = timeFormatter.string(from: timestamp)
        
        return "[\(timeString)] [\(severity.displayName)] [\(source)] \(eventType): \(details)"
    }
    
    /// CSV 格式輸出
    var csvLine: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = timeFormatter.string(from: timestamp)
        
        return "\(timeString),\(eventType),\(source),\(severity.rawValue),\"\(details.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

/// 安全日誌嚴重度等級
enum SecurityLogSeverity: String, Codable, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var displayName: String {
        switch self {
        case .info:
            return "資訊"
        case .warning:
            return "警告"
        case .error:
            return "錯誤"
        case .critical:
            return "嚴重"
        }
    }
    
    var priority: Int {
        switch self {
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}

/// 攻擊類型統計
struct AttackType: Codable {
    let type: String
    let count: Int
}

/// 日誌統計資料
struct SecurityLogStatistics: Codable {
    let totalEntries: Int
    let entriesByType: [String: Int]
    let entriesBySeverity: [String: Int]
    let entriesBySource: [String: Int]
    let timeRange: DateInterval?
    let topAttackTypes: [AttackType]
    let riskPeriods: [RiskPeriod]
    
    struct RiskPeriod: Codable {
        let hour: Int
        let riskScore: Int
        let eventCount: Int
    }
}

/// 安全日誌管理器
class SecurityLogManager: ObservableObject {
    
    // MARK: - 配置
    
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxTotalLogSize: Int = 50 * 1024 * 1024 // 50MB
    private let logDirectory: URL
    private let currentLogFile: URL
    private let encryptionKey: SymmetricKey
    
    // MARK: - 必記錄事件類型
    
    private static let criticalEventTypes = [
        "connection_failed",
        "large_data_packet",
        "repeated_connection_attempts",
        "unknown_protocol_request",
        "data_validation_failed",
        "flood_protection_triggered",
        "malicious_content_detected",
        "unauthorized_access_attempt",
        "encryption_failure",
        "key_exchange_failure"
    ]
    
    // MARK: - 屬性
    
    @Published var recentLogs: [SecurityLogEntry] = []
    @Published var statistics: SecurityLogStatistics?
    
    private let maxRecentLogs = 1000
    private var logQueue = DispatchQueue(label: "SecurityLogManager", qos: .utility)
    
    // MARK: - 初始化
    
    init() {
        // 創建安全的日誌目錄
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logDirectory = documentsPath.appendingPathComponent("SecurityLogs")
        
        // 確保目錄存在
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // 當前日誌文件
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        self.currentLogFile = logDirectory.appendingPathComponent("security_\(todayString).log")
        
        // 生成加密密鑰
        self.encryptionKey = SecurityLogManager.generateEncryptionKey()
        
        // 載入近期日誌
        loadRecentLogs()
        
        // 設定定期清理
        setupPeriodicCleanup()
        
        print("🔒 SecurityLogManager: 安全日誌系統已初始化")
        print("📁 日誌目錄: \(logDirectory.path)")
        
        // 記錄系統啟動
        logEntry(
            eventType: "system_startup",
            source: "SecurityLogManager",
            severity: .info,
            details: "安全日誌系統啟動"
        )
    }
    
    // MARK: - 公開方法
    
    /// 記錄安全事件
    func logEntry(
        eventType: String,
        source: String,
        severity: SecurityLogSeverity,
        details: String
    ) {
        let entry = SecurityLogEntry(
            eventType: eventType,
            source: source,
            severity: severity,
            details: details
        )
        
        logQueue.async {
            self.writeLogEntry(entry)
            
            DispatchQueue.main.async {
                self.recentLogs.insert(entry, at: 0)
                if self.recentLogs.count > self.maxRecentLogs {
                    self.recentLogs = Array(self.recentLogs.prefix(self.maxRecentLogs))
                }
            }
        }
    }
    
    /// 記錄連線失敗
    func logConnectionFailure(peerID: String, reason: String) {
        logEntry(
            eventType: "connection_failed",
            source: "NetworkService",
            severity: .warning,
            details: "連線失敗 - PeerID: \(peerID), 原因: \(reason)"
        )
    }
    
    /// 記錄異常大資料包
    func logLargeDataPacket(peerID: String, size: Int) {
        logEntry(
            eventType: "large_data_packet",
            source: "NetworkService",
            severity: .warning,
            details: "異常大資料包 - PeerID: \(peerID), 大小: \(size) bytes"
        )
    }
    
    /// 記錄重複連線嘗試
    func logRepeatedConnectionAttempts(peerID: String, attempts: Int) {
        logEntry(
            eventType: "repeated_connection_attempts",
            source: "NetworkService",
            severity: .error,
            details: "重複連線嘗試 - PeerID: \(peerID), 次數: \(attempts)"
        )
    }
    
    /// 記錄未知協議請求
    func logUnknownProtocolRequest(peerID: String, protocolType: String) {
        logEntry(
            eventType: "unknown_protocol_request",
            source: "NetworkService",
            severity: .warning,
            details: "未知協議請求 - PeerID: \(peerID), 協議: \(protocolType)"
        )
    }
    
    /// 記錄資料驗證失敗
    func logDataValidationFailure(peerID: String, error: String) {
        logEntry(
            eventType: "data_validation_failed",
            source: "NetworkService",
            severity: .error,
            details: "資料驗證失敗 - PeerID: \(peerID), 錯誤: \(error)"
        )
    }
    
    /// 獲取日誌統計
    func generateStatistics() -> SecurityLogStatistics {
        let stats = calculateStatistics()
        
        DispatchQueue.main.async {
            self.statistics = stats
        }
        
        return stats
    }
    
    /// 手動清理日誌
    func manualCleanup() {
        logQueue.async {
            self.performCleanup()
        }
    }
    
    /// 導出日誌
    func exportLogs() -> URL? {
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("security_logs_export.csv")
        
        do {
            let csvHeader = "時間,事件類型,來源,嚴重度,詳細資訊\n"
            var csvContent = csvHeader
            
            for entry in recentLogs.reversed() {
                csvContent += entry.csvLine + "\n"
            }
            
            try csvContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            print("❌ 導出日誌失敗: \(error)")
            return nil
        }
    }
    
    // MARK: - 私有方法
    
    /// 隱私保護 - 清理敏感資訊
    internal static func sanitizeDetails(_ details: String) -> String {
        var sanitized = details
        
        // 移除可能的個人訊息內容
        sanitized = sanitized.replacingOccurrences(of: "content:\\s*\"[^\"]*\"", with: "content: [REDACTED]", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "message:\\s*\"[^\"]*\"", with: "message: [REDACTED]", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "text:\\s*\"[^\"]*\"", with: "text: [REDACTED]", options: .regularExpression)
        
        // 限制長度
        if sanitized.count > 500 {
            sanitized = String(sanitized.prefix(500)) + "..."
        }
        
        return sanitized
    }
    
    /// 寫入日誌條目
    private func writeLogEntry(_ entry: SecurityLogEntry) {
        do {
            let logLine = entry.formattedEntry + "\n"
            let data = logLine.data(using: .utf8) ?? Data()
            
            // 檢查文件大小
            let fileSize = getFileSize(currentLogFile)
            if fileSize > maxLogFileSize {
                rotateLogFile()
            }
            
            // 寫入文件
            if FileManager.default.fileExists(atPath: currentLogFile.path) {
                let fileHandle = try FileHandle(forWritingTo: currentLogFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: currentLogFile)
            }
            
            // 檢查總大小
            checkTotalLogSize()
            
        } catch {
            print("❌ 寫入日誌失敗: \(error)")
        }
    }
    
    /// 載入近期日誌
    private func loadRecentLogs() {
        logQueue.async {
            do {
                if FileManager.default.fileExists(atPath: self.currentLogFile.path) {
                    let content = try String(contentsOf: self.currentLogFile, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    
                    let entries = lines.suffix(self.maxRecentLogs)
                        .compactMap { line in
                            self.parseLogLine(line)
                        }
                    
                    DispatchQueue.main.async {
                        self.recentLogs = entries.reversed()
                    }
                }
            } catch {
                print("❌ 載入日誌失敗: \(error)")
            }
        }
    }
    
    /// 解析日誌行
    private func parseLogLine(_ line: String) -> SecurityLogEntry? {
        // 簡化解析 - 實際應用中可能需要更複雜的解析邏輯
        let pattern = #"^\[(.+?)\] \[(.+?)\] \[(.+?)\] (.+?): (.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        guard let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let timeString = String(line[Range(match.range(at: 1), in: line)!])
        let severityString = String(line[Range(match.range(at: 2), in: line)!])
        let source = String(line[Range(match.range(at: 3), in: line)!])
        let eventType = String(line[Range(match.range(at: 4), in: line)!])
        let details = String(line[Range(match.range(at: 5), in: line)!])
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let timestamp = timeFormatter.date(from: timeString) else { return nil }
        
        let severity = SecurityLogSeverity.allCases.first { $0.displayName == severityString } ?? .info
        
        return SecurityLogEntry(
            eventType: eventType,
            source: source,
            severity: severity,
            details: details
        )
    }
    
    /// 輪替日誌文件
    private func rotateLogFile() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let rotatedFile = logDirectory.appendingPathComponent("security_\(timestamp).log")
        
        do {
            try FileManager.default.moveItem(at: currentLogFile, to: rotatedFile)
            print("📁 日誌文件已輪替: \(rotatedFile.lastPathComponent)")
        } catch {
            print("❌ 日誌輪替失敗: \(error)")
        }
    }
    
    /// 檢查總日誌大小
    private func checkTotalLogSize() {
        let totalSize = getTotalLogSize()
        if totalSize > maxTotalLogSize {
            performCleanup()
        }
    }
    
    /// 獲取文件大小
    private func getFileSize(_ url: URL) -> Int {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int ?? 0
        } catch {
            return 0
        }
    }
    
    /// 獲取總日誌大小
    private func getTotalLogSize() -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return files.reduce(0) { total, file in
                total + (getFileSize(file))
            }
        } catch {
            return 0
        }
    }
    
    /// 執行清理
    private func performCleanup() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1! < date2!
            }
            
            var totalSize = getTotalLogSize()
            
            for file in sortedFiles {
                if totalSize <= maxTotalLogSize {
                    break
                }
                
                let fileSize = getFileSize(file)
                try FileManager.default.removeItem(at: file)
                totalSize -= fileSize
                
                print("🗑️ 清理舊日誌: \(file.lastPathComponent)")
            }
            
        } catch {
            print("❌ 清理日誌失敗: \(error)")
        }
    }
    
    /// 設定定期清理
    private func setupPeriodicCleanup() {
        // 每個月1號00:00自動清理
        let calendar = Calendar.current
        let now = Date()
        
        let nextCleanup = calendar.nextDate(after: now, matching: DateComponents(day: 1, hour: 0, minute: 0), matchingPolicy: .nextTime) ?? Date()
        
        Timer.scheduledTimer(withTimeInterval: nextCleanup.timeIntervalSinceNow, repeats: false) { _ in
            self.performCleanup()
            
            // 設定下個月的清理
            self.setupPeriodicCleanup()
        }
    }
    
    /// 計算統計資料
    private func calculateStatistics() -> SecurityLogStatistics {
        let entries = recentLogs
        let totalEntries = entries.count
        
        let entriesByType = Dictionary(grouping: entries) { $0.eventType }
            .mapValues { $0.count }
        
        let entriesBySeverity = Dictionary(grouping: entries) { $0.severity.rawValue }
            .mapValues { $0.count }
        
        let entriesBySource = Dictionary(grouping: entries) { $0.source }
            .mapValues { $0.count }
        
        let timeRange: DateInterval? = {
            guard !entries.isEmpty,
                  let firstEntry = entries.first,
                  let lastEntry = entries.last else {
                return nil
            }
            
            // entries 是按時間排序的，first 是最新的，last 是最舊的
            let startTime = min(firstEntry.timestamp, lastEntry.timestamp)
            let endTime = max(firstEntry.timestamp, lastEntry.timestamp)
            
            return DateInterval(start: startTime, end: endTime)
        }()
        
        let topAttackTypes = entriesByType.sorted { $0.value > $1.value }
            .prefix(10)
            .map { AttackType(type: $0.key, count: $0.value) }
        
        let riskPeriods = calculateRiskPeriods(entries)
        
        return SecurityLogStatistics(
            totalEntries: totalEntries,
            entriesByType: entriesByType,
            entriesBySeverity: entriesBySeverity,
            entriesBySource: entriesBySource,
            timeRange: timeRange,
            topAttackTypes: topAttackTypes,
            riskPeriods: riskPeriods
        )
    }
    
    /// 計算風險時段
    private func calculateRiskPeriods(_ entries: [SecurityLogEntry]) -> [SecurityLogStatistics.RiskPeriod] {
        let hourlyEvents = Dictionary(grouping: entries) { entry in
            Calendar.current.component(.hour, from: entry.timestamp)
        }
        
        return hourlyEvents.map { hour, events in
            let riskScore = events.reduce(0) { total, event in
                total + event.severity.priority
            }
            
            return SecurityLogStatistics.RiskPeriod(
                hour: hour,
                riskScore: riskScore,
                eventCount: events.count
            )
        }.sorted { $0.hour < $1.hour }
    }
    
    /// 生成加密密鑰
    private static func generateEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
}

// MARK: - 與現有安全事件系統整合

extension SecurityLogManager {
    
    /// 處理 NotificationCenter 安全事件
    func handleSecurityNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let eventType = userInfo["event"] as? String ?? "unknown"
        let _ = userInfo["peerID"] as? String ?? "unknown"
        let details = userInfo["details"] as? String ?? ""
        let source = userInfo["source"] as? String ?? "unknown"
        
        // 優先使用通知中的 severity 值
        let severity: SecurityLogSeverity
        if let severityString = userInfo["severity"] as? String {
            severity = SecurityLogSeverity(rawValue: severityString) ?? .info
        } else {
            // 舊版本兼容邏輯
            switch eventType {
            case "large_packet", "malicious_content", "suspicious_content_detected", "oversized_message_blocked":
                severity = .warning
            case "flood_protection_triggered", "message_type_rate_limit_exceeded", "temporary_ban_applied":
                severity = .error
            case "peer_banned", "tiered_ban_applied", "unauthorized_access":
                severity = .critical
            case "banned_peer_message_blocked":
                severity = .warning
            default:
                severity = .info
            }
        }
        
        logEntry(
            eventType: eventType,
            source: source,
            severity: severity,
            details: details
        )
    }
    
    /// 啟動監聽安全事件
    func startListening() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SecurityEvent"),
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.handleSecurityNotification(notification)
        }
    }
}