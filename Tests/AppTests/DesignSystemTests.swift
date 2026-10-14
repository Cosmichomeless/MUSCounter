import XCTest
import SwiftUI
import UIKit
import MusCore
@testable import MUSCounter

final class DesignSystemTests: XCTestCase {
    private func resolve(_ color: Color, _ style: UIUserInterfaceStyle) -> HexColor {
        let ui = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = (UInt32((r * 255).rounded()) << 16) | (UInt32((g * 255).rounded()) << 8) | UInt32((b * 255).rounded())
        return HexColor(hex: hex)
    }

    func testThemeFollowsPaletteInBothStyles() {
        XCTAssertEqual(resolve(Theme.background, .dark), Palette.dark.background)
        XCTAssertEqual(resolve(Theme.background, .light), Palette.light.background)
        XCTAssertEqual(resolve(Theme.text, .dark), Palette.dark.text)
        XCTAssertEqual(resolve(Theme.text, .light), Palette.light.text)
        XCTAssertEqual(resolve(Theme.team(.second), .dark), Palette.dark.teamSecond)
        XCTAssertEqual(resolve(Theme.team(.first), .light), Palette.light.teamFirst)
    }

    @MainActor
    func testGalleryRendersWithoutCrashing() {
        for style in [UIUserInterfaceStyle.dark, .light] {
            let host = UIHostingController(rootView: ComponentGallery())
            host.overrideUserInterfaceStyle = style
            host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            host.view.layoutIfNeeded()
            XCTAssertGreaterThan(host.view.bounds.width, 0)
        }
    }
}
