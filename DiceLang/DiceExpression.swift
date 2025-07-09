import Foundation

// MARK: - AST Node Protocols

public protocol DiceExpression {
    func evaluate(with context: EvaluationContext) throws -> DiceResult
    var description: String { get }
}

public protocol Visitable {
    func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result
}

public protocol DiceExpressionVisitor {
    associatedtype Result
    
    func visit(_ expression: LiteralExpression) throws -> Result
    func visit(_ expression: DiceRollExpression) throws -> Result
    func visit(_ expression: BinaryExpression) throws -> Result
    func visit(_ expression: UnaryExpression) throws -> Result
    func visit(_ expression: GroupExpression) throws -> Result
    func visit(_ expression: ModifiedDiceExpression) throws -> Result
    func visit(_ expression: MultiModifiedDiceExpression) throws -> Result
    func visit(_ expression: TaggedGroup) throws -> Result
}

// MARK: - Evaluation Context

public struct EvaluationContext {
    public let randomNumberGenerator: RandomNumberGenerator
    public let diceRoller: DiceRoller
    
    public init(randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.randomNumberGenerator = randomNumberGenerator
        self.diceRoller = DiceRoller(randomNumberGenerator: randomNumberGenerator)
    }
}

// MARK: - Parse Errors

public enum ParseError: Error, LocalizedError {
    case unexpectedToken(expected: String, found: Token)
    case unexpectedEndOfInput(expected: String)
    case invalidExpression(message: String)
    case invalidNumber(value: String)
    case invalidDiceNotation(message: String)
    case missingOperand(`operator`: String)
    case unclosedParentheses
    case unexpectedCharacter(character: Character, position: Int)
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedToken(let expected, let found):
            return "Expected \(expected), but found '\(found.value)' at line \(found.line), column \(found.column)"
        case .unexpectedEndOfInput(let expected):
            return "Unexpected end of input. Expected \(expected)"
        case .invalidExpression(let message):
            return "Invalid expression: \(message)"
        case .invalidNumber(let value):
            return "Invalid number: '\(value)'"
        case .invalidDiceNotation(let message):
            return "Invalid dice notation: \(message)"
        case .missingOperand(let `operator`):
            return "Missing operand for operator '\(`operator`)'"
        case .unclosedParentheses:
            return "Unclosed parentheses in expression"
        case .unexpectedCharacter(let character, let position):
            return "Unexpected character '\(character)' at position \(position)"
        }
    }
}

// MARK: - AST Node Implementations

public struct LiteralExpression: DiceExpression, Visitable {
    public let value: Int
    
    public init(_ value: Int) {
        self.value = value
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        return DiceResult(
            rolls: [value],
            total: value,
            breakdown: DiceBreakdown(originalRolls: [value]),
            type: .literal
        )
    }
    
