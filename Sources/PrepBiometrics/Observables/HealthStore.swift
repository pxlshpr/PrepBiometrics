import HealthKit
import PrepShared

public class HealthStore {
    
    internal static let shared = HealthStore()
    internal static let store: HKHealthStore = HKHealthStore()
    internal var updateBiometricsTask: Task<Void, Error>? = nil
    
    public static var defaultUnitHandler: ((QuantityType) -> HKUnit)? = nil
}

extension HealthStore {
    
    static func latestQuantity(for type: QuantityType, using unit: HKUnit? = nil) async -> Quantity? {
        do {
            try await requestPermission(for: type)
            return try await latestQuantity(
                for: type,
                using: unit ?? defaultUnitHandler?(type),
                excludingToday: false
            )
        } catch {
            return nil
        }
    }
    
    static func biologicalSex_legacy() async -> HKBiologicalSex? {
        do {
            try await requestPermission(for: .biologicalSex)
            return try store.biologicalSex().biologicalSex
        } catch {
            return nil
        }
    }
    
    static func dateOfBirthComponents_legacy() async -> DateComponents? {
        do {
            try await requestPermission(for: .dateOfBirth)
            return try store.dateOfBirthComponents()
        } catch {
            return nil
        }
    }
    
    static func requestPermissions(
        characteristicTypeIdentifiers: [CharacteristicType] = [],
        quantityTypes: [QuantityType] = []
    ) async throws {
        try await requestPermissions(
            characteristicTypeIdentifiers: characteristicTypeIdentifiers.map { $0.healthType },
            quantityTypeIdentifiers: quantityTypes.map { $0.healthKitTypeIdentifier })
    }
}

extension HealthStore {
    static func latestQuantity(for type: QuantityType, using heightUnit: HeightUnit? = nil) async -> Quantity? {
        await latestQuantity(for: type, using: heightUnit?.healthKitUnit)
    }
    
    static func latestQuantity(for type: QuantityType, using bodyMassUnit: BodyMassUnit? = nil) async -> Quantity? {
        await latestQuantity(for: type, using: bodyMassUnit?.healthKitUnit)
    }
}

//MARK: - Quantities

extension QuantityType {
    var defaultUnit: HKUnit {
        switch self {
        case .weight:           .gramUnit(with: .kilo)
        case .leanBodyMass:     .gramUnit(with: .kilo)
        case .height:           .meterUnit(with: .centi)
        case .restingEnergy:    .kilocalorie()
        case .activeEnergy:     .kilocalorie()
        }
    }
}

private extension HealthStore {

    static func latestQuantity(
        for type: QuantityType,
        using unit: HKUnit?,
        excludingToday: Bool
    ) async throws -> Quantity? {
        do {
            let sample = try await latestQuantitySample(
                for: type.healthKitTypeIdentifier,
                excludingToday: excludingToday
            )
            let unit = unit ?? type.defaultUnit
            let quantity = sample.quantity.doubleValue(for: unit)
            let date = sample.startDate
            return Quantity(
                value: quantity,
                date: date
            )
        } catch {
            //TODO: This might be an indiciator of needing permissions
            print("Error getting quantity")
            return nil
        }
    }
    
    static func latestQuantitySample(
        for typeIdentifier: HKQuantityTypeIdentifier,
        excludingToday: Bool = false
    ) async throws -> HKQuantitySample {
        
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        
        let predicate: NSPredicate?
        if excludingToday {
            predicate = NSPredicate(format: "startDate < %@", Date().startOfDay as NSDate)
        } else {
            predicate = nil
        }
        let samplePredicates = [HKSamplePredicate.quantitySample(type: type, predicate: predicate)]
        let sortDescriptors: [SortDescriptor<HKQuantitySample>] = [SortDescriptor(\.startDate, order: .reverse)]
        let limit = 1
        
        let asyncQuery = HKSampleQueryDescriptor(
            predicates: samplePredicates,
            sortDescriptors: sortDescriptors,
            limit: limit
        )

        let results = try await asyncQuery.result(for: store)
        guard let sample = results.first else {
            throw HealthStoreError.couldNotGetSample
        }
        return sample
    }
}

//MARK: - Permissions
internal extension HealthStore {
    static func requestPermission(for type: QuantityType) async throws {
        try await requestPermissions(quantityTypeIdentifiers: [type.healthKitTypeIdentifier])
    }
    
    static func requestPermission(for characteristicType: HKCharacteristicTypeIdentifier) async throws {
        try await requestPermissions(characteristicTypeIdentifiers: [characteristicType])
    }

    static func requestPermissions(
        characteristicTypeIdentifiers: [HKCharacteristicTypeIdentifier] = [],
        quantityTypeIdentifiers: [HKQuantityTypeIdentifier] = []
    ) async throws {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthStoreError.healthKitNotAvailable
        }
        
        var readTypes: [HKObjectType] = []
        readTypes.append(contentsOf: quantityTypeIdentifiers.compactMap { HKQuantityType($0) })
        readTypes.append(contentsOf: characteristicTypeIdentifiers.compactMap { HKCharacteristicType($0) } )

        do {
            try await store.requestAuthorization(toShare: Set(), read: Set(readTypes))
        } catch {
            throw HealthStoreError.permissionsError(error)
        }
    }
}
