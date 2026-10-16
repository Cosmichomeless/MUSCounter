import SwiftUI
import MusCore

struct SetupView: View {
    @Bindable var model: AppModel
    @State private var confirmReplace = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nueva partida").font(.title.bold())
                Spacer()
                Button {
                    model.cancelSetup()
                } label: {
                    Image(systemName: "xmark").font(.title3.weight(.bold))
                        .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar")
            }
            .padding(Metrics.spacingL)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingL) {
                    teamField(title: "Equipo 1", team: .first, text: $model.draft.firstName)
                    teamField(title: "Equipo 2", team: .second, text: $model.draft.secondName)

                    playersSection

                    field("Tantos de la vaca") {
                        MusSegmented(
                            options: GameRules.allowedGoals.map { MusOption(value: $0, label: "\($0)") },
                            selection: $model.draft.goal,
                            title: "Tantos de la vaca"
                        )
                    }
                    field("Vacas para ganar") {
                        MusSegmented(
                            options: [
                                MusOption(value: 1, label: "Sin vacas"),
                                MusOption(value: 2, label: "2 de 3"),
                                MusOption(value: 3, label: "3 de 5"),
                            ],
                            selection: $model.draft.vacasToWin,
                            title: "Vacas para ganar"
                        )
                        Text("«Sin vacas»: una sola vaca decide la partida.")
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedText)
                    }
                }
                .padding(.horizontal, Metrics.spacingL)
            }

            Button("Empezar partida") { start() }
                .buttonStyle(.musPrimary)
                .disabled(model.draft.hasDuplicateSeatNames)
                .padding(Metrics.spacingL)
        }
        .foregroundStyle(Theme.text)
        .musScreen()
        .confirmationDialog(
            "Ya tienes una partida en curso",
            isPresented: $confirmReplace,
            titleVisibility: .visible
        ) {
            Button("Empezar una nueva", role: .destructive) { model.startGame(with: model.draft) }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("La partida actual se guardará en el historial como abandonada.")
        }
    }

    // MARK: - Jugadores

    /// Nombres guardados que aún no están sentados, para rellenar un asiento con un toque.
    private var suggestions: [Player] {
        let seated = Set(model.draft.seatNames.map { Self.key($0) })
        return model.players.filter { !seated.contains(Self.key($0.name)) }
    }

    private static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    private var playersSection: some View {
        field("Jugadores (opcional)") {
            VStack(alignment: .leading, spacing: Metrics.spacingM) {
                ForEach(0..<Table.seatCount, id: \.self) { seat in
                    seatField(seat)
                }
                if model.draft.hasDuplicateSeatNames {
                    Text("Dos jugadores tienen el mismo nombre. Cambia uno para continuar.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.danger)
                } else {
                    Text("Escribe los cuatro nombres, en el orden en que os sentáis, para llevar la mano y guardar estadísticas de cada jugador. Se quedan solo en este iPhone.")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                }
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Metrics.spacingS) {
                            ForEach(suggestions) { player in
                                Button(player.name) { seatPlayer(player) }
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, Metrics.spacingM)
                                    .frame(minHeight: Metrics.minTapTarget)
                                    .background(Theme.card, in: Capsule())
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Lo sienta en el primer sitio libre")
                            }
                        }
                    }
                }
                if model.draft.tracksPlayers && !model.draft.hasDuplicateSeatNames {
                    Text("Primera mano".uppercased())
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                    MusSegmented(
                        options: (0..<Table.seatCount).map {
                            MusOption(value: $0, label: model.draft.seatNames[$0].trimmingCharacters(in: .whitespacesAndNewlines))
                        },
                        selection: $model.draft.firstMano,
                        axis: .horizontal,
                        title: "Primera mano"
                    )
                }
            }
        }
    }

    private func seatField(_ seat: Int) -> some View {
        let team = Table.team(ofSeat: seat)
        return HStack(spacing: Metrics.spacingM) {
            TeamMarker(team: team)
            TextField("Jugador \(seat + 1)", text: $model.draft.seatNames[seat])
                .font(.title3)
                .submitLabel(.next)
                .autocorrectionDisabled()
                .onChange(of: model.draft.seatNames[seat]) { _, newValue in
                    if newValue.count > Game.maxNameLength {
                        model.draft.seatNames[seat] = String(newValue.prefix(Game.maxNameLength))
                    }
                }
        }
        .padding(.horizontal, Metrics.spacingL)
        .frame(minHeight: Metrics.minTapTarget)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Jugador \(seat + 1), \(team == .first ? "equipo 1" : "equipo 2")")
    }

    private func seatPlayer(_ player: Player) {
        guard let free = model.draft.seatNames.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else { return }
        model.draft.seatNames[free] = player.name
    }

    private func start() {
        if model.hasGameInProgress {
            confirmReplace = true
        } else {
            model.startGame(with: model.draft)
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            content()
        }
    }

    private func teamField(title: String, team: TeamID, text: Binding<String>) -> some View {
        field(title) {
            HStack(spacing: Metrics.spacingM) {
                TeamMarker(team: team)
                TextField(team == .first ? GameSetupDraft.defaultFirstName : GameSetupDraft.defaultSecondName, text: text)
                    .font(.title3)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .onChange(of: text.wrappedValue) { _, newValue in
                        if newValue.count > Game.maxNameLength {
                            text.wrappedValue = String(newValue.prefix(Game.maxNameLength))
                        }
                    }
            }
            .padding(.horizontal, Metrics.spacingL)
            .frame(minHeight: Metrics.minTapTarget)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
