import Testing
@testable import DiceLang
import Foundation

@Suite("DiceLang Parser Tests")
struct DiceLangParserTests {
    
    @Test("Parser initialization")
    func parserInitialization() throws {
        // Test default initialization
        let parser1 = DiceLangParser()
        #expect(parser1.tableManager.registeredTableNames.isEmpty)
        
        // Test shared instance
        let sharedParser = DiceLangParser.shared
        #expect(sharedParser.tableManager.registeredTableNames.isEmpty)
        
        // Test custom initialization
        let customTableManager = TableManager()
        let customRng = FixedRandomNumberGenerator(values: [3, 4, 5])
        let parser2 = DiceLangParser(tableManager: customTableManager, randomNumberGenerator: customRng)
        #expect(parser2.tableManager.registeredTableNames.isEmpty)
    }
    
    @Test("Basic dice expression evaluation")
    func basicDiceEvaluation() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [3, 4]))
        
        // Test simple dice roll
        let result1 = try parser.evaluate("2d6")
        #expect(result1.total == 7) // 3 + 4
        #expect(result1.rolls == [3, 4])
        #expect(result1.type == .standard)
        
        // Test arithmetic
        let result2 = try parser.evaluate("2d6+5")
        #expect(result2.total == 12) // 7 + 5
        
        // Test literal number
        let result3 = try parser.evaluate("10")
        #expect(result3.total == 10)
        #expect(result3.rolls == [10])
    }
    
    @Test("Parse without evaluation")
    func parseWithoutEvaluation() throws {
        let parser = DiceLangParser()
        
        // Test parsing returns correct AST types
        let expr1 = try parser.parse("2d6")
        #expect(expr1 is DiceRollExpression)
        
        let expr2 = try parser.parse("2d6+3")
        #expect(expr2 is BinaryExpression)
        
        let expr3 = try parser.parse("(2d6+3)*2")
        #expect(expr3 is BinaryExpression)
        
        // Test invalid expressions throw errors
        #expect(throws: ParseError.self) {
            _ = try parser.parse("2d6+")
        }
        
        #expect(throws: ParseError.self) {
            _ = try parser.parse("(2d6+3")
        }
    }
    
    @Test("Table registration and management")
    func tableManagement() throws {
        let parser = DiceLangParser()
        
        // Initially no tables
        #expect(parser.getTableNames().isEmpty)
        #expect(parser.getTable(named: "test") == nil)
        
        // Register a table from definition
        let tableDefinition = """
        @treasure
        1-3: 1d6 gold pieces
        4-5: 1d4 silver pieces
        6: A magical gem
        """
        
        try parser.registerTable(tableDefinition)
        
        // Verify table was registered
        #expect(parser.getTableNames() == ["treasure"])
        let table = parser.getTable(named: "treasure")
        #expect(table != nil)
        #expect(table!.name == "treasure")
        #expect(table!.entries.count == 3)
        
        // Register with custom name
        try parser.registerTable(tableDefinition, name: "loot")
        #expect(parser.getTableNames().sorted() == ["loot", "treasure"])
        
        // Register pre-built table
        let customTable = RandomTable(name: "custom", entries: [
            TableEntry(weight: 1, result: "Custom result", reference: nil)
        ])
        parser.registerTable(customTable)
        #expect(parser.getTableNames().sorted() == ["custom", "loot", "treasure"])
        
        // Clear all tables
        parser.clearTables()
        #expect(parser.getTableNames().isEmpty)
    }
    
    @Test("Table evaluation")
    func tableEvaluation() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [2, 5]))
        
        // Register a simple table
        let tableDefinition = """
        @weapons
        1-2: Sword
        3-4: Bow
        5-6: Staff
        """
        
        try parser.registerTable(tableDefinition)
        
        // Test table evaluation
        let result = try parser.evaluateTable(named: "weapons")
        #expect(result.finalResult == "Sword") // Roll 2 should hit "Sword"
        #expect(result.primaryResult.roll == 2)
        #expect(result.primaryResult.tableName == "weapons")
        
        // Test table evaluation with custom RNG
        let customRng = FixedRandomNumberGenerator(values: [5])
        let result2 = try parser.evaluateTable(named: "weapons", with: customRng)
        #expect(result2.finalResult == "Staff") // Roll 5 should hit "Staff"
        
        // Test non-existent table
        #expect(throws: ParseError.self) {
            _ = try parser.evaluateTable(named: "nonexistent")
        }
    }
    
    @Test("Table expression evaluation")
    func tableExpressionEvaluation() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [3]))
        
        // Register a table
        let tableDefinition = """
        @monsters
        1-2: Goblin
        3-4: Orc
        5-6: Troll
        """
        
        try parser.registerTable(tableDefinition)
        
        // Test @table_name syntax
        let result = try parser.evaluate("@monsters")
        #expect(result.type == .table)
        #expect(result.total == 3) // The roll value
        
        // Test table not found
        #expect(throws: ParseError.self) {
            _ = try parser.evaluate("@nonexistent")
        }
    }
    
    @Test("Convenience methods")
    func convenienceMethods() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [4, 3, 4, 3, 4]))
        
        // Test roll() convenience method
        let total = try parser.roll("2d6")
        #expect(total == 7) // 4 + 3
        
        // Test evaluateAll()
        let expressions = ["1d6", "2d6", "1d6+2"]
        let results = try parser.evaluateAll(expressions)
        #expect(results.count == 3)
        #expect(results[0].total == 4) // First 1d6
        #expect(results[1].total == 7) // 2d6 (4+3)
        #expect(results[2].total == 6) // 1d6+2 (4+2)
        
        // Test isValid()
        #expect(parser.isValid("2d6+3"))
        #expect(parser.isValid("(2d6)*3"))
        #expect(!parser.isValid("2d6+"))
        #expect(!parser.isValid("(2d6+3"))
        
        // Test getParseError()
        let validError = parser.getParseError(for: "2d6+3")
        #expect(validError == nil)
        
        let invalidError = parser.getParseError(for: "2d6+")
        #expect(invalidError != nil)
    }
    
    @Test("Batch table operations")
    func batchTableOperations() throws {
        let parser = DiceLangParser()
        
        // Test registerTables with dictionary
        let tables = [
            "weapons": """
            @weapons
            1-3: Sword
            4-6: Bow
            """,
            "armor": """
            @armor
            1-3: Leather
            4-6: Chain Mail
            """
        ]
        
        try parser.registerTables(tables)
        #expect(parser.getTableNames().sorted() == ["armor", "weapons"])
        
        // Verify both tables work
        let weaponTable = parser.getTable(named: "weapons")
        let armorTable = parser.getTable(named: "armor")
        #expect(weaponTable != nil)
        #expect(armorTable != nil)
        #expect(weaponTable!.entries.count == 2)
        #expect(armorTable!.entries.count == 2)
    }
    
    @Test("File-based table operations")
    func fileBasedTableOperations() throws {
        let parser = DiceLangParser()
        
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_tables.txt")
        
        // Register some tables first
        let tableDefinition1 = """
        @test_table1
        1-2: Result A
        3-4: Result B
        """
        
        let tableDefinition2 = """
        @test_table2
        1: Single result
        """
        
        try parser.registerTable(tableDefinition1)
        try parser.registerTable(tableDefinition2)
        
        // Save tables to file
        try parser.saveTables(to: fileURL)
        
        // Verify file was created
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Clear tables and load from file
        parser.clearTables()
        #expect(parser.getTableNames().isEmpty)
        
        try parser.loadTables(from: fileURL)
        #expect(parser.getTableNames().sorted() == ["test_table1", "test_table2"])
        
        // Verify tables were loaded correctly
        let table1 = parser.getTable(named: "test_table1")
        let table2 = parser.getTable(named: "test_table2")
        #expect(table1 != nil)
        #expect(table2 != nil)
        #expect(table1!.entries.count == 2)
        #expect(table2!.entries.count == 1)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    @Test("Error handling in evaluation")
    func errorHandlingInEvaluation() throws {
        let parser = DiceLangParser()
        
        // Test division by zero
        #expect(throws: ParseError.self) {
            _ = try parser.evaluate("10/0")
        }
        
        do {
            _ = try parser.evaluate("10/0")
        } catch let error as ParseError {
            if case .divisionByZero = error {
                // Expected error type
            } else {
                #expect(Bool(false), "Expected divisionByZero error")
            }
        }
        
        // Test invalid dice notation during evaluation
        #expect(throws: ParseError.self) {
            _ = try parser.evaluate("2d0")
        }
        
        // Test malformed expressions
        #expect(throws: ParseError.self) {
            _ = try parser.evaluate("2d6+")
        }
    }
    
    @Test("Complex expressions")
    func complexExpressions() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [6, 5, 4, 3, 2, 1]))
        
        // Test nested arithmetic
        let result1 = try parser.evaluate("(2d6+3)*2-5")
        // 2d6 = 6+5 = 11, +3 = 14, *2 = 28, -5 = 23
        #expect(result1.total == 23)
        
        // Test multiple dice expressions
        let result2 = try parser.evaluate("2d6+1d4")
        // 2d6 = 4+3 = 7, 1d4 = 2, total = 9
        #expect(result2.total == 9)
        
        // Test parentheses grouping
        let result3 = try parser.evaluate("2*(1d6+3)")
        // 1d6 = 1, +3 = 4, *2 = 8
        #expect(result3.total == 8)
    }
    
    @Test("Table with embedded dice rolls")
    func tableWithEmbeddedDiceRolls() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [2, 4, 5]))
        
        // Register table with embedded dice
        let tableDefinition = """
        @treasure
        1-2: 1d6 gold pieces
        3-4: 2d4 silver pieces
        5-6: A magical item worth 1d10 gold
        """
        
        try parser.registerTable(tableDefinition)
        
        // Evaluate table (should roll 2, hitting first entry)
        let result = try parser.evaluateTable(named: "treasure")
        
        // The result should contain the raw text from the table
        // Note: Embedded dice evaluation happens separately via TableResultEvaluator
        #expect(result.finalResult.contains("gold pieces"))
        #expect(result.finalResult == "1d6 gold pieces") // Raw table result
    }
    
    @Test("Nested table references")
    func nestedTableReferences() throws {
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [1, 2]))
        
        // Register main table
        let mainTable = """
        @encounter
        1-3: Random monster → @monster_table
        4-6: Treasure chest
        """
        
        // Register referenced table
        let monsterTable = """
        @monster_table
        1-2: Goblin
        3-4: Orc
        5-6: Dragon
        """
        
        try parser.registerTable(mainTable)
        try parser.registerTable(monsterTable)
        
        // Evaluate main table (roll 1 should trigger monster_table reference)
        let result = try parser.evaluateTable(named: "encounter")
        
        // Should resolve to the monster table result
        #expect(result.finalResult == "Goblin") // Roll 2 in monster table
        #expect(result.nestedResults.count == 1)
        #expect(result.depth == 0) // Main table is depth 0
        #expect(result.nestedResults[0].depth == 1) // Nested table is depth 1
    }
    
    @Test("Performance with large expressions")
    func performanceWithLargeExpressions() throws {
        let parser = DiceLangParser()
        
        // Test parsing performance with complex expression
        let complexExpression = "(2d6+3)*(1d4+2)+(3d8-1d6)*(2d10+5)"
        
        let startTime = Date()
        let result = try parser.evaluate(complexExpression)
        let endTime = Date()
        
        // Should complete reasonably quickly (less than 1 second)
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0)
        #expect(result.total > 0) // Should produce a valid result
    }
    
    @Test("Edge cases and validation")
    func edgeCasesAndValidation() throws {
        let parser = DiceLangParser()
        
        // Test empty string
        #expect(throws: ParseError.self) {
            _ = try parser.evaluate("")
        }
        
        // Test whitespace handling
        let result1 = try parser.evaluate("  2d6 + 3  ")
        #expect(result1.total > 0)
        
        // Test very large dice numbers (within limits)
        let result2 = try parser.evaluate("1000d1000")
        #expect(result2.total >= 1000) // Minimum possible result
        #expect(result2.total <= 1000000) // Maximum possible result
        
        // Test invalid table definitions (malformed syntax)
        #expect(throws: ParseError.self) {
            try parser.registerTable("invalid table definition")
        }
        
        #expect(throws: ParseError.self) {
            try parser.registerTable("@table\nmalformed entry")
        }
    }
}