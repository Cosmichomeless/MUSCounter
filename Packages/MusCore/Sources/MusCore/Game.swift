import Foundation

/// Una partida de mus entre dos equipos. Es un registro de acciones: el tanteo se deriva
/// de ellas, por lo que deshacer es exactamente quitar la última acción.
public struct Game: Codable, Equatable, Identifiable, Sendable {
    public static let maxNameLength = 20

    public let id: UUID
    public let createdAt: Date
    public let rules: GameRules
    public private(set) var teamNames: PerTeam<String>
    /// Los cuatro asientos de la mesa en sentido horario, o vacío si la partida no sigue a los jugadores.
    public private(set) var seats: [Seat]
    /// Asiento (0-3) que es mano en la primera mano.
    public let firstMano: Int
    public private(set) var actions: [GameAction]
    public private(set) var state: GameState
    public private(set) var isAbandoned: Bool
    /// Momento en que la partida terminó o se abandonó (nil si sigue en curso).
    public private(set) var endedAt: Date?

    public init(
        id: UUID = UUID(),
        teamNames: PerTeam<String> = PerTeam("Equipo 1", "Equipo 2"),
        rules: GameRules = .standard,
        seats: [Seat] = [],
        firstMano: Int = 0,
        createdAt: Date = Date()
    ) throws {
        guard rules.isValid else { throw ScoringError.invalidRules }
        guard seats.isEmpty || seats.count == Table.seatCount, (0..<Table.seatCount).contains(firstMano) else {
            throw ScoringError.invalidSeating
        }
        // La misma persona no puede ocupar dos asientos: falsearía sus estadísticas.
        let linked = seats.compactMap(\.playerID)
        guard Set(linked).count == linked.count else { throw ScoringError.invalidSeating }
        self.id = id
        self.createdAt = createdAt
        self.rules = rules
        self.teamNames = PerTeam(
            Self.normalizedName(teamNames.first, fallback: "Equipo 1"),
            Self.normalizedName(teamNames.second, fallback: "Equipo 2")
        )
        self.seats = seats.map { Seat(name: Self.normalizedName($0.name, fallback: "Jugador"), playerID: $0.playerID) }
        self.firstMano = firstMano
        self.actions = []
        self.state = .initial
        self.isAbandoned = false
        self.endedAt = nil
    }

    /// Las partidas guardadas antes del esquema 4 no llevan asientos: no siguen a los jugadores.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        rules = try c.decode(GameRules.self, forKey: .rules)
        teamNames = try c.decode(PerTeam<String>.self, forKey: .teamNames)
        seats = try c.decodeIfPresent([Seat].self, forKey: .seats) ?? []
        firstMano = try c.decodeIfPresent(Int.self, forKey: .firstMano) ?? 0
        actions = try c.decode([GameAction].self, forKey: .actions)
        state = try c.decode(GameState.self, forKey: .state)
        isAbandoned = try c.decode(Bool.self, forKey: .isAbandoned)
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
    }

    static func normalizedName(_ name: String, fallback: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : String(trimmed.prefix(maxNameLength))
    }

    public var status: GameStatus {
        if isAbandoned { return .abandoned }
        if let winner = state.winner, let reason = state.winReason {
            return .finished(winner: winner, reason: reason)
        }
        return .inProgress
    }

    public var isInProgress: Bool { status == .inProgress }

    /// `true` si la partida sabe quién se sienta en cada sitio.
    public var tracksPlayers: Bool { !seats.isEmpty }

    /// Asiento que es mano ahora, o `nil` si no se siguen los jugadores.
    public var manoSeat: Int? {
        tracksPlayers ? Table.manoSeat(firstMano: firstMano, handsPlayed: state.handsPlayed) : nil
    }

    public var manoName: String? { manoSeat.map { seats[$0].name } }

    /// Quién era mano justo después de `action` (para el registro de acciones), o `nil` si la acción no
    /// está en la partida o no se siguen los jugadores.
    public func manoName(after action: GameAction) -> String? {
        guard tracksPlayers, let index = actions.firstIndex(where: { $0.id == action.id }) else { return nil }
        let handsPlayed = actions[...index].filter { $0.kind == .nextHand }.count
        return seats[Table.manoSeat(firstMano: firstMano, handsPlayed: handsPlayed)].name
    }
    public var canUndo: Bool { !isAbandoned && !actions.isEmpty }

    // MARK: - Acciones

    /// Apunta `amount` tantos de `lance` al equipo `team`.
    public mutating func addScore(_ amount: Int, lance: Lance, to team: TeamID, at date: Date = Date()) throws {
        try record(GameAction(team: team, kind: .score(lance), amount: amount, date: date))
    }

    /// El equipo `winner` gana un órdago aceptado: gana la vaca en curso.
    public mutating func declareOrdago(winner: TeamID, at date: Date = Date()) throws {
        try record(GameAction(team: winner, kind: .ordago, amount: 0, date: date))
    }

    /// Cierra la mano en curso: la mano pasa al siguiente asiento.
    public mutating func nextHand(at date: Date = Date()) throws {
        guard tracksPlayers else { throw ScoringError.invalidSeating }
        let upcoming = Table.manoSeat(firstMano: firstMano, handsPlayed: state.handsPlayed + 1)
        try record(GameAction(team: Table.team(ofSeat: upcoming), kind: .nextHand, amount: 0, date: date))
    }

    /// Corrige el tanteo de un equipo sumando o restando `delta` tantos.
    public mutating func adjust(team: TeamID, by delta: Int, at date: Date = Date()) throws {
        try record(GameAction(team: team, kind: .adjustment, amount: delta, date: date))
    }

    /// Revierte exactamente la última acción (también si fue la que cerró una vaca o la partida).
    @discardableResult
    public mutating func undo() throws -> GameAction {
        guard !isAbandoned else { throw ScoringError.notInProgress }
        guard let last = actions.last else { throw ScoringError.nothingToUndo }
        actions.removeLast()
        state = try Self.replay(actions, rules: rules)
        endedAt = nil
        return last
    }

    /// Abandona la partida: queda sin ganador y no admite más acciones.
    public mutating func abandon(at date: Date = Date()) throws {
        guard status == .inProgress else { throw ScoringError.notInProgress }
        isAbandoned = true
        endedAt = date
    }

    /// Nueva partida con los mismos equipos y reglas.
    /// Los asientos se conservan y la primera mano sigue la rotación de la partida que acaba de terminar.
    public func rematch(createdAt: Date = Date()) throws -> Game {
        let next = tracksPlayers ? Table.manoSeat(firstMano: firstMano, handsPlayed: state.handsPlayed) : 0
        return try Game(teamNames: teamNames, rules: rules, seats: seats, firstMano: next, createdAt: createdAt)
    }

    // MARK: - Internos

    private mutating func record(_ action: GameAction) throws {
        guard !isAbandoned else { throw ScoringError.notInProgress }
        let next = try state.applying(action, rules: rules)
        actions.append(action)
        state = next
        if next.winner != nil { endedAt = action.date }
    }

    static func replay(_ actions: [GameAction], rules: GameRules) throws -> GameState {
        try actions.reduce(GameState.initial) { try $0.applying($1, rules: rules) }
    }
}
