import SwiftUI
import MusCore

/// Marcador principal: dos equipos lado a lado, selector de lance y botones de suma.
/// En vertical apila los controles; en horizontal (altura compacta) reparte tres columnas —equipo, lances, equipo—
/// para que todo quepa sin desplazarse. Si aun así no cabe (letra muy grande) se desplaza en vez de recortarse.
struct GameView: View {
    let model: AppModel
    @State private var confirmation: GameConfirmation?
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLargeText: Bool { dynamicTypeSize.isAccessibilitySize }
    /// El diseño apaisado de tres columnas solo cabe con letra normal; con letra de accesibilidad se usa
    /// el diseño vertical (que se desplaza) para que ningún control quede recortado ni oculto.
    private var isLandscape: Bool { verticalSizeClass == .compact && !isLargeText }

    var body: some View {
        if let game = model.game {
            ViewThatFits(in: .vertical) {
                content(game)
                ScrollView { content(game).frame(minHeight: isLandscape ? 340 : 640) }
            }
            .foregroundStyle(Theme.text)
            .musScreen()
            .overlay(alignment: .top) {
                if let toast = model.toast {
                    UndoToast(message: toast.message) { model.undo() }
                        .padding(.horizontal, Metrics.spacingL)
                        .padding(.top, Metrics.spacingS)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .task(id: toast.id) {
                            try? await Task.sleep(for: .seconds(4))
                            if model.toast?.id == toast.id { model.toast = nil }
                        }
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: model.toast)
            .onChange(of: model.toast?.id) { _, id in
                guard id != nil, let game = model.game else { return }
                announce(for: game)
            }
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

    @ViewBuilder private func content(_ game: Game) -> some View {
        if isLandscape {
            landscapeContent(game)
        } else {
            portraitContent(game)
        }
    }

    private func teamPanel(_ game: Game, _ team: TeamID) -> some View {
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
            enabled: game.isInProgress,
            compact: isLandscape
        ) { amount in
            model.score(amount, to: team)
        } onMore: {
            model.sheet = .amount(team)
        }
    }

    /// Anuncia a VoiceOver el resultado de una anotación (la ventana de aviso desaparece sola).
    private func announce(for game: Game) {
        var text = model.toast?.message ?? ""
        text += ". " + AccessibilityText.scoreboard(names: game.teamNames, score: game.state.score)
        AccessibilityNotification.Announcement(text).post()
    }

    private func lanceBinding() -> Binding<Lance> {
        Binding(get: { model.selectedLance }, set: { model.selectedLance = $0 })
    }

    private func undoButton(_ game: Game) -> some View {
        Button { model.undo() } label: {
            Label("Deshacer", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.musSecondary)
        .disabled(!game.canUndo)
    }

    private func ordagoButton(_ game: Game) -> some View {
        Button("¡Órdago!") { model.sheet = .ordago }
            .buttonStyle(.musDanger)
            .disabled(!game.isInProgress)
    }

    /// Horizontal: barra superior con las acciones, y debajo equipo | lances | equipo.
    private func landscapeContent(_ game: Game) -> some View {
        VStack(spacing: Metrics.spacingS) {
            HStack(spacing: Metrics.spacingS) {
                Button("Salir") { model.leaveGame() }
                    .buttonStyle(.musSecondary)
                    .fixedSize(horizontal: true, vertical: false)
                Text(subtitle(game))
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                undoButton(game).frame(maxWidth: 170)
                ordagoButton(game).frame(maxWidth: 150)
                iconButton("clock.arrow.circlepath", "Acciones recientes") { model.sheet = .log }
                if game.isInProgress {
                    iconButton("ellipsis", "Menú de la partida") { model.sheet = .menu }
                }
            }

            HStack(spacing: Metrics.spacingS) {
                teamPanel(game, .first)

                VStack(spacing: Metrics.spacingS) {
                    if case let .finished(winner, reason) = game.status {
                        winnerBanner(game, winner: winner, reason: reason)
                    } else {
                        MusSegmented(
                            options: Lance.allCases.map { MusOption(value: $0, label: $0.displayName) },
                            selection: lanceBinding(),
                            axis: .vertical,
                            title: "Lance"
                        )
                        if game.tracksPlayers, game.isInProgress { manoBar(game, compact: true) }
                    }
                }
                .frame(width: 150)

                teamPanel(game, .second)
            }
        }
        .padding(.horizontal, Metrics.spacingM)
        .padding(.vertical, Metrics.spacingS)
        .overlay(alignment: .bottom) {
            if let message = model.errorMessage {
                ErrorBanner(message: message).padding(Metrics.spacingM)
            }
        }
    }

    private func portraitContent(_ game: Game) -> some View {
        VStack(spacing: Metrics.spacingM) {
            header(game)

            if case let .finished(winner, reason) = game.status {
                winnerBanner(game, winner: winner, reason: reason)
            }
            if let message = model.errorMessage {
                ErrorBanner(message: message)
            }

            panels(game)

            if game.tracksPlayers, game.isInProgress { manoBar(game) }

            MusSegmented(
                options: Lance.allCases.map { MusOption(value: $0, label: $0.displayName) },
                selection: lanceBinding(),
                title: "Lance"
            )
            .disabled(!game.isInProgress)

            HStack(spacing: Metrics.spacingM) {
                undoButton(game)
                ordagoButton(game)
            }
        }
        .padding(Metrics.spacingL)
    }

    /// Los dos paneles, uno junto al otro; con letra de accesibilidad, uno encima del otro.
    @ViewBuilder private func panels(_ game: Game) -> some View {
        if isLargeText {
            VStack(spacing: Metrics.spacingM) {
                ForEach(TeamID.allCases, id: \.self) { teamPanel(game, $0) }
            }
        } else {
            HStack(spacing: Metrics.spacingM) {
                ForEach(TeamID.allCases, id: \.self) { teamPanel(game, $0) }
            }
        }
    }

    /// Quién es mano y el botón para pasar la mano al siguiente jugador al terminar la mano.
    @ViewBuilder private func manoBar(_ game: Game, compact: Bool = false) -> some View {
        let name = game.manoName ?? ""
        if compact {
            VStack(spacing: Metrics.spacingXS) {
                Text("Mano: \(name)")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button("Siguiente mano") { model.nextHand() }
                    .buttonStyle(.musSecondary)
            }
        } else {
            HStack(spacing: Metrics.spacingM) {
                Label {
                    Text("Mano: \(name)").font(.subheadline.weight(.semibold)).lineLimit(2)
                } icon: {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Theme.accent)
                }
                Spacer(minLength: 0)
                Button("Siguiente mano") { model.nextHand() }
                    .buttonStyle(.musSecondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .musCard()
            .accessibilityElement(children: .contain)
        }
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

    @ViewBuilder private func header(_ game: Game) -> some View {
        if isLargeText {
            VStack(spacing: Metrics.spacingS) {
                HStack {
                    Button("Salir") { model.leaveGame() }
                        .buttonStyle(.musSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 0)
                    headerIcons(game)
                }
                Text(subtitle(game))
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
            }
        } else {
            HStack {
                Button("Salir") { model.leaveGame() }
                    .buttonStyle(.musSecondary)
                    .fixedSize(horizontal: true, vertical: false)
                Text(subtitle(game))
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                headerIcons(game)
            }
        }
    }

    @ViewBuilder private func headerIcons(_ game: Game) -> some View {
        iconButton("clock.arrow.circlepath", "Acciones recientes") { model.sheet = .log }
        if game.isInProgress {
            iconButton("ellipsis", "Menú de la partida") { model.sheet = .menu }
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
        .accessibilityAddTraits(.isHeader)
        .onAppear { AccessibilityNotification.Announcement(AccessibilityText.victory(winner: game.teamNames[winner], reason: reason)).post() }
    }

    private func subtitle(_ game: Game) -> String {
        game.rules.vacasToWin > 1
            ? "Vacas \(game.state.vacas.first) – \(game.state.vacas.second) · a \(game.rules.goal) tantos"
            : "Una vaca a \(game.rules.goal) tantos"
    }
}
