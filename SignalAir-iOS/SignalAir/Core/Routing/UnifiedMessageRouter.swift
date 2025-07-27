import Foundation
import SwiftUI

// MARK: - 統一訊息路由管理器
// 集中管理所有訊息路由決策，簡化分散式路由架構
@MainActor
@Observable
class UnifiedMessageRouter {
    
    // MARK: - 核心組件
    private let routingTable = MessageRoutingTable()
    private let middlewareChain = MiddlewareChain()
    private let routeOptimizer = RouteOptimizer()
    private let routeTracker = RouteTracker()
    
    // MARK: - 路由統計
    @Published var routingMetrics = RoutingMetrics()
    @Published var activeRoutes: [String: RouteInfo] = [:]
    
    // MARK: - 初始化
    init() {
        setupDefaultRoutes()
        setupDefaultMiddleware()
    }
    
    // MARK: - 統一路由介面
    func routeMessage(_ message: UniversalMessage, from source: String) async throws {
        let startTime = Date()
        let routeID = UUID().uuidString
        
        do {
            // 1. 路由追蹤開始
            await routeTracker.startTracking(routeID: routeID, message: message)
            
            // 2. 中間件處理鏈
            let processedMessage = try await middlewareChain.process(message)
            
            // 3. 路由決策
            let routes = try routingTable.findRoutes(for: processedMessage)
            guard !routes.isEmpty else {
                throw RoutingError.noRouteFound(messageType: processedMessage.type)
            }
            
            // 4. 智能路由選擇
            let optimalRoute = routeOptimizer.selectBestRoute(routes, for: processedMessage)
            
            // 5. 執行路由
            try await executeRoute(processedMessage, via: optimalRoute, routeID: routeID)
            
            // 6. 統計更新
            let duration = Date().timeIntervalSince(startTime)
            await updateMetrics(duration: duration, success: true, messageType: processedMessage.type)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            await updateMetrics(duration: duration, success: false, messageType: message.type)
            await routeTracker.recordError(routeID: routeID, error: error)
            throw error
        }
    }
    
    // MARK: - 路由執行
    private func executeRoute(_ message: UniversalMessage, via route: Route, routeID: String) async throws {
        switch route.destination {
        case .direct(let peerID):
            try await routeToPeer(message, peerID: peerID, route: route)
            
        case .broadcast(let scope):
            try await routeBroadcast(message, scope: scope, route: route)
            
        case .multicast(let targets):
            try await routeMulticast(message, targets: targets, route: route)
            
        case .conditional(let predicate):
            let filteredTargets = await findTargetsMatchingPredicate(predicate)
            try await routeMulticast(message, targets: filteredTargets, route: route)
        }
        
        await routeTracker.recordSuccess(routeID: routeID, route: route)
    }
    
    // MARK: - 具體路由實現
    private func routeToPeer(_ message: UniversalMessage, peerID: String, route: Route) async throws {
        guard let handler = route.handler else {
            throw RoutingError.handlerNotFound
        }
        
        try await handler.handleMessage(message, destination: .direct(peerID: peerID))
    }
    
    private func routeBroadcast(_ message: UniversalMessage, scope: BroadcastScope, route: Route) async throws {
        guard let handler = route.handler else {
            throw RoutingError.handlerNotFound
        }
        
        try await handler.handleMessage(message, destination: .broadcast(scope: scope))
    }
    
    private func routeMulticast(_ message: UniversalMessage, targets: [String], route: Route) async throws {
        guard let handler = route.handler else {
            throw RoutingError.handlerNotFound
        }
        
        try await handler.handleMessage(message, destination: .multicast(targets: targets))
    }
    
    // MARK: - 路由表管理
    func registerHandler<T: MessageHandler>(_ handler: T, for messageType: MessageType) {
        routingTable.register(handler, for: messageType)
    }
    
    func unregisterHandler(for messageType: MessageType) {
        routingTable.unregister(for: messageType)
    }
    
    // MARK: - 默認配置
    private func setupDefaultRoutes() {
        // 默認路由將在實際集成時配置
    }
    
    private func setupDefaultMiddleware() {
        middlewareChain.add(SecurityMiddleware())
        middlewareChain.add(ValidationMiddleware())
        middlewareChain.add(LoggingMiddleware())
        middlewareChain.add(MetricsMiddleware())
        middlewareChain.add(RateLimitingMiddleware())
    }
    
    // MARK: - 診斷和監控
    private func updateMetrics(duration: TimeInterval, success: Bool, messageType: MessageType) async {
        routingMetrics.totalMessages += 1
        routingMetrics.averageLatency = (routingMetrics.averageLatency * Double(routingMetrics.totalMessages - 1) + duration) / Double(routingMetrics.totalMessages)
        
        if success {
            routingMetrics.successfulRoutes += 1
        } else {
            routingMetrics.failedRoutes += 1
        }
        
        routingMetrics.messageTypeStats[messageType, default: 0] += 1
    }
    
    private func findTargetsMatchingPredicate(_ predicate: MessagePredicate) async -> [String] {
        // 實際實現將查詢網路拓撲和設備狀態
        return []
    }
    
