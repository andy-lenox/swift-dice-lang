import Foundation

// MARK: - Random Table System

/// Represents a random table with weighted entries
public struct RandomTable {
    public let name: String
    public let entries: [TableEntry]
    public let totalWeight: Int
    
    public init(name: String, entries: [TableEntry]) {
        self.name = name
        self.entries = entries
        self.totalWeight = entries.reduce(0) { $0 + $1.weight }
    }
    
    /// Roll on this table using the provided random number generator
    public func roll(with rng: RandomNumberGenerator) -> TableResult {
        let roll = rng.roll(sides: totalWeight)
        
        var currentWeight = 0
        for entry in entries {
            currentWeight += entry.weight
            if roll <= currentWeight {
                return TableResult(
                    tableName: name,
                    roll: roll,
                    result: entry.result,
                    nestedResults: nil
                )
            }
        }
        
        // Fallback to last entry if something goes wrong
        let lastEntry = entries.last!
        return TableResult(
            tableName: name,
            roll: roll,
            result: lastEntry.result,
            nestedResults: nil
        )
    }
    
    /// Create a table from range-based entries (e.g., "1-2: Goblins")
    public static func fromRangeEntries(name: String, rangeEntries: [RangeTableEntry]) -> RandomTable {
        let entries = rangeEntries.map { rangeEntry in
            let weight = rangeEntry.range.upperBound - rangeEntry.range.lowerBound + 1
            return TableEntry(
                weight: weight,
                result: rangeEntry.result,
                reference: rangeEntry.reference
            )
        }
        return RandomTable(name: name, entries: entries)
    }
    
    /// Create a table from percentage-based entries (e.g., "50%: Common")
    public static func fromPercentageEntries(name: String, percentageEntries: [PercentageTableEntry]) -> RandomTable {
        let entries = percentageEntries.map { percentEntry in
            TableEntry(
                weight: percentEntry.percentage,
                result: percentEntry.result,
                reference: percentEntry.reference
            )
        }
        return RandomTable(name: name, entries: entries)
    }
}

/// Represents a single entry in a random table
public struct TableEntry {
    public let weight: Int
    public let result: String
    public let reference: TableReference?
    
    public init(weight: Int, result: String, reference: TableReference? = nil) {
        self.weight = weight
        self.result = result
        self.reference = reference
    }
}

/// Represents a range-based table entry (e.g., "1-2: Goblins")
public struct RangeTableEntry {
    public let range: ClosedRange<Int>
    public let result: String
    public let reference: TableReference?
    
    public init(range: ClosedRange<Int>, result: String, reference: TableReference? = nil) {
        self.range = range
        self.result = result
        self.reference = reference
    }
    
    /// Create from range string (e.g., "1-2", "5", "6-10")
    public static func fromRangeString(_ rangeString: String, result: String, reference: TableReference? = nil) throws -> RangeTableEntry {
        let trimmed = rangeString.trimmingCharacters(in: .whitespaces)
        
        if trimmed.contains("-") {
            let parts = trimmed.components(separatedBy: "-")
            guard parts.count == 2,
                  let lower = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                  let upper = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
                throw ParseError.invalidExpression(message: "Invalid range format: \(rangeString)")
            }
            
            guard lower <= upper else {
                throw ParseError.invalidExpression(message: "Invalid range: lower bound must be <= upper bound")
            }
            
            return RangeTableEntry(range: lower...upper, result: result, reference: reference)
        } else {
            guard let singleValue = Int(trimmed) else {
                throw ParseError.invalidExpression(message: "Invalid range format: \(rangeString)")
            }
            return RangeTableEntry(range: singleValue...singleValue, result: result, reference: reference)
        }
    }
}

/// Represents a percentage-based table entry (e.g., "50%: Common")
public struct PercentageTableEntry {
    public let percentage: Int
    public let result: String
    public let reference: TableReference?
    
    public init(percentage: Int, result: String, reference: TableReference? = nil) {
        self.percentage = percentage
        self.result = result
        self.reference = reference
    }
    
