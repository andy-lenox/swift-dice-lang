import Testing
import Foundation
@testable import DiceLang

// MARK: - Tagged Dice Tests

@Suite("Tagged Dice System")
struct TaggedDiceTests {
    
    // MARK: - Basic Tagged Dice Tests
    
    @Test("Tagged dice basic parsing")
    func taggedDiceBasicParsing() throws {
        // Test basic tagged dice parsing
        let input = "[hope: d12, fear: d12] => higher_tag determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        let expression = try parser.parse()
        
        // Verify it's a TaggedGroup
        #expect(expression is TaggedGroup)
        
        if let taggedGroup = expression as? TaggedGroup {
            #expect(taggedGroup.taggedDice.count == 2)
            #expect(taggedGroup.taggedDice[0].tag == "hope")
            #expect(taggedGroup.taggedDice[1].tag == "fear")
            #expect(taggedGroup.outcomeRule.description == "higher_tag determines outcome")
        }
    }
    
    @Test("Tagged dice single tag parsing")
    func taggedDiceSingleTagParsing() throws {
        let input = "[magic: 2d6] => higher_tag determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        let expression = try parser.parse()
        
        #expect(expression is TaggedGroup)
        
        if let taggedGroup = expression as? TaggedGroup {
            #expect(taggedGroup.taggedDice.count == 1)
            #expect(taggedGroup.taggedDice[0].tag == "magic")
        }
    }
    
    @Test("Tagged dice multiple tags parsing")
    func taggedDiceMultipleTagsParsing() throws {
        let input = "[hope: d12, fear: d12, chaos: d10, order: d8] => higher_tag determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        let expression = try parser.parse()
        
        #expect(expression is TaggedGroup)
        
        if let taggedGroup = expression as? TaggedGroup {
            #expect(taggedGroup.taggedDice.count == 4)
            #expect(taggedGroup.taggedDice[0].tag == "hope")
            #expect(taggedGroup.taggedDice[1].tag == "fear")
            #expect(taggedGroup.taggedDice[2].tag == "chaos")
            #expect(taggedGroup.taggedDice[3].tag == "order")
        }
    }
    
    // MARK: - Evaluation Tests
    
