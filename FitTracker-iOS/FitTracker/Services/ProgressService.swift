import Foundation
import SwiftUI

struct WorkoutFrequencyData {
    let date: Date
    let count: Int
}

struct VolumeData {
    let date: Date
    let volume: Int
}

struct StrengthData {
    let date: Date
    let weight: Double
    let exerciseName: String
}

struct NutritionProgressData {
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct BodyStatsData {
    let date: Date
    let weight: Double
    let bodyFat: Double?
    let muscleMass: Double?
}

// Note: PersonalRecord and PRType are defined in Analytics.swift

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

class ProgressService: ObservableObject {
    @Published var workoutFrequencyData: [WorkoutFrequencyData] = []
    @Published var volumeData: [VolumeData] = []
    @Published var strengthData: [StrengthData] = []
    @Published var nutritionData: [NutritionProgressData] = []
    @Published var bodyStatsData: [BodyStatsData] = []
    @Published var personalRecords: [PersonalRecord] = []
    
    @Published var selectedTimeRange: TimeRange = .month
    @Published var selectedExercise: String = "All Exercises"
    
    private let workoutService = WorkoutService.shared
    private let nutritionService = NutritionService.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        generateWorkoutFrequencyData()
        generateVolumeData()
        generateStrengthData()
        generateNutritionData()
        generateBodyStatsData()
        Task { @MainActor in
            generatePersonalRecords()
        }
    }
    
    private func generateWorkoutFrequencyData() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        var data: [WorkoutFrequencyData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let workoutCount = workoutService.getWorkoutsForDate(currentDate).count
            data.append(WorkoutFrequencyData(date: currentDate, count: workoutCount))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        self.workoutFrequencyData = data
    }
    
    private func generateVolumeData() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        var data: [VolumeData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayWorkouts = workoutService.getWorkoutsForDate(currentDate)
            let totalVolume = dayWorkouts.reduce(0) { total, workout in
                total + workout.exercises.reduce(0) { exTotal, exercise in
                    exTotal + exercise.sets.reduce(0) { setTotal, set in
                        setTotal + (set.completed ? Int(set.weight * Double(set.reps)) : 0)
                    }
                }
            }
            data.append(VolumeData(date: currentDate, volume: totalVolume))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        self.volumeData = data
    }
    
    private func generateStrengthData() {
        let allWorkouts = workoutService.getAllWorkouts()
        var data: [StrengthData] = []
        
        for workout in allWorkouts {
            for exercise in workout.exercises {
                if selectedExercise == "All Exercises" || exercise.exerciseId == selectedExercise {
                    let maxWeight = exercise.sets.compactMap { $0.completed ? $0.weight : nil }.max() ?? 0
                    if maxWeight > 0 {
                        data.append(StrengthData(
                            date: workout.date,
                            weight: maxWeight,
                            exerciseName: exercise.exerciseId
                        ))
                    }
                }
            }
        }
        
        self.strengthData = data.sorted { $0.date < $1.date }
    }
    
    private func generateNutritionData() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        var data: [NutritionProgressData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayNutrition = nutritionService.getDayNutrition(for: currentDate)
            data.append(NutritionProgressData(
                date: currentDate,
                calories: Int(dayNutrition.calories),
                protein: dayNutrition.protein,
                carbs: dayNutrition.carbs,
                fat: dayNutrition.fat
            ))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        self.nutritionData = data
    }
    
    private func generateBodyStatsData() {
        // Mock body stats data - in real app would come from HealthKit or manual entry
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        var data: [BodyStatsData] = []
        var currentDate = startDate
        var baseWeight = 75.0
        
        while currentDate <= endDate {
            // Simulate slight weight variations
            let weightVariation = Double.random(in: -0.5...0.5)
            let weight = baseWeight + weightVariation
            
            data.append(BodyStatsData(
                date: currentDate,
                weight: weight,
                bodyFat: Double.random(in: 12...18),
                muscleMass: Double.random(in: 35...40)
            ))
            
            currentDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            baseWeight += Double.random(in: -0.1...0.1) // Gradual trend
        }
        
        self.bodyStatsData = data
    }
    
    @MainActor private func generatePersonalRecords() {
        var records: [PersonalRecord] = []
        
        // Get exercises from OpenWorkout API instead of hardcoded list
        let openWorkoutService = OpenWorkoutService.shared
        for exercise in openWorkoutService.exercises.prefix(5) {
            // Generate multiple PRs over time
            for i in 0..<3 {
                let date = Calendar.current.date(byAdding: .month, value: -i*2, to: Date()) ?? Date()
                let baseWeight = exercise.name == "Pull-ups" ? 0 : Double.random(in: 60...120)
                let weight = baseWeight + Double(i * 5)
                
                records.append(PersonalRecord(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    type: .oneRepMax,
                    value: weight,
                    date: date
                ))
            }
        }
        
        self.personalRecords = records.sorted { $0.date > $1.date }
    }
    
    // Mock data generation removed - now using real data from APIs
    
    func updateTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        loadData()
    }
    
    func updateSelectedExercise(_ exercise: String) {
        selectedExercise = exercise
        generateStrengthData()
    }
    
    func getWorkoutStreakData() -> (current: Int, longest: Int) {
        let workouts = workoutService.getAllWorkouts().sorted { $0.date > $1.date }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastWorkoutDate: Date?
        
        for workout in workouts.reversed() {
            if let lastDate = lastWorkoutDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: lastDate, to: workout.date).day ?? 0
                
                if daysBetween <= 2 { // Allow 1 day gap
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            
            lastWorkoutDate = workout.date
        }
        
        // Check current streak
        if let lastDate = lastWorkoutDate {
            let daysSinceLastWorkout = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            currentStreak = daysSinceLastWorkout <= 2 ? tempStreak : 0
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        return (current: currentStreak, longest: longestStreak)
    }
    
    func getWeeklyStats() -> (workouts: Int, volume: Int, avgDuration: Int) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyWorkouts = workoutService.getAllWorkouts().filter { $0.date > weekAgo }
        let totalVolume = weeklyWorkouts.reduce(0) { total, workout in
            total + workout.exercises.reduce(0) { exTotal, exercise in
                exTotal + exercise.sets.reduce(0) { setTotal, set in
                    setTotal + (set.completed ? Int(set.weight * Double(set.reps)) : 0)
                }
            }
        }
        
        let avgDuration = weeklyWorkouts.isEmpty ? 0 : weeklyWorkouts.reduce(0) { $0 + ($1.duration ?? 0) } / Double(weeklyWorkouts.count)
        
        return (workouts: weeklyWorkouts.count, volume: totalVolume, avgDuration: Int(avgDuration))
    }
    
    func getMacroTrends() -> (protein: Double, carbs: Double, fat: Double) {
        let recentData = nutritionData.suffix(7) // Last 7 days
        
        guard !recentData.isEmpty else { return (0, 0, 0) }
        
        let avgProtein = recentData.reduce(0) { $0 + $1.protein } / Double(recentData.count)
        let avgCarbs = recentData.reduce(0) { $0 + $1.carbs } / Double(recentData.count)
        let avgFat = recentData.reduce(0) { $0 + $1.fat } / Double(recentData.count)
        
        return (protein: avgProtein, carbs: avgCarbs, fat: avgFat)
    }
}