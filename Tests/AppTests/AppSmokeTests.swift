import XCTest
import MusCore

final class AppSmokeTests: XCTestCase {
    func testCoreIsLinked() {
        XCTAssertFalse(MusCoreInfo.version.isEmpty)
    }
}
