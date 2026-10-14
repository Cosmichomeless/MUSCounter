/// Los cinco lances de una mano de mus.
public enum Lance: String, Codable, CaseIterable, Sendable {
    case grande, chica, pares, juego, punto

    public var displayName: String {
        switch self {
        case .grande: return "Grande"
        case .chica: return "Chica"
        case .pares: return "Pares"
        case .juego: return "Juego"
        case .punto: return "Punto"
        }
    }

    /// Cantidades que la interfaz ofrece con un toque (ver docs/reglas-de-tanteo.md §4).
    public var quickAmounts: [Int] {
        switch self {
        case .juego: return [2, 3, 4, 5, 6]
        default: return [1, 2, 3, 4, 5]
        }
    }
}

/// Variantes configurables de una partida (ver docs/reglas-de-tanteo.md §3).
public struct GameRules: Codable, Equatable, Sendable {
    public static let allowedGoals = [30, 40]
    public static let allowedVacasToWin = [1, 2, 3]
    public static let standard = GameRules(goal: 40, vacasToWin: 1)

    /// Tantos que hay que alcanzar para ganar una vaca.
    public var goal: Int
    /// Vacas que hay que ganar para ganar la partida (1 = sin vacas).
    public var vacasToWin: Int

    public init(goal: Int = 40, vacasToWin: Int = 1) {
        self.goal = goal
        self.vacasToWin = vacasToWin
    }

    public var isValid: Bool {
        Self.allowedGoals.contains(goal) && Self.allowedVacasToWin.contains(vacasToWin)
    }
}

public enum ScoringError: Error, Equatable, Sendable {
    /// La partida ya terminó o fue abandonada.
    case notInProgress
    /// La cantidad no es válida (menor que 1, mayor que el objetivo, o ajuste a 0).
    case invalidAmount
    /// El ajuste dejaría el tanteo por debajo de 0.
    case belowZero
    /// No hay ninguna acción que deshacer.
    case nothingToUndo
    /// Las reglas no están entre las variantes admitidas.
    case invalidRules
}
