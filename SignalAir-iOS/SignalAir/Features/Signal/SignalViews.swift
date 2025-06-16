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
                    Text(type.label(languageService: languageService))
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
                    Text(type.label(languageService: languageService))
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
        case .danger: return .black
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
                Text(message.type.label(languageService: languageService))
                    .font(.headline)
                    .fontWeight(.medium)
                Text("\(languageService.t("from")) \(message.deviceName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(TimeFormatter.formatRelativeTime(message.timestamp, languageService: languageService))
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
    
    private func backgroundColorForType(_ type: SignalType) -> Color {
        switch type {
        case .safe: return Color(red: 38/255, green: 62/255, blue: 234/255)
        case .supplies: return Color(red: 177/255, green: 153/255, blue: 234/255)
        case .medical: return Color(red: 255/255, green: 86/255, blue: 98/255)
        case .danger: return Color(red: 254/255, green: 201/255, blue: 27/255)
        }
    }
}

struct DirectionCompassView: View {
    let direction: CompassDirection
    let distance: Double
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "navigation.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(direction.angle))
                Text(DistanceFormatter.format(distance))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Text(direction.displayName(languageService: languageService))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
