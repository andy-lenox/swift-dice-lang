# Changelog

All notable changes to DiceLang will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Swift Package Manager support
- Comprehensive test suite with 100+ test cases
- Open source release preparation

## [1.0.0] - 2025-01-XX

### Added
- **Core Dice Operations**
  - Standard dice notation (`2d6`, `1d20`, `3d8+2`)
  - Arithmetic operations with full precedence support
  - Parentheses grouping for complex expressions

- **Advanced Dice Mechanics**
  - Exploding dice (`d6!`, `d10!!`) with configurable explosion conditions
  - Keep/drop modifiers (`4d6kh3`, `6d6dl2`) with both short and long form syntax
  - Dice pools (`10d6>=5`) with all comparison operators (`>=`, `>`, `<=`, `<`, `==`, `!=`)

- **Tagged Dice System**
  - Named dice groups (`[hope: d12, fear: d12]`)
  - Outcome evaluation logic (`higher_tag determines outcome`)
  - Complex narrative game support

- **Random Tables System**
  - Range-based table entries (`1-3: Sword`, `4-6: Bow`)
  - Percentage-based entries (`50%: Common`, `30%: Rare`)
  - Nested table references (`→ @sub_table`)
  - Embedded dice rolls in table results (`"Find 1d6 gold pieces"`)
  - Table expressions in dice notation (`@treasure_table`)

- **Comprehensive API**
  - `DiceLangParser` main interface with convenience methods
  - `ResultFormatter` for JSON output and human-readable summaries
  - `ErrorHandler` with detailed error reporting and recovery suggestions
  - `TableManager` for table registration and management

- **Error Handling**
  - 17 specific error types with detailed messages
  - User-friendly error descriptions
  - Correction suggestions for common mistakes
  - Comprehensive validation utilities

- **Output Formats**
  - Structured JSON output for all result types
  - Human-readable summary formatting
  - Detailed breakdown information
  - Extension methods for easy conversion

- **Testing Framework**
  - 100+ comprehensive test cases
  - Deterministic testing with `FixedRandomNumberGenerator`
  - Performance benchmarks
  - Error scenario coverage

### Technical Details
- **Architecture**: Clean separation with Lexer → Parser → Evaluator → Formatter
- **Performance**: Optimized recursive descent parser with efficient evaluation
- **Platforms**: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+
- **Dependencies**: Zero external dependencies
- **Swift Version**: 5.9+

### Documentation
- Complete README with usage examples
- Contributing guidelines for open source development
- Formal grammar specification
- Comprehensive API documentation

---

## Development History

This changelog represents the initial open source release of DiceLang. The framework was developed through six phases:

1. **Phase 1**: Core Foundation (Token system, Lexer, Basic structures)
2. **Phase 2**: Basic Parser & Core Features (Recursive descent parser, Standard dice)
3. **Phase 3**: Advanced Dice Mechanics (Keep/drop, Dice pools, Complex expressions)
4. **Phase 4**: Tagged Dice & Outcome Logic (Named groups, Outcome evaluation)
5. **Phase 5**: Random Tables System (Table definition, Nested references, Embedded dice)
6. **Phase 6**: Integration & Polish (Public API, JSON formatting, Error handling)

Each phase included comprehensive testing and validation to ensure reliability and maintainability.

## Future Roadmap

Planned features for future releases:

- **v1.1**: Fate/Fudge dice support (`4dF`, `3dF+2`)
- **v1.2**: Advanced table features (weighted percentages, conditional entries)
- **v1.3**: Custom dice types and mechanics
- **v1.4**: Command-line tools and REPL interface
- **v1.5**: Performance optimizations and memory improvements
- **v2.0**: Plugin architecture for custom mechanics

## Migration Guides

For future releases, this section will contain migration guides for breaking changes.

## Support

- **Issues**: Report bugs and request features on GitHub
- **Discussions**: Community support and questions
- **Documentation**: Comprehensive guides and API reference
- **Examples**: Real-world usage patterns and tutorials

---

*DiceLang is developed with ❤️ for the tabletop gaming community.*