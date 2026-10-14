import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class ResultFlowTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("result-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func store() -> FileAppDataStore {
        FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
    }

    private func finishedModel(draft: GameSetupDraft = .standard) throws -> AppModel {
        let model = AppModel(repository: try GameRepository(store: store()))
        model.startGame(with: draft)
        model.score(draft.goal, to: .first)
        return model
    }

    func testReachingGoalShowsResultAndSavesOnceInHistory() throws {
        let model = try finishedModel()
        XCTAssertEqual(model.screen, .result)
        XCTAssertEqual(model.game?.status, .finished(winner: .first, reason: .targetReached))
        let repo = try GameRepository(store: store())
        XCTAssertEqual(repo.history.count, 1)
        XCTAssertNil(repo.activeGame)
    }

    func testOrdagoShowsResultWithOrdagoReason() throws {
        let model = AppModel(repository: try GameRepository(store: store()))
        model.startGame(with: .standard)
        model.declareOrdago(winner: .second)
        XCTAssertEqual(model.screen, .result)
        XCTAssertEqual(model.game?.status, .finished(winner: .second, reason: .ordago))
    }

    func testRematchKeepsTeamsAndRulesAndDoesNotDuplicateHistory() throws {
        let draft = GameSetupDraft(firstName: "A", secondName: "B", goal: 30, vacasToWin: 2)
        let model = try finishedModel(draft: draft)
        model.score(30, to: .first)
        XCTAssertEqual(model.screen, .result)
        model.rematch()
        XCTAssertEqual(model.screen, .game)
        XCTAssertEqual(model.game?.teamNames, PerTeam("A", "B"))
        XCTAssertEqual(model.game?.rules, GameRules(goal: 30, vacasToWin: 2))
        XCTAssertEqual(model.game?.state.score, PerTeam(0, 0))
        let repo = try GameRepository(store: store())
        XCTAssertEqual(repo.history.count, 1)
        XCTAssertNotNil(repo.activeGame)
    }

    func testNewGameFromResultOpensSetupWithSamePreferences() throws {
        let draft = GameSetupDraft(firstName: "A", secondName: "B", goal: 30, vacasToWin: 1)
        let model = try finishedModel(draft: draft)
        model.newGameFromResult()
        XCTAssertEqual(model.screen, .setup)
        XCTAssertEqual(model.draft, draft)
    }

    func testGoHomeFromResultLeavesNothingInProgress() throws {
        let model = try finishedModel()
        model.goHome()
        XCTAssertEqual(model.screen, .home)
        XCTAssertFalse(model.hasGameInProgress)
    }

    func testUndoFromResultReturnsToScoreboard() throws {
        let model = try finishedModel()
        model.undo()
        XCTAssertEqual(model.screen, .game)
        XCTAssertEqual(model.game?.status, .inProgress)
        let repo = try GameRepository(store: store())
        XCTAssertTrue(repo.history.isEmpty)
        XCTAssertNotNil(repo.activeGame)
    }
}