    // MARK: - 路由優化建議
    func getRoutingInsights() -> RoutingInsights {
        return RoutingInsights(
            hotspots: identifyRoutingHotspots(),
            bottlenecks: identifyBottlenecks(),
            optimizationSuggestions: generateOptimizationSuggestions()
        )
    }
    
    private func identifyRoutingHotspots() -> [String] {
        return routingMetrics.messageTypeStats
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key.rawValue }
    }
    
    private func identifyBottlenecks() -> [String] {
        return activeRoutes.values
            .filter { $0.averageLatency > 1.0 }
            .map { $0.routeDescription }
    }
    
    private func generateOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if routingMetrics.failedRoutes > routingMetrics.successfulRoutes * 0.1 {
            suggestions.append("高失敗率檢測 - 考慮增強錯誤恢復機制")
        }
        
        if routingMetrics.averageLatency > 0.5 {
            suggestions.append("平均延遲過高 - 考慮路由優化或負載均衡")
        }
        
        return suggestions
    }
}

// MARK: - 通用訊息格式
struct UniversalMessage {
    let id: String
    let type: MessageType
    let category: MessageCategory
    let priority: MessagePriority
    let source: String
    let destination: MessageDestination
    let payload: Data
    let metadata: MessageMetadata
    let routing: RoutingInfo
    let timestamp: Date
    
    init(type: MessageType, category: MessageCategory = .normal, priority: MessagePriority = .normal,
         source: String, destination: MessageDestination, payload: Data,
         metadata: MessageMetadata = MessageMetadata(), routing: RoutingInfo = RoutingInfo()) {
        self.id = UUID().uuidString
        self.type = type
        self.category = category
        self.priority = priority
        self.source = source
        self.destination = destination
        self.payload = payload
        self.metadata = metadata
        self.routing = routing
        self.timestamp = Date()
    }
}

// MARK: - 訊息類型系統
enum MessageType: String, CaseIterable {
    case signal = "signal"
    case chat = "chat"
    case game = "game"
    case heartbeat = "heartbeat"
    case topology = "topology"
    case security = "security"
    case system = "system"
    case emergency = "emergency"
}

enum MessageCategory {
    case normal
    case priority
    case emergency
    case system
}

enum MessagePriority: Int {
    case low = 1
    case normal = 5
    case high = 8
    case emergency = 10
}

enum MessageDestination {
    case direct(peerID: String)
    case broadcast(scope: BroadcastScope)
    case multicast(targets: [String])
    case conditional(predicate: MessagePredicate)
}

enum BroadcastScope {
    case local      // 直連設備
    case network    // 整個網狀網路
    case emergency  // 緊急廣播
}

// MARK: - 路由相關結構
struct MessageMetadata {
    var ttl: Int = 10
    var encryption: Bool = true
    var compression: Bool = false
    var retryCount: Int = 0
    var originalSource: String?
    var routePath: [String] = []
}

struct RoutingInfo {
    var preferredRoute: String?
    var avoidPeers: Set<String> = []
    var maxHops: Int = 5
    var requireAck: Bool = false
}

struct MessagePredicate {
    let condition: (String) -> Bool
    
    static let allPeers = MessagePredicate { _ in true }
    static let connectedPeers = MessagePredicate { peerID in
        // 實際實現將檢查連接狀態
        return true
    }
}

// MARK: - 路由表
class MessageRoutingTable {
    private var routes: [MessageType: [RouteDefinition]] = [:]
    private let queue = DispatchQueue(label: "routing.table", qos: .userInitiated)
    
    func register<T: MessageHandler>(_ handler: T, for messageType: MessageType) {
        queue.sync {
            let definition = RouteDefinition(
                messageType: messageType,
                handler: AnyMessageHandler(handler),
                middleware: handler.middleware,
                conditions: handler.routingConditions,
                priority: handler.priority
            )
            routes[messageType, default: []].append(definition)
            routes[messageType]?.sort { $0.priority > $1.priority }
        }
    }
    
    func unregister(for messageType: MessageType) {
        queue.sync {
            routes[messageType] = nil
        }
    }
    
    func findRoutes(for message: UniversalMessage) throws -> [Route] {
        return queue.sync {
            guard let definitions = routes[message.type] else {
                return []
            }
            
            return definitions
                .filter { $0.matches(message) }
                .map { Route(definition: $0, message: message) }
        }
    }
}

// MARK: - 路由定義和處理器
struct RouteDefinition {
    let messageType: MessageType
    let handler: AnyMessageHandler
    let middleware: [String]
    let conditions: [RoutingCondition]
    let priority: Int
    
    func matches(_ message: UniversalMessage) -> Bool {
        return messageType == message.type &&
               conditions.allSatisfy { $0.evaluate(message) }
    }
}

struct Route {
    let definition: RouteDefinition
    let message: UniversalMessage
    let networkQuality: Double = 1.0
    let estimatedLatency: Double = 0.1
    
    var handler: AnyMessageHandler? { definition.handler }
    var destination: MessageDestination { message.destination }
}

