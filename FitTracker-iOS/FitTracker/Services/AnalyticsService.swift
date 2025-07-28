import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private let db = Firestore.firestore()
    // Retry service implementation would go here
    
    // Collection names
    private let userAnalyticsCollection = "user_analytics"
    private let workoutAnalyticsCollection = "workout_analytics"
    private let progressSnapshotsCollection = "progress_snapshots"
    private let goalsCollection = "user_goals"
    private let achievementsCollection = "user_achievements"
    
    @Published var currentAnalytics: UserAnalytics?
    @Published var workoutAnalytics: WorkoutAnalytics?
    @Published var progressData: [ProgressDataPoint] = []
    @Published var goals: [FitnessGoal] = []
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Analytics Tracking
    func trackWorkoutCompletion(_ workout: EnhancedWorkout) async throws {
        // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let workoutMetrics = calculateWorkoutMetrics(workout)
                let analyticsData = WorkoutAnalyticsEntry(
                    id: UUID().uuidString,
                    userId: currentUserId,
                    workoutId: workout.id,
                    date: workout.date,
                    duration: workout.duration ?? 0,
                    totalVolume: workoutMetrics.totalVolume,
                    totalSets: workoutMetrics.totalSets,
                    totalReps: workoutMetrics.totalReps,
                    averageRPE: workoutMetrics.averageRPE,
                    muscleGroups: workoutMetrics.muscleGroups,
                    exercises: workoutMetrics.exerciseNames,
                    workoutType: determineWorkoutType(workout),
                    caloriesBurned: estimateCaloriesBurned(workout),
                    personalRecords: findPersonalRecords(workout)
                )
                
                // Save workout analytics
                try await db.collection(workoutAnalyticsCollection)
                    .document(analyticsData.id)
                    .setData(analyticsData.toDictionary())
                
                // Update user analytics
                try await updateUserAnalytics(analyticsData)
                
                // Check for achievements
                try await checkForAchievements(analyticsData)
                
                // Update goals progress
                try await updateGoalsProgress(analyticsData)
                
    }
    
    func trackNutritionLog(_ meal: MealEntry) async throws {
        // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let nutritionMetrics = calculateNutritionMetrics(meal)
                
                // Update daily nutrition analytics
                let today = Calendar.current.startOfDay(for: Date())
                let nutritionData: [String: Any] = [
                    "date": today,
                    "calories": FieldValue.increment(Int64(nutritionMetrics.calories)),
                    "protein": FieldValue.increment(Int64(nutritionMetrics.protein)),
                    "carbs": FieldValue.increment(Int64(nutritionMetrics.carbs)),
                    "fat": FieldValue.increment(Int64(nutritionMetrics.fat)),
                    "fiber": FieldValue.increment(Int64(nutritionMetrics.fiber)),
                    "sugar": FieldValue.increment(Int64(nutritionMetrics.sugar)),
                    "sodium": FieldValue.increment(Int64(nutritionMetrics.sodium)),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                try await db.collection("nutrition_analytics")
                    .document("\(currentUserId)_\(today.timeIntervalSince1970)")
                    .setData(nutritionData, merge: true)
                
    }
    
    // MARK: - Progress Tracking
    func createProgressSnapshot() async throws {
        // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let analytics = try await getCurrentAnalytics()
                let snapshot = ProgressSnapshot(
                    id: UUID().uuidString,
                    userId: currentUserId,
                    date: Date(),
                    totalWorkouts: analytics.totalWorkouts,
                    totalVolume: analytics.totalVolume,
                    averageWorkoutDuration: analytics.averageWorkoutDuration,
                    strengthMetrics: analytics.strengthMetrics,
                    bodyMetrics: analytics.bodyMetrics,
                    cardioMetrics: analytics.cardioMetrics
                )
                
                try await db.collection(progressSnapshotsCollection)
                    .document(snapshot.id)
                    .setData(snapshot.toDictionary())
                
                await MainActor.run {
                    self.progressData.append(ProgressDataPoint(
                        date: snapshot.date,
                        totalVolume: snapshot.totalVolume,
                        totalWorkouts: snapshot.totalWorkouts,
                        averageDuration: snapshot.averageWorkoutDuration
                    ))
                }
                
    }
    
    func getProgressHistory(timeframe: ProgressTimeframe = .threeMonths) async throws -> [ProgressDataPoint] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw AppError.authenticationFailed("User not authenticated")
        }
        
        let startDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -timeframe.value, to: Date()) ?? Date()
        
        let snapshot = try await db.collection(progressSnapshotsCollection)
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .order(by: "date", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            guard let progressSnapshot = ProgressSnapshot.fromFirestore(document.data()) else {
                return nil
            }
            
            return ProgressDataPoint(
                date: progressSnapshot.date,
                totalVolume: progressSnapshot.totalVolume,
                totalWorkouts: progressSnapshot.totalWorkouts,
                averageDuration: progressSnapshot.averageWorkoutDuration
            )
        }
    }
    
    // MARK: - Goals Management
    func createGoal(_ goal: FitnessGoal) async throws {
        // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                var goalWithUser = goal
                goalWithUser.userId = currentUserId
                
                try await db.collection(goalsCollection)
                    .document(goal.id)
                    .setData(goalWithUser.toDictionary())
                
                await MainActor.run {
                    self.goals.append(goalWithUser)
                }
                
    }
    
    func updateGoal(_ goal: FitnessGoal) async throws {
        // Execute operation directly
                try await db.collection(goalsCollection)
                    .document(goal.id)
                    .updateData(goal.toDictionary())
                
                await MainActor.run {
                    if let index = self.goals.firstIndex(where: { $0.id == goal.id }) {
                        self.goals[index] = goal
                    }
                }
                
    }
    
    func getUserGoals() async throws {
        // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let snapshot = try await db.collection(goalsCollection)
                    .whereField("userId", isEqualTo: currentUserId)
                    .whereField("isCompleted", isEqualTo: false)
                    .order(by: "createdAt", descending: false)
                    .getDocuments()
                
                let goals = snapshot.documents.compactMap { document in
                    FitnessGoal.fromFirestore(document.data())
                }
                
                await MainActor.run {
                    self.goals = goals
                }
                
    }
    
    // MARK: - Analytics Calculations
    private func calculateWorkoutMetrics(_ workout: EnhancedWorkout) -> WorkoutMetrics {
        let totalVolume = workout.exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                setTotal + (Double(set.reps) * set.weight)
            }
        }
        
        let totalSets = workout.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
        
        let totalReps = workout.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + set.reps
            }
        }
        
        let rpeValues = workout.exercises.flatMap { exercise in
            exercise.sets.compactMap { $0.rpe }
        }
        let averageRPE = rpeValues.isEmpty ? 0.0 : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
        
        let muscleGroups = Array(Set(workout.exercises.flatMap { $0.primaryMuscles }))
        let exerciseNames = workout.exercises.map { $0.name }
        
        return WorkoutMetrics(
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            averageRPE: averageRPE,
            muscleGroups: muscleGroups,
            exerciseNames: exerciseNames
        )
    }
    
    private func calculateNutritionMetrics(_ meal: MealEntry) -> NutritionMetrics {
        let calories = meal.foods.reduce(0.0) { total, foodEntry in
            total + (foodEntry.food.calories * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let protein = meal.foods.reduce(0.0) { total, foodEntry in
            total + (foodEntry.food.protein * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let carbs = meal.foods.reduce(0.0) { total, foodEntry in
            total + (foodEntry.food.carbs * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let fat = meal.foods.reduce(0.0) { total, foodEntry in
            total + (foodEntry.food.fat * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let fiber = meal.foods.reduce(0.0) { total, foodEntry in
            total + ((foodEntry.food.fiber ?? 0) * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let sugar = meal.foods.reduce(0.0) { total, foodEntry in
            total + ((foodEntry.food.sugar ?? 0) * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        let sodium = meal.foods.reduce(0.0) { total, foodEntry in
            total + ((foodEntry.food.sodium ?? 0) * foodEntry.actualServingSize / foodEntry.food.servingSize)
        }
        
        return NutritionMetrics(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium
        )
    }
    
    private func determineWorkoutType(_ workout: EnhancedWorkout) -> String {
        let muscleGroups = Set(workout.exercises.flatMap { $0.primaryMuscles })
        
        if muscleGroups.contains("cardio") || muscleGroups.contains("cardiovascular") {
            return "cardio"
        } else if muscleGroups.count >= 3 {
            return "full_body"
        } else if muscleGroups.contains("chest") || muscleGroups.contains("shoulders") || muscleGroups.contains("triceps") {
            return "push"
        } else if muscleGroups.contains("back") || muscleGroups.contains("biceps") {
            return "pull"
        } else if muscleGroups.contains("legs") || muscleGroups.contains("glutes") {
            return "legs"
        } else {
            return "strength"
        }
    }
    
    private func estimateCaloriesBurned(_ workout: EnhancedWorkout) -> Double {
        // Simplified calorie estimation based on workout duration and intensity
        guard let duration = workout.duration, duration > 0 else { return 0 }
        
        let durationInHours = duration / 3600
        let baseCaloriesPerHour: Double = 300 // Average for strength training
        
        // Adjust based on workout type
        let workoutType = determineWorkoutType(workout)
        let multiplier: Double = {
            switch workoutType {
            case "cardio": return 1.5
            case "full_body": return 1.3
            case "legs": return 1.2
            default: return 1.0
            }
        }()
        
        return baseCaloriesPerHour * durationInHours * multiplier
    }
    
    private func findPersonalRecords(_ workout: EnhancedWorkout) -> [PersonalRecord] {
        var records: [PersonalRecord] = []
        
        for exercise in workout.exercises {
            let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
            let maxReps = exercise.sets.map { $0.reps }.max() ?? 0
            let maxVolume = exercise.sets.map { Double($0.reps) * $0.weight }.max() ?? 0
            
            // Check if these are potential PRs (would need comparison with historical data)
            if maxWeight > 0 {
                records.append(PersonalRecord(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.name,
                    type: .oneRepMax,
                    value: maxWeight,
                    date: workout.date
                ))
            }
            
            if maxVolume > 0 {
                records.append(PersonalRecord(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.name,
                    type: .volume,
                    value: maxVolume,
                    date: workout.date
                ))
            }
        }
        
        return records
    }
    
    // MARK: - User Analytics
    private func updateUserAnalytics(_ workoutEntry: WorkoutAnalyticsEntry) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let thisWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? today
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? today
        
        let updateData: [String: Any] = [
            "userId": currentUserId,
            "totalWorkouts": FieldValue.increment(Int64(1)),
            "totalVolume": FieldValue.increment(Int64(workoutEntry.totalVolume)),
            "totalDuration": FieldValue.increment(Int64(workoutEntry.duration)),
            "workoutsThisWeek": FieldValue.increment(Int64(1)),
            "workoutsThisMonth": FieldValue.increment(Int64(1)),
            "lastWorkoutDate": workoutEntry.date,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(userAnalyticsCollection)
            .document(currentUserId)
            .setData(updateData, merge: true)
    }
    
    private func getCurrentAnalytics() async throws -> UserAnalytics {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw AppError.authenticationFailed("User not authenticated")
        }
        
        let document = try await db.collection(userAnalyticsCollection)
            .document(currentUserId)
            .getDocument()
        
        if let data = document.data(), let analytics = UserAnalytics.fromFirestore(data) {
            return analytics
        } else {
            // Create default analytics if none exist
            let defaultAnalytics = UserAnalytics.createDefault(userId: currentUserId)
            try await db.collection(userAnalyticsCollection)
                .document(currentUserId)
                .setData(defaultAnalytics.toDictionary())
            return defaultAnalytics
        }
    }
    
    // MARK: - Achievement System
    private func checkForAchievements(_ workoutEntry: WorkoutAnalyticsEntry) async throws {
        let analytics = try await getCurrentAnalytics()
        var newAchievements: [Achievement] = []
        
        // Workout count achievements
        if analytics.totalWorkouts == 1 {
            newAchievements.append(Achievement.firstWorkout())
        } else if analytics.totalWorkouts == 10 {
            newAchievements.append(Achievement.tenWorkouts())
        } else if analytics.totalWorkouts == 50 {
            newAchievements.append(Achievement.fiftyWorkouts())
        } else if analytics.totalWorkouts == 100 {
            newAchievements.append(Achievement.hundredWorkouts())
        }
        
        // Volume achievements
        if analytics.totalVolume >= 10000 {
            newAchievements.append(Achievement.volumeMilestone(volume: 10000))
        } else if analytics.totalVolume >= 50000 {
            newAchievements.append(Achievement.volumeMilestone(volume: 50000))
        } else if analytics.totalVolume >= 100000 {
            newAchievements.append(Achievement.volumeMilestone(volume: 100000))
        }
        
        // Consistency achievements
        if analytics.workoutsThisWeek >= 3 {
            newAchievements.append(Achievement.weeklyConsistency())
        }
        
        if analytics.workoutsThisMonth >= 12 {
            newAchievements.append(Achievement.monthlyConsistency())
        }
        
        // Save new achievements
        for achievement in newAchievements {
            try await saveAchievement(achievement)
        }
    }
    
    private func saveAchievement(_ achievement: Achievement) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        var achievementWithUser = achievement
        achievementWithUser.userId = currentUserId
        
        try await db.collection(achievementsCollection)
            .document(achievement.id)
            .setData(achievementWithUser.toDictionary())
        
        await MainActor.run {
            self.achievements.append(achievementWithUser)
        }
    }
    
    private func updateGoalsProgress(_ workoutEntry: WorkoutAnalyticsEntry) async throws {
        for goal in goals where !goal.isCompleted {
            var updatedGoal = goal
            var progressMade = false
            
            switch goal.type {
            case .workoutCount:
                if goal.targetValue <= Double(currentAnalytics?.totalWorkouts ?? 0) {
                    updatedGoal.isCompleted = true
                    updatedGoal.completedAt = Date()
                    progressMade = true
                }
                
            case .totalVolume:
                if goal.targetValue <= (currentAnalytics?.totalVolume ?? 0) {
                    updatedGoal.isCompleted = true
                    updatedGoal.completedAt = Date()
                    progressMade = true
                }
                
            case .weeklyWorkouts:
                if goal.targetValue <= Double(currentAnalytics?.workoutsThisWeek ?? 0) {
                    updatedGoal.isCompleted = true
                    updatedGoal.completedAt = Date()
                    progressMade = true
                }
                
            default:
                break
            }
            
            if progressMade {
                try await updateGoal(updatedGoal)
            }
        }
    }
}

// MARK: - Supporting Types
struct WorkoutMetrics {
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let averageRPE: Double
    let muscleGroups: [String]
    let exerciseNames: [String]
}

struct NutritionMetrics {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

enum ProgressTimeframe: CaseIterable {
    case oneMonth, threeMonths, sixMonths, oneYear
    
    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .oneMonth, .threeMonths, .sixMonths: return .month
        case .oneYear: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 1
        }
    }
}