import SwiftUI

// MARK: - Hevy-Style Workout Models
struct HevyWorkout: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date
    var exercises: [HevyWorkoutExercise]
    var duration: TimeInterval?
    var completed: Bool
    var notes: String?
    let routineId: String?
    
    init(id: String = UUID().uuidString, name: String, routineId: String? = nil) {
        self.id = id
        self.name = name
        self.date = Date()
        self.exercises = []
        self.duration = nil
        self.completed = false
        self.notes = nil
        self.routineId = routineId
    }
}

struct HevyWorkoutExercise: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let name: String
    var sets: [HevySet]
    var notes: String?
    let order: Int
    
    init(id: String = UUID().uuidString, exerciseId: String, name: String, order: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.sets = []
        self.notes = nil
        self.order = order
    }
}

struct HevySet: Identifiable, Codable {
    let id: String
    var reps: Int
    var weight: Double
    var setType: SetType
    var completed: Bool
    var notes: String?
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var restTime: TimeInterval?
    
    enum SetType: String, CaseIterable, Codable {
        case normal = "Normal"
        case warmup = "Warmup"
        case drop = "Drop"
        case failure = "Failure"
        case amrap = "AMRAP"
        
        var color: Color {
            switch self {
            case .normal: return .blue
            case .warmup: return .orange
            case .drop: return .purple
            case .failure: return .red
            case .amrap: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .normal: return "circle.fill"
            case .warmup: return "flame.fill"
            case .drop: return "arrow.down.circle.fill"
            case .failure: return "xmark.circle.fill"
            case .amrap: return "infinity.circle.fill"
            }
        }
    }
    
    init(id: String = UUID().uuidString, reps: Int = 0, weight: Double = 0, setType: SetType = .normal) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.setType = setType
        self.completed = false
        self.notes = nil
        self.rpe = nil
        self.restTime = nil
    }
}

// MARK: - Main Hevy-Style Workout View
struct HevyStyleWorkoutView: View {
    @StateObject private var workoutService = WorkoutService.shared
    @State private var currentWorkout: HevyWorkout?
    @State private var showingRoutineSelector = false
    @State private var showingExerciseSearch = false
    @State private var showingWorkoutHistory = false
    @State private var isWorkoutActive = false
    @State private var currentRestTimer: TimeInterval = 0
    @State private var restTimerActive = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    workoutHeader
                    
                    if let workout = currentWorkout {
                        // Active Workout
                        activeWorkoutView(workout)
                    } else {
                        // Workout Selection
                        workoutSelectionView
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("History") {
                        showingWorkoutHistory = true
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingRoutineSelector) {
            RoutineSelectorView { routine in
                startWorkout(with: routine)
            }
        }
        .sheet(isPresented: $showingExerciseSearch) {
            ExerciseSearchView { exercise in
                addExerciseToWorkout(exercise)
            }
        }
        .sheet(isPresented: $showingWorkoutHistory) {
            WorkoutHistoryView()
        }
    }
    
