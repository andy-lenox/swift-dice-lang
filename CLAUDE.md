# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DiceLang is a Swift framework for parsing and evaluating dice-rolling expressions for tabletop RPGs and narrative systems. It implements a custom domain-specific language (DSL) that supports:

- Standard dice rolls (`2d6+3`)
- Dice pools with thresholds (`10d6 >= 5`) 
- Keep/Drop modifiers (`4d6kh3`)
- Exploding dice (`d6!`)
- Tagged dice for outcome evaluation (`[hope: d12, fear: d12]`)
- Random tables with weights and nesting

## Development Commands

### Building
```bash
# Build the framework
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -configuration Debug build

# Build for release
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -configuration Release build
```

### Testing
```bash
# Run all tests
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -destination 'platform=iOS Simulator,name=iPhone 15' test

# Run tests with verbose output
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -destination 'platform=iOS Simulator,name=iPhone 15' test -verbose
```

### Project Structure
- `DiceLang/` - Main framework source code
  - `DiceLang.swift` - Main entry point (currently empty)
  - `DiceLang.docc/` - Documentation bundle
- `DiceLangTests/` - Test suite using Swift Testing framework
- `docs/` - Language specification and documentation
  - `dice_language_grammar_spec.md` - Complete grammar specification

## Architecture Notes

This is an iOS framework project (targets iOS 18.4+) built with Xcode 16.3 and Swift 5.0. The project uses:

- Swift Testing framework for unit tests (not XCTest)
- DocC for documentation generation
- Standard iOS framework structure with automatic code signing

The language grammar supports complex dice expressions including arithmetic operations, exploding dice, dice pools, keep/drop mechanics, tagged dice groups, and random table lookups. Refer to `docs/dice_language_grammar_spec.md` for the complete formal grammar specification.

## Key Implementation Areas

Based on the grammar specification, the main components to implement include:

1. **Lexer/Tokenizer** - Parse dice notation syntax
2. **Parser** - Build AST from tokens following EBNF grammar
3. **Evaluator** - Execute dice rolls and return structured results
4. **Random Tables** - Support weighted table lookups with nesting
5. **Tagged Dice Groups** - Handle complex outcome evaluation logic

The expected output format is JSON with detailed breakdowns of roll results, supporting both simple dice rolls and complex tagged group evaluations.

## Development Rules

### Test-Driven Development Requirements

**MANDATORY: Every unit of code MUST have comprehensive unit tests.**

1. **Write Tests First**: Before implementing any new functionality, create failing tests that define the expected behavior
2. **Test Coverage**: Every public method, computed property, and critical private method must have unit tests
3. **Test Every Change**: After any code modification, ALL tests must be run to ensure no regressions
4. **Test Failure Policy**: If any test fails, stop development and fix the issue before proceeding

### Testing Commands (MUST run after every change)
```bash
# Run all tests with verbose output - REQUIRED after every code change
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -destination 'platform=iOS Simulator,id=E7B9A71C-E033-4A4F-BFD5-25C607BF53D0' test -verbose

# Quick test run for development
xcodebuild -project DiceLang.xcodeproj -scheme DiceLang -destination 'platform=iOS Simulator,id=E7B9A71C-E033-4A4F-BFD5-25C607BF53D0' test

# NOTE: The scheme may need to be configured for testing. If tests fail to run due to scheme configuration:
# 1. Open the project in Xcode
# 2. Edit the scheme to include the test target
# 3. Or create a shared scheme that includes both build and test actions
```

### Testing Standards

1. **Unit Test Structure**: Use Swift Testing framework with clear test names describing the behavior being tested
2. **Test Organization**: Group related tests in nested test suites
3. **Test Data**: Use both fixed test data and property-based testing for dice mechanics
4. **Mock Objects**: Use dependency injection and mock objects for testing components in isolation
5. **Error Testing**: Test both success and failure cases, including edge cases and invalid inputs

### Implementation Workflow

1. **Red**: Write failing test that defines expected behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests passing
4. **Test**: Run full test suite to ensure no regressions
5. **Repeat**: Continue with next feature/change

### Test Categories Required

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Property-Based Tests**: Test dice mechanics with random inputs
- **Error Handling Tests**: Test invalid inputs and edge cases
- **Performance Tests**: Benchmark critical parsing operations