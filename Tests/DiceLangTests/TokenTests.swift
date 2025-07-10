import Testing
@testable import DiceLang

struct TokenTests {
    
    @Test("Token creation with basic properties")
    func testTokenCreation() {
        let token = Token(type: .number, value: "42", position: 0, line: 1, column: 1)
        
        #expect(token.type == .number)
        #expect(token.value == "42")
        #expect(token.position == 0)
        #expect(token.line == 1)
        #expect(token.column == 1)
    }
    
    @Test("Token creation with default line and column")
    func testTokenCreationWithDefaults() {
        let token = Token(type: .dice, value: "d", position: 5)
        
        #expect(token.type == .dice)
        #expect(token.value == "d")
        #expect(token.position == 5)
        #expect(token.line == 1)
        #expect(token.column == 1)
    }
    
    @Test("Token equality comparison")
    func testTokenEquality() {
        let token1 = Token(type: .number, value: "42", position: 0, line: 1, column: 1)
        let token2 = Token(type: .number, value: "42", position: 0, line: 1, column: 1)
        let token3 = Token(type: .number, value: "43", position: 0, line: 1, column: 1)
        
        #expect(token1 == token2)
        #expect(token1 != token3)
    }
    
    @Test("Token string representation")
    func testTokenDescription() {
        let token = Token(type: .number, value: "42", position: 0, line: 2, column: 5)
        let description = token.description
        
        #expect(description == "Token(NUMBER, \"42\", 2:5)")
    }
    
    @Test("Token debug description")
    func testTokenDebugDescription() {
        let token = Token(type: .dice, value: "d", position: 1, line: 1, column: 2)
        let debugDescription = token.debugDescription
        
        #expect(debugDescription == "Token(DICE, \"d\", 1:2)")
    }
    
    @Test("All token types have string representations")
    func testAllTokenTypesHaveStringRepresentations() {
        for tokenType in TokenType.allCases {
            let token = Token(type: tokenType, value: "test", position: 0)
            let description = token.description
            
            #expect(description.contains(tokenType.rawValue))
        }
    }
    
    @Test("Token types for basic dice operations")
    func testBasicDiceTokenTypes() {
        let numberToken = Token(type: .number, value: "2", position: 0)
        let diceToken = Token(type: .dice, value: "d", position: 1)
        let sidesToken = Token(type: .number, value: "6", position: 2)
        
        #expect(numberToken.type == .number)
        #expect(diceToken.type == .dice)
        #expect(sidesToken.type == .number)
    }
    
    @Test("Token types for arithmetic operators")
    func testArithmeticOperatorTokenTypes() {
        let plusToken = Token(type: .plus, value: "+", position: 0)
        let minusToken = Token(type: .minus, value: "-", position: 1)
        let multiplyToken = Token(type: .multiply, value: "*", position: 2)
        let divideToken = Token(type: .divide, value: "/", position: 3)
        
        #expect(plusToken.type == .plus)
        #expect(minusToken.type == .minus)
        #expect(multiplyToken.type == .multiply)
        #expect(divideToken.type == .divide)
    }
    
    @Test("Token types for comparison operators")
    func testComparisonOperatorTokenTypes() {
        let gtToken = Token(type: .greaterThan, value: ">", position: 0)
        let gteToken = Token(type: .greaterThanOrEqual, value: ">=", position: 1)
        let ltToken = Token(type: .lessThan, value: "<", position: 2)
        let lteToken = Token(type: .lessThanOrEqual, value: "<=", position: 3)
        
        #expect(gtToken.type == .greaterThan)
        #expect(gteToken.type == .greaterThanOrEqual)
        #expect(ltToken.type == .lessThan)
        #expect(lteToken.type == .lessThanOrEqual)
    }
    
    @Test("Token types for exploding dice")
    func testExplodingDiceTokenTypes() {
        let explodeToken = Token(type: .explode, value: "!", position: 0)
        let compoundExplodeToken = Token(type: .compoundExplode, value: "!!", position: 1)
        
        #expect(explodeToken.type == .explode)
        #expect(compoundExplodeToken.type == .compoundExplode)
    }
    
    @Test("Token types for keep/drop modifiers")
    func testKeepDropModifierTokenTypes() {
        let keepHighestToken = Token(type: .keepHighest, value: "kh", position: 0)
        let keepLowestToken = Token(type: .keepLowest, value: "kl", position: 1)
        let dropHighestToken = Token(type: .dropHighest, value: "dh", position: 2)
        let dropLowestToken = Token(type: .dropLowest, value: "dl", position: 3)
        
        #expect(keepHighestToken.type == .keepHighest)
        #expect(keepLowestToken.type == .keepLowest)
        #expect(dropHighestToken.type == .dropHighest)
        #expect(dropLowestToken.type == .dropLowest)
    }
    
    @Test("Token types for grouping symbols")
    func testGroupingSymbolTokenTypes() {
        let leftParenToken = Token(type: .leftParen, value: "(", position: 0)
        let rightParenToken = Token(type: .rightParen, value: ")", position: 1)
        let leftBracketToken = Token(type: .leftBracket, value: "[", position: 2)
        let rightBracketToken = Token(type: .rightBracket, value: "]", position: 3)
        let commaToken = Token(type: .comma, value: ",", position: 4)
        let colonToken = Token(type: .colon, value: ":", position: 5)
        
        #expect(leftParenToken.type == .leftParen)
        #expect(rightParenToken.type == .rightParen)
        #expect(leftBracketToken.type == .leftBracket)
        #expect(rightBracketToken.type == .rightBracket)
        #expect(commaToken.type == .comma)
        #expect(colonToken.type == .colon)
    }
    
    @Test("Token types for special tokens")
    func testSpecialTokenTypes() {
        let eofToken = Token(type: .eof, value: "", position: 0)
        let newlineToken = Token(type: .newline, value: "\n", position: 1)
        let whitespaceToken = Token(type: .whitespace, value: " ", position: 2)
        let unknownToken = Token(type: .unknown, value: "?", position: 3)
        
        #expect(eofToken.type == .eof)
        #expect(newlineToken.type == .newline)
        #expect(whitespaceToken.type == .whitespace)
        #expect(unknownToken.type == .unknown)
    }
}