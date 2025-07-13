# SignalAir 穩定性測試計劃

## 測試目標
驗證階段一修復能否解決「Not in connected state, so giving up for participant」崩潰問題

## 測試環境
- **設備**: iOS Simulator (iPhone 16)
- **iOS版本**: 18.5
- **Xcode版本**: 最新版本
- **測試時間**: 2025-07-07

## 核心崩潰場景重現測試

### 1. 原始崩潰觸發場景
- **場景A**: 快速進入賓果遊戲室
- **場景B**: 網路不穩定時加入房間
- **場景C**: 多次快速切換房間
- **場景D**: 應用程式背景/前景切換

### 2. Timer 相關穩定性測試
- **測試項目**: 定時器記憶體洩漏檢測
- **驗證點**: 7個獨立Timer → 統一管理
- **預期結果**: 無記憶體洩漏，清理完整

### 3. MultipeerConnectivity 通道狀態測試
- **測試項目**: 連接狀態驗證機制
- **驗證點**: validateChannelState() 方法
- **預期結果**: 在發送前正確驗證通道狀態

### 4. 併發安全性測試
- **測試項目**: Swift 6 MainActor 隔離
- **驗證點**: Timer 方法的併發安全性
- **預期結果**: 無競爭條件，無崩潰

## 測試執行命令

```bash
# 1. 編譯驗證
xcodebuild -scheme "SignalAir" -configuration Debug build

# 2. 單元測試執行
xcodebuild test -scheme "SignalAir" -destination "platform=iOS Simulator,name=iPhone 16"

# 3. 記憶體洩漏檢測
# 使用 Instruments 或 Xcode Memory Debugger

# 4. 壓力測試
# 重複進入/退出賓果遊戲室 50 次
```

## 成功標準

### ✅ 基本功能正常
- [ ] 可以正常進入賓果遊戲室
- [ ] Timer 正常工作（倒數計時、遊戲同步等）
- [ ] 網路連接穩定
- [ ] UI 響應正常

### ✅ 崩潰修復驗證
- [ ] 不再出現「Not in connected state」錯誤
- [ ] BingoGameViewModel 初始化不崩潰
- [ ] 快速操作不引發崩潰
- [ ] 背景/前景切換穩定

### ✅ 性能改善
- [ ] 記憶體使用量減少
- [ ] Timer 數量從 7 個減少到統一管理
- [ ] 應用程式響應速度提升
- [ ] 電池使用量優化

## 測試結果記錄

### 階段一改進驗證
| 改進項目 | 測試狀態 | 結果 | 備註 |
|---------|---------|------|------|
| StableNetworkManager | ⏳ 待測試 | - | 簡化網路管理 |
| Timer 統一管理 | ⏳ 待測試 | - | 7→1 整合 |
| 初始化邏輯簡化 | ⏳ 待測試 | - | 併發安全 |
| 編譯成功 | ✅ 完成 | 通過 | BUILD SUCCEEDED |

### 崩潰場景測試結果
| 場景 | 測試次數 | 崩潰次數 | 成功率 | 狀態 |
|------|---------|---------|--------|------|
| 快速進入遊戲室 | 0 | 0 | - | ⏳ 待測試 |
| 網路不穩定加入 | 0 | 0 | - | ⏳ 待測試 |
| 快速切換房間 | 0 | 0 | - | ⏳ 待測試 |
| 背景前景切換 | 0 | 0 | - | ⏳ 待測試 |

---

**測試執行者**: 測試工程師 + 性能工程師 + 網路工程師 + QA
**測試命令**: --stability-testing --crash-validation --performance-monitoring
**品質標準**: --quality-high --comprehensive-testing