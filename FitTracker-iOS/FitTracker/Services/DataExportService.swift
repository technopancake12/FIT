import Foundation
import UIKit
import MessageUI
import UniformTypeIdentifiers

@MainActor
class DataExportService: NSObject, ObservableObject {
    static let shared = DataExportService()
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportError: String?
    
    private let firebaseManager = FirebaseManager.shared
    private let analyticsService = AnalyticsService.shared
    
    override init() {
        super.init()
    }
    
    // MARK: - Export Methods
    
    func exportAllData(format: ExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        exportError = nil
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        do {
            let exportData = try await gatherAllUserData()
            exportProgress = 0.8
            
            let fileURL = try await createExportFile(data: exportData, format: format)
            exportProgress = 1.0
            
            return fileURL
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }
    
    func exportWorkoutData(format: ExportFormat = .csv) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        do {
            let workouts = try await firebaseManager.getUserWorkouts()
            exportProgress = 0.5
            
            let fileURL = try await createWorkoutExportFile(workouts: workouts, format: format)
            exportProgress = 1.0
            
            return fileURL
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }
    
    func exportNutritionData(format: ExportFormat = .csv) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        do {
            let nutritionLogs = try await firebaseManager.getNutritionLogs()
            exportProgress = 0.5
            
            let fileURL = try await createNutritionExportFile(logs: nutritionLogs, format: format)
            exportProgress = 1.0
            
            return fileURL
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }
    
    func exportAnalyticsData(format: ExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        do {
            let analytics = try await analyticsService.getFullAnalyticsData()
            exportProgress = 0.5
            
            let fileURL = try await createAnalyticsExportFile(analytics: analytics, format: format)
            exportProgress = 1.0
            
            return fileURL
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }
    
    func createBackup() async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        do {
            let backupData = try await gatherBackupData()
            exportProgress = 0.8
            
            let backupURL = try await createBackupFile(data: backupData)
            exportProgress = 1.0
            
            return backupURL
        } catch {
            exportError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Data Gathering
    
    private func gatherAllUserData() async throws -> ExportData {
        exportProgress = 0.1
        
        let workouts = try await firebaseManager.getUserWorkouts()
        exportProgress = 0.2
        
        let nutritionLogs = try await firebaseManager.getNutritionLogs()
        exportProgress = 0.3
        
        let analytics = try await analyticsService.getFullAnalyticsData()
        exportProgress = 0.4
        
        let goals = try await analyticsService.getUserGoals()
        exportProgress = 0.5
        
        let achievements = try await analyticsService.getUserAchievements()
        exportProgress = 0.6
        
        let templates = try await firebaseManager.getUserWorkoutTemplates()
        exportProgress = 0.7
        
        return ExportData(
            userInfo: UserExportInfo(
                userId: firebaseManager.currentUserId ?? "",
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            ),
            workouts: workouts,
            nutritionLogs: nutritionLogs,
            analytics: analytics,
            goals: goals,
            achievements: achievements,
            templates: templates
        )
    }
    
    private func gatherBackupData() async throws -> BackupData {
        exportProgress = 0.1
        
        let allData = try await gatherAllUserData()
        exportProgress = 0.6
        
        let userProfile = try await firebaseManager.getUserProfile()
        exportProgress = 0.7
        
        return BackupData(
            metadata: BackupMetadata(
                version: "1.0",
                createdAt: Date(),
                userId: firebaseManager.currentUserId ?? "",
                deviceInfo: UIDevice.current.name
            ),
            userData: allData,
            userProfile: userProfile
        )
    }
    
    // MARK: - File Creation
    
    private func createExportFile(data: ExportData, format: ExportFormat) async throws -> URL {
        let fileName = "FitTracker_Export_\(formatDate(Date()))"
        
        switch format {
        case .json:
            return try createJSONFile(data: data, fileName: fileName)
        case .csv:
            return try createZippedCSVFiles(data: data, fileName: fileName)
        case .xlsx:
            return try createExcelFile(data: data, fileName: fileName)
        }
    }
    
    private func createWorkoutExportFile(workouts: [Workout], format: ExportFormat) async throws -> URL {
        let fileName = "FitTracker_Workouts_\(formatDate(Date()))"
        
        switch format {
        case .json:
            let jsonData = try JSONEncoder().encode(workouts)
            return try writeToFile(data: jsonData, fileName: "\(fileName).json")
        case .csv:
            let csvContent = generateWorkoutsCSV(workouts)
            return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
        case .xlsx:
            return try createWorkoutsExcelFile(workouts: workouts, fileName: fileName)
        }
    }
    
    private func createNutritionExportFile(logs: [NutritionLog], format: ExportFormat) async throws -> URL {
        let fileName = "FitTracker_Nutrition_\(formatDate(Date()))"
        
        switch format {
        case .json:
            let jsonData = try JSONEncoder().encode(logs)
            return try writeToFile(data: jsonData, fileName: "\(fileName).json")
        case .csv:
            let csvContent = generateNutritionCSV(logs)
            return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
        case .xlsx:
            return try createNutritionExcelFile(logs: logs, fileName: fileName)
        }
    }
    
    private func createAnalyticsExportFile(analytics: UserAnalytics, format: ExportFormat) async throws -> URL {
        let fileName = "FitTracker_Analytics_\(formatDate(Date()))"
        
        switch format {
        case .json:
            let jsonData = try JSONEncoder().encode(analytics)
            return try writeToFile(data: jsonData, fileName: "\(fileName).json")
        case .csv:
            let csvContent = generateAnalyticsCSV(analytics)
            return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
        case .xlsx:
            return try createAnalyticsExcelFile(analytics: analytics, fileName: fileName)
        }
    }
    
    private func createBackupFile(data: BackupData) async throws -> URL {
        let fileName = "FitTracker_Backup_\(formatDate(Date())).json"
        let jsonData = try JSONEncoder().encode(data)
        return try writeToFile(data: jsonData, fileName: fileName)
    }
    
    // MARK: - CSV Generation
    
    private func generateWorkoutsCSV(_ workouts: [Workout]) -> String {
        var csv = "Date,Name,Duration (min),Exercises,Sets,Reps,Volume (lbs),Notes\n"
        
        for workout in workouts {
            let dateString = formatDate(workout.date)
            let duration = Int(workout.duration / 60)
            let exerciseNames = workout.exercises.map { $0.name }.joined(separator: "; ")
            let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
            let totalReps = workout.exercises.flatMap { $0.sets }.reduce(0) { $0 + $1.reps }
            let totalVolume = workout.exercises.flatMap { $0.sets }.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            let notes = workout.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            csv += "\"\(dateString)\",\"\(workout.name)\",\(duration),\"\(exerciseNames)\",\(totalSets),\(totalReps),\(totalVolume),\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func generateNutritionCSV(_ logs: [NutritionLog]) -> String {
        var csv = "Date,Meal,Food,Calories,Protein (g),Carbs (g),Fat (g),Quantity\n"
        
        for log in logs {
            let dateString = formatDate(log.date)
            
            for meal in log.meals {
                for food in meal.foods {
                    csv += "\"\(dateString)\",\"\(meal.type)\",\"\(food.name)\",\(food.calories),\(food.protein),\(food.carbs),\(food.fat),\(food.quantity) \(food.unit)\n"
                }
            }
        }
        
        return csv
    }
    
    private func generateAnalyticsCSV(_ analytics: UserAnalytics) -> String {
        var csv = "Metric,Value,Unit\n"
        
        csv += "Total Workouts,\(analytics.totalWorkouts),count\n"
        csv += "Total Volume,\(analytics.totalVolume),lbs\n"
        csv += "Total Duration,\(Int(analytics.totalDuration / 60)),minutes\n"
        csv += "Average Workout Duration,\(Int(analytics.averageWorkoutDuration / 60)),minutes\n"
        csv += "Workouts This Week,\(analytics.workoutsThisWeek),count\n"
        csv += "Workouts This Month,\(analytics.workoutsThisMonth),count\n"
        
        csv += "Bench Press Max,\(analytics.strengthMetrics.benchPressMax),lbs\n"
        csv += "Squat Max,\(analytics.strengthMetrics.squatMax),lbs\n"
        csv += "Deadlift Max,\(analytics.strengthMetrics.deadliftMax),lbs\n"
        csv += "Overhead Press Max,\(analytics.strengthMetrics.overheadPressMax),lbs\n"
        
        if let weight = analytics.bodyMetrics.weight {
            csv += "Current Weight,\(weight),lbs\n"
        }
        if let bodyFat = analytics.bodyMetrics.bodyFatPercentage {
            csv += "Body Fat Percentage,\(bodyFat),%\n"
        }
        
        return csv
    }
    
    // MARK: - Excel Generation (Simplified)
    
    private func createWorkoutsExcelFile(workouts: [Workout], fileName: String) throws -> URL {
        // For now, create CSV as Excel functionality would require additional dependencies
        let csvContent = generateWorkoutsCSV(workouts)
        return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
    }
    
    private func createNutritionExcelFile(logs: [NutritionLog], fileName: String) throws -> URL {
        let csvContent = generateNutritionCSV(logs)
        return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
    }
    
    private func createAnalyticsExcelFile(analytics: UserAnalytics, fileName: String) throws -> URL {
        let csvContent = generateAnalyticsCSV(analytics)
        return try writeToFile(string: csvContent, fileName: "\(fileName).csv")
    }
    
    private func createJSONFile(data: ExportData, fileName: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(data)
        return try writeToFile(data: jsonData, fileName: "\(fileName).json")
    }
    
    private func createZippedCSVFiles(data: ExportData, fileName: String) throws -> URL {
        // Create individual CSV files and zip them
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create individual CSV files
        let workoutsCSV = generateWorkoutsCSV(data.workouts)
        try workoutsCSV.write(to: tempDir.appendingPathComponent("workouts.csv"), atomically: true, encoding: .utf8)
        
        let nutritionCSV = generateNutritionCSV(data.nutritionLogs)
        try nutritionCSV.write(to: tempDir.appendingPathComponent("nutrition.csv"), atomically: true, encoding: .utf8)
        
        let analyticsCSV = generateAnalyticsCSV(data.analytics)
        try analyticsCSV.write(to: tempDir.appendingPathComponent("analytics.csv"), atomically: true, encoding: .utf8)
        
        // For now, return the temp directory (would need zip functionality)
        return tempDir
    }
    
    // MARK: - File Operations
    
    private func writeToFile(data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func writeToFile(string: String, fileName: String) throws -> URL {
        let data = string.data(using: .utf8) ?? Data()
        return try writeToFile(data: data, fileName: fileName)
    }
    
    // MARK: - Sharing
    
    func shareFile(url: URL, from viewController: UIViewController) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityController, animated: true)
    }
    
    // MARK: - Utilities
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct ExportData: Codable {
    let userInfo: UserExportInfo
    let workouts: [Workout]
    let nutritionLogs: [NutritionLog]
    let analytics: UserAnalytics
    let goals: [FitnessGoal]
    let achievements: [Achievement]
    let templates: [WorkoutTemplate]
}

struct UserExportInfo: Codable {
    let userId: String
    let exportDate: Date
    let appVersion: String
}

struct BackupData: Codable {
    let metadata: BackupMetadata
    let userData: ExportData
    let userProfile: UserProfile?
}

struct BackupMetadata: Codable {
    let version: String
    let createdAt: Date
    let userId: String
    let deviceInfo: String
}

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case xlsx = "Excel"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .xlsx: return "xlsx"
        }
    }
}

// MARK: - Extensions

extension FirebaseManager {
    func getUserWorkouts() async throws -> [Workout] {
        guard let userId = currentUserId else { throw AppError.userNotAuthenticated }
        // Return empty array for now - would implement actual Firebase queries
        return []
    }
    
    func getNutritionLogs() async throws -> [NutritionLog] {
        guard let userId = currentUserId else { throw AppError.userNotAuthenticated }
        // Return empty array for now - would implement actual Firebase queries
        return []
    }
    
    func getUserWorkoutTemplates() async throws -> [WorkoutTemplate] {
        guard let userId = currentUserId else { throw AppError.userNotAuthenticated }
        // Return empty array for now - would implement actual Firebase queries
        return []
    }
    
    func getUserProfile() async throws -> UserProfile? {
        guard let userId = currentUserId else { throw AppError.userNotAuthenticated }
        // Return nil for now - would implement actual Firebase queries
        return nil
    }
}

extension AnalyticsService {
    func getFullAnalyticsData() async throws -> UserAnalytics {
        // Implementation would return complete analytics data
        return currentAnalytics ?? UserAnalytics.createDefault(userId: "")
    }
    
    func getUserGoals() async throws -> [FitnessGoal] {
        return goals
    }
    
    func getUserAchievements() async throws -> [Achievement] {
        return achievements
    }
}