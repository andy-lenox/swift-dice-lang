import Foundation

/// Formats dice results into structured JSON output
public class ResultFormatter {
    
    /// Format a dice result as JSON data
    /// - Parameter result: The dice result to format
    /// - Returns: JSON data representation
    /// - Throws: Encoding errors
    public static func formatAsJSON(_ result: DiceResult) throws -> Data {
        let jsonObject = formatAsJSONObject(result)
        return try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
    }
    
    /// Format a dice result as a JSON string
    /// - Parameter result: The dice result to format
    /// - Returns: JSON string representation
    /// - Throws: Encoding errors
    public static func formatAsJSONString(_ result: DiceResult) throws -> String {
        let data = try formatAsJSON(result)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Format a dice result as a JSON object (Dictionary)
    /// - Parameter result: The dice result to format
    /// - Returns: JSON object representation
    public static func formatAsJSONObject(_ result: DiceResult) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": result.type.rawValue,
            "total": result.total,
            "rolls": result.rolls
        ]
        
        // Add breakdown details
        jsonObject["breakdown"] = formatBreakdown(result.breakdown)
        
        // Add type-specific details
        switch result.type {
        case .pool:
            if let successCount = result.breakdown.successCount {
                jsonObject["successes"] = successCount
            }
            if let failureCount = result.breakdown.failureCount {
                jsonObject["failures"] = failureCount
            }
            
        case .keepDrop:
            if let keptRolls = result.breakdown.keptRolls {
                jsonObject["kept_rolls"] = keptRolls
            }
            if let droppedRolls = result.breakdown.droppedRolls {
                jsonObject["dropped_rolls"] = droppedRolls
            }
            
        case .exploding, .compoundExploding:
            if let explodedRolls = result.breakdown.explodedRolls {
                jsonObject["exploded_rolls"] = explodedRolls.map { explodedRoll in
                    [
                        "original_roll": explodedRoll.originalRoll,
                        "additional_rolls": explodedRoll.additionalRolls,
                        "total_value": explodedRoll.totalValue
                    ]
                }
            }
            
        default:
            break
        }
        
