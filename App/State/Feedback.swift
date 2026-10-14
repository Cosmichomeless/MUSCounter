import UIKit
import AudioToolbox

/// Momentos de la partida que pueden dar respuesta háptica o sonora.
enum FeedbackEvent: Equatable {
    /// Se han apuntado tantos.
    case scored
    /// La partida ha terminado con un ganador.
    case victory
}

/// Reproduce la respuesta háptica y sonora. Son canales independientes: `AppModel` solo llama a cada uno
/// si la persona lo tiene activado, y el marcador es igual de comprensible sin ninguno de los dos.
@MainActor
protocol FeedbackPlayer {
    func haptic(_ event: FeedbackEvent)
    func sound(_ event: FeedbackEvent)
}

/// Implementación real con los generadores del sistema.
///
/// - La háptica no bloquea: los generadores devuelven el control al instante y se vuelven a preparar
///   para que la siguiente pulsación responda sin retraso.
/// - El sonido usa sonidos del sistema (`AudioServicesPlaySystemSound`): respetan el interruptor de
///   silencio y el volumen del timbre, no interrumpen la música ni el audio de otras apps y no
///   necesitan configurar una sesión de audio.
@MainActor
final class SystemFeedback: FeedbackPlayer {
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    /// 1057 = «Tink», un chasquido corto; 1025 = «Fanfare».
    private static let scoredSound: SystemSoundID = 1057
    private static let victorySound: SystemSoundID = 1025

    func haptic(_ event: FeedbackEvent) {
        switch event {
        case .scored:
            impact.impactOccurred()
            impact.prepare()
        case .victory:
            notification.notificationOccurred(.success)
            notification.prepare()
        }
    }

    func sound(_ event: FeedbackEvent) {
        AudioServicesPlaySystemSound(event == .scored ? Self.scoredSound : Self.victorySound)
    }
}
