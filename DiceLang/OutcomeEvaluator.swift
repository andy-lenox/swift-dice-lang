import Foundation

// MARK: - Outcome Evaluation Framework

/// Advanced outcome evaluator that handles complex outcome determination logic
public struct OutcomeEvaluator {
    
    /// Evaluate tagged dice results using various outcome rules
    public static func evaluate(
        taggedResults: [TaggedDieResult],
        using rule: OutcomeRule,
        context: EvaluationContext
    ) throws -> TaggedOutcome {
        return try rule.evaluate(taggedResults: taggedResults, context: context)
    }
    
    /// Evaluate multiple outcome rules and return the first successful result
    public static func evaluateWithFallback(
        taggedResults: [TaggedDieResult],
        using rules: [OutcomeRule],
        context: EvaluationContext
    ) throws -> TaggedOutcome {
        var lastError: Error?
        
        for rule in rules {
            do {
                return try rule.evaluate(taggedResults: taggedResults, context: context)
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? ParseError.invalidExpression(message: "No outcome rules could be evaluated")
    }
    
    /// Combine multiple outcome evaluations using logical operations
    public static func combineOutcomes(
        _ outcomes: [TaggedOutcome],
        using combiner: OutcomeCombiner
    ) -> TaggedOutcome {
        return combiner.combine(outcomes)
    }
}

// MARK: - Outcome Combiners

/// Protocol for combining multiple outcome results
public protocol OutcomeCombiner {
    func combine(_ outcomes: [TaggedOutcome]) -> TaggedOutcome
}

/// Combiner that takes the first non-tie outcome
public struct FirstNonTieCombiner: OutcomeCombiner {
    public init() {}
    
    public func combine(_ outcomes: [TaggedOutcome]) -> TaggedOutcome {
        for outcome in outcomes {
            if outcome.winningTag != "tie" {
                return outcome
            }
        }
        
        // If all are ties, return the first one
        return outcomes.first ?? TaggedOutcome(
            rule: "first_non_tie",
            winningTag: "tie",
            result: "all_tied"
        )
    }
}

/// Combiner that performs majority voting on outcomes
public struct MajorityVoteCombiner: OutcomeCombiner {
    public init() {}
    
    public func combine(_ outcomes: [TaggedOutcome]) -> TaggedOutcome {
        let voteCounts = Dictionary(grouping: outcomes, by: { $0.winningTag })
            .mapValues { $0.count }
        
        guard let winner = voteCounts.max(by: { $0.value < $1.value })?.key else {
            return TaggedOutcome(
                rule: "majority_vote",
                winningTag: "tie",
                result: "no_majority"
            )
        }
        
        return TaggedOutcome(
            rule: "majority_vote",
            winningTag: winner,
            result: "majority_winner"
        )
    }
}

// MARK: - Advanced Outcome Rules

/// Outcome rule that considers weighted tag values
public struct WeightedTagOutcome: OutcomeRule {
    public let tagWeights: [String: Double]
    
    public init(tagWeights: [String: Double]) {
        self.tagWeights = tagWeights
    }
    
    public var description: String {
        return "weighted_tag determines outcome"
    }
    
    public func evaluate(taggedResults: [TaggedDieResult], context: EvaluationContext) throws -> TaggedOutcome {
        guard !taggedResults.isEmpty else {
            throw ParseError.invalidExpression(message: "No tagged dice to evaluate")
        }
        
        // Calculate weighted scores
        let weightedScores = taggedResults.compactMap { result -> (String, Double)? in
            guard let weight = tagWeights[result.tag] else { return nil }
            return (result.tag, Double(result.value) * weight)
        }
        
        guard !weightedScores.isEmpty else {
            throw ParseError.invalidExpression(message: "No tags found in weight mapping")
        }
        
        // Find the highest weighted score
        let maxScore = weightedScores.map { $0.1 }.max() ?? 0
        let winners = weightedScores.filter { $0.1 == maxScore }
        
        if winners.count == 1 {
            let winner = winners[0]
            return TaggedOutcome(
                rule: "weighted_tag determines outcome",
                winningTag: winner.0,
                result: "weighted_winner"
            )
        } else {
            let tiedTags = winners.map { $0.0 }
            return TaggedOutcome(
                rule: "weighted_tag determines outcome",
                winningTag: "tie",
                result: "tie: \(tiedTags.joined(separator: ", "))"
            )
        }
    }
}

/// Outcome rule that requires a minimum threshold to win
public struct ThresholdOutcome: OutcomeRule {
    public let threshold: Int
    
    public init(threshold: Int) {
        self.threshold = threshold
    }
    
    public var description: String {
        return "threshold_\(threshold) determines outcome"
    }
    
    public func evaluate(taggedResults: [TaggedDieResult], context: EvaluationContext) throws -> TaggedOutcome {
        guard !taggedResults.isEmpty else {
            throw ParseError.invalidExpression(message: "No tagged dice to evaluate")
        }
        
        // Find all tags that meet the threshold
        let qualifiedResults = taggedResults.filter { $0.value >= threshold }
        
        if qualifiedResults.isEmpty {
            return TaggedOutcome(
                rule: "threshold_\(threshold) determines outcome",
                winningTag: "failure",
                result: "no_threshold_met"
            )
        } else if qualifiedResults.count == 1 {
            let winner = qualifiedResults[0]
            return TaggedOutcome(
                rule: "threshold_\(threshold) determines outcome",
                winningTag: winner.tag,
                result: "threshold_met"
            )
        } else {
            // Multiple tags meet threshold, use highest value
            let maxValue = qualifiedResults.map { $0.value }.max() ?? 0
            let winners = qualifiedResults.filter { $0.value == maxValue }
            
            if winners.count == 1 {
                let winner = winners[0]
                return TaggedOutcome(
                    rule: "threshold_\(threshold) determines outcome",
                    winningTag: winner.tag,
                    result: "threshold_met"
                )
            } else {
                let tiedTags = winners.map { $0.tag }
                return TaggedOutcome(
                    rule: "threshold_\(threshold) determines outcome",
                    winningTag: "tie",
                    result: "tie: \(tiedTags.joined(separator: ", "))"
                )
            }
        }
    }
}

/// Outcome rule that allows custom evaluation logic
public struct CustomOutcomeRule: OutcomeRule {
    public let ruleName: String
    public let evaluationBlock: ([TaggedDieResult], EvaluationContext) throws -> TaggedOutcome
    
    public init(
        ruleName: String,
        evaluationBlock: @escaping ([TaggedDieResult], EvaluationContext) throws -> TaggedOutcome
    ) {
        self.ruleName = ruleName
        self.evaluationBlock = evaluationBlock
    }
    
    public var description: String {
        return "\(ruleName) determines outcome"
    }
    
    public func evaluate(taggedResults: [TaggedDieResult], context: EvaluationContext) throws -> TaggedOutcome {
        return try evaluationBlock(taggedResults, context)
    }
}

// MARK: - Outcome Statistics

/// Provides statistical analysis of outcome results
public struct OutcomeStatistics {
    public let totalRolls: Int
    public let tagFrequencies: [String: Int]
    public let averageValues: [String: Double]
    public let outcomeDistribution: [String: Int]
    
    public init(from results: [TaggedOutcome]) {
        self.totalRolls = results.count
        
        let outcomes = results.map { $0.winningTag }
        self.outcomeDistribution = Dictionary(grouping: outcomes, by: { $0 }).mapValues { $0.count }
        
        // Initialize other statistics (would need more data in real implementation)
        self.tagFrequencies = [:]
        self.averageValues = [:]
    }
    
    /// Calculate win rate for a specific tag
    public func winRate(for tag: String) -> Double {
        guard totalRolls > 0 else { return 0.0 }
        let wins = outcomeDistribution[tag] ?? 0
        return Double(wins) / Double(totalRolls)
    }
    
    /// Get the most frequent outcome
    public var mostFrequentOutcome: String? {
        return outcomeDistribution.max(by: { $0.value < $1.value })?.key
    }
}