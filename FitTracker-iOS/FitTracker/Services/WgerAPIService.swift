import Foundation
import CoreData

// MARK: - WGER API Models
struct WgerExercise: Codable {
    let id: Int
    let uuid: String?
    let name: String?
    let exerciseBase: Int?
    let description: String?
    let creationDate: String?
    let category: WgerCategory?
    let muscles: [WgerMuscle]
    let musclesSecondary: [WgerMuscle]
    let equipment: [WgerEquipment]
    let license: Int?
    let licenseAuthor: String?
    let language: Int?
    
    // Computed properties for safe access
    var safeName: String {
        return name ?? "Unknown Exercise"
    }
    
    var safeDescription: String {
        return description ?? "No description available"
    }
    
    var safeCategory: String {
        return category?.name ?? "General"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, name, description, category, muscles, equipment, license, language
        case exerciseBase = "exercise_base"
        case creationDate = "creation_date"
        case musclesSecondary = "muscles_secondary"
        case licenseAuthor = "license_author"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        exerciseBase = try container.decodeIfPresent(Int.self, forKey: .exerciseBase)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        creationDate = try container.decodeIfPresent(String.self, forKey: .creationDate)
        category = try container.decodeIfPresent(WgerCategory.self, forKey: .category)
        license = try container.decodeIfPresent(Int.self, forKey: .license)
        licenseAuthor = try container.decodeIfPresent(String.self, forKey: .licenseAuthor)
        language = try container.decodeIfPresent(Int.self, forKey: .language)
        
        // Handle arrays with fallback to empty arrays
        muscles = (try? container.decode([WgerMuscle].self, forKey: .muscles)) ?? []
        musclesSecondary = (try? container.decode([WgerMuscle].self, forKey: .musclesSecondary)) ?? []
        equipment = (try? container.decode([WgerEquipment].self, forKey: .equipment)) ?? []
    }
}

struct WgerCategory: Codable {
    let id: Int
    let name: String?
    
