import Foundation
import SwiftUI

// MARK: - Manual Security Audit Checklist
/// 手動安全審計檢查清單
/// 提供系統化的安全審核指南和互動式檢查表
class ManualSecurityAuditChecklist: ObservableObject {
    
    // MARK: - Audit Categories
    @Published var auditCategories: [SecurityAuditCategory] = []
    @Published var currentProgress: Double = 0.0
    @Published var auditStartTime: Date?
    @Published var auditNotes: [AuditNote] = []
    @Published var findings: [SecurityFinding] = []
    
    // MARK: - Audit Configuration
    private let auditStandards: [SecurityStandard] = [
        .iso27001,
        .nistCybersecurityFramework,
        .owaspTop10,
        .cis20Controls
    ]
    
    init() {
        setupAuditCategories()
        print("📋 ManualSecurityAuditChecklist: 手動安全審計檢查清單初始化")
    }
    
    // MARK: - Audit Execution
    
    /// 開始安全審計
    func startAudit() {
        auditStartTime = Date()
        resetAuditState()
        print("🔍 開始手動安全審計...")
    }
    
    /// 完成安全審計並生成報告
    func completeAudit() -> ManualAuditReport {
        let duration = auditStartTime?.timeIntervalSinceNow ?? 0
        let report = generateAuditReport(duration: abs(duration))
        print("📋 手動安全審計完成，生成報告")
        return report
    }
    
    // MARK: - Audit Category Setup
    
    private func setupAuditCategories() {
        auditCategories = [
            createNetworkSecurityCategory(),
            createAccessControlCategory(),
            createDataProtectionCategory(),
            createCryptographyCategory(),
            createSecurityArchitectureCategory(),
            createIncidentResponseCategory(),
            createComplianceCategory(),
            createPhysicalSecurityCategory()
        ]
    }
    
    // MARK: - Network Security Category
    
    private func createNetworkSecurityCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "NET001",
                title: "網路分段檢查",
                description: "驗證網路是否正確分段，限制橫向移動",
                checkPoints: [
                    "檢查 P2P 網路拓撲設計",
                    "驗證設備間連接限制",
                    "測試網路隔離效果",
                    "檢查網路監控機制"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "NET002",
                title: "DDoS 防護機制",
                description: "評估系統對分散式阻斷攻擊的防護能力",
                checkPoints: [
                    "檢查連接速率限制",
                    "驗證異常流量檢測",
                    "測試負載平衡機制",
                    "評估自動防護響應"
                ],
                riskLevel: .high,
                compliance: [.nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "NET003",
                title: "網路流量監控",
                description: "檢查網路流量的監控和記錄機制",
                checkPoints: [
                    "驗證流量記錄完整性",
                    "檢查異常行為檢測",
                    "測試告警機制",
                    "評估日誌分析能力"
                ],
                riskLevel: .medium,
                compliance: [.iso27001, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "NET004",
                title: "無線網路安全",
                description: "評估 WiFi 和 Bluetooth 連接的安全性",
                checkPoints: [
                    "檢查 WiFi-Direct 加密",
                    "驗證 Bluetooth 配對安全",
                    "測試無線攔截防護",
                    "評估設備發現安全"
                ],
                riskLevel: .medium,
                compliance: [.iso27001]
            )
        ]
        
        return SecurityAuditCategory(
            id: "NETWORK",
            name: "網路安全",
            description: "評估網路層面的安全控制措施",
            checkItems: checkItems,
            priority: .critical
        )
    }
    
    // MARK: - Access Control Category
    
