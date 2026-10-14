import XCTest
@testable import MusCore

final class MusCoreInfoTests: XCTestCase {
    func testVersionIsSemver() {
        let parts = MusCoreInfo.version.split(separator: ".")
        XCTAssertEqual(parts.count, 3)
        XCTAssertTrue(parts.allSatisfy { Int($0) != nil })
    }
}
