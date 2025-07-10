import Testing
@testable import DiceLang

struct ParserTests {
    
    // MARK: - Literal Expression Tests
    
    @Test("Parser parses simple numbers")
    func testSimpleNumber() throws {
        let expression = try Parser.parse("42")
        
        #expect(expression is LiteralExpression)
        let literal = expression as! LiteralExpression
        #expect(literal.value == 42)
        #expect(literal.description == "42")
    }
    
    @Test("Parser parses negative numbers")
    func testNegativeNumber() throws {
        let expression = try Parser.parse("-42")
        
        #expect(expression is UnaryExpression)
        let unary = expression as! UnaryExpression
        #expect(unary.operator == .negate)
        #expect(unary.operand is LiteralExpression)
    }
    
    // MARK: - Dice Expression Tests
    
    @Test("Parser parses basic dice roll")
    func testBasicDiceRoll() throws {
        let expression = try Parser.parse("2d6")
        
        #expect(expression is DiceRollExpression)
        let dice = expression as! DiceRollExpression
        #expect(dice.count == 2)
        #expect(dice.sides == 6)
        #expect(dice.description == "2d6")
    }
    
    @Test("Parser parses single die")
    func testSingleDie() throws {
        let expression = try Parser.parse("d20")
        
        #expect(expression is DiceRollExpression)
        let dice = expression as! DiceRollExpression
        #expect(dice.count == 1)
        #expect(dice.sides == 20)
        #expect(dice.description == "1d20")
    }
    
