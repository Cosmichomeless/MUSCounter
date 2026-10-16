import Foundation
import Observation
import MusCore

/// Estado de la app: qué pantalla se muestra y la partida actual. Toda la lógica de reglas vive en `MusCore`.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

@MainActor
@Observable
final class AppModel {
    enum Screen: Equatable {
        case home, setup, game, result, history, settings
    }

    private let repository: GameRepository
    private let feedback: FeedbackPlayer
    private let scoreboard: ScoreboardPublishing

    var screen: Screen = .home
    var game: Game?
    var draft: GameSetupDraft = .standard
    /// Partidas terminadas o abandonadas, la más reciente primero.
    private(set) var history: [Game] = []
    /// Preferencias guardadas: reglas y tema que se usan al crear partidas nuevas.
    private(set) var preferences: Preferences = .standard
    /// Personas guardadas al jugar con jugadores (para sugerirlas y calcular estadísticas).
    private(set) var players: [Player] = []
    /// Lance al que se apuntan los tantos con los botones del marcador.
    var selectedLance: Lance = .grande
    /// Hoja abierta sobre el marcador (cantidad libre u órdago).
    var sheet: GameSheet?
    /// Aviso temporal con «Deshacer» tras la última anotación.
    var toast: Toast?
    /// Mensaje de error para mostrar al usuario (nil si no hay).
    var errorMessage: String?

    init(repository: GameRepository, feedback: FeedbackPlayer? = nil, scoreboard: ScoreboardPublishing? = nil) {
        self.repository = repository
        self.feedback = feedback ?? SystemFeedback()
        self.scoreboard = scoreboard ?? NoScoreboard()
        self.game = repository.activeGame
        self.history = repository.history
        self.preferences = repository.preferences
        self.players = repository.players
        self.scoreboard.publish(game)
    }

    /// Abre los datos del dispositivo. Si el fichero está dañado se aparta (nunca se pierde en silencio)
    /// y la app arranca vacía.
    static func live() -> AppModel {
        do {
            let url = try FileAppDataStore.defaultURL()
            let store = FileAppDataStore(fileURL: url)
            do {
                return AppModel(repository: try GameRepository(store: store), scoreboard: ScoreboardActivity())
            } catch {
                let quarantine = url.appendingPathExtension("dañado")
                try? FileManager.default.removeItem(at: quarantine)
                try? FileManager.default.moveItem(at: url, to: quarantine)
                let model = AppModel(repository: try GameRepository(store: store), scoreboard: ScoreboardActivity())
                model.errorMessage = "No se pudieron leer las partidas guardadas. Se ha empezado de cero."
                return model
            }
        } catch {
            fatalError("No se puede acceder al almacenamiento local: \(error)")
        }
    }

    var hasGameInProgress: Bool { game?.isInProgress == true }

    // MARK: - Navegación

    /// Abre las opciones de partida con las reglas de las preferencias.
    func openSetup() {
        draft = GameSetupDraft(preferences: preferences)
        screen = .setup
    }

    /// Cancelar la configuración descarta el borrador: no se crea ninguna partida.
    func cancelSetup() {
        draft = GameSetupDraft(preferences: preferences)
        screen = .home
    }

    func openHistory() {
        errorMessage = nil
        screen = .history
    }

    func openSettings() {
        errorMessage = nil
        screen = .settings
    }

    func backToHome() {
        errorMessage = nil
        screen = .home
    }

    func resumeGame() {
        guard hasGameInProgress else { return }
        screen = .game
    }

    func leaveGame() {
        screen = .home
    }

    /// Vuelve al inicio desde la pantalla de resultado: no queda ninguna partida en curso.
    func goHome() {
        game = repository.activeGame
        sync()
        refreshScoreboard()
        toast = nil
        screen = .home
    }

    /// Revancha: mismos equipos y reglas. La partida terminada ya está en el historial (una sola vez).
    func rematch() {
        guard let finished = game, !finished.isInProgress else { return }
        startGame(with: GameSetupDraft(from: finished))
    }

    /// Nueva partida desde el resultado: abre las opciones con la configuración de la partida terminada.
    func newGameFromResult() {
        if let finished = game, !finished.isInProgress {
            draft = GameSetupDraft(from: finished)
            screen = .setup
        } else {
            openSetup()
        }
    }

    // MARK: - Historial y preferencias

    /// Guarda un cambio en las preferencias. Solo afecta a las partidas nuevas; si falla no cambia nada.
    func updatePreferences(_ change: (inout Preferences) -> Void) {
        var updated = preferences
        change(&updated)
        guard updated != preferences else { return }
        do {
            try repository.updatePreferences(updated)
            sync()
            errorMessage = nil
        } catch {
            errorMessage = "No se pudieron guardar los ajustes. Inténtalo de nuevo."
        }
    }

