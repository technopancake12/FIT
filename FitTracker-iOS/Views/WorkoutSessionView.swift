import SwiftUI

struct WorkoutSessionView: View {
    let workout: Workout
    let onComplete: () -> Void
    let onUpdate: () -> Void
    
    @State private var currentExerciseIndex = 0
    @State private var showTimer = false
    @State private var showInstructions = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    private let startTime = Date()
    
    var currentExercise: WorkoutExercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }
    
    var workoutProgress: Double {
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let completedSets = workout.exercises.reduce(0) { $0 + $1.sets.filter(\.completed).count }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    workoutHeaderView
                    
                    // Timer
                    if showTimer {
                        WorkoutTimerView(onComplete: { showTimer = false })
                    }
                    
                    // Current Exercise
                    if let exercise = currentExercise {
                        currentExerciseView(exercise)
                    }
                    
                    // Navigation
                    navigationButtons
                    
                    // Workout Overview
                    workoutOverviewView
                }
                .padding()
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Timer") {
                        showTimer.toggle()
                    }
                }
            }
            .onAppear {
                startElapsedTimer()
            }
            .onDisappear {
                stopElapsedTimer()
            }
        }
    }
    
    private var workoutHeaderView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Exercise \(currentExerciseIndex + 1) of \(workout.exercises.count) • \(formatTime(elapsedTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            ProgressView(value: workoutProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 4)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func currentExerciseView(_ exercise: WorkoutExercise) -> some View {
        let exerciseInfo = ExerciseDatabase.shared.findExercise(by: exercise.exerciseId)
        let completedSets = exercise.sets.filter(\.completed).count
        
        return VStack(alignment: .leading, spacing: 16) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading) {
                    Text(exerciseInfo?.name ?? "Unknown Exercise")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(exerciseInfo?.equipment ?? "") • \(completedSets)/\(exercise.sets.count) sets completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Tips") {
                    showInstructions = true
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            // Muscle Groups
            if let muscles = exerciseInfo?.primaryMuscles {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(muscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        if let secondaryMuscles = exerciseInfo?.secondaryMuscles {
                            ForEach(secondaryMuscles, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Target Info
            targetInfoView(exercise)
            
            // Sets
            setsView(exercise)
            
            // Instructions Button
            Button("View Instructions") {
                showInstructions = true
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(BorderedButtonStyle())
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showInstructions) {
            if let exerciseInfo = exerciseInfo {
                ExerciseInstructionsView(exercise: exerciseInfo)
            }
        }
    }
    
    private func targetInfoView(_ exercise: WorkoutExercise) -> some View {
        HStack(spacing: 16) {
            VStack {
                Text("Target Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(exercise.targetSets)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                Text("Target Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(exercise.targetReps)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                Text("Target Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(exercise.targetWeight))kg")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func setsView(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sets")
                    .font(.headline)
                Spacer()
                Text("Tap to mark complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                SetRowView(
                    set: set,
                    setNumber: index + 1,
                    onUpdate: { updatedSet in
                        // Update the set in the workout
                        // This would typically update through a view model
                        onUpdate()
                    }
                )
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                if currentExerciseIndex > 0 {
                    currentExerciseIndex -= 1
                }
            }
            .disabled(currentExerciseIndex == 0)
            .frame(maxWidth: .infinity)
            .buttonStyle(BorderedButtonStyle())
            
            if currentExerciseIndex < workout.exercises.count - 1 {
                Button("Next Exercise") {
                    currentExerciseIndex += 1
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderedProminentButtonStyle())
            } else {
                Button("Complete Workout") {
                    onComplete()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
    }
    
    private var workoutOverviewView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Overview")
                .font(.headline)
            
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                let exerciseInfo = ExerciseDatabase.shared.findExercise(by: exercise.exerciseId)
                let completedSets = exercise.sets.filter(\.completed).count
                let totalSets = exercise.sets.count
                let isCurrentExercise = index == currentExerciseIndex
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseInfo?.name ?? "Unknown Exercise")
                            .font(.subheadline)
                            .fontWeight(isCurrentExercise ? .bold : .regular)
                        
                        if let muscles = exerciseInfo?.primaryMuscles {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(muscles.prefix(2), id: \.self) { muscle in
                                        Text(muscle)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(2)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(completedSets)/\(totalSets)")
                        .font(.subheadline)
                        .foregroundColor(completedSets == totalSets ? .green : .secondary)
                        .fontWeight(.medium)
                }
                .padding(12)
                .background(isCurrentExercise ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentExercise ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func startElapsedTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopElapsedTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SetRowView: View {
    let set: WorkoutSet
    let setNumber: Int
    let onUpdate: (WorkoutSet) -> Void
    
    @State private var reps: String
    @State private var weight: String
    @State private var completed: Bool
    
    init(set: WorkoutSet, setNumber: Int, onUpdate: @escaping (WorkoutSet) -> Void) {
        self.set = set
        self.setNumber = setNumber
        self.onUpdate = onUpdate
        self._reps = State(initialValue: set.reps > 0 ? String(set.reps) : "")
        self._weight = State(initialValue: set.weight > 0 ? String(format: "%.1f", set.weight) : "")
        self._completed = State(initialValue: set.completed)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                completed.toggle()
                updateSet()
            }) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(completed ? .green : .gray)
            }
            
            Text("#\(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .leading)
            
            HStack(spacing: 8) {
                TextField("Reps", text: $reps)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .onChange(of: reps) { _ in updateSet() }
                
                TextField("Weight", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 70)
                    .onChange(of: weight) { _ in updateSet() }
            }
            
            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(completed ? Color.green.opacity(0.1) : Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(completed ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func updateSet() {
        let updatedSet = WorkoutSet(
            id: set.id,
            reps: Int(reps) ?? 0,
            weight: Double(weight) ?? 0,
            restTime: set.restTime,
            completed: completed,
            rpe: set.rpe
        )
        onUpdate(updatedSet)
    }
}

struct WorkoutTimerView: View {
    let onComplete: () -> Void
    @State private var timeRemaining = 90
    @State private var timer: Timer?
    @State private var isActive = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rest Timer")
                .font(.headline)
            
            Text(formatTime(timeRemaining))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(timeRemaining <= 10 ? .red : .primary)
            
            HStack(spacing: 16) {
                Button(isActive ? "Pause" : "Start") {
                    if isActive {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                    isActive.toggle()
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
                Button("Reset") {
                    stopTimer()
                    timeRemaining = 90
                    isActive = false
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button("Skip") {
                    stopTimer()
                    onComplete()
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onComplete()
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct ExerciseInstructionsView: View {
    let exercise: Exercise
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .fontWeight(.medium)
                                Text(instruction)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    // Tips
                    if !exercise.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tips")
                                .font(.headline)
                            
                            ForEach(exercise.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .fontWeight(.bold)
                                    Text(tip)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    
                    // Exercise Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise Details")
                            .font(.headline)
                        
                        DetailRow(title: "Equipment", value: exercise.equipment)
                        DetailRow(title: "Difficulty", value: exercise.difficulty.rawValue)
                        DetailRow(title: "Category", value: exercise.category)
                    }
                }
                .padding()
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

#Preview {
    let sampleWorkout = Workout(
        id: "1",
        name: "Push Day",
        date: Date(),
        exercises: [],
        duration: nil,
        completed: false,
        notes: nil
    )
    
    return WorkoutSessionView(
        workout: sampleWorkout,
        onComplete: {},
        onUpdate: {}
    )
}