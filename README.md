# DiceLang

A powerful Swift framework for parsing and evaluating dice-rolling expressions for tabletop RPGs and narrative systems.

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

DiceLang implements a comprehensive domain-specific language (DSL) for dice expressions, supporting:

### Core Dice Operations
- **Standard dice rolls**: `2d6`, `1d20`, `3d8+2`
- **Arithmetic operations**: `(2d6+3)*2`, `1d20+5-2`
- **Exploding dice**: `d6!` (explode on max), `d10!!` (compound exploding)

### Advanced Mechanics
- **Keep/Drop modifiers**: `4d6kh3` (keep highest 3), `6d6dl2` (drop lowest 2)
- **Dice pools**: `10d6>=5` (count successes), `8d10>7` (threshold pools)
- **Comparison operators**: `>=`, `>`, `<=`, `<`, `==`, `!=`
- **Named variables**: `damage = 2d6+4` with lazy evaluation and reuse

### Tagged Dice & Outcomes
- **Tagged dice groups**: `[hope: d12, fear: d12]`
- **Outcome evaluation**: `higher_tag determines outcome`
- **Complex narrative logic**: Perfect for story games and narrative systems

### Random Tables
- **Weighted tables**: Range-based (`1-3: Sword`, `4-6: Bow`) and percentage-based (`50%: Common`, `30%: Rare`)
- **Nested references**: `→ @sub_table` for hierarchical tables
- **Embedded dice**: `"Find 1d6 gold pieces"` with automatic evaluation
- **Table expressions**: `@treasure_table` in dice expressions

## Installation

### Swift Package Manager

Add DiceLang to your project using Xcode's Swift Package Manager:

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `[https://github.com/yourusername/DiceLang](https://github.com/andy-lenox/swift-dice-lang/)`
3. Select the version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/andy-lenox/swift-dice-lang", from: "1.0.0")
]
```

## Quick Start

```swift
import DiceLang

// Create a parser instance
let parser = DiceLangParser()

// Basic dice rolling
let result = try parser.evaluate("2d6+3")
print("Rolled: \(result.total)") // e.g., "Rolled: 11"

// Get detailed breakdown
print("Breakdown: \(result.breakdown.originalRolls)") // e.g., "[4, 5]"

// Advanced mechanics
let poolResult = try parser.evaluate("6d6>=4")
print("Successes: \(poolResult.breakdown.successCount ?? 0)")

let keepHighest = try parser.evaluate("4d6kh3")
print("Kept rolls: \(keepHighest.breakdown.keptRolls ?? [])")

// Named variables with persistent context
let context = EvaluationContext(variableContext: VariableContext())
let damageDecl = try parser.parse("damage = 2d6+4")
let damageResult = try damageDecl.evaluate(with: context)
print("Damage roll: \(damageResult.total)") // e.g., "Damage roll: 12"

// Reuse variables in complex expressions
let totalDamage = try parser.parse("damage + damage")
let totalResult = try totalDamage.evaluate(with: context)
print("Total damage: \(totalResult.total)") // Each reference re-evaluates
```

## Advanced Usage

### Random Tables

```swift
// Register a random table
let tableDefinition = """
@treasure
1-2: 1d6 gold pieces
3-4: A healing potion
5: A magic sword
6: Ancient artifact → @artifact_table
"""

try parser.registerTable(tableDefinition)

// Use in expressions
let treasure = try parser.evaluateTable(named: "treasure")
print("Found: \(treasure.finalResult)")

// Table expressions
let result = try parser.evaluate("@treasure")
```

### Named Variables for Complex Calculations

```swift
// Create persistent context for variables
let context = EvaluationContext(variableContext: VariableContext())

// Declare variables for character stats
let strengthDecl = try parser.parse("strength = 16")
_ = try strengthDecl.evaluate(with: context)

let modifierDecl = try parser.parse("str_mod = (strength - 10) / 2")
let modResult = try modifierDecl.evaluate(with: context)
print("Strength modifier: \(modResult.total)") // "Strength modifier: 3"

// Use variables in complex expressions
let attackDecl = try parser.parse("attack_roll = d20 + str_mod")
let attackResult = try attackDecl.evaluate(with: context)
print("Attack roll: \(attackResult.total)") // e.g., "Attack roll: 18"

// Variables with dice mechanics
let advantageDecl = try parser.parse("advantage = 2d20kh1 + str_mod")
_ = try advantageDecl.evaluate(with: context)

// Lazy evaluation - each reference re-rolls
let damageDecl = try parser.parse("damage = 2d6 + str_mod")
let firstDamage = try damageDecl.evaluate(with: context)
let secondDamage = try parser.parse("damage").evaluate(with: context)
// firstDamage and secondDamage will likely be different due to re-rolling
```

### Tagged Dice for Narrative Games

```swift
// Perfect for games like Apocalypse World, Blades in the Dark, etc.
let expression = "[action: 2d6, stress: 1d6] higher_tag determines outcome"
let result = try parser.evaluate(expression)

