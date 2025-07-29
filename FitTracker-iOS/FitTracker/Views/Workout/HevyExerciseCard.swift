import SwiftUI

struct HevyExerciseCard: View {
    let exercise: HevyWorkoutExercise
    let onSetCompleted: (Int) -> Void
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    
    @State private var showingNotes = false
    @State private var exerciseNotes = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header
            exerciseHeader
            
            // Sets Section
            setsSection
            
            // Exercise Notes (if any)
            if !exercise.notes.isNilOrEmpty {
                exerciseNotesSection
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingNotes) {
            ExerciseNotesSheet(
                notes: $exerciseNotes,
                exerciseName: exercise.name
            )
        }
    }
    
    // MARK: - Exercise Header
    private var exerciseHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("\(exercise.sets.count) sets")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: { showingNotes = true }) {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Sets Section
    private var setsSection: some View {
        VStack(spacing: 0) {
            // Sets Header
            HStack {
                Text("Sets")
                    .font(Theme.Typography.footnote)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Spacer()
                
                Button("Add Set") {
                    onAddSet()
                }
                .font(Theme.Typography.footnote)
                .foregroundColor(Theme.Colors.accent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Sets List
            if exercise.sets.isEmpty {
                emptySetsView
            } else {
                setsListView
            }
        }
    }
    
    // MARK: - Empty Sets View
    private var emptySetsView: some View {
                        Button(action: onAddSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text("Add First Set")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Theme.Colors.accent.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Sets List View
    private var setsListView: some View {
        VStack(spacing: 8) {
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                HevySetRow(
                    setNumber: index + 1,
                    set: set,
                    onCompleted: { onSetCompleted(index) },
                    onRemove: { onRemoveSet(index) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Exercise Notes Section
    private var exerciseNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Notes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(exercise.notes ?? "")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Hevy Set Row
struct HevySetRow: View {
    let setNumber: Int
    let set: HevySet
    let onCompleted: () -> Void
    let onRemove: () -> Void
    
    @State private var showingSetDetails = false
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var setType: HevySet.SetType = .normal
    @State private var notes: String = ""
    @State private var rpe: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Set Number and Type
            VStack(spacing: Theme.Spacing.xs) {
                Text("\(setNumber)")
                    .font(Theme.Typography.footnote)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Image(systemName: set.setType.icon)
                    .font(.system(size: 12))
                    .foregroundColor(set.setType.color)
            }
            .frame(width: 30)
            
            // Reps Input
            VStack(spacing: Theme.Spacing.xs) {
                Text("Reps")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.tertiaryText)
                
                TextField("0", text: $reps)
                    .textFieldStyle()
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
            }
            
            // Weight Input
            VStack(spacing: Theme.Spacing.xs) {
                Text("Weight")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.tertiaryText)
                
                TextField("0", text: $weight)
                    .textFieldStyle()
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
            }
            
            Text("lbs")
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Spacer()
            
            // Set Type Button
            Button(action: { showingSetDetails = true }) {
                Image(systemName: set.setType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(set.setType.color)
            }
            
            // Complete Button
            Button(action: onCompleted) {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(set.completed ? Theme.Colors.success : Theme.Colors.tertiaryText)
            }
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.error.opacity(0.8))
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(set.completed ? Theme.Colors.success.opacity(0.1) : Theme.Colors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .stroke(set.completed ? Theme.Colors.success.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                )
        )
        .onAppear {
            reps = "\(set.reps)"
            weight = "\(Int(set.weight))"
            setType = set.setType
            notes = set.notes ?? ""
            rpe = set.rpe != nil ? "\(set.rpe!)" : ""
        }
        .sheet(isPresented: $showingSetDetails) {
            SetDetailsSheet(
                setType: $setType,
                notes: $notes,
                rpe: $rpe
            )
        }
    }
}



// MARK: - Exercise Notes Sheet
struct ExerciseNotesSheet: View {
    @Binding var notes: String
    let exerciseName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Notes for \(exerciseName)")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    TextEditor(text: $notes)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .textFieldStyle()
                        .foregroundColor(Theme.Colors.primaryText)
                }
                .padding()
            }
            .navigationTitle("Exercise Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - Set Details Sheet
struct SetDetailsSheet: View {
    @Binding var setType: HevySet.SetType
    @Binding var notes: String
    @Binding var rpe: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    // Set Type Selection
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Set Type")
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.Spacing.sm) {
                            ForEach(HevySet.SetType.allCases, id: \.self) { type in
                                Button(action: { setType = type }) {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(type.color)
                                        
                                        Text(type.rawValue)
                                            .font(Theme.Typography.subheadline)
                                            .foregroundColor(Theme.Colors.primaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                            .fill(setType == type ? type.color.opacity(0.2) : Theme.Colors.secondaryBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                                    .stroke(setType == type ? type.color.opacity(0.5) : Theme.Colors.border, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    // RPE Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("RPE (Rate of Perceived Exertion)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        TextField("1-10", text: $rpe)
                            .textFieldStyle()
                            .keyboardType(.numberPad)
                    }
                    
                    // Notes Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Notes")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding()
                            .textFieldStyle()
                            .foregroundColor(Theme.Colors.primaryText)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Set Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

#Preview {
    HevyExerciseCard(
        exercise: HevyWorkoutExercise(
            exerciseId: "1",
            name: "Bench Press",
            order: 0
        ),
        onSetCompleted: { _ in },
        onAddSet: {},
        onRemoveSet: { _ in }
    )
    .padding()
    .background(Theme.Colors.background)
} 