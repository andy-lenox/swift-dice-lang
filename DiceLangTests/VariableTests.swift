import Foundation
import Testing
@testable import DiceLang

@Suite("Variable Tests")
struct VariableTests {
    
    // MARK: - Variable Context Tests
    
    @Test("Variable context can declare and retrieve variables")
    func testVariableContextBasicOperations() throws {
        let context = VariableContext()
        let expression = LiteralExpression(42)
        
        // Test declaration
        try context.declare("testVar", expression: expression)
        
        // Test retrieval
        let retrieved = try context.get("testVar")
        #expect(retrieved is LiteralExpression)
        
        // Test contains
        #expect(context.contains("testVar"))
        #expect(!context.contains("nonexistent"))
        
        // Test declared variables
        #expect(context.declaredVariables.contains("testVar"))
    }
    
    @Test("Variable context prevents redeclaration")
    func testVariableRedeclarationPrevention() throws {
        let context = VariableContext()
        let expression1 = LiteralExpression(42)
        let expression2 = LiteralExpression(24)
        
        // First declaration should succeed
        try context.declare("testVar", expression: expression1)
        
        // Second declaration should fail
        #expect(throws: ParseError.self) {
            try context.declare("testVar", expression: expression2)
        }
    }
    
    @Test("Variable context throws error for undefined variables")
    func testUndefinedVariableError() throws {
        let context = VariableContext()
        
        #expect(throws: ParseError.self) {
            _ = try context.get("undefined")
        }
    }
    
    @Test("Variable context can be copied")
    func testVariableContextCopy() throws {
        let originalContext = VariableContext()
        let expression = LiteralExpression(42)
        
        try originalContext.declare("testVar", expression: expression)
        
        let copiedContext = originalContext.copy()
        
        // Both should contain the variable
        #expect(originalContext.contains("testVar"))
        #expect(copiedContext.contains("testVar"))
        
        // Changes to copy shouldn't affect original
        let newExpression = LiteralExpression(24)
        try copiedContext.declare("newVar", expression: newExpression)
        
        #expect(copiedContext.contains("newVar"))
        #expect(!originalContext.contains("newVar"))
    }
    
    // MARK: - Token and Lexer Tests
    
    @Test("Lexer tokenizes assignment operator")
    func testAssignmentTokenization() throws {
        let lexer = Lexer(input: "x = 2d6")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count >= 5) // identifier, assign, number, dice, number, eof
        #expect(tokens[0].type == .identifier)
        #expect(tokens[0].value == "x")
        #expect(tokens[1].type == .assign)
        #expect(tokens[1].value == "=")
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "2")
        #expect(tokens[3].type == .dice)
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "6")
    }
    
    @Test("Lexer distinguishes assignment from arrow")
    func testAssignmentVsArrow() throws {
        let assignLexer = Lexer(input: "x = 5")
        let assignTokens = assignLexer.tokenize()
        
        let arrowLexer = Lexer(input: "x => outcome")
        let arrowTokens = arrowLexer.tokenize()
        
        #expect(assignTokens[1].type == .assign)
        #expect(assignTokens[1].value == "=")
        
        #expect(arrowTokens[1].type == .arrow)
        #expect(arrowTokens[1].value == "=>")
    }
    
    // MARK: - Parser Tests
    
    @Test("Parser handles variable declarations")
    func testVariableDeclarationParsing() throws {
        let parser = try createParser("damage = 2d6+3")
        let expression = try parser.parse()
        
        #expect(expression is VariableDeclarationExpression)
        
        if let varDecl = expression as? VariableDeclarationExpression {
            #expect(varDecl.name == "damage")
            #expect(varDecl.expression is BinaryExpression)
        }
    }
    
    @Test("Parser handles variable references")
    func testVariableReferenceParsing() throws {
        let parser = try createParser("damage")
        let expression = try parser.parse()
        
        #expect(expression is VariableReferenceExpression)
        
        if let varRef = expression as? VariableReferenceExpression {
            #expect(varRef.name == "damage")
        }
    }
    
    @Test("Parser correctly distinguishes declarations from references")
    func testDeclarationVsReference() throws {
        // Declaration
        let declParser = try createParser("x = 5")
        let declExpr = try declParser.parse()
        #expect(declExpr is VariableDeclarationExpression)
        
        // Reference
        let refParser = try createParser("x")
        let refExpr = try refParser.parse()
        #expect(refExpr is VariableReferenceExpression)
    }
    
    @Test("Parser handles complex variable expressions")
    func testComplexVariableExpressions() throws {
        let parser = try createParser("total = (2d6 + strength) * 2")
        let expression = try parser.parse()
        
        #expect(expression is VariableDeclarationExpression)
        
        if let varDecl = expression as? VariableDeclarationExpression {
            #expect(varDecl.name == "total")
            #expect(varDecl.expression is BinaryExpression)
        }
    }
    
    // MARK: - Evaluation Tests
    
    @Test("Variable declaration evaluates correctly")
    func testVariableDeclarationEvaluation() throws {
        let context = createEvaluationContext()
        let expression = VariableDeclarationExpression(name: "test", expression: LiteralExpression(42))
        
        let result = try expression.evaluate(with: context)
        
        #expect(result.total == 42)
        #expect(context.variableContext.contains("test"))
        
        // Variable should be retrievable
        let retrieved = try context.variableContext.get("test")
        let retrievedResult = try retrieved.evaluate(with: context)
        #expect(retrievedResult.total == 42)
    }
    
    @Test("Variable reference evaluates correctly")
    func testVariableReferenceEvaluation() throws {
        let context = createEvaluationContext()
        
        // First declare a variable
        let declaration = VariableDeclarationExpression(name: "test", expression: LiteralExpression(24))
        _ = try declaration.evaluate(with: context)
        
        // Then reference it
        let reference = VariableReferenceExpression(name: "test")
        let result = try reference.evaluate(with: context)
        
        #expect(result.total == 24)
    }
    
    @Test("Variable reference throws error for undefined variable")
    func testUndefinedVariableReference() throws {
        let context = createEvaluationContext()
        let reference = VariableReferenceExpression(name: "undefined")
        
        #expect(throws: ParseError.self) {
            _ = try reference.evaluate(with: context)
        }
    }
    
    @Test("Variables work in complex expressions")
    func testVariablesInComplexExpressions() throws {
        let context = createEvaluationContext()
        
        // Declare variables
        let strengthDecl = VariableDeclarationExpression(name: "strength", expression: LiteralExpression(15))
        _ = try strengthDecl.evaluate(with: context)
        
        let diceDecl = VariableDeclarationExpression(name: "dice", expression: LiteralExpression(6)) // Simulating 1d6
        _ = try diceDecl.evaluate(with: context)
        
        // Use variables in expression
        let strengthRef = VariableReferenceExpression(name: "strength")
        let diceRef = VariableReferenceExpression(name: "dice")
        let totalExpr = BinaryExpression(left: strengthRef, operator: .add, right: diceRef)
        
        let result = try totalExpr.evaluate(with: context)
        #expect(result.total == 21) // 15 + 6
    }
    
    // MARK: - Integration Tests
    
    @Test("End-to-end variable functionality")
    func testEndToEndVariables() throws {
        // Test parsing and evaluation of variable declaration
        let result = try Parser.parseAndEvaluate("damage = 10")
        #expect(result.total == 10)
        
        // Test that the variable persists in context for next evaluation
        let context = createEvaluationContext()
        _ = try Parser.parseAndEvaluate("damage = 10", context: context)
        let referenceResult = try Parser.parseAndEvaluate("damage", context: context)
        #expect(referenceResult.total == 10)
    }
    
    @Test("Variable immutability")
    func testVariableImmutability() throws {
        let context = createEvaluationContext()
        
        // Declare variable
        _ = try Parser.parseAndEvaluate("x = 5", context: context)
        
        // Attempt to redeclare should fail
        #expect(throws: ParseError.self) {
            _ = try Parser.parseAndEvaluate("x = 10", context: context)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createParser(_ input: String) throws -> Parser {
        let lexer = Lexer(input: input)
        let tokens = lexer.tokenize()
        return Parser(tokens: tokens)
    }
    
    private func createEvaluationContext() -> EvaluationContext {
        return EvaluationContext(variableContext: VariableContext())
    }
}

// MARK: - Test Extensions

extension ParseError: @retroactive Equatable {
    public static func == (lhs: ParseError, rhs: ParseError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}