    var safeName: String {
        return name ?? "Unknown Category"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct WgerMuscle: Codable, Hashable {
    let id: Int
    let name: String?
    let nameEn: String?
    let isFront: Bool?
    
    var safeName: String {
        return nameEn ?? name ?? "Unknown Muscle"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case nameEn = "name_en"
        case isFront = "is_front"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn)
        isFront = try container.decodeIfPresent(Bool.self, forKey: .isFront)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WgerMuscle, rhs: WgerMuscle) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WgerEquipment: Codable {
    let id: Int
    let name: String?
    
    var safeName: String {
        return name ?? "Unknown Equipment"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct WgerExerciseImage: Codable {
    let id: Int
    let uuid: String
    let exerciseBase: Int
    let exerciseBaseUuid: String
    let image: String
    let isMain: Bool
    let style: String
    let license: Int
    let licenseAuthor: String
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, image, style, license
        case exerciseBase = "exercise_base"
        case exerciseBaseUuid = "exercise_base_uuid"
        case isMain = "is_main"
        case licenseAuthor = "license_author"
    }
}

struct WgerResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}

// MARK: - API Service
class WgerAPIService: ObservableObject {
    static let shared = WgerAPIService()
    
    private let baseURL = "https://wger.de/api/v2"
    private let session = URLSession.shared
    private let apiKey = "c5bf06de75b1642db24c405fbbb05a0c779a0f0e" // Replace with your actual API key
    
    @Published var exercises: [WgerExercise] = []
    @Published var categories: [WgerCategory] = []
    @Published var muscles: [WgerMuscle] = []
    @Published var equipment: [WgerEquipment] = []
    @Published var isLoading = false
    
    private var exerciseCache: [String: [WgerExercise]] = [:]
    private var imageCache: [Int: [WgerExerciseImage]] = [:]
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Public Methods
    func fetchExercises(searchTerm: String? = nil, category: Int? = nil, muscles: [Int]? = nil, equipment: Int? = nil) async throws -> [WgerExercise] {
        var components = URLComponents(string: "\(baseURL)/exercise/")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "2"), // English
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: searchTerm))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: String(category)))
        }
        
        if let equipment = equipment {
            queryItems.append(URLQueryItem(name: "equipment", value: String(equipment)))
        }
        
        if let muscles = muscles, !muscles.isEmpty {
            for muscle in muscles {
                queryItems.append(URLQueryItem(name: "muscles", value: String(muscle)))
            }
        }
        
        components.queryItems = queryItems
        
        let cacheKey = components.url?.absoluteString ?? ""
        if let cachedExercises = exerciseCache[cacheKey] {
            return cachedExercises
        }
        
        let request = createRequest(for: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(WgerResponse<WgerExercise>.self, from: data)
        
        // Cache the results
        exerciseCache[cacheKey] = response.results
        await saveCachedData()
        
        return response.results
    }
    
    func fetchExerciseImages(for exerciseBaseId: Int) async throws -> [WgerExerciseImage] {
        if let cachedImages = imageCache[exerciseBaseId] {
            return cachedImages
        }
        
        var components = URLComponents(string: "\(baseURL)/exerciseimage/")!
        components.queryItems = [
            URLQueryItem(name: "exercise_base", value: String(exerciseBaseId)),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        let request = createRequest(for: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(WgerResponse<WgerExerciseImage>.self, from: data)
        
        // Cache the results
        imageCache[exerciseBaseId] = response.results
        await saveCachedData()
        
        return response.results
    }
    
    func fetchCategories() async throws -> [WgerCategory] {
        if !categories.isEmpty {
            return categories
        }
        
        let url = URL(string: "\(baseURL)/exercisecategory/")!
        let request = createRequest(for: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(WgerResponse<WgerCategory>.self, from: data)
        
        await MainActor.run {
            self.categories = response.results
        }
        
        await saveCachedData()
        return response.results
    }
    
    func fetchMuscles() async throws -> [WgerMuscle] {
        if !muscles.isEmpty {
            return muscles
        }
        
        let url = URL(string: "\(baseURL)/muscle/")!
        let request = createRequest(for: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(WgerResponse<WgerMuscle>.self, from: data)
        
        await MainActor.run {
            self.muscles = response.results
        }
        
        await saveCachedData()
        return response.results
    }
    
    func fetchEquipment() async throws -> [WgerEquipment] {
        if !equipment.isEmpty {
            return equipment
        }
        
        let url = URL(string: "\(baseURL)/equipment/")!
        let request = createRequest(for: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(WgerResponse<WgerEquipment>.self, from: data)
        
        await MainActor.run {
            self.equipment = response.results
        }
        
        await saveCachedData()
        return response.results
    }
    
    // MARK: - Helper Methods
    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    // MARK: - Caching
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "wger_exercises_cache"),
           let cache = try? JSONDecoder().decode([String: [WgerExercise]].self, from: data) {
            exerciseCache = cache
        }
        
        if let data = UserDefaults.standard.data(forKey: "wger_images_cache"),
           let cache = try? JSONDecoder().decode([Int: [WgerExerciseImage]].self, from: data) {
            imageCache = cache
        }
        
        if let data = UserDefaults.standard.data(forKey: "wger_categories_cache"),
           let cached = try? JSONDecoder().decode([WgerCategory].self, from: data) {
            categories = cached
        }
        
        if let data = UserDefaults.standard.data(forKey: "wger_muscles_cache"),
           let cached = try? JSONDecoder().decode([WgerMuscle].self, from: data) {
            muscles = cached
        }
        
        if let data = UserDefaults.standard.data(forKey: "wger_equipment_cache"),
           let cached = try? JSONDecoder().decode([WgerEquipment].self, from: data) {
            equipment = cached
        }
    }
    
    private func saveCachedData() async {
        if let data = try? JSONEncoder().encode(exerciseCache) {
            UserDefaults.standard.set(data, forKey: "wger_exercises_cache")
        }
        
        if let data = try? JSONEncoder().encode(imageCache) {
            UserDefaults.standard.set(data, forKey: "wger_images_cache")
        }
        
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: "wger_categories_cache")
        }
        
        if let data = try? JSONEncoder().encode(muscles) {
            UserDefaults.standard.set(data, forKey: "wger_muscles_cache")
        }
        
        if let data = try? JSONEncoder().encode(equipment) {
            UserDefaults.standard.set(data, forKey: "wger_equipment_cache")
        }
    }
    
    func clearCache() {
        exerciseCache.removeAll()
        imageCache.removeAll()
        categories.removeAll()
        muscles.removeAll()
        equipment.removeAll()
        
        UserDefaults.standard.removeObject(forKey: "wger_exercises_cache")
        UserDefaults.standard.removeObject(forKey: "wger_images_cache")
        UserDefaults.standard.removeObject(forKey: "wger_categories_cache")
        UserDefaults.standard.removeObject(forKey: "wger_muscles_cache")
        UserDefaults.standard.removeObject(forKey: "wger_equipment_cache")
    }
}

// MARK: - Extension for converting to local models
extension WgerExercise {
    func toLocalExercise() -> Exercise {
        return Exercise(
            id: String(self.id),
            name: self.name ?? "Unknown Exercise",
            category: self.category?.name ?? "General",
            primaryMuscles: self.muscles.compactMap { $0.nameEn },
            secondaryMuscles: self.musclesSecondary.compactMap { $0.nameEn },
            equipment: self.equipment.first?.name ?? "None",
            difficulty: .intermediate, // Default, as WGER doesn't provide difficulty
            instructions: [self.description ?? "No instructions available"],
            tips: [],
            alternatives: []
        )
    }
}