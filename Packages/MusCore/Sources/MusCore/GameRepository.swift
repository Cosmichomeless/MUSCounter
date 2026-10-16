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
    public var preferences: Preferences { data.preferences }
    public var players: [Player] { data.players }

    /// Guarda las preferencias. Solo afectan a las partidas que se creen a partir de ahora.
    public func updatePreferences(_ preferences: Preferences) throws {
        guard preferences.isValid else { throw ScoringError.invalidRules }
        try commit { $0.preferences = preferences }
    }

    /// Empieza una partida nueva. Si había otra en curso se archiva como abandonada: nunca se pierde en silencio.
    @discardableResult
    public func startGame(
        teamNames: PerTeam<String>, rules: GameRules, seats: [Seat] = [], firstMano: Int = 0, now: Date = Date()
    ) throws -> Game {
        var game = try Game(teamNames: teamNames, rules: rules, seats: seats, firstMano: firstMano, createdAt: now)
        try commit { data in
            if game.tracksPlayers {
                // Cada asiento queda ligado a un jugador guardado (se crea si es nuevo).
                let linked = game.seats.map { Seat(name: $0.name, playerID: Self.player(named: $0.name, in: &data).id) }
                game = try Game(
                    id: game.id, teamNames: game.teamNames, rules: rules,
                    seats: linked, firstMano: firstMano, createdAt: now
                )
            }
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
        let fresh = try Game(
            teamNames: current.teamNames, rules: current.rules, seats: current.seats,
            firstMano: current.firstMano, createdAt: now
        )
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

    /// Quita a una persona de la lista de jugadores. Las partidas guardadas conservan su nombre,
    /// pero dejan de contar para ninguna estadística.
    public func deletePlayer(id: UUID) throws {
        try commit { $0.players.removeAll { $0.id == id } }
    }

    /// Borra todo el historial (la partida en curso se conserva).
    public func deleteHistory() throws {
        try commit { $0.history = [] }
    }

    /// Borra todos los datos locales: historial, partida en curso y preferencias.
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

    /// Jugador con ese nombre (sin distinguir mayúsculas ni acentos); se crea si no existe.
    private static func player(named name: String, in data: inout AppData) -> Player {
        let key = Self.key(name)
        if let existing = data.players.first(where: { Self.key($0.name) == key }) { return existing }
        let created = Player(name: name)
        data.players.append(created)
        return created
    }

    private static func key(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    private static func insertIntoHistory(_ game: Game, in data: inout AppData) {
        data.history.removeAll { $0.id == game.id }
        data.history.append(game)
        data.history.sort { ($0.endedAt ?? $0.createdAt) > ($1.endedAt ?? $1.createdAt) }
    }
}