    @Test("Parser parses exploding dice")
    func testExplodingDice() throws {
        let expression = try Parser.parse("d6!")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 1)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .exploding)
    }
    
    @Test("Parser parses compound exploding dice")
    func testCompoundExplodingDice() throws {
        let expression = try Parser.parse("d10!!")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 1)
        #expect(modified.diceExpression.sides == 10)
        #expect(modified.modifier == .compoundExploding)
    }
    
    @Test("Parser parses keep highest modifier")
    func testKeepHighest() throws {
        let expression = try Parser.parse("4d6kh3")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 4)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .keepHighest(3))
    }
    
    @Test("Parser parses keep lowest modifier")
    func testKeepLowest() throws {
        let expression = try Parser.parse("4d6kl1")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 4)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .keepLowest(1))
    }
    
    @Test("Parser parses drop highest modifier")
    func testDropHighest() throws {
        let expression = try Parser.parse("4d6dh1")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 4)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .dropHighest(1))
    }
    
    @Test("Parser parses drop lowest modifier")
    func testDropLowest() throws {
        let expression = try Parser.parse("4d6dl1")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 4)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .dropLowest(1))
    }
    
    @Test("Parser parses dice pools with thresholds")
    func testDicePoolGreaterThanOrEqual() throws {
        let expression = try Parser.parse("10d6>=5")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 10)
        #expect(modified.diceExpression.sides == 6)
        #expect(modified.modifier == .threshold(.greaterThanOrEqual, 5))
    }
    
    @Test("Parser parses dice pools with greater than")
    func testDicePoolGreaterThan() throws {
        let expression = try Parser.parse("8d10>7")
        
        #expect(expression is ModifiedDiceExpression)
        let modified = expression as! ModifiedDiceExpression
        #expect(modified.diceExpression.count == 8)
        #expect(modified.diceExpression.sides == 10)
        #expect(modified.modifier == .threshold(.greaterThan, 7))
    }
    
    // MARK: - Arithmetic Expression Tests
    
    @Test("Parser parses simple addition")
    func testSimpleAddition() throws {
        let expression = try Parser.parse("2+3")
        
        #expect(expression is BinaryExpression)
        let binary = expression as! BinaryExpression
        #expect(binary.operator == .add)
        #expect(binary.left is LiteralExpression)
        #expect(binary.right is LiteralExpression)
    }
    
    @Test("Parser parses dice with modifier")
    func testDiceWithModifier() throws {
        let expression = try Parser.parse("2d6+3")
        
        #expect(expression is BinaryExpression)
        let binary = expression as! BinaryExpression
        #expect(binary.operator == .add)
        #expect(binary.left is DiceRollExpression)
        #expect(binary.right is LiteralExpression)
    }
    
    @Test("Parser respects operator precedence")
    func testOperatorPrecedence() throws {
        let expression = try Parser.parse("2+3*4")
        
        #expect(expression is BinaryExpression)
        let binary = expression as! BinaryExpression
        #expect(binary.operator == .add)
        #expect(binary.left is LiteralExpression)
        #expect(binary.right is BinaryExpression)
        
        let rightBinary = binary.right as! BinaryExpression
        #expect(rightBinary.operator == .multiply)
    }
    
    @Test("Parser handles parentheses")
    func testParentheses() throws {
        let expression = try Parser.parse("(2+3)*4")
        
        #expect(expression is BinaryExpression)
        let binary = expression as! BinaryExpression
        #expect(binary.operator == .multiply)
        #expect(binary.left is GroupExpression)
        #expect(binary.right is LiteralExpression)
        
        let group = binary.left as! GroupExpression
        #expect(group.expression is BinaryExpression)
    }
    
    @Test("Parser handles complex expressions")
    func testComplexExpression() throws {
        let expression = try Parser.parse("2d6+1d4-3")
        
        #expect(expression is BinaryExpression)
        let outerBinary = expression as! BinaryExpression
        #expect(outerBinary.operator == .subtract)
        #expect(outerBinary.right is LiteralExpression)
        
        #expect(outerBinary.left is BinaryExpression)
        let innerBinary = outerBinary.left as! BinaryExpression
        #expect(innerBinary.operator == .add)
        #expect(innerBinary.left is DiceRollExpression)
        #expect(innerBinary.right is DiceRollExpression)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Parser throws on empty input")
    func testEmptyInput() {
        #expect(throws: ParseError.self) {
            try Parser.parse("")
        }
    }
    
    @Test("Parser throws on invalid dice notation")
    func testInvalidDiceNotation() {
        #expect(throws: ParseError.self) {
            try Parser.parse("2d0")
        }
    }
    
    @Test("Parser throws on missing operand")
    func testMissingOperand() {
        #expect(throws: ParseError.self) {
            try Parser.parse("2d6+")
        }
    }
    
    @Test("Parser throws on unclosed parentheses")
    func testUnclosedParentheses() {
        #expect(throws: ParseError.self) {
            try Parser.parse("(2d6+3")
        }
    }
    
    @Test("Parser throws on unexpected token")
    func testUnexpectedToken() {
        #expect(throws: ParseError.self) {
            try Parser.parse("2d6 extra")
        }
    }
    
    @Test("Parser throws on invalid numbers")
    func testInvalidNumbers() {
        #expect(throws: ParseError.self) {
            try Parser.parse("0d6")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Parser handles large numbers")
    func testLargeNumbers() throws {
        let expression = try Parser.parse("100d100")
        
        #expect(expression is DiceRollExpression)
        let dice = expression as! DiceRollExpression
        #expect(dice.count == 100)
        #expect(dice.sides == 100)
    }
    
    @Test("Parser handles nested parentheses")
    func testNestedParentheses() throws {
        let expression = try Parser.parse("((2d6))")
        
        #expect(expression is GroupExpression)
        let outerGroup = expression as! GroupExpression
        #expect(outerGroup.expression is GroupExpression)
        
        let innerGroup = outerGroup.expression as! GroupExpression
        #expect(innerGroup.expression is DiceRollExpression)
    }
    
    @Test("Parser handles multiple operators")
    func testMultipleOperators() throws {
        let expression = try Parser.parse("1+2-3*4/5")
        
        #expect(expression is BinaryExpression)
        // This tests that the parser correctly builds the AST with proper precedence
        let result = expression.description
        #expect(result.contains("+"))
        #expect(result.contains("-"))
        #expect(result.contains("*"))
        #expect(result.contains("/"))
    }
    
    // MARK: - Advanced Dice Mechanics Tests (Phase 3)
    
    @Test("Parser handles long form keep highest")
    func testLongFormKeepHighest() throws {
        let expression = try Parser.parse("4d6 keep highest 3")
        
        #expect(expression is ModifiedDiceExpression)
        let modifiedExpr = expression as! ModifiedDiceExpression
        
        #expect(modifiedExpr.diceExpression.count == 4)
        #expect(modifiedExpr.diceExpression.sides == 6)
        
        if case .keepHighest(let count) = modifiedExpr.modifier {
            #expect(count == 3)
        } else {
            Issue.record("Expected keepHighest modifier")
        }
    }
    
    @Test("Parser handles long form keep lowest")
    func testLongFormKeepLowest() throws {
        let expression = try Parser.parse("6d8 keep lowest 2")
        
        #expect(expression is ModifiedDiceExpression)
        let modifiedExpr = expression as! ModifiedDiceExpression
        
        #expect(modifiedExpr.diceExpression.count == 6)
        #expect(modifiedExpr.diceExpression.sides == 8)
        
        if case .keepLowest(let count) = modifiedExpr.modifier {
            #expect(count == 2)
        } else {
            Issue.record("Expected keepLowest modifier")
        }
    }
    
    @Test("Parser handles long form drop highest")
    func testLongFormDropHighest() throws {
        let expression = try Parser.parse("5d10 drop highest 1")
        
        #expect(expression is ModifiedDiceExpression)
        let modifiedExpr = expression as! ModifiedDiceExpression
        
        #expect(modifiedExpr.diceExpression.count == 5)
        #expect(modifiedExpr.diceExpression.sides == 10)
        
        if case .dropHighest(let count) = modifiedExpr.modifier {
            #expect(count == 1)
        } else {
            Issue.record("Expected dropHighest modifier")
        }
    }
    
    @Test("Parser handles long form drop lowest")
    func testLongFormDropLowest() throws {
        let expression = try Parser.parse("8d4 drop lowest 2")
        
        #expect(expression is ModifiedDiceExpression)
        let modifiedExpr = expression as! ModifiedDiceExpression
        
        #expect(modifiedExpr.diceExpression.count == 8)
        #expect(modifiedExpr.diceExpression.sides == 4)
        
        if case .dropLowest(let count) = modifiedExpr.modifier {
            #expect(count == 2)
        } else {
            Issue.record("Expected dropLowest modifier")
        }
    }
    
    @Test("Parser handles dice pools with different comparison operators")
    func testDicePoolsWithVariousOperators() throws {
        // Test greater than
        let expr1 = try Parser.parse("8d10 > 7")
        #expect(expr1 is ModifiedDiceExpression)
        let modified1 = expr1 as! ModifiedDiceExpression
        if case .threshold(let op, let value) = modified1.modifier {
            #expect(op == .greaterThan)
            #expect(value == 7)
        } else {
            Issue.record("Expected threshold modifier with greater than")
        }
        
        // Test less than
        let expr2 = try Parser.parse("6d6 < 3")
        #expect(expr2 is ModifiedDiceExpression)
        let modified2 = expr2 as! ModifiedDiceExpression
        if case .threshold(let op, let value) = modified2.modifier {
            #expect(op == .lessThan)
            #expect(value == 3)
        } else {
            Issue.record("Expected threshold modifier with less than")
        }
        
        // Test less than or equal
        let expr3 = try Parser.parse("12d8 <= 4")
        #expect(expr3 is ModifiedDiceExpression)
        let modified3 = expr3 as! ModifiedDiceExpression
        if case .threshold(let op, let value) = modified3.modifier {
            #expect(op == .lessThanOrEqual)
            #expect(value == 4)
        } else {
            Issue.record("Expected threshold modifier with less than or equal")
        }
    }
    
    @Test("Parser handles complex arithmetic with modified dice")
    func testComplexArithmeticWithModifiedDice() throws {
        let expression = try Parser.parse("(4d6 kh3) + 2 * (3d8 drop lowest 1)")
        
        #expect(expression is BinaryExpression)
        let binaryExpr = expression as! BinaryExpression
        #expect(binaryExpr.`operator` == .add)
        
        // Left side should be grouped modified dice
        #expect(binaryExpr.left is GroupExpression)
        let leftGroup = binaryExpr.left as! GroupExpression
        #expect(leftGroup.expression is ModifiedDiceExpression)
        
        // Right side should be multiplication
        #expect(binaryExpr.right is BinaryExpression)
        let rightMult = binaryExpr.right as! BinaryExpression
        #expect(rightMult.`operator` == .multiply)
    }
    
    @Test("Parser validates keep/drop counts")
    func testKeepDropValidation() throws {
        // Test that parser accepts valid keep/drop expressions
        let _ = try Parser.parse("4d6 kh3")  // Keep 3 out of 4 dice
        let _ = try Parser.parse("6d8 drop lowest 2")  // Drop 2 out of 6 dice
        
        // These should parse successfully without throwing
    }
    
    @Test("Parser handles edge cases for dice pools")
    func testDicePoolEdgeCases() throws {
        // Single die pool
        let expr1 = try Parser.parse("d20 >= 15")
        #expect(expr1 is ModifiedDiceExpression)
        
        // Large threshold values
        let expr2 = try Parser.parse("100d6 >= 999")
        #expect(expr2 is ModifiedDiceExpression)
        
        // Zero threshold
        let expr3 = try Parser.parse("5d4 > 0")
        #expect(expr3 is ModifiedDiceExpression)
    }
    
    @Test("Parser handles mixed short and long form modifiers")
    func testMixedModifierForms() throws {
        // Short form
        let expr1 = try Parser.parse("4d6kh3")
        #expect(expr1 is ModifiedDiceExpression)
        
        // Long form
        let expr2 = try Parser.parse("4d6 keep highest 3")
        #expect(expr2 is ModifiedDiceExpression)
        
        // Both should produce equivalent results
        let modified1 = expr1 as! ModifiedDiceExpression
        let modified2 = expr2 as! ModifiedDiceExpression
        
        #expect(modified1.modifier == modified2.modifier)
    }
    
    // MARK: - Complex Multiple Modifier Tests
    
    @Test("Parser handles exploding dice with keep highest")
    func testExplodingDiceWithKeepHighest() throws {
        let expression = try Parser.parse("4d6!kh3")
        
        #expect(expression is MultiModifiedDiceExpression)
        let multiModified = expression as! MultiModifiedDiceExpression
        
        #expect(multiModified.diceExpression.count == 4)
        #expect(multiModified.diceExpression.sides == 6)
        #expect(multiModified.modifiers.count == 2)
        
        // First modifier should be exploding
        #expect(multiModified.modifiers[0] == .exploding)
        
        // Second modifier should be keep highest 3
        if case .keepHighest(let count) = multiModified.modifiers[1] {
            #expect(count == 3)
        } else {
            Issue.record("Expected keepHighest(3) as second modifier")
        }
    }
    
    @Test("Parser handles compound exploding with drop lowest")
    func testCompoundExplodingWithDropLowest() throws {
        let expression = try Parser.parse("6d10!! drop lowest 2")
        
        #expect(expression is MultiModifiedDiceExpression)
        let multiModified = expression as! MultiModifiedDiceExpression
        
        #expect(multiModified.diceExpression.count == 6)
        #expect(multiModified.diceExpression.sides == 10)
        #expect(multiModified.modifiers.count == 2)
        
        // First modifier should be compound exploding
        #expect(multiModified.modifiers[0] == .compoundExploding)
        
        // Second modifier should be drop lowest 2
        if case .dropLowest(let count) = multiModified.modifiers[1] {
            #expect(count == 2)
        } else {
            Issue.record("Expected dropLowest(2) as second modifier")
        }
    }
    
    @Test("Parser handles exploding dice with threshold")
    func testExplodingDiceWithThreshold() throws {
        let expression = try Parser.parse("8d6! >= 4")
        
        #expect(expression is MultiModifiedDiceExpression)
        let multiModified = expression as! MultiModifiedDiceExpression
        
        #expect(multiModified.diceExpression.count == 8)
        #expect(multiModified.diceExpression.sides == 6)
        #expect(multiModified.modifiers.count == 2)
        
        // First modifier should be exploding
        #expect(multiModified.modifiers[0] == .exploding)
        
        // Second modifier should be threshold >= 4
        if case .threshold(let op, let value) = multiModified.modifiers[1] {
            #expect(op == .greaterThanOrEqual)
            #expect(value == 4)
        } else {
            Issue.record("Expected threshold(>=, 4) as second modifier")
        }
    }
    
    @Test("Parser handles keep highest with threshold")
    func testKeepHighestWithThreshold() throws {
        let expression = try Parser.parse("10d8 kh5 > 6")
        
        #expect(expression is MultiModifiedDiceExpression)
        let multiModified = expression as! MultiModifiedDiceExpression
        
        #expect(multiModified.diceExpression.count == 10)
        #expect(multiModified.diceExpression.sides == 8)
        #expect(multiModified.modifiers.count == 2)
        
        // First modifier should be keep highest 5
        if case .keepHighest(let count) = multiModified.modifiers[0] {
            #expect(count == 5)
        } else {
            Issue.record("Expected keepHighest(5) as first modifier")
        }
        
        // Second modifier should be threshold > 6
        if case .threshold(let op, let value) = multiModified.modifiers[1] {
            #expect(op == .greaterThan)
            #expect(value == 6)
        } else {
            Issue.record("Expected threshold(>, 6) as second modifier")
        }
    }
    
    @Test("Parser handles long form multiple modifiers")
    func testLongFormMultipleModifiers() throws {
        let expression = try Parser.parse("6d12! keep highest 4 >= 8")
        
        #expect(expression is MultiModifiedDiceExpression)
        let multiModified = expression as! MultiModifiedDiceExpression
        
        #expect(multiModified.diceExpression.count == 6)
        #expect(multiModified.diceExpression.sides == 12)
        #expect(multiModified.modifiers.count == 3)
        
        // First modifier should be exploding
        #expect(multiModified.modifiers[0] == .exploding)
        
        // Second modifier should be keep highest 4
        if case .keepHighest(let count) = multiModified.modifiers[1] {
            #expect(count == 4)
        } else {
            Issue.record("Expected keepHighest(4) as second modifier")
        }
        
        // Third modifier should be threshold >= 8
        if case .threshold(let op, let value) = multiModified.modifiers[2] {
            #expect(op == .greaterThanOrEqual)
            #expect(value == 8)
        } else {
            Issue.record("Expected threshold(>=, 8) as third modifier")
        }
    }
    
    @Test("Parser description includes all modifiers")
    func testMultipleModifierDescription() throws {
        let expression = try Parser.parse("4d6!kh3")
        
        let description = expression.description
        #expect(description.contains("4d6"))
        #expect(description.contains("!"))
        #expect(description.contains("kh3"))
        
        // Should show as "4d6!kh3"
        #expect(description == "4d6!kh3")
    }
    
    // MARK: - Edge Case and Error Handling Tests
    
    @Test("Parser validates keep count against dice count")
    func testKeepCountValidation() throws {
        // Try to keep more dice than rolled
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 kh5")
        }
        
        // Try to keep zero dice
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 kh0")
        }
        
        // Valid keep operation
        let _ = try Parser.parse("4d6 kh3")  // Should succeed
    }
    
    @Test("Parser validates drop count against dice count") 
    func testDropCountValidation() throws {
        // Try to drop all dice
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 dh4")
        }
        
        // Try to drop more dice than rolled
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 dh5")
        }
        
        // Try to drop zero dice
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 dh0")
        }
        
        // Valid drop operation
        let _ = try Parser.parse("4d6 dh3")  // Should succeed
    }
    
    @Test("Parser validates long form keep/drop counts")
    func testLongFormKeepDropValidation() throws {
        // Invalid keep counts
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 keep highest 5")
        }
        
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 keep lowest 0")
        }
        
        // Invalid drop counts
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 drop highest 4")
        }
        
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 drop lowest 5")
        }
        
        // Valid operations
        let _ = try Parser.parse("4d6 keep highest 3")  // Should succeed
        let _ = try Parser.parse("4d6 drop lowest 2")   // Should succeed
    }
    
    @Test("Parser validates threshold values")
    func testThresholdValidation() throws {
        // Negative threshold should fail
        #expect(throws: ParseError.self) {
            try Parser.parse("4d6 >= -1")
        }
        
        // Zero threshold should succeed
        let _ = try Parser.parse("4d6 > 0")
        
        // High threshold should succeed (even if unlikely to trigger)
        let _ = try Parser.parse("4d6 >= 10")
    }
    
    @Test("Parser handles boundary cases for single die")
    func testSingleDieBoundaries() throws {
        // Can't drop from single die
        #expect(throws: ParseError.self) {
            try Parser.parse("d20 dh1")
        }
        
        // Can keep single die
        let expr = try Parser.parse("d20 kh1")
        #expect(expr is ModifiedDiceExpression)
        
        // Single die with threshold
        let thresholdExpr = try Parser.parse("d20 >= 15")
        #expect(thresholdExpr is ModifiedDiceExpression)
    }
    
    @Test("Parser handles complex boundary interactions")
    func testComplexBoundaryValidation() throws {
        // Multiple modifiers with edge cases
        #expect(throws: ParseError.self) {
            try Parser.parse("2d6! kh3")  // Can't keep more than rolled
        }
        
        #expect(throws: ParseError.self) {
            try Parser.parse("3d8 drop highest 3")  // Can't drop all dice
        }
        
        // Valid complex combinations
        let _ = try Parser.parse("6d10! kh4 >= 7")  // Should succeed
        let _ = try Parser.parse("8d6 drop lowest 2 > 3")  // Should succeed
    }
    
    @Test("Parser handles large dice counts")
    func testLargeDiceCounts() throws {
        // Large but valid dice count
        let expr = try Parser.parse("100d6 kh50")
        #expect(expr is ModifiedDiceExpression)
        
        // Large drop that leaves some dice
        let dropExpr = try Parser.parse("50d10 drop lowest 25")
        #expect(dropExpr is ModifiedDiceExpression)
    }
    
    @Test("Parser handles dice with large numbers of sides")
    func testLargeDiceSides() throws {
        // Large die with reasonable threshold
        let expr = try Parser.parse("d100 >= 90")
        #expect(expr is ModifiedDiceExpression)
        
        // Threshold higher than max die value (should still parse)
        let impossibleExpr = try Parser.parse("d6 >= 10")
        #expect(impossibleExpr is ModifiedDiceExpression)
    }
    
    @Test("Parser provides meaningful error messages")
    func testErrorMessages() {
        do {
            _ = try Parser.parse("4d6 kh5")
            Issue.record("Expected error for invalid keep count")
        } catch let error as ParseError {
            switch error {
            case .invalidDiceNotation(let message):
                #expect(message.contains("Cannot keep more dice"))
                #expect(message.contains("5"))
                #expect(message.contains("4"))
            default:
                Issue.record("Expected invalidDiceNotation error")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}