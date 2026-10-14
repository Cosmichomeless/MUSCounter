import XCTest
@testable import MusCore

final class DesignTokensTests: XCTestCase {
    func testContrastRatioExtremes() {
        let black = HexColor(hex: 0x000000), white = HexColor(hex: 0xFFFFFF)
        XCTAssertEqual(HexColor.contrastRatio(black, white), 21, accuracy: 0.01)
        XCTAssertEqual(HexColor.contrastRatio(white, white), 1, accuracy: 0.0001)
    }

    private func check(_ p: Palette, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let text: [(String, HexColor, HexColor)] = [
            ("texto/fondo", p.text, p.background),
            ("texto/tarjeta", p.text, p.card),
            ("texto/tarjeta elevada", p.text, p.cardRaised),
            ("secundario/fondo", p.mutedText, p.background),
            ("secundario/tarjeta", p.mutedText, p.card),
            ("secundario/tarjeta elevada", p.mutedText, p.cardRaised),
            ("texto sobre acento", p.onAccent, p.accent),
            ("texto sobre equipo 1 (botón pulsado)", p.onAccent, p.teamFirst),
            ("texto sobre equipo 2 (botón pulsado)", p.onAccent, p.teamSecond),
            ("peligro/fondo", p.danger, p.background),
            ("peligro/tarjeta", p.danger, p.card),
        ]
        for (label, fg, bg) in text {
            XCTAssertGreaterThanOrEqual(HexColor.contrastRatio(fg, bg), 4.5, "\(name) \(label) (texto, WCAG AA)", file: file, line: line)
        }
        let graphics: [(String, HexColor, HexColor)] = [
            ("equipo 1/tarjeta", p.teamFirst, p.card),
            ("equipo 2/tarjeta", p.teamSecond, p.card),
            ("acento/tarjeta", p.accent, p.card),
            ("acento/fondo", p.accent, p.background),
        ]
        for (label, fg, bg) in graphics {
            XCTAssertGreaterThanOrEqual(HexColor.contrastRatio(fg, bg), 3.0, "\(name) \(label) (elementos gráficos, WCAG 1.4.11)", file: file, line: line)
        }
    }

    func testDarkPaletteContrast() { check(.dark, "oscuro") }
    func testLightPaletteContrast() { check(.light, "claro") }

    func testTeamColorsAreDistinct() {
        for palette in [Palette.dark, .light] {
            XCTAssertNotEqual(palette.teamFirst, palette.teamSecond)
            XCTAssertEqual(palette.team(.first), palette.teamFirst)
            XCTAssertEqual(palette.team(.second), palette.teamSecond)
        }
    }

    func testMinTapTargetMeetsAppleGuideline() {
        XCTAssertGreaterThanOrEqual(Metrics.minTapTarget, 44)
        XCTAssertGreaterThanOrEqual(Metrics.minSegmentHeight, 44)
    }
}
