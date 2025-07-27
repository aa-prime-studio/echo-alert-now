import Foundation

// MARK: - 舊版本資料清理器
/// 清理所有可能的舊版本資料和快取，確保app使用統一的協議版本1
class LegacyDataCleaner {
    
    // MARK: - 清理所有舊版本資料
    static func cleanAllLegacyData() {
        print("🧹 LegacyDataCleaner: 開始清理所有舊版本資料...")
        
        // 1. 清理協議版本相關的快取
        clearProtocolVersionCaches()
        
        // 2. 清理網路連接快取
        clearNetworkCaches()
        
        // 3. 清理信任評分快取
        clearTrustScoreCaches()
        
        // 4. 清理聊天訊息快取
        clearChatCaches()
        
        // 5. 清理設備指紋快取
        clearDeviceFingerprintCaches()
        
        // 6. 清理臨時ID快取
        clearTemporaryIDCaches()
        
        // 7. 清理安全日誌快取
        clearSecurityLogCaches()
        
        // 8. 清理MultipeerConnectivity快取
        clearMultipeerCaches()
        
        print("✅ LegacyDataCleaner: 舊版本資料清理完成")
    }
    
    // MARK: - 具體清理方法
    
    private static func clearProtocolVersionCaches() {
        let keys = [
            "protocol_version",
            "peer_versions",
            "negotiated_versions",
            "version_compatibility",
            "protocol_negotiation",
            "version_cache",
            "ProtocolVersionManager"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🔄 清理協議版本快取")
    }
    
    private static func clearNetworkCaches() {
        let keys = [
            "connected_peers",
            "peer_discovery",
            "network_topology",
            "mesh_routing",
            "connection_cache",
            "peer_trust_cache",
            "network_security_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🌐 清理網路快取")
    }
    
    private static func clearTrustScoreCaches() {
        let keys = [
            "trust_scores",
            "local_blacklist",
            "observation_list",
            "bloom_filter",
            "peer_reputation",
            "security_violations",
            "trust_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🛡️ 清理信任評分快取")
    }
    
    private static func clearChatCaches() {
        let keys = [
            "chat_messages",
            "message_hashes",
            "daily_message_count",
            "last_reset_date",
            "chat_cache",
            "mention_cache",
            "message_encoding_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("💬 清理聊天快取")
    }
    
    private static func clearDeviceFingerprintCaches() {
        let keys = [
            "device_uuid",
            "device_fingerprint",
            "daily_accounts",
            "device_identity",
            "fingerprint_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("📱 清理設備指紋快取")
    }
    
    private static func clearTemporaryIDCaches() {
        let keys = [
            "temp_device_id",
            "id_update_timer",
            "device_id_history",
            "temporary_id_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🆔 清理臨時ID快取")
    }
    
    private static func clearSecurityLogCaches() {
        let keys = [
            "security_logs",
            "security_events",
            "log_cache",
            "security_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("📝 清理安全日誌快取")
    }
    
    private static func clearMultipeerCaches() {
        // 清理MultipeerConnectivity framework可能的快取
        let keys = [
            "MCSession",
            "MCNearbyServiceAdvertiser", 
            "MCNearbyServiceBrowser",
            "MCPeerID",
            "multipeer_cache"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🔗 清理MultipeerConnectivity快取")
    }
    
    // MARK: - 強制清理系統快取
    static func forceCleanSystemCaches() {
        print("🔥 強制清理系統快取...")
        
        // 清理所有UserDefaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            UserDefaults.standard.synchronize()
        }
        
        // 清理Documents目錄中的快取檔案
        clearDocumentsCaches()
        
        print("✅ 系統快取清理完成")
    }
    
    private static func clearDocumentsCaches() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let documentsURL = documentsPath else { return }
        
        let cacheDirectories = [
            "SecurityLogs",
            "TrustScores", 
            "ChatCache",
            "NetworkCache",
            "ProtocolCache"
        ]
        
        for directory in cacheDirectories {
            let dirURL = documentsURL.appendingPathComponent(directory)
            try? FileManager.default.removeItem(at: dirURL)
        }
        
        print("📁 清理Documents快取目錄")
    }
}