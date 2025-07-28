import Foundation
import SwiftUI

// MARK: - Core Nutrition Models
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
    
    init(id: String, name: String, brand: String? = nil, barcode: String? = nil,
         calories: Double, protein: Double, carbs: Double, fat: Double,
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         category: String, servingSize: Double? = 100, servingUnit: String? = "g",
         isVerified: Bool = true) {
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
    }
}

struct MealEntry: Identifiable, Codable {
    let id: String
    let foodId: String
    let amount: Double  // in grams
    let mealType: MealType
    let date: Date
    let notes: String?
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snack = "snack"
        
        var displayName: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snacks"
            }
        }
        
        var icon: String {
            switch self {
            case .breakfast: return "cup.and.saucer"
            case .lunch: return "fork.knife"
            case .dinner: return "fork.knife"
            case .snack: return "hands.sparkles"
            }
        }
    }
}

struct DailyNutrition: Codable {
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let meals: [MealEntry]
}

struct NutritionGoals: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    
    static let `default` = NutritionGoals(
        calories: 2200,
        protein: 150,
        carbs: 275,
        fat: 73,
        fiber: 25
    )
}

struct MacroPercentages {
    let protein: Int
    let carbs: Int
    let fat: Int
}

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
    let id = UUID()
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