import Foundation
import PrepShared

public enum ActiveEnergySource: Int16, Codable, CaseIterable {
    case health = 1
    case activityLevel
    case userEntered
}

extension ActiveEnergySource: Pickable {
    
    public var pickedTitle: String {
        switch self {
        case .health:           "Health app"
        case .activityLevel:    "Activity level"
        case .userEntered:      "Entered manually"
        }
    }
    
    public var menuTitle: String { pickedTitle }
    
    public var menuImage: String {
        switch self {
        case .health:           "heart.fill"
        case .activityLevel:    "dial.medium.fill"
        case .userEntered:      ""
        }
    }
    
    public static var `default`: ActiveEnergySource { .activityLevel }
}
