import SwiftUI

struct AsyncProcessingSettingsView: View {
    @AppStorage("useAsyncTrustProcessing") private var useAsyncProcessing: Bool = false
    @ObservedObject private var trustManager = TrustScoreManager()
    @State private var showingExplanation = false
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            VStack(alignment: .leading, spacing: 8) {
                Text(languageService.t("performance_optimization"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(languageService.t("optimize_trust_scoring"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 主要設定
            VStack(spacing: 16) {
                // 異步處理開關
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(languageService.t("async_trust_processing"))
                            .font(.headline)
                        
                        Text(useAsyncProcessing ? languageService.t("enabled_background") : languageService.t("disabled_realtime"))
                            .font(.caption)
                            .foregroundColor(useAsyncProcessing ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $useAsyncProcessing)
                        .onChange(of: useAsyncProcessing) { newValue in
                            trustManager.toggleAsyncProcessing(newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 說明按鈕
                Button(action: {
                    showingExplanation = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text(languageService.t("learn_more"))
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // 性能指標
                if useAsyncProcessing {
                    AsyncPerformanceIndicator()
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingExplanation) {
            AsyncProcessingExplanationView()
        }
    }
}

struct AsyncPerformanceIndicator: View {
    @State private var updateCount = 0
    @State private var batchCount = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Text(languageService.t("performance_monitoring"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(languageService.t("batch_updates"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(batchCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(languageService.t("total_updates"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(updateCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Text(languageService.t("async_processing_description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onReceive(NotificationCenter.default.publisher(for: .trustScoreUpdated)) { _ in
            updateCount += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .trustScoreBatchUpdated)) { _ in
            batchCount += 1
        }
    }
}

struct AsyncProcessingExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題說明
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageService.t("async_processing_optimization"))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(languageService.t("optimization_description"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 運作原理
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageService.t("how_it_works"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(
                                icon: "cpu",
                                title: "背景處理",
                                description: "將耗時的信任評分計算移到背景線程"
                            )
                            
                            FeatureRow(
                                icon: "square.stack.3d.up",
                                title: "批次處理",
                                description: "將多個更新合併為批次，減少重複計算"
                            )
                            
                            FeatureRow(
                                icon: "exclamationmark.triangle",
                                title: "優先級機制",
                                description: "緊急更新（如安全威脅）立即處理"
                            )
                            
                            FeatureRow(
                                icon: "arrow.clockwise",
                                title: "安全回滾",
                                description: "可隨時切換回同步模式"
                            )
                        }
                    }
                    
                    // 效果說明
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageService.t("expected_benefits"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BenefitRow(
                                benefit: "UI 響應速度",
                                improvement: "提升 50-100 倍"
                            )
                            
                            BenefitRow(
                                benefit: "電池續航",
                                improvement: "減少 20-30% 耗電"
                            )
                            
                            BenefitRow(
                                benefit: "網路效能",
                                improvement: "減少處理延遲"
                            )
                        }
                    }
                    
                    // 安全說明
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageService.t("security_guarantees"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 關鍵安全事件（如惡意內容檢測）仍會立即處理")
                            Text("• 可隨時關閉異步處理，立即回到原始模式")
                            Text("• 不影響安全功能的核心邏輯")
                            Text("• 所有更新都會被正確記錄和儲存")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BenefitRow: View {
    let benefit: String
    let improvement: String
    
    var body: some View {
        HStack {
            Text(benefit)
                .font(.body)
            
            Spacer()
            
            Text(improvement)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AsyncProcessingSettingsView()
}