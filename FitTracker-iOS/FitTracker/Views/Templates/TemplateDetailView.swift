import SwiftUI

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var templateService: WorkoutTemplateService
    @State private var showingRatingView = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    TemplateHeaderView(template: template)
                    
                    // Description
                    if let description = template.description {
                        DescriptionSection(description: description)
                    }
                    
                    // Stats Section
                    StatsSection(template: template)
                    
                    // Exercises Section
                    ExercisesSection(exercises: template.exercises)
                    
                    // Ratings Section
                    RatingsSection(
                        ratings: template.ratings,
                        averageRating: template.averageRating,
                        onAddRating: { showingRatingView = true }
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { toggleFavorite() }) {
                            Label(
                                isFavorited ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: isFavorited ? "heart.slash" : "heart"
                            )
                        }
                        
                        Button(action: { showingRatingView = true }) {
                            Label("Rate Template", systemImage: "star")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ActionButtonsView(
                    template: template,
                    onUse: { useTemplate() }
                )
            }
        }
        .sheet(isPresented: $showingRatingView) {
            RateTemplateView(template: template)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareTemplateView(template: template)
        }
    }
    
    private var isFavorited: Bool {
        templateService.favoriteTemplates.contains { $0.id == template.id }
    }
    
    private func useTemplate() {
        Task {
            do {
                let workout = try await templateService.useTemplate(template)
                presentationMode.wrappedValue.dismiss()
                
                NotificationCenter.default.post(
                    name: .startWorkoutFromTemplate,
                    object: workout
                )
            } catch {
                print("Error using template: \(error)")
            }
        }
    }
    
    private func toggleFavorite() {
        Task {
            do {
                if isFavorited {
                    try await templateService.removeFromFavorites(template.id)
                } else {
                    try await templateService.addToFavorites(template.id)
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}

// MARK: - Header View
struct TemplateHeaderView: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryBadge(category: template.category)
                DifficultyBadge(difficulty: template.difficulty)
                Spacer()
                
                if template.isPublic {
                    Text("Public")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            HStack {
                Text("Created by @username") // Would fetch actual username
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(template.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !template.tags.isEmpty {
                TagsScrollView(tags: template.tags)
            }
        }
    }
}

// MARK: - Description Section
struct DescriptionSection: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    icon: "dumbbell",
                    title: "Exercises",
                    value: "\(template.totalExercises)",
                    color: .blue
                )
                
                StatCard(
                    icon: "list.number",
                    title: "Total Sets",
                    value: "\(template.totalSets)",
                    color: .green
                )
                
                StatCard(
                    icon: "clock",
                    title: "Duration",
                    value: template.estimatedDuration?.formattedDuration ?? "N/A",
                    color: .orange
                )
                
                StatCard(
                    icon: "person.3",
                    title: "Uses",
                    value: "\(template.usageCount)",
                    color: .purple
                )
            }
            
            if !template.targetMuscleGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Muscle Groups")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TagsScrollView(tags: template.targetMuscleGroups)
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Exercises Section
struct ExercisesSection: View {
    let exercises: [TemplateExercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises (\(exercises.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(exercises) { exercise in
                TemplateExerciseCard(exercise: exercise)
            }
        }
    }
}

struct TemplateExerciseCard: View {
    let exercise: TemplateExercise
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(exercise.sets.count) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !exercise.primaryMuscles.isEmpty {
                        Text("Primary: \(exercise.primaryMuscles.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !exercise.secondaryMuscles.isEmpty {
                        Text("Secondary: \(exercise.secondaryMuscles.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        TemplateSetRow(setNumber: index + 1, set: set)
                    }
                    
                    if let notes = exercise.notes {
                        Text("Notes: \(notes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TemplateSetRow: View {
    let setNumber: Int
    let set: TemplateSet
    
    var body: some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            if let reps = set.targetReps {
                Text("\(reps) reps")
                    .font(.caption)
            }
            
            if let weight = set.targetWeight {
                Text("\(weight, specifier: "%.1f") lbs")
                    .font(.caption)
            }
            
            if let rpe = set.targetRPE {
                Text("RPE \(rpe)")
                    .font(.caption)
            }
            
            Spacer()
            
            Text(set.type.abbreviation)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Ratings Section
struct RatingsSection: View {
    let ratings: [Rating]
    let averageRating: Double
    let onAddRating: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ratings (\(ratings.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Rating", action: onAddRating)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if !ratings.isEmpty {
                HStack {
                    StarRatingView(rating: averageRating, size: 20)
                    Text(String(format: "%.1f", averageRating))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("(\(ratings.count) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(ratings.prefix(3)) { rating in
                    RatingCard(rating: rating)
                }
            } else {
                Text("No ratings yet. Be the first to rate this template!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RatingCard: View {
    let rating: Rating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StarRatingView(rating: Double(rating.rating), size: 16)
                Spacer()
                Text(rating.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let comment = rating.comment {
                Text(comment)
                    .font(.body)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StarRatingView: View {
    let rating: Double
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.system(size: size))
            }
        }
    }
    
    private func starType(for index: Int) -> String {
        let filledStars = Int(rating)
        let hasHalfStar = rating - Double(filledStars) >= 0.5
        
        if index < filledStars {
            return "star.fill"
        } else if index == filledStars && hasHalfStar {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Action Buttons
struct ActionButtonsView: View {
    let template: WorkoutTemplate
    let onUse: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Use This Template") {
                onUse()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 1)
    }
}

// MARK: - Tags Scroll View
struct TagsScrollView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Rate Template View
struct RateTemplateView: View {
    let template: WorkoutTemplate
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var templateService: WorkoutTemplateService
    
    @State private var selectedRating = 0
    @State private var comment = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Rate this template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                InteractiveStarRatingView(rating: $selectedRating)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment (Optional)")
                        .font(.headline)
                    
                    TextField("Share your thoughts...", text: $comment, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                Button("Submit Rating") {
                    submitRating()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedRating == 0 || isSubmitting)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Rate Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        
        Task {
            do {
                try await templateService.rateTemplate(
                    template.id,
                    rating: selectedRating,
                    comment: comment.isEmpty ? nil : comment
                )
                
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                print("Error submitting rating: \(error)")
            }
        }
    }
}

struct InteractiveStarRatingView: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button(action: { rating = index }) {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title)
                }
            }
        }
    }
}

// MARK: - Share Template View
struct ShareTemplateView: View {
    let template: WorkoutTemplate
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Share Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let shareCode = template.shareCode {
                    VStack(spacing: 16) {
                        Text("Share Code")
                            .font(.headline)
                        
                        Text(shareCode)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Copy Code") {
                            UIPasteboard.general.string = shareCode
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
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