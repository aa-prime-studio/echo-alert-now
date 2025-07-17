import SwiftUI

// MARK: - Security Alert Banner Demo
// 安全警告橫幅演示程式

struct SecurityAlertBannerDemo: View {
    @StateObject private var bannerSystem = SecurityAlertBannerSystem.shared
    @State private var selectedAttackType: SecurityAlertType = .trustAnomaly
    @State private var deviceName = "iPhone-用戶A"
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 標題
                Text("🛡️ 安全警告橫幅演示")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // 說明
                Text("此演示展示不同類型的安全威脅警告橫幅")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 控制區域
                VStack(spacing: 16) {
                    // 攻擊類型選擇
                    VStack(alignment: .leading, spacing: 8) {
                        Text("選擇攻擊類型")
                            .font(.headline)
                        
                        Picker("攻擊類型", selection: $selectedAttackType) {
                            Text("信任濫用").tag(SecurityAlertType.trustAnomaly)
                            Text("節點異常").tag(SecurityAlertType.nodeAnomaly)
                            Text("高級威脅").tag(SecurityAlertType.aptThreat)
                            Text("DDoS攻擊").tag(SecurityAlertType.connectionLimit)
                            Text("數據外洩").tag(SecurityAlertType.dataExfiltration)
                            Text("認證失敗").tag(SecurityAlertType.authenticationFailure)
                            Text("系統入侵").tag(SecurityAlertType.systemCompromise)
                            Text("惡意軟體").tag(SecurityAlertType.malwareDetection)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 設備名稱輸入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("設備名稱")
                            .font(.headline)
                        
                        TextField("輸入設備名稱", text: $deviceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 觸發按鈕
                    Button(action: {
                        triggerSecurityAlert()
                    }) {
                        Text("觸發安全警告")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // 攻擊類型說明
                attackTypeDescriptionView
                
                // 佇列狀態
                queueStatusView
                
                Spacer()
            }
            .padding()
            
            // 安全警告橫幅
            SecurityAlertBannerView()
        }
    }
    
    // 攻擊類型說明視圖
    private var attackTypeDescriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("攻擊類型說明")
                .font(.headline)
            
            Text(getAttackTypeDescription(selectedAttackType))
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // 佇列狀態視圖
    private var queueStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("警告佇列狀態")
                .font(.headline)
            
            HStack {
                Text("當前警告:")
                    .fontWeight(.medium)
                Text(bannerSystem.currentAlert?.title ?? "無")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text("佇列中:")
                    .fontWeight(.medium)
                Text("\(bannerSystem.alertQueue.count) 個")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text("狀態:")
                    .fontWeight(.medium)
                Text(bannerSystem.isShowingAlert ? "顯示中" : "空閒")
                    .foregroundColor(bannerSystem.isShowingAlert ? .green : .gray)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // 觸發安全警告
    private func triggerSecurityAlert() {
        bannerSystem.showSecurityAlert(for: selectedAttackType, deviceName: deviceName)
    }
    
    // 獲取攻擊類型說明
    private func getAttackTypeDescription(_ attackType: SecurityAlertType) -> String {
        switch attackType {
        case .trustAnomaly:
            return "信任濫用攻擊：設備發送不安全的訊息，可能影響通訊安全。用戶需要停止與該設備通訊。"
        case .nodeAnomaly:
            return "節點異常：設備出現異常行為，可能影響網路穩定。用戶需要檢查設備狀態。"
        case .aptThreat:
            return "高級威脅：設備試圖探測網路，可能是高級攻擊。用戶需要立即斷開連線。"
        case .connectionLimit:
            return "DDoS攻擊：大量訊息試圖干擾通訊網路。系統會自動處理，用戶保持連線即可。"
        case .dataExfiltration:
            return "數據外洩：設備試圖傳送敏感數據，可能危害資訊安全。用戶需要斷開連線。"
        case .authenticationFailure:
            return "認證失敗：設備無法通過安全認證，可能存在風險。用戶需要重新認證。"
        case .systemCompromise:
            return "系統入侵：設備發起多種可疑活動，可能是混合攻擊。用戶需要立即斷開並重啟應用。"
        case .malwareDetection:
            return "惡意軟體：設備可能運行惡意軟體，威脅網路安全。用戶需要立即斷開並掃描設備。"
        }
    }
}

// MARK: - 預覽
struct SecurityAlertBannerDemo_Previews: PreviewProvider {
    static var previews: some View {
        SecurityAlertBannerDemo()
    }
}

// MARK: - 演示用的 SecurityAlertType
enum SecurityAlertType: CaseIterable {
    case trustAnomaly
    case nodeAnomaly
    case aptThreat
    case connectionLimit
    case dataExfiltration
    case authenticationFailure
    case systemCompromise
    case malwareDetection
}

// MARK: - 模擬的 SecurityAlertBannerSystem
class SecurityAlertBannerSystem: ObservableObject {
    static let shared = SecurityAlertBannerSystem()
    
    @Published var currentAlert: SecurityBannerAlert?
    @Published var alertQueue: [SecurityBannerAlert] = []
    @Published var isShowingAlert = false
    
    private var alertTimer: Timer?
    private let alertDisplayDuration: TimeInterval = 8.0
    
    func showSecurityAlert(for attackType: SecurityAlertType, deviceName: String) {
        let alert = createMockAlert(for: attackType, deviceName: deviceName)
        
        DispatchQueue.main.async { [weak self] in
            self?.queueAlert(alert)
        }
    }
    
    func dismissCurrentAlert() {
        DispatchQueue.main.async { [weak self] in
            self?.isShowingAlert = false
            self?.currentAlert = nil
            self?.processNextAlert()
        }
    }
    
    private func createMockAlert(for attackType: SecurityAlertType, deviceName: String) -> SecurityBannerAlert {
        let config = getMockAlertConfig(for: attackType)
        
        return SecurityBannerAlert(
            id: UUID(),
            attackType: attackType,
            title: config.title,
            body: config.body.replacingOccurrences(of: "%device%", with: deviceName),
            action: config.action,
            severity: config.severity,
            iconName: config.iconName,
            primaryColor: config.primaryColor,
            backgroundColor: config.backgroundColor,
            timestamp: Date(),
            deviceName: deviceName
        )
    }
    
    private func getMockAlertConfig(for attackType: SecurityAlertType) -> AlertConfiguration {
        switch attackType {
        case .trustAnomaly:
            return AlertConfiguration(
                title: "可疑訊息檢測",
                body: "設備 %device% 發送了不安全的訊息，可能影響您的通訊。",
                action: "請停止與此設備通訊，並檢查設備安全。",
                severity: .high,
                iconName: "exclamationmark.triangle.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.orange.opacity(0.1)
            )
        case .nodeAnomaly:
            return AlertConfiguration(
                title: "設備運行異常",
                body: "設備 %device% 出現異常行為，可能影響網路穩定。",
                action: "請檢查設備狀態並暫停其連線。",
                severity: .medium,
                iconName: "wifi.exclamationmark",
                primaryColor: Color.yellow,
                backgroundColor: Color.yellow.opacity(0.1)
            )
        case .aptThreat:
            return AlertConfiguration(
                title: "高級威脅檢測",
                body: "設備 %device% 試圖探測您的網路，可能危害通訊安全。",
                action: "請立即斷開與此設備的連線。",
                severity: .critical,
                iconName: "shield.slash.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
        case .connectionLimit:
            return AlertConfiguration(
                title: "網路流量異常",
                body: "檢測到大量訊息試圖干擾您的通訊網路。",
                action: "請保持設備連線，系統正在自動處理。",
                severity: .high,
                iconName: "network.badge.shield.half.filled",
                primaryColor: Color.yellow,
                backgroundColor: Color.blue.opacity(0.1)
            )
        case .dataExfiltration:
            return AlertConfiguration(
                title: "數據洩露風險",
                body: "設備 %device% 試圖傳送敏感數據，可能危害您的資訊。",
                action: "請斷開設備連線並檢查數據安全。",
                severity: .critical,
                iconName: "lock.slash.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
        case .authenticationFailure:
            return AlertConfiguration(
                title: "設備認證失敗",
                body: "設備 %device% 無法通過安全認證，可能存在風險。",
                action: "請檢查設備身份並重新連線。",
                severity: .medium,
                iconName: "person.badge.minus.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.orange.opacity(0.1)
            )
        case .systemCompromise:
            return AlertConfiguration(
                title: "多重安全威脅",
                body: "設備 %device% 發起多種可疑活動，可能影響您的通訊。",
                action: "請立即斷開連線並重新啟動應用程式。",
                severity: .critical,
                iconName: "exclamationmark.octagon.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
        case .malwareDetection:
            return AlertConfiguration(
                title: "可疑軟體檢測",
                body: "設備 %device% 可能運行惡意軟體，威脅網路安全。",
                action: "請立即斷開連線並掃描設備。",
                severity: .critical,
                iconName: "ant.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
        }
    }
    
    private func queueAlert(_ alert: SecurityBannerAlert) {
        if alertQueue.count >= 5 {
            alertQueue.removeFirst()
        }
        
        alertQueue.append(alert)
        
        if !isShowingAlert {
            processNextAlert()
        }
    }
    
    private func processNextAlert() {
        guard !alertQueue.isEmpty else { return }
        
        let nextAlert = alertQueue.removeFirst()
        currentAlert = nextAlert
        isShowingAlert = true
        
        alertTimer?.invalidate()
        alertTimer = Timer.scheduledTimer(withTimeInterval: alertDisplayDuration, repeats: false) { [weak self] _ in
            self?.dismissCurrentAlert()
        }
    }
}

// MARK: - 模擬的 SecurityBannerAlert
struct SecurityBannerAlert: Identifiable {
    let id: UUID
    let attackType: SecurityAlertType
    let title: String
    let body: String
    let action: String
    let severity: AlertSeverity
    let iconName: String
    let primaryColor: Color
    let backgroundColor: Color
    let timestamp: Date
    let deviceName: String
}

struct AlertConfiguration {
    let title: String
    let body: String
    let action: String
    let severity: AlertSeverity
    let iconName: String
    let primaryColor: Color
    let backgroundColor: Color
}

enum AlertSeverity {
    case low, medium, high, critical
}

// MARK: - 模擬的 SecurityAlertBannerView
struct SecurityAlertBannerView: View {
    @ObservedObject var bannerSystem = SecurityAlertBannerSystem.shared
    
    var body: some View {
        VStack {
            if bannerSystem.isShowingAlert, let alert = bannerSystem.currentAlert {
                SecurityBannerCard(alert: alert)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: bannerSystem.isShowingAlert)
            }
            
            Spacer()
        }
        .zIndex(1000)
    }
}

struct SecurityBannerCard: View {
    let alert: SecurityBannerAlert
    @ObservedObject private var bannerSystem = SecurityAlertBannerSystem.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // 警告圖示
            Image(systemName: alert.iconName)
                .font(.title2)
                .foregroundColor(alert.primaryColor)
                .frame(width: 24, height: 24)
            
            // 警告內容
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 14, weight: .bold)) // 主標題跟內文一樣大，但改成粗體
                    .foregroundColor(.black) // 統一改成黑色
                
                Text(alert.body)
                    .font(.system(size: 14)) // 警告文字大小
                    .foregroundColor(.black) // 統一改成黑色
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(alert.action)
                    .font(.system(size: 12, weight: .medium)) // 小字改成藍色字
                    .foregroundColor(.blue) // 使用安全藍色按鈕色
            }
            
            Spacer()
            
            // 關閉按鈕
            Button(action: {
                bannerSystem.dismissCurrentAlert()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white) // 白底背景，透明度100%
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1) // 灰色邊框
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 使用說明
/*
 🛡️ 安全警告橫幅演示程式
 此程式展示了 SignalAir 的安全警告橫幅系統
 包含8種不同的攻擊類型警告
 每種警告都有用戶友善的說明和建議行動
 
 使用方法：
 1. 在 Xcode 中打開此項目
 2. 運行 SecurityAlertBannerDemo
 3. 選擇不同的攻擊類型
 4. 點擊觸發按鈕查看警告效果
 
 特色功能：
 • 8種安全威脅類型
 • 用戶友善的警告訊息
 • 清晰的行動建議
 • 自動消失計時器
 • 警告佇列管理
 • 美觀的 UI 設計
 */