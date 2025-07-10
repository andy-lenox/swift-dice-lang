import Foundation

// MARK: - JSON Output Formatter

/// Formats dice results into JSON according to the DiceLang specification
public struct JSONFormatter {
    
    /// Format a dice result into JSON according to spec
    public static func formatResult(_ result: DiceResult, originalExpression: String) -> Data {
        let jsonObject = createJSONObject(from: result, originalExpression: originalExpression)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return jsonData
        } catch {
            // Fallback to basic JSON structure
            let fallbackObject: [String: Any] = [
                "type": "error",
                "message": "Failed to serialize result",
                "raw": originalExpression
            ]
            return try! JSONSerialization.data(withJSONObject: fallbackObject, options: [.prettyPrinted])
        }
    }
    
    /// Format a dice result into JSON string
    public static func formatResultAsString(_ result: DiceResult, originalExpression: String) -> String {
        let jsonData = formatResult(result, originalExpression: originalExpression)
        return String(data: jsonData, encoding: .utf8) ?? "{\"error\": \"encoding_failed\"}"
    }
    
    /// Create JSON object from dice result
    internal static func createJSONObject(from result: DiceResult, originalExpression: String) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "raw": originalExpression,
            "sum": result.total,
            "rolls": result.rolls
        ]
        
        // Handle different result types
        switch result.type {
        case .tagged:
            return formatTaggedResult(result, originalExpression: originalExpression)
        case .pool:
            return formatPoolResult(result, originalExpression: originalExpression)
        case .exploding, .compoundExploding:
            return formatExplodingResult(result, originalExpression: originalExpression)
        case .keepDrop:
            return formatKeepDropResult(result, originalExpression: originalExpression)
        case .table:
            return formatTableResult(result, originalExpression: originalExpression)
        case .standard, .arithmetic:
            jsonObject["type"] = "standard"
            return jsonObject
        }
    }
    
    /// Format tagged dice result according to spec
    private static func formatTaggedResult(_ result: DiceResult, originalExpression: String) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": "tagged_group",
            "raw": originalExpression,
            "sum": result.total
        ]
        
        // Parse tagged information from modifier description
        let modifierDescription = result.breakdown.modifierDescription ?? ""
        
        var rolls: [String: Int] = [:]
        var higherTag = "unknown"
        var outcome = "unknown"
        
        // Extract tagged results from description
        if let taggedRange = modifierDescription.range(of: "\\[([^\\]]+)\\]", options: .regularExpression) {
            let taggedString = String(modifierDescription[taggedRange])
            let cleanedString = taggedString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            
            // Parse tag:value pairs
            let tagPairs = cleanedString.components(separatedBy: ",")
            for pair in tagPairs {
                let components = pair.components(separatedBy: ":")
                if components.count == 2 {
                    let tag = components[0].trimmingCharacters(in: .whitespaces)
                    let value = Int(components[1].trimmingCharacters(in: .whitespaces)) ?? 0
                    rolls[tag] = value
                }
            }
        }
        
        // Extract outcome information
        if let outcomeRange = modifierDescription.range(of: "outcome=([^:]+):(.+)", options: .regularExpression) {
            let outcomeString = String(modifierDescription[outcomeRange])
            let components = outcomeString.components(separatedBy: ":")
            if components.count >= 2 {
                higherTag = components[0].replacingOccurrences(of: "outcome=", with: "")
                outcome = components[1]
            }
        }
        
        jsonObject["rolls"] = rolls
        jsonObject["higher_tag"] = higherTag
        jsonObject["outcome"] = outcome
        
        return jsonObject
    }
    
    /// Format dice pool result
    private static func formatPoolResult(_ result: DiceResult, originalExpression: String) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": "pool",
            "raw": originalExpression,
            "rolls": result.rolls,
            "sum": result.total
        ]
        
        // Add pool-specific information
        if let successCount = result.breakdown.successCount {
            jsonObject["successes"] = successCount
        }
        if let failureCount = result.breakdown.failureCount {
            jsonObject["failures"] = failureCount
        }
        
        return jsonObject
    }
    
    /// Format exploding dice result
    private static func formatExplodingResult(_ result: DiceResult, originalExpression: String) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": result.type == .exploding ? "exploding" : "compound_exploding",
            "raw": originalExpression,
            "sum": result.total
        ]
        
        // Include exploded roll details
        if let explodedRolls = result.breakdown.explodedRolls {
            let explodedDetails = explodedRolls.map { explodedRoll in
                return [
                    "original": explodedRoll.originalRoll,
                    "additional": explodedRoll.additionalRolls,
                    "total": explodedRoll.totalValue
                ]
            }
            jsonObject["exploded_rolls"] = explodedDetails
        }
        
        jsonObject["original_rolls"] = result.breakdown.originalRolls
        jsonObject["final_rolls"] = result.rolls
        
        return jsonObject
    }
    
    /// Format keep/drop result
    private static func formatKeepDropResult(_ result: DiceResult, originalExpression: String) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": "keep_drop",
            "raw": originalExpression,
            "sum": result.total
        ]
        
        jsonObject["original_rolls"] = result.breakdown.originalRolls
        jsonObject["final_rolls"] = result.rolls
        
        if let keptRolls = result.breakdown.keptRolls {
            jsonObject["kept_rolls"] = keptRolls
        }
        if let droppedRolls = result.breakdown.droppedRolls {
            jsonObject["dropped_rolls"] = droppedRolls
        }
        
        return jsonObject
    }
    
    /// Format table result
    private static func formatTableResult(_ result: DiceResult, originalExpression: String) -> [String: Any] {
        return [
            "type": "table",
            "raw": originalExpression,
            "sum": result.total,
            "rolls": result.rolls
        ]
    }
}

