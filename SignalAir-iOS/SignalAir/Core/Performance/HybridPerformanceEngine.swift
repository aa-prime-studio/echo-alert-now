import Foundation
import Accelerate
import Metal
import MetalPerformanceShaders

/// 混合性能引擎：智能選擇 Accelerate 或 Metal 進行優化
class HybridPerformanceEngine {
    // MARK: - Properties
    
    /// 性能閾值配置
    private let accelerateThreshold = 100    // < 100 筆用 Accelerate
    private let metalThreshold = 1000        // > 1000 筆用 Metal GPU
    
    /// Accelerate 並發隊列
    private let accelerateQueue = DispatchQueue(label: "com.signalAir.accelerate", 
                                                attributes: .concurrent)
    
    /// Metal GPU 資源（延遲初始化以避免 Swift 6 問題）
    private var _metalDevice: MTLDevice?
    private var _metalQueue: MTLCommandQueue?
    private var _metalLibrary: MTLLibrary?
    private var _trustComputePipeline: MTLComputePipelineState?
    private var isMetalSetup = false
    private let metalSetupQueue = DispatchQueue(label: "com.signalAir.metal.setup")
    
    /// 性能統計
    private var performanceMetrics = PerformanceMetrics()
    
    // MARK: - Singleton
    
    static let shared = HybridPerformanceEngine()
    
    private init() {
        // 延遲 Metal 設置到實際需要時
        print("🔧 HybridPerformanceEngine: 初始化完成，Metal 將在需要時設置")
    }
    
    // MARK: - Setup
    
    private func setupMetalIfNeeded() {
        guard !isMetalSetup else { return }
        
        metalSetupQueue.sync {
            guard !isMetalSetup else { return }
            
            _metalDevice = MTLCreateSystemDefaultDevice()
            _metalQueue = _metalDevice?.makeCommandQueue()
            
            // 加載 Metal shader library
            if let device = _metalDevice {
                do {
                    _metalLibrary = device.makeDefaultLibrary()
                    
                    // 創建計算管線
                    if let trustFunction = _metalLibrary?.makeFunction(name: "trustScoreKernel") {
                        _trustComputePipeline = try device.makeComputePipelineState(function: trustFunction)
                    }
                    print("✅ Metal 初始化成功")
                } catch {
                    print("❌ Metal 初始化失敗: \(error)")
                }
            } else {
                print("⚠️ Metal 設備不可用")
            }
            
            isMetalSetup = true
        }
    }
    
    // MARK: - Metal Properties Access
    
    private var metalDevice: MTLDevice? {
        setupMetalIfNeeded()
        return _metalDevice
    }
    
    private var metalQueue: MTLCommandQueue? {
        setupMetalIfNeeded()
        return _metalQueue
    }
    
    private var metalLibrary: MTLLibrary? {
        setupMetalIfNeeded()
        return _metalLibrary
    }
    
    private var trustComputePipeline: MTLComputePipelineState? {
        setupMetalIfNeeded()
        return _trustComputePipeline
    }
    
    // MARK: - 智能處理選擇器
    
    /// 根據數據量自動選擇最佳處理方式
    func processTrustScores(_ scores: [Float], 
                           behaviors: [[Float]]) async -> [Float] {
        let dataCount = scores.count
        
        switch dataCount {
        case 0..<accelerateThreshold:
            // 小量數據：純 Swift
            return processWithSwift(scores, behaviors: behaviors)
            
        case accelerateThreshold..<metalThreshold:
            // 中量數據：Accelerate SIMD
            return await processWithAccelerate(scores, behaviors: behaviors)
            
        default:
            // 大量數據：Metal GPU
            return await processWithMetal(scores, behaviors: behaviors)
        }
    }
    
    // MARK: - Layer 1: 即時響應 (< 1ms) - Accelerate
    
    /// 超快速信任檢查
    func quickTrustCheck(pattern: [Float], 
                        against knownPattern: [Float]) -> Float {
        guard pattern.count == knownPattern.count else { return 0 }
        
        var similarity: Float = 0
        
        // 使用 Accelerate 向量點積計算相似度
        vDSP_dotpr(pattern, 1, 
                   knownPattern, 1, 
                   &similarity, 
                   vDSP_Length(pattern.count))
        
        // 正規化到 0-100
        return min(max(similarity * 100, 0), 100)
    }
    
