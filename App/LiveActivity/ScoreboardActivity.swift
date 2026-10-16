import ActivityKit
import Foundation
import MusCore

/// Lo que `AppModel` necesita del marcador en la pantalla de bloqueo. Se puede sustituir en las pruebas.
@MainActor
protocol ScoreboardPublishing {
    /// Muestra o actualiza el marcador de `game`, o lo retira si no hay partida en curso.
    func publish(_ game: Game?)
}

/// No hace nada: pruebas y dispositivos sin Live Activities.
struct NoScoreboard: ScoreboardPublishing {
    func publish(_ game: Game?) {}
}

/// Marcador en la pantalla de bloqueo y en la Isla Dinámica mientras hay una partida en curso.
/// Es una Live Activity local: no usa notificaciones push ni sale ningún dato del iPhone.
@MainActor
final class ScoreboardActivity: ScoreboardPublishing {
    static let preferenceKey = "showLiveScoreboard"

    private var activity: Activity<MarcadorActivityAttributes>?
    private var gameID: UUID?

    func publish(_ game: Game?) {
        let enabled = UserDefaults.standard.object(forKey: Self.preferenceKey) as? Bool ?? true
        guard enabled, ActivityAuthorizationInfo().areActivitiesEnabled, let game, game.isInProgress else {
            end()
            return
        }
        let state = Self.contentState(for: game)
        if let activity, gameID == game.id {
            Task { await activity.update(.init(state: state, staleDate: nil)) }
            return
        }
        end()
        let attributes = MarcadorActivityAttributes(teamNames: [game.teamNames.first, game.teamNames.second])
        activity = try? Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
        gameID = activity == nil ? nil : game.id
    }

    private func end() {
        let ending = activity
        activity = nil
        gameID = nil
        // También se retiran las que hubieran quedado de una sesión anterior de la app.
        Task {
            for old in Activity<MarcadorActivityAttributes>.activities where old.id == ending?.id || ending == nil {
                await old.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    static func contentState(for game: Game) -> MarcadorActivityAttributes.ContentState {
        .init(
            score: [game.state.score.first, game.state.score.second],
            vacas: [game.state.vacas.first, game.state.vacas.second],
            goal: game.rules.goal,
            vacasToWin: game.rules.vacasToWin,
            mano: game.manoName
        )
    }
}
