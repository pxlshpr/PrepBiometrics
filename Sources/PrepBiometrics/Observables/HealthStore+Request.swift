import HealthKit
import PrepShared

extension HealthStore {
    
    static func weight(
        in unit: BodyMassUnit = .kg,
        for date: Date = Date.now
    ) async throws -> Quantity? {
        try await HealthKitQuantityRequest(.weight, unit.healthKitUnit, date)
            .mostRecentOrEarliestAvailable()
    }

    static func leanBodyMass(
        in unit: BodyMassUnit = .kg,
        for date: Date = Date.now
    ) async throws -> Quantity? {
        try await HealthKitQuantityRequest(.leanBodyMass, unit.healthKitUnit, date)
            .mostRecentOrEarliestAvailable()
    }

    static func height(
        in unit: HeightUnit = .cm,
        for date: Date = Date.now
    ) async throws -> Quantity? {
        try await HealthKitQuantityRequest(.height, unit.healthKitUnit, date)
            .mostRecentOrEarliestAvailable()
    }

    static func biologicalSex() async throws -> HKBiologicalSex? {
        try await requestPermission(for: .biologicalSex)
        return try store.biologicalSex().biologicalSex
    }
    
    static func dateOfBirthComponents() async throws -> DateComponents? {
        try await requestPermission(for: .dateOfBirth)
        return try store.dateOfBirthComponents()
    }

    static func restingEnergy(
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal
    ) async throws -> Double {
        try await HealthKitEnergyRequest(.resting, unit, interval, date).dailyAverage()
    }
    
    static func activeEnergy(
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal
    ) async throws -> Double {
        try await HealthKitEnergyRequest(.active, unit, interval, date).dailyAverage()
    }
}

