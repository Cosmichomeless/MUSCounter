import Foundation

/// Mantiene la partida en curso y el historial, y los persiste tras cada cambio.
/// Cada cambio se guarda antes de publicarse: si falla el guardado, el estado en memoria no cambia.
public final class GameRepository {
    private let store: AppDataStore
    public private(set) var data: AppData

    public init(store: AppDataStore) throws {
        self.store = store
        self.data = try store.load()
    }

    public var activeGame: Game? { data.activeGame }
    public var history: [Game] { data.history }

    /// Empieza una partida nueva. Si había otra en curso se archiva como abandonada: nunca se pierde en silencio.
    @discardableResult
    public func startGame(
        teamNames: PerTeam<String>, rules: GameRules, now: Date = Date()
    ) throws -> Game {
        let game = try Game(teamNames: teamNames, rules: rules, createdAt: now)
        try commit { data in
            if var previous = data.activeGame {
                try? previous.abandon(at: now)
                Self.insertIntoHistory(previous, in: &data)
            }
            data.activeGame = game
        }
        return game
    }

    /// Guarda el estado de una partida tras una acción.
    /// Si terminó o se abandonó pasa al historial (una sola vez, por `id`); si volvió a estar en curso
    /// (por ejemplo, al deshacer la acción ganadora) vuelve a ser la partida activa.
    public func update(_ game: Game) throws {
        try commit { data in
            data.history.removeAll { $0.id == game.id }
            if game.status == .inProgress {
                data.activeGame = game
            } else {
                if data.activeGame?.id == game.id { data.activeGame = nil }
                Self.insertIntoHistory(game, in: &data)
            }
        }
    }

    /// Reinicia la partida en curso: mismos equipos y reglas, tanteo a cero. La anterior se descarta
    /// (no pasa al historial).
    @discardableResult
    public func restartActiveGame(now: Date = Date()) throws -> Game {
        guard let current = data.activeGame else { throw ScoringError.notInProgress }
        let fresh = try Game(teamNames: current.teamNames, rules: current.rules, createdAt: now)
        try commit { $0.activeGame = fresh }
        return fresh
    }

    /// Descarta la partida en curso sin guardarla.
    public func discardActiveGame() throws {
        try commit { $0.activeGame = nil }
    }

    public func deleteHistoryGame(id: UUID) throws {
        try commit { $0.history.removeAll { $0.id == id } }
    }

    /// Borra todo el historial (la partida en curso se conserva).
    public func deleteHistory() throws {
        try commit { $0.history = [] }
    }

    /// Borra todos los datos locales: historial y partida en curso.
    public func deleteAllData() throws {
        try store.deleteAll()
        data = .empty
    }

    // MARK: - Internos

    private func commit(_ change: (inout AppData) throws -> Void) throws {
        var next = data
        try change(&next)
        try store.save(next)
        data = next
    }

    private static func insertIntoHistory(_ game: Game, in data: inout AppData) {
        data.history.removeAll { $0.id == game.id }
        data.history.append(game)
        data.history.sort { ($0.endedAt ?? $0.createdAt) > ($1.endedAt ?? $1.createdAt) }
    }
}
