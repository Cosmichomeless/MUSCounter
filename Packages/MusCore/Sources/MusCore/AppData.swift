import Foundation

/// Todo lo que la app guarda en el dispositivo: la partida en curso, el historial y las preferencias.
public struct AppData: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 4

    public var schemaVersion: Int
    public var activeGame: Game?
    /// Partidas terminadas o abandonadas, la más reciente primero.
    public var history: [Game]
    public var preferences: Preferences
    /// Personas que han jugado, para reconocerlas entre partidas y calcular sus estadísticas.
    public var players: [Player]

    public init(
        schemaVersion: Int = AppData.currentSchemaVersion,
        activeGame: Game? = nil,
        history: [Game] = [],
        preferences: Preferences = .standard,
        players: [Player] = []
    ) {
        self.schemaVersion = schemaVersion
        self.activeGame = activeGame
        self.history = history
        self.preferences = preferences
        self.players = players
    }

    public static let empty = AppData()
}
