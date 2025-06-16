import SwiftUI

struct SignalButtonView: View {
    let type: SignalType
    let onSend: (SignalType) -> Void
    let disabled: Bool
    let size: ButtonSize
    
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
                    Text(type.label)
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
                    Text(type.label)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("附近訊號")
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
                    Text("目前沒有訊息")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("當附近有人發送訊號時，會顯示在這裡")
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.type.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(backgroundColorForType(message.type))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.type.label)
                    .font(.headline)
                    .fontWeight(.medium)
                Text("來自: \(message.deviceName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(formatTime(message.timestamp))
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
    
    private func formatTime(_ timestamp: TimeInterval) -> String {
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
}

struct DirectionCompassView: View {
    let direction: CompassDirection
    let distance: Double
    
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
            Text(direction.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
