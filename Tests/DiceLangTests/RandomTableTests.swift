import Testing
import Foundation
@testable import DiceLang

// MARK: - Random Table Tests

@Suite("Random Table System")
struct RandomTableTests {
    
    // MARK: - Basic Table Tests
    
    @Test("Basic table creation")
    func basicTableCreation() throws {
        let entries = [
            TableEntry(weight: 1, result: "Goblins"),
            TableEntry(weight: 2, result: "Wolves"),
            TableEntry(weight: 1, result: "Nothing")
        ]
        
        let table = RandomTable(name: "encounter", entries: entries)
        
        #expect(table.name == "encounter")
        #expect(table.entries.count == 3)
        #expect(table.totalWeight == 4)
    }
    
    @Test("Table rolling")
    func tableRolling() throws {
        let entries = [
            TableEntry(weight: 1, result: "Goblins"),
            TableEntry(weight: 2, result: "Wolves"),
            TableEntry(weight: 1, result: "Nothing")
        ]
        
        let table = RandomTable(name: "encounter", entries: entries)
        let rng = FixedRandomNumberGenerator(values: [1, 2, 3, 4])
        
        let result1 = table.roll(with: rng)
        #expect(result1.result == "Goblins")
        
        let result2 = table.roll(with: rng)
        #expect(result2.result == "Wolves")
        
        let result3 = table.roll(with: rng)
        #expect(result3.result == "Wolves")
        
        let result4 = table.roll(with: rng)
        #expect(result4.result == "Nothing")
    }
    
    @Test("Range table entry creation")
    func rangeTableEntryCreation() throws {
        let entry1 = try RangeTableEntry.fromRangeString("1-3", result: "Common")
        #expect(entry1.range == 1...3)
        #expect(entry1.result == "Common")
        
        let entry2 = try RangeTableEntry.fromRangeString("5", result: "Rare")
        #expect(entry2.range == 5...5)
        #expect(entry2.result == "Rare")
        
        let entry3 = try RangeTableEntry.fromRangeString("10-20", result: "Epic")
        #expect(entry3.range == 10...20)
        #expect(entry3.result == "Epic")
    }
    
    @Test("Percentage table entry creation")
    func percentageTableEntryCreation() throws {
        let entry1 = try PercentageTableEntry.fromPercentageString("50%", result: "Common")
        #expect(entry1.percentage == 50)
        #expect(entry1.result == "Common")
        
        let entry2 = try PercentageTableEntry.fromPercentageString("25%", result: "Uncommon")
        #expect(entry2.percentage == 25)
        #expect(entry2.result == "Uncommon")
        
        let entry3 = try PercentageTableEntry.fromPercentageString("5%", result: "Rare")
        #expect(entry3.percentage == 5)
        #expect(entry3.result == "Rare")
    }
    
    @Test("Table reference creation")
    func tableReferenceCreation() throws {
        let ref1 = try TableReference.fromReferenceString("→ @sub_table")
        #expect(ref1.tableName == "sub_table")
        
        let ref2 = try TableReference.fromReferenceString("-> @another_table")
        #expect(ref2.tableName == "another_table")
        
        let ref3 = try TableReference.fromReferenceString("@direct_table")
        #expect(ref3.tableName == "direct_table")
    }
    
    // MARK: - Table Manager Tests
    
    @Test("Table manager registration")
    func tableManagerRegistration() throws {
        let manager = TableManager()
        
        let table = RandomTable(name: "test", entries: [
            TableEntry(weight: 1, result: "Result 1"),
            TableEntry(weight: 1, result: "Result 2")
        ])
        
        manager.registerTable(table)
        
        #expect(manager.isTableRegistered(named: "test"))
        #expect(manager.registeredTableNames.contains("test"))
        #expect(manager.getTable(named: "test") == table)
    }
    
    @Test("Table manager evaluation")
    func tableManagerEvaluation() throws {
        let manager = TableManager()
        let rng = FixedRandomNumberGenerator(values: [1, 2])
        
        let table = RandomTable(name: "test", entries: [
            TableEntry(weight: 1, result: "First"),
            TableEntry(weight: 1, result: "Second")
        ])
        
        manager.registerTable(table)
        
        let result1 = try manager.evaluateTable(named: "test", with: rng)
        #expect(result1.finalResult == "First")
        
        let result2 = try manager.evaluateTable(named: "test", with: rng)
        #expect(result2.finalResult == "Second")
    }
    
