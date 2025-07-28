import SwiftUI

struct DailyNutritionLogView: View {
    @State private var selectedDate = Date()
    @State private var dailyNutrition = DailyNutrition()
    @State private var mealEntries: [String: [NutritionEntry]] = [
        "Breakfast": [],
        "Lunch": [],
        "Dinner": [],
        "Snacks": []
    ]
    @State private var showAddFood = false
    @State private var selectedMealForAdd = "Breakfast"
    
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    dateSelector
                    
                    // Daily Summary
                    dailySummarySection
                    
                    // Meal Sections
                    ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { mealType in
                        mealSection(mealType: mealType)
                    }
                    
                    // Water Tracking
                    waterTrackingSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showAddFood) {
            USFoodSearchView()
        }
    }
    
    private var dateSelector: some View {
        HStack {
            Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(selectedDate, style: .date)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if Calendar.current.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Text(relativeDateText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
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
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Summary")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(dailyNutrition.totalCalories))/\(Int(dailyNutrition.goals.calories)) cal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            // Calories Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(dailyNutrition.caloriesProgress, 1.0))
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: dailyNutrition.caloriesProgress)
                
                VStack(spacing: 4) {
                    Text("\(Int(dailyNutrition.totalCalories))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("calories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Macros Summary
            HStack(spacing: 16) {
                MacroSummaryCard(
                    title: "Protein",
                    current: dailyNutrition.totalProtein,
                    target: dailyNutrition.goals.protein,
                    unit: "g",
                    color: .red
                )
                
                MacroSummaryCard(
                    title: "Carbs",
                    current: dailyNutrition.totalCarbs,
                    target: dailyNutrition.goals.carbs,
                    unit: "g",
                    color: .blue
                )
                
                MacroSummaryCard(
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
    
    private func mealSection(mealType: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: mealIcon(mealType))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(mealColor(mealType))
                    
                    Text(mealType)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(mealCalories(mealType)) cal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: { 
                    selectedMealForAdd = mealType
                    showAddFood = true 
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            
            if let entries = mealEntries[mealType], !entries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        NutritionEntryRow(entry: entry) {
                            removeMealEntry(entry, from: mealType)
                        }
                    }
                }
            } else {
                HStack {
                    Text("No foods logged for \(mealType.lowercased())")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Button("Add Food") {
                        selectedMealForAdd = mealType
                        showAddFood = true
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
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
    
    private var waterTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Water Intake")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(dailyNutrition.waterIntake))/\(Int(dailyNutrition.goals.water)) ml")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Water Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * min(dailyNutrition.waterProgress, 1.0), height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .animation(.easeInOut, value: dailyNutrition.waterProgress)
                }
            }
            .frame(height: 8)
            
            // Water Quick Add Buttons
            HStack(spacing: 12) {
                ForEach([250, 500, 750], id: \.self) { amount in
                    Button("+\(amount)ml") {
                        addWater(amount)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                    )
                }
                
                Spacer()
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
    
    private var relativeDateText: String {
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDate(selectedDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
            return "Yesterday"
        } else if calendar.isDate(selectedDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today) ?? today) {
            return "Tomorrow"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: selectedDate, relativeTo: today)
        }
    }
    
    private func mealIcon(_ mealType: String) -> String {
        switch mealType {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.fill"
        case "Snacks": return "sparkles"
        default: return "fork.knife"
        }
    }
    
    private func mealColor(_ mealType: String) -> Color {
        switch mealType {
        case "Breakfast": return .orange
        case "Lunch": return .yellow
        case "Dinner": return .purple
        case "Snacks": return .green
        default: return .blue
        }
    }
    
    private func mealCalories(_ mealType: String) -> Int {
        return mealEntries[mealType]?.reduce(0) { $0 + Int($1.calories) } ?? 0
    }
    
    private func addWater(_ amount: Int) {
        dailyNutrition.waterIntake += Double(amount)
        dailyNutrition.waterIntake = min(dailyNutrition.waterIntake, dailyNutrition.goals.water)
    }
    
    private func removeMealEntry(_ entry: NutritionEntry, from mealType: String) {
        mealEntries[mealType]?.removeAll { $0.id == entry.id }
        updateDailyNutrition()
    }
    
    private func updateDailyNutrition() {
        // Recalculate daily totals
        let allEntries = mealEntries.values.flatMap { $0 }
        dailyNutrition.totalCalories = allEntries.reduce(0) { $0 + $1.calories }
        dailyNutrition.totalProtein = allEntries.reduce(0) { $0 + $1.protein }
        dailyNutrition.totalCarbs = allEntries.reduce(0) { $0 + $1.carbs }
        dailyNutrition.totalFat = allEntries.reduce(0) { $0 + $1.fat }
    }
}

struct MacroSummaryCard: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(Int(current))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("of \(Int(target))\(unit)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct NutritionEntryRow: View {
    let entry: NutritionEntry
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(entry.quantity, specifier: "%.0f")g • \(Int(entry.calories)) cal")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("P: \(Int(entry.protein))g")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 4)))
                
                Text("C: \(Int(entry.carbs))g")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 4)))
                
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct NutritionEntry: Identifiable {
    let id = UUID()
    let foodName: String
    let quantity: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let timestamp: Date
}

#Preview {
    DailyNutritionLogView()
}