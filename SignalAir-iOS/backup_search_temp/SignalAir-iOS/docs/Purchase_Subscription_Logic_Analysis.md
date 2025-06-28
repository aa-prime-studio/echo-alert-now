# 訂閱內購邏輯分析報告

## 概述

SignalAir iOS 項目目前實現了基礎的內購框架，但核心購買邏輯尚未完成，處於 **Phase 1 框架階段**。

## 🏗️ 當前實現狀況

### 1. 購買層級定義 ✅ **已完成**

**文件**: `SignalAir/Services/PurchaseService.swift`

```swift
enum PurchaseTier: String, CaseIterable {
    case coffee = "com.signalair.coffee"         // NT$90 - 純贊助
    case bingoUnlock = "com.signalair.bingo"     // NT$330 - 解鎖賓果
    case fullVersion = "com.signalair.full"      // NT$1,680 - 完整版
}
```

#### 購買層級詳情：
| 層級 | 價格 | 功能 | Product ID |
|------|------|------|------------|
| **喝杯楊枝甘露** | NT$90 | 純贊助，無解鎖功能 | com.signalair.coffee |
| **解鎖賓果遊戲** | NT$330 | 解鎖賓果遊戲室 | com.signalair.bingo |
| **完整版** | NT$1,680 | 全功能 + 未來擴充語言包，幫助更多地球人！ | com.signalair.full |

### 2. 用戶界面 ✅ **已完成**

#### A. 購買選項界面 (`PurchaseOptionsView.swift`)
- ✅ 三種購買層級的卡片展示
- ✅ 選擇和購買按鈕
- ✅ 恢復購買功能
- ✅ 推薦方案標示（完整版）

#### B. 設定頁面集成 (`SettingsView.swift`)
- ✅ 顯示用戶狀態（免費用戶/付費用戶）
- ✅ 升級按鈕（僅對免費用戶顯示）
- ✅ 恢復購買按鈕

### 3. 權限控制邏輯 ⚠️ **部分實現**

#### A. Premium 用戶檢查
```swift
var isPremiumUser: Bool {
    return purchasedTiers.contains(PurchaseTier.bingoUnlock.rawValue) || 
           purchasedTiers.contains(PurchaseTier.fullVersion.rawValue)
}
```

#### B. 功能限制（目前暫時關閉）
```swift
struct GameTabView: View {
    let isPremiumUser: Bool
    
    var body: some View {
        // 暫時關閉內購檢查，直接顯示遊戲
        GameView()
    }
}
```

**狀態**: 遊戲功能目前對所有用戶開放（暫時性）

## ❌ 缺少的核心實現

### 1. StoreKit 集成 **未實現**

**當前問題**: PurchaseService 中標記為 "TODO: Phase 2"

```swift
init() {
    // TODO: Phase 2 - Initialize StoreKit
}

func purchase(_ tier: PurchaseTier) async {
    // TODO: Phase 2 - Implement actual purchase
    print("模擬購買: \(tier.displayName)")
}

func restorePurchases() async {
    // TODO: Phase 2 - Implement restore
    print("模擬恢復購買")
}
```

### 2. 缺少的關鍵功能

#### A. StoreKit 2 集成
- ❌ 產品查詢和載入
- ❌ 實際購買處理
- ❌ 交易驗證
- ❌ 收據驗證

#### B. 本地存儲
- ❌ 購買狀態持久化
- ❌ 購買記錄管理
- ❌ 恢復購買邏輯

#### C. 錯誤處理
- ❌ 購買失敗處理
- ❌ 網路錯誤處理
- ❌ 用戶取消處理

## 🔧 建議實施方案

### Phase 2: StoreKit 集成實現

#### 1. 完整的 PurchaseService 實現

```swift
import StoreKit

class PurchaseService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedTiers: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func requestProducts() async {
        do {
            let productIDs = PurchaseTier.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to request products: \(error)")
        }
    }
    
    func purchase(_ tier: PurchaseTier) async {
        guard let product = products.first(where: { $0.id == tier.rawValue }) else {
            return
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateCustomerProductStatus()
                await transaction.finish()
            case .userCancelled, .pending:
                break
            default:
                break
            }
        } catch {
            print("Failed to purchase product: \(error)")
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    private func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchasedProducts.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction")
            }
        }
        
        await MainActor.run {
            self.purchasedTiers = purchasedProducts
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
```

#### 2. App Store Connect 配置

**必要步驟**:
1. ✅ 在 App Store Connect 中創建產品
2. ✅ 設定產品 ID 和價格
3. ✅ 創建沙盒測試帳戶
4. ✅ 配置稅務和銀行資訊

#### 3. 權限控制重新啟用

```swift
struct GameTabView: View {
    let isPremiumUser: Bool
    
    var body: some View {
        NavigationView {
            if isPremiumUser {
                GameView()
                    .navigationBarHidden(true)
            } else {
                PremiumRequiredView()
            }
        }
    }
}
```

## 📊 功能權限矩陣

| 功能 | 免費用戶 | 賓果解鎖 | 完整版 |
|------|---------|---------|--------|
| **Signal 功能** | ✅ | ✅ | ✅ |
| **Chat 功能** | ✅ | ✅ | ✅ |
| **賓果遊戲** | ❌ | ✅ | ✅ |
| **未來語言包** | ❌ | ❌ | ✅ |
| **優先支援** | ❌ | ❌ | ✅ |

## ⚠️ 當前風險

### 1. 開發風險
- **StoreKit 集成複雜度**: 需要專業的 iOS 內購開發經驗
- **測試困難**: 需要 App Store Connect 沙盒環境
- **收據驗證**: 需要後端服務器驗證（或使用 StoreKit 2 本地驗證）

### 2. 商業風險
- **用戶體驗**: 當前所有功能都可免費使用，啟用限制可能影響用戶滿意度
- **定價策略**: 需要市場調研確認價格競爭力

## ✅ 建議實施順序

### 立即 (Phase 2A)
1. **StoreKit 2 基礎集成**: 產品查詢和購買流程
2. **購買狀態持久化**: UserDefaults 或 Keychain 存儲
3. **基本錯誤處理**: 用戶友好的錯誤訊息

### 短期 (Phase 2B)
1. **重新啟用權限控制**: 賓果遊戲的付費限制
2. **購買體驗優化**: 載入狀態、成功確認
3. **沙盒測試**: 完整的購買流程測試

### 長期 (Phase 2C)
1. **伺服器端驗證**: 防止購買欺詐
2. **分析集成**: 購買轉換率追蹤
3. **A/B 測試**: 價格和包裝優化

---

**結論**: 內購系統架構完整但核心實現缺失，需要完成 StoreKit 2 集成才能啟用真實的購買功能。 