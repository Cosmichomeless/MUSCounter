import SwiftUI
import MusCore

/// Marcador de la partida. En esta versión muestra equipos, tanteo y vacas;
/// los controles de anotación llegan con el marcador principal.
struct GameView: View {
    let model: AppModel

    var body: some View {
        if let game = model.game {
            VStack(spacing: Metrics.spacingL) {
                HStack {
                    Button("Salir") { model.leaveGame() }
                        .buttonStyle(.musSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    Text(subtitle(game))
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.trailing)
                }
                HStack(spacing: Metrics.spacingM) {
                    ForEach(TeamID.allCases, id: \.self) { team in
                        VStack(spacing: Metrics.spacingS) {
                            HStack(spacing: Metrics.spacingS) {
                                TeamMarker(team: team)
                                Text(game.teamNames[team]).font(.headline).lineLimit(1)
                            }
                            ScoreText(value: game.state.score[team])
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .musCard()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(game.teamNames[team]): \(game.state.score[team]) tantos")
                    }
                }
            }
            .padding(Metrics.spacingL)
            .foregroundStyle(Theme.text)
            .musScreen()
        }
    }

    private func subtitle(_ game: Game) -> String {
        game.rules.vacasToWin > 1
            ? "Vacas \(game.state.vacas.first) – \(game.state.vacas.second) · a \(game.rules.goal) tantos"
            : "Una vaca a \(game.rules.goal) tantos"
    }
}
