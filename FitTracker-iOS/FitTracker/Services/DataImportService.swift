import Foundation
import UIKit
import UniformTypeIdentifiers

@MainActor
class DataImportService: ObservableObject {
    static let shared = DataImportService()
    
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importError: String?
    @Published var importSummary: ImportSummary?
    
    private let firebaseManager = FirebaseManager.shared
    private let analyticsService = AnalyticsService.shared
    
    private init() {}
    
    // MARK: - Import Methods
    
    func importFromBackup(fileURL: URL) async throws {
        isImporting = true
        importProgress = 0.0
        importError = nil
        importSummary = nil
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            importProgress = 0.1
            
            let backupData = try JSONDecoder().decode(BackupData.self, from: data)
            importProgress = 0.2
            
            try await processBackupImport(backupData)
            importProgress = 1.0
            
            generateImportSummary(from: backupData.userData)
        } catch {
            importError = error.localizedDescription
            throw error
        }
    }
    
    func importWorkoutsFromCSV(fileURL: URL) async throws {
        isImporting = true
        importProgress = 0.0
        importError = nil
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let csvContent = try String(contentsOf: fileURL)
            importProgress = 0.2
            
            let workouts = try parseWorkoutsCSV(csvContent)
            importProgress = 0.6
            
            try await importWorkouts(workouts)
            importProgress = 1.0
            
            importSummary = ImportSummary(
                workoutsImported: workouts.count,
                nutritionLogsImported: 0,
                goalsImported: 0,
                achievementsImported: 0,
                templatesImported: 0
            )
        } catch {
            importError = error.localizedDescription
            throw error
        }
    }
    
    func importNutritionFromCSV(fileURL: URL) async throws {
        isImporting = true
        importProgress = 0.0
        importError = nil
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let csvContent = try String(contentsOf: fileURL)
            importProgress = 0.2
            
            let nutritionLogs = try parseNutritionCSV(csvContent)
            importProgress = 0.6
            
            try await importNutritionLogs(nutritionLogs)
            importProgress = 1.0
            
            importSummary = ImportSummary(
                workoutsImported: 0,
                nutritionLogsImported: nutritionLogs.count,
                goalsImported: 0,
                achievementsImported: 0,
                templatesImported: 0
            )
        } catch {
            importError = error.localizedDescription
            throw error
        }
    }
    
    func importFromJSON(fileURL: URL) async throws {
        isImporting = true
        importProgress = 0.0
        importError = nil
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            importProgress = 0.1
            
            let exportData = try JSONDecoder().decode(ExportData.self, from: data)
            importProgress = 0.2
            
            try await processFullDataImport(exportData)
            importProgress = 1.0
            
            generateImportSummary(from: exportData)
        } catch {
            importError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Processing Methods
    
    private func processBackupImport(_ backupData: BackupData) async throws {
        importProgress = 0.3
        
        // Import user profile if available
        if let userProfile = backupData.userProfile {
            try await firebaseManager.updateUserProfile(userProfile)
        }
        importProgress = 0.4
        
        try await processFullDataImport(backupData.userData)
    }
    
    private func processFullDataImport(_ exportData: ExportData) async throws {
        importProgress = 0.3
        
        // Import workouts
        try await importWorkouts(exportData.workouts)
        importProgress = 0.5
        
        // Import nutrition logs
        try await importNutritionLogs(exportData.nutritionLogs)
        importProgress = 0.7
        
        // Import goals
        try await importGoals(exportData.goals)
        importProgress = 0.8
        
        // Import achievements
        try await importAchievements(exportData.achievements)
        importProgress = 0.9
        
        // Import templates
        try await importTemplates(exportData.templates)
    }
    
    // MARK: - Individual Import Methods
    
    private func importWorkouts(_ workouts: [Workout]) async throws {
        for workout in workouts {
            try await firebaseManager.saveWorkout(workout)
        }
    }
    
    private func importNutritionLogs(_ logs: [NutritionLog]) async throws {
        for log in logs {
            for meal in log.meals {
                try await firebaseManager.saveNutritionEntry(meal)
            }
        }
    }
    
    private func importGoals(_ goals: [FitnessGoal]) async throws {
        for goal in goals {
            try await analyticsService.createGoal(goal)
        }
    }
    
    private func importAchievements(_ achievements: [Achievement]) async throws {
        for achievement in achievements {
            try await saveAchievementToFirestore(achievement)
        }
    }
    
    private func importTemplates(_ templates: [WorkoutTemplate]) async throws {
        for template in templates {
            try await saveWorkoutTemplateToFirestore(template)
        }
    }
    
    // MARK: - CSV Parsing
    
    private func parseWorkoutsCSV(_ csvContent: String) throws -> [Workout] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ImportError.invalidFormat }
        
        var workouts: [Workout] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let components = parseCSVLine(line)
            guard components.count >= 8 else { continue }
            
            let dateString = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let date = dateFormatter.date(from: dateString) else { continue }
            
            let name = components[1]
            let duration = TimeInterval((Int(components[2]) ?? 0) * 60)
            let exerciseNames = components[3].components(separatedBy: "; ")
            let notes = components[7]
            
            // Create simplified workout (would need more complex parsing for full exercise data)
            let exercises = exerciseNames.map { name in
                WorkoutExercise(
                    id: UUID().uuidString,
                    exerciseId: UUID().uuidString,
                    sets: [WorkoutSet(id: UUID().uuidString, reps: 10, weight: 0, restTime: nil, completed: true, rpe: nil)],
                    notes: nil,
                    targetSets: 1,
                    targetReps: 10,
                    targetWeight: 0
                )
            }
            
            let workout = Workout(
                id: UUID().uuidString,
                name: name,
                date: date,
                exercises: exercises,
                duration: duration,
                completed: true,
                notes: notes.isEmpty ? nil : notes
            )
            
            workouts.append(workout)
        }
        
        return workouts
    }
    
    private func parseNutritionCSV(_ csvContent: String) throws -> [NutritionLog] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ImportError.invalidFormat }
        
        var nutritionLogs: [String: NutritionLog] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let components = parseCSVLine(line)
            guard components.count >= 8 else { continue }
            
            let dateString = components[0]
            guard let date = dateFormatter.date(from: dateString) else { continue }
            
            let mealType = components[1]
            let foodName = components[2]
            let calories = Double(components[3]) ?? 0
            let protein = Double(components[4]) ?? 0
            let carbs = Double(components[5]) ?? 0
            let fat = Double(components[6]) ?? 0
            let quantity = components[7]
            
            let food = Food(
                id: UUID().uuidString,
                name: foodName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
            
            let dateKey = dateFormatter.string(from: date)
            
            if let existingLog = nutritionLogs[dateKey] {
                // Find or create meal
                var updatedMeals = existingLog.meals
                if let mealIndex = updatedMeals.firstIndex(where: { $0.mealType.rawValue == mealType }) {
                    var updatedMeal = updatedMeals[mealIndex]
                    updatedMeal.foods.append(FoodEntry(food: food, servingSize: 100))
                    updatedMeals[mealIndex] = updatedMeal
                } else {
                    let newMeal = MealEntry(
                        id: UUID().uuidString,
                        date: date,
                        mealType: MealEntry.MealType(rawValue: mealType) ?? .snack,
                        foods: [FoodEntry(food: food, servingSize: 100)],
                        notes: nil
                    )
                    updatedMeals.append(newMeal)
                }
                
                // Create new nutrition log with updated meals
                let updatedLog = NutritionLog(
                    id: existingLog.id,
                    userId: existingLog.userId,
                    date: date,
                    meals: updatedMeals,
                    notes: existingLog.notes
                )
                nutritionLogs[dateKey] = updatedLog
            } else {
                let meal = MealEntry(
                    id: UUID().uuidString,
                    date: date,
                    mealType: MealEntry.MealType(rawValue: mealType) ?? .snack,
                    foods: [FoodEntry(food: food, servingSize: 100)],
                    notes: nil
                )
                
                let log = NutritionLog(
                    userId: firebaseManager.currentUserId ?? "",
                    date: date,
                    meals: [meal],
                    notes: nil
                )
                
                nutritionLogs[dateKey] = log
            }
        }
        
        return Array(nutritionLogs.values)
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                components.append(currentComponent.trimmingCharacters(in: .whitespacesAndNewlines))
                currentComponent = ""
            } else {
                currentComponent.append(char)
            }
        }
        
        if !currentComponent.isEmpty {
            components.append(currentComponent.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return components
    }
    
    // MARK: - Helper Methods
    
    private func saveAchievementToFirestore(_ achievement: Achievement) async throws {
        guard let userId = firebaseManager.currentUserId else { throw AuthError.noUser }
        
        var achievementWithUser = achievement
        achievementWithUser.userId = userId
        
        try await firebaseManager.firestore
            .collection("user_achievements")
            .document(achievement.id)
            .setData(achievementWithUser.toDictionary())
    }
    
    private func saveWorkoutTemplateToFirestore(_ template: WorkoutTemplate) async throws {
        try await firebaseManager.firestore
            .collection("workout_templates")
            .document(template.id)
            .setData(template.toFirestore())
    }
    
    // MARK: - Utilities
    
    private func generateImportSummary(from exportData: ExportData) {
        importSummary = ImportSummary(
            workoutsImported: exportData.workouts.count,
            nutritionLogsImported: exportData.nutritionLogs.count,
            goalsImported: exportData.goals.count,
            achievementsImported: exportData.achievements.count,
            templatesImported: exportData.templates.count
        )
    }
    
    func validateImportFile(url: URL) -> ImportFileType? {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "json":
            return .json
        case "csv":
            return .csv
        case "backup":
            return .backup
        default:
            return nil
        }
    }
    
    func clearImportState() {
        importError = nil
        importSummary = nil
        importProgress = 0.0
    }
}

