/// Uno de los dos equipos de una partida.
public enum TeamID: Int, Codable, CaseIterable, Sendable {
    case first = 0
    case second = 1

    public var other: TeamID { self == .first ? .second : .first }
}

/// Un valor por equipo (tanteo, vacas, nombre…), indexable por `TeamID`.
public struct PerTeam<Value: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public var first: Value
    public var second: Value

    public init(_ first: Value, _ second: Value) {
        self.first = first
        self.second = second
    }

    public init(repeating value: Value) {
        self.init(value, value)
    }

    public subscript(team: TeamID) -> Value {
        get { team == .first ? first : second }
        set {
            switch team {
            case .first: first = newValue
            case .second: second = newValue
            }
        }
    }
}
