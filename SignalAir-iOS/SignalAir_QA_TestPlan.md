# SignalAir 解鎖機制測試計劃 - 品質保證工程師版

## 1. 功能測試計劃

### 1.1 測試用例矩陣

#### A. 購買流程測試矩陣

| 測試場景 | 測試用例 | 預期結果 | 優先級 |
|---------|---------|---------|---------|
| **正常購買流程** | | | |
| TC-001 | 用戶選擇咖啡版本(NT$90)並成功購買 | 購買成功，但不解鎖任何功能 | P1 |
| TC-002 | 用戶選擇賓果解鎖版(NT$330)並成功購買 | 購買成功，解鎖賓果遊戲功能 | P1 |
| TC-003 | 用戶選擇完整版(NT$1,680)並成功購買 | 購買成功，解鎖所有功能 | P1 |
| TC-004 | 用戶在購買過程中取消交易 | 購買被取消，不解鎖任何功能 | P2 |
| TC-005 | 用戶恢復已購買的內容 | 恢復成功，重新解鎖對應功能 | P1 |
| **異常購買流程** | | | |
| TC-006 | 網路連線中斷時進行購買 | 顯示網路錯誤，進入降級模式 | P1 |
| TC-007 | 無Apple ID登錄時進行購買 | 顯示登錄提示，自動切換測試模式 | P1 |
| TC-008 | 支付受限制時進行購買 | 顯示限制提示，提供設定指引 | P1 |
| TC-009 | 重複購買同一產品 | 顯示已購買，不重複扣費 | P1 |
| TC-010 | 產品載入失敗時進行購買 | 顯示錯誤訊息，提供重試選項 | P2 |

#### B. 解鎖機制測試矩陣

| 測試場景 | 測試用例 | 預期結果 | 優先級 |
|---------|---------|---------|---------|
| **解鎖狀態驗證** | | | |
| TC-011 | 檢查未購買時的賓果遊戲狀態 | 賓果遊戲不可用，顯示升級提示 | P1 |
| TC-012 | 檢查購買賓果版後的功能狀態 | 賓果遊戲可用，完整版功能不可用 | P1 |
| TC-013 | 檢查購買完整版後的功能狀態 | 所有功能可用 | P1 |
| TC-014 | 檢查測試模式下的功能狀態 | 所有功能自動解鎖 | P2 |
| **狀態持久化** | | | |
| TC-015 | 購買後重啟應用程式 | 購買狀態正確保存和恢復 | P1 |
| TC-016 | 購買後切換設備 | 購買狀態正確同步 | P1 |
| TC-017 | 購買後登出/登入Apple ID | 購買狀態正確維持 | P1 |
| TC-018 | 購買後清除應用程式資料 | 購買狀態可透過恢復功能找回 | P2 |

#### C. 使用者介面測試矩陣

| 測試場景 | 測試用例 | 預期結果 | 優先級 |
|---------|---------|---------|---------|
| **購買選項顯示** | | | |
| TC-019 | 檢查購買選項頁面的產品資訊 | 正確顯示價格、描述和推薦標籤 | P1 |
| TC-020 | 檢查購買選項的選擇狀態 | 正確顯示選中/未選中狀態 | P2 |
| TC-021 | 檢查購買按鈕的啟用狀態 | 選擇產品後按鈕啟用，購買中按鈕禁用 | P1 |
| TC-022 | 檢查錯誤訊息的顯示 | 錯誤訊息正確顯示，提供重試選項 | P1 |
| **多語言支援** | | | |
| TC-023 | 切換到英文介面 | 所有購買相關文字正確顯示英文 | P2 |
| TC-024 | 切換到中文介面 | 所有購買相關文字正確顯示中文 | P2 |

### 1.2 驗收標準

#### 功能性驗收標準
- ✅ 所有購買流程必須在30秒內完成
- ✅ 購買成功率必須達到99%以上
- ✅ 解鎖功能必須在購買完成後立即生效
- ✅ 購買狀態必須正確持久化和同步

#### 可用性驗收標準
- ✅ 購買介面必須直觀易用
- ✅ 錯誤訊息必須清晰明確
- ✅ 重試機制必須可靠有效
- ✅ 載入狀態必須明確顯示

#### 相容性驗收標準
- ✅ 支援iOS 15.0以上版本
- ✅ 支援iPhone和iPad設備
- ✅ 支援深色/淺色主題
- ✅ 支援中文/英文雙語

### 1.3 失敗條件

#### 嚴重失敗條件 (導致測試失敗)
- ❌ 購買成功但功能未解鎖
- ❌ 重複扣費
- ❌ 購買狀態丟失
- ❌ 應用程式崩潰
- ❌ 無法恢復購買

#### 一般失敗條件 (需要修復)
- ⚠️ 購買流程超過30秒
- ⚠️ 錯誤訊息不明確
- ⚠️ 介面顯示異常
- ⚠️ 網路錯誤處理不當

## 2. 回歸測試策略

### 2.1 核心功能回歸

#### 購買系統回歸檢查點
```
✓ 購買流程完整性
✓ 解鎖機制正確性
✓ 狀態持久化穩定性
✓ 錯誤處理健全性
✓ 使用者介面一致性
```

