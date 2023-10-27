import SwiftUI
import OSLog
import HealthKit
import CoreData

import PrepShared

@Observable public class BiometricsStore {

    public let isCurrent: Bool
    public var ignoreChanges: Bool = false
    
    public static var updateHealthBiometricsTask: Task<Void, Error>? = nil

    internal let logger = Logger(subsystem: "BiometricsStore", category: "")
    internal var saveBiometricsTask: Task<Void, Error>? = nil
    
    var currentBiometricsHandler: (() async throws -> Biometrics)? = nil
    var saveHandler: ((Biometrics, Bool) async throws -> ())
    
    public var biometrics: Biometrics {
        didSet {
            guard !ignoreChanges else { return }
            handleChanges(from: oldValue)
        }
    }

    /// Current Biometrics
    public init(
        currentBiometricsHandler: (@escaping () async throws -> Biometrics),
        saveHandler: (@escaping (Biometrics, Bool) async throws -> ())
    ) {
        self.currentBiometricsHandler = currentBiometricsHandler
        self.saveHandler = saveHandler
        self.biometrics = Biometrics()
        self.isCurrent = true
        loadCurrentBiometrics(currentBiometricsHandler)
    }
    
    /// Past Biometrics
    public init(
        biometrics: Biometrics,
        saveHandler: (@escaping (Biometrics, Bool) async throws -> ())
    ) {
        self.currentBiometricsHandler = nil
        self.saveHandler = saveHandler
        self.biometrics = biometrics
        self.isCurrent = false
    }

    public func loadCurrentBiometrics(_ currentBiometricsHandler: (() async throws -> Biometrics)? = nil) {
        guard let currentBiometricsHandler else { return }
        Task {
            let biometrics = try await currentBiometricsHandler()
            await MainActor.run {
                self.biometrics = biometrics
            }
        }
    }
}

public extension BiometricsStore {

    func updateHealthValues() async throws {
        /// Set the model to ignore changes so that it doesn't redudantly fetch biometrics twice (in `handleChanges`)
        ignoreChanges = true

        try await setBiometricsFromHealth()

        /// Now turn off this flag so that manual user changes are handled appropriately
        ignoreChanges = false
    }
}

//MARK: - Set Units

public extension BiometricsStore {
    func setHeightUnit(_ newValue: HeightUnit, whileEditing type: BiometricType? = nil) {
        
        Task {
            switch heightSource {
            case .health:
                try await setHeightFromHealth(using: newValue)
            case .userEntered:
                await MainActor.run {
                    if type != .height, let value = biometrics.height?.quantity?.value {
                        let converted = biometrics.heightUnit.convert(value, to: newValue)
                        biometrics.height?.quantity?.value = converted
                    }
                }
            }
            
            await MainActor.run {
                biometrics.heightUnit = newValue
            }
        }
    }

    func setEnergyUnit(_ newValue: EnergyUnit, whileEditing type: BiometricType? = nil) {
        
        Task {
            switch restingEnergySource {
            case .health:
                try await setRestingEnergyFromHealth(using: newValue)
            case .equation:
                break
            case .userEntered:
                //TODO: Convert
                break
//                await MainActor.run {
//                    if type != .weight, let value = biometrics.weight?.quantity?.value {
//                        let converted = bodyMassUnit.convert(value, to: newValue)
//                        biometrics.weight?.quantity?.value = converted
//                    }
//                }
            }
            
            switch activeEnergySource {
            case .health:
                try await setActiveEnergyFromHealth(using: newValue)
            case .activityLevel:
                break
            case .userEntered:
                //TODO: Convert
                break
//                await MainActor.run {
//                    if type != .leanBodyMass, let value = biometrics.leanBodyMass?.quantity?.value {
//                        let converted = bodyMassUnit.convert(value, to: newValue)
//                        biometrics.leanBodyMass?.quantity?.value = converted
//                    }
//                }
            }
            
            await MainActor.run {
                biometrics.energyUnit = newValue
            }
        }
    }
    
    func setBodyMassUnit(_ newValue: BodyMassUnit, whileEditing type: BiometricType? = nil) {
        
        Task {
            switch weightSource {
            case .health:
                try await setWeightFromHealth(using: newValue)
            case .userEntered:
                await MainActor.run {
                    if type != .weight, let value = biometrics.weight?.quantity?.value {
                        let converted = biometrics.bodyMassUnit.convert(value, to: newValue)
                        biometrics.weight?.quantity?.value = converted
                    }
                }
            }
            
            switch leanBodyMassSource {
            case .health:
                try await setLeanBodyMassFromHealth(using: newValue)
            case .equation, .fatPercentage:
                break
            case .userEntered:
                await MainActor.run {
                    if type != .leanBodyMass, let value = biometrics.leanBodyMass?.quantity?.value {
                        let converted = biometrics.bodyMassUnit.convert(value, to: newValue)
                        biometrics.leanBodyMass?.quantity?.value = converted
                    }
                }
            }
            
            await MainActor.run {
                biometrics.bodyMassUnit = newValue
            }
        }
    }
}

