import SwiftUI
import MusAds
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
    @Environment(AdsController.self) private var ads: AdsController?
    @State private var showsPrivacy = false
    @AppStorage(PiedrasPreference.key) private var showPiedras = false
    @AppStorage(ScoreboardActivity.preferenceKey) private var showLiveScoreboard = true

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

                    field("Piedras", note: "Dibuja el tanteo de cada equipo en grupos de cinco, como las piedras de la mesa. Solo cambia cómo se ve el marcador, no las reglas.") {
                        feedbackToggle("Mostrar piedras", isOn: $showPiedras)
                            .padding(.horizontal, Metrics.spacingL)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                    }

                    field("Pantalla de bloqueo", note: "Mientras hay una partida en curso, muestra el tanteo en la pantalla de bloqueo y en la Isla Dinámica. Se queda en tu iPhone y desaparece al terminar la partida.") {
                        feedbackToggle("Marcador en la pantalla de bloqueo", isOn: $showLiveScoreboard)
                            .padding(.horizontal, Metrics.spacingL)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                            .onChange(of: showLiveScoreboard) { model.refreshScoreboard() }
                    }

                    field("Respuesta al apuntar", note: "El sonido respeta el modo silencioso del iPhone. El marcador se entiende igual sin vibración ni sonido.") {
                        VStack(spacing: 0) {
                            feedbackToggle("Vibración", isOn: binding(\.hapticsEnabled))
                            Divider().overlay(Theme.cardRaised)
                            feedbackToggle("Sonido", isOn: binding(\.soundEnabled))
                        }
                        .padding(.horizontal, Metrics.spacingL)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                    }

                    if let ads, ads.isEnabled {
                        field("Anuncios", note: "Banners discretos en Inicio, Historial y al terminar la partida; nunca durante el marcador.") {
                            if ads.privacyOptionsRequired {
                                Button("Revisar consentimiento de anuncios") {
                                    Task { await ads.presentPrivacyOptions() }
                                }
                                .buttonStyle(.musSecondary)
                            }
                        }
                    }

                    field("Privacidad y soporte", note: "Qué datos usa la app, cómo contactar y cómo ejercer tus derechos.") {
                        Button("Privacidad y soporte") { showsPrivacy = true }
                            .buttonStyle(.musSecondary)
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
        .sheet(isPresented: $showsPrivacy) {
            PrivacyView(info: SupportInfo(), showsAds: ads?.isEnabled == true)
        }
    }

    private func feedbackToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(.headline)
            .tint(Theme.accent)
            .frame(minHeight: Metrics.minTapTarget)
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
