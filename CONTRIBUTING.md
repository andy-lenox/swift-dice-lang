# Contributing to DiceLang

Thank you for your interest in contributing to DiceLang! We welcome contributions from the community to help make this dice expression parser even better.

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- Swift 5.9 or later
- Familiarity with tabletop RPGs and dice mechanics is helpful but not required

### Development Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/DiceLang.git
   cd DiceLang
   ```
3. Open `Package.swift` in Xcode or use command line tools
4. Run the tests to ensure everything works:
   ```bash
   swift test
   ```

## How to Contribute

### Reporting Issues

Before creating a new issue, please:

1. Search existing issues to avoid duplicates
2. Use our issue templates when available
3. Provide clear reproduction steps
4. Include relevant system information (OS, Swift version, etc.)

### Suggesting Features

We love feature suggestions! Please:

1. Check if the feature already exists or is planned
2. Describe the use case and benefits
3. Consider backward compatibility
4. Provide examples of the desired syntax/behavior

### Code Contributions

#### Pull Request Process

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our coding standards

3. Add tests for new functionality:
   - Unit tests for individual components
   - Integration tests for end-to-end functionality
   - Performance tests for optimization changes

4. Update documentation:
   - Code comments for complex logic
   - README.md for new features
   - Grammar specification for language changes

5. Ensure all tests pass:
   ```bash
   swift test
   ```

6. Commit with clear, descriptive messages:
   ```bash
   git commit -m "Add support for custom dice notation XdY+Z"
   ```

7. Push to your fork and create a pull request

#### Code Style Guidelines

**Swift Style:**
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Prefer explicit types when clarity is improved
- Use `// MARK:` comments to organize code sections

**Documentation:**
- Document all public APIs with Swift documentation comments
- Include usage examples for complex features
- Explain the "why" not just the "what" in comments

**Testing:**
- Follow the existing test patterns
- Use descriptive test names: `testKeepHighestModifierWithMultipleDice()`
- Test both success and failure cases
- Use `FixedRandomNumberGenerator` for deterministic tests

**Architecture:**
- Maintain separation of concerns
- Follow the existing patterns (Lexer → Parser → Evaluator)
- Prefer composition over inheritance
- Use protocols for extensibility

#### Testing Requirements

All contributions must include tests:

- **Unit Tests**: Test individual methods and classes in isolation
- **Integration Tests**: Test complete workflows
- **Error Tests**: Verify proper error handling
- **Performance Tests**: For changes affecting performance

**Test Organization:**
```swift
@Suite("Feature Name Tests")
struct FeatureNameTests {
    
    @Test("Specific behavior description")
    func testSpecificBehavior() throws {
        // Arrange
        let parser = DiceLangParser(randomNumberGenerator: FixedRandomNumberGenerator(values: [3, 4]))
        
        // Act
        let result = try parser.evaluate("2d6")
        
        // Assert
        #expect(result.total == 7)
    }
}
```

### Areas Needing Help

We especially welcome contributions in these areas:

1. **New Dice Mechanics**
   - Fate/Fudge dice support
   - Burning Wheel mechanics
   - Custom dice types

2. **Performance Improvements**
   - Parser optimizations
   - Memory usage reduction
   - Benchmark improvements

3. **Documentation**
   - API documentation
   - Usage examples
   - Tutorial content

4. **Platform Support**
   - Linux compatibility
   - Command-line tools
   - Server-side Swift integration

5. **Error Handling**
   - Better error messages
   - Recovery suggestions
   - Validation improvements

## Development Guidelines

### Test-Driven Development

We follow TDD practices:

1. **Red**: Write a failing test that describes the desired behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests passing

### Grammar Changes

Changes to the dice language grammar require:

1. Update `docs/dice_language_grammar_spec.md`
2. Add lexer tokens if needed
3. Implement parser logic
4. Add evaluator support
5. Comprehensive tests
6. Update examples and documentation

### Backward Compatibility

We strive to maintain backward compatibility:

- Existing expressions should continue to work
- New features should be additive when possible
- Breaking changes require major version bump
- Deprecation warnings for removed features

## Code Review Process

All contributions go through code review:

1. **Automated Checks**: CI runs tests and checks style
2. **Maintainer Review**: Core team reviews design and implementation
3. **Community Feedback**: Other contributors may provide input
4. **Approval**: At least one maintainer approval required

### Review Criteria

- **Correctness**: Does the code work as intended?
- **Test Coverage**: Are there sufficient tests?
- **Documentation**: Is the code well-documented?
- **Style**: Does it follow project conventions?
- **Performance**: Any negative performance impact?
- **API Design**: Is the API intuitive and consistent?

## Release Process

1. **Feature Freeze**: No new features for upcoming release
2. **Testing**: Comprehensive testing across platforms
3. **Documentation**: Update CHANGELOG and README
4. **Versioning**: Follow semantic versioning (MAJOR.MINOR.PATCH)
5. **Release**: Tag release and publish package

## Community

- **Discussions**: Use GitHub Discussions for questions and ideas
- **Issues**: GitHub Issues for bugs and feature requests
- **Code**: Pull Requests for contributions

### Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- Be respectful and considerate
- Focus on the technical merits
- Assume good intentions
- Ask questions when unclear
- Help others learn and grow

## Recognition

Contributors are recognized in:

- GitHub contributor graphs
- Release notes for significant contributions
- README acknowledgments
- Special recognition for major features

## Questions?

If you have questions about contributing:

1. Check this guide first
2. Search existing issues and discussions
3. Create a discussion thread for general questions
4. Open an issue for specific bugs or features

Thank you for helping make DiceLang better for the entire tabletop gaming community!

---

*This contributing guide is adapted from best practices in the Swift open source community.*