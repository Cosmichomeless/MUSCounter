import XCTest
@testable import MusCore

/// Casos de referencia R-01…R-20 de docs/reglas-de-tanteo.md.
final class GameRulesTests: XCTestCase {
    private func game(goal: Int = 40, vacas: Int = 1) throws -> Game {
        try Game(rules: GameRules(goal: goal, vacasToWin: vacas))
    }

    func testR01NewGame() throws {
        let g = try game()
        XCTAssertEqual(g.state.score, PerTeam(0, 0))
        XCTAssertEqual(g.state.vacas, PerTeam(0, 0))
        XCTAssertEqual(g.status, .inProgress)
    }

    func testR02ScoreToTeam() throws {
        var g = try game()
        try g.addScore(2, lance: .grande, to: .first)
        XCTAssertEqual(g.state.score, PerTeam(2, 0))
    }

    func testR03BothTeamsScoreIndependently() throws {
        var g = try game()
        try g.addScore(2, lance: .grande, to: .first)
        try g.addScore(1, lance: .chica, to: .second)
        try g.addScore(3, lance: .pares, to: .first)
        try g.addScore(2, lance: .juego, to: .second)
        XCTAssertEqual(g.state.score, PerTeam(5, 3))
    }

    func testR04ZeroAmountRejected() throws {
        var g = try game()
        XCTAssertThrowsError(try g.addScore(0, lance: .grande, to: .first)) {
            XCTAssertEqual($0 as? ScoringError, .invalidAmount)
        }
        XCTAssertThrowsError(try g.addScore(-1, lance: .grande, to: .first))
        XCTAssertThrowsError(try g.addScore(41, lance: .grande, to: .first))
        XCTAssertTrue(g.actions.isEmpty)
    }

    func testR05OneShortOfTarget() throws {
        var g = try game()
        try g.addScore(38, lance: .grande, to: .first)
        try g.addScore(1, lance: .chica, to: .first)
        XCTAssertEqual(g.state.score.first, 39)
        XCTAssertEqual(g.status, .inProgress)
    }

