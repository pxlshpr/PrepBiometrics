import Foundation
import PrepShared

public enum BiometricSource: Int16, Codable, CaseIterable {
    case health = 1
    case userEntered
}

public extension BiometricSource {
    var name: String {
        switch self {
        case .health:       "Health app"
        case .userEntered:  "Entered manually"
        }
    }
    
    var menuImage: String {
        switch self {
        case .health:       "heart.fill"
        case .userEntered:  ""
        }
    }
}

extension BiometricSource: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: BiometricSource { .userEntered }
}