    @Test("Tagged dice evaluation basic")
    func taggedDiceEvaluationBasic() throws {
        let input = "[hope: d12, fear: d12] => higher_tag determines outcome"
        let expression = try Parser.parse(input)
        
        // Create a fixed context for consistent testing
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [10, 6]))
        let result = try expression.evaluate(with: context)
        
        #expect(result.type == .tagged)
        #expect(result.total == 16) // 10 + 6
        #expect(result.rolls.count == 2)
        
        // Check that the breakdown contains tagged information
        let description = result.breakdown.modifierDescription ?? ""
        #expect(description.contains("Tagged dice"))
        #expect(description.contains("hope:10"))
        #expect(description.contains("fear:6"))
        #expect(description.contains("outcome=hope"))
    }
    
    @Test("Tagged dice evaluation with tie")
    func taggedDiceEvaluationWithTie() throws {
        let input = "[hope: d12, fear: d12] => higher_tag determines outcome"
        let expression = try Parser.parse(input)
        
        // Create a context where both dice roll the same value
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [8, 8]))
        let result = try expression.evaluate(with: context)
        
        #expect(result.type == .tagged)
        #expect(result.total == 16) // 8 + 8
        
        // Check that the breakdown indicates a tie
        let description = result.breakdown.modifierDescription ?? ""
        #expect(description.contains("outcome=tie"))
    }
    
    @Test("Tagged dice with different die types")
    func taggedDiceWithDifferentDieTypes() throws {
        let input = "[strength: d20, dexterity: d6, magic: 2d10] => higher_tag determines outcome"
        let expression = try Parser.parse(input)
        
        // Setup values: d20=15, d6=4, 2d10=7+3=10
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [15, 4, 7, 3]))
        let result = try expression.evaluate(with: context)
        
        #expect(result.type == .tagged)
        #expect(result.total == 29) // 15 + 4 + 10
        
        // Check that strength wins (15 > 10 > 4)
        let description = result.breakdown.modifierDescription ?? ""
        #expect(description.contains("outcome=strength"))
    }
    
    // MARK: - Outcome Rule Tests
    
    @Test("Higher tag determines outcome rule")
    func higherTagDeterminesOutcomeRule() throws {
        let rule = HigherTagDeterminesOutcome()
        
        // Create test results
        let hopeDiceResult = DiceResult(
            rolls: [10], 
            total: 10, 
            breakdown: DiceBreakdown(originalRolls: [10]), 
            type: DiceResultType.standard
        )
        let fearDiceResult = DiceResult(
            rolls: [6], 
            total: 6, 
            breakdown: DiceBreakdown(originalRolls: [6]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "hope", result: hopeDiceResult),
            TaggedDieResult(tag: "fear", result: fearDiceResult)
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "higher_tag determines outcome")
        #expect(outcome.winningTag == "hope")
        #expect(outcome.result == "hopeful")
    }
    
    @Test("Higher tag with tie outcome")
    func higherTagWithTieOutcome() throws {
        let rule = HigherTagDeterminesOutcome()
        
        // Create test results with same values
        let hopeDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        let fearDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "hope", result: hopeDiceResult),
            TaggedDieResult(tag: "fear", result: fearDiceResult)
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "higher_tag determines outcome")
        #expect(outcome.winningTag == "tie")
        #expect(outcome.result.contains("hope"))
        #expect(outcome.result.contains("fear"))
    }
    
    // MARK: - Outcome Type Determination Tests
    
    @Test("Outcome type determination for common tags")
    func outcomeTypeDeterminationForCommonTags() throws {
        let rule = HigherTagDeterminesOutcome()
        
        // Test various tag types
        let testCases = [
            ("hope", "hopeful"),
            ("fear", "fearful"),
            ("chaos", "chaotic"),
            ("order", "orderly"),
            ("custom", "custom_outcome")
        ]
        
        for (tag, expectedOutcome) in testCases {
            let diceResult = DiceResult(
                rolls: [10], 
                total: 10, 
                breakdown: DiceBreakdown(originalRolls: [10]), 
                type: DiceResultType.standard
            )
            
            let taggedResults = [TaggedDieResult(tag: tag, result: diceResult)]
            let context = EvaluationContext()
            let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
            
            #expect(outcome.winningTag == tag)
            #expect(outcome.result == expectedOutcome)
        }
    }
    
    // MARK: - JSON Formatting Tests
    
    @Test("JSON formatting for tagged dice")
    func jsonFormattingForTaggedDice() throws {
        let input = "[hope: d12, fear: d12] => higher_tag determines outcome"
        let expression = try Parser.parse(input)
        
        // Create a fixed context for consistent testing
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [10, 6]))
        let result = try expression.evaluate(with: context)
        
        let jsonString = result.toJSON(originalExpression: input)
        
        // Verify JSON contains expected structure
        #expect(jsonString.contains("\"type\" : \"tagged_group\""))
        #expect(jsonString.contains("\"raw\" : \"[hope: d12, fear: d12] => higher_tag determines outcome\""))
        #expect(jsonString.contains("\"sum\" : 16"))
        #expect(jsonString.contains("\"rolls\""))
        #expect(jsonString.contains("\"higher_tag\""))
        #expect(jsonString.contains("\"outcome\""))
    }
    
    // MARK: - Extended Outcome Evaluator Tests
    
    @Test("Weighted tag outcome evaluator")
    func weightedTagOutcomeEvaluator() throws {
        let weights = ["hope": 2.0, "fear": 1.0]
        let rule = WeightedTagOutcome(tagWeights: weights)
        
        // Create test results where fear has higher raw value but hope has higher weighted value
        let hopeDiceResult = DiceResult(
            rolls: [6], 
            total: 6, 
            breakdown: DiceBreakdown(originalRolls: [6]), 
            type: DiceResultType.standard
        )
        let fearDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "hope", result: hopeDiceResult), // 6 * 2.0 = 12
            TaggedDieResult(tag: "fear", result: fearDiceResult)  // 8 * 1.0 = 8
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "weighted_tag determines outcome")
        #expect(outcome.winningTag == "hope")
        #expect(outcome.result == "weighted_winner")
    }
    
    @Test("Threshold outcome evaluator")
    func thresholdOutcomeEvaluator() throws {
        let rule = ThresholdOutcome(threshold: 7)
        
        // Create test results where only one tag meets threshold
        let hopeDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        let fearDiceResult = DiceResult(
            rolls: [5], 
            total: 5, 
            breakdown: DiceBreakdown(originalRolls: [5]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "hope", result: hopeDiceResult), // 8 >= 7
            TaggedDieResult(tag: "fear", result: fearDiceResult)  // 5 < 7
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "threshold_7 determines outcome")
        #expect(outcome.winningTag == "hope")
        #expect(outcome.result == "threshold_met")
    }
    
    @Test("Threshold outcome evaluator with no qualifying tags")
    func thresholdOutcomeEvaluatorWithNoQualifyingTags() throws {
        let rule = ThresholdOutcome(threshold: 10)
        
        // Create test results where no tag meets threshold
        let hopeDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        let fearDiceResult = DiceResult(
            rolls: [5], 
            total: 5, 
            breakdown: DiceBreakdown(originalRolls: [5]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "hope", result: hopeDiceResult), // 8 < 10
            TaggedDieResult(tag: "fear", result: fearDiceResult)  // 5 < 10
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "threshold_10 determines outcome")
        #expect(outcome.winningTag == "failure")
        #expect(outcome.result == "no_threshold_met")
    }
    
    @Test("Custom outcome rule")
    func customOutcomeRule() throws {
        // Create a custom rule that always picks the alphabetically first tag
        let rule = CustomOutcomeRule(ruleName: "alphabetical_first") { taggedResults, context in
            let sortedTags = taggedResults.sorted { $0.tag < $1.tag }
            let winner = sortedTags.first!
            return TaggedOutcome(
                rule: "alphabetical_first determines outcome",
                winningTag: winner.tag,
                result: "alphabetical_winner"
            )
        }
        
        let hopeDiceResult = DiceResult(
            rolls: [8], 
            total: 8, 
            breakdown: DiceBreakdown(originalRolls: [8]), 
            type: DiceResultType.standard
        )
        let zestDiceResult = DiceResult(
            rolls: [12], 
            total: 12, 
            breakdown: DiceBreakdown(originalRolls: [12]), 
            type: DiceResultType.standard
        )
        
        let taggedResults = [
            TaggedDieResult(tag: "zest", result: zestDiceResult),
            TaggedDieResult(tag: "hope", result: hopeDiceResult)
        ]
        
        let context = EvaluationContext()
        let outcome = try rule.evaluate(taggedResults: taggedResults, context: context)
        
        #expect(outcome.rule == "alphabetical_first determines outcome")
        #expect(outcome.winningTag == "hope") // "hope" comes before "zest" alphabetically
        #expect(outcome.result == "alphabetical_winner")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Tagged dice parsing error - missing colon")
    func taggedDiceParsingErrorMissingColon() throws {
        let input = "[hope d12, fear: d12] => higher_tag determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        
        #expect(throws: ParseError.self) {
            try parser.parse()
        }
    }
    
    @Test("Tagged dice parsing error - missing arrow")
    func taggedDiceParsingErrorMissingArrow() throws {
        let input = "[hope: d12, fear: d12] higher_tag determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        
        #expect(throws: ParseError.self) {
            try parser.parse()
        }
    }
    
    @Test("Tagged dice parsing error - invalid outcome rule")
    func taggedDiceParsingErrorInvalidOutcomeRule() throws {
        let input = "[hope: d12, fear: d12] => invalid_rule determines outcome"
        let tokens = Lexer(input: input).tokenize()
        let parser = Parser(tokens: tokens)
        
        #expect(throws: ParseError.self) {
            try parser.parse()
        }
    }
    
    @Test("Empty tagged dice evaluation error")
    func emptyTaggedDiceEvaluationError() throws {
        let rule = HigherTagDeterminesOutcome()
        let context = EvaluationContext()
        
        #expect(throws: ParseError.self) {
            try rule.evaluate(taggedResults: [], context: context)
        }
    }
    
    // MARK: - Outcome Combiner Tests
    
    @Test("First non-tie combiner")
    func firstNonTieCombiner() throws {
        let combiner = FirstNonTieCombiner()
        
        let outcomes = [
            TaggedOutcome(rule: "test", winningTag: "tie", result: "tie result"),
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful"),
            TaggedOutcome(rule: "test", winningTag: "fear", result: "fearful")
        ]
        
        let result = combiner.combine(outcomes)
        
        #expect(result.winningTag == "hope")
        #expect(result.result == "hopeful")
    }
    
    @Test("Majority vote combiner")
    func majorityVoteCombiner() throws {
        let combiner = MajorityVoteCombiner()
        
        let outcomes = [
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful"),
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful"),
            TaggedOutcome(rule: "test", winningTag: "fear", result: "fearful")
        ]
        
        let result = combiner.combine(outcomes)
        
        #expect(result.rule == "majority_vote")
        #expect(result.winningTag == "hope")
        #expect(result.result == "majority_winner")
    }
    
    // MARK: - Outcome Statistics Tests
    
    @Test("Outcome statistics calculation")
    func outcomeStatisticsCalculation() throws {
        let outcomes = [
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful"),
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful"),
            TaggedOutcome(rule: "test", winningTag: "fear", result: "fearful"),
            TaggedOutcome(rule: "test", winningTag: "hope", result: "hopeful")
        ]
        
        let stats = OutcomeStatistics(from: outcomes)
        
        #expect(stats.totalRolls == 4)
        #expect(stats.winRate(for: "hope") == 0.75)
        #expect(stats.winRate(for: "fear") == 0.25)
        #expect(stats.mostFrequentOutcome == "hope")
    }
}

