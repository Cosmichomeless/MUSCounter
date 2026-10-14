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
