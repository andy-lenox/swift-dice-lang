import Foundation

// MARK: - Table Result Evaluator

/// Evaluates table results that may contain embedded dice rolls
public class TableResultEvaluator {
    
    /// Evaluate a table result string that may contain embedded dice rolls
    public static func evaluate(_ resultString: String, with context: EvaluationContext) throws -> EvaluatedTableResult {
        // Check if the result contains any dice notation
        if containsDiceNotation(resultString) {
            return try evaluateWithDiceRolls(resultString, with: context)
        } else {
            // No dice rolls, return as plain text
            return EvaluatedTableResult(
                originalText: resultString,
                evaluatedText: resultString,
                diceRolls: [],
                totalValue: 0
            )
        }
    }
    
    /// Check if a string contains dice notation
    private static func containsDiceNotation(_ text: String) -> Bool {
        // Look for patterns like "1d6", "2d8", "d20", etc.
        let dicePattern = "\\b(\\d+)?d\\d+(\\+\\d+|-\\d+)?\\b"
        let regex = try! NSRegularExpression(pattern: dicePattern, options: [.caseInsensitive])
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    /// Evaluate a result string with embedded dice rolls
    private static func evaluateWithDiceRolls(_ resultString: String, with context: EvaluationContext) throws -> EvaluatedTableResult {
        var evaluatedText = resultString
        var diceRolls: [EmbeddedDiceRoll] = []
        var totalValue = 0
        
        // Find all dice expressions in the string
        let dicePattern = "\\b(\\d+)?d\\d+(\\+\\d+|-\\d+)?\\b"
        let regex = try! NSRegularExpression(pattern: dicePattern, options: [.caseInsensitive])
        let range = NSRange(resultString.startIndex..., in: resultString)
        
        // Get matches in forward order for consistent evaluation
        let matches = regex.matches(in: resultString, options: [], range: range)
        
        // First pass: evaluate all dice expressions in forward order
        var evaluatedResults: [(range: NSRange, originalExpression: String, result: DiceResult)] = []
        
        for match in matches {
            let matchRange = match.range
            let start = resultString.index(resultString.startIndex, offsetBy: matchRange.location)
            let end = resultString.index(start, offsetBy: matchRange.length)
            let diceExpression = String(resultString[start..<end])
            
            // Parse and evaluate the dice expression
            do {
                let expression = try Parser.parse(diceExpression)
                let result = try expression.evaluate(with: context)
                
                evaluatedResults.append((range: matchRange, originalExpression: diceExpression, result: result))
                
                // Create embedded dice roll record
                let embeddedRoll = EmbeddedDiceRoll(
                    originalExpression: diceExpression,
                    result: result,
                    position: matchRange.location
                )
                diceRolls.append(embeddedRoll)
                totalValue += result.total
                
            } catch {
                // If parsing fails, leave the expression as-is
                continue
            }
        }
        
        // Second pass: replace text in reverse order to avoid index issues
        for evaluatedResult in evaluatedResults.reversed() {
            let start = evaluatedText.index(evaluatedText.startIndex, offsetBy: evaluatedResult.range.location)
            let end = evaluatedText.index(start, offsetBy: evaluatedResult.range.length)
            evaluatedText.replaceSubrange(start..<end, with: "\(evaluatedResult.result.total)")
        }
        
        return EvaluatedTableResult(
            originalText: resultString,
            evaluatedText: evaluatedText,
            diceRolls: diceRolls,
            totalValue: totalValue
        )
    }
    
    /// Evaluate a table result with full nested resolution
    public static func evaluateWithNestedTables(
        _ resultString: String,
        tableManager: TableManager,
        context: EvaluationContext
    ) throws -> EvaluatedTableResult {
        var evaluatedResult = try evaluate(resultString, with: context)
        
        // Check for nested table references (→ @table_name)
        if let nestedTableName = extractNestedTableReference(resultString) {
            // Evaluate the nested table
            let nestedEvaluation = try tableManager.evaluateTable(named: nestedTableName, with: context.randomNumberGenerator)
            
            // Create a new result that includes the nested evaluation
            let combinedText = "\(evaluatedResult.evaluatedText) → \(nestedEvaluation.finalResult)"
            evaluatedResult = EvaluatedTableResult(
                originalText: evaluatedResult.originalText,
                evaluatedText: combinedText,
                diceRolls: evaluatedResult.diceRolls,
                totalValue: evaluatedResult.totalValue,
                nestedTableResult: nestedEvaluation
            )
        }
        
        return evaluatedResult
    }
    
    /// Extract nested table reference from a result string
    private static func extractNestedTableReference(_ text: String) -> String? {
        // Look for pattern like "→ @table_name" or "-> @table_name"
        let referencePattern = "→\\s*@(\\w+)|->\\s*@(\\w+)"
        let regex = try! NSRegularExpression(pattern: referencePattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            // Extract the table name from the first or second capture group
            for i in 1...2 {
                let groupRange = match.range(at: i)
                if groupRange.location != NSNotFound {
                    let start = text.index(text.startIndex, offsetBy: groupRange.location)
                    let end = text.index(start, offsetBy: groupRange.length)
                    return String(text[start..<end])
                }
            }
        }
        
        return nil
    }
}

// MARK: - Evaluated Table Result

/// Represents the result of evaluating a table result string with embedded dice rolls
public struct EvaluatedTableResult {
    public let originalText: String
    public let evaluatedText: String
    public let diceRolls: [EmbeddedDiceRoll]
    public let totalValue: Int
    public let nestedTableResult: TableEvaluationResult?
    
