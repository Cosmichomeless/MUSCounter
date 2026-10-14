import XCTest
@testable import MusCore

/// Recorre todas las variantes admitidas (docs/reglas-de-tanteo.md §3) para que ninguna combinación
/// de objetivo y vacas quede sin probar.
final class VariantMatrixTests: XCTestCase {
    private let variants: [GameRules] = GameRules.allowedGoals.flatMap { goal in
        GameRules.allowedVacasToWin.map { GameRules(goal: goal, vacasToWin: $0) }
    }

    func testEveryAllowedVariantBuildsAGame() throws {
        XCTAssertEqual(variants.count, 6)
        for rules in variants {
            let game = try Game(rules: rules)
            XCTAssertEqual(game.status, .inProgress, "\(rules)")
        }
    }

    func testUnsupportedVariantsAreRejected() {
        for rules in [GameRules(goal: 35, vacasToWin: 1), GameRules(goal: 40, vacasToWin: 0),
                      GameRules(goal: 40, vacasToWin: 4), GameRules(goal: 0, vacasToWin: 1)] {
            XCTAssertThrowsError(try Game(rules: rules)) { XCTAssertEqual($0 as? ScoringError, .invalidRules) }
        }
    }

    func testOneBelowTheGoalNeverClosesAVaca() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            try game.addScore(rules.goal - 1, lance: .grande, to: .first)
            XCTAssertEqual(game.state.score, PerTeam(rules.goal - 1, 0), "\(rules)")
            XCTAssertEqual(game.state.vacas, PerTeam(0, 0), "\(rules)")
            XCTAssertTrue(game.isInProgress, "\(rules)")
        }
    }

    func testReachingTheGoalClosesTheVacaAndTheGameWhenItWasTheLast() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            for vaca in 1...rules.vacasToWin {
                try game.addScore(rules.goal, lance: .grande, to: .second)
                XCTAssertEqual(game.state.vacas.second, vaca, "\(rules)")
                if vaca < rules.vacasToWin {
                    XCTAssertEqual(game.state.score, PerTeam(0, 0), "tras cada vaca el tanteo vuelve a 0 (\(rules))")
                    XCTAssertTrue(game.isInProgress, "\(rules)")
                }
            }
            XCTAssertEqual(game.status, .finished(winner: .second, reason: .targetReached), "\(rules)")
            XCTAssertEqual(game.state.score.second, rules.goal, "\(rules)")
            XCTAssertNotNil(game.endedAt, "\(rules)")
        }
    }

    func testOverflowIsDiscardedInEveryVariant() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            try game.addScore(rules.goal - 2, lance: .grande, to: .first)
            try game.addScore(5, lance: .chica, to: .first)
            XCTAssertEqual(game.state.completedVacas.first?.finalScore.first, rules.goal, "\(rules)")
        }
    }

    func testAmountAboveTheGoalIsRejectedInEveryVariant() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            XCTAssertThrowsError(try game.addScore(rules.goal + 1, lance: .punto, to: .first)) {
                XCTAssertEqual($0 as? ScoringError, .invalidAmount, "\(rules)")
            }
            XCTAssertTrue(game.actions.isEmpty, "una anotación rechazada no deja rastro (\(rules))")
        }
    }

    func testOrdagoWinsTheVacaFromAnyScoreInEveryVariant() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            try game.addScore(3, lance: .grande, to: .first)
            try game.addScore(rules.goal - 1, lance: .chica, to: .second)
            try game.declareOrdago(winner: .first)
            XCTAssertEqual(game.state.vacas.first, 1, "\(rules)")
            XCTAssertEqual(game.state.completedVacas.last?.reason, .ordago, "\(rules)")
            XCTAssertEqual(game.state.completedVacas.last?.finalScore.first, rules.goal, "\(rules)")
        }
    }

    func testEveryQuickAmountOfEveryLanceIsAccepted() throws {
        for lance in Lance.allCases {
            XCTAssertFalse(lance.quickAmounts.isEmpty)
            for amount in lance.quickAmounts {
                var game = try Game(rules: GameRules(goal: 30, vacasToWin: 1))
                XCTAssertNoThrow(try game.addScore(amount, lance: lance, to: .first), "\(lance) \(amount)")
                XCTAssertEqual(game.state.score.first, amount)
            }
        }
    }

    func testAdjustmentLimits() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            XCTAssertThrowsError(try game.adjust(team: .first, by: 0)) { XCTAssertEqual($0 as? ScoringError, .invalidAmount) }
            XCTAssertThrowsError(try game.adjust(team: .first, by: -1)) { XCTAssertEqual($0 as? ScoringError, .belowZero) }
            XCTAssertThrowsError(try game.adjust(team: .first, by: rules.goal + 1)) { XCTAssertEqual($0 as? ScoringError, .invalidAmount) }
            XCTAssertTrue(game.actions.isEmpty, "\(rules)")
        }
    }

    func testUndoingEverythingReturnsToTheInitialStateInEveryVariant() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            var turn = TeamID.first
            while game.isInProgress {
                try game.addScore(7, lance: .grande, to: turn)
                turn = turn == .first ? .second : .first
            }
            XCTAssertTrue(game.canUndo)
            while game.canUndo { try game.undo() }
            XCTAssertEqual(game.state, .initial, "\(rules)")
            XCTAssertNil(game.endedAt, "\(rules)")
            XCTAssertThrowsError(try game.undo()) { XCTAssertEqual($0 as? ScoringError, .nothingToUndo) }
        }
    }

    func testAbandonedGameRejectsEveryActionAndKeepsNoWinner() throws {
        for rules in variants {
            var game = try Game(rules: rules)
            try game.addScore(2, lance: .grande, to: .first)
            try game.abandon()
            XCTAssertEqual(game.status, .abandoned)
            XCTAssertNil(game.state.winner)
            XCTAssertThrowsError(try game.addScore(1, lance: .punto, to: .first))
            XCTAssertThrowsError(try game.declareOrdago(winner: .first))
            XCTAssertThrowsError(try game.adjust(team: .first, by: 1))
            XCTAssertThrowsError(try game.undo())
            XCTAssertThrowsError(try game.abandon())
        }
    }

    func testFinishedGameCannotBeAbandoned() throws {
        var game = try Game(rules: GameRules(goal: 30, vacasToWin: 1))
        try game.addScore(30, lance: .grande, to: .first)
        XCTAssertThrowsError(try game.abandon()) { XCTAssertEqual($0 as? ScoringError, .notInProgress) }
    }
}
