import Foundation

public extension DateComponents {
    var age: Int? {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.year, .month, .day], from: Date())
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year
    }
}