    /// Create from percentage string (e.g., "50%")
    public static func fromPercentageString(_ percentString: String, result: String, reference: TableReference? = nil) throws -> PercentageTableEntry {
        let trimmed = percentString.trimmingCharacters(in: .whitespaces)
        
        guard trimmed.hasSuffix("%") else {
            throw ParseError.invalidExpression(message: "Percentage must end with %")
        }
        
        let numberPart = String(trimmed.dropLast())
        guard let percentage = Int(numberPart) else {
            throw ParseError.invalidExpression(message: "Invalid percentage format: \(percentString)")
        }
        
        guard percentage >= 0 && percentage <= 100 else {
            throw ParseError.invalidExpression(message: "Percentage must be between 0 and 100")
        }
        
        return PercentageTableEntry(percentage: percentage, result: result, reference: reference)
    }
}

/// Represents a reference to another table
public struct TableReference {
    public let tableName: String
    
    public init(tableName: String) {
        self.tableName = tableName
    }
    
    /// Create from reference string (e.g., "→ @sub_table")
    public static func fromReferenceString(_ referenceString: String) throws -> TableReference {
        let trimmed = referenceString.trimmingCharacters(in: .whitespaces)
        
        // Expected format: "→ @table_name" or "-> @table_name"
        var cleanString = trimmed
        if cleanString.hasPrefix("→ ") || cleanString.hasPrefix("-> ") {
            cleanString = String(cleanString.dropFirst(cleanString.hasPrefix("→ ") ? 2 : 3))
        }
        
        guard cleanString.hasPrefix("@") else {
            throw ParseError.invalidExpression(message: "Table reference must start with @")
        }
        
        let tableName = String(cleanString.dropFirst())
        guard !tableName.isEmpty else {
            throw ParseError.invalidExpression(message: "Table name cannot be empty")
        }
        
        return TableReference(tableName: tableName)
    }
}

// MARK: - Table Lookup Expression

/// Represents a table lookup expression in the AST
public struct TableLookupExpression: DiceExpression, Visitable {
    public let tableName: String
    
    public init(tableName: String) {
        self.tableName = tableName
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        // Look up the table from the context
        guard let table = context.tableManager?.getTable(named: tableName) else {
            throw ParseError.invalidExpression(message: "Table not found: \(tableName)")
        }
        
        // Roll on the table
        let tableResult = table.roll(with: context.randomNumberGenerator)
        
        // Create a DiceResult representing the table lookup
        return DiceResult(
            rolls: [tableResult.roll],
            total: tableResult.roll,
            breakdown: DiceBreakdown(
                originalRolls: [tableResult.roll],
                modifierDescription: "Table lookup: @\(tableName)"
            ),
            type: DiceResult.ResultType.table
        )
    }
    
