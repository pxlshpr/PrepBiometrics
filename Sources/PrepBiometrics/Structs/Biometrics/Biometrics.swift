import Foundation
import HealthKit
import PrepShared

public struct Biometrics: Hashable, Codable {
    
    public var date: Date
    public var energyUnit: EnergyUnit
    public var heightUnit: HeightUnit
    public var bodyMassUnit: BodyMassUnit
    
    public var restingEnergy: RestingEnergy?
    public var activeEnergy: ActiveEnergy?
    public var age: Age?
    public var sex: Sex?
    public var weight: BiometricQuantity?
    public var height: BiometricQuantity?
    public var leanBodyMass: LeanBodyMass?
    public var fatPercentage: Double?
    
    public var updatedAt: Date
    
    public init(
        date: Date = Date.now,
        energyUnit: EnergyUnit = .default,
        heightUnit: HeightUnit = .default,
        bodyMassUnit: BodyMassUnit = .default,
        restingEnergy: RestingEnergy? = nil,
        activeEnergy: ActiveEnergy? = nil,
        age: Age? = nil,
        sex: Sex? = nil,
        weight: BiometricQuantity? = nil,
        height: BiometricQuantity? = nil,
        leanBodyMass: LeanBodyMass? = nil,
        fatPercentage: Double? = nil,
        updatedAt: Date = Date.now
    ) {
        self.date = date
        self.energyUnit = energyUnit
        self.heightUnit = heightUnit
        self.bodyMassUnit = bodyMassUnit
        self.restingEnergy = restingEnergy
        self.activeEnergy = activeEnergy
        self.age = age
        self.sex = sex
        self.weight = weight
        self.height = height
        self.leanBodyMass = leanBodyMass
        self.fatPercentage = fatPercentage
        self.updatedAt = updatedAt
    }
}

public extension Biometrics {
    /// Checks that everything except `date` and `updatedAt` match
    func matches(_ other: Biometrics) -> Bool {
        energyUnit == other.energyUnit
        && heightUnit == other.heightUnit
        && bodyMassUnit == other.bodyMassUnit
        && restingEnergy == other.restingEnergy
        && activeEnergy == other.activeEnergy
        && age == other.age
        && sex == other.sex
        && weight == other.weight
        && height == other.height
        && leanBodyMass == other.leanBodyMass
        && fatPercentage == other.fatPercentage
    }
}

public extension Biometrics {
    var usesHealth: Bool {
        restingEnergy?.source == .health
        || activeEnergy?.source == .health
        || age?.source == .health
        || sex?.source == .health
        || weight?.source == .health
        || height?.source == .health
        || leanBodyMass?.source == .health
    }
}

public extension RestingEnergyEquation {
    func usesHealth(in biometrics: Biometrics) -> Bool {
        for param in self.params {
            switch param {
            case .sex:
                if biometrics.usesHealthForSex { return true }
            case .age:
                if biometrics.usesHealthForAge { return true }
            case .weight:
                if biometrics.usesHealthForWeight { return true }
            case .leanBodyMass:
                if biometrics.usesHealthForLeanBodyMass { return true }
            case .height:
                if biometrics.usesHealthForHeight { return true }
            default:
                /// Remaining biometric types are not possible parameters
                continue
            }
        }
        return false
    }
}

public extension LeanBodyMassEquation {
    func usesHealth(in biometrics: Biometrics) -> Bool {
        for param in self.params {
            switch param {
            case .sex:
                if biometrics.usesHealthForSex { return true }
            case .weight:
                if biometrics.usesHealthForWeight { return true }
            case .height:
                if biometrics.usesHealthForHeight { return true }
            default:
                /// Remaining biometric types are not possible parameters
                continue
            }
        }
        return false
    }
}

public extension Biometrics {
    var usesHealthForRestingEnergy: Bool {
        switch restingEnergySource {
        case .equation:     restingEnergyEquation.usesHealth(in: self)
        case .health:       true
        case .userEntered:  false
        }
    }
    
    var usesHealthForActiveEnergy: Bool {
        switch activeEnergySource {
        case .health:                       true
        case .activityLevel, .userEntered:  false
        }
    }

    var usesHealthForMaintenanceEnergy: Bool {
        usesHealthForRestingEnergy || usesHealthForActiveEnergy
    }
    
    var usesHealthForWeight: Bool { weightSource == .health }
    var usesHealthForHeight: Bool { heightSource == .health }
    var usesHealthForSex: Bool { sexSource == .health }
    var usesHealthForAge: Bool { ageSource == .health }

