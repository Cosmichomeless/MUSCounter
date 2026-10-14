import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class ScoreboardTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("scoreboard-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel() throws -> AppModel {
        let store = FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
        let model = AppModel(repository: try GameRepository(store: store))
        model.startGame(with: .standard)
        return model
    }

    func testScoringUsesSelectedLanceAndTeam() throws {
        let model = try makeModel()
        model.selectedLance = .pares
        model.score(3, to: .second)
        XCTAssertEqual(model.game?.state.score, PerTeam(0, 3))
        XCTAssertEqual(model.game?.actions.last?.kind, .score(.pares))
        XCTAssertEqual(model.game?.actions.last?.team, .second)
    }

    func testReachingGoalFinishesGameAndBlocksMoreScoring() throws {
        let model = try makeModel()
        for _ in 0..<8 { model.score(5, to: .first) }
        XCTAssertEqual(model.game?.status, .finished(winner: .first, reason: .targetReached))
        model.score(1, to: .second)
        XCTAssertEqual(model.game?.state.score.second, 0)
        XCTAssertEqual(model.errorMessage, "La partida ya ha terminado.")
    }

    func testScoreIsPersistedAfterEveryAction() throws {
        let model = try makeModel()
        model.score(4, to: .first)
        let store = FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
        let reopened = try GameRepository(store: store)
        XCTAssertEqual(reopened.activeGame?.state.score, PerTeam(4, 0))
    }

    func testPanelsAreAvailableForBothTeamsWithTapTargetsOfAtLeast44Points() {
        XCTAssertGreaterThanOrEqual(Metrics.minTapTarget, 44)
        for lance in Lance.allCases { XCTAssertFalse(lance.quickAmounts.isEmpty) }
    }
}
