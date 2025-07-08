import Foundation

public class Lexer {
    private let input: String
    private var position: Int = 0
    private var line: Int = 1
    private var column: Int = 1
    private var current: Character? {
        guard position < input.count else { return nil }
        return input[input.index(input.startIndex, offsetBy: position)]
    }
    
    public init(input: String) {
        self.input = input
    }
    
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        
        while let char = current {
            switch char {
            case " ", "\t":
                skipWhitespace()
            case "\n":
                tokens.append(Token(type: .newline, value: "\n", position: position, line: line, column: column))
                advance()
                line += 1
                column = 1
            case "(":
                tokens.append(Token(type: .leftParen, value: "(", position: position, line: line, column: column))
                advance()
            case ")":
                tokens.append(Token(type: .rightParen, value: ")", position: position, line: line, column: column))
                advance()
            case "[":
                tokens.append(Token(type: .leftBracket, value: "[", position: position, line: line, column: column))
                advance()
            case "]":
                tokens.append(Token(type: .rightBracket, value: "]", position: position, line: line, column: column))
                advance()
            case ",":
                tokens.append(Token(type: .comma, value: ",", position: position, line: line, column: column))
                advance()
            case ":":
                tokens.append(Token(type: .colon, value: ":", position: position, line: line, column: column))
                advance()
            case "+":
                tokens.append(Token(type: .plus, value: "+", position: position, line: line, column: column))
                advance()
            case "-":
                if peek() == ">" {
                    tokens.append(Token(type: .arrow, value: "->", position: position, line: line, column: column))
                    advance()
                    advance()
                } else {
                    tokens.append(Token(type: .minus, value: "-", position: position, line: line, column: column))
                    advance()
                }
            case "*":
                tokens.append(Token(type: .multiply, value: "*", position: position, line: line, column: column))
                advance()
            case "/":
                tokens.append(Token(type: .divide, value: "/", position: position, line: line, column: column))
                advance()
            case "=":
                if peek() == ">" {
                    tokens.append(Token(type: .arrow, value: "=>", position: position, line: line, column: column))
                    advance()
                    advance()
                } else {
                    tokens.append(Token(type: .unknown, value: "=", position: position, line: line, column: column))
                    advance()
                }
            case ">":
                if peek() == "=" {
                    tokens.append(Token(type: .greaterThanOrEqual, value: ">=", position: position, line: line, column: column))
                    advance()
                    advance()
                } else {
                    tokens.append(Token(type: .greaterThan, value: ">", position: position, line: line, column: column))
                    advance()
                }
            case "<":
                if peek() == "=" {
                    tokens.append(Token(type: .lessThanOrEqual, value: "<=", position: position, line: line, column: column))
                    advance()
                    advance()
                } else {
                    tokens.append(Token(type: .lessThan, value: "<", position: position, line: line, column: column))
                    advance()
                }
            case "!":
                if peek() == "!" {
                    tokens.append(Token(type: .compoundExplode, value: "!!", position: position, line: line, column: column))
                    advance()
                    advance()
                } else {
                    tokens.append(Token(type: .explode, value: "!", position: position, line: line, column: column))
                    advance()
                }
            case "@":
                tokens.append(Token(type: .at, value: "@", position: position, line: line, column: column))
                advance()
            case "%":
                tokens.append(Token(type: .percent, value: "%", position: position, line: line, column: column))
                advance()
            default:
                if char.isNumber {
                    tokens.append(tokenizeNumber())
                } else if char.isLetter || char == "_" {
                    // Check if this might be a standalone 'd' for dice notation
                    if (char == "d" || char == "D") && !isPartOfIdentifier() {
                        tokens.append(Token(type: .dice, value: String(char), position: position, line: line, column: column))
                        advance()
                    } else {
                        tokens.append(tokenizeIdentifier())
                    }
                } else {
                    tokens.append(Token(type: .unknown, value: String(char), position: position, line: line, column: column))
                    advance()
                }
            }
        }
        
        tokens.append(Token(type: .eof, value: "", position: position, line: line, column: column))
        return tokens
    }
    
    private func advance() {
        position += 1
        column += 1
    }
    
    private func peek() -> Character? {
        let nextPosition = position + 1
        guard nextPosition < input.count else { return nil }
        return input[input.index(input.startIndex, offsetBy: nextPosition)]
    }
    
    private func skipWhitespace() {
        while let char = current, char == " " || char == "\t" {
            advance()
        }
    }
    
    private func tokenizeNumber() -> Token {
        let startPosition = position
        let startLine = line
        let startColumn = column
        var value = ""
        
        while let char = current, char.isNumber {
            value += String(char)
            advance()
        }
        
        return Token(type: .number, value: value, position: startPosition, line: startLine, column: startColumn)
    }
    
    private func tokenizeIdentifier() -> Token {
        let startPosition = position
        let startLine = line
        let startColumn = column
        var value = ""
        
        // First, collect only letters and underscores
        while let char = current, char.isLetter || char == "_" {
            value += String(char)
            advance()
        }
        
        // Check if this might be a keep/drop modifier followed by numbers
        if isKeepDropModifier(value) && current?.isNumber == true {
            // This is a keep/drop modifier followed by numbers
            // We'll return just the modifier part and let the next tokenization handle the number
            position = startPosition + value.count
            column = startColumn + value.count
        } else {
            // Continue collecting numbers if this isn't a keep/drop modifier
            while let char = current, char.isNumber {
                value += String(char)
                advance()
            }
        }
        
        // Check for keywords
        let tokenType = keywordType(for: value)
        return Token(type: tokenType, value: value, position: startPosition, line: startLine, column: startColumn)
    }
    
    private func isKeepDropModifier(_ value: String) -> Bool {
        return value.lowercased() == "kh" || value.lowercased() == "kl" || 
               value.lowercased() == "dh" || value.lowercased() == "dl"
    }
    
    private func isPartOfIdentifier() -> Bool {
        // Check if the next character would make this part of a larger identifier
        // For 'd'/'D', we only treat it as dice if followed by a number
        guard let nextChar = peek() else { return false }
        
        if current == "d" || current == "D" {
            return nextChar.isLetter || nextChar == "_" // Only letters/underscore continue identifier
        }
        
        return nextChar.isLetter || nextChar.isNumber || nextChar == "_"
    }
    
    private func keywordType(for value: String) -> TokenType {
        switch value.lowercased() {
        case "kh":
            return .keepHighest
        case "kl":
            return .keepLowest
        case "dh":
            return .dropHighest
        case "dl":
            return .dropLowest
        case "keep":
            return .keep
        case "drop":
            return .drop
        case "highest":
            return .highest
        case "lowest":
            return .lowest
        case "higher_tag":
            return .higherTag
        case "determines":
            return .determines
        case "outcome":
            return .outcome
        default:
            return .identifier
        }
    }
}