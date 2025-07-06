import Foundation
import StoreKit

// MARK: - 臨時語言支援（避免循環依賴）
extension PurchaseService {
    enum Language {
        case chinese
        case english
    }
    
    /// 從 LanguageService.Language 轉換到 PurchaseService.Language
    static func convertLanguage(_ languageServiceLang: Any) -> Language {
        let langString = String(describing: languageServiceLang)
        switch langString {
        case "chinese":
            return .chinese
        case "english":
            return .english
        default:
            return .chinese // 預設為中文
        }
    }
}

@MainActor
class PurchaseService: NSObject, ObservableObject {
    @Published var purchasedTiers: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var products: [Product] = []
    
    // 持久化鍵
    private let purchasedTiersKey = "SignalAir_PurchasedTiers"
    private let deviceSyncKey = "SignalAir_DeviceSync"
    
    // StoreKit 2 相關
    private var updateListenerTask: Task<Void, Never>?
    
    // 防止重複購買的標記
    private var isPurchasing = false
    
    enum PurchaseTier: String, CaseIterable {
        case coffee = "com.signalair.coffee"
        case bingoUnlock = "com.signalair.bingo"
        case fullVersion = "com.signalair.full"
        
        func displayName(language: PurchaseService.Language) -> String {
            switch language {
            case .chinese:
                switch self {
                case .coffee: return "喝杯楊枝甘露"
                case .bingoUnlock: return "成為play的一環版"
                case .fullVersion: return "好想吃丹丹漢堡版"
                }
            case .english:
                switch self {
                case .coffee: return "Buy a Drink"
                case .bingoUnlock: return "Part of Play Edition"
                case .fullVersion: return "Want Dan Dan Burger Edition"
                }
            }
        }
        
        func description(language: PurchaseService.Language) -> String {
            switch language {
            case .chinese:
                switch self {
                case .coffee: return "純贊助，無解鎖功能"
                case .bingoUnlock: return "購買解鎖賓果遊戲室"
                case .fullVersion: return "購買解鎖賓果遊戲室 + 贊助未來擴充語言包，幫助更多地球人！"
                }
            case .english:
                switch self {
                case .coffee: return "Pure support, no unlock features"
                case .bingoUnlock: return "Purchase to unlock Bingo Game Room"
                case .fullVersion: return "Purchase to unlock Bingo Game Room + support future language packs, help more people!"
                }
            }
        }
        
        var price: String {
            switch self {
            case .coffee: return "NT$90"
            case .bingoUnlock: return "NT$330"
            case .fullVersion: return "NT$1,680"
            }
        }
        
        // 保持向後相容性的屬性
        var defaultDisplayName: String {
            return self.displayName(language: .chinese)
        }
        
        var defaultDescription: String {
            return self.description(language: .chinese)
        }
    }
    
