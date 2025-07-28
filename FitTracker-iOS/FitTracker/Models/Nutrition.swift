import Foundation
import SwiftUI

// MARK: - Core Food Model
struct Food: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let barcode: String?
    let calories: Double  // per 100g
    let protein: Double   // per 100g
    let carbs: Double     // per 100g
    let fat: Double       // per 100g
    let fiber: Double?    // per 100g
    let sugar: Double?    // per 100g  
    let sodium: Double?   // per 100g (mg)
    let category: String
    let servingSize: Double?  // in grams
    let servingUnit: String?
    let isVerified: Bool
    let imageUrl: String?
    
    init(id: String = UUID().uuidString, name: String, brand: String? = nil, barcode: String? = nil,
         calories: Double, protein: Double, carbs: Double, fat: Double,
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         category: String = "General", servingSize: Double? = 100, servingUnit: String? = "g",
         isVerified: Bool = true, imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.category = category
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.isVerified = isVerified
        self.imageUrl = imageUrl
    }
}

// MARK: - Meal Entry Models
struct MealEntry: Identifiable, Codable {
    let id: String
    let date: Date
    let mealType: MealType
    var foods: [FoodEntry]
    let notes: String?
    
    // Legacy support
    var foodId: String? { foods.first?.food.id }
    var amount: Double { foods.first?.actualServingSize ?? 0 }
    
    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.totalCalories }
    }
    
    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFat: Double {
        foods.reduce(0) { $0 + $1.totalFat }
    }
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var displayName: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .breakfast: return "cup.and.saucer.fill"
            case .lunch: return "fork.knife"
            case .dinner: return "fork.knife"
            case .snack: return "hands.sparkles.fill"
            }
        }
    }
    
    init(id: String = UUID().uuidString, date: Date = Date(), mealType: MealType, 
         foods: [FoodEntry] = [], notes: String? = nil) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.foods = foods
        self.notes = notes
    }
}

// MARK: - Food Entry Model
struct FoodEntry: Identifiable, Codable {
    let id: String
    let food: Food
    let actualServingSize: Double // in grams
    
    var totalCalories: Double {
        (food.calories * actualServingSize) / 100.0
    }
    
    var totalProtein: Double {
        (food.protein * actualServingSize) / 100.0
    }
    
    var totalCarbs: Double {
        (food.carbs * actualServingSize) / 100.0
    }
    
    var totalFat: Double {
        (food.fat * actualServingSize) / 100.0
    }
    
    init(id: String = UUID().uuidString, food: Food, servingSize: Double = 100.0) {
        self.id = id
        self.food = food
        self.actualServingSize = servingSize
    }
}

// MARK: - Daily Nutrition Model
struct DailyNutrition: Codable {
    var date: Date
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var totalFiber: Double
    var waterIntake: Double
    var goals: NutritionGoals
    var meals: [MealEntry]
    
    // Legacy support
    var calories: Double { totalCalories }
    var protein: Double { totalProtein }
    var carbs: Double { totalCarbs }
    var fat: Double { totalFat }
    var fiber: Double { totalFiber }
    
    // Computed properties for progress
    var caloriesProgress: Double {
        guard goals.calories > 0 else { return 0.0 }
        return min(totalCalories / goals.calories, 1.0)
    }
    
    var proteinProgress: Double {
        guard goals.protein > 0 else { return 0.0 }
        return min(totalProtein / goals.protein, 1.0)
    }
    
    var carbsProgress: Double {
        guard goals.carbs > 0 else { return 0.0 }
        return min(totalCarbs / goals.carbs, 1.0)
    }
    
    var fatProgress: Double {
        guard goals.fat > 0 else { return 0.0 }
        return min(totalFat / goals.fat, 1.0)
    }
    
    var waterProgress: Double {
        guard goals.water > 0 else { return 0.0 }
        return min(waterIntake / goals.water, 1.0)
    }
    
    init(date: Date = Date(), totalCalories: Double = 0, totalProtein: Double = 0,
         totalCarbs: Double = 0, totalFat: Double = 0, totalFiber: Double = 0,
         waterIntake: Double = 0, goals: NutritionGoals = .default, meals: [MealEntry] = []) {
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.totalFiber = totalFiber
        self.waterIntake = waterIntake
        self.goals = goals
        self.meals = meals
    }
}

// MARK: - Nutrition Goals Model
struct NutritionGoals: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let water: Double
    
    static let `default` = NutritionGoals(
        calories: 2200,
        protein: 150,
        carbs: 275,
        fat: 73,
        fiber: 25,
        water: 2000
    )
}

// MARK: - Macro Percentages
struct MacroPercentages {
    let protein: Int
    let carbs: Int
    let fat: Int
}

