import HealthKit
import PrepShared

public extension EnergyUnit {
    var healthKitUnit: HKUnit {
        switch self {
        case .kcal:
            return .kilocalorie()
        case .kJ:
            return .jouleUnit(with: .kilo)
        }
    }
}
