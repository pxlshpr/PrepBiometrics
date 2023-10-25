import Foundation
import PrepShared

public enum BiometricType {
    case maintenanceEnergy
    case restingEnergy
    case activeEnergy
    case sex
    case age
    case weight
    case leanBodyMass
    case fatPercentage
    case height
}

public extension BiometricType {
    
    var usesPrecision: Bool {
        switch self {
        case .weight, .leanBodyMass, .fatPercentage, .height: true
        default: false
        }
    }
    
    var abbreviation: String {
        switch self {
        case .maintenanceEnergy:    "maintenance energy"
        case .restingEnergy:        "resting energy"
        case .activeEnergy:         "active energy"
        case .sex:                  "biological sex"
        case .age:                  "age"
        case .weight:               "weight"
        case .leanBodyMass:         "lean body mass"
        case .fatPercentage:        "fat %"
        case .height:               "height"
        }
    }
    
    var name: String {
        switch self {
        case .maintenanceEnergy:    "Maintenance Energy"
        case .restingEnergy:        "Resting Energy"
        case .activeEnergy:         "Active Energy"
        case .sex:                  "Biological Sex"
        case .age:                  "Age"
        case .weight:               "Weight"
        case .leanBodyMass:         "Lean Body Mass"
        case .fatPercentage:        "Fat Percentage"
        case .height:               "Height"
        }
    }

    var usesUnit: Bool {
        switch self {
        case .sex, .age, .fatPercentage: false
        default: true
        }
    }
    
    var systemImage: String? {
        switch self {
        case .restingEnergy: "bed.double.fill"
        case .activeEnergy: "figure.walk.motion"
        default: nil
        }
    }
}

public extension BodyMassType {
    var biometricType: BiometricType {
        switch self {
        case .weight:   .weight
        case .leanMass: .leanBodyMass
        }
    }
}
