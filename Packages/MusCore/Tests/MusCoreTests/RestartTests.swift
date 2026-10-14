import XCTest
@testable import MusCore

final class RestartTests: XCTestCase {
    private struct MemoryStore: AppDataStore {
        func load() throws -> AppData { .empty }
        func save(_ data: AppData) throws {}
        func deleteAll() throws {}
    }

    func testRestartKeepsTeamsAndRulesButClearsScoreAndActions() throws {
        let repo = try GameRepository(store: MemoryStore())
        var game = try repo.startGame(teamNames: PerTeam("A", "B"), rules: GameRules(goal: 30, vacasToWin: 2))
        try game.addScore(7, lance: .grande, to: .first)
        try repo.update(game)

        let fresh = try repo.restartActiveGame()
        XCTAssertNotEqual(fresh.id, game.id)
        XCTAssertEqual(fresh.teamNames, PerTeam("A", "B"))
        XCTAssertEqual(fresh.rules, GameRules(goal: 30, vacasToWin: 2))
        XCTAssertTrue(fresh.actions.isEmpty)
        XCTAssertEqual(repo.activeGame?.id, fresh.id)
        XCTAssertTrue(repo.history.isEmpty, "reiniciar descarta la partida; no la archiva")
    }

    func testRestartWithoutActiveGameFails() throws {
        let repo = try GameRepository(store: MemoryStore())
        XCTAssertThrowsError(try repo.restartActiveGame())
    }

    func testDiscardActiveGameLeavesNoTrace() throws {
        let repo = try GameRepository(store: MemoryStore())
        _ = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard)
        try repo.discardActiveGame()
        XCTAssertNil(repo.activeGame)
        XCTAssertTrue(repo.history.isEmpty)
    }

    func testUndoCannotGoBeyondTheStartOfTheGame() throws {
        var game = try Game()
        try game.addScore(2, lance: .grande, to: .first)
        try game.undo()
        XCTAssertFalse(game.canUndo)
        XCTAssertThrowsError(try game.undo()) { XCTAssertEqual($0 as? ScoringError, .nothingToUndo) }
        XCTAssertEqual(game.state.score, PerTeam(0, 0))
    }

    func testUndoRevertsExactlyTheLastActionOnly() throws {
        var game = try Game()
        try game.addScore(2, lance: .grande, to: .first)
        try game.addScore(3, lance: .chica, to: .second)
        let undone = try game.undo()
        XCTAssertEqual(undone.team, .second)
        XCTAssertEqual(undone.amount, 3)
        XCTAssertEqual(game.state.score, PerTeam(2, 0))
        XCTAssertEqual(game.actions.count, 1)
    }
}
