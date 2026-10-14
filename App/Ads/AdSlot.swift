import MusAds
import SwiftUI

/// Pantallas donde se permite un banner. El marcador (`.game`), Preparar partida y Ajustes **nunca** llevan anuncios.
enum AdPlacement: CaseIterable {
    case home, history, result

    init?(screen: AppModel.Screen) {
        switch screen {
        case .home: self = .home
        case .history: self = .history
        case .result: self = .result
        case .setup, .game, .settings: return nil
        }
    }
}

/// Banner discreto al pie de una pantalla. Si los anuncios no están disponibles no ocupa nada.
struct AdSlot: View {
    let placement: AdPlacement
    @Environment(AdsController.self) private var ads: AdsController?

    var body: some View {
        if let ads {
            AdBanner(controller: ads)
        }
    }
}

extension AdsController {
    /// Anuncios reales solo en la app en marcha: desactivados en pruebas (`XCTest`), con el argumento
    /// `-MusAdsDisabled` y cuando faltan identificadores válidos.
    static func live(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        bundle: Bundle = .main
    ) -> AdsController {
        let underTest = environment["XCTestConfigurationFilePath"] != nil
        guard !underTest, !arguments.contains("-MusAdsDisabled") else { return .disabled() }
        return AdsController(configuration: AdsConfiguration(bundle: bundle))
    }
}
