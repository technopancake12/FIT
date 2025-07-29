import Foundation
import SwiftUI

// MARK: - Enhanced Workout Models

struct EnhancedWorkout: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date
    let exercises: [EnhancedWorkoutExercise]
    let duration: TimeInterval?
    let completed: Bool
    let notes: String?
    let templateId: String?
    let tags: [String]
    
    init(id: String = UUID().uuidString, name: String, date: Date = Date(), exercises: [EnhancedWorkoutExercise] = [], duration: TimeInterval? = nil, completed: Bool = false, notes: String? = nil, templateId: String? = nil, tags: [String] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.exercises = exercises
        self.duration = duration
        self.completed = completed
        self.notes = notes
        self.templateId = templateId
        self.tags = tags
    }
    
    // Calculated properties
    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var primaryMuscles: [String] {
        Array(Set(exercises.flatMap { $0.primaryMuscles }))
    }
    
    var averageRPE: Double {
        let rpeValues = exercises.flatMap { $0.sets }.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return 0 }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }
}

struct EnhancedWorkoutExercise: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let name: String
    let category: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    var sets: [EnhancedWorkoutSet]
    var notes: String?
    let targetSets: Int?
    let targetReps: Int?
    let targetWeight: Double?
    let restTime: TimeInterval?
    let imageUrls: [String]
    
    init(id: String = UUID().uuidString, exerciseId: String, name: String, category: String = "", primaryMuscles: [String] = [], secondaryMuscles: [String] = [], equipment: String = "", sets: [EnhancedWorkoutSet] = [], notes: String? = nil, targetSets: Int? = nil, targetReps: Int? = nil, targetWeight: Double? = nil, restTime: TimeInterval? = nil, imageUrls: [String] = []) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.sets = sets
        self.notes = notes
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restTime = restTime
        self.imageUrls = imageUrls
    }
    
    // Calculated properties
    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var maxWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }
    
    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }
    
    var averageRPE: Double {
        let rpeValues = sets.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return 0 }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }
}

struct EnhancedWorkoutSet: Identifiable, Codable {
    let id: String
    var reps: Int
    var weight: Double
    var restTime: TimeInterval?
    var completed: Bool
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var notes: String?
    var duration: TimeInterval?
    let timestamp: Date
    
    init(id: String = UUID().uuidString, reps: Int = 0, weight: Double = 0, restTime: TimeInterval? = nil, completed: Bool = false, rpe: Int? = nil, notes: String? = nil, duration: TimeInterval? = nil, timestamp: Date = Date()) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.completed = completed
        self.rpe = rpe
        self.notes = notes
        self.duration = duration
        self.timestamp = timestamp
    }
    
    // Calculated properties
    var volume: Double {
        weight * Double(reps)
    }
    
    var oneRepMax: Double {
        guard reps > 0, weight > 0 else { return 0 }
        // Epley formula: 1RM = weight * (1 + reps/30)
        return weight * (1 + Double(reps) / 30.0)
    }
}

// MARK: - Workout Template
// Note: WorkoutTemplate and TemplateExercise are defined in WorkoutTemplate.swift
// This file contains the WorkoutDifficulty enum for compatibility
enum WorkoutDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

// MARK: - Progress Tracking
struct ProgressEntry: Identifiable, Codable {
    let id: String
    let date: Date
    let exerciseId: String
    let exerciseName: String
    let weight: Double
    let reps: Int
    let volume: Double
    let oneRepMax: Double
    let rpe: Int?
    let notes: String?
}

// BodyMeasurement is defined in Analytics.swift

// MARK: - Enhanced Social Models
struct EnhancedSocialPost: Identifiable, Codable {
    let id: String
    let userId: String
    let type: PostType
    let content: String
    let media: [MediaItem]
    let workoutData: WorkoutSummary?
    let achievementData: AchievementData?
    var likes: Int
    var likedBy: [String]
    var comments: [EnhancedComment]
    let createdAt: Date
    let location: Location?
    let tags: [String]
    let visibility: PostVisibility
    let challengeId: String?
    
    enum PostType: String, CaseIterable, Codable {
        case workout = "workout"
        case progress = "progress"
        case achievement = "achievement"
        case motivation = "motivation"
        case tip = "tip"
        case challenge = "challenge"
    }
    
    enum PostVisibility: String, CaseIterable, Codable {
        case `public` = "public"
        case friends = "friends"
        case `private` = "private"
    }
}

struct MediaItem: Identifiable, Codable {
    let id: String
    let type: MediaType
    let url: String
    let thumbnailUrl: String?
    let duration: TimeInterval?
    
    enum MediaType: String, Codable {
        case image = "image"
        case video = "video"
    }
}

struct WorkoutSummary: Codable {
    let workoutId: String
    let name: String
    let duration: TimeInterval
    let totalVolume: Double
    let exerciseCount: Int
    let primaryMuscles: [String]
}

// Achievement is defined in Analytics.swift

struct Location: Codable {
    let name: String
    let latitude: Double?
    let longitude: Double?
}

struct EnhancedComment: Identifiable, Codable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date
    var likes: Int
    var likedBy: [String]
    let replies: [EnhancedComment]?
    let parentId: String?
}

// MARK: - Challenge System
struct EnhancedChallenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: EnhancedChallengeType
    let startDate: Date
    let endDate: Date
    let goal: ChallengeGoal
    let participants: [String]
    let leaderboard: [LeaderboardEntry]
    let isPublic: Bool
    let createdBy: String
    let rewards: [Reward]?
    
    enum EnhancedChallengeType: String, CaseIterable, Codable {
        case individual = "individual"
        case group = "group"
        case community = "community"
    }
}

struct ChallengeGoal: Codable {
    let type: GoalType
    let target: Double
    let unit: String
    let metric: String // "workouts", "volume", "calories", etc.
    
    enum GoalType: String, Codable {
        case accumulative = "accumulative"
        case consistency = "consistency"
        case personal_best = "personal_best"
    }
}

// Note: Reward and LeaderboardEntry are defined in Challenge.swift

// MARK: - Basic Workout Models (for compatibility)
struct EnhancedExercise: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let sets: [ExerciseSet]
    let restTime: TimeInterval?
    let notes: String?
    
    init(name: String, category: String = "General", sets: [ExerciseSet] = [], 
         restTime: TimeInterval? = nil, notes: String? = nil) {
        self.name = name
        self.category = category
        self.sets = sets
        self.restTime = restTime
        self.notes = notes
    }
}

struct ExerciseSet: Identifiable {
    let id = UUID()
    let reps: Int
    let weight: Double?
    let duration: TimeInterval?
    let distance: Double?
    let restTime: TimeInterval?
    let completed: Bool
    
    init(reps: Int = 0, weight: Double? = nil, duration: TimeInterval? = nil, 
         distance: Double? = nil, restTime: TimeInterval? = nil, completed: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.restTime = restTime
        self.completed = completed
    }
}