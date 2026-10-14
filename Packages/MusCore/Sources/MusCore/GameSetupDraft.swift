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

    public init(
        firstName: String = GameSetupDraft.defaultFirstName,
        secondName: String = GameSetupDraft.defaultSecondName,
        goal: Int = GameRules.standard.goal,
        vacasToWin: Int = GameRules.standard.vacasToWin
    ) {
        self.firstName = firstName
        self.secondName = secondName
        self.goal = goal
        self.vacasToWin = vacasToWin
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
            vacasToWin: game.rules.vacasToWin
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

    public func makeGame(createdAt: Date = Date()) throws -> Game {
        try Game(teamNames: teamNames, rules: rules, createdAt: createdAt)
    }
}