        return jsonObject
    }
    
    /// Format a table evaluation result as JSON
    /// - Parameter result: The table evaluation result
    /// - Returns: JSON object representation
    public static func formatTableEvaluationAsJSONObject(_ result: TableEvaluationResult) -> [String: Any] {
        var jsonObject: [String: Any] = [
            "type": "table_evaluation",
            "final_result": result.finalResult,
            "depth": result.depth,
            "primary_result": formatTableResult(result.primaryResult)
        ]
        
        if !result.nestedResults.isEmpty {
            jsonObject["nested_results"] = result.nestedResults.map { formatTableEvaluationAsJSONObject($0) }
        }
        
        return jsonObject
    }
    
    /// Format multiple results as a JSON array
    /// - Parameter results: Array of dice results
    /// - Returns: JSON array representation
    public static func formatMultipleAsJSONObject(_ results: [DiceResult]) -> [[String: Any]] {
        return results.map { formatAsJSONObject($0) }
    }
    
    // MARK: - Private Helper Methods
    
    private static func formatBreakdown(_ breakdown: DiceBreakdown) -> [String: Any] {
        var breakdownObject: [String: Any] = [
            "original_rolls": breakdown.originalRolls
        ]
        
        if let modifiedRolls = breakdown.modifiedRolls {
            breakdownObject["modified_rolls"] = modifiedRolls
        }
        
        if let explodedRolls = breakdown.explodedRolls {
            breakdownObject["exploded_rolls"] = explodedRolls.map { explodedRoll in
                [
                    "original_roll": explodedRoll.originalRoll,
                    "additional_rolls": explodedRoll.additionalRolls,
                    "total_value": explodedRoll.totalValue
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
    
    private static func formatTaggedResults(_ taggedResults: [String: DiceResult]) -> [String: Any] {
        var results: [String: Any] = [:]
        
        for (tag, result) in taggedResults {
            results[tag] = formatAsJSONObject(result)
        }
        
        return results
    }
    
    private static func formatTableResult(_ tableResult: TableResult) -> [String: Any] {
        var result: [String: Any] = [
            "table_name": tableResult.tableName,
            "roll": tableResult.roll,
            "result": tableResult.result
        ]
        
        if let nestedResults = tableResult.nestedResults {
            result["nested_results"] = nestedResults.map { formatTableResult($0) }
        }
        
        return result
    }
}

// MARK: - Convenience Extensions

extension DiceResult {
    
    /// Convert this result to JSON data
    /// - Returns: JSON data representation
    /// - Throws: Encoding errors
    public func toJSON() throws -> Data {
        return try ResultFormatter.formatAsJSON(self)
    }
    
    /// Convert this result to a JSON string
    /// - Returns: JSON string representation
    /// - Throws: Encoding errors
    public func toJSONString() throws -> String {
        return try ResultFormatter.formatAsJSONString(self)
    }
    
    /// Convert this result to a JSON object
    /// - Returns: JSON object representation
    public func toJSONObject() -> [String: Any] {
        return ResultFormatter.formatAsJSONObject(self)
    }
}

extension TableEvaluationResult {
    
    /// Convert this result to JSON data
    /// - Returns: JSON data representation
    /// - Throws: Encoding errors
    public func toJSON() throws -> Data {
        let jsonObject = ResultFormatter.formatTableEvaluationAsJSONObject(self)
        return try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
    }
    
    /// Convert this result to a JSON string
    /// - Returns: JSON string representation
    /// - Throws: Encoding errors
    public func toJSONString() throws -> String {
        let data = try toJSON()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Convert this result to a JSON object
    /// - Returns: JSON object representation
    public func toJSONObject() -> [String: Any] {
        return ResultFormatter.formatTableEvaluationAsJSONObject(self)
    }
}

// MARK: - Batch Formatting

extension Array where Element == DiceResult {
    
    /// Convert array of results to JSON data
    /// - Returns: JSON array data
    /// - Throws: Encoding errors
    public func toJSON() throws -> Data {
        let jsonArray = ResultFormatter.formatMultipleAsJSONObject(self)
        return try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
    }
    
    /// Convert array of results to JSON string
    /// - Returns: JSON array string
    /// - Throws: Encoding errors
    public func toJSONString() throws -> String {
        let data = try toJSON()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Convert array of results to JSON object array
    /// - Returns: Array of JSON objects
    public func toJSONObjectArray() -> [[String: Any]] {
        return ResultFormatter.formatMultipleAsJSONObject(self)
    }
}

// MARK: - Summary Formatting

extension ResultFormatter {
    
    /// Create a summary format for quick display
    /// - Parameter result: The dice result to summarize
    /// - Returns: Human-readable summary string
    public static func formatSummary(_ result: DiceResult) -> String {
        switch result.type {
        case .standard, .arithmetic:
            return "Result: \(result.total)"
            
        case .pool:
            if let successCount = result.breakdown.successCount {
                return "Pool: \(successCount) successes"
            }
            return "Pool: \(result.total)"
            
        case .keepDrop:
            if let keptRolls = result.breakdown.keptRolls {
                return "Keep/Drop: \(keptRolls) = \(result.total)"
            }
            return "Keep/Drop: \(result.total)"
            
        case .exploding, .compoundExploding:
            return "Exploding: \(result.total)"
            
        case .tagged:
            return "Tagged: \(result.total)"
            
        case .table:
            return "Table: \(result.total)"
        }
    }
    
    /// Create a detailed breakdown format
    /// - Parameter result: The dice result to detail
    /// - Returns: Detailed breakdown string
    public static func formatDetailed(_ result: DiceResult) -> String {
        var details = formatSummary(result)
        
        details += "\nBreakdown:"
        details += "\n  Original rolls: \(result.breakdown.originalRolls)"
        
        if let modifiedRolls = result.breakdown.modifiedRolls {
            details += "\n  Modified rolls: \(modifiedRolls)"
        }
        
        if let explodedRolls = result.breakdown.explodedRolls {
            details += "\n  Exploded rolls:"
            for exploded in explodedRolls {
                details += "\n    \(exploded.originalRoll) → \(exploded.additionalRolls) (total: \(exploded.totalValue))"
            }
        }
        
        if let keptRolls = result.breakdown.keptRolls {
            details += "\n  Kept rolls: \(keptRolls)"
        }
        
        if let droppedRolls = result.breakdown.droppedRolls {
            details += "\n  Dropped rolls: \(droppedRolls)"
        }
        
        if let successCount = result.breakdown.successCount {
            details += "\n  Successes: \(successCount)"
        }
        
        if let failureCount = result.breakdown.failureCount {
            details += "\n  Failures: \(failureCount)"
        }
        
        if let modifierDescription = result.breakdown.modifierDescription {
            details += "\n  Modifier: \(modifierDescription)"
        }
        
        return details
    }
}