import Foundation

/// Textos que lee VoiceOver. Viven aquí (lógica pura) para poder comprobarlos con pruebas.
public enum AccessibilityText {
    /// Plural correcto de «tanto».
    public static func points(_ count: Int) -> String {
        count == 1 ? "1 tanto" : "\(count) tantos"
    }

    /// Valor accesible de un panel de equipo: tanteo respecto al objetivo, vacas y situación.
    /// Nunca depende del color: «va ganando» y «ha ganado» se dicen con palabras.
    public static func teamValue(
        score: Int, goal: Int, vacas: Int, vacasToWin: Int, isLeading: Bool, isWinner: Bool
    ) -> String {
        var parts = ["\(points(score)) de \(goal)"]
        if vacasToWin > 1 {
            parts.append("vacas \(vacas) de \(vacasToWin)")
        }
        if isWinner {
            parts.append("ha ganado la partida")
        } else if isLeading {
            parts.append("va por delante")
        }
        return parts.joined(separator: ", ")
    }

    /// Resumen del marcador completo, para anunciarlo tras cada anotación.
    public static func scoreboard(names: PerTeam<String>, score: PerTeam<Int>) -> String {
        if score.first == score.second {
            return "Empate a \(points(score.first)): \(names.first) y \(names.second)"
        }
        return "\(names.first) \(score.first), \(names.second) \(score.second)"
    }

    /// Anuncio al terminar la partida.
    public static func victory(winner: String, reason: WinReason) -> String {
        "¡Victoria de \(winner)! " + (reason == .ordago ? "Por órdago." : "Objetivo alcanzado.")
    }
}
