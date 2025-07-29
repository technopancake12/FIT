import SwiftUI

struct USFoodSearchView: View {
    @StateObject private var offService = OpenFoodFactsService.shared
    @State private var searchText = ""
    @State private var foods: [Food] = []
    @State private var isLoading = false
    @State private var selectedMealType = "Breakfast"
    @State private var showFoodDetail = false
    @State private var selectedFood: Food?
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Header
                searchHeaderSection
                
                // Meal Type Selector
                mealTypeSelectorSection
                
                // Content Area
                if isLoading {
                    loadingView
                } else if foods.isEmpty && !searchText.isEmpty {
                    emptySearchState
                } else if foods.isEmpty {
                    initialState
                } else {
                    foodListSection
                }
            }
        }
        .sheet(item: $selectedFood) { food in
            FoodDetailView(food: food, mealType: selectedMealType)
        }
        .task {
            await loadPopularFoods()
        }
    }
    
    private var searchHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
                
                Text("US Food Database")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(foods.count) results")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search US foods (brands, products...)", text: $searchText)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        Task { await loadPopularFoods() }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var mealTypeSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(mealTypes, id: \.self) { mealType in
                    Button(action: { selectedMealType = mealType }) {
                        HStack(spacing: 6) {
                            Image(systemName: mealTypeIcon(mealType))
                                .font(.system(size: 12, weight: .medium))
                            
                            Text(mealType)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedMealType == mealType ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedMealType == mealType ? Color.green.opacity(0.8) : Color.white.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Searching US food database...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var initialState: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(.green.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Search US Foods")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Find nutrition info for US brands and products")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("Try searching for:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    SearchSuggestionChip(text: "Coca Cola", action: { searchSuggestion("Coca Cola") })
                    SearchSuggestionChip(text: "Cheerios", action: { searchSuggestion("Cheerios") })
                    SearchSuggestionChip(text: "Starbucks", action: { searchSuggestion("Starbucks") })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No results found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Try searching for specific US brands or product names")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var foodListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(foods, id: \.id) { food in
                    USFoodCard(food: food, mealType: selectedMealType) {
                        selectedFood = food
                        showFoodDetail = true
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private func mealTypeIcon(_ mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.fill"
        case "Snack": return "sparkles"
        default: return "fork.knife"
        }
    }
    
    private func searchSuggestion(_ query: String) {
        searchText = query
        performSearch()
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            Task { await loadPopularFoods() }
            return
        }
        
        Task {
            do {
                isLoading = true
                let searchResults = try await offService.searchProducts(query: searchText, pageSize: 50)
            foods = searchResults.products.map { $0.toFood() }
                isLoading = false
            } catch {
                print("Error searching foods: \(error)")
                isLoading = false
            }
        }
    }
    
    private func loadPopularFoods() async {
        // Load some popular US foods as initial display
        do {
            let searchResults = try await offService.searchProducts(query: "", pageSize: 20)
            foods = searchResults.products.map { $0.toFood() }
        } catch {
            print("Error loading popular foods: \(error)")
        }
    }
}

struct USFoodCard: View {
    let food: Food
    let mealType: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food Image
                AsyncImage(url: URL(string: food.imageFrontUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Food Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.productName ?? "Unknown Product")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let brands = food.brands, !brands.isEmpty {
                        Text(brands)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                    
                    // Nutrition Preview
                    HStack(spacing: 12) {
                        if let calories = food.energyKcal100g {
                            NutritionBadge(label: "Cal", value: "\(Int(calories))", color: .orange)
                        }
                        
                        if let protein = food.proteins100g {
                            NutritionBadge(label: "Pro", value: "\(Int(protein))g", color: .red)
                        }
                        
                        if let carbs = food.carbohydrates100g {
                            NutritionBadge(label: "Carb", value: "\(Int(carbs))g", color: .blue)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Add Button
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    Text("Add")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.2))
        )
    }
}

struct SearchSuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FoodDetailView: View {
    let food: Food
    let mealType: String
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double = 100
    @State private var servingUnit = "g"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Food Header
                        foodHeaderSection
                        
                        // Serving Size
                        servingSizeSection
                        
                        // Nutrition Facts
                        nutritionFactsSection
                        
                        // Add to Log Button
                        addToLogButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var foodHeaderSection: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: food.imageFrontUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 8) {
                Text(food.productName ?? "Unknown Product")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let brands = food.brands, !brands.isEmpty {
                    Text(brands)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
                
                if let categories = food.categories, !categories.isEmpty {
                    Text(categories.replacingOccurrences(of: "en:", with: "").capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Serving Size")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                TextField("100", value: $quantity, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Picker("Unit", selection: $servingUnit) {
                    Text("g").tag("g")
                    Text("oz").tag("oz")
                    Text("cup").tag("cup")
                    Text("piece").tag("piece")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var nutritionFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts (per \(Int(quantity))\(servingUnit))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let calories = food.energyKcal100g {
                    USNutritionRow(label: "Calories", value: "\(Int(calories * quantity / 100))", unit: "kcal", color: .orange)
                }
                
                if let protein = food.proteins100g {
                    USNutritionRow(label: "Protein", value: String(format: "%.1f", protein * quantity / 100), unit: "g", color: .red)
                }
                
                if let carbs = food.carbohydrates100g {
                    USNutritionRow(label: "Carbohydrates", value: String(format: "%.1f", carbs * quantity / 100), unit: "g", color: .blue)
                }
                
                if let fat = food.fat100g {
                    USNutritionRow(label: "Fat", value: String(format: "%.1f", fat * quantity / 100), unit: "g", color: .purple)
                }
                
                if let fiber = food.fiber100g {
                    USNutritionRow(label: "Fiber", value: String(format: "%.1f", fiber * quantity / 100), unit: "g", color: .green)
                }
                
                if let sugars = food.sugars100g {
                    USNutritionRow(label: "Sugars", value: String(format: "%.1f", sugars * quantity / 100), unit: "g", color: .yellow)
                }
                
                if let sodium = food.sodium100g {
                    USNutritionRow(label: "Sodium", value: String(format: "%.0f", sodium * quantity / 100), unit: "mg", color: .cyan)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var addToLogButton: some View {
        Button(action: addToLog) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                
                Text("Add to \(mealType)")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.8))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func addToLog() {
        // Add food to daily nutrition log
        print("Adding \(food.productName ?? "Unknown") to \(mealType)")
        dismiss()
    }
}

struct USNutritionRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    USFoodSearchView()
}