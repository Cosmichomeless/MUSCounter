import SwiftUI
import MusCore

extension ThemePreference {
    /// Esquema de color que se fuerza en la app; `nil` sigue al iPhone.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ajustes").font(.title.bold())
                Spacer()
                Button {
                    model.backToHome()
                } label: {
                    Image(systemName: "xmark").font(.title3.weight(.bold))
                        .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar ajustes")
            }
            .padding(Metrics.spacingL)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingL) {
                    if let message = model.errorMessage {
                        ErrorBanner(message: message)
                    }

                    field("Tantos de la vaca", note: "Predeterminado: 40 tantos.") {
                        MusSegmented(
                            options: GameRules.allowedGoals.map { MusOption(value: $0, label: "\($0)") },
                            selection: binding(\.goal),
                            title: "Tantos de la vaca"
                        )
                    }
                    field("Vacas para ganar", note: "Predeterminado: sin vacas, una sola vaca decide la partida.") {
                        MusSegmented(
                            options: [
                                MusOption(value: 1, label: "Sin vacas"),
                                MusOption(value: 2, label: "2 de 3"),
                                MusOption(value: 3, label: "3 de 5"),
                            ],
                            selection: binding(\.vacasToWin),
                            title: "Vacas para ganar"
                        )
                    }
                    field("Tema", note: "Predeterminado: Sistema, que sigue el modo claro u oscuro del iPhone.") {
                        MusSegmented(
                            options: [ThemePreference.system, .light, .dark].map {
                                MusOption(value: $0, label: $0.displayName)
                            },
                            selection: binding(\.theme),
                            title: "Tema"
                        )
                    }

                    Text("Estos ajustes se usan al crear partidas nuevas. Las partidas ya empezadas o guardadas no cambian.")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal, Metrics.spacingL)
            }
        }
        .foregroundStyle(Theme.text)
        .musScreen()
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<Preferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.preferences[keyPath: keyPath] },
            set: { newValue in model.updatePreferences { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func field<Content: View>(_ title: String, note: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            content()
            Text(note)
                .font(.footnote)
                .foregroundStyle(Theme.mutedText)
        }
    }
}
