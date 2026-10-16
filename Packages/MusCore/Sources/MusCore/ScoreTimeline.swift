import Foundation

/// Evolución del tanteo de una partida, acción a acción, para dibujarla.
public struct ScoreTimeline: Equatable, Sendable {
    public struct Point: Equatable, Sendable {
        /// 0 es el inicio de la partida; cada acción añade un paso.
        public let step: Int
        /// Tanteo tras la acción. Si la acción cierra una vaca, es el tanteo con el que se cerró.
        public let score: PerTeam<Int>
        /// Vaca en la que ocurre la acción (0 es la primera).
        public let vaca: Int
        /// `true` si la acción pasa de mano.
        public let isHandBreak: Bool
    }

    public let points: [Point]
    public let goal: Int

    public init(game: Game) {
        goal = game.rules.goal
        var state = GameState.initial
        var vaca = 0
        var result = [Point(step: 0, score: PerTeam(0, 0), vaca: 0, isHandBreak: false)]
        for action in game.actions {
            // Las acciones ya se aplicaron al guardarlas: si no, la partida no existiría.
            guard let next = try? state.applying(action, rules: game.rules) else { break }
            let closed = next.completedVacas.count > state.completedVacas.count
            let score = closed ? (next.completedVacas.last?.finalScore ?? next.score) : next.score
            result.append(Point(step: result.count, score: score, vaca: vaca, isHandBreak: action.kind == .nextHand))
            if closed { vaca += 1 }
            state = next
        }
        points = result
    }
}

/// Desglose de un tanteo en grupos de cinco y tantos sueltos, para dibujarlo como piedras.
public enum Piedras {
    public static let groupSize = 5

    public static func split(_ tantos: Int) -> (groups: Int, singles: Int) {
        let value = max(tantos, 0)
        return (value / groupSize, value % groupSize)
    }
}
