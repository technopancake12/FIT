import SwiftUI

struct NutritionView: View {
    @StateObject private var nutritionService = NutritionService()
    @State private var showFoodSearch = false
    @State private var showBarcodeScanner = false
    @State private var selectedMealType: MealEntry.MealType = .breakfast
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Daily Overview
                    MacroOverviewCard(
                        dailyNutrition: nutritionService.dailyNutrition,
                        goals: nutritionService.goals,
                        macroPercentages: nutritionService.calculateMacroPercentages()
                    )
                    
                    // Add Food Actions
                    AddFoodActionsCard(
                        onAddFood: { selectedMealType = .breakfast; showFoodSearch = true },
                        onScanBarcode: { selectedMealType = .breakfast; showBarcodeScanner = true }
                    )
                    
                    // Meal Sections
                    ForEach(MealEntry.MealType.allCases, id: \.self) { mealType in
                        MealSectionCard(
                            mealType: mealType,
                            meals: nutritionService.getMealsByType(mealType: mealType),
                            onAddFood: {
                                selectedMealType = mealType
                                showFoodSearch = true
                            },
                            onDeleteMeal: { mealId in
                                nutritionService.deleteMealEntry(mealId: mealId)
                            },
                            nutritionService: nutritionService
                        )
                    }
                    
                    // Weekly Stats
                    WeeklyStatsCard(averages: nutritionService.getWeeklyAverages())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Set Goals") {
                            // TODO: Show goals setting view
                        }
                        Button("View History") {
                            // TODO: Show nutrition history
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchView(
                    mealType: selectedMealType,
                    nutritionService: nutritionService,
                    isPresented: $showFoodSearch
                )
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    mealType: selectedMealType,
                    nutritionService: nutritionService,
                    isPresented: $showBarcodeScanner
                )
            }
        }
        .onAppear {
            nutritionService.updateDailyNutrition()
        }
    }
}

// MARK: - Macro Overview Card
struct MacroOverviewCard: View {
    let dailyNutrition: DailyNutrition?
    let goals: NutritionGoals
    let macroPercentages: MacroPercentages
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Nutrition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Calories Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Calories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(dailyNutrition?.calories ?? 0))/\(Int(goals.calories))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: (dailyNutrition?.calories ?? 0) / goals.calories)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2)
            }
            
            // Macros Grid
            HStack(spacing: 16) {
                MacroCard(
                    name: "Protein",
                    value: Int(dailyNutrition?.protein ?? 0),
                    unit: "g",
                    percentage: macroPercentages.protein,
                    color: .red,
                    progress: (dailyNutrition?.protein ?? 0) / goals.protein
                )
                
                MacroCard(
                    name: "Carbs",
                    value: Int(dailyNutrition?.carbs ?? 0),
                    unit: "g",
                    percentage: macroPercentages.carbs,
                    color: .yellow,
                    progress: (dailyNutrition?.carbs ?? 0) / goals.carbs
                )
                
                MacroCard(
                    name: "Fat",
                    value: Int(dailyNutrition?.fat ?? 0),
                    unit: "g",
                    percentage: macroPercentages.fat,
                    color: .green,
                    progress: (dailyNutrition?.fat ?? 0) / goals.fat
                )
            }
            
            // Fiber
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fiber")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(dailyNutrition?.fiber ?? 0))g/\(Int(goals.fiber))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: (dailyNutrition?.fiber ?? 0) / goals.fiber)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(x: 1, y: 1.5)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroCard: View {
    let name: String
    let value: Int
    let unit: String
    let percentage: Int
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)\(unit)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("\(name) (\(percentage)%)")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Food Actions Card
struct AddFoodActionsCard: View {
    let onAddFood: () -> Void
    let onScanBarcode: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onAddFood) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        Text("Add Food")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: onScanBarcode) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.headline)
                        Text("Scan Barcode")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NutritionView()
}