import Foundation

public class DiceRoller {
    private let rng: RandomNumberGenerator
    
    public init(randomNumberGenerator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.rng = randomNumberGenerator
    }
    
    public func roll(_ diceRoll: DiceRoll) -> DiceResult {
        let baseRolls = rng.roll(sides: diceRoll.sides, count: diceRoll.count)
        
        guard let modifier = diceRoll.modifier else {
            return DiceResult(
                rolls: baseRolls,
                total: baseRolls.reduce(0, +),
                breakdown: DiceBreakdown(originalRolls: baseRolls),
                type: DiceResultType.standard
            )
        }
        
        return applyModifier(modifier, to: baseRolls, sides: diceRoll.sides)
    }
    
    private func applyModifier(_ modifier: DiceModifier, to rolls: [Int], sides: Int) -> DiceResult {
        switch modifier {
        case .exploding:
            return handleExplodingDice(rolls, sides: sides, compound: false)
        case .compoundExploding:
            return handleExplodingDice(rolls, sides: sides, compound: true)
        case .keepHighest(let count):
            return handleKeepDrop(rolls, keep: true, highest: true, count: count)
        case .keepLowest(let count):
            return handleKeepDrop(rolls, keep: true, highest: false, count: count)
        case .dropHighest(let count):
            return handleKeepDrop(rolls, keep: false, highest: true, count: count)
        case .dropLowest(let count):
            return handleKeepDrop(rolls, keep: false, highest: false, count: count)
        case .threshold(let op, let value):
            return handleThreshold(rolls, operator: op, value: value)
        }
    }
    
    private func handleExplodingDice(_ rolls: [Int], sides: Int, compound: Bool) -> DiceResult {
        var explodedRolls: [ExplodedRoll] = []
        var totalValue = 0
        
        for originalRoll in rolls {
            if originalRoll == sides {
                let additionalRolls = rollExplodingDice(originalRoll: originalRoll, sides: sides, compound: compound)
                let explodedRoll = ExplodedRoll(originalRoll: originalRoll, additionalRolls: additionalRolls)
                explodedRolls.append(explodedRoll)
                totalValue += explodedRoll.totalValue
            } else {
                explodedRolls.append(ExplodedRoll(originalRoll: originalRoll, additionalRolls: []))
                totalValue += originalRoll
            }
        }
        
        let finalRolls = explodedRolls.map { $0.totalValue }
        let breakdown = DiceBreakdown(
            originalRolls: rolls,
            explodedRolls: explodedRolls,
            modifierDescription: compound ? "compound exploding" : "exploding"
        )
        
        return DiceResult(
            rolls: finalRolls,
            total: totalValue,
            breakdown: breakdown,
            type: compound ? DiceResultType.compoundExploding : DiceResultType.exploding
        )
    }
    
    private func rollExplodingDice(originalRoll: Int, sides: Int, compound: Bool) -> [Int] {
        var additionalRolls: [Int] = []
        var currentRoll = originalRoll
        
        while currentRoll == sides {
            let newRoll = rng.roll(sides: sides)
            additionalRolls.append(newRoll)
            currentRoll = compound ? newRoll : 0  // Stop if not compound
        }
        
        return additionalRolls
    }
    
    private func handleKeepDrop(_ rolls: [Int], keep: Bool, highest: Bool, count: Int) -> DiceResult {
        let sortedRolls = rolls.sorted()
        
        var keptRolls: [Int] = []
        var droppedRolls: [Int] = []
        
        if keep {
            if highest {
                keptRolls = Array(sortedRolls.suffix(min(count, rolls.count)))
                droppedRolls = Array(sortedRolls.prefix(max(0, rolls.count - count)))
            } else {
                keptRolls = Array(sortedRolls.prefix(min(count, rolls.count)))
                droppedRolls = Array(sortedRolls.suffix(max(0, rolls.count - count)))
            }
        } else {
            if highest {
                droppedRolls = Array(sortedRolls.suffix(min(count, rolls.count)))
                keptRolls = Array(sortedRolls.prefix(max(0, rolls.count - count)))
            } else {
                droppedRolls = Array(sortedRolls.prefix(min(count, rolls.count)))
                keptRolls = Array(sortedRolls.suffix(max(0, rolls.count - count)))
            }
        }
        
        let total = keptRolls.reduce(0, +)
        let modifierDesc = keep ? (highest ? "keep highest \(count)" : "keep lowest \(count)")
                                : (highest ? "drop highest \(count)" : "drop lowest \(count)")
        
        let breakdown = DiceBreakdown(
            originalRolls: rolls,
            keptRolls: keptRolls,
            droppedRolls: droppedRolls,
            modifierDescription: modifierDesc
        )
        
        return DiceResult(
            rolls: keptRolls,
            total: total,
            breakdown: breakdown,
            type: DiceResultType.keepDrop
        )
    }
    
    private func handleThreshold(_ rolls: [Int], operator op: DiceModifier.ComparisonOperator, value: Int) -> DiceResult {
        var successCount = 0
        var failureCount = 0
        
        for roll in rolls {
            let isSuccess = evaluateThreshold(roll, operator: op, value: value)
            if isSuccess {
                successCount += 1
            } else {
                failureCount += 1
            }
        }
        
        let breakdown = DiceBreakdown(
            originalRolls: rolls,
            successCount: successCount,
            failureCount: failureCount,
            modifierDescription: "threshold \(op.rawValue) \(value)"
        )
        
        return DiceResult(
            rolls: rolls,
            total: successCount,
            breakdown: breakdown,
            type: DiceResultType.pool
        )
    }
    
    private func evaluateThreshold(_ roll: Int, operator op: DiceModifier.ComparisonOperator, value: Int) -> Bool {
        switch op {
        case .greaterThan:
            return roll > value
        case .greaterThanOrEqual:
            return roll >= value
        case .lessThan:
            return roll < value
        case .lessThanOrEqual:
            return roll <= value
        }
    }
}

// MARK: - Convenience Methods

extension DiceRoller {
    public func rollD4(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 4))
    }
    
    public func rollD6(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 6))
    }
    
    public func rollD8(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 8))
    }
    
    public func rollD10(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 10))
    }
    
    public func rollD12(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 12))
    }
    
    public func rollD20(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 20))
    }
    
    public func rollD100(count: Int = 1) -> DiceResult {
        return roll(DiceRoll(count: count, sides: 100))
    }
}