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
        
        let timerManager = createManager(type: .timer) as! TimerManager
        
        let networkManager = createManager(type: .network(
            meshManager: meshManager,
            timerManager: timerManager,
            settings: settingsViewModel,
            language: languageService
        )) as! BingoNetworkManager
        
        let gameStateManager = createManager(type: .gameState(
            timerManager: timerManager,
            networkManager: networkManager
        )) as! BingoGameStateManager
        
        return (timerManager, networkManager, gameStateManager)
    }
}