    override init() {
        super.init()
        
        // 載入本地儲存的購買狀態
        loadPurchasedTiers()
        
        // 只啟動交易監聽器，不自動載入產品
        Task {
            startTransactionListener()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    var isPremiumUser: Bool {
        return purchasedTiers.contains(PurchaseTier.bingoUnlock.rawValue) || 
               purchasedTiers.contains(PurchaseTier.fullVersion.rawValue)
    }
    
    func getPurchasedTierDisplayName(language: PurchaseService.Language) -> String? {
        if purchasedTiers.contains(PurchaseTier.fullVersion.rawValue) {
            return PurchaseTier.fullVersion.displayName(language: language)
        } else if purchasedTiers.contains(PurchaseTier.bingoUnlock.rawValue) {
            return PurchaseTier.bingoUnlock.displayName(language: language)
        } else if purchasedTiers.contains(PurchaseTier.coffee.rawValue) {
            return PurchaseTier.coffee.displayName(language: language)
        }
        return nil
    }
    
    // MARK: - 載入產品
    
    /// 手動重新載入產品（公共方法）
    func reloadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        print("🔄 手動重新載入產品...")
        await loadProducts()
        await refreshPurchasedProducts()
    }
    
    /// 懶加載產品（只在需要時載入）
    private func loadProductsIfNeeded() async {
        guard products.isEmpty else { return }
        await loadProducts()
        await refreshPurchasedProducts()
    }
    
    private func loadProducts() async {
        do {
            let productIdentifiers = PurchaseTier.allCases.map { $0.rawValue }
            print("🛒 嘗試載入產品 IDs: \(productIdentifiers)")
            
            products = try await Product.products(for: productIdentifiers)
            print("✅ 載入 \(products.count) 個產品")
            
            if products.isEmpty {
                print("⚠️ 警告：沒有載入到任何產品，可能原因：")
                print("  1. App Store Connect 中沒有配置這些產品ID")
                print("  2. 網路連接問題")
                print("  3. Sandbox 環境配置問題")
                print("  4. Apple ID 未登錄")
                errorMessage = "無法載入產品，請檢查網路連接和Apple ID登錄狀態"
            } else {
                // 顯示載入的產品詳細信息
                for product in products {
                    print("📦 載入產品: \(product.id) - \(product.displayName) (\(product.price))")
                }
                errorMessage = nil
            }
        } catch {
            print("❌ 載入產品失敗: \(error)")
            print("💡 建議：請檢查網路連接，確保已登錄Apple ID，並檢查App Store Connect配置")
            errorMessage = "無法載入產品資訊：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 購買功能
    func purchase(_ tier: PurchaseTier) async {
        // 防止重複購買
        guard !isPurchasing else {
            print("⚠️ 已有購買進行中，忽略重複請求")
            return
        }
        
        isPurchasing = true
        isLoading = true
        errorMessage = nil
        
        defer {
            isPurchasing = false
            isLoading = false
        }
        
        // 🚨 購買前檢查應用內購買可用性（核心功能）
        guard AppStore.canMakePayments else {
            errorMessage = "應用內購買被限制，請到「設定 > 螢幕使用時間」中啟用後重試"
            print("❌ PurchaseService: 嘗試購買但應用內購買被禁用")
            return
        }
        
        // 檢查是否已購買（避免重複購買）
        if purchasedTiers.contains(tier.rawValue) {
            print("✅ 產品已購買: \(tier.rawValue)")
            errorMessage = nil  // 已購買不算錯誤
            return
        }
        
        // 懶加載產品（只在購買時才載入）
        await loadProductsIfNeeded()
        
        // 尋找對應的產品
        guard let product = products.first(where: { $0.id == tier.rawValue }) else {
            errorMessage = "產品暫時無法使用"
            return
        }
        
        do {
            // 執行購買
            print("🛒 開始購買: \(tier.defaultDisplayName)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 驗證交易
                switch verification {
                case .verified(let transaction):
                    // 交易驗證成功
                    print("✅ 購買成功: \(tier.defaultDisplayName)")
                    
                    // 確保在主線程更新UI狀態
                    await MainActor.run {
                        purchasedTiers.insert(tier.rawValue)
                        savePurchasedTiers()
                    }
                    
                    // 完成交易
                    await transaction.finish()
                    
                    // 同步到其他設備
                    await syncPurchaseStatus()
                    
                case .unverified(let transaction, let error):
                    // 交易驗證失敗
                    print("❌ 交易驗證失敗: \(error)")
                    errorMessage = "交易驗證失敗"
                    
                    // 仍然完成交易以避免卡住
                    await transaction.finish()
                }
                
            case .userCancelled:
                // 用戶取消購買
                print("🚫 用戶取消購買")
                errorMessage = nil
                
            case .pending:
                // 購買待處理（例如：需要家長批准）
                print("⏳ 購買待處理")
                errorMessage = "購買待處理批准"
                
            @unknown default:
                print("❓ 未知的購買結果")
                errorMessage = "購買失敗"
            }
            
        } catch {
            print("❌ 購買失敗: \(error)")
            errorMessage = "購買失敗：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 恢復購買
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        print("🔄 開始恢復購買")
        
        do {
            // 先載入產品（如果需要）
            await loadProductsIfNeeded()
            
            // 同步所有交易
            try await AppStore.sync()
            
            // 刷新購買狀態
            await refreshPurchasedProducts()
            
            if purchasedTiers.isEmpty {
                errorMessage = "沒有找到可恢復的購買"
            } else {
                print("✅ 恢復購買成功，找到 \(purchasedTiers.count) 個已購買產品")
                errorMessage = nil
            }
            
        } catch {
            print("❌ 恢復購買失敗: \(error)")
            errorMessage = "恢復購買失敗：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 刷新購買狀態
    private func refreshPurchasedProducts() async {
        var newPurchasedTiers: Set<String> = []
        
        // 檢查每個產品的購買狀態
        for product in products {
            if let status = await product.currentEntitlement {
                switch status {
                case .verified(_):
                    newPurchasedTiers.insert(product.id)
                    print("✅ 已購買: \(product.id)")
                case .unverified(_, _):
                    print("⚠️ 未驗證的購買: \(product.id)")
                }
            }
        }
        
        // 確保在主線程更新購買狀態
        if newPurchasedTiers != purchasedTiers {
            await MainActor.run {
                purchasedTiers = newPurchasedTiers
                savePurchasedTiers()
            }
        }
    }
    
    // MARK: - 交易監聽器
    private func startTransactionListener() {
        updateListenerTask = Task {
            // 🚨 強化的 StoreKit 可用性檢查
            await verifyStoreKitAvailability()
            
            // 🚨 應用內購買是核心功能，必須支援
            guard AppStore.canMakePayments else {
                print("❌ PurchaseService: 應用內購買被禁用 - 這是核心功能")
                await MainActor.run {
                    errorMessage = "應用內購買被限制，請到「設定 > 螢幕使用時間 > 內容與隱私權限制」中啟用"
                }
                // 不要直接返回，而是定期重試檢查
                await retryPaymentAvailabilityCheck()
                return
            }
            
            // 監聽交易更新
            for await update in Transaction.updates {
                await handleTransactionUpdate(update)
            }
        }
    }
    
    /// 驗證 StoreKit 可用性（應用內購買是核心功能）
    private func verifyStoreKitAvailability() async {
        // 檢查 App Store 連接狀態
        do {
            // 嘗試載入一個簡單的產品來驗證連接
            let testProducts = try await Product.products(for: [])
            print("✅ PurchaseService: StoreKit 連接正常，測試產品數量: \(testProducts.count)")
            await MainActor.run {
                errorMessage = nil  // 清除之前的錯誤訊息
            }
        } catch {
            print("❌ PurchaseService: StoreKit 連接問題: \(error)")
            await MainActor.run {
                if error.localizedDescription.contains("No active account") {
                    errorMessage = "請先登入 Apple ID - 這是應用的核心功能"
                } else if error.localizedDescription.contains("Cannot connect") {
                    errorMessage = "無法連接 App Store，請檢查網路連接後重試"
                } else {
                    errorMessage = "App Store 服務異常，請稍後再試"
                }
            }
            
            // 🚨 因為應用內購買是核心功能，自動重試
            await autoRetryStoreKitConnection()
        }
    }
    
    /// 定期重試應用內購買可用性檢查
    private func retryPaymentAvailabilityCheck() async {
        print("🔄 PurchaseService: 開始定期檢查應用內購買可用性...")
        
        for attempt in 1...5 {  // 最多重試5次
            try? await Task.sleep(nanoseconds: UInt64(Double(attempt) * 10_000_000_000))  // 10秒, 20秒, 30秒...
            
            if AppStore.canMakePayments {
                print("✅ PurchaseService: 應用內購買已恢復可用！")
                await MainActor.run {
                    errorMessage = nil
                }
                // 重新啟動交易監聽
                startTransactionListener()
                return
            } else {
                print("⏳ PurchaseService: 應用內購買仍不可用 (嘗試 \(attempt)/5)")
            }
        }
        
        await MainActor.run {
            errorMessage = "應用內購買功能持續不可用，請檢查設備限制設定"
        }
    }
    
    /// 自動重試 StoreKit 連接
    private func autoRetryStoreKitConnection() async {
        print("🔄 PurchaseService: 自動重試 StoreKit 連接...")
        
        for attempt in 1...3 {  // 重試3次
            try? await Task.sleep(nanoseconds: UInt64(Double(attempt) * 5_000_000_000))  // 5秒, 10秒, 15秒
            
            do {
                let testProducts = try await Product.products(for: [])
                print("✅ PurchaseService: StoreKit 重連成功！產品數量: \(testProducts.count)")
                await MainActor.run {
                    errorMessage = nil
                }
                return
            } catch {
                print("⚠️ PurchaseService: StoreKit 重連失敗 (嘗試 \(attempt)/3): \(error)")
            }
        }
        
        print("❌ PurchaseService: StoreKit 重連最終失敗")
    }
    
    /// 處理交易更新
    private func handleTransactionUpdate(_ update: VerificationResult<Transaction>) async {
        switch update {
        case .verified(let transaction):
            print("📱 PurchaseService: 收到已驗證交易: \(transaction.productID)")
            
            // 確保在主線程更新UI狀態
            await MainActor.run {
                purchasedTiers.insert(transaction.productID)
                savePurchasedTiers()
                errorMessage = nil  // 清除錯誤訊息
            }
            
            // 完成交易
            await transaction.finish()
            
            // 同步到其他設備
            await syncPurchaseStatus()
            
        case .unverified(let transaction, let error):
            print("⚠️ PurchaseService: 收到未驗證交易: \(transaction.productID), 錯誤: \(error)")
            
            // 根據錯誤類型決定處理方式
            await handleTransactionVerificationError(transaction, error: error)
            
            // 仍然完成交易以避免卡住
            await transaction.finish()
        }
    }
    
    /// 處理交易驗證錯誤
    private func handleTransactionVerificationError(_ transaction: Transaction, error: VerificationResult<Transaction>.VerificationError) async {
        await MainActor.run {
            // 使用更簡單的錯誤處理，避免 switch exhaustive 問題
            let errorMessage: String
            
            switch error {
            case .invalidSignature:
                errorMessage = "交易簽名驗證失敗，請重試"
            case .revokedCertificate:
                errorMessage = "應用證書已被撤銷，請更新應用"
            default:
                // 處理所有其他可能的錯誤類型
                errorMessage = "交易驗證失敗：\(error.localizedDescription)"
            }
            
            self.errorMessage = errorMessage
        }
    }
    
    /// 處理 StoreKit 錯誤
    private func handleStoreKitError(_ error: Error) async {
        await MainActor.run {
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .notAvailableInStorefront:
                    errorMessage = "此項目在您的地區不可用"
                case .networkError:
                    errorMessage = "網路連接錯誤，請稍後再試"
                default:
                    errorMessage = "App Store 錯誤：\(storeKitError.localizedDescription)"
                }
            } else if error.localizedDescription.contains("No active account") {
                errorMessage = "請先登入您的 Apple ID"
            } else if error.localizedDescription.contains("Cannot connect") {
                errorMessage = "無法連接到 App Store，請檢查網路連接"
            } else {
                errorMessage = "購買系統暫時不可用：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 多設備同步
    private func syncPurchaseStatus() async {
        // 記錄同步時間戳
        let syncTimestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(syncTimestamp, forKey: deviceSyncKey)
        
        print("🔄 同步購買狀態到其他設備，時間戳: \(syncTimestamp)")
        
        // 通知其他視圖更新
        NotificationCenter.default.post(
            name: NSNotification.Name("PurchaseStatusDidChange"),
            object: nil,
            userInfo: ["tiers": Array(purchasedTiers)]
        )
    }
    
    // MARK: - 本地存儲
    private func loadPurchasedTiers() {
        if let savedTiers = UserDefaults.standard.array(forKey: purchasedTiersKey) as? [String] {
            purchasedTiers = Set(savedTiers)
            print("📱 載入本地購買狀態: \(purchasedTiers)")
        }
    }
    
    private func savePurchasedTiers() {
        let tiersArray = Array(purchasedTiers)
        UserDefaults.standard.set(tiersArray, forKey: purchasedTiersKey)
        print("💾 儲存購買狀態: \(tiersArray)")
    }
    
    // MARK: - 測試用方法
    #if DEBUG
    func resetPurchases() {
        purchasedTiers.removeAll()
        savePurchasedTiers()
        print("🗑️ 已重置購買狀態")
    }
    
    // 模擬購買（僅用於開發測試）
    func simulatePurchase(_ tier: PurchaseTier) {
        purchasedTiers.insert(tier.rawValue)
        savePurchasedTiers()
        print("🧪 模擬購買: \(tier.defaultDisplayName)")
        
        Task {
            await syncPurchaseStatus()
        }
    }
    
    // 直接解鎖功能（用於實機測試）
    func unlockForTesting(_ tier: PurchaseTier) {
        purchasedTiers.insert(tier.rawValue)
        savePurchasedTiers()
        errorMessage = nil
        print("🔓 測試解鎖: \(tier.defaultDisplayName)")
        
        Task {
            await syncPurchaseStatus()
        }
    }
    #endif
}