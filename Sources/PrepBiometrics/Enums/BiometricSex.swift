import Foundation
import PrepShared

public enum BiometricSex: Int16, Codable, CaseIterable {
    case female = 1
    case male
    case notSpecified
}

public extension BiometricSex {
    
    var name: String {
        switch self {
        case .female:   "Female"
        case .male:     "Male"
        case .notSpecified: "Not specified"
        }
    }
}

import HealthKit

extension BiometricSex: Pickable {
    public var pickedTitle: String { self.name }
    public var menuTitle: String { self.name }
    public static var `default`: BiometricSex { .notSpecified }
    public static var noneOption: BiometricSex? { .notSpecified }
}

public extension BiometricSex {
    var hkBiologicalSex: HKBiologicalSex {
        switch self {
        case .female:       .female
        case .male:         .male
        default:            .other
        }
    }
}

public extension HKBiologicalSex {
    var biometricSex: BiometricSex? {
        switch self {
        case .female:   .female
        case .male:     .male
        case .other:    .notSpecified
        default:        nil
        }
    }
}