// MARK: - Extended JSON Formatting

/// Extended formatter with more configuration options
public struct ExtendedJSONFormatter {
    
    public struct FormattingOptions {
        public let includeBreakdown: Bool
        public let includeRawRolls: Bool
        public let includeStatistics: Bool
        public let prettyPrint: Bool
        
        public init(
            includeBreakdown: Bool = true,
            includeRawRolls: Bool = true,
            includeStatistics: Bool = false,
            prettyPrint: Bool = true
        ) {
            self.includeBreakdown = includeBreakdown
            self.includeRawRolls = includeRawRolls
            self.includeStatistics = includeStatistics
            self.prettyPrint = prettyPrint
        }
        
        public static let standard = FormattingOptions()
        public static let minimal = FormattingOptions(includeBreakdown: false, includeRawRolls: false)
        public static let detailed = FormattingOptions(includeStatistics: true)
    }
    
    /// Format dice result with extended options
    public static func formatResult(
        _ result: DiceResult,
        originalExpression: String,
        options: FormattingOptions = .standard
    ) -> Data {
        var jsonObject = JSONFormatter.createJSONObject(from: result, originalExpression: originalExpression)
        
        // Add optional components
        if options.includeBreakdown {
            jsonObject["breakdown"] = formatBreakdown(result.breakdown)
        }
        
        if options.includeStatistics {
            jsonObject["statistics"] = formatStatistics(result)
        }
        
        // Format JSON with specified options
        let jsonOptions: JSONSerialization.WritingOptions = options.prettyPrint ? [.prettyPrinted] : []
        
        do {
            return try JSONSerialization.data(withJSONObject: jsonObject, options: jsonOptions)
        } catch {
            let fallbackObject: [String: Any] = [
                "type": "error",
                "message": "Failed to serialize result",
                "raw": originalExpression
            ]
            return try! JSONSerialization.data(withJSONObject: fallbackObject, options: jsonOptions)
        }
    }
    
    /// Format breakdown information
    private static func formatBreakdown(_ breakdown: DiceBreakdown) -> [String: Any] {
        var breakdownObject: [String: Any] = [
            "original_rolls": breakdown.originalRolls
        ]
        
        if let modifiedRolls = breakdown.modifiedRolls {
            breakdownObject["modified_rolls"] = modifiedRolls
        }
        
        if let explodedRolls = breakdown.explodedRolls {
            breakdownObject["exploded_rolls"] = explodedRolls.map { explodedRoll in
                return [
                    "original": explodedRoll.originalRoll,
                    "additional": explodedRoll.additionalRolls,
                    "total": explodedRoll.totalValue
                ]
            }
        }
        
        if let keptRolls = breakdown.keptRolls {
            breakdownObject["kept_rolls"] = keptRolls
        }
        
        if let droppedRolls = breakdown.droppedRolls {
            breakdownObject["dropped_rolls"] = droppedRolls
        }
        
        if let successCount = breakdown.successCount {
            breakdownObject["success_count"] = successCount
        }
        
        if let failureCount = breakdown.failureCount {
            breakdownObject["failure_count"] = failureCount
        }
        
        if let modifierDescription = breakdown.modifierDescription {
            breakdownObject["modifier_description"] = modifierDescription
        }
        
        return breakdownObject
    }
    
    /// Format statistics information
    private static func formatStatistics(_ result: DiceResult) -> [String: Any] {
        let rolls = result.rolls
        let average = rolls.isEmpty ? 0 : Double(rolls.reduce(0, +)) / Double(rolls.count)
        let min = rolls.min() ?? 0
        let max = rolls.max() ?? 0
        
        return [
            "average": average,
            "min": min,
            "max": max,
            "count": rolls.count
        ]
    }
}

// MARK: - Convenience Extensions

extension DiceResult {
    /// Convert to JSON string using default formatter
    public func toJSON(originalExpression: String) -> String {
        return JSONFormatter.formatResultAsString(self, originalExpression: originalExpression)
    }
    
    /// Convert to JSON data using default formatter
    public func toJSONData(originalExpression: String) -> Data {
        return JSONFormatter.formatResult(self, originalExpression: originalExpression)
    }
    
    /// Convert to JSON with extended options
    public func toJSONWithOptions(
        originalExpression: String,
        options: ExtendedJSONFormatter.FormattingOptions = .standard
    ) -> Data {
        return ExtendedJSONFormatter.formatResult(self, originalExpression: originalExpression, options: options)
    }
}