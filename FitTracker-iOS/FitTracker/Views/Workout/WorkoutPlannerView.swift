import SwiftUI

struct WorkoutPlannerView: View {
    @StateObject private var localDatabase = LocalDatabaseService.shared
    @StateObject private var wgerService = WgerAPIService.shared
    @State private var selectedExercises: [Exercise] = []
    @State private var workoutName = ""
    @State private var workoutNotes = ""
    @State private var restTime: Double = 90
    @State private var showExerciseSearch = false
    @State private var currentWorkoutSets: [String: [WorkoutSet]] = [:]
    @State private var showSaveDialog = false
    @State private var savedWorkout: WorkoutTemplate?
    
    var body: some View {
        NavigationView {
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
                        // Workout Header
                        workoutHeaderSection
                        
                        // Exercise List
                        exerciseListSection
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Workout Builder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Template") {
                        showSaveDialog = true
                    }
                    .foregroundColor(.white)
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            ExerciseSelectionView(selectedExercises: $selectedExercises)
        }
        .alert("Save Workout Template", isPresented: $showSaveDialog) {
            TextField("Template Name", text: $workoutName)
            Button("Save") {
                saveWorkoutTemplate()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give your workout template a name to save it for later use.")
        }
    }
    
    private var workoutHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Build Your Workout")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rest Timer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(restTime))s")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Slider(value: $restTime, in: 30...300, step: 15)
                    .accentColor(.blue)
            }
            
            TextField("Workout notes (optional)", text: $workoutNotes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
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
    
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Exercises (\(selectedExercises.count))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !selectedExercises.isEmpty {
                    Button("Clear All") {
                        selectedExercises.removeAll()
                        currentWorkoutSets.removeAll()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                }
            }
            
            if selectedExercises.isEmpty {
                emptyExerciseState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseBuilderCard(
                            exercise: exercise,
                            sets: Binding(
                                get: { currentWorkoutSets[exercise.id] ?? [] },
                                set: { currentWorkoutSets[exercise.id] = $0 }
                            ),
                            onRemove: {
                                selectedExercises.remove(at: index)
                                currentWorkoutSets.removeValue(forKey: exercise.id)
                            }
                        )
                    }
                }
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
    
    private var emptyExerciseState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No exercises added yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Tap the button below to add exercises to your workout")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var addExerciseButton: some View {
        Button(action: {
            showExerciseSearch = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                
                Text("Add Exercise")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.8))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Start Workout Button
            Button(action: startWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Start This Workout")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedExercises.isEmpty)
            .opacity(selectedExercises.isEmpty ? 0.6 : 1.0)
            
            // Load Template Button
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Load Template")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func startWorkout() {
        // Navigate to active workout session
        print("Starting workout with \(selectedExercises.count) exercises")
    }
    
    private func saveWorkoutTemplate() {
        guard !workoutName.isEmpty, !selectedExercises.isEmpty else { return }
        
        let templateExercises = selectedExercises.enumerated().map { index, exercise in
            TemplateExercise(
                id: UUID().uuidString,
                exerciseId: exercise.id,
                name: exercise.name,
                sets: currentWorkoutSets[exercise.id]?.count ?? 3,
                reps: "8-12",
                weight: nil,
                restTime: restTime,
                notes: nil,
                order: index
            )
        }
        
        let template = WorkoutTemplate(
            id: UUID().uuidString,
            name: workoutName,
            description: workoutNotes.isEmpty ? nil : workoutNotes,
            exercises: templateExercises,
            tags: extractMuscleGroups(),
            isPublic: false,
            createdBy: "current_user", // TODO: Get actual user ID
            createdAt: Date(),
            difficulty: convertDifficulty(calculateDifficulty()),
            estimatedDuration: TimeInterval(estimatedDuration * 60)
        )
        
        savedWorkout = template
        // Save to local database or Firebase
        print("Saved workout template: \(template.name)")
    }
    
    private var estimatedDuration: Int {
        let totalSets = currentWorkoutSets.values.flatMap { $0 }.count
        let estimatedMinutes = totalSets * 2 + (totalSets - 1) * Int(restTime) / 60
        return max(estimatedMinutes, 15)
    }
    
    private func calculateDifficulty() -> ExerciseDifficulty {
        let difficulties = selectedExercises.map { $0.difficulty }
        let beginnerCount = difficulties.filter { $0 == .beginner }.count
        let intermediateCount = difficulties.filter { $0 == .intermediate }.count
        let advancedCount = difficulties.filter { $0 == .advanced }.count
        
        if advancedCount > intermediateCount && advancedCount > beginnerCount {
            return .advanced
        } else if intermediateCount > beginnerCount {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func convertDifficulty(_ difficulty: ExerciseDifficulty) -> WorkoutTemplate.WorkoutDifficulty {
        switch difficulty {
        case .beginner:
            return .beginner
        case .intermediate:
            return .intermediate
        case .advanced:
            return .advanced
        }
    }
    
    private func extractMuscleGroups() -> [String] {
        return Array(Set(selectedExercises.flatMap { $0.primaryMuscles }))
    }
}

struct ExerciseBuilderCard: View {
    let exercise: Exercise
    @Binding var sets: [WorkoutSet]
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(exercise.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            
            // Sets Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Button("Add Set") {
                        sets.append(WorkoutSet(id: UUID().uuidString, reps: 12, weight: 0, restTime: 90, completed: false))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                }
                
                if sets.isEmpty {
                    Button("Add First Set") {
                        sets.append(WorkoutSet(id: UUID().uuidString, reps: 12, weight: 0, restTime: 90, completed: false))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                    )
                } else {
                    ForEach(Array(sets.enumerated()), id: \.offset) { index, _ in
                        SetBuilderRow(
                            setNumber: index + 1,
                            set: Binding(
                                get: { sets[index] },
                                set: { sets[index] = $0 }
                            ),
                            onRemove: {
                                sets.remove(at: index)
                            }
                        )
                    }
                }
            }
            
            // Muscle Groups
            if !exercise.primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary Muscles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.green.opacity(0.3))
                                    )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct SetBuilderRow: View {
    let setNumber: Int
    @Binding var set: WorkoutSet
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24)
            
            // Reps
            VStack(spacing: 4) {
                Text("Reps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("12", value: $set.reps, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
            }
            
            // Weight
            VStack(spacing: 4) {
                Text("Weight")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("0", value: $set.weight, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
            }
            
            Text("lbs")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Remove Set
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
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

struct ExerciseSelectionView: View {
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localDatabase = LocalDatabaseService.shared
    @State private var searchText = ""
    @State private var exercises: [DatabaseExercise] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Search exercises...", text: $searchText)
                            .foregroundColor(.white)
                            .onSubmit {
                                performSearch()
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // Exercise List
                    List {
                        ForEach(exercises, id: \.id) { exercise in
                            ExerciseSelectionRow(
                                exercise: exercise.toLocalExercise(),
                                isSelected: selectedExercises.contains { $0.id == exercise.id.description },
                                onToggle: { toggleExercise(exercise.toLocalExercise()) }
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadExercises()
        }
        .onChange(of: searchText) {
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private func loadExercises() async {
        isLoading = true
        do {
            exercises = try await localDatabase.searchExercises(query: "", limit: 100)
        } catch {
            print("Error loading exercises: \(error)")
        }
        isLoading = false
    }
    
    private func performSearch() {
        Task {
            do {
                isLoading = true
                exercises = try await localDatabase.searchExercises(query: searchText, limit: 100)
                isLoading = false
            } catch {
                print("Error searching exercises: \(error)")
                isLoading = false
            }
        }
    }
    
    private func toggleExercise(_ exercise: Exercise) {
        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }
}

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(exercise.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                
                if !exercise.primaryMuscles.isEmpty {
                    Text(exercise.primaryMuscles.joined(separator: ", "))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    WorkoutPlannerView()
}