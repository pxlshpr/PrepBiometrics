import SwiftUI
import CoreData
import OSLog

import PrepShared

private let logger = Logger(subsystem: "Settings Store", category: "")

public typealias SettingsFetchHandler = (() async throws -> Settings)
public typealias SettingsSaveHandler = ((Settings) async throws -> ())

@Observable public class SettingsStore {
    
//    static let shared = SettingsStore()
//    static var energyUnit: EnergyUnit { shared.energyUnit }

    public var settings: Settings = .default {
        didSet {
            settingsDidChange(from: oldValue)
        }
    }

    var fetchHandler: SettingsFetchHandler
    var saveHandler: SettingsSaveHandler

    public init(
        fetchHandler: @escaping SettingsFetchHandler,
        saveHandler: @escaping SettingsSaveHandler
    ) {
        self.fetchHandler = fetchHandler
        self.saveHandler = saveHandler
        fetchSettings()
    }
    
    func fetchSettings() {
        Task {
//            let settings = try await Self.fetchOrCreateSettings()
            let settings = try await fetchHandler()
            await MainActor.run {
                self.settings = settings
            }
        }
    }
    
//    static func fetchOrCreateSettings() async throws -> Settings {
//        try await PrivateStore.fetchOrCreateSettings()
//    }
    
    func settingsDidChange(from old: Settings) {
        if old != settings {
            save()
        }
    }
}

public extension SettingsStore {
    
    var energyUnit: EnergyUnit {
        get { settings.energyUnit }
        set {
            settings.energyUnit = newValue
        }
    }

    var metricType: GoalMetricType {
        get { settings.metricType }
        set {
            withAnimation {
                settings.metricType = newValue
            }
        }
    }

    var expandedMicroGroups: [MicroGroup] {
        get { settings.expandedMicroGroups }
        set {
            withAnimation {
                settings.expandedMicroGroups = newValue
            }
        }
    }
    
    //MARK: Units
    
    var heightUnit: HeightUnit {
        get { settings.heightUnit }
        set {
            settings.heightUnit = newValue
        }
    }
    
    var bodyMassUnit: BodyMassUnit {
        get { settings.bodyMassUnit }
        set {
            settings.bodyMassUnit = newValue
        }
    }
}


public extension SettingsStore {
    
    func save() {
        Task.detached(priority: .background) {
            try await self.saveHandler(self.settings)
//            try await PrivateStore.saveSettings(self.settings)
        }
    }
}

import HealthKit

//extension SettingsStore {
//    static func unit(for type: QuantityType) -> HKUnit {
//        switch type {
//        case .weight, .leanBodyMass:
//            shared.settings.bodyMassUnit.healthKitUnit
//        case .height:
//            shared.settings.heightUnit.healthKitUnit
//        case .restingEnergy, .activeEnergy:
//            shared.settings.energyUnit.healthKitUnit
//        }
//    }
//}