    public var description: String {
        return "@\(tableName)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

// MARK: - Table Builder

/// Builder for creating random tables programmatically
public class TableBuilder {
    private var name: String
    private var entries: [TableEntry] = []
    
    public init(name: String) {
        self.name = name
    }
    
    /// Add an entry with a specific weight
    public func addEntry(weight: Int, result: String, reference: TableReference? = nil) -> TableBuilder {
        entries.append(TableEntry(weight: weight, result: result, reference: reference))
        return self
    }
    
    /// Add a range-based entry
    public func addRangeEntry(range: ClosedRange<Int>, result: String, reference: TableReference? = nil) -> TableBuilder {
        let weight = range.upperBound - range.lowerBound + 1
        entries.append(TableEntry(weight: weight, result: result, reference: reference))
        return self
    }
    
    /// Add a percentage-based entry
    public func addPercentageEntry(percentage: Int, result: String, reference: TableReference? = nil) -> TableBuilder {
        entries.append(TableEntry(weight: percentage, result: result, reference: reference))
        return self
    }
    
    /// Build the final table
    public func build() -> RandomTable {
        return RandomTable(name: name, entries: entries)
    }
}

// MARK: - Table Validation

/// Validates table entries for correctness
public struct TableValidator {
    
    /// Validate that range entries don't overlap and cover the expected range
    public static func validateRangeEntries(_ entries: [RangeTableEntry]) throws {
        let sortedEntries = entries.sorted { $0.range.lowerBound < $1.range.lowerBound }
        
        for i in 0..<sortedEntries.count {
            let current = sortedEntries[i]
            
            // Check for overlaps with next entry
            if i < sortedEntries.count - 1 {
                let next = sortedEntries[i + 1]
                if current.range.upperBound >= next.range.lowerBound {
                    throw ParseError.invalidExpression(message: "Overlapping ranges: \(current.range) and \(next.range)")
                }
            }
        }
    }
    
    /// Validate that percentage entries add up to 100%
    public static func validatePercentageEntries(_ entries: [PercentageTableEntry]) throws {
        let totalPercentage = entries.reduce(0) { $0 + $1.percentage }
        
        if totalPercentage != 100 {
            throw ParseError.invalidExpression(message: "Percentage entries must add up to 100%, got \(totalPercentage)%")
        }
    }
    
    /// Validate that a table has at least one entry
    public static func validateTable(_ table: RandomTable) throws {
        if table.entries.isEmpty {
            throw ParseError.invalidExpression(message: "Table must have at least one entry")
        }
        
        if table.totalWeight <= 0 {
            throw ParseError.invalidExpression(message: "Table total weight must be positive")
        }
    }
}

// MARK: - Extensions

extension RandomTable: CustomStringConvertible {
    public var description: String {
        let entriesDescription = entries.map { entry in
            let refString = entry.reference?.tableName ?? ""
            let refPart = refString.isEmpty ? "" : " → @\(refString)"
            return "  \(entry.weight): \(entry.result)\(refPart)"
        }.joined(separator: "\n")
        
        return "@\(name)\n\(entriesDescription)"
    }
}

extension TableEntry: CustomStringConvertible {
    public var description: String {
        let refString = reference?.tableName ?? ""
        let refPart = refString.isEmpty ? "" : " → @\(refString)"
        return "\(weight): \(result)\(refPart)"
    }
}

extension RangeTableEntry: CustomStringConvertible {
    public var description: String {
        let rangeString = range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)-\(range.upperBound)"
        let refString = reference?.tableName ?? ""
        let refPart = refString.isEmpty ? "" : " → @\(refString)"
        return "\(rangeString): \(result)\(refPart)"
    }
}

extension PercentageTableEntry: CustomStringConvertible {
    public var description: String {
        let refString = reference?.tableName ?? ""
        let refPart = refString.isEmpty ? "" : " → @\(refString)"
        return "\(percentage)%: \(result)\(refPart)"
    }
}

// MARK: - Equatable Conformance

extension RandomTable: Equatable {
    public static func == (lhs: RandomTable, rhs: RandomTable) -> Bool {
        return lhs.name == rhs.name &&
               lhs.entries == rhs.entries &&
               lhs.totalWeight == rhs.totalWeight
    }
}

extension TableEntry: Equatable {
    public static func == (lhs: TableEntry, rhs: TableEntry) -> Bool {
        return lhs.weight == rhs.weight &&
               lhs.result == rhs.result &&
               lhs.reference == rhs.reference
    }
}

extension RangeTableEntry: Equatable {
    public static func == (lhs: RangeTableEntry, rhs: RangeTableEntry) -> Bool {
        return lhs.range == rhs.range &&
               lhs.result == rhs.result &&
               lhs.reference == rhs.reference
    }
}

extension PercentageTableEntry: Equatable {
    public static func == (lhs: PercentageTableEntry, rhs: PercentageTableEntry) -> Bool {
        return lhs.percentage == rhs.percentage &&
               lhs.result == rhs.result &&
               lhs.reference == rhs.reference
    }
}

extension TableReference: Equatable {
    public static func == (lhs: TableReference, rhs: TableReference) -> Bool {
        return lhs.tableName == rhs.tableName
    }
}