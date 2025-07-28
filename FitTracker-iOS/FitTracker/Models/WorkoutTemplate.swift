import Foundation
import Firebase
import FirebaseFirestore

// MARK: - Workout Template Models
struct WorkoutTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let createdBy: String
    let createdByUsername: String
    let exercises: [TemplateExercise]
    let tags: [String]
    let difficulty: DifficultyLevel
    let estimatedDuration: TimeInterval
    let targetMuscleGroups: [MuscleGroup]
    let equipment: [Equipment]
    let visibility: TemplateVisibility
    let rating: Double
    let totalRatings: Int
    let totalUses: Int
    let isVerified: Bool
    let isPremium: Bool
    let createdAt: Date
    let updatedAt: Date
    let imageUrl: String?
    let videoUrl: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        createdBy: String,
        createdByUsername: String,
        exercises: [TemplateExercise],
        tags: [String] = [],
        difficulty: DifficultyLevel = .intermediate,
        estimatedDuration: TimeInterval = 3600,
        targetMuscleGroups: [MuscleGroup] = [],
        equipment: [Equipment] = [],
        visibility: TemplateVisibility = .public,
        rating: Double = 0.0,
        totalRatings: Int = 0,
        totalUses: Int = 0,
        isVerified: Bool = false,
        isPremium: Bool = false,
        imageUrl: String? = nil,
        videoUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdBy = createdBy
        self.createdByUsername = createdByUsername
        self.exercises = exercises
        self.tags = tags
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.targetMuscleGroups = targetMuscleGroups
        self.equipment = equipment
        self.visibility = visibility
        self.rating = rating
        self.totalRatings = totalRatings
        self.totalUses = totalUses
        self.isVerified = isVerified
        self.isPremium = isPremium
        self.createdAt = Date()
        self.updatedAt = Date()
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
    }
    
    // MARK: - Firestore Conversion
    static func fromFirestore(_ data: [String: Any]) -> WorkoutTemplate? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let createdBy = data["createdBy"] as? String,
              let createdByUsername = data["createdByUsername"] as? String,
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            return nil
        }
        
        let exercises = exercisesData.compactMap { TemplateExercise.fromFirestore($0) }
        
        return WorkoutTemplate(
            id: id,
            name: name,
            description: description,
            createdBy: createdBy,
            createdByUsername: createdByUsername,
            exercises: exercises,
            tags: data["tags"] as? [String] ?? [],
            difficulty: DifficultyLevel(rawValue: data["difficulty"] as? String ?? "intermediate") ?? .intermediate,
            estimatedDuration: data["estimatedDuration"] as? TimeInterval ?? 3600,
            targetMuscleGroups: (data["targetMuscleGroups"] as? [String] ?? []).compactMap { MuscleGroup(rawValue: $0) },
            equipment: (data["equipment"] as? [String] ?? []).compactMap { Equipment(rawValue: $0) },
            visibility: TemplateVisibility(rawValue: data["visibility"] as? String ?? "public") ?? .public,
            rating: data["rating"] as? Double ?? 0.0,
            totalRatings: data["totalRatings"] as? Int ?? 0,
            totalUses: data["totalUses"] as? Int ?? 0,
            isVerified: data["isVerified"] as? Bool ?? false,
            isPremium: data["isPremium"] as? Bool ?? false,
            imageUrl: data["imageUrl"] as? String,
            videoUrl: data["videoUrl"] as? String
        )
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "createdBy": createdBy,
            "createdByUsername": createdByUsername,
            "exercises": exercises.map { $0.toFirestore() },
            "tags": tags,
            "difficulty": difficulty.rawValue,
            "estimatedDuration": estimatedDuration,
            "targetMuscleGroups": targetMuscleGroups.map { $0.rawValue },
            "equipment": equipment.map { $0.rawValue },
            "visibility": visibility.rawValue,
            "rating": rating,
            "totalRatings": totalRatings,
            "totalUses": totalUses,
            "isVerified": isVerified,
            "isPremium": isPremium,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "imageUrl": imageUrl as Any,
            "videoUrl": videoUrl as Any
        ]
    }
}

