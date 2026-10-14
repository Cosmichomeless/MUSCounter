import XCTest
@testable import MusCore

final class ScorePreviewTests: XCTestCase {
    func testPreviewOfNormalScore() throws {
        var g = try Game()
        try g.addScore(1, lance: .grande, to: .second)
        let preview = try g.previewScore(amount: 6, for: .second).get()
        XCTAssertEqual(preview, ScorePreview(team: .second, scoreBefore: 1, scoreAfter: 7, closesVaca: false, winsGame: false))
    }

    func testPreviewDoesNotChangeTheGame() throws {
        let g = try Game()
        _ = g.previewScore(amount: 10, for: .first)
        XCTAssertTrue(g.actions.isEmpty)
        XCTAssertEqual(g.state.score, PerTeam(0, 0))
    }

    func testPreviewOfScoreThatWinsTheGame() throws {
        var g = try Game()
        try g.addScore(35, lance: .grande, to: .first)
        let preview = try g.previewScore(amount: 9, for: .first).get()
        XCTAssertEqual(preview.scoreAfter, 40)
        XCTAssertTrue(preview.closesVaca)
        XCTAssertTrue(preview.winsGame)
    }

    func testPreviewOfScoreThatOnlyClosesAVaca() throws {
        var g = try Game(rules: GameRules(goal: 30, vacasToWin: 2))
        try g.addScore(28, lance: .grande, to: .first)
        let preview = try g.previewScore(amount: 5, for: .first).get()
        XCTAssertTrue(preview.closesVaca)
        XCTAssertFalse(preview.winsGame)
        XCTAssertEqual(preview.scoreAfter, 30)
    }

    func testPreviewRejectsInvalidAmounts() throws {
        let g = try Game()
        XCTAssertEqual(g.previewScore(amount: 0, for: .first), .failure(.invalidAmount))
        XCTAssertEqual(g.previewScore(amount: 41, for: .first), .failure(.invalidAmount))
    }

    func testPreviewExplainsFinishedAndAbandonedGames() throws {
        var finished = try Game()
        try finished.addScore(40, lance: .grande, to: .first)
        XCTAssertEqual(finished.previewScore(amount: 1, for: .second), .failure(.notInProgress))
        XCTAssertEqual(finished.previewOrdago(winner: .second), .failure(.notInProgress))

        var abandoned = try Game()
        try abandoned.abandon()
        XCTAssertEqual(abandoned.previewScore(amount: 1, for: .first), .failure(.notInProgress))
    }

    func testOrdagoPreview() throws {
        var g = try Game()
        try g.addScore(10, lance: .grande, to: .first)
        let preview = try g.previewOrdago(winner: .first).get()
        XCTAssertEqual(preview, ScorePreview(team: .first, scoreBefore: 10, scoreAfter: 40, closesVaca: true, winsGame: true))
    }
}
