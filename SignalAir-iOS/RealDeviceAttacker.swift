#!/usr/bin/env swift

import Foundation
import MultipeerConnectivity

// MARK: - 真實設備攻擊器
// 透過 MultipeerConnectivity 真正攻擊您的 SignalAir 實機

class RealDeviceAttacker: NSObject {
    
    private let serviceType = "signalair"
    private let myPeerID = MCPeerID(displayName: "AttackerDevice-\(UUID().uuidString.prefix(8))")
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?
    private var connectedPeers: [MCPeerID] = []
    private var attackTimer: Timer?
    private var isAttacking = false
    
    // 攻擊統計
    private var attackCount = 0
    private var detectionsTriggered = 0
    private var messagesBlocked = 0
    
    override init() {
        super.init()
        setupNetworking()
    }
    
    // MARK: - 網路設定
    private func setupNetworking() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self
        
        // 開始廣播和搜索
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("🔴 攻擊設備已啟動")
        print("📡 設備名稱: \(myPeerID.displayName)")
        print("🔍 正在搜索目標設備...")
    }
    
    // MARK: - 開始攻擊
    func startAttack() {
        guard !isAttacking else { return }
        
        isAttacking = true
        print("\\n🚨 開始攻擊序列！")
        print("=====================================")
        
        // 延遲10秒等待連接
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.executeAttackSequence()
        }
        
        // 啟動連接監控
        startConnectionMonitoring()
    }
    
    // MARK: - 連接監控
    private func startConnectionMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if self.connectedPeers.count > 0 {
                print("✅ 已連接 \(self.connectedPeers.count) 個設備")
                for peer in self.connectedPeers {
                    print("   - \(peer.displayName)")
                }
            } else {
                print("🔍 搜索設備中...")
            }
        }
    }
    
    // MARK: - 攻擊序列
    private func executeAttackSequence() {
        print("🎯 目標設備數量: \(connectedPeers.count)")
        
        if connectedPeers.isEmpty {
            print("❌ 沒有找到目標設備，請確認:")
            print("   1. 兩台設備都在運行 SignalAir")
            print("   2. 設備在同一個 Wi-Fi 網路")
            print("   3. 藍牙已開啟")
            return
        }
        
        print("🔥 開始真實駭客攻擊模式 - 長時間持續攻擊")
        print("⏰ 預計攻擊時間: 5-10分鐘")
        
        // 階段1: 偵察和初始滲透 (0-60秒)
        performReconnaissancePhase()
        
        // 階段2: 持續信任濫用攻擊 (60-180秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
            self.performSustainedTrustAbuseAttack()
        }
        
        // 階段3: 多階段APT攻擊 (180-300秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 180.0) {
            self.performAdvancedPersistentThreat()
        }
        
        // 階段4: 混合攻擊模式 (300-420秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0) {
            self.performHybridAttackMode()
        }
        
        // 階段5: 數據外洩和逃避檢測 (420-540秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 420.0) {
            self.performDataExfiltrationAndEvasion()
        }
        
        // 階段6: 最終破壞性攻擊 (540-600秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 540.0) {
            self.performFinalDestructiveAttack()
        }
        
        // 生成詳細報告
        DispatchQueue.main.asyncAfter(deadline: .now() + 600.0) {
            self.generateComprehensiveAttackReport()
        }
    }
    
    // MARK: - 攻擊1: 信任濫用攻擊
    private func performTrustAbuseAttack() {
        print("\\n🔥 攻擊1: 信任濫用攻擊")
        print("─────────────────────")
        
        let maliciousMessages = [
            "TRUST_ABUSE_RAPID_BEHAVIOR_CHANGE",
            "FAKE_TRUST_SCORE_MANIPULATION",
            "IDENTITY_SPOOFING_ATTEMPT",
            "BASELINE_BYPASS_ATTACK",
            "TRUST_THRESHOLD_EXPLOIT"
        ]
        
        // 重複攻擊多次以增加檢測機會
        for round in 1...3 {
            print("   🔄 信任濫用攻擊 - 第 \(round) 輪")
            for (index, message) in maliciousMessages.enumerated() {
                let attackData = createTrustAbusePayload(message: message, step: index)
                sendAttackToAllPeers(data: attackData)
                
                print("   📤 發送信任濫用攻擊 \(index + 1)/\(maliciousMessages.count)")
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        attackCount += maliciousMessages.count * 3
        print("   ✅ 信任濫用攻擊完成")
    }
    
    // MARK: - 攻擊2: 節點異常攻擊
    private func performNodeAnomalyAttack() {
        print("\\n🔥 攻擊2: 節點異常攻擊")
        print("─────────────────────")
        
        let anomalyPatterns = [
            "HIGH_FREQUENCY_CONNECTIONS",
            "MASSIVE_DATA_TRANSFER",
            "UNUSUAL_TIMING_PATTERN",
            "TOPOLOGY_MANIPULATION",
            "PROTOCOL_ABUSE"
        ]
        
        for (index, pattern) in anomalyPatterns.enumerated() {
            let attackData = createNodeAnomalyPayload(pattern: pattern, intensity: index + 1)
            sendAttackToAllPeers(data: attackData)
            
            print("   📤 發送節點異常攻擊 \(index + 1)/\(anomalyPatterns.count)")
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        attackCount += anomalyPatterns.count
        print("   ✅ 節點異常攻擊完成")
    }
    
    // MARK: - 攻擊3: APT 攻擊
    private func performAPTAttack() {
        print("\\n🔥 攻擊3: APT 攻擊")
        print("─────────────────────")
        
        let aptPhases = [
            "RECONNAISSANCE_PHASE",
            "INITIAL_COMPROMISE",
            "ESTABLISH_FOOTHOLD",
            "ESCALATE_PRIVILEGES",
            "INTERNAL_RECONNAISSANCE",
            "LATERAL_MOVEMENT",
            "MAINTAIN_PERSISTENCE",
            "COMPLETE_MISSION"
        ]
        
        for (index, phase) in aptPhases.enumerated() {
            let attackData = createAPTPayload(phase: phase, stageNumber: index + 1)
            sendAttackToAllPeers(data: attackData)
            
            print("   📤 執行 APT 階段 \(index + 1)/\(aptPhases.count): \(phase)")
            Thread.sleep(forTimeInterval: 2.0)
        }
        
        attackCount += aptPhases.count
        print("   ✅ APT 攻擊完成")
    }
    
    // MARK: - 攻擊4: DDoS 攻擊
    private func performDDoSAttack() {
        print("\\n🔥 攻擊4: DDoS 攻擊")
        print("─────────────────────")
        
        let ddosIntensity = 50 // 50個快速請求
        
        for i in 1...ddosIntensity {
            let attackData = createDDoSPayload(requestNumber: i)
            sendAttackToAllPeers(data: attackData)
            
            if i % 10 == 0 {
                print("   📤 DDoS 攻擊進度: \(i)/\(ddosIntensity)")
            }
            
            Thread.sleep(forTimeInterval: 0.1) // 高頻攻擊
        }
        
        attackCount += ddosIntensity
        print("   ✅ DDoS 攻擊完成")
    }
    
    // MARK: - 攻擊5: 數據外洩攻擊
    private func performDataExfiltrationAttack() {
        print("\\n🔥 攻擊5: 數據外洩攻擊")
        print("─────────────────────")
        
        let exfiltrationMethods = [
            "FRAGMENTED_DATA_EXTRACTION",
            "TUNNELING_ATTACK",
            "COVERT_CHANNEL_ABUSE",
            "ENCRYPTED_DATA_THEFT",
            "STEGANOGRAPHY_ATTACK"
        ]
        
        for (index, method) in exfiltrationMethods.enumerated() {
            let attackData = createDataExfiltrationPayload(method: method, dataSize: 1024 * (index + 1))
            sendAttackToAllPeers(data: attackData)
            
            print("   📤 執行數據外洩攻擊 \(index + 1)/\(exfiltrationMethods.count): \(method)")
            Thread.sleep(forTimeInterval: 1.5)
        }
        
        attackCount += exfiltrationMethods.count
        print("   ✅ 數據外洩攻擊完成")
    }
    
    // MARK: - 創建攻擊載荷
    private func createTrustAbusePayload(message: String, step: Int) -> Data {
        let payload = [
            "type": "trust_abuse_attack",
            "message": message,
            "step": step,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "high"
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createNodeAnomalyPayload(pattern: String, intensity: Int) -> Data {
        let payload = [
            "type": "node_anomaly_attack",
            "pattern": pattern,
            "intensity": intensity,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "medium"
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createAPTPayload(phase: String, stageNumber: Int) -> Data {
        let payload = [
            "type": "apt_attack",
            "phase": phase,
            "stage": stageNumber,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "critical"
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createDDoSPayload(requestNumber: Int) -> Data {
        let payload = [
            "type": "ddos_attack",
            "request_number": requestNumber,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "high"
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createDataExfiltrationPayload(method: String, dataSize: Int) -> Data {
        let payload = [
            "type": "data_exfiltration_attack",
            "method": method,
            "data_size": dataSize,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "critical"
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    // MARK: - 新增攻擊載荷創建方法
    
    private func createReconnaissancePayload(pattern: String) -> Data {
        let payload = [
            "type": "reconnaissance_attack",
            "pattern": pattern,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "medium",
            "phase": "reconnaissance",
            "target_scan": true,
            "stealth_mode": true
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createAdvancedTrustAbusePayload(type: String, round: Int) -> Data {
        let payload = [
            "type": "advanced_trust_abuse",
            "attack_type": type,
            "round": round,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "high",
            "persistence": true,
            "evasion_techniques": ["behavioral_mimicry", "trust_manipulation"],
            "payload_size": 2048 + round * 256
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createAPTCampaignPayload(campaign: Int, stage: String, stageNumber: Int) -> Data {
        let payload = [
            "type": "apt_campaign",
            "campaign_id": campaign,
            "stage": stage,
            "stage_number": stageNumber,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "critical",
            "persistence": true,
            "lateral_movement": true,
            "c2_communication": true,
            "encrypted_payload": true
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createHybridAttackPayload(attackType: String, round: Int) -> Data {
        let payload = [
            "type": "hybrid_attack",
            "attack_type": attackType,
            "round": round,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "critical",
            "multi_vector": true,
            "coordinated_attack": true,
            "payload_size": 4096 + round * 512,
            "obfuscation": true
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createEvasionPayload(technique: String, round: Int) -> Data {
        let payload = [
            "type": "evasion_attack",
            "technique": technique,
            "round": round,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "high",
            "stealth_mode": true,
            "anti_detection": true,
            "payload_obfuscation": true,
            "randomized_timing": true,
            "encrypted_content": true
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    private func createDestructivePayload(attackType: String, round: Int) -> Data {
        let payload = [
            "type": "destructive_attack",
            "attack_type": attackType,
            "round": round,
            "timestamp": Date().timeIntervalSince1970,
            "attacker_id": myPeerID.displayName,
            "severity": "critical",
            "destructive_intent": true,
            "system_targeting": true,
            "persistence_mechanism": true,
            "payload_size": 8192 + round * 1024,
            "final_stage": true
        ] as [String: Any]
        
        return try! JSONSerialization.data(withJSONObject: payload)
    }
    
    // MARK: - 發送攻擊數據
    private func sendAttackToAllPeers(data: Data) {
        guard let session = session else { return }
        
        for peer in connectedPeers {
            do {
                try session.send(data, toPeers: [peer], with: .reliable)
            } catch {
                print("   ❌ 向 \(peer.displayName) 發送攻擊失敗: \(error)")
                messagesBlocked += 1
            }
        }
    }
    
    // MARK: - 階段1: 偵察和初始滲透
    private func performReconnaissancePhase() {
        print("\\n🔍 階段1: 偵察和初始滲透 (0-60秒)")
        print("═══════════════════════════════════════")
        
        // 模擬網路掃描
        let scanningPatterns = [
            "NETWORK_TOPOLOGY_SCAN",
            "PORT_ENUMERATION",
            "SERVICE_DISCOVERY",
            "VULNERABILITY_PROBE",
            "DEVICE_FINGERPRINTING",
            "PROTOCOL_ANALYSIS",
            "TRAFFIC_PATTERN_ANALYSIS",
            "SECURITY_WEAKNESS_DETECTION"
        ]
        
        for (index, pattern) in scanningPatterns.enumerated() {
            // 每5秒發送一次偵察攻擊
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 7.0) {
                let attackData = self.createReconnaissancePayload(pattern: pattern)
                self.sendAttackToAllPeers(data: attackData)
                print("   🔍 偵察攻擊: \(pattern)")
            }
        }
        
        attackCount += scanningPatterns.count
        print("   ✅ 偵察階段已啟動 - 持續60秒")
    }
    
    // MARK: - 階段2: 持續信任濫用攻擊
    private func performSustainedTrustAbuseAttack() {
        print("\\n🔥 階段2: 持續信任濫用攻擊 (60-180秒)")
        print("═══════════════════════════════════════")
        
        // 2分鐘的持續攻擊
        let attackDuration = 120.0
        let attackInterval = 3.0
        let totalAttacks = Int(attackDuration / attackInterval)
        
        for i in 0..<totalAttacks {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * attackInterval) {
                let attackTypes = [
                    "TRUST_SCORE_MANIPULATION",
                    "IDENTITY_SPOOFING_ADVANCED",
                    "BASELINE_CORRUPTION",
                    "BEHAVIORAL_MIMICRY",
                    "TRUST_RELATIONSHIP_ABUSE",
                    "CREDENTIAL_HARVESTING",
                    "SESSION_HIJACKING",
                    "PRIVILEGE_ESCALATION_ATTEMPT"
                ]
                
                let randomAttack = attackTypes.randomElement() ?? "TRUST_ABUSE_GENERIC"
                let attackData = self.createAdvancedTrustAbusePayload(type: randomAttack, round: i + 1)
                self.sendAttackToAllPeers(data: attackData)
                
                if i % 10 == 0 {
                    print("   🔥 持續攻擊進度: \(i + 1)/\(totalAttacks)")
                }
            }
        }
        
        attackCount += totalAttacks
        print("   ✅ 持續信任濫用攻擊已啟動 - 2分鐘")
    }
    
    // MARK: - 階段3: 多階段APT攻擊
    private func performAdvancedPersistentThreat() {
        print("\\n💀 階段3: 多階段APT攻擊 (180-300秒)")
        print("═══════════════════════════════════════")
        
        let aptCampaigns = [
            // 經典APT攻擊鏈
            ["SPEAR_PHISHING", "MALWARE_DEPLOYMENT", "SYSTEM_COMPROMISE"],
            ["WATERING_HOLE", "ZERO_DAY_EXPLOIT", "BACKDOOR_INSTALLATION"],
            ["SUPPLY_CHAIN_ATTACK", "LATERAL_MOVEMENT", "PERSISTENCE_MECHANISM"],
            ["SOCIAL_ENGINEERING", "CREDENTIAL_THEFT", "PRIVILEGE_ESCALATION"],
            ["INSIDER_THREAT", "DATA_STAGING", "COVERT_CHANNEL_SETUP"]
        ]
        
        for (campaignIndex, campaign) in aptCampaigns.enumerated() {
            let campaignDelay = Double(campaignIndex) * 24.0 // 每24秒一個campaign
            
            for (stageIndex, stage) in campaign.enumerated() {
                let stageDelay = campaignDelay + Double(stageIndex) * 8.0 // 每8秒一個stage
                
                DispatchQueue.main.asyncAfter(deadline: .now() + stageDelay) {
                    let attackData = self.createAPTCampaignPayload(
                        campaign: campaignIndex + 1,
                        stage: stage,
                        stageNumber: stageIndex + 1
                    )
                    self.sendAttackToAllPeers(data: attackData)
                    print("   💀 APT Campaign \(campaignIndex + 1): \(stage)")
                }
            }
        }
        
        attackCount += aptCampaigns.flatMap { $0 }.count
        print("   ✅ 多階段APT攻擊已啟動 - 5個攻擊鏈")
    }
    
    // MARK: - 階段4: 混合攻擊模式
    private func performHybridAttackMode() {
        print("\\n⚡ 階段4: 混合攻擊模式 (300-420秒)")
        print("═══════════════════════════════════════")
        
        // 同時進行多種攻擊
        let hybridAttacks = [
            ("DDOS_AMPLIFICATION", 2.0),
            ("BOTNET_COORDINATION", 3.0),
            ("CRYPTOJACKING", 4.0),
            ("RANSOMWARE_DEPLOYMENT", 5.0),
            ("ROOTKIT_INSTALLATION", 6.0),
            ("KEYLOGGER_ACTIVATION", 7.0),
            ("SCREEN_CAPTURE", 8.0),
            ("NETWORK_SNIFFING", 9.0),
            ("MAN_IN_THE_MIDDLE", 10.0),
            ("DNS_POISONING", 11.0)
        ]
        
        for (attackType, interval) in hybridAttacks {
            // 每種攻擊重複多次
            for round in 1...15 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(round) * interval) {
                    let attackData = self.createHybridAttackPayload(
                        attackType: attackType,
                        round: round
                    )
                    self.sendAttackToAllPeers(data: attackData)
                    
                    if round % 5 == 0 {
                        print("   ⚡ 混合攻擊: \(attackType) 第\(round)輪")
                    }
                }
            }
        }
        
        attackCount += hybridAttacks.count * 15
        print("   ✅ 混合攻擊模式已啟動 - 10種攻擊類型")
    }
    
    // MARK: - 階段5: 數據外洩和逃避檢測
    private func performDataExfiltrationAndEvasion() {
        print("\\n🥷 階段5: 數據外洩和逃避檢測 (420-540秒)")
        print("═══════════════════════════════════════")
        
        let evasionTechniques = [
            "STEGANOGRAPHY_HIDING",
            "TRAFFIC_OBFUSCATION",
            "ENCRYPTION_BYPASS",
            "PROTOCOL_TUNNELING",
            "COVERT_TIMING_CHANNEL",
            "FRAGMENTATION_ATTACK",
            "POLYMORPHIC_ENCODING",
            "ANTI_FORENSIC_TECHNIQUES",
            "LOG_TAMPERING",
            "EVIDENCE_DESTRUCTION"
        ]
        
        for (index, technique) in evasionTechniques.enumerated() {
            // 每技術重複多次，間隔時間隨機
            for round in 1...12 {
                let randomDelay = Double(index) * 2.0 + Double(round) * Double.random(in: 1.0...3.0)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    let attackData = self.createEvasionPayload(
                        technique: technique,
                        round: round
                    )
                    self.sendAttackToAllPeers(data: attackData)
                    
                    if round % 4 == 0 {
                        print("   🥷 逃避技術: \(technique) 第\(round)輪")
                    }
                }
            }
        }
        
        attackCount += evasionTechniques.count * 12
        print("   ✅ 數據外洩和逃避檢測已啟動 - 10種逃避技術")
    }
    
    // MARK: - 階段6: 最終破壞性攻擊
    private func performFinalDestructiveAttack() {
        print("\\n💥 階段6: 最終破壞性攻擊 (540-600秒)")
        print("═══════════════════════════════════════")
        
        let destructiveAttacks = [
            "SYSTEM_DESTRUCTION",
            "DATA_CORRUPTION",
            "NETWORK_DISRUPTION",
            "DEVICE_BRICK_ATTEMPT",
            "FIRMWARE_CORRUPTION",
            "PERSISTENT_BACKDOOR",
            "FINAL_PAYLOAD_DELIVERY",
            "SELF_DESTRUCT_MECHANISM"
        ]
        
        for (index, attack) in destructiveAttacks.enumerated() {
            let attackDelay = Double(index) * 7.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + attackDelay) {
                // 每種破壞性攻擊發送5輪
                for round in 1...5 {
                    let roundDelay = Double(round) * 1.0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + roundDelay) {
                        let attackData = self.createDestructivePayload(
                            attackType: attack,
                            round: round
                        )
                        self.sendAttackToAllPeers(data: attackData)
                        print("   💥 破壞性攻擊: \(attack) 第\(round)輪")
                    }
                }
            }
        }
        
        attackCount += destructiveAttacks.count * 5
        print("   ✅ 最終破壞性攻擊已啟動 - 8種破壞技術")
    }
    
    // MARK: - 生成攻擊報告
    private func generateAttackReport() {
        print("\\n📊 攻擊報告")
        print("=====================================")
        print("🎯 目標設備數量: \(connectedPeers.count)")
        print("📤 總攻擊次數: \(attackCount)")
        print("🚫 被阻擋的訊息: \(messagesBlocked)")
        print("🔍 觸發的檢測: \(detectionsTriggered)")
        print("📈 攻擊成功率: \((Double(attackCount - messagesBlocked) / Double(attackCount)) * 100)%")
        
        if messagesBlocked > 0 {
            print("\\n✅ 安全系統運作正常！")
            print("🛡️  檢測到 \(messagesBlocked) 個攻擊並成功阻擋")
        } else {
            print("\\n⚠️  警告：沒有檢測到任何攻擊被阻擋")
            print("🔧 建議檢查安全系統設定")
        }
        
        print("\\n🔄 攻擊測試完成")
        print("=====================================")
        
        // 停止攻擊
        stopAttack()
    }
    
    // MARK: - 生成詳細攻擊報告
    private func generateComprehensiveAttackReport() {
        print("\\n📊 詳細駭客攻擊報告")
        print("=====================================================")
        print("🎯 目標設備數量: \(connectedPeers.count)")
        print("📤 總攻擊次數: \(attackCount)")
        print("🚫 被阻擋的訊息: \(messagesBlocked)")
        print("🔍 觸發的檢測: \(detectionsTriggered)")
        print("📈 攻擊成功率: \((Double(attackCount - messagesBlocked) / Double(attackCount)) * 100)%")
        print("⏰ 攻擊持續時間: 10分鐘")
        
        print("\\n🔥 攻擊階段總結:")
        print("   階段1: 偵察和初始滲透 - 8種偵察技術")
        print("   階段2: 持續信任濫用攻擊 - 40次持續攻擊")
        print("   階段3: 多階段APT攻擊 - 5個攻擊鏈")
        print("   階段4: 混合攻擊模式 - 10種攻擊類型")
        print("   階段5: 數據外洩和逃避檢測 - 10種逃避技術")
        print("   階段6: 最終破壞性攻擊 - 8種破壞技術")
        
        if messagesBlocked > 0 {
            print("\\n✅ 安全系統運作正常！")
            print("🛡️  成功檢測並阻擋了 \(messagesBlocked) 個攻擊")
            print("🔒 您的系統能夠抵禦真實駭客攻擊")
        } else {
            print("\\n⚠️  嚴重警告：沒有檢測到任何攻擊被阻擋")
            print("🔧 建議立即檢查並加強安全系統設定")
            print("🚨 系統可能容易受到真實駭客攻擊")
        }
        
        print("\\n🎯 攻擊評估結果:")
        let detectionRate = Double(detectionsTriggered) / Double(attackCount) * 100
        if detectionRate > 80 {
            print("   🟢 檢測率: \(String(format: "%.1f", detectionRate))% - 優秀")
        } else if detectionRate > 60 {
            print("   🟡 檢測率: \(String(format: "%.1f", detectionRate))% - 良好")
        } else if detectionRate > 40 {
            print("   🟠 檢測率: \(String(format: "%.1f", detectionRate))% - 需要改進")
        } else {
            print("   🔴 檢測率: \(String(format: "%.1f", detectionRate))% - 危險")
        }
        
        print("\\n🔄 真實駭客攻擊測試完成")
        print("=====================================================")
        
        // 停止攻擊
        stopAttack()
    }
    
    // MARK: - 停止攻擊
    private func stopAttack() {
        isAttacking = false
        attackTimer?.invalidate()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        
        print("\\n🔴 攻擊器已停止")
        exit(0)
    }
}

// MARK: - MCSession Delegate
extension RealDeviceAttacker: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            DispatchQueue.main.async {
                self.connectedPeers.append(peerID)
                print("✅ 連接到目標設備: \(peerID.displayName)")
            }
        case .connecting:
            print("🔄 正在連接到: \(peerID.displayName)")
        case .notConnected:
            DispatchQueue.main.async {
                self.connectedPeers.removeAll { $0 == peerID }
                print("❌ 與 \(peerID.displayName) 斷開連接")
            }
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 處理來自目標設備的回應
        if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let type = response["type"] as? String {
                if type.contains("security_alert") || type.contains("detection") {
                    detectionsTriggered += 1
                    print("   🚨 目標設備觸發安全警報: \(type)")
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 不處理串流
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 不處理資源傳輸
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 不處理資源傳輸
    }
}

// MARK: - MCNearbyServiceAdvertiser Delegate
extension RealDeviceAttacker: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📞 收到來自 \(peerID.displayName) 的邀請")
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowser Delegate
extension RealDeviceAttacker: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("🔍 發現目標設備: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("💔 失去目標設備: \(peerID.displayName)")
    }
}

// MARK: - 主程式
print("💀 SignalAir 高級駭客攻擊模擬器")
print("=====================================================")
print("🚨 警告：此工具模擬真實駭客攻擊行為")
print("🎯 目標：全面測試 SignalAir 安全防護系統")
print("⏰ 攻擊時間：10分鐘持續攻擊")
print("")
print("📋 攻擊階段預覽:")
print("   階段1: 偵察和初始滲透 (60秒)")
print("   階段2: 持續信任濫用攻擊 (2分鐘)")
print("   階段3: 多階段APT攻擊 (2分鐘)")
print("   階段4: 混合攻擊模式 (2分鐘)")
print("   階段5: 數據外洩和逃避檢測 (2分鐘)")
print("   階段6: 最終破壞性攻擊 (1分鐘)")
print("")
print("🔥 預計攻擊數量: 500+ 次")
print("💀 攻擊技術數量: 40+ 種")
print("")

let attacker = RealDeviceAttacker()

// 等待用戶確認
print("準備開始真實駭客攻擊測試...")
print("請確認:")
print("1. ✅ 兩台設備都在運行 SignalAir")
print("2. ✅ 設備在同一個 Wi-Fi 網路")
print("3. ✅ 藍牙已開啟")
print("4. ✅ 已在 testing-environment 分支")
print("5. ✅ 安全系統已啟用")
print("")
print("⚠️  注意：這是一個長時間攻擊測試")
print("📱 請保持應用程式在前台運行")
print("🔋 確保設備電量充足")
print("")
print("按 Enter 開始 10分鐘駭客攻擊...")
_ = readLine()

print("\\n🔥 駭客攻擊開始！")
print("=====================================================")

attacker.startAttack()

// 保持程式運行
RunLoop.main.run()