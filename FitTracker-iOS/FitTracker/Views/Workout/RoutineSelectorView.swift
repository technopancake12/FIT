import SwiftUI

struct RoutineSelectorView: View {
    let onRoutineSelected: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutService = WorkoutService.shared
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var routines: [WorkoutTemplate] = []
    
    private let categories = ["All", "Push", "Pull", "Legs", "Upper", "Lower", "Full Body", "Custom"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter
                    searchAndFilterSection
                    
                    // Routines List
                    routinesList
                }
            }
            .navigationTitle("Select Routine")
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
            await loadRoutines()
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.tertiaryText)
                
                TextField("Search routines...", text: $searchText)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .padding()
            .textFieldStyle()
            .padding(.horizontal)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
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
    
    // MARK: - Routines List
    private var routinesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredRoutines, id: \.id) { routine in
                    RoutineDetailCard(
                        routine: routine,
                        onSelect: {
                            onRoutineSelected(routine)
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
    private var filteredRoutines: [WorkoutTemplate] {
        var filtered = routines
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { routine in
                routine.name.localizedCaseInsensitiveContains(searchText) ||
                (routine.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                routine.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { routine in
                routine.tags.contains { $0.localizedCaseInsensitiveContains(selectedCategory.lowercased()) }
            }
        }
        
        return filtered
    }
    
    // MARK: - Helper Functions
    private func loadRoutines() async {
        // TODO: Load from database/service
        routines = sampleRoutines
    }
    
    // MARK: - Sample Data
    private var sampleRoutines: [WorkoutTemplate] {
        [
            WorkoutTemplate(
                id: "1",
                name: "Push Day",
                description: "Chest, shoulders, and triceps workout",
                exercises: [],
                tags: ["push", "upper", "strength"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .intermediate,
                estimatedDuration: 3600
            ),
            WorkoutTemplate(
                id: "2",
                name: "Pull Day",
                description: "Back and biceps focused workout",
                exercises: [],
                tags: ["pull", "upper", "strength"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .intermediate,
                estimatedDuration: 3600
            ),
            WorkoutTemplate(
                id: "3",
                name: "Leg Day",
                description: "Complete lower body workout",
                exercises: [],
                tags: ["legs", "lower", "strength"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .advanced,
                estimatedDuration: 4200
            ),
            WorkoutTemplate(
                id: "4",
                name: "Upper Body",
                description: "Push and pull exercises combined",
                exercises: [],
                tags: ["upper", "full", "strength"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .beginner,
                estimatedDuration: 3000
            ),
            WorkoutTemplate(
                id: "5",
                name: "Full Body",
                description: "Complete body workout",
                exercises: [],
                tags: ["full body", "strength", "cardio"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .intermediate,
                estimatedDuration: 4800
            )
        ]
    }
}

// MARK: - Routine Detail Card
struct RoutineDetailCard: View {
    let routine: WorkoutTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(routine.name)
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        if let description = routine.description {
                            Text(description)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                
                // Stats
                HStack(spacing: 16) {
                    StatBadge(
                        icon: "dumbbell.fill",
                        text: "\(routine.exercises.count) exercises",
                        color: .blue
                    )
                    
                    StatBadge(
                        icon: "clock.fill",
                        text: routine.estimatedDuration != nil ? "\(Int(routine.estimatedDuration! / 60))min" : "Unknown",
                        color: .orange
                    )
                    
                    StatBadge(
                        icon: "chart.bar.fill",
                        text: routine.difficulty.rawValue,
                        color: difficultyColor
                    )
                }
                
                // Tags
                if !routine.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(routine.tags, id: \.self) { tag in
                                Text(tag.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
    }
    
    private var difficultyColor: Color {
        switch routine.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(text)
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

#Preview {
    RoutineSelectorView { routine in
        print("Selected routine: \(routine.name)")
    }
} 