import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class UndoTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("undo-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func store() -> FileAppDataStore {
        FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
    }

    private func makeModel() throws -> AppModel {
        let model = AppModel(repository: try GameRepository(store: store()))
        model.startGame(with: .standard)
        return model
    }

    func testUndoRevertsLastScoreAndPersists() throws {
        let model = try makeModel()
        model.score(2, to: .first)
        model.score(3, to: .second)
        model.undo()
        XCTAssertEqual(model.game?.state.score, PerTeam(2, 0))
        XCTAssertEqual(try GameRepository(store: store()).activeGame?.state.score, PerTeam(2, 0))
    }

    func testUndoAtStartShowsMessageAndChangesNothing() throws {
        let model = try makeModel()
        model.undo()
        XCTAssertEqual(model.errorMessage, "No hay nada que deshacer.")
        XCTAssertEqual(model.game?.state.score, PerTeam(0, 0))
    }

    func testToastDescribesLastActionAndUndoClearsIt() throws {
        let model = try makeModel()
        model.selectedLance = .chica
        model.score(2, to: .second)
        XCTAssertEqual(model.toast?.message, "Chica: +2 para Ellos")
        model.undo()
        XCTAssertNil(model.toast)
    }

    func testUndoingTheWinningActionReopensTheGame() throws {
        let model = try makeModel()
        model.score(40, to: .first)
        XCTAssertEqual(model.game?.status, .finished(winner: .first, reason: .targetReached))
        model.undo()
        XCTAssertEqual(model.game?.status, .inProgress)
        XCTAssertNotNil(try GameRepository(store: store()).activeGame)
        XCTAssertTrue(try GameRepository(store: store()).history.isEmpty)
    }

    func testRestartClearsScoreWithoutArchiving() throws {
        let model = try makeModel()
        model.score(5, to: .first)
        model.restartGame()
        XCTAssertEqual(model.game?.state.score, PerTeam(0, 0))
        XCTAssertTrue(try GameRepository(store: store()).history.isEmpty)
    }

    func testAbandonMovesGameToHistoryAndGoesHome() throws {
        let model = try makeModel()
        model.score(5, to: .first)
        model.abandonGame()
        XCTAssertEqual(model.screen, .home)
        XCTAssertFalse(model.hasGameInProgress)
        let repo = try GameRepository(store: store())
        XCTAssertNil(repo.activeGame)
        XCTAssertEqual(repo.history.first?.status, .abandoned)
    }

    func testDeleteGameLeavesNoTrace() throws {
        let model = try makeModel()
        model.score(5, to: .first)
        model.deleteGame()
        XCTAssertEqual(model.screen, .home)
        let repo = try GameRepository(store: store())
        XCTAssertNil(repo.activeGame)
        XCTAssertTrue(repo.history.isEmpty)
    }

    func testAdjustChangesScoreAndRejectsBelowZero() throws {
        let model = try makeModel()
        model.adjust(.first, by: -1)
        XCTAssertEqual(model.errorMessage, "El tanteo no puede bajar de 0.")
        model.score(3, to: .first)
        model.adjust(.first, by: -1)
        XCTAssertEqual(model.game?.state.score.first, 2)
    }
}
