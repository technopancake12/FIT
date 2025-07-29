import Foundation
import SwiftUI

// MARK: - OpenWorkout API Service
@MainActor
class OpenWorkoutService: ObservableObject {
    static let shared = OpenWorkoutService()
    
    private let baseURL = "https://openworkout.com/api/v1"
    private let cache = NSCache<NSString, CachedData>()
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    @Published var exercises: [Exercise] = []
    @Published var categories: [ExerciseCategory] = []
    @Published var equipment: [OpenWorkoutEquipment] = []
    @Published var muscles: [Muscle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        setupCache()
        loadCachedData()
    }
    
    // MARK: - Cache Management
    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    private func loadCachedData() {
        if let cachedExercises = getCachedData(for: "exercises") as? [Exercise] {
            self.exercises = cachedExercises
        }
        if let cachedCategories = getCachedData(for: "categories") as? [ExerciseCategory] {
            self.categories = cachedCategories
        }
        if let cachedEquipment = getCachedData(for: "equipment") as? [OpenWorkoutEquipment] {
            self.equipment = cachedEquipment
        }
        if let cachedMuscles = getCachedData(for: "muscles") as? [Muscle] {
            self.muscles = cachedMuscles
        }
    }
    
    private func cacheData(_ data: Any, for key: String) {
        let cachedData = CachedData(data: data, timestamp: Date())
        cache.setObject(cachedData, forKey: key as NSString)
    }
    
    private func getCachedData(for key: String) -> Any? {
        guard let cachedData = cache.object(forKey: key as NSString) else { return nil }
        
        if Date().timeIntervalSince(cachedData.timestamp) > cacheExpiration {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        
        return cachedData.data
    }
    
    // MARK: - API Methods
    func fetchExercises(category: Int? = nil, equipment: Int? = nil, muscle: Int? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var components = URLComponents(string: "\(baseURL)/exercises")!
        var queryItems: [URLQueryItem] = []
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: "\(category)"))
        }
        if let equipment = equipment {
            queryItems.append(URLQueryItem(name: "equipment", value: "\(equipment)"))
        }
        if let muscle = muscle {
            queryItems.append(URLQueryItem(name: "muscle", value: "\(muscle)"))
        }
        
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let exercises = try JSONDecoder().decode([OpenWorkoutExercise].self, from: data)
        let convertedExercises = exercises.map { $0.toExercise() }
        
        self.exercises = convertedExercises
        cacheData(convertedExercises, for: "exercises")
    }
    
    func fetchCategories() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/exercisecategories")!
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let categories = try JSONDecoder().decode([OpenWorkoutCategory].self, from: data)
        let convertedCategories = categories.map { $0.toExerciseCategory() }
        
        self.categories = convertedCategories
        cacheData(convertedCategories, for: "categories")
    }
    
    func fetchEquipment() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/equipment")!
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let equipment = try JSONDecoder().decode([OpenWorkoutEquipment].self, from: data)
        
        self.equipment = equipment
        cacheData(equipment, for: "equipment")
    }
    
    func fetchMuscles() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/muscles")!
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let muscles = try JSONDecoder().decode([OpenWorkoutMuscle].self, from: data)
        let convertedMuscles = muscles.map { $0.toMuscle() }
        
        self.muscles = convertedMuscles
        cacheData(convertedMuscles, for: "muscles")
    }
    
    func searchExercises(query: String) async throws -> [Exercise] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var components = URLComponents(string: "\(baseURL)/exercises")!
        components.queryItems = [URLQueryItem(name: "search", value: query)]
        
        let request = URLRequest(url: components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let exercises = try JSONDecoder().decode([OpenWorkoutExercise].self, from: data)
        return exercises.map { $0.toExercise() }
    }
    
    func fetchExerciseDetails(id: String) async throws -> Exercise {
        let url = URL(string: "\(baseURL)/exercises/\(id)")!
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWorkoutError.invalidResponse
        }
        
        let exercise = try JSONDecoder().decode(OpenWorkoutExercise.self, from: data)
        return exercise.toExercise()
    }
    
    // MARK: - Convenience Methods
    func refreshAllData() async {
        do {
            async let exercisesTask = fetchExercises()
            async let categoriesTask = fetchCategories()
            async let equipmentTask = fetchEquipment()
            async let musclesTask = fetchMuscles()
            
            try await (exercisesTask, categoriesTask, equipmentTask, musclesTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getExercisesByCategory(_ category: String) -> [Exercise] {
        return exercises.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    func getExercisesByMuscle(_ muscle: String) -> [Exercise] {
        return exercises.filter { exercise in
            exercise.primaryMuscles.contains { $0.lowercased().contains(muscle.lowercased()) } ||
            exercise.secondaryMuscles.contains { $0.lowercased().contains(muscle.lowercased()) }
        }
    }
}

// MARK: - OpenWorkout API Models
struct OpenWorkoutExercise: Codable {
    let id: Int
    let name: String
    let description: String?
    let category: OpenWorkoutCategory?
    let muscles: [OpenWorkoutMuscle]
    let musclesSecondary: [OpenWorkoutMuscle]
    let equipment: [OpenWorkoutEquipment]
    let images: [String]?
    let instructions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, muscles, equipment, images, instructions
        case musclesSecondary = "muscles_secondary"
    }
    
    func toExercise() -> Exercise {
        return Exercise(
            id: String(id),
            name: name,
            category: category?.name ?? "General",
            primaryMuscles: muscles.map { $0.name },
            secondaryMuscles: musclesSecondary.map { $0.name },
            equipment: equipment.first?.name ?? "None",
            difficulty: .intermediate,
            instructions: instructions ?? [description ?? "No instructions available"],
            tips: [],
            alternatives: []
        )
    }
}

struct OpenWorkoutCategory: Codable {
    let id: Int
    let name: String
    
    func toExerciseCategory() -> ExerciseCategory {
        return ExerciseCategory(id: String(id), name: name)
    }
}

struct OpenWorkoutEquipment: Identifiable, Codable {
    let id: String
    let name: String
    
    init(id: Int, name: String) {
        self.id = String(id)
        self.name = name
    }
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

struct OpenWorkoutMuscle: Codable {
    let id: Int
    let name: String
    let isFront: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case isFront = "is_front"
    }
    
    func toMuscle() -> Muscle {
        return Muscle(id: String(id), name: name, isFront: isFront)
    }
}

// MARK: - Supporting Models
struct ExerciseCategory: Identifiable, Codable {
    let id: String
    let name: String
}



struct Muscle: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isFront: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Muscle, rhs: Muscle) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Cache Model
private class CachedData {
    let data: Any
    let timestamp: Date
    
    init(data: Any, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}

// MARK: - Errors
enum OpenWorkoutError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenWorkout API"
        case .decodingError:
            return "Failed to decode response data"
        case .networkError:
            return "Network connection error"
        }
    }
} 