//MARK: - Bindings

public extension BiometricsStore {
    
    var restingEnergyUnit: EnergyUnit {
        get { biometrics.energyUnit }
        set { setEnergyUnit(newValue, whileEditing: .restingEnergy) }
    }

    var activeEnergyUnit: EnergyUnit {
        get { biometrics.energyUnit }
        set { setEnergyUnit(newValue, whileEditing: .activeEnergy) }
    }

    var biometricsWeightUnit: BodyMassUnit {
        get { biometrics.bodyMassUnit }
        set { setBodyMassUnit(newValue, whileEditing: .weight) }
    }
    
    var biometricsHeightUnit: HeightUnit {
        get { biometrics.heightUnit }
        set { setHeightUnit(newValue, whileEditing: .height) }
    }
    
    var biometricsLeanBodyMassUnit: BodyMassUnit {
        get { biometrics.bodyMassUnit }
        set { setBodyMassUnit(newValue, whileEditing: .leanBodyMass) }
    }
    
    //MARK: Interval Types
    
    var restingEnergyIntervalType: HealthIntervalType {
        get { biometrics.restingEnergyIntervalType }
        set {
            Task {
                await MainActor.run {
                    biometrics.restingEnergyIntervalType = newValue
                }
                try await setRestingEnergyFromHealth()
            }
        }
    }
    
    var activeEnergyIntervalType: HealthIntervalType {
        get { biometrics.activeEnergyIntervalType }
        set {
            Task {
                await MainActor.run {
                    biometrics.activeEnergyIntervalType = newValue
                }
                try await setActiveEnergyFromHealth()
            }
        }
    }

    //MARK: Interval Periods
    
    var restingEnergyIntervalPeriod: HealthPeriod {
        get { biometrics.restingEnergyIntervalPeriod }
        set {
            Task {
                await MainActor.run {
                    biometrics.restingEnergyIntervalPeriod = newValue
                }
                try await setRestingEnergyFromHealth()
            }
        }
    }

    var activeEnergyIntervalPeriod: HealthPeriod {
        get { biometrics.activeEnergyIntervalPeriod }
        set {
            Task {
                await MainActor.run {
                    biometrics.activeEnergyIntervalPeriod = newValue
                }
                try await setActiveEnergyFromHealth()
            }
        }
    }

    //MARK: Interval Value
    
    var restingEnergyIntervalValue: Int {
        get { biometrics.restingEnergyIntervalValue }
        set {
            Task {
                await MainActor.run {
                    biometrics.restingEnergyIntervalValue = newValue
                }
                try await setRestingEnergyFromHealth()
            }
        }
    }

    var activeEnergyIntervalValue: Int {
        get { biometrics.activeEnergyIntervalValue }
        set {
            Task {
                await MainActor.run {
                    biometrics.activeEnergyIntervalValue = newValue
                }
                try await setActiveEnergyFromHealth()
            }
        }
    }
    
    //MARK: Sources
    
    var ageSource: AgeSource {
        get { biometrics.ageSource }
        set {
            Task {
                await MainActor.run {
                    biometrics.ageSource = newValue
                }
                if newValue == .health {
                    try await setAgeFromHealth()
                }
//                if newValue != .userEnteredDateOfBirth {
//                    biometrics.ageDateOfBirth = nil
//                }
            }
        }
    }
    
    var sexSource: BiometricSource {
        get { biometrics.sexSource }
        set {
            Task {
                await MainActor.run {
                    biometrics.sexSource = newValue
                }
                if newValue == .health {
                    try await setSexFromHealth()
                }
            }
        }
    }

    var weightSource: BiometricSource {
        get { biometrics.weightSource }
        set {
            Task {
                await MainActor.run {
                    biometrics.weightSource = newValue
                }
                if newValue == .health {
                    try await setWeightFromHealth()
                }
            }
        }
    }

    var heightSource: BiometricSource {
        get { biometrics.heightSource }
        set {
            Task {
                await MainActor.run {
                    biometrics.heightSource = newValue
                }
                if newValue == .health {
                    try await setHeightFromHealth()
                }
            }
        }
    }

    var leanBodyMassSource: LeanBodyMassSource {
        get { biometrics.leanBodyMassSource }
        set {
            Task {
                await MainActor.run {
                    biometrics.leanBodyMassSource = newValue
                }
                switch leanBodyMassSource {
                case .health:
                    try await setLeanBodyMassFromHealth()
                case .equation, .fatPercentage, .userEntered:
                    break
                }
            }
        }
    }

    var restingEnergySource: RestingEnergySource {
        get { biometrics.restingEnergySource }
        set {
            Task {
                await MainActor.run {
                    biometrics.restingEnergySource = newValue
                }
                switch restingEnergySource {
                case .health:
                    try await setRestingEnergyFromHealth()
                case .equation, .userEntered:
                    break
                }
            }
        }
    }
    
