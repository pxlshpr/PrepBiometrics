import Foundation

struct SchofieldCoefficients {
    static func a(sexIsFemale: Bool, ageGroup: AgeGroup) -> Double {
        switch sexIsFemale {
        case true:
            switch ageGroup {
            case .zeroToTwo:
                return 58.317
            case .threeToNine:
                return 20.315
            case .tenToSeventeen:
                return 13.384
            case .eighteenToTwentyNine:
                return 14.818
            case .thirtyToFiftyNine:
                return 8.126
            case .sixtyAndOver:
                return 9.082
            }
        default:
            switch ageGroup {
            case .zeroToTwo:
                return 59.512
            case .threeToNine:
                return 22.706
            case .tenToSeventeen:
                return 17.686
            case .eighteenToTwentyNine:
                return 15.057
            case .thirtyToFiftyNine:
                return 11.472
            case .sixtyAndOver:
                return 11.711
            }
        }
    }
    
    static func c(sexIsFemale: Bool, ageGroup: AgeGroup) -> Double {
        switch sexIsFemale {
        case true:
            switch ageGroup {
            case .zeroToTwo:
                return -31.1
            case .threeToNine:
                return 485.9
            case .tenToSeventeen:
                return 692.6
            case .eighteenToTwentyNine:
                return 486.6
            case .thirtyToFiftyNine:
                return 845.6
            case .sixtyAndOver:
                return 658.5
            }
        default:
            switch ageGroup {
            case .zeroToTwo:
                return -30.4
            case .threeToNine:
                return 504.3
            case .tenToSeventeen:
                return 658.2
            case .eighteenToTwentyNine:
                return 692.2
            case .thirtyToFiftyNine:
                return 873.1
            case .sixtyAndOver:
                return 587.7
            }
        }
    }
}
