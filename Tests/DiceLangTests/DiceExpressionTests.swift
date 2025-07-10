import Testing
@testable import DiceLang

struct DiceExpressionTests {
    
    // MARK: - Test Setup
    
    private func createFixedContext(values: [Int]) -> EvaluationContext {
        let rng = FixedRandomNumberGenerator(values: values)
        return EvaluationContext(randomNumberGenerator: rng)
    }
    
    // MARK: - Literal Expression Tests
    
    @Test("LiteralExpression evaluates correctly")
    func testLiteralExpression() throws {
        let expression = LiteralExpression(42)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 42)
        #expect(result.rolls == [42])
        #expect(result.type == .standard)
    }
    
    // MARK: - Dice Roll Expression Tests
    
    @Test("DiceRollExpression evaluates correctly")
    func testDiceRollExpression() throws {
        let expression = DiceRollExpression(count: 2, sides: 6)
        let context = createFixedContext(values: [3, 5])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 8)
        #expect(result.rolls == [3, 5])
        #expect(result.type == .standard)
    }
    
    @Test("Single die expression evaluates correctly")
    func testSingleDieExpression() throws {
        let expression = DiceRollExpression(count: 1, sides: 20)
        let context = createFixedContext(values: [15])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 15)
        #expect(result.rolls == [15])
        #expect(result.type == .standard)
    }
    
    // MARK: - Binary Expression Tests
    
    @Test("BinaryExpression addition evaluates correctly")
    func testBinaryAddition() throws {
        let left = LiteralExpression(5)
        let right = LiteralExpression(3)
        let expression = BinaryExpression(left: left, operator: .add, right: right)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 8)
        #expect(result.rolls == [8])
    }
    
    @Test("BinaryExpression subtraction evaluates correctly")
    func testBinarySubtraction() throws {
        let left = LiteralExpression(10)
        let right = LiteralExpression(3)
        let expression = BinaryExpression(left: left, operator: .subtract, right: right)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 7)
        #expect(result.rolls == [7])
    }
    
    @Test("BinaryExpression multiplication evaluates correctly")
    func testBinaryMultiplication() throws {
        let left = LiteralExpression(4)
        let right = LiteralExpression(3)
        let expression = BinaryExpression(left: left, operator: .multiply, right: right)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 12)
        #expect(result.rolls == [12])
    }
    
    @Test("BinaryExpression division evaluates correctly")
    func testBinaryDivision() throws {
        let left = LiteralExpression(15)
        let right = LiteralExpression(3)
        let expression = BinaryExpression(left: left, operator: .divide, right: right)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 5)
        #expect(result.rolls == [5])
    }
    
    @Test("BinaryExpression throws on division by zero")
    func testDivisionByZero() {
        let left = LiteralExpression(10)
        let right = LiteralExpression(0)
        let expression = BinaryExpression(left: left, operator: .divide, right: right)
        let context = createFixedContext(values: [])
        
        #expect(throws: ParseError.self) {
            try expression.evaluate(with: context)
        }
    }
    
    @Test("BinaryExpression with dice evaluates correctly")
    func testBinaryWithDice() throws {
        let left = DiceRollExpression(count: 2, sides: 6)
        let right = LiteralExpression(3)
        let expression = BinaryExpression(left: left, operator: .add, right: right)
        let context = createFixedContext(values: [4, 2])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 9) // (4+2) + 3 = 9
        #expect(result.rolls == [9])
    }
    
    // MARK: - Unary Expression Tests
    
    @Test("UnaryExpression negation evaluates correctly")
    func testUnaryNegation() throws {
        let operand = LiteralExpression(5)
        let expression = UnaryExpression(operator: .negate, operand: operand)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == -5)
        #expect(result.rolls == [-5])
    }
    
    @Test("UnaryExpression positive evaluates correctly")
    func testUnaryPositive() throws {
        let operand = LiteralExpression(5)
        let expression = UnaryExpression(operator: .positive, operand: operand)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 5)
        #expect(result.rolls == [5])
    }
    
    @Test("UnaryExpression with dice evaluates correctly")
    func testUnaryWithDice() throws {
        let operand = DiceRollExpression(count: 1, sides: 6)
        let expression = UnaryExpression(operator: .negate, operand: operand)
        let context = createFixedContext(values: [4])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == -4)
        #expect(result.rolls == [-4])
    }
    
    // MARK: - Group Expression Tests
    
    @Test("GroupExpression evaluates correctly")
    func testGroupExpression() throws {
        let inner = LiteralExpression(42)
        let expression = GroupExpression(inner)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 42)
        #expect(result.rolls == [42])
    }
    
    @Test("GroupExpression with complex inner expression")
    func testGroupWithComplexExpression() throws {
        let left = LiteralExpression(2)
        let right = LiteralExpression(3)
        let inner = BinaryExpression(left: left, operator: .add, right: right)
        let expression = GroupExpression(inner)
        let context = createFixedContext(values: [])
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 5)
        #expect(result.rolls == [5])
    }
    
    // MARK: - Modified Dice Expression Tests
    
    @Test("ModifiedDiceExpression with exploding modifier")
    func testModifiedDiceExploding() throws {
        let diceExpression = DiceRollExpression(count: 1, sides: 6)
        let expression = ModifiedDiceExpression(diceExpression: diceExpression, modifier: .exploding)
        let context = createFixedContext(values: [6, 3]) // Roll max, then 3
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 9) // 6 + 3 (exploded)
        #expect(result.type == .exploding)
    }
    
    @Test("ModifiedDiceExpression with keep highest modifier")
    func testModifiedDiceKeepHighest() throws {
        let diceExpression = DiceRollExpression(count: 4, sides: 6)
        let expression = ModifiedDiceExpression(diceExpression: diceExpression, modifier: .keepHighest(3))
        let context = createFixedContext(values: [1, 6, 4, 3]) // Keep 6, 4, 3
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 13) // 6 + 4 + 3 = 13
        #expect(result.type == .keepDrop)
    }
    
    @Test("ModifiedDiceExpression with threshold modifier")
    func testModifiedDiceThreshold() throws {
        let diceExpression = DiceRollExpression(count: 3, sides: 6)
        let expression = ModifiedDiceExpression(diceExpression: diceExpression, modifier: .threshold(.greaterThanOrEqual, 4))
        let context = createFixedContext(values: [2, 5, 6]) // 2 successes (5 and 6)
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 2) // 2 successes
        #expect(result.type == .pool)
    }
    
    // MARK: - Integration Tests
    
    @Test("Complex expression integration test")
    func testComplexExpression() throws {
        // Test: (2d6 + 3) * 2
        let diceRoll = DiceRollExpression(count: 2, sides: 6)
        let modifier = LiteralExpression(3)
        let addition = BinaryExpression(left: diceRoll, operator: .add, right: modifier)
        let grouped = GroupExpression(addition)
        let multiplier = LiteralExpression(2)
        let final = BinaryExpression(left: grouped, operator: .multiply, right: multiplier)
        
        let context = createFixedContext(values: [4, 3])
        let result = try final.evaluate(with: context)
        
        #expect(result.total == 20) // ((4+3) + 3) * 2 = 10 * 2 = 20
    }
    
    // MARK: - Description Tests
    
    @Test("Expression descriptions are correct")
    func testExpressionDescriptions() {
        let literal = LiteralExpression(42)
        #expect(literal.description == "42")
        
        let dice = DiceRollExpression(count: 2, sides: 6)
        #expect(dice.description == "2d6")
        
        let binary = BinaryExpression(left: literal, operator: .add, right: dice)
        #expect(binary.description == "(42 + 2d6)")
        
        let unary = UnaryExpression(operator: .negate, operand: literal)
        #expect(unary.description == "-42")
        
        let group = GroupExpression(dice)
        #expect(group.description == "(2d6)")
        
        let modified = ModifiedDiceExpression(diceExpression: dice, modifier: .exploding)
        #expect(modified.description == "2d6!")
    }
    
    // MARK: - Parse and Evaluate Integration Tests
    
    @Test("Parse and evaluate simple expressions")
    func testParseAndEvaluateSimple() throws {
        let context = createFixedContext(values: [3, 4])
        
        let result = try Parser.parseAndEvaluate("2d6", context: context)
        
        #expect(result.total == 7)
        #expect(result.rolls == [3, 4])
    }
    
    @Test("Parse and evaluate complex expressions")
    func testParseAndEvaluateComplex() throws {
        let context = createFixedContext(values: [4, 2])
        
        let result = try Parser.parseAndEvaluate("(2d6 + 3) * 2", context: context)
        
        #expect(result.total == 18) // ((4+2) + 3) * 2 = 9 * 2 = 18
    }
    
    @Test("Parse and evaluate dice with modifiers")
    func testParseAndEvaluateWithModifiers() throws {
        let context = createFixedContext(values: [6, 4]) // First roll explodes
        
        let result = try Parser.parseAndEvaluate("d6!", context: context)
        
        #expect(result.total == 10) // 6 + 4 = 10
        #expect(result.type == .exploding)
    }
}