    var activeEnergySource: ActiveEnergySource {
        get { biometrics.activeEnergySource }
        set {
            Task {
                await MainActor.run {
                    biometrics.activeEnergySource = newValue
                }
                switch activeEnergySource {
                case .health:
                    try await setActiveEnergyFromHealth()
                case .activityLevel, .userEntered:
                    break
                }
            }
        }
    }
    
    //MARK: Equations
    
    var leanBodyMassEquation: LeanBodyMassEquation {
        get { biometrics.leanBodyMassEquation }
        set { biometrics.leanBodyMassEquation = newValue }
    }

    var restingEnergyEquation: RestingEnergyEquation {
        get { biometrics.restingEnergyEquation }
        set { biometrics.restingEnergyEquation = newValue }
    }

    var activeEnergyActivityLevel: ActivityLevel {
        get { biometrics.activeEnergyActivityLevel }
        set { biometrics.activeEnergyActivityLevel = newValue }
    }

    //MARK: Texts
    
    var leanBodyMassBiometricsLinkTitle: String {
        if leanBodyMassSource.params.count == 1, let param = leanBodyMassSource.params.first {
            param.name
        } else {
            "Biometrics"
        }
    }

    //MARK: Values
    
    var restingEnergyValue: Double {
        get { biometrics.restingEnergyValue ?? 0 }
        set { biometrics.restingEnergyValue = newValue }
    }

    var activeEnergyValue: Double {
        get { biometrics.activeEnergyValue ?? 0 }
        set { biometrics.activeEnergyValue = newValue }
    }

    var ageValue: Int {
        get { biometrics.ageValue ?? 0 }
        set { biometrics.ageValue = newValue }
    }

    var sexValue: BiometricSex? {
        get { biometrics.sexValue }
        set { biometrics.sexValue = newValue }
    }
    
    var weightValue: Double {
        get { biometrics.weightQuantity?.value ?? 0 }
        set { biometrics.weightQuantity = .init(value: newValue) }
    }
    
    var weightStonesComponent: Int {
        get { Int(weightValue.whole) }
        set {
            let value = Double(newValue) + (weightPoundsComponent / PoundsPerStone)
            biometrics.weightQuantity = .init(value: value)
        }
    }
    
    var weightPoundsComponent: Double {
        get { weightValue.fraction * PoundsPerStone }
        set {
            let newValue = min(newValue, PoundsPerStone-1)
            let value = Double(weightStonesComponent) + (newValue / PoundsPerStone)
            biometrics.weightQuantity = .init(value: value)
        }
    }
    
    var leanBodyMassValue: Double {
        get { biometrics.leanBodyMassQuantity?.value ?? 0 }
        set { biometrics.leanBodyMassQuantity = .init(value: newValue) }
    }

    var fatPercentageValue: Double {
        get { biometrics.fatPercentage ?? 0 }
        set { biometrics.fatPercentage = newValue }
    }

    var leanBodyMassStonesComponent: Int {
        get { Int(leanBodyMassValue.whole) }
        set {
            let value = Double(newValue) + (leanBodyMassPoundsComponent / PoundsPerStone)
            biometrics.leanBodyMassQuantity = .init(value: value)
        }
    }
    
    var leanBodyMassPoundsComponent: Double {
        get { leanBodyMassValue.fraction * PoundsPerStone }
        set {
            let newValue = min(newValue, PoundsPerStone-1)
            let value = Double(leanBodyMassStonesComponent) + (newValue / PoundsPerStone)
            biometrics.leanBodyMassQuantity = .init(value: value)
        }
    }
    
    var heightValue: Double {
        get { biometrics.heightQuantity?.value ?? 0 }
        set { biometrics.heightQuantity = .init(value: newValue) }
    }
    
    var heightFeetComponent: Int {
        get { Int(heightValue.whole) }
        set {
            let value = Double(newValue) + (heightCentimetersComponent / InchesPerFoot)
            biometrics.heightQuantity = .init(value: value)
        }
    }
    
    var heightCentimetersComponent: Double {
        get { heightValue.fraction * InchesPerFoot }
        set {
            let newValue = min(newValue, InchesPerFoot-1)
            let value = Double(heightFeetComponent) + (newValue / InchesPerFoot)
            biometrics.heightQuantity = .init(value: value)
        }
    }
}

public extension BiometricsStore {
    var activeEnergyInterval: HealthInterval? {
        get { biometrics.activeEnergy?.interval }
        set { }
    }
    var restingEnergyInterval: HealthInterval? {
        get { biometrics.restingEnergy?.interval }
        set { }
    }
}

//MARK: - Texts

//extension BiometricsStore {
//    var weightText: some View {
//        biometrics.weightText
//    }
//    
//    var leanBodyMassText: some View {
//        biometrics.leanBodyMassText
//    }
//    
//    var heightText: some View {
//        biometrics.heightText
//    }
//}