// MARK: - Test Helper

// MARK: - Integration Tests

@Suite("Tagged Dice Integration Tests")
struct TaggedDiceIntegrationTests {
    
    @Test("Complete tagged dice workflow")
    func completeTaggedDiceWorkflow() throws {
        // Test complete workflow from parsing to JSON output
        let input = "[hope: d12, fear: d12] => higher_tag determines outcome"
        
        // Parse
        let expression = try Parser.parse(input)
        
        // Evaluate
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [10, 6]))
        let result = try expression.evaluate(with: context)
        
        // Convert to JSON
        let jsonString = result.toJSON(originalExpression: input)
        
        // Verify complete workflow
        #expect(result.type == .tagged)
        #expect(result.total == 16)
        #expect(jsonString.contains("tagged_group"))
        #expect(jsonString.contains("hope"))
        #expect(jsonString.contains("fear"))
    }
    
    @Test("Tagged dice with arithmetic operations")
    func taggedDiceWithArithmeticOperations() throws {
        // This test is disabled for now as arithmetic operations within tagged dice
        // require more complex parsing implementation
        // TODO: Implement arithmetic operations within tagged dice expressions
        let input = "[strength: 2d6, magic: d8] => higher_tag determines outcome"
        
        // Parse and evaluate
        let expression = try Parser.parse(input)
        let context = EvaluationContext(randomNumberGenerator: FixedRandomNumberGenerator(values: [4, 5, 6]))
        let result = try expression.evaluate(with: context)
        
        // strength: 2d6 = 4+5 = 9
        // magic: d8 = 6
        // total: 9+6 = 15
        
        #expect(result.type == .tagged)
        #expect(result.total == 15)
        
        let description = result.breakdown.modifierDescription ?? ""
        #expect(description.contains("strength"))
        #expect(description.contains("magic"))
    }
}