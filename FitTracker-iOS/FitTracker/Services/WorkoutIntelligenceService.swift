import Foundation

class WorkoutIntelligenceService: ObservableObject {
    static let shared = WorkoutIntelligenceService()
    
    private let firebaseManager = FirebaseManager.shared
    
    private init() {}
    
    // MARK: - Progressive Overload Suggestions
    func generateProgressiveOverloadSuggestion(
        for exercise: EnhancedWorkoutExercise,
        previousWorkouts: [EnhancedWorkout]
    ) -> ProgressiveOverloadSuggestion {
        
        let exerciseHistory = getExerciseHistory(exerciseId: exercise.exerciseId, from: previousWorkouts)
        
        guard !exerciseHistory.isEmpty else {
            return ProgressiveOverloadSuggestion(
                type: .maintain,
                suggestedWeight: exercise.sets.first?.weight ?? 0,
                suggestedReps: exercise.sets.first?.reps ?? 8,
                suggestedSets: exercise.sets.count,
                reason: "First time performing this exercise. Focus on proper form."
            )
        }
        
        let lastPerformance = exerciseHistory[0]
        let progressTrend = analyzeProgressTrend(exerciseHistory)
        
        return calculateNextProgression(
            currentPerformance: lastPerformance,
            trend: progressTrend,
            exerciseType: determineExerciseType(exercise.name)
        )
    }
    
    private func getExerciseHistory(
        exerciseId: String,
        from workouts: [EnhancedWorkout]
    ) -> [EnhancedWorkoutExercise] {
        return workouts
            .sorted { $0.date > $1.date }
            .compactMap { workout in
                workout.exercises.first { $0.exerciseId == exerciseId }
            }
            .prefix(5)
            .map { $0 }
    }
    
