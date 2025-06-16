import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    
    private let deviceName = "Device-\(String(Int.random(in: 100000...999999)))"
    private var cleanupTimer: Timer?
    
    init() {
        setupCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            message: newMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceName: deviceName,
            isOwn: true
        )
        
        messages.insert(message, at: 0)
        newMessage = ""
        
        if messages.count > 50 {
            messages = Array(messages.prefix(50))
        }
        
        print("發送訊息: \(message.message)")
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    func formatTime(_ timestamp: TimeInterval) -> String {
        let now = Date().timeIntervalSince1970
        let diff = now - timestamp
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        
        if hours > 0 {
            return "\(hours)小時前"
        } else if minutes > 0 {
            return "\(minutes)分鐘前"
        } else {
            return "剛剛"
        }
    }
    
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupOldMessages()
        }
    }
    
    private func cleanupOldMessages() {
        let twentyFourHoursAgo = Date().timeIntervalSince1970 - (24 * 60 * 60)
        messages = messages.filter { $0.timestamp > twentyFourHoursAgo }
    }
    

}
