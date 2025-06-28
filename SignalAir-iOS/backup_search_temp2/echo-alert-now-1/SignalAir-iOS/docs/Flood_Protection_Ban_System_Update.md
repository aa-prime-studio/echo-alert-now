# 🛡️ 洪水保护系统 - 阶梯式封禁机制更新

## 📋 更新概述

根据用户需求，已实现更严格的阶梯式封禁机制：
- **可疑阈值**：同一内容出现 **5次以上** 开始封禁
- **第1-2次封禁**：封禁 **2小时**
- **第3次封禁**：封禁 **5天**（最终封禁）

## 🔧 技术实现

### 1. 可疑内容检测机制

#### 原有机制
```swift
// 旧版本：只检测可疑内容，未区分节点
func checkSuspiciousContent(_ data: Data) -> Bool
```

#### 新机制
```swift
// 新版本：按节点跟踪可疑内容，支持精确封禁
func checkSuspiciousContent(_ data: Data, from peerID: String) -> (isSuspicious: Bool, shouldBan: Bool)
```

**关键改进**：
- 按节点分别跟踪可疑内容发送历史
- 只封禁实际发送可疑内容的节点
- 避免误封无辜节点

### 2. 阶梯式封禁系统

#### 封禁历史跟踪
```swift
private var banHistory: [String: Int] = [:] // 记录每个节点的封禁次数

// 封禁时长配置
private let firstBanDuration: TimeInterval = 7200   // 2小时
private let finalBanDuration: TimeInterval = 432000 // 5天
private let maxBanCount = 3 // 最大封禁次数
```

#### 封禁逻辑
```swift
func banPeerForSuspiciousContent(_ peerID: String) {
    let currentBanCount = banHistory[peerID, default: 0] + 1
    banHistory[peerID] = currentBanCount
    
    let banDuration: TimeInterval
    switch currentBanCount {
    case 1, 2:
        banDuration = firstBanDuration // 2小时
    case maxBanCount:
        banDuration = finalBanDuration // 5天
    default:
        banDuration = finalBanDuration // 5天（持续）
    }
}
```

## 📊 封禁统计功能

### 新增数据结构

#### BanStatistics
```swift
struct BanStatistics {
    let currentlyBanned: Int      // 当前被封禁的节点数
    let totalWithHistory: Int     // 有封禁历史的节点总数
    let firstTimeBanned: Int      // 第一次被封禁的节点数
    let secondTimeBanned: Int     // 第二次被封禁的节点数
    let finallyBanned: Int        // 第三次及以上被封禁的节点数
}
```

#### SuspiciousActivityStats
```swift
struct SuspiciousActivityStats {
    let totalSuspiciousMessages: Int    // 总可疑消息数
    let uniqueSuspiciousHashes: Int     // 独特可疑内容哈希数
    let mostFrequentCount: Int          // 最频繁内容的出现次数
}
```

## 🔍 新增管理方法

### 封禁历史管理
```swift
// 获取节点封禁历史
func getBanHistory(for peerID: String) -> Int

// 获取所有节点封禁历史
func getAllBanHistory() -> [String: Int]

// 重置节点封禁历史（管理员功能）
func resetBanHistory(for peerID: String)

// 清除所有封禁历史（管理员功能）
func clearAllBanHistory()

// 获取封禁统计信息
func getBanStatistics() -> BanStatistics
```

### 可疑活动管理
```swift
// 获取节点可疑活动统计
func getSuspiciousActivityStats(for peerID: String) -> SuspiciousActivityStats

// 清理节点可疑活动记录
func clearSuspiciousActivity(for peerID: String)
```

## 🚨 封禁流程示例

### 场景：节点发送重复垃圾消息

#### 第1次触发（同一内容发送5次）
```
🚨 可疑重复内容检测: hash 123456
   - 全局出现次数: 5
   - 节点 peer_A 发送次数: 5
🔨 节点 peer_A 发送可疑重复内容，触发封禁机制
🚨 第1次可疑内容封禁: 封禁节点 peer_A 2小时，到期时间: 2025-06-18 12:13:11
📊 节点 peer_A 累计封禁次数: 1/3
```

