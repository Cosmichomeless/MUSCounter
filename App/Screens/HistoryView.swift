import SwiftUI
import MusCore

/// Textos del historial. Aparte de la vista para poder probarlos sin pintar nada.
enum HistoryText {
    static func score(_ game: Game) -> String {
        let (first, second) = game.rules.vacasToWin > 1
            ? (game.state.vacas.first, game.state.vacas.second)
            : (game.state.score.first, game.state.score.second)
        return "\(game.teamNames.first) \(first) – \(second) \(game.teamNames.second)"
    }

    /// Qué se está contando: tantos o vacas, para que el número no se malinterprete.
    static func scoreUnit(_ game: Game) -> String {
        game.rules.vacasToWin > 1 ? "vacas" : "tantos"
    }

    static func result(_ game: Game) -> String {
        switch game.status {
        case .inProgress:
            return "Pendiente de continuar"
        case .abandoned:
            return "Abandonada"
        case let .finished(winner, reason):
            let name = winner == .first ? game.teamNames.first : game.teamNames.second
            return "Ganó \(name) · \(reason == .ordago ? "Órdago" : "Tantos")"
        }
    }

    static func rules(_ game: Game) -> String {
        let vacas = game.rules.vacasToWin == 1 ? "sin vacas" : (game.rules.vacasToWin == 2 ? "2 de 3" : "3 de 5")
        return "A \(game.rules.goal) tantos · \(vacas)"
    }

    static func date(
        _ date: Date,
        locale: Locale = Locale(identifier: "es"),
        timeZone: TimeZone = .current
    ) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, timeZone: timeZone)
                .day().month(.abbreviated).year().hour().minute()
        )
    }

    static func date(of game: Game) -> String {
        date(game.endedAt ?? game.createdAt)
    }

    static func accessibilityLabel(_ game: Game) -> String {
        "\(score(game)) \(scoreUnit(game)). \(result(game)). \(rules(game)). \(date(of: game))"
    }
}

struct HistoryView: View {
    let model: AppModel
    @State private var gameToDelete: Game?
    @State private var confirmDeleteAll = false
    @State private var detailGame: Game?
    @State private var tab: Tab = .games

    private enum Tab: Hashable { case games, players }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Historial").font(.title.bold())
                Spacer()
                Button {
                    model.backToHome()
                } label: {
                    Image(systemName: "xmark").font(.title3.weight(.bold))
                        .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar historial")
            }
            .padding(Metrics.spacingL)

            MusSegmented(
                options: [MusOption(value: Tab.games, label: "Partidas"), MusOption(value: Tab.players, label: "Jugadores")],
                selection: $tab,
                title: "Historial"
            )
            .padding(.horizontal, Metrics.spacingL)
            .padding(.bottom, Metrics.spacingM)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingM) {
                    if let message = model.errorMessage {
                        ErrorBanner(message: message)
                    }
                    if tab == .players {
                        PlayersStatsView(model: model)
                    } else {
                        if let game = model.game, game.isInProgress {
                            activeCard(game)
                        }
                        if model.history.isEmpty {
                            Text("Todavía no hay partidas guardadas.")
                                .foregroundStyle(Theme.mutedText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, Metrics.spacingL)
                        } else {
                            ForEach(model.history) { row($0) }
                        }
                    }
                }
                .padding(.horizontal, Metrics.spacingL)
            }

            if tab == .games, !model.history.isEmpty {
                Button("Borrar todo el historial") { confirmDeleteAll = true }
                    .buttonStyle(.musDanger)
                    .padding(Metrics.spacingL)
            }
        }
        .foregroundStyle(Theme.text)
        .safeAreaInset(edge: .bottom, spacing: 0) { AdSlot(placement: .history) }
        .musScreen()
        .sheet(item: $detailGame) { GameDetailView(game: $0) }
        .confirmationDialog(
            "¿Borrar la partida?",
            isPresented: Binding(get: { gameToDelete != nil }, set: { if !$0 { gameToDelete = nil } }),
            titleVisibility: .visible,
            presenting: gameToDelete
        ) { game in
            Button("Borrar partida", role: .destructive) { model.deleteHistoryGame(game.id) }
            Button("Cancelar", role: .cancel) {}
        } message: { game in
            Text(HistoryText.score(game))
        }
        .confirmationDialog(
            "¿Borrar todo el historial?",
            isPresented: $confirmDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Borrar todo", role: .destructive) { model.deleteHistory() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrarán todas las partidas guardadas. La partida en curso no se toca. No se puede deshacer.")
        }
    }

    private func activeCard(_ game: Game) -> some View {
        HStack(spacing: Metrics.spacingM) {
            VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                Text("Pendiente de continuar").font(.headline)
                Text("\(game.teamNames.first) \(game.state.score.first) – \(game.state.score.second) \(game.teamNames.second)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer(minLength: 0)
            Button("Continuar") { model.resumeGame() }
                .buttonStyle(.musPrimary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .musCard()
        .accessibilityElement(children: .contain)
    }

    private func row(_ game: Game) -> some View {
        HStack(spacing: Metrics.spacingM) {
            VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                Text(HistoryText.score(game)).font(.headline)
                Text(HistoryText.result(game)).font(.subheadline)
                Text("\(HistoryText.rules(game)) · \(HistoryText.date(of: game))")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(HistoryText.accessibilityLabel(game))
            .contentShape(Rectangle())
            .onTapGesture { detailGame = game }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Abre el resumen y la gráfica")

            Button {
                gameToDelete = game
            } label: {
                Image(systemName: "trash").font(.title3)
                    .foregroundStyle(Theme.danger)
                    .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Borrar partida")
        }
        .musCard()
    }
}
