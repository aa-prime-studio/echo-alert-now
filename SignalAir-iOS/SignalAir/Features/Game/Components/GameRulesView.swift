import SwiftUI

struct GameRulesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("遊戲規則")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                RuleItem(
                    icon: "number.circle",
                    title: "號碼範圍",
                    description: "1-60 隨機抽取"
                )
                
                RuleItem(
                    icon: "target",
                    title: "獲勝條件",
                    description: "完成 6 條線即獲勝"
                )
                
                RuleItem(
                    icon: "calendar",
                    title: "每日排行",
                    description: "每天更新排行榜"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct RuleItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.149, green: 0.243, blue: 0.894)) // #263ee4
                .frame(width: 40, height: 40)
                .background(Color(red: 0.0, green: 0.843, blue: 0.416)) // #00d76a
                .cornerRadius(20)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GameRulesView()
        .padding()
} 