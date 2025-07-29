import SwiftUI
import Foundation

struct ExerciseSearchView: View {
    let onExerciseSelected: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openWorkoutService = OpenWorkoutService.shared
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    
    private let categories = ["All", "Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter
                    searchAndFilterSection
                    
                    // Exercises List
                    exercisesList
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primaryText)
                }
            }
        }
        .task {
            await loadExercises()
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.tertiaryText)
                
                TextField("Search exercises...", text: $searchText)
                    .foregroundColor(Theme.Colors.primaryText)
                    .onSubmit {
                        performSearch()
                    }
            }
            .padding()
            .textFieldStyle()
            .padding(.horizontal)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { 
                            selectedCategory = category
                            filterExercises()
                        }) {
                            Text(category)
                                .font(Theme.Typography.footnote)
                                .foregroundColor(selectedCategory == category ? Theme.Colors.secondary : Theme.Colors.secondaryText)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedCategory == category ? Theme.Colors.accent : Theme.Colors.secondaryBackground)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Exercises List
    private var exercisesList: some View {
        Group {
            if isLoading {
                loadingView
            } else if filteredExercises.isEmpty {
                emptyStateView
            } else {
                exercisesListView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading exercises...")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text("No exercises found")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("Try adjusting your search or category filter")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Exercises List View
    private var exercisesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExerciseSearchCard(
                        exercise: exercise,
                        onSelect: {
                            onExerciseSelected(exercise)
                            dismiss()
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Computed Properties
    private var filteredExercises: [Exercise] {
        var filtered = exercises
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.localizedCaseInsensitiveContains(searchText) ||
                exercise.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { exercise in
                exercise.category.localizedCaseInsensitiveContains(selectedCategory.lowercased()) ||
                exercise.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(selectedCategory.lowercased()) }
            }
        }
        
        return filtered
    }
    
    // MARK: - Helper Functions
    private func loadExercises() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await openWorkoutService.fetchExercises()
            exercises = openWorkoutService.exercises
        } catch {
            print("Error loading exercises: \(error)")
            exercises = sampleExercises
        }
    }
    
    private func performSearch() {
        // Search is handled by the computed property
    }
    
    private func filterExercises() {
        // Filtering is handled by the computed property
    }
    
    // MARK: - Sample Data
    private var sampleExercises: [Exercise] {
        [
            Exercise(
                id: "1",
                name: "Bench Press",
                category: "Chest",
                primaryMuscles: ["Chest", "Triceps", "Shoulders"],
                secondaryMuscles: ["Forearms"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: ["Lie on bench", "Lower bar to chest", "Press up"],
                tips: ["Keep feet flat", "Retract shoulder blades"],
                alternatives: ["Dumbbell Press", "Push-ups"]
            ),
            Exercise(
                id: "2",
                name: "Squat",
                category: "Legs",
                primaryMuscles: ["Quadriceps", "Glutes"],
                secondaryMuscles: ["Hamstrings", "Calves"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: ["Stand with bar on shoulders", "Lower down", "Stand up"],
                tips: ["Keep chest up", "Knees over toes"],
                alternatives: ["Goblet Squat", "Bodyweight Squat"]
            ),
            Exercise(
                id: "3",
                name: "Deadlift",
                category: "Back",
                primaryMuscles: ["Lower Back", "Hamstrings"],
                secondaryMuscles: ["Glutes", "Traps"],
                equipment: "Barbell",
                difficulty: .advanced,
                instructions: ["Stand over bar", "Grip bar", "Lift up"],
                tips: ["Keep bar close", "Hips back"],
                alternatives: ["Romanian Deadlift", "Kettlebell Deadlift"]
            ),
            Exercise(
                id: "4",
                name: "Pull-up",
                category: "Back",
                primaryMuscles: ["Lats", "Biceps"],
                secondaryMuscles: ["Traps", "Forearms"],
                equipment: "Bodyweight",
                difficulty: .intermediate,
                instructions: ["Hang from bar", "Pull up", "Lower down"],
                tips: ["Full range of motion", "Control descent"],
                alternatives: ["Assisted Pull-up", "Lat Pulldown"]
            ),
            Exercise(
                id: "5",
                name: "Overhead Press",
                category: "Shoulders",
                primaryMuscles: ["Shoulders", "Triceps"],
                secondaryMuscles: ["Traps", "Core"],
                equipment: "Barbell",
                difficulty: .intermediate,
                instructions: ["Stand with bar at shoulders", "Press up", "Lower down"],
                tips: ["Keep core tight", "Don't lean back"],
                alternatives: ["Dumbbell Press", "Push Press"]
            )
        ]
    }
}

// MARK: - Exercise Search Card
struct ExerciseSearchCard: View {
    let exercise: Exercise
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Exercise Icon
                VStack {
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 24))
                        .foregroundColor(exerciseColor)
                }
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(exerciseColor.opacity(0.2))
                )
                
                // Exercise Info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(exercise.name)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(exercise.category)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.accent)
                    
                    if !exercise.primaryMuscles.isEmpty {
                        Text(exercise.primaryMuscles.joined(separator: ", "))
                            .font(Theme.Typography.caption1)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Difficulty Badge
                Text(exercise.difficulty.rawValue)
                    .font(Theme.Typography.caption1)
                    .foregroundColor(Theme.Colors.secondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(difficultyColor)
                    )
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .padding(Theme.Spacing.sm)
            .cardStyle()
        }
    }
    
    private var exerciseIcon: String {
        switch exercise.category.lowercased() {
        case "chest": return "heart.fill"
        case "back": return "figure.strengthtraining.traditional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.arms.open"
        case "legs": return "figure.walk"
        case "core": return "figure.core.training"
        case "cardio": return "heart.circle.fill"
        default: return "dumbbell.fill"
        }
    }
    
    private var exerciseColor: Color {
        switch exercise.category.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "arms": return .purple
        case "legs": return .green
        case "core": return .yellow
        case "cardio": return .pink
        default: return .gray
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
    ExerciseSearchView { exercise in
        print("Selected exercise: \(exercise.name)")
    }
} 