    @Test("Nested table evaluation")
    func nestedTableEvaluation() throws {
        let manager = TableManager()
        let rng = FixedRandomNumberGenerator(values: [1, 1])
        
        let subTable = RandomTable(name: "sub", entries: [
            TableEntry(weight: 1, result: "Nested Result")
        ])
        
        let mainTable = RandomTable(name: "main", entries: [
            TableEntry(weight: 1, result: "Main Result", reference: TableReference(tableName: "sub"))
        ])
        
        manager.registerTable(subTable)
        manager.registerTable(mainTable)
        
        let result = try manager.evaluateTable(named: "main", with: rng)
        #expect(result.finalResult == "Nested Result")
        #expect(result.nestedResults.count == 1)
        #expect(result.tableChain == ["main", "sub"])
    }
    
    @Test("Table validation with circular references")
    func tableValidationCircularReferences() throws {
        let manager = TableManager()
        
        // Create tables with circular reference
        let table1 = RandomTable(name: "table1", entries: [
            TableEntry(weight: 1, result: "Result", reference: TableReference(tableName: "table2"))
        ])
        
        let table2 = RandomTable(name: "table2", entries: [
            TableEntry(weight: 1, result: "Result", reference: TableReference(tableName: "table1"))
        ])
        
        manager.registerTable(table1)
        manager.registerTable(table2)
        
        #expect(throws: ParseError.self) {
            try manager.validateTables()
        }
    }
    
    // MARK: - Table Parser Tests
    
    @Test("Table parser basic parsing")
    func tableParserBasicParsing() throws {
        let definition = """
        @encounter
        1-2: Goblins
        3-4: Wolves
        5: Ancient Ruins
        6-10: Nothing
        """
        
        let table = try TableParser.parseTable(from: definition)
        
        #expect(table.name == "encounter")
        #expect(table.entries.count == 4)
        #expect(table.totalWeight == 10)
        
        // Check individual entries
        #expect(table.entries[0].weight == 2) // 1-2 range
        #expect(table.entries[0].result == "Goblins")
        
        #expect(table.entries[1].weight == 2) // 3-4 range
        #expect(table.entries[1].result == "Wolves")
        
        #expect(table.entries[2].weight == 1) // 5 single value
        #expect(table.entries[2].result == "Ancient Ruins")
        
        #expect(table.entries[3].weight == 5) // 6-10 range
        #expect(table.entries[3].result == "Nothing")
    }
    
    @Test("Table parser percentage parsing")
    func tableParserPercentageParsing() throws {
        let definition = """
        @loot
        50%: Common item
        30%: Uncommon item
        15%: Rare item
        5%: Legendary item
        """
        
        let table = try TableParser.parseTable(from: definition)
        
        #expect(table.name == "loot")
        #expect(table.entries.count == 4)
        #expect(table.totalWeight == 100)
        
        #expect(table.entries[0].weight == 50)
        #expect(table.entries[0].result == "Common item")
        
        #expect(table.entries[1].weight == 30)
        #expect(table.entries[1].result == "Uncommon item")
        
        #expect(table.entries[2].weight == 15)
        #expect(table.entries[2].result == "Rare item")
        
        #expect(table.entries[3].weight == 5)
        #expect(table.entries[3].result == "Legendary item")
    }
    
    @Test("Table parser with references")
    func tableParserWithReferences() throws {
        let definition = """
        @main_table
        1-3: Normal result
        4: Special result → @special_table
        5-6: Another result
        """
        
        let table = try TableParser.parseTable(from: definition)
        
        #expect(table.name == "main_table")
        #expect(table.entries.count == 3)
        
        #expect(table.entries[0].reference == nil)
        #expect(table.entries[1].reference?.tableName == "special_table")
        #expect(table.entries[2].reference == nil)
    }
    
    // MARK: - Table Expression Tests
    
    @Test("Table lookup expression parsing")
    func tableLookupExpressionParsing() throws {
        let input = "@encounter"
        let expression = try Parser.parse(input)
        
        #expect(expression is TableLookupExpression)
        
        if let tableLookup = expression as? TableLookupExpression {
            #expect(tableLookup.tableName == "encounter")
            #expect(tableLookup.description == "@encounter")
        }
    }
    
    @Test("Table lookup expression evaluation")
    func tableLookupExpressionEvaluation() throws {
        let manager = TableManager()
        let table = RandomTable(name: "test", entries: [
            TableEntry(weight: 1, result: "Result")
        ])
        manager.registerTable(table)
        
        let rng = FixedRandomNumberGenerator(values: [1])
        let context = EvaluationContext(randomNumberGenerator: rng, tableManager: manager)
        
        let expression = TableLookupExpression(tableName: "test")
        let result = try expression.evaluate(with: context)
        
        #expect(result.type == .table)
        #expect(result.total == 1)
        #expect(result.rolls == [1])
    }
    
    @Test("Table lookup expression missing table")
    func tableLookupExpressionMissingTable() throws {
        let manager = TableManager()
        let rng = FixedRandomNumberGenerator(values: [1])
        let context = EvaluationContext(randomNumberGenerator: rng, tableManager: manager)
        
        let expression = TableLookupExpression(tableName: "missing")
        
        #expect(throws: ParseError.self) {
            try expression.evaluate(with: context)
        }
    }
    
    // MARK: - Table Result Evaluator Tests
    
    @Test("Table result evaluator basic text")
    func tableResultEvaluatorBasicText() throws {
        let result = try TableResultEvaluator.evaluate("Simple text result", with: EvaluationContext())
        
        #expect(result.originalText == "Simple text result")
        #expect(result.evaluatedText == "Simple text result")
        #expect(result.diceRolls.isEmpty)
        #expect(result.totalValue == 0)
    }
    
    @Test("Table result evaluator with dice")
    func tableResultEvaluatorWithDice() throws {
        let rng = FixedRandomNumberGenerator(values: [3, 4])
        let context = EvaluationContext(randomNumberGenerator: rng)
        
        let result = try TableResultEvaluator.evaluate("You find 1d6 gold pieces", with: context)
        
        #expect(result.originalText == "You find 1d6 gold pieces")
        #expect(result.evaluatedText == "You find 3 gold pieces")
        #expect(result.diceRolls.count == 1)
        #expect(result.diceRolls[0].originalExpression == "1d6")
        #expect(result.diceRolls[0].result.total == 3)
        #expect(result.totalValue == 3)
    }
    
    @Test("Table result evaluator multiple dice")
    func tableResultEvaluatorMultipleDice() throws {
        let rng = FixedRandomNumberGenerator(values: [2, 5])
        let context = EvaluationContext(randomNumberGenerator: rng)
        
        let result = try TableResultEvaluator.evaluate("You find 1d4 silver and 1d6 gold", with: context)
        
        #expect(result.originalText == "You find 1d4 silver and 1d6 gold")
        #expect(result.evaluatedText == "You find 2 silver and 5 gold")
        #expect(result.diceRolls.count == 2)
        #expect(result.totalValue == 7)
    }
    
    // MARK: - Table Builder Tests
    
    @Test("Table builder")
    func tableBuilder() throws {
        let table = TableBuilder(name: "test")
            .addEntry(weight: 1, result: "First")
            .addEntry(weight: 2, result: "Second")
            .addRangeEntry(range: 1...3, result: "Range")
            .addPercentageEntry(percentage: 25, result: "Percent")
            .build()
        
        #expect(table.name == "test")
        #expect(table.entries.count == 4)
        #expect(table.totalWeight == 31) // 1 + 2 + 3 + 25
    }
    
    // MARK: - Table Validation Tests
    
    @Test("Range entry validation")
    func rangeEntryValidation() throws {
        let validEntries = [
            RangeTableEntry(range: 1...3, result: "First"),
            RangeTableEntry(range: 4...6, result: "Second"),
            RangeTableEntry(range: 7...10, result: "Third")
        ]
        
        // Should not throw
        try TableValidator.validateRangeEntries(validEntries)
        
        let overlappingEntries = [
            RangeTableEntry(range: 1...3, result: "First"),
            RangeTableEntry(range: 3...6, result: "Second") // Overlaps at 3
        ]
        
        #expect(throws: ParseError.self) {
            try TableValidator.validateRangeEntries(overlappingEntries)
        }
    }
    
    @Test("Percentage entry validation")
    func percentageEntryValidation() throws {
        let validEntries = [
            PercentageTableEntry(percentage: 50, result: "Common"),
            PercentageTableEntry(percentage: 30, result: "Uncommon"),
            PercentageTableEntry(percentage: 20, result: "Rare")
        ]
        
        // Should not throw
        try TableValidator.validatePercentageEntries(validEntries)
        
        let invalidEntries = [
            PercentageTableEntry(percentage: 60, result: "Common"),
            PercentageTableEntry(percentage: 50, result: "Uncommon") // Total is 110%
        ]
        
        #expect(throws: ParseError.self) {
            try TableValidator.validatePercentageEntries(invalidEntries)
        }
    }
    
    @Test("Table validation with empty table")
    func tableValidationEmptyTable() throws {
        let validTable = RandomTable(name: "valid", entries: [
            TableEntry(weight: 1, result: "Result")
        ])
        
        // Should not throw
        try TableValidator.validateTable(validTable)
        
        let emptyTable = RandomTable(name: "empty", entries: [])
        
        #expect(throws: ParseError.self) {
            try TableValidator.validateTable(emptyTable)
        }
    }
    
    // MARK: - Complex Integration Tests
    
    @Test("Complex table system integration")
    func complexTableSystemIntegration() throws {
        let manager = TableManager()
        let rng = FixedRandomNumberGenerator(values: [1, 1, 3]) // For predictable results
        
        // Define a loot table
        let lootTable = RandomTable(name: "loot", entries: [
            TableEntry(weight: 1, result: "1d6 gold pieces"),
            TableEntry(weight: 1, result: "Magic item", reference: TableReference(tableName: "magic_items"))
        ])
        
        // Define a magic items table
        let magicTable = RandomTable(name: "magic_items", entries: [
            TableEntry(weight: 1, result: "Healing potion"),
            TableEntry(weight: 1, result: "Magic sword")
        ])
        
        manager.registerTable(lootTable)
        manager.registerTable(magicTable)
        
        let context = EvaluationContext(randomNumberGenerator: rng, tableManager: manager)
        
        // Test table lookup expression
        let expression = TableLookupExpression(tableName: "loot")
        let result = try expression.evaluate(with: context)
        
        #expect(result.type == .table)
        #expect(result.total == 1)
        
        // Test full evaluation with nesting
        let evaluation = try manager.evaluateTable(named: "loot", with: rng)
        #expect(evaluation.depth == 0)
        
        // Test with dice evaluation
        let diceResult = try TableResultEvaluator.evaluate("1d6 gold pieces", with: context)
        #expect(diceResult.evaluatedText == "3 gold pieces")
        #expect(diceResult.diceRolls.count == 1)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Range entry parsing errors")
    func rangeEntryParsingErrors() throws {
        #expect(throws: ParseError.self) {
            try RangeTableEntry.fromRangeString("invalid", result: "Result")
        }
        
        #expect(throws: ParseError.self) {
            try RangeTableEntry.fromRangeString("5-3", result: "Result") // Invalid range
        }
    }
    
    @Test("Percentage entry parsing errors")
    func percentageEntryParsingErrors() throws {
        #expect(throws: ParseError.self) {
            try PercentageTableEntry.fromPercentageString("invalid", result: "Result")
        }
        
        #expect(throws: ParseError.self) {
            try PercentageTableEntry.fromPercentageString("150%", result: "Result") // > 100%
        }
    }
    
    @Test("Table reference parsing errors")
    func tableReferenceParsingErrors() throws {
        #expect(throws: ParseError.self) {
            try TableReference.fromReferenceString("invalid_reference")
        }
        
        #expect(throws: ParseError.self) {
            try TableReference.fromReferenceString("→ @") // Empty table name
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Large table performance")
    func largeTablePerformance() throws {
        // Create a large table with many entries
        var entries: [TableEntry] = []
        for i in 1...1000 {
            entries.append(TableEntry(weight: 1, result: "Result \(i)"))
        }
        
        let table = RandomTable(name: "large", entries: entries)
        let rng = FixedRandomNumberGenerator(values: [500])
        
        let result = table.roll(with: rng)
        #expect(result.result == "Result 500")
    }
    
    @Test("Deep nesting performance")
    func deepNestingPerformance() throws {
        let manager = TableManager()
        
        // Create a chain of 10 nested tables
        for i in 1...10 {
            let nextTable = i < 10 ? TableReference(tableName: "table\(i+1)") : nil
            let table = RandomTable(name: "table\(i)", entries: [
                TableEntry(weight: 1, result: "Result \(i)", reference: nextTable)
            ])
            manager.registerTable(table)
        }
        
        let rng = FixedRandomNumberGenerator(values: Array(repeating: 1, count: 10))
        let result = try manager.evaluateTable(named: "table1", with: rng)
        
        #expect(result.finalResult == "Result 10")
        #expect(result.depth == 0)
        #expect(result.nestedResults.count == 1)
    }
}

