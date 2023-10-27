import SwiftUI
import PrepShared

extension BiometricsStore {
    static func updateHealthBiometrics() {
        //TODO: Replace this task with something else
//        updateHealthBiometricsTask?.cancel()
//        updateHealthBiometricsTask = Task(priority: .utility) {
//            let start = CFAbsoluteTimeGetCurrent()
//            
//            try await updateCurrentHealthBiometrics()
//            try await updatePastPlansUsingHealthBiometrics()
//
//            print("Done in: \(CFAbsoluteTimeGetCurrent()-start)s")
//            print("We here")
//        }
    }
}

extension BiometricsStore {
    
    static func updateCurrentHealthBiometrics() async throws {
        
        /// Set the date to `.now` so that we retrieve the most recent results
        current.biometrics.date = Date.now
        try await current.updateHealthValues()

        /// Now retrieve and persist the updated biometrics
        let biometrics = current.biometrics
        try await PrivateStore.setBiometrics(biometrics, for: Date.now)
        
        /// Send a notification of its change
        await MainActor.run { [biometrics] in
            post(.didSaveBiometrics, [
                .isCurrentBiometrics: true,
                .biometrics: biometrics
            ])
        }

        /// Update our plans with them
        try await PlansStore.updatePlans(with: biometrics)
    }
    
    static func updatePastPlansUsingHealthBiometrics() async throws {
        
        /// Go through all the past days with plans using health biometrics
        /// *Note: We won't be redundantly updating the biometrics for days without a plan as they're not in use and querying HealthKit, especially for average vaalues takes time*
        for day in try await pastDaysWithPlansUsingHealthBiometrics() {
            
            guard let biometrics = day.biometrics, let plan = day.plan else {
                continue
            }
            
            var updatedBiometrics = biometrics
            /// Sanity check to ensure date in biometrics is the day is belongs to (so that correct health values are fetched)
            updatedBiometrics.date = day.date
            
            /// Create a `BiometricsStore` with the biometrics (which includes the date its for)
            let biometricsStore = BiometricsStore(biometrics: biometrics)
            
            /// Update its health values, while preserving existing values of any biometrics that can't be fetched
            try await biometricsStore.updateHealthValues()
            updatedBiometrics = biometricsStore.biometrics

            /// Skip any that weren't modified
            guard !updatedBiometrics.matches(biometrics) else { continue }
            
            await MainActor.run { [updatedBiometrics] in
                post(.didSaveBiometrics, [
                    .isCurrentBiometrics: false,
                    .biometrics: updatedBiometrics
                ])
            }
            
            /// Persist the biometrics against the `Day` it belongs to
            try await PrivateStore.setBiometrics(updatedBiometrics, for: day.date)

            /// Update the plan with the updated biometrics
            let updatedPlan = plan.updatedPlan(with: updatedBiometrics)
            
            /// Skip any plans that haven't changed
            guard updatedPlan != plan else { continue }

            /// Persist the plan agains the `Day` it belongs to
            try await PrivateStore.setPlan(updatedPlan, for: day.date)

            await MainActor.run { [updatedPlan] in
                post(.didUpdatePlan, [
                    .date: day.date,
                    .plan: updatedPlan
                ])
            }
        }
    }
}

extension BiometricsStore {

    static func pastDaysWithPlansUsingHealthBiometrics() async throws -> [Day] {
        var days: [Day] = []
        try await PrivateStore.performInBackground { context in
            
            /// Fetch all the `DayEntity`s that have biometrics data, sorted in descending order
            let predicate = NSPredicate(format: "biometricsData != nil")
            let sortDescriptors = [NSSortDescriptor(keyPath: \DayEntity.dateString, ascending: false)]
            
            days = DayEntity.entities(
                in: context,
                predicate: predicate,
                sortDescriptors: sortDescriptors
            ).filter {
                /// Filter out only days that have past
                guard let date = $0.date, date.startOfDay < Date.now.startOfDay
                else {
                    return false
                }
                /// Filter out only days with biometrics that use health
                guard let biometrics = $0.biometrics, biometrics.usesHealth else {
                    return false
                }
                /// Filter out only days that have a plan that uses health values in the biometrics
                guard let plan = $0.plan, plan.usesHealthValues(in: biometrics) else {
                    return false
                }
                return true
            }.map { Day($0) }
        }
        return days
    }
}
