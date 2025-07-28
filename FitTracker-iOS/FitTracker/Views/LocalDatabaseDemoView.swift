import SwiftUI

struct LocalDatabaseDemoView: View {
    @StateObject private var dbService = LocalDatabaseService.shared
    @State private var searchText = ""
    @State private var exercises: [DatabaseExercise] = []
    @State private var foods: [DatabaseFood] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Data Type", selection: $selectedTab) {
                    Text("Exercises").tag(0)
                    Text("Foods").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search bar
                SearchBar(text: $searchText, placeholder: selectedTab == 0 ? "Search exercises..." : "Search foods...")
                    .padding(.horizontal)
                
                // Content
                if isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if selectedTab == 0 {
                        ExerciseListView(exercises: exercises)
                    } else {
                        FoodListView(foods: foods)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Local Database Demo")
            .onChange(of: searchText) { newValue in
                performSearch()
            }
            .onChange(of: selectedTab) { _ in
                searchText = ""
                exercises = []
                foods = []
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            exercises = []
            foods = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if selectedTab == 0 {
                    exercises = try await dbService.searchExercises(query: searchText)
                } else {
                    foods = try await dbService.searchFoods(query: searchText)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Exercise List View
struct ExerciseListView: View {
    let exercises: [DatabaseExercise]
    
    var body: some View {
        if exercises.isEmpty {
            VStack {
                Image(systemName: "dumbbell")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No exercises found")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Try searching for exercises like 'curl', 'squat', or 'push-up'")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(exercises) { exercise in
                ExerciseRowView(exercise: exercise)
            }
        }
    }
}

struct ExerciseRowView: View {
    let exercise: DatabaseExercise
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let category = exercise.categoryName {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let equipment = exercise.equipment, !equipment.isEmpty {
                    Text("Equipment: \(equipment)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let muscles = exercise.muscles, !muscles.isEmpty {
                    Text("Muscles: \(muscles)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailView(exercise: exercise)
        }
    }
}

// MARK: - Food List View
struct FoodListView: View {
    let foods: [DatabaseFood]
    
    var body: some View {
        if foods.isEmpty {
            VStack {
                Image(systemName: "leaf")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No foods found")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Try searching for foods like 'apple', 'chicken', or 'bread'")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(foods) { food in
                FoodRowView(food: food)
            }
        }
    }
}

struct FoodRowView: View {
    let food: DatabaseFood
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.productName ?? food.genericName ?? "Unknown Food")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let brands = food.brands {
                        Text(brands)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let calories = food.energyKcal100g {
                        Text("\(Int(calories)) kcal/100g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let protein = food.proteins100g {
                        Text("P: \(String(format: "%.1f", protein))g")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if let carbs = food.carbohydrates100g {
                        Text("C: \(String(format: "%.1f", carbs))g")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if let fat = food.fat100g {
                        Text("F: \(String(format: "%.1f", fat))g")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            FoodDetailView(food: food)
        }
    }
}

// MARK: - Detail Views
struct ExerciseDetailView: View {
    let exercise: DatabaseExercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let category = exercise.categoryName {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Description
                    if let description = exercise.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(description)
                                .font(.body)
                        }
                    }
                    
                    // Equipment
                    if let equipment = exercise.equipment, !equipment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Equipment")
                                .font(.headline)
                            Text(equipment)
                                .font(.body)
                        }
                    }
                    
                    // Muscles
                    if let muscles = exercise.muscles, !muscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Muscles")
                                .font(.headline)
                            Text(muscles)
                                .font(.body)
                        }
                    }
                    
                    if let secondaryMuscles = exercise.musclesSecondary, !secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Muscles")
                                .font(.headline)
                            Text(secondaryMuscles)
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FoodDetailView: View {
    let food: DatabaseFood
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.productName ?? food.genericName ?? "Unknown Food")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let brands = food.brands {
                            Text(brands)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let categories = food.categories {
                            Text(categories)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Nutrition Facts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition Facts (per 100g)")
                            .font(.headline)
                        
                        NutritionRow(label: "Calories", value: food.energyKcal100g, unit: "kcal")
                        NutritionRow(label: "Protein", value: food.proteins100g, unit: "g", color: .blue)
                        NutritionRow(label: "Carbohydrates", value: food.carbohydrates100g, unit: "g", color: .orange)
                        NutritionRow(label: "Fat", value: food.fat100g, unit: "g", color: .red)
                        NutritionRow(label: "Fiber", value: food.fiber100g, unit: "g", color: .green)
                        NutritionRow(label: "Sugar", value: food.sugars100g, unit: "g", color: .purple)
                        NutritionRow(label: "Sodium", value: food.sodium100g, unit: "mg", color: .gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Additional Info
                    if let ingredients = food.ingredientsText {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                            Text(ingredients)
                                .font(.body)
                        }
                    }
                    
                    if let allergens = food.allergensTags {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Allergens")
                                .font(.headline)
                            Text(allergens)
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: Double?
    let unit: String
    var color: Color = .primary
    
    var body: some View {
        if let value = value {
            HStack {
                Text(label)
                    .foregroundColor(color)
                Spacer()
                Text("\(String(format: "%.1f", value)) \(unit)")
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    LocalDatabaseDemoView()
} 