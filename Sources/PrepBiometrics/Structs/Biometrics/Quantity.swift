import Foundation

public struct Quantity: Hashable, Codable {
    public var value: Double
    public var date: Date?
    
    public init(value: Double, date: Date? = nil) {
        self.value = value
        self.date = date
    }
}
