import SwiftUI

// MARK: - Meal Section Card
struct MealSectionCard: View {
    let mealType: MealEntry.MealType
    let meals: [MealEntry]
    let onAddFood: () -> Void
    let onDeleteMeal: (String) -> Void
    let nutritionService: NutritionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: mealType.icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(mealType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if mealNutrition.calories > 0 {
                        Spacer()
                        Text("\(Int(mealNutrition.calories)) cal")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: onAddFood) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Meals List
            if meals.isEmpty {
                Text("No foods logged for \(mealType.displayName.lowercased())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(meals) { meal in
                        MealEntryRow(
                            meal: meal,
                            nutritionService: nutritionService,
                            onDelete: { onDeleteMeal(meal.id) }
                        )
                    }
                    
                    if mealNutrition.calories > 0 {
                        Divider()
                        
                        HStack {
                            Text("Total: \(Int(mealNutrition.calories)) cal")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("P: \(Int(mealNutrition.protein))g C: \(Int(mealNutrition.carbs))g F: \(Int(mealNutrition.fat))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var mealNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        for meal in meals {
            calories += meal.totalCalories
            protein += meal.totalProtein
            carbs += meal.totalCarbs
            fat += meal.totalFat
        }
        
        return (calories, protein, carbs, fat)
    }
}

// MARK: - Meal Entry Row
struct MealEntryRow: View {
    let meal: MealEntry
    let nutritionService: NutritionService
    let onDelete: () -> Void
    
    @State private var showEditAmount = false
    @State private var editedAmount: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(food?.name ?? "Unknown Food")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(Int(meal.amount))g")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(4)
                }
                
                if let nutrition = calculatedNutrition {
                    Text("\(Int(nutrition.calories)) cal • P: \(Int(nutrition.protein))g C: \(Int(nutrition.carbs))g F: \(Int(nutrition.fat))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                Button("Edit Amount") {
                    editedAmount = String(Int(meal.amount))
                    showEditAmount = true
                }
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(8)
        .alert("Edit Amount", isPresented: $showEditAmount) {
            TextField("Amount (g)", text: $editedAmount)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) { }
            
            Button("Save") {
                if let newAmount = Double(editedAmount), newAmount > 0 {
                    nutritionService.updateMealEntry(mealId: meal.id, amount: newAmount)
                }
            }
        }
    }
    
    private var food: Food? {
        meal.foods.first?.food
    }
    
    private var calculatedNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double)? {
        return (calories: meal.totalCalories, protein: meal.totalProtein, carbs: meal.totalCarbs, fat: meal.totalFat)
    }
}

// MARK: - Weekly Stats Card
struct WeeklyStatsCard: View {
    let averages: WeeklyNutritionAverages
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Weekly Averages")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 16) {
                WeeklyStatItem(
                    title: "Avg Calories",
                    value: "\(averages.avgCalories)",
                    color: .blue
                )
                
                WeeklyStatItem(
                    title: "Avg Protein",
                    value: "\(averages.avgProtein)g",
                    color: .red
                )
                
                WeeklyStatItem(
                    title: "Avg Carbs", 
                    value: "\(averages.avgCarbs)g",
                    color: .yellow
                )
                
                WeeklyStatItem(
                    title: "Avg Fat",
                    value: "\(averages.avgFat)g",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WeeklyStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Food Search View
struct FoodSearchView: View {
    let mealType: MealEntry.MealType
    let nutritionService: NutritionService
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var searchResults: [Food] = []
    @State private var selectedFood: Food?
    @State private var amount: String = "100"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                }
                .padding()
                
                if let selectedFood = selectedFood {
                    // Food Details & Amount Selection
                    ScrollView {
                        VStack(spacing: 20) {
                            FoodDetailsCard(food: selectedFood)
                            
                            AmountSelectionCard(
                                food: selectedFood,
                                amount: $amount
                            )
                            
                            if let amountValue = Double(amount), amountValue > 0 {
                                NutritionPreviewCard(
                                    food: selectedFood,
                                    amount: amountValue
                                )
                            }
                            
                            HStack(spacing: 16) {
                                Button("Back") {
                                    self.selectedFood = nil
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                                
                                Button("Add Food") {
                                    if let amountValue = Double(amount), amountValue > 0 {
                                        nutritionService.addMealEntry(
                                            foodId: selectedFood.id,
                                            amount: amountValue,
                                            mealType: mealType
                                        )
                                        isPresented = false
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .disabled(Double(amount) == nil || Double(amount) ?? 0 <= 0)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    // Search Results
                    List(searchResults) { food in
                        FoodSearchResultRow(food: food) {
                            selectedFood = food
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    if searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("Search for foods to add to \(mealType.displayName.lowercased())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchResults.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No foods found")
                                .font(.headline)
                            
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Create Custom Food") {
                                // TODO: Implement custom food creation
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Add Food to \(mealType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            performSearch()
        }
        .onChange(of: searchText) {
            performSearch()
        }
    }
    
    private func performSearch() {
        searchResults = nutritionService.searchFoods(query: searchText)
    }
}

struct FoodSearchResultRow: View {
    let food: Food
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(food.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(food.calories)) cal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("per 100g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FoodDetailsCard: View {
    let food: Food
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(food.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                NutritionFactItem(label: "Calories", value: "\(Int(food.calories))/100g")
                NutritionFactItem(label: "Protein", value: String(format: "%.1f", food.protein) + "g")
                NutritionFactItem(label: "Carbs", value: String(format: "%.1f", food.carbs) + "g")
                NutritionFactItem(label: "Fat", value: String(format: "%.1f", food.fat) + "g")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NutritionFactItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AmountSelectionCard: View {
    let food: Food
    @Binding var amount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount (grams)")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Amount", text: $amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct NutritionPreviewCard: View {
    let food: Food
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition for \(Int(amount))g:")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                NutritionFactItem(
                    label: "Calories",
                    value: "\(Int(food.calories * amount / 100))"
                )
                NutritionFactItem(
                    label: "Protein",
                    value: String(format: "%.1f", food.protein * amount / 100) + "g"
                )
                NutritionFactItem(
                    label: "Carbs",
                    value: String(format: "%.1f", food.carbs * amount / 100) + "g"
                )
                NutritionFactItem(
                    label: "Fat",
                    value: String(format: "%.1f", food.fat * amount / 100) + "g"
                )
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// Note: BarcodeScannerView is implemented in OpenFoodFactsService.swift