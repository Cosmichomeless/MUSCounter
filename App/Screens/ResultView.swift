import SwiftUI
import MusCore

/// Pantalla de fin de partida: quién ha ganado, por qué y qué hacer a continuación.
struct ResultView: View {
    let model: AppModel

    var body: some View {
        if let game = model.game, case let .finished(winner, reason) = game.status {
            ScrollView {
                VStack(spacing: Metrics.spacingL) {
                    Spacer(minLength: Metrics.spacingXL)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)

                    HStack(spacing: Metrics.spacingS) {
                        TeamMarker(team: winner, size: 22)
                        Text("¡Victoria de \(game.teamNames[winner])!")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                    }

                    Text(whyText(game, reason: reason))
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.center)

                    Text(finalScore(game))
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .accessibilityLabel(finalScoreSpoken(game))

                    if game.rules.vacasToWin > 1 {
                        vacasList(game)
                    }

                    VStack(spacing: Metrics.spacingM) {
                        Button("Revancha") { model.rematch() }.buttonStyle(.musPrimary)
                        Button("Nueva partida") { model.newGameFromResult() }.buttonStyle(.musSecondary)
                        Button("Volver al inicio") { model.goHome() }.buttonStyle(.musSecondary)
                        if game.canUndo {
                            Button {
                                model.undo()
                            } label: {
                                Label("Deshacer la última anotación", systemImage: "arrow.uturn.backward")
                            }
                            .buttonStyle(.musSecondary)
                        }
                    }
                    .padding(.top, Metrics.spacingL)
                }
                .padding(Metrics.spacingL)
            }
            .foregroundStyle(Theme.text)
            .safeAreaInset(edge: .bottom, spacing: 0) { AdSlot(placement: .result) }
            .musScreen()
        }
    }

    private func whyText(_ game: Game, reason: WinReason) -> String {
        switch reason {
        case .ordago: return "Gana por órdago"
        case .targetReached: return "Ha alcanzado los \(game.rules.goal) tantos"
        }
    }

    private func finalScore(_ game: Game) -> String {
        game.rules.vacasToWin > 1
            ? "\(game.state.vacas.first) – \(game.state.vacas.second)"
            : "\(game.state.score.first) – \(game.state.score.second)"
    }

    private func finalScoreSpoken(_ game: Game) -> String {
        let unit = game.rules.vacasToWin > 1 ? "vacas" : "tantos"
        let (a, b) = game.rules.vacasToWin > 1
            ? (game.state.vacas.first, game.state.vacas.second)
            : (game.state.score.first, game.state.score.second)
        return "\(game.teamNames.first) \(a), \(game.teamNames.second) \(b) \(unit)"
    }

    private func vacasList(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            ForEach(Array(game.state.completedVacas.enumerated()), id: \.offset) { index, vaca in
                HStack(spacing: Metrics.spacingM) {
                    TeamMarker(team: vaca.winner)
                    Text("Vaca \(index + 1): \(game.teamNames[vaca.winner])")
                    Spacer(minLength: 0)
                    Text("\(vaca.finalScore.first) – \(vaca.finalScore.second)").monospacedDigit()
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
        .musCard()
    }
}
