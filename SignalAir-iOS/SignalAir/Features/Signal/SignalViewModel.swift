import Foundation
import SwiftUI

class SignalViewModel: ObservableObject {
    @Published var messages: [SignalMessage] = []
    
    private let deviceName = "Device-\(String(Int.random(in: 100000...999999)))"
    
    init() {
        generateSimulatedMessages()
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
        simulateResponses()
    }
    
    private func generateSimulatedMessages() {
        let simulatedMessages = [
            SignalMessage(type: .safe, deviceName: "救援隊-A", timestamp: Date().timeIntervalSince1970 - 300, distance: 150, direction: .NE),
            SignalMessage(type: .medical, deviceName: "Device-789012", timestamp: Date().timeIntervalSince1970 - 600, distance: 250, direction: .S),
            SignalMessage(type: .supplies, deviceName: "援助站-B", timestamp: Date().timeIntervalSince1970 - 900, distance: 80, direction: .W)
        ]
        messages = simulatedMessages
    }
    
    private func simulateResponses() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
            let responseTypes: [SignalType] = [.safe, .medical, .supplies]
            let randomType = responseTypes.randomElement() ?? .safe
            
            let responseMessage = SignalMessage(
                type: randomType,
                deviceName: "救援隊-\(["A", "B", "C"].randomElement()!)",
                distance: Double.random(in: 100...400),
                direction: CompassDirection.allCases.randomElement()
            )
            
            self.messages.insert(responseMessage, at: 0)
            if self.messages.count > 20 {
                self.messages = Array(self.messages.prefix(20))
            }
        }
    }
}
