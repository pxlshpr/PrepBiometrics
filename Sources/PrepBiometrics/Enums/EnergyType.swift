import HealthKit
import PrepShared

enum EnergyType {
    case resting
    case active

    var healthKitType: HKQuantityType {
        HKQuantityType(healthKitTypeIdentifier)
    }
    
    var healthKitTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .resting:  .basalEnergyBurned
        case .active:   .activeEnergyBurned
        }
    }
}
