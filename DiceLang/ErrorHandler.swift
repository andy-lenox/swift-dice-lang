import Foundation

/// Comprehensive error handling utilities for DiceLang
public class ErrorHandler {
    
    /// Validate dice notation parameters
    /// - Parameters:
    ///   - dice: Number of dice
    ///   - sides: Number of sides per die
    /// - Throws: ParseError if parameters are invalid
    public static func validateDiceParameters(dice: Int, sides: Int) throws {
        guard dice > 0 else {
            throw ParseError.invalidDiceNotation(message: "Number of dice must be positive (got \(dice))")
        }
        
        guard sides > 0 else {
            throw ParseError.invalidDiceNotation(message: "Number of sides must be positive (got \(sides))")
        }
        
        guard dice <= 1000 else {
            throw ParseError.outOfRange(value: dice, min: 1, max: 1000)
        }
        
        guard sides <= 1000 else {
            throw ParseError.outOfRange(value: sides, min: 1, max: 1000)
        }
    }
    
    /// Validate keep/drop modifier parameters
    /// - Parameters:
    ///   - count: Number of dice to keep/drop
    ///   - totalDice: Total number of dice available
    /// - Throws: ParseError if parameters are invalid
    public static func validateKeepDropParameters(count: Int, totalDice: Int) throws {
        guard count > 0 else {
            throw ParseError.invalidKeepDropCount(count: count, totalDice: totalDice)
        }
        
        guard count <= totalDice else {
            throw ParseError.invalidKeepDropCount(count: count, totalDice: totalDice)
        }
    }
    
    /// Validate dice pool parameters
    /// - Parameters:
    ///   - threshold: Success threshold
    ///   - diceSides: Number of sides on each die
    /// - Throws: ParseError if parameters are invalid
    public static func validateDicePoolParameters(threshold: Int, diceSides: Int) throws {
        guard threshold > 0 else {
            throw ParseError.invalidThreshold(threshold: threshold)
        }
        
        guard threshold <= diceSides else {
            throw ParseError.invalidDicePool(message: "Threshold (\(threshold)) cannot be higher than die sides (\(diceSides))")
        }
    }
    
    /// Validate table name format
    /// - Parameter tableName: The table name to validate
    /// - Throws: ParseError if the name is invalid
    public static func validateTableName(_ tableName: String) throws {
        guard !tableName.isEmpty else {
            throw ParseError.invalidTableDefinition(message: "Table name cannot be empty")
        }
        
        guard tableName.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            throw ParseError.invalidTableDefinition(message: "Table name '\(tableName)' contains invalid characters. Only letters, numbers, and underscores are allowed.")
        }
        
        guard tableName.first?.isLetter == true else {
            throw ParseError.invalidTableDefinition(message: "Table name '\(tableName)' must start with a letter")
        }
        
