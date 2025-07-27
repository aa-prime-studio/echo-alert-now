import Foundation
import SwiftUI

// MARK: - 路由性能監控與優化系統
// 實時監控路由性能，提供智能優化建議

@MainActor
@Observable
class RoutingPerformanceMonitor {
    
    // MARK: - 性能指標
    @Published var currentMetrics = PerformanceMetrics()
    @Published var historicalData: [PerformanceSnapshot] = []
    @Published var alerts: [PerformanceAlert] = []
    @Published var optimizationSuggestions: [OptimizationSuggestion] = []
    
    // MARK: - 監控配置
    private let monitoringInterval: TimeInterval = 5.0
    private let alertThresholds = AlertThresholds()
    private let maxHistorySize = 1000
    
    // MARK: - 私有狀態
    private var monitoringTimer: Timer?
    private var routeLatencyHistory: [String: [LatencyMeasurement]] = [:]
    private var messageTypeFrequency: [MessageType: FrequencyCounter] = [:]
    private var errorPatterns: [ErrorPattern] = []
    
    // MARK: - 初始化
    init() {
        startMonitoring()
        setupAlertThresholds()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 監控控制
    func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.collectMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - 性能數據收集
    func recordRouteLatency(routeID: String, latency: TimeInterval, success: Bool) {
        let measurement = LatencyMeasurement(
            timestamp: Date(),
            latency: latency,
            success: success
        )
        
        routeLatencyHistory[routeID, default: []].append(measurement)
        
        // 保持歷史記錄大小
        if routeLatencyHistory[routeID]!.count > 100 {
            routeLatencyHistory[routeID]!.removeFirst()
        }
        
        // 檢查性能異常
        checkLatencyAnomaly(routeID: routeID, latency: latency)
    }
    
    func recordMessageProcessing(messageType: MessageType, processingTime: TimeInterval, success: Bool) {
        let counter = messageTypeFrequency[messageType] ?? FrequencyCounter()
        counter.increment(processingTime: processingTime, success: success)
        messageTypeFrequency[messageType] = counter
        
        // 檢查處理時間異常
        if processingTime > alertThresholds.maxProcessingTime {
            addAlert(.highProcessingTime(messageType: messageType, time: processingTime))
        }
    }
    
    func recordRoutingError(error: RoutingError, context: ErrorContext) {
        let pattern = ErrorPattern(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        errorPatterns.append(pattern)
        
        // 保持錯誤模式歷史大小
        if errorPatterns.count > 500 {
            errorPatterns.removeFirst()
        }
        
        // 分析錯誤模式
        analyzeErrorPattern(pattern)
    }
    
    // MARK: - 指標收集
    private func collectMetrics() async {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            totalRoutes: routeLatencyHistory.keys.count,
            averageLatency: calculateAverageLatency(),
            successRate: calculateSuccessRate(),
            messageTypeDistribution: calculateMessageTypeDistribution(),
            errorRate: calculateErrorRate(),
            throughput: calculateThroughput()
        )
        
        historicalData.append(snapshot)
        
        // 保持歷史數據大小
        if historicalData.count > maxHistorySize {
            historicalData.removeFirst()
        }
        
        // 更新當前指標
        updateCurrentMetrics(snapshot)
        
        // 生成優化建議
        generateOptimizationSuggestions()
        
        // 檢查性能警報
        checkPerformanceAlerts(snapshot)
    }
    
    private func calculateAverageLatency() -> Double {
        let allMeasurements = routeLatencyHistory.values.flatMap { $0 }
        guard !allMeasurements.isEmpty else { return 0.0 }
        
        let totalLatency = allMeasurements.map { $0.latency }.reduce(0, +)
        return totalLatency / Double(allMeasurements.count)
    }
    
    private func calculateSuccessRate() -> Double {
        let allMeasurements = routeLatencyHistory.values.flatMap { $0 }
        guard !allMeasurements.isEmpty else { return 1.0 }
        
        let successCount = allMeasurements.filter { $0.success }.count
        return Double(successCount) / Double(allMeasurements.count)
    }
    
    private func calculateMessageTypeDistribution() -> [MessageType: Double] {
        let totalMessages = messageTypeFrequency.values.map { $0.totalCount }.reduce(0, +)
        guard totalMessages > 0 else { return [:] }
        
        var distribution: [MessageType: Double] = [:]
        for (messageType, counter) in messageTypeFrequency {
            distribution[messageType] = Double(counter.totalCount) / Double(totalMessages)
        }
        
        return distribution
    }
    
    private func calculateErrorRate() -> Double {
        let recentErrors = errorPatterns.filter { 
            Date().timeIntervalSince($0.timestamp) < 300 // 最近5分鐘
        }
        
        let recentMeasurements = routeLatencyHistory.values.flatMap { measurements in
            measurements.filter { Date().timeIntervalSince($0.timestamp) < 300 }
        }
        
        guard !recentMeasurements.isEmpty else { return 0.0 }
        
        return Double(recentErrors.count) / Double(recentMeasurements.count)
    }
    
    private func calculateThroughput() -> Double {
        let recentMeasurements = routeLatencyHistory.values.flatMap { measurements in
            measurements.filter { Date().timeIntervalSince($0.timestamp) < 60 } // 最近1分鐘
        }
        
        return Double(recentMeasurements.count) / 60.0 // 每秒消息數
    }
    
    // MARK: - 異常檢測
    private func checkLatencyAnomaly(routeID: String, latency: TimeInterval) {
        guard let history = routeLatencyHistory[routeID], history.count >= 10 else { return }
        
        let recentLatencies = history.suffix(10).map { $0.latency }
        let averageLatency = recentLatencies.reduce(0, +) / Double(recentLatencies.count)
        
        // 檢測異常高延遲 (超過平均值2倍)
        if latency > averageLatency * 2 && latency > alertThresholds.maxLatency {
            addAlert(.highLatency(routeID: routeID, latency: latency, average: averageLatency))
        }
    }
    
    private func analyzeErrorPattern(_ pattern: ErrorPattern) {
        let recentSimilarErrors = errorPatterns.filter { existing in
            Date().timeIntervalSince(existing.timestamp) < 300 && // 最近5分鐘
            type(of: existing.error) == type(of: pattern.error) &&
            existing.context.messageType == pattern.context.messageType
        }
        
        // 檢測錯誤頻率異常
        if recentSimilarErrors.count >= 5 {
            addAlert(.errorPattern(
                errorType: String(describing: type(of: pattern.error)),
                count: recentSimilarErrors.count,
                messageType: pattern.context.messageType
            ))
        }
    }
    
    // MARK: - 警報管理
    private func addAlert(_ alertType: PerformanceAlertType) {
        let alert = PerformanceAlert(
            id: UUID().uuidString,
            type: alertType,
            timestamp: Date(),
            severity: getSeverity(for: alertType)
        )
        
        alerts.append(alert)
        
        // 保持警報數量
        if alerts.count > 50 {
            alerts.removeFirst()
        }
        
        print("🚨 路由性能警報: \(alert.description)")
    }
    
    private func getSeverity(for alertType: PerformanceAlertType) -> AlertSeverity {
        switch alertType {
        case .highLatency(_, let latency, _):
            return latency > 2.0 ? .critical : .warning
        case .errorPattern(_, let count, _):
            return count > 10 ? .critical : .warning
        case .highProcessingTime(_, let time):
            return time > 1.0 ? .critical : .warning
        case .lowSuccessRate(let rate):
            return rate < 0.8 ? .critical : .warning
        case .resourceExhaustion:
            return .critical
        }
    }
    
    private func checkPerformanceAlerts(_ snapshot: PerformanceSnapshot) {
        // 檢查成功率
        if snapshot.successRate < alertThresholds.minSuccessRate {
            addAlert(.lowSuccessRate(rate: snapshot.successRate))
        }
        
        // 檢查平均延遲
        if snapshot.averageLatency > alertThresholds.maxLatency {
            addAlert(.highLatency(routeID: "overall", latency: snapshot.averageLatency, average: snapshot.averageLatency))
        }
        
        // 檢查錯誤率
        if snapshot.errorRate > alertThresholds.maxErrorRate {
            addAlert(.errorPattern(errorType: "general", count: Int(snapshot.errorRate * 100), messageType: nil))
        }
    }
    
    // MARK: - 優化建議
    private func generateOptimizationSuggestions() {
        optimizationSuggestions.removeAll()
        
        // 分析延遲模式
        analyzeLatencyPatterns()
        
        // 分析錯誤模式
        analyzeErrorFrequency()
        
        // 分析消息類型分佈
        analyzeMessageDistribution()
        
        // 分析資源使用
        analyzeResourceUsage()
    }
    
    private func analyzeLatencyPatterns() {
        // 找出高延遲路由
        let highLatencyRoutes = routeLatencyHistory.compactMap { (routeID, measurements) -> (String, Double)? in
            let averageLatency = measurements.map { $0.latency }.reduce(0, +) / Double(measurements.count)
            return averageLatency > alertThresholds.maxLatency ? (routeID, averageLatency) : nil
        }.sorted { $0.1 > $1.1 }
        
        if !highLatencyRoutes.isEmpty {
            optimizationSuggestions.append(OptimizationSuggestion(
                type: .routeOptimization,
                priority: .high,
                description: "優化高延遲路由: \(highLatencyRoutes.prefix(3).map { $0.0 }.joined(separator: ", "))",
                estimatedImpact: .high,
                implementationComplexity: .medium
            ))
        }
    }
    
    private func analyzeErrorFrequency() {
        let errorTypeCounts = Dictionary(grouping: errorPatterns) { 
            String(describing: type(of: $0.error))
        }.mapValues { $0.count }
        
        let topErrors = errorTypeCounts.sorted { $0.value > $1.value }.prefix(3)
        
        if !topErrors.isEmpty {
            optimizationSuggestions.append(OptimizationSuggestion(
                type: .errorReduction,
                priority: .high,
                description: "減少頻繁錯誤: \(topErrors.map { $0.key }.joined(separator: ", "))",
                estimatedImpact: .high,
                implementationComplexity: .medium
            ))
        }
    }
    
    private func analyzeMessageDistribution() {
        let distribution = calculateMessageTypeDistribution()
        let sortedTypes = distribution.sorted { $0.value > $1.value }
        
        // 檢查是否有熱點消息類型
        if let topType = sortedTypes.first, topType.value > 0.5 {
            optimizationSuggestions.append(OptimizationSuggestion(
                type: .loadBalancing,
                priority: .medium,
                description: "優化熱點訊息類型: \(topType.key.rawValue) (\(Int(topType.value * 100))%)",
                estimatedImpact: .medium,
                implementationComplexity: .low
            ))
        }
    }
    
    private func analyzeResourceUsage() {
        // 檢查吞吐量
        let currentThroughput = calculateThroughput()
        if currentThroughput > 100 { // 每秒超過100條消息
            optimizationSuggestions.append(OptimizationSuggestion(
                type: .scalability,
                priority: .medium,
                description: "考慮擴展處理能力，當前吞吐量: \(Int(currentThroughput)) msg/s",
                estimatedImpact: .medium,
                implementationComplexity: .high
            ))
        }
    }
    
    // MARK: - 報告生成
    func generatePerformanceReport() -> PerformanceReport {
        let latestSnapshot = historicalData.last ?? PerformanceSnapshot.empty
        
        return PerformanceReport(
            generatedAt: Date(),
            summary: generateSummary(latestSnapshot),
            metrics: latestSnapshot,
            alerts: alerts.filter { Date().timeIntervalSince($0.timestamp) < 3600 }, // 最近1小時
            suggestions: optimizationSuggestions,
            trends: analyzeTrends(),
            topRoutes: getTopPerformingRoutes(),
            problemRoutes: getProblemRoutes()
        )
    }
    
    private func generateSummary(_ snapshot: PerformanceSnapshot) -> String {
        var summary = "路由系統性能摘要：\n"
        summary += "• 總路由數: \(snapshot.totalRoutes)\n"
        summary += "• 平均延遲: \(String(format: "%.2f", snapshot.averageLatency * 1000))ms\n"
        summary += "• 成功率: \(String(format: "%.1f", snapshot.successRate * 100))%\n"
        summary += "• 吞吐量: \(String(format: "%.1f", snapshot.throughput)) msg/s\n"
        summary += "• 活躍警報: \(alerts.filter { Date().timeIntervalSince($0.timestamp) < 3600 }.count)"
        
        return summary
    }
    
    private func analyzeTrends() -> [TrendAnalysis] {
        guard historicalData.count >= 10 else { return [] }
        
        let recentData = historicalData.suffix(10)
        let oldData = historicalData.dropLast(10).suffix(10)
        
        var trends: [TrendAnalysis] = []
        
        // 延遲趨勢
        let recentAvgLatency = recentData.map { $0.averageLatency }.reduce(0, +) / Double(recentData.count)
        let oldAvgLatency = oldData.map { $0.averageLatency }.reduce(0, +) / Double(oldData.count)
        let latencyChange = (recentAvgLatency - oldAvgLatency) / oldAvgLatency
        
        trends.append(TrendAnalysis(
            metric: "平均延遲",
            direction: latencyChange > 0.1 ? .increasing : (latencyChange < -0.1 ? .decreasing : .stable),
            changePercentage: latencyChange * 100
        ))
        
        // 成功率趨勢
        let recentSuccessRate = recentData.map { $0.successRate }.reduce(0, +) / Double(recentData.count)
        let oldSuccessRate = oldData.map { $0.successRate }.reduce(0, +) / Double(oldData.count)
        let successRateChange = (recentSuccessRate - oldSuccessRate) / oldSuccessRate
        
        trends.append(TrendAnalysis(
            metric: "成功率",
            direction: successRateChange > 0.05 ? .increasing : (successRateChange < -0.05 ? .decreasing : .stable),
            changePercentage: successRateChange * 100
        ))
        
        return trends
    }
    
    private func getTopPerformingRoutes() -> [RoutePerformanceInfo] {
        return routeLatencyHistory.compactMap { (routeID, measurements) in
            guard !measurements.isEmpty else { return nil }
            
            let avgLatency = measurements.map { $0.latency }.reduce(0, +) / Double(measurements.count)
            let successRate = Double(measurements.filter { $0.success }.count) / Double(measurements.count)
            
            return RoutePerformanceInfo(
                routeID: routeID,
                averageLatency: avgLatency,
                successRate: successRate,
                messageCount: measurements.count
            )
        }.sorted { $0.successRate > $1.successRate && $0.averageLatency < $1.averageLatency }.prefix(5).map { $0 }
    }
    
    private func getProblemRoutes() -> [RoutePerformanceInfo] {
        return routeLatencyHistory.compactMap { (routeID, measurements) in
            guard !measurements.isEmpty else { return nil }
            
            let avgLatency = measurements.map { $0.latency }.reduce(0, +) / Double(measurements.count)
            let successRate = Double(measurements.filter { $0.success }.count) / Double(measurements.count)
            
            // 問題路由定義：延遲高或成功率低
            if avgLatency > alertThresholds.maxLatency || successRate < alertThresholds.minSuccessRate {
                return RoutePerformanceInfo(
                    routeID: routeID,
                    averageLatency: avgLatency,
                    successRate: successRate,
                    messageCount: measurements.count
                )
            }
            
            return nil
        }.sorted { $0.averageLatency > $1.averageLatency }.prefix(5).map { $0 }
    }
    
    // MARK: - 配置
    private func setupAlertThresholds() {
        // 警報閾值可以根據實際環境調整
    }
    
    private func updateCurrentMetrics(_ snapshot: PerformanceSnapshot) {
        currentMetrics.totalRoutes = snapshot.totalRoutes
        currentMetrics.averageLatency = snapshot.averageLatency
        currentMetrics.successRate = snapshot.successRate
        currentMetrics.errorRate = snapshot.errorRate
        currentMetrics.throughput = snapshot.throughput
        currentMetrics.lastUpdate = snapshot.timestamp
    }
}

// MARK: - 數據結構

struct PerformanceMetrics {
    var totalRoutes: Int = 0
    var averageLatency: Double = 0.0
    var successRate: Double = 1.0
    var errorRate: Double = 0.0
    var throughput: Double = 0.0
    var lastUpdate: Date = Date()
}

struct PerformanceSnapshot {
    let timestamp: Date
    let totalRoutes: Int
    let averageLatency: Double
    let successRate: Double
    let messageTypeDistribution: [MessageType: Double]
    let errorRate: Double
    let throughput: Double
    
