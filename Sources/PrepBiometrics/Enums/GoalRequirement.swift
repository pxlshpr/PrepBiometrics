import Foundation

public enum GoalRequirement {
    case maintenanceEnergy
    case leanMass
    case weight
    case energyGoal
    case workoutDuration
}

public extension GoalRequirement {
    
    var message: String {
        switch self {
        case .maintenanceEnergy:
            return "Set Maintenance Energy"
        case .leanMass:
            return "Set Lean Body Mass"
        case .weight:
            return "Set Weight"
        case .energyGoal:
            return "Set Energy Goal"
        case .workoutDuration:
            return "Calculated when used"
        }
    }
    
    var description: String {
        switch self {
        case .maintenanceEnergy:
            return "maintenance"
        case .leanMass:
            return "lean body mass"
        case .weight:
            return "body weight"
        case .energyGoal:
            return "energy goal"
        case .workoutDuration:
//            return "workout duration"
            return "exercise"
        }
    }
    
    var isBiometric: Bool {
        self != .workoutDuration
    }
    
    var systemImage: String {
        switch self {
        case .maintenanceEnergy:
            return "flame.fill"
        case .leanMass, .weight:
            return "figure.arms.open"
        case .energyGoal:
            return "flame.fill"
        case .workoutDuration:
            return "figure.run"
        }
    }
}
