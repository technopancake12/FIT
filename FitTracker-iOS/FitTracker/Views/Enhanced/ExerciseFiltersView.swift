import SwiftUI

struct ExerciseFiltersView: View {
    @StateObject private var openWorkoutService = OpenWorkoutService.shared
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCategory: ExerciseCategory?
@Binding var selectedMuscles: Set<Muscle>
@Binding var selectedEquipment: OpenWorkoutEquipment?
    
    let onApply: () -> Void
    
    @State private var categories: [ExerciseCategory] = []
    @State private var muscles: [Muscle] = []
    @State private var equipment: [OpenWorkoutEquipment] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .task {
            await loadFilterData()
        }
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundGradient
            
            if isLoading {
                loadingView
            } else {
                filterContent
            }
        }
        .navigationTitle("Exercise Filters")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                clearAllButton
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                applyButton
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.1),
                Color(red: 0.1, green: 0.1, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var filterContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                categorySection
                musclesSection
                equipmentSection
            }
            .padding(20)
        }
    }
    
    private var categorySection: some View {
        FilterSection(title: "Category", icon: "list.bullet") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(categories, id: \.id) { category in
                    FilterButton(
                        title: category.name,
                        isSelected: selectedCategory?.id == category.id,
                        color: .blue
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
    }
    
    private var musclesSection: some View {
        FilterSection(title: "Target Muscles", icon: "figure.strengthtraining.traditional") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(muscles, id: \.id) { muscle in
                    FilterButton(
                        title: muscle.name,
                        isSelected: selectedMuscles.contains(muscle),
                        color: .green
                    ) {
                        toggleMuscle(muscle)
                    }
                }
            }
        }
    }
    
    private var equipmentSection: some View {
        FilterSection(title: "Equipment", icon: "dumbbell") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(equipment, id: \.id) { equipmentItem in
                    FilterButton(
                        title: equipmentItem.name,
                        isSelected: selectedEquipment?.id == equipmentItem.id,
                        color: .orange
                    ) {
                        toggleEquipment(equipmentItem)
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading filters...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var clearAllButton: some View {
        Button("Clear All") {
            selectedCategory = nil
            selectedMuscles.removeAll()
            selectedEquipment = nil
        }
        .foregroundColor(.red)
    }
    
    private var applyButton: some View {
        Button("Apply") {
            onApply()
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.blue)
    }
    
    private func toggleCategory(_ category: ExerciseCategory) {
        if selectedCategory?.id == category.id {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
    
    private func toggleMuscle(_ muscle: Muscle) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }
    
    private func toggleEquipment(_ equipmentItem: OpenWorkoutEquipment) {
        if selectedEquipment?.id == equipmentItem.id {
            selectedEquipment = nil
        } else {
            selectedEquipment = equipmentItem
        }
    }
    
    private func loadFilterData() async {
        do {
            let openWorkoutService = OpenWorkoutService.shared
            async let categoriesTask = openWorkoutService.fetchCategories()
            async let musclesTask = openWorkoutService.fetchMuscles()
            async let equipmentTask = openWorkoutService.fetchEquipment()
            
            let (_, _, _) = try await (categoriesTask, musclesTask, equipmentTask)
            
            await MainActor.run {
                self.categories = openWorkoutService.categories
                self.muscles = openWorkoutService.muscles
                self.equipment = openWorkoutService.equipment
                self.isLoading = false
            }
        } catch {
            print("Error loading filter data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseFiltersView(
        selectedCategory: .constant(nil as ExerciseCategory?),
        selectedMuscles: .constant(Set<Muscle>()),
        selectedEquipment: .constant(nil as OpenWorkoutEquipment?),
        onApply: {}
    )
}