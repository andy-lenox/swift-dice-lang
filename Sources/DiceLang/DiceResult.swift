import Foundation

public struct DiceResult {
    public let rolls: [Int]
    public let total: Int
    public let breakdown: DiceBreakdown
    public let type: DiceResultType
    
    public init(rolls: [Int], total: Int, breakdown: DiceBreakdown, type: DiceResultType) {
        self.rolls = rolls
        self.total = total
        self.breakdown = breakdown
        self.type = type
    }
}

public enum DiceResultType: String, CaseIterable {
    case standard = "standard"
    case exploding = "exploding"
    case compoundExploding = "compound_exploding"
    case keepDrop = "keep_drop"
    case pool = "pool"
    case tagged = "tagged"
    case table = "table"
    case arithmetic = "arithmetic"
}

public struct DiceBreakdown {
    public let originalRolls: [Int]
    public let modifiedRolls: [Int]?
    public let explodedRolls: [ExplodedRoll]?
    public let keptRolls: [Int]?
    public let droppedRolls: [Int]?
    public let successCount: Int?
    public let failureCount: Int?
    public let modifierDescription: String?
    
    public init(
        originalRolls: [Int],
        modifiedRolls: [Int]? = nil,
        explodedRolls: [ExplodedRoll]? = nil,
        keptRolls: [Int]? = nil,
        droppedRolls: [Int]? = nil,
        successCount: Int? = nil,
        failureCount: Int? = nil,
        modifierDescription: String? = nil
    ) {
        self.originalRolls = originalRolls
        self.modifiedRolls = modifiedRolls
        self.explodedRolls = explodedRolls
        self.keptRolls = keptRolls
        self.droppedRolls = droppedRolls
        self.successCount = successCount
        self.failureCount = failureCount
        self.modifierDescription = modifierDescription
    }
}

public struct ExplodedRoll {
    public let originalRoll: Int
    public let additionalRolls: [Int]
    public let totalValue: Int
    
    public init(originalRoll: Int, additionalRolls: [Int]) {
        self.originalRoll = originalRoll
        self.additionalRolls = additionalRolls
        self.totalValue = originalRoll + additionalRolls.reduce(0, +)
    }
}

public struct TaggedDiceResult {
    public let tags: [String: DiceResult]
    public let total: Int
    public let outcome: TaggedOutcome?
    
    public init(tags: [String: DiceResult], total: Int, outcome: TaggedOutcome? = nil) {
        self.tags = tags
        self.total = total
        self.outcome = outcome
    }
}

public struct TaggedOutcome {
    public let rule: String
    public let winningTag: String
    public let result: String
    
    public init(rule: String, winningTag: String, result: String) {
        self.rule = rule
        self.winningTag = winningTag
        self.result = result
    }
}

public struct TableResult {
    public let tableName: String
    public let roll: Int
    public let result: String
    public let nestedResults: [TableResult]?
    
    public init(tableName: String, roll: Int, result: String, nestedResults: [TableResult]? = nil) {
        self.tableName = tableName
        self.roll = roll
        self.result = result
        self.nestedResults = nestedResults
    }
}

// MARK: - Equatable Conformance

extension DiceResult: Equatable {
    public static func == (lhs: DiceResult, rhs: DiceResult) -> Bool {
        return lhs.rolls == rhs.rolls &&
               lhs.total == rhs.total &&
               lhs.breakdown == rhs.breakdown &&
               lhs.type == rhs.type
    }
}

extension DiceBreakdown: Equatable {
    public static func == (lhs: DiceBreakdown, rhs: DiceBreakdown) -> Bool {
        return lhs.originalRolls == rhs.originalRolls &&
               lhs.modifiedRolls == rhs.modifiedRolls &&
               lhs.explodedRolls == rhs.explodedRolls &&
               lhs.keptRolls == rhs.keptRolls &&
               lhs.droppedRolls == rhs.droppedRolls &&
               lhs.successCount == rhs.successCount &&
               lhs.failureCount == rhs.failureCount &&
               lhs.modifierDescription == rhs.modifierDescription
    }
}

extension ExplodedRoll: Equatable {
    public static func == (lhs: ExplodedRoll, rhs: ExplodedRoll) -> Bool {
        return lhs.originalRoll == rhs.originalRoll &&
               lhs.additionalRolls == rhs.additionalRolls &&
               lhs.totalValue == rhs.totalValue
    }
}

extension TaggedDiceResult: Equatable {
    public static func == (lhs: TaggedDiceResult, rhs: TaggedDiceResult) -> Bool {
        return lhs.tags == rhs.tags &&
               lhs.total == rhs.total &&
               lhs.outcome == rhs.outcome
    }
}

extension TaggedOutcome: Equatable {
    public static func == (lhs: TaggedOutcome, rhs: TaggedOutcome) -> Bool {
        return lhs.rule == rhs.rule &&
               lhs.winningTag == rhs.winningTag &&
               lhs.result == rhs.result
    }
}

extension TableResult: Equatable {
    public static func == (lhs: TableResult, rhs: TableResult) -> Bool {
        return lhs.tableName == rhs.tableName &&
               lhs.roll == rhs.roll &&
               lhs.result == rhs.result &&
               lhs.nestedResults == rhs.nestedResults
    }
}

// MARK: - JSON Serialization Support

extension DiceResult: Codable {}
extension DiceResultType: Codable {}
extension DiceBreakdown: Codable {}
extension ExplodedRoll: Codable {}
extension TaggedDiceResult: Codable {}
extension TaggedOutcome: Codable {}
extension TableResult: Codable {}