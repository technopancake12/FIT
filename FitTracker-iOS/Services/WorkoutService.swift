import Foundation
import CoreData

class WorkoutService: ObservableObject {
    static let shared = WorkoutService()
    
    @Published private var workouts: [Workout] = []
    @Published private var currentWorkout: Workout?
    
    private init() {
        loadWorkouts()
    }
    
    // MARK: - Workout Management
    
    func startWorkout(name: String, exercises: [WorkoutExercise]) -> Workout {
        let workout = Workout(
            id: UUID().uuidString,
            name: name,
            date: Date(),
            exercises: exercises,
            duration: nil,
            completed: false,
            notes: nil
        )
        
        currentWorkout = workout
        return workout
    }
    
    func updateSet(workoutId: String, exerciseIndex: Int, setIndex: Int, data: WorkoutSet) {
        guard let workout = currentWorkout, workout.id == workoutId else { return }
        
        guard exerciseIndex < workout.exercises.count,
              setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        var updatedWorkout = workout
        updatedWorkout.exercises[exerciseIndex].sets[setIndex] = data
        currentWorkout = updatedWorkout
        
        saveCurrentWorkout()
    }
    
    func completeWorkout() {
        guard var workout = currentWorkout else { return }
        
        workout.completed = true
        workout.duration = Date().timeIntervalSince(workout.date)
        
        workouts.append(workout)
        currentWorkout = nil
        
        saveWorkouts()
        
        // Send notification
        NotificationCenter.default.post(name: .workoutCompleted, object: workout)
    }
    
    func getCurrentWorkout() -> Workout? {
        return currentWorkout
    }
    
    // MARK: - Workout History
    
    func getWorkoutHistory() -> [Workout] {
        return workouts.filter { $0.completed }.sorted { $0.date > $1.date }
    }
    
    func getAllWorkouts() -> [Workout] {
        return workouts.sorted { $0.date > $1.date }
    }
    
    func getWorkoutsForDate(_ date: Date) -> [Workout] {
        return workouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date)
        }
    }
    
    func getWorkoutStats() -> WorkoutStats {
        let completedWorkouts = getWorkoutHistory()
        let totalWorkouts = completedWorkouts.count
        
        let totalVolume = completedWorkouts.reduce(0.0) { total, workout in
            total + workout.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.completed ? Double(set.reps) * set.weight : 0)
                }
            }
        }
        
        let thisWeek = completedWorkouts.filter { workout in
            Calendar.current.isDate(workout.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        
        let streak = calculateWorkoutStreak()
        
        return WorkoutStats(
            totalWorkouts: totalWorkouts,
            totalVolume: totalVolume,
            workoutsThisWeek: thisWeek,
            currentStreak: streak
        )
    }
    
    // MARK: - Exercise History & Progression
    
    func getExerciseHistory(for exerciseId: String) -> ExerciseHistory {
        let workoutHistory = getWorkoutHistory().compactMap { workout -> ExerciseHistoryEntry? in
            guard let exercise = workout.exercises.first(where: { $0.exerciseId == exerciseId }) else {
                return nil
            }
            
            let completedSets = exercise.sets.filter { $0.completed }
            let volume = completedSets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
            let maxWeight = completedSets.max { $0.weight < $1.weight }?.weight ?? 0
            
            return ExerciseHistoryEntry(
                date: workout.date,
                sets: completedSets,
                volume: volume,
                maxWeight: maxWeight
            )
        }
        
        return ExerciseHistory(exerciseId: exerciseId, workouts: workoutHistory)
    }
    
    func getProgressionSuggestion(for exerciseId: String, currentSets: Int, currentReps: Int, currentWeight: Double) -> ProgressionSuggestion {
        let history = getExerciseHistory(for: exerciseId)
        
        if history.workouts.count < 3 {
            return ProgressionSuggestion(
                type: .weight,
                currentValue: currentWeight,
                suggestedValue: currentWeight + 2.5,
                reason: "Progressive overload - increase weight gradually"
            )
        }
        
        let lastThreeWorkouts = Array(history.workouts.suffix(3))
        let averageReps = lastThreeWorkouts.reduce(0.0) { total, entry in
            let avgReps = entry.sets.reduce(0) { $0 + $1.reps } / entry.sets.count
            return total + Double(avgReps)
        } / Double(lastThreeWorkouts.count)
        
        if averageReps >= Double(currentReps + 2) {
            return ProgressionSuggestion(
                type: .weight,
                currentValue: currentWeight,
                suggestedValue: currentWeight + 5,
                reason: "Consistently exceeding target reps - time to increase weight"
            )
        }
        
        if averageReps < Double(currentReps - 2) {
            return ProgressionSuggestion(
                type: .reps,
                currentValue: Double(currentReps),
                suggestedValue: Double(max(currentReps - 1, 5)),
                reason: "Focus on form and building strength at current weight"
            )
        }
        
        return ProgressionSuggestion(
            type: .weight,
            currentValue: currentWeight,
            suggestedValue: currentWeight + 2.5,
            reason: "Standard progressive overload"
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateWorkoutStreak() -> Int {
        let sortedWorkouts = getWorkoutHistory()
        
        guard !sortedWorkouts.isEmpty else { return 0 }
        
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for workout in sortedWorkouts {
            let daysDiff = calendar.dateComponents([.day], from: workout.date, to: currentDate).day ?? 0
            
            if daysDiff <= 1 {
                streak += 1
                currentDate = workout.date
            } else if daysDiff <= 2 && streak == 0 {
                streak += 1
                currentDate = workout.date
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func loadWorkouts() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "savedWorkouts"),
           let decodedWorkouts = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decodedWorkouts
        }
        
        if let data = UserDefaults.standard.data(forKey: "currentWorkout"),
           let decodedWorkout = try? JSONDecoder().decode(Workout.self, from: data) {
            currentWorkout = decodedWorkout
        }
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: "savedWorkouts")
        }
    }
    
    private func saveCurrentWorkout() {
        if let workout = currentWorkout,
           let encoded = try? JSONEncoder().encode(workout) {
            UserDefaults.standard.set(encoded, forKey: "currentWorkout")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentWorkout")
        }
    }
}

// MARK: - Supporting Types

struct WorkoutStats {
    let totalWorkouts: Int
    let totalVolume: Double
    let workoutsThisWeek: Int
    let currentStreak: Int
}

struct ExerciseHistory {
    let exerciseId: String
    let workouts: [ExerciseHistoryEntry]
}

struct ExerciseHistoryEntry {
    let date: Date
    let sets: [WorkoutSet]
    let volume: Double
    let maxWeight: Double
}

// MARK: - Notifications

extension Notification.Name {
    static let workoutCompleted = Notification.Name("workoutCompleted")
    static let workoutStarted = Notification.Name("workoutStarted")
    static let setCompleted = Notification.Name("setCompleted")
}