import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject var languageService: LanguageService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 最後更新日期
                Text(languageService.t("last_updated"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                // 隱私承諾
                PolicySection(
                    title: languageService.t("privacy_commitment_title"),
                    content: languageService.t("privacy_commitment_content")
                )
                
                // 一、我們收集的資料
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageService.t("data_collection_title"))
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    
                    Text(languageService.t("data_collection_intro"))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    // 裝置資訊
                    SubPolicySection(
                        title: languageService.t("device_info_title"),
                        content: languageService.t("device_info_content")
                    )
                    
                    // 使用者設定
                    SubPolicySection(
                        title: languageService.t("user_settings_title"),
                        content: languageService.t("user_settings_content")
                    )
                    
                    // 位置資訊
                    SubPolicySection(
                        title: languageService.t("location_info_title"),
                        content: languageService.t("location_info_content")
                    )
                }
                .padding()
                
                // 二、我們不會收集的資料
                PolicySection(
                    title: languageService.t("data_not_collected_title"),
                    content: languageService.t("data_not_collected_content")
                )
                
                // 三、資料儲存與安全性
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageService.t("data_storage_title"))
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                    
                    // 本機儲存
                    SubPolicySection(
                        title: languageService.t("local_storage_title"),
                        content: languageService.t("local_storage_content")
                    )
                    
                    // 加密保護
                    SubPolicySection(
                        title: languageService.t("encryption_title"),
                        content: languageService.t("encryption_content")
                    )
                    
                    // 傳輸機制
                    SubPolicySection(
                        title: languageService.t("transmission_title"),
                        content: languageService.t("transmission_content")
                    )
                }
                .padding()
                
                // 四、第三方服務
                PolicySection(
                    title: languageService.t("third_party_title"),
                    content: languageService.t("third_party_content")
                )
                
                // 五、資料分享政策
                PolicySection(
                    title: languageService.t("data_sharing_title"),
                    content: languageService.t("data_sharing_content")
                )
                
                // 六、兒童隱私
                PolicySection(
                    title: languageService.t("children_privacy_title"),
                    content: languageService.t("children_privacy_content")
                )
                
                // 七、您的權利
                PolicySection(
                    title: languageService.t("user_rights_title"),
                    content: languageService.t("user_rights_content")
                )
                
                // 八、內購機制說明
                PolicySection(
                    title: languageService.t("purchase_mechanism_title"),
                    content: languageService.t("purchase_mechanism_content")
                )
                
                // 九、隱私政策更新通知
                PolicySection(
                    title: languageService.t("policy_updates_title"),
                    content: languageService.t("policy_updates_content")
                )
                
                // 十、聯絡方式
                PolicySection(
                    title: languageService.t("contact_title"),
                    content: languageService.t("contact_content")
                )
            }
            .padding()
        }
        .navigationTitle(languageService.t("privacy_policy"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.semibold)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}

struct SubPolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}
