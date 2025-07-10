import Foundation

// MARK: - Table Management System

/// Manages registration, lookup, and evaluation of random tables
public class TableManager {
    private var tables: [String: RandomTable] = [:]
    private let recursionLimit: Int
    
    public init(recursionLimit: Int = 10) {
        self.recursionLimit = recursionLimit
    }
    
    // MARK: - Table Registration
    
    /// Register a table for use in expressions
    public func registerTable(_ table: RandomTable) {
        tables[table.name] = table
    }
    
    /// Register multiple tables at once
    public func registerTables(_ tables: [RandomTable]) {
        for table in tables {
            registerTable(table)
        }
    }
    
    /// Remove a table from registration
    public func unregisterTable(named name: String) {
        tables.removeValue(forKey: name)
    }
    
    /// Clear all registered tables
    public func clearTables() {
        tables.removeAll()
    }
    
    // MARK: - Table Lookup
    
    /// Get a registered table by name
    public func getTable(named name: String) -> RandomTable? {
        return tables[name]
    }
    
    /// Get all registered table names
    public var registeredTableNames: [String] {
        return Array(tables.keys).sorted()
    }
    
    /// Check if a table is registered
    public func isTableRegistered(named name: String) -> Bool {
        return tables[name] != nil
    }
    
    // MARK: - Table Evaluation
    
    /// Evaluate a table lookup with full nested resolution
    public func evaluateTable(named name: String, with rng: RandomNumberGenerator) throws -> TableEvaluationResult {
        guard let table = tables[name] else {
            throw ParseError.invalidExpression(message: "Table not found: \(name)")
        }
        
        return try evaluateTableRecursive(table, with: rng, depth: 0)
    }
    
    /// Recursively evaluate a table, resolving all nested references
    private func evaluateTableRecursive(_ table: RandomTable, with rng: RandomNumberGenerator, depth: Int) throws -> TableEvaluationResult {
        // Check recursion limit
        if depth > recursionLimit {
            throw ParseError.invalidExpression(message: "Table recursion limit exceeded (\(recursionLimit))")
        }
        
        // Roll on the table
        let initialResult = table.roll(with: rng)
        
        // Check if there are any nested references to resolve
        let matchingEntry = findMatchingEntry(for: initialResult.roll, in: table)
        
        if let reference = matchingEntry?.reference {
            // Resolve the nested reference
            guard let nestedTable = tables[reference.tableName] else {
                throw ParseError.invalidExpression(message: "Referenced table not found: \(reference.tableName)")
            }
            
            let nestedResult = try evaluateTableRecursive(nestedTable, with: rng, depth: depth + 1)
            
            // Create a combined result
            return TableEvaluationResult(
                primaryResult: initialResult,
                nestedResults: [nestedResult],
                finalResult: nestedResult.finalResult,
                depth: depth
            )
        } else {
            // No nested reference, return the result as-is
            return TableEvaluationResult(
                primaryResult: initialResult,
                nestedResults: [],
                finalResult: initialResult.result,
                depth: depth
            )
        }
    }
    
    /// Find the table entry that matches a given roll value
    private func findMatchingEntry(for roll: Int, in table: RandomTable) -> TableEntry? {
        var currentWeight = 0
        for entry in table.entries {
            currentWeight += entry.weight
            if roll <= currentWeight {
                return entry
            }
        }
        return table.entries.last
    }
    
    // MARK: - Table Validation
    
    /// Validate all registered tables for circular references
    public func validateTables() throws {
        for (tableName, table) in tables {
            try validateTableReferences(table, visited: Set([tableName]))
        }
    }
    
    /// Recursively validate table references to detect circular dependencies
    private func validateTableReferences(_ table: RandomTable, visited: Set<String>) throws {
        for entry in table.entries {
            if let reference = entry.reference {
                let referencedTableName = reference.tableName
                
                // Check for circular reference
                if visited.contains(referencedTableName) {
                    throw ParseError.invalidExpression(message: "Circular table reference detected: \(visited.joined(separator: " → ")) → \(referencedTableName)")
                }
                
                // Check if referenced table exists
                guard let referencedTable = tables[referencedTableName] else {
                    throw ParseError.invalidExpression(message: "Referenced table not found: \(referencedTableName)")
                }
                
                // Recursively validate the referenced table
                var newVisited = visited
                newVisited.insert(referencedTableName)
                try validateTableReferences(referencedTable, visited: newVisited)
            }
        }
    }
    
