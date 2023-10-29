import HealthKit
import PrepShared

struct HealthKitQuantityRequest {
    let quantityType: QuantityType
    let healthKitUnit: HKUnit
    let date: Date
    
    init(
        _ type: QuantityType,
        _ unit: HKUnit,
        _ date: Date
    ) {
        self.quantityType = type
        self.healthKitUnit = unit
        self.date = date
    }
    
    var typeIdentifier: HKQuantityTypeIdentifier { quantityType.healthKitTypeIdentifier }

    func requestPersmissions() async throws {
        try await HealthStore.requestPermissions(quantityTypeIdentifiers: [typeIdentifier])
    }

    func mostRecentOrEarliestAvailable() async throws -> Quantity? {
        guard let mostRecent = try await mostRecent() else {
            return try await earliestAvailable()
        }
        return mostRecent
    }

    func mostRecent() async throws -> Quantity? {
        try await firstSample(
            matching: NSPredicate(format: "startDate <= %@", date as NSDate),
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
    }
    
    func earliestAvailable() async throws -> Quantity? {
        try await firstSample(
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
    }
    
    func firstSample(
        matching predicate: NSPredicate? = nil,
        sortDescriptors: [SortDescriptor<HKQuantitySample>]
    ) async throws -> Quantity? {
        try await requestPersmissions()

        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let samplePredicates = [HKSamplePredicate.quantitySample(type: type, predicate: predicate)]
        let limit = 1
        
        let asyncQuery = HKSampleQueryDescriptor(
            predicates: samplePredicates,
            sortDescriptors: sortDescriptors,
            limit: limit
        )

        let results = try await asyncQuery.result(for: HealthStore.store)
        guard let sample = results.first else {
            return nil
        }
        
        let quantity = sample.quantity.doubleValue(for: healthKitUnit)
        let date = sample.startDate
        return Quantity(value: quantity, date: date)
    }
    
}