    public init(
        originalText: String,
        evaluatedText: String,
        diceRolls: [EmbeddedDiceRoll],
        totalValue: Int,
        nestedTableResult: TableEvaluationResult? = nil
    ) {
        self.originalText = originalText
        self.evaluatedText = evaluatedText
        self.diceRolls = diceRolls
        self.totalValue = totalValue
        self.nestedTableResult = nestedTableResult
    }
    
    /// Get all dice results from embedded rolls
    public var allDiceResults: [DiceResult] {
        return diceRolls.map { $0.result }
    }
    
    /// Get the final result text for display
    public var finalText: String {
        return evaluatedText
    }
}

// MARK: - Embedded Dice Roll

/// Represents a dice roll that was embedded in a table result
public struct EmbeddedDiceRoll {
    public let originalExpression: String
    public let result: DiceResult
    public let position: Int
    
    public init(originalExpression: String, result: DiceResult, position: Int) {
        self.originalExpression = originalExpression
        self.result = result
        self.position = position
    }
}

// MARK: - Enhanced Table Result

/// Enhanced table result that includes evaluation of embedded dice rolls
public struct EnhancedTableResult {
    public let tableName: String
    public let roll: Int
    public let originalResult: String
    public let evaluatedResult: EvaluatedTableResult
    
    public init(tableName: String, roll: Int, originalResult: String, evaluatedResult: EvaluatedTableResult) {
        self.tableName = tableName
        self.roll = roll
        self.originalResult = originalResult
        self.evaluatedResult = evaluatedResult
    }
    
    /// Get the final display text
    public var finalResult: String {
        return evaluatedResult.finalText
    }
    
    /// Get all dice results from the evaluation
    public var allDiceResults: [DiceResult] {
        return evaluatedResult.allDiceResults
    }
}

// MARK: - Extensions

extension EvaluatedTableResult: CustomStringConvertible {
    public var description: String {
        if diceRolls.isEmpty {
            return evaluatedText
        } else {
            let rollDescriptions = diceRolls.map { "\($0.originalExpression) → \($0.result.total)" }
            return "\(evaluatedText) (rolls: \(rollDescriptions.joined(separator: ", ")))"
        }
    }
}

extension EmbeddedDiceRoll: CustomStringConvertible {
    public var description: String {
        return "\(originalExpression) → \(result.total)"
    }
}

extension EnhancedTableResult: CustomStringConvertible {
    public var description: String {
        return "[\(tableName): \(roll)] \(finalResult)"
    }
}

// MARK: - Equatable Conformance

extension EvaluatedTableResult: Equatable {
    public static func == (lhs: EvaluatedTableResult, rhs: EvaluatedTableResult) -> Bool {
        return lhs.originalText == rhs.originalText &&
               lhs.evaluatedText == rhs.evaluatedText &&
               lhs.diceRolls == rhs.diceRolls &&
               lhs.totalValue == rhs.totalValue &&
               lhs.nestedTableResult == rhs.nestedTableResult
    }
}

extension EmbeddedDiceRoll: Equatable {
    public static func == (lhs: EmbeddedDiceRoll, rhs: EmbeddedDiceRoll) -> Bool {
        return lhs.originalExpression == rhs.originalExpression &&
               lhs.result == rhs.result &&
               lhs.position == rhs.position
    }
}

extension EnhancedTableResult: Equatable {
    public static func == (lhs: EnhancedTableResult, rhs: EnhancedTableResult) -> Bool {
        return lhs.tableName == rhs.tableName &&
               lhs.roll == rhs.roll &&
               lhs.originalResult == rhs.originalResult &&
               lhs.evaluatedResult == rhs.evaluatedResult
    }
}

// MARK: - Table Result Parser

/// Parser for table result strings with embedded dice
public class TableResultParser {
    
