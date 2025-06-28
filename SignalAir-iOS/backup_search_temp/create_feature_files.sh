#!/bin/bash

echo "🎯 Creating Feature files..."

# === SIGNAL FEATURE ===

# SignalViewModel.swift
cat > "SignalAir/Features/Signal/SignalViewModel.swift" << 'EOF'
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
EOF

# SignalButtonView.swift + MessageListView.swift combined
cat > "SignalAir/Features/Signal/SignalViews.swift" << 'EOF'
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
EOF

# === CHAT FEATURE ===

# ChatViewModel.swift
cat > "SignalAir/Features/Chat/ChatViewModel.swift" << 'EOF'
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
        simulateResponse()
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
    
    private func simulateResponse() {
        let responses = ["收到！", "了解狀況", "正在前往", "需要更多資訊", "已通知相關單位"]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...4)) {
            guard let randomResponse = responses.randomElement() else { return }
            
            let responseMessage = ChatMessage(
                message: randomResponse,
                deviceName: "救援隊-\(String(Int.random(in: 100...999)))",
                isOwn: false
            )
            
            self.messages.insert(responseMessage, at: 0)
            if self.messages.count > 50 {
                self.messages = Array(self.messages.prefix(50))
            }
        }
    }
}
EOF

# ChatView.swift
cat > "SignalAir/Features/Chat/ChatView.swift" << 'EOF'
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            messagesSection
            Divider()
            inputSection.padding()
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("支援聊天室")
                    .font(.headline)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("24小時自動清除")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("(\(viewModel.messages.count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(action: { viewModel.clearMessages() }) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var messagesSection: some View {
        Group {
            if viewModel.messages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    VStack(spacing: 8) {
                        Text("目前沒有訊息")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("發送第一條訊息開始對話")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message, formatTime: viewModel.formatTime)
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                TextField("輸入訊息...", text: $viewModel.newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { viewModel.sendMessage() }
                
                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Text("訊息會在24小時後自動刪除 • 最多顯示50條訊息")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .background(Color.white)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let formatTime: (TimeInterval) -> String
    
    var body: some View {
        HStack {
            if message.isOwn { Spacer() }
            
            VStack(alignment: message.isOwn ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if !message.isOwn {
                        Text(message.deviceName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if message.isOwn {
                        Text("我")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isOwn ? Color.blue : Color.white)
                    .foregroundColor(message.isOwn ? .white : .primary)
                    .cornerRadius(16)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isOwn ? .trailing : .leading)
            
            if !message.isOwn { Spacer() }
        }
    }
}
EOF

echo "✅ Signal and Chat feature files created" 