import Foundation

/// Una persona que ha jugado alguna partida. Se guarda en el dispositivo para reconocerla entre partidas.
public struct Player: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// Un asiento de la mesa. Se guarda en la partida con el nombre tal como se jugó: borrar a una persona
/// de la lista de jugadores no cambia las partidas ya guardadas.
public struct Seat: Codable, Equatable, Sendable {
    public var name: String
    /// `nil` si el asiento no está ligado a ningún jugador guardado.
    public var playerID: UUID?

    public init(name: String, playerID: UUID? = nil) {
        self.name = name
        self.playerID = playerID
    }
}

/// La mesa de mus: cuatro asientos en sentido horario. Los equipos se sientan alternados, así que
/// los asientos 0 y 2 son del primer equipo y el 1 y el 3 del segundo.
public enum Table {
    public static let seatCount = 4

    public static func team(ofSeat seat: Int) -> TeamID {
        seat % 2 == 0 ? .first : .second
    }

    /// Asientos de un equipo, en orden de mesa.
    public static func seats(of team: TeamID) -> [Int] {
        (0..<seatCount).filter { self.team(ofSeat: $0) == team }
    }

    /// El asiento que es mano en la mano número `handsPlayed` (0 = la primera).
    /// La mano pasa al siguiente asiento en sentido horario tras cada mano.
    public static func manoSeat(firstMano: Int, handsPlayed: Int) -> Int {
        (firstMano + handsPlayed) % seatCount
    }
}
