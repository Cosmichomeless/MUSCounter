import SwiftUI
import MusCore

/// Muestra todos los componentes y sus estados. Sirve para revisar el sistema visual
/// (vista previa de Xcode) y como prueba de humo de renderizado.
struct ComponentGallery: View {
    @State private var goal = 40
    @State private var vacas = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingXL) {
                section("Botones") {
                    Button("Nueva partida") {}.buttonStyle(.musPrimary)
                    Button("Opciones de la partida") {}.buttonStyle(.musSecondary)
                    Button("Reiniciar partida") {}.buttonStyle(.musDanger)
                    Button("Desactivado") {}.buttonStyle(.musPrimary).disabled(true)
                }

                section("Equipos y tanteo") {
                    HStack(spacing: Metrics.spacingL) {
                        ForEach(TeamID.allCases, id: \.self) { team in
                            VStack(spacing: Metrics.spacingS) {
                                HStack {
                                    TeamMarker(team: team)
                                    Text(team == .first ? "Nosotros" : "Ellos").font(.headline)
                                }
                                ScoreText(value: team == .first ? 27 : 8)
                            }
                            .frame(maxWidth: .infinity)
                            .musCard()
                        }
                    }
                }

                section("Selectores") {
                    MusSegmented(
                        options: [MusOption(value: 30, label: "30"), MusOption(value: 40, label: "40")],
                        selection: $goal
                    )
                    MusSegmented(
                        options: [
                            MusOption(value: 1, label: "Sin vacas"),
                            MusOption(value: 2, label: "2 de 3"),
                            MusOption(value: 3, label: "3 de 5"),
                        ],
                        selection: $vacas
                    )
                }

                section("Mensajes") {
                    ErrorBanner(message: "El tanteo no puede bajar de 0.")
                }
            }
            .padding(Metrics.spacingL)
        }
        .foregroundStyle(Theme.text)
        .musScreen()
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            Text(title).font(.title3.bold())
            content()
        }
    }
}

#Preview("Oscuro") {
    ComponentGallery().preferredColorScheme(.dark)
}

#Preview("Claro") {
    ComponentGallery().preferredColorScheme(.light)
}
