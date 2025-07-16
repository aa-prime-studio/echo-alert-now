# 🚨 SignalAir 安全警報完整對照表

## 📋 警報類型總覽

SignalAir 系統支援 **8 種不同的安全警報類型**，每種警報都有特定的視覺設計和用戶指導。

---

## 🔴 1. 信任異常警報 (Trust Anomaly)

### 警報顯示
- **標題**: 🚨 可疑訊息檢測！
- **內容**: 設備 [設備名稱] 發送了不安全的訊息，可能影響您的通訊。
- **建議**: 請停止與此設備通訊，並檢查設備安全。
- **嚴重程度**: 高 (High)
- **圖示**: ⚠️ 三角形警告
- **顏色**: 橙色 (Orange)

### 觸發攻擊類型
- `trust_abuse_attack` - 原始信任濫用攻擊
- `advanced_trust_abuse` - 高級信任濫用攻擊
  - TRUST_SCORE_MANIPULATION
  - IDENTITY_SPOOFING_ADVANCED
  - BASELINE_CORRUPTION
  - BEHAVIORAL_MIMICRY
  - TRUST_RELATIONSHIP_ABUSE
  - CREDENTIAL_HARVESTING
  - SESSION_HIJACKING
  - PRIVILEGE_ESCALATION_ATTEMPT

---

## 🟡 2. 節點異常警報 (Node Anomaly)

### 警報顯示
- **標題**: 🚨 設備運行異常！
- **內容**: 設備 [設備名稱] 出現異常行為，可能影響網路穩定。
- **建議**: 請檢查設備狀態並暫停其連線。
- **嚴重程度**: 中 (Medium)
- **圖示**: 📶 WiFi 警告
- **顏色**: 黃色 (Yellow)

### 觸發攻擊類型
- `node_anomaly_attack` - 節點異常攻擊
- `reconnaissance_attack` - 偵察攻擊
  - NETWORK_TOPOLOGY_SCAN
  - PORT_ENUMERATION
  - SERVICE_DISCOVERY
  - VULNERABILITY_PROBE
  - DEVICE_FINGERPRINTING
  - PROTOCOL_ANALYSIS
  - TRAFFIC_PATTERN_ANALYSIS
  - SECURITY_WEAKNESS_DETECTION

---

## 🔴 3. 高級威脅警報 (APT Threat)

### 警報顯示
- **標題**: 🚨 高級威脅檢測！
- **內容**: 設備 [設備名稱] 試圖探測您的網路，可能危害通訊安全。
- **建議**: 請立即斷開與此設備的連線。
- **嚴重程度**: 危急 (Critical)
- **圖示**: 🛡️ 盾牌斜線
- **顏色**: 紅色 (Red)

### 觸發攻擊類型
- `apt_attack` - 原始 APT 攻擊
- `apt_campaign` - APT 攻擊鏈
  - SPEAR_PHISHING → MALWARE_DEPLOYMENT → SYSTEM_COMPROMISE
  - WATERING_HOLE → ZERO_DAY_EXPLOIT → BACKDOOR_INSTALLATION
  - SUPPLY_CHAIN_ATTACK → LATERAL_MOVEMENT → PERSISTENCE_MECHANISM
  - SOCIAL_ENGINEERING → CREDENTIAL_THEFT → PRIVILEGE_ESCALATION
  - INSIDER_THREAT → DATA_STAGING → COVERT_CHANNEL_SETUP
- `destructive_attack` (特定子類型)
  - PERSISTENT_BACKDOOR
  - FINAL_PAYLOAD_DELIVERY

---

## 🔵 4. 網路流量異常警報 (Connection Limit)

### 警報顯示
- **標題**: 🚨 網路流量異常！
- **內容**: 檢測到大量訊息試圖干擾您的通訊網路。
- **建議**: 請保持設備連線，系統正在自動處理。
- **嚴重程度**: 高 (High)
- **圖示**: 🛡️ 網路盾牌
- **顏色**: 藍色 (Blue)

### 觸發攻擊類型
- `ddos_attack` - DDoS 攻擊
- `hybrid_attack` (特定子類型)
  - DDOS_AMPLIFICATION
  - BOTNET_COORDINATION

---

## 🔴 5. 數據外洩警報 (Data Exfiltration)

### 警報顯示
- **標題**: 🚨 數據洩露風險！
- **內容**: 設備 [設備名稱] 試圖傳送敏感數據，可能危害您的資訊。
- **建議**: 請斷開設備連線並檢查數據安全。
- **嚴重程度**: 危急 (Critical)
- **圖示**: 🔒 鎖頭斜線
- **顏色**: 紅色 (Red)

### 觸發攻擊類型
- `data_exfiltration_attack` - 數據外洩攻擊
- `evasion_attack` - 逃避檢測攻擊
  - STEGANOGRAPHY_HIDING
  - TRAFFIC_OBFUSCATION
  - ENCRYPTION_BYPASS
  - PROTOCOL_TUNNELING
  - COVERT_TIMING_CHANNEL
  - FRAGMENTATION_ATTACK
  - POLYMORPHIC_ENCODING
  - ANTI_FORENSIC_TECHNIQUES
  - LOG_TAMPERING
  - EVIDENCE_DESTRUCTION

