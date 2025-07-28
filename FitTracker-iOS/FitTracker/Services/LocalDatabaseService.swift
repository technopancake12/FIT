import Foundation
import SQLite3

// MARK: - Database Models
struct DatabaseExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let categoryId: Int?
    let categoryName: String?
    let equipment: String?
    let muscles: String?
    let musclesSecondary: String?
    let language: Int?
    let license: Int?
    let licenseAuthor: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language, license
        case categoryId = "category_id"
        case categoryName = "category_name"
        case equipment, muscles
        case musclesSecondary = "muscles_secondary"
        case licenseAuthor = "license_author"
        case createdAt = "created_at"
    }
    
    func toLocalExercise() -> Exercise {
        return Exercise(
            id: String(id),
            name: name,
            category: categoryName ?? "General",
            primaryMuscles: muscles?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            secondaryMuscles: musclesSecondary?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            equipment: equipment ?? "None",
            difficulty: .intermediate,
            instructions: [description ?? "No instructions available"],
            tips: [],
            alternatives: []
        )
    }
}

struct DatabaseFood: Codable, Identifiable {
    let code: String
    let productName: String?
    let genericName: String?
    let brands: String?
    let categories: String?
    let imageFrontUrl: String?
    let imageNutritionUrl: String?
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?
    let salt100g: Double?
    let sodium100g: Double?
    let nutriscoreGrade: String?
    let novaGroup: Int?
    let servingSize: String?
    let ingredientsText: String?
    let allergensTags: String?
    let tracesTags: String?
    let nutritionDataPer: String?
    let nutritionGradeFr: String?
    let ecoscoreGrade: String?
    let lastModifiedT: Int?
    let createdT: Int?
    
    var id: String { code }
    
    enum CodingKeys: String, CodingKey {
        case code, brands, categories
        case productName = "product_name"
        case genericName = "generic_name"
        case imageFrontUrl = "image_front_url"
        case imageNutritionUrl = "image_nutrition_url"
        case energyKcal100g = "energy_kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated_fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
        case salt100g = "salt_100g"
        case sodium100g = "sodium_100g"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case servingSize = "serving_size"
        case ingredientsText = "ingredients_text"
        case allergensTags = "allergens_tags"
        case tracesTags = "traces_tags"
        case nutritionDataPer = "nutrition_data_per"
        case nutritionGradeFr = "nutrition_grade_fr"
        case ecoscoreGrade = "ecoscore_grade"
        case lastModifiedT = "last_modified_t"
        case createdT = "created_t"
    }
    
    func toLocalFood() -> Food {
        return Food(
            name: productName ?? genericName ?? "Unknown Product",
            brand: brands,
            barcode: code,
            calories: energyKcal100g ?? 0,
            protein: proteins100g ?? 0,
            carbs: carbohydrates100g ?? 0,
            fat: fat100g ?? 0,
            fiber: fiber100g,
            sugar: sugars100g,
            sodium: sodium100g,
            category: categories ?? "General",
            servingSize: nil,
            servingUnit: "g",
            isVerified: true,
            imageUrl: imageFrontUrl
        )
    }
}

// MARK: - Database Service (Placeholder Implementation)
class LocalDatabaseService: ObservableObject {
    static let shared = LocalDatabaseService()
    
    @Published var exercises: [DatabaseExercise] = []
    @Published var foods: [DatabaseFood] = []
    @Published var isLoading = false
    
    private init() {
        // Placeholder initialization
        print("LocalDatabaseService initialized - database not yet set up")
    }
    
    // MARK: - Exercise Queries (Placeholder)
    func searchExercises(query: String, category: String? = nil) async throws -> [DatabaseExercise] {
        // Placeholder - return empty array for now
        print("Searching exercises for: \(query)")
        return []
    }
    
    func searchExercises(query: String, limit: Int = 50) async throws -> [DatabaseExercise] {
        // Placeholder - return empty array for now
        print("Searching exercises for: \(query) with limit: \(limit)")
        return []
    }
    
    func getExercisesByCategory(_ category: String) async throws -> [DatabaseExercise] {
        // Placeholder - return empty array for now
        print("Getting exercises for category: \(category)")
        return []
    }
    
    func getExerciseCategories() async throws -> [String] {
        // Placeholder - return empty array for now
        return []
    }
    
    // MARK: - Food Queries (Placeholder)
    func searchFoods(query: String, category: String? = nil) async throws -> [DatabaseFood] {
        // Placeholder - return empty array for now
        print("Searching foods for: \(query)")
        return []
    }
    
    func searchFoods(query: String, limit: Int = 50) async throws -> [DatabaseFood] {
        // Placeholder - return empty array for now
        print("Searching foods for: \(query) with limit: \(limit)")
        return []
    }
    
    func getFoodByBarcode(_ barcode: String) async throws -> DatabaseFood? {
        // Placeholder - return nil for now
        print("Looking up food by barcode: \(barcode)")
        return nil
    }
    
    func getFoodCategories() async throws -> [String] {
        // Placeholder - return empty array for now
        return []
    }
}

// MARK: - Database Errors
enum DatabaseError: Error, LocalizedError {
    case databaseNotOpen
    case prepareFailed
    case executionFailed
    case databaseNotSetUp
    
    var errorDescription: String? {
        switch self {
        case .databaseNotOpen:
            return "Database is not open"
        case .prepareFailed:
            return "Failed to prepare SQL statement"
        case .executionFailed:
            return "Failed to execute SQL statement"
        case .databaseNotSetUp:
            return "Local database has not been set up yet. Run the database setup script first."
        }
    }
}