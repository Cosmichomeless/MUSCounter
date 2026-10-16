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
    /// Versión para pantalla apaisada: cifra más pequeña para que todo quepa en poca altura.
    var compact = false
    let onScore: (Int) -> Void
    let onMore: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(PiedrasPreference.key) private var showPiedras = false

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: Metrics.spacingS), count: count)
    }

    /// Lo que lee VoiceOver al enfocar el marcador del equipo.
    private var accessibleValue: String {
        AccessibilityText.teamValue(
            score: score, goal: goal, vacas: vacas, vacasToWin: vacasToWin, isLeading: isLeading, isWinner: isWinner
        )
    }

    var body: some View {
        VStack(spacing: Metrics.spacingS) {
            scoreSummary

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

    /// Nombre, cifra, progreso y vacas: un único elemento para VoiceOver con el nombre como etiqueta
    /// y el estado (tantos, vacas, quién va por delante) como valor.
    private var scoreSummary: some View {
        VStack(spacing: Metrics.spacingS) {
            HStack(spacing: Metrics.spacingS) {
                TeamMarker(team: team)
                Text(name)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.7)
                // La ventaja y la victoria se ven también sin color: icono distinto además del anillo dorado.
                if isWinner {
                    Image(systemName: "trophy.fill").foregroundStyle(Theme.accent)
                } else if isLeading {
                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(Theme.accent)
                }
            }

            ScoreText(value: score, baseSize: compact ? 64 : 120)
                .frame(maxHeight: .infinity)

            ProgressMeter(value: score, goal: goal, team: team)

            if showPiedras, !compact {
                PiedrasView(value: score, color: Theme.team(team))
            }

            HStack {
                Text("\(score)/\(goal)")
                Spacer(minLength: 0)
                if vacasToWin > 1 {
                    Text(String(repeating: "●", count: vacas) + String(repeating: "○", count: max(vacasToWin - vacas, 0)))
                        .foregroundStyle(Theme.accent)
                }
            }
            .font(.footnote)
            .foregroundStyle(Theme.mutedText)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(accessibleValue)
        .accessibilityAddTraits(.isHeader)
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

/// Ajuste visual: dibujar el tanteo como piedras (grupos de cinco y sueltas). No cambia ninguna regla.
enum PiedrasPreference {
    static let key = "showPiedras"
}

/// El tanteo dibujado como marcas de cinco en cinco: cuatro rayas y una cruzada por cada grupo,
/// y las sueltas al final. Es decorativo: el número y la barra ya dicen lo mismo a VoiceOver.
struct PiedrasView: View {
    let value: Int
    let color: Color

    var body: some View {
        let (groups, singles) = Piedras.split(value)
        let count = groups + (singles > 0 ? 1 : 0)
        Canvas { context, size in
            guard count > 0 else { return }
            let gap: CGFloat = 4
            let width = min(22, (size.width - gap * CGFloat(count - 1)) / CGFloat(count))
            for index in 0..<count {
                let x = CGFloat(index) * (width + gap)
                let strokes = index < groups ? 4 : singles
                let step = strokes > 1 ? width / CGFloat(strokes - 1) : 0
                var path = Path()
                for stroke in 0..<strokes {
                    let sx = strokes > 1 ? x + CGFloat(stroke) * step : x + width / 2
                    path.move(to: CGPoint(x: sx, y: 2))
                    path.addLine(to: CGPoint(x: sx, y: size.height - 2))
                }
                if index < groups {
                    path.move(to: CGPoint(x: x - 2, y: size.height - 4))
                    path.addLine(to: CGPoint(x: x + width + 2, y: 4))
                }
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
        .frame(height: 24)
        .accessibilityHidden(true)
    }
}
