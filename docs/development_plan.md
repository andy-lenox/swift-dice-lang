# DiceLang Parser Development Plan

## Phase 1: Core Foundation (Week 1-2)

### 1.1 Token System & Lexer
- **Token.swift**: Define token types (NUMBER, DICE, OPERATOR, IDENTIFIER, etc.)
- **Lexer.swift**: Tokenize input strings into token sequences
- **Tests**: Lexer unit tests for all token types

### 1.2 Basic Data Structures
- **DiceRoll.swift**: Core dice roll representation
- **DiceResult.swift**: Result structures with detailed breakdowns
- **DiceExpression.swift**: AST node protocols and base classes

### 1.3 Random Number Generation
- **RandomNumberGenerator.swift**: Abstracted RNG for testability
- **DiceRoller.swift**: Core dice rolling logic with exploding dice support

## Phase 2: Basic Parser & Core Features (Week 3-4)

### 2.1 Recursive Descent Parser
- **Parser.swift**: Main parser class with recursive descent implementation
- **ExpressionParser.swift**: Handle arithmetic expressions with precedence
- **DiceParser.swift**: Parse basic dice notation (XdY)

### 2.2 Core Dice Features
- Standard dice rolls (`2d6`, `d20`)
- Arithmetic modifiers (`2d6+3`, `(2d6+3)*2`)
- Exploding dice (`d6!`, `d10!!`)
- Parentheses grouping

### 2.3 Testing & Validation
- Comprehensive test suite for basic features
- Error handling for invalid expressions
- Performance benchmarks

## Phase 3: Advanced Dice Mechanics (Week 5-6)

### 3.1 Keep/Drop System
- **KeepDropModifier.swift**: Handle kh/kl/dh/dl syntax
- Long form parsing (`keep highest 3`)
- Integration with existing dice rolls

### 3.2 Dice Pools
- **DicePool.swift**: Threshold-based success counting
- Support for all comparison operators (`>=`, `>`, `<=`, `<`)
- Pool-specific result formatting

### 3.3 Complex Expressions
- Nested expressions with multiple modifiers
- Order of operations validation
- Edge case handling

## Phase 4: Tagged Dice & Outcome Logic (Week 7-8)

### 4.1 Tagged Dice System
- **TaggedDice.swift**: Named dice roll containers
- **TaggedGroup.swift**: Handle grouped tagged rolls
- **OutcomeEvaluator.swift**: Implement outcome rules

### 4.2 Outcome Rules Engine
- `higher_tag determines outcome` logic
- Extensible framework for custom rules
- JSON output formatting matching spec

### 4.3 Advanced Features
- Multiple tag support in single expression
- Complex outcome determination logic
- Integration with existing dice mechanics

## Phase 5: Random Tables System (Week 9-10)

### 5.1 Table Definition & Storage
- **RandomTable.swift**: Table definition and storage
- **TableEntry.swift**: Individual table entries with weights
- **TableManager.swift**: Table registration and lookup

### 5.2 Table Parsing & Evaluation
- Weight range parsing (`1-2`, `50%`)
- Nested table references (`→ @sub_table`)
- Embedded dice rolls in results

### 5.3 Table Integration
- `@table_name` syntax parsing
- Result substitution and evaluation
- Recursive table resolution

## Phase 6: Integration & Polish (Week 11-12)

### 6.1 Complete Parser Integration
- **DiceLangParser.swift**: Main public API
- Integration of all subsystems
- Comprehensive error handling

### 6.2 Output System
- **ResultFormatter.swift**: JSON output formatting
- Detailed roll breakdowns
- Structured result objects matching spec

### 6.3 Testing & Documentation
- Complete test coverage
- Performance optimization
- DocC documentation updates
- Example usage patterns

## Technical Architecture

### Core Components:
1. **Lexer**: String → Token stream
2. **Parser**: Tokens → AST
3. **Evaluator**: AST → Results
4. **Formatter**: Results → JSON

### Key Design Patterns:
- **Recursive Descent Parser** for grammar parsing
- **Visitor Pattern** for AST evaluation
- **Strategy Pattern** for different dice mechanics
- **Factory Pattern** for creating dice expressions

### Error Handling Strategy:
- Detailed parse error messages with position info
- Graceful degradation for partial parsing
- Type-safe result types with error cases

### Testing Strategy:
- Unit tests for each component
- Integration tests for complete expressions
- Property-based testing for dice mechanics
- Performance benchmarks for complex expressions

## Implementation Order

### Phase 1 Tasks:
1. Create `Token.swift` with all token types
2. Implement `Lexer.swift` for string tokenization
3. Create `DiceRoll.swift` and `DiceResult.swift` data structures
4. Implement `RandomNumberGenerator.swift` abstraction
5. Create `DiceRoller.swift` with basic and exploding dice logic
6. Write comprehensive unit tests

### Phase 2 Tasks:
1. Implement `Parser.swift` with recursive descent parsing
2. Create `ExpressionParser.swift` for arithmetic expressions
3. Implement `DiceParser.swift` for basic dice notation
4. Add support for standard dice rolls and modifiers
5. Implement parentheses grouping
6. Add error handling and validation

### Phase 3 Tasks:
1. Create `KeepDropModifier.swift` for keep/drop mechanics
2. Implement `DicePool.swift` for threshold-based pools
3. Add support for all comparison operators
4. Integrate advanced mechanics with existing parser
5. Add comprehensive testing for edge cases

### Phase 4 Tasks:
1. Create `TaggedDice.swift` and `TaggedGroup.swift`
2. Implement `OutcomeEvaluator.swift` for outcome rules
3. Add support for `higher_tag determines outcome`
4. Implement JSON output formatting
5. Add extensibility for custom outcome rules

### Phase 5 Tasks:
1. Create `RandomTable.swift` and `TableEntry.swift`
2. Implement `TableManager.swift` for table management
3. Add parsing for weight ranges and percentages
4. Implement nested table references
5. Add support for embedded dice rolls in results

### Phase 6 Tasks:
1. Create `DiceLangParser.swift` main API
2. Implement `ResultFormatter.swift` for JSON output
3. Add comprehensive error handling
4. Optimize performance
5. Complete documentation and examples

This plan provides a systematic approach to implementing the complete DiceLang specification while maintaining code quality and testability throughout the development process.