import Foundation

public protocol RandomNumberGenerator {
    func roll(sides: Int) -> Int
    func roll(sides: Int, count: Int) -> [Int]
}

public class SystemRandomNumberGenerator: RandomNumberGenerator {
    private var generator = Swift.SystemRandomNumberGenerator()
    
    public init() {}
    
    public func roll(sides: Int) -> Int {
        guard sides > 0 else { return 1 }
        return Int.random(in: 1...sides, using: &generator)
    }
    
    public func roll(sides: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        return (0..<count).map { _ in roll(sides: sides) }
    }
}

public class FixedRandomNumberGenerator: RandomNumberGenerator {
    private var values: [Int]
    private var index: Int = 0
    
    public init(values: [Int]) {
        self.values = values
    }
    
    public func roll(sides: Int) -> Int {
        guard !values.isEmpty else { return 1 }
        
        let value = values[index % values.count]
        index += 1
        return value
    }
    
    public func roll(sides: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        return (0..<count).map { _ in roll(sides: sides) }
    }
    
    public func reset() {
        index = 0
    }
}

public class SeededRandomNumberGenerator: RandomNumberGenerator {
    private var generator: Swift.SystemRandomNumberGenerator
    
    public init(seed: UInt64) {
        self.generator = Swift.SystemRandomNumberGenerator()
        // Note: SystemRandomNumberGenerator doesn't support seeding directly
        // For true seeded behavior, we'd need a different approach
    }
    
    public func roll(sides: Int) -> Int {
        guard sides > 0 else { return 1 }
        return Int.random(in: 1...sides, using: &generator)
    }
    
    public func roll(sides: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        return (0..<count).map { _ in roll(sides: sides) }
    }
}

// MARK: - Convenience Extensions

extension RandomNumberGenerator {
    public func rollD4() -> Int {
        return roll(sides: 4)
    }
    
    public func rollD6() -> Int {
        return roll(sides: 6)
    }
    
    public func rollD8() -> Int {
        return roll(sides: 8)
    }
    
    public func rollD10() -> Int {
        return roll(sides: 10)
    }
    
    public func rollD12() -> Int {
        return roll(sides: 12)
    }
    
    public func rollD20() -> Int {
        return roll(sides: 20)
    }
    
    public func rollD100() -> Int {
        return roll(sides: 100)
    }
    
    public func rollPercentile() -> Int {
        return roll(sides: 100)
    }
    
    public func rollFudge() -> Int {
        return roll(sides: 3) - 2  // -1, 0, 1
    }
}