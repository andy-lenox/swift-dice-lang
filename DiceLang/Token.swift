import Foundation

public enum TokenType: String, CaseIterable {
    case number = "NUMBER"
    case dice = "DICE"
    case identifier = "IDENTIFIER"
    
    // Operators
    case plus = "PLUS"
    case minus = "MINUS"
    case multiply = "MULTIPLY"
    case divide = "DIVIDE"
    
    // Comparison operators
    case greaterThan = "GREATER_THAN"
    case greaterThanOrEqual = "GREATER_THAN_OR_EQUAL"
    case lessThan = "LESS_THAN"
    case lessThanOrEqual = "LESS_THAN_OR_EQUAL"
    
    // Exploding dice
    case explode = "EXPLODE"
    case compoundExplode = "COMPOUND_EXPLODE"
    
    // Keep/Drop modifiers
    case keepHighest = "KEEP_HIGHEST"
    case keepLowest = "KEEP_LOWEST"
    case dropHighest = "DROP_HIGHEST"
    case dropLowest = "DROP_LOWEST"
    case keep = "KEEP"
    case drop = "DROP"
    case highest = "HIGHEST"
    case lowest = "LOWEST"
    
    // Grouping and structure
    case leftParen = "LEFT_PAREN"
    case rightParen = "RIGHT_PAREN"
    case leftBracket = "LEFT_BRACKET"
    case rightBracket = "RIGHT_BRACKET"
    case comma = "COMMA"
    case colon = "COLON"
    
    // Tagged dice and outcomes
    case arrow = "ARROW"
    case higherTag = "HIGHER_TAG"
    case determines = "DETERMINES"
    case outcome = "OUTCOME"
    
    // Random tables
    case at = "AT"
    case percent = "PERCENT"
    case dash = "DASH"
    
    // Variable assignment
    case assign = "ASSIGN"
    
    // Special tokens
    case eof = "EOF"
    case newline = "NEWLINE"
    case whitespace = "WHITESPACE"
    case unknown = "UNKNOWN"
}

public struct Token: Equatable {
    public let type: TokenType
    public let value: String
    public let position: Int
    public let line: Int
    public let column: Int
    
    public init(type: TokenType, value: String, position: Int, line: Int = 1, column: Int = 1) {
        self.type = type
        self.value = value
        self.position = position
        self.line = line
        self.column = column
    }
}

extension Token: CustomStringConvertible {
    public var description: String {
        return "Token(\(type.rawValue), \"\(value)\", \(line):\(column))"
    }
}

extension Token: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}