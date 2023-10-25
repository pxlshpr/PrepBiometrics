import HealthKit

public enum QuantityType {
    case weight
    case leanBodyMass
    case height
    case restingEnergy
    case activeEnergy
}

public extension QuantityType {
    
    var healthKitTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .weight:           .bodyMass
        case .leanBodyMass:     .leanBodyMass
        case .height:           .height
        case .restingEnergy:    .basalEnergyBurned
        case .activeEnergy:     .activeEnergyBurned
        }
    }
}
