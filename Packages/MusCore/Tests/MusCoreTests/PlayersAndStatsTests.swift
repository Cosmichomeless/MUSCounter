import XCTest
@testable import MusCore

final class PlayersAndStatsTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL { directory.appendingPathComponent("appdata.json") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("muscore-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func repository() throws -> GameRepository {
        try GameRepository(store: FileAppDataStore(fileURL: fileURL))
    }

    private func date(_ seconds: TimeInterval) -> Date { Date(timeIntervalSince1970: 1_700_000_000 + seconds) }

    private func seats(_ names: String...) -> [Seat] { names.map { Seat(name: $0) } }

    private let table = ["Ana", "Beto", "Carla", "Dani"]

    // MARK: - Migración 3 → 4

    func testVersionThreeFileMigratesWithEmptyPlayersAndKeepsGames() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard, createdAt: date(0))
        try game.addScore(5, lance: .grande, to: .first, at: date(1))
        let encoded = try FileAppDataStore.makeEncoder().encode(AppData(activeGame: game, history: [], preferences: .standard))
        var document = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        document["schemaVersion"] = 3
        document.removeValue(forKey: "players")
        try JSONSerialization.data(withJSONObject: document).write(to: fileURL)

        let loaded = try FileAppDataStore(fileURL: fileURL).load()
        XCTAssertEqual(loaded.schemaVersion, AppData.currentSchemaVersion)
        XCTAssertEqual(loaded.players, [])
        XCTAssertEqual(loaded.activeGame, game)
    }

    // MARK: - Repositorio

    func testStartingGameWithSeatsCreatesPlayersOnce() throws {
        let repo = try repository()
        let game = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: .standard,
            seats: seats("Ana", "Beto", "Carla", "Dani"), now: date(0)
        )
        XCTAssertEqual(repo.players.map(\.name), table)
        XCTAssertEqual(game.seats.compactMap(\.playerID), repo.players.map(\.id))

        // Los mismos nombres (otra grafía) reutilizan a las mismas personas.
        let again = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: .standard,
            seats: seats("ana", "BETO", "Carla", "dani"), now: date(1)
        )
        XCTAssertEqual(repo.players.count, 4)
        XCTAssertEqual(again.seats.compactMap(\.playerID), game.seats.compactMap(\.playerID))
    }

    func testAccentsAndCaseDoNotCreateDuplicatePlayers() throws {
        let repo = try repository()
        try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, seats: seats("José", "B", "C", "D"), now: date(0))
        try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, seats: seats("jose", "B", "C", "D"), now: date(1))
        XCTAssertEqual(repo.players.count, 4)
    }

    func testStartingGameWithoutSeatsCreatesNoPlayers() throws {
        let repo = try repository()
        try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, now: date(0))
        XCTAssertEqual(repo.players, [])
    }

    func testPlayersSurviveReopeningTheApp() throws {
        let repo = try repository()
        try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, seats: seats("Ana", "Beto", "Carla", "Dani"), now: date(0))
        XCTAssertEqual(try repository().players, repo.players)
    }

    func testRestartKeepsSeatsAndFirstMano() throws {
        let repo = try repository()
        let first = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: .standard,
            seats: seats("Ana", "Beto", "Carla", "Dani"), firstMano: 2, now: date(0)
        )
        let restarted = try repo.restartActiveGame(now: date(1))
        XCTAssertEqual(restarted.seats, first.seats)
        XCTAssertEqual(restarted.firstMano, 2)
    }

    func testDeletingAPlayerKeepsTheSavedGameNames() throws {
        let repo = try repository()
        let game = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: .standard, seats: seats("Ana", "Beto", "Carla", "Dani"), now: date(0)
        )
        try repo.deletePlayer(id: try XCTUnwrap(repo.players.first).id)
        XCTAssertEqual(repo.players.count, 3)
        XCTAssertEqual(repo.activeGame?.seats.map(\.name), game.seats.map(\.name))
    }

    func testDeleteAllDataAlsoForgetsPlayers() throws {
        let repo = try repository()
        try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, seats: seats("Ana", "Beto", "Carla", "Dani"), now: date(0))
        try repo.deleteAllData()
        XCTAssertEqual(repo.players, [])
    }

    // MARK: - Estadísticas

    /// Juega una partida con la mesa de siempre y devuelve las partidas terminadas del historial.
    private func finishedGame(
        repo: GameRepository, seatNames: [String]? = nil, at start: TimeInterval,
        script: (inout Game) throws -> Void
    ) throws {
        var game = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: .standard,
            seats: (seatNames ?? table).map { Seat(name: $0) }, now: date(start)
        )
        try script(&game)
        try repo.update(game)
    }

    func testPlayerStatsCountGamesWinsAndOrdagos() throws {
        let repo = try repository()
        // Gana el primer equipo (Ana y Carla) con un órdago.
        try finishedGame(repo: repo, at: 0) { try $0.declareOrdago(winner: .first, at: self.date(10)) }
        // Gana el segundo equipo (Beto y Dani) por tantos.
        try finishedGame(repo: repo, at: 100) {
            try $0.addScore(40, lance: .juego, to: .second, at: self.date(110))
        }
        let stats = Stats.players(from: repo.history)
        let ana = try XCTUnwrap(repo.players.first { $0.name == "Ana" })
        let beto = try XCTUnwrap(repo.players.first { $0.name == "Beto" })

        XCTAssertEqual(stats[ana.id]?.gamesPlayed, 2)
        XCTAssertEqual(stats[ana.id]?.gamesWon, 1)
        XCTAssertEqual(stats[ana.id]?.ordagosWon, 1)
        XCTAssertEqual(stats[ana.id]?.ordagosLost, 0)
        XCTAssertEqual(stats[ana.id]?.winRate, 0.5)
        XCTAssertEqual(stats[beto.id]?.ordagosLost, 1)
        XCTAssertEqual(stats[beto.id]?.tantosByLance[.juego], 40)
        XCTAssertEqual(stats[beto.id]?.bestLance, .juego)
    }

    func testAbandonedAndUntrackedGamesDoNotCount() throws {
        let repo = try repository()
        try finishedGame(repo: repo, at: 0) { try $0.abandon(at: self.date(5)) }
        var plain = try repo.startGame(teamNames: PerTeam("N", "E"), rules: .standard, now: date(10))
        try plain.declareOrdago(winner: .first, at: date(11))
        try repo.update(plain)
        XCTAssertTrue(Stats.players(from: repo.history).isEmpty)
        XCTAssertTrue(Stats.pairs(from: repo.history).isEmpty)
    }

    func testManualAdjustmentsDoNotCountAsTantosByLance() throws {
        let repo = try repository()
        try finishedGame(repo: repo, at: 0) {
            try $0.adjust(team: .first, by: 3, at: self.date(1))
            try $0.declareOrdago(winner: .first, at: self.date(2))
        }
        let ana = try XCTUnwrap(repo.players.first { $0.name == "Ana" })
        XCTAssertEqual(Stats.players(from: repo.history)[ana.id]?.tantosByLance, [:])
        XCTAssertNil(Stats.players(from: repo.history)[ana.id]?.bestLance)
    }

    func testVacasWonAreCountedPerTeam() throws {
        let repo = try repository()
        var game = try repo.startGame(
            teamNames: PerTeam("N", "E"), rules: GameRules(goal: 30, vacasToWin: 2),
            seats: seats("Ana", "Beto", "Carla", "Dani"), now: date(0)
        )
        try game.declareOrdago(winner: .first, at: date(1))
        try game.declareOrdago(winner: .second, at: date(2))
        try game.declareOrdago(winner: .second, at: date(3))
        try repo.update(game)
        let stats = Stats.players(from: repo.history)
        let ana = try XCTUnwrap(repo.players.first { $0.name == "Ana" })
        let dani = try XCTUnwrap(repo.players.first { $0.name == "Dani" })
        XCTAssertEqual(stats[ana.id]?.vacasWon, 1)
        XCTAssertEqual(stats[dani.id]?.vacasWon, 2)
    }

    func testPairStatsAreOrderIndependentAndSortedByGamesPlayed() throws {
        let repo = try repository()
        // Ana + Carla ganan dos veces; después juegan Ana + Beto contra Carla + Dani y pierden.
        try finishedGame(repo: repo, at: 0) { try $0.declareOrdago(winner: .first, at: self.date(1)) }
        try finishedGame(repo: repo, at: 100) { try $0.declareOrdago(winner: .first, at: self.date(101)) }
        try finishedGame(repo: repo, seatNames: ["Ana", "Carla", "Beto", "Dani"], at: 200) {
            try $0.declareOrdago(winner: .second, at: self.date(201))
        }
        let pairs = Stats.pairs(from: repo.history)
        let id = { (name: String) in repo.players.first { $0.name == name }!.id }

        let anaCarla = try XCTUnwrap(pairs.first { Set($0.playerIDs) == [id("Ana"), id("Carla")] })
        XCTAssertEqual(anaCarla.gamesPlayed, 2)
        XCTAssertEqual(anaCarla.gamesWon, 2)
        XCTAssertEqual(pairs.first, anaCarla)
        let anaBeto = try XCTUnwrap(pairs.first { Set($0.playerIDs) == [id("Ana"), id("Beto")] })
        XCTAssertEqual(anaBeto.gamesWon, 0)
        XCTAssertEqual(anaBeto.gamesPlayed, 1)
    }

    func testStatsWithNoGamesHaveNoWinRate() {
        XCTAssertNil(PlayerStats(playerID: UUID()).winRate)
        XCTAssertNil(PlayerStats(playerID: UUID()).bestLance)
    }

    // MARK: - Evolución del tanteo

    func testTimelineFollowsEachActionAndMarksHandBreaks() throws {
        var game = try Game(seats: seats("Ana", "Beto", "Carla", "Dani"), createdAt: date(0))
        try game.addScore(2, lance: .grande, to: .first, at: date(1))
        try game.nextHand(at: date(2))
        try game.addScore(3, lance: .chica, to: .second, at: date(3))
        let timeline = ScoreTimeline(game: game)
        XCTAssertEqual(timeline.goal, 40)
        XCTAssertEqual(timeline.points.map(\.score), [PerTeam(0, 0), PerTeam(2, 0), PerTeam(2, 0), PerTeam(2, 3)])
        XCTAssertEqual(timeline.points.map(\.isHandBreak), [false, false, true, false])
        XCTAssertEqual(timeline.points.map(\.step), [0, 1, 2, 3])
    }

    func testTimelineKeepsTheClosingScoreOfEachVaca() throws {
        var game = try Game(rules: GameRules(goal: 30, vacasToWin: 2), createdAt: date(0))
        try game.addScore(20, lance: .juego, to: .first, at: date(1))
        try game.declareOrdago(winner: .first, at: date(2))
        try game.addScore(4, lance: .grande, to: .second, at: date(3))
        let timeline = ScoreTimeline(game: game)
        XCTAssertEqual(timeline.points[2].score, PerTeam(30, 0))
        XCTAssertEqual(timeline.points[2].vaca, 0)
        XCTAssertEqual(timeline.points[3].score, PerTeam(0, 4))
        XCTAssertEqual(timeline.points[3].vaca, 1)
    }

    func testTimelineOfEmptyGameHasOnlyTheStart() throws {
        let timeline = ScoreTimeline(game: try Game())
        XCTAssertEqual(timeline.points.count, 1)
    }

    // MARK: - Piedras

    func testPiedrasSplitIntoFivesAndSingles() {
        XCTAssertEqual(Piedras.split(0).groups, 0)
        XCTAssertEqual(Piedras.split(4).singles, 4)
        XCTAssertEqual(Piedras.split(5).groups, 1)
        XCTAssertEqual(Piedras.split(5).singles, 0)
        XCTAssertEqual(Piedras.split(38).groups, 7)
        XCTAssertEqual(Piedras.split(38).singles, 3)
        XCTAssertEqual(Piedras.split(-3).groups, 0)
    }
}
