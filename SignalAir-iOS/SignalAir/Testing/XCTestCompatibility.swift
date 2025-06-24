import Foundation

// XCTest 相容性層 - 用於 macOS 建構
#if canImport(XCTest)
import XCTest
#else
// 為 macOS 建構提供基本的測試結構
class XCTestCase {
    func setUp() {}
    func tearDown() {}
}

func XCTAssertEqual<T: Equatable>(_ expression1: T, _ expression2: T, _ message: String = "") {
    if expression1 != expression2 {
        print("❌ 測試失敗: \(message)")
    } else {
        print("✅ 測試通過: \(message)")
    }
}

func XCTAssertTrue(_ expression: Bool, _ message: String = "") {
    if !expression {
        print("❌ 測試失敗: \(message)")
    } else {
        print("✅ 測試通過: \(message)")
    }
}

func XCTAssertFalse(_ expression: Bool, _ message: String = "") {
    if expression {
        print("❌ 測試失敗: \(message)")
    } else {
        print("✅ 測試通過: \(message)")
    }
}
#endif 