import Foundation

// MARK: - 協議版本管理器
// 注意：實際實現已移至 ServiceContainer.swift 以解決編譯範圍問題
// 此檔案保留作為參考，實際使用時請參考 ServiceContainer.swift 中的內聯版本

// MARK: - 協議版本信息
public struct ProtocolVersionInfo {
    public let currentVersion: UInt8
    public let minSupportedVersion: UInt8
    public let preferredFormat: MessageFormat
    
    public enum MessageFormat {
        case legacy    // 舊版本格式（57字節）
        case compact   // 新版本精簡格式（48-51字節）
    }
}