    private func analyzeProgressTrend(_ history: [EnhancedWorkoutExercise]) -> ProgressTrend {
        guard history.count >= 2 else { return .stable }
        
        let recent = history[0]
        let previous = history[1]
        
        let recentVolume = recent.totalVolume
        let previousVolume = previous.totalVolume
        
        let volumeIncrease = (recentVolume - previousVolume) / previousVolume
        
        if volumeIncrease > 0.1 {
            return .improving
        } else if volumeIncrease < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func calculateNextProgression(
        currentPerformance: EnhancedWorkoutExercise,
        trend: ProgressTrend,
        exerciseType: ExerciseType
    ) -> ProgressiveOverloadSuggestion {
        
        let currentWeight = currentPerformance.maxWeight
        let currentReps = currentPerformance.sets.map { $0.reps }.max() ?? 8
        let currentSets = currentPerformance.sets.count
        
        switch trend {
        case .improving:
            // Continue progression
            return suggestWeightIncrease(
                currentWeight: currentWeight,
                currentReps: currentReps,
                currentSets: currentSets,
                exerciseType: exerciseType
            )
            
        case .stable:
            // Try volume increase first, then weight
            if currentReps < 12 {
                return ProgressiveOverloadSuggestion(
                    type: .increaseReps,
                    suggestedWeight: currentWeight,
                    suggestedReps: min(currentReps + 2, 12),
                    suggestedSets: currentSets,
                    reason: "Increase reps to build volume before adding weight"
                )
            } else {
                return suggestWeightIncrease(
                    currentWeight: currentWeight,
                    currentReps: 8,
                    currentSets: currentSets,
                    exerciseType: exerciseType
                )
            }
            
        case .declining:
            // Reduce intensity, focus on volume
            return ProgressiveOverloadSuggestion(
                type: .deload,
                suggestedWeight: currentWeight * 0.9,
                suggestedReps: currentReps,
                suggestedSets: currentSets,
                reason: "Deload week - reduce weight by 10% to recover"
            )
        }
    }
    
    private func suggestWeightIncrease(
        currentWeight: Double,
        currentReps: Int,
        currentSets: Int,
        exerciseType: ExerciseType
    ) -> ProgressiveOverloadSuggestion {
        
        let increasePercentage: Double
        let newReps: Int
        
        switch exerciseType {
        case .compound:
            increasePercentage = 0.025 // 2.5%
            newReps = max(currentReps - 2, 6)
        case .isolation:
            increasePercentage = 0.05 // 5%
            newReps = max(currentReps - 1, 8)
        case .bodyweight:
            // For bodyweight, increase reps instead
            return ProgressiveOverloadSuggestion(
                type: .increaseReps,
                suggestedWeight: currentWeight,
                suggestedReps: currentReps + 2,
                suggestedSets: currentSets,
                reason: "Increase reps for progressive overload in bodyweight exercise"
            )
        }
        
        let newWeight = currentWeight * (1 + increasePercentage)
        
        return ProgressiveOverloadSuggestion(
            type: .increaseWeight,
            suggestedWeight: newWeight,
            suggestedReps: newReps,
            suggestedSets: currentSets,
            reason: "Progressive overload - increase weight by \(Int(increasePercentage * 100))%"
        )
    }
    
    private func determineExerciseType(_ exerciseName: String) -> ExerciseType {
        let compoundKeywords = ["squat", "deadlift", "bench", "press", "row", "pull-up", "chin-up"]
        let bodyweightKeywords = ["push-up", "pull-up", "chin-up", "dip", "plank"]
        
        let name = exerciseName.lowercased()
        
        if bodyweightKeywords.contains(where: name.contains) {
            return .bodyweight
        } else if compoundKeywords.contains(where: name.contains) {
            return .compound
        } else {
            return .isolation
        }
    }
    
    // MARK: - Alternative Exercise Suggestions
    func suggestAlternativeExercises(
        for exercise: EnhancedWorkoutExercise,
        unavailableEquipment: [String] = []
    ) async -> [ExerciseAlternative] {
        
        let primaryMuscle = exercise.primaryMuscles.first ?? ""
        let alternatives = await findAlternativeExercises(
            targetMuscle: primaryMuscle,
            excludeEquipment: unavailableEquipment + [exercise.equipment]
        )
        
        return alternatives.map { alt in
            ExerciseAlternative(
                exercise: alt,
                similarity: calculateSimilarity(original: exercise, alternative: alt),
                reason: generateAlternativeReason(original: exercise, alternative: alt)
            )
        }
    }
    
    private func findAlternativeExercises(
        targetMuscle: String,
        excludeEquipment: [String]
    ) async -> [EnhancedWorkoutExercise] {
        // This would integrate with WGER API to find alternatives
        // For now, return mock data
        return []
    }
    
    private func calculateSimilarity(
        original: EnhancedWorkoutExercise,
        alternative: EnhancedWorkoutExercise
    ) -> Double {
        var similarity = 0.0
        
        // Compare primary muscles
        let commonPrimaryMuscles = Set(original.primaryMuscles).intersection(Set(alternative.primaryMuscles))
        similarity += Double(commonPrimaryMuscles.count) / Double(max(original.primaryMuscles.count, 1)) * 0.5
        
        // Compare secondary muscles
        let commonSecondaryMuscles = Set(original.secondaryMuscles).intersection(Set(alternative.secondaryMuscles))
        similarity += Double(commonSecondaryMuscles.count) / Double(max(original.secondaryMuscles.count, 1)) * 0.3
        
        // Compare category
        if original.category == alternative.category {
            similarity += 0.2
        }
        
        return min(similarity, 1.0)
    }
    
    private func generateAlternativeReason(
        original: EnhancedWorkoutExercise,
        alternative: EnhancedWorkoutExercise
    ) -> String {
        if original.equipment != alternative.equipment {
            return "Uses \(alternative.equipment) instead of \(original.equipment)"
        } else if original.category != alternative.category {
            return "Different movement pattern targeting same muscles"
        } else {
            return "Similar exercise with slight variation"
        }
    }
    
    // MARK: - Rest Period Optimization
    func calculateOptimalRestPeriod(
        for exercise: EnhancedWorkoutExercise,
        workoutContext: WorkoutContext
    ) -> RestPeriodSuggestion {
        
        let exerciseType = determineExerciseType(exercise.name)
        let intensity = calculateIntensity(exercise)
        
        var baseRestSeconds: TimeInterval
        
        switch exerciseType {
        case .compound:
            baseRestSeconds = intensity > 0.8 ? 180 : 120 // 3 min for high intensity, 2 min otherwise
        case .isolation:
            baseRestSeconds = intensity > 0.8 ? 90 : 60   // 1.5 min for high intensity, 1 min otherwise
        case .bodyweight:
            baseRestSeconds = 60                          // 1 min standard
        }
        
        // Adjust for workout context
        switch workoutContext.goal {
        case .strength:
            baseRestSeconds *= 1.2
        case .hypertrophy:
            baseRestSeconds *= 1.0
        case .endurance:
            baseRestSeconds *= 0.7
        case .powerlifting:
            baseRestSeconds *= 1.5
        }
        
        // Adjust for fatigue level
        let fatigueMultiplier = 1.0 + (workoutContext.fatigueLevel * 0.3)
        baseRestSeconds *= fatigueMultiplier
        
        return RestPeriodSuggestion(
            minRestSeconds: baseRestSeconds * 0.8,
            maxRestSeconds: baseRestSeconds * 1.2,
            optimalRestSeconds: baseRestSeconds,
            reason: generateRestReason(exerciseType: exerciseType, intensity: intensity, goal: workoutContext.goal)
        )
    }
    
    private func calculateIntensity(_ exercise: EnhancedWorkoutExercise) -> Double {
        // Calculate intensity based on RPE or weight/reps relationship
        if let avgRPE = exercise.sets.compactMap({ $0.rpe }).reduce(0, +) / exercise.sets.count,
           avgRPE > 0 {
            return Double(avgRPE) / 10.0
        }
        
        // Fallback: estimate intensity from reps (lower reps = higher intensity)
        let avgReps = exercise.sets.map { $0.reps }.reduce(0, +) / exercise.sets.count
        return max(0.5, 1.0 - (Double(avgReps) - 1.0) / 20.0)
    }
    
    private func generateRestReason(
        exerciseType: ExerciseType,
        intensity: Double,
        goal: WorkoutGoal
    ) -> String {
        let intensityDesc = intensity > 0.8 ? "high" : "moderate"
        
        switch (exerciseType, goal) {
        case (.compound, .strength):
            return "Compound exercise with \(intensityDesc) intensity requires longer rest for strength gains"
        case (.isolation, .hypertrophy):
            return "Isolation exercise optimized for muscle growth with shorter rest periods"
        case (_, .endurance):
            return "Shorter rest periods to maintain cardiovascular challenge"
        default:
            return "Rest period optimized for \(exerciseType.rawValue) exercise at \(intensityDesc) intensity"
        }
    }
    
    // MARK: - Muscle Group Balancing
    func analyzeMuscleGroupBalance(workouts: [EnhancedWorkout]) -> MuscleBalanceAnalysis {
        let recentWorkouts = workouts.prefix(10) // Last 10 workouts
        
        var muscleGroupVolume: [String: Double] = [:]
        
        for workout in recentWorkouts {
            for exercise in workout.exercises {
                for muscle in exercise.primaryMuscles {
                    muscleGroupVolume[muscle, default: 0] += exercise.totalVolume
                }
                
                // Secondary muscles get half weight
                for muscle in exercise.secondaryMuscles {
                    muscleGroupVolume[muscle, default: 0] += exercise.totalVolume * 0.5
                }
            }
        }
        
        return analyzeMuscleImbalances(muscleGroupVolume)
    }
    
    private func analyzeMuscleImbalances(_ volumeData: [String: Double]) -> MuscleBalanceAnalysis {
        var imbalances: [MuscleImbalance] = []
        var recommendations: [String] = []
        
        // Check push/pull balance
        let pushMuscles = ["chest", "shoulders", "triceps"]
        let pullMuscles = ["back", "biceps", "lats"]
        
        let pushVolume = pushMuscles.compactMap { volumeData[$0] }.reduce(0, +)
        let pullVolume = pullMuscles.compactMap { volumeData[$0] }.reduce(0, +)
        
        if pushVolume > pullVolume * 1.3 {
            imbalances.append(MuscleImbalance(
                overdeveloped: "Push muscles",
                underdeveloped: "Pull muscles",
                severity: .moderate,
                recommendation: "Add more pulling exercises (rows, pull-ups, face pulls)"
            ))
        } else if pullVolume > pushVolume * 1.3 {
            imbalances.append(MuscleImbalance(
                overdeveloped: "Pull muscles",
                underdeveloped: "Push muscles",
                severity: .moderate,
                recommendation: "Add more pushing exercises (bench press, shoulder press, dips)"
            ))
        }
        
        // Check quad/hamstring balance
        let quadVolume = volumeData["quadriceps"] ?? 0
        let hamstringVolume = volumeData["hamstrings"] ?? 0
        
        if quadVolume > hamstringVolume * 1.5 {
            imbalances.append(MuscleImbalance(
                overdeveloped: "Quadriceps",
                underdeveloped: "Hamstrings",
                severity: .high,
                recommendation: "Focus on hamstring exercises (deadlifts, leg curls, good mornings)"
            ))
        }
        
        // Generate overall recommendations
        if imbalances.isEmpty {
            recommendations.append("Great muscle balance! Keep up the well-rounded training.")
        } else {
            recommendations.append("Focus on addressing muscle imbalances to prevent injury and improve performance.")
        }
        
        return MuscleBalanceAnalysis(
            imbalances: imbalances,
            overallBalance: imbalances.isEmpty ? .excellent : .needsImprovement,
            recommendations: recommendations
        )
    }
    
    // MARK: - Workout Modifications
    func suggestWorkoutModifications(
        originalWorkout: EnhancedWorkout,
        userContext: UserContext
    ) -> [WorkoutModification] {
        var modifications: [WorkoutModification] = []
        
        // Adjust for experience level
        if userContext.experienceLevel == .beginner {
            modifications.append(WorkoutModification(
                type: .reduceVolume,
                description: "Reduce sets by 1 for each exercise to avoid overtraining",
                priority: .high
            ))
        }
        
        // Adjust for available time
        if userContext.availableTime < originalWorkout.duration ?? 0 {
            modifications.append(WorkoutModification(
                type: .reduceExercises,
                description: "Remove isolation exercises to fit time constraint",
                priority: .medium
            ))
        }
        
        // Adjust for fatigue level
        if userContext.fatigueLevel > 0.7 {
            modifications.append(WorkoutModification(
                type: .reduceIntensity,
                description: "Reduce weight by 10-15% and focus on form",
                priority: .high
            ))
        }
        
        return modifications
    }
}

// MARK: - Supporting Models
struct ProgressiveOverloadSuggestion {
    let type: ProgressionType
    let suggestedWeight: Double
    let suggestedReps: Int
    let suggestedSets: Int
    let reason: String
    
