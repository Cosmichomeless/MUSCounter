import XCTest
import MusCore
@testable import MUSCounter

@MainActor
final class OrdagoAndAmountTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("ordago-\(UUID().uuidString)")
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

    func testOrdagoEndsTheGameForTheWinner() throws {
        let model = try makeModel()
        model.score(10, to: .first)
        model.declareOrdago(winner: .second)
        XCTAssertEqual(model.game?.status, .finished(winner: .second, reason: .ordago))
    }

    func testOrdagoIsRejectedOnceTheGameIsOver() throws {
        let model = try makeModel()
        model.declareOrdago(winner: .first)
        model.declareOrdago(winner: .second)
        XCTAssertEqual(model.game?.status, .finished(winner: .first, reason: .ordago))
        XCTAssertEqual(model.errorMessage, "La partida ya ha terminado.")
    }

    func testSheetsHaveStableIdentifiers() {
        XCTAssertNotEqual(GameSheet.amount(.first).id, GameSheet.amount(.second).id)
        XCTAssertNotEqual(GameSheet.amount(.first).id, GameSheet.ordago.id)
    }
}
