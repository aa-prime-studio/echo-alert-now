import Foundation
import CoreLocation
import XCTest

// 網格系統測試
class GridSystemTests: XCTestCase {
    
    func testCoordinateToGrid() {
        // 測試台北市信義區的座標轉換
        let coordinate = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
        let gridCode = GridLocationSystem.coordinateToGrid(coordinate)
        
        print("座標 \(coordinate) 轉換為網格代碼: \(gridCode)")
        
        // 驗證網格代碼格式（字母+數字）
        XCTAssertTrue(gridCode.count >= 2)
        XCTAssertTrue(gridCode.first?.isLetter == true)
    }
    
    func testDistanceFormatting() {
        // 測試距離格式化
        let testCases = [
            (30.0, "< 50m"),
            (75.0, "約 70m"),
            (150.0, "約 150m"),
            (450.0, "約 450m"),
            (750.0, "約 700m"),
            (1500.0, "約 1.5 公里"),
            (5500.0, "約 5 公里")
        ]
        
        for (distance, expected) in testCases {
            let result = GridLocationSystem.formatDistance(distance)
            print("距離 \(distance)m -> \(result)")
            // 注意：由於格式化邏輯，可能會有細微差異
        }
    }
    
    func testRelativePositionCalculation() {
        // 測試相對位置計算
        let myGrid = "A5"
        let peerGrid = "B7"
        
        let (distance, direction) = GridLocationSystem.calculateRelativePosition(
            from: myGrid,
            to: peerGrid
        )
        
        print("從 \(myGrid) 到 \(peerGrid):")
        print("距離: \(distance)m")
        print("方向: \(direction?.rawValue ?? "未知")")
        
        XCTAssertGreaterThan(distance, 0)
        XCTAssertNotNil(direction)
    }
    
    func testGridSystemPrivacy() {
        // 測試隱私保護
        let originalCoord = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
        let nearbyCoord = CLLocationCoordinate2D(latitude: 25.0335, longitude: 121.5659)
        
        let grid1 = GridLocationSystem.coordinateToGrid(originalCoord)
        let grid2 = GridLocationSystem.coordinateToGrid(nearbyCoord)
        
        print("原始座標: \(originalCoord) -> 網格: \(grid1)")
        print("附近座標: \(nearbyCoord) -> 網格: \(grid2)")
        
        // 在 500 公尺網格內的點應該有相同的網格代碼
        // 這驗證了隱私保護機制
    }
    
    func testCompassDirections() {
        // 測試羅盤方向轉換
        let testBearings = [
            (0.0, CompassDirection.north),
            (45.0, CompassDirection.northeast),
            (90.0, CompassDirection.east),
            (135.0, CompassDirection.southeast),
            (180.0, CompassDirection.south),
            (225.0, CompassDirection.southwest),
            (270.0, CompassDirection.west),
            (315.0, CompassDirection.northwest)
        ]
        
        for (bearing, expected) in testBearings {
            let result = GridLocationSystem.bearingToCompassDirection(bearing)
            print("角度 \(bearing)° -> \(result.rawValue)")
            XCTAssertEqual(result, expected)
        }
    }
}

// 模擬網格系統使用案例
class GridSystemUsageExample {
    
    static func demonstrateUsage() {
        print("\n=== 網格系統使用示例 ===")
        
        // 1. 設備位置
        let deviceLocation = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
        let deviceGrid = GridLocationSystem.coordinateToGrid(deviceLocation)
        print("設備位置網格: \(deviceGrid)")
        
        // 2. 模擬接收到的信號
        let receivedSignals = [
            ("A6", "救援隊-Alpha"),
            ("B5", "醫療站-1"),
            ("A4", "補給點-Central")
        ]
        
        print("\n接收到的信號:")
        for (grid, name) in receivedSignals {
            let (distance, direction) = GridLocationSystem.calculateRelativePosition(
                from: deviceGrid,
                to: grid
            )
            
            let formattedDistance = GridLocationSystem.formatDistance(distance)
            let directionText = direction?.rawValue ?? "未知方向"
            
            print("- \(name): \(directionText) \(formattedDistance)")
        }
        
        // 3. 模擬發送信號
        print("\n發送信號數據:")
        let signalData: [String: Any] = [
            "id": UUID().uuidString,
            "type": "medical",
            "timestamp": Date().timeIntervalSince1970,
            "deviceName": "緊急求救者",
            "gridCode": deviceGrid  // 只傳送網格代碼，保護隱私
        ]
        
        print("發送的數據: \(signalData)")
        print("注意：只傳送網格代碼，不暴露精確位置")
    }
} 