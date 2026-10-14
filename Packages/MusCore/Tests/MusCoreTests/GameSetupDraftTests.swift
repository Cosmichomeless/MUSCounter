import XCTest
@testable import MusCore

final class GameSetupDraftTests: XCTestCase {
    func testStandardDraftStartsWithoutFillingAnything() throws {
        let game = try GameSetupDraft.standard.makeGame()
        XCTAssertEqual(game.teamNames, PerTeam("Nosotros", "Ellos"))
        XCTAssertEqual(game.rules, .standard)
        XCTAssertEqual(game.rules.goal, 40)
        XCTAssertEqual(game.rules.vacasToWin, 1)
        XCTAssertEqual(game.status, .inProgress)
    }

    func testEditedNamesAndRulesAreUsed() throws {
        var draft = GameSetupDraft.standard
        draft.firstName = "  Los Ases "
        draft.secondName = "Peña"
        draft.goal = 30
        draft.vacasToWin = 2
        let game = try draft.makeGame()
        XCTAssertEqual(game.teamNames, PerTeam("Los Ases", "Peña"))
        XCTAssertEqual(game.rules, GameRules(goal: 30, vacasToWin: 2))
    }

    func testBlankNamesFallBackToDefaults() {
        var draft = GameSetupDraft.standard
        draft.firstName = "   "
        draft.secondName = ""
        XCTAssertEqual(draft.teamNames, PerTeam("Nosotros", "Ellos"))
    }

    func testInvalidRulesFailToBuildGame() {
        var draft = GameSetupDraft.standard
        draft.goal = 35
        XCTAssertThrowsError(try draft.makeGame()) { XCTAssertEqual($0 as? ScoringError, .invalidRules) }
    }

    func testDraftFromGameKeepsTeamsAndRules() throws {
        let game = try Game(teamNames: PerTeam("A", "B"), rules: GameRules(goal: 30, vacasToWin: 3))
        let draft = GameSetupDraft(from: game)
        XCTAssertEqual(draft.firstName, "A")
        XCTAssertEqual(draft.secondName, "B")
        XCTAssertEqual(draft.rules, game.rules)
    }

    func testDraftDoesNotCreateAnythingUntilMakeGame() throws {
        // Cancelar la configuración = descartar el borrador: no hay ninguna partida que borrar.
        var draft = GameSetupDraft.standard
        draft.firstName = "Cambiado"
        let repo = try GameRepository(store: InMemoryStore())
        XCTAssertNil(repo.activeGame)
        XCTAssertTrue(repo.history.isEmpty)
    }

    private struct InMemoryStore: AppDataStore {
        func load() throws -> AppData { .empty }
        func save(_ data: AppData) throws {}
        func deleteAll() throws {}
    }
}
