import Foundation

/// Todo lo que la app guarda en el dispositivo: la partida en curso, el historial y las preferencias.
public struct AppData: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var activeGame: Game?
    /// Partidas terminadas o abandonadas, la más reciente primero.
    public var history: [Game]
    public var preferences: Preferences

    public init(
        schemaVersion: Int = AppData.currentSchemaVersion,
        activeGame: Game? = nil,
        history: [Game] = [],
        preferences: Preferences = .standard
    ) {
        self.schemaVersion = schemaVersion
        self.activeGame = activeGame
        self.history = history
        self.preferences = preferences
    }

    public static let empty = AppData()
}