    var usesHealthForLeanBodyMass: Bool {
        switch leanBodyMassSource {
        case .equation:         leanBodyMassEquation.usesHealth(in: self)
        case .fatPercentage:    usesHealthForWeight
        case .health:           true
        case .userEntered:      false
        }
    }
}

public extension Biometrics {
    
    struct RestingEnergy: Hashable, Codable {
        public var source: RestingEnergySource
        public var equation: RestingEnergyEquation?
        public var interval: HealthInterval?
        public var value: Double?
        
        public init(
            source: RestingEnergySource,
            equation: RestingEnergyEquation? = nil,
            interval: HealthInterval? = nil,
            value: Double? = nil
        ) {
            self.source = source
            switch source {
            case .health:
                self.equation = nil
                self.interval = interval ?? .default
            case .equation:
                self.equation = equation ?? .default
                self.interval = nil
            case .userEntered:
                self.equation = nil
                self.interval = nil
            }
            self.value = value
        }
    }
    
    struct ActiveEnergy: Hashable, Codable {
        public var source: ActiveEnergySource
        public var activityLevel: ActivityLevel?
        public var interval: HealthInterval?
        public var value: Double?
        
        public init(
            source: ActiveEnergySource,
            activityLevel: ActivityLevel? = nil,
            interval: HealthInterval? = nil,
            value: Double? = nil
        ) {
            self.source = source
            
            switch source {
            case .health:
                self.activityLevel = nil
                self.interval = interval ?? .default
            case .activityLevel:
                self.activityLevel = activityLevel ?? .default
                self.interval = nil
            case .userEntered:
                self.activityLevel = nil
                self.interval = nil
            }
            
            self.value = value
        }
    }
    
    struct Age: Hashable, Codable {
        public var source: AgeSource
        public var dateOfBirthComponents: DateComponents?
        public var value: Int?
        
        public init(
            source: AgeSource,
            dateOfBirthComponents: DateComponents? = nil,
            value: Int? = nil
        ) {
            self.source = source
            self.dateOfBirthComponents = dateOfBirthComponents
            self.value = value
        }
        
        public var dateOfBirth: Date? {
            get {
                guard let dateOfBirthComponents else { return nil }
                var components = dateOfBirthComponents
                components.hour = 0
                components.minute = 0
                components.second = 0
                return Calendar.current.date(from: components)
            }
            set {
                guard let newValue else {
                    dateOfBirthComponents = nil
                    return
                }
                dateOfBirthComponents = Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: newValue
                )
            }
        }
    }

    struct Sex: Hashable, Codable {
        public var source: BiometricSource
        public var value: BiometricSex?
    }

    struct LeanBodyMass: Hashable, Codable {
        public var source: LeanBodyMassSource
        public var equation: LeanBodyMassEquation?
        public var quantity: Quantity?
        
        public init(
            source: LeanBodyMassSource,
            equation: LeanBodyMassEquation? = nil,
            quantity: Quantity? = nil
        ) {
            self.source = source
            switch source {
            case .health:
                self.equation = nil
            case .equation:
                self.equation = equation ?? .default
            case .fatPercentage:
                self.equation = nil
            case .userEntered:
                self.equation = nil
            }
            self.quantity = quantity
        }
    }
}

public extension Biometrics {
    var maintenanceEnergy: Double? {
        guard let activeEnergyValue, let restingEnergyValue else {
            return nil
        }
        return activeEnergyValue + restingEnergyValue
    }
    
    var maintenanceEnergyInKcal: Double? {
        guard let maintenanceEnergy else { return nil }
        return energyUnit.convert(maintenanceEnergy, to: .kcal)
    }
    
    var maintenanceEnergyFormatted: String {
        guard let maintenanceEnergy else { return "" }
        return maintenanceEnergy.formattedEnergy
    }
}

public extension Biometrics {
    
    func quantityTypesToSync(from old: Biometrics) -> [QuantityType] {
        var types: [QuantityType] = []
        if old.weightSource != .health, weightSource == .health {
            types.append(.weight)
        }
        if old.leanBodyMassSource != .health, leanBodyMassSource == .health {
            types.append(.leanBodyMass)
        }
        if old.heightSource != .health, heightSource == .health {
            types.append(.height)
        }
        if old.restingEnergySource != .health, restingEnergySource == .health {
            types.append(.restingEnergy)
        }
        if old.activeEnergySource != .health, activeEnergySource == .health {
            types.append(.activeEnergy)
        }
        return types
    }

    func characteristicTypesToSync(from old: Biometrics) -> [CharacteristicType] {
        var types: [CharacteristicType] = []
        if old.sexSource != .health, sexSource == .health {
            types.append(.sex)
        }
        if old.ageSource != .health, ageSource == .health {
            types.append(.dateOfBirth)
        }
        return types
    }
    