        guard tableName.count <= 50 else {
            throw ParseError.invalidTableDefinition(message: "Table name '\(tableName)' is too long. Maximum length is 50 characters.")
        }
    }
    
    /// Validate table weight range
    /// - Parameters:
    ///   - lowerBound: Lower bound of the range
    ///   - upperBound: Upper bound of the range
    /// - Throws: ParseError if the range is invalid
    public static func validateTableWeightRange(lowerBound: Int, upperBound: Int) throws {
        guard lowerBound > 0 else {
            throw ParseError.invalidTableDefinition(message: "Table weight range lower bound must be positive (got \(lowerBound))")
        }
        
        guard upperBound > 0 else {
            throw ParseError.invalidTableDefinition(message: "Table weight range upper bound must be positive (got \(upperBound))")
        }
        
        guard lowerBound <= upperBound else {
            throw ParseError.invalidTableDefinition(message: "Table weight range lower bound (\(lowerBound)) cannot be greater than upper bound (\(upperBound))")
        }
        
        guard upperBound <= 1000 else {
            throw ParseError.outOfRange(value: upperBound, min: 1, max: 1000)
        }
    }
    
    /// Validate table percentage
    /// - Parameter percentage: The percentage to validate
    /// - Throws: ParseError if the percentage is invalid
    public static func validateTablePercentage(_ percentage: Int) throws {
        guard percentage > 0 else {
            throw ParseError.invalidTableDefinition(message: "Table percentage must be positive (got \(percentage))")
        }
        
        guard percentage <= 100 else {
            throw ParseError.outOfRange(value: percentage, min: 1, max: 100)
        }
    }
    
    /// Validate table entry result text
    /// - Parameter result: The result text to validate
    /// - Throws: ParseError if the result is invalid
    public static func validateTableResult(_ result: String) throws {
        guard !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParseError.invalidTableDefinition(message: "Table entry result cannot be empty")
        }
        
        guard result.count <= 500 else {
            throw ParseError.invalidTableDefinition(message: "Table entry result is too long. Maximum length is 500 characters.")
        }
    }
    
    /// Detect potential circular references in table definitions
    /// - Parameters:
    ///   - tableName: The table being evaluated
    ///   - referencePath: The current path of table references
    /// - Throws: ParseError if circular reference is detected
    public static func detectCircularReference(tableName: String, referencePath: [String]) throws {
        if referencePath.contains(tableName) {
            throw ParseError.circularTableReference(tableName: tableName, referencePath: referencePath + [tableName])
        }
    }
    
    /// Validate recursion depth
    /// - Parameters:
    ///   - currentDepth: Current recursion depth
    ///   - limit: Maximum allowed depth
    /// - Throws: ParseError if recursion limit is exceeded
    public static func validateRecursionDepth(currentDepth: Int, limit: Int) throws {
        guard currentDepth <= limit else {
            throw ParseError.recursionLimitExceeded(limit: limit)
        }
    }
    
    /// Wrap and enhance error messages with context
    /// - Parameters:
    ///   - error: The original error
    ///   - context: Additional context information
    /// - Returns: Enhanced error with context
    public static func enhanceError(_ error: Error, context: String) -> Error {
        if let parseError = error as? ParseError {
            switch parseError {
            case .invalidExpression(let message):
                return ParseError.invalidExpression(message: "\(context): \(message)")
            case .evaluationError(let message):
                return ParseError.evaluationError(message: "\(context): \(message)")
            case .invalidTableDefinition(let message):
                return ParseError.invalidTableDefinition(message: "\(context): \(message)")
            default:
                return parseError
            }
        }
        return error
    }
    
    /// Create a user-friendly error summary
    /// - Parameter error: The error to summarize
    /// - Returns: User-friendly error description
    public static func createUserFriendlyError(_ error: Error) -> String {
        if let parseError = error as? ParseError {
            switch parseError {
            case .unexpectedToken(let expected, let found):
                return "Syntax error: Expected \(expected), but found '\(found.value)' at position \(found.column)"
            case .unexpectedEndOfInput(let expected):
                return "Incomplete expression: Expected \(expected)"
            case .invalidDiceNotation(let message):
                return "Invalid dice: \(message)"
            case .divisionByZero:
                return "Math error: Cannot divide by zero"
            case .tableNotFound(let tableName):
                return "Missing table: '\(tableName)' was not found"
            case .circularTableReference(let tableName, _):
                return "Circular reference: Table '\(tableName)' references itself"
            case .recursionLimitExceeded(_):
                return "Too many nested table references"
            case .invalidKeepDropCount(let count, let totalDice):
                return "Cannot keep/drop \(count) dice from only \(totalDice) dice"
            case .invalidThreshold(let threshold):
                return "Invalid success threshold: \(threshold)"
            case .outOfRange(let value, let min, let max):
                return "Value \(value) is out of range (expected \(min)-\(max))"
            default:
                return parseError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Error Recovery Utilities

extension ErrorHandler {
    
    /// Attempt to recover from parsing errors by suggesting corrections
    /// - Parameters:
    ///   - expression: The original expression that failed
    ///   - error: The parsing error
    /// - Returns: Suggested correction or nil if no recovery is possible
    public static func suggestCorrection(for expression: String, error: ParseError) -> String? {
        switch error {
        case .unexpectedToken(let expected, let found):
            if expected == "number" && found.type == .identifier {
                return "Did you mean to add a 'd' before '\(found.value)'? Try 'd\(found.value)'"
            }
            
        case .unclosedParentheses:
            let openCount = expression.filter { $0 == "(" }.count
            let closeCount = expression.filter { $0 == ")" }.count
            if openCount > closeCount {
                return "Try adding \(openCount - closeCount) closing parenthesis: \(expression + String(repeating: ")", count: openCount - closeCount))"
            }
            
        case .invalidDiceNotation(let message) where message.contains("Number of dice must be positive"):
            return "Dice count must be positive. Try '1d6' instead of '0d6'"
            
        case .divisionByZero:
            return "Make sure you're not dividing by zero. Check your expression for '/0' or variables that might be zero"
            
        case .tableNotFound(let tableName):
            return "Register the table '\(tableName)' before using it, or check the table name spelling"
            
        default:
            break
        }
        
        return nil
    }
    
    /// Validate an expression and return detailed validation results
    /// - Parameter expression: The expression to validate
    /// - Returns: Validation result with errors and warnings
    public static func validateExpression(_ expression: String) -> ValidationResult {
        var errors: [ParseError] = []
        var warnings: [String] = []
        
        do {
            _ = try Parser.parse(expression)
        } catch let error as ParseError {
            errors.append(error)
        } catch {
            errors.append(ParseError.invalidExpression(message: "Unknown parsing error"))
        }
        
        // Check for potential issues
        if expression.contains("d0") {
            warnings.append("Dice with 0 sides detected. This will cause an error.")
        }
        
        if expression.contains("/0") {
            warnings.append("Division by zero detected. This will cause an error.")
        }
        
        if expression.filter({ $0 == "(" }).count != expression.filter({ $0 == ")" }).count {
            warnings.append("Mismatched parentheses detected.")
        }
        
        return ValidationResult(errors: errors, warnings: warnings)
    }
}

// MARK: - Validation Result

public struct ValidationResult {
    public let errors: [ParseError]
    public let warnings: [String]
    
    public var isValid: Bool {
        return errors.isEmpty
    }
    
    public var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}

// MARK: - Error Context

public struct ErrorContext {
    public let expression: String
    public let position: Int?
    public let operation: String?
    public let additionalInfo: [String: Any]?
    
    public init(expression: String, position: Int? = nil, operation: String? = nil, additionalInfo: [String: Any]? = nil) {
        self.expression = expression
        self.position = position
        self.operation = operation
        self.additionalInfo = additionalInfo
    }
}