protocol MessageHandler {
    var middleware: [String] { get }
    var routingConditions: [RoutingCondition] { get }
    var priority: Int { get }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws
}

// MARK: - 類型擦除包裝器
struct AnyMessageHandler {
    private let _handleMessage: (UniversalMessage, MessageDestination) async throws -> Void
    let middleware: [String]
    let routingConditions: [RoutingCondition]
    let priority: Int
    
    init<T: MessageHandler>(_ handler: T) {
        self._handleMessage = handler.handleMessage
        self.middleware = handler.middleware
        self.routingConditions = handler.routingConditions
        self.priority = handler.priority
    }
    
    func handleMessage(_ message: UniversalMessage, destination: MessageDestination) async throws {
        try await _handleMessage(message, destination)
    }
}

// MARK: - 路由條件
struct RoutingCondition {
    let name: String
    let evaluate: (UniversalMessage) -> Bool
    
    static let always = RoutingCondition(name: "always") { _ in true }
    static let emergencyOnly = RoutingCondition(name: "emergency") { $0.category == .emergency }
    static let encryptedOnly = RoutingCondition(name: "encrypted") { $0.metadata.encryption }
}

// MARK: - 中間件系統
class MiddlewareChain {
    private var middlewares: [MessageMiddleware] = []
    
    func add(_ middleware: MessageMiddleware) {
        middlewares.append(middleware)
    }
    
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        var processedMessage = message
        for middleware in middlewares {
            processedMessage = try await middleware.process(processedMessage)
        }
        return processedMessage
    }
}

protocol MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage
}

// MARK: - 默認中間件實現
struct SecurityMiddleware: MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        // 安全檢查和加密處理
        return message
    }
}

struct ValidationMiddleware: MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        // 訊息驗證
        guard !message.payload.isEmpty else {
            throw RoutingError.invalidMessage("Empty payload")
        }
        return message
    }
}

struct LoggingMiddleware: MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        print("🔄 路由訊息: \(message.type.rawValue) 從 \(message.source)")
        return message
    }
}

struct MetricsMiddleware: MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        // 性能指標收集
        return message
    }
}

struct RateLimitingMiddleware: MessageMiddleware {
    func process(_ message: UniversalMessage) async throws -> UniversalMessage {
        // 流量控制
        return message
    }
}

// MARK: - 路由優化器
class RouteOptimizer {
    func selectBestRoute(_ routes: [Route], for message: UniversalMessage) -> Route {
        return routes
            .sorted { route1, route2 in
                calculateRouteScore(route1, for: message) > 
                calculateRouteScore(route2, for: message)
            }
            .first ?? routes.first!
    }
    
    private func calculateRouteScore(_ route: Route, for message: UniversalMessage) -> Double {
        var score = 0.0
        
        // 優先級權重
        score += Double(message.priority.rawValue) * 10
        
        // 網路條件
        score += route.networkQuality * 5
        
        // 延遲預測
        score -= route.estimatedLatency * 3
        
        // 處理器優先級
        score += Double(route.definition.priority)
        
        return score
    }
}

// MARK: - 路由追蹤器
class RouteTracker {
    private var activeTrackings: [String: RouteTracking] = [:]
    
    func startTracking(routeID: String, message: UniversalMessage) async {
        activeTrackings[routeID] = RouteTracking(
            routeID: routeID,
            messageID: message.id,
            messageType: message.type,
            startTime: Date()
        )
    }
    
    func recordSuccess(routeID: String, route: Route) async {
        activeTrackings[routeID]?.endTime = Date()
        activeTrackings[routeID]?.success = true
    }
    
    func recordError(routeID: String, error: Error) async {
        activeTrackings[routeID]?.endTime = Date()
        activeTrackings[routeID]?.success = false
        activeTrackings[routeID]?.error = error
    }
}

struct RouteTracking {
    let routeID: String
    let messageID: String
    let messageType: MessageType
    let startTime: Date
    var endTime: Date?
    var success: Bool = false
    var error: Error?
}

// MARK: - 統計和監控
struct RoutingMetrics {
    var totalMessages: Int = 0
    var successfulRoutes: Int = 0
    var failedRoutes: Int = 0
    var averageLatency: Double = 0.0
    var messageTypeStats: [MessageType: Int] = [:]
}

struct RouteInfo {
    let routeDescription: String
    let averageLatency: Double
    let successRate: Double
    let lastUsed: Date
}

struct RoutingInsights {
    let hotspots: [String]
    let bottlenecks: [String]
    let optimizationSuggestions: [String]
}

// MARK: - 錯誤類型
enum RoutingError: Error, LocalizedError {
    case noRouteFound(messageType: MessageType)
    case handlerNotFound
    case invalidMessage(String)
    case routingTimeout
    case destinationUnreachable
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound(let messageType):
            return "無法找到 \(messageType.rawValue) 類型訊息的路由"
        case .handlerNotFound:
            return "路由處理器未找到"
        case .invalidMessage(let reason):
            return "無效訊息: \(reason)"
        case .routingTimeout:
            return "路由超時"
        case .destinationUnreachable:
            return "目標不可達"
        }
    }
}