import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class PlayersAndDetailTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("players-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel() throws -> AppModel {
        let store = FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
        return AppModel(repository: try GameRepository(store: store))
    }

    private func startTableGame(_ model: AppModel) {
        model.openSetup()
        model.draft.seatNames = ["Ana", "Beto", "Carla", "Dani"]
        model.draft.firstMano = 1
        model.startGame(with: model.draft)
    }

    func testSetupWithFourNamesStartsATableGameAndRemembersPlayers() throws {
        let model = try makeModel()
        startTableGame(model)
        XCTAssertEqual(model.game?.tracksPlayers, true)
        XCTAssertEqual(model.game?.manoName, "Beto")
        XCTAssertEqual(Set(model.players.map(\.name)), ["Ana", "Beto", "Carla", "Dani"])
    }

    func testNextHandPassesTheManoAndShowsAToast() throws {
        let model = try makeModel()
        startTableGame(model)
        model.nextHand()
        XCTAssertEqual(model.game?.manoName, "Carla")
        XCTAssertEqual(model.toast?.message, "Mano para Carla")
        model.undo()
        XCTAssertEqual(model.game?.manoName, "Beto")
    }

    func testNextHandWithoutPlayersShowsAnError() throws {
        let model = try makeModel()
        model.startGame(with: .standard)
        model.nextHand()
        XCTAssertEqual(model.errorMessage, AppModel.message(for: .invalidSeating))
        XCTAssertEqual(model.game?.actions.count, 0)
    }

    func testDeletingAPlayerKeepsFinishedGames() throws {
        let model = try makeModel()
        startTableGame(model)
        model.declareOrdago(winner: .first)
        let id = try XCTUnwrap(model.players.first { $0.name == "Ana" }?.id)
        model.deletePlayer(id)
        XCTAssertNil(model.players.first { $0.name == "Ana" })
        XCTAssertEqual(model.history.first?.seats.first?.name, "Ana")
    }

    func testChartSummaryAndLanceTotals() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard)
        try game.addScore(2, lance: .grande, to: .first)
        try game.addScore(3, lance: .chica, to: .second)
        try game.addScore(1, lance: .grande, to: .second)
        let totals = ScoreChartText.tantos(game)
        XCTAssertEqual(totals.map(\.lance), [.grande, .chica])
        XCTAssertEqual(totals[0].tantos, PerTeam(2, 1))
        XCTAssertTrue(ScoreChartText.summary(game).hasPrefix("3 anotaciones."))
    }

    func testShareCardRendersAnImage() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard)
        try game.addScore(2, lance: .grande, to: .first)
        let image = ShareCard.render(game)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 300)
    }

    func testStatsText() {
        XCTAssertEqual(StatsText.percent(nil), "–")
        XCTAssertEqual(StatsText.percent(2.0 / 3.0), "67 %")
        XCTAssertEqual(StatsText.games(1), "1 partida")
        XCTAssertEqual(StatsText.wins(3), "3 victorias")
    }
}

@MainActor
private final class SpyScoreboard: ScoreboardPublishing {
    private(set) var published: [Game?] = []
    func publish(_ game: Game?) { published.append(game) }
}

@MainActor
final class ScoreboardPublishingTests: XCTestCase {
    private func makeModel(_ spy: SpyScoreboard) throws -> AppModel {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("live-\(UUID().uuidString).json")
        return AppModel(repository: try GameRepository(store: FileAppDataStore(fileURL: url)), scoreboard: spy)
    }

    func testScoreboardFollowsTheGameAndDisappearsWhenItIsAbandoned() throws {
        let spy = SpyScoreboard()
        let model = try makeModel(spy)
        model.openSetup()
        model.startGame(with: model.draft)
        XCTAssertEqual(spy.published.last??.state.score, PerTeam(0, 0))

        model.score(3, to: .first)
        XCTAssertEqual(spy.published.last??.state.score, PerTeam(3, 0))

        model.undo()
        XCTAssertEqual(spy.published.last??.state.score, PerTeam(0, 0))

        model.abandonGame()
        XCTAssertNil(spy.published.last ?? nil)
    }

    func testContentStateCarriesScoreRulesAndMano() throws {
        let spy = SpyScoreboard()
        let model = try makeModel(spy)
        model.openSetup()
        model.draft.seatNames = ["Ana", "Beto", "Carla", "Dani"]
        model.draft.firstMano = 2
        model.startGame(with: model.draft)
        model.score(5, to: .second)
        let state = ScoreboardActivity.contentState(for: try XCTUnwrap(model.game))
        XCTAssertEqual(state.score, [0, 5])
        XCTAssertEqual(state.goal, model.game?.rules.goal)
        XCTAssertEqual(state.mano, "Carla")
    }
}
