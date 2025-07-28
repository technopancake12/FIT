import SwiftUI

struct WorkoutView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if let currentWorkout = viewModel.currentWorkout {
                    WorkoutSessionView(
                        workout: currentWorkout,
                        onComplete: viewModel.completeWorkout,
                        onUpdate: viewModel.updateWorkout
                    )
                } else if viewModel.showExerciseSearch {
                    ExerciseSearchView(
                        selectedExercises: $viewModel.selectedExercises,
                        workoutName: $viewModel.workoutName,
                        onStartWorkout: viewModel.startWorkout,
                        onCancel: { viewModel.showExerciseSearch = false }
                    )
                } else {
                    workoutMainView
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Custom Workout") {
                        viewModel.showExerciseSearch = true
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private var workoutMainView: some View {
        VStack(spacing: 0) {
            // Tab Selection
            Picker("Workout Type", selection: $selectedTab) {
                Text("Quick Start").tag(0)
                Text("Programs").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TabView(selection: $selectedTab) {
                quickStartView.tag(0)
                programsView.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    private var quickStartView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Workout Stats
                WorkoutStatsCard()
                
                // Quick Start Templates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Start Templates")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        QuickWorkoutCard(
                            title: "Push Day",
                            description: "Chest, Shoulders, Triceps",
                            exercises: ["bench-press", "overhead-press", "tricep-dip"],
                            onStart: viewModel.startQuickWorkout
                        )
                        
                        QuickWorkoutCard(
                            title: "Pull Day",
                            description: "Back, Biceps",
                            exercises: ["pull-up", "bent-over-row", "bicep-curl"],
                            onStart: viewModel.startQuickWorkout
                        )
                        
                        QuickWorkoutCard(
                            title: "Leg Day",
                            description: "Quadriceps, Hamstrings, Glutes",
                            exercises: ["squat", "deadlift", "lunge"],
                            onStart: viewModel.startQuickWorkout
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var programsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Workout Programs")
                    .font(.headline)
                
                // This would show structured workout programs
                VStack(spacing: 12) {
                    ProgramCard(
                        title: "Beginner Full Body",
                        description: "3-day full body routine for beginners",
                        duration: "8 weeks",
                        difficulty: "Beginner"
                    )
                    
                    ProgramCard(
                        title: "Push/Pull/Legs",
                        description: "6-day intermediate split routine",
                        duration: "12 weeks",
                        difficulty: "Intermediate"
                    )
                    
                    ProgramCard(
                        title: "Strength Builder",
                        description: "Focus on compound movements",
                        duration: "16 weeks",
                        difficulty: "Advanced"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct WorkoutStatsCard: View {
    @StateObject private var viewModel = WorkoutStatsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(viewModel.workoutsThisWeek)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("This Week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(viewModel.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct QuickWorkoutCard: View {
    let title: String
    let description: String
    let exercises: [String]
    let onStart: ([Exercise]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(exercises.prefix(2), id: \.self) { exerciseId in
                            if let exercise = ExerciseDatabase.shared.findExercise(by: exerciseId) {
                                Text(exercise.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        if exercises.count > 2 {
                            Text("+\(exercises.count - 2) more")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Button("Start") {
                    let exerciseList = exercises.compactMap { ExerciseDatabase.shared.findExercise(by: $0) }
                    onStart(exerciseList)
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProgramCard: View {
    let title: String
    let description: String
    let duration: String
    let difficulty: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(difficulty)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.1))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(4)
                    
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("View Program") {
                // Navigate to program details
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(BorderedButtonStyle())
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case "Beginner": return .green
        case "Intermediate": return .orange
        case "Advanced": return .red
        default: return .gray
        }
    }
}

class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var showExerciseSearch = false
    @Published var selectedExercises: [Exercise] = []
    @Published var workoutName = ""
    
    private let workoutService = WorkoutService.shared
    
    func startWorkout() {
        guard !selectedExercises.isEmpty else { return }
        
        let workoutExercises = selectedExercises.map { exercise in
            WorkoutExercise(
                id: UUID().uuidString,
                exerciseId: exercise.id,
                sets: Array(repeating: WorkoutSet(
                    id: UUID().uuidString,
                    reps: 0,
                    weight: exercise.equipment == "Bodyweight" ? 0 : 20,
                    restTime: nil,
                    completed: false,
                    rpe: nil
                ), count: 3),
                notes: nil,
                targetSets: 3,
                targetReps: 10,
                targetWeight: exercise.equipment == "Bodyweight" ? 0 : 20
            )
        }
        
        let workout = Workout(
            id: UUID().uuidString,
            name: workoutName.isEmpty ? "Quick Workout" : workoutName,
            date: Date(),
            exercises: workoutExercises,
            duration: nil,
            completed: false,
            notes: nil
        )
        
        currentWorkout = workout
        selectedExercises = []
        workoutName = ""
        showExerciseSearch = false
    }
    
    func startQuickWorkout(exercises: [Exercise]) {
        selectedExercises = exercises
        startWorkout()
    }
    
    func completeWorkout() {
        currentWorkout = nil
        // Save completed workout to Core Data
    }
    
    func updateWorkout() {
        // Update current workout state
        objectWillChange.send()
    }
}

class WorkoutStatsViewModel: ObservableObject {
    @Published var workoutsThisWeek = 4
    @Published var currentStreak = 7
    @Published var totalWorkouts = 45
    @Published var totalVolume = 15000.0
    
    init() {
        loadWorkoutStats()
    }
    
    private func loadWorkoutStats() {
        // Load from Core Data or service
    }
}

#Preview {
    WorkoutView()
}