// MARK: - Supporting Types

struct ImportSummary: Equatable {
    let workoutsImported: Int
    let nutritionLogsImported: Int
    let goalsImported: Int
    let achievementsImported: Int
    let templatesImported: Int
    
    var totalItemsImported: Int {
        workoutsImported + nutritionLogsImported + goalsImported + achievementsImported + templatesImported
    }
}

enum ImportFileType {
    case json
    case csv
    case backup
    
    var displayName: String {
        switch self {
        case .json: return "JSON Export"
        case .csv: return "CSV File"
        case .backup: return "Backup File"
        }
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    case unsupportedFileType
    case corruptedData
    case missingRequiredFields
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file format is invalid or corrupted"
        case .unsupportedFileType:
            return "This file type is not supported for import"
        case .corruptedData:
            return "The file appears to be corrupted"
        case .missingRequiredFields:
            return "Required fields are missing from the import file"
        }
    }
}

// MARK: - Extensions

extension FirebaseManager {
    func saveWorkoutFromImport(_ workout: Workout) async throws {
        // Implementation would save workout to Firebase
    }
    
    func saveNutritionLog(_ log: NutritionLog) async throws {
        // Implementation would save nutrition log to Firebase
    }
    
    func saveWorkoutTemplateFromImport(_ template: WorkoutTemplate) async throws {
        // Implementation would save workout template to Firebase
    }
    
    func updateUserProfile(_ profile: User) async throws {
        // Implementation would update user profile in Firebase
        try await updateUserProfile(displayName: profile.displayName, photoURL: nil)
    }
}

extension AnalyticsService {
    func saveGoalFromImport(_ goal: FitnessGoal) async throws {
        // Implementation would save goal
        goals.append(goal)
    }
    
    func saveAchievementFromImport(_ achievement: Achievement) async throws {
        // Implementation would save achievement
        achievements.append(achievement)
    }
}