---

## 🟠 6. 設備認證失敗警報 (Authentication Failure)

### 警報顯示
- **標題**: 🚨 設備認證失敗！
- **內容**: 設備 [設備名稱] 無法通過安全認證，可能存在風險。
- **建議**: 請檢查設備身份並重新連線。
- **嚴重程度**: 中 (Medium)
- **圖示**: 👤 人員減號
- **顏色**: 橙色 (Orange)

### 觸發攻擊類型
- 目前沒有直接觸發此警報的攻擊類型
- 預留給未來的認證相關攻擊

---

## 🔴 7. 系統入侵警報 (System Compromise)

### 警報顯示
- **標題**: 🚨 多重安全威脅！
- **內容**: 設備 [設備名稱] 發起多種可疑活動，可能影響您的通訊。
- **建議**: 請立即斷開連線並重新啟動應用程式。
- **嚴重程度**: 危急 (Critical)
- **圖示**: 🛑 八角形警告
- **顏色**: 紅色 (Red)

### 觸發攻擊類型
- `hybrid_attack` (特定子類型)
  - RANSOMWARE_DEPLOYMENT
  - SYSTEM_DESTRUCTION
  - 其他未分類的混合攻擊
- `destructive_attack` (特定子類型)
  - SYSTEM_DESTRUCTION
  - DATA_CORRUPTION
  - NETWORK_DISRUPTION
  - 其他未分類的破壞性攻擊

---

## 🔴 8. 惡意軟體警報 (Malware Detection)

### 警報顯示
- **標題**: 🚨 可疑軟體檢測！
- **內容**: 設備 [設備名稱] 可能運行惡意軟體，威脅網路安全。
- **建議**: 請立即斷開連線並掃描設備。
- **嚴重程度**: 危急 (Critical)
- **圖示**: 🐛 螞蟻
- **顏色**: 紅色 (Red)

### 觸發攻擊類型
- `hybrid_attack` (特定子類型)
  - CRYPTOJACKING
  - ROOTKIT_INSTALLATION
- `destructive_attack` (特定子類型)
  - DEVICE_BRICK_ATTEMPT
  - FIRMWARE_CORRUPTION

---

## 📊 攻擊階段與警報映射

### 階段1: 偵察和初始滲透 (0-60秒)
- **攻擊類型**: reconnaissance_attack
- **觸發警報**: 🟡 節點異常警報
- **攻擊數量**: 8次

### 階段2: 持續信任濫用攻擊 (60-180秒)
- **攻擊類型**: advanced_trust_abuse
- **觸發警報**: 🔴 信任異常警報
- **攻擊數量**: 40次

### 階段3: 多階段APT攻擊 (180-300秒)
- **攻擊類型**: apt_campaign
- **觸發警報**: 🔴 高級威脅警報
- **攻擊數量**: 15次

### 階段4: 混合攻擊模式 (300-420秒)
- **攻擊類型**: hybrid_attack
- **觸發警報**: 🔵 網路流量異常 / 🔴 系統入侵 / 🔴 惡意軟體
- **攻擊數量**: 150次

### 階段5: 數據外洩和逃避檢測 (420-540秒)
- **攻擊類型**: evasion_attack
- **觸發警報**: 🔴 數據外洩警報
- **攻擊數量**: 120次

### 階段6: 最終破壞性攻擊 (540-600秒)
- **攻擊類型**: destructive_attack
- **觸發警報**: 🔴 系統入侵 / 🔴 惡意軟體 / 🔴 高級威脅
- **攻擊數量**: 40次

---

## 🎨 視覺設計規範

### 文字大小
- **標題**: 16pt (semibold)
- **內容**: 14pt (regular)
- **建議**: 12pt (medium)

### 文字顏色
- **標題與內容**: 黑色
- **建議文字**: 藍色

### 背景設計
- **背景色**: 白色 (100% opacity)
- **邊框**: 灰色 (40% opacity)
- **圓角**: 12pt
- **陰影**: 黑色 (10% opacity)

### 顯示邏輯
- **自動消失**: 8秒後自動關閉
- **手動關閉**: 點擊 X 按鈕
- **佇列管理**: 最多5個警報排隊
- **動畫效果**: 滑入滑出動畫

---

## 🔍 測試驗證

運行增強攻擊器時，您會看到以下警報順序：

1. 🟡 **節點異常** (8次) - 偵察階段
2. 🔴 **信任異常** (40次) - 信任濫用階段
3. 🔴 **高級威脅** (15次) - APT攻擊階段
4. 🔵🔴 **多種警報** (150次) - 混合攻擊階段
5. 🔴 **數據外洩** (120次) - 逃避檢測階段
6. 🔴 **系統入侵/惡意軟體/高級威脅** (40次) - 破壞性攻擊階段

**總計**: 373次攻擊，觸發8種不同類型的安全警報！