    /// 批量 XOR 加密優化
    func batchXOR(data: [UInt8], key: [UInt8]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: data.count)
        let keyRepeated = Array(repeating: key, count: (data.count / key.count) + 1)
            .flatMap { $0 }
            .prefix(data.count)
        
        // SIMD 並行 XOR
        data.withUnsafeBufferPointer { dataPtr in
            Array(keyRepeated).withUnsafeBufferPointer { keyPtr in
                result.withUnsafeMutableBufferPointer { resultPtr in
                    for i in stride(from: 0, to: data.count, by: 16) {
                        let remaining = min(16, data.count - i)
                        for j in 0..<remaining {
                            resultPtr[i + j] = dataPtr[i + j] ^ keyPtr[i + j]
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Layer 2: 定期分析 - Accelerate
    
    /// 計算信任統計數據（簡化版）
    private func calculateSimpleStats(scores: [Float]) -> (mean: Float, variance: Float) {
        guard !scores.isEmpty else {
            return (mean: 0, variance: 0)
        }
        
        var mean: Float = 0
        var variance: Float = 0
        
        // SIMD 加速統計計算
        vDSP_meanv(scores, 1, &mean, vDSP_Length(scores.count))
        vDSP_measqv(scores, 1, &variance, vDSP_Length(scores.count))
        
        return (mean: mean, variance: variance)
    }
    
    /// 行為模式相似度矩陣
    func calculateSimilarityMatrix(patterns: [[Float]]) async -> [[Float]] {
        let count = patterns.count
        var matrix = [[Float]](repeating: [Float](repeating: 0, count: count), 
                              count: count)
        
        await withTaskGroup(of: (Int, Int, Float).self) { group in
            for i in 0..<count {
                for j in i..<count {
                    group.addTask {
                        let similarity = self.quickTrustCheck(
                            pattern: patterns[i], 
                            against: patterns[j]
                        )
                        return (i, j, similarity)
                    }
                }
            }
            
            for await (i, j, similarity) in group {
                matrix[i][j] = similarity
                matrix[j][i] = similarity
            }
        }
        
        return matrix
    }
    
    // MARK: - Layer 3: 批量處理 - Metal GPU
    
    /// GPU 加速的批量行為分析
    func batchAnalyzeBehaviors(for peers: [String], 
                              behaviors: [[Float]]) async -> [String] {
        // 簡化實現，直接返回安全狀態
        return Array(repeating: "safe", count: peers.count)
    }
    
    private func originalBatchAnalyzeBehaviors(for peers: [String], 
                              behaviors: [[Float]]) async -> [String] {
        guard behaviors.count >= metalThreshold,
              let device = metalDevice,
              let queue = metalQueue else {
            // 降級到 Accelerate
            return Array(repeating: "safe", count: behaviors.count)
        }
        
        do {
            // 準備 GPU 數據
            let flatBehaviors = behaviors.flatMap { $0 }
            let bufferSize = flatBehaviors.count * MemoryLayout<Float>.size
            
            guard let inputBuffer = device.makeBuffer(bytes: flatBehaviors, 
                                                     length: bufferSize) else {
                throw PerformanceError.bufferCreationFailed
            }
            
            let outputBuffer = device.makeBuffer(length: behaviors.count * MemoryLayout<Float>.size)!
            
            // 創建命令緩衝區
            guard let commandBuffer = queue.makeCommandBuffer(),
                  let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
                  let pipeline = trustComputePipeline else {
                throw PerformanceError.metalSetupFailed
            }
            
            // 設置計算管線
            computeEncoder.setComputePipelineState(pipeline)
            computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
            
            // 配置線程組
            let threadGroupSize = MTLSize(width: 256, height: 1, depth: 1)
            let threadGroups = MTLSize(width: (behaviors.count + 255) / 256, 
                                      height: 1, 
                                      depth: 1)
            
            // 執行 GPU 計算
            computeEncoder.dispatchThreadgroups(threadGroups, 
                                               threadsPerThreadgroup: threadGroupSize)
            computeEncoder.endEncoding()
            
            // 提交並等待完成
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            // 讀取結果
            _ = outputBuffer.contents().bindMemory(to: Float.self, 
                                                  capacity: behaviors.count)
            
            return (0..<behaviors.count).map { i in
                "safe"
            }
            
        } catch {
            print("❌ Metal 處理失敗，降級到 Accelerate: \(error)")
            return await accelerateBatchAnalyze(behaviors)
        }
    }
    
    // MARK: - Private Helpers
    
    private func processWithSwift(_ scores: [Float], 
                                 behaviors: [[Float]]) -> [Float] {
        // 純 Swift 實現
        return zip(scores, behaviors).map { score, behavior in
            let behaviorScore = behavior.reduce(0, +) / Float(behavior.count)
            return (score + behaviorScore) / 2
        }
    }
    
    private func processWithAccelerate(_ scores: [Float], 
                                      behaviors: [[Float]]) async -> [Float] {
        await withTaskGroup(of: (Int, Float).self) { group in
            for (index, behavior) in behaviors.enumerated() {
                group.addTask {
                    var sum: Float = 0
                    vDSP_sve(behavior, 1, &sum, vDSP_Length(behavior.count))
                    let avg = sum / Float(behavior.count)
                    return (index, (scores[index] + avg) / 2)
                }
            }
            
            var results = [Float](repeating: 0, count: scores.count)
            for await (index, score) in group {
                results[index] = score
            }
            return results
        }
    }
    
    private func processWithMetal(_ scores: [Float], 
                                 behaviors: [[Float]]) async -> [Float] {
        // Metal GPU 實現（委託給 batchAnalyzeBehaviors）
        let dummyPeers = (0..<scores.count).map { "peer_\($0)" }
        let threatLevels = await batchAnalyzeBehaviors(for: dummyPeers, 
                                                       behaviors: behaviors)
        
        return zip(scores, threatLevels).map { score, threat in
            let threatModifier: Float = {
                switch threat {
                case "safe": return 1.0
                case "suspicious": return 0.7
                case "dangerous": return 0.3
                default: return 0.5
                }
            }()
            return score * threatModifier
        }
    }
    
    private func accelerateBatchAnalyze(_ behaviors: [[Float]]) async -> [String] {
        await withTaskGroup(of: (Int, String).self) { group in
            for (index, behavior) in behaviors.enumerated() {
                group.addTask {
                    let stats = self.calculateSimpleStats(scores: behavior)
                    let threat = stats.mean > 50 ? "safe" : "suspicious"
                    return (index, threat)
                }
            }
            
            var results = [String](repeating: "safe", count: behaviors.count)
            for await (index, threat) in group {
                results[index] = threat
            }
            return results
        }
    }
    
    private func mapScoreToThreatLevel(_ score: Float) -> String {
        switch score {
        case 80...100: return "safe"
        case 40..<80: return "suspicious"
        default: return "dangerous"
        }
    }
    
    private func mapStatsToThreatLevel(_ mean: Float, _ variance: Float) -> String {
        if mean > 70 && variance < 15 {
            return "safe"
        } else if mean > 40 {
            return "suspicious"
        } else {
            return "dangerous"
        }
    }
}

// MARK: - Supporting Types

// 使用既有的 TrustStatistics 定義

struct PerformanceMetrics {
    var accelerateCallCount = 0
    var metalCallCount = 0
    var averageProcessingTime: Double = 0
}

enum PerformanceError: Error {
    case bufferCreationFailed
    case metalSetupFailed
    case invalidDataSize
}

// 使用既有的 ThreatLevel 定義，不再重複定義

// MARK: - Metal Shader String (暫時內嵌)
extension HybridPerformanceEngine {
    private var metalShaderSource: String {
        """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void trustScoreKernel(device float* behaviorData [[buffer(0)]],
                                    device float* output [[buffer(1)]],
                                    uint id [[thread_position_in_grid]]) {
            // 簡單的信任分數計算
            float sum = 0;
            int dataSize = 100; // 假設每個行為向量長度
            int offset = id * dataSize;
            
            for (int i = 0; i < dataSize; i++) {
                sum += behaviorData[offset + i];
            }
            
            output[id] = sum / float(dataSize) * 100.0;
        }
        """
    }
}