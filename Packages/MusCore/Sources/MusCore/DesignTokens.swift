import Foundation

/// Color en sRGB definido por su valor hexadecimal (0xRRGGBB). Vive en el paquete para poder
/// comprobar el contraste con pruebas automáticas.
public struct RGBColor: Equatable, Sendable {
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
    public static func contrastRatio(_ a: RGBColor, _ b: RGBColor) -> Double {
        let (hi, lo) = (max(a.relativeLuminance, b.relativeLuminance), min(a.relativeLuminance, b.relativeLuminance))
        return (hi + 0.05) / (lo + 0.05)
    }
}

/// Paleta semántica de un tema (fieltro de mesa + oro de baraja). Ver docs/prototipo.
public struct Palette: Equatable, Sendable {
    public let background: RGBColor
    public let card: RGBColor
    public let cardRaised: RGBColor
    public let text: RGBColor
    public let mutedText: RGBColor
    public let accent: RGBColor
    public let onAccent: RGBColor
    public let teamFirst: RGBColor
    public let teamSecond: RGBColor
    public let danger: RGBColor

    public static let dark = Palette(
        background: RGBColor(hex: 0x12301F),
        card: RGBColor(hex: 0x194029),
        cardRaised: RGBColor(hex: 0x21523A),
        text: RGBColor(hex: 0xF6F0DC),
        mutedText: RGBColor(hex: 0xA9BFAE),
        accent: RGBColor(hex: 0xE8C56A),
        onAccent: RGBColor(hex: 0x1A1A0F),
        teamFirst: RGBColor(hex: 0xE0735B),
        teamSecond: RGBColor(hex: 0x5AA0E6),
        danger: RGBColor(hex: 0xFF8A80)
    )

    public static let light = Palette(
        background: RGBColor(hex: 0xF3EFE2),
        card: RGBColor(hex: 0xE6E0CC),
        cardRaised: RGBColor(hex: 0xD6CFB6),
        text: RGBColor(hex: 0x16241B),
        mutedText: RGBColor(hex: 0x465B4D),
        accent: RGBColor(hex: 0x9A6B00),
        onAccent: RGBColor(hex: 0xFFFFFF),
        teamFirst: RGBColor(hex: 0xB93F27),
        teamSecond: RGBColor(hex: 0x1D5FB0),
        danger: RGBColor(hex: 0xB3261E)
    )

    public func team(_ team: TeamID) -> RGBColor { team == .first ? teamFirst : teamSecond }
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
}
