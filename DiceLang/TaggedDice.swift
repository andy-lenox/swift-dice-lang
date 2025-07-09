import Foundation

// MARK: - Tagged Dice System

/// Represents a single tagged die roll with its tag identifier
public struct TaggedDie {
    public let tag: String
    public let diceExpression: DiceExpression
    
    public init(tag: String, diceExpression: DiceExpression) {
        self.tag = tag
        self.diceExpression = diceExpression
    }
}

/// Result of a tagged die roll
public struct TaggedDieResult {
    public let tag: String
    public let result: DiceResult
    
    public init(tag: String, result: DiceResult) {
        self.tag = tag
        self.result = result
    }
    
    public var value: Int {
        return result.total
    }
}

/// Represents a group of tagged dice with an outcome rule
public struct TaggedGroup: DiceExpression, Visitable {
    public let taggedDice: [TaggedDie]
    public let outcomeRule: OutcomeRule
    
    public init(taggedDice: [TaggedDie], outcomeRule: OutcomeRule) {
        self.taggedDice = taggedDice
        self.outcomeRule = outcomeRule
    }
    
    public func evaluate(with context: EvaluationContext) throws -> DiceResult {
        // Evaluate each tagged die
        var taggedResults: [TaggedDieResult] = []
        
        for taggedDie in taggedDice {
            let result = try taggedDie.diceExpression.evaluate(with: context)
            taggedResults.append(TaggedDieResult(tag: taggedDie.tag, result: result))
        }
        
        // Apply outcome rule
        let outcome = try outcomeRule.evaluate(taggedResults: taggedResults, context: context)
        
        // Create result with tagged breakdown
        let totalSum = taggedResults.reduce(0) { $0 + $1.value }
        let allRolls = taggedResults.flatMap { $0.result.rolls }
        
        let taggedBreakdown = TaggedDiceBreakdown(
            taggedResults: taggedResults,
            outcome: outcome,
            outcomeRule: outcomeRule
        )
        
        // Create a standard DiceBreakdown compatible with DiceResult
        // Store tagged breakdown info in the modifier description as JSON
        let taggedInfo = taggedBreakdown.taggedResults.map { result in
            "\(result.tag):\(result.value)"
        }.joined(separator: ",")
        
        let outcomeInfo = "outcome=\(taggedBreakdown.outcome.winningTag):\(taggedBreakdown.outcome.result)"
        
        let breakdown = DiceBreakdown(
            originalRolls: taggedBreakdown.originalRolls,
            modifierDescription: "Tagged dice with \(outcomeRule.description) [\(taggedInfo)] \(outcomeInfo)"
        )
        
        return DiceResult(
            rolls: allRolls,
            total: totalSum,
            breakdown: breakdown,
            type: .tagged
        )
    }
    
    public var description: String {
        let taggedDescriptions = taggedDice.map { "\($0.tag): \($0.diceExpression.description)" }
        return "[\(taggedDescriptions.joined(separator: ", "))] => \(outcomeRule.description)"
    }
    
    public func accept<V: DiceExpressionVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}

// MARK: - Outcome Rules

/// Protocol for outcome evaluation rules
public protocol OutcomeRule {
    var description: String { get }
    func evaluate(taggedResults: [TaggedDieResult], context: EvaluationContext) throws -> TaggedOutcome
}


/// Rule that determines outcome based on highest tagged die value
public struct HigherTagDeterminesOutcome: OutcomeRule {
    public init() {}
    
    public var description: String {
        return "higher_tag determines outcome"
    }
    
    public func evaluate(taggedResults: [TaggedDieResult], context: EvaluationContext) throws -> TaggedOutcome {
        guard !taggedResults.isEmpty else {
            throw ParseError.invalidExpression(message: "No tagged dice to evaluate")
        }
        
        // Find the highest value
        let maxValue = taggedResults.map { $0.value }.max() ?? 0
        
        // Find all tags with the maximum value
        let winnersWithMaxValue = taggedResults.filter { $0.value == maxValue }
        
        if winnersWithMaxValue.count == 1 {
            // Clear winner
            let winner = winnersWithMaxValue[0]
            let outcomeType = determineOutcomeType(for: winner.tag)
            
            return TaggedOutcome(
                rule: "higher_tag determines outcome",
                winningTag: winner.tag,
                result: outcomeType
            )
        } else {
            // Tie situation
            let tiedTags = winnersWithMaxValue.map { $0.tag }
            return TaggedOutcome(
                rule: "higher_tag determines outcome",
                winningTag: "tie",
                result: "tie: \(tiedTags.joined(separator: ", "))"
            )
        }
    }
    
    private func determineOutcomeType(for tag: String) -> String {
        // Convert tag to outcome type
        // This can be customized based on game rules
        switch tag.lowercased() {
        case "hope", "good", "success", "light":
            return "hopeful"
        case "fear", "bad", "failure", "dark":
            return "fearful"
        case "chaos", "wild", "random":
            return "chaotic"
        case "order", "law", "stable":
            return "orderly"
        default:
            return "\(tag)_outcome"
        }
    }
}

// MARK: - Tagged Dice Breakdown

/// Detailed breakdown for tagged dice results
public struct TaggedDiceBreakdown {
    public let taggedResults: [TaggedDieResult]
    public let outcome: TaggedOutcome
    public let outcomeRule: OutcomeRule
    
    public init(taggedResults: [TaggedDieResult], outcome: TaggedOutcome, outcomeRule: OutcomeRule) {
        self.taggedResults = taggedResults
        self.outcome = outcome
        self.outcomeRule = outcomeRule
    }
    
    public var originalRolls: [Int] {
        return taggedResults.flatMap { $0.result.breakdown.originalRolls }
    }
    
    public var modifierDescription: String {
        return "Tagged dice with \(outcomeRule.description)"
    }
    
    public var detailedBreakdown: String {
        let tagBreakdowns = taggedResults.map { taggedResult in
            "\(taggedResult.tag): \(taggedResult.result.total)"
        }
        
        let outcomeDescription = "Winner: \(outcome.winningTag) (\(outcome.result))"
        
        return "[\(tagBreakdowns.joined(separator: ", "))] => \(outcomeDescription)"
    }
}


