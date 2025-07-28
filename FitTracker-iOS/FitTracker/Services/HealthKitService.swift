import Foundation
import HealthKit
import SwiftUI

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var healthData: HealthData = HealthData()
    @Published var isLoading = false
    
    // Health metrics we want to read
    private let readTypes: Set<HKSampleType> = [
        HKSampleType.quantityType(forIdentifier: .stepCount)!,
        HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKSampleType.quantityType(forIdentifier: .heartRate)!,
        HKSampleType.quantityType(forIdentifier: .bodyMass)!,
        HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKSampleType.quantityType(forIdentifier: .leanBodyMass)!,
        HKSampleType.quantityType(forIdentifier: .height)!,
        HKSampleType.quantityType(forIdentifier: .restingHeartRate)!,
        HKSampleType.quantityType(forIdentifier: .vo2Max)!,
        HKSampleType.workoutType()
    ]
    
    // Health metrics we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKSampleType.quantityType(forIdentifier: .bodyMass)!,
        HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKSampleType.workoutType()
    ]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                self.isAuthorized = true
                self.loadAllHealthData()
            }
        } catch {
            print("HealthKit authorization failed: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        for type in readTypes {
            let status = healthStore.authorizationStatus(for: type)
            if status == .notDetermined {
                return
            }
        }
        isAuthorized = true
        loadAllHealthData()
    }
    
    // MARK: - Data Loading
    
    func loadAllHealthData() {
        isLoading = true
        
        Task {
            await loadTodayStats()
            await loadWeeklyStats()
            await loadBodyMetrics()
            await loadHeartRateData()
            await loadWorkoutData()
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadTodayStats() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        // Load steps
        if let steps = await loadQuantitySum(for: .stepCount, predicate: predicate) {
            await MainActor.run {
                self.healthData.todaySteps = Int(steps)
            }
        }
        
        // Load distance
        if let distance = await loadQuantitySum(for: .distanceWalkingRunning, predicate: predicate) {
            await MainActor.run {
                self.healthData.todayDistance = distance / 1000 // Convert to km
            }
        }
        
        // Load calories
        if let calories = await loadQuantitySum(for: .activeEnergyBurned, predicate: predicate) {
            await MainActor.run {
                self.healthData.todayCalories = Int(calories)
            }
        }
    }
    
    private func loadWeeklyStats() async {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: Date(), options: .strictStartDate)
        
        // Load weekly data
        let weeklySteps = await loadDailyQuantities(for: .stepCount, predicate: predicate, days: 7)
        let weeklyDistance = await loadDailyQuantities(for: .distanceWalkingRunning, predicate: predicate, days: 7)
        let weeklyCalories = await loadDailyQuantities(for: .activeEnergyBurned, predicate: predicate, days: 7)
        
        await MainActor.run {
            self.healthData.weeklySteps = weeklySteps.map { Int($0) }
            self.healthData.weeklyDistance = weeklyDistance.map { $0 / 1000 } // Convert to km
            self.healthData.weeklyCalories = weeklyCalories.map { Int($0) }
        }
    }
    
    private func loadBodyMetrics() async {
        // Load latest body metrics
        if let weight = await loadLatestQuantity(for: .bodyMass) {
            await MainActor.run {
                self.healthData.currentWeight = weight
            }
        }
        
        if let bodyFat = await loadLatestQuantity(for: .bodyFatPercentage) {
            await MainActor.run {
                self.healthData.currentBodyFat = bodyFat * 100 // Convert to percentage
            }
        }
        
        if let leanMass = await loadLatestQuantity(for: .leanBodyMass) {
            await MainActor.run {
                self.healthData.currentLeanMass = leanMass
            }
        }
        
        if let height = await loadLatestQuantity(for: .height) {
            await MainActor.run {
                self.healthData.height = height * 100 // Convert to cm
            }
        }
    }
    
    private func loadHeartRateData() async {
        // Load resting heart rate
        if let restingHR = await loadLatestQuantity(for: .restingHeartRate) {
            await MainActor.run {
                self.healthData.restingHeartRate = Int(restingHR)
            }
        }
        
        // Load VO2 Max
        if let vo2Max = await loadLatestQuantity(for: .vo2Max) {
            await MainActor.run {
                self.healthData.vo2Max = vo2Max
            }
        }
        
        // Load heart rate variability and trends would go here
        // For now, using mock data
        await MainActor.run {
            self.healthData.heartRateVariability = 45.0
            self.healthData.weeklyHeartRate = [72, 74, 71, 73, 75, 70, 72]
        }
    }
    
    private func loadWorkoutData() async {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: Date(), options: .strictStartDate)
        
        let workouts = await loadWorkouts(predicate: predicate)
        
        await MainActor.run {
            self.healthData.weeklyWorkouts = workouts.count
            self.healthData.totalWorkoutDuration = workouts.reduce(0) { $0 + Int($1.duration / 60) }
            self.healthData.averageWorkoutIntensity = workouts.isEmpty ? 0 : 
                workouts.reduce(0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) } / Double(workouts.count)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadQuantitySum(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, statistics, error in
                if let sum = statistics?.sumQuantity() {
                    let value = sum.doubleValue(for: HKUnit.count()) 
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadLatestQuantity(for identifier: HKQuantityTypeIdentifier) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let sample = samples?.first as? HKQuantitySample {
                    let unit: HKUnit
                    switch identifier {
                    case .bodyMass, .leanBodyMass:
                        unit = .gramUnit(with: .kilo)
                    case .height:
                        unit = .meter()
                    case .bodyFatPercentage:
                        unit = .percent()
                    case .heartRate, .restingHeartRate:
                        unit = HKUnit.count().unitDivided(by: .minute())
                    case .vo2Max:
                        unit = HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
                    default:
                        unit = .count()
                    }
                    
                    let value = sample.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadDailyQuantities(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, days: Int) async -> [Double] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            var interval = DateComponents()
            interval.day = 1
            
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: Date()),
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { query, results, error in
                var values: [Double] = []
                
                if let results = results {
                    let endDate = Date()
                    let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
                    
                    results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                        let unit: HKUnit
                        switch identifier {
                        case .distanceWalkingRunning:
                            unit = .meter()
                        case .activeEnergyBurned:
                            unit = .kilocalorie()
                        default:
                            unit = .count()
                        }
                        
                        let value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                        values.append(value)
                    }
                }
                
                continuation.resume(returning: values)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func loadWorkouts(predicate: NSPredicate) async -> [HKWorkout] {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Writing Data
    
    func saveWorkout(type: HKWorkoutActivityType, startDate: Date, endDate: Date, totalEnergyBurned: Double?) async {
        let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: HKWorkoutConfiguration(), device: .local())
        
        workoutBuilder.beginCollection(withStart: startDate) { (success, error) in
            if success {
                if let energyBurned = totalEnergyBurned {
                    let energySample = HKQuantitySample(
                        type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                        quantity: HKQuantity(unit: .kilocalorie(), doubleValue: energyBurned),
                        start: startDate,
                        end: endDate
                    )
                    workoutBuilder.add([energySample]) { _, _ in }
                }
                
                workoutBuilder.endCollection(withEnd: endDate) { _, _ in
                    workoutBuilder.finishWorkout { _, _ in }
                }
            }
        }
    }
    
    func saveBodyWeight(_ weight: Double) async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: Date(),
            end: Date(),
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        do {
            try await healthStore.save(weightSample)
            print("Weight saved to HealthKit")
            await MainActor.run {
                self.healthData.currentWeight = weight
            }
        } catch {
            print("Failed to save weight: \(error)")
        }
    }
    
    func saveBodyFatPercentage(_ bodyFat: Double) async {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let bodyFatQuantity = HKQuantity(unit: .percent(), doubleValue: bodyFat / 100.0)
        let bodyFatSample = HKQuantitySample(
            type: bodyFatType,
            quantity: bodyFatQuantity,
            start: Date(),
            end: Date(),
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        do {
            try await healthStore.save(bodyFatSample)
            print("Body fat percentage saved to HealthKit")
            await MainActor.run {
                self.healthData.currentBodyFat = bodyFat
            }
        } catch {
            print("Failed to save body fat percentage: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct HealthData {
    // Daily stats
    var todaySteps: Int = 0
    var todayDistance: Double = 0.0 // km
    var todayCalories: Int = 0
    
    // Weekly trends
    var weeklySteps: [Int] = []
    var weeklyDistance: [Double] = []
    var weeklyCalories: [Int] = []
    var weeklyHeartRate: [Int] = []
    
    // Body metrics
    var currentWeight: Double = 0.0
    var currentBodyFat: Double = 0.0
    var currentLeanMass: Double = 0.0
    var height: Double = 0.0
    
    // Heart health
    var restingHeartRate: Int = 0
    var heartRateVariability: Double = 0.0
    var vo2Max: Double = 0.0
    
    // Workout data
    var weeklyWorkouts: Int = 0
    var totalWorkoutDuration: Int = 0 // minutes
    var averageWorkoutIntensity: Double = 0.0 // calories
}

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .walking:
            return "Walking"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .yoga:
            return "Yoga"
        case .pilates:
            return "Pilates"
        case .dance:
            return "Dance"
        case .boxing:
            return "Boxing"
        case .climbing:
            return "Climbing"
        default:
            return "Other"
        }
    }
}