import Foundation

/// The main public API for the DiceLang framework
/// Provides a unified interface for parsing and evaluating dice expressions
public class DiceLangParser {
    
    /// Shared instance for convenient access
    public static let shared = DiceLangParser()
    
    /// Table manager for random table operations
    public let tableManager: TableManager
    
    /// Random number generator for dice rolls
    private let randomNumberGenerator: RandomNumberGenerator
    
    /// Initialize with custom dependencies
    /// - Parameters:
    ///   - tableManager: Custom table manager instance
    ///   - randomNumberGenerator: Custom RNG instance
    public init(tableManager: TableManager = TableManager(), randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.tableManager = tableManager
        self.randomNumberGenerator = randomNumberGenerator
    }
    
    /// Parse and evaluate a dice expression
    /// - Parameter expression: The dice expression string to evaluate
    /// - Returns: The evaluation result
    /// - Throws: ParseError if the expression is invalid
    public func evaluate(_ expression: String) throws -> DiceResult {
        let parsedExpression = try Parser.parse(expression)
        let context = EvaluationContext(randomNumberGenerator: randomNumberGenerator, tableManager: tableManager)
        return try parsedExpression.evaluate(with: context)
    }
    
    /// Parse a dice expression without evaluating it
    /// - Parameter expression: The dice expression string to parse
    /// - Returns: The parsed expression AST
    /// - Throws: ParseError if the expression is invalid
    public func parse(_ expression: String) throws -> DiceExpression {
        return try Parser.parse(expression)
    }
    
    /// Register a random table for use in expressions
    /// - Parameters:
    ///   - definition: The table definition string
    ///   - name: Optional name override (defaults to name in definition)
    /// - Throws: ParseError if the table definition is invalid
    public func registerTable(_ definition: String, name: String? = nil) throws {
        let table = try TableParser.parseTable(from: definition)
        if let overrideName = name {
            let renamedTable = RandomTable(name: overrideName, entries: table.entries)
            tableManager.registerTable(renamedTable)
        } else {
            tableManager.registerTable(table)
        }
    }
    
    /// Register a pre-built random table
    /// - Parameter table: The table to register
    public func registerTable(_ table: RandomTable) {
        tableManager.registerTable(table)
    }
    
    /// Get a registered table by name
    /// - Parameter name: The table name
    /// - Returns: The table if found, nil otherwise
    public func getTable(named name: String) -> RandomTable? {
        return tableManager.getTable(named: name)
    }
    
    /// Get all registered table names
    /// - Returns: Array of table names
    public func getTableNames() -> [String] {
        return tableManager.registeredTableNames
    }
    
    /// Clear all registered tables
    public func clearTables() {
        tableManager.clearTables()
    }
    
    /// Evaluate a table directly
    /// - Parameters:
    ///   - tableName: The name of the table to evaluate
    ///   - rng: Optional custom RNG (defaults to instance RNG)
    /// - Returns: The table evaluation result
    /// - Throws: ParseError if the table is not found or evaluation fails
    public func evaluateTable(named tableName: String, with rng: RandomNumberGenerator? = nil) throws -> TableEvaluationResult {
        let effectiveRng = rng ?? randomNumberGenerator
        return try tableManager.evaluateTable(named: tableName, with: effectiveRng)
    }
}

// MARK: - Convenience Methods

extension DiceLangParser {
    
    /// Quick evaluation of a dice expression string
    /// - Parameter expression: The dice expression to evaluate
    /// - Returns: The total value of the roll
    /// - Throws: ParseError if the expression is invalid
    public func roll(_ expression: String) throws -> Int {
        return try evaluate(expression).total
    }
    
    /// Evaluate multiple expressions in sequence
    /// - Parameter expressions: Array of expressions to evaluate
    /// - Returns: Array of results in the same order
    /// - Throws: ParseError if any expression is invalid
    public func evaluateAll(_ expressions: [String]) throws -> [DiceResult] {
        return try expressions.map { try evaluate($0) }
    }
    
    /// Validate that an expression is syntactically correct
    /// - Parameter expression: The expression to validate
    /// - Returns: True if valid, false otherwise
    public func isValid(_ expression: String) -> Bool {
        do {
            _ = try parse(expression)
            return true
        } catch {
            return false
        }
    }
    
    /// Get detailed information about a parse error
    /// - Parameter expression: The expression that failed to parse
    /// - Returns: Detailed error information, or nil if expression is valid
    public func getParseError(for expression: String) -> ParseError? {
        do {
            _ = try parse(expression)
            return nil
        } catch let error as ParseError {
            return error
        } catch {
            return ParseError.invalidExpression(message: "Unknown parsing error")
        }
    }
}

// MARK: - Table Convenience Methods

extension DiceLangParser {
    
    /// Register multiple tables from a batch definition
    /// - Parameter definitions: Dictionary of table name to definition string
    /// - Throws: ParseError if any table definition is invalid
    public func registerTables(_ definitions: [String: String]) throws {
        for (name, definition) in definitions {
            try registerTable(definition, name: name)
        }
    }
    
    /// Load tables from a configuration file
    /// - Parameter url: URL to the configuration file
    /// - Throws: ParseError or file system errors
    public func loadTables(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        
        // Simple format: each table separated by blank lines
        let tableDefinitions = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        for definition in tableDefinitions {
            try registerTable(definition)
        }
    }
    
    /// Save all registered tables to a configuration file
    /// - Parameter url: URL to save the configuration file
    /// - Throws: File system errors
    public func saveTables(to url: URL) throws {
        let tableNames = getTableNames().sorted()
        var content = ""
        
        for (index, name) in tableNames.enumerated() {
            if let table = getTable(named: name) {
                content += "@\(table.name)\n"
                for entry in table.entries {
                    // Format entry based on its weight range
                    let weight = entry.weight
                    content += "\(weight): \(entry.result)"
                    
                    if let reference = entry.reference {
                        content += " → @\(reference.tableName)"
                    }
                    content += "\n"
                }
                
                if index < tableNames.count - 1 {
                    content += "\n"
                }
            }
        }
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}