    func testR06ReachingTargetWinsAndCapsScore() throws {
        var g = try game()
        try g.addScore(38, lance: .grande, to: .first)
        try g.addScore(3, lance: .pares, to: .first)
        XCTAssertEqual(g.state.score.first, 40)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .targetReached))
        XCTAssertNotNil(g.endedAt)
    }

    func testR07NoActionsAfterFinish() throws {
        var g = try game()
        try g.addScore(40, lance: .grande, to: .first)
        XCTAssertThrowsError(try g.addScore(1, lance: .chica, to: .second)) {
            XCTAssertEqual($0 as? ScoringError, .notInProgress)
        }
        XCTAssertThrowsError(try g.declareOrdago(winner: .second))
        XCTAssertEqual(g.actions.count, 1)
    }

    func testR08GoalThirty() throws {
        var g = try game(goal: 30)
        try g.addScore(29, lance: .grande, to: .first)
        XCTAssertEqual(g.status, .inProgress)
        try g.addScore(1, lance: .punto, to: .first)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .targetReached))
    }

    func testR09OrdagoWinsVaca() throws {
        var g = try game()
        try g.addScore(10, lance: .grande, to: .first)
        try g.addScore(25, lance: .chica, to: .second)
        try g.declareOrdago(winner: .first)
        XCTAssertEqual(g.state.score.first, 40)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .ordago))
    }

    func testR10UndoOrdagoRestoresScore() throws {
        var g = try game()
        try g.addScore(10, lance: .grande, to: .first)
        try g.addScore(25, lance: .chica, to: .second)
        try g.declareOrdago(winner: .first)
        let undone = try g.undo()
        XCTAssertEqual(undone.kind, .ordago)
        XCTAssertEqual(g.state.score, PerTeam(10, 25))
        XCTAssertEqual(g.status, .inProgress)
        XCTAssertNil(g.endedAt)
    }

    func testR11UndoWithoutActionsRejected() throws {
        var g = try game()
        XCTAssertThrowsError(try g.undo()) { XCTAssertEqual($0 as? ScoringError, .nothingToUndo) }
        XCTAssertFalse(g.canUndo)
    }

    func testR12AdjustCannotGoBelowZero() throws {
        var g = try game()
        XCTAssertThrowsError(try g.adjust(team: .first, by: -1)) {
            XCTAssertEqual($0 as? ScoringError, .belowZero)
        }
        XCTAssertThrowsError(try g.adjust(team: .first, by: 0))
        XCTAssertEqual(g.state.score.first, 0)
    }

    func testR13AdjustReachingTargetWins() throws {
        var g = try game()
        try g.addScore(39, lance: .grande, to: .first)
        try g.adjust(team: .first, by: 1)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .targetReached))
    }

    func testAdjustDownWorks() throws {
        var g = try game()
        try g.addScore(5, lance: .grande, to: .second)
        try g.adjust(team: .second, by: -1)
        XCTAssertEqual(g.state.score.second, 4)
    }

    func testR14FirstVacaOfSeveral() throws {
        var g = try game(vacas: 2)
        try g.addScore(40, lance: .grande, to: .first)
        XCTAssertEqual(g.state.score, PerTeam(0, 0))
        XCTAssertEqual(g.state.vacas, PerTeam(1, 0))
        XCTAssertEqual(g.status, .inProgress)
        XCTAssertEqual(g.state.completedVacas.count, 1)
        XCTAssertEqual(g.state.completedVacas[0].winner, .first)
    }

    func testR15WinningAllVacasWinsGame() throws {
        var g = try game(vacas: 2)
        try g.addScore(40, lance: .grande, to: .first)
        try g.addScore(40, lance: .grande, to: .first)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .targetReached))
        XCTAssertEqual(g.state.vacas, PerTeam(2, 0))
    }

    func testR16BestOfThree() throws {
        var g = try game(vacas: 2)
        try g.addScore(40, lance: .grande, to: .first)
        try g.addScore(40, lance: .grande, to: .second)
        XCTAssertEqual(g.status, .inProgress)
        try g.addScore(40, lance: .grande, to: .first)
        XCTAssertEqual(g.status, .finished(winner: .first, reason: .targetReached))
        XCTAssertEqual(g.state.vacas, PerTeam(2, 1))
    }

    func testR17UndoClosingActionOfFirstVaca() throws {
        var g = try game(vacas: 2)
        try g.addScore(30, lance: .grande, to: .first)
        try g.addScore(10, lance: .pares, to: .first)
        XCTAssertEqual(g.state.vacas.first, 1)
        try g.undo()
        XCTAssertEqual(g.state.score, PerTeam(30, 0))
        XCTAssertEqual(g.state.vacas, PerTeam(0, 0))
        XCTAssertTrue(g.state.completedVacas.isEmpty)
    }

    func testR18AbandonGame() throws {
        var g = try game()
        try g.addScore(3, lance: .grande, to: .first)
        try g.abandon()
        XCTAssertEqual(g.status, .abandoned)
        XCTAssertNotNil(g.endedAt)
        XCTAssertNil(g.state.winner)
        XCTAssertThrowsError(try g.addScore(1, lance: .chica, to: .first))
        XCTAssertThrowsError(try g.undo())
        XCTAssertThrowsError(try g.abandon())
    }

    func testR19ActionLogKeepsOrderTeamLanceAndAmount() throws {
        var g = try game()
        try g.addScore(2, lance: .grande, to: .first)
        try g.addScore(1, lance: .punto, to: .second)
        try g.adjust(team: .first, by: -1)
        XCTAssertEqual(g.actions.map(\.team), [.first, .second, .first])
        XCTAssertEqual(g.actions.map(\.kind), [.score(.grande), .score(.punto), .adjustment])
        XCTAssertEqual(g.actions.map(\.amount), [2, 1, -1])
    }

    func testR20AdjustAfterFinishRejected() throws {
        var g = try game()
        try g.addScore(40, lance: .grande, to: .first)
        XCTAssertThrowsError(try g.adjust(team: .second, by: 1)) {
            XCTAssertEqual($0 as? ScoringError, .notInProgress)
        }
    }

    func testUndoAfterFinishReopensGame() throws {
        var g = try game()
        try g.addScore(40, lance: .grande, to: .first)
        try g.undo()
        XCTAssertEqual(g.status, .inProgress)
        XCTAssertEqual(g.state.score, PerTeam(0, 0))
    }

    func testInvalidRulesRejected() {
        XCTAssertThrowsError(try Game(rules: GameRules(goal: 35, vacasToWin: 1))) {
            XCTAssertEqual($0 as? ScoringError, .invalidRules)
        }
        XCTAssertThrowsError(try Game(rules: GameRules(goal: 40, vacasToWin: 4)))
    }

    func testTeamNamesAreNormalized() throws {
        let g = try Game(teamNames: PerTeam("   ", "  Los Ases  "))
        XCTAssertEqual(g.teamNames.first, "Equipo 1")
        XCTAssertEqual(g.teamNames.second, "Los Ases")
        let long = try Game(teamNames: PerTeam(String(repeating: "x", count: 50), "B"))
        XCTAssertEqual(long.teamNames.first.count, Game.maxNameLength)
    }

    func testRematchKeepsTeamsAndRules() throws {
        var g = try Game(teamNames: PerTeam("A", "B"), rules: GameRules(goal: 30, vacasToWin: 2))
        try g.addScore(30, lance: .grande, to: .first)
        let r = try g.rematch()
        XCTAssertEqual(r.teamNames, g.teamNames)
        XCTAssertEqual(r.rules, g.rules)
        XCTAssertNotEqual(r.id, g.id)
        XCTAssertTrue(r.actions.isEmpty)
    }

    func testUndoEqualsReplayOfRemainingActions() throws {
        var g = try game(vacas: 2)
        for (i, amount) in [5, 7, 3, 9].enumerated() {
            try g.addScore(amount, lance: Lance.allCases[i], to: i % 2 == 0 ? .first : .second)
        }
        let before = g.state
        try g.addScore(2, lance: .punto, to: .first)
        try g.undo()
        XCTAssertEqual(g.state, before)
    }
}
