import XCTest
@testable import MusCore

final class PreferencesTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL { directory.appendingPathComponent("appdata.json") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("prefs-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func repository() throws -> GameRepository {
        try GameRepository(store: FileAppDataStore(fileURL: fileURL))
    }

    private func date(_ seconds: TimeInterval) -> Date { Date(timeIntervalSince1970: 1_700_000_000 + seconds) }

    func testDefaultsMatchStandardRulesAndSystemTheme() {
        let preferences = Preferences.standard
        XCTAssertEqual(preferences.rules, .standard)
        XCTAssertEqual(preferences.theme, .system)
        XCTAssertTrue(preferences.isValid)
    }

    func testPreferencesAreRememberedBetweenSessions() throws {
        let repo = try repository()
        try repo.updatePreferences(Preferences(goal: 30, vacasToWin: 2, theme: .dark))
        let reopened = try repository()
        XCTAssertEqual(reopened.preferences, Preferences(goal: 30, vacasToWin: 2, theme: .dark))
    }

    func testInvalidPreferencesAreRejectedAndNothingChanges() throws {
        let repo = try repository()
        XCTAssertThrowsError(try repo.updatePreferences(Preferences(goal: 35))) {
            XCTAssertEqual($0 as? ScoringError, .invalidRules)
        }
        XCTAssertThrowsError(try repo.updatePreferences(Preferences(vacasToWin: 4)))
        XCTAssertEqual(repo.preferences, .standard)
    }

    func testChangingPreferencesDoesNotAlterSavedGames() throws {
        let repo = try repository()
        var done = try repo.startGame(teamNames: PerTeam("A", "B"), rules: GameRules(goal: 40, vacasToWin: 1), now: date(0))
        try done.addScore(40, lance: .grande, to: .first, at: date(1))
        try repo.update(done)
        let active = try repo.startGame(teamNames: PerTeam("C", "D"), rules: GameRules(goal: 40, vacasToWin: 1), now: date(10))

        try repo.updatePreferences(Preferences(goal: 30, vacasToWin: 3, theme: .light))

        let reopened = try repository()
        XCTAssertEqual(reopened.history, [done])
        XCTAssertEqual(reopened.activeGame, active)
        XCTAssertEqual(reopened.activeGame?.rules, GameRules(goal: 40, vacasToWin: 1))
    }

    func testPreferencesSurviveGameChanges() throws {
        let repo = try repository()
        try repo.updatePreferences(Preferences(goal: 30, theme: .light))
        var game = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try game.addScore(1, lance: .grande, to: .first, at: date(1))
        try repo.update(game)
        try repo.deleteHistory()
        XCTAssertEqual(try repository().preferences, Preferences(goal: 30, theme: .light))
    }

    func testDeleteAllDataAlsoResetsPreferences() throws {
        let repo = try repository()
        try repo.updatePreferences(Preferences(theme: .dark))
        try repo.deleteAllData()
        XCTAssertEqual(repo.preferences, .standard)
        XCTAssertEqual(try repository().preferences, .standard)
    }

    func testVersionOneFileMigratesWithDefaultPreferencesAndKeepsGames() throws {
        let game = try Game(teamNames: PerTeam("A", "B"), rules: .standard, createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        // Fichero tal y como lo escribía la versión 1 (sin `preferences`).
        let current = AppData(activeGame: game, history: [], preferences: .standard)
        let encoded = try FileAppDataStore.makeEncoder().encode(current)
        var document = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        document["schemaVersion"] = 1
        document.removeValue(forKey: "preferences")
        try JSONSerialization.data(withJSONObject: document).write(to: fileURL)

        let loaded = try FileAppDataStore(fileURL: fileURL).load()
        XCTAssertEqual(loaded.schemaVersion, AppData.currentSchemaVersion)
        XCTAssertEqual(loaded.preferences, .standard)
        XCTAssertEqual(loaded.activeGame, game)
    }

    func testDraftFromPreferencesUsesTheirRulesAndDefaultNames() {
        let draft = GameSetupDraft(preferences: Preferences(goal: 30, vacasToWin: 2, theme: .dark))
        XCTAssertEqual(draft.rules, GameRules(goal: 30, vacasToWin: 2))
        XCTAssertEqual(draft.teamNames, PerTeam("Nosotros", "Ellos"))
    }
}
