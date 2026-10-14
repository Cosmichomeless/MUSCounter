import Foundation

public enum ActionKind: Codable, Equatable, Sendable {
    case score(Lance)
    case ordago
    case adjustment
}

/// Una acción registrada en la partida. `amount` es 0 para el órdago y puede ser negativo en un ajuste.
public struct GameAction: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let team: TeamID
    public let kind: ActionKind
    public let amount: Int
    public let date: Date

    public init(id: UUID = UUID(), team: TeamID, kind: ActionKind, amount: Int, date: Date = Date()) {
        self.id = id
        self.team = team
        self.kind = kind
        self.amount = amount
        self.date = date
    }
}

public enum WinReason: String, Codable, Sendable {
    case targetReached
    case ordago
}

public struct VacaResult: Codable, Equatable, Sendable {
    public let winner: TeamID
    public let finalScore: PerTeam<Int>
    public let reason: WinReason
}

/// Estado derivado de aplicar, en orden, las acciones de una partida.
public struct GameState: Codable, Equatable, Sendable {
    public var score = PerTeam(0, 0)
    public var vacas = PerTeam(0, 0)
    public var completedVacas: [VacaResult] = []
    public var winner: TeamID?
    public var winReason: WinReason?

    public static let initial = GameState()

    /// Devuelve el estado tras aplicar `action`. No muta el estado actual.
    func applying(_ action: GameAction, rules: GameRules) throws -> GameState {
        guard winner == nil else { throw ScoringError.notInProgress }
        var next = self
        let team = action.team
        let vacaReason: WinReason
        var vacaWon = false

        switch action.kind {
        case .score:
            guard action.amount >= 1, action.amount <= rules.goal else { throw ScoringError.invalidAmount }
            next.score[team] = min(score[team] + action.amount, rules.goal)
            vacaWon = next.score[team] == rules.goal
            vacaReason = .targetReached
        case .adjustment:
            guard action.amount != 0, abs(action.amount) <= rules.goal else { throw ScoringError.invalidAmount }
            let value = score[team] + action.amount
            guard value >= 0 else { throw ScoringError.belowZero }
            next.score[team] = min(value, rules.goal)
            vacaWon = next.score[team] == rules.goal
            vacaReason = .targetReached
        case .ordago:
            next.score[team] = rules.goal
            vacaWon = true
            vacaReason = .ordago
        }

        if vacaWon {
            next.vacas[team] += 1
            next.completedVacas.append(VacaResult(winner: team, finalScore: next.score, reason: vacaReason))
            if next.vacas[team] >= rules.vacasToWin {
                next.winner = team
                next.winReason = vacaReason
            } else {
                next.score = PerTeam(0, 0)
            }
        }
        return next
    }
}

public enum GameStatus: Codable, Equatable, Sendable {
    case inProgress
    case finished(winner: TeamID, reason: WinReason)
    case abandoned
}
