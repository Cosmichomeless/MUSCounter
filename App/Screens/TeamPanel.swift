import SwiftUI
import MusCore

/// Un lado del marcador: nombre, tanteo, progreso hacia el objetivo, vacas y botones de suma.
struct TeamPanel: View {
    let team: TeamID
    let name: String
    let score: Int
    let goal: Int
    let vacas: Int
    let vacasToWin: Int
    let isLeading: Bool
    let isWinner: Bool
    let lance: Lance
    let enabled: Bool
    let onScore: (Int) -> Void
    let onMore: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Metrics.spacingS), count: 3)

    var body: some View {
        VStack(spacing: Metrics.spacingS) {
            HStack(spacing: Metrics.spacingS) {
                TeamMarker(team: team)
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            ScoreText(value: score)
                .frame(maxHeight: .infinity)

            ProgressMeter(value: score, goal: goal, team: team)

            HStack {
                Text("\(score)/\(goal)")
                Spacer(minLength: 0)
                if vacasToWin > 1 {
                    Text(String(repeating: "●", count: vacas) + String(repeating: "○", count: max(vacasToWin - vacas, 0)))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }
            .font(.footnote)
            .foregroundStyle(Theme.mutedText)

            LazyVGrid(columns: columns, spacing: Metrics.spacingS) {
                ForEach(lance.quickAmounts, id: \.self) { amount in
                    Button("\(amount)") { onScore(amount) }
                        .buttonStyle(AmountButtonStyle(team: team))
                        .accessibilityLabel("Apuntar \(amount) de \(lance.displayName) a \(name)")
                }
                Button("Más", action: onMore)
                    .buttonStyle(AmountButtonStyle(team: team, compact: true))
                    .accessibilityLabel("Otra cantidad para \(name)")
            }
            .disabled(!enabled)
        }
        .padding(Metrics.spacingM)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                .fill(Theme.team(team))
                .frame(height: 8)
        }
        .overlay {
            if isLeading || isWinner {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 3)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Barra de progreso hacia el objetivo de tantos.
struct ProgressMeter: View {
    let value: Int
    let goal: Int
    let team: TeamID

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.background)
                Capsule()
                    .fill(Theme.team(team))
                    .frame(width: proxy.size.width * CGFloat(min(max(value, 0), goal)) / CGFloat(max(goal, 1)))
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

/// Botón de cantidad: grande, con el color del equipo al pulsar.
struct AmountButtonStyle: ButtonStyle {
    let team: TeamID
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .subheadline.weight(.bold) : .title2.weight(.heavy))
            .foregroundStyle(configuration.isPressed ? Theme.onAccent : Theme.text)
            .frame(maxWidth: .infinity, minHeight: Metrics.minTapTarget)
            .background(
                configuration.isPressed ? Theme.team(team) : Theme.cardRaised,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
    }
}