    private func createAccessControlCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "ACC001",
                title: "身份驗證機制",
                description: "檢查用戶和設備的身份驗證強度",
                checkPoints: [
                    "驗證設備指紋識別",
                    "檢查身份驗證協議",
                    "測試多因素驗證",
                    "評估身份偽造防護"
                ],
                riskLevel: .critical,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "ACC002",
                title: "授權控制",
                description: "評估系統的權限管理和存取控制",
                checkPoints: [
                    "檢查權限分配原則",
                    "驗證最小權限原則",
                    "測試權限提升防護",
                    "評估存取記錄機制"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "ACC003",
                title: "信任評分系統",
                description: "審核信任評分機制的設計和實施",
                checkPoints: [
                    "檢查信任計算邏輯",
                    "驗證評分更新機制",
                    "測試信任閾值設定",
                    "評估信任操縱防護"
                ],
                riskLevel: .high,
                compliance: [.nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "ACC004",
                title: "會話管理",
                description: "檢查用戶會話的安全管理",
                checkPoints: [
                    "驗證會話超時設定",
                    "檢查會話固定防護",
                    "測試並發會話限制",
                    "評估會話終止機制"
                ],
                riskLevel: .medium,
                compliance: [.owaspTop10]
            )
        ]
        
        return SecurityAuditCategory(
            id: "ACCESS_CONTROL",
            name: "存取控制",
            description: "評估身份驗證和授權控制機制",
            checkItems: checkItems,
            priority: .critical
        )
    }
    
    // MARK: - Data Protection Category
    
    private func createDataProtectionCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "DATA001",
                title: "資料加密",
                description: "檢查靜態和傳輸中的資料加密",
                checkPoints: [
                    "驗證傳輸加密強度",
                    "檢查本地資料加密",
                    "測試密鑰管理機制",
                    "評估加密算法選擇"
                ],
                riskLevel: .critical,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "DATA002",
                title: "資料完整性",
                description: "評估資料完整性驗證機制",
                checkPoints: [
                    "檢查數位簽章實施",
                    "驗證雜湊驗證機制",
                    "測試資料篡改檢測",
                    "評估完整性恢復能力"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "DATA003",
                title: "資料備份與恢復",
                description: "檢查資料備份和災難恢復機制",
                checkPoints: [
                    "驗證備份策略實施",
                    "檢查備份資料加密",
                    "測試恢復程序",
                    "評估業務連續性計畫"
                ],
                riskLevel: .medium,
                compliance: [.iso27001, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "DATA004",
                title: "隱私保護",
                description: "評估個人資料和隱私保護措施",
                checkPoints: [
                    "檢查資料最小化原則",
                    "驗證匿名化機制",
                    "測試資料洩露防護",
                    "評估隱私政策實施"
                ],
                riskLevel: .high,
                compliance: [.iso27001]
            )
        ]
        
        return SecurityAuditCategory(
            id: "DATA_PROTECTION",
            name: "資料保護",
            description: "評估資料安全和隱私保護機制",
            checkItems: checkItems,
            priority: .critical
        )
    }
    
    // MARK: - Cryptography Category
    
    private func createCryptographyCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "CRYPTO001",
                title: "密鑰管理",
                description: "審核密鑰生成、分發和管理流程",
                checkPoints: [
                    "檢查密鑰生成隨機性",
                    "驗證密鑰分發安全",
                    "測試密鑰輪換機制",
                    "評估密鑰銷毀程序"
                ],
                riskLevel: .critical,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "CRYPTO002",
                title: "加密算法選擇",
                description: "評估所使用的加密算法和實施",
                checkPoints: [
                    "檢查算法安全強度",
                    "驗證實施正確性",
                    "測試已知弱點防護",
                    "評估算法更新機制"
                ],
                riskLevel: .high,
                compliance: [.nistCybersecurityFramework, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "CRYPTO003",
                title: "數位簽章",
                description: "檢查數位簽章的實施和驗證",
                checkPoints: [
                    "驗證簽章算法選擇",
                    "檢查簽章驗證流程",
                    "測試簽章偽造防護",
                    "評估憑證管理機制"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "CRYPTO004",
                title: "隨機數生成",
                description: "評估隨機數生成器的品質和安全性",
                checkPoints: [
                    "檢查隨機數源品質",
                    "驗證熵收集機制",
                    "測試統計隨機性",
                    "評估可預測性防護"
                ],
                riskLevel: .medium,
                compliance: [.nistCybersecurityFramework]
            )
        ]
        
        return SecurityAuditCategory(
            id: "CRYPTOGRAPHY",
            name: "密碼學",
            description: "評估密碼學控制措施和實施",
            checkItems: checkItems,
            priority: .critical
        )
    }
    
    // MARK: - Security Architecture Category
    
    private func createSecurityArchitectureCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "ARCH001",
                title: "安全設計原則",
                description: "檢查系統是否遵循安全設計原則",
                checkPoints: [
                    "驗證深度防禦實施",
                    "檢查失敗安全設計",
                    "測試最小權限原則",
                    "評估攻擊面最小化"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "ARCH002",
                title: "威脅模型",
                description: "評估威脅建模和風險分析",
                checkPoints: [
                    "檢查威脅識別完整性",
                    "驗證風險評估準確性",
                    "測試緩解措施效果",
                    "評估威脅情報整合"
                ],
                riskLevel: .high,
                compliance: [.nistCybersecurityFramework, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "ARCH003",
                title: "安全邊界",
                description: "檢查系統安全邊界的定義和實施",
                checkPoints: [
                    "驗證信任邊界設定",
                    "檢查邊界控制措施",
                    "測試跨境數據流",
                    "評估邊界監控機制"
                ],
                riskLevel: .medium,
                compliance: [.iso27001]
            ),
            SecurityCheckItem(
                id: "ARCH004",
                title: "安全組件整合",
                description: "評估各安全組件的整合和協調",
                checkPoints: [
                    "檢查組件間通信安全",
                    "驗證統一政策執行",
                    "測試組件故障處理",
                    "評估整體安全效果"
                ],
                riskLevel: .medium,
                compliance: [.nistCybersecurityFramework]
            )
        ]
        
        return SecurityAuditCategory(
            id: "SECURITY_ARCHITECTURE",
            name: "安全架構",
            description: "評估整體安全架構設計和實施",
            checkItems: checkItems,
            priority: .high
        )
    }
    
    // MARK: - Incident Response Category
    
    private func createIncidentResponseCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "IR001",
                title: "事件檢測機制",
                description: "評估安全事件的檢測能力",
                checkPoints: [
                    "檢查監控系統覆蓋度",
                    "驗證異常檢測準確性",
                    "測試告警機制有效性",
                    "評估檢測時間效率"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "IR002",
                title: "事件回應流程",
                description: "檢查安全事件的回應和處理流程",
                checkPoints: [
                    "驗證回應程序完整性",
                    "檢查角色和責任分配",
                    "測試升級機制",
                    "評估回應時間效率"
                ],
                riskLevel: .high,
                compliance: [.iso27001, .nistCybersecurityFramework, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "IR003",
                title: "取證和調查",
                description: "評估數位取證和事件調查能力",
                checkPoints: [
                    "檢查證據保全機制",
                    "驗證調查工具和技術",
                    "測試證據鏈完整性",
                    "評估法律合規性"
                ],
                riskLevel: .medium,
                compliance: [.iso27001]
            ),
            SecurityCheckItem(
                id: "IR004",
                title: "事件後分析",
                description: "檢查事件後的學習和改進機制",
                checkPoints: [
                    "驗證事件分析報告",
                    "檢查改進措施實施",
                    "測試知識分享機制",
                    "評估預防措施效果"
                ],
                riskLevel: .medium,
                compliance: [.nistCybersecurityFramework, .cis20Controls]
            )
        ]
        
        return SecurityAuditCategory(
            id: "INCIDENT_RESPONSE",
            name: "事件回應",
            description: "評估安全事件檢測和回應能力",
            checkItems: checkItems,
            priority: .high
        )
    }
    
    // MARK: - Compliance Category
    
    private func createComplianceCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "COMP001",
                title: "法規遵循",
                description: "檢查相關法規和標準的遵循情況",
                checkPoints: [
                    "驗證適用法規識別",
                    "檢查合規控制措施",
                    "測試合規監控機制",
                    "評估合規報告完整性"
                ],
                riskLevel: .high,
                compliance: [.iso27001]
            ),
            SecurityCheckItem(
                id: "COMP002",
                title: "政策和程序",
                description: "評估安全政策和程序的完整性",
                checkPoints: [
                    "檢查政策覆蓋範圍",
                    "驗證程序可操作性",
                    "測試政策執行效果",
                    "評估更新維護機制"
                ],
                riskLevel: .medium,
                compliance: [.iso27001, .cis20Controls]
            ),
            SecurityCheckItem(
                id: "COMP003",
                title: "審計和評估",
                description: "檢查內部審計和評估機制",
                checkPoints: [
                    "驗證審計計畫完整性",
                    "檢查審計執行品質",
                    "測試發現追蹤機制",
                    "評估改善措施效果"
                ],
                riskLevel: .medium,
                compliance: [.iso27001, .nistCybersecurityFramework]
            ),
            SecurityCheckItem(
                id: "COMP004",
                title: "第三方風險管理",
                description: "評估供應商和第三方的安全風險管理",
                checkPoints: [
                    "檢查供應商評估流程",
                    "驗證合約安全條款",
                    "測試第三方監控機制",
                    "評估風險緩解措施"
                ],
                riskLevel: .medium,
                compliance: [.iso27001, .cis20Controls]
            )
        ]
        
        return SecurityAuditCategory(
            id: "COMPLIANCE",
            name: "合規性",
            description: "評估法規遵循和治理機制",
            checkItems: checkItems,
            priority: .medium
        )
    }
    
    // MARK: - Physical Security Category
    
    private func createPhysicalSecurityCategory() -> SecurityAuditCategory {
        let checkItems = [
            SecurityCheckItem(
                id: "PHYS001",
                title: "設備物理安全",
                description: "檢查設備的物理安全保護",
                checkPoints: [
                    "驗證設備防竊機制",
                    "檢查物理存取控制",
                    "測試環境監控系統",
                    "評估災害防護措施"
                ],
                riskLevel: .medium,
                compliance: [.iso27001]
            ),
            SecurityCheckItem(
                id: "PHYS002",
                title: "介面安全",
                description: "評估設備介面的安全性",
                checkPoints: [
                    "檢查USB端口保護",
                    "驗證調試介面安全",
                    "測試無線介面防護",
                    "評估網路端口安全"
                ],
                riskLevel: .medium,
                compliance: [.cis20Controls]
            ),
            SecurityCheckItem(
                id: "PHYS003",
                title: "供應鏈安全",
                description: "檢查硬體供應鏈的安全性",
                checkPoints: [
                    "驗證供應商可信度",
                    "檢查硬體完整性",
                    "測試韌體驗證機制",
                    "評估篡改檢測能力"
                ],
                riskLevel: .high,
                compliance: [.nistCybersecurityFramework]
            )
        ]
        
        return SecurityAuditCategory(
            id: "PHYSICAL_SECURITY",
            name: "實體安全",
            description: "評估實體層面的安全控制措施",
            checkItems: checkItems,
            priority: .medium
        )
    }
    
    // MARK: - Audit Progress Management
    
    func updateCheckItemStatus(_ categoryId: String, _ itemId: String, _ status: CheckStatus, _ note: String? = nil) {
        if let categoryIndex = auditCategories.firstIndex(where: { $0.id == categoryId }),
           let itemIndex = auditCategories[categoryIndex].checkItems.firstIndex(where: { $0.id == itemId }) {
            auditCategories[categoryIndex].checkItems[itemIndex].status = status
            auditCategories[categoryIndex].checkItems[itemIndex].auditDate = Date()
            auditCategories[categoryIndex].checkItems[itemIndex].auditorNote = note
            
            // 根據檢查結果添加發現
            if status == .nonCompliant {
                let finding = SecurityFinding(
                    id: UUID().uuidString,
                    categoryId: categoryId,
                    itemId: itemId,
                    title: auditCategories[categoryIndex].checkItems[itemIndex].title,
                    description: note ?? "發現不合規項目",
                    riskLevel: auditCategories[categoryIndex].checkItems[itemIndex].riskLevel,
                    recommendation: generateRecommendation(for: itemId),
                    timestamp: Date()
                )
                findings.append(finding)
            }
            
            updateProgress()
        }
    }
    
    private func updateProgress() {
        let totalItems = auditCategories.flatMap { $0.checkItems }.count
        let completedItems = auditCategories.flatMap { $0.checkItems }.filter { $0.status != .notChecked }.count
        currentProgress = totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0.0
    }
    
    private func generateRecommendation(for itemId: String) -> String {
        switch itemId {
        case "NET001":
            return "實施網路微分段策略，限制設備間的橫向移動"
        case "NET002":
            return "部署多層次DDoS防護機制，包括速率限制和異常檢測"
        case "ACC001":
            return "強化設備身份驗證，實施多因素驗證機制"
        case "DATA001":
            return "升級加密算法，實施端到端加密和強化密鑰管理"
        case "CRYPTO001":
            return "建立完善的密鑰生命周期管理流程"
        default:
            return "根據最佳實務建議改善此項目的安全控制措施"
        }
    }
    
    // MARK: - Report Generation
    
    private func generateAuditReport(duration: TimeInterval) -> ManualAuditReport {
        let totalItems = auditCategories.flatMap { $0.checkItems }.count
        let compliantItems = auditCategories.flatMap { $0.checkItems }.filter { $0.status == .compliant }.count
        let nonCompliantItems = auditCategories.flatMap { $0.checkItems }.filter { $0.status == .nonCompliant }.count
        let partiallyCompliantItems = auditCategories.flatMap { $0.checkItems }.filter { $0.status == .partiallyCompliant }.count
        
        let overallRating = calculateOverallRating()
        let priorityFindings = findings.filter { $0.riskLevel == .critical || $0.riskLevel == .high }
        
        return ManualAuditReport(
            auditDate: Date(),
            duration: duration,
            totalCheckItems: totalItems,
            compliantItems: compliantItems,
            nonCompliantItems: nonCompliantItems,
            partiallyCompliantItems: partiallyCompliantItems,
            findings: findings,
            priorityFindings: priorityFindings,
            overallRating: overallRating,
            auditCategories: auditCategories,
            recommendations: generateOverallRecommendations()
        )
    }
    
    private func calculateOverallRating() -> AuditRating {
        let totalItems = auditCategories.flatMap { $0.checkItems }.count
        let compliantItems = auditCategories.flatMap { $0.checkItems }.filter { $0.status == .compliant }.count
        let criticalFindings = findings.filter { $0.riskLevel == .critical }.count
        
        if criticalFindings > 0 {
            return .poor
        }
        
        let complianceRate = totalItems > 0 ? Double(compliantItems) / Double(totalItems) : 0.0
        
        switch complianceRate {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.7..<0.8:
            return .fair
        default:
            return .poor
        }
    }
    
    private func generateOverallRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let criticalFindings = findings.filter { $0.riskLevel == .critical }.count
        let highFindings = findings.filter { $0.riskLevel == .high }.count
        
        if criticalFindings > 0 {
            recommendations.append("立即處理 \(criticalFindings) 個關鍵安全問題")
        }
        
        if highFindings > 0 {
            recommendations.append("優先處理 \(highFindings) 個高風險安全問題")
        }
        
        recommendations.append("建立定期安全審計機制")
        recommendations.append("實施持續監控和改進流程")
        recommendations.append("加強安全意識培訓")
        
        return recommendations
    }
    
    private func resetAuditState() {
        findings.removeAll()
        auditNotes.removeAll()
        currentProgress = 0.0
        
        for categoryIndex in auditCategories.indices {
            for itemIndex in auditCategories[categoryIndex].checkItems.indices {
                auditCategories[categoryIndex].checkItems[itemIndex].status = .notChecked
                auditCategories[categoryIndex].checkItems[itemIndex].auditDate = nil
                auditCategories[categoryIndex].checkItems[itemIndex].auditorNote = nil
            }
        }
    }
}

