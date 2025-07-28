import SwiftUI

struct ExerciseFiltersView: View {
    @StateObject private var wgerService = WgerAPIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCategory: WgerCategory?
    @Binding var selectedMuscles: Set<WgerMuscle>
    @Binding var selectedEquipment: WgerEquipment?
    
    let onApply: () -> Void
    
    @State private var categories: [WgerCategory] = []
    @State private var muscles: [WgerMuscle] = []
    @State private var equipment: [WgerEquipment] = []
    @State private var isLoading = true
    
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
                        // Categories Section
                        FilterSection(title: "Category", icon: "list.bullet") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(categories, id: \.id) { category in
                                    FilterButton(
                                        title: category.name,
                                        isSelected: selectedCategory?.id == category.id,
                                        color: .blue
                                    ) {
                                        if selectedCategory?.id == category.id {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Muscles Section
                        FilterSection(title: "Target Muscles", icon: "figure.strengthtraining.traditional") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(muscles, id: \.id) { muscle in
                                    FilterButton(
                                        title: muscle.nameEn,
                                        isSelected: selectedMuscles.contains(muscle),
                                        color: .green
                                    ) {
                                        if selectedMuscles.contains(muscle) {
                                            selectedMuscles.remove(muscle)
                                        } else {
                                            selectedMuscles.insert(muscle)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Equipment Section
                        FilterSection(title: "Equipment", icon: "dumbbell") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(equipment, id: \.id) { equipmentItem in
                                    FilterButton(
                                        title: equipmentItem.name,
                                        isSelected: selectedEquipment?.id == equipmentItem.id,
                                        color: .orange
                                    ) {
                                        if selectedEquipment?.id == equipmentItem.id {
                                            selectedEquipment = nil
                                        } else {
                                            selectedEquipment = equipmentItem
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Loading filters...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .navigationTitle("Exercise Filters")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        selectedMuscles.removeAll()
                        selectedEquipment = nil
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadFilterData()
        }
    }
    
    private func loadFilterData() async {
        do {
            async let categoriesTask = wgerService.fetchCategories()
            async let musclesTask = wgerService.fetchMuscles()
            async let equipmentTask = wgerService.fetchEquipment()
            
            let (loadedCategories, loadedMuscles, loadedEquipment) = try await (categoriesTask, musclesTask, equipmentTask)
            
            await MainActor.run {
                self.categories = loadedCategories
                self.muscles = loadedMuscles
                self.equipment = loadedEquipment
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
        selectedCategory: .constant(nil as WgerCategory?),
        selectedMuscles: .constant(Set<WgerMuscle>()),
        selectedEquipment: .constant(nil as WgerEquipment?),
        onApply: {}
    )
}