import Foundation

enum SignalType: String, CaseIterable, Codable {
    case safe = "safe"
    case supplies = "supplies"
    case medical = "medical"
    case danger = "danger"
    
    func label(languageService: LanguageService) -> String {
        switch self {
        case .safe: return languageService.t("signal_safe")
        case .supplies: return languageService.t("signal_supplies")
        case .medical: return languageService.t("signal_medical")
        case .danger: return languageService.t("signal_danger")
        }
    }
    
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
    
    func displayName(languageService: LanguageService) -> String {
        switch self {
        case .N: return languageService.t("direction_north")
        case .NE: return languageService.t("direction_northeast")
        case .E: return languageService.t("direction_east")
        case .SE: return languageService.t("direction_southeast")
        case .S: return languageService.t("direction_south")
        case .SW: return languageService.t("direction_southwest")
        case .W: return languageService.t("direction_west")
        case .NW: return languageService.t("direction_northwest")
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

struct TimeFormatter {
    static func formatRelativeTime(_ timestamp: TimeInterval, languageService: LanguageService) -> String {
        let now = Date().timeIntervalSince1970
        let diff = now - timestamp
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        
        if hours > 0 {
            return "\(hours)\(languageService.t("hours_ago"))"
        } else if minutes > 0 {
            return "\(minutes)\(languageService.t("minutes_ago"))"
        } else {
            return languageService.t("just_now")
        }
    }
}
