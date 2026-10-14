import SwiftUI
import MusCore

/// Registro breve de las últimas acciones (la más reciente primero).
struct ActionLogSheet: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var recent: [GameAction] { Array(game.actions.suffix(8).reversed()) }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingL) {
            Text("Acciones recientes").font(.title2.bold())
            if recent.isEmpty {
                Text("Todavía no hay acciones.").foregroundStyle(Theme.mutedText)
            } else {
                ScrollView {
                    VStack(spacing: Metrics.spacingS) {
                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, action in
                            row(action, isLast: index == 0)
                        }
                    }
                }
            }
            Button("Cerrar") { dismiss() }.buttonStyle(.musSecondary)
        }
        .padding(Metrics.spacingL)
        .foregroundStyle(Theme.text)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.background)
    }

    private func row(_ action: GameAction, isLast: Bool) -> some View {
        HStack(spacing: Metrics.spacingM) {
            TeamMarker(team: action.team)
            VStack(alignment: .leading, spacing: 2) {
                Text(game.teamNames[action.team]).font(.subheadline.weight(.semibold))
                Text(ActionText.lance(action)).font(.footnote).foregroundStyle(Theme.mutedText)
            }
            Spacer(minLength: 0)
            Text(ActionText.amount(action)).font(.headline.monospacedDigit())
        }
        .padding(Metrics.spacingM)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if isLast { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.accent, lineWidth: 2) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.teamNames[action.team]), \(ActionText.lance(action)), \(ActionText.amount(action))\(isLast ? ", última acción" : "")")
    }
}

/// Textos de las acciones, compartidos por el registro y el aviso de «deshacer».
enum ActionText {
    static func lance(_ action: GameAction) -> String {
        switch action.kind {
        case let .score(lance): return lance.displayName
        case .ordago: return "Órdago"
        case .adjustment: return "Ajuste"
        }
    }

    static func amount(_ action: GameAction) -> String {
        switch action.kind {
        case .ordago: return "Órdago"
        default: return action.amount > 0 ? "+\(action.amount)" : "\(action.amount)"
        }
    }

    static func summary(_ action: GameAction, game: Game) -> String {
        let team = game.teamNames[action.team]
        switch action.kind {
        case let .score(lance): return "\(lance.displayName): +\(action.amount) para \(team)"
        case .ordago: return "Órdago ganado por \(team)"
        case .adjustment: return "Ajuste \(action.amount > 0 ? "+" : "")\(action.amount) para \(team)"
        }
    }
}

/// Corrección manual del tanteo (±1) sin deshacer.
struct AdjustSheet: View {
    let model: AppModel
    let game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingL) {
            Text("Corregir tanteo").font(.title2.bold())
            Text("Suma o resta un tanto al equipo que corresponda.").foregroundStyle(Theme.mutedText)
            ForEach(TeamID.allCases, id: \.self) { team in
                HStack(spacing: Metrics.spacingM) {
                    TeamMarker(team: team)
                    Text(game.teamNames[team]).font(.headline).lineLimit(1)
                    Spacer(minLength: 0)
                    stepper("minus", "Restar un tanto a \(game.teamNames[team])") { model.adjust(team, by: -1) }
                    Text("\(game.state.score[team])")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .frame(minWidth: 44)
                    stepper("plus", "Sumar un tanto a \(game.teamNames[team])") { model.adjust(team, by: 1) }
                }
                .musCard()
            }
            if let message = model.errorMessage {
                ErrorBanner(message: message)
            }
            Button("Cerrar") { dismiss() }.buttonStyle(.musSecondary)
        }
        .padding(Metrics.spacingL)
        .foregroundStyle(Theme.text)
        .presentationDetents([.medium])
        .presentationBackground(Theme.background)
    }

    private func stepper(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                .background(Theme.cardRaised, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

enum GameConfirmation: Identifiable {
    case restart, abandon, delete
    var id: Int { hashValue }

    var title: String {
        switch self {
        case .restart: return "¿Reiniciar la partida?"
        case .abandon: return "¿Abandonar la partida?"
        case .delete: return "¿Borrar la partida?"
        }
    }

    var message: String {
        switch self {
        case .restart: return "Se borrará el tanteo y las acciones de esta partida. No se puede deshacer."
        case .abandon: return "Se guardará en el historial como abandonada y no se podrá retomar."
        case .delete: return "Se borrará la partida sin guardarla en el historial. No se puede deshacer."
        }
    }

    var confirmLabel: String {
        switch self {
        case .restart: return "Reiniciar"
        case .abandon: return "Abandonar"
        case .delete: return "Borrar"
        }
    }
}

/// Menú de la partida en curso.
struct GameMenuSheet: View {
    let onAdjust: () -> Void
    let onConfirm: (GameConfirmation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Metrics.spacingM) {
            Text("Partida").font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)
            Button("Corregir tanteo") { onAdjust() }.buttonStyle(.musSecondary)
            Button("Abandonar partida") { onConfirm(.abandon) }.buttonStyle(.musSecondary)
            Button("Reiniciar partida") { onConfirm(.restart) }.buttonStyle(.musDanger)
            Button("Borrar partida") { onConfirm(.delete) }.buttonStyle(.musDanger)
            Button("Cerrar") { dismiss() }.buttonStyle(.musSecondary)
        }
        .padding(Metrics.spacingL)
        .foregroundStyle(Theme.text)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.background)
    }
}

/// Aviso temporal tras una anotación, con deshacer inmediato.
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Metrics.spacingM) {
            Text(message).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Button("Deshacer", action: onUndo)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, Metrics.spacingM)
                .frame(minHeight: 44)
                .background(Theme.accent, in: Capsule())
                .foregroundStyle(Theme.onAccent)
        }
        .padding(Metrics.spacingM)
        .background(Theme.cardRaised, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous).strokeBorder(Theme.accent, lineWidth: 1.5))
        .foregroundStyle(Theme.text)
        .accessibilityElement(children: .combine)
    }
}
