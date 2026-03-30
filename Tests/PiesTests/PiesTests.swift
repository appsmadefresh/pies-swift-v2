import XCTest
@testable import Pies

final class PiesTests: XCTestCase {
    func testEventTypeRawValues() {
        XCTAssertEqual(EventType.newInstall.rawValue, "newInstall")
        XCTAssertEqual(EventType.sessionStart.rawValue, "sessionStart")
        XCTAssertEqual(EventType.inAppPurchase.rawValue, "inAppPurchase")
        XCTAssertEqual(EventType.deviceActiveToday.rawValue, "deviceActiveToday")
    }
}
