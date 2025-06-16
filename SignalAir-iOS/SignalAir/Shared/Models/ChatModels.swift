import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let message: String
    let deviceName: String
    let timestamp: TimeInterval
    let isOwn: Bool
    
    init(id: String = UUID().uuidString, message: String, deviceName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isOwn: Bool = false) {
        self.id = id
        self.message = message
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.isOwn = isOwn
    }
}
