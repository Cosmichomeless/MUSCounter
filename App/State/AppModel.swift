import Foundation
import Observation
import MusCore

/// Estado de la app: qué pantalla se muestra y la partida actual. Toda la lógica de reglas vive en `MusCore`.
@MainActor
@Observable
final class AppModel {
    enum Screen: Equatable {
        case home, setup, game
    }

    private let repository: GameRepository

    var screen: Screen = .home
    var game: Game?
    var draft: GameSetupDraft = .standard
    /// Lance al que se apuntan los tantos con los botones del marcador.
    var selectedLance: Lance = .grande
    /// Hoja abierta sobre el marcador (cantidad libre u órdago).
    var sheet: GameSheet?
    /// Mensaje de error para mostrar al usuario (nil si no hay).
    var errorMessage: String?

    init(repository: GameRepository) {
        self.repository = repository
        self.game = repository.activeGame
    }

    /// Abre los datos del dispositivo. Si el fichero está dañado se aparta (nunca se pierde en silencio)
    /// y la app arranca vacía.
    static func live() -> AppModel {
        do {
            let url = try FileAppDataStore.defaultURL()
            let store = FileAppDataStore(fileURL: url)
            do {
                return AppModel(repository: try GameRepository(store: store))
            } catch {
                let quarantine = url.appendingPathExtension("dañado")
                try? FileManager.default.removeItem(at: quarantine)
                try? FileManager.default.moveItem(at: url, to: quarantine)
                let model = AppModel(repository: try GameRepository(store: store))
                model.errorMessage = "No se pudieron leer las partidas guardadas. Se ha empezado de cero."
                return model
            }
        } catch {
            fatalError("No se puede acceder al almacenamiento local: \(error)")
        }
    }

    var hasGameInProgress: Bool { game?.isInProgress == true }

    // MARK: - Navegación

    func openSetup() {
        draft = game.map(GameSetupDraft.init(from:)) ?? .standard
        screen = .setup
    }

    /// Cancelar la configuración descarta el borrador: no se crea ninguna partida.
    func cancelSetup() {
        draft = .standard
        screen = .home
    }

    func resumeGame() {
        guard hasGameInProgress else { return }
        screen = .game
    }

    func leaveGame() {
        screen = .home
    }

    // MARK: - Partida

    /// Apunta `amount` tantos del lance seleccionado al equipo `team`.
    func score(_ amount: Int, to team: TeamID) {
        perform { try $0.addScore(amount, lance: selectedLance, to: team) }
    }

    /// El equipo `winner` gana un órdago aceptado.
    func declareOrdago(winner: TeamID) {
        perform { try $0.declareOrdago(winner: winner) }
    }

    /// Aplica un cambio a la partida y lo guarda. Si falla (regla o guardado) el estado no cambia.
    private func perform(_ change: (inout Game) throws -> Void) {
        guard var updated = game else { return }
        do {
            try change(&updated)
            try repository.update(updated)
            game = updated
            errorMessage = nil
        } catch let error as ScoringError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = "No se pudo guardar la partida en el dispositivo."
        }
    }

    static func message(for error: ScoringError) -> String {
        switch error {
        case .notInProgress: return "La partida ya ha terminado."
        case .invalidAmount: return "La cantidad no es válida."
        case .belowZero: return "El tanteo no puede bajar de 0."
        case .nothingToUndo: return "No hay nada que deshacer."
        case .invalidRules: return "Las opciones de la partida no son válidas."
        }
    }

    /// Empieza una partida con el borrador. Si había otra en curso se archiva como abandonada.
    func startGame(with draft: GameSetupDraft) {
        do {
            game = try repository.startGame(teamNames: draft.teamNames, rules: draft.rules)
            screen = .game
        } catch {
            errorMessage = "No se pudo crear la partida. Revisa las opciones e inténtalo de nuevo."
        }
    }
}
