import Foundation

/// Estadísticas de una persona, calculadas a partir de las partidas terminadas en las que se sentó.
/// Las partidas abandonadas no cuentan: no tienen ganador.
public struct PlayerStats: Equatable, Sendable {
    public let playerID: UUID
    public internal(set) var gamesPlayed = 0
    public internal(set) var gamesWon = 0
    public internal(set) var vacasWon = 0
    public internal(set) var ordagosWon = 0
    public internal(set) var ordagosLost = 0
    /// Tantos que ha sumado su equipo en cada lance (sin contar los ajustes manuales).
    public internal(set) var tantosByLance: [Lance: Int] = [:]

    public init(playerID: UUID) {
        self.playerID = playerID
    }

    public var winRate: Double? {
        gamesPlayed == 0 ? nil : Double(gamesWon) / Double(gamesPlayed)
    }

    /// El lance en el que más tantos ha sumado su equipo, o `nil` si no ha sumado ninguno.
    public var bestLance: Lance? {
        tantosByLance.filter { $0.value > 0 }
            .max { ($0.value, $1.key.rawValue) < ($1.value, $0.key.rawValue) }?.key
    }
}

/// Estadísticas de dos personas que han jugado juntas, en el mismo equipo.
public struct PairStats: Equatable, Identifiable, Sendable {
    /// Los dos jugadores, ordenados para que (a, b) y (b, a) sean la misma pareja.
    public let playerIDs: [UUID]
    public internal(set) var gamesPlayed = 0
    public internal(set) var gamesWon = 0

    public var id: String { playerIDs.map(\.uuidString).joined(separator: "+") }

    public var winRate: Double? {
        gamesPlayed == 0 ? nil : Double(gamesWon) / Double(gamesPlayed)
    }
}

public enum Stats {
    /// Estadísticas por jugador. Solo cuentan las partidas terminadas que siguieron a los jugadores.
    public static func players(from games: [Game]) -> [UUID: PlayerStats] {
        var result: [UUID: PlayerStats] = [:]
        for game in games {
            guard case let .finished(winner, _) = game.status, game.tracksPlayers else { continue }
            for (index, seat) in game.seats.enumerated() {
                guard let id = seat.playerID else { continue }
                let team = Table.team(ofSeat: index)
                var stats = result[id] ?? PlayerStats(playerID: id)
                stats.gamesPlayed += 1
                if winner == team { stats.gamesWon += 1 }
                stats.vacasWon += game.state.completedVacas.filter { $0.winner == team }.count
                for action in game.actions {
                    switch action.kind {
                    case let .score(lance) where action.team == team:
                        stats.tantosByLance[lance, default: 0] += action.amount
                    case .ordago:
                        if action.team == team { stats.ordagosWon += 1 } else { stats.ordagosLost += 1 }
                    default:
                        break
                    }
                }
                result[id] = stats
            }
        }
        return result
    }

    /// Estadísticas por pareja, de la que más ha jugado a la que menos.
    public static func pairs(from games: [Game]) -> [PairStats] {
        var result: [String: PairStats] = [:]
        for game in games {
            guard case let .finished(winner, _) = game.status, game.tracksPlayers else { continue }
            for team in TeamID.allCases {
                let ids = Table.seats(of: team).compactMap { game.seats[$0].playerID }
                guard ids.count == 2 else { continue }
                let blank = PairStats(playerIDs: ids.sorted { $0.uuidString < $1.uuidString })
                var entry = result[blank.id] ?? blank
                entry.gamesPlayed += 1
                if winner == team { entry.gamesWon += 1 }
                result[blank.id] = entry
            }
        }
        return result.values.sorted {
            ($0.gamesPlayed, $0.gamesWon, $1.id) > ($1.gamesPlayed, $1.gamesWon, $0.id)
        }
    }
}
