import XCTest
@testable import MusCore

final class PersistenceTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL { directory.appendingPathComponent("sub/appdata.json") }

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

    // MARK: - Almacén

    func testLoadFromMissingFileReturnsEmpty() throws {
        let store = FileAppDataStore(fileURL: fileURL)
        XCTAssertEqual(try store.load(), .empty)
    }

    func testRoundTripPreservesGameExactly() throws {
        var game = try Game(teamNames: PerTeam("Nosotros", "Ellos"), rules: GameRules(goal: 30, vacasToWin: 2), createdAt: date(0))
        try game.addScore(4, lance: .grande, to: .first, at: date(1))
        try game.declareOrdago(winner: .second, at: date(2))
        let store = FileAppDataStore(fileURL: fileURL)
        let data = AppData(activeGame: game, history: [])
        try store.save(data)
        XCTAssertEqual(try store.load(), data)
    }

    func testDeleteAllRemovesFile() throws {
        let store = FileAppDataStore(fileURL: fileURL)
        try store.save(.empty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        try store.deleteAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        try store.deleteAll() // idempotente
    }

    func testCorruptedFileThrows() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("no es json".utf8).write(to: fileURL)
        XCTAssertThrowsError(try FileAppDataStore(fileURL: fileURL).load()) {
            guard case .corrupted = $0 as? PersistenceError else { return XCTFail("esperaba .corrupted") }
        }
    }

    // MARK: - Migraciones

    func testNewerSchemaIsRejected() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"schemaVersion": 99, "history": []}"#.utf8).write(to: fileURL)
        XCTAssertThrowsError(try FileAppDataStore(fileURL: fileURL).load()) {
            XCTAssertEqual($0 as? PersistenceError, .unsupportedSchemaVersion(99))
        }
    }

    func testMigratorAppliesStepsInOrder() throws {
        let migrator = SchemaMigrator(currentVersion: 3, steps: [
            1: { var d = $0; d["b"] = (d["a"] as? Int ?? 0) * 10; return d },
            2: { var d = $0; d["c"] = (d["b"] as? Int ?? 0) + 1; return d },
        ])
        let migrated = try migrator.migrate(Data(#"{"schemaVersion": 1, "a": 2}"#.utf8))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 3)
        XCTAssertEqual(json["b"] as? Int, 20)
        XCTAssertEqual(json["c"] as? Int, 21)
    }

    func testMigratorFailsWhenStepIsMissing() {
        let migrator = SchemaMigrator(currentVersion: 2)
        XCTAssertThrowsError(try migrator.migrate(Data(#"{"schemaVersion": 1}"#.utf8))) {
            guard case .corrupted = $0 as? PersistenceError else { return XCTFail("esperaba .corrupted") }
        }
    }

    func testStoreMigratesOlderFileBeforeDecoding() throws {
        // Simula un fichero de la "versión 0" que guardaba las partidas bajo otra clave.
        let migrator = SchemaMigrator(currentVersion: AppData.currentSchemaVersion, steps: [
            0: { var d = $0; d["history"] = d.removeValue(forKey: "games") ?? []; return d },
            1: { var d = $0; d["preferences"] = ["goal": 40, "vacasToWin": 1, "theme": "system"]; return d },
        ])
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"games": []}"#.utf8).write(to: fileURL)
        let loaded = try FileAppDataStore(fileURL: fileURL, migrator: migrator).load()
        XCTAssertEqual(loaded.schemaVersion, AppData.currentSchemaVersion)
        XCTAssertEqual(loaded.history, [])
    }

    // MARK: - Repositorio

    func testActiveGameSurvivesReopeningTheApp() throws {
        let repo = try repository()
        var game = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try game.addScore(3, lance: .grande, to: .first, at: date(1))
        try repo.update(game)

        let reopened = try repository()
        XCTAssertEqual(reopened.activeGame, game)
        XCTAssertEqual(reopened.activeGame?.state.score, PerTeam(3, 0))
    }

    func testFinishedGameMovesToHistoryExactlyOnce() throws {
        let repo = try repository()
        var game = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try game.addScore(40, lance: .grande, to: .first, at: date(1))
        try repo.update(game)
        try repo.update(game) // guardar dos veces no duplica

        XCTAssertNil(repo.activeGame)
        XCTAssertEqual(repo.history.count, 1)
        XCTAssertEqual(try repository().history, [game])
    }

    func testUndoingTheWinningActionRestoresActiveGame() throws {
        let repo = try repository()
        var game = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try game.addScore(40, lance: .grande, to: .first, at: date(1))
        try repo.update(game)
        try game.undo()
        try repo.update(game)

        XCTAssertEqual(repo.activeGame?.id, game.id)
        XCTAssertTrue(repo.history.isEmpty)
    }

    func testStartingNewGameArchivesPreviousAsAbandoned() throws {
        let repo = try repository()
        var first = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try first.addScore(5, lance: .grande, to: .first, at: date(1))
        try repo.update(first)
        let second = try repo.startGame(teamNames: PerTeam("C", "D"), rules: .standard, now: date(10))

        XCTAssertEqual(repo.activeGame?.id, second.id)
        XCTAssertEqual(repo.history.count, 1)
        XCTAssertEqual(repo.history[0].id, first.id)
        XCTAssertEqual(repo.history[0].status, .abandoned)
    }

    func testHistoryKeepsRulesAndResultOfEachGame() throws {
        let repo = try repository()
        var a = try repo.startGame(teamNames: PerTeam("A", "B"), rules: GameRules(goal: 30, vacasToWin: 2), now: date(0))
        try a.addScore(30, lance: .grande, to: .first, at: date(1))
        try a.addScore(30, lance: .grande, to: .first, at: date(2))
        try repo.update(a)
        var b = try repo.startGame(teamNames: PerTeam("C", "D"), rules: .standard, now: date(10))
        try b.addScore(40, lance: .pares, to: .second, at: date(11))
        try repo.update(b)

        let history = try repository().history
        XCTAssertEqual(history.map(\.id), [b.id, a.id]) // la más reciente primero
        XCTAssertEqual(history[1].rules, GameRules(goal: 30, vacasToWin: 2))
        XCTAssertEqual(history[1].status, .finished(winner: .first, reason: .targetReached))
    }

    func testDeleteHistoryKeepsActiveGame() throws {
        let repo = try repository()
        var done = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try done.addScore(40, lance: .grande, to: .first, at: date(1))
        try repo.update(done)
        let active = try repo.startGame(teamNames: PerTeam("C", "D"), rules: .standard, now: date(10))

        try repo.deleteHistory()
        XCTAssertTrue(repo.history.isEmpty)
        XCTAssertEqual(try repository().activeGame?.id, active.id)
    }

    func testDeleteSingleHistoryGame() throws {
        let repo = try repository()
        var g1 = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard, now: date(0))
        try g1.addScore(40, lance: .grande, to: .first, at: date(1))
        try repo.update(g1)
        var g2 = try repo.startGame(teamNames: PerTeam("C", "D"), rules: .standard, now: date(10))
        try g2.addScore(40, lance: .grande, to: .second, at: date(11))
        try repo.update(g2)

        try repo.deleteHistoryGame(id: g1.id)
        XCTAssertEqual(repo.history.map(\.id), [g2.id])
    }

    func testDeleteAllDataRemovesEverything() throws {
        let repo = try repository()
        _ = try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard)
        try repo.deleteAllData()
        XCTAssertNil(repo.activeGame)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertNil(try repository().activeGame)
    }

    func testFailedSaveDoesNotChangeInMemoryState() throws {
        struct FailingStore: AppDataStore {
            func load() throws -> AppData { .empty }
            func save(_ data: AppData) throws { throw CocoaError(.fileWriteOutOfSpace) }
            func deleteAll() throws {}
        }
        let repo = try GameRepository(store: FailingStore())
        XCTAssertThrowsError(try repo.startGame(teamNames: PerTeam("A", "B"), rules: .standard))
        XCTAssertNil(repo.activeGame)
    }
}
