import Foundation

class LanguageService: ObservableObject {
    @Published var currentLanguage: Language = .chinese
    
    enum Language: String, CaseIterable {
        case chinese = "zh"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .chinese: return "繁體中文"
            case .english: return "English"
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "selectedLanguage"
    
    init() {
        loadLanguage()
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        userDefaults.set(language.rawValue, forKey: languageKey)
    }
    
    private func loadLanguage() {
        let savedLanguage = userDefaults.string(forKey: languageKey) ?? Language.chinese.rawValue
        currentLanguage = Language(rawValue: savedLanguage) ?? .chinese
    }
    
    func t(_ key: String) -> String {
        return translations[key] ?? key
    }
    
    private var translations: [String: String] {
        switch currentLanguage {
        case .chinese:
            return [
                // 標籤頁
                "settings": "設定",
                "language": "語言",
                "chinese": "繁體中文",
                "english": "English",
                "signals": "訊號",
                "chat": "聊天室",
                "games": "遊戲",
                
                // 設定頁面
                "subscription_status": "訂購狀態",
                "premium_user": "付費用戶",
                "free_user": "免費用戶",
                "upgrade_unlock_games": "升級解鎖遊戲功能",
                "restore_purchases": "恢復購買",
                "nickname": "暱稱",
                "device_name": "裝置名稱",
                "version": "版本",
                "privacy_policy": "隱私權政策",
                "terms_of_service": "服務條款",
                "help_guide": "使用說明",
                "select_language": "選擇語言",
                "done": "完成",
                "full_features": "享有完整功能",
                "signal_chat_features": "訊號、聊天室功能",
                
                // 訊號頁面
                "connected_status": "已連線 - 可發送和接收訊號",
                "signal_safe": "我安全",
                "signal_supplies": "需要物資",
                "signal_medical": "需要醫療",
                "signal_danger": "危險警告",
                "nearby_signals": "附近訊號",
                "no_signals": "目前沒有訊息",
                "signals_will_show": "當附近有人發送訊號時，會顯示在這裡",
                "from": "來自:",
                "just_now": "剛剛",
                "minutes_ago": "分鐘前",
                "hours_ago": "小時前",
                
                // 方向
                "direction_north": "北方",
                "direction_northeast": "東北方",
                "direction_east": "東方",
                "direction_southeast": "東南方",
                "direction_south": "南方",
                "direction_southwest": "西南方",
                "direction_west": "西方",
                "direction_northwest": "西北方",
                
                // 聊天室頁面
                "auto_delete_24h": "24小時自動清除",
                "no_messages": "目前沒有訊息",
                "send_first_message": "發送第一條訊息開始對話",
                "enter_message": "輸入訊息...",
                "auto_delete_info": "訊息會在24小時後自動刪除 • 最多顯示50條訊息",
                "me": "我",
                
                // 遊戲頁面
                "room_status": "房間狀態:",
                "waiting_players": "等待玩家",
                "needs_4_to_start": "需4人開始",
                "ready_to_start": "準備開始",
                "game_in_progress": "遊戲進行中",
                "game_finished": "遊戲結束",
                "people": "人",
                "seconds": "秒",
                "completed_lines": "完成線數",
                "won": "🎉 獲勝!",
                "leave": "離開",
                "playing_in": "正在遊戲:",
                
                // 暱稱編輯
                "set_nickname": "設定暱稱",
                "edit_nickname": "編輯暱稱",
                "enter_new_nickname": "輸入新暱稱",
                "nickname_max_chars": "暱稱最多20個字元",
                "cancel": "取消",
                "save": "儲存",
                "alert": "提示",
                "confirm": "確定",
                "nickname_empty": "暱稱不能為空",
                "nickname_too_long": "暱稱不能超過20個字元",
                "nickname_updated": "暱稱更新成功！",
                "nickname_no_change": "暱稱沒有變更",
                "nickname_max_reached": "已用完修改次數"
            ]
        case .english:
            return [
                // Tab labels
                "settings": "Settings",
                "language": "Language",
                "chinese": "繁體中文",
                "english": "English",
                "signals": "Signals",
                "chat": "Chat",
                "games": "Games",
                
                // Settings page
                "subscription_status": "Subscription Status",
                "premium_user": "Premium User",
                "free_user": "Free User",
                "upgrade_unlock_games": "Upgrade to Unlock Games",
                "restore_purchases": "Restore Purchases",
                "nickname": "Nickname",
                "device_name": "Device Name",
                "version": "Version",
                "privacy_policy": "Privacy Policy",
                "terms_of_service": "Terms of Service",
                "help_guide": "Help Guide",
                "select_language": "Select Language",
                "done": "Done",
                "full_features": "Full Features Available",
                "signal_chat_features": "Signal & Chat Features",
                
                // Signal page
                "connected_status": "Connected - Can send and receive signals",
                "signal_safe": "I'm Safe",
                "signal_supplies": "Need Supplies",
                "signal_medical": "Need Medical",
                "signal_danger": "Danger Alert",
                "nearby_signals": "Nearby Signals",
                "no_signals": "No messages yet",
                "signals_will_show": "When someone nearby sends a signal, it will appear here",
                "from": "From:",
                "just_now": "Just now",
                "minutes_ago": "minutes ago",
                "hours_ago": "hours ago",
                
                // Directions
                "direction_north": "North",
                "direction_northeast": "Northeast",
                "direction_east": "East",
                "direction_southeast": "Southeast",
                "direction_south": "South",
                "direction_southwest": "Southwest",
                "direction_west": "West",
                "direction_northwest": "Northwest",
                
                // Chat page
                "auto_delete_24h": "Auto-delete in 24 hours",
                "no_messages": "No messages yet",
                "send_first_message": "Send first message to start conversation",
                "enter_message": "Enter message...",
                "auto_delete_info": "Messages auto-delete after 24 hours • Max 50 messages",
                "me": "Me",
                
                // Game page
                "room_status": "Room Status:",
                "waiting_players": "Waiting for Players",
                "needs_4_to_start": "Need 4 to start",
                "ready_to_start": "Ready to Start",
                "game_in_progress": "Game in Progress",
                "game_finished": "Game Finished",
                "people": "people",
                "seconds": "seconds",
                "completed_lines": "Completed Lines",
                "won": "🎉 Won!",
                "leave": "Leave",
                "playing_in": "Playing in:",
                
                // Nickname editing
                "set_nickname": "Set Nickname",
                "edit_nickname": "Edit Nickname",
                "enter_new_nickname": "Enter new nickname",
                "nickname_max_chars": "Nickname max 20 characters",
                "cancel": "Cancel",
                "save": "Save",
                "alert": "Alert",
                "confirm": "OK",
                "nickname_empty": "Nickname cannot be empty",
                "nickname_too_long": "Nickname cannot exceed 20 characters",
                "nickname_updated": "Nickname updated successfully!",
                "nickname_no_change": "Nickname not changed",
                "nickname_max_reached": "Maximum changes reached"
            ]
        }
    }
}
