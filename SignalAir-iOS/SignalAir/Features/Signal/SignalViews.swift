import Foundation
import CoreLocation
import SwiftUI

struct SignalButtonView: View {
    let type: SignalType
    let onSend: (SignalType) -> Void
    let disabled: Bool
    let size: ButtonSize
    @EnvironmentObject var languageService: LanguageService
    
    enum ButtonSize {
        case large, small
    }
    
    var body: some View {
        Button(action: { onSend(type) }) {
            if size == .large {
                VStack(spacing: 8) {
                    Image(systemName: type.iconName)
                        .font(.title)
                        .foregroundColor(.white)
                    Text(languageService.t(type.translationKey))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 132)
                .background(backgroundColorForType(type))
                .cornerRadius(12)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: type.iconName)
                        .font(.title3)
                        .foregroundColor(textColorForType(type))
                    Text(languageService.t(type.translationKey))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColorForType(type))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(backgroundColorForType(type))
                .cornerRadius(12)
            }
        }
        .disabled(disabled)
    }
    
    private func backgroundColorForType(_ type: SignalType) -> Color {
        switch type {
        case .safe: return Color(red: 38/255, green: 62/255, blue: 234/255)
        case .supplies: return Color(red: 177/255, green: 153/255, blue: 234/255)
        case .medical: return Color(red: 255/255, green: 86/255, blue: 98/255)
        case .danger: return Color(red: 254/255, green: 201/255, blue: 27/255)
        }
    }
    
    private func textColorForType(_ type: SignalType) -> Color {
        switch type {
        case .safe, .supplies, .medical: return .white
        case .danger: return .white
        }
    }
}

struct MessageListView: View {
    let messages: [SignalMessage]
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(languageService.t("nearby_signals"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("(\(messages.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text(languageService.t("no_signals"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(languageService.t("signals_will_show"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        MessageRowView(message: message)
                        if index < messages.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

struct MessageRowView: View {
    let message: SignalMessage
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.type.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(backgroundColorForType(message.type))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(languageService.t(message.type.translationKey))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text("\(languageService.t("from")) \(NicknameFormatter.cleanNickname(message.deviceName))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let distance = message.distance, let direction = message.direction {
                DirectionCompassView(direction: direction, distance: distance)
            }
        }
        .padding()
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(timestamp)
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)
        
        if days > 0 {
            return "\(days)\(languageService.t("days_ago"))"
        } else if hours > 0 {
            return "\(hours)\(languageService.t("hours_ago"))"
        } else if minutes > 0 {
            return "\(minutes)\(languageService.t("minutes_ago"))"
        } else {
            return languageService.t("just_now")
        }
    }
    
    private func backgroundColorForType(_ type: SignalType) -> Color {
        switch type {
        case .safe: return Color(red: 38/255, green: 62/255, blue: 234/255)
        case .supplies: return Color(red: 177/255, green: 153/255, blue: 234/255)
        case .medical: return Color(red: 255/255, green: 86/255, blue: 98/255)
        case .danger: return Color(red: 254/255, green: 201/255, blue: 27/255)
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        switch meters {
        case 0..<50:
            return "< 50m"
        case 50..<100:
            return "約 \(Int(meters/10)*10)m"
        case 100..<500:
            return "約 \(Int(meters/50)*50)m"
        case 500..<1000:
            return "約 \(Int(meters/100)*100)m"
        case 1000..<5000:
            let km = meters / 1000
            return "約 \(String(format: "%.1f", km)) 公里"
        default:
            let km = Int(meters / 1000)
            return "約 \(km) 公里"
        }
    }
    
    private func getDirectionText(_ direction: CompassDirection) -> String {
        switch direction {
        case .north: return "北方"
        case .northeast: return "東北方"
        case .east: return "東方"
        case .southeast: return "東南方"
        case .south: return "南方"
        case .southwest: return "西南方"
        case .west: return "西方"
        case .northwest: return "西北方"
        }
    }
    
    private func getDirectionAngle(_ direction: CompassDirection) -> Double {
        switch direction {
        case .north: return 0
        case .northeast: return 45
        case .east: return 90
        case .southeast: return 135
        case .south: return 180
        case .southwest: return 225
        case .west: return 270
        case .northwest: return 315
        }
    }
}

struct DirectionCompassView: View {
    let direction: CompassDirection
    let distance: Double
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDistance(distance))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(getDirectionText(direction))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
    
    private func getDirectionText(_ direction: CompassDirection) -> String {
        switch direction {
        case .north: return "北方"
        case .northeast: return "東北方"
        case .east: return "東方"
        case .southeast: return "東南方"
        case .south: return "南方"
        case .southwest: return "西南方"
        case .west: return "西方"
        case .northwest: return "西北方"
        }
    }
    
    private func getDirectionAngle(_ direction: CompassDirection) -> Double {
        switch direction {
        case .north: return 0
        case .northeast: return 45
        case .east: return 90
        case .southeast: return 135
        case .south: return 180
        case .southwest: return 225
        case .west: return 270
        case .northwest: return 315
        }
    }
}
