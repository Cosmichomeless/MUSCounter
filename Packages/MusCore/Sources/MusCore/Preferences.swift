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
    /// Vibración suave al apuntar tantos y al ganar. Activada de forma predeterminada.
    public var hapticsEnabled: Bool
    /// Sonido breve al apuntar tantos y al ganar. Desactivado de forma predeterminada: en la mesa
    /// se juega con ruido y conversación, y se activa solo si se quiere.
    public var soundEnabled: Bool

    public init(
        goal: Int = GameRules.standard.goal,
        vacasToWin: Int = GameRules.standard.vacasToWin,
        theme: ThemePreference = .system,
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = false
    ) {
        self.goal = goal
        self.vacasToWin = vacasToWin
        self.theme = theme
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
    }

    /// Los ficheros anteriores al esquema 3 no tienen háptica ni sonido: se usan los valores predeterminados.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            goal: try c.decode(Int.self, forKey: .goal),
            vacasToWin: try c.decode(Int.self, forKey: .vacasToWin),
            theme: try c.decode(ThemePreference.self, forKey: .theme),
            hapticsEnabled: try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true,
            soundEnabled: try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? false
        )
    }

    public var rules: GameRules { GameRules(goal: goal, vacasToWin: vacasToWin) }

    public var isValid: Bool { rules.isValid }
}
