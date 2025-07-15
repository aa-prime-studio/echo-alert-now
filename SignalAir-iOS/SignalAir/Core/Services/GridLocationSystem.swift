import Foundation
import CoreLocation

// 引入共享類型 - 確保可以找到 CompassDirection 和 LocationData
extension CompassDirection {}
extension LocationData {}

struct GridReference {
    let x: Int
    let y: Int
    let gridSize: Double = 0.005 // 約 500 公尺
    
    var code: String {
        let letter = Character(UnicodeScalar(65 + min(x, 25))!) // A-Z
        return "\(letter)\(y)"
    }
}

// 網格位置系統 - 用於計算相對位置和方向
class GridLocationSystem {
    private static let gridSize = 0.005 // 約 500 公尺
    
    // 動態計算邊界，不限於台北市
    static func coordinateToGrid(_ coordinate: CLLocationCoordinate2D) -> String {
        // 使用基準點計算相對網格
        let baseLatitude = floor(coordinate.latitude * 100) / 100  // 取小數點後兩位
        let baseLongitude = floor(coordinate.longitude * 100) / 100
        
        let xIndex = Int((coordinate.longitude - baseLongitude) / gridSize)
        let yIndex = Int((coordinate.latitude - baseLatitude) / gridSize)
        
        // 確保在有效範圍內 (A-Z, 1-99)
        let x = max(0, min(25, xIndex))
        let y = max(1, min(99, yIndex + 1))
        
        return GridReference(x: x, y: y).code
    }
    
    static func gridToApproximateCoordinate(_ gridCode: String) -> CLLocationCoordinate2D? {
        guard let letter = gridCode.first,
              let number = Int(gridCode.dropFirst()),
              letter.isLetter else { return nil }
        
        guard let asciiValue = letter.asciiValue else { return nil }
        let x = Int(asciiValue - 65)
        let y = number - 1
        
        // 返回網格中心點（已經是模糊化的位置）
        // 這裡需要知道原始的基準點，實際使用時應該傳入
        return nil // 簡化實作，實際使用時需要完整邏輯
    }
    
    static func calculateRelativePosition(from myGrid: String, to peerGrid: String) -> (distance: Double, direction: CompassDirection?) {
        // 簡化計算：基於網格差異估算
        guard let myLetter = myGrid.first,
              let myNumber = Int(myGrid.dropFirst()),
              let peerLetter = peerGrid.first,
              let peerNumber = Int(peerGrid.dropFirst()) else {
            return (0, nil)
        }
        
        guard let peerLetterValue = peerLetter.asciiValue,
              let myLetterValue = myLetter.asciiValue else {
            return (0, nil)
        }
        let xDiff = Int(peerLetterValue) - Int(myLetterValue)
        let yDiff = peerNumber - myNumber
        
        // 估算距離（每個網格約 500 米）
        let gridDistance = sqrt(Double(xDiff * xDiff + yDiff * yDiff))
        let estimatedDistance = gridDistance * 500 // 米
        
        // 計算方向
        let angle = atan2(Double(xDiff), Double(yDiff)) * 180 / .pi
        let normalizedAngle = angle < 0 ? angle + 360 : angle
        let direction = bearingToCompassDirection(normalizedAngle)
        
        return (estimatedDistance, direction)
    }
    
    static func bearingToCompassDirection(_ bearing: Double) -> CompassDirection {
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360)
        
        switch normalizedBearing {
        case 337.5...360, 0..<22.5: return .north
        case 22.5..<67.5: return .northeast
        case 67.5..<112.5: return .east
        case 112.5..<157.5: return .southeast
        case 157.5..<202.5: return .south
        case 202.5..<247.5: return .southwest
        case 247.5..<292.5: return .west
        case 292.5..<337.5: return .northwest
        default: return .north
        }
    }
    
    // 統一的距離格式化方法
    static func formatDistance(_ meters: Double) -> String {
        switch meters {
        case 0..<50:
            return "< 50m"
        case 50..<100:
            return "約 \(Int(meters/10)*10)m"  // 50m, 60m, 70m...
        case 100..<500:
            return "約 \(Int(meters/50)*50)m"  // 100m, 150m, 200m...
        case 500..<1000:
            return "約 \(Int(meters/100)*100)m"  // 500m, 600m, 700m...
        case 1000..<5000:
            let km = meters / 1000
            return "約 \(String(format: "%.1f", km)) 公里"  // 1.2 公里, 2.5 公里...
        default:
            let km = Int(meters / 1000)
            return "約 \(km) 公里"  // 5 公里, 10 公里...
        }
    }
    
    // 兼容舊版本的方法
    static func calculateDistance(from: LocationData, to: LocationData) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    static func calculateDirection(from: LocationData, to: LocationData) -> CompassDirection {
        let deltaLat = to.latitude - from.latitude
        let deltaLng = to.longitude - from.longitude
        
        let radians = atan2(deltaLng, deltaLat)
        var degrees = radians * 180.0 / Double.pi
        
        if degrees < 0 {
            degrees += 360
        }
        
        return bearingToCompassDirection(degrees)
    }
    
    // 格式化方向顯示
    static func formatDirection(_ direction: CompassDirection) -> String {
        return direction.rawValue
    }
    
    // 計算位置的網格座標（用於附近訊號分組）
    static func getGridCoordinate(for location: LocationData, gridSize: Double = 100.0) -> (Int, Int) {
        let latGrid = Int(location.latitude * 111320 / gridSize)
        let lngGrid = Int(location.longitude * 111320 * cos(location.latitude * Double.pi / 180) / gridSize)
        return (latGrid, lngGrid)
    }
    
    // 檢查兩個位置是否在同一個網格內
    static func areInSameGrid(_ location1: LocationData, _ location2: LocationData, gridSize: Double = 100.0) -> Bool {
        let grid1 = getGridCoordinate(for: location1, gridSize: gridSize)
        let grid2 = getGridCoordinate(for: location2, gridSize: gridSize)
        return grid1.0 == grid2.0 && grid1.1 == grid2.1
    }
    
    // 取得附近網格的座標（用於擴展搜尋範圍）
    static func getNearbyGrids(for location: LocationData, radius: Int = 1, gridSize: Double = 100.0) -> [(Int, Int)] {
        let centerGrid = getGridCoordinate(for: location, gridSize: gridSize)
        var nearbyGrids: [(Int, Int)] = []
        
        for x in -radius...radius {
            for y in -radius...radius {
                nearbyGrids.append((centerGrid.0 + x, centerGrid.1 + y))
            }
        }
        
        return nearbyGrids
    }
} 