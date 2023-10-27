import Foundation
import PrepShared

public extension DayEntity {
    var biometrics: Biometrics? {
        get {
            guard let biometricsData else { return nil }
            do {
                return try JSONDecoder().decode(Biometrics.self, from: biometricsData)
            } catch {
                /// Error decoding, so set to nil
                self.biometricsData = nil
                return nil
            }
        }
        set {
            guard let newValue else {
                self.biometricsData = nil
                return
            }
            self.biometricsData = try! JSONEncoder().encode(newValue)
        }
    }
}
