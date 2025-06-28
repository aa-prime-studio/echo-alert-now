# 網格系統實現說明

## 📍 已實現功能

### 1. 網格位置系統 (`GridLocationSystem.swift`)

#### 核心功能：
- **`coordinateToGrid()`**: 將 GPS 座標轉換為網格代碼（如 "A5", "B12"）
- **`calculateRelativePosition()`**: 基於網格差異計算相對距離和方向
- **`formatDistance()`**: 統一的模糊距離顯示格式
- **`bearingToCompassDirection()`**: 8 方向羅盤轉換

#### 隱私保護特點：
- 🔒 **網格化保護**: 500 公尺網格，隱藏精確位置
- 🌐 **動態邊界**: 不限於特定城市，全球通用
- 📱 **設備友好**: A-Z (26 個) × 1-99 網格編碼

### 2. SignalViewModel 優化

#### 整合改進：
- ✅ **LocationManager 整合**: 統一位置服務管理
- ✅ **網格代碼傳輸**: 只傳送網格代碼，不暴露精確座標
- ✅ **相對位置計算**: 使用網格系統計算距離和方向
- ✅ **統一距離格式**: 刪除重複方法，使用 `GridLocationSystem.formatDistance()`

#### 刪除的重複方法：
- ❌ `calculateBearing()` 
- ❌ `angleToCompassDirection()`
- ❌ `fuzzyDistanceDescription()`

### 3. UI 顯示優化

#### MessageRowView 改進：
```swift
// 新的佈局
Text("・\(getDirectionText(direction)) \(GridLocationSystem.formatDistance(distance))")
    .font(.caption)
    .foregroundColor(.secondary)

// 右側方位指示器
Image(systemName: "navigation.fill")
    .font(.title3)
    .foregroundColor(backgroundColorForType(message.type))
    .rotationEffect(.degrees(direction.angle))
```

### 4. 資料結構更新

#### SignalMessage 擴展：
```swift
struct SignalMessage {
    // ... 現有屬性
    let gridCode: String?  // 新增網格代碼
}
```

#### 信號傳輸格式：
```swift
let signalData = [
    "id": UUID().uuidString,
    "type": type.rawValue,
    "timestamp": Date().timeIntervalSince1970,
    "deviceName": deviceName,
    "gridCode": GridLocationSystem.coordinateToGrid(location.coordinate)  // 只傳網格代碼
]
```

## 🔧 距離格式化邏輯

```swift
switch meters {
case 0..<50: return "< 50m"
case 50..<100: return "約 \(Int(meters/10)*10)m"      // 50m, 60m, 70m
case 100..<500: return "約 \(Int(meters/50)*50)m"     // 100m, 150m, 200m
case 500..<1000: return "約 \(Int(meters/100)*100)m"  // 500m, 600m, 700m
case 1000..<5000: return "約 \(km) 公里"              // 1.2 公里, 2.5 公里
default: return "約 \(Int(km)) 公里"                  // 5 公里, 10 公里
}
```

## 🧭 8 方向羅盤系統

| 角度範圍 | 方向 | 顯示 |
|---------|------|------|
| 337.5° - 22.5° | North | 北 |
| 22.5° - 67.5° | Northeast | 東北 |
| 67.5° - 112.5° | East | 東 |
| 112.5° - 157.5° | Southeast | 東南 |
| 157.5° - 202.5° | South | 南 |
| 202.5° - 247.5% | Southwest | 西南 |
| 247.5° - 292.5° | West | 西 |
| 292.5° - 337.5° | Northwest | 西北 |

## 🔐 隱私保護機制

1. **網格量化**: GPS 座標 → 500m 網格代碼
2. **模糊距離**: 具體但不精確的距離範圍
3. **相對計算**: 基於網格中心點，不暴露真實位置
4. **動態基準**: 基於當前位置動態計算基準點

## ✅ 測試驗證

使用 `GridSystemTests.swift` 進行：
- 座標轉網格代碼測試
- 距離格式化測試  
- 相對位置計算測試
- 隱私保護驗證
- 羅盤方向轉換測試

## 🎯 使用示例

```swift
// 1. 生成網格代碼
let coordinate = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
let gridCode = GridLocationSystem.coordinateToGrid(coordinate)  // "A5"

// 2. 計算相對位置
let (distance, direction) = GridLocationSystem.calculateRelativePosition(
    from: "A5", 
    to: "B7"
)

// 3. 格式化顯示
let formattedDistance = GridLocationSystem.formatDistance(distance)  // "約 750m"
let directionText = direction?.rawValue  // "東北"
```

## 🚀 效果總結

### 隱私保護
- ✅ 只交換網格代碼，不交換精確座標
- ✅ 距離基於網格中心點計算
- ✅ UI 顯示模糊化距離

### 性能優化  
- ✅ 位置更新有閾值控制
- ✅ 統一計算邏輯，減少重複
- ✅ 固定測試場景便於調試

### 用戶體驗
- ✅ 顯示具體但模糊的距離數字（約 450m）
- ✅ 8 方向羅盤提供清晰指引
- ✅ 錯誤處理和權限提示

這個實現創建了一個既保護隱私又實用的緊急通訊系統，符合您的所有要求。 