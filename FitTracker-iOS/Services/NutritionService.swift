import Foundation
import SwiftUI

class NutritionService: ObservableObject {
    static let shared = NutritionService()
    @Published var meals: [MealEntry] = []
    @Published var goals: NutritionGoals = .default
    @Published var dailyNutrition: DailyNutrition?
    
    private let foodDatabase = FoodDatabase.shared
    
    init() {
        loadFromStorage()
        updateDailyNutrition()
    }
    
    // MARK: - Data Persistence
    private func loadFromStorage() {
        if let mealsData = UserDefaults.standard.data(forKey: "nutrition_meals"),
           let decodedMeals = try? JSONDecoder().decode([MealEntry].self, from: mealsData) {
            self.meals = decodedMeals
        }
        
        if let goalsData = UserDefaults.standard.data(forKey: "nutrition_goals"),
           let decodedGoals = try? JSONDecoder().decode(NutritionGoals.self, from: goalsData) {
            self.goals = decodedGoals
        }
    }
    
    private func saveToStorage() {
        if let mealsData = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(mealsData, forKey: "nutrition_meals")
        }
        
        if let goalsData = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(goalsData, forKey: "nutrition_goals")
        }
    }
    
    // MARK: - Meal Management
    func addMealEntry(foodId: String, amount: Double, mealType: MealEntry.MealType, notes: String? = nil) {
        let meal = MealEntry(
            id: "meal_\(Date().timeIntervalSince1970)",
            foodId: foodId,
            amount: amount,
            mealType: mealType,
            date: Date(),
            notes: notes
        )
        
        meals.append(meal)
        saveToStorage()
        updateDailyNutrition()
    }
    
    func deleteMealEntry(mealId: String) {
        meals.removeAll { $0.id == mealId }
        saveToStorage()
        updateDailyNutrition()
    }
    
    func updateMealEntry(mealId: String, amount: Double? = nil, notes: String? = nil) {
        if let index = meals.firstIndex(where: { $0.id == mealId }) {
            let meal = meals[index]
            let updatedMeal = MealEntry(
                id: meal.id,
                foodId: meal.foodId,
                amount: amount ?? meal.amount,
                mealType: meal.mealType,
                date: meal.date,
                notes: notes ?? meal.notes
            )
            meals[index] = updatedMeal
            saveToStorage()
            updateDailyNutrition()
        }
    }
    
    // MARK: - Nutrition Calculations
    func updateDailyNutrition(for date: Date = Date()) {
        let dateString = Calendar.current.startOfDay(for: date)
        let dayMeals = meals.filter { meal in
            Calendar.current.isDate(meal.date, inSameDayAs: dateString)
        }
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalFiber: Double = 0
        
        for meal in dayMeals {
            if let food = foodDatabase.findFood(by: meal.foodId) {
                let multiplier = meal.amount / 100.0
                totalCalories += food.calories * multiplier
                totalProtein += food.protein * multiplier
                totalCarbs += food.carbs * multiplier
                totalFat += food.fat * multiplier
                totalFiber += (food.fiber ?? 0) * multiplier
            }
        }
        
        dailyNutrition = DailyNutrition(
            date: date,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            meals: dayMeals
        )
    }
    
    func getMealsByType(date: Date = Date(), mealType: MealEntry.MealType) -> [MealEntry] {
        return meals.filter { meal in
            Calendar.current.isDate(meal.date, inSameDayAs: date) && meal.mealType == mealType
        }
    }
    
    func calculateMacroPercentages() -> MacroPercentages {
        guard let nutrition = dailyNutrition, nutrition.calories > 0 else {
            return MacroPercentages(protein: 0, carbs: 0, fat: 0)
        }
        
        let proteinCals = nutrition.protein * 4
        let carbsCals = nutrition.carbs * 4
        let fatCals = nutrition.fat * 9
        
        return MacroPercentages(
            protein: Int((proteinCals / nutrition.calories) * 100),
            carbs: Int((carbsCals / nutrition.calories) * 100),
            fat: Int((fatCals / nutrition.calories) * 100)
        )
    }
    
    func getWeeklyAverages() -> WeeklyNutritionAverages {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var dayCount = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayNutrition = getDayNutrition(for: date)
                if dayNutrition.calories > 0 {
                    totalCalories += dayNutrition.calories
                    totalProtein += dayNutrition.protein
                    totalCarbs += dayNutrition.carbs
                    totalFat += dayNutrition.fat
                    dayCount += 1
                }
            }
        }
        
        let avgDivisor = max(dayCount, 1)
        
        return WeeklyNutritionAverages(
            avgCalories: Int(totalCalories / Double(avgDivisor)),
            avgProtein: Int(totalProtein / Double(avgDivisor)),
            avgCarbs: Int(totalCarbs / Double(avgDivisor)),
            avgFat: Int(totalFat / Double(avgDivisor))
        )
    }
    
    func getDayNutrition(for date: Date) -> DailyNutrition {
        return calculateDayNutrition(for: date)
    }
    
    private func calculateDayNutrition(for date: Date) -> DailyNutrition {
        let dayMeals = meals.filter { meal in
            Calendar.current.isDate(meal.date, inSameDayAs: date)
        }
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalFiber: Double = 0
        
        for meal in dayMeals {
            if let food = foodDatabase.findFood(by: meal.foodId) {
                let multiplier = meal.amount / 100.0
                totalCalories += food.calories * multiplier
                totalProtein += food.protein * multiplier
                totalCarbs += food.carbs * multiplier
                totalFat += food.fat * multiplier
                totalFiber += (food.fiber ?? 0) * multiplier
            }
        }
        
        return DailyNutrition(
            date: date,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            meals: dayMeals
        )
    }
    
    // MARK: - Goals Management
    func updateNutritionGoals(calories: Double? = nil, protein: Double? = nil, 
                            carbs: Double? = nil, fat: Double? = nil, fiber: Double? = nil) {
        goals = NutritionGoals(
            calories: calories ?? goals.calories,
            protein: protein ?? goals.protein,
            carbs: carbs ?? goals.carbs,
            fat: fat ?? goals.fat,
            fiber: fiber ?? goals.fiber
        )
        saveToStorage()
    }
    
    // MARK: - Food Search and Barcode
    func searchFoods(query: String) -> [Food] {
        return foodDatabase.searchFoods(query: query)
    }
    
    func findFood(by id: String) -> Food? {
        return foodDatabase.findFood(by: id)
    }
    
    func scanBarcode(_ barcode: String) -> Food? {
        return foodDatabase.findFoodByBarcode(barcode)
    }
    
    // MARK: - Helper Methods
    func formatNutritionValue(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }
    
    func calculateNutritionForAmount(food: Food, amount: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let multiplier = amount / 100.0
        return (
            calories: food.calories * multiplier,
            protein: food.protein * multiplier,
            carbs: food.carbs * multiplier,
            fat: food.fat * multiplier
        )
    }
}

