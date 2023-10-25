import Foundation
import PrepShared

public enum AgeSource: Int16, Codable, CaseIterable {
    case health = 1
    case userEnteredDateOfBirth
    case userEnteredAge
}

public extension AgeSource {
    var name: String {
        switch self {
        case .health:                   "Health app"
        case .userEnteredDateOfBirth:   "Date of birth"
        case .userEnteredAge:           "Entered manually"
        }
    }
    
    var menuImage: String {
        switch self {
        case .health:                   "heart.fill"
        case .userEnteredDateOfBirth:   "calendar"
        case .userEnteredAge:           ""
        }
    }
}

extension AgeSource: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: AgeSource { .userEnteredDateOfBirth }
}

