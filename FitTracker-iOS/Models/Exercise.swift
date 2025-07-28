import Foundation

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    let difficulty: ExerciseDifficulty
    let instructions: [String]
    let tips: [String]
    let alternatives: [String]
}

enum ExerciseDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct WorkoutExercise: Identifiable, Codable {
    let id: String
    let exerciseId: String
    var sets: [WorkoutSet]
    var notes: String?
    let targetSets: Int
    let targetReps: Int
    let targetWeight: Double
}

struct WorkoutSet: Identifiable, Codable {
    let id: String
    var reps: Int
    var weight: Double
    var restTime: Int?
    var completed: Bool
    var rpe: Int? // Rate of Perceived Exertion (1-10)
}

struct Workout: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date
    var exercises: [WorkoutExercise]
    var duration: TimeInterval?
    var completed: Bool
    var notes: String?
}

struct ProgressionSuggestion {
    let type: ProgressionType
    let currentValue: Double
    let suggestedValue: Double
    let reason: String
}

enum ProgressionType {
    case weight
    case reps
    case sets
}