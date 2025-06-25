# SwiftUI 純生態系統左右對齊文字實作

## 概述

本實作提供了一個完整的 SwiftUI 原生解決方案，用於實現繁體中文文字的左右對齊（justified alignment）效果，不依賴任何 UIKit 組件。

## 核心功能

### 1. JustifiedTextLayout
- **完整的 SwiftUI Layout Protocol 實作**
- 智能文字排版與空間分配
- 高效的快取機制
- 支援動態寬度調整

### 2. SmartTextBreaker
- **智能多語言文字分解**
- 中文字符按字分解（每個字都可換行）
- 英文單詞按詞分解（保持單詞完整性）
- 混合語言智能處理
- 標點符號規則處理

### 3. 語言特性支援
- **中文（CJK）**: 4E00-9FFF, 3400-4DBF, 20000-2A6DF 等 Unicode 範圍
- **日文**: 平假名（3040-309F）、片假名（30A0-30FF）
- **韓文**: AC00-D7AF 範圍
- **英文**: 單詞邊界檢測與保護

## 使用方式

### 基本用法
```swift
JustifiedTextView(
    text: "這是需要左右對齊的繁體中文文字。",
    font: .system(size: 16),
    lineSpacing: 4,
    spacing: 1
)
```

### 進階配置
```swift
JustifiedTextLayout(spacing: 1, lineSpacing: 6) {
    ForEach(textElements, id: \.id) { element in
        Text(element.text)
            .font(.system(size: 16))
            .fixedSize(horizontal: true, vertical: false)
    }
}
```

## 技術架構

### Layout Protocol 實作
1. **sizeThatFits**: 計算所需空間並建立行佈局快取
2. **placeSubviews**: 實際放置子視圖，實現左右對齊
3. **makeCache**: 創建並管理快取資料

### 對齊算法
1. **內容寬度計算**: 測量所有文字元素的實際寬度
2. **空間分配**: 均勻分配多餘空間到字符間距
3. **最後一行處理**: 保持自然間距，不強制對齊

### 效能優化
- **快取機制**: 避免重複計算文字大小
- **惰性評估**: 只在需要時進行排版計算
- **增量更新**: 支援動態內容變更

## 整合範例

### 隱私權政策
```swift
JustifiedTextView(
    text: PrivacyPolicyContent.getContent(language: .chinese),
    font: .system(size: 15),
    lineSpacing: 4,
    spacing: 1
)
.foregroundColor(.secondary)
```

### 服務條款
```swift
JustifiedTextView(
    text: TermsOfServiceContent.getContent(language: .chinese),
    font: .system(size: 15),
    lineSpacing: 4,
    spacing: 1
)
.foregroundColor(.secondary)
```

## 限制與注意事項

### 效能考量
- **大量文字**: 建議分段處理，避免單一組件處理超過 1000 字符
- **記憶體使用**: 文字分解會產生較多的 TextElement 物件
- **渲染效能**: 複雜排版可能影響滾動流暢度

### 視覺效果
- **字符間距**: 可能會比原生文字略微分散
- **行高一致性**: 需要手動調整以符合設計需求
- **混合內容**: 中英文混合時需要額外的微調

### 使用限制
- **iOS 16+**: 需要 SwiftUI Layout Protocol 支援
- **純文字**: 不支援富文本格式（粗體、斜體等）
- **固定寬度**: 父容器需要提供明確的寬度限制

## 測試建議

### 多語言測試
```swift
let testTexts = [
    "純中文內容測試文字排版效果。",
    "Pure English content for testing layout.",
    "中英混合 Mixed content 測試效果。",
    "包含標點符號：句號。感嘆號！問號？"
]
```

### 邊界條件
- 超長單詞處理
- 單行文字效果
- 空文字處理
- 極窄容器適配

## 擴展建議

### 未來改進方向
1. **富文本支援**: 整合 AttributedString
2. **性能優化**: 虛擬化長文本渲染
3. **動畫支援**: 文字變更時的動畫效果
4. **無障礙功能**: VoiceOver 和動態字體支援

### 自定義選項
- 對齊強度調整
- 字符間距限制
- 行間距動態調整
- 語言檢測閾值配置
