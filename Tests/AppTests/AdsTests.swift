import XCTest
import MusAds
import MusCore
@testable import MUSCounter

@MainActor
final class AdsTests: XCTestCase {
    func testAdsAreNeverPlacedOnScoreboardSetupOrSettings() {
        XCTAssertNil(AdPlacement(screen: .game))
        XCTAssertNil(AdPlacement(screen: .setup))
        XCTAssertNil(AdPlacement(screen: .settings))
    }

    func testAdsAreAllowedOnHomeHistoryAndResultOnly() {
        XCTAssertEqual(AdPlacement(screen: .home), .home)
        XCTAssertEqual(AdPlacement(screen: .history), .history)
        XCTAssertEqual(AdPlacement(screen: .result), .result)
        XCTAssertEqual(AdPlacement.allCases.count, 3)
    }

    func testLiveControllerIsDisabledUnderTests() {
        let controller = AdsController.live()
        XCTAssertFalse(controller.isEnabled)
        XCTAssertFalse(controller.canShowAds)
    }

    func testLaunchArgumentDisablesAds() {
        let controller = AdsController.live(environment: [:], arguments: ["-MusAdsDisabled"])
        XCTAssertFalse(controller.isEnabled)
    }

    func testMissingConfigurationDisablesAds() {
        let controller = AdsController.live(environment: [:], arguments: [], bundle: Bundle(for: AdsTests.self))
        XCTAssertFalse(controller.isEnabled, "Sin identificadores en el Info.plist no hay anuncios")
    }

    func testDisabledControllerStartsWithoutShowingAds() async {
        let controller = AdsController.disabled()
        await controller.start()
        XCTAssertFalse(controller.canShowAds)
        XCTAssertFalse(controller.privacyOptionsRequired)
    }

    func testInvalidIdentifiersAreRejected() {
        XCTAssertNil(AdsConfiguration(bundle: Bundle(for: AdsTests.self)))
    }

    func testGoogleTestIdentifiersAreDetected() {
        let test = AdsConfiguration(appID: AdsConfiguration.googleTestAppID, bannerUnitID: AdsConfiguration.googleTestBannerUnitID)
        XCTAssertTrue(test.usesGoogleTestIdentifiers)
        let real = AdsConfiguration(appID: "ca-app-pub-1111111111111111~2222222222", bannerUnitID: "ca-app-pub-1111111111111111/3333333333")
        XCTAssertFalse(real.usesGoogleTestIdentifiers)
    }

    /// El marcador funciona igual con el módulo de anuncios desactivado (siempre lo está en las pruebas).
    func testScoreboardWorksWithAdsDisabled() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ads-\(UUID().uuidString).json")
        let model = AppModel(repository: try GameRepository(store: FileAppDataStore(fileURL: url)))
        model.startGame(with: .standard)
        model.score(2, to: .first)
        XCTAssertEqual(model.screen, .game)
        XCTAssertEqual(model.game?.state.score, PerTeam(2, 0))
    }
}