    // MARK: - Header
    private var workoutHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workouts")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Track your progress, smash your goals")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isWorkoutActive {
                    Button("End Workout") {
                        endWorkout()
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            
            // Quick Stats
            if let workout = currentWorkout {
                workoutStatsView(workout)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    // MARK: - Workout Selection
    private var workoutSelectionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Quick Start
                VStack(spacing: 16) {
                    HStack {
                        Text("Quick Start")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    
                    Button(action: { startQuickWorkout() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Empty Workout")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Text("Build your workout as you go")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                
                // Recent Routines
                VStack(spacing: 16) {
                    HStack {
                        Text("Recent Routines")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("View All") {
                            showingRoutineSelector = true
                        }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.blue)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(sampleRoutines, id: \.id) { routine in
                            RoutineCard(routine: routine) {
                                startWorkout(with: routine)
                            }
                        }
                    }
                }
                
                // Recent Workouts
                VStack(spacing: 16) {
                    HStack {
                        Text("Recent Workouts")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("View All") {
                            showingWorkoutHistory = true
                        }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.blue)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(sampleRecentWorkouts, id: \.id) { workout in
                            RecentWorkoutCard(workout: workout)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Active Workout View
    private func activeWorkoutView(_ workout: HevyWorkout) -> some View {
        VStack(spacing: 0) {
            // Rest Timer
            if restTimerActive {
                restTimerView
            }
            
            // Exercise List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        HevyExerciseCard(
                            exercise: exercise,
                            onSetCompleted: { setIndex in
                                completeSet(exerciseIndex: index, setIndex: setIndex)
                            },
                            onAddSet: {
                                addSetToExercise(exerciseIndex: index)
                            },
                            onRemoveSet: { setIndex in
                                removeSetFromExercise(exerciseIndex: index, setIndex: setIndex)
                            }
                        )
                    }
                    
                    // Add Exercise Button
                    Button(action: { showingExerciseSearch = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            Text("Add Exercise")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Rest Timer
    private var restTimerView: some View {
        HStack {
            Image(systemName: "timer")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text(timeString(from: currentRestTimer))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("Skip") {
                restTimerActive = false
                currentRestTimer = 0
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.orange)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }
    
    // MARK: - Workout Stats
    private func workoutStatsView(_ workout: HevyWorkout) -> some View {
        HStack(spacing: 20) {
            WorkoutStatCard(
                title: "Exercises",
                value: "\(workout.exercises.count)",
                icon: "dumbbell.fill",
                color: .blue
            )
            
            WorkoutStatCard(
                title: "Sets",
                value: "\(workout.exercises.flatMap { $0.sets }.count)",
                icon: "repeat.circle.fill",
                color: .green
            )
            
            WorkoutStatCard(
                title: "Duration",
                value: workout.duration != nil ? timeString(from: workout.duration!) : "0:00",
                icon: "clock.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Helper Functions
    private func startQuickWorkout() {
        currentWorkout = HevyWorkout(name: "Quick Workout")
        isWorkoutActive = true
    }
    
    private func startWorkout(with routine: WorkoutTemplate) {
        let workout = HevyWorkout(name: routine.name, routineId: routine.id)
        // Convert routine exercises to Hevy format
        workout.exercises = routine.exercises.enumerated().map { index, exercise in
            HevyWorkoutExercise(
                exerciseId: exercise.exerciseId,
                name: exercise.name,
                order: index
            )
        }
        currentWorkout = workout
        isWorkoutActive = true
    }
    
    private func addExerciseToWorkout(_ exercise: Exercise) {
        guard var workout = currentWorkout else { return }
        let newExercise = HevyWorkoutExercise(
            exerciseId: exercise.id,
            name: exercise.name,
            order: workout.exercises.count
        )
        workout.exercises.append(newExercise)
        currentWorkout = workout
    }
    
    private func completeSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout else { return }
        workout.exercises[exerciseIndex].sets[setIndex].completed = true
        
        // Start rest timer
        startRestTimer()
        
        currentWorkout = workout
    }
    
    private func addSetToExercise(exerciseIndex: Int) {
        guard var workout = currentWorkout else { return }
        let newSet = HevySet()
        workout.exercises[exerciseIndex].sets.append(newSet)
        currentWorkout = workout
    }
    
    private func removeSetFromExercise(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout else { return }
        workout.exercises[exerciseIndex].sets.remove(at: setIndex)
        currentWorkout = workout
    }
    
    private func startRestTimer() {
        currentRestTimer = 90 // 90 seconds default
        restTimerActive = true
        
        // Start countdown timer
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if currentRestTimer > 0 {
                currentRestTimer -= 1
            } else {
                restTimerActive = false
                timer.invalidate()
            }
        }
    }
    
    private func endWorkout() {
        guard var workout = currentWorkout else { return }
        workout.completed = true
        workout.duration = Date().timeIntervalSince(workout.date)
        
        // Save workout
        // TODO: Save to database
        
        currentWorkout = nil
        isWorkoutActive = false
        restTimerActive = false
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Sample Data
    private var sampleRoutines: [WorkoutTemplate] {
        [
            WorkoutTemplate(
                id: "1",
                name: "Push Day",
                description: "Chest, shoulders, triceps",
                exercises: [],
                tags: ["push", "upper"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .intermediate,
                estimatedDuration: 3600
            ),
            WorkoutTemplate(
                id: "2",
                name: "Pull Day",
                description: "Back and biceps",
                exercises: [],
                tags: ["pull", "upper"],
                isPublic: true,
                createdBy: "user1",
                createdAt: Date(),
                difficulty: .intermediate,
                estimatedDuration: 3600
            )
        ]
    }
    
    private var sampleRecentWorkouts: [HevyWorkout] {
        [
            HevyWorkout(id: "1", name: "Push Day"),
            HevyWorkout(id: "2", name: "Pull Day"),
            HevyWorkout(id: "3", name: "Leg Day")
        ]
    }
}

// MARK: - Supporting Views
struct WorkoutStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct RoutineCard: View {
    let routine: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    if let description = routine.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        Text(routine.difficulty.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.2))
                            )
                        
                        if let duration = routine.estimatedDuration {
                            Text("\(Int(duration / 60))min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.orange.opacity(0.2))
                                )
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
}

struct RecentWorkoutCard: View {
    let workout: HevyWorkout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(workout.date, style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if workout.completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    HevyStyleWorkoutView()
} 