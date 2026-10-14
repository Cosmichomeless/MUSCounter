import Foundation

/// Tema visual elegido por la persona. `system` sigue el modo claro u oscuro del iPhone.
public enum ThemePreference: String, Codable, CaseIterable, Sendable {
    case system, light, dark

    public var displayName: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }
}

/// Opciones que se recuerdan entre sesiones. Solo se usan como valores iniciales de las partidas
/// nuevas: cada partida guarda sus propias reglas, así que cambiar una preferencia no altera
/// ninguna partida ya empezada o guardada.
public struct Preferences: Codable, Equatable, Sendable {
    public static let standard = Preferences()

    /// Tantos que hay que alcanzar para ganar una vaca.
    public var goal: Int
    /// Vacas que hay que ganar para ganar la partida (1 = sin vacas).
    public var vacasToWin: Int
    public var theme: ThemePreference

    public init(
        goal: Int = GameRules.standard.goal,
        vacasToWin: Int = GameRules.standard.vacasToWin,
        theme: ThemePreference = .system
    ) {
        self.goal = goal
        self.vacasToWin = vacasToWin
        self.theme = theme
    }

    public var rules: GameRules { GameRules(goal: goal, vacasToWin: vacasToWin) }

    public var isValid: Bool { rules.isValid }
}