    public var description: String {
        return "\(value)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct DiceRollExpression: DiceExpression, Visitable {
    public let count: Int
    public let sides: Int
    
    public init(count: Int, sides: Int) {
        self.count = count
        self.sides = sides
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        let diceRoll = DiceRoll(count: count, sides: sides)
        return context.diceRoller.roll(diceRoll)
    }
    
    public var description: String {
        return "\(count)d\(sides)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct BinaryExpression: DiceExpression, Visitable {
    public enum Operator: String, CaseIterable {
        case add = "+"
        case subtract = "-"
        case multiply = "*"
        case divide = "/"
        
        public var precedence: Int {
            switch self {
            case .multiply, .divide:
                return 2
            case .add, .subtract:
                return 1
            }
        }
        
        public var isLeftAssociative: Bool {
            return true
        }
    }
    
    public let left: DiceExpression
    public let `operator`: Operator
    public let right: DiceExpression
    
    public init(left: DiceExpression, operator: Operator, right: DiceExpression) {
        self.left = left
        self.`operator` = `operator`
        self.right = right
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        let leftResult = try left.evaluate(with: context)
        let rightResult = try right.evaluate(with: context)
        
        let result: Int
        switch self.`operator` {
        case .add:
            result = leftResult.total + rightResult.total
        case .subtract:
            result = leftResult.total - rightResult.total
        case .multiply:
            result = leftResult.total * rightResult.total
        case .divide:
            guard rightResult.total != 0 else {
                throw ParseError.invalidExpression(message: "Division by zero")
            }
            result = leftResult.total / rightResult.total
        }
        
        return DiceResult(
            rolls: [result],
            total: result,
            breakdown: DiceBreakdown(
                originalRolls: [result],
                modifierDescription: "\(leftResult.total) \(self.`operator`.rawValue) \(rightResult.total)"
            ),
            type: DiceResult.ResultType.arithmetic
        )
    }
    
    public var description: String {
        return "(\(left.description) \(self.`operator`.rawValue) \(right.description))"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct UnaryExpression: DiceExpression, Visitable {
    public enum Operator: String, CaseIterable {
        case negate = "-"
        case positive = "+"
    }
    
    public let `operator`: Operator
    public let operand: DiceExpression
    
    public init(operator: Operator, operand: DiceExpression) {
        self.`operator` = `operator`
        self.operand = operand
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        let operandResult = try operand.evaluate(with: context)
        
        let result: Int
        switch self.`operator` {
        case .negate:
            result = -operandResult.total
        case .positive:
            result = operandResult.total
        }
        
        return DiceResult(
            rolls: [result],
            total: result,
            breakdown: DiceBreakdown(
                originalRolls: [result],
                modifierDescription: "\(self.`operator`.rawValue)\(operandResult.total)"
            ),
            type: DiceResult.ResultType.arithmetic
        )
    }
    
    public var description: String {
        return "\(self.`operator`.rawValue)\(operand.description)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct GroupExpression: DiceExpression, Visitable {
    public let expression: DiceExpression
    
    public init(_ expression: DiceExpression) {
        self.expression = expression
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        return try expression.evaluate(with: context)
    }
    
    public var description: String {
        return "(\(expression.description))"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct ModifiedDiceExpression: DiceExpression, Visitable {
    public let diceExpression: DiceRollExpression
    public let modifier: DiceModifier
    
    public init(diceExpression: DiceRollExpression, modifier: DiceModifier) {
        self.diceExpression = diceExpression
        self.modifier = modifier
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        let diceRoll = DiceRoll(count: diceExpression.count, sides: diceExpression.sides, modifier: modifier)
        return context.diceRoller.roll(diceRoll)
    }
    
    public var description: String {
        return "\(diceExpression.description)\(modifier.description)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

public struct MultiModifiedDiceExpression: DiceExpression, Visitable {
    public let diceExpression: DiceRollExpression
    public let modifiers: [DiceModifier]
    
    public init(diceExpression: DiceRollExpression, modifiers: [DiceModifier]) {
        self.diceExpression = diceExpression
        self.modifiers = modifiers
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        // Apply modifiers in sequence
        // For now, we'll need to apply them one by one
        // This requires extending DiceRoll to support multiple modifiers
        // or applying them sequentially
        
        // Start with base dice roll
        var currentResult = context.diceRoller.roll(DiceRoll(count: diceExpression.count, sides: diceExpression.sides))
        
        // Apply each modifier in sequence
        for modifier in modifiers {
            // For complex chaining, we'd need to apply modifiers to the result
            // This is a simplified approach that applies the last modifier only
            let diceRoll = DiceRoll(count: diceExpression.count, sides: diceExpression.sides, modifier: modifier)
            currentResult = context.diceRoller.roll(diceRoll)
        }
        
        return currentResult
    }
    
    public var description: String {
        let modifierDescriptions = modifiers.map { $0.description }.joined()
        return "\(diceExpression.description)\(modifierDescriptions)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

// MARK: - DiceResult Type Extension

extension DiceResult {
    public enum ResultType {
        case literal
        case standard
        case exploding
        case compoundExploding
        case keepDrop
        case pool
        case arithmetic
    }
}

extension DiceResult {
    public init(rolls: [Int], total: Int, breakdown: DiceBreakdown, type: ResultType) {
        self.init(rolls: rolls, total: total, breakdown: breakdown, type: convertResultType(type))
    }
}

private func convertResultType(_ type: DiceResult.ResultType) -> DiceResultType {
    switch type {
    case .literal, .arithmetic:
        return .standard
    case .standard:
        return .standard
    case .exploding:
        return .exploding
    case .compoundExploding:
        return .compoundExploding
    case .keepDrop:
        return .keepDrop
    case .pool:
        return .pool
    }
}