    // MARK: - Bulk Operations
    
    /// Create a table manager with predefined tables
    public static func withTables(_ tables: [RandomTable]) -> TableManager {
        let manager = TableManager()
        manager.registerTables(tables)
        return manager
    }
    
    /// Export all registered tables to a dictionary
    public func exportTables() -> [String: RandomTable] {
        return tables
    }
    
    /// Import tables from a dictionary
    public func importTables(_ tableDictionary: [String: RandomTable]) {
        for (_, table) in tableDictionary {
            registerTable(table)
        }
    }
    
    // MARK: - Statistics
    
    /// Get statistics about registered tables
    public func getStatistics() -> TableManagerStatistics {
        let totalEntries = tables.values.reduce(0) { $0 + $1.entries.count }
        let tablesWithReferences = tables.values.filter { table in
            table.entries.contains { $0.reference != nil }
        }.count
        
        return TableManagerStatistics(
            totalTables: tables.count,
            totalEntries: totalEntries,
            tablesWithReferences: tablesWithReferences,
            averageEntriesPerTable: tables.isEmpty ? 0 : Double(totalEntries) / Double(tables.count)
        )
    }
}

// MARK: - Table Evaluation Result

/// Represents the result of evaluating a table lookup with nested resolution
public struct TableEvaluationResult {
    public let primaryResult: TableResult
    public let nestedResults: [TableEvaluationResult]
    public let finalResult: String
    public let depth: Int
    
    public init(primaryResult: TableResult, nestedResults: [TableEvaluationResult], finalResult: String, depth: Int) {
        self.primaryResult = primaryResult
        self.nestedResults = nestedResults
        self.finalResult = finalResult
        self.depth = depth
    }
    
    /// Get all table results in the chain
    public var allResults: [TableResult] {
        var results = [primaryResult]
        for nestedResult in nestedResults {
            results.append(contentsOf: nestedResult.allResults)
        }
        return results
    }
    
    /// Get the chain of table names that were evaluated
    public var tableChain: [String] {
        var chain = [primaryResult.tableName]
        for nestedResult in nestedResults {
            chain.append(contentsOf: nestedResult.tableChain)
        }
        return chain
    }
}

// MARK: - Table Manager Statistics

/// Statistics about a table manager's registered tables
public struct TableManagerStatistics {
    public let totalTables: Int
    public let totalEntries: Int
    public let tablesWithReferences: Int
    public let averageEntriesPerTable: Double
    
    public init(totalTables: Int, totalEntries: Int, tablesWithReferences: Int, averageEntriesPerTable: Double) {
        self.totalTables = totalTables
        self.totalEntries = totalEntries
        self.tablesWithReferences = tablesWithReferences
        self.averageEntriesPerTable = averageEntriesPerTable
    }
}

// MARK: - Table Parser

/// Parses table definitions from strings
public class TableParser {
    
    /// Parse a table definition from a multi-line string
    public static func parseTable(from definition: String) throws -> RandomTable {
        let lines = definition.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ParseError.invalidExpression(message: "Empty table definition")
        }
        
        // First line should be the table name (e.g., "@table_name")
        let firstLine = lines[0]
        guard firstLine.hasPrefix("@") else {
            throw ParseError.invalidExpression(message: "Table definition must start with @table_name")
        }
        
        let tableName = String(firstLine.dropFirst())
        guard !tableName.isEmpty else {
            throw ParseError.invalidExpression(message: "Table name cannot be empty")
        }
        
        // Parse entries
        var entries: [TableEntry] = []
        var isPercentageTable = false
        var hasRangeFormat = false
        
        for line in lines.dropFirst() {
            // Skip empty lines and comments
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            
            let entry = try parseTableEntry(line)
            entries.append(entry)
            
            // Detect table format
            if line.contains("%") {
                isPercentageTable = true
            } else if line.contains("-") || line.first?.isNumber == true {
                hasRangeFormat = true
            }
        }
        
        // Validate format consistency
        if isPercentageTable && hasRangeFormat {
            throw ParseError.invalidExpression(message: "Cannot mix percentage and range formats in the same table")
        }
        
