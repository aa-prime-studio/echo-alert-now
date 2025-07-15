import Foundation

class BingoManagerFactory {
    enum ManagerType {
        case timer
        case network(meshManager: MeshManagerProtocol, timerManager: TimerManager, settings: SettingsViewModel, language: LanguageService)
        case gameState(timerManager: TimerManager, networkManager: BingoNetworkManager)
    }
    
    static func createManager(type: ManagerType) -> Any {
        switch type {
        case .timer:
            return TimerManager()
            
        case .network(let meshManager, let timerManager, let settings, let language):
            return BingoNetworkManager(
                meshManager: meshManager,
                timerManager: timerManager,
                settingsViewModel: settings,
                languageService: language
            )
            
        case .gameState(let timerManager, let networkManager):
            return BingoGameStateManager(
                timerManager: timerManager,
                networkManager: networkManager
            )
        }
    }
    
    static func createAllManagers(
        meshManager: MeshManagerProtocol,
        settingsViewModel: SettingsViewModel,
        languageService: LanguageService
    ) -> (TimerManager, BingoNetworkManager, BingoGameStateManager) {
        
        guard let timerManager = createManager(type: .timer) as? TimerManager else {
            fatalError("Failed to create TimerManager")
        }
        
        guard let networkManager = createManager(type: .network(
            meshManager: meshManager,
            timerManager: timerManager,
            settings: settingsViewModel,
            language: languageService
        )) as? BingoNetworkManager else {
            fatalError("Failed to create BingoNetworkManager")
        }
        
        guard let gameStateManager = createManager(type: .gameState(
            timerManager: timerManager,
            networkManager: networkManager
        )) as? BingoGameStateManager else {
            fatalError("Failed to create BingoGameStateManager")
        }
        
        return (timerManager, networkManager, gameStateManager)
    }
}