#### 相關功能回歸檢查點
```
✓ 賓果遊戲功能
✓ 聊天室功能
✓ 設定頁面
✓ 語言切換
✓ 網路連線
```

### 2.2 設備兼容性測試

#### 測試設備矩陣
| 設備型號 | iOS版本 | 測試重點 |
|---------|---------|---------|
| iPhone 15 Pro | iOS 17.x | 最新功能兼容性 |
| iPhone 14 | iOS 16.x | 主流設備測試 |
| iPhone 13 | iOS 15.x | 最低版本支援 |
| iPad Pro 12.9" | iOS 17.x | 平板介面適配 |
| iPad Air | iOS 16.x | 中階平板測試 |
| iPhone SE 3rd | iOS 15.x | 小屏幕適配 |

#### 測試執行方式
```bash
# 自動化測試腳本
for device in iPhone15Pro iPhone14 iPhone13 iPadPro iPadAir iPhoneSE3; do
    run_purchase_tests $device
    run_ui_tests $device
    run_regression_tests $device
done
```

### 2.3 性能和記憶體測試

#### 性能指標
- 購買流程響應時間 < 30秒
- 解鎖功能切換時間 < 3秒
- 介面載入時間 < 2秒
- 記憶體使用增長 < 50MB

#### 記憶體監控
```swift
// 記憶體使用監控
func monitorMemoryUsage() {
    let memoryBefore = getMemoryUsage()
    performPurchaseFlow()
    let memoryAfter = getMemoryUsage()
    
    assert(memoryAfter - memoryBefore < 50_000_000, "記憶體使用超標")
}
```

## 3. 安全測試

### 3.1 購買流程安全性

#### 安全檢查清單
```
✓ 交易憑證正確驗證
✓ 購買狀態加密存儲
✓ 網路通信使用HTTPS
✓ 敏感資料不被記錄
✓ 異常交易正確處理
```

#### 安全測試用例
| 測試項目 | 檢查內容 | 驗證方法 |
|---------|---------|---------|
| 交易驗證 | StoreKit交易簽名驗證 | 模擬偽造交易 |
| 資料加密 | 購買狀態本地存儲安全 | 檢查UserDefaults |
| 網路安全 | API通信加密 | 網路封包分析 |
| 日誌安全 | 敏感資料不洩露 | 檢查日誌輸出 |

### 3.2 狀態篡改防護

#### 防護機制驗證
```swift
// 狀態篡改檢測
func testTamperProtection() {
    // 1. 嘗試直接修改購買狀態
    UserDefaults.standard.set(["com.signalair.full"], forKey: "SignalAir_PurchasedTiers")
    
    // 2. 檢查是否被檢測到
    let purchaseService = PurchaseService()
    XCTAssertFalse(purchaseService.isPremiumUser, "狀態篡改應該被檢測到")
    
    // 3. 驗證StoreKit驗證機制
    purchaseService.refreshPurchasedProducts()
    XCTAssertFalse(purchaseService.isPremiumUser, "StoreKit驗證應該拒絕篡改")
}
```

### 3.3 測試與生產環境隔離

#### 環境配置
```swift
// 測試環境配置
#if DEBUG
    // 測試模式配置
    let testMode = true
    let sandboxMode = true
    let mockPurchases = true
#else
    // 生產環境配置
    let testMode = false
    let sandboxMode = false
    let mockPurchases = false
#endif
```

#### 隔離驗證
- 測試資料不影響生產環境
- 測試購買使用沙盒環境
- 測試日誌與生產日誌分離
- 測試配置不洩露到生產環境

## 4. 測試腳本和驗證步驟

### 4.1 自動化測試腳本

#### 購買流程自動化測試
```swift
// PurchaseFlowUITests.swift
class PurchaseFlowUITests: XCTestCase {
    
    func testSuccessfulPurchase() {
        let app = XCUIApplication()
        app.launch()
        
        // 進入設定頁面
        app.buttons["設定"].tap()
        
        // 點擊升級選項
        app.buttons["升級到高級版"].tap()
        
        // 選擇賓果版本
        app.buttons["成為play的一環版"].tap()
        
        // 點擊購買按鈕
        app.buttons["購買"].tap()
        
        // 驗證購買成功
        XCTAssertTrue(app.alerts["購買成功"].exists)
        
        // 驗證功能解鎖
        app.buttons["確認"].tap()
        app.tabBars.buttons["遊戲"].tap()
        XCTAssertTrue(app.buttons["開始賓果遊戲"].isEnabled)
    }
    
    func testPurchaseErrorHandling() {
        // 模擬網路錯誤
        mockNetworkError()
        
        let app = XCUIApplication()
        app.launch()
        
        // 嘗試購買
        performPurchaseFlow()
        
        // 驗證錯誤處理
        XCTAssertTrue(app.alerts["網路連接錯誤"].exists)
        XCTAssertTrue(app.buttons["重試"].exists)
    }
}
```