    enum ProgressionType {
        case increaseWeight
        case increaseReps
        case increaseSets
        case deload
        case maintain
    }
}

enum ProgressTrend {
    case improving
    case stable
    case declining
}

enum ExerciseType: String {
    case compound = "compound"
    case isolation = "isolation"
    case bodyweight = "bodyweight"
}

struct ExerciseAlternative {
    let exercise: EnhancedWorkoutExercise
    let similarity: Double // 0.0 to 1.0
    let reason: String
}

struct RestPeriodSuggestion {
    let minRestSeconds: TimeInterval
    let maxRestSeconds: TimeInterval
    let optimalRestSeconds: TimeInterval
    let reason: String
}

struct WorkoutContext {
    let goal: WorkoutGoal
    let fatigueLevel: Double // 0.0 to 1.0
    let timeConstraint: TimeInterval?
    
    enum WorkoutGoal {
        case strength
        case hypertrophy
        case endurance
        case powerlifting
    }
}

struct MuscleBalanceAnalysis {
    let imbalances: [MuscleImbalance]
    let overallBalance: BalanceRating
    let recommendations: [String]
    
    enum BalanceRating {
        case excellent
        case good
        case needsImprovement
        case poor
    }
}

struct MuscleImbalance {
    let overdeveloped: String
    let underdeveloped: String
    let severity: Severity
    let recommendation: String
    
    enum Severity {
        case low
        case moderate
        case high
    }
}

struct WorkoutModification {
    let type: ModificationType
    let description: String
    let priority: Priority
    
    enum ModificationType {
        case reduceVolume
        case increaseVolume
        case reduceIntensity
        case increaseIntensity
        case reduceExercises
        case addExercises
        case changeExerciseOrder
    }
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct UserContext {
    let experienceLevel: ExperienceLevel
    let availableTime: TimeInterval
    let fatigueLevel: Double // 0.0 to 1.0
    let injuries: [String]
    let goals: [String]
    
    enum ExperienceLevel {
        case beginner
        case intermediate
        case advanced
        case expert
    }
}