// MARK: - Weekly Nutrition Averages
struct WeeklyNutritionAverages {
    let avgCalories: Int
    let avgProtein: Int
    let avgCarbs: Int
    let avgFat: Int
}

// MARK: - Recipe Models
struct Recipe: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: RecipeCategory
    let cuisine: String
    let difficulty: RecipeDifficulty
    let prepTime: Int        // minutes
    let cookTime: Int        // minutes
    let totalTime: Int       // minutes
    let servings: Int
    
    let nutrition: RecipeNutrition
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let equipment: [String]
    
    let imageUrl: String?
    let videoUrl: String?
    
    let tags: [String]
    let dietaryTags: [DietaryTag]
    let author: String
    let rating: Double
    let ratingsCount: Int
    let createdAt: Date
    
    let variations: [RecipeVariation]
    let tips: [String]
    let notes: String?
    
    enum RecipeCategory: String, CaseIterable, Codable {
        case breakfast, lunch, dinner, snack, dessert, smoothie
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    enum RecipeDifficulty: String, CaseIterable, Codable {
        case easy = "Easy"
        case medium = "Medium" 
        case hard = "Hard"
    }
    
    enum DietaryTag: String, CaseIterable, Codable {
        case vegetarian, vegan, glutenFree = "gluten-free"
        case dairyFree = "dairy-free", lowCarb = "low-carb"
        case keto, paleo, highProtein = "high-protein"
        case lowSodium = "low-sodium", sugarFree = "sugar-free"
        
        var displayName: String {
            switch self {
            case .glutenFree: return "Gluten-Free"
            case .dairyFree: return "Dairy-Free"
            case .lowCarb: return "Low-Carb"
            case .highProtein: return "High-Protein"
            case .lowSodium: return "Low-Sodium"
            case .sugarFree: return "Sugar-Free"
            default: return rawValue.capitalized
            }
        }
    }
}

struct RecipeNutrition: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

struct RecipeIngredient: Identifiable, Codable {
    let id: String
    let name: String
    let amount: Double
    let unit: String
    let notes: String?
    let optional: Bool
    let substitutes: [String]?
}

struct RecipeVariation: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let ingredientChanges: [IngredientChange]
    let nutritionChanges: RecipeNutrition?
    
    struct IngredientChange: Codable {
        let ingredientId: String
        let newAmount: Double?
        let substitute: String?
    }
}

// MARK: - Meal Planning Models
struct MealPlan: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let duration: Int  // days
    let startDate: Date
    let endDate: Date
    
    let nutritionGoals: NutritionGoals
    let dietaryRestrictions: [Recipe.DietaryTag]
    let excludedIngredients: [String]
    let preferredCuisines: [String]
    let cookingTime: CookingTimePreference
    
    let meals: [Int: DayMeals]  // day number to meals
    let shoppingList: [ShoppingListItem]
    let estimatedCost: Double
    
    let createdBy: String
    let createdAt: Date
    let isTemplate: Bool
    let followers: Int
    let tags: [String]
    
    enum CookingTimePreference: String, CaseIterable, Codable {
        case quick, moderate, any
        
        var displayName: String { rawValue.capitalized }
        var maxMinutes: Int? {
            switch self {
            case .quick: return 30
            case .moderate: return 60
            case .any: return nil
            }
        }
    }
}

struct DayMeals: Codable {
    let breakfast: String?
    let lunch: String?
    let dinner: String?
    let snacks: [String]
}

struct ShoppingListItem: Identifiable, Codable {
    var id = UUID()
    let ingredientName: String
    let totalAmount: Double
    let unit: String
    let category: ShoppingCategory
    let estimatedCost: Double
    var purchased: Bool
    var notes: String?
    
    enum ShoppingCategory: String, CaseIterable, Codable {
        case produce, meat, dairy, pantry, frozen, other
        
        var displayName: String { rawValue.capitalized }
        var icon: String {
            switch self {
            case .produce: return "leaf"
            case .meat: return "fish"
            case .dairy: return "drop"
            case .pantry: return "cabinet"
            case .frozen: return "snowflake"
            case .other: return "bag"
            }
        }
    }
}

struct MealPlanTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let goal: String
    let duration: Int
    let difficulty: String
    let features: [String]
    let sampleDay: DayMeals
    let estimatedCost: Double
    let rating: Double
}

// MARK: - Extensions for OpenFoodFacts Integration
extension Food {
    init(from offProduct: OFFProductDetails) {
        self.init(
            name: offProduct.productName ?? "Unknown Product",
            brand: offProduct.brands,
            calories: offProduct.nutriments?.energyKcal100g ?? 0,
            protein: offProduct.nutriments?.proteins100g ?? 0,
            carbs: offProduct.nutriments?.carbohydrates100g ?? 0,
            fat: offProduct.nutriments?.fat100g ?? 0,
            imageUrl: offProduct.imageFrontUrl
        )
    }
}