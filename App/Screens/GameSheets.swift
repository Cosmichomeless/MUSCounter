import SwiftUI
import MusCore

/// Hojas que se abren desde el marcador.
enum GameSheet: Identifiable {
    case amount(TeamID)
    case ordago
    case log
    case menu
    case adjust

    var id: String {
        switch self {
        case let .amount(team): return "amount-\(team.rawValue)"
        case .ordago: return "ordago"
        case .log: return "log"
        case .menu: return "menu"
        case .adjust: return "adjust"
        }
    }
}

/// Cantidad libre: ajusta los tantos y muestra un resumen antes de apuntar.
struct AmountSheet: View {
    let model: AppModel
    let game: Game
    let team: TeamID
    @State private var amount: Int
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel, game: Game, team: TeamID) {
        self.model = model
        self.game = game
        self.team = team
        _amount = State(initialValue: min(((model.selectedLance.quickAmounts.last ?? 5) + 1), game.rules.goal))
    }

    private var preview: Result<ScorePreview, ScoringError> {
        game.previewScore(amount: amount, for: team, lance: model.selectedLance)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingL) {
                Text("Otra cantidad").font(.title2.bold())

                HStack(spacing: Metrics.spacingXL) {
                    stepButton("minus", label: "Menos") { amount = max(1, amount - 1) }
                        .disabled(amount <= 1)
                    Text("\(amount)")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 90)
                        .accessibilityLabel("\(amount) tantos")
                    stepButton("plus", label: "Más") { amount = min(game.rules.goal, amount + 1) }
                        .disabled(amount >= game.rules.goal)
                }
                .frame(maxWidth: .infinity)

                summary

                HStack(spacing: Metrics.spacingM) {
                    Button("Cancelar") { dismiss() }.buttonStyle(.musSecondary)
                    Button("Apuntar") {
                        model.score(amount, to: team)
                        dismiss()
                    }
                    .buttonStyle(.musPrimary)
                    .disabled({ if case .failure = preview { return true } else { return false } }())
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(Metrics.spacingL)
        .foregroundStyle(Theme.text)
        .presentationDetents([.medium])
        .presentationBackground(Theme.background)
    }

    @ViewBuilder private var summary: some View {
        switch preview {
        case let .success(p):
            VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                Text("\(model.selectedLance.displayName) · \(amount) tantos para \(game.teamNames[team])")
                    .font(.headline)
                Text("\(p.scoreBefore) → \(p.scoreAfter)").font(.title3.monospacedDigit())
                if p.winsGame {
                    Label("¡Gana la partida!", systemImage: "trophy.fill").foregroundStyle(Theme.accent)
                } else if p.closesVaca {
                    Label("¡Gana la vaca!", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .musCard()
            .accessibilityElement(children: .combine)
        case let .failure(error):
            ErrorBanner(message: AppModel.message(for: error))
        }
    }

    private func stepButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title.weight(.bold))
                .frame(width: 72, height: 72)
                .background(Theme.cardRaised, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Órdago: se elige quién lo gana y se confirma con un resumen.
struct OrdagoSheet: View {
    let model: AppModel
    let game: Game
    @State private var winner: TeamID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingL) {
                Text("¡Órdago!").font(.title2.bold())
                Text("¿Quién gana el órdago? La vaca será para ese equipo.")
                    .foregroundStyle(Theme.mutedText)

                HStack(spacing: Metrics.spacingM) {
                    ForEach(TeamID.allCases, id: \.self) { team in
                        Button {
                            winner = team
                        } label: {
                            HStack(spacing: Metrics.spacingS) {
                                TeamMarker(team: team)
                                Text(game.teamNames[team]).lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity, minHeight: Metrics.minTapTarget)
                            .background(
                                winner == team ? Theme.accent : Theme.cardRaised,
                                in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                            )
                            .foregroundStyle(winner == team ? Theme.onAccent : Theme.text)
                            .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(winner == team ? .isSelected : [])
                    }
                }

                summary

                HStack(spacing: Metrics.spacingM) {
                    Button("Cancelar") { dismiss() }.buttonStyle(.musSecondary)
                    Button("Confirmar órdago") {
                        if let winner { model.declareOrdago(winner: winner) }
                        dismiss()
                    }
                    .buttonStyle(.musPrimary)
                    .disabled(winner == nil)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(Metrics.spacingL)
        .foregroundStyle(Theme.text)
        .presentationDetents([.medium])
        .presentationBackground(Theme.background)
    }

    @ViewBuilder private var summary: some View {
        if let winner {
            switch game.previewOrdago(winner: winner) {
            case let .success(p):
                VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                    Text("Gana \(game.teamNames[winner]) la vaca").font(.headline)
                    Text("\(p.scoreBefore) → \(p.scoreAfter)").font(.title3.monospacedDigit())
                    if p.winsGame {
                        Label("¡Gana la partida!", systemImage: "trophy.fill").foregroundStyle(Theme.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .musCard()
                .accessibilityElement(children: .combine)
            case let .failure(error):
                ErrorBanner(message: AppModel.message(for: error))
            }
        } else {
            Text("Elige un equipo para ver el resumen.")
                .foregroundStyle(Theme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .musCard()
        }
    }
}