    /// Parse a table result string and identify embedded dice expressions
    public static func parse(_ resultString: String) -> ParsedTableResult {
        let segments = extractSegments(from: resultString)
        return ParsedTableResult(originalText: resultString, segments: segments)
    }
    
    /// Extract segments from a result string, separating text and dice expressions
    private static func extractSegments(from text: String) -> [ResultSegment] {
        var segments: [ResultSegment] = []
        var currentIndex = text.startIndex
        
        let dicePattern = "\\b(\\d+)?d\\d+(\\+\\d+|-\\d+)?\\b"
        let regex = try! NSRegularExpression(pattern: dicePattern, options: [.caseInsensitive])
        let range = NSRange(text.startIndex..., in: text)
        
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            let matchRange = match.range
            let start = text.index(text.startIndex, offsetBy: matchRange.location)
            let end = text.index(start, offsetBy: matchRange.length)
            
            // Add text segment before the dice expression
            if currentIndex < start {
                let textSegment = String(text[currentIndex..<start])
                segments.append(ResultSegment(type: .text, content: textSegment))
            }
            
            // Add dice expression segment
            let diceExpression = String(text[start..<end])
            segments.append(ResultSegment(type: .dice, content: diceExpression))
            
            currentIndex = end
        }
        
        // Add remaining text
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex...])
            segments.append(ResultSegment(type: .text, content: remainingText))
        }
        
        return segments
    }
}

// MARK: - Parsed Table Result

/// Represents a parsed table result with identified segments
public struct ParsedTableResult {
    public let originalText: String
    public let segments: [ResultSegment]
    
    public init(originalText: String, segments: [ResultSegment]) {
        self.originalText = originalText
        self.segments = segments
    }
    
    /// Get all dice expressions in the result
    public var diceExpressions: [String] {
        return segments.compactMap { segment in
            segment.type == .dice ? segment.content : nil
        }
    }
    
    /// Get all text segments
    public var textSegments: [String] {
        return segments.compactMap { segment in
            segment.type == .text ? segment.content : nil
        }
    }
}

// MARK: - Result Segment

/// Represents a segment of a table result (either text or dice)
public struct ResultSegment {
    public enum SegmentType {
        case text
        case dice
    }
    
    public let type: SegmentType
    public let content: String
    
    public init(type: SegmentType, content: String) {
        self.type = type
        self.content = content
    }
}

// MARK: - Extensions

extension ParsedTableResult: CustomStringConvertible {
    public var description: String {
        let segmentDescriptions = segments.map { segment in
            switch segment.type {
            case .text:
                return segment.content
            case .dice:
                return "[\(segment.content)]"
            }
        }
        return segmentDescriptions.joined()
    }
}

extension ResultSegment: CustomStringConvertible {
    public var description: String {
        switch type {
        case .text:
            return content
        case .dice:
            return "[\(content)]"
        }
    }
}

// MARK: - Equatable Conformance

extension ParsedTableResult: Equatable {
    public static func == (lhs: ParsedTableResult, rhs: ParsedTableResult) -> Bool {
        return lhs.originalText == rhs.originalText &&
               lhs.segments == rhs.segments
    }
}

extension ResultSegment: Equatable {
    public static func == (lhs: ResultSegment, rhs: ResultSegment) -> Bool {
        return lhs.type == rhs.type &&
               lhs.content == rhs.content
    }
}