if let outcome = result.outcome {
    print("Outcome determined by: \(outcome)")
}
```

### JSON Output

```swift
let result = try parser.evaluate("4d6kh3+2")
let jsonData = try result.toJSON()
let jsonString = try result.toJSONString()

// Structured output perfect for APIs and data storage
print(jsonString)
```

### Batch Operations

```swift
// Evaluate multiple expressions
let expressions = ["1d20+5", "2d6", "1d4+1"]
let results = try parser.evaluateAll(expressions)

// Validate expressions
let isValid = parser.isValid("2d6+3")
let parseError = parser.getParseError(for: "invalid expression")
```

## Language Grammar

DiceLang supports a rich expression grammar:

```
// Basic dice notation
1d6, 2d20, 100d100

// Arithmetic
2d6+3, (1d8+2)*3, 1d20+5-2

// Named variables
damage = 2d6+4
strength_mod = (strength - 10) / 2
attack_roll = d20 + strength_mod

// Exploding dice
1d6!, 1d10!!, 3d6!

// Keep/drop modifiers
4d6kh3, 6d6kl4, 4d6dh1, 4d6dl1
4d6 keep highest 3, 6d6 drop lowest 2

// Dice pools
10d6>=5, 8d10>7, 5d6<3, 12d6==6

// Tagged dice
[hope: d12, fear: d12]
[action: 2d6, effect: 1d6, stress: 1d3]

// Table references
@treasure_table, @encounters, @random_events
```

## Error Handling

DiceLang provides comprehensive error handling with detailed messages:

```swift
do {
    let result = try parser.evaluate("2d6+")
} catch let error as ParseError {
    print("Parse error: \(error.localizedDescription)")
    
    // Get user-friendly error message
    let friendlyError = ErrorHandler.createUserFriendlyError(error)
    print("Friendly error: \(friendlyError)")
    
    // Get correction suggestions
    if let suggestion = ErrorHandler.suggestCorrection(for: "2d6+", error: error) {
        print("Suggestion: \(suggestion)")
    }
}
```

## Architecture

- **Lexer**: Tokenizes input strings into structured tokens
- **Parser**: Builds Abstract Syntax Trees (AST) using recursive descent parsing
- **Evaluator**: Executes AST nodes with visitor pattern
- **Formatter**: Converts results to JSON and other formats
- **Error Handler**: Provides detailed error reporting and recovery

The framework is designed for:
- **Performance**: Efficient parsing and evaluation
- **Extensibility**: Easy to add new dice mechanics
- **Testability**: Comprehensive test suite with deterministic results
- **Type Safety**: Full Swift type system integration

## Use Cases

DiceLang is perfect for:

- **Digital tabletop RPG apps** (D&D, Pathfinder, etc.) - Complex character calculations with variables
- **Narrative game systems** (Apocalypse World, Blades in the Dark) - Tagged dice outcomes
- **Board game companions** - Quick dice rolling with custom mechanics
- **Game master tools** - Random tables and complex encounter generation
- **Discord/Slack bots** - Named variables for persistent character stats
- **Educational dice probability tools** - Teaching statistics with real dice mechanics
- **Game design prototyping** - Testing new dice mechanics and balance

## Documentation

- [Language Grammar Specification](docs/dice_language_grammar_spec.md)
- [API Documentation](https://yourusername.github.io/DiceLang/)
- [Examples and Tutorials](docs/examples/)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code style and conventions
- Testing requirements
- Submitting pull requests
- Reporting issues

### Development Setup

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Run tests: `swift test`
4. Build: `swift build`

## Performance

DiceLang is optimized for performance:

- **Fast parsing**: Efficient recursive descent parser
- **Memory efficient**: Minimal allocations during evaluation
- **Scalable**: Handles complex expressions with hundreds of dice
- **Deterministic**: Consistent performance characteristics

Benchmarks on modern hardware:
- Simple expressions (`2d6+3`): ~0.1ms
- Complex expressions (`(4d6kh3+2)*3`): ~0.5ms
- Large pools (`100d6>=4`): ~2ms

## License

DiceLang is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the rich tradition of tabletop RPGs and the need for robust dice expression parsing in digital gaming tools
- Built with assistance from [Claude](https://claude.ai) for architecture design, implementation, and testing

## Development

DiceLang was developed through a collaborative process using modern AI-assisted development practices. The framework architecture, comprehensive test suite, and documentation were created with the assistance of Claude AI to ensure high code quality and maintainability.

---

*Made with ❤️ for the tabletop gaming community*