#### 第2次触发（解封后再次发送可疑内容）
```
🚨 第2次可疑内容封禁: 封禁节点 peer_A 2小时，到期时间: 2025-06-18 14:13:11
📊 节点 peer_A 累计封禁次数: 2/3
```

#### 第3次触发（最终封禁）
```
🚨 第3次可疑内容封禁（最终封禁）: 封禁节点 peer_A 5天，到期时间: 2025-06-23 10:13:11
📊 节点 peer_A 累计封禁次数: 3/3
```

## 🛠️ 管理员功能

### 查看封禁统计
```swift
let stats = floodProtection.getBanStatistics()
print("当前被封禁节点: \(stats.currentlyBanned)")
print("有封禁历史的节点: \(stats.totalWithHistory)")
print("第一次封禁: \(stats.firstTimeBanned)")
print("第二次封禁: \(stats.secondTimeBanned)")
print("最终封禁: \(stats.finallyBanned)")
```

### 查看节点详细信息
```swift
// 查看特定节点的封禁历史
let banCount = floodProtection.getBanHistory(for: "peer_A")
print("节点 peer_A 封禁次数: \(banCount)")

// 查看节点的可疑活动统计
let suspiciousStats = floodProtection.getSuspiciousActivityStats(for: "peer_A")
print("可疑消息总数: \(suspiciousStats.totalSuspiciousMessages)")
print("独特可疑内容: \(suspiciousStats.uniqueSuspiciousHashes)")
print("最高重复次数: \(suspiciousStats.mostFrequentCount)")
```

### 管理员干预
```swift
// 重置节点封禁历史（给予第二次机会）
floodProtection.resetBanHistory(for: "peer_A")

// 清理节点可疑活动记录
floodProtection.clearSuspiciousActivity(for: "peer_A")

// 手动解封节点
floodProtection.unbanPeer("peer_A")
```

## 🔒 安全特性

### 1. 精确定位
- 只封禁实际发送可疑内容的节点
- 避免连坐误封其他无辜节点

### 2. 渐进式惩罚
- 第1-2次：短期封禁（2小时），给予改正机会
- 第3次：长期封禁（5天），严厉惩罚

### 3. 持久化记录
- 封禁历史持久保存
- 重启应用后仍然有效

### 4. 管理员控制
- 提供完整的管理员干预机制
- 支持重置、清理、手动解封

## 📈 性能优化

### 内存管理
```swift
// 限制哈希缓存大小，防止内存泄漏
private let maxRecentHashes = 1000

// 定期清理过期数据
if recentHashes.count > maxRecentHashes {
    let oldHashes = Array(recentHashes.prefix(maxRecentHashes / 2))
    // 清理逻辑...
}
```

### 线程安全
```swift
// 所有操作都使用锁保护
private let lock = NSLock()

func banPeerForSuspiciousContent(_ peerID: String) {
    lock.lock()
    defer { lock.unlock() }
    // 封禁逻辑...
}
```

## 🎯 效果预期

### 1. 更严格的内容过滤
- 可疑阈值从默认值降低到5次
- 快速识别和处理重复垃圾内容

### 2. 渐进式威慑
- 第一次违规：短期警告性封禁
- 重复违规：长期严厉封禁
- 有效减少恶意行为

### 3. 精确执法
- 只封禁真正的违规者
- 保护正常用户的通信权利

### 4. 完善的管理
- 详细的统计信息
- 灵活的管理员干预选项

## 🔄 版本兼容性

- ✅ 向后兼容现有的FloodProtection API
- ✅ 新增功能不影响现有代码
- ✅ 可选择性启用新的封禁机制

---

**更新时间**: 2025-06-18  
**版本**: v2.0  
**状态**: ✅ 已实现并测试通过 