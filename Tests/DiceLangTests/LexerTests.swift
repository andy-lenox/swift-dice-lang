import Testing
@testable import DiceLang

struct LexerTests {
    
    @Test("Lexer tokenizes empty string correctly")
    func testEmptyString() {
        let lexer = Lexer(input: "")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 1)
        #expect(tokens[0].type == .eof)
    }
    
    @Test("Lexer tokenizes simple dice roll")
    func testSimpleDiceRoll() {
        let lexer = Lexer(input: "2d6")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 4) // number, dice, number, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "2")
        #expect(tokens[1].type == .dice)
        #expect(tokens[1].value == "d")
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .eof)
    }
    
    @Test("Lexer tokenizes dice roll with modifier")
    func testDiceRollWithModifier() {
        let lexer = Lexer(input: "2d6+3")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 6) // number, dice, number, plus, number, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "2")
        #expect(tokens[1].type == .dice)
        #expect(tokens[1].value == "d")
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .plus)
        #expect(tokens[3].value == "+")
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "3")
        #expect(tokens[5].type == .eof)
    }
    
    @Test("Lexer tokenizes arithmetic operators")
    func testArithmeticOperators() {
        let lexer = Lexer(input: "+-*/")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 5) // plus, minus, multiply, divide, eof
        #expect(tokens[0].type == .plus)
        #expect(tokens[1].type == .minus)
        #expect(tokens[2].type == .multiply)
        #expect(tokens[3].type == .divide)
        #expect(tokens[4].type == .eof)
    }
    
    @Test("Lexer tokenizes comparison operators")
    func testComparisonOperators() {
        let lexer = Lexer(input: ">= > <= <")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 5) // >=, >, <=, <, eof
        #expect(tokens[0].type == .greaterThanOrEqual)
        #expect(tokens[0].value == ">=")
        #expect(tokens[1].type == .greaterThan)
        #expect(tokens[1].value == ">")
        #expect(tokens[2].type == .lessThanOrEqual)
        #expect(tokens[2].value == "<=")
        #expect(tokens[3].type == .lessThan)
        #expect(tokens[3].value == "<")
        #expect(tokens[4].type == .eof)
    }
    
    @Test("Lexer tokenizes exploding dice")
    func testExplodingDice() {
        let lexer = Lexer(input: "d6! d10!!")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 7) // dice, number, explode, dice, number, compound_explode, eof
        #expect(tokens[0].type == .dice)
        #expect(tokens[1].type == .number)
        #expect(tokens[1].value == "6")
        #expect(tokens[2].type == .explode)
        #expect(tokens[2].value == "!")
        #expect(tokens[3].type == .dice)
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "10")
        #expect(tokens[5].type == .compoundExplode)
        #expect(tokens[5].value == "!!")
        #expect(tokens[6].type == .eof)
    }
    
    @Test("Lexer tokenizes keep/drop modifiers")
    func testKeepDropModifiers() {
        let lexer = Lexer(input: "kh kl dh dl")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 5) // kh, kl, dh, dl, eof
        #expect(tokens[0].type == .keepHighest)
        #expect(tokens[0].value == "kh")
        #expect(tokens[1].type == .keepLowest)
        #expect(tokens[1].value == "kl")
        #expect(tokens[2].type == .dropHighest)
        #expect(tokens[2].value == "dh")
        #expect(tokens[3].type == .dropLowest)
        #expect(tokens[3].value == "dl")
        #expect(tokens[4].type == .eof)
    }
    
    @Test("Lexer tokenizes long form keep/drop")
    func testLongFormKeepDrop() {
        let lexer = Lexer(input: "keep highest drop lowest")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 5) // keep, highest, drop, lowest, eof
        #expect(tokens[0].type == .keep)
        #expect(tokens[0].value == "keep")
        #expect(tokens[1].type == .highest)
        #expect(tokens[1].value == "highest")
        #expect(tokens[2].type == .drop)
        #expect(tokens[2].value == "drop")
        #expect(tokens[3].type == .lowest)
        #expect(tokens[3].value == "lowest")
        #expect(tokens[4].type == .eof)
    }
    
    @Test("Lexer tokenizes grouping symbols")
    func testGroupingSymbols() {
        let lexer = Lexer(input: "()[],:@%")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 9) // (, ), [, ], ,, :, @, %, eof
        #expect(tokens[0].type == .leftParen)
        #expect(tokens[1].type == .rightParen)
        #expect(tokens[2].type == .leftBracket)
        #expect(tokens[3].type == .rightBracket)
        #expect(tokens[4].type == .comma)
        #expect(tokens[5].type == .colon)
        #expect(tokens[6].type == .at)
        #expect(tokens[7].type == .percent)
        #expect(tokens[8].type == .eof)
    }
    
    @Test("Lexer tokenizes arrows")
    func testArrows() {
        let lexer = Lexer(input: "-> =>")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 3) // arrow, arrow, eof
        #expect(tokens[0].type == .arrow)
        #expect(tokens[0].value == "->")
        #expect(tokens[1].type == .arrow)
        #expect(tokens[1].value == "=>")
        #expect(tokens[2].type == .eof)
    }
    
    @Test("Lexer tokenizes tagged dice expression")
    func testTaggedDiceExpression() {
        let lexer = Lexer(input: "[hope: d12, fear: d12]")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 12) // [, hope, :, d, 12, ,, fear, :, d, 12, ], eof
        #expect(tokens[0].type == .leftBracket)
        #expect(tokens[1].type == .identifier)
        #expect(tokens[1].value == "hope")
        #expect(tokens[2].type == .colon)
        #expect(tokens[3].type == .dice)
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "12")
        #expect(tokens[5].type == .comma)
        #expect(tokens[6].type == .identifier)
        #expect(tokens[6].value == "fear")
        #expect(tokens[7].type == .colon)
        #expect(tokens[8].type == .dice)
        #expect(tokens[9].type == .number)
        #expect(tokens[9].value == "12")
        #expect(tokens[10].type == .rightBracket)
        #expect(tokens[11].type == .eof)
    }
    
    @Test("Lexer tokenizes outcome keywords")
    func testOutcomeKeywords() {
        let lexer = Lexer(input: "higher_tag determines outcome")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 4) // higher_tag, determines, outcome, eof
        #expect(tokens[0].type == .higherTag)
        #expect(tokens[0].value == "higher_tag")
        #expect(tokens[1].type == .determines)
        #expect(tokens[1].value == "determines")
        #expect(tokens[2].type == .outcome)
        #expect(tokens[2].value == "outcome")
        #expect(tokens[3].type == .eof)
    }
    
    @Test("Lexer handles whitespace correctly")
    func testWhitespaceHandling() {
        let lexer = Lexer(input: "  2  d6  +  3  ")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 6) // number, dice, number, plus, number, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "2")
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .plus)
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "3")
        #expect(tokens[5].type == .eof)
    }
    
    @Test("Lexer handles newlines correctly")
    func testNewlineHandling() {
        let lexer = Lexer(input: "2d6\n+3")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 7) // number, dice, number, newline, plus, number, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[3].type == .newline)
        #expect(tokens[4].type == .plus)
        #expect(tokens[5].type == .number)
        #expect(tokens[6].type == .eof)
    }
    
    @Test("Lexer tracks line and column positions")
    func testLineAndColumnTracking() {
        let lexer = Lexer(input: "2d6\n+3")
        let tokens = lexer.tokenize()
        
        // Check first line tokens
        #expect(tokens[0].line == 1)
        #expect(tokens[0].column == 1)
        #expect(tokens[1].line == 1)
        #expect(tokens[1].column == 2)
        #expect(tokens[2].line == 1)
        #expect(tokens[2].column == 3)
        
        // Check newline token
        #expect(tokens[3].line == 1)
        #expect(tokens[3].column == 4)
        
        // Check second line tokens
        #expect(tokens[4].line == 2)
        #expect(tokens[4].column == 1)
        #expect(tokens[5].line == 2)
        #expect(tokens[5].column == 2)
    }
    
    @Test("Lexer handles complex dice expression with spaces")
    func testComplexDiceExpressionWithSpaces() {
        let lexer = Lexer(input: "4d6 kh 3+2*3")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 10) // 4, d, 6, kh, 3, +, 2, *, 3, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "4")
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .keepHighest)
        #expect(tokens[3].value == "kh")
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "3")
        #expect(tokens[5].type == .plus)
        #expect(tokens[6].type == .number)
        #expect(tokens[6].value == "2")
        #expect(tokens[7].type == .multiply)
        #expect(tokens[8].type == .number)
        #expect(tokens[8].value == "3")
        #expect(tokens[9].type == .eof)
    }
    
    @Test("Lexer handles complex dice expression without spaces")
    func testComplexDiceExpressionWithoutSpaces() {
        let lexer = Lexer(input: "4d6kh3+2*3")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 10) // 4, d, 6, kh, 3, +, 2, *, 3, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "4")
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .keepHighest) // "kh" is now properly separated
        #expect(tokens[3].value == "kh")
        #expect(tokens[4].type == .number) // "3" is now a separate token
        #expect(tokens[4].value == "3")
        #expect(tokens[5].type == .plus)
        #expect(tokens[6].type == .number)
        #expect(tokens[6].value == "2")
        #expect(tokens[7].type == .multiply)
        #expect(tokens[8].type == .number)
        #expect(tokens[8].value == "3")
        #expect(tokens[9].type == .eof)
    }
    
    @Test("Lexer handles dice pool expression")
    func testDicePoolExpression() {
        let lexer = Lexer(input: "10d6 >= 5")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 6) // 10, d, 6, >=, 5, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[0].value == "10")
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[2].value == "6")
        #expect(tokens[3].type == .greaterThanOrEqual)
        #expect(tokens[3].value == ">=")
        #expect(tokens[4].type == .number)
        #expect(tokens[4].value == "5")
        #expect(tokens[5].type == .eof)
    }
    
    @Test("Lexer handles unknown characters")
    func testUnknownCharacters() {
        let lexer = Lexer(input: "2d6&3")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 6) // 2, d, 6, unknown(&), 3, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[1].type == .dice)
        #expect(tokens[2].type == .number)
        #expect(tokens[3].type == .unknown)
        #expect(tokens[3].value == "&")
        #expect(tokens[4].type == .number)
        #expect(tokens[5].type == .eof)
    }
    
    @Test("Lexer handles uppercase dice notation")
    func testUppercaseDiceNotation() {
        let lexer = Lexer(input: "2D6")
        let tokens = lexer.tokenize()
        
        #expect(tokens.count == 4) // 2, D, 6, eof
        #expect(tokens[0].type == .number)
        #expect(tokens[1].type == .dice)
        #expect(tokens[1].value == "D")
        #expect(tokens[2].type == .number)
        #expect(tokens[3].type == .eof)
    }
}