// MARK: - Food Database
class FoodDatabase: ObservableObject {
    static let shared = FoodDatabase()
    
    private var foods: [Food] = []
    
    private init() {
        loadSampleFoods()
    }
    
    private func loadSampleFoods() {
        foods = [
            // Proteins
            Food(id: "chicken-breast", name: "Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, category: "Protein"),
            Food(id: "salmon", name: "Salmon", calories: 208, protein: 25, carbs: 0, fat: 12, fiber: 0, category: "Protein"),
            Food(id: "eggs", name: "Eggs", calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, category: "Protein"),
            Food(id: "ground-beef", name: "Ground Beef (85% lean)", calories: 250, protein: 25, carbs: 0, fat: 17, fiber: 0, category: "Protein"),
            Food(id: "greek-yogurt", name: "Greek Yogurt (Plain)", calories: 59, protein: 10, carbs: 3.6, fat: 0.4, fiber: 0, category: "Dairy"),
            
            // Carbohydrates
            Food(id: "brown-rice", name: "Brown Rice", calories: 112, protein: 2.6, carbs: 22, fat: 0.9, fiber: 1.8, category: "Carbohydrates"),
            Food(id: "sweet-potato", name: "Sweet Potato", calories: 86, protein: 1.6, carbs: 20, fat: 0.1, fiber: 3, category: "Carbohydrates"),
            Food(id: "oats", name: "Oats", calories: 389, protein: 16.9, carbs: 66, fat: 6.9, fiber: 10.6, category: "Carbohydrates"),
            Food(id: "quinoa", name: "Quinoa", calories: 120, protein: 4.4, carbs: 22, fat: 1.9, fiber: 2.8, category: "Carbohydrates"),
            
            // Fruits
            Food(id: "banana", name: "Banana", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12, category: "Fruits"),
            Food(id: "apple", name: "Apple", calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10, category: "Fruits"),
            Food(id: "berries", name: "Mixed Berries", calories: 57, protein: 0.7, carbs: 14, fat: 0.3, fiber: 2.4, category: "Fruits"),
            
            // Vegetables
            Food(id: "broccoli", name: "Broccoli", calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, category: "Vegetables"),
            Food(id: "spinach", name: "Spinach", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, category: "Vegetables"),
            Food(id: "carrots", name: "Carrots", calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, category: "Vegetables"),
            
            // Fats
            Food(id: "avocado", name: "Avocado", calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, category: "Fats"),
            Food(id: "almonds", name: "Almonds", calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, category: "Nuts & Seeds"),
            Food(id: "olive-oil", name: "Olive Oil", calories: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, category: "Fats"),
            Food(id: "peanut-butter", name: "Peanut Butter", calories: 588, protein: 25, carbs: 20, fat: 50, fiber: 6, category: "Nuts & Seeds"),
            
            // Dairy
            Food(id: "milk", name: "Milk (2%)", calories: 50, protein: 3.3, carbs: 4.8, fat: 2, fiber: 0, category: "Dairy"),
            Food(id: "cheese", name: "Cheddar Cheese", calories: 403, protein: 25, carbs: 1.3, fat: 33, fiber: 0, category: "Dairy"),
            
            // Grains
            Food(id: "bread", name: "Whole Wheat Bread", calories: 247, protein: 13, carbs: 41, fat: 4.2, fiber: 7, category: "Grains"),
            Food(id: "pasta", name: "Whole Wheat Pasta", calories: 124, protein: 5.3, carbs: 25, fat: 1.1, fiber: 3.9, category: "Grains")
        ]
    }
    
    func searchFoods(query: String) -> [Food] {
        if query.isEmpty {
            return Array(foods.prefix(10))
        }
        
        let lowercaseQuery = query.lowercased()
        return foods.filter { food in
            food.name.lowercased().contains(lowercaseQuery) ||
            food.category.lowercased().contains(lowercaseQuery) ||
            (food.brand?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }
    
    func findFood(by id: String) -> Food? {
        return foods.first { $0.id == id }
    }
    
    func findFoodByBarcode(_ barcode: String) -> Food? {
        return foods.first { $0.barcode == barcode }
    }
    
    func getFoodsByCategory(_ category: String) -> [Food] {
        return foods.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    func addCustomFood(_ food: Food) {
        foods.append(food)
    }
}