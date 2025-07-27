import Foundation
import os.signpost

// MARK: - 加密性能監控器
// 實時監控加密/解密性能，優化大規模網路通訊

@available(iOS 12.0, *)
public class CryptoPerformanceMonitor {
    
    // MARK: - Signpost 日誌
    private static let log = OSLog(subsystem: "com.signalair.crypto", category: "performance")
    private static let encryptSignpost = OSSignpostID(log: log)
    private static let decryptSignpost = OSSignpostID(log: log)
    
    // MARK: - 性能指標
    public struct PerformanceMetrics {
        public var totalEncryptions: Int = 0
        public var totalDecryptions: Int = 0
        public var totalEncryptionTime: TimeInterval = 0
        public var totalDecryptionTime: TimeInterval = 0
        public var totalBytesEncrypted: Int = 0
        public var totalBytesDecrypted: Int = 0
        public var compressionRatio: Double = 0.0
        public var chachaUseCount: Int = 0
        public var aesUseCount: Int = 0
        
        public var averageEncryptionTime: TimeInterval {
            totalEncryptions > 0 ? totalEncryptionTime / Double(totalEncryptions) : 0
        }
        
        public var averageDecryptionTime: TimeInterval {
            totalDecryptions > 0 ? totalDecryptionTime / Double(totalDecryptions) : 0
        }
        
        public var encryptionThroughput: Double {
            totalEncryptionTime > 0 ? Double(totalBytesEncrypted) / totalEncryptionTime : 0
        }
        
        public var decryptionThroughput: Double {
            totalDecryptionTime > 0 ? Double(totalBytesDecrypted) / totalDecryptionTime : 0
        }
    }
    
    // MARK: - 單例
    public static let shared = CryptoPerformanceMonitor()
    
    // MARK: - 屬性
    private var metrics = PerformanceMetrics()
    private let metricsQueue = DispatchQueue(label: "crypto.metrics", qos: .utility)
    private var performanceHistory: [Date: PerformanceMetrics] = [:]
    
