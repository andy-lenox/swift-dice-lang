import Testing
@testable import DiceLang

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    
    @Test("Dice parameter validation")
    func diceParameterValidation() throws {
        // Valid parameters should not throw
        try ErrorHandler.validateDiceParameters(dice: 1, sides: 6)
        try ErrorHandler.validateDiceParameters(dice: 10, sides: 20)
        try ErrorHandler.validateDiceParameters(dice: 1000, sides: 1000)
        
        // Invalid dice count
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: 0, sides: 6)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: -1, sides: 6)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: 1001, sides: 6)
        }
        
        // Invalid sides count
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: 1, sides: 0)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: 1, sides: -1)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDiceParameters(dice: 1, sides: 1001)
        }
    }
    
    @Test("Keep/drop parameter validation")
    func keepDropParameterValidation() throws {
        // Valid parameters should not throw
        try ErrorHandler.validateKeepDropParameters(count: 1, totalDice: 4)
        try ErrorHandler.validateKeepDropParameters(count: 3, totalDice: 4)
        try ErrorHandler.validateKeepDropParameters(count: 4, totalDice: 4)
        
        // Invalid count
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateKeepDropParameters(count: 0, totalDice: 4)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateKeepDropParameters(count: -1, totalDice: 4)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateKeepDropParameters(count: 5, totalDice: 4)
        }
    }
    
    @Test("Dice pool parameter validation")
    func dicePoolParameterValidation() throws {
        // Valid parameters should not throw
        try ErrorHandler.validateDicePoolParameters(threshold: 1, diceSides: 6)
        try ErrorHandler.validateDicePoolParameters(threshold: 4, diceSides: 6)
        try ErrorHandler.validateDicePoolParameters(threshold: 6, diceSides: 6)
        
        // Invalid threshold
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDicePoolParameters(threshold: 0, diceSides: 6)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDicePoolParameters(threshold: -1, diceSides: 6)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateDicePoolParameters(threshold: 7, diceSides: 6)
        }
    }
    
    @Test("Table name validation")
    func tableNameValidation() throws {
        // Valid names should not throw
        try ErrorHandler.validateTableName("test_table")
        try ErrorHandler.validateTableName("table1")
        try ErrorHandler.validateTableName("encounters")
        try ErrorHandler.validateTableName("a")
        try ErrorHandler.validateTableName("very_long_table_name_but_still_valid")
        
        // Invalid names
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName("")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName("123table")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName("table-name")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName("table name")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName("table.name")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableName(String(repeating: "a", count: 51))
        }
    }
    
    @Test("Table weight range validation")
    func tableWeightRangeValidation() throws {
        // Valid ranges should not throw
        try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: 1)
        try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: 10)
        try ErrorHandler.validateTableWeightRange(lowerBound: 5, upperBound: 10)
        try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: 1000)
        
        // Invalid lower bound
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: 0, upperBound: 10)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: -1, upperBound: 10)
        }
        
        // Invalid upper bound
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: 0)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: -1)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: 1, upperBound: 1001)
        }
        
        // Invalid range order
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableWeightRange(lowerBound: 10, upperBound: 5)
        }
    }
    
    @Test("Table percentage validation")
    func tablePercentageValidation() throws {
        // Valid percentages should not throw
        try ErrorHandler.validateTablePercentage(1)
        try ErrorHandler.validateTablePercentage(50)
        try ErrorHandler.validateTablePercentage(100)
        
        // Invalid percentages
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTablePercentage(0)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTablePercentage(-1)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTablePercentage(101)
        }
    }
    
    @Test("Table result validation")
    func tableResultValidation() throws {
        // Valid results should not throw
        try ErrorHandler.validateTableResult("Valid result")
        try ErrorHandler.validateTableResult("1d6 gold pieces")
        try ErrorHandler.validateTableResult("A")
        try ErrorHandler.validateTableResult(String(repeating: "a", count: 500))
        
        // Invalid results
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableResult("")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableResult("   ")
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateTableResult(String(repeating: "a", count: 501))
        }
    }
    
    @Test("Circular reference detection")
    func circularReferenceDetection() throws {
        // No circular reference should not throw
        try ErrorHandler.detectCircularReference(tableName: "table1", referencePath: ["table2", "table3"])
        try ErrorHandler.detectCircularReference(tableName: "table1", referencePath: [])
        
        // Circular reference should throw
        #expect(throws: ParseError.self) {
            try ErrorHandler.detectCircularReference(tableName: "table1", referencePath: ["table2", "table1"])
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.detectCircularReference(tableName: "table1", referencePath: ["table1"])
        }
    }
    
    @Test("Recursion depth validation")
    func recursionDepthValidation() throws {
        // Valid depths should not throw
        try ErrorHandler.validateRecursionDepth(currentDepth: 0, limit: 10)
        try ErrorHandler.validateRecursionDepth(currentDepth: 5, limit: 10)
        try ErrorHandler.validateRecursionDepth(currentDepth: 10, limit: 10)
        
        // Exceeded depth should throw
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateRecursionDepth(currentDepth: 11, limit: 10)
        }
        
        #expect(throws: ParseError.self) {
            try ErrorHandler.validateRecursionDepth(currentDepth: 100, limit: 10)
        }
    }
    
    @Test("Error enhancement")
    func errorEnhancement() throws {
        let originalError = ParseError.invalidExpression(message: "Test error")
        let enhancedError = ErrorHandler.enhanceError(originalError, context: "While parsing table")
        
        if let parseError = enhancedError as? ParseError,
           case .invalidExpression(let message) = parseError {
            #expect(message.contains("While parsing table"))
            #expect(message.contains("Test error"))
        } else {
            #expect(Bool(false), "Enhanced error should be a ParseError.invalidExpression")
        }
    }
    
    @Test("User-friendly error messages")
    func userFriendlyErrorMessages() throws {
        let token = Token(type: .identifier, value: "test", position: 5, line: 1, column: 5)
        let errors: [ParseError] = [
            .unexpectedToken(expected: "number", found: token),
            .unexpectedEndOfInput(expected: "closing parenthesis"),
            .invalidDiceNotation(message: "Invalid dice count"),
            .divisionByZero,
            .tableNotFound(tableName: "test_table"),
            .circularTableReference(tableName: "test", referencePath: ["a", "b"]),
            .recursionLimitExceeded(limit: 10),
            .invalidKeepDropCount(count: 5, totalDice: 3),
            .invalidThreshold(threshold: -1),
            .outOfRange(value: 1001, min: 1, max: 1000)
        ]
        
        for error in errors {
            let friendlyMessage = ErrorHandler.createUserFriendlyError(error)
            #expect(!friendlyMessage.isEmpty)
            #expect(!friendlyMessage.contains("ParseError"))
        }
    }
    
    @Test("Correction suggestions")
    func correctionSuggestions() throws {
        let token = Token(type: .identifier, value: "6", position: 1, line: 1, column: 1)
        
        // Test suggestion for missing 'd'
        let suggestion1 = ErrorHandler.suggestCorrection(
            for: "6+3",
            error: .unexpectedToken(expected: "number", found: token)
        )
        #expect(suggestion1?.contains("d6") == true)
        
        // Test suggestion for unclosed parentheses
        let suggestion2 = ErrorHandler.suggestCorrection(
            for: "(2d6+3",
            error: .unclosedParentheses
        )
        #expect(suggestion2?.contains(")") == true)
        
        // Test suggestion for division by zero
        let suggestion3 = ErrorHandler.suggestCorrection(
            for: "2d6/0",
            error: .divisionByZero
        )
        #expect(suggestion3?.contains("zero") == true)
        
        // Test suggestion for table not found
        let suggestion4 = ErrorHandler.suggestCorrection(
            for: "@missing_table",
            error: .tableNotFound(tableName: "missing_table")
        )
        #expect(suggestion4?.contains("Register") == true)
    }
    
    @Test("Expression validation")
    func expressionValidation() throws {
        // Valid expressions
        let validResults = [
            ErrorHandler.validateExpression("2d6+3"),
            ErrorHandler.validateExpression("4d6kh3"),
            ErrorHandler.validateExpression("(2d6+3)*2")
        ]
        
        for result in validResults {
            #expect(result.isValid)
            #expect(!result.hasWarnings)
        }
        
        // Invalid expressions
        let invalidResults = [
            ErrorHandler.validateExpression("2d6+"),
            ErrorHandler.validateExpression("(2d6+3")
        ]
        
        for result in invalidResults {
            #expect(!result.isValid)
            #expect(!result.errors.isEmpty)
        }
        
        // Expressions with warnings
        let warningResults = [
            ErrorHandler.validateExpression("2d0+3"),
            ErrorHandler.validateExpression("2d6/0"),
            ErrorHandler.validateExpression("(2d6+3")
        ]
        
        for result in warningResults {
            #expect(result.hasWarnings)
        }
    }
    
    @Test("Division by zero error")
    func divisionByZeroError() throws {
        let parser = DiceLangParser()
        
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
    }
    
    @Test("Enhanced error descriptions")
    func enhancedErrorDescriptions() throws {
        let errors: [ParseError] = [
            .tableNotFound(tableName: "missing"),
            .circularTableReference(tableName: "loop", referencePath: ["a", "b", "loop"]),
            .recursionLimitExceeded(limit: 5),
            .invalidKeepDropCount(count: 10, totalDice: 3),
            .invalidThreshold(threshold: 0),
            .divisionByZero,
            .negativeResult(operation: "subtraction"),
            .outOfRange(value: 2000, min: 1, max: 1000)
        ]
        
        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(!description!.isEmpty)
        }
    }
}