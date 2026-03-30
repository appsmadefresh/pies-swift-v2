import XCTest
@testable import Pies

final class PiesTests: XCTestCase {
    func testDateStartOfDay() {
        let date = Date(timeIntervalSince1970: 1711756800) // 2024-03-30 00:00:00 UTC
        let startOfDay = date.startOfDay
        XCTAssertEqual(startOfDay, 1711756800)
    }
}
