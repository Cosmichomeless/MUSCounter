import ActivityKit
import Foundation

/// Datos de la Live Activity del marcador. Los comparten la app y la extensión, por eso no dependen de `MusCore`:
/// son solo textos y números ya calculados.
struct MarcadorActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var score: [Int]
        var vacas: [Int]
        var goal: Int
        var vacasToWin: Int
        /// Nombre de quien es mano; `nil` si la partida no sigue a los jugadores.
        var mano: String?
    }

    var teamNames: [String]
}
