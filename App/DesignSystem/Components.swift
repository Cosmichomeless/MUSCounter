import SwiftUI
import MusCore

// MARK: - Botones

enum MusButtonKind {
    case primary, secondary, danger
}

/// Estilo de botón de la app: alto mínimo de 52 pt, estados de pulsación, desactivado y foco.
struct MusButtonStyle: ButtonStyle {
    var kind: MusButtonKind = .secondary

    func makeBody(configuration: Configuration) -> some View {
        MusButtonBody(kind: kind, configuration: configuration)
    }
}

private struct MusButtonBody: View {
    let kind: MusButtonKind
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Theme.onAccent
        case .secondary: return Theme.text
        case .danger: return Theme.danger
        }
    }

    private var fill: Color {
        switch kind {
        case .primary: return Theme.accent
        case .secondary: return Theme.cardRaised
        case .danger: return Color.clear
        }
    }

    var body: some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .padding(.horizontal, Metrics.spacingL)
            .frame(maxWidth: .infinity, minHeight: Metrics.minTapTarget)
            .background(fill, in: shape)
            .overlay {
                if kind == .danger {
                    shape.strokeBorder(Theme.danger, lineWidth: 2)
                }
            }
            .overlay {
                if isFocused {
                    shape.strokeBorder(Theme.accent, lineWidth: 3).padding(-3)
                }
            }
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == MusButtonStyle {
    static var musPrimary: MusButtonStyle { MusButtonStyle(kind: .primary) }
    static var musSecondary: MusButtonStyle { MusButtonStyle(kind: .secondary) }
    static var musDanger: MusButtonStyle { MusButtonStyle(kind: .danger) }
}

// MARK: - Superficies

extension View {
    /// Tarjeta con el fondo y el radio de la app.
    func musCard() -> some View {
        padding(Metrics.spacingL)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
    }

    /// Fondo de pantalla completo que respeta las áreas seguras.
    func musScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Equipos y tanteo

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Marca de equipo: color **y** forma (círculo / rombo), para no depender solo del color.
struct TeamMarker: View {
    let team: TeamID
    var size: CGFloat = 18

    var body: some View {
        Group {
            if team == .first {
                Circle().fill(Theme.team(team))
            } else {
                Diamond().fill(Theme.team(team))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Número de tanteo grande, con cifras de ancho fijo que escalan con el tamaño de texto.
struct ScoreText: View {
    let value: Int
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 120

    var body: some View {
        Text("\(value)")
            .font(.system(size: size, weight: .black, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .foregroundStyle(Theme.text)
    }
}

// MARK: - Controles

struct MusOption<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    var id: Value { value }
}

/// Selector de una opción entre varias, con zonas táctiles de 48 pt.
struct MusSegmented<Value: Hashable>: View {
    let options: [MusOption<Value>]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: Metrics.spacingXS) {
            ForEach(options) { option in
                let selected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(selected ? Theme.onAccent : Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            selected ? Theme.accent : Color.clear,
                            in: RoundedRectangle(cornerRadius: Metrics.cornerRadius - 6, style: .continuous)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(Metrics.spacingXS)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
    }
}

/// Mensaje de error corregible: icono + texto (nunca solo color).
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Metrics.spacingM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.danger)
        .padding(Metrics.spacingM)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .strokeBorder(Theme.danger, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}