struct TemplateExercise: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let name: String
    let category: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    let instructions: String?
    let targetSets: Int
    let targetReps: String // Can be "8-12", "AMRAP", "3x30s", etc.
    let targetWeight: String? // Can be "bodyweight", "75% 1RM", etc.
    let restTime: TimeInterval
    let notes: String?
    let order: Int
    let isSuperset: Bool
    let supersetGroup: String?
    let alternatives: [AlternativeExercise]
    
    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        name: String,
        category: String,
        primaryMuscles: [String],
        secondaryMuscles: [String] = [],
        equipment: String,
        instructions: String? = nil,
        targetSets: Int,
        targetReps: String,
        targetWeight: String? = nil,
        restTime: TimeInterval = 120,
        notes: String? = nil,
        order: Int,
        isSuperset: Bool = false,
        supersetGroup: String? = nil,
        alternatives: [AlternativeExercise] = []
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restTime = restTime
        self.notes = notes
        self.order = order
        self.isSuperset = isSuperset
        self.supersetGroup = supersetGroup
        self.alternatives = alternatives
    }
    
    static func fromFirestore(_ data: [String: Any]) -> TemplateExercise? {
        guard let id = data["id"] as? String,
              let exerciseId = data["exerciseId"] as? String,
              let name = data["name"] as? String,
              let category = data["category"] as? String,
              let primaryMuscles = data["primaryMuscles"] as? [String],
              let equipment = data["equipment"] as? String,
              let targetSets = data["targetSets"] as? Int,
              let targetReps = data["targetReps"] as? String,
              let order = data["order"] as? Int else {
            return nil
        }
        
        let alternativesData = data["alternatives"] as? [[String: Any]] ?? []
        let alternatives = alternativesData.compactMap { AlternativeExercise.fromFirestore($0) }
        
        return TemplateExercise(
            id: id,
            exerciseId: exerciseId,
            name: name,
            category: category,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: data["secondaryMuscles"] as? [String] ?? [],
            equipment: equipment,
            instructions: data["instructions"] as? String,
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: data["targetWeight"] as? String,
            restTime: data["restTime"] as? TimeInterval ?? 120,
            notes: data["notes"] as? String,
            order: order,
            isSuperset: data["isSuperset"] as? Bool ?? false,
            supersetGroup: data["supersetGroup"] as? String,
            alternatives: alternatives
        )
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "id": id,
            "exerciseId": exerciseId,
            "name": name,
            "category": category,
            "primaryMuscles": primaryMuscles,
            "secondaryMuscles": secondaryMuscles,
            "equipment": equipment,
            "instructions": instructions as Any,
            "targetSets": targetSets,
            "targetReps": targetReps,
            "targetWeight": targetWeight as Any,
            "restTime": restTime,
            "notes": notes as Any,
            "order": order,
            "isSuperset": isSuperset,
            "supersetGroup": supersetGroup as Any,
            "alternatives": alternatives.map { $0.toFirestore() }
        ]
    }
}

struct AlternativeExercise: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let name: String
    let reason: String // "No equipment", "Easier variation", "Harder variation", etc.
    
    static func fromFirestore(_ data: [String: Any]) -> AlternativeExercise? {
        guard let id = data["id"] as? String,
              let exerciseId = data["exerciseId"] as? String,
              let name = data["name"] as? String,
              let reason = data["reason"] as? String else {
            return nil
        }
        
        return AlternativeExercise(id: id, exerciseId: exerciseId, name: name, reason: reason)
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "id": id,
            "exerciseId": exerciseId,
            "name": name,
            "reason": reason
        ]
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

enum TemplateVisibility: String, CaseIterable, Codable {
    case `private` = "private"
    case friends = "friends"
    case `public` = "public"
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .friends: return "Friends Only"
        case .public: return "Public"
        }
    }
    
    var icon: String {
        switch self {
        case .private: return "lock"
        case .friends: return "person.2"
        case .public: return "globe"
        }
    }
}

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case legs = "legs"
    case glutes = "glutes"
    case core = "core"
    case cardio = "cardio"
    case fullBody = "full_body"
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .legs: return "Legs"
        case .glutes: return "Glutes"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }
    
    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .arms: return "dumbbell"
        case .legs: return "figure.run"
        case .glutes: return "figure.squatting"
        case .core: return "figure.core.training"
        case .cardio: return "heart"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

enum Equipment: String, CaseIterable, Codable {
    case bodyweight = "bodyweight"
    case dumbbells = "dumbbells"
    case barbell = "barbell"
    case kettlebell = "kettlebell"
    case resistanceBands = "resistance_bands"
    case pullupBar = "pullup_bar"
    case bench = "bench"
    case cables = "cables"
    case machines = "machines"
    case cardioEquipment = "cardio_equipment"
    
    var displayName: String {
        switch self {
        case .bodyweight: return "Bodyweight"
        case .dumbbells: return "Dumbbells"
        case .barbell: return "Barbell"
        case .kettlebell: return "Kettlebell"
        case .resistanceBands: return "Resistance Bands"
        case .pullupBar: return "Pull-up Bar"
        case .bench: return "Bench"
        case .cables: return "Cables"
        case .machines: return "Machines"
        case .cardioEquipment: return "Cardio Equipment"
        }
    }
    
    var icon: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .dumbbells: return "dumbbell"
        case .barbell: return "dumbbell"
        case .kettlebell: return "dumbbell"
        case .resistanceBands: return "link"
        case .pullupBar: return "minus.rectangle"
        case .bench: return "bed.double"
        case .cables: return "cable.connector"
        case .machines: return "gearshape"
        case .cardioEquipment: return "figure.run"
        }
    }
}

// MARK: - Template Rating
struct TemplateRating: Identifiable, Codable {
    let id: String
    let templateId: String
    let userId: String
    let rating: Int // 1-5 stars
    let review: String?
    let createdAt: Date
    
    init(templateId: String, userId: String, rating: Int, review: String? = nil) {
        self.id = UUID().uuidString
        self.templateId = templateId
        self.userId = userId
        self.rating = rating
        self.review = review
        self.createdAt = Date()
    }
    
    static func fromFirestore(_ data: [String: Any]) -> TemplateRating? {
        guard let id = data["id"] as? String,
              let templateId = data["templateId"] as? String,
              let userId = data["userId"] as? String,
              let rating = data["rating"] as? Int else {
            return nil
        }
        
        var templateRating = TemplateRating(
            templateId: templateId,
            userId: userId,
            rating: rating,
            review: data["review"] as? String
        )
        
        // Override the generated values with Firestore data
        return TemplateRating(
            id: id,
            templateId: templateId,
            userId: userId,
            rating: rating,
            review: data["review"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    init(id: String, templateId: String, userId: String, rating: Int, review: String?, createdAt: Date) {
        self.id = id
        self.templateId = templateId
        self.userId = userId
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "id": id,
            "templateId": templateId,
            "userId": userId,
            "rating": rating,
            "review": review as Any,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}