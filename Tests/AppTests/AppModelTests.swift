import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class AppModelTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("appmodel-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel() throws -> AppModel {
        let store = FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
        return AppModel(repository: try GameRepository(store: store))
    }

    func testQuickStartUsesDefaultsAndOpensScoreboard() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        XCTAssertEqual(model.screen, .game)
        XCTAssertEqual(model.game?.teamNames, PerTeam("Nosotros", "Ellos"))
        XCTAssertEqual(model.game?.rules, .standard)
    }

    func testCancelingSetupCreatesNoGame() throws {
        let model = try makeModel()
        model.openSetup()
        model.draft.firstName = "Otros"
        model.cancelSetup()
        XCTAssertEqual(model.screen, .home)
        XCTAssertNil(model.game)
        XCTAssertFalse(model.hasGameInProgress)
    }

    func testSetupOptionsReachTheGame() throws {
        let model = try makeModel()
        model.openSetup()
        model.draft.firstName = "Los Ases"
        model.draft.goal = 30
        model.draft.vacasToWin = 2
        model.startGame(with: model.draft)
        XCTAssertEqual(model.game?.teamNames.first, "Los Ases")
        XCTAssertEqual(model.game?.rules, GameRules(goal: 30, vacasToWin: 2))
    }

    func testGameInProgressCanBeResumedAfterLeaving() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        model.leaveGame()
        XCTAssertEqual(model.screen, .home)
        XCTAssertTrue(model.hasGameInProgress)
        model.resumeGame()
        XCTAssertEqual(model.screen, .game)
    }

    func testSetupStartsFromPreferencesNotFromLastGame() throws {
        let model = try makeModel()
        model.updatePreferences { $0.goal = 30; $0.vacasToWin = 2 }
        model.startGame(with: GameSetupDraft(firstName: "A", secondName: "B", goal: 40, vacasToWin: 3))
        model.leaveGame()
        model.openSetup()
        XCTAssertEqual(model.draft, GameSetupDraft(goal: 30, vacasToWin: 2))
    }

    func testInvalidDraftShowsErrorAndStaysPut() throws {
        let model = try makeModel()
        model.openSetup()
        var bad = GameSetupDraft.standard
        bad.goal = 35
        model.startGame(with: bad)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.screen, .setup)
        XCTAssertNil(model.game)
    }
}
