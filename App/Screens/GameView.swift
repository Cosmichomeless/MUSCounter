import SwiftUI
import MusCore

/// Marcador principal: dos equipos lado a lado, selector de lance y botones de suma.
/// Si el contenido no cabe (letra grande, horizontal) se desplaza en vez de recortarse.
struct GameView: View {
    let model: AppModel
    @State private var confirmation: GameConfirmation?

    var body: some View {
        if let game = model.game {
            ViewThatFits(in: .vertical) {
                content(game)
                ScrollView { content(game).frame(minHeight: 640) }
            }
            .foregroundStyle(Theme.text)
            .musScreen()
            .overlay(alignment: .top) {
                if let toast = model.toast {
                    UndoToast(message: toast.message) { model.undo() }
                        .padding(.horizontal, Metrics.spacingL)
                        .padding(.top, Metrics.spacingS)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: toast.id) {
                            try? await Task.sleep(for: .seconds(4))
                            if model.toast?.id == toast.id { model.toast = nil }
                        }
                }
            }
            .animation(.easeOut(duration: 0.2), value: model.toast)
            .confirmationDialog(
                confirmation?.title ?? "",
                isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
                titleVisibility: .visible
            ) {
                if let confirmation {
                    Button(confirmation.confirmLabel, role: .destructive) {
                        switch confirmation {
                        case .restart: model.restartGame()
                        case .abandon: model.abandonGame()
                        case .delete: model.deleteGame()
                        }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(confirmation?.message ?? "")
            }
            .sheet(item: Binding(get: { model.sheet }, set: { model.sheet = $0 })) { sheet in
                switch sheet {
                case let .amount(team): AmountSheet(model: model, game: game, team: team)
                case .ordago: OrdagoSheet(model: model, game: game)
                case .log: ActionLogSheet(game: game)
                case .adjust: AdjustSheet(model: model, game: game)
                case .menu:
                    GameMenuSheet(
                        onAdjust: { model.sheet = .adjust },
                        onConfirm: { choice in
                            model.sheet = nil
                            confirmation = choice
                        }
                    )
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

            HStack(spacing: Metrics.spacingM) {
                Button { model.undo() } label: {
                    Label("Deshacer", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.musSecondary)
                .disabled(!game.canUndo)

                Button("¡Órdago!") { model.sheet = .ordago }
                    .buttonStyle(.musDanger)
                    .disabled(!game.isInProgress)
            }
        }
        .padding(Metrics.spacingL)
    }

    private func iconButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func header(_ game: Game) -> some View {
        HStack {
            Button("Salir") { model.leaveGame() }
                .buttonStyle(.musSecondary)
                .fixedSize(horizontal: true, vertical: false)
            Text(subtitle(game))
                .font(.footnote)
                .foregroundStyle(Theme.mutedText)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            iconButton("clock.arrow.circlepath", "Acciones recientes") { model.sheet = .log }
            if game.isInProgress {
                iconButton("ellipsis", "Menú de la partida") { model.sheet = .menu }
            }
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
