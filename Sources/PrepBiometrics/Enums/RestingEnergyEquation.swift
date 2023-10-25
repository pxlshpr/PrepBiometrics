import Foundation
import PrepShared

public enum RestingEnergyEquation: Int16, Hashable, Codable, CaseIterable {
    case katchMcardle = 1
    case henryOxford
    case mifflinStJeor
    case schofield
    case cunningham
    case rozaShizgal
    case harrisBenedict
}

extension RestingEnergyEquation: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: RestingEnergyEquation { .katchMcardle }
}

public extension RestingEnergyEquation {
    var name: String {
        switch self {
        case .schofield:        "Schofield"
        case .henryOxford:      "Henry Oxford"
        case .harrisBenedict:   "Harris-Benedict"
        case .cunningham:       "Cunningham"
        case .rozaShizgal:      "Roza-Shizgal"
        case .mifflinStJeor:    "Mifflin-St. Jeor"
        case .katchMcardle:     "Katch-McArdle"
        }
    }
    
    var year: String {
        switch self {
        case .schofield:        "1985"
        case .henryOxford:      "2005"
        case .harrisBenedict:   "1919"
        case .cunningham:       "1980"
        case .rozaShizgal:      "1984"
        case .mifflinStJeor:    "1990"
        case .katchMcardle:     "1996"
        }
    }
}

public extension RestingEnergyEquation {
    
    static var latest: [RestingEnergyEquation] {
        [.henryOxford, .katchMcardle, .mifflinStJeor, .schofield]
    }

    static var legacy: [RestingEnergyEquation] {
        [.rozaShizgal, .cunningham, .harrisBenedict]
    }

    
    var requiresHeight: Bool {
        switch self {
        case .henryOxford, .schofield, .katchMcardle, .cunningham:
            false
        default:
            true
        }
    }
   
    var usesLeanBodyMass: Bool {
        switch self {
        case .katchMcardle, .cunningham:
            true
        default:
            false
        }
    }

    var params: [BiometricType] {
        switch self {
        case .katchMcardle, .cunningham:
            [.leanBodyMass]
        case .henryOxford, .schofield:
            [.sex, .age, .weight]
        case .mifflinStJeor, .rozaShizgal, .harrisBenedict:
            [.sex, .age, .weight, .height]
        }
    }
}

public extension RestingEnergyEquation {
    func calculate(lbmInKg: Double, energyUnit: EnergyUnit) -> Double? {
        let kcal: Double? = switch self {
        case .katchMcardle: 370 + (21.6 * lbmInKg)
        case .cunningham:   500 + (22.0 * lbmInKg)
        default:            nil
        }
        guard let kcal else { return nil }
        let value = EnergyUnit.kcal.convert(kcal, to: energyUnit)
        return max(value, 0)
    }

    func calculate(age: Int, weightInKg: Double, sexIsFemale: Bool, energyUnit: EnergyUnit) -> Double? {
        let ageGroup = AgeGroup(age)
        let kcal: Double
        switch self {
            
        case .henryOxford:
            let a = OxfordCoefficients.a(sexIsFemale: sexIsFemale, ageGroup: ageGroup)
            let c = OxfordCoefficients.c(sexIsFemale: sexIsFemale, ageGroup: ageGroup)
            kcal = (a * weightInKg) + c
            
        case .schofield:
            let a = SchofieldCoefficients.a(sexIsFemale: sexIsFemale, ageGroup: ageGroup)
            let c = SchofieldCoefficients.c(sexIsFemale: sexIsFemale, ageGroup: ageGroup)
            kcal = (a * weightInKg) + c

        default:
            return nil
        }
        
        let value = EnergyUnit.kcal.convert(kcal, to: energyUnit)
        return max(value, 0)
    }
    
    func calculate(age: Int, weightInKg: Double, heightInCm: Double, sexIsFemale: Bool, energyUnit: EnergyUnit) -> Double? {
        let kcal: Double
        switch self {

        case .henryOxford:
            return calculate(age: age, weightInKg: weightInKg, sexIsFemale: sexIsFemale, energyUnit: energyUnit)
        case .schofield:
            return calculate(age: age, weightInKg: weightInKg, sexIsFemale: sexIsFemale, energyUnit: energyUnit)

        case .mifflinStJeor:
            if sexIsFemale {
                kcal = (9.99 * weightInKg) + (6.25 * heightInCm) - (4.92 * Double(age)) - 161
            } else {
                kcal = (9.99 * weightInKg) + (6.25 * heightInCm) - (4.92 * Double(age)) + 5
            }
            
        case .rozaShizgal:
            if sexIsFemale {
                kcal = 447.593 + (9.247 * weightInKg) + (3.098 * heightInCm) - (4.33 * Double(age))
            } else {
                kcal = 88.362 + (13.397 * weightInKg) + (4.799 * heightInCm) - (5.677 * Double(age))
            }

        case .harrisBenedict:
            if sexIsFemale {
                kcal = 655.0955 + (9.5634 * weightInKg) + (1.8496 * heightInCm) - (4.6756 * Double(age))
            } else {
                kcal = 66.4730 + (13.7516 * weightInKg) + (5.0033 * heightInCm) - (6.7550 * Double(age))
            }
            
        default:
            return nil
        }
        let value = EnergyUnit.kcal.convert(kcal, to: energyUnit)
        return max(value, 0)
    }
}
