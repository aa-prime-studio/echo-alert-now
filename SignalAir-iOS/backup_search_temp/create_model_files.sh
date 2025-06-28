#!/bin/bash

echo "📊 Creating Model files..."

# SignalModels.swift
cat > "SignalAir/Shared/Models/SignalModels.swift" << 'EOF'
import Foundation

enum SignalType: String, CaseIterable, Codable {
    case safe = "safe"
    case supplies = "supplies"
    case medical = "medical"
    case danger = "danger"
    
    var label: String {
        switch self {
        case .safe: return "我安全"
        case .supplies: return "需要物資"
        case .medical: return "需要醫療"
        case .danger: return "危險警告"
        }
    }
    
    var iconName: String {
        switch self {
        case .safe: return "shield.fill"
        case .supplies: return "shippingbox.fill"
        case .medical: return "heart.fill"
        case .danger: return "exclamationmark.triangle.fill"
        }
    }
}

enum CompassDirection: String, CaseIterable, Codable {
    case N, NE, E, SE, S, SW, W, NW
    
    var angle: Double {
        switch self {
        case .N: return 0
        case .NE: return 45
        case .E: return 90
        case .SE: return 135
        case .S: return 180
        case .SW: return 225
        case .W: return 270
        case .NW: return 315
        }
    }
    
    var displayName: String {
        switch self {
        case .N: return "北方"
        case .NE: return "東北方"
        case .E: return "東方"
        case .SE: return "東南方"
        case .S: return "南方"
        case .SW: return "西南方"
        case .W: return "西方"
        case .NW: return "西北方"
        }
    }
}

struct SignalMessage: Identifiable, Codable {
    let id: String
    let type: SignalType
    let deviceName: String
    let timestamp: TimeInterval
    let distance: Double?
    let direction: CompassDirection?
    
    init(id: String = UUID().uuidString, type: SignalType, deviceName: String, timestamp: TimeInterval = Date().timeIntervalSince1970, distance: Double? = nil, direction: CompassDirection? = nil) {
        self.id = id
        self.type = type
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.distance = distance
        self.direction = direction
    }
}

struct DistanceFormatter {
    static func format(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}
EOF

# ChatModels.swift
cat > "SignalAir/Shared/Models/ChatModels.swift" << 'EOF'
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
EOF

# GameModels.swift
cat > "SignalAir/Shared/Models/GameModels.swift" << 'EOF'
import Foundation

struct BingoCard: Codable {
    let numbers: [Int]
    var marked: [Bool]
    
    init() {
        var uniqueNumbers: Set<Int> = []
        var generatedNumbers: [Int] = []
        
        while generatedNumbers.count < 25 {
            let number = Int.random(in: 1...60)
            if !uniqueNumbers.contains(number) {
                uniqueNumbers.insert(number)
                generatedNumbers.append(number)
            }
        }
        
        self.numbers = generatedNumbers
        self.marked = Array(repeating: false, count: 25)
    }
}

struct BingoRoom: Identifiable, Codable {
    let id: Int
    let name: String
    var players: [RoomPlayer]
    var currentNumbers: [Int]
    var isActive: Bool
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.players = []
        self.currentNumbers = []
        self.isActive = false
    }
}

struct RoomPlayer: Identifiable, Codable {
    let id: String
    let name: String
    var completedLines: Int
    var hasWon: Bool
    
    init(id: String = UUID().uuidString, name: String, completedLines: Int = 0, hasWon: Bool = false) {
        self.id = id
        self.name = name
        self.completedLines = completedLines
        self.hasWon = hasWon
    }
}
EOF

echo "✅ Model files created" 