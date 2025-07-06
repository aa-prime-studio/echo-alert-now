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
                "broadcast_range_info": "訊號會廣播至 50-500 公尺範圍內的裝置",
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
                "distance_only": "僅距離",
                
                // 聊天室頁面
                "auto_delete_24h": "24小時自動清除",
                "no_messages": "目前沒有訊息",
                "send_first_message": "發送第一條訊息開始對話",
                "enter_message": "輸入訊息...",
                "auto_delete_info": "訊息於每日00:00自動清除 • 最多顯示100條訊息",
                "me": "我",
                
                // 遊戲頁面
                "room_status": "房間狀態:",
                "waiting_players": "等待玩家",
                "needs_2_to_start": "需2人開始",
                "ready_to_start": "準備開始",
                "game_in_progress": "遊戲進行中",
                "game_finished": "遊戲結束",
                "people": "人",
                "seconds": "秒",
                "completed_lines": "完成線數",
                "won": "🎉 獲勝!",
                "leave": "離開",
                "playing_in": "正在遊戲:",
                "select_room": "選擇房間",
                "players": "玩家",
                "game_rules": "遊戲規則",
                "number_range": "數字範圍",
                "number_range_desc": "1-60的數字",
                "win_condition": "勝利條件",
                "win_condition_desc": "完成5條線即獲勝",
                "daily_leaderboard": "每日排行榜",
                "daily_leaderboard_desc": "每日最佳成績",
                "room_players": "房間玩家",
                "lines_score": "線",
                "chat_room": "聊天室",
                "drawn_numbers": "已抽取號碼",
                "total_count": "共",
                "count_unit": "個",
                "waiting_draw": "等待抽取...",
                "todays_leaderboard": "今日排行榜",
                "no_leaderboard_data": "目前沒有排行榜數據",
                
                // 遊戲狀態和連線
                "offline": "離線",
                "waiting_sync": "等待同步",
                "click_drawn_numbers": "點擊已抽取的號碼來標記",
                "room_created": "🏠 已創建遊戲房間:",
                "joining_room": "🔍 正在加入遊戲房間:",
                "left_room": "👋 已離開遊戲房間",
                "system": "系統",
                
                // 聊天訊息
                "chat_cheer": "加油！",
                "chat_almost_win": "我差一條線就贏了！",
                "chat_good_luck": "好運氣！",
                
                // 暱稱編輯
                "set_nickname": "設定暱稱",
                "edit_nickname": "編輯暱稱",
                "enter_new_nickname": "輸入新暱稱",
                "nickname_max_chars": "暱稱最多8個字元",
                "cancel": "取消",
                "save": "儲存",
                "alert": "提示",
                "confirm": "確定",
                "nickname_empty": "暱稱不能為空",
                "nickname_too_long": "暱稱不能超過8個字元",
                "nickname_updated": "暱稱更新成功！",
                "nickname_no_change": "暱稱沒有變更",
                "nickname_max_reached": "已用完修改次數",
                "remaining_changes": "剩餘修改次數 ———",
                "no_changes_left": "已無修改次數 ———",
                
                // 賓果遊戲解鎖
                "bingo_locked_title": "賓果遊戲室已鎖定",
                "bingo_locked_description": "升級至付費版本即可解鎖賓果遊戲室，與朋友一起享受刺激的遊戲體驗！",
                "unlock_bingo_game": "解鎖賓果遊戲",
                
                // Purchase related
                "unlock_full_features": "解鎖完整功能",
                "choose_best_plan": "選擇最適合您的方案",
                "purchase": "購買",
                
                // 解鎖畫面和賓果遊戲室相關
                "bingo_game_room": "賓果遊戲室",
                "ready": "準備就緒",
                "game_features": "遊戲特色",
                "multiplayer_battle": "多人連線對戰",
                "max_6_players": "最多6人同時遊戲",
                "daily_leaderboard_title": "每日排行榜",
                "daily_best_scores": "競爭每日最佳成績",
                "realtime_chat": "即時聊天",
                "interact_with_players": "與其他玩家互動交流",
                "unlock_full_experience": "立即解鎖享受完整遊戲體驗",
                "upgrade_options": "升級選項",
                "recommended_plan": "推薦方案",
                
                // 遊戲室相關
                "can_join_until_full": "可繼續加入至滿房",
                "become_player": "成為player",
                "connecting_to_room": "正在連接房間",
                "became_room_host": "已成為房間主機",
                "game_starting": "遊戲即將開始...",
                "start_drawing": "開始抽卡！",
                "need_at_least": "需要至少",
                "players_to_start": "人才能開始遊戲",
                
                // 連線狀態
                "connected": "已連線",
                "connecting": "連線中",
                "disconnected": "未連線",
                "connected_devices": "已連線 (%@ 個設備)",
                "midnight_auto_update": "00:00 ——— 午夜自動更新",
                
                // 表情模板
                "emote_bingo": "%@ 喊出 BINGO!",
                "emote_nen": "%@ 說你嫩！",
                "emote_wow": "%@ 大叫太扯！",
                "emote_rocket": "%@ 說一起飛向宇宙",
                "emote_burger": "%@ 想吃漢堡",
                "emote_battery": "%@ 需要充電",
                "emote_dizzy": "%@ 頭暈了",
                "emote_mouse": "%@ 説家裡有老鼠",
                "emote_ring": "%@ 問你要不要嫁給他"
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
                "broadcast_range_info": "Signals broadcast to devices within 50-500 meters range",
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
                "distance_only": "Distance Only",
                
                // Chat page
                "auto_delete_24h": "Auto-delete in 24 hours",
                "no_messages": "No messages yet",
                "send_first_message": "Send first message to start conversation",
                "enter_message": "Enter message...",
                "auto_delete_info": "Messages auto-clear at 00:00 daily • Max 100 messages",
                "me": "Me",
                
                // Game page
                "room_status": "Room Status:",
                "waiting_players": "Waiting for Players",
                "needs_2_to_start": "Need 2 to start",
                "ready_to_start": "Ready to Start",
                "game_in_progress": "Game in Progress",
                "game_finished": "Game Finished",
                "people": "people",
                "seconds": "seconds",
                "completed_lines": "Completed Lines",
                "won": "🎉 Won!",
                "leave": "Leave",
                "playing_in": "Playing in:",
                "select_room": "Select Room",
                "players": "Players",
                "game_rules": "Game Rules",
                "number_range": "Number Range",
                "number_range_desc": "Numbers 1-60",
                "win_condition": "Win Condition",
                "win_condition_desc": "Complete 5 lines to win",
                "daily_leaderboard": "Daily Leaderboard",
                "daily_leaderboard_desc": "Daily best scores",
                "room_players": "Room Players",
                "lines_score": " lines",
                "chat_room": "Chat Room",
                "drawn_numbers": "Drawn Numbers",
                "total_count": "Total",
                "count_unit": "numbers",
                "waiting_draw": "Waiting to draw...",
                "todays_leaderboard": "Today's Leaderboard",
                "no_leaderboard_data": "No leaderboard data yet",
                
                // Nickname editing
                "set_nickname": "Set Nickname",
                "edit_nickname": "Edit Nickname",
                "enter_new_nickname": "Enter new nickname",
                "nickname_max_chars": "Nickname max 8 characters",
                "cancel": "Cancel",
                "save": "Save",
                "alert": "Alert",
                "confirm": "OK",
                "nickname_empty": "Nickname cannot be empty",
                "nickname_too_long": "Nickname cannot exceed 8 characters",
                "nickname_updated": "Nickname updated successfully!",
                "nickname_no_change": "Nickname not changed",
                "nickname_max_reached": "Maximum changes reached",
                "remaining_changes": "Remaining changes ———",
                "no_changes_left": "No changes left ———",
                
                // Game status and connection
                "offline": "Offline",
                "waiting_sync": "Waiting for sync",
                "click_drawn_numbers": "Click drawn numbers to mark",
                "room_created": "🏠 Created game room:",
                "joining_room": "🔍 Joining game room:",
                "left_room": "👋 Left game room",
                "system": "System",
                
                // Chat messages
                "chat_cheer": "Good luck!",
                "chat_almost_win": "Almost got a line!",
                "chat_good_luck": "Great job!",
                
                // Bingo game unlock
                "bingo_locked_title": "Bingo Game Room Locked",
                "bingo_locked_description": "Upgrade to premium to unlock the Bingo Game Room and enjoy exciting gameplay with friends!",
                "unlock_bingo_game": "Unlock Bingo Game",
                
                // Purchase related
                "unlock_full_features": "Unlock Full Features",
                "choose_best_plan": "Choose the best plan for you",
                "purchase": "Purchase",
                
                // Unlock screen and Bingo game room related
                "bingo_game_room": "Bingo Game Room",
                "ready": "Ready",
                "game_features": "Game Features",
                "multiplayer_battle": "Multiplayer Online Battle",
                "max_6_players": "Up to 6 players simultaneously",
                "daily_leaderboard_title": "Daily Leaderboard",
                "daily_best_scores": "Compete for daily best scores",
                "realtime_chat": "Real-time Chat",
                "interact_with_players": "Interact with other players",
                "unlock_full_experience": "Unlock immediately to enjoy full gaming experience",
                "upgrade_options": "Upgrade Options",
                "recommended_plan": "Recommended",
                
                // Game room related
                "can_join_until_full": "Can join until room is full",
                "become_player": "Become Player",
                "connecting_to_room": "Connecting to room",
                "became_room_host": "Became room host",
                "game_starting": "Game starting...",
                "start_drawing": "Start drawing cards!",
                "need_at_least": "Need at least",
                "players_to_start": "players to start game",
                
                // Connection status
                "connected": "Connected",
                "connecting": "Connecting",
                "disconnected": "Disconnected",
                "connected_devices": "Connected (%@ devices)",
                "midnight_auto_update": "00:00 — Automatic midnight update",
                
                // Emote templates
                "emote_bingo": "%@ shouts BINGO!",
                "emote_nen": "%@ says you're new!",
                "emote_wow": "%@ shouts too much!",
                "emote_rocket": "%@ says let's fly to space",
                "emote_burger": "%@ wants to eat burger",
                "emote_battery": "%@ needs charging",
                "emote_dizzy": "%@ is dizzy",
                "emote_mouse": "%@ says there's a mouse at home",
                "emote_ring": "%@ asks if you want to marry them"
            ]
        }
    }
}