    static let empty = PerformanceSnapshot(
        timestamp: Date(),
        totalRoutes: 0,
        averageLatency: 0.0,
        successRate: 1.0,
        messageTypeDistribution: [:],
        errorRate: 0.0,
        throughput: 0.0
    )
}

struct LatencyMeasurement {
    let timestamp: Date
    let latency: TimeInterval
    let success: Bool
}

class FrequencyCounter {
    var totalCount: Int = 0
    var successCount: Int = 0
    var totalProcessingTime: TimeInterval = 0.0
    
    func increment(processingTime: TimeInterval, success: Bool) {
        totalCount += 1
        totalProcessingTime += processingTime
        if success {
            successCount += 1
        }
    }
    
    var averageProcessingTime: TimeInterval {
        return totalCount > 0 ? totalProcessingTime / Double(totalCount) : 0.0
    }
    
    var successRate: Double {
        return totalCount > 0 ? Double(successCount) / Double(totalCount) : 1.0
    }
}

struct ErrorPattern {
    let error: RoutingError
    let context: ErrorContext
    let timestamp: Date
}

struct ErrorContext {
    let messageType: MessageType?
    let sourceID: String?
    let destinationType: String?
    let routeID: String?
}

struct PerformanceAlert {
    let id: String
    let type: PerformanceAlertType
    let timestamp: Date
    let severity: AlertSeverity
    
