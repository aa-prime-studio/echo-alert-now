// ServiceContainer.swift - 更新部分

// MARK: - 更新的 BingoGameViewModel 創建方法
extension ServiceContainer {
    
    /// 【修復版】使用工廠模式創建 BingoGameViewModel
    @MainActor
    var bingoGameViewModel: BingoGameViewModel {
        get async {
            // 確保所有依賴都已就緒
            let safeMeshManager = await ensureMeshManagerReady()
            
            print("🎮 ServiceContainer: 使用工廠模式創建 BingoGameViewModel")
            
            // 使用工廠方法創建 ViewModel
            let viewModel = await BingoGameViewModelFactory.create(
                meshManager: safeMeshManager,
                securityService: self.securityService,
                settingsViewModel: self.settingsViewModel,
                languageService: self.languageService,
                nicknameService: self.nicknameService
            )
            
            print("🎮 ServiceContainer: BingoGameViewModel 創建完成")
            return viewModel
        }
    }
    
    /// 【備用方案】如果需要同步創建（不推薦）
    @MainActor
    var bingoGameViewModelSync: BingoGameViewModel {
        let safeMeshManager = meshManager // 假設已就緒
        
        print("🎮 ServiceContainer: 同步創建 BingoGameViewModel")
        
        let viewModel = BingoGameViewModel(
            meshManager: safeMeshManager,
            securityService: self.securityService,
            settingsViewModel: self.settingsViewModel,
            languageService: self.languageService,
            nicknameService: self.nicknameService
        )
        
        // 需要外部手動調用 initialize()
        print("⚠️ ServiceContainer: 需要外部調用 viewModel.initialize()")
        
        return viewModel
    }
    
    /// 確保 MeshManager 就緒
    private func ensureMeshManagerReady() async -> MeshManagerProtocol {
        // 如果 MeshManager 需要異步初始化，在這裡處理
        // 目前假設已經就緒
        return meshManager
    }
}

// MARK: - 使用範例

/*
// 在 ContentView 或其他地方使用：

class ContentView: View {
    @StateObject private var viewModel: BingoGameViewModel
    
    init(serviceContainer: ServiceContainer) {
        // 創建未初始化的 ViewModel
        let vm = serviceContainer.bingoGameViewModelSync
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        // UI 內容
        VStack {
            if viewModel.isInitializing {
                ProgressView("初始化中...")
            } else if viewModel.hasError {
                Text("錯誤: \(viewModel.errorMessage ?? "未知錯誤")")
            } else {
                // 正常的遊戲 UI
                gameContentView
            }
        }
        .task {
            // 在 UI 載入後進行初始化
            await viewModel.initialize()
        }
    }
    
    private var gameContentView: some View {
        // 遊戲內容
        Text("遊戲內容")
    }
}

// 或者使用異步創建：

class GameViewController: UIViewController {
    private var viewModel: BingoGameViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            // 異步創建 ViewModel
            self.viewModel = await ServiceContainer.shared.bingoGameViewModel
            
            // 設置 UI
            await MainActor.run {
                setupUI()
            }
        }
    }
    
    private func setupUI() {
        // 設置 UI
    }
}
*/