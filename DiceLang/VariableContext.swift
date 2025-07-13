import Foundation

/// Manages variable storage and resolution for the dice language
public class VariableContext {
    private var variables: [String: DiceExpression] = [:]
    
    public init() {}
    
    /// Declares a new variable with the given name and expression
    /// - Parameters:
    ///   - name: The variable name
    ///   - expression: The expression to store
    /// - Throws: ParseError if the variable is already declared
    public func declare(_ name: String, expression: DiceExpression) throws {
        guard variables[name] == nil else {
            throw ParseError.invalidExpression(message: "Variable '\(name)' is already declared. Variables are immutable.")
        }
        variables[name] = expression
    }
    
    /// Retrieves the expression for a variable
    /// - Parameter name: The variable name
    /// - Returns: The stored expression
    /// - Throws: ParseError if the variable is not found
    public func get(_ name: String) throws -> DiceExpression {
        guard let expression = variables[name] else {
            throw ParseError.evaluationError(message: "Variable '\(name)' is not defined")
        }
        return expression
    }
    
    /// Checks if a variable is declared
    /// - Parameter name: The variable name
    /// - Returns: true if the variable exists
    public func contains(_ name: String) -> Bool {
        return variables[name] != nil
    }
    
    /// Returns all declared variable names
    public var declaredVariables: [String] {
        return Array(variables.keys)
    }
    
    /// Clears all variables
    public func clear() {
        variables.removeAll()
    }
    
    /// Creates a copy of this variable context
    public func copy() -> VariableContext {
        let newContext = VariableContext()
        newContext.variables = self.variables
        return newContext
    }
}

/// Error types specific to variable operations
extension ParseError {
    public static func variableAlreadyDeclared(_ name: String) -> ParseError {
        return .invalidExpression(message: "Variable '\(name)' is already declared. Variables are immutable.")
    }
    
    public static func variableNotFound(_ name: String) -> ParseError {
        return .evaluationError(message: "Variable '\(name)' is not defined")
    }
}