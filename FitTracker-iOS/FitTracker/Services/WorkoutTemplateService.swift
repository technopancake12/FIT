import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class WorkoutTemplateService: ObservableObject {
    static let shared = WorkoutTemplateService()
    
    private let db = Firestore.firestore()
    private let errorHandler = ErrorHandlingService.shared
    // Retry service implementation would go here
    
    // Collection names
    private let templatesCollection = "workout_templates"
    private let ratingsCollection = "template_ratings"
    private let userTemplatesCollection = "user_templates"
    
    @Published var userTemplates: [WorkoutTemplate] = []
    @Published var popularTemplates: [WorkoutTemplate] = []
    @Published var recentTemplates: [WorkoutTemplate] = []
    @Published var isLoading = false
    
    private var listeners: [ListenerRegistration] = []
    private let timeout: TimeInterval = 30.0
    
    private init() {}
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Template Management
    func createTemplate(_ template: WorkoutTemplate) async throws {
        try validateTemplate(template)
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw AppError.authenticationFailed("User not authenticated")
        }
        
        guard template.createdBy == currentUserId else {
            throw AppError.unauthorized("Cannot create template for another user")
        }
        
        let templateData = template.toFirestore()
        
        // Use batch write for atomic operation
        let batch = db.batch()
        
        // Add template to main collection
        let templateRef = db.collection(templatesCollection).document(template.id)
        batch.setData(templateData, forDocument: templateRef)
        
        // Add to user's templates collection
        let userTemplateRef = db.collection("users")
            .document(currentUserId)
            .collection(userTemplatesCollection)
            .document(template.id)
        
        batch.setData([
            "templateId": template.id,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: userTemplateRef)
        
        try await batch.commit()
    }
    
    func updateTemplate(_ template: WorkoutTemplate) async throws {
        try await // Execute operation directly
                try validateTemplate(template)
                
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                guard template.createdBy == currentUserId else {
                    throw AppError.unauthorized("Cannot update template owned by another user")
                }
                
                var templateData = template.toFirestore()
                templateData["updatedAt"] = FieldValue.serverTimestamp()
                
                try await db.collection(templatesCollection)
                    .document(template.id)
                    .updateData(templateData)
        // Context: WorkoutTemplateService.updateTemplate",
    }
    
    func deleteTemplate(_ templateId: String) async throws {
        try await // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                // Verify ownership
                let template = try await getTemplate(templateId)
                guard template.createdBy == currentUserId else {
                    throw AppError.unauthorized("Cannot delete template owned by another user")
                }
                
                let batch = db.batch()
                
                // Delete from main collection
                let templateRef = db.collection(templatesCollection).document(templateId)
                batch.deleteDocument(templateRef)
                
                // Delete from user's templates
                let userTemplateRef = db.collection("users")
                    .document(currentUserId)
                    .collection(userTemplatesCollection)
                    .document(templateId)
                batch.deleteDocument(userTemplateRef)
                
                // Delete all ratings for this template
                let ratingsSnapshot = try await db.collection(ratingsCollection)
                    .whereField("templateId", isEqualTo: templateId)
                    .getDocuments()
                
                for ratingDoc in ratingsSnapshot.documents {
                    batch.deleteDocument(ratingDoc.reference)
                }
                
                try await batch.commit()
        // Context: WorkoutTemplateService.deleteTemplate",
    }
    
    // MARK: - Template Retrieval
    func getTemplate(_ templateId: String) async throws -> WorkoutTemplate {
        return try await // Execute operation directly
                let document = try await db.collection(templatesCollection)
                    .document(templateId)
                    .getDocument()
                
                guard let data = document.data(),
                      let template = WorkoutTemplate.fromFirestore(data) else {
                    throw AppError.dataCorruption("Template not found or corrupted: \(templateId)")
                }
                
                return template
        // Context: WorkoutTemplateService.getTemplate",
    }
    
    func searchTemplates(
        query: String = "",
        muscleGroups: [MuscleGroup] = [],
        equipment: [Equipment] = [],
        difficulty: DifficultyLevel? = nil,
        maxDuration: TimeInterval? = nil,
        sortBy: TemplateSortOption = .popularity,
        limit: Int = 20
    ) async throws -> [WorkoutTemplate] {
        return try await // Execute operation directly
                var firestoreQuery = db.collection(templatesCollection)
                    .whereField("visibility", isEqualTo: "public")
                
                // Apply filters
                if let difficulty = difficulty {
                    firestoreQuery = firestoreQuery.whereField("difficulty", isEqualTo: difficulty.rawValue)
                }
                
                if let maxDuration = maxDuration {
                    firestoreQuery = firestoreQuery.whereField("estimatedDuration", isLessThanOrEqualTo: maxDuration)
                }
                
                if !muscleGroups.isEmpty {
                    firestoreQuery = firestoreQuery.whereField("targetMuscleGroups", arrayContainsAny: muscleGroups.map { $0.rawValue })
                }
                
                if !equipment.isEmpty {
                    firestoreQuery = firestoreQuery.whereField("equipment", arrayContainsAny: equipment.map { $0.rawValue })
                }
                
                // Apply sorting
                switch sortBy {
                case .popularity:
                    firestoreQuery = firestoreQuery.order(by: "totalUses", descending: true)
                case .rating:
                    firestoreQuery = firestoreQuery.order(by: "rating", descending: true)
                case .newest:
                    firestoreQuery = firestoreQuery.order(by: "createdAt", descending: true)
                case .duration:
                    firestoreQuery = firestoreQuery.order(by: "estimatedDuration", descending: false)
                }
                
                firestoreQuery = firestoreQuery.limit(to: limit)
                
                let snapshot = try await firestoreQuery.getDocuments()
                
                var templates = snapshot.documents.compactMap { document -> WorkoutTemplate? in
                    return WorkoutTemplate.fromFirestore(document.data())
                }
                
                // Apply text search filter (client-side for better flexibility)
                if !query.isEmpty {
                    let searchQuery = query.lowercased()
                    templates = templates.filter { template in
                        template.name.lowercased().contains(searchQuery) ||
                        template.description.lowercased().contains(searchQuery) ||
                        template.tags.contains { $0.lowercased().contains(searchQuery) } ||
                        template.createdByUsername.lowercased().contains(searchQuery)
                    }
                }
                
                return templates
        // Context: WorkoutTemplateService.searchTemplates",
    }
    
    func getUserTemplates(_ userId: String? = nil) async throws -> [WorkoutTemplate] {
        return try await // Execute operation directly
                let targetUserId = userId ?? Auth.auth().currentUser?.uid
                
                guard let targetUserId = targetUserId else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let snapshot = try await db.collection(templatesCollection)
                    .whereField("createdBy", isEqualTo: targetUserId)
                    .order(by: "updatedAt", descending: true)
                    .getDocuments()
                
                return snapshot.documents.compactMap { document in
                    WorkoutTemplate.fromFirestore(document.data())
                }
        // Context: WorkoutTemplateService.getUserTemplates",
    }
    
    func getPopularTemplates(limit: Int = 10) async throws -> [WorkoutTemplate] {
        return try await searchTemplates(sortBy: .popularity, limit: limit)
    }
    
    func getFeaturedTemplates() async throws -> [WorkoutTemplate] {
        return try await // Execute operation directly
                let snapshot = try await db.collection(templatesCollection)
                    .whereField("isVerified", isEqualTo: true)
                    .whereField("visibility", isEqualTo: "public")
                    .order(by: "rating", descending: true)
                    .limit(to: 10)
                    .getDocuments()
                
                return snapshot.documents.compactMap { document in
                    WorkoutTemplate.fromFirestore(document.data())
                }
        // Context: WorkoutTemplateService.getFeaturedTemplates",
    }
    
    // MARK: - Template Usage
    func useTemplate(_ templateId: String) async throws -> EnhancedWorkout {
        return try await // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let template = try await getTemplate(templateId)
                
                // Increment usage count
                try await db.collection(templatesCollection)
                    .document(templateId)
                    .updateData([
                        "totalUses": FieldValue.increment(Int64(1))
                    ])
                
                // Convert template to workout
                let workout = convertTemplateToWorkout(template, userId: currentUserId)
                
                // Save the workout
                try await FirebaseManager.shared.saveWorkout(workout)
                
                return workout
        // Context: WorkoutTemplateService.useTemplate",
    }
    
    private func convertTemplateToWorkout(_ template: WorkoutTemplate, userId: String) -> EnhancedWorkout {
        let exercises = template.exercises.sorted { $0.order < $1.order }.map { templateExercise in
            EnhancedWorkoutExercise(
                id: UUID().uuidString,
                exerciseId: templateExercise.exerciseId,
                name: templateExercise.name,
                category: templateExercise.category,
                primaryMuscles: templateExercise.primaryMuscles,
                secondaryMuscles: templateExercise.secondaryMuscles,
                equipment: templateExercise.equipment,
                sets: createEmptySets(count: templateExercise.targetSets),
                notes: templateExercise.notes,
                targetSets: templateExercise.targetSets,
                targetReps: templateExercise.targetReps,
                targetWeight: templateExercise.targetWeight,
                restTime: templateExercise.restTime,
                imageUrls: []
            )
        }
        
        return EnhancedWorkout(
            id: UUID().uuidString,
            userId: userId,
            name: template.name,
            date: Date(),
            exercises: exercises,
            duration: 0,
            completed: false,
            notes: "Created from template: \(template.name)",
            templateId: template.id,
            tags: template.tags
        )
    }
    
    private func createEmptySets(count: Int) -> [EnhancedWorkoutSet] {
        return (0..<count).map { index in
            EnhancedWorkoutSet(
                id: UUID().uuidString,
                reps: 0,
                weight: 0,
                restTime: 120,
                completed: false,
                rpe: nil,
                notes: nil,
                duration: 0,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - Template Rating
    func rateTemplate(_ templateId: String, rating: Int, review: String? = nil) async throws {
        try await // Execute operation directly
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                guard rating >= 1 && rating <= 5 else {
                    throw AppError.validationError("Rating must be between 1 and 5")
                }
                
                let ratingData = TemplateRating(
                    templateId: templateId,
                    userId: currentUserId,
                    rating: rating,
                    review: review
                )
                
                let batch = db.batch()
                
                // Save the rating
                let ratingRef = db.collection(ratingsCollection).document(ratingData.id)
                batch.setData(ratingData.toFirestore(), forDocument: ratingRef)
                
                // Check if user has already rated this template
                let existingRatings = try await db.collection(ratingsCollection)
                    .whereField("templateId", isEqualTo: templateId)
                    .whereField("userId", isEqualTo: currentUserId)
                    .getDocuments()
                
                // Delete any existing ratings from this user
                for existingRating in existingRatings.documents {
                    if existingRating.documentID != ratingData.id {
                        batch.deleteDocument(existingRating.reference)
                    }
                }
                
                try await batch.commit()
                
                // Update template's average rating
                try await updateTemplateRating(templateId)
        // Context: WorkoutTemplateService.rateTemplate",
    }
    
    private func updateTemplateRating(_ templateId: String) async throws {
        let ratingsSnapshot = try await db.collection(ratingsCollection)
            .whereField("templateId", isEqualTo: templateId)
            .getDocuments()
        
        let ratings = ratingsSnapshot.documents.compactMap { document in
            TemplateRating.fromFirestore(document.data())
        }
        
        let totalRatings = ratings.count
        let averageRating = totalRatings > 0 ? ratings.reduce(0) { $0 + $1.rating } / totalRatings : 0
        
        try await db.collection(templatesCollection)
            .document(templateId)
            .updateData([
                "rating": Double(averageRating),
                "totalRatings": totalRatings
            ])
    }
    
    func getTemplateRatings(_ templateId: String, limit: Int = 10) async throws -> [TemplateRating] {
        return try await // Execute operation directly
                let snapshot = try await db.collection(ratingsCollection)
                    .whereField("templateId", isEqualTo: templateId)
                    .order(by: "createdAt", descending: true)
                    .limit(to: limit)
                    .getDocuments()
                
                return snapshot.documents.compactMap { document in
                    TemplateRating.fromFirestore(document.data())
                }
        // Context: WorkoutTemplateService.getTemplateRatings",
    }
    
    // MARK: - Template Sharing
    func shareTemplate(_ templateId: String, shareType: ShareType) async throws -> String {
        return try await // Execute operation directly
                let template = try await getTemplate(templateId)
                
                guard template.visibility != .private else {
                    throw AppError.permissionDenied("Cannot share private template")
                }
                
                switch shareType {
                case .link:
                    return generateShareableLink(for: template)
                case .copy:
                    return generateShareableText(for: template)
                case .export:
                    return try await exportTemplate(template)
                }
        // Context: WorkoutTemplateService.shareTemplate",
    }
    
    private func generateShareableLink(for template: WorkoutTemplate) -> String {
        return "fittracker://template/\(template.id)"
    }
    
    private func generateShareableText(for template: WorkoutTemplate) -> String {
        var text = """
        🏋️ \(template.name)
        
        \(template.description)
        
        💪 Difficulty: \(template.difficulty.displayName)
        ⏱️ Duration: \(formatDuration(template.estimatedDuration))
        🎯 Target: \(template.targetMuscleGroups.map { $0.displayName }.joined(separator: ", "))
        
        Exercises:
        """
        
        for (index, exercise) in template.exercises.enumerated() {
            text += "\n\(index + 1). \(exercise.name) - \(exercise.targetSets) sets x \(exercise.targetReps)"
        }
        
        text += "\n\nCreated by @\(template.createdByUsername) on FitTracker"
        text += "\nTry it: \(generateShareableLink(for: template))"
        
        return text
    }
    
    private func exportTemplate(_ template: WorkoutTemplate) async throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(template)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Validation
    private func validateTemplate(_ template: WorkoutTemplate) throws {
        guard !template.name.isEmpty else {
            throw AppError.validationError("Template name cannot be empty")
        }
        
        guard template.name.count <= 100 else {
            throw AppError.validationError("Template name must be 100 characters or less")
        }
        
        guard !template.description.isEmpty else {
            throw AppError.validationError("Template description cannot be empty")
        }
        
        guard template.description.count <= 500 else {
            throw AppError.validationError("Template description must be 500 characters or less")
        }
        
        guard !template.exercises.isEmpty else {
            throw AppError.validationError("Template must have at least one exercise")
        }
        
        guard template.exercises.count <= 20 else {
            throw AppError.validationError("Template cannot have more than 20 exercises")
        }
        
        guard template.estimatedDuration > 0 else {
            throw AppError.validationError("Template duration must be greater than 0")
        }
        
        guard template.estimatedDuration <= 7200 else { // 2 hours max
            throw AppError.validationError("Template duration cannot exceed 2 hours")
        }
        
        // Validate exercises
        for exercise in template.exercises {
            try validateTemplateExercise(exercise)
        }
    }
    
    private func validateTemplateExercise(_ exercise: TemplateExercise) throws {
        guard !exercise.name.isEmpty else {
            throw AppError.validationError("Exercise name cannot be empty")
        }
        
        guard exercise.targetSets > 0 && exercise.targetSets <= 10 else {
            throw AppError.validationError("Exercise must have between 1 and 10 sets")
        }
        
        guard !exercise.targetReps.isEmpty else {
            throw AppError.validationError("Exercise target reps cannot be empty")
        }
        
        guard exercise.restTime >= 0 && exercise.restTime <= 600 else {
            throw AppError.validationError("Rest time must be between 0 and 600 seconds")
        }
    }
    
    // MARK: - Listeners
    private func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: - Supporting Types
enum TemplateSortOption: String, CaseIterable {
    case popularity = "popularity"
    case rating = "rating"
    case newest = "newest"
    case duration = "duration"
    
    var displayName: String {
        switch self {
        case .popularity: return "Most Popular"
        case .rating: return "Highest Rated"
        case .newest: return "Newest"
        case .duration: return "Shortest Duration"
        }
    }
}

enum ShareType {
    case link
    case copy
    case export
}