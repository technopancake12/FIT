import SwiftUI

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutService = WorkoutService.shared
    @State private var workouts: [HevyWorkout] = []
    @State private var selectedTimeframe: Timeframe = .week
    @State private var isLoading = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Stats
                    headerStats
                    
                    // Timeframe Filter
                    timeframeFilter
                    
                    // Workouts List
                    workoutsList
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primaryText)
                }
            }
        }
        .task {
            await loadWorkouts()
        }
    }
    
    // MARK: - Header Stats
    private var headerStats: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Your Progress")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text("Track your fitness journey")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Workouts",
                    value: "\(filteredWorkouts.count)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Time",
                    value: totalWorkoutTime,
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Exercises",
                    value: "\(totalExercises)",
                    icon: "figure.strengthtraining.traditional",
                    color: .green
                )
                
                StatCard(
                    title: "Sets",
                    value: "\(totalSets)",
                    icon: "repeat.circle.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Timeframe Filter
    private var timeframeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                            Button(action: { selectedTimeframe = timeframe }) {
                            Text(timeframe.rawValue)
                                .font(Theme.Typography.footnote)
                                .foregroundColor(selectedTimeframe == timeframe ? Theme.Colors.secondary : Theme.Colors.secondaryText)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedTimeframe == timeframe ? Theme.Colors.accent : Theme.Colors.secondaryBackground)
                                )
                        }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Workouts List
    private var workoutsList: some View {
        Group {
            if isLoading {
                loadingView
            } else if filteredWorkouts.isEmpty {
                emptyStateView
            } else {
                workoutsListView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading workout history...")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text("No workouts yet")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("Start your first workout to see your progress here")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Workouts List View
    private var workoutsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredWorkouts, id: \.id) { workout in
                    WorkoutHistoryCard(workout: workout)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Computed Properties
    private var filteredWorkouts: [HevyWorkout] {
        let calendar = Calendar.current
        let now = Date()
        
        return workouts.filter { workout in
            switch selectedTimeframe {
            case .week:
                return calendar.isDate(workout.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(workout.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(workout.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
    }
    
    private var totalWorkoutTime: String {
        let totalSeconds = filteredWorkouts.compactMap { $0.duration }.reduce(0, +)
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var totalExercises: Int {
        filteredWorkouts.reduce(0) { $0 + $1.exercises.count }
    }
    
    private var totalSets: Int {
        filteredWorkouts.reduce(0) { workout in
            workout + workout.exercises.reduce(0) { $0 + $1.sets.count }
        }
    }
    
    // MARK: - Helper Functions
    private func loadWorkouts() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load from database/service
        workouts = sampleWorkouts
    }
    
    // MARK: - Sample Data
    private var sampleWorkouts: [HevyWorkout] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            HevyWorkout(
                id: "1",
                name: "Push Day",
                routineId: "routine1"
            ),
            HevyWorkout(
                id: "2",
                name: "Pull Day",
                routineId: "routine2"
            ),
            HevyWorkout(
                id: "3",
                name: "Leg Day",
                routineId: "routine3"
            ),
            HevyWorkout(
                id: "4",
                name: "Upper Body",
                routineId: "routine4"
            ),
            HevyWorkout(
                id: "5",
                name: "Full Body",
                routineId: "routine5"
            )
        ].map { workout in
            var modifiedWorkout = workout
            modifiedWorkout.date = calendar.date(byAdding: .day, value: -Int.random(in: 1...30), to: now) ?? now
            modifiedWorkout.duration = TimeInterval.random(in: 1800...7200) // 30-120 minutes
            modifiedWorkout.completed = true
            return modifiedWorkout
        }.sorted { $0.date > $1.date }
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: HevyWorkout
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(workout.name)
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        Text(workout.date, style: .date)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if workout.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.success)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                
                // Stats
                HStack(spacing: Theme.Spacing.md) {
                    StatBadge(
                        icon: "dumbbell.fill",
                        text: "\(workout.exercises.count) exercises",
                        color: .blue
                    )
                    
                    StatBadge(
                        icon: "repeat.circle.fill",
                        text: "\(workout.exercises.reduce(0) { $0 + $1.sets.count }) sets",
                        color: .green
                    )
                    
                    if let duration = workout.duration {
                        StatBadge(
                            icon: "clock.fill",
                            text: formatDuration(duration),
                            color: .orange
                        )
                    }
                }
                
                // Progress Indicators
                if !workout.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Exercises")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(workout.exercises.prefix(5), id: \.id) { exercise in
                                    Text(exercise.name)
                                        .font(Theme.Typography.caption1)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Theme.Colors.secondaryBackground)
                                        )
                                }
                                
                                if workout.exercises.count > 5 {
                                    Text("+\(workout.exercises.count - 5) more")
                                        .font(Theme.Typography.caption1)
                                        .foregroundColor(Theme.Colors.accent)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Theme.Colors.accent.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
        .sheet(isPresented: $showingDetails) {
            WorkoutDetailView(workout: workout)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: HevyWorkout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Workout Summary
                        workoutSummary
                        
                        // Exercises List
                        exercisesList
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primaryText)
                }
            }
        }
    }
    
    private var workoutSummary: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Workout Summary")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text(workout.date, style: .date)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Exercises",
                    value: "\(workout.exercises.count)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Sets",
                    value: "\(workout.exercises.reduce(0) { $0 + $1.sets.count })",
                    icon: "repeat.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Duration",
                    value: workout.duration != nil ? formatDuration(workout.duration!) : "Unknown",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Status",
                    value: workout.completed ? "Completed" : "In Progress",
                    icon: workout.completed ? "checkmark.circle.fill" : "clock.circle.fill",
                    color: workout.completed ? .green : .orange
                )
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
    
    private var exercisesList: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercises")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
            }
            
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(workout.exercises, id: \.id) { exercise in
                    ExerciseHistoryCard(exercise: exercise)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Exercise History Card
struct ExerciseHistoryCard: View {
    let exercise: HevyWorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(exercise.name)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text("\(exercise.sets.count) sets")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // Sets Summary
            if !exercise.sets.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(exercise.sets, id: \.id) { set in
                        HStack {
                            Text("Set \(exercise.sets.firstIndex(of: set)! + 1)")
                                .font(Theme.Typography.footnote)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                            
                            Text("\(set.reps) reps")
                                .font(Theme.Typography.footnote)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Text("\(Int(set.weight)) lbs")
                                .font(Theme.Typography.footnote)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            if set.completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.success)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(set.completed ? Theme.Colors.success.opacity(0.1) : Theme.Colors.secondaryBackground)
                        )
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}

#Preview {
    WorkoutHistoryView()
} 