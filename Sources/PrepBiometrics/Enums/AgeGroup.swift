import Foundation

public enum AgeGroup {
    case zeroToTwo
    case threeToNine
    case tenToSeventeen
    case eighteenToTwentyNine
    case thirtyToFiftyNine
    case sixtyAndOver
    
    public init(_ age: Int) {
        switch age {
        case 0..<3:
            self = .zeroToTwo
        case 3..<9:
            self = .threeToNine
        case 10..<17:
            self = .tenToSeventeen
        case 18..<29:
            self = .eighteenToTwentyNine
        case 30..<59:
            self = .thirtyToFiftyNine
        default:
            self = .sixtyAndOver
        }
    }
}

