import SwiftUI

struct EnhancedNutritionView: View {
    @StateObject private var offService = OpenFoodFactsService.shared
    @State private var dailyNutrition = DailyNutrition()
    @State private var selectedDate = Date()
    @State private var showAddFood = false
    @State private var selectedMealType: MealEntry.MealType = .breakfast
    @State private var waterIntake: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header with date and calories
                        headerView
                        
                        // Daily progress overview
                        dailyProgressView
                        
                        // Macros breakdown
                        macrosBreakdownView
                        
                        // Water intake
                        waterIntakeView
                        
                        // Meals sections
                        ForEach(MealEntry.MealType.allCases, id: \.self) { mealType in
                            mealSectionView(for: mealType)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .refreshable {
                    await loadNutritionData()
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            EnhancedNutritionSearchView(mealType: selectedMealType.rawValue) { food in
                addFoodToMeal(food, to: selectedMealType)
                showAddFood = false
            }
        }
        .task {
            await loadNutritionData()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Date selector
            HStack {
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .disabled(Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                .opacity(Calendar.current.isDate(selectedDate, inSameDayAs: Date()) ? 0.3 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Daily calories overview
            VStack(spacing: 8) {
                Text("Daily Calories")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(dailyNutrition.totalCalories))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("/ \(Int(dailyNutrition.goals.calories))")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text("calories remaining: \(Int(dailyNutrition.goals.calories - dailyNutrition.totalCalories))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(dailyNutrition.totalCalories > dailyNutrition.goals.calories ? .red : .green)
            }
        }
    }
    
    private var dailyProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Progress")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 12)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.yellow, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(dailyNutrition.caloriesProgress, 1.0), height: 12)
                            .animation(.easeInOut, value: dailyNutrition.caloriesProgress),
                        alignment: .leading
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var macrosBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macronutrients")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                MacroProgressView(
                    title: "Protein",
                    current: dailyNutrition.totalProtein,
                    target: dailyNutrition.goals.protein,
                    unit: "g",
                    color: .red
                )
                
                MacroProgressView(
                    title: "Carbs",
                    current: dailyNutrition.totalCarbs,
                    target: dailyNutrition.goals.carbs,
                    unit: "g",
                    color: .yellow
                )
                
                MacroProgressView(
                    title: "Fat",
                    current: dailyNutrition.totalFat,
                    target: dailyNutrition.goals.fat,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var waterIntakeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Water Intake")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(waterIntake))/\(Int(dailyNutrition.goals.water)) ml")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { index in
                    Button(action: { addWater(250) }) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 16))
                            .foregroundColor(index < Int(waterIntake / 250) ? .blue : .white.opacity(0.3))
                    }
                }
                
                Spacer()
                
                Button(action: { addWater(250) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("250ml")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.8))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func mealSectionView(for mealType: MealEntry.MealType) -> some View {
        let meal = dailyNutrition.meals.first { $0.mealType == mealType }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: mealType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colorForMealType(mealType))
                
                Text(mealType.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let meal = meal {
                    Text("\(Int(meal.totalCalories)) cal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: { 
                    selectedMealType = mealType
                    showAddFood = true 
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            
            if let meal = meal, !meal.foods.isEmpty {
                VStack(spacing: 8) {
                    ForEach(meal.foods) { foodEntry in
                        FoodEntryRow(foodEntry: foodEntry)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No foods added yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Tap + to add food")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func colorForMealType(_ mealType: MealEntry.MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        }
    }
    
    private func addWater(_ amount: Double) {
        waterIntake += amount
        // Here you would normally save to Firebase/Core Data
    }
    
    private func addFoodToMeal(_ food: Food, to mealType: MealEntry.MealType) {
        let foodEntry = FoodEntry(food: food)
        
        // Find existing meal or create new one
        if let mealIndex = dailyNutrition.meals.firstIndex(where: { $0.mealType == mealType }) {
            dailyNutrition.meals[mealIndex].foods.append(foodEntry)
        } else {
            let newMeal = MealEntry(
                id: UUID().uuidString,
                date: selectedDate,
                mealType: mealType,
                foods: [foodEntry],
                notes: nil
            )
            dailyNutrition.meals.append(newMeal)
        }
        
        // Here you would normally save to Firebase/Core Data
    }
    
    private func loadNutritionData() async {
        // Load nutrition data for selected date
        // This would typically fetch from Firebase/Core Data
    }
}

struct MacroProgressView: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    var progress: Double {
        guard target > 0 else { return 0.0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack(spacing: 2) {
                    Text("\(Int(current))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Text("\(Int(target)) \(unit)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodEntryRow: View {
    let foodEntry: FoodEntry
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: foodEntry.food.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(foodEntry.food.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let brand = foodEntry.food.brand {
                    Text(brand)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Text("\(Int(foodEntry.actualServingSize))g")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(foodEntry.totalCalories)) cal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("P: \(Int(foodEntry.totalProtein))g")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                    
                    Text("C: \(Int(foodEntry.totalCarbs))g")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.yellow.opacity(0.8))
                    
                    Text("F: \(Int(foodEntry.totalFat))g")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    EnhancedNutritionView()
}