import Foundation
import PrepShared

public enum HealthPeriod: Int16, Codable, CaseIterable {
    case day = 1
    case week
    case month
}

public extension HealthPeriod {
    var range: ClosedRange<Int> {
        minValue...maxValue
    }
}

public extension HealthPeriod {
    
    var name: String {
        switch self {
        case .day:      "day"
        case .week:     "week"
        case .month:    "month"
        }
    }
    
    var minValue: Int {
        switch self {
        case .day:  2
        default:    1
        }
    }
    var maxValue: Int {
        switch self {
        case .day:      6
        case .week:     3
        case .month:    12
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:      .day
        case .month:    .month
        case .week:     .weekOfMonth
        }
    }

    func dateRangeOfPast(_ value: Int, to date: Date = Date()) -> ClosedRange<Date>? {
        
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        let endDate = startOfDay

        guard let startDate = calendar.date(
            byAdding: calendarComponent,
            value: -value,
            to: endDate
        ) else {
            return nil
        }

        return startDate.moveDayBy(-1)...endDate.moveDayBy(-1)
    }
}

extension HealthPeriod: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: HealthPeriod { .week }
}
