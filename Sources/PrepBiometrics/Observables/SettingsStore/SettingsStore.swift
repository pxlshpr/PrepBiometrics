import SwiftUI
import CoreData
import OSLog

import PrepShared

private let logger = Logger(subsystem: "Settings Store", category: "")

public typealias SettingsFetchHandler = (() async throws -> Settings)
public typealias SettingsSaveHandler = ((Settings) async throws -> ())

@Observable public class SettingsStore {
    
    public static let shared = SettingsStore()
    public static var energyUnit: EnergyUnit { shared.energyUnit }

    public var settings: Settings = .default {
        didSet {
            settingsDidChange(from: oldValue)
        }
    }

    var fetchHandler: SettingsFetchHandler? = nil
    var saveHandler: SettingsSaveHandler? = nil

    public init() { }

    func settingsDidChange(from old: Settings) {
        if old != settings {
            save()
        }
    }
}

public extension SettingsStore {
    
    static func configure(
        fetchHandler: @escaping SettingsFetchHandler,
        saveHandler: @escaping SettingsSaveHandler
    ) {
        shared.configure(fetchHandler: fetchHandler, saveHandler: saveHandler)
    }
    
    static func save() {
        shared.save()
    }
    
    static func fetch() {
        shared.fetch()
    }
}

extension SettingsStore {
    
    func configure(
        fetchHandler: @escaping SettingsFetchHandler,
        saveHandler: @escaping SettingsSaveHandler
    ) {
        self.fetchHandler = fetchHandler
        self.saveHandler = saveHandler
        fetch()
    }

    func save() {
        guard let saveHandler else { return }
        Task.detached(priority: .background) {
            try await saveHandler(self.settings)
        }
    }
    
    func fetch() {
        guard let fetchHandler else { return }
        Task {
            let settings = try await fetchHandler()
            await MainActor.run {
                self.settings = settings
            }
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

import HealthKit

public extension SettingsStore {
    
    static func unit(for type: QuantityType) -> HKUnit {
        switch type {
        case .weight, .leanBodyMass:
            shared.settings.bodyMassUnit.healthKitUnit
        case .height:
            shared.settings.heightUnit.healthKitUnit
        case .restingEnergy, .activeEnergy:
            shared.settings.energyUnit.healthKitUnit
        }
    }
}
