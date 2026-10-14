/// Resultado previsto de una anotación, para mostrar un resumen antes de aplicarla.
public struct ScorePreview: Equatable, Sendable {
    public let team: TeamID
    public let scoreBefore: Int
    /// Tanteo del equipo tras la anotación (el objetivo si gana la vaca).
    public let scoreAfter: Int
    public let closesVaca: Bool
    public let winsGame: Bool
}

extension Game {
    /// Qué pasaría al apuntar `amount` tantos al equipo `team`, o el motivo por el que no se puede.
    public func previewScore(amount: Int, for team: TeamID, lance: Lance = .grande) -> Result<ScorePreview, ScoringError> {
        preview(GameAction(team: team, kind: .score(lance), amount: amount))
    }

    /// Qué pasaría si `winner` gana un órdago, o el motivo por el que no se puede.
    public func previewOrdago(winner: TeamID) -> Result<ScorePreview, ScoringError> {
        preview(GameAction(team: winner, kind: .ordago, amount: 0))
    }

    private func preview(_ action: GameAction) -> Result<ScorePreview, ScoringError> {
        guard !isAbandoned else { return .failure(.notInProgress) }
        do {
            let next = try state.applying(action, rules: rules)
            let closes = next.vacas[action.team] > state.vacas[action.team]
            return .success(ScorePreview(
                team: action.team,
                scoreBefore: state.score[action.team],
                scoreAfter: closes ? rules.goal : next.score[action.team],
                closesVaca: closes,
                winsGame: next.winner != nil
            ))
        } catch let error as ScoringError {
            return .failure(error)
        } catch {
            return .failure(.invalidAmount)
        }
    }
}
