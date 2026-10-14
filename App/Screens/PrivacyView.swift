import SwiftUI
import MusCore

/// Resumen de privacidad y soporte, disponible sin conexión. La política completa vive en la URL pública.
struct PrivacyView: View {
    let info: SupportInfo
    let showsAds: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingL) {
                    section("Tus partidas son tuyas",
                            "El marcador, las partidas y las preferencias se guardan solo en tu iPhone. No hay cuenta y no enviamos tus partidas a ningún servidor.")
                    if showsAds {
                        section("Anuncios",
                                "La app muestra banners de Google AdMob en Inicio, Historial y al terminar la partida; nunca durante el marcador. Google puede tratar datos del dispositivo para servirlos. Puedes revisar tu consentimiento en Ajustes cuando la ley lo exige.")
                    }
                    section("Tus derechos",
                            "Puedes pedir información o ejercer tus derechos de privacidad escribiendo a soporte. Borrar la app borra tus partidas.")

                    if let url = info.policyURL {
                        Link("Política de privacidad completa", destination: url)
                            .buttonStyle(.musSecondary)
                    }
                    if let mail = info.supportMailURL {
                        Link("Contactar con soporte", destination: mail)
                            .buttonStyle(.musSecondary)
                    }
                }
                .padding(Metrics.spacingL)
            }
            .foregroundStyle(Theme.text)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Privacidad y soporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingS) {
            Text(title).font(.headline)
            Text(text).font(.body).foregroundStyle(Theme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
