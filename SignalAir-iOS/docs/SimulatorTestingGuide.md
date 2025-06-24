# SignalAir iOS 模擬器測試指南

## 📱 MultipeerConnectivity 模擬器測試

### ⚠️ 重要須知

MultipeerConnectivity 在 iOS 模擬器上的行為與實體裝置有所不同：

- **支援度**：iOS 模擬器支援 MultipeerConnectivity 的大部分功能
- **限制**：藍牙功能在模擬器上被模擬，Wi-Fi Direct 完全可用
- **網路**：多個模擬器可以在同一台 Mac 上相互發現和連接

---

## 🔧 測試環境設定

### 1. 基本要求

```bash
# 確認 Xcode 版本 (需要 14.0+)
xcode-select --version

# 確認可用的模擬器
xcrun simctl list devices | grep "iOS"
```

### 2. 創建多裝置測試環境

```bash
# 啟動第一個模擬器（iPhone 14）
xcrun simctl boot "iPhone 14"

# 啟動第二個模擬器（iPhone 14 Pro）
xcrun simctl boot "iPhone 14 Pro"

# 檢查模擬器狀態
xcrun simctl list devices | grep "Booted"
```

### 3. 專案配置

確保 `Info.plist` 包含必要的權限：

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>SignalAir 需要本地網路權限以建立 P2P 連接</string>

<key>NSBonjourServices</key>
<array>
    <string>_signalair._tcp</string>
</array>
```

---

## 🧪 測試步驟

### Phase 1: 單一模擬器基礎測試

#### 1.1 啟動應用程式

```bash
# 在第一個模擬器上安裝並運行
xcodebuild -project SignalAir Rescue.xcodeproj \
           -scheme SignalAir \
           -destination 'platform=iOS Simulator,name=iPhone 14' \
           clean build

# 在模擬器中啟動應用程式
open -a Simulator
```

#### 1.2 服務初始化測試

在 Xcode Console 中查看以下日誌：

```
🚀 ServiceContainer: 開始初始化服務容器...
🔧 ServiceContainer: 配置服務依賴關係...
✅ ServiceContainer: 服務容器初始化完成
📊 App Health Status: [健康狀態]
```

#### 1.3 基本功能測試

1. **設定功能**：修改暱稱 → 檢查是否同步到各 ViewModel
2. **聊天功能**：發送測試訊息 → 檢查本地顯示
3. **信號功能**：發送各種類型信號 → 檢查訊息列表
4. **遊戲功能**：建立房間 → 檢查房間狀態

### Phase 2: 雙模擬器 P2P 測試

#### 2.1 準備兩個模擬器

```bash
# 終端 1：啟動第一個模擬器
xcrun simctl boot "iPhone 14"
# 設定暱稱：「測試者A」

# 終端 2：啟動第二個模擬器  
xcrun simctl boot "iPhone 14 Pro"
# 設定暱稱：「測試者B」
```

#### 2.2 網路發現測試

1. **在兩個模擬器上同時啟動 SignalAir**
2. **檢查 Console 輸出**：
   ```
   📡 NetworkService: 開始廣播服務...
   🔍 NetworkService: 發現裝置: [裝置名稱]
   🤝 NetworkService: 連接成功: [裝置ID]
   ```

3. **驗證連接狀態**：
   - 檢查 "連線狀態" 顯示 "已連線"
   - 檢查 "已連線裝置" 列表包含對方

#### 2.3 聊天功能 P2P 測試

```markdown
測試步驟：
1. 測試者A 發送：「你好，我是 A」
2. 測試者B 應該收到訊息
3. 測試者B 回覆：「你好，我是 B」
4. 測試者A 應該收到回覆

預期結果：
- 雙向訊息傳遞成功
- 訊息顯示正確的發送者暱稱
- 時間戳記正確
- 無重複訊息
```

#### 2.4 信號功能 P2P 測試

```markdown
測試案例：
1. 安全信號：測試者A 發送 → 測試者B 接收
2. 求助信號：測試者B 發送 → 測試者A 接收  
3. 緊急信號：測試高優先級處理

驗證項目：
- 信號正確傳遞
- 優先級正確處理
- 位置資訊包含適當雜訊
- 防洪水機制運作正常
```

#### 2.5 遊戲功能 P2P 測試

```markdown
Bingo 遊戲測試：
1. 測試者A 建立房間「測試房間」
2. 測試者B 加入房間
3. 開始遊戲
4. 測試數字抽取同步
5. 測試遊戲進度同步

檢查項目：
- 房間列表正確顯示
- 玩家加入/離開正確處理
- 遊戲狀態同步
- 訊息廣播正確
```

### Phase 3: 多模擬器壓力測試

#### 3.1 三裝置以上測試

```bash
# 啟動多個模擬器
for device in "iPhone 14" "iPhone 14 Pro" "iPhone 15" "iPad Air"; do
    xcrun simctl boot "$device" 2>/dev/null || echo "跳過 $device"
done
```

#### 3.2 網路負載測試

```markdown
測試項目：
1. 同時 10 條聊天訊息
2. 連續緊急信號發送
3. 多房間同時遊戲
4. 網路中斷/重連測試