    // MARK: - 加密性能測量
    public func measureEncryption<T>(
        operation: () async throws -> T,
        dataSize: Int,
        algorithm: String
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: Self.log, name: "Encryption", signpostID: Self.encryptSignpost, 
                       "Algorithm: %s, Size: %d", algorithm, dataSize)
        }
        
        let result = try await operation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        if #available(iOS 12.0, *) {
            os_signpost(.end, log: Self.log, name: "Encryption", signpostID: Self.encryptSignpost,
                       "Duration: %.3f ms", duration * 1000)
        }
        
        await updateEncryptionMetrics(duration: duration, dataSize: dataSize, algorithm: algorithm)
        
        return result
    }
    
    // MARK: - 解密性能測量
    public func measureDecryption<T>(
        operation: () async throws -> T,
        dataSize: Int,
        algorithm: String
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: Self.log, name: "Decryption", signpostID: Self.decryptSignpost,
                       "Algorithm: %s, Size: %d", algorithm, dataSize)
        }
        
        let result = try await operation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        if #available(iOS 12.0, *) {
            os_signpost(.end, log: Self.log, name: "Decryption", signpostID: Self.decryptSignpost,
                       "Duration: %.3f ms", duration * 1000)
        }
        
        await updateDecryptionMetrics(duration: duration, dataSize: dataSize, algorithm: algorithm)
        
        return result
    }
    
    // MARK: - 指標更新
    private func updateEncryptionMetrics(duration: TimeInterval, dataSize: Int, algorithm: String) async {
        await metricsQueue.sync {
            metrics.totalEncryptions += 1
            metrics.totalEncryptionTime += duration
            metrics.totalBytesEncrypted += dataSize
            
            if algorithm.contains("ChaCha") {
                metrics.chachaUseCount += 1
            }
            // REMOVED: AES tracking (已移除AES支持)
        }
    }
    
    private func updateDecryptionMetrics(duration: TimeInterval, dataSize: Int, algorithm: String) async {
        await metricsQueue.sync {
            metrics.totalDecryptions += 1
            metrics.totalDecryptionTime += duration
            metrics.totalBytesDecrypted += dataSize
        }
    }
    
    // MARK: - 性能報告
    public func getCurrentMetrics() async -> PerformanceMetrics {
        return await metricsQueue.sync {
            return metrics
        }
    }
    
    public func getPerformanceReport() async -> String {
        let currentMetrics = await getCurrentMetrics()
        
        return """
        🚀 加密性能報告
        ==========================================
        
        📊 總體統計:
        • 總加密次數: \(currentMetrics.totalEncryptions)
        • 總解密次數: \(currentMetrics.totalDecryptions)
        • 總處理數據: \(formatBytes(currentMetrics.totalBytesEncrypted + currentMetrics.totalBytesDecrypted))
        
        ⚡ 性能指標:
        • 平均加密時間: \(String(format: "%.2f", currentMetrics.averageEncryptionTime * 1000)) ms
        • 平均解密時間: \(String(format: "%.2f", currentMetrics.averageDecryptionTime * 1000)) ms
        • 加密吞吐量: \(formatBytes(Int(currentMetrics.encryptionThroughput)))/s
        • 解密吞吐量: \(formatBytes(Int(currentMetrics.decryptionThroughput)))/s
        
        🔐 算法使用:
        • ChaCha20-Poly1305: \(currentMetrics.chachaUseCount) 次
        // REMOVED: AES-GCM 統計 (已移除AES支持)
        
        📈 壓縮效果:
        • 壓縮率: \(String(format: "%.1f", currentMetrics.compressionRatio * 100))%
        ==========================================
        """
    }
    
    // MARK: - 基準測試
    public func runBenchmark() async -> String {
        let testSizes = [1024, 4096, 16384, 65536, 262144] // 1KB to 256KB
        var results: [String] = []
        
        results.append("🏎️ 加密基準測試")
        results.append("=" * 50)
        
        for size in testSizes {
            let testData = Data(repeating: 0xFF, count: size)
            
            // REMOVED: AES-GCM 測試 (已移除AES支持)
            
            // ChaCha20 測試
            let chachaStartTime = CFAbsoluteTimeGetCurrent()
            for _ in 0..<100 {
                _ = try? await performMockEncryption(testData, algorithm: "ChaCha20")
            }
            let chachaTime = (CFAbsoluteTimeGetCurrent() - chachaStartTime) / 100
            
            results.append(String(format: "%s | ChaCha: %.2fms", 
                                 formatBytes(size).padding(toLength: 8, withPad: " ", startingAt: 0),
                                 chachaTime * 1000))
        }
        
        return results.joined(separator: "\n")
    }
    
    // MARK: - 模擬加密 (用於測試)
    private func performMockEncryption(_ data: Data, algorithm: String) async throws -> Data {
        // 模擬加密操作的CPU開銷
        await Task.sleep(nanoseconds: UInt64(data.count * 10)) // 基於數據大小的延遲
        return data
    }
    
    // MARK: - 工具方法
    private func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f%s", size, units[unitIndex])
    }
    
    // MARK: - 重置統計
    public func resetMetrics() async {
        await metricsQueue.sync {
            metrics = PerformanceMetrics()
            performanceHistory.removeAll()
        }
    }
    
    // MARK: - 自動性能優化建議
    public func getOptimizationSuggestions() async -> [String] {
        let currentMetrics = await getCurrentMetrics()
        var suggestions: [String] = []
        
        // 基於性能數據提供優化建議
        if currentMetrics.averageEncryptionTime > 0.01 { // > 10ms
            suggestions.append("⚠️ 加密時間較長，建議使用硬件加速或調整算法選擇")
        }
        
        if currentMetrics.chachaUseCount > currentMetrics.aesUseCount * 2 {
            suggestions.append("💡 ChaCha20使用頻繁，確保設備支持硬件加速")
        }
        
        if currentMetrics.compressionRatio < 0.1 {
            suggestions.append("📦 壓縮效果不佳，考慮調整壓縮閾值或算法")
        }
        
        if currentMetrics.encryptionThroughput < 1_000_000 { // < 1MB/s
            suggestions.append("🚀 吞吐量較低，建議啟用批量處理和並行加密")
        }
        
        if suggestions.isEmpty {
            suggestions.append("✅ 性能表現良好，無需特殊優化")
        }
        
        return suggestions
    }
}

// MARK: - String Extension
private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}