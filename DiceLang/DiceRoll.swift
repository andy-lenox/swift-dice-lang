import Foundation

public struct DiceRoll {
    public let count: Int
    public let sides: Int
    public let modifier: DiceModifier?
    
    public init(count: Int, sides: Int, modifier: DiceModifier? = nil) {
        self.count = count
        self.sides = sides
        self.modifier = modifier
    }
}

public enum DiceModifier: Equatable {
    case exploding
    case compoundExploding
    case keepHighest(Int)
    case keepLowest(Int)
    case dropHighest(Int)
    case dropLowest(Int)
    case threshold(ComparisonOperator, Int)
    
    public enum ComparisonOperator: String, CaseIterable {
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case lessThan = "<"
        case lessThanOrEqual = "<="
    }
}

extension DiceRoll: Equatable {
    public static func == (lhs: DiceRoll, rhs: DiceRoll) -> Bool {
        return lhs.count == rhs.count && 
               lhs.sides == rhs.sides && 
               lhs.modifier == rhs.modifier
    }
}

extension DiceRoll: CustomStringConvertible {
    public var description: String {
        var desc = "\(count)d\(sides)"
        if let modifier = modifier {
            desc += modifier.description
        }
        return desc
    }
}

extension DiceModifier: CustomStringConvertible {
    public var description: String {
        switch self {
        case .exploding:
            return "!"
        case .compoundExploding:
            return "!!"
        case .keepHighest(let n):
            return "kh\(n)"
        case .keepLowest(let n):
            return "kl\(n)"
        case .dropHighest(let n):
            return "dh\(n)"
        case .dropLowest(let n):
            return "dl\(n)"
        case .threshold(let op, let value):
            return " \(op.rawValue) \(value)"
        }
    }
}