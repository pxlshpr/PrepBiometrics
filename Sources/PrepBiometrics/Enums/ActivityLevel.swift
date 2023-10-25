import Foundation
import PrepShared

public enum ActivityLevel: Int16, Codable, Hashable, CaseIterable {
    
    case notSet = 1
    case sedentary
    case lightlyActive
    case moderatelyActive
    case active
    case veryActive
}

public extension ActivityLevel {
    
    var name: String {
        switch self {
        case .notSet:           return "Do not use"
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly active"
        case .moderatelyActive: return "Moderately active"
        case .active:           return "Active"
        case .veryActive:       return "Very active"
        }
    }
    
    var scaleFactor: Double {
        switch self {
        case .notSet:           return 1
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .active:           return 1.725
        case .veryActive:       return 1.9
        }
    }
}

extension ActivityLevel: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: ActivityLevel { .sedentary }
}
