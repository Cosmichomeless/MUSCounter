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

    func testEmailValidation() {
        XCTAssertEqual(SupportInfo.email(from: " soporte@ejemplo.es "), "soporte@ejemplo.es")
        XCTAssertNil(SupportInfo.email(from: "soporte"))
        XCTAssertNil(SupportInfo.email(from: ""))
    }

    func testMissingConfigurationHidesLinks() {
        let info = SupportInfo(bundle: Bundle(for: SupportInfoTests.self))
        XCTAssertNil(info.policyURL)
        XCTAssertNil(info.supportMailURL)
    }

    func testMailURLIncludesSubject() throws {
        let info = SupportInfo(policyURL: nil, supportEmail: "soporte@ejemplo.es")
        let url = try XCTUnwrap(info.supportMailURL)
        XCTAssertTrue(url.absoluteString.hasPrefix("mailto:soporte@ejemplo.es"))
        XCTAssertTrue(url.absoluteString.contains("subject="))
    }
}
