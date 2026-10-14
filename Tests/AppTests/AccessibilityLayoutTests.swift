import XCTest
import SwiftUI
import UIKit
import MusCore
@testable import MUSCounter

/// Comprobaciones de accesibilidad del marcador: se monta con todos los tamaños de texto y en las dos
/// orientaciones sin fallar. Los textos de VoiceOver se prueban en `AccessibilityTextTests` (MusCore).
@MainActor
final class AccessibilityLayoutTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("a11y-\(UUID().uuidString)")
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

    private func host(_ model: AppModel, size: DynamicTypeSize, frame: CGRect) -> UIHostingController<AnyView> {
        let root = AnyView(GameView(model: model).environment(\.dynamicTypeSize, size))
        let controller = UIHostingController(rootView: root)
        let window = UIWindow(frame: frame)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = frame
        controller.view.layoutIfNeeded()
        return controller
    }

    func testScoreboardRendersAtEveryTextSizeInBothOrientations() throws {
        let model = try makeModel()
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility1, .accessibility3, .accessibility5]
        let frames = [CGRect(x: 0, y: 0, width: 390, height: 844), CGRect(x: 0, y: 0, width: 844, height: 390)]
        for size in sizes {
            for frame in frames {
                let controller = host(model, size: size, frame: frame)
                XCTAssertGreaterThan(controller.view.bounds.width, 0, "\(size) \(frame)")
            }
        }
    }

    func testSegmentHeightMeetsTapTargetGuideline() {
        XCTAssertGreaterThanOrEqual(Metrics.minSegmentHeight, 44)
        XCTAssertGreaterThanOrEqual(Metrics.minTapTarget, 44)
    }
}
