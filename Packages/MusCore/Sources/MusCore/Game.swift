import Foundation

/// Una partida de mus entre dos equipos. Es un registro de acciones: el tanteo se deriva
/// de ellas, por lo que deshacer es exactamente quitar la última acción.
public struct Game: Codable, Equatable, Identifiable, Sendable {
    public static let maxNameLength = 20

    public let id: UUID
    public let createdAt: Date
    public let rules: GameRules
    public private(set) var teamNames: PerTeam<String>
    public private(set) var actions: [GameAction]
    public private(set) var state: GameState
    public private(set) var isAbandoned: Bool
    /// Momento en que la partida terminó o se abandonó (nil si sigue en curso).
    public private(set) var endedAt: Date?

    public init(
        id: UUID = UUID(),
        teamNames: PerTeam<String> = PerTeam("Equipo 1", "Equipo 2"),
        rules: GameRules = .standard,
        createdAt: Date = Date()
    ) throws {
        guard rules.isValid else { throw ScoringError.invalidRules }
        self.id = id
        self.createdAt = createdAt
        self.rules = rules
        self.teamNames = PerTeam(
            Self.normalizedName(teamNames.first, fallback: "Equipo 1"),
            Self.normalizedName(teamNames.second, fallback: "Equipo 2")
        )
        self.actions = []
        self.state = .initial
        self.isAbandoned = false
        self.endedAt = nil
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
    public func rematch(createdAt: Date = Date()) throws -> Game {
        try Game(teamNames: teamNames, rules: rules, createdAt: createdAt)
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
