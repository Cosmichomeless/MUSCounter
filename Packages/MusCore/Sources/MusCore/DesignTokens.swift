import Foundation

/// Color en sRGB definido por su valor hexadecimal (0xRRGGBB). Vive en el paquete para poder
/// comprobar el contraste con pruebas automáticas.
public struct HexColor: Equatable, Sendable {
    public let hex: UInt32

    public init(hex: UInt32) { self.hex = hex }

    public var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    public var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(hex & 0xFF) / 255 }

    /// Luminancia relativa según WCAG 2.x.
    public var relativeLuminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// Relación de contraste WCAG entre dos colores (de 1 a 21).
    public static func contrastRatio(_ a: HexColor, _ b: HexColor) -> Double {
        let (hi, lo) = (max(a.relativeLuminance, b.relativeLuminance), min(a.relativeLuminance, b.relativeLuminance))
        return (hi + 0.05) / (lo + 0.05)
    }
}

/// Paleta semántica de un tema (fieltro de mesa + oro de baraja). Ver docs/prototipo.
public struct Palette: Equatable, Sendable {
    public let background: HexColor
    public let card: HexColor
    public let cardRaised: HexColor
    public let text: HexColor
    public let mutedText: HexColor
    public let accent: HexColor
    public let onAccent: HexColor
    public let teamFirst: HexColor
    public let teamSecond: HexColor
    public let danger: HexColor

    public static let dark = Palette(
        background: HexColor(hex: 0x12301F),
        card: HexColor(hex: 0x194029),
        cardRaised: HexColor(hex: 0x21523A),
        text: HexColor(hex: 0xF6F0DC),
        mutedText: HexColor(hex: 0xA9BFAE),
        accent: HexColor(hex: 0xE8C56A),
        onAccent: HexColor(hex: 0x1A1A0F),
        teamFirst: HexColor(hex: 0xE0735B),
        teamSecond: HexColor(hex: 0x5AA0E6),
        danger: HexColor(hex: 0xFF8A80)
    )

    public static let light = Palette(
        background: HexColor(hex: 0xF3EFE2),
        card: HexColor(hex: 0xE6E0CC),
        cardRaised: HexColor(hex: 0xD6CFB6),
        text: HexColor(hex: 0x16241B),
        mutedText: HexColor(hex: 0x465B4D),
        accent: HexColor(hex: 0x9A6B00),
        onAccent: HexColor(hex: 0xFFFFFF),
        teamFirst: HexColor(hex: 0xB93F27),
        teamSecond: HexColor(hex: 0x1D5FB0),
        danger: HexColor(hex: 0xB3261E)
    )

    public func team(_ team: TeamID) -> HexColor { team == .first ? teamFirst : teamSecond }
}

/// Medidas compartidas de la interfaz, en puntos.
public enum Metrics {
    public static let spacingXS: Double = 4
    public static let spacingS: Double = 8
    public static let spacingM: Double = 12
    public static let spacingL: Double = 16
    public static let spacingXL: Double = 24
    public static let cornerRadius: Double = 18
    /// Alto mínimo de cualquier control tocable (Apple recomienda 44).
    public static let minTapTarget: Double = 52
    /// Alto mínimo de cada opción de un selector segmentado (sigue por encima de los 44 pt de Apple).
    public static let minSegmentHeight: Double = 48
}
