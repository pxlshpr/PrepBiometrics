import SwiftUI
import PrepShared

//MARK: - Saving

//public extension BiometricsStore {
//    func save() async throws {
//            
//        try await privateStore.performInBackground { context in
//            /// Fetch the date to save against. Use the current date if this is the current biometrics in case the date has passed over to the next.
//            let date = self.isCurrent ? Date.now : self.biometrics.date
//            let dayEntity = self.privateStore.fetchOrCreateDayEntity(for: date, in: context)
//            dayEntity.biometrics = self.biometrics
//        }
//        
//        try Task.checkCancellation()
//
//        await MainActor.run {
//            post(.didSaveBiometrics, [
//                .isCurrentBiometrics: self.isCurrent,
//                .biometrics: self.biometrics
//            ])
//        }
//    }
//}

//MARK: - Handle Changes
public extension BiometricsStore {
    
    func handleChanges(from old: Biometrics) {
        guard !old.matches(biometrics) else {
            logger.debug("Biometrics set but did not change, ignoring")
            return
        }
        
        /// Use this for debugging as `self.biometrics` isn't always printable
//        let new = biometrics

        logger.debug("Biometrics changed, updating and saving")

        saveBiometricsTask?.cancel()
        saveBiometricsTask = Task {
            do {
                try await handleChanges(from: old)
                try Task.checkCancellation()
                try await saveHandler(biometrics, isCurrent)
            } catch is CancellationError {
                /// Task cancelled
                logger.debug("Task was cancelled")
            } catch {
                logger.error("Error updating biometrics: \(error.localizedDescription)")
            }
        }
    }
    
    func handleChanges(from old: Biometrics) async throws {
        
        /// Request for permissions
        let quantityTypes = biometrics.quantityTypesToSync(from: old)
        let characteristicTypeIdentifiers = biometrics.characteristicTypesToSync(from: old)
        if !quantityTypes.isEmpty || !characteristicTypeIdentifiers.isEmpty {
            try await HealthStore.requestPermissions(
                characteristicTypeIdentifiers: characteristicTypeIdentifiers,
                quantityTypes: quantityTypes
            )
            try Task.checkCancellation()
        }
        
        /// Trigger HealthKit syncs for any that were turned on
        if quantityTypes.contains(.weight) {
            try await setWeightFromHealth()
            try Task.checkCancellation()
        }
        if quantityTypes.contains(.leanBodyMass) {
            try await setLeanBodyMassFromHealth()
            try Task.checkCancellation()
        }
        if quantityTypes.contains(.height) {
            try await setHeightFromHealth()
            try Task.checkCancellation()
        }
        if characteristicTypeIdentifiers.contains(.sex) {
            try await setSexFromHealth()
            try Task.checkCancellation()
        }
        if characteristicTypeIdentifiers.contains(.dateOfBirth) {
            try await setAgeFromHealth()
            try Task.checkCancellation()
        }
        if quantityTypes.contains(.restingEnergy) {
            try await setRestingEnergyFromHealth()
            try Task.checkCancellation()
        }
        if quantityTypes.contains(.activeEnergy) {
            try await setActiveEnergyFromHealth()
            try Task.checkCancellation()
        }
        
        await MainActor.run {
            biometrics.recalculate()
        }
    }
    
    func setBiometricsFromHealth() async throws {
        if weightSource == .health {
            try await setWeightFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if leanBodyMassSource == .health {
            try await setLeanBodyMassFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if heightSource == .health {
            try await setHeightFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if sexSource == .health {
            try await setSexFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if ageSource == .health {
            try await setAgeFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if restingEnergySource == .health {
            try await setRestingEnergyFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        if activeEnergySource == .health {
            try await setActiveEnergyFromHealth(preservingExistingValue: !isCurrent)
            try Task.checkCancellation()
        }
        
        await MainActor.run {
            biometrics.recalculate()
        }
    }
}
