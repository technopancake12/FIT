import SwiftUI

struct FoodDetailSheet: View {
    let product: OFFProductDetails
    let onAdd: (Food) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = "100"
    @State private var selectedServingSize: ServingSize = .grams
    
    enum ServingSize: String, CaseIterable {
        case grams = "grams"
        case serving = "serving"
        case ml = "ml"
        
        var displayName: String {
            switch self {
            case .grams: return "grams (g)"
            case .serving: return "serving"
            case .ml: return "milliliters (ml)"
            }
        }
    }
    
    var calculatedAmount: Double {
        let inputAmount = Double(amount) ?? 100
        
        switch selectedServingSize {
        case .grams, .ml:
            return inputAmount
        case .serving:
            // Assume average serving is 100g if not specified
            let servingWeight = parseServingSize(product.servingSize) ?? 100
            return inputAmount * servingWeight
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Product header
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: product.imageFrontUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.6))
                                    )
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(spacing: 8) {
                                Text(product.productName ?? "Unknown Product")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if let brands = product.brands, !brands.isEmpty {
                                    Text(brands)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                HStack {
                                    if let grade = product.nutriscoreGrade {
                                        HStack(spacing: 6) {
                                            Text("Nutri-Score:")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                            NutriscoreGrade(grade: grade)
                                        }
                                    }
                                    
                                    if let nova = product.novaGroup {
                                        HStack(spacing: 6) {
                                            Text("NOVA:")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                            Text("\(nova)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 20, height: 20)
                                                .background(Circle().fill(novaColor(nova)))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Serving size selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Amount")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                TextField("Amount", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .frame(width: 80)
                                
                                Picker("Unit", selection: $selectedServingSize) {
                                    ForEach(ServingSize.allCases, id: \.self) { size in
                                        Text(size.displayName).tag(size)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .colorScheme(.dark)
                            }
                            
                            if selectedServingSize == .serving, let servingSize = product.servingSize {
                                Text("1 serving ≈ \(servingSize)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Nutrition facts
                        if let nutriments = product.nutriments {
                            NutritionFactsCard(
                                nutriments: nutriments,
                                amount: calculatedAmount
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Ingredients
                        if let ingredients = product.ingredients, !ingredients.isEmpty {
                            IngredientsCard(ingredients: ingredients)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let food = createFood()
                        onAdd(food)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    private func createFood() -> Food {
        let baseFood = product.toLocalFood()
        let multiplier = calculatedAmount / 100.0
        
        return Food(
            id: baseFood.id,
            name: baseFood.name,
            brand: baseFood.brand,
            barcode: baseFood.barcode,
            calories: baseFood.calories * multiplier,
            protein: baseFood.protein * multiplier,
            carbs: baseFood.carbs * multiplier,
            fat: baseFood.fat * multiplier,
            fiber: (baseFood.fiber ?? 0) * multiplier,
            sugar: (baseFood.sugar ?? 0) * multiplier,
            sodium: (baseFood.sodium ?? 0) * multiplier,
            servingSize: calculatedAmount,
            imageUrl: baseFood.imageUrl
        )
    }
    
    private func parseServingSize(_ servingSize: String?) -> Double? {
        guard let servingSize = servingSize else { return nil }
        
        let numbers = servingSize.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
        
        return numbers.first
    }
    
    private func novaColor(_ nova: Int) -> Color {
        switch nova {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
}

struct NutritionFactsCard: View {
    let nutriments: OFFNutriments
    let amount: Double
    
    var multiplier: Double {
        amount / 100.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Per \(Int(amount))g serving")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                if let calories = nutriments.energyKcal100g {
                    FoodNutritionRow(
                        label: "Calories",
                        value: "\(Int(calories * multiplier))",
                        unit: "kcal",
                        isMain: true
                    )
                }
                
                if let fat = nutriments.fat100g {
                    FoodNutritionRow(
                        label: "Total Fat",
                        value: String(format: "%.1f", fat * multiplier),
                        unit: "g"
                    )
                }
                
                if let saturatedFat = nutriments.saturatedFat100g {
                    NutritionRow(
                        label: "Saturated Fat",
                        value: String(format: "%.1f", saturatedFat * multiplier),
                        unit: "g",
                        isIndented: true
                    )
                }
                
                if let carbs = nutriments.carbohydrates100g {
                    FoodNutritionRow(
                        label: "Total Carbohydrates",
                        value: String(format: "%.1f", carbs * multiplier),
                        unit: "g"
                    )
                }
                
                if let sugars = nutriments.sugars100g {
                    NutritionRow(
                        label: "Sugars",
                        value: String(format: "%.1f", sugars * multiplier),
                        unit: "g",
                        isIndented: true
                    )
                }
                
                if let fiber = nutriments.fiber100g {
                    NutritionRow(
                        label: "Dietary Fiber",
                        value: String(format: "%.1f", fiber * multiplier),
                        unit: "g",
                        isIndented: true
                    )
                }
                
                if let protein = nutriments.proteins100g {
                    FoodNutritionRow(
                        label: "Protein",
                        value: String(format: "%.1f", protein * multiplier),
                        unit: "g"
                    )
                }
                
                if let sodium = nutriments.sodium100g {
                    FoodNutritionRow(
                        label: "Sodium",
                        value: String(format: "%.0f", sodium * multiplier * 1000),
                        unit: "mg"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct FoodNutritionRow: View {
    let label: String
    let value: String
    let unit: String
    let isMain: Bool
    let isIndented: Bool
    
    init(label: String, value: String, unit: String, isMain: Bool = false, isIndented: Bool = false) {
        self.label = label
        self.value = value
        self.unit = unit
        self.isMain = isMain
        self.isIndented = isIndented
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isMain ? 16 : 14, weight: isMain ? .bold : .medium))
                .foregroundColor(isMain ? .white : .white.opacity(0.9))
                .padding(.leading, isIndented ? 16 : 0)
            
            Spacer()
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: isMain ? 16 : 14, weight: .semibold))
                    .foregroundColor(isMain ? .white : .white.opacity(0.9))
                
                Text(unit)
                    .font(.system(size: isMain ? 14 : 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, isMain ? 4 : 2)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(isMain ? 0.2 : 0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct IngredientsCard: View {
    let ingredients: [OFFIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                    if let text = ingredient.text, !text.isEmpty {
                        Text(text.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    FoodDetailSheet(
        product: OFFProductDetails(
            productName: "Sample Product",
            genericName: "Sample Generic",
            brands: "Sample Brand",
            categories: "beverages",
            imageUrl: nil,
            imageFrontUrl: nil,
            imageNutritionUrl: nil,
            nutriments: OFFNutriments(
                energyKcal100g: 250,
                fat100g: 10.5,
                saturatedFat100g: 3.2,
                carbohydrates100g: 35.0,
                sugars100g: 8.5,
                fiber100g: 2.1,
                proteins100g: 6.8,
                salt100g: 0.5,
                sodium100g: 0.2
            ),
            ingredients: [],
            nutriscoreGrade: "B",
            novaGroup: 2,
            servingSize: "30g",
            packagingTags: [],
            countriesTags: ["en:united-states"]
        )
    ) { food in
        print("Added food: \(food.name)")
    }
}