    var description: String {
        switch type {
        case .highLatency(let routeID, let latency, let average):
            return "路由 \(routeID) 延遲異常: \(String(format: "%.2f", latency * 1000))ms (平均: \(String(format: "%.2f", average * 1000))ms)"
        case .errorPattern(let errorType, let count, let messageType):
            return "\(errorType) 錯誤頻發: \(count)次 (訊息類型: \(messageType?.rawValue ?? "全部"))"
        case .highProcessingTime(let messageType, let time):
            return "\(messageType.rawValue) 處理時間過長: \(String(format: "%.2f", time * 1000))ms"
        case .lowSuccessRate(let rate):
            return "路由成功率過低: \(String(format: "%.1f", rate * 100))%"
        case .resourceExhaustion:
            return "系統資源不足"
        }
    }
}

enum PerformanceAlertType {
    case highLatency(routeID: String, latency: TimeInterval, average: TimeInterval)
    case errorPattern(errorType: String, count: Int, messageType: MessageType?)
    case highProcessingTime(messageType: MessageType, time: TimeInterval)
    case lowSuccessRate(rate: Double)
    case resourceExhaustion
}

enum AlertSeverity {
    case info
    case warning
    case critical
}

struct AlertThresholds {
    let maxLatency: TimeInterval = 0.5 // 500ms
    let maxProcessingTime: TimeInterval = 0.3 // 300ms
    let minSuccessRate: Double = 0.95 // 95%
    let maxErrorRate: Double = 0.05 // 5%
}

struct OptimizationSuggestion {
    let type: OptimizationType
    let priority: SuggestionPriority
    let description: String
    let estimatedImpact: Impact
    let implementationComplexity: Complexity
}

enum OptimizationType {
    case routeOptimization
    case errorReduction
    case loadBalancing
    case scalability
    case caching
}

enum SuggestionPriority {
    case low
    case medium
    case high
    case critical
}

enum Impact {
    case low
    case medium
    case high
}

enum Complexity {
    case low
    case medium
    case high
}

struct PerformanceReport {
    let generatedAt: Date
    let summary: String
    let metrics: PerformanceSnapshot
    let alerts: [PerformanceAlert]
    let suggestions: [OptimizationSuggestion]
    let trends: [TrendAnalysis]
    let topRoutes: [RoutePerformanceInfo]
    let problemRoutes: [RoutePerformanceInfo]
}

struct TrendAnalysis {
    let metric: String
    let direction: TrendDirection
    let changePercentage: Double
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

struct RoutePerformanceInfo {
    let routeID: String
    let averageLatency: TimeInterval
    let successRate: Double
    let messageCount: Int
}