效能指標：
- 訊息延遲 < 1 秒
- CPU 使用率 < 50%
- 記憶體使用穩定
- 無記憶體洩漏
```

---

## 🔍 除錯指南

### 常見問題與解決方案

#### 1. 模擬器無法發現彼此

**問題**：兩個模擬器無法建立連接

**解決方案**：
```bash
# 重置網路設定
xcrun simctl shutdown all
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# 重新啟動模擬器
xcrun simctl boot "iPhone 14"
xcrun simctl boot "iPhone 14 Pro"
```

#### 2. 連接頻繁中斷

**檢查項目**：
- Mac 的防火牆設定
- 網路環境穩定性
- 模擬器資源使用量

**監控指令**：
```bash
# 監控網路活動
sudo netstat -rn | grep 127.0.0.1

# 檢查模擬器進程
ps aux | grep Simulator
```

#### 3. 訊息重複或遺失

**除錯步驟**：
1. 檢查洪水保護機制
2. 驗證訊息雜湊去重
3. 檢查網路封包順序

**Console 關鍵字**：
```
🛡️ FloodProtection: 
🔒 SecurityService: 
📨 MeshManager: 
```

### 效能監控

#### 使用 Instruments

```bash
# 啟動 Memory 監控
instruments -t "Leaks" -D leak_trace.trace YourApp.app

# 啟動 Network 監控  
instruments -t "Network" -D network_trace.trace YourApp.app
```

#### Console 監控關鍵指標

```markdown
服務健康度：
- ServiceContainer 初始化狀態
- 網路連接穩定性
- 記憶體使用量
- 錯誤發生頻率

效能指標：
- 訊息發送延遲
- 遊戲狀態同步時間
- UI 響應時間
- 背景處理效率
```

---

## 📊 自動化測試腳本

### 基本測試腳本

```bash
#!/bin/bash
# run_simulator_tests.sh

echo "🚀 開始 SignalAir 模擬器測試"

# 1. 清理環境
xcrun simctl shutdown all
sleep 2

# 2. 啟動模擬器
echo "📱 啟動測試模擬器..."
xcrun simctl boot "iPhone 14" &
xcrun simctl boot "iPhone 14 Pro" &
wait

# 3. 安裝應用程式
echo "📦 安裝應用程式..."
xcodebuild -project SignalAir Rescue.xcodeproj \
           -scheme SignalAir \
           -destination 'platform=iOS Simulator,name=iPhone 14' \
           clean build | grep -E "(SUCCEEDED|FAILED)"

# 4. 運行單元測試
echo "🧪 執行單元測試..."
xcodebuild test \
           -project SignalAir Rescue.xcodeproj \
           -scheme SignalAir \
           -destination 'platform=iOS Simulator,name=iPhone 14'

# 5. 運行整合測試
echo "🔗 執行整合測試..."
xcodebuild test \
           -project SignalAir Rescue.xcodeproj \
           -scheme SignalAir \
           -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

echo "✅ 測試完成"
```

### 執行權限設定

```bash
chmod +x run_simulator_tests.sh
./run_simulator_tests.sh
```

---

## ✅ 測試檢查清單

### 基礎功能 ✓

- [ ] 應用程式啟動無崩潰
- [ ] 服務容器正確初始化
- [ ] 所有 ViewModel 正常創建
- [ ] 設定功能正常運作
- [ ] UI 響應正常

### 網路功能 ✓

- [ ] MultipeerConnectivity 服務啟動
- [ ] 裝置發現機制運作
- [ ] P2P 連接建立成功
- [ ] 連接狀態正確顯示
- [ ] 網路中斷重連機制

### 聊天功能 ✓

- [ ] 訊息發送成功
- [ ] 訊息接收正確
- [ ] 加密/解密正常
- [ ] 自毀計時器運作
- [ ] 洪水保護機制

### 信號功能 ✓

- [ ] 各類型信號發送
- [ ] 緊急信號優先處理
- [ ] 位置資訊正確
- [ ] 信號歷史記錄

### 遊戲功能 ✓

- [ ] 房間建立/加入
- [ ] 玩家管理
- [ ] 遊戲狀態同步
- [ ] 數字抽取同步
- [ ] 遊戲結果處理

### 整合測試 ✓

- [ ] 跨模組通訊
- [ ] 服務共享正確
- [ ] 資料一致性
- [ ] 錯誤處理優雅
- [ ] 效能指標達標

---

## 📝 測試報告範本

```markdown
# SignalAir 模擬器測試報告

## 測試環境
- Xcode 版本：15.0
- iOS 模擬器版本：17.0
- 測試裝置：iPhone 14, iPhone 14 Pro
- 測試日期：2024-01-XX

## 測試結果

### 單元測試
- 服務容器測試：✅ 通過 (12/12)
- ViewModel 測試：✅ 通過 (8/8)
- 網路服務測試：✅ 通過 (6/6)

### 整合測試  
- 聊天功能：✅ 通過 (5/5)
- 信號功能：✅ 通過 (4/4)
- 遊戲功能：✅ 通過 (6/6)
- 跨模組測試：✅ 通過 (4/4)

### 效能測試
- 記憶體使用：< 50MB ✅
- CPU 使用率：< 30% ✅
- 訊息延遲：< 500ms ✅
- 啟動時間：< 3s ✅

## 發現問題
無重大問題發現

## 建議改進
1. 優化啟動時間
2. 提高網路重連速度

## 測試結論
✅ 系統整合測試通過，準備進入下一階段開發
``` 