import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class HistoryAndPreferencesTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL { directory.appendingPathComponent("appdata.json") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("history-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel() throws -> AppModel {
        AppModel(repository: try GameRepository(store: FileAppDataStore(fileURL: fileURL)))
    }

    /// Termina una partida ganando el equipo 1 de un solo golpe (órdago).
    private func finishGame(_ model: AppModel, names: (String, String) = ("A", "B")) {
        model.startGame(with: GameSetupDraft(firstName: names.0, secondName: names.1))
        model.declareOrdago(winner: .first)
    }

    // MARK: - Historial

    func testFinishedAndAbandonedGamesAppearInHistory() throws {
        let model = try makeModel()
        finishGame(model)
        model.goHome()
        model.startGame(with: .standard)
        model.abandonGame()
        XCTAssertEqual(model.history.count, 2)
        let statuses = model.history.map(\.status)
        XCTAssertTrue(statuses.contains(.finished(winner: .first, reason: .ordago)))
        XCTAssertTrue(statuses.contains(.abandoned))
    }

    func testDeletingOneGameKeepsTheOthers() throws {
        let model = try makeModel()
        finishGame(model, names: ("A", "B"))
        model.goHome()
        finishGame(model, names: ("C", "D"))
        model.goHome()
        let target = try XCTUnwrap(model.history.first { $0.teamNames.first == "A" })
        model.deleteHistoryGame(target.id)
        XCTAssertEqual(model.history.map(\.teamNames.first), ["C"])
        XCTAssertEqual(try makeModel().history.count, 1)
    }

    func testDeletingAllHistoryKeepsTheGameInProgress() throws {
        let model = try makeModel()
        finishGame(model)
        model.goHome()
        model.startGame(with: .standard)
        model.deleteHistory()
        XCTAssertTrue(model.history.isEmpty)
        XCTAssertTrue(model.hasGameInProgress)
        XCTAssertTrue(try makeModel().history.isEmpty)
    }

    func testGameInProgressIsStillPendingAfterReopeningTheApp() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        model.score(3, to: .second)

        let reopened = try makeModel()
        XCTAssertTrue(reopened.hasGameInProgress)
        XCTAssertEqual(reopened.game?.state.score, PerTeam(0, 3))
        XCTAssertTrue(reopened.history.isEmpty)
        reopened.resumeGame()
        XCTAssertEqual(reopened.screen, .game)
    }

    func testHistoryAndSettingsScreensOpenAndCloseWithoutSideEffects() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        model.leaveGame()
        model.openHistory()
        XCTAssertEqual(model.screen, .history)
        model.backToHome()
        model.openSettings()
        XCTAssertEqual(model.screen, .settings)
        model.backToHome()
        XCTAssertEqual(model.screen, .home)
        XCTAssertTrue(model.hasGameInProgress)
    }

    // MARK: - Preferencias

    func testPreferencesPersistBetweenSessions() throws {
        let model = try makeModel()
        model.updatePreferences { $0.goal = 30; $0.theme = .dark }
        let reopened = try makeModel()
        XCTAssertEqual(reopened.preferences, Preferences(goal: 30, vacasToWin: 1, theme: .dark))
    }

    func testPreferencesApplyToNewGamesAndNotToExistingOnes() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        model.updatePreferences { $0.goal = 30; $0.vacasToWin = 2 }
        XCTAssertEqual(model.game?.rules, .standard)

        model.leaveGame()
        model.openSetup()
        XCTAssertEqual(model.draft.rules, GameRules(goal: 30, vacasToWin: 2))
        model.startGame(with: model.draft)
        XCTAssertEqual(model.game?.rules, GameRules(goal: 30, vacasToWin: 2))
        XCTAssertEqual(model.history.first?.rules, .standard)
    }

    func testChangingPreferencesDoesNotAlterSavedHistory() throws {
        let model = try makeModel()
        finishGame(model)
        model.goHome()
        let before = model.history
        model.updatePreferences { $0.goal = 30; $0.vacasToWin = 3 }
        let after = try makeModel().history
        // Las fechas se guardan sin fracciones de segundo, así que se comparan los campos que importan.
        XCTAssertEqual(after.map(\.id), before.map(\.id))
        XCTAssertEqual(after.map(\.rules), before.map(\.rules))
        XCTAssertEqual(after.map(\.status), before.map(\.status))
        XCTAssertEqual(after.map(\.state), before.map(\.state))
    }

    func testInvalidPreferenceShowsErrorAndChangesNothing() throws {
        let model = try makeModel()
        model.updatePreferences { $0.goal = 35 }
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.preferences, .standard)
    }

    func testThemePreferenceMapsToColorScheme() {
        XCTAssertNil(ThemePreference.system.colorScheme)
        XCTAssertEqual(ThemePreference.light.colorScheme, .light)
        XCTAssertEqual(ThemePreference.dark.colorScheme, .dark)
    }

    // MARK: - Textos del historial

    func testHistoryTextDescribesEachOutcome() throws {
        let model = try makeModel()
        finishGame(model)
        let finished = try XCTUnwrap(model.history.first)
        XCTAssertEqual(HistoryText.score(finished), "A 40 – 0 B")
        XCTAssertEqual(HistoryText.result(finished), "Ganó A · Órdago")
        XCTAssertEqual(HistoryText.rules(finished), "A 40 tantos · sin vacas")

        model.goHome()
        model.startGame(with: GameSetupDraft(goal: 30, vacasToWin: 2))
        model.abandonGame()
        let abandoned = try XCTUnwrap(model.history.first { $0.status == .abandoned })
        XCTAssertEqual(HistoryText.result(abandoned), "Abandonada")
        XCTAssertEqual(HistoryText.score(abandoned), "Nosotros 0 – 0 Ellos")
        XCTAssertEqual(HistoryText.scoreUnit(abandoned), "vacas")
        XCTAssertEqual(HistoryText.rules(abandoned), "A 30 tantos · 2 de 3")
    }

    func testHistoryDateIsSpanishAndStable() {
        let date = Date(timeIntervalSince1970: 1_700_000_000) // 14 nov 2023, 22:13 UTC
        let text = HistoryText.date(date, locale: Locale(identifier: "es"), timeZone: TimeZone(identifier: "UTC")!)
        XCTAssertTrue(text.contains("nov"), text)
        XCTAssertTrue(text.contains("2023"), text)
        XCTAssertTrue(text.contains("22:13"), text)
    }
}
