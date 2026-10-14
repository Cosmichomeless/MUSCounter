import Foundation

/// Todo lo que la app guarda en el dispositivo: la partida en curso y el historial.
public struct AppData: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var activeGame: Game?
    /// Partidas terminadas o abandonadas, la más reciente primero.
    public var history: [Game]

    public init(schemaVersion: Int = AppData.currentSchemaVersion, activeGame: Game? = nil, history: [Game] = []) {
        self.schemaVersion = schemaVersion
        self.activeGame = activeGame
        self.history = history
    }

    public static let empty = AppData()
}
