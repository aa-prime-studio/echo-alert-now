import Foundation
import SwiftUI

class SignalViewModel: ObservableObject {
    @Published var messages: [SignalMessage] = []
    
    @Published var deviceName: String = UIDevice.current.name
    
    init() {
        // 初始化空的訊息列表，等待真實的訊號傳輸
    }
    
    func sendSignal(_ type: SignalType) {
        let message = SignalMessage(
            type: type,
            deviceName: deviceName,
            distance: Double.random(in: 50...500),
            direction: CompassDirection.allCases.randomElement()
        )
        
        messages.insert(message, at: 0)
        print("發送訊號: \(type.label)")
    }
    

    

}
