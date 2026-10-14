import XCTest
import MusCore
@testable import MUSCounter

@MainActor
private final class SpyFeedback: FeedbackPlayer {
    var haptics: [FeedbackEvent] = []
    var sounds: [FeedbackEvent] = []
    func haptic(_ event: FeedbackEvent) { haptics.append(event) }
    func sound(_ event: FeedbackEvent) { sounds.append(event) }
}

@MainActor
final class FeedbackTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("feedback-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel(_ spy: SpyFeedback) throws -> AppModel {
        let store = FileAppDataStore(fileURL: directory.appendingPathComponent("appdata.json"))
        let model = AppModel(repository: try GameRepository(store: store), feedback: spy)
        model.startGame(with: .standard)
        return model
    }

    func testDefaultsGiveHapticsButNoSound() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.score(2, to: .first)
        XCTAssertEqual(spy.haptics, [.scored])
        XCTAssertEqual(spy.sounds, [])
    }

    func testNothingPlaysWhenBothAreDisabled() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.updatePreferences { $0.hapticsEnabled = false; $0.soundEnabled = false }
        model.score(2, to: .first)
        model.declareOrdago(winner: .second)
        XCTAssertEqual(spy.haptics, [])
        XCTAssertEqual(spy.sounds, [])
    }

    func testSoundPlaysOnlyWhenEnabled() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.updatePreferences { $0.hapticsEnabled = false; $0.soundEnabled = true }
        model.score(1, to: .second)
        XCTAssertEqual(spy.haptics, [])
        XCTAssertEqual(spy.sounds, [.scored])
    }

    func testVictoryPlaysVictoryInsteadOfScoredAndOnlyOnce() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.updatePreferences { $0.soundEnabled = true }
        for _ in 0..<8 { model.score(5, to: .first) }
        XCTAssertEqual(spy.haptics, Array(repeating: .scored, count: 7) + [.victory])
        XCTAssertEqual(spy.sounds, Array(repeating: .scored, count: 7) + [.victory])
        model.score(1, to: .second) // partida terminada: rechazada, sin respuesta
        XCTAssertEqual(spy.haptics.count, 8)
    }

    func testRejectedActionsAndAdjustmentsMakeNoFeedback() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.adjust(.first, by: 1)
        model.adjust(.first, by: -5) // por debajo de cero: rechazado
        model.undo()
        XCTAssertEqual(spy.haptics, [])
    }

    func testScoringStillWorksWithFeedbackDisabled() throws {
        let spy = SpyFeedback()
        let model = try makeModel(spy)
        model.updatePreferences { $0.hapticsEnabled = false }
        model.score(3, to: .first)
        XCTAssertEqual(model.game?.state.score, PerTeam(3, 0))
        XCTAssertNotNil(model.toast)
    }
}