// MARK: - Additional Integration Tests

@Suite("Table System Integration")
struct TableSystemIntegrationTests {
    
    @Test("Complete workflow test")
    func completeWorkflowTest() throws {
        // Parse a complete table definition
        let definition = """
        @encounter
        1-2: 1d4 goblins
        3-4: 1d2 wolves
        5: Ancient ruins → @ruins_table
        6-10: Nothing interesting
        """
        
        let table = try TableParser.parseTable(from: definition)
        
        // Verify table structure
        #expect(table.name == "encounter")
        #expect(table.entries.count == 4)
        #expect(table.totalWeight == 10)
        
        // Create a ruins table
        let ruinsTable = RandomTable(name: "ruins_table", entries: [
            TableEntry(weight: 1, result: "Crumbling tower with 2d6 gold")
        ])
        
        // Set up manager
        let manager = TableManager()
        manager.registerTable(table)
        manager.registerTable(ruinsTable)
        
        // Test different scenarios with specific RNG values
        
        // Test 1: Roll 5 should hit "Ancient ruins" entry
        let rng1 = FixedRandomNumberGenerator(values: [5, 1])
        let context1 = EvaluationContext(randomNumberGenerator: rng1, tableManager: manager)
        
        let expression1 = TableLookupExpression(tableName: "encounter")
        let result1 = try expression1.evaluate(with: context1)
        
        #expect(result1.type == .table)
        #expect(result1.total == 5)
        
        // Test 2: Full evaluation should resolve nested table
        let rng2 = FixedRandomNumberGenerator(values: [5, 1])
        let evaluation = try manager.evaluateTable(named: "encounter", with: rng2)
        #expect(evaluation.finalResult == "Crumbling tower with 2d6 gold")
        
        // Test 3: Embedded dice evaluation
        let diceRng = FixedRandomNumberGenerator(values: [4, 5])
        let diceContext = EvaluationContext(randomNumberGenerator: diceRng, tableManager: manager)
        let diceResult = try TableResultEvaluator.evaluate("Crumbling tower with 2d6 gold", with: diceContext)
        #expect(diceResult.evaluatedText == "Crumbling tower with 9 gold") // 4 + 5 = 9
    }
    
    @Test("JSON formatting for table results")
    func jsonFormattingForTableResults() throws {
        let manager = TableManager()
        let table = RandomTable(name: "test", entries: [
            TableEntry(weight: 1, result: "Test result")
        ])
        manager.registerTable(table)
        
        let rng = FixedRandomNumberGenerator(values: [1])
        let context = EvaluationContext(randomNumberGenerator: rng, tableManager: manager)
        
        let expression = TableLookupExpression(tableName: "test")
        let result = try expression.evaluate(with: context)
        
        let jsonString = result.toJSON(originalExpression: "@test")
        
        #expect(jsonString.contains("\"type\" : \"table\""))
        #expect(jsonString.contains("\"raw\" : \"@test\""))
        #expect(jsonString.contains("\"sum\" : 1"))
    }
}
