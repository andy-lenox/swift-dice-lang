import Foundation

public class Parser {
    private let tokens: [Token]
    private var current: Int = 0
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    // MARK: - Public API
    
    public func parse() throws -> DiceExpression {
        let expression = try parseExpression()
        
        if !isAtEnd() {
            let unexpectedToken = peek()
            throw ParseError.unexpectedToken(expected: "end of input", found: unexpectedToken)
        }
        
        return expression
    }
    
    // MARK: - Expression Parsing (Precedence Climbing)
    
    private func parseExpression() throws -> DiceExpression {
        return try parseAddition()
    }
    
    private func parseAddition() throws -> DiceExpression {
        var expr = try parseMultiplication()
        
        while match(.plus, .minus) {
            let operatorToken = previous()
            let right = try parseMultiplication()
            
            let op: BinaryExpression.Operator
            switch operatorToken.type {
            case .plus:
                op = .add
            case .minus:
                op = .subtract
            default:
                throw ParseError.invalidExpression(message: "Invalid operator: \(operatorToken.value)")
            }
            
            expr = BinaryExpression(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func parseMultiplication() throws -> DiceExpression {
        var expr = try parseUnary()
        
        while match(.multiply, .divide) {
            let operatorToken = previous()
            let right = try parseUnary()
            
            let op: BinaryExpression.Operator
            switch operatorToken.type {
            case .multiply:
                op = .multiply
            case .divide:
                op = .divide
            default:
                throw ParseError.invalidExpression(message: "Invalid operator: \(operatorToken.value)")
            }
            
            expr = BinaryExpression(left: expr, operator: op, right: right)
        }
        
        return expr
    }
    
    private func parseUnary() throws -> DiceExpression {
        if match(.minus, .plus) {
            let operatorToken = previous()
            let expr = try parseUnary()
            
            let op: UnaryExpression.Operator
            switch operatorToken.type {
            case .minus:
                op = .negate
            case .plus:
                op = .positive
            default:
                throw ParseError.invalidExpression(message: "Invalid unary operator: \(operatorToken.value)")
            }
            
            return UnaryExpression(operator: op, operand: expr)
        }
        
        return try parsePrimary()
    }
    
    private func parsePrimary() throws -> DiceExpression {
        // Handle tagged dice groups
        if match(.leftBracket) {
            return try parseTaggedDiceGroup()
        }
        
        // Handle parentheses
        if match(.leftParen) {
            let expr = try parseExpression()
            if !match(.rightParen) {
                throw ParseError.unexpectedToken(expected: ")", found: peek())
            }
            return GroupExpression(expr)
        }
        
        // Handle table lookups (@table_name)
        if match(.at) {
            return try parseTableLookup()
        }
        
        // Handle numbers (potential dice or literals)
        if check(.number) {
            return try parseNumberOrDice()
        }
        
        // Handle dice notation starting with 'd' (like d20)
        if match(.dice) {
            return try parseDiceWithoutCount()
        }
        
        // If we get here, we have an unexpected token
        if isAtEnd() {
            throw ParseError.unexpectedEndOfInput(expected: "expression")
        } else {
            throw ParseError.unexpectedToken(expected: "number, dice, '[', '@', or '('", found: peek())
        }
    }
    
    private func parseNumberOrDice() throws -> DiceExpression {
        let numberToken = advance()
        guard let number = Int(numberToken.value) else {
            throw ParseError.invalidNumber(value: numberToken.value)
        }
        
        // Check if this is a dice roll (number followed by 'd')
        if match(.dice) {
            return try parseDiceRoll(count: number)
        }
        
        // Just a literal number
        return LiteralExpression(number)
    }
    
    private func parseDiceWithoutCount() throws -> DiceExpression {
        // We already consumed the 'd', now we need the sides
        if !check(.number) {
            throw ParseError.unexpectedToken(expected: "number", found: peek())
        }
        
        return try parseDiceRoll(count: 1)
    }
    
    private func parseDiceRoll(count: Int) throws -> DiceExpression {
        // Parse the sides
        if !check(.number) {
            throw ParseError.unexpectedToken(expected: "number", found: peek())
        }
        
        let sidesToken = advance()
        guard let sides = Int(sidesToken.value) else {
            throw ParseError.invalidNumber(value: sidesToken.value)
        }
        
        guard sides > 0 else {
            throw ParseError.invalidDiceNotation(message: "Dice must have at least 1 side")
        }
        
        guard count > 0 else {
            throw ParseError.invalidDiceNotation(message: "Must roll at least 1 die")
        }
        
        let baseDiceExpression = DiceRollExpression(count: count, sides: sides)
        
        // Check for modifiers
        return try parseModifiers(for: baseDiceExpression)
    }
    
    private func parseModifiers(for diceExpression: DiceRollExpression) throws -> DiceExpression {
        var modifiers: [DiceModifier] = []
        
        // Parse exploding modifiers first
        if match(.explode) {
            modifiers.append(.exploding)
        } else if match(.compoundExplode) {
            modifiers.append(.compoundExploding)
        }
        
        // Handle keep/drop modifiers (both short and long form)
        if match(.keepHighest, .keepLowest, .dropHighest, .dropLowest, .keep, .drop) {
            let modifierToken = previous()
            
            let modifier: DiceModifier
            
            // Handle long form keep/drop syntax
            if modifierToken.type == .keep {
                // Expect "highest" or "lowest"
                if match(.highest) {
                    // Expect a number after "highest"
                    if !check(.number) {
                        throw ParseError.unexpectedToken(expected: "number", found: peek())
                    }
                    let countToken = advance()
                    guard let count = Int(countToken.value) else {
                        throw ParseError.invalidNumber(value: countToken.value)
                    }
                    
                    // Validate keep count
                    guard count > 0 else {
                        throw ParseError.invalidDiceNotation(message: "Keep count must be positive")
                    }
                    guard count <= diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot keep more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    
                    modifier = .keepHighest(count)
                } else if match(.lowest) {
                    // Expect a number after "lowest"
                    if !check(.number) {
                        throw ParseError.unexpectedToken(expected: "number", found: peek())
                    }
                    let countToken = advance()
                    guard let count = Int(countToken.value) else {
                        throw ParseError.invalidNumber(value: countToken.value)
                    }
                    
                    // Validate keep count
                    guard count > 0 else {
                        throw ParseError.invalidDiceNotation(message: "Keep count must be positive")
                    }
                    guard count <= diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot keep more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    
                    modifier = .keepLowest(count)
                } else {
                    throw ParseError.unexpectedToken(expected: "highest or lowest", found: peek())
                }
            } else if modifierToken.type == .drop {
                // Expect "highest" or "lowest"
                if match(.highest) {
                    // Expect a number after "highest"
                    if !check(.number) {
                        throw ParseError.unexpectedToken(expected: "number", found: peek())
                    }
                    let countToken = advance()
                    guard let count = Int(countToken.value) else {
                        throw ParseError.invalidNumber(value: countToken.value)
                    }
                    
                    // Validate drop count
                    guard count > 0 else {
                        throw ParseError.invalidDiceNotation(message: "Drop count must be positive")
                    }
                    guard count < diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot drop all or more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    
                    modifier = .dropHighest(count)
                } else if match(.lowest) {
                    // Expect a number after "lowest"
                    if !check(.number) {
                        throw ParseError.unexpectedToken(expected: "number", found: peek())
                    }
                    let countToken = advance()
                    guard let count = Int(countToken.value) else {
                        throw ParseError.invalidNumber(value: countToken.value)
                    }
                    
                    // Validate drop count
                    guard count > 0 else {
                        throw ParseError.invalidDiceNotation(message: "Drop count must be positive")
                    }
                    guard count < diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot drop all or more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    
                    modifier = .dropLowest(count)
                } else {
                    throw ParseError.unexpectedToken(expected: "highest or lowest", found: peek())
                }
            } else {
                // Handle short form modifiers (kh, kl, dh, dl)
                // Expect a number after the modifier
                if !check(.number) {
                    throw ParseError.unexpectedToken(expected: "number", found: peek())
                }
                
                let countToken = advance()
                guard let count = Int(countToken.value) else {
                    throw ParseError.invalidNumber(value: countToken.value)
                }
                
                // Validate count based on modifier type
                guard count > 0 else {
                    throw ParseError.invalidDiceNotation(message: "Modifier count must be positive")
                }
                
                switch modifierToken.type {
                case .keepHighest, .keepLowest:
                    guard count <= diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot keep more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    modifier = modifierToken.type == .keepHighest ? .keepHighest(count) : .keepLowest(count)
                case .dropHighest, .dropLowest:
                    guard count < diceExpression.count else {
                        throw ParseError.invalidDiceNotation(message: "Cannot drop all or more dice (\(count)) than are being rolled (\(diceExpression.count))")
                    }
                    modifier = modifierToken.type == .dropHighest ? .dropHighest(count) : .dropLowest(count)
                default:
                    throw ParseError.invalidExpression(message: "Invalid modifier: \(modifierToken.value)")
                }
            }
            
            modifiers.append(modifier)
        }
        
        // Handle threshold modifiers (dice pools)
        if match(.greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual) {
            let operatorToken = previous()
            
            if !check(.number) {
                throw ParseError.unexpectedToken(expected: "number", found: peek())
            }
            
            let valueToken = advance()
            guard let value = Int(valueToken.value) else {
                throw ParseError.invalidNumber(value: valueToken.value)
            }
            
            // Validate threshold value
            guard value >= 0 else {
                throw ParseError.invalidDiceNotation(message: "Threshold value must be non-negative")
            }
            
            // Note: Allow thresholds higher than die sides
            // This is valid in some systems where you want impossible thresholds
            
            let comparisonOp: DiceModifier.ComparisonOperator
            switch operatorToken.type {
            case .greaterThan:
                comparisonOp = .greaterThan
            case .greaterThanOrEqual:
                comparisonOp = .greaterThanOrEqual
            case .lessThan:
                comparisonOp = .lessThan
            case .lessThanOrEqual:
                comparisonOp = .lessThanOrEqual
            default:
                throw ParseError.invalidExpression(message: "Invalid comparison operator: \(operatorToken.value)")
            }
            
            let modifier = DiceModifier.threshold(comparisonOp, value)
            modifiers.append(modifier)
        }
        
        // Return appropriate expression based on number of modifiers
        if modifiers.isEmpty {
            return diceExpression
        } else if modifiers.count == 1 {
            return ModifiedDiceExpression(diceExpression: diceExpression, modifier: modifiers[0])
        } else {
            return MultiModifiedDiceExpression(diceExpression: diceExpression, modifiers: modifiers)
        }
    }
    
    // MARK: - Tagged Dice Parsing
    
    private func parseTaggedDiceGroup() throws -> DiceExpression {
        // Parse tagged dice: [tag1: dX, tag2: dY] => outcome_rule
        var taggedDice: [TaggedDie] = []
        
        // Parse first tagged die
        if !check(.identifier) {
            throw ParseError.unexpectedToken(expected: "tag identifier", found: peek())
        }
        
        let firstTag = advance().value
        
        if !match(.colon) {
            throw ParseError.unexpectedToken(expected: ":", found: peek())
        }
        
        let firstDiceExpr = try parseUnary()
        taggedDice.append(TaggedDie(tag: firstTag, diceExpression: firstDiceExpr))
        
        // Parse additional tagged dice
        while match(.comma) {
            if !check(.identifier) {
                throw ParseError.unexpectedToken(expected: "tag identifier", found: peek())
            }
            
            let tag = advance().value
            
            if !match(.colon) {
                throw ParseError.unexpectedToken(expected: ":", found: peek())
            }
            
            let diceExpr = try parseUnary()
            taggedDice.append(TaggedDie(tag: tag, diceExpression: diceExpr))
        }
        
        if !match(.rightBracket) {
            throw ParseError.unexpectedToken(expected: "]", found: peek())
        }
        
        // Parse outcome rule
        if !match(.arrow) {
            throw ParseError.unexpectedToken(expected: "=>", found: peek())
        }
        
        let outcomeRule = try parseOutcomeRule()
        
        return TaggedGroup(taggedDice: taggedDice, outcomeRule: outcomeRule)
    }
    
    private func parseOutcomeRule() throws -> OutcomeRule {
        // Currently only supports "higher_tag determines outcome"
        if match(.higherTag) {
            if !match(.determines) {
                throw ParseError.unexpectedToken(expected: "determines", found: peek())
            }
            if !match(.outcome) {
                throw ParseError.unexpectedToken(expected: "outcome", found: peek())
            }
            return HigherTagDeterminesOutcome()
        } else {
            throw ParseError.unexpectedToken(expected: "higher_tag", found: peek())
        }
    }
    
    // MARK: - Table Lookup Parsing
    
    private func parseTableLookup() throws -> DiceExpression {
        // Parse table name after @
        if !check(.identifier) {
            throw ParseError.unexpectedToken(expected: "table name", found: peek())
        }
        
        let tableName = advance().value
        
        return TableLookupExpression(tableName: tableName)
    }
    
    // MARK: - Token Utilities
    
    private func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                _ = advance()
                return true
            }
        }
        return false
    }
    
    private func check(_ type: TokenType) -> Bool {
        if isAtEnd() { return false }
        return peek().type == type
    }
    
    private func advance() -> Token {
        if !isAtEnd() { current += 1 }
        return previous()
    }
    
    private func isAtEnd() -> Bool {
        return peek().type == .eof
    }
    
    private func peek() -> Token {
        return tokens[current]
    }
    
    private func previous() -> Token {
        return tokens[current - 1]
    }
}

// MARK: - Convenience Parsing Functions

extension Parser {
    public static func parse(_ input: String) throws -> DiceExpression {
        let lexer = Lexer(input: input)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        return try parser.parse()
    }
    
    public static func parseAndEvaluate(_ input: String, context: EvaluationContext = EvaluationContext()) throws -> DiceResult {
        let expression = try parse(input)
        return try expression.evaluate(with: context)
    }
}