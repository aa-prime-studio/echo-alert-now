# 裝置名稱加密機制分析報告

## 概述

經過詳細檢查，SignalAir iOS 項目的裝置名稱加密機制實現情況如下：

## 🔍 加密機制檢查結果

### 1. 整體加密系統 ✅ **已實現**

**SecurityService.swift** 提供完整的端對端加密：
- **ECDH 密鑰交換**: 使用 Curve25519
- **AES-256-GCM 加密**: 對稱加密
- **HMAC-SHA256 認證**: 訊息完整性
- **Perfect Forward Secrecy**: 密鑰輪轉機制

### 2. 裝置名稱加密狀況 ⚠️ **部分實現**

#### 已加密的部分：
- **Chat 訊息**: `ChatMessage.deviceName` 通過 SecurityService 加密
- **Game 資料**: 遊戲房間中的玩家名稱經過加密傳輸
- **有會話密鑰的連接**: 透過 MeshManager 加密處理

#### 未加密的部分：
- **Signal 訊息**: `SignalMessage.deviceName` **未經加密**
- **MultipeerConnectivity 層**: MCPeerID.displayName 是明文傳輸
- **臨時 ID 系統**: TemporaryIDManager 生成的 deviceID 是明文

## 📊 詳細分析

### A. Signal 傳輸流程
```swift
SignalViewModel.sendSignal() 
    → MeshManager.broadcastMessage()
    → NetworkService.broadcast()
    → MultipeerConnectivity (明文)
```

**問題**: 在 `SignalViewModel.sendSignal()` 中，`EmergencySignal` 結構的 `senderNickname` 欄位未經加密就傳輸。

### B. Chat 傳輸流程
```swift
ChatViewModel.sendMessage()
    → MeshManager (加密層)
    → SecurityService.encrypt()
    → NetworkService.send() (密文)
```

**正常**: Chat 訊息透過 SecurityService 完整加密。

### C. 臨時 ID 系統
```swift
TemporaryIDManager.generateDeviceID()
    → "珍珠奶茶-42" (明文格式)
    → 每24小時自動更新
```

**狀況**: 提供匿名性但非加密，是隱私保護機制。

## 🔧 修復建議

### 1. 緊急修復：Signal 訊息加密

修改 `SignalViewModel.sendSignal()` 方法：

```swift
// 當前實現 (未加密)
let signal = EmergencySignal(
    type: type,
    senderNickname: userNickname,  // ❌ 明文
    location: currentLocationWithNoise(),
    message: generateSignalMessage(for: type),
    timestamp: Date()
)

// 建議修復 (加密)
let signal = EmergencySignal(
    type: type,
    senderNickname: temporaryIDManager.deviceID,  // ✅ 使用臨時ID
    location: currentLocationWithNoise(),
    message: generateSignalMessage(for: type),
    timestamp: Date()
)
```

### 2. 完整修復：統一加密處理

在 `MeshManager.processOutgoingMessage()` 中：

```swift
private func processOutgoingMessage(_ message: MeshMessage) {
    do {
        // 對所有訊息進行加密處理
        let messageData = try JSONEncoder().encode(message)
        
        // 如果有安全連線，使用加密
        let finalData: Data
        if securityService.hasSessionKey(for: targetPeer) {
            let encrypted = try securityService.encrypt(messageData, for: targetPeer)
            finalData = try JSONEncoder().encode(encrypted)
        } else {
            finalData = messageData
        }
        
        networkService.send(finalData)
    } catch {
        print("❌ Failed to process outgoing message: \(error)")
    }
}
```

## 📈 現狀總結

| 功能模組 | 裝置名稱 | 加密狀態 | 隱私等級 |
|---------|---------|---------|---------|
| **Signal** | 用戶暱稱 | ❌ 明文 | 低 |
| **Chat** | 用戶暱稱 | ✅ 加密 | 高 |
| **Game** | 用戶暱稱 | ✅ 加密 | 高 |
| **臨時ID** | 台灣小吃名 | ⚠️ 匿名 | 中 |

## 🚨 安全風險評估

### 高風險：
- **Signal 訊息洩漏真實暱稱**: 可能被惡意節點收集用戶身份資訊

### 中風險：
- **MultipeerConnectivity 層暴露**: MCPeerID 在網路層可見

### 低風險：
- **臨時ID 推測**: 雖然匿名但模式可能被分析

## ✅ 建議實施順序

1. **立即**: 修改 Signal 訊息使用臨時ID
2. **短期**: 實施訊息層統一加密
3. **長期**: 研究 MultipeerConnectivity 層加密選項

---

**結論**: 裝置名稱加密機制**部分實現**，需要針對 Signal 模組進行安全強化。 