import SwiftUI

// MARK: - 網路架構演示視圖
// 提供完整的UI界面來測試和監控新的通道池管理架構

struct NetworkArchitectureDemoView: View {
    @StateObject private var demo = NetworkArchitectureDemo()
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 測試控制台
            TestConsoleView(demo: demo)
                .tabItem {
                    Image(systemName: "testtube.2")
                    Text("測試控制台")
                }
                .tag(0)
            
            // Tab 2: 系統監控
            SystemMonitorView(demo: demo)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("系統監控")
                }
                .tag(1)
            
            // Tab 3: 測試結果
            TestResultsView(demo: demo)
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("測試結果")
                }
                .tag(2)
            
            // Tab 4: 系統報告
            SystemReportView(demo: demo)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("系統報告")
                }
                .tag(3)
        }
        .navigationTitle("網路架構演示")
        .alert("系統通知", isPresented: $showingAlert) {
            Button("確定") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - 測試控制台視圖
struct TestConsoleView: View {
    @ObservedObject var demo: NetworkArchitectureDemo
    @State private var selectedEdgeCase: EdgeCaseType = .simultaneousConnection
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 當前測試狀態
                    StatusCardView(
                        title: "測試狀態",
                        status: demo.isRunning ? "進行中" : "待機",
                        color: demo.isRunning ? .orange : .green
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("當前測試: \(demo.currentTest)")
                                .font(.subheadline)
                            
                            if demo.isRunning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    
                    // 測試控制按鈕
                    VStack(spacing: 16) {
                        // 完整測試套件
                        Button(action: {
                            Task {
                                await demo.startComprehensiveTest()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("執行完整測試套件")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(demo.isRunning)
                        
                        // 單一邊界情況測試
                        VStack(alignment: .leading, spacing: 12) {
                            Text("單一測試項目")
                                .font(.headline)
                            
                            Picker("選擇測試項目", selection: $selectedEdgeCase) {
                                ForEach(EdgeCaseType.allCases, id: \.self) { edgeCase in
                                    Text(edgeCase.rawValue).tag(edgeCase)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            Button(action: {
                                Task {
                                    await demo.testSpecificEdgeCase(selectedEdgeCase)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.circle")
                                    Text("執行選定測試")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .disabled(demo.isRunning)
                        }
                        
                        // 緊急恢復測試
                        Button(action: {
                            Task {
                                await demo.testEmergencyRecovery()
                            }
                        }) {
                            HStack {
                                Image(systemName: "cross.circle.fill")
                                Text("測試緊急恢復")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(demo.isRunning)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(16)
                    
                    // 測試結果摘要
                    if !demo.testResults.isEmpty {
                        TestSummaryCardView(results: demo.testResults)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("測試控制台")
            .refreshable {
                // 刷新狀態
            }
        }
    }
}

// MARK: - 系統監控視圖
struct SystemMonitorView: View {
    @ObservedObject var demo: NetworkArchitectureDemo
    @State private var realtimeStatus = ""
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 即時狀態卡片
                    StatusCardView(
                        title: "即時系統狀態",
                        status: "運行中",
                        color: .green
                    ) {
                        ScrollView {
                            Text(realtimeStatus)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 300)
                    }
                    
                    // 性能指標圖表區域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("性能指標")
                            .font(.headline)
                        
                        // 這裡可以添加實際的圖表組件
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                Text("性能圖表\n(需要圖表庫支持)")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("系統監控")
            .onAppear {
                startRealtimeUpdates()
            }
            .onDisappear {
                stopRealtimeUpdates()
            }
        }
    }
    
    private func startRealtimeUpdates() {
        updateStatus()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateStatus()
        }
    }
    
    private func stopRealtimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func updateStatus() {
        realtimeStatus = demo.getRealtimeStatus()
    }
}

// MARK: - 測試結果視圖
struct TestResultsView: View {
    @ObservedObject var demo: NetworkArchitectureDemo
    
    var body: some View {
        NavigationView {
            List {
                ForEach(demo.testResults.indices, id: \.self) { index in
                    let result = demo.testResults[index]
                    TestResultRowView(result: result)
                }
            }
            .navigationTitle("測試結果")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清除") {
                        demo.testResults.removeAll()
                    }
                    .disabled(demo.testResults.isEmpty)
                }
            }
        }
    }
}

// MARK: - 系統報告視圖
struct SystemReportView: View {
    @ObservedObject var demo: NetworkArchitectureDemo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !demo.systemReport.isEmpty {
                        Text(demo.systemReport)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                    } else {
                        Text("暫無系統報告")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding()
            }
            .navigationTitle("系統報告")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(
                        item: demo.systemReport,
                        subject: Text("SignalAir 網路架構測試報告"),
                        message: Text("系統測試報告")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(demo.systemReport.isEmpty)
                }
            }
        }
    }
}

// MARK: - 支持視圖組件

struct StatusCardView<Content: View>: View {
    let title: String
    let status: String
    let color: Color
    let content: Content
    
    init(title: String, status: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.status = status
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    
                    Text(status)
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            
            content
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
}

struct TestSummaryCardView: View {
    let results: [TestResult]
    
    private var summary: (passed: Int, total: Int, avgDuration: Double) {
        let passed = results.filter { $0.success }.count
        let total = results.count
        let avgDuration = total > 0 ? results.reduce(0) { $0 + $1.duration } / Double(total) : 0
        return (passed, total, avgDuration)
    }
    
    var body: some View {
        let (passed, total, avgDuration) = summary
        
        VStack(alignment: .leading, spacing: 12) {
            Text("測試摘要")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("通過率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(passed)/\(total)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("平均耗時")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2fs", avgDuration))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            // 成功率進度條
            ProgressView(value: Double(passed), total: Double(total))
                .tint(passed == total ? .green : (passed > total / 2 ? .orange : .red))
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
}

struct TestResultRowView: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.scenario)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !result.metrics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(result.metrics.keys.sorted()), id: \.self) { key in
                            VStack {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.2f", result.metrics[key] ?? 0))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 預覽
struct NetworkArchitectureDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NetworkArchitectureDemoView()
        }
    }
}