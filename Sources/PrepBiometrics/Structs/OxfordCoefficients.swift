import Foundation

struct OxfordCoefficients {
    
    static func a(sexIsFemale: Bool, ageGroup: AgeGroup) -> Double {
        switch sexIsFemale {
        case true:
            switch ageGroup {
            case .zeroToTwo:
                return 58.9
            case .threeToNine:
                return 20.1
            case .tenToSeventeen:
                return 11.1
            case .eighteenToTwentyNine:
                return 13.1
            case .thirtyToFiftyNine:
                return 9.74
            case .sixtyAndOver:
                return 10.1
            }
        default:
            switch ageGroup {
            case .zeroToTwo:
                return 61.0
            case .threeToNine:
                return 23.3
            case .tenToSeventeen:
                return 18.4
            case .eighteenToTwentyNine:
                return 16.0
            case .thirtyToFiftyNine:
                return 14.2
            case .sixtyAndOver:
                return 13.5
            }
        }
    }
    
    static func c(sexIsFemale: Bool, ageGroup: AgeGroup) -> Double {
        switch sexIsFemale {
        case true:
            switch ageGroup {
            case .zeroToTwo:
                return -23.1
            case .threeToNine:
                return 507
            case .tenToSeventeen:
                return 761
            case .eighteenToTwentyNine:
                return 558
            case .thirtyToFiftyNine:
                return 694
            case .sixtyAndOver:
                return 569
            }
        default:
            switch ageGroup {
            case .zeroToTwo:
                return -33.7
            case .threeToNine:
                return 514
            case .tenToSeventeen:
                return 581
            case .eighteenToTwentyNine:
                return 545
            case .thirtyToFiftyNine:
                return 593
            case .sixtyAndOver:
                return 514
            }
        }
    }
}