// MARK: - Supporting Types

struct SecurityAuditCategory {
    let id: String
    let name: String
    let description: String
    var checkItems: [SecurityCheckItem]
    let priority: AuditPriority
}

struct SecurityCheckItem {
    let id: String
    let title: String
    let description: String
    let checkPoints: [String]
    let riskLevel: RiskLevel
    let compliance: [SecurityStandard]
    var status: CheckStatus = .notChecked
    var auditDate: Date?
    var auditorNote: String?
}

enum CheckStatus {
    case notChecked
    case compliant
    case partiallyCompliant
    case nonCompliant
    case notApplicable
}

enum AuditPriority {
    case critical
    case high
    case medium
    case low
}

enum SecurityStandard {
    case iso27001
    case nistCybersecurityFramework
    case owaspTop10
    case cis20Controls
}

enum RiskLevel {
    case low
    case medium
    case high
    case critical
}

enum AuditRating {
    case excellent
    case good
    case fair
    case poor
}

struct SecurityFinding {
    let id: String
    let categoryId: String
    let itemId: String
    let title: String
    let description: String
    let riskLevel: RiskLevel
    let recommendation: String
    let timestamp: Date
}

struct AuditNote {
    let id: String
    let categoryId: String
    let itemId: String?
    let note: String
    let timestamp: Date
}

