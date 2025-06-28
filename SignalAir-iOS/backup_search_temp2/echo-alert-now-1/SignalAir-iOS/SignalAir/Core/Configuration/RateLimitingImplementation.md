# 速率限制實作文檔

## 概述
為了防止系統在高頻率緊急救援場景中過載，我們為 MessageDeduplicator 添加了全面的速率限制功能。

## 核心組件

### 1. DeduplicationError 枚舉
```swift
enum DeduplicationError: Error, LocalizedError {
    case rateLimitExceeded      // 速率限制超過
    case invalidMessageFormat   // 訊息格式無效
    case systemOverload        // 系統過載
    case cacheCorrupted        // 快取損壞
}
```

### 2. RateLimiter 類
```swift
class RateLimiter {
    private let maxQueriesPerMinute: Int = 1000  // 每分鐘最多1000次
    private let maxQueriesPerSecond: Int = 50    // 每秒最多50次
    private var queryCounter = 0
    private var secondCounter = 0
}
```

## 速率限制策略

### 雙重限制機制
- **每秒限制**: 50 次查詢/秒
- **每分鐘限制**: 1000 次查詢/分鐘

### 統計追蹤
- 總查詢次數
- 被拒絕查詢次數
- 使用率計算
- 重置倒數計時

## MessageDeduplicator 增強功能

### 1. 速率限制整合
```swift
func isDuplicate(messageID: String, senderID: String, timestamp: Date, content: Data) throws -> Bool {
    // 首先檢查速率限制
    try rateLimiter.checkRateLimit()
    
    // 檢查系統健康狀態
    try checkSystemHealth()
    
    // 執行去重邏輯...
}
```

### 2. 系統健康監控
- **連續錯誤追蹤**: 最多允許10次連續錯誤
- **健康狀態檢查**: 每30秒檢查一次系統狀態
- **自動保護機制**: 錯誤過多時觸發系統保護

### 3. 安全模式
```swift
func isDuplicateSafe(messageID: String, senderID: String, timestamp: Date, content: Data) -> (isDuplicate: Bool, error: Error?) {
    // 不拋出異常的安全版本
    // 發生錯誤時保守地視為重複
}
```

## 配置參數

### 速率限制設定
| 參數 | 預設值 | 說明 |
|------|--------|------|
| maxQueriesPerMinute | 1000 | 每分鐘最大查詢次數 |
| maxQueriesPerSecond | 50 | 每秒最大查詢次數 |
| maxConsecutiveErrors | 10 | 最大連續錯誤次數 |
| healthCheckInterval | 30秒 | 健康檢查間隔 |

### 緊急救援場景優化
- **高頻率支援**: 能處理突發的大量訊息
- **錯誤恢復**: 自動從錯誤狀態恢復
- **資源保護**: 防止系統資源耗盡

## 統計與監控

### RateLimitStatistics 結構
```swift
struct RateLimitStatistics {
    let currentQueriesPerMinute: Int
    let maxQueriesPerMinute: Int
    let currentQueriesPerSecond: Int
    let maxQueriesPerSecond: Int
    let totalQueries: Int
    let rejectedQueries: Int
    let timeUntilReset: TimeInterval
    let utilizationRate: Double
}
```

### DeduplicationSystemStats 結構
```swift
struct DeduplicationSystemStats {
    let cacheCount: Int
    let cacheCapacity: Int
    let cacheUtilization: Double
    let rateLimitUtilization: Double
    let totalQueries: Int
    let rejectedQueries: Int
    let consecutiveErrors: Int
    let systemHealth: String
}
```

## 使用範例

### 基本使用
```swift
let deduplicator = MessageDeduplicator()

do {
    let isDuplicate = try deduplicator.isDuplicate(
        messageID: "MSG_001",
        senderID: "DEVICE_A",
        timestamp: Date(),
        content: messageData
    )
    
    if isDuplicate {
        print("重複訊息，忽略")
    } else {
        print("新訊息，處理")
    }
} catch DeduplicationError.rateLimitExceeded {
    print("速率限制觸發，請稍後重試")
} catch {
    print("其他錯誤: \(error)")
}
```

### 安全模式使用
```swift
let result = deduplicator.isDuplicateSafe(
    messageID: "MSG_002",
    senderID: "DEVICE_B", 
    timestamp: Date(),
    content: messageData
)

if let error = result.error {
    print("發生錯誤: \(error.localizedDescription)")
}

if result.isDuplicate {
    print("重複或錯誤，忽略訊息")
}
```

### 統計監控
```swift
let stats = deduplicator.getSystemStats()
print(stats.summary)

let rateLimitStats = deduplicator.getRateLimitStats()
print("使用率: \(String(format: "%.1f", rateLimitStats.utilizationRate * 100))%")
```

## 錯誤處理策略

### 1. 速率限制觸發
- **立即響應**: 拋出 `rateLimitExceeded` 錯誤
- **建議行動**: 等待1分鐘或降低發送頻率
- **自動恢復**: 計數器每分鐘自動重置

### 2. 系統過載保護
- **觸發條件**: 連續錯誤達到10次
- **保護措施**: 拋出 `systemOverload` 錯誤
- **恢復機制**: 成功處理後重置錯誤計數

### 3. 降級策略
- **安全模式**: 使用 `isDuplicateSafe` 方法
- **保守處理**: 錯誤時視為重複訊息
- **系統穩定**: 避免級聯失敗

## 性能影響

### 記憶體使用
- **速率限制器**: 極小的記憶體開銷
- **統計資料**: 約100字節額外記憶體
- **錯誤追蹤**: 忽略不計的開銷

### 處理延遲
- **速率檢查**: < 1ms 額外延遲
- **健康檢查**: 每30秒一次，忽略不計
- **統計更新**: 極小的 CPU 開銷

### 吞吐量限制
- **正常情況**: 50 QPS，1000 QPM
- **突發處理**: 短期內可處理更高頻率
- **長期穩定**: 確保系統可持續運行

## 調優建議

### 緊急情況調整
```swift
// 提高限制（緊急情況）
let emergencyRateLimiter = RateLimiter(
    maxQueriesPerMinute: 2000,  // 提高到2000
    maxQueriesPerSecond: 100    // 提高到100
)

let deduplicator = MessageDeduplicator(rateLimiter: emergencyRateLimiter)
```

### 資源受限調整
```swift
// 降低限制（資源受限）
let conservativeRateLimiter = RateLimiter(
    maxQueriesPerMinute: 500,   // 降低到500
    maxQueriesPerSecond: 25     // 降低到25
)
```

## 監控告警

### 關鍵指標
- 速率限制使用率 > 80%
- 被拒絕查詢率 > 5%
- 連續錯誤 > 5次
- 系統健康狀態 != "正常"

### 建議告警閾值
```swift
if rateLimitStats.utilizationRate > 0.8 {
    // 發送警告：速率限制使用率過高
}

if rateLimitStats.rejectedQueries > rateLimitStats.totalQueries * 0.05 {
    // 發送告警：拒絕率過高
}

if systemStats.consecutiveErrors > 5 {
    // 發送緊急告警：系統不穩定
}
```

## 結論

速率限制功能為 SignalAir Rescue 系統提供了強大的保護機制，確保在高壓力緊急救援場景下系統的穩定性和可靠性。通過雙重限制、健康監控和安全降級，系統能夠優雅地處理各種異常情況，同時保持高效的訊息處理能力。 