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
                "live_support_chatroom": "即時支援\n聊天室",
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
                "number_range_desc": "1-99的數字",
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
                
                // 安全警告 - 8種攻擊類型
                "security_trust_anomaly_title": "可疑訊息檢測",
                "security_trust_anomaly_content": "設備 %device% 發送了不安全的訊息，可能影響您的通訊。",
                "security_trust_anomaly_action": "請停止與此設備通訊，並檢查設備安全。",
                
                "security_node_anomaly_title": "設備運行異常",
                "security_node_anomaly_content": "設備 %device% 出現異常行為，可能影響網路穩定。",
                "security_node_anomaly_action": "請檢查設備狀態並暫停其連線。",
                
                "security_apt_threat_title": "高級威脅檢測",
                "security_apt_threat_content": "設備 %device% 試圖探測您的網路，可能危害通訊安全。",
                "security_apt_threat_action": "請立即斷開與此設備的連線。",
                
                "security_connection_limit_title": "網路流量異常",
                "security_connection_limit_content": "檢測到大量訊息試圖干擾您的通訊網路。",
                "security_connection_limit_action": "請保持設備連線，系統正在自動處理。",
                
                "security_data_exfiltration_title": "數據洩露風險",
                "security_data_exfiltration_content": "設備 %device% 試圖傳送敏感數據，可能危害您的資訊。",
                "security_data_exfiltration_action": "請斷開設備連線並檢查數據安全。",
                
                "security_authentication_failure_title": "設備認證失敗",
                "security_authentication_failure_content": "設備 %device% 無法通過安全認證，可能存在風險。",
                "security_authentication_failure_action": "請檢查設備身份並重新連線。",
                
                "security_system_compromise_title": "多重安全威脅",
                "security_system_compromise_content": "設備 %device% 發起多種可疑活動，可能影響您的通訊。",
                "security_system_compromise_action": "請立即斷開連線並重新啟動應用程式。",
                
                "security_malware_detection_title": "可疑軟體檢測",
                "security_malware_detection_content": "設備 %device% 可能運行惡意軟體，威脅網路安全。",
                "security_malware_detection_action": "請立即斷開連線並掃描設備。",
                
                // 通用安全警告
                "security_action_now": "立即處理",
                "security_action_later": "稍後處理",
                "security_demo_title": "安全警告演示",
                "security_demo_description": "選擇攻擊類型來測試安全警告系統：",
                "security_demo_trigger": "觸發安全警告",
                "security_demo_status": "警告狀態",
                
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
                "emote_ring": "%@ 問你要不要嫁給他",
                
                // 錯誤處理和載入
                "error_occurred": "發生錯誤",
                "retry": "重試",
                "initializing_services": "正在初始化服務...",
                "terms_of_service_alt": "服務條款",
                "privacy_policy_terms": "隱私權條款",
                "network_diagnosis": "🔍 網路診斷",
                
                // 購買選項
                "monthly": "月費",
                "yearly": "年費",
                "monthly_billing": "每月收費",
                "yearly_billing": "每年收費",
                "processing": "處理中...",
                "purchase_now": "立即購買",
                "retry_loading": "重試載入",
                "test_unlock_dev": "🔓 測試解鎖 (開發模式)",
                
                // 異步處理設置
                "performance_optimization": "性能優化設定",
                "optimize_trust_scoring": "優化密集網路環境下的信任評分處理",
                "async_trust_processing": "異步信任評分處理",
                "enabled_background": "已啟用 - 後台處理",
                "disabled_realtime": "已停用 - 即時處理",
                "learn_more": "了解更多",
                "performance_monitoring": "性能監控",
                "batch_updates": "批次更新",
                "total_updates": "總更新數",
                "async_processing_description": "異步處理可減少 UI 阻塞並提升整體響應性",
                "async_processing_optimization": "異步處理優化",
                "optimization_description": "在密集網路環境中優化信任評分計算",
                "how_it_works": "運作原理",
                "expected_benefits": "預期效果",
                "security_guarantees": "安全保證",
                
                // 其他View文件
                "this_week_leaderboard": "本週排行榜",
                "bingo_god": "Bingo神",
                "are_you_dj": "你是DJ嗎",
                "turtle_god": "烏龜神",
                "no_leaderboard_data_weekly": "本週暫無排行榜數據",
                "joining": "加入中...",
                "emote_broadcast": "表情廣播",
                "terms_agreement": "使用條款同意",
                "welcome_signalair": "歡迎使用 SignalAir",
                "read_terms_before": "在使用本應用程式之前，請仔細閱讀並同意以下使用條款：",
                "agree_terms": "我已閱讀並同意上述使用條款",
                "agree_continue": "同意並繼續",
                "signalair_privacy_policy": "SignalAir Rescue 隱私權政策",
                
                // 幫助頁面
                "help_guide_main": "使用說明",
                "emergency_signals": "緊急訊號",
                "emergency_signals_content": "快速發送求救訊號：\n• 藍色「我安全」- 告知他人您的安全狀況\n• 紫色「需要物資」- 請求食物、水或其他物資\n• 紅色「需要醫療」- 緊急醫療協助\n• 黃色「危險警告」- 警告他人周遭危險",
                "chat_functions": "聊天室功能",
                "chat_functions_content": "與附近使用者溝通：\n• 輸入文字訊息並發送\n• 查看其他人的訊息\n• 訊息會在24小時後自動刪除\n• 支援最多50條訊息記錄",
                "bingo_game": "賓果遊戲",
                "bingo_game_content": "多人連線娛樂功能：\n• 需要付費解鎖\n• 3個遊戲房間可選擇\n• 與其他玩家即時互動\n• 自動產生隨機賓果卡",
                "settings_options": "設定選項",
                "settings_options_content": "個人化設定：\n• 切換語言（中文/English）\n• 查看訂購狀態\n• 升級到付費版本\n• 恢復之前的購買",
                "location_info": "位置資訊",
                "location_info_content": "距離與方向顯示：\n• 自動計算與訊號源的距離\n• 顯示模糊方位\n• 僅用於改善使用體驗\n",
                "important_notes": "注意事項",
                "important_notes_content": "使用時請注意：\n• 確保裝置有足夠電量\n• 在真正緊急情況下，請同時聯繫官方救援單位\n• 不要濫用緊急訊號功能\n• 保持裝置在通訊範圍內"
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
                "privacy_policy_main": "Privacy Policy",
                "terms_of_service_main": "Terms of Service",
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
                "live_support_chatroom": "Live Support\nChatroom",
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
                "number_range_desc": "Numbers 1-99",
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
                "no_leaderboard_data_main": "No leaderboard data yet",
                
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
                
                // Security Alerts - 8 Attack Types
                "security_trust_anomaly_title": "Suspicious Message Detection",
                "security_trust_anomaly_content": "Device %device% sent unsafe messages that may affect your communication.",
                "security_trust_anomaly_action": "Please stop communicating with this device and check device security.",
                
                "security_node_anomaly_title": "Device Operation Anomaly",
                "security_node_anomaly_content": "Device %device% shows abnormal behavior that may affect network stability.",
                "security_node_anomaly_action": "Please check device status and suspend its connection.",
                
                "security_apt_threat_title": "Advanced Threat Detection",
                "security_apt_threat_content": "Device %device% attempted to probe your network, potentially compromising communication security.",
                "security_apt_threat_action": "Please disconnect from this device immediately.",
                
                "security_connection_limit_title": "Network Traffic Anomaly",
                "security_connection_limit_content": "Detected massive messages attempting to disrupt your communication network.",
                "security_connection_limit_action": "Please keep device connected, system is handling automatically.",
                
                "security_data_exfiltration_title": "Data Leak Risk",
                "security_data_exfiltration_content": "Device %device% attempted to transmit sensitive data, potentially compromising your information.",
                "security_data_exfiltration_action": "Please disconnect device and check data security.",
                
                "security_authentication_failure_title": "Device Authentication Failed",
                "security_authentication_failure_content": "Device %device% failed security authentication and may pose risks.",
                "security_authentication_failure_action": "Please verify device identity and reconnect.",
                
                "security_system_compromise_title": "Multiple Security Threats",
                "security_system_compromise_content": "Device %device% initiated various suspicious activities that may affect your communication.",
                "security_system_compromise_action": "Please disconnect immediately and restart the application.",
                
                "security_malware_detection_title": "Suspicious Software Detection",
                "security_malware_detection_content": "Device %device% may be running malicious software, threatening network security.",
                "security_malware_detection_action": "Please disconnect immediately and scan the device.",
                
                // Common Security Alerts
                "security_action_now": "Handle Now",
                "security_action_later": "Handle Later",
                "security_demo_title": "Security Alert Demo",
                "security_demo_description": "Select attack type to test security alert system:",
                "security_demo_trigger": "Trigger Security Alert",
                "security_demo_status": "Alert Status",
                
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
                "emote_ring": "%@ asks if you want to marry them",
                
                // 錯誤處理和載入
                "error_occurred": "An Error Occurred",
                "retry": "Retry",
                "initializing_services": "Initializing services...",
                "terms_of_service_alt": "Terms of Service",
                "privacy_policy": "Privacy Policy",
                "network_diagnosis": "🔍 Network Diagnosis",
                
                // 購買選項
                "monthly": "Monthly",
                "yearly": "Yearly",
                "monthly_billing": "Monthly billing",
                "yearly_billing": "Yearly billing",
                "processing": "Processing...",
                "purchase_now": "Purchase Now",
                "retry_loading": "Retry Loading",
                "test_unlock_dev": "🔓 Test Unlock (Dev Mode)",
                
                // 異步處理設置
                "performance_optimization": "Performance Optimization Settings",
                "optimize_trust_scoring": "Optimize trust scoring in dense network environments",
                "async_trust_processing": "Async Trust Processing",
                "enabled_background": "Enabled - Background Processing",
                "disabled_realtime": "Disabled - Real-time Processing",
                "learn_more": "Learn More",
                "performance_monitoring": "Performance Monitoring",
                "batch_updates": "Batch Updates",
                "total_updates": "Total Updates",
                "async_processing_description": "Async processing reduces UI blocking and improves overall responsiveness",
                "async_processing_optimization": "Async Processing Optimization",
                "optimization_description": "Optimize trust scoring calculations in dense network environments",
                "how_it_works": "How It Works",
                "expected_benefits": "Expected Benefits",
                "security_guarantees": "Security Guarantees",
                
                // 其他View文件
                "this_week_leaderboard": "This Week's Leaderboard",
                "bingo_god": "Bingo God",
                "are_you_dj": "Are You a DJ?",
                "turtle_god": "Turtle God",
                "no_leaderboard_data_weekly": "No leaderboard data this week",
                "joining": "Joining...",
                "emote_broadcast": "Emote Broadcast",
                "terms_agreement": "Terms Agreement",
                "welcome_signalair": "Welcome to SignalAir",
                "read_terms_before": "Before using this application, please read and agree to the following terms:",
                "agree_terms": "I have read and agree to the above terms",
                "agree_continue": "Agree and Continue",
                "signalair_privacy_policy": "SignalAir Rescue Privacy Policy",
                
                // 幫助頁面
                "help_guide_main": "Help Guide",
                "emergency_signals": "Emergency Signals",
                "emergency_signals_content": "Quick emergency signal sending:\n• Blue 'I'm Safe' - Inform others of your safety status\n• Purple 'Need Supplies' - Request food, water or other supplies\n• Red 'Need Medical' - Emergency medical assistance\n• Yellow 'Danger Alert' - Warn others of surrounding dangers",
                "chat_functions": "Chat Functions",
                "chat_functions_content": "Communicate with nearby users:\n• Enter text messages and send\n• View messages from others\n• Messages auto-delete after 24 hours\n• Support up to 50 message records",
                "bingo_game": "Bingo Game",
                "bingo_game_content": "Multiplayer entertainment features:\n• Requires paid unlock\n• 3 game rooms to choose from\n• Real-time interaction with other players\n• Automatically generate random bingo cards",
                "settings_options": "Settings Options",
                "settings_options_content": "Personalization settings:\n• Switch language (Chinese/English)\n• View subscription status\n• Upgrade to paid version\n• Restore previous purchases",
                "location_info": "Location Information",
                "location_info_content": "Distance and direction display:\n• Automatically calculate distance to signal source\n• Show approximate direction\n• Only used to improve user experience\n",
                "important_notes": "Important Notes",
                "important_notes_content": "Please note when using:\n• Ensure device has sufficient battery\n• In real emergencies, also contact official rescue units\n• Do not abuse emergency signal functions\n• Keep device within communication range"
            ]
        }
    }
}
