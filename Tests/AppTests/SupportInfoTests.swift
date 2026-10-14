import XCTest
@testable import MUSCounter

final class SupportInfoTests: XCTestCase {
    func testOnlyHttpsUrlsWithHostAreAccepted() {
        XCTAssertNotNil(SupportInfo.url(from: "https://ejemplo.es/privacidad"))
        XCTAssertNil(SupportInfo.url(from: "http://ejemplo.es/privacidad"))
        XCTAssertNil(SupportInfo.url(from: "https://localhost"))
        XCTAssertNil(SupportInfo.url(from: ""))
        XCTAssertNil(SupportInfo.url(from: nil))
    }

    func testMissingConfigurationHidesLinks() {
        let info = SupportInfo(bundle: Bundle(for: SupportInfoTests.self))
        XCTAssertNil(info.policyURL)
        XCTAssertNil(info.supportURL)
    }

    func testAppBundleCarriesPublicPrivacyAndSupportPages() throws {
        let info = SupportInfo(bundle: .main)
        XCTAssertEqual(info.policyURL?.host(), "cosmichomeless.github.io")
        XCTAssertEqual(info.policyURL?.path(), "/MUSCounter/privacy/")
        XCTAssertEqual(info.supportURL?.path(), "/MUSCounter/support/")
    }
}
