import Foundation
import os.log

/// 安全日誌記錄器 - 防止敏感資訊洩露
@MainActor
class SecureLogger {
    
    // MARK: - Log Levels
    enum LogLevel: Int, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4
        
        var prefix: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Log Categories
    enum Category: String {
        case security = "Security"
        case network = "Network"
        case crypto = "Crypto"
        case ui = "UI"
        case purchase = "Purchase"
        case game = "Game"
        case general = "General"
        
        var logger: Logger {
            return Logger(subsystem: "com.signalair", category: self.rawValue)
        }
    }
    
    // MARK: - Configuration
    private static var minimumLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .error  // 生產環境只記錄錯誤和關鍵訊息
        #endif
    }()
    
    // MARK: - Public Methods
    
    /// 記錄調試訊息（僅在 DEBUG 模式下可用）
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(.debug, message: message, category: category, file: file, function: function, line: line)
        #endif
    }
    
    /// 記錄資訊訊息
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄警告訊息
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄錯誤訊息
    static func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄關鍵錯誤訊息
    static func critical(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message: message, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private static func log(_ level: LogLevel, message: String, category: Category, file: String, function: String, line: Int) {
        guard level.rawValue >= minimumLevel.rawValue else { return }
        
        let sanitizedMessage = sanitizeMessage(message)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(sanitizedMessage)"
        
        // 使用 OSLog 進行結構化日誌記錄
        category.logger.log(level: level.osLogType, "\(level.prefix) \(logMessage)")
    }
    
    /// 清理敏感資訊的日誌訊息
    private static func sanitizeMessage(_ message: String) -> String {
        var sanitized = message
        
        // 移除或遮蔽敏感關鍵字
        let sensitivePatterns = [
            // 密鑰相關
            ("key", "***KEY***"),
            ("Key", "***KEY***"),
            ("密鑰", "***密鑰***"),
            ("privateKey", "***PRIVATE_KEY***"),
            ("publicKey", "***PUBLIC_KEY***"),
            ("sessionKey", "***SESSION_KEY***"),
            
            // ID 相關 - 只顯示前4位
            ("ID: [A-Fa-f0-9]{8,}", "ID: ****"),
            ("id: [A-Fa-f0-9]{8,}", "id: ****"),
            ("設備ID: [A-Fa-f0-9]{8,}", "設備ID: ****"),
            
            // UUID 相關 - 只顯示前8位
            ("[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}", "****-****-****-****-****"),
            
            // 密碼相關
            ("password", "***PASSWORD***"),
            ("Password", "***PASSWORD***"),
            ("密碼", "***密碼***"),
            
            // 令牌相關
            ("token", "***TOKEN***"),
            ("Token", "***TOKEN***"),
            ("令牌", "***令牌***")
        ]
        
        for (pattern, replacement) in sensitivePatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        
        return sanitized
    }
    
    /// 縮短長字串以防止日誌過長
    private static func truncateIfNeeded(_ string: String, maxLength: Int = 200) -> String {
        if string.count <= maxLength {
            return string
        }
        return String(string.prefix(maxLength)) + "..."
    }
}

// MARK: - Convenience Extensions

extension SecureLogger {
    /// 記錄安全事件
    static func security(_ message: String, level: LogLevel = .warning) {
        switch level {
        case .debug: debug(message, category: .security)
        case .info: info(message, category: .security)
        case .warning: warning(message, category: .security)
        case .error: error(message, category: .security)
        case .critical: critical(message, category: .security)
        }
    }
    
    /// 記錄網路事件
    static func network(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: debug(message, category: .network)
        case .info: info(message, category: .network)
        case .warning: warning(message, category: .network)
        case .error: error(message, category: .network)
        case .critical: critical(message, category: .network)
        }
    }
    
    /// 記錄加密事件
    static func crypto(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: debug(message, category: .crypto)
        case .info: info(message, category: .crypto)
        case .warning: warning(message, category: .crypto)
        case .error: error(message, category: .crypto)
        case .critical: critical(message, category: .crypto)
        }
    }
}