#### 解鎖機制驗證測試
```swift
// UnlockMechanismTests.swift
class UnlockMechanismTests: XCTestCase {
    
    func testUnlockAfterPurchase() {
        let purchaseService = PurchaseService()
        
        // 模擬購買
        purchaseService.simulatePurchase(.bingoUnlock)
        
        // 驗證解鎖狀態
        XCTAssertTrue(purchaseService.isPremiumUser)
        
        // 驗證持久化
        let newInstance = PurchaseService()
        XCTAssertTrue(newInstance.isPremiumUser)
    }
    
    func testMultiDeviceSync() {
        let device1 = PurchaseService()
        let device2 = PurchaseService()
        
        // 在設備1購買
        device1.simulatePurchase(.fullVersion)
        
        // 模擬同步
        device1.syncPurchaseStatus()
        
        // 驗證設備2同步
        device2.restorePurchases()
        XCTAssertTrue(device2.isPremiumUser)
    }
}
```

### 4.2 手動測試檢查清單

#### 購買流程手動測試
```
□ 開啟SignalAir應用程式
□ 進入設定頁面
□ 點擊"升級到高級版"
□ 檢查三個版本的顯示是否正確
□ 選擇賓果版本(NT$330)
□ 點擊購買按鈕
□ 完成Apple ID驗證
□ 確認購買成功訊息
□ 返回主介面
□ 驗證賓果遊戲功能已解鎖
□ 測試賓果遊戲是否正常運作
```

#### 錯誤處理手動測試
```
□ 斷開網路連接
□ 嘗試購買任一版本
□ 驗證錯誤訊息顯示
□ 點擊重試按鈕
□ 連接網路
□ 確認購買流程恢復正常
□ 測試無Apple ID登錄情況
□ 測試支付受限制情況
□ 測試重複購買情況
```

### 4.3 性能測試腳本

#### 購買流程性能測試
```swift
// PerformanceTests.swift
class PurchasePerformanceTests: XCTestCase {
    
    func testPurchaseFlowPerformance() {
        measure {
            let purchaseService = PurchaseService()
            let expectation = self.expectation(description: "購買完成")
            
            Task {
                await purchaseService.purchase(.bingoUnlock)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 30.0)
        }
    }
    
    func testMemoryUsage() {
        let initialMemory = getMemoryUsage()
        
        // 執行100次購買流程
        for _ in 0..<100 {
            let purchaseService = PurchaseService()
            purchaseService.simulatePurchase(.bingoUnlock)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryIncrease, 50_000_000, "記憶體使用增長超標")
    }
}
```

### 4.4 測試報告範本

#### 測試執行報告
```
SignalAir 解鎖機制測試報告
執行日期: 2024-XX-XX
測試人員: [測試人員姓名]
測試環境: iOS 17.x, iPhone 15 Pro

測試結果摘要:
- 總測試用例數: 24
- 通過測試用例: 22
- 失敗測試用例: 2
- 測試覆蓋率: 95%

失敗用例詳情:
- TC-010: 產品載入失敗時重試機制不穩定
- TC-018: 清除資料後恢復購買偶爾失敗

建議修復:
1. 加強產品載入重試機制
2. 改善購買狀態恢復流程
3. 增加異常情況的用戶提示

測試結論: 整體功能穩定，建議修復失敗用例後發布
```

## 5. 測試執行計畫

### 5.1 測試階段安排

#### 第一階段：功能測試 (2天)
- 核心購買流程測試
- 解鎖機制驗證
- 基本錯誤處理測試

#### 第二階段：相容性測試 (2天)
- 多設備測試
- 多版本iOS測試
- 介面適配測試

#### 第三階段：安全性測試 (1天)
- 購買安全性驗證
- 狀態篡改防護測試
- 環境隔離驗證

#### 第四階段：性能測試 (1天)
- 購買流程性能測試
- 記憶體使用測試
- 壓力測試

### 5.2 測試資源需求

#### 硬體需求
- iPhone 15 Pro (iOS 17.x)
- iPhone 14 (iOS 16.x)
- iPhone 13 (iOS 15.x)
- iPad Pro 12.9" (iOS 17.x)
- iPad Air (iOS 16.x)
- iPhone SE 3rd (iOS 15.x)

#### 軟體需求
- Xcode 15.0+
- iOS Simulator
- TestFlight
- Apple Developer Account (沙盒測試)

#### 人力需求
- 資深QA工程師 1名
- 自動化測試工程師 1名
- 手動測試工程師 2名

### 5.3 風險評估

#### 高風險項目
- StoreKit API變更
- Apple審核政策變更
- 網路連接不穩定
- 設備相容性問題

#### 風險緩解措施
- 建立完整的測試環境
- 準備回滾計畫
- 加強錯誤處理機制
- 建立用戶反饋管道

---

**注意事項：**
1. 所有測試都應在沙盒環境中進行
2. 測試前務必備份重要資料
3. 測試結果應詳細記錄並存檔
4. 發現問題應立即報告並追蹤修復進度
5. 測試完成後應進行測試資料清理

此測試計劃確保SignalAir解鎖機制的穩定性、安全性和用戶體驗，為產品發布提供品質保證。