struct ManualAuditReport {
    let auditDate: Date
    let duration: TimeInterval
    let totalCheckItems: Int
    let compliantItems: Int
    let nonCompliantItems: Int
    let partiallyCompliantItems: Int
    let findings: [SecurityFinding]
    let priorityFindings: [SecurityFinding]
    let overallRating: AuditRating
    let auditCategories: [SecurityAuditCategory]
    let recommendations: [String]
}

// MARK: - SwiftUI Audit Interface

struct ManualSecurityAuditView: View {
    @StateObject private var auditChecklist = ManualSecurityAuditChecklist()
    @State private var selectedCategory: SecurityAuditCategory?
    @State private var showingReport = false
    @State private var auditReport: ManualAuditReport?
    
    var body: some View {
        NavigationView {
            VStack {
                // 進度顯示
                AuditProgressView(progress: auditChecklist.currentProgress)
                
                // 類別列表
                List(auditChecklist.auditCategories, id: \.id) { category in
                    CategoryRowView(category: category) {
                        selectedCategory = category
                    }
                }
                
                // 控制按鈕
                HStack {
                    Button("開始審計") {
                        auditChecklist.startAudit()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("生成報告") {
                        auditReport = auditChecklist.completeAudit()
                        showingReport = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(auditChecklist.currentProgress < 0.1)
                }
                .padding()
            }
            .navigationTitle("手動安全審計")
            .sheet(item: $selectedCategory) { category in
                CategoryDetailView(
                    category: category,
                    onStatusUpdate: auditChecklist.updateCheckItemStatus
                )
            }
            .sheet(isPresented: $showingReport) {
                if let report = auditReport {
                    AuditReportView(report: report)
                }
            }
        }
    }
}

struct AuditProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack {
            Text("審計進度")
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(progress * 100))% 完成")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct CategoryRowView: View {
    let category: SecurityAuditCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    priorityBadge
                    completionBadge
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityBadge: some View {
        Text(priorityText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var completionBadge: some View {
        let completed = category.checkItems.filter { $0.status != .notChecked }.count
        let total = category.checkItems.count
        
        return Text("\(completed)/\(total)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var priorityText: String {
        switch category.priority {
        case .critical: return "關鍵"
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
    
    private var priorityColor: Color {
        switch category.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct CategoryDetailView: View {
    let category: SecurityAuditCategory
    let onStatusUpdate: (String, String, CheckStatus, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: SecurityCheckItem?
    
    var body: some View {
        NavigationView {
            List(category.checkItems, id: \.id) { item in
                CheckItemRowView(
                    item: item,
                    onStatusUpdate: { status, note in
                        onStatusUpdate(category.id, item.id, status, note)
                    }
                )
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CheckItemRowView: View {
    let item: SecurityCheckItem
    let onStatusUpdate: (CheckStatus, String?) -> Void
    
    @State private var showingDetail = false
    @State private var note = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                
                Spacer()
                
                statusBadge
            }
            
            Text(item.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // 檢查點
            ForEach(item.checkPoints, id: \.self) { point in
                Text("• \(point)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 狀態控制
            HStack {
                statusPicker
                
                Button("詳細") {
                    showingDetail = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetail) {
            CheckItemDetailView(
                item: item,
                note: $note,
                onStatusUpdate: onStatusUpdate
            )
        }
    }
    
    private var statusBadge: some View {
        Text(statusText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var statusPicker: some View {
        Menu("狀態: \(statusText)") {
            Button("符合") { onStatusUpdate(.compliant, note.isEmpty ? nil : note) }
            Button("部分符合") { onStatusUpdate(.partiallyCompliant, note.isEmpty ? nil : note) }
            Button("不符合") { onStatusUpdate(.nonCompliant, note.isEmpty ? nil : note) }
            Button("不適用") { onStatusUpdate(.notApplicable, note.isEmpty ? nil : note) }
        }
    }
    
    private var statusText: String {
        switch item.status {
        case .notChecked: return "未檢查"
        case .compliant: return "符合"
        case .partiallyCompliant: return "部分符合"
        case .nonCompliant: return "不符合"
        case .notApplicable: return "不適用"
        }
    }
    
    private var statusColor: Color {
        switch item.status {
        case .notChecked: return .gray
        case .compliant: return .green
        case .partiallyCompliant: return .yellow
        case .nonCompliant: return .red
        case .notApplicable: return .blue
        }
    }
}

struct CheckItemDetailView: View {
    let item: SecurityCheckItem
    @Binding var note: String
    let onStatusUpdate: (CheckStatus, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(item.description)
                    .font(.body)
                
                Text("檢查要點:")
                    .font(.headline)
                
                ForEach(item.checkPoints, id: \.self) { point in
                    Text("• \(point)")
                        .font(.body)
                }
                
                Text("審計備註:")
                    .font(.headline)
                
                TextEditor(text: $note)
                    .border(Color.gray, width: 1)
                    .frame(height: 100)
                
                HStack {
                    Button("符合") {
                        onStatusUpdate(.compliant, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("部分符合") {
                        onStatusUpdate(.partiallyCompliant, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    
                    Button("不符合") {
                        onStatusUpdate(.nonCompliant, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("檢查項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AuditReportView: View {
    let report: ManualAuditReport
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 總覽
                    reportSummary
                    
                    // 發現
                    if !report.findings.isEmpty {
                        findingsSection
                    }
                    
                    // 建議
                    recommendationsSection
                }
                .padding()
            }
            .navigationTitle("審計報告")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("審計總覽")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("總評等級:")
                Text(ratingText)
                    .foregroundColor(ratingColor)
                    .fontWeight(.bold)
            }
            
            Text("檢查項目總數: \(report.totalCheckItems)")
            Text("符合項目: \(report.compliantItems)")
            Text("不符合項目: \(report.nonCompliantItems)")
            Text("部分符合項目: \(report.partiallyCompliantItems)")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var findingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("安全發現")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(report.priorityFindings, id: \.id) { finding in
                VStack(alignment: .leading, spacing: 4) {
                    Text(finding.title)
                        .font(.headline)
                    
                    Text(finding.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("建議: \(finding.recommendation)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("總體建議")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(report.recommendations, id: \.self) { recommendation in
                Text("• \(recommendation)")
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var ratingText: String {
        switch report.overallRating {
        case .excellent: return "優秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "需改善"
        }
    }
    
    private var ratingColor: Color {
        switch report.overallRating {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

#Preview {
    ManualSecurityAuditView()
}