import SwiftUI
import UIKit
import MusCore

extension Color {
    init(_ rgb: RGBColor) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1)
    }

    /// Color que cambia solo entre tema claro y oscuro.
    init(light: RGBColor, dark: RGBColor) {
        self.init(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 1)
        })
    }
}

/// Colores semánticos de la app. Los valores viven en `Palette` (MusCore), donde se comprueba su contraste.
enum Theme {
    static let background = Color(light: Palette.light.background, dark: Palette.dark.background)
    static let card = Color(light: Palette.light.card, dark: Palette.dark.card)
    static let cardRaised = Color(light: Palette.light.cardRaised, dark: Palette.dark.cardRaised)
    static let text = Color(light: Palette.light.text, dark: Palette.dark.text)
    static let mutedText = Color(light: Palette.light.mutedText, dark: Palette.dark.mutedText)
    static let accent = Color(light: Palette.light.accent, dark: Palette.dark.accent)
    static let onAccent = Color(light: Palette.light.onAccent, dark: Palette.dark.onAccent)
    static let danger = Color(light: Palette.light.danger, dark: Palette.dark.danger)

    static func team(_ team: TeamID) -> Color {
        Color(light: Palette.light.team(team), dark: Palette.dark.team(team))
    }
}
