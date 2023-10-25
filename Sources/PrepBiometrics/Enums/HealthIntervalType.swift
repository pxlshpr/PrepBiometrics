import Foundation
import PrepShared

public enum HealthIntervalType: Int16, Codable, CaseIterable {
    case average = 1
    case sameDay
    case previousDay
}

extension HealthIntervalType: Pickable {

    public var pickedTitle: String {
        switch self {
        case .average:      "Daily average"
        case .sameDay:      "Same day"
        case .previousDay:  "Previous day"
        }
    }
    
    public var menuTitle: String {
        pickedTitle
    }
    
    public static var `default`: HealthIntervalType { .average }
}
