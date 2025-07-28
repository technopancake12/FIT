import SwiftUI

struct ExerciseSearchView: View {
    @Binding var selectedExercises: [Exercise]
    @Binding var workoutName: String
    let onStartWorkout: () -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedEquipment = "All"
    
    private let categories = ["All"] + ["Chest", "Back", "Shoulders", "Arms", "Legs", "Abs"]
    private let equipment = ["All"] + ["Bodyweight", "Barbell", "Dumbbell", "Cable Machine", "Pull-up Bar"]
    
    private var filteredExercises: [Exercise] {
        ExerciseDatabase.shared.searchExercises(
            query: searchText,
            category: selectedCategory == "All" ? nil : selectedCategory,
            equipment: selectedEquipment == "All" ? nil : selectedEquipment
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filters
                searchAndFiltersView
                
                // Selected Exercises
                if !selectedExercises.isEmpty {
                    selectedExercisesView
                }
                
                // Exercise List
                exerciseListView
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            TextField("Workout name (optional)", text: $workoutName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if !selectedExercises.isEmpty {
                Button("Start Workout") {
                    onStartWorkout()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderedProminentButtonStyle())
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 1)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Category Filter
                    Menu("Category: \(selectedCategory)") {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    // Equipment Filter
                    Menu("Equipment: \(selectedEquipment)") {
                        ForEach(equipment, id: \.self) { equipmentType in
                            Button(equipmentType) {
                                selectedEquipment = equipmentType
                            }
                        }
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
    }
    
    private var selectedExercisesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Exercises (\(selectedExercises.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedExercises) { exercise in
                        selectedExerciseChip(exercise)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemGray6))
    }
    
    private func selectedExerciseChip(_ exercise: Exercise) -> some View {
        HStack(spacing: 4) {
            Text(exercise.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: {
                selectedExercises.removeAll { $0.id == exercise.id }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var exerciseListView: some View {
        List(filteredExercises) { exercise in
            ExerciseRowView(
                exercise: exercise,
                isSelected: selectedExercises.contains { $0.id == exercise.id },
                onToggle: { toggleExerciseSelection(exercise) }
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .listStyle(PlainListStyle())
    }
    
    private func toggleExerciseSelection(_ exercise: Exercise) {
        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(exercise.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(exercise.equipment)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(exercise.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(exercise.primaryMuscles.prefix(3), id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onToggle()
        }
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

#Preview {
    ExerciseSearchView(
        selectedExercises: .constant([]),
        workoutName: .constant(""),
        onStartWorkout: {},
        onCancel: {}
    )
}