    mutating func cleanup() {
        weight?.removeDateIfNotNeeded()
    }
}

public extension Biometrics {
    func bodyMassValue(for type: BodyMassType, in unit: BodyMassUnit? = nil) -> Double? {
        let value: Double? = switch type {
        case .weight:   weight?.quantity?.value
        case .leanMass: leanBodyMass?.quantity?.value
        }
        
        guard let value else { return nil}
        
        return if let unit {
            bodyMassUnit.convert(value, to: unit)
        } else {
            value
        }
    }
}

//MARK: - Bindings

public extension Biometrics {
    
    //MARK: Interval Types
    
    var restingEnergyIntervalType: HealthIntervalType {
        get { restingEnergy?.interval?.intervalType ?? .default }
        set {
            restingEnergy?.interval?.intervalType = newValue
            switch newValue {
            case .average:
                cleanupRestingEnergyIntervalValue()
            case .previousDay:
                restingEnergy?.interval = .init(1, .day)
            case .sameDay:
                restingEnergy?.interval = .init(0, .day)
            }
        }
    }
    
    var activeEnergyIntervalType: HealthIntervalType {
        get { activeEnergy?.interval?.intervalType ?? .default }
        set {
            activeEnergy?.interval?.intervalType = newValue
            switch newValue {
            case .average:
                cleanupActiveEnergyIntervalValue()
            case .previousDay:
                activeEnergy?.interval = .init(1, .day)
            case .sameDay:
                activeEnergy?.interval = .init(0, .day)
            }
        }
    }
    
    //MARK: Interval Periods
    
    var restingEnergyIntervalPeriod: HealthPeriod {
        get { restingEnergy?.interval?.period ?? .default }
        set {
            restingEnergy?.interval?.period = newValue
            cleanupRestingEnergyIntervalValue()
        }
    }
    
    var activeEnergyIntervalPeriod: HealthPeriod {
        get { activeEnergy?.interval?.period ?? .default }
        set {
            activeEnergy?.interval?.period = newValue
            cleanupActiveEnergyIntervalValue()
        }
    }
    
    //MARK: Interval Value
    
    var restingEnergyIntervalValue: Int {
        get { restingEnergy?.interval?.value ?? 1 }
        set {
            guard newValue >= restingEnergyIntervalPeriod.minValue,
                  newValue <= restingEnergyIntervalPeriod.maxValue
            else { return }
            restingEnergy?.interval?.value = newValue
        }
    }
    
    var activeEnergyIntervalValue: Int {
        get { activeEnergy?.interval?.value ?? 1 }
        set {
            guard newValue >= activeEnergyIntervalPeriod.minValue,
                  newValue <= activeEnergyIntervalPeriod.maxValue
            else { return }
            activeEnergy?.interval?.value = newValue
        }
    }
    
    //MARK: Interval cleanup
    
    mutating func cleanupRestingEnergyIntervalValue() {
        restingEnergy?.interval?.correctIfNeeded()
    }
    
    mutating func cleanupActiveEnergyIntervalValue() {
        activeEnergy?.interval?.correctIfNeeded()
    }
    
    //MARK: Sources
    
    var ageSource: AgeSource {
        get { age?.source ?? .default }
        set {
            age = Age(source: newValue)
            //            guard age != nil else {
            //                age = Age(source: newValue)
            //                return
            //            }
            //            age?.source = newValue
        }
    }
    
    var sexSource: BiometricSource {
        get { sex?.source ?? .default }
        set {
            guard sex != nil else {
                sex = Sex(source: newValue)
                return
            }
            sex?.source = newValue
        }
    }
    
    var weightSource: BiometricSource {
        get { weight?.source ?? .default }
        set {
            guard weight != nil else {
                weight = BiometricQuantity(source: newValue)
                return
            }
            weight?.source = newValue
        }
    }
    
    var heightSource: BiometricSource {
        get { height?.source ?? .default }
        set {
            guard height != nil else {
                height = BiometricQuantity(source: newValue)
                return
            }
            height?.source = newValue
        }
    }
    
    var leanBodyMassSource: LeanBodyMassSource {
        get { leanBodyMass?.source ?? .default }
        set {
            guard leanBodyMass != nil else {
                leanBodyMass = LeanBodyMass(source: newValue)
                return
            }
            leanBodyMass?.source = newValue
            leanBodyMass?.equation = newValue == .equation ? .default : nil
        }
    }
    
    var restingEnergySource: RestingEnergySource {
        get { restingEnergy?.source ?? .default }
        set {
            guard restingEnergy != nil else {
                restingEnergy = RestingEnergy(source: newValue)
                return
            }
            restingEnergy?.source = newValue
            restingEnergy?.interval = newValue == .health ? .default : nil
            restingEnergy?.equation = newValue == .equation ? .default : nil
        }
    }
    
    var activeEnergySource: ActiveEnergySource {
        get { activeEnergy?.source ?? .default }
        set {
            guard activeEnergy != nil else {
                activeEnergy = ActiveEnergy(source: newValue)
                return
            }
            activeEnergy?.source = newValue
            activeEnergy?.interval = newValue == .health ? .default : nil
            activeEnergy?.activityLevel = newValue == .activityLevel ? .default : nil
        }
    }
    
    //MARK: Equations
    
    var restingEnergyEquation: RestingEnergyEquation {
        get { restingEnergy?.equation ?? .default }
        set {
            guard restingEnergy != nil else {
                restingEnergy = RestingEnergy(source: .equation, equation: newValue)
                return
            }
            restingEnergy?.equation = newValue
        }
    }
    
    var activeEnergyActivityLevel: ActivityLevel {
        get { activeEnergy?.activityLevel ?? .default }
        set {
            guard activeEnergy != nil else {
                activeEnergy = ActiveEnergy(source: .activityLevel, activityLevel: newValue)
                return
            }
            activeEnergy?.activityLevel = newValue
        }
    }
    
    var leanBodyMassEquation: LeanBodyMassEquation {
        get { leanBodyMass?.equation ?? .default }
        set {
            guard leanBodyMass != nil else {
                leanBodyMass = LeanBodyMass(source: .equation, equation: newValue)
                return
            }
            leanBodyMass?.equation = newValue
        }
    }
}

//MARK: Values

public extension Biometrics {
    
    var activeEnergyValue: Double? {
        get { activeEnergy?.value }
        set {
            guard activeEnergy != nil else {
                activeEnergy = ActiveEnergy(
                    source: .userEntered,
                    value: newValue
                )
                return
            }
            activeEnergy?.value = newValue
        }
    }
    
    var restingEnergyValue: Double? {
        get { restingEnergy?.value }
        set {
            guard restingEnergy != nil else {
                restingEnergy = RestingEnergy(
                    source: .userEntered,
                    value: newValue
                )
                return
            }
            restingEnergy?.value = newValue
        }
    }
    
    var ageValue: Int? {
        get { age?.value }
        set {
            guard age != nil else {
                age = Age(source: .userEnteredAge, value: newValue)
                return
            }
            age?.value = newValue
        }
    }

    var ageDateOfBirth: Date? {
        get { age?.dateOfBirth }
        set {
            guard let newValue else {
                age?.dateOfBirth = nil
                return
            }
            let components = Calendar.current.dateComponents([.year, .month, .day], from: newValue)
            age = Age(
                source: .userEnteredDateOfBirth,
                dateOfBirthComponents: components,
                value: components.age
            )
        }
    }

    var sexValue: BiometricSex? {
        get { sex?.value }
        set {
            guard sex != nil else {
                sex = Sex(source: .userEntered, value: newValue)
                return
            }
            sex?.value = newValue
        }
    }

    var weightQuantity: Quantity? {
        get { weight?.quantity }
        set {
            guard weight != nil else {
                weight = BiometricQuantity(
                    source: .userEntered,
                    quantity: newValue
                )
                return
            }
            weight?.quantity = newValue
        }
    }
    
    var heightQuantity: Quantity? {
        get { height?.quantity }
        set {
            guard height != nil else {
                height = BiometricQuantity(
                    source: .userEntered,
                    quantity: newValue
                )
                return
            }
            height?.quantity = newValue
        }
    }
    
    var leanBodyMassQuantity: Quantity? {
        get { leanBodyMass?.quantity }
        set {
            guard leanBodyMass != nil else {
                leanBodyMass = LeanBodyMass(
                    source: .userEntered,
                    quantity: newValue
                )
                return
            }
            leanBodyMass?.quantity = newValue
        }
    }
}

public extension Biometrics {
    var weightInKg: Double? {
        guard let value = weight?.quantity?.value else { return nil }
        return bodyMassUnit.convert(value, to: .kg)
    }

    var lbmInKg: Double? {
        guard let value = leanBodyMass?.quantity?.value else { return nil }
        return bodyMassUnit.convert(value, to: .kg)
    }

    var heightInCm: Double? {
        guard let value = height?.quantity?.value else { return nil }
        return heightUnit.convert(value, to: .cm)
    }
}

