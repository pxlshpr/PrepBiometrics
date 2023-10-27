import Foundation
import PrepShared

public extension Date {
    var calendarDayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        return dateFormatter.string(from: self).lowercased()
    }
}

public extension Date {
    var biometricShortFormat: String {
        let dayString: String
        var timeString = ""
        if Calendar.current.isDateInToday(self) {
            dayString = "Today"
            timeString = shortTime
        }
        else if Calendar.current.isDateInYesterday(self) {
            dayString = "Yesterday"
        }
        else if Calendar.current.isDateInTomorrow(self) {
            dayString = "Tomorrow"
        }
        else {
            let formatter = DateFormatter()
            let sameYear = year == Date().year
            formatter.dateFormat = sameYear ? "d MMM" : "d MMM yy"
            dayString = formatter.string(from: self)
        }
        if timeString.isEmpty {
            return dayString
        } else {
            return timeString
        }
    }

    var biometricFormat: String {
        let dayString: String
        var timeString = shortTime
        if Calendar.current.isDateInToday(self) { dayString = "Today" }
        else if Calendar.current.isDateInYesterday(self) { dayString = "Yesterday" }
        else if Calendar.current.isDateInTomorrow(self) { dayString = "Tomorrow" }
        else {
            let formatter = DateFormatter()
            let sameYear = year == Date().year
            formatter.dateFormat = sameYear ? "d MMM" : "d MMM yy"
            dayString = formatter.string(from: self)
            timeString = ""
        }
        if timeString.isEmpty {
            return dayString
        } else {
            return dayString + ", " + timeString
        }
    }
    
    var biometricEnergyFormat: String {
        let dayString: String
        if Calendar.current.isDateInToday(self) { dayString = "Today" }
        else if Calendar.current.isDateInYesterday(self) { dayString = "Yesterday" }
        else if Calendar.current.isDateInTomorrow(self) { dayString = "Tomorrow" }
        else {
            let formatter = DateFormatter()
            let sameYear = year == Date().year
            formatter.dateFormat = sameYear ? "d MMM" : "d MMM yy"
            dayString = formatter.string(from: self)
        }
        return dayString
    }
}

public extension ClosedRange<Date> {
    var description: String {
        "\(lowerBound.calendarDayString) to \(upperBound.calendarDayString)"
    }
    
    var days: [Date] {
        var days: [Date] = []
        let calendar = Calendar(identifier: .gregorian)
        calendar.enumerateDates(
            startingAfter: lowerBound,
            matching: DateComponents(hour: 0, minute: 0, second:0),
            matchingPolicy: .nextTime)
        { (date, _, stop) in
            guard let date = date, date <= upperBound else {
                stop = true
                return
            }
            days.append(date)
        }
        return days
    }
}
