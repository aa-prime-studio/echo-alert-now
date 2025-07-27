import SwiftUI
import MultipeerConnectivity
import Combine

// MARK: - Security Alert Banner System
// 安全警告橫幅系統 - 用戶友善的安全提示

class SecurityAlertBannerSystem: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SecurityAlertBannerSystem()
    
    // MARK: - Published Properties
    @Published var currentAlert: SecurityBannerAlert?
    @Published var alertQueue: [SecurityBannerAlert] = []
    @Published var isShowingAlert = false
    
    // MARK: - Properties
    private var alertTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let languageService = LanguageService.shared
    
    // MARK: - Configuration
    private let alertDisplayDuration: TimeInterval = 8.0
    private let maxQueueSize = 5
    
    private init() {
        setupAlertProcessing()
    }
    
    // MARK: - Public Interface
    func showSecurityAlert(for attackType: SecurityAlertType, deviceName: String = "未知設備") {
        let alert = createBannerAlert(for: attackType, deviceName: deviceName)
        
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
    
    // MARK: - Alert Creation
    private func createBannerAlert(for attackType: SecurityAlertType, deviceName: String) -> SecurityBannerAlert {
        let alertConfig = getAlertConfiguration(for: attackType)
        
        return SecurityBannerAlert(
            id: UUID(),
            attackType: attackType,
            title: alertConfig.title,
            body: alertConfig.body.replacingOccurrences(of: "%device%", with: deviceName),
            action: alertConfig.action,
            severity: alertConfig.severity,
            iconName: alertConfig.iconName,
            primaryColor: alertConfig.primaryColor,
            backgroundColor: alertConfig.backgroundColor,
            timestamp: Date(),
            deviceName: deviceName
        )
    }
    
    // MARK: - Alert Configuration
    private func getAlertConfiguration(for attackType: SecurityAlertType) -> AlertConfiguration {
        switch attackType {
        case .trustAnomaly:
            return AlertConfiguration(
                title: languageService.t("security_trust_anomaly_title"),
                body: languageService.t("security_trust_anomaly_content"),
                action: languageService.t("security_trust_anomaly_action"),
                severity: .high,
                iconName: "exclamationmark.triangle.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.orange.opacity(0.1)
            )
            
        case .nodeAnomaly:
            return AlertConfiguration(
                title: languageService.t("security_node_anomaly_title"),
                body: languageService.t("security_node_anomaly_content"),
                action: languageService.t("security_node_anomaly_action"),
                severity: .medium,
                iconName: "wifi.exclamationmark",
                primaryColor: Color.yellow,
                backgroundColor: Color.yellow.opacity(0.1)
            )
            
        case .aptThreat:
            return AlertConfiguration(
                title: languageService.t("security_apt_threat_title"),
                body: languageService.t("security_apt_threat_content"),
                action: languageService.t("security_apt_threat_action"),
                severity: .critical,
                iconName: "shield.slash.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
            
        case .connectionLimit:
            return AlertConfiguration(
                title: languageService.t("security_connection_limit_title"),
                body: languageService.t("security_connection_limit_content"),
                action: languageService.t("security_connection_limit_action"),
                severity: .high,
                iconName: "network.badge.shield.half.filled",
                primaryColor: Color.yellow,
                backgroundColor: Color.blue.opacity(0.1)
            )
            
        case .dataExfiltration:
            return AlertConfiguration(
                title: languageService.t("security_data_exfiltration_title"),
                body: languageService.t("security_data_exfiltration_content"),
                action: languageService.t("security_data_exfiltration_action"),
                severity: .critical,
                iconName: "lock.slash.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
            
        case .authenticationFailure:
            return AlertConfiguration(
                title: languageService.t("security_authentication_failure_title"),
                body: languageService.t("security_authentication_failure_content"),
                action: languageService.t("security_authentication_failure_action"),
                severity: .medium,
                iconName: "person.badge.minus.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.orange.opacity(0.1)
            )
            
        case .systemCompromise:
            return AlertConfiguration(
                title: languageService.t("security_system_compromise_title"),
                body: languageService.t("security_system_compromise_content"),
                action: languageService.t("security_system_compromise_action"),
                severity: .critical,
                iconName: "exclamationmark.octagon.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
            
        case .malwareDetection:
            return AlertConfiguration(
                title: languageService.t("security_malware_detection_title"),
                body: languageService.t("security_malware_detection_content"),
                action: languageService.t("security_malware_detection_action"),
                severity: .critical,
                iconName: "ant.fill",
                primaryColor: Color.yellow,
                backgroundColor: Color.red.opacity(0.1)
            )
        }
    }
    
    // MARK: - Alert Processing
    private func setupAlertProcessing() {
        // 監聽安全系統的告警
        NotificationCenter.default.publisher(for: .securityAlertTriggered)
            .sink { [weak self] notification in
                guard let alertInfo = notification.object as? [String: Any],
                      let attackType = alertInfo["attackType"] as? SecurityAlertType,
                      let deviceName = alertInfo["deviceName"] as? String else {
                    return
                }
                
                self?.showSecurityAlert(for: attackType, deviceName: deviceName)
            }
            .store(in: &cancellables)
    }
    
    private func queueAlert(_ alert: SecurityBannerAlert) {
        // 限制隊列大小
        if alertQueue.count >= maxQueueSize {
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
        
        // 自動關閉計時器
        alertTimer?.invalidate()
        alertTimer = Timer.scheduledTimer(withTimeInterval: alertDisplayDuration, repeats: false) { [weak self] _ in
            self?.dismissCurrentAlert()
        }
    }
    
    // MARK: - User Actions
    func executeAlertAction(for alert: SecurityBannerAlert) {
        switch alert.attackType {
        case .trustAnomaly, .nodeAnomaly, .aptThreat, .dataExfiltration, .systemCompromise, .malwareDetection:
            // 斷開與該設備的連線
            disconnectFromDevice(alert.deviceName)
            
        case .connectionLimit:
            // 啟動 DDoS 防護
            activateDDoSProtection()
            
        case .authenticationFailure:
            // 要求重新認證
            requestReauthentication(alert.deviceName)
        }
        
        // 記錄用戶行動
        logUserAction(alert: alert, action: "executed")
        
        // 關閉當前告警
        dismissCurrentAlert()
    }
    
    private func disconnectFromDevice(_ deviceName: String) {
        // 通知 NetworkService 斷開連線
        NotificationCenter.default.post(
            name: .disconnectFromDevice,
            object: ["deviceName": deviceName]
        )
    }
    
    private func activateDDoSProtection() {
        // 啟動 DDoS 保護機制
        NotificationCenter.default.post(
            name: .activateDDoSProtection,
            object: nil
        )
    }
    
    private func requestReauthentication(_ deviceName: String) {
        // 要求重新認證
        NotificationCenter.default.post(
            name: .requestReauthentication,
            object: ["deviceName": deviceName]
        )
    }
    
    private func logUserAction(alert: SecurityBannerAlert, action: String) {
        print("📝 用戶行動記錄:")
        print("   告警類型: \(alert.attackType)")
        print("   設備: \(alert.deviceName)")
        print("   行動: \(action)")
        print("   時間: \(Date())")
    }
}

// MARK: - SwiftUI Banner View
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
        .zIndex(1000) // 確保在最上層
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

// MARK: - Data Structures
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
    case low
    case medium
    case high
    case critical
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let securityAlertTriggered = Notification.Name("SecurityAlertTriggered")
    static let disconnectFromDevice = Notification.Name("DisconnectFromDevice")
    static let activateDDoSProtection = Notification.Name("ActivateDDoSProtection")
    static let requestReauthentication = Notification.Name("RequestReauthentication")
}

// MARK: - Integration Helper
class SecurityAlertIntegration {
    
    static func triggerSecurityAlert(attackType: SecurityAlertType, deviceName: String) {
        NotificationCenter.default.post(
            name: .securityAlertTriggered,
            object: [
                "attackType": attackType,
                "deviceName": deviceName
            ]
        )
    }
    
    static func setupSecurityAlertHandling() {
        // 整合到 IntegratedSecurityAlertSystem
        let alertSystem = IntegratedSecurityAlertSystem.shared
        
        // 監聽各種安全告警
        NotificationCenter.default.addObserver(
            forName: .trustAnomalyDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let result = notification.object as? TrustAnomalyResult {
                triggerSecurityAlert(
                    attackType: .trustAnomaly,
                    deviceName: result.userID ?? "未知設備"
                )
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .nodeAnomalyDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let alert = notification.object as? NodeAnomalyAlert {
                triggerSecurityAlert(
                    attackType: .nodeAnomaly,
                    deviceName: alert.nodeID
                )
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .behaviorAnomalyDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let alert = notification.object as? BehaviorAlert {
                triggerSecurityAlert(
                    attackType: .behaviorAnomaly,
                    deviceName: alert.affectedNodes.first ?? "未知設備"
                )
            }
        }
    }
}

// MARK: - Usage Example Integration
/*
 在您的主要 View 中添加安全警告橫幅：
 
 struct ContentView: View {
     var body: some View {
         ZStack {
             // 您的主要內容
             MainAppContent()
             
             // 安全警告橫幅
             SecurityAlertBannerView()
         }
         .onAppear {
             SecurityAlertIntegration.setupSecurityAlertHandling()
         }
     }
 }
 
 觸發安全告警的方法：
 
 // 在檢測到威脅時調用
 SecurityAlertIntegration.triggerSecurityAlert(
     attackType: .aptThreat,
     deviceName: "iPhone-用戶A"
 )
 */