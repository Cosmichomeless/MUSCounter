import SwiftUI
import MusCore

/// Marcador principal: dos equipos lado a lado, selector de lance y botones de suma.
/// Si el contenido no cabe (letra grande, horizontal) se desplaza en vez de recortarse.
struct GameView: View {
    let model: AppModel

    var body: some View {
        if let game = model.game {
            ViewThatFits(in: .vertical) {
                content(game)
                ScrollView { content(game).frame(minHeight: 640) }
            }
            .foregroundStyle(Theme.text)
            .musScreen()
            .sheet(item: Binding(get: { model.sheet }, set: { model.sheet = $0 })) { sheet in
                switch sheet {
                case let .amount(team): AmountSheet(model: model, game: game, team: team)
                case .ordago: OrdagoSheet(model: model, game: game)
                }
            }
        }
    }

    private func content(_ game: Game) -> some View {
        VStack(spacing: Metrics.spacingM) {
            header(game)

            if case let .finished(winner, reason) = game.status {
                winnerBanner(game, winner: winner, reason: reason)
            }
            if let message = model.errorMessage {
                ErrorBanner(message: message)
            }

            HStack(spacing: Metrics.spacingM) {
                ForEach(TeamID.allCases, id: \.self) { team in
                    TeamPanel(
                        team: team,
                        name: game.teamNames[team],
                        score: game.state.score[team],
                        goal: game.rules.goal,
                        vacas: game.state.vacas[team],
                        vacasToWin: game.rules.vacasToWin,
                        isLeading: game.state.score[team] > game.state.score[team.other] && game.isInProgress,
                        isWinner: game.state.winner == team,
                        lance: model.selectedLance,
                        enabled: game.isInProgress
                    ) { amount in
                        model.score(amount, to: team)
                    } onMore: {
                        model.sheet = .amount(team)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("\(game.teamNames[team]), \(game.state.score[team]) tantos")
                }
            }

            MusSegmented(
                options: Lance.allCases.map { MusOption(value: $0, label: $0.displayName) },
                selection: Binding(get: { model.selectedLance }, set: { model.selectedLance = $0 })
            )
            .disabled(!game.isInProgress)

            Button("¡Órdago!") { model.sheet = .ordago }
                .buttonStyle(.musDanger)
                .disabled(!game.isInProgress)
        }
        .padding(Metrics.spacingL)
    }

    private func header(_ game: Game) -> some View {
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
    }

    private func winnerBanner(_ game: Game, winner: TeamID, reason: WinReason) -> some View {
        HStack(spacing: Metrics.spacingM) {
            Image(systemName: "trophy.fill").foregroundStyle(Theme.accent).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("¡Victoria de \(game.teamNames[winner])!").font(.headline)
                Text(reason == .ordago ? "Por órdago" : "Objetivo alcanzado")
                    .font(.footnote).foregroundStyle(Theme.mutedText)
            }
            Spacer(minLength: 0)
        }
        .musCard()
        .accessibilityElement(children: .combine)
    }

    private func subtitle(_ game: Game) -> String {
        game.rules.vacasToWin > 1
            ? "Vacas \(game.state.vacas.first) – \(game.state.vacas.second) · a \(game.rules.goal) tantos"
            : "Una vaca a \(game.rules.goal) tantos"
    }
}
