import XCTest
@testable import MusCore

final class SeatingTests: XCTestCase {
    private func date(_ seconds: TimeInterval) -> Date { Date(timeIntervalSince1970: 1_700_000_000 + seconds) }

    private func seats(_ names: String...) -> [Seat] { names.map { Seat(name: $0) } }

    private func tableGame(firstMano: Int = 0, rules: GameRules = .standard) throws -> Game {
        try Game(
            teamNames: PerTeam("Nosotros", "Ellos"), rules: rules,
            seats: seats("Ana", "Beto", "Carla", "Dani"), firstMano: firstMano, createdAt: date(0)
        )
    }

    // MARK: - Mesa

    func testTeamsSitAlternately() {
        XCTAssertEqual((0..<4).map(Table.team(ofSeat:)), [.first, .second, .first, .second])
        XCTAssertEqual(Table.seats(of: .first), [0, 2])
        XCTAssertEqual(Table.seats(of: .second), [1, 3])
    }

    func testManoRotatesClockwiseAndWraps() {
        XCTAssertEqual((0..<6).map { Table.manoSeat(firstMano: 2, handsPlayed: $0) }, [2, 3, 0, 1, 2, 3])
    }

    // MARK: - Partida con asientos

    func testGameWithoutSeatsDoesNotTrackPlayers() throws {
        let game = try Game(teamNames: PerTeam("A", "B"), rules: .standard)
        XCTAssertFalse(game.tracksPlayers)
        XCTAssertNil(game.manoSeat)
        XCTAssertNil(game.manoName)
    }

    func testSeatsMustBeEmptyOrFour() {
        XCTAssertThrowsError(try Game(seats: seats("A", "B", "C"))) { XCTAssertEqual($0 as? ScoringError, .invalidSeating) }
    }

    func testFirstManoMustBeAValidSeat() {
        XCTAssertThrowsError(try Game(seats: seats("A", "B", "C", "D"), firstMano: 4)) {
            XCTAssertEqual($0 as? ScoringError, .invalidSeating)
        }
    }

    func testSamePlayerCannotTakeTwoSeats() {
        let id = UUID()
        let twice = [Seat(name: "A", playerID: id), Seat(name: "B"), Seat(name: "C", playerID: id), Seat(name: "D")]
        XCTAssertThrowsError(try Game(seats: twice)) { XCTAssertEqual($0 as? ScoringError, .invalidSeating) }
    }

    func testNextHandPassesManoClockwise() throws {
        var game = try tableGame(firstMano: 1)
        XCTAssertEqual(game.manoName, "Beto")
        try game.nextHand(at: date(1))
        XCTAssertEqual(game.manoName, "Carla")
        try game.nextHand(at: date(2))
        try game.nextHand(at: date(3))
        XCTAssertEqual(game.manoName, "Ana")
        XCTAssertEqual(game.state.handsPlayed, 3)
    }

    func testManoNameAfterEachAction() throws {
        var game = try tableGame(firstMano: 0)
        try game.addScore(1, lance: .grande, to: .first, at: date(1))
        try game.nextHand(at: date(2))
        try game.nextHand(at: date(3))
        XCTAssertEqual(game.manoName(after: game.actions[0]), "Ana")
        XCTAssertEqual(game.manoName(after: game.actions[1]), "Beto")
        XCTAssertEqual(game.manoName(after: game.actions[2]), "Carla")
        XCTAssertNil(game.manoName(after: GameAction(team: .first, kind: .nextHand, amount: 0)))
    }

    func testNextHandDoesNotChangeTheScore() throws {
        var game = try tableGame()
        try game.addScore(3, lance: .grande, to: .first, at: date(1))
        try game.nextHand(at: date(2))
        XCTAssertEqual(game.state.score, PerTeam(3, 0))
    }

    func testUndoNextHandGivesTheManoBack() throws {
        var game = try tableGame()
        try game.nextHand(at: date(1))
        XCTAssertEqual(game.manoName, "Beto")
        let undone = try game.undo()
        XCTAssertEqual(undone.kind, .nextHand)
        XCTAssertEqual(game.manoName, "Ana")
    }

    func testNextHandNeedsSeats() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard)
        XCTAssertThrowsError(try game.nextHand()) { XCTAssertEqual($0 as? ScoringError, .invalidSeating) }
    }

    func testNextHandIsRejectedOnceTheGameIsOver() throws {
        var game = try tableGame()
        try game.declareOrdago(winner: .first, at: date(1))
        XCTAssertThrowsError(try game.nextHand()) { XCTAssertEqual($0 as? ScoringError, .notInProgress) }
    }

    func testNextHandWithAmountIsInvalid() {
        let action = GameAction(team: .first, kind: .nextHand, amount: 2)
        XCTAssertThrowsError(try GameState.initial.applying(action, rules: .standard)) {
            XCTAssertEqual($0 as? ScoringError, .invalidAmount)
        }
    }

    func testRematchKeepsSeatsAndContinuesTheRotation() throws {
        var game = try tableGame(firstMano: 0)
        try game.nextHand(at: date(1))
        try game.nextHand(at: date(2))
        try game.declareOrdago(winner: .second, at: date(3))
        let next = try game.rematch(createdAt: date(4))
        XCTAssertEqual(next.seats, game.seats)
        XCTAssertEqual(next.manoName, "Carla")
        XCTAssertEqual(next.state.handsPlayed, 0)
    }

    func testRematchOfGameWithoutSeatsStaysWithoutSeats() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard)
        try game.declareOrdago(winner: .first)
        XCTAssertFalse(try game.rematch().tracksPlayers)
    }

    // MARK: - Compatibilidad con partidas antiguas

    func testGameSavedBeforeSeatsStillDecodes() throws {
        var game = try Game(teamNames: PerTeam("A", "B"), rules: .standard, createdAt: date(0))
        try game.addScore(4, lance: .pares, to: .second, at: date(1))
        let encoded = try FileAppDataStore.makeEncoder().encode(game)
        var document = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        document.removeValue(forKey: "seats")
        document.removeValue(forKey: "firstMano")
        var state = try XCTUnwrap(document["state"] as? [String: Any])
        state.removeValue(forKey: "handsPlayed")
        document["state"] = state

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let old = try decoder.decode(Game.self, from: JSONSerialization.data(withJSONObject: document))
        XCTAssertEqual(old, game)
        XCTAssertFalse(old.tracksPlayers)
    }

    func testGameWithSeatsRoundTrips() throws {
        var game = try tableGame(firstMano: 3)
        try game.nextHand(at: date(1))
        let encoder = FileAppDataStore.makeEncoder()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        XCTAssertEqual(try decoder.decode(Game.self, from: encoder.encode(game)), game)
    }
}
