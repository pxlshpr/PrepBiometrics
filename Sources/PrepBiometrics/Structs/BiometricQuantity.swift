import Foundation

public struct BiometricQuantity: Hashable, Codable {
    public var source: BiometricSource
    public var quantity: Quantity?
    
    public init(source: BiometricSource, quantity: Quantity? = nil) {
        self.source = source
        self.quantity = quantity
    }
}

public extension BiometricQuantity {
    
    mutating func removeDateIfNotNeeded() {
        switch source {
        case .health:       break
        case .userEntered:  quantity?.date = nil
        }
    }
}