    /// Estadísticas de cada jugador guardado, de las partidas terminadas.
    var playerStats: [UUID: PlayerStats] { Stats.players(from: history) }

    /// Parejas que han jugado juntas, de la que más ha jugado a la que menos.
    var pairStats: [PairStats] { Stats.pairs(from: history) }

    /// Quita a una persona de la lista de jugadores; sus partidas guardadas conservan el nombre.
    func deletePlayer(_ id: UUID) {
        do {
            try repository.deletePlayer(id: id)
            sync()
            errorMessage = nil
        } catch {
            errorMessage = "No se pudo borrar al jugador."
        }
    }

    /// Borra una partida del historial.
    func deleteHistoryGame(_ id: UUID) {
        do {
            try repository.deleteHistoryGame(id: id)
            sync()
            errorMessage = nil
        } catch {
            errorMessage = "No se pudo borrar la partida del historial."
        }
    }

    /// Borra todo el historial; la partida en curso se conserva.
    func deleteHistory() {
        do {
            try repository.deleteHistory()
            sync()
            errorMessage = nil
        } catch {
            errorMessage = "No se pudo borrar el historial."
        }
    }

    /// Vuelve a publicar el marcador de la pantalla de bloqueo (por ejemplo, al cambiar el ajuste).
    func refreshScoreboard() { scoreboard.publish(game) }

    /// Refresca lo que se muestra a partir del repositorio, que es la fuente de verdad.
    private func sync() {
        history = repository.history
        preferences = repository.preferences
        players = repository.players
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

    /// Cierra la mano en curso: la mano pasa al siguiente jugador.
    func nextHand() {
        perform { try $0.nextHand() }
    }

    /// Corrección manual del tanteo de un equipo.
    func adjust(_ team: TeamID, by delta: Int) {
        perform { try $0.adjust(team: team, by: delta) }
    }

    /// Revierte exactamente la última acción.
    func undo() {
        guard var updated = game else { return }
        do {
            try updated.undo()
            try repository.update(updated)
            game = updated
            sync()
            refreshScoreboard()
            toast = nil
            errorMessage = nil
            if screen == .result, updated.isInProgress { screen = .game }
        } catch let error as ScoringError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = "No se pudo guardar la partida en el dispositivo."
        }
    }

    /// Reinicia la partida en curso (se descarta la anterior).
    func restartGame() {
        do {
            game = try repository.restartActiveGame()
            sync()
            refreshScoreboard()
            toast = nil
            errorMessage = nil
        } catch {
            errorMessage = "No se pudo reiniciar la partida."
        }
    }

    /// Abandona la partida: queda en el historial como abandonada.
    func abandonGame() {
        perform { try $0.abandon() }
        guard game?.status == .abandoned else { return }
        game = nil
        refreshScoreboard()
        toast = nil
        screen = .home
    }

    /// Borra la partida en curso sin guardarla.
    func deleteGame() {
        do {
            try repository.discardActiveGame()
            game = nil
            sync()
            refreshScoreboard()
            toast = nil
            screen = .home
        } catch {
            errorMessage = "No se pudo borrar la partida."
        }
    }

    /// Respuesta háptica y sonora, cada una solo si está activada en las preferencias.
    private func play(_ event: FeedbackEvent) {
        if preferences.hapticsEnabled { feedback.haptic(event) }
        if preferences.soundEnabled { feedback.sound(event) }
    }

    /// Aplica un cambio a la partida y lo guarda. Si falla (regla o guardado) el estado no cambia.
    private func perform(_ change: (inout Game) throws -> Void) {
        guard var updated = game else { return }
        do {
            let before = updated.actions.count
            try change(&updated)
            try repository.update(updated)
            game = updated
            sync()
            refreshScoreboard()
            errorMessage = nil
            if updated.actions.count > before, let last = updated.actions.last, updated.status != .abandoned {
                toast = Toast(message: ActionText.summary(last, game: updated))
                // Los ajustes manuales son correcciones: no se celebran.
                if updated.isInProgress, last.kind != .adjustment { play(.scored) }
            }
            if case .finished = updated.status {
                toast = nil
                screen = .result
                if updated.actions.count > before { play(.victory) }
            }
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
        case .invalidSeating: return "Los jugadores no son válidos: cada uno debe sentarse en un sitio distinto."
        }
    }

    /// Empieza una partida con el borrador. Si había otra en curso se archiva como abandonada.
    func startGame(with draft: GameSetupDraft) {
        do {
            game = try repository.startGame(
                teamNames: draft.teamNames, rules: draft.rules, seats: draft.seats, firstMano: draft.firstMano
            )
            sync()
            refreshScoreboard()
            screen = .game
        } catch {
            errorMessage = "No se pudo crear la partida. Revisa las opciones e inténtalo de nuevo."
        }
    }
}