        let table = RandomTable(name: tableName, entries: entries)
        
        // Validate the table
        try TableValidator.validateTable(table)
        
        return table
    }
    
    /// Parse a single table entry line
    private static func parseTableEntry(_ line: String) throws -> TableEntry {
        // Expected format: "weight: result [→ @reference]"
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2 else {
            throw ParseError.invalidExpression(message: "Invalid table entry format: \(line)")
        }
        
        let weightPart = parts[0].trimmingCharacters(in: .whitespaces)
        let resultPart = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
        
        // Parse weight
        let weight: Int
        if weightPart.hasSuffix("%") {
            let percentString = String(weightPart.dropLast())
            guard let percent = Int(percentString) else {
                throw ParseError.invalidExpression(message: "Invalid percentage format: \(weightPart)")
            }
            weight = percent
        } else if weightPart.contains("-") {
            let rangeParts = weightPart.components(separatedBy: "-")
            guard rangeParts.count == 2,
                  let lower = Int(rangeParts[0].trimmingCharacters(in: .whitespaces)),
                  let upper = Int(rangeParts[1].trimmingCharacters(in: .whitespaces)) else {
                throw ParseError.invalidExpression(message: "Invalid range format: \(weightPart)")
            }
            weight = upper - lower + 1
        } else {
            guard let singleWeight = Int(weightPart) else {
                throw ParseError.invalidExpression(message: "Invalid weight format: \(weightPart)")
            }
            weight = 1 // Single value represents weight of 1
        }
        
        // Parse result and reference
        let result: String
        let reference: TableReference?
        
        if resultPart.contains("→") {
            let referenceParts = resultPart.components(separatedBy: "→")
            guard referenceParts.count == 2 else {
                throw ParseError.invalidExpression(message: "Invalid reference format: \(resultPart)")
            }
            
            result = referenceParts[0].trimmingCharacters(in: .whitespaces)
            let referenceString = referenceParts[1].trimmingCharacters(in: .whitespaces)
            
            guard referenceString.hasPrefix("@") else {
                throw ParseError.invalidExpression(message: "Table reference must start with @")
            }
            
            let referencedTableName = String(referenceString.dropFirst())
            reference = TableReference(tableName: referencedTableName)
        } else {
            result = resultPart
            reference = nil
        }
        
        return TableEntry(weight: weight, result: result, reference: reference)
    }
}

// MARK: - Extensions

extension TableManager: CustomStringConvertible {
    public var description: String {
        let stats = getStatistics()
        return """
        TableManager:
          Tables: \(stats.totalTables)
          Entries: \(stats.totalEntries)
          With References: \(stats.tablesWithReferences)
          Avg Entries/Table: \(String(format: "%.1f", stats.averageEntriesPerTable))
        """
    }
}

extension TableEvaluationResult: CustomStringConvertible {
    public var description: String {
        let chain = tableChain.joined(separator: " → ")
        return "[\(chain)]: \(finalResult)"
    }
}

extension TableManagerStatistics: CustomStringConvertible {
    public var description: String {
        return """
        Table Statistics:
          Total Tables: \(totalTables)
          Total Entries: \(totalEntries)
          Tables with References: \(tablesWithReferences)
          Average Entries per Table: \(String(format: "%.1f", averageEntriesPerTable))
        """
    }
}

// MARK: - Equatable Conformance

extension TableEvaluationResult: Equatable {
    public static func == (lhs: TableEvaluationResult, rhs: TableEvaluationResult) -> Bool {
        return lhs.primaryResult == rhs.primaryResult &&
               lhs.nestedResults == rhs.nestedResults &&
               lhs.finalResult == rhs.finalResult &&
               lhs.depth == rhs.depth
    }
}

extension TableManagerStatistics: Equatable {
    public static func == (lhs: TableManagerStatistics, rhs: TableManagerStatistics) -> Bool {
        return lhs.totalTables == rhs.totalTables &&
               lhs.totalEntries == rhs.totalEntries &&
               lhs.tablesWithReferences == rhs.tablesWithReferences &&
               abs(lhs.averageEntriesPerTable - rhs.averageEntriesPerTable) < 0.001
    }
}