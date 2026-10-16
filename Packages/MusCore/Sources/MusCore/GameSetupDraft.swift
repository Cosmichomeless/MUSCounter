import Foundation

/// Borrador de la configuración de una partida. No crea nada hasta que se llama a `makeGame()`,
/// de modo que cancelar la configuración nunca deja una partida accidental.
public struct GameSetupDraft: Equatable, Sendable {
    public static let defaultFirstName = "Nosotros"
    public static let defaultSecondName = "Ellos"
    public static let standard = GameSetupDraft()

    public var firstName: String
    public var secondName: String
    public var goal: Int
    public var vacasToWin: Int
    /// Nombres de los cuatro asientos en sentido horario; todos vacíos = no seguir a los jugadores.
    public var seatNames: [String]
    /// Asiento (0-3) que es mano en la primera mano.
    public var firstMano: Int

    public init(
        firstName: String = GameSetupDraft.defaultFirstName,
        secondName: String = GameSetupDraft.defaultSecondName,
        goal: Int = GameRules.standard.goal,
        vacasToWin: Int = GameRules.standard.vacasToWin,
        seatNames: [String] = Array(repeating: "", count: Table.seatCount),
        firstMano: Int = 0
    ) {
        self.firstName = firstName
        self.secondName = secondName
        self.goal = goal
        self.vacasToWin = vacasToWin
        self.seatNames = seatNames
        self.firstMano = firstMano
    }

    /// Borrador con los equipos predeterminados y las reglas de las preferencias.
    public init(preferences: Preferences) {
        self.init(goal: preferences.goal, vacasToWin: preferences.vacasToWin)
    }

    /// Borrador con los mismos equipos y reglas que una partida existente (revancha, última configuración).
    public init(from game: Game) {
        self.init(
            firstName: game.teamNames.first,
            secondName: game.teamNames.second,
            goal: game.rules.goal,
            vacasToWin: game.rules.vacasToWin,
            seatNames: game.tracksPlayers ? game.seats.map(\.name) : Array(repeating: "", count: Table.seatCount),
            firstMano: game.tracksPlayers ? Table.manoSeat(firstMano: game.firstMano, handsPlayed: game.state.handsPlayed) : 0
        )
    }

    public var rules: GameRules { GameRules(goal: goal, vacasToWin: vacasToWin) }

    /// Nombres ya recortados; un nombre vacío vuelve al predeterminado.
    public var teamNames: PerTeam<String> {
        PerTeam(
            Game.normalizedName(firstName, fallback: Self.defaultFirstName),
            Game.normalizedName(secondName, fallback: Self.defaultSecondName)
        )
    }

    /// Se siguen los jugadores solo si se ha escrito el nombre de los cuatro.
    public var tracksPlayers: Bool {
        seatNames.count == Table.seatCount
            && seatNames.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// `true` si dos asientos tienen el mismo nombre (sin distinguir mayúsculas ni acentos).
    public var hasDuplicateSeatNames: Bool {
        let keys = seatNames.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
        }.filter { !$0.isEmpty }
        return Set(keys).count != keys.count
    }

    /// Asientos sin ligar a ningún jugador guardado (lo hace el repositorio al empezar la partida).
    public var seats: [Seat] {
        tracksPlayers ? seatNames.map { Seat(name: $0) } : []
    }

    public func makeGame(createdAt: Date = Date()) throws -> Game {
        try Game(teamNames: teamNames, rules: rules, seats: seats, firstMano: